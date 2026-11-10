// SPDX-FileCopyrightText: © 2026 Tave La Rocque
// SPDX-License-Identifier: Apache-2.0
//
// The Tiny Tapeout demo board (TT06 to TT08 layout, RP2040) in emulation:
// rp2040js runs Tiny Tapeout's own MicroPython firmware, and its pins are
// wired to the chip's RTL and its devices (cosim.node, from board.v).
//
// Time: rp2040js counts each instruction's ARMv6-M cycles at 125 MHz; the
// hardware runs on that same time line. Two things are added here that
// rp2040js leaves untimed:
//   - PIO. rp2040js steps its state machines from a timer, unrelated to
//     the CPU's time; here each state machine executes on its own clock
//     (system clock / CLKDIV), with each instruction's delay cycles.
//   - The pins. The hardware is advanced to the current time whenever a
//     pin it reads changes, and at least every [quantumNs] otherwise, so
//     the chip sees each input change at the instruction that made it and
//     the RP2040 reads outputs at most [quantumNs] old.

import { openSync, readSync, closeSync, writeFileSync } from 'fs';
import { createRequire } from 'module';
import { Simulator, USBCDC, ConsoleLogger, LogLevel } from 'rp2040js';
import { bootromB1 } from './build/bootrom.mjs';

const require = createRequire(import.meta.url);
export const hw = require('./cosim.node');

export const CPU_HZ = 125_000_000; // rp2040js's fixed core clock

// The TT06+ demo board's RP2040 pins (ttboard/pins/gpio_map.py, v2.0.4).
export const UI_IN = [9, 10, 11, 12, 17, 18, 19, 20];
export const UO_OUT = [5, 6, 7, 8, 13, 14, 15, 16];

function loadUF2(path, mcu) {
  const f = openSync(path, 'r');
  const b = Buffer.alloc(512);
  let n = 0;
  while (readSync(f, b, 0, 512, null) === 512) {
    if (b.readUInt32LE(0) !== 0x0a324655 || b.readUInt32LE(4) !== 0x9e5d5157) continue;
    const addr = b.readUInt32LE(12), size = b.readUInt32LE(16);
    if (addr >= 0x10000000 && addr < 0x11000000) {
      mcu.flash.set(b.subarray(32, 32 + size), addr - 0x10000000);
      n++;
    }
  }
  closeSync(f);
  if (!n) throw new Error('no flash blocks in ' + path);
}

export class Board {
  constructor(uf2, { quantumNs = 20, cpuSlowdown = 1, log = false } = {}) {
    this.cpuSlowdown = cpuSlowdown; // >1 makes only the CPU's instructions slower (a margin test)
    this.sim = new Simulator();
    const mcu = (this.mcu = this.sim.rp2040);
    mcu.loadBootrom(bootromB1);
    mcu.logger = new ConsoleLogger(LogLevel.Error);
    loadUF2(uf2, mcu);
    this.cdc = new USBCDC(mcu.usbCtrl);
    this.out = '';
    this.log = log;
    this.connected = false;
    this.cdc.onDeviceConnected = () => { this.connected = true; };
    this.cdc.onSerialData = (v) => {
      const s = Buffer.from(v).toString('latin1');
      this.out += s;
      if (this.log) process.stdout.write(s);
    };
    mcu.core.PC = 0x10000000;

    // PIO on its own clock (see the top of this file).
    for (const pio of mcu.pio) {
      pio.run = () => {}; // never free-run
      for (const sm of pio.machines) sm.nextNs = null;
    }

    // The hardware is off until [power].
    this.hwOn = false;
    this.quantumNs = quantumNs;
    this.pinsDirty = true;
    for (const g of UI_IN) mcu.gpio[g].addListener(() => { this.pinsDirty = true; });
  }

  // Power the hardware afresh, in reset: the chip at [chipHz]; the USB
  // device's 48 MHz clock only if [usb]; the SPI flash loaded from
  // [flashHex] ($readmemh format); [device], if given, a JavaScript model on
  // the protocol pins: { mode, pins, step(nowNs, outputs) -> pins }. From
  // now on the hardware runs with the CPU.
  power({ chipHz, devMode = 0, usb = false, flashHex = '', device = null }) {
    if (!flashHex) {
      flashHex = new URL('./build/empty.hex', import.meta.url).pathname;
      writeFileSync(flashHex, '');
    }
    hw.init(chipHz, usb ? 48e6 : 0, flashHex, this.nanos * 1000);
    this.rstN = 0;
    this.usbRst = 1;
    this.ui = -1;
    this.uo = -1;
    this.portDone = []; // [time (ns), 24-bit word] of each host-port transaction
    this.portWord = 0;
    this.device = device;
    this.devMode = devMode;
    this.devPins = device ? device.pins : 0x3f;
    this.out = hw.setDev(devMode, this.devPins);
    this.hwOn = true;
    this.pinsDirty = true;
    this.syncHw(this.nanos);
  }

  get nanos() { return this.sim.clock.nanos; }

  stepPio(now) {
    const cycleNs = 1e9 / CPU_HZ;
    for (const pio of this.mcu.pio) {
      let any = false;
      for (const sm of pio.machines) {
        if (!sm.enabled) { sm.nextNs = null; continue; }
        any = true;
        if (sm.nextNs === null) sm.nextNs = now;
        const period = (sm.clockDivInt + sm.clockDivFrac / 256 || 1) * cycleNs;
        while (sm.nextNs <= now) {
          const c0 = sm.cycles;
          sm.step();
          let dc = sm.cycles - c0;
          if (!(dc > 0)) dc = 1; // a stalled cycle
          sm.nextNs += dc * period;
        }
      }
      if (any) pio.checkChangedPins();
    }
  }

  readUi() {
    let v = 0;
    const g = this.mcu.gpio;
    for (let i = 0; i < 8; i++) {
      const p = g[UI_IN[i]];
      if (p.outputEnable && p.outputValue) v |= 1 << i;
    }
    return v;
  }

  syncHw(now) {
    const ps = now * 1000;
    let out = hw.advance(ps);
    if (this.device) {
      const pins = this.device.step(now, out);
      if (pins !== undefined && pins !== this.devPins) {
        this.devPins = pins;
        out = hw.setDev(this.devMode, pins);
      }
    }
    let uo = out & 0xff;
    if (this.pinsDirty) {
      this.pinsDirty = false;
      const ui = this.readUi();
      if (ui !== this.ui) {
        // The host port, decoded: SCK ui_in[0], CS_N [1], MOSI [2]; a
        // transaction ends where CS_N rises.
        if (this.ui >= 0) {
          if (!(this.ui & 1) && ui & 1 && !(ui & 2)) this.portWord = (this.portWord << 1 | (ui >> 2 & 1)) >>> 0;
          if (!(this.ui & 2) && ui & 2) { this.portDone.push([now, this.portWord & 0xffffff]); }
          if (this.ui & 2 && !(ui & 2)) this.portWord = 0;
        }
        this.ui = ui;
        out = hw.set(ui, this.rstN, this.usbRst);
        uo = out & 0xff;
      }
    }
    this.outputs = out;
    if (uo !== this.uo) {
      const changed = uo ^ (this.uo < 0 ? ~uo : this.uo);
      this.uo = uo;
      for (let i = 0; i < 8; i++) {
        if (changed & (1 << i)) this.mcu.gpio[UO_OUT[i]].setInputValue(!!(uo & (1 << i)));
      }
    }
    this.lastSyncNs = now;
  }

  // Put a JavaScript device model on the protocol pins (devices.mjs).
  attachDevice(device) {
    this.syncHw(this.nanos);
    this.device = device;
    this.devMode = device.mode;
    this.devPins = device.pins;
    this.outputs = hw.setDev(this.devMode, this.devPins);
  }

  setResets({ rstN = this.rstN, usbRst = this.usbRst }) {
    this.syncHw(this.nanos);
    this.rstN = rstN;
    this.usbRst = usbRst;
    this.ui = this.readUi();
    hw.set(this.ui, rstN, usbRst);
  }

  // Run until [pred] holds (checked every few thousand instructions) or
  // [maxNs] of emulated time pass.
  run(pred, maxNs) {
    const { mcu } = this;
    const clock = this.sim.clock;
    const cycleNs = 1e9 / CPU_HZ;
    const end = clock.nanos + maxNs;
    let k = 0;
    while (clock.nanos < end) {
      if (mcu.core.waiting) {
        // Sleep to the next alarm, but not past the next quantum while the
        // hardware or PIO is running.
        let dt = Math.min(clock.nanosToNextAlarm, end - clock.nanos);
        if (this.hwOn) dt = Math.min(dt, this.quantumNs);
        clock.tick(Math.max(dt, cycleNs));
      } else {
        clock.tick(mcu.core.executeInstruction() * cycleNs * this.cpuSlowdown);
      }
      const now = clock.nanos;
      this.stepPio(now);
      if (this.hwOn && (this.pinsDirty || now - this.lastSyncNs >= this.quantumNs)) this.syncHw(now);
      if ((++k & 0xfff) === 0 && pred && pred()) return true;
    }
    return pred ? pred() : false;
  }

  send(s) { for (const ch of Buffer.from(s, 'latin1')) this.cdc.sendSerialByte(ch); }

  // Execute code through MicroPython's raw-paste mode, which has flow
  // control, so a slow CPU loses nothing; returns [stdout, stderr].
  exec(code, maxNs = 60e9) {
    this.out = '';
    this.send('\x01');
    if (!this.run(() => this.out.includes('raw REPL; CTRL-B to exit\r\n>'), 5e9))
      throw new Error('no raw REPL: ' + JSON.stringify(this.out.slice(-300)));
    this.out = '';
    this.send('\x05A\x01');
    if (!this.run(() => this.out.length >= 4, 5e9) || !this.out.startsWith('R\x01'))
      throw new Error('no raw-paste mode: ' + JSON.stringify(this.out));
    const inc = this.out.charCodeAt(2) | (this.out.charCodeAt(3) << 8);
    let window = inc, seen = 4, i = 0;
    while (i < code.length) {
      // Each 0x01 from the device grants another window of bytes.
      for (; seen < this.out.length; seen++) {
        if (this.out.charCodeAt(seen) === 1) window += inc;
        else if (this.out.charCodeAt(seen) === 4) throw new Error('paste aborted');
      }
      if (window > 0) {
        const n = Math.min(window, code.length - i, 32);
        this.send(code.slice(i, i + n));
        i += n;
        window -= n;
        this.run(null, 50e3);
      } else if (!this.run(() => this.out.length > seen, 5e9)) {
        throw new Error('raw-paste stalled at byte ' + i);
      }
    }
    this.send('\x04');
    // The device acknowledges the end with 0x04, then runs the code: stdout,
    // 0x04, stderr, 0x04.
    const ack = () => this.out.indexOf('\x04', seen);
    if (!this.run(() => ack() >= 0 && (this.out.slice(ack() + 1).match(/\x04/g) || []).length >= 2, maxNs))
      throw new Error('timeout: ' + JSON.stringify(this.out.slice(-500)));
    const m = this.out.slice(ack() + 1).match(/^([\s\S]*?)\x04([\s\S]*?)\x04/);
    return [m[1], m[2]];
  }

  // Boot, and stop main.py if it is still running. Wait for main.py to end
  // first (here it stops at its first write to the emulated flash, the boot
  // log): interrupted in the middle of an import, it leaves the SDK's
  // modules half loaded, and a later import of them fails.
  boot() {
    if (!this.run(() => this.connected, 10e9)) throw new Error('USB never connected');
    this.run(() => this.out.includes('>>> '), 20e9);
    this.send('\x03\x03');
    this.run(() => this.out.includes('>>> '), 5e9);
  }
}
