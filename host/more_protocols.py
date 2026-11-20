# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# Drivers for the protocols added on v2.0: I2S, DMX512, Wiegand and NEC
# infrared (to send and to receive), RC-5 infrared, MDIO, DALI and LIN, and
# Modbus RTU framing for the UART. Each takes a Chip from
# protocol_emulator.py and a firmware image, as the drivers there do.
#
# They are a module of their own because of the Pico's memory: MicroPython
# compiles a module whole, and on an RP2040 one file holding every driver
# no longer fits. Copy both files to the board and import what you use.

import protocol_emulator as pe


class I2sTx:
    """I2S transmitter, 16-bit stereo (i2s_tx.hex): SCK on pin 0, WS on
    pin 1, SD on pin 2. SCK is core clock / (4 x clkdiv). [first]: up to
    two (left, right) frames queued before the clock starts."""

    START = 8  # Firmware.i2s_tx_start

    def __init__(self, chip, image, clkdiv=0, first=()):
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(start=self.START, sideset_base=0, sideset_count=2, out_base=2,
                       out_count=1, threshold=16, out_msb_first=True, clkdiv=clkdiv)
        chip.set_pin_modes({0: pe.PUSH_PULL, 1: pe.PUSH_PULL, 2: pe.PUSH_PULL})
        for left, right in first:
            chip.write(pe.TX_FIFO, left & 0xFFFF)
            chip.write(pe.TX_FIFO, right & 0xFFFF)
        chip.run()

    def write(self, frames):
        for left, right in frames:
            self.chip.push(left & 0xFFFF)
            self.chip.push(right & 0xFFFF)


class DmxTx:
    """DMX512 transmitter on [pin] (dmx_tx.hex), 250 kbit/s."""

    def __init__(self, chip, image, clock_hz=10_000_000, pin=0):
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(out_base=pin, set_base=pin, threshold=9)
        chip.run()  # the firmware raises the line before the pin drives it
        chip.set_pin_modes({pin: pe.PUSH_PULL})
        chip.push(clock_hz // 250_000 - 4)

    def send(self, slots, start_code=0):
        """One packet: break, mark, the start code, then the slots."""
        self.chip.push(1 | (start_code << 1))
        for level in slots:
            self.chip.push(level << 1)


class WiegandTx:
    """Wiegand transmitter (wiegand_tx.hex): D0 on pin 0, D1 on pin 1; 50 us
    pulses, 1 ms apart."""

    def __init__(self, chip, image, clock_hz=10_000_000):
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(set_base=0, set_count=2, threshold=16, clkdiv=clock_hz // 40_000)
        chip.run()  # the firmware raises both lines before the pins drive them
        chip.set_pin_modes({0: pe.PUSH_PULL, 1: pe.PUSH_PULL})

    def send(self, bits):
        """A frame of bits (0 or 1), first bit first."""
        self.chip.push(len(bits) - 1)
        for k in range(0, len(bits), 16):
            self.chip.push(sum(b << i for i, b in enumerate(bits[k:k + 16])))

    def send26(self, facility, card):
        """The 26-bit format: even parity, 8-bit facility code, 16-bit card
        number, odd parity; each parity bit covers the 12 bits next to it."""
        data = [(facility >> (7 - k)) & 1 for k in range(8)]
        data += [(card >> (15 - k)) & 1 for k in range(16)]
        self.send([sum(data[:12]) & 1] + data + [1 ^ (sum(data[12:]) & 1)])


class NecTx:
    """NEC infrared transmitter with carrier (nec_tx.hex): an IR LED on pin
    0, lit when high."""

    def __init__(self, chip, image, clock_hz=10_000_000, carrier_hz=38_000):
        self.chip = chip
        clkdiv = (clock_hz + carrier_hz) // (2 * carrier_hz)  # half a carrier period
        self.leader = (9 * clock_hz + 1000 * clkdiv) // (2000 * clkdiv)  # 9 ms, in periods
        chip.stop()
        chip.load(image)
        chip.configure(sideset_base=0, sideset_count=1, threshold=16, clkdiv=clkdiv)
        chip.run()  # pins reset high: the firmware turns the LED off before the pin drives it
        chip.set_pin_modes({0: pe.PUSH_PULL})

    def send(self, address, command):
        self.chip.push(self.leader - 1)
        self.chip.push(address | ((address ^ 0xFF) << 8))
        self.chip.push(command | ((command ^ 0xFF) << 8))


class MdioError(Exception):
    pass


class Mdio:
    """MDIO controller, IEEE 802.3 clause 22 (mdio.hex): MDC on pin 0, MDIO
    on pin 1, open-drain, so the bus needs its pull-up. MDC is core clock /
    (4 x clkdiv): 1.25 MHz at 10 MHz by default. clkdiv=1 gives 2.5 MHz, the
    standard's limit, at which a PHY that takes its full 300 ns to answer
    is read with no margin."""

    def __init__(self, chip, image, clkdiv=2):
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(sideset_base=0, sideset_count=1, out_base=1, in_base=1, threshold=16,
                       out_msb_first=True, in_msb_first=True, clkdiv=clkdiv)
        chip.set_pin_modes({0: pe.PUSH_PULL, 1: pe.OPEN_DRAIN})
        chip.run()
        self._words([0xFFFF])  # release the data line

    def _words(self, words):
        """Shift 16-bit words out; return what was on the line meanwhile."""
        read = []
        for word in words:
            self.chip.push(word)
            read.append(self.chip.pop())
        return read

    @staticmethod
    def _header(read, phy, reg):
        return (0b01 << 14) | ((0b10 if read else 0b01) << 12) | (phy << 7) | (reg << 2) | \
            (0b11 if read else 0b10)

    def write(self, phy, reg, value):
        self._words([0xFFFF, 0xFFFF, self._header(False, phy, reg), value])

    def read(self, phy, reg):
        back = self._words([0xFFFF, 0xFFFF, self._header(True, phy, reg), 0xFFFF])
        if back[2] & 1:
            raise MdioError("no PHY drove the turnaround bit")
        return back[3]


class DaliTx:
    """DALI forward frames on pin 0 (dali_tx.hex): the bus level, high when
    idle, for a DALI line driver."""

    def __init__(self, chip, image, clock_hz=10_000_000):
        self.chip = chip
        chip.stop()
        chip.load(image)
        # A tick is 1/8 of a half bit: 1/19200 s.
        chip.configure(sideset_base=0, sideset_count=1, threshold=16, out_msb_first=True,
                       clkdiv=(clock_hz + 9600) // 19200)
        chip.run()  # the firmware raises the bus before the pin drives it
        chip.set_pin_modes({0: pe.PUSH_PULL})

    def send(self, address, command):
        self.chip.push((address << 8) | command)


class Rc5Tx:
    """RC-5 infrared transmitter with carrier (rc5_tx.hex): an IR LED on pin
    0, lit when high."""

    def __init__(self, chip, image, clock_hz=10_000_000, carrier_hz=36_000):
        self.chip = chip
        self.toggle = 0
        chip.stop()
        chip.load(image)
        chip.configure(sideset_base=0, sideset_count=1, threshold=14, out_msb_first=True,
                       clkdiv=(clock_hz + carrier_hz) // (2 * carrier_hz))
        chip.run()  # pins reset high: the firmware turns the LED off before the pin drives it
        chip.set_pin_modes({0: pe.PUSH_PULL})

    def send(self, address, command, new_press=True):
        """One frame. The toggle bit flips for each new key press and stays
        for the repeats of a held key."""
        if new_press:
            self.toggle ^= 1
        self.chip.push(((0b11 << 12) | (self.toggle << 11) | (address << 6) | command) << 2)


class LinMaster:
    """LIN frames from the master, header and response, on pin 0: needs no
    firmware of its own, only the DMX512 transmitter (dmx_tx.hex), which is
    a UART that can send a break."""

    def __init__(self, chip, image, baud=19_200, clock_hz=10_000_000, pin=0):
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(out_base=pin, set_base=pin, threshold=9)
        chip.run()
        chip.set_pin_modes({pin: pe.PUSH_PULL})
        chip.push((clock_hz + baud // 2) // baud - 4)

    @staticmethod
    def protected_id(frame_id):
        bit = lambda k: (frame_id >> k) & 1
        p0 = bit(0) ^ bit(1) ^ bit(2) ^ bit(4)
        p1 = 1 ^ bit(1) ^ bit(3) ^ bit(4) ^ bit(5)
        return frame_id | (p0 << 6) | (p1 << 7)

    def send(self, frame_id, data):
        """Break, sync, protected identifier, data and the LIN 2 checksum
        (over the identifier and the data)."""
        pid = self.protected_id(frame_id)
        total = pid
        for byte in data:
            total += byte
            total = (total & 0xFF) + (total >> 8)
        self.chip.push(1 | (0x55 << 1))
        for byte in [pid] + list(data) + [total ^ 0xFF]:
            self.chip.push(byte << 1)


class Pwm:
    """PWM on pin 0 (pwm.hex), and so RC servo pulses. Times are in ticks of
    [tick_us] microseconds."""

    def __init__(self, chip, image, tick_us=1, clock_hz=10_000_000):
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(sideset_base=0, sideset_count=1, clkdiv=clock_hz * tick_us // 1_000_000)
        chip.run()  # pins reset high: the firmware lowers the pin before it drives
        chip.set_pin_modes({0: pe.PUSH_PULL})
        chip.stop()

    def set(self, high, period):
        """High for [high] ticks in every [period]. The pin holds its level
        for the moment it takes to change over."""
        self.chip.stop()
        self.chip.push(high - 2)
        self.chip.push(period - high - 3)
        self.chip.run()

    def servo(self, microseconds):
        """A servo pulse of that width every 20 ms (with a 1 us tick)."""
        self.set(microseconds, 20_000)


class NesPad:
    """NES gamepad (nes_pad.hex): latch on pin 0, clock on pin 1, data on
    pin 2."""

    BUTTONS = ("A", "B", "Select", "Start", "Up", "Down", "Left", "Right")

    def __init__(self, chip, image, clock_hz=10_000_000):
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(sideset_base=0, sideset_count=2, in_base=2, threshold=8,
                       in_msb_first=True, clkdiv=3 * clock_hz // 1_000_000)
        chip.run()  # the firmware lowers the latch before the pins drive
        chip.set_pin_modes({0: pe.PUSH_PULL, 1: pe.PUSH_PULL, 2: pe.INPUT})

    def read(self):
        """The buttons held down, as a list of their names."""
        self.chip.push(0)
        word = self.chip.pop()
        return [name for k, name in enumerate(self.BUTTONS) if not (word >> (7 - k)) & 1]


def modbus_crc16(data):
    """Modbus RTU's CRC: polynomial 0xA001 (reflected), start 0xFFFF."""
    crc = 0xFFFF
    for byte in data:
        crc ^= byte
        for _ in range(8):
            crc = (crc >> 1) ^ 0xA001 if crc & 1 else crc >> 1
    return crc


def modbus_frame(server, function, payload):
    """A Modbus RTU frame: server address, function code, payload, and the
    CRC low byte first. Send it with UartTx, and leave 3.5 character times
    of silence before the next."""
    body = bytes([server, function]) + bytes(payload)
    crc = modbus_crc16(body)
    return body + bytes([crc & 0xFF, crc >> 8])


class WiegandError(Exception):
    pass


class WiegandRx:
    """Wiegand receiver (wiegand_rx.hex): D0 on pin 0 and D1 on pin 1, which
    the firmware requires. The bus supplies the pull-ups."""

    def __init__(self, chip, image):
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(in_base=0, threshold=16, in_msb_first=True)
        chip.set_pin_modes({0: pe.INPUT, 1: pe.INPUT})
        chip.run()

    def expect(self, bits):
        """Tell the chip how long the next frame is; it then waits for it."""
        self.bits = bits
        self.chip.push(bits - 1)

    def read(self, patience=20000):
        """The frame asked for with [expect], first bit first. [patience]:
        how many looks at the chip before giving up on a frame that stopped
        short, whose bits are then thrown away."""
        bits = self.bits
        words = []
        for _ in range(patience):
            word = self.chip.try_pop()
            if word is not None:
                words.append(word)
                if 16 * len(words) >= bits:
                    break
        else:
            self.chip.stop()  # a stopped thread forgets what it had shifted in
            self.chip.run()
            raise WiegandError("no complete frame of %d bits" % bits)
        frame = []
        for k, word in enumerate(words):
            width = min(16, bits - 16 * k)
            frame += [(word >> (width - 1 - i)) & 1 for i in range(width)]
        return frame

    def read26(self, patience=20000):
        """After expect(26): the frame as (facility code, card number), its
        two parity bits checked."""
        frame = self.read(patience)
        data = frame[1:25]
        if frame[0] != sum(data[:12]) & 1 or frame[25] != 1 ^ (sum(data[12:]) & 1):
            raise WiegandError("parity")
        number = lambda field: sum(b << (len(field) - 1 - i) for i, b in enumerate(field))
        return number(data[:8]), number(data[8:])


class NecError(Exception):
    pass


class NecRx:
    """NEC infrared receiver (nec_rx.hex): an IR receiver module's output,
    low while it sees carrier, on pin 0."""

    START = 4  # Firmware.nec_rx_start

    def __init__(self, chip, image, clock_hz=10_000_000):
        self.chip = chip
        chip.stop()
        chip.load(image)
        # A tick is 1/16 of 562.5 us.
        chip.configure(start=self.START, in_base=0, threshold=16, timeout=128,
                       timeout_vector=0, clkdiv=(9 * clock_hz + 128_000) // 256_000)
        chip.set_pin_modes({0: pe.INPUT})
        chip.run()

    def read(self, patience=200000):
        """Wait for a frame; return (address, command). The address is 8 bits
        when its second byte is the complement of its first, 16 otherwise
        (the extended form). Raises NecError for a frame cut short or a
        command that fails its complement."""
        words = []
        for _ in range(patience):
            word = self.chip.try_pop()
            if word is not None:
                words.append(word)
                if len(words) == 2:
                    break
        else:
            raise NecError("no frame")
        address, command = words
        if command == 0:
            raise NecError("frame cut short")
        if (command ^ (command >> 8)) & 0xFF != 0xFF:
            raise NecError("command 0x%04X fails its complement" % command)
        if (address ^ (address >> 8)) & 0xFF == 0xFF:
            address &= 0xFF
        return address, command & 0xFF


# --- v2.1: the packet buffer, the CRC register, Ethernet -----------------------

AUTOPULL, AUTOPUSH, CRC_INVERT, CRC_IN = 1, 2, 4, 8  # for configure(auto=...)
CRC_POLY = 0x61  # low half; the high half follows. Thread 1's are + pe.BANK
CRC_INIT = 0x63
BUF_CTRL, BUF_PTR, BUF_END, BUF_DATA = 0x68, 0x69, 0x6A, 0x6B
BUF_WORDS = 1024


def set_crc(chip, poly, init, thread=0):
    """The thread's CRC register: its polynomial, low power first, and
    what it starts from. Both are 32 bits."""
    bank = pe.BANK * thread
    chip.write(CRC_POLY + bank, poly & 0xFFFF)
    chip.write(CRC_POLY + 1 + bank, poly >> 16)
    chip.write(CRC_INIT + bank, init & 0xFFFF)
    chip.write(CRC_INIT + 1 + bank, init >> 16)


class Buffer:
    """The packet buffer: 1024 words that stand in for the host at one end
    of one thread's FIFOs."""

    def __init__(self, chip):
        self.chip = chip

    def load(self, words, at=0):
        """Store [words] from [at] on. The buffer stops playing or
        recording first."""
        self.chip.write(BUF_CTRL, 0)
        self.chip.write(BUF_PTR, at)
        self.chip.write_many([(BUF_DATA, w) for w in words])

    def play(self, count, thread=0, at=0):
        """Play [count] words from [at] into the thread's TX FIFO."""
        self._go(1, count, thread, at)

    def record(self, count, thread=0, at=0):
        """Record up to [count] words from the thread's RX FIFO, from [at]."""
        self._go(2, count, thread, at)

    def _go(self, mode, count, thread, at):
        self.chip.write(BUF_CTRL, 0)
        self.chip.write(BUF_PTR, at)
        self.chip.write(BUF_END, (at + count) % BUF_WORDS)
        self.chip.write(BUF_CTRL, mode | (thread << 2))

    def position(self):
        """Where the pointer is: how far a play or a recording has got."""
        return self.chip.read(BUF_PTR)

    def read(self, count, at=0):
        """Take [count] words back from [at]."""
        self.chip.write(BUF_CTRL, 0)
        self.chip.write(BUF_PTR, at)
        return [self.chip.read(BUF_DATA) for _ in range(count)]


class EthernetTx:
    """10BASE-T Ethernet transmit (eth_tx.hex): TD+ on pin 0 and TD- on pin
    1, to a transformer through series resistors. The chip's clock must be
    40 MHz. The chip makes the preamble, the Manchester code, the CRC-32
    and the idle signal; the host supplies the frame."""

    START = 51  # eth_tx_origin; an odd number of bytes starts two words on
    PARK = 113  # where the program waits once a frame is out

    def __init__(self, chip, image):
        self.chip = chip
        chip.stop()
        chip.load(image)
        set_crc(chip, 0xEDB88320, 0xFFFFFFFF)
        self.buffer = Buffer(chip)
        # Pins reset high. Both high is no voltage across the pair, which is
        # idle, so they can drive from now on; the program idles both low.
        chip.set_pin_modes({0: pe.PUSH_PULL, 1: pe.PUSH_PULL})

    def send(self, frame):
        """Send one frame: destination address to the end of the data, no
        frame check sequence. Shorter than 60 bytes, it is padded with
        zeros. Returns at once; [sent] says when it is on the wire."""
        frame = bytes(frame)
        frame += bytes(max(0, 60 - len(frame)))
        odd = len(frame) & 1
        if odd:
            frame = b"\x00" + frame  # the first word holds one byte, in its top half
        words = [frame[k] | (frame[k + 1] << 8) for k in range(0, len(frame), 2)]
        self.chip.stop()
        self.chip.configure(start=self.START + 2 * odd, threshold=16, sideset_base=0,
                            sideset_count=2, auto=AUTOPULL | CRC_INVERT)
        self.buffer.load(words)
        self.buffer.play(len(words))
        self.chip.run()

    def sent(self):
        return self.chip.status()["pc"] == self.PARK
