// SPDX-FileCopyrightText: © 2026 Tave La Rocque
// SPDX-License-Identifier: Apache-2.0
//
// Devices on the chip's protocol pins, modelled in JavaScript for the
// board co-simulation (board.mjs; board.v's dev_mode). Each is
// { mode, pins, step(nowNs, outputs) -> pins }: board.mjs calls step at
// every hardware sync (40 ns apart at most) with the chip's outputs, and
// drives the returned pins.
//
// These are written for this project from the specifications (NXP UM10204
// for I2C; SPI mode 0; 8N1 UART), so they test the board driver's timing
// and logic, not the firmware's protocol correctness: that is the cocotb
// suite's job, against device models written by other people.

// outputs = uo_out | uio_out << 8 | uio_oe << 16 | SDA << 24 | SCL << 25
export const uioOut = (out, pin) => (out >> (8 + pin)) & 1;
export const uioOe = (out, pin) => (out >> (16 + pin)) & 1;
export const sdaLine = (out) => (out >> 24) & 1;
export const sclLine = (out) => (out >> 25) & 1;

// pins = SDA drive | SCL drive << 1 (1 = released) | UART RX << 2
//      | SPI SCLK << 3 | SPI MOSI << 4 | SPI CS_N << 5
const IDLE = 0b100111;

// A device run by a generator: it sets dev.pins and yields a number of
// nanoseconds to wait, or a predicate on the outputs to wait for. The
// generator's return value becomes dev.result.
export function scripted(mode, script) {
  const dev = { mode, pins: IDLE, done: false, result: undefined, now: 0, out: 0 };
  const gen = script(dev);
  let until = 0, cond = null;
  dev.step = (now, out) => {
    dev.now = now;
    dev.out = out;
    while (!dev.done) {
      if (cond) {
        if (!cond(out)) break;
        cond = null;
      }
      if (now < until) break;
      const r = gen.next();
      if (r.done) {
        dev.done = true;
        dev.result = r.value;
        break;
      }
      if (typeof r.value === 'number') until = now + r.value;
      else cond = r.value;
    }
    return dev.pins;
  };
  return dev;
}

// A UART receiver (8N1) on uio_out[pin], pulled up, [bitNs] a bit:
// collects bytes.
export function uartReceiver(bitNs, pin = 0) {
  const dev = { mode: 3, pins: IDLE, bytes: [], framingErrors: 0 };
  let state = 'idle', next = 0, bit = 0, value = 0, last = 1;
  dev.step = (now, out) => {
    const line = uioOe(out, pin) ? uioOut(out, pin) : 1; // pulled up while undriven
    if (state === 'idle') {
      if (last === 1 && line === 0) {
        state = 'data';
        next = now + 1.5 * bitNs; // the middle of data bit 0
        bit = 0;
        value = 0;
      }
    } else if (now >= next) {
      if (state === 'data') {
        value |= line << bit;
        bit++;
        next += bitNs;
        if (bit === 8) state = 'stop';
      } else {
        if (line !== 1) dev.framingErrors++;
        dev.bytes.push(value);
        state = 'idle';
      }
    }
    last = line;
    return dev.pins;
  };
  return dev;
}

// An I2C controller (UM10204, fast mode by default), honouring clock
// stretching. [ops]: { write: [addr, bytes] } or { read: [addr, n] }, run
// back to back with repeated STARTs, then STOP. Result: per op, the ACK
// bits seen (0 = ACK) and, for reads, the bytes.
export function i2cController(ops, { halfNs = 1250, stretchLimitNs = 50e6 } = {}) {
  return scripted(1, function* (dev) {
    const q = halfNs / 2;
    const set = (sda, scl) => { dev.pins = (dev.pins & ~3) | sda | (scl << 1); };
    const sda = () => dev.pins & 1, scl = () => (dev.pins >> 1) & 1;
    function* sclHigh() {
      set(sda(), 1);
      const start = dev.now;
      yield (out) => sclLine(out) === 1 || dev.now - start > stretchLimitNs;
      if (sclLine(dev.out) !== 1) throw new Error('SCL held low for ' + stretchLimitNs / 1e6 + ' ms');
    }
    function* bitOut(b) {
      set(b, 0);
      yield q;
      yield* sclHigh();
      yield halfNs;
      set(sda(), 0);
      yield q;
    }
    function* bitIn() {
      set(1, 0);
      yield q;
      yield* sclHigh();
      yield q;
      const b = sdaLine(dev.out);
      yield q;
      set(1, 0);
      yield q;
      return b;
    }
    function* byteOut(v) {
      for (let i = 7; i >= 0; i--) yield* bitOut((v >> i) & 1);
      return yield* bitIn();
    }
    function* byteIn(ack) {
      let v = 0;
      for (let i = 0; i < 8; i++) v = (v << 1) | (yield* bitIn());
      yield* bitOut(ack ? 0 : 1);
      return v;
    }
    const results = [];
    yield 5000; // bus free
    // START: SDA falls while SCL is high.
    set(1, 1);
    yield halfNs;
    for (let k = 0; k < ops.length; k++) {
      const op = ops[k];
      if (k > 0) {
        // Repeated START: SDA high, SCL high, then SDA falls.
        set(1, 0);
        yield q;
        yield* sclHigh();
        yield halfNs;
      }
      set(0, 1);
      yield halfNs;
      set(0, 0);
      yield q;
      if (op.write) {
        const [addr, bytes] = op.write;
        const acks = [yield* byteOut(addr << 1)];
        for (const b of bytes) acks.push(yield* byteOut(b));
        results.push({ acks });
      } else {
        const [addr, n] = op.read;
        const acks = [yield* byteOut((addr << 1) | 1)];
        const bytes = [];
        for (let i = 0; i < n; i++) bytes.push(yield* byteIn(i < n - 1));
        results.push({ acks, bytes });
      }
    }
    // STOP: SDA rises while SCL is high.
    set(0, 0);
    yield q;
    yield* sclHigh();
    yield halfNs;
    set(1, 1);
    yield 5000;
    return results;
  });
}

// An SPI controller, mode 0, MSB first, [halfNs] a phase: one transfer of
// [bytes] with CS_N low throughout; result: the bytes read on MISO
// (uio_out[2]).
export function spiController(bytes, { halfNs = 1000 } = {}) {
  return scripted(4, function* (dev) {
    const SCLK = 1 << 3, MOSI = 1 << 4, CS = 1 << 5;
    const set = (bit, v) => { dev.pins = v ? dev.pins | bit : dev.pins & ~bit; };
    yield 5000;
    set(CS, 0);
    yield halfNs;
    const got = [];
    for (const b of bytes) {
      let v = 0;
      for (let i = 7; i >= 0; i--) {
        set(MOSI, (b >> i) & 1);
        yield halfNs;
        set(SCLK, 1); // both ends sample
        v = (v << 1) | uioOut(dev.out, 2);
        yield halfNs;
        set(SCLK, 0);
      }
      got.push(v);
    }
    yield halfNs;
    set(CS, 1);
    set(MOSI, 1);
    yield 5000;
    return got;
  });
}
