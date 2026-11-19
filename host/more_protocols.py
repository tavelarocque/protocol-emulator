# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# Drivers for the protocols added on v2.0: I2S, DMX512, Wiegand, NEC and
# RC-5 infrared, MDIO, DALI and LIN. Each takes a Chip from
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
