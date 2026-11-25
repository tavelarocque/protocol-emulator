# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# Drivers for link protocols: compact JTAG (IEEE 1149.7) as the debug
# probe, and PJON packets sent over PJDL. Each takes a Chip from
# protocol_emulator.py and a firmware image, as the drivers there do.
#
# A module of its own for the same reason more_protocols.py is a second:
# the Pico's memory. Copy the files you use to the board.

import protocol_emulator as pe


class CJtagController(pe.JtagController):
    """Compact JTAG probe (cjtag.hex), IEEE 1149.7 in the OScan1 format:
    TCKC on pin 0, TMSC on pin 1, open-drain, which needs a pull-up. Each
    JTAG clock is three TCKC clocks: nTDI and TMS from the chip, TDO from
    the target. A JTAG clock takes 13 core clocks x clkdiv: 770 kHz at 10
    MHz with clkdiv 0 or 1. reset, shift_ir and shift_dr are JTAG's, once
    activate has brought the target online."""

    ACTIVATE = 0x8000

    def __init__(self, chip, image, clkdiv=0):
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(sideset_base=0, sideset_count=1, set_base=1, set_count=1,
                       out_base=1, out_count=1, in_base=1, threshold=16, clkdiv=clkdiv)
        chip.run()  # TCKC is low from the program's first instruction
        chip.set_pin_modes({0: pe.PUSH_PULL, 1: pe.OPEN_DRAIN})

    def activate(self):
        """The reset escape, three clocks, the selection escape and the
        activation code for OScan1: the target is then online, its TAP in
        Test-Logic-Reset."""
        self.chip.push(self.ACTIVATE)

    @staticmethod
    def words(tms, tdi):
        """The TX words for a scan of len(tms) clocks: N - 1, then (TDI,
        TMS) pairs, eight to a word, TDI in the even bit."""
        n = len(tms)
        if not 1 <= n <= 32768 or len(tdi) != n:
            raise ValueError("a scan is 1 to 32768 clocks")
        words = [n - 1]
        for start in range(0, n, 8):
            w = 0
            for k in range(min(8, n - start)):
                w |= (tdi[start + k] & 1) << (2 * k)
                w |= (tms[start + k] & 1) << (2 * k + 1)
            words.append(w)
        return words

    def scan(self, tms, tdi):
        """Clock len(tms) times with the given TMS and TDI bits; return the
        TDO bit the target sent in each."""
        words = self.words(tms, tdi)
        n, got = len(tms), []
        for w in words:
            self.chip.push(w)
            r = self.chip.try_pop()  # keep RX draining so neither FIFO jams
            if r is not None:
                got.append(r)
        while len(got) < len(words) - 1:
            got.append(self.chip.pop())
        tdo = []
        for i, w in enumerate(got):
            for k in range(min(8, n - 8 * i)):
                tdo.append((w >> k) & 1)
        return tdo


def pjon_crc8(data):
    """PJON's CRC8 (polynomial 0x97, reflected, from 0), as the chip's CRC
    register computes it."""
    crc = 0
    for b in data:
        crc ^= b
        for _ in range(8):
            odd = crc & 1
            crc >>= 1
            if odd:
                crc ^= 0x97
    return crc


class PjonPjdl:
    """A PJON node sending over PJDL (pjdl.hex): the line on pin 0,
    push-pull, low when idle. The image is built for one of PJDL's modes
    (test/pjdl.hex: mode 4, 26 us data bits and 60 us pads); give the same
    [mode] here. The chip sends the frame initializer, the pads, the bytes
    and both CRC8s; packets are up to 15 bytes, as PJON allows with CRC8.
    It sends without asking for an acknowledgement and does not receive."""

    TICK_US = {1: 4, 2: 4, 3: 4, 4: 2}

    def __init__(self, chip, image, mode=4, clock_hz=10_000_000):
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(set_base=0, set_count=1, out_base=0, out_count=1, threshold=8,
                       clkdiv=clock_hz // 1_000_000 * self.TICK_US[mode])
        for addr, value in ((pe.CRC_POLY, 0x97), (pe.CRC_POLY + 1, 0),
                            (pe.CRC_INIT, 0), (pe.CRC_INIT + 1, 0)):
            chip.write(addr, value)
        chip.run()  # the line is low from the program's first instruction
        chip.set_pin_modes({0: pe.PUSH_PULL})

    @staticmethod
    def words(receiver, payload, sender=None):
        """The TX words for a packet to [receiver] (0: everyone) with
        [payload], from [sender] if given: receiver ID, header
        configuration (sender info or nothing), length, sender ID,
        payload."""
        info = [] if sender is None else [sender]
        length = 5 + len(info) + len(payload)
        if length > 15 or not all(0 <= b <= 255 for b in [receiver] + info + list(payload)):
            raise ValueError("a PJON packet with CRC8 is at most 15 bytes of 0 to 255")
        return [receiver, 0x02 if info else 0x00, length] + info + list(payload)

    def send(self, receiver, payload, sender=None):
        """Send a packet; return its end CRC once it has gone out."""
        for w in self.words(receiver, payload, sender):
            self.chip.push(w)
        return self.chip.pop()


class LfastSipi:
    """SIPI (Zipwire) frames over NXP's LFAST (lfast.hex): TXP's level on
    pin 0, push-pull, for an LVDS driver; low when idle. A bit is 5 ticks:
    5 Mbit/s, LFAST's low speed, at 50 MHz with clkdiv 2. The chip makes
    the sync pattern, the SIPI CRC-16 and the sleep bit; the words of a
    frame go through the packet buffer, as they leave faster than the host
    port can push them. It sends; the answers come back on the other pair,
    which it does not read."""

    BUF_CTRL, BUF_PTR, BUF_END, BUF_DATA = 0x68, 0x69, 0x6A, 0x6B
    SIZE_CODES = {4: 1, 8: 2, 12: 3, 16: 4, 32: 5, 64: 6, 36: 7}  # payload bytes: code
    DATA_A = 0b0100  # LFAST's logical channel types: data channels A to H are 4 to 11

    def __init__(self, chip, image, clock_hz=50_000_000, bit_rate=5_000_000):
        if clock_hz % (5 * bit_rate):
            raise ValueError("the bit rate must be the clock / (5 x clkdiv)")
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(out_base=0, out_count=1, set_base=0, set_count=1, threshold=16,
                       out_msb_first=True, clkdiv=clock_hz // (5 * bit_rate))
        for addr, value in ((pe.CRC_POLY, 0x8408), (pe.CRC_POLY + 1, 0),
                            (pe.CRC_INIT, 0xFFFF), (pe.CRC_INIT + 1, 0)):
            chip.write(addr, value)
        chip.run()  # the line is low from the program's first instruction
        chip.set_pin_modes({0: pe.PUSH_PULL})

    @classmethod
    def words(cls, sipi, channel=DATA_A):
        """The TX words for an LFAST frame on [channel] carrying the SIPI
        frame [sipi] (16-bit words, its CRC left out)."""
        size = cls.SIZE_CODES.get(2 * len(sipi) + 2)
        if size is None:
            raise ValueError("no LFAST payload size fits %d words" % len(sipi))
        return [(((size << 5) | (channel << 1)) << 8) | (len(sipi) - 1)] + list(sipi)

    @staticmethod
    def header(command, tag=0, channel=0):
        """SIPI's header word: transaction tag, command code, channel."""
        return (tag << 13) | (command << 8) | (channel << 1)

    def send(self, frames):
        """Send SIPI frames ([[word, ...], ...]), one LFAST frame each, back
        to back from the packet buffer."""
        words = []
        for f in frames:
            words += self.words(f)
        self.chip.write(self.BUF_CTRL, 0)
        self.chip.write(self.BUF_PTR, 0)
        self.chip.write_many([(self.BUF_DATA, w) for w in words])
        self.chip.write(self.BUF_PTR, 0)
        self.chip.write(self.BUF_END, len(words))
        self.chip.write(self.BUF_CTRL, 1)  # play into thread 0's TX FIFO

    @classmethod
    def write_frame(cls, address, value, tag=0, channel=0):
        """Write 4 bytes with ACK."""
        return [cls.header(0b00110, tag, channel), address >> 16, address & 0xFFFF,
                value >> 16, value & 0xFFFF]

    @classmethod
    def read_frame(cls, address, tag=0, channel=0):
        """Read 4 bytes: the answer comes on the other pair."""
        return [cls.header(0b00010, tag, channel), address >> 16, address & 0xFFFF]

    @classmethod
    def id_frame(cls, tag=0):
        """Read the 4-byte JTAG ID."""
        return [cls.header(0b10010, tag)]
