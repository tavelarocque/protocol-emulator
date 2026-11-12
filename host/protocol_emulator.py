# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
"""Host driver for the protocol emulator chip.

Runs on the Tiny Tapeout demo board (RP2040 or RP2350) under MicroPython,
and under CPython, where the cocotb testbench (test/test.py, "host driver"
tests) runs this same file against the RTL and the gate-level netlist. It uses nothing
beyond the core language, so the code tested is the code that ships;
test/board_emu runs it in MicroPython on an emulated demo board too, which
is how two CPython-only calls (int.bit_length, format) were found.

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

The USB host needs the port driven by PIO instead (see UsbHost)::

    tt.clock_project_PWM(12_000_000)
    usb = pe.UsbHost(pe.Chip(pe.PioPort()), pe.load_hex("usb_host.hex"))
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

    def transfer_many(self, words):
        """Several transactions back to back; returns what each read."""
        return [self.transfer(w) for w in words]


def board_host_pins():
    """The GPIOs of the host port on the demo board in use, as (SCK, MISO):
    ui_in[0] and uo_out[0] in the Tiny Tapeout SDK's pin map, which the SDK
    sets when it detects the board. CS_N and MOSI are the two GPIOs after
    SCK on every board.

    - RP2040 boards (TT06 to TT08, SDK v2): SCK on GPIO 9, MISO on GPIO 5.
    - RP2350 board (demo board v3, for the IHP shuttles, SDK v3): SCK on
      GPIO 17, MISO on GPIO 33."""
    import ttboard.pins.gpio_map as gpio_map  # only exists on the board
    m = gpio_map.GPIOMap
    if (m.UI_IN1, m.UI_IN2) != (m.UI_IN0 + 1, m.UI_IN0 + 2):
        raise RuntimeError("ui_in[0] to [2] are not consecutive GPIOs on this board")
    return m.UI_IN0, m.UO_OUT0


class PioPort:
    """The host port driven by one of the RP2040's or RP2350's PIO state
    machines, so a batch of transactions goes out at a fixed pace however
    slow MicroPython is: SCK, CS_N and MOSI on [sck_pin] and the two pins
    after it (ui_in[0] to [2]), MISO on [miso_pin] (uo_out[0]). By default
    the pins come from the SDK's map of the board in use (board_host_pins).

    The state machine runs at the system clock divided by the whole number
    nearest 12.5 MHz, so its cycles never jitter: 12.5 MHz at 125 or 150
    MHz, 12 MHz at the 120 MHz the SDK sets for a 10 or 12 MHz project
    clock. Create the port after clock_project_PWM, which can change the
    system clock. At 12.5 MHz and a 12 MHz core clock, every SCK phase lasts
    at least 4.8 core clocks, against the 4 the chip needs; a read's low
    phases last 7 (6.7 clocks) because MISO moves a few clocks after SCK
    falls, as the cocotb tests give it 6. A write takes 21 us, a read 25 us;
    at 12 MHz everything is 4% longer.

    On the RP2350B, PIO reaches 32 GPIOs at a time (0 to 31 or 16 to 47);
    MISO on GPIO 33 needs the upper window, which this selects for the
    state machine's PIO block. MicroPython only."""

    def __init__(self, sck_pin=None, miso_pin=None, sm_id=0, pio_hz=None):
        import machine
        import rp2
        from machine import Pin

        if sck_pin is None or miso_pin is None:
            sck_pin, miso_pin = board_host_pins()
        if pio_hz is None:
            sys_hz = machine.freq()
            pio_hz = sys_hz // max(1, (sys_hz + 6_250_000) // 12_500_000)
        if max(sck_pin + 2, miso_pin) >= 32:
            if min(sck_pin, miso_pin) < 16:
                raise ValueError("host port pins span more than one PIO window")
            rp2.PIO(sm_id // 4).gpio_base(Pin(16))

        @rp2.asm_pio(out_init=rp2.PIO.OUT_LOW,
                     sideset_init=(rp2.PIO.OUT_LOW, rp2.PIO.OUT_HIGH),
                     out_shiftdir=rp2.PIO.SHIFT_LEFT,
                     in_shiftdir=rp2.PIO.SHIFT_LEFT)
        def spi24():
            # Each word: bit 31 set for a read, then the 24 bits to send.
            # Side-set bit 0 is SCK, bit 1 CS_N.
            pull()                .side(0b10)      # idle: CS_N high, SCK low
            out(y, 1)             .side(0b10)      # y: a read?
            set(x, 23)            .side(0b00) [4]  # select
            jmp(not_y, "wbit")    .side(0b00)
            label("rbit")                          # a read: 7 cycles low, 5 high
            out(pins, 1)          .side(0b00) [6]  # MOSI changes while SCK is low
            in_(pins, 1)          .side(0b01) [3]  # SCK rises: both ends sample
            jmp(x_dec, "rbit")    .side(0b01)
            jmp("end")            .side(0b00) [4]
            label("wbit")                          # a write: 5 cycles low, 5 high
            out(pins, 1)          .side(0b00) [4]
            jmp(x_dec, "wbit")    .side(0b01) [4]
            nop()                 .side(0b00) [4]
            label("end")
            push()                .side(0b10) [7]  # deselect: CS_N high 10 cycles

        self.pio_hz = pio_hz
        self.sm = rp2.StateMachine(sm_id, spi24, freq=pio_hz, sideset_base=Pin(sck_pin),
                                   out_base=Pin(sck_pin + 2), in_base=Pin(miso_pin))
        self.sm.active(1)

    def transfer(self, word):
        return self.transfer_many([word])[0]

    def transfer_many(self, words):
        """Runs the transactions back to back at the state machine's pace,
        not MicroPython's: a batch of up to 4 is queued with the state
        machine stopped (between transactions, so nothing is cut), then
        started. Returns the 16 bits each read (0 for a write)."""
        sm = self.sm
        vals = [w if w & (1 << 23) else w | (1 << 24) for w in words]  # bit 24: a read
        got = []
        for start in range(0, len(vals), 4):
            batch = vals[start:start + 4]
            sm.active(0)
            for v in batch:
                sm.put(v, 7)  # shifted in C: bit 31 is past a small int
            sm.active(1)
            for _ in batch:
                got.append(sm.get() & 0xFFFF)
        return got


def demo_board_port():
    """The port on the Tiny Tapeout demo board, through the SDK's direct pin
    access on either board, RP2040 or RP2350 (the demo board must be in
    ASIC_RP_CONTROL mode). Too slow for the USB host (see UsbHost); PioPort
    is not."""
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

    def write_many(self, writes):
        """[(addr, data), ...] back to back, as one batch on the port."""
        self.port.transfer_many([(1 << 23) | (a << 16) | (d & 0xFFFF) for a, d in writes])

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

    @staticmethod
    def ctrl(threads=(0,), chain=False):
        """The CTRL value that enables [threads] (and CHAIN)."""
        v = 4 if chain else 0
        for t in threads:
            v |= 1 << t
        return v

    def run(self, threads=(0,), chain=False):
        """Enable the given threads together (one CTRL write)."""
        self.write(CTRL, self.ctrl(threads, chain))

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


class SwdError(Exception):
    pass


class SwdController:
    """Arm Serial Wire Debug host (swd.hex does the clocking): P0 SWCLK, P1
    SWDIO, open-drain, which needs a pull-up (most targets have one). The SWD
    framing is here: line reset, the JTAG-to-SWD switch, requests, parity,
    ACK and turnaround. Register addresses are byte addresses 0x0, 0x4, 0x8,
    0xC, as in Arm's documentation."""

    DPIDR, CTRL_STAT, SELECT, RDBUFF = 0x0, 0x4, 0x8, 0xC

    def __init__(self, chip, image, clkdiv=0):
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(sideset_base=0, sideset_count=1, out_base=1, out_count=1,
                       in_base=1, threshold=16, clkdiv=clkdiv)
        chip.set_pin_modes({0: PUSH_PULL, 1: OPEN_DRAIN})
        chip.run()

    def clock(self, bits):
        """One clock per bit (1 releases SWDIO); returns SWDIO as sampled
        just before each rising edge."""
        n = len(bits)
        words = []
        for start in range(0, n, 16):
            w = 0
            for k in range(min(16, n - start)):
                w |= (bits[start + k] & 1) << k
            words.append(w)
        got = []
        self.chip.push(n - 1)
        for w in words:
            self.chip.push(w)
            r = self.chip.try_pop()
            if r is not None:
                got.append(r)
        while len(got) < len(words):
            got.append(self.chip.pop())
        out = []
        for i, w in enumerate(got):
            for k in range(min(16, n - 16 * i)):
                out.append((w >> k) & 1)
        return out

    def connect(self):
        """Line reset, the JTAG-to-SWD select sequence 0xE79E, line reset,
        idle, then read DPIDR (which ADIv5 requires first). Returns DPIDR."""
        select = [(0xE79E >> i) & 1 for i in range(16)]
        self.clock([1] * 56 + select + [1] * 56 + [0] * 4)
        return self.read_dp(self.DPIDR)

    @staticmethod
    def _request(apndp, rnw, addr):
        a2, a3 = (addr >> 2) & 1, (addr >> 3) & 1
        return [1, apndp, rnw, a2, a3, apndp ^ rnw ^ a2 ^ a3, 0, 1]

    def _transfer(self, apndp, rnw, addr, value=0):
        req = self._request(apndp, rnw, addr)
        if rnw:  # request, turnaround, ACK, data and parity, turnaround, idle
            bits = req + [1] + [1] * 3 + [1] * 33 + [1] + [0, 0]
        else:  # request, turnaround, ACK, turnaround, data and parity, idle
            data = [(value >> i) & 1 for i in range(32)]
            parity = sum(data) & 1
            bits = req + [1] + [1] * 3 + [1] + data + [parity] + [0, 0]
        s = self.clock(bits)
        ack = s[9] | (s[10] << 1) | (s[11] << 2)
        if ack != 0b001:
            raise SwdError("ACK %d%d%d (%s)" % (ack >> 2, (ack >> 1) & 1, ack & 1,
                           {0b010: "WAIT", 0b100: "FAULT", 0b111: "no response"}.get(ack, "?")))
        if not rnw:
            return None
        v = sum(s[12 + i] << i for i in range(32))
        if (sum(s[12:44]) & 1) != s[44]:
            raise SwdError("read data parity error")
        return v

    def read_dp(self, addr):
        return self._transfer(0, 1, addr)

    def write_dp(self, addr, value):
        self._transfer(0, 0, addr, value)

    def read_ap(self, addr):
        """Posted, as in ADIv5: returns the previous AP read's result; this
        read's result is in RDBUFF (see read_ap_now)."""
        return self._transfer(1, 1, addr)

    def write_ap(self, addr, value):
        self._transfer(1, 0, addr, value)

    def read_ap_now(self, addr):
        self.read_ap(addr)
        return self.read_dp(self.RDBUFF)


class OneWireError(Exception):
    pass


def onewire_crc8(data):
    """The 1-Wire CRC8 (x^8 + x^5 + x^4 + 1, least significant bit first), as
    in ROM codes and DS18B20 scratchpads. Over data that ends in its own CRC
    it is 0."""
    crc = 0
    for b in data:
        for _ in range(8):
            mix = (crc ^ b) & 1
            crc >>= 1
            if mix:
                crc ^= 0x8C
            b >>= 1
    return crc


class OneWire:
    """1-Wire bus host at standard speed (onewire.hex does the timing): DQ on
    P0, open-drain, which needs a pull-up (4.7 kohm is usual). The rest of
    1-Wire is here: reset and presence, bytes least significant bit first,
    the ROM commands, the ROM search (Maxim application note 187) and CRC8.
    [clock_hz] is the core clock; the engine counts in microseconds."""

    READ_ROM, MATCH_ROM, SEARCH_ROM, SKIP_ROM = 0x33, 0x55, 0xF0, 0xCC
    CONVERT_T, READ_SCRATCHPAD = 0x44, 0xBE  # DS18B20 function commands

    def __init__(self, chip, image, clock_hz=10_000_000):
        if clock_hz <= 0 or clock_hz % 1_000_000:
            raise ValueError("the core clock must be a whole number of MHz")
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(set_base=0, out_base=0, in_base=0, threshold=16,
                       clkdiv=clock_hz // 1_000_000)
        chip.set_pin_modes({0: OPEN_DRAIN})
        chip.run()

    def reset(self):
        """A reset pulse. True if any device answered with a presence pulse."""
        self.chip.push(1)
        return (self.chip.pop() & 1) == 0

    def slots(self, bits):
        """One time slot per bit, writing it (a 1 releases the line, so
        writing 1s is how the host reads). Returns the line as sampled in
        each slot: the bit written, ANDed with whatever devices sent."""
        out = []
        for start in range(0, len(bits), 8):
            chunk = bits[start:start + 8]
            w = (len(chunk) - 1) << 1
            for k in range(len(chunk)):
                w |= (chunk[k] & 1) << (4 + k)
            self.chip.push(w)
            r = self.chip.pop()
            for k in range(len(chunk)):
                out.append((r >> k) & 1)
        return out

    def write(self, data):
        bits = []
        for b in data:
            for k in range(8):
                bits.append((b >> k) & 1)
        self.slots(bits)

    def read(self, n):
        got = self.slots([1] * (8 * n))
        return bytes([sum(got[8 * i + k] << k for k in range(8)) for i in range(n)])

    def _reset_or_raise(self):
        if not self.reset():
            raise OneWireError("no presence pulse")

    def read_rom(self):
        """The ROM code of the only device on the bus (READ ROM): family
        code, 48-bit serial number, CRC8."""
        self._reset_or_raise()
        self.write([self.READ_ROM])
        rom = self.read(8)
        if onewire_crc8(rom) != 0:
            raise OneWireError("ROM code CRC error")
        return rom

    def select(self, rom=None):
        """Reset, then address one device by its ROM code (MATCH ROM), or
        every device at once if [rom] is None (SKIP ROM)."""
        self._reset_or_raise()
        if rom is None:
            self.write([self.SKIP_ROM])
        else:
            self.write([self.MATCH_ROM] + list(rom))

    def search(self):
        """The ROM codes of every device on the bus (SEARCH ROM). Each pass
        walks the 64 bits: every device still in the search sends its bit
        and then the bit's complement, and the host writes the direction it
        takes. Two 0s mean the devices disagree there; the host takes 0 on
        the first pass and revisits the last such bit on the next."""
        roms = []
        rom = [0] * 64
        last = -1  # the bit where the previous pass took 0 at a disagreement
        while True:
            if not self.reset():
                return roms
            self.write([self.SEARCH_ROM])
            fork = -1
            for i in range(64):
                bit, cmp = self.slots([1, 1])
                if bit and cmp:
                    raise OneWireError("no device answered the search at bit %d" % i)
                if bit != cmp:
                    d = bit
                else:
                    d = rom[i] if i < last else int(i == last)
                    if d == 0:
                        fork = i
                rom[i] = d
                self.slots([d])
            code = bytes([sum(rom[8 * j + k] << k for k in range(8)) for j in range(8)])
            if onewire_crc8(code) != 0:
                raise OneWireError("ROM code CRC error in the search")
            roms.append(code)
            last = fork
            if last < 0:
                return roms

    def ds18b20_temperature(self, rom=None, polls=100000):
        """Start a DS18B20 conversion, wait for it (the device reads 0 while
        busy), then read the scratchpad. Returns degrees Celsius."""
        self.select(rom)
        self.write([self.CONVERT_T])
        for _ in range(polls):
            if self.slots([1])[0]:
                break
        else:
            raise OneWireError("conversion never finished")
        self.select(rom)
        self.write([self.READ_SCRATCHPAD])
        pad = self.read(9)
        if onewire_crc8(pad) != 0:
            raise OneWireError("scratchpad CRC error")
        raw = pad[0] | (pad[1] << 8)
        if raw & 0x8000:
            raw -= 0x10000
        return raw / 16


class Ps2Error(Exception):
    pass


class Ps2:
    """PS/2 host for a keyboard or mouse (ps2.hex: the receiver on thread 0,
    the transmitter on thread 1): DATA on P0 and CLK on P1, both open-drain,
    each needing a pull-up to the device's supply through a level shifter if
    that is 5 V. P2 is used between the threads and must be left unconnected.
    [clock_hz] is the core clock; the firmware counts in microseconds."""

    RX_WORDS = 11        # the receiver's length: the transmitter follows it
    RX_ABANDON = 9
    TX_DEAD = 16
    ACK, RESEND = 0xFA, 0xFE

    def __init__(self, chip, image, clock_hz=10_000_000):
        if clock_hz <= 0 or clock_hz % 1_000_000:
            raise ValueError("the core clock must be a whole number of MHz")
        mhz = clock_hz // 1_000_000
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(thread=0, start=0, in_base=0, threshold=11, timeout=150,
                       timeout_vector=self.RX_ABANDON, sideset_base=2,
                       sideset_count=1, clkdiv=mhz)
        chip.configure(thread=1, start=self.RX_WORDS, set_base=0, set_count=2,
                       out_base=0, out_count=1, in_base=0, threshold=10,
                       timeout=20_000, timeout_vector=self.RX_WORDS + self.TX_DEAD,
                       clkdiv=mhz)
        chip.set_pin_modes({0: OPEN_DRAIN, 1: OPEN_DRAIN, 2: PUSH_PULL})
        chip.run(threads=(0, 1))

    @staticmethod
    def _odd_parity(byte):
        ones = 0
        for k in range(8):
            ones += (byte >> k) & 1
        return 1 - (ones & 1)

    @classmethod
    def decode(cls, word):
        """The byte in a frame word from the receiver, or None if the start
        bit, parity or stop bit is wrong."""
        byte = (word >> 1) & 0xFF
        if (word & 1) or not (word >> 10) & 1 or (word >> 9) & 1 != cls._odd_parity(byte):
            return None
        return byte

    def read(self):
        """The next byte from the device, or None if none has arrived. A
        badly framed byte raises Ps2Error."""
        w = self.chip.try_pop(thread=0)
        if w is None:
            return None
        byte = self.decode(w)
        if byte is None:
            raise Ps2Error("bad frame 0x%03x" % w)
        return byte

    def write(self, byte):
        """Send one byte to the device and wait for its acknowledge bit.
        The receiver hears the host's byte too, as the device clocked it:
        that record is checked against what was sent."""
        byte &= 0xFF
        sent = byte | (self._odd_parity(byte) << 8)
        self.chip.push(sent | (1 << 9), thread=1)
        r = self.chip.pop(thread=1)
        if r == 3:
            raise Ps2Error("no device: it never clocked")
        # Frames the device completed before the host got the bus come first.
        held = []
        while True:
            w = self.chip.pop(thread=0)
            if not (w >> 10) & 1:
                break
            held.append(w)
        self._held = held
        if (w >> 1) & 0x1FF != sent:
            raise Ps2Error("sent 0x%03x, the bus carried 0x%03x" % (sent, (w >> 1) & 0x1FF))
        if r != 0:
            raise Ps2Error("the device did not acknowledge")

    def held(self):
        """Bytes the device finished sending while the last write() waited
        for the bus, oldest first."""
        out = [self.decode(w) for w in getattr(self, "_held", [])]
        self._held = []
        return out


class CanError(Exception):
    pass


class Can:
    """CAN (classical, 11-bit identifiers) through a transceiver such as an
    SN65HVD230 (can.hex: the receiver on thread 0, the transmitter on thread
    1): RXD on P0, TXD on P1. It sends data frames and hears every frame on
    the bus, its own included. It is not a full node: it does not
    acknowledge other nodes' frames, so the bus needs at least one node that
    does, and it sends no error frames.

    The engines own the bit timing, arbitration and the ACK slot; framing,
    CRC and bit stuffing are here. The host has to keep up: a word of 16
    bits each way per 16 bit times while a frame is on the bus, so use the
    PIO port (PioPort) above a few kbit/s."""

    RX_WORDS, RX_SAME, TX_LOST = 19, 14, 19
    FRAME_END = 0xFFFF

    def __init__(self, chip, image, clock_hz=10_000_000, bitrate=125_000):
        clkdiv = clock_hz // (10 * bitrate)
        if clkdiv < 1 or clkdiv * 10 * bitrate != clock_hz:
            raise ValueError("the core clock must be 10 x bitrate x a whole number")
        self.chip = chip
        self._words, self._frames = [], []
        chip.stop()
        chip.load(image)
        chip.configure(thread=0, start=0, in_base=0, threshold=15, timeout=4,
                       timeout_vector=self.RX_SAME, clkdiv=clkdiv, out_msb_first=True)
        chip.configure(thread=1, start=self.RX_WORDS, out_base=1, out_count=1,
                       threshold=16, timeout=0,
                       timeout_vector=self.RX_WORDS + self.TX_LOST, clkdiv=clkdiv)
        chip.set_pin_modes({1: PUSH_PULL})
        chip.run(threads=(0, 1))

    @staticmethod
    def _crc15(bits):
        crc = 0
        for b in bits:
            top = (crc >> 14) & 1
            crc = (crc << 1) & 0x7FFF
            if top ^ b:
                crc ^= 0x4599
        return crc

    @staticmethod
    def _stuff(bits):
        """A bit of the opposite level after every five equal bits."""
        out, last, run = [], -1, 0
        for b in bits:
            run = run + 1 if b == last else 1
            last = b
            out.append(b)
            if run == 5:
                last, run = 1 - b, 1
                out.append(last)
        return out

    @classmethod
    def frame_bits(cls, ident, data):
        """A data frame on the wire (1 = recessive), from its start-of-frame
        bit to its ACK delimiter."""
        if not 0 <= ident < 0x800 or len(data) > 8:
            raise ValueError("11-bit identifier, at most 8 bytes")
        body = [0] + [(ident >> (10 - k)) & 1 for k in range(11)] + [0, 0, 0]
        body += [(len(data) >> (3 - k)) & 1 for k in range(4)]
        for byte in data:
            body += [(byte >> (7 - k)) & 1 for k in range(8)]
        crc = cls._crc15(body)
        body += [(crc >> (14 - k)) & 1 for k in range(15)]
        return cls._stuff(body) + [1, 1, 1]

    @classmethod
    def decode(cls, levels):
        """(identifier, data, acknowledged) from a frame's recorded levels,
        or None if its stuffing, fixed bits or CRC are wrong."""
        pos, last, run = 0, -1, 0

        def take(n):
            nonlocal pos, last, run
            out = []
            while len(out) < n:
                if pos >= len(levels):
                    return None
                b = levels[pos]
                pos += 1
                if run == 5:
                    if b == last:
                        return None
                    last, run = b, 1
                else:
                    run = run + 1 if b == last else 1
                    last = b
                    out.append(b)
            return out

        def value(bits):
            v = 0
            for b in bits:
                v = (v << 1) | b
            return v

        head = take(19)
        if head is None or head[0] or value(head[12:15]):
            return None
        n = value(head[15:19])
        if n > 8:
            return None
        payload = take(8 * n)
        crc = take(15) if payload is not None else None
        if crc is None or value(crc) != cls._crc15(head + payload):
            return None
        if run == 5:  # a stuff bit can follow the CRC
            if pos >= len(levels) or levels[pos] == last:
                return None
            pos += 1
        tail = levels[pos:pos + 3]
        if len(tail) < 3 or tail[0] != 1 or tail[2] != 1:
            return None
        return (value(head[1:12]),
                [value(payload[8 * k:8 * k + 8]) for k in range(n)], tail[1] == 0)

    def _pump(self):
        """Moves what the receiver has pushed into frames."""
        while True:
            w = self.chip.try_pop(thread=0)
            if w is None:
                return
            if w != self.FRAME_END:
                self._words.append(w)
                continue
            levels = []
            for k, word in enumerate(self._words):
                n = 15
                if k == len(self._words) - 1:
                    n = 0
                    while word >> n:
                        n += 1
                levels += [(word >> j) & 1 for j in range(n)]
            self._words = []
            self._frames.append(self.decode(levels))

    def send(self, ident, data, attempts=8):
        """Sends a data frame, again each time it loses arbitration. True
        if a node acknowledged it, False if none did."""
        bits = self.frame_bits(ident, data)[1:]  # the engine sends the SOF
        words = [len(bits) - 1]
        for k in range(0, len(bits), 16):
            w = 0
            for j, b in enumerate(bits[k:k + 16]):
                w |= b << j
            words.append(w)
        for _ in range(attempts):
            for w in words:
                while self.chip.status(thread=1)["tx_level"] >= FIFO_DEPTH:
                    self._pump()
                self.chip.write(TX_FIFO + BANK, w)
                self._pump()
            r = None
            while r is None:
                self._pump()
                r = self.chip.try_pop(thread=1)
            if r == 0:
                return True
            if r == self.FRAME_END:
                return False
        raise CanError("arbitration lost %d times" % attempts)

    def receive(self):
        """The oldest frame heard and not yet returned, as (identifier,
        data, acknowledged), or None if there is none. The chip's own frames
        are among them. A frame that does not decode raises CanError."""
        self._pump()
        if not self._frames:
            return None
        frame = self._frames.pop(0)
        if frame is None:
            raise CanError("a frame with a stuffing, form or CRC error")
        return frame


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


# --- Low-speed USB --------------------------------------------------------
#
# Packet encoding, from the USB 1.1 specification (chapter 8): the chip's
# usb_tx engine clocks out line states at 8 core clocks per bit (so the core
# clock must be 12 MHz) and adds EOP itself; everything above the wire is
# built here, the split RP2040 PIO-USB uses as well.

USB_OUT, USB_IN, USB_SETUP = 0x1, 0x9, 0xD
USB_DATA0, USB_DATA1 = 0x3, 0xB
USB_ACK, USB_NAK, USB_STALL = 0x2, 0xA, 0xE


def usb_pid(p):
    return p | ((~p & 0xF) << 4)


def usb_crc5(value, nbits):
    crc = 0x1F
    for i in range(nbits):
        if (crc ^ (value >> i)) & 1:
            crc = (crc >> 1) ^ 0x14
        else:
            crc >>= 1
    return ~crc & 0x1F


def usb_crc16(data):
    crc = 0xFFFF
    for b in data:
        for i in range(8):
            if (crc ^ (b >> i)) & 1:
                crc = (crc >> 1) ^ 0xA001
            else:
                crc >>= 1
    return ~crc & 0xFFFF


def usb_token(pid, addr, endp):
    field = addr | (endp << 7)
    v = field | (usb_crc5(field, 11) << 11)
    return [usb_pid(pid), v & 0xFF, v >> 8]


def usb_data(pid, payload):
    c = usb_crc16(payload)
    return [usb_pid(pid)] + list(payload) + [c & 0xFF, c >> 8]


def usb_handshake(pid):
    return [usb_pid(pid)]


def usb_line_states(packet):
    """Line states (1 = K, 0 = J) of a packet from its bytes after SYNC:
    SYNC, bit stuffing and NRZI from idle J. EOP is the chip's."""
    bits = []
    for b in [0x80] + list(packet):
        for i in range(8):
            bits.append((b >> i) & 1)
    states = []
    level = 0  # J
    run = 0
    for b in bits:
        if b:
            states.append(level)
            run += 1
            if run == 6:
                level ^= 1  # a stuffed 0 toggles the line
                states.append(level)
                run = 0
        else:
            level ^= 1
            states.append(level)
            run = 0
    return states


USB_ENGINE_ORIGIN = 5  # Firmware.Usb_host.engine_origin (the OCaml tests check these)
USB_TMO = 22  # Firmware.usb_tmo: the receive timeout vector, from the origin
USB_RECEIVE = 0x8000  # Firmware.usb_receive: the receive command
USB_BUFFER_WORDS = 13  # both threads' FIFOs, chained
USB_LATE_WORDS = 2  # words a transaction may send after the engine starts
RECEIVE = "receive"  # in a transaction's command list


def usb_words(packet):
    """The engine's send command for one packet: its line-state count less
    one, then the line states 16 to a word, first in bit 0."""
    states = usb_line_states(packet)
    words = [len(states) - 1]
    for start in range(0, len(states), 16):
        w = 0
        for k, s in enumerate(states[start:start + 16]):
            w |= s << k
        words.append(w)
    return words


def usb_decode(words):
    """The bytes after SYNC of a received packet, from the engine's words
    (line levels, 1 = K, 16 to a word; a 1 after the last), or None if they
    do not decode: from the first K, NRZI and stuffing undone, SYNC dropped
    through its final 1."""
    if not words:
        return None
    levels = []
    for w in words[:-1]:
        levels += [(w >> k) & 1 for k in range(16)]
    last = words[-1]
    if last == 0:
        return None
    top = 15  # the end marker's position (MicroPython ints have no bit_length)
    while not (last >> top) & 1:
        top -= 1
    levels += [(last >> k) & 1 for k in range(top)]
    bits, prev, run = [], 0, 0
    for lv in levels:
        b = 1 if lv == prev else 0
        prev = lv
        if run == 6:
            if b:
                return None
            run = 0
            continue
        run = run + 1 if b else 0
        bits.append(b)
    if 1 not in bits:
        return None
    bits = bits[bits.index(1) + 1:]
    if not bits or len(bits) % 8:
        return None
    return [sum(bits[8 * n + i] << i for i in range(8)) for n in range(len(bits) // 8)]


class UsbError(Exception):
    pass


class UsbHost:
    """Low-speed USB host (usb_host.hex) through a USB 1.1 transceiver in
    VO/FSE0 mode: P0 VP, P1 VM (inputs); P2 VO, P3 FSE0, P4 OE_N. The core
    clock must be 12 MHz (8 clocks per bit at 1.5 Mbit/s).

    The engine (Firmware.usb) runs on one thread and echo on the other,
    relaying through CHAIN, so both threads' FIFOs are one buffer on
    whichever side of the engine a transaction needs it: before it for
    sending (the transaction is loaded with the engine stopped, then started
    with one CTRL write), after it for receiving. Commands always go to
    thread 0 and results come from thread 1. The engine owns the bit timing,
    clock recovery and turnaround; this code owns packets, CRCs and the
    transfer logic. Only one step is timed: an IN transaction's handshake
    goes in after the engine starts, in the same port batch, so the port
    must run a batch at its own pace. PioPort does; bit-banging from
    MicroPython is about a hundred times too slow (test/board_emu)."""

    def __init__(self, chip, image):
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.set_pin_modes({2: PUSH_PULL, 3: PUSH_PULL, 4: PUSH_PULL})
        self.engine = None

    def _layout(self, rx_buffered):
        engine = 0 if rx_buffered else 1
        relay = 1 - engine
        self.chip.stop()
        self.chip.configure(thread=relay)  # echo, at 0
        self.chip.configure(thread=engine, start=USB_ENGINE_ORIGIN, in_base=0,
                            out_base=2, out_count=1, set_base=2, set_count=1,
                            sideset_base=3, sideset_count=2, threshold=16,
                            timeout=2, timeout_vector=USB_ENGINE_ORIGIN + USB_TMO)
        self.chip.run(threads=(relay,), chain=True)  # the engine stays stopped
        self.engine = engine

    def _idle(self):
        e = self.chip.status(thread=self.engine)
        r = self.chip.status(thread=1 - self.engine)
        return (e["pc"] == USB_ENGINE_ORIGIN and e["tx_level"] == 0
                and r["pc"] == 0 and r["tx_level"] == 0
                and self.chip.status(thread=0)["rx_level"] == 0)

    def transaction(self, commands, rx_buffered=False, polls=400):
        """Runs [commands] in order: packets (their bytes after SYNC) to
        send, and at most one RECEIVE. Returns the received packet's bytes
        (None if it did not decode, or nothing came: after [polls] status
        reads the engine is stopped)."""
        words = []
        for c in commands:
            words += [USB_RECEIVE] if c == RECEIVE else usb_words(c)
        preload = FIFO_DEPTH if rx_buffered else USB_BUFFER_WORDS
        if len(words) > preload + (USB_LATE_WORDS if rx_buffered else 0):
            raise ValueError("transaction too long for the chip's buffers")
        self._layout(rx_buffered)
        for w in words[:preload]:
            self.chip.push(w)
        # Start the engine and send the words that did not fit in one batch,
        # with no status reads between: in an IN transaction the handshake
        # must follow the device's data within 16 bit times, about 100 us
        # after the start, far less than one MicroPython register access by
        # bit-banging (milliseconds). These writes need not check for room:
        # the engine takes its first two words within a few clocks of
        # starting, and each write lands a whole port transaction (192 core
        # clocks at least) after the one before.
        self.chip.write_many([(CTRL, self.chip.ctrl((0, 1), chain=True))]
                             + [(TX_FIFO, w) for w in words[preload:]])
        got = []
        for _ in range(polls):
            w = self.chip.try_pop(thread=1)
            if w is not None:
                got.append(w)
            elif self._idle():
                # The engine may have finished between the two checks:
                # collect what it pushed meanwhile.
                while True:
                    w = self.chip.try_pop(thread=1)
                    if w is None:
                        break
                    got.append(w)
                break
        else:
            self.chip.run(threads=(1 - self.engine,), chain=True)  # stop the engine
            return None
        if RECEIVE not in commands:
            return []
        return usb_decode(got)

    def control_read(self, addr, setup, length):
        """A control read (USB 1.1, 8.5.2): SETUP stage, IN data stage until
        [length] bytes or a short packet, OUT status stage. [setup] is the
        8-byte request. Returns the data."""
        ack = [usb_pid(USB_ACK)]
        got = self.transaction([usb_token(USB_SETUP, addr, 0),
                                usb_data(USB_DATA0, setup), RECEIVE])
        if got != ack:
            raise UsbError("SETUP not acknowledged: %r" % (got,))
        data, toggle = [], USB_DATA1
        while len(data) < length:
            got = self.transaction([usb_token(USB_IN, addr, 0), RECEIVE,
                                    usb_handshake(USB_ACK)], rx_buffered=True)
            if got == [usb_pid(USB_NAK)]:
                continue  # not ready yet (the ACK that followed it is ignored)
            if not got or got[0] != usb_pid(toggle) or usb_crc16(got[1:-2]) != (
                    got[-2] | (got[-1] << 8)):
                raise UsbError("bad data packet: %r" % (got,))
            data += got[1:-2]
            toggle ^= USB_DATA0 ^ USB_DATA1
            if len(got) - 3 < 8:
                break
        got = self.transaction([usb_token(USB_OUT, addr, 0),
                                usb_data(USB_DATA1, []), RECEIVE])
        if got != ack:
            raise UsbError("status stage not acknowledged: %r" % (got,))
        return data[:length]
