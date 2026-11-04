// SPDX-FileCopyrightText: © 2026 Tave La Rocque
// SPDX-License-Identifier: Apache-2.0
//
// The USB host driver (host/protocol_emulator.py) running in MicroPython on
// the emulated demo board, reading a device descriptor from a low-speed
// device through the chip's RTL.
//
//   node run_usb.mjs [--port pio|bitbang] [--driver FILE] [--cpu-slowdown K]
//                    [--mutant push-after-start] [--expect-fail]
//
// Prints the bus, packet by packet, with the device-side timing that
// matters (the gap from the device's data to the host's handshake), and
// exits 0 if the descriptor read back is right (or, with --expect-fail,
// if it is not).

import { readFileSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';
import { Board, hw } from './board.mjs';
import { steps, packets, describe, pidName, BIT_NS } from './usb_bus.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const arg = (name, def) => {
  const i = process.argv.indexOf('--' + name);
  return i < 0 ? def : process.argv[i + 1];
};
const portKind = arg('port', 'pio');
const driverPath = arg('driver', join(HERE, '..', '..', 'host', 'protocol_emulator.py'));
const expectFail = process.argv.includes('--expect-fail');
const firmware = arg('firmware', join(HERE, 'build', 'tt-demo-rp2040-v2.0.4.uf2'));

const DESCRIPTOR = [0x12, 0x01, 0x10, 0x01, 0x00, 0x00, 0x00, 0x08, 0xc7, 0x05,
  0x13, 0x01, 0x01, 0x00, 0x01, 0x02, 0x03, 0x01]; // usbhostslave/usbROM.v
const image = readFileSync(join(HERE, '..', 'usb_host.hex'), 'latin1')
  .split('\n').filter((l) => l.trim()).map((l) => parseInt(l, 16));

const wall = Date.now();
const cpuSlowdown = Number(arg('cpu-slowdown', '1'));
const board = new Board(firmware, { quantumNs: 40, cpuSlowdown });
board.boot();
const bootMs = board.nanos / 1e6;

// The driver, then the board's pins as the SDK leaves them for direct
// control: ui_in outputs (CS_N high), uo_out inputs.
// Planted bug: the late words go in the old way, one push (a status read
// then a write) at a time after starting the engine.
const MUTANTS = {
  'push-after-start': [
    /        self\.chip\.write_many\(\[\(CTRL, self\.chip\.ctrl\(\(0, 1\), chain=True\)\)\]\n\s*\+ \[\(TX_FIFO, w\) for w in words\[preload:\]\]\)/,
    '        self.chip.run(threads=(0, 1), chain=True)\n        for w in words[preload:]:\n            self.chip.push(w)'],
};
let driver = readFileSync(driverPath, 'latin1');
const mutant = arg('mutant', null);
if (mutant) {
  const [re, rep] = MUTANTS[mutant];
  if (!re.test(driver)) throw new Error('mutant does not apply: ' + mutant);
  driver = driver.replace(re, rep);
}
let [o, e] = board.exec(driver + '\nprint("driver loaded")\n');
if (!o.includes('driver loaded')) throw new Error('driver: ' + o + e);
[o, e] = board.exec(`
from machine import Pin
for g in (9, 10, 11, 12, 17, 18, 19, 20):
    Pin(g, Pin.OUT, value=1 if g == 10 else 0)
for g in (5, 6, 7, 8, 13, 14, 15, 16):
    Pin(g, Pin.IN)
`);
if (e) throw new Error(e);

// Power the chip and the device: reset both, then wait for the device's
// pull-up.
board.power({ chipHz: 12e6, devMode: 7, usb: true });
board.setResets({ rstN: 0, usbRst: 1 });
board.run(null, 2000);
board.setResets({ rstN: 1, usbRst: 0 });
if (!board.run(() => hw.state()[2] === 1, 50e6)) throw new Error('the USB device never connected');
hw.takeBusLog();
const t0 = board.nanos;

[o, e] = board.exec(`
import time
port = ${portKind === 'pio' ? 'PioPort()' : 'demo_board_port()'}
chip = Chip(port)
t = time.ticks_us()
host = UsbHost(chip, ${JSON.stringify(image)})
t_load = time.ticks_diff(time.ticks_us(), t)
t = time.ticks_us()
try:
    d = host.control_read(0, [0x80, 0x06, 0x00, 0x01, 0x00, 0x00, 0x12, 0x00], 18)
    print("DATA", " ".join("%02x" % b for b in d))
except UsbError as x:
    print("USBERROR", x)
print("TIMES load_us", t_load, "control_read_us", time.ticks_diff(time.ticks_us(), t))
`, 600e9);
const log = hw.takeBusLog();
const [, , , conflicts] = hw.state();

console.log(`board: TT MicroPython SDK on RP2040 (rp2040js), booted in ${bootMs.toFixed(0)} ms emulated`);
console.log(`port: ${portKind}, driver: ${driverPath}${mutant ? ' with planted bug ' + mutant : ''}, CPU slowed x${cpuSlowdown}`);
console.log('MicroPython printed:', (o + e).trim());

// The bus, and the handshake timing after each data packet from the device.
const ps = packets(steps(log));
console.log('\nbus (time from the device connecting):');
for (const p of ps) console.log(describe(p, t0));
let worst = 0, late = 0, minSlack = Infinity, worstZlp = 0;
console.log('\nhandshakes after the device\'s data (deadline: 16 bit times, ' + (16 * BIT_NS / 1000).toFixed(2) + ' us):');
for (let i = 0; i < ps.length; i++) {
  const p = ps[i];
  if (p.host || !['DATA0', 'DATA1'].includes(pidName(p))) continue;
  const n = ps[i + 1];
  const gap = n ? (n.start - p.end) / BIT_NS : Infinity;
  const ok = n && n.host && pidName(n) === 'ACK' && gap <= 16;
  if (!ok) late++;
  else worst = Math.max(worst, gap);
  // Slack: how long before the device's data ended the handshake's last
  // word reached the chip (negative if after). That word is the last TX
  // FIFO write after the CTRL write that started this transaction.
  const CTRL_WRITE = (1 << 7) | 0x40, TX_WRITE = (1 << 7) | 0x48;
  const pd = board.portDone;
  let c = -1;
  for (let q = 0; q < pd.length && pd[q][0] < p.start; q++) if (pd[q][1] >> 16 === CTRL_WRITE) c = q;
  let last = null;
  for (let q = c + 1; q < pd.length && pd[q][1] >> 16 !== CTRL_WRITE; q++) if (pd[q][1] >> 16 === TX_WRITE) last = pd[q][0];
  const slack = c >= 0 && last !== null ? (p.end - last) / 1000 : NaN;
  // A zero-length data packet (SYNC, PID, CRC16: 32 bits, then EOP) would
  // end this much sooner, with the host's words arriving at the same time;
  // the handshake would then start late by however far they missed it.
  const zlpSlack = slack - (p.end - (p.start + 34 * BIT_NS)) / 1000;
  const zlpGap = gap + (Math.max(0, -zlpSlack) - Math.max(0, -slack)) * 1000 / BIT_NS;
  if (ok) { minSlack = Math.min(minSlack, slack); worstZlp = Math.max(worstZlp, zlpGap); }
  console.log(`  ${pidName(p)} ${p.bytes.length - 3} bytes: next is ${n ? (n.host ? 'host ' : 'device ') + pidName(n) : 'nothing'} after ${gap.toFixed(2)} bit times ${ok ? 'OK' : 'LATE'}; handshake's last word in ${slack.toFixed(1)} us before the data ended (a zero-length packet's handshake would follow after ${zlpGap.toFixed(2)} bit times)`);
}
const got = (o.match(/DATA ([0-9a-f ]+)/) || [])[1];
const want = DESCRIPTOR.map((b) => b.toString(16).padStart(2, '0')).join(' ');
const pass = got === want && late === 0 && worstZlp <= 16 && conflicts === 0;
console.log(`\ndescriptor ${got === want ? 'correct' : 'WRONG or missing'}; late handshakes ${late}; ` +
  `worst handshake gap ${worst.toFixed(2)} bit times (${worstZlp.toFixed(2)} for a zero-length packet); least slack ${isFinite(minSlack) ? minSlack.toFixed(1) + ' us' : 'n/a'}; bus conflicts ${conflicts}; ` +
  `wall ${((Date.now() - wall) / 1000).toFixed(0)} s`);
process.exit(pass !== expectFail ? 0 : 1);
