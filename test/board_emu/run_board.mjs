// SPDX-FileCopyrightText: © 2026 Tave La Rocque
// SPDX-License-Identifier: Apache-2.0
//
// Every protocol class of the host driver (host/protocol_emulator.py), run
// in MicroPython on the emulated demo board against the chip's RTL and a
// device on its protocol pins: the same scenarios as the cocotb "host
// driver" tests (test/test.py), so what passed under CPython is shown to
// work, in MicroPython, at the board's speed.
//
//   node run_board.mjs [scenario ...]     (default: all but usb)
//   node run_board.mjs swd --mutant cpython-only-call --expect-fail
//
// Scenarios: uart, flash, i2c_device, spi_device, jtag, swd. USB has its own
// timing report: run_usb.mjs. The host port is bit-banged (demo_board_port)
// with the chip at 10 MHz, as docs/info.md describes. Exits 0 if all pass.

import { readFileSync, writeFileSync, mkdirSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';
import { Board, hw } from './board.mjs';
import { uartReceiver, i2cController, spiController } from './devices.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const TEST = join(HERE, '..');
const image = (name) => JSON.stringify(readFileSync(join(TEST, name + '.hex'), 'latin1')
  .split('\n').filter((l) => l.trim()).map((l) => parseInt(l, 16)));
const eq = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const hex = (v) => '0x' + (v >>> 0).toString(16);

let board;

// Run MicroPython that prints one line "RESULT <json>"; returns the value.
function py(code, maxNs = 120e9) {
  const [o, e] = board.exec(`
import json, time
_t = time.ticks_us()
${code}
`, maxNs);
  const m = o.match(/RESULT (.*)/);
  if (!m) throw new Error('MicroPython: ' + (o + e).trim());
  return JSON.parse(m[1]);
}

// Power the chip at 10 MHz with [opts], reset it, and connect the
// bit-banged host port.
function powerOn(opts) {
  board.power({ chipHz: 10e6, ...opts });
  board.setResets({ rstN: 0 });
  board.run(null, 2000);
  board.setResets({ rstN: 1 });
  py('chip = Chip(demo_board_port())\nprint("RESULT", json.dumps(0))');
}

const SCENARIOS = {
  // test_host_driver_uart_and_spi, first half: UART TX into a receiver.
  uart() {
    const divisor = 16;
    const rx = uartReceiver(1e9 / (10e6 / divisor));
    powerOn({ devMode: 3, device: rx });
    const message = 'pins to pins';
    const ms = py(`UartTx(chip, ${image('uart_tx')}, divisor=${divisor}).write(b"${message}")
print("RESULT", json.dumps(time.ticks_diff(time.ticks_us(), _t) / 1000))`);
    board.run(() => rx.bytes.length >= message.length, 200e6);
    const got = String.fromCharCode(...rx.bytes);
    return [got === message && rx.framingErrors === 0,
      `receiver got ${JSON.stringify(got)} (${rx.framingErrors} framing errors); the driver took ${ms} ms`];
  },

  // test_host_driver_uart_and_spi, second half: picosoc's SPI flash.
  flash() {
    mkdirSync(join(HERE, 'build'), { recursive: true });
    const file = join(HERE, 'build', 'flash.hex');
    writeFileSync(file, '@100\n12 34 56\n');
    powerOn({ devMode: 2, flashHex: file });
    const [got, ms] = py(`spi = SpiController(chip, ${image('spi_fast')})
spi.transfer([0xAB])  # wake from power-down
got = spi.transfer([0x03, 0x00, 0x01, 0x00, 0, 0, 0])[4:]
print("RESULT", json.dumps([got, time.ticks_diff(time.ticks_us(), _t) / 1000]))`);
    return [eq(got, [0x12, 0x34, 0x56]), `flash returned ${JSON.stringify(got)}; ${ms} ms`];
  },

  // test_host_driver_devices, first half: the chip as an I2C device, read
  // through a repeated START by a fast-mode controller.
  i2c_device() {
    powerOn({ devMode: 1 });
    py(`device = I2cDevice(chip, ${image('i2c_target')}, address=0x2A)
device.reply([0xBE, 0xEF])
print("RESULT", json.dumps(0))`);
    const ctl = i2cController([{ write: [0x2a, [0x07]] }, { read: [0x2a, 2] }]);
    board.attachDevice(ctl);
    board.run(() => ctl.done, 500e6);
    const events = py('print("RESULT", json.dumps(device.events()))');
    const r = ctl.result;
    const ok = ctl.done && eq(r, [{ acks: [0, 0] }, { acks: [0], bytes: [0xbe, 0xef] }]) &&
      eq(events, [['start', false], 7, ['start', true]]);
    return [ok, `controller saw ${JSON.stringify(r)}; driver events ${JSON.stringify(events)}`];
  },

  // test_host_driver_devices, second half: the chip as an SPI device.
  spi_device() {
    powerOn({ devMode: 4 });
    py(`spi_device = SpiDevice(chip, ${image('spi_target')})
spi_device.reply([0xA1, 0xB2, 0xC3, 0x00])  # 3 bytes, plus 1 held ahead
print("RESULT", json.dumps(0))`);
    const ctl = spiController([0x9f, 0x01, 0x02], { halfNs: 1000 });
    board.attachDevice(ctl);
    board.run(() => ctl.done, 100e6);
    const transfers = py('print("RESULT", json.dumps(spi_device.transfers()))');
    const ok = ctl.done && eq(ctl.result, [0xa1, 0xb2, 0xc3]) && eq(transfers, [[0x9f, 1, 2]]);
    return [ok, `controller read ${JSON.stringify(ctl.result)}; driver saw ${JSON.stringify(transfers)}`];
  },

  // test_thirdparty_jtag: an IEEE 1149.1 TAP (test/jtag_tap.v).
  jtag() {
    powerOn({ devMode: 5 });
    const [r, ms] = py(`j = JtagController(chip, ${image('jtag')})
j.reset()
r = [j.shift_dr(0, 32), j.shift_ir(0b1000, 4), j.shift_dr(0xCAFEF00D, 32),
     j.shift_dr(0x12345678, 32)]
j.shift_ir(0b1111, 4)
r.append(j.shift_dr(0b1011, 4))
print("RESULT", json.dumps([r, time.ticks_diff(time.ticks_us(), _t) / 1000]))`);
    const want = [0x1badc0de, 0b0101, 0, 0xcafef00d, 0b0110];
    return [eq(r, want), `IDCODE ${hex(r[0])}, IR capture ${r[1]}, USER ${hex(r[2])} then ${hex(r[3])}, BYPASS ${r[4]}; ${ms} ms`];
  },

  // test_swd: an SWD target written from ADIv5 (test/swd_dp.v).
  swd() {
    powerOn({ devMode: 6 });
    const [r, ms] = py(`swd = SwdController(chip, ${image('swd')})
try:
    swd.read_dp(swd.DPIDR)
    silent = False
except SwdError:
    silent = True
dpidr = swd.connect()
swd.write_dp(swd.CTRL_STAT, 0x50000000)
ctrl = swd.read_dp(swd.CTRL_STAT)
swd.write_dp(swd.SELECT, 0x000000F0)
idr = swd.read_ap_now(0xC)
swd.write_dp(swd.SELECT, 0x00000000)
swd.write_ap(0x4, 0xDEADBEEF)
posted = swd.read_ap(0x4)
tar = swd.read_dp(swd.RDBUFF)
print("RESULT", json.dumps([[silent, dpidr, ctrl, idr, posted, tar], time.ticks_diff(time.ticks_us(), _t) / 1000]))`);
    const parity = hw.state()[4];
    const want = [true, 0x2ba01477, 0xf0000000, 0x24770011, 0x24770011, 0xdeadbeef];
    return [eq(r, want) && parity === 0,
      `silent before the switch ${r[0]}, DPIDR ${hex(r[1])}, CTRL/STAT ${hex(r[2])}, AP IDR ${hex(r[3])}, posted ${hex(r[4])}, RDBUFF ${hex(r[5])}, parity errors ${parity}; ${ms} ms`];
  },
};

// Planted bug: a call CPython has and MicroPython does not, on the SWD
// driver's error path (the bug the board first found there).
const MUTANTS = {
  'cpython-only-call': [
    'raise SwdError("ACK %d%d%d (%s)" % (ack >> 2, (ack >> 1) & 1, ack & 1,',
    'raise SwdError("ACK %s (%s)" % (format(ack, "03b"),'],
};
const args = process.argv.slice(2);
const m = args.indexOf('--mutant');
const mutant = m < 0 ? null : args.splice(m, 2)[1];
const expectFail = args.includes('--expect-fail') ? (args.splice(args.indexOf('--expect-fail'), 1), true) : false;
const names = args.length ? args : Object.keys(SCENARIOS);
let driver = readFileSync(join(HERE, '..', '..', 'host', 'protocol_emulator.py'), 'latin1');
if (mutant) {
  const [from, to] = MUTANTS[mutant];
  if (!driver.includes(from)) throw new Error('mutant does not apply: ' + mutant);
  driver = driver.replace(from, to);
  console.log('with planted bug ' + mutant);
}
const wall = Date.now();
board = new Board(join(HERE, 'build', 'tt-demo-rp2040-v2.0.4.uf2'), { quantumNs: 40 });
board.boot();
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

let failed = 0;
for (const name of names) {
  const t = Date.now();
  let ok, msg;
  try {
    [ok, msg] = SCENARIOS[name]();
  } catch (err) {
    [ok, msg] = [false, String(err.message || err).slice(0, 600)];
  }
  if (!ok) failed++;
  console.log(`${ok ? 'PASS' : 'FAIL'} ${name.padEnd(10)} ${msg} [${((Date.now() - t) / 1000).toFixed(0)} s]`);
}
console.log(`${names.length - failed}/${names.length} passed; wall ${((Date.now() - wall) / 1000).toFixed(0)} s`);
process.exit(!!failed !== expectFail ? 1 : 0);
