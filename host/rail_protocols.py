# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# Drivers for building and railway buses and studio timecode: KNX TP1
# telegrams, MVB frames (IEC 61375-3-1) and SMPTE linear timecode. Each
# takes a Chip from protocol_emulator.py and a firmware image, as the
# drivers there do.
#
# A module of its own for the same reason more_protocols.py is a second:
# the Pico's memory. Copy the files you use to the board.

import protocol_emulator as pe

KNX_NOACK = 56  # Firmware.knx_noack


def knx_checksum(data):
    """KNX's checksum: the exclusive or of the bytes, inverted, as the
    chip's CRC register makes it."""
    x = 0
    for b in data:
        x ^= b
    return ~x & 0xFF


class KnxTp1:
    """KNX TP1 telegrams (knx_tx.hex): the bus on pin 0, open-drain, with a
    pull-up; a real bus needs a TP1 transceiver, as it is 30 V DC. 9615
    bit/s (a bit of 104 us, 0.16% fast), a 0 a 35 us pulse. The chip makes
    the characters, their parity bits and the checksum, then listens for
    the acknowledgement for [ack_timeout_us]; it does not listen before
    sending or repeat a telegram."""

    ACK, NAK, BUSY = 0xCC, 0x0C, 0xC0

    def __init__(self, chip, image, clock_hz=10_000_000, ack_timeout_us=2000):
        if clock_hz % 1_000_000 or not 0 < ack_timeout_us < 65536:
            raise ValueError("the clock must be a whole number of MHz")
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(out_base=0, out_count=1, set_base=0, set_count=1, in_base=0, threshold=8,
                       timeout_vector=KNX_NOACK, timeout=ack_timeout_us,
                       clkdiv=clock_hz // 1_000_000, auto=4)
        for addr, value in ((pe.CRC_POLY, 0x80), (pe.CRC_POLY + 1, 0),
                            (pe.CRC_INIT, 0), (pe.CRC_INIT + 1, 0)):
            chip.write(addr, value)
        chip.run()
        chip.set_pin_modes({0: pe.OPEN_DRAIN})

    @staticmethod
    def individual(area, line, device):
        """An individual address, area.line.device."""
        return (area << 12) | (line << 8) | device

    @staticmethod
    def group(main, middle, sub):
        """A group address in three levels, main/middle/sub."""
        return (main << 11) | (middle << 8) | sub

    @staticmethod
    def group_write(source, group, value, priority=3, hops=6):
        """The bytes of an A_GroupValue_Write of a value of 6 bits or less
        (a switch: 0 or 1) to a group address, the checksum left out."""
        if not 0 <= value < 64 or not 0 <= priority < 4:
            raise ValueError("a short group value is 0 to 63")
        return [0xB0 | (priority << 2), source >> 8, source & 0xFF, group >> 8, group & 0xFF,
                0x80 | (hops << 4) | 1, 0x00, 0x80 | value]

    @staticmethod
    def words(telegram):
        """The TX words: the bytes, the last with bit 8 set."""
        if not 7 <= len(telegram) <= 22 or not all(0 <= b <= 255 for b in telegram):
            raise ValueError("a telegram is 7 to 22 bytes before its checksum")
        return [b | (0x100 if i == len(telegram) - 1 else 0) for i, b in enumerate(telegram)]

    def send(self, telegram):
        """Send a telegram; return the acknowledgement's byte (ACK, NAK,
        BUSY or another), or None if none came or it was not a character."""
        for w in self.words(telegram):
            self.chip.push(w)
        r = self.chip.pop()
        byte, parity, stop = r & 0xFF, (r >> 8) & 1, (r >> 9) & 1
        if not stop or (bin(byte).count("1") + parity) % 2:
            return None
        return byte


class Mvb:
    """MVB master and slave frames (mvb.hex), IEC 61375-3-1, at 1.5 Mbit/s:
    pin 0 the line driver's data, pin 1 its enable, both push-pull, low
    while the bus is silent. A half bit is 16 ticks, so the core clock
    must be a multiple of 48 MHz (no whole number of clocks makes a bit at
    50 MHz). The chip makes the delimiters, the Manchester code, the check
    sequence after every 64 bits and the end delimiter; frames go through
    the packet buffer, as their words leave faster than the host port can
    push them. It sends; it does not read the bus."""

    BUF_CTRL, BUF_PTR, BUF_END, BUF_DATA = 0x68, 0x69, 0x6A, 0x6B
    F_CODES = {2: 0, 4: 1, 8: 2, 16: 3, 32: 4}  # process data bytes: function code

    def __init__(self, chip, image, clock_hz=48_000_000):
        if clock_hz % 48_000_000:
            raise ValueError("MVB needs a core clock that is a multiple of 48 MHz")
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(out_base=0, out_count=1, set_base=0, set_count=2, threshold=16,
                       out_msb_first=True, clkdiv=clock_hz // 48_000_000, auto=4)
        for addr, value in ((pe.CRC_POLY, 0xF4), (pe.CRC_POLY + 1, 0),
                            (pe.CRC_INIT, 0), (pe.CRC_INIT + 1, 0)):
            chip.write(addr, value)
        chip.run()  # the line is low from the program's first instruction
        chip.set_pin_modes({0: pe.PUSH_PULL, 1: pe.PUSH_PULL})

    @classmethod
    def master(cls, port, size):
        """A master frame asking for process data port [port] of [size]
        bytes: the function code and the address."""
        if size not in cls.F_CODES or not 0 <= port < 4096:
            raise ValueError("process data is 2, 4, 8, 16 or 32 bytes from a port below 4096")
        return ("master", [(cls.F_CODES[size] << 12) | port])

    @staticmethod
    def slave(words):
        """A slave frame of 1, 2, 4, 8 or 16 16-bit words."""
        if len(words) not in (1, 2, 4, 8, 16) or not all(0 <= w < 65536 for w in words):
            raise ValueError("a slave frame is 1, 2, 4, 8 or 16 words")
        return ("slave", list(words))

    @staticmethod
    def words(frame):
        kind, ws = frame
        return [(0x8000 if kind == "master" else 0) | (len(ws) - 1)] + ws

    def send(self, frames):
        """Send frames ([Mvb.master(...) or Mvb.slave(...), ...]) from the
        packet buffer, each after eight bit times of silence."""
        words = []
        for f in frames:
            words += self.words(f)
        self.chip.write(self.BUF_CTRL, 0)
        self.chip.write(self.BUF_PTR, 0)
        self.chip.write_many([(self.BUF_DATA, w) for w in words])
        self.chip.write(self.BUF_PTR, 0)
        self.chip.write(self.BUF_END, len(words))
        self.chip.write(self.BUF_CTRL, 1)  # play into thread 0's TX FIFO


class Ltc:
    """SMPTE linear timecode at 25 frames a second (ltc.hex): the line on
    pin 0, push-pull, for a level shifter to an audio input. The chip
    sends the frames back to back in biphase mark code, makes the sync
    word and the polarity correction bit (59); the host sends each frame's
    time and user bits, and has a frame's time (40 ms) to send the next.
    A half bit is 100 ticks: the clock must be a multiple of 400 kHz."""

    def __init__(self, chip, image, clock_hz=10_000_000):
        if clock_hz % 400_000:
            raise ValueError("the clock must be a multiple of 400 kHz")
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(out_base=0, out_count=1, set_base=0, set_count=1, threshold=16,
                       clkdiv=clock_hz // 400_000, auto=4)
        for addr, value in ((pe.CRC_POLY, 1), (pe.CRC_POLY + 1, 0),
                            (pe.CRC_INIT, 0), (pe.CRC_INIT + 1, 0)):
            chip.write(addr, value)
        chip.run()
        chip.set_pin_modes({0: pe.PUSH_PULL})

    @staticmethod
    def words(hours, minutes, seconds, frames, user=(0,) * 8, colour=False):
        """A frame's four words: the time in BCD, the eight user-bit
        nibbles (the first in bits 4-7) and the colour frame flag; bit 59
        is the chip's."""
        if not (0 <= hours < 24 and 0 <= minutes < 60 and 0 <= seconds < 60 and 0 <= frames < 25
                and len(user) == 8 and all(0 <= u < 16 for u in user)):
            raise ValueError("a time of day at 25 frames a second, and 8 nibbles")
        def word(value, u0, u1, flags=0):
            return (value % 10) | (u0 << 4) | ((value // 10) << 8) | (flags << 10) | (u1 << 12)
        return [word(frames, user[0], user[1], int(colour) << 1), word(seconds, user[2], user[3]),
                word(minutes, user[4], user[5]), word(hours, user[6], user[7])]

    def send(self, frames):
        """Send frames: [(hours, minutes, seconds, frames), ...] or
        [(time, user), ...]."""
        for f in frames:
            time, user = (f[0], f[1]) if len(f) == 2 else (f, (0,) * 8)
            for w in self.words(*time, user=user):
                self.chip.push(w)
