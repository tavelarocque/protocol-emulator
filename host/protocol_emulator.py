# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
"""Host driver for the protocol emulator chip.

Runs on the Tiny Tapeout demo board's RP2040 under MicroPython, and under
CPython, where the cocotb testbench (test/test.py, "host driver" tests) runs
this same file against the RTL and the gate-level netlist. It uses nothing
beyond the core language, so the code tested is the code that ships.

The chip's host port is SPI mode 0 on ui_in[0] (SCK), ui_in[1] (CS_N) and
ui_in[2] (MOSI), with MISO on uo_out[0]; every transaction is 24 bits:
write flag, 7-bit register address, 16 data bits. The register map is in
hw/top.ml. Each SCK phase must last at least 4 core clocks, which bit-banging
from MicroPython always does.

On the demo board::

    from ttboard.demoboard import DemoBoard
    import protocol_emulator as pe

    tt = DemoBoard.get()
    tt.shuttle.tt_um_tavelarocque_protocol_emulator.enable()
    tt.clock_project_PWM(10_000_000)
    chip = pe.Chip(pe.demo_board_port())
    uart = pe.UartTx(chip, pe.load_hex("uart_tx.hex"), divisor=87)  # 115200 baud
    uart.write(b"hello")
"""

# --- Register map (hw/top.ml) ------------------------------------------------

CTRL = 0x40
PIN_MODES = 0x47
SYNC_BYPASS = 0x4E
START = 0x41
OUT_CFG = 0x42
SET_CFG = 0x43
IN_BASE = 0x44
THRESHOLD = 0x45
TIMEOUT_VECTOR = 0x46
TX_FIFO = 0x48
RX_FIFO = 0x49
STATUS = 0x4A
TIMEOUT = 0x4B
SIDESET = 0x4C
CLKDIV = 0x4D
SHIFT = 0x4F
BANK = 0x10  # thread 1's registers are thread 0's plus this
FIFO_DEPTH = 4
PROGRAM_WORDS = 64

INPUT, PUSH_PULL, OPEN_DRAIN = 0, 1, 2

# Firmware constants (model/firmware.ml; the OCaml tests check them).
I2C_STUCK = 18  # Firmware.i2c_stuck
I2C_TARGET_REST = 57  # Firmware.i2c_target_rest
SPI_TARGET_DESEL = 16  # Firmware.spi_target_desel


def rev8(b):
    """Reverse the bits of a byte (for firmware that shifts LSB first)."""
    r = 0
    for i in range(8):
        r |= ((b >> i) & 1) << (7 - i)
    return r


def load_hex(path):
    """A firmware image from a .hex file (one 16-bit word per line), as
    built by dune into test/."""
    with open(path) as f:
        return [int(line, 16) for line in f if line.strip()]


# --- Transports --------------------------------------------------------------


class BitBangPort:
    """The host port, bit-banged. [set_pins(sck, cs_n, mosi)] drives the
    three inputs (and on a simulator waits for them to be seen);
    [read_miso()] returns MISO."""

    def __init__(self, set_pins, read_miso):
        self.set_pins = set_pins
        self.read_miso = read_miso

    def transfer(self, word):
        """One 24-bit transaction, MSB first. Data changes while SCK is low;
        both sides sample on the rising edge. Returns the 16 bits read."""
        set_pins, read_miso = self.set_pins, self.read_miso
        set_pins(0, 0, 0)
        got = 0
        for b in range(23, -1, -1):
            mosi = (word >> b) & 1
            set_pins(0, 0, mosi)
            if b < 16:
                got = (got << 1) | read_miso()
            set_pins(1, 0, mosi)
        set_pins(0, 0, 0)
        set_pins(0, 1, 0)
        return got


def demo_board_port():
    """The port on the Tiny Tapeout demo board, through the RP2040's direct
    pin access (the demo board must be in ASIC_RP_CONTROL mode)."""
    import ttboard.util.platform as platform  # only exists on the board

    def set_pins(sck, cs_n, mosi):
        platform.write_ui_in_byte(sck | (cs_n << 1) | (mosi << 2))

    def read_miso():
        return platform.read_uo_out_byte() & 1

    return BitBangPort(set_pins, read_miso)


# --- The chip ----------------------------------------------------------------


class Chip:
    def __init__(self, port):
        self.port = port

    def write(self, addr, data):
        self.port.transfer((1 << 23) | (addr << 16) | (data & 0xFFFF))

    def read(self, addr):
        return self.port.transfer(addr << 16) & 0xFFFF

    def stop(self):
        """Disable both threads (they return to their start state)."""
        self.write(CTRL, 0)

    def load(self, words, origin=0):
        """Write a firmware image into program memory at [origin]."""
        if origin + len(words) > PROGRAM_WORDS:
            raise ValueError("image does not fit in program memory")
        for i, w in enumerate(words):
            self.write(origin + i, w)

    def configure(self, thread=0, start=0, out_base=0, out_count=1, set_base=0,
                  set_count=1, in_base=0, threshold=8, timeout_vector=0, timeout=0,
                  sideset_base=0, sideset_count=0, clkdiv=0, out_msb_first=False,
                  in_msb_first=False):
        """Write every field of a thread's configuration. The defaults are
        the reset values."""
        bank = BANK * thread
        self.write(START + bank, start)
        self.write(OUT_CFG + bank, out_base | (out_count << 4))
        self.write(SET_CFG + bank, set_base | (set_count << 4))
        self.write(IN_BASE + bank, in_base)
        self.write(THRESHOLD + bank, threshold)
        self.write(TIMEOUT_VECTOR + bank, timeout_vector)
        self.write(TIMEOUT + bank, timeout)
        self.write(SIDESET + bank, sideset_base | (sideset_count << 4))
        self.write(CLKDIV + bank, clkdiv)
        self.write(SHIFT + bank, int(out_msb_first) | (int(in_msb_first) << 1))

    def set_pin_modes(self, modes):
        """[modes] maps pin number to INPUT, PUSH_PULL or OPEN_DRAIN; pins not
        named are inputs."""
        v = 0
        for pin, mode in modes.items():
            v |= mode << (2 * pin)
        self.write(PIN_MODES, v)

    def set_sync_bypass(self, pins):
        """Pins read without the 2-flop input synchroniser."""
        v = 0
        for pin in pins:
            v |= 1 << pin
        self.write(SYNC_BYPASS, v)

    def run(self, threads=(0,), chain=False):
        """Enable the given threads together (one CTRL write)."""
        v = 4 if chain else 0
        for t in threads:
            v |= 1 << t
        self.write(CTRL, v)

    def status(self, thread=0):
        s = self.read(STATUS + BANK * thread)
        return {"pc": (s >> 8) & 0x3F, "enabled": bool(s & 0x80),
                "rx_level": (s >> 4) & 7, "tx_level": s & 7}

    def push(self, value, thread=0):
        """Queue a word on a thread's TX FIFO, waiting while it is full."""
        while self.read(STATUS + BANK * thread) & 7 >= FIFO_DEPTH:
            pass
        self.write(TX_FIFO + BANK * thread, value)

    def pop(self, thread=0):
        """Take a word from a thread's RX FIFO, waiting while it is empty."""
        while (self.read(STATUS + BANK * thread) >> 4) & 7 == 0:
            pass
        return self.read(RX_FIFO + BANK * thread)

    def try_pop(self, thread=0):
        """A word from the RX FIFO, or None if it is empty."""
        if (self.read(STATUS + BANK * thread) >> 4) & 7 == 0:
            return None
        return self.read(RX_FIFO + BANK * thread)


# --- Protocols ----------------------------------------------------------------
#
# Each takes the image built from model/firmware.ml (test/<name>.hex), loads
# it, configures one thread and starts it. One protocol per thread; two can
# run at once from one image (see docs/info.md).


class UartTx:
    """8N1 transmitter on [pin] (uart_tx.hex). [divisor] = core clocks per
    bit, at least 4: 87 for 115200 baud at 10 MHz."""

    def __init__(self, chip, image, divisor, pin=0):
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(out_base=pin, set_base=pin)
        chip.set_pin_modes({pin: PUSH_PULL})
        chip.run()
        chip.push(divisor - 4)

    def write(self, data):
        for b in data:
            self.chip.push(b)


class SpiController:
    """Mode-0 SPI controller at core clock / 2 (spi_fast.hex): P0 SCK, P1
    MOSI, P2 MISO, P3 CS_N. Plain bytes both ways (SHIFT MSB first)."""

    def __init__(self, chip, image):
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(sideset_base=0, sideset_count=1, out_base=1, out_count=3,
                       in_base=2, out_msb_first=True, in_msb_first=True)
        chip.set_pin_modes({0: PUSH_PULL, 1: PUSH_PULL, 3: PUSH_PULL})
        chip.set_sync_bypass([2])  # MISO is sampled one clock after SCK falls
        chip.run()

    def transfer(self, data):
        """One selection: send [data], return the bytes read back."""
        n = len(data)
        out = []
        # At most FIFO_DEPTH words in flight, so the replies never back up.
        for i, b in enumerate(data):
            self.chip.push((b << 8) | (int(i == n - 1) << 7))
            if i >= FIFO_DEPTH - 1:
                out.append(self.chip.pop())
        while len(out) < n:
            out.append(self.chip.pop())
        return out


class I2cDevice:
    """The chip as an I2C device at [address] (i2c_target.hex): P0 SDA, P1
    SCL, open-drain. [replies] queue bytes for the controller to read;
    [events] returns what arrived: ("start", read?) markers and written
    bytes."""

    def __init__(self, chip, image, address):
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(set_base=0, out_base=0, in_base=0, sideset_base=1,
                       sideset_count=1, threshold=8, timeout=0,
                       timeout_vector=I2C_TARGET_REST, in_msb_first=True)
        chip.set_pin_modes({0: OPEN_DRAIN, 1: OPEN_DRAIN})
        chip.run()
        chip.push(address)

    def reply(self, data):
        for b in data:
            self.chip.push(rev8(b))

    def events(self):
        got = []
        while True:
            w = self.chip.try_pop()
            if w is None:
                return got
            got.append(("start", bool((w >> 8) & 1)) if w >= 0x100 else w)


class JtagController:
    """JTAG controller (jtag.hex): P0 TCK, P1 TMS, P2 TDI, P3 TDO. TCK runs
    at core clock / (5 x clkdiv), 2 MHz at 10 MHz with clkdiv 0 or 1."""

    def __init__(self, chip, image, clkdiv=0):
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(sideset_base=0, sideset_count=1, out_base=1, out_count=2,
                       in_base=3, threshold=16, clkdiv=clkdiv)
        chip.set_pin_modes({0: PUSH_PULL, 1: PUSH_PULL, 2: PUSH_PULL})
        chip.run()

    def scan(self, tms, tdi):
        """Clock len(tms) times with the given TMS and TDI bits; return the
        TDO bit sampled before each rising edge."""
        n = len(tms)
        words = []
        for start in range(0, n, 8):
            w = 0
            for k in range(min(8, n - start)):
                w |= (tms[start + k] & 1) << (2 * k)
                w |= (tdi[start + k] & 1) << (2 * k + 1)
            words.append(w)
        got = []
        self.chip.push(n - 1)
        for w in words:
            self.chip.push(w)
            r = self.chip.try_pop()  # keep RX draining so neither FIFO jams
            if r is not None:
                got.append(r)
        while len(got) < len(words):
            got.append(self.chip.pop())
        tdo = []
        for i, w in enumerate(got):
            for k in range(min(8, n - 8 * i)):
                tdo.append((w >> k) & 1)
        return tdo

    def reset(self):
        """Five clocks with TMS high reach Test-Logic-Reset from any state;
        one more with TMS low parks the TAP in Run-Test/Idle."""
        self.scan([1, 1, 1, 1, 1, 0], [0] * 6)

    def _shift(self, prefix, value, n):
        bits = [(value >> i) & 1 for i in range(n)]
        tms = prefix + [0] * (n - 1) + [1] + [1, 0]  # last bit exits; update; idle
        tdi = [0] * len(prefix) + bits + [0, 0]
        tdo = self.scan(tms, tdi)[len(prefix):len(prefix) + n]
        return sum(b << i for i, b in enumerate(tdo))

    def shift_ir(self, value, n):
        """From Run-Test/Idle: shift an n-bit instruction in (LSB first),
        return what the IR captured, end in Run-Test/Idle."""
        return self._shift([1, 1, 0, 0], value, n)

    def shift_dr(self, value, n):
        """From Run-Test/Idle: shift n bits through the selected data
        register, return what it held, end in Run-Test/Idle."""
        return self._shift([1, 0, 0], value, n)


class SpiDevice:
    """The chip as a mode-0 SPI device (spi_target.hex): P0 SCK, P1 MOSI,
    P2 MISO, P3 CS_N. The host must keep replies queued ahead of the
    controller: one per byte it will clock."""

    END = 0x100  # Firmware.spi_target_end_marker

    def __init__(self, chip, image):
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(in_base=1, out_base=2, out_count=1, threshold=8, timeout=0,
                       timeout_vector=SPI_TARGET_DESEL, in_msb_first=True)
        chip.set_pin_modes({2: PUSH_PULL})
        chip.run()
        self._current = []

    def reply(self, data):
        for b in data:
            self.chip.push(rev8(b))

    def transfers(self):
        """Transfers completed since the last call, each a list of the bytes
        received. Bytes of a transfer still in progress are kept for the
        next call."""
        done = []
        while True:
            w = self.chip.try_pop()
            if w is None:
                return done
            if w == self.END:
                done.append(self._current)
                self._current = []
            else:
                self._current.append(w)
