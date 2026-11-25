# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# Drivers for things that move or measure movement: DShot to a motor's
# speed controller, XY2-100 to a laser galvanometer scanner, and a digital
# caliper's data port, the chip playing the caliper. Each takes a Chip from
# protocol_emulator.py and firmware images, as the drivers there do.
#
# A fourth module for the reason more_protocols.py is a second: the Pico's
# memory. Copy the files you use to the board.

import protocol_emulator as pe

# The packet buffer's registers (hw/top.ml), as in more_protocols.py.
BUF_CTRL, BUF_PTR, BUF_END, BUF_DATA = 0x68, 0x69, 0x6A, 0x6B


def _set_crc(chip, poly, init, thread=0):
    """A thread's CRC register: polynomial, low power first, and start."""
    bank = pe.BANK * thread
    chip.write(pe.CRC_POLY + bank, poly & 0xFFFF)
    chip.write(pe.CRC_POLY + 1 + bank, poly >> 16)
    chip.write(pe.CRC_INIT + bank, init & 0xFFFF)
    chip.write(pe.CRC_INIT + 1 + bank, init >> 16)


class Dshot:
    """DShot to an ESC (dshot.hex) on pin 0, push-pull, low between frames.
    The chip makes each frame's checksum. A bit is 8 ticks, a 0 high for 3
    and a 1 for 6: [rate] (150, 300, 600 or 1200) sets the divider, rounded,
    and [bitrate] is what that gives: at 10 MHz 600 is 625 kbit/s, at
    50 MHz 600 is 625 kbit/s and 300 is 297.6 kbit/s. Bidirectional DShot
    is not supported."""

    RATES = (150, 300, 600, 1200)

    def __init__(self, chip, image, rate=600, clock_hz=10_000_000):
        if rate not in self.RATES:
            raise ValueError("DShot rate must be 150, 300, 600 or 1200")
        clkdiv = (clock_hz + 4000 * rate) // (8000 * rate)
        if clkdiv < 1:
            raise ValueError("core clock too slow for this rate")
        self.bitrate = clock_hz // (8 * clkdiv)
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(sideset_base=0, sideset_count=1, threshold=16, out_msb_first=True,
                       clkdiv=clkdiv)
        _set_crc(chip, 0x8, 0)  # x^4 + 1: the exclusive or of the nibbles
        chip.run()  # the line is low from the first instruction
        chip.set_pin_modes({0: pe.PUSH_PULL})

    @staticmethod
    def word(value, telemetry=False):
        """The TX word: 0 disarms, 1 to 47 are commands, 48 to 2047 throttle."""
        if not 0 <= value <= 2047:
            raise ValueError("DShot value out of range")
        return (value << 1) | int(bool(telemetry))

    def send(self, value, telemetry=False):
        self.chip.push(self.word(value, telemetry))

    def command(self, n):
        """A command (1 to 47); ESCs act on one only with the telemetry
        bit set, and most want it several times in a row."""
        if not 1 <= n <= 47:
            raise ValueError("DShot commands are 1 to 47")
        self.send(n, telemetry=True)


class Xy2100:
    """XY2-100 to a galvanometer scanner (xy2_x.hex on thread 0, xy2_y.hex
    on thread 1, with CHAIN): CLK on pin 0, SYNC on pin 1, X on pin 2, Y on
    pin 3, all push-pull; each needs an RS-422 line driver for a real
    scanner. The clock is the core clock over 5 x [clkdiv]: 1 at 10 MHz
    and 5 at 50 MHz make the standard 2 MHz. Positions are signed 16-bit.
    [first]: up to two points queued before the clock starts."""

    def __init__(self, chip, x_image, y_image, clkdiv=1, first=()):
        if not 1 <= clkdiv <= 65535:
            raise ValueError("clkdiv out of range")
        self.chip = chip
        self._end = None
        chip.stop()
        chip.write(BUF_CTRL, 0)
        chip.load(x_image, threads=(0,))
        chip.load(y_image, threads=(1,))
        chip.configure(thread=0, sideset_base=0, sideset_count=2, out_base=2, set_base=2,
                       threshold=16, out_msb_first=True, clkdiv=clkdiv)
        chip.configure(thread=1, out_base=3, set_base=3, threshold=16, out_msb_first=True,
                       clkdiv=clkdiv)
        for t in (0, 1):
            _set_crc(chip, 1, 1, thread=t)  # x + 1, from the control bits' one 1
        chip.set_pin_modes({0: pe.PUSH_PULL, 1: pe.PUSH_PULL, 2: pe.PUSH_PULL, 3: pe.PUSH_PULL})
        if len(first) > 2:
            raise ValueError("at most two points before the start")
        for w in self.words(first):
            chip.write(pe.TX_FIFO, w)
        chip.run(threads=(0, 1), chain=True)  # one write: the threads keep step

    @staticmethod
    def words(points):
        out = []
        for x, y in points:
            if not (-32768 <= x <= 32767 and -32768 <= y <= 32767):
                raise ValueError("positions are signed 16-bit")
            out += [x & 0xFFFF, y & 0xFFFF]
        return out

    def write(self, points):
        """Send [(x, y), ...] through the FIFO. The clock waits, low with
        SYNC low, whenever the next point is not there in time."""
        self.wait()
        for w in self.words(points):
            self.chip.push(w)

    def play(self, points):
        """Up to 511 points from the packet buffer, frame after frame with
        no gap: 100,000 a second at 2 MHz."""
        words = self.words(points)
        if not 0 < len(words) <= 1022:
            raise ValueError("1 to 511 points")
        self.wait()
        self.chip.write(BUF_CTRL, 0)
        self.chip.write(BUF_PTR, 0)
        self.chip.write_many([(BUF_DATA, w) for w in words])
        self.chip.write(BUF_PTR, 0)
        self.chip.write(BUF_END, len(words))
        self._end = len(words)
        self.chip.write(BUF_CTRL, 1)  # play into thread 0

    def wait(self):
        """Until the buffer has handed the chip every point played."""
        if self._end is None:
            return
        while self.chip.read(BUF_PTR) != self._end:
            pass
        self.chip.write(BUF_CTRL, 0)
        self._end = None


class Caliper:
    """The chip as a digital caliper's data port (caliper.hex): CLK on pin 0
    and DATA on pin 1, push-pull; a real caliper's lines are 1.5 V, so a
    reader built for one may need a level shifter. A bit is about 13 us
    (8 ticks); CLK rests high for 64 bit times or more after each packet."""

    def __init__(self, chip, image, clock_hz=10_000_000):
        clkdiv = (clock_hz * 13 // 1_000_000 + 4) // 8
        if not 1 <= clkdiv <= 65535:
            raise ValueError("core clock out of range")
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(sideset_base=0, sideset_count=1, out_base=1, threshold=16, clkdiv=clkdiv)
        chip.run()  # CLK high from the first instruction, as at rest
        chip.set_pin_modes({0: pe.PUSH_PULL, 1: pe.PUSH_PULL})

    @staticmethod
    def words(counts, negative=False, inches=False):
        """A reading in counts: hundredths of a millimetre, or with
        [inches] halves of a thousandth of an inch."""
        if not 0 <= counts <= 0xFFFF:
            raise ValueError("reading out of range")
        return [counts, int(bool(negative)) | (int(bool(inches)) << 1)]

    def send_counts(self, counts, negative=False, inches=False):
        for w in self.words(counts, negative, inches):
            self.chip.push(w)

    def send(self, value, inches=False):
        """A reading in millimetres, or in inches with [inches]."""
        counts = int(round(abs(value) * (2000 if inches else 100)))
        self.send_counts(counts, value < 0, inches)
