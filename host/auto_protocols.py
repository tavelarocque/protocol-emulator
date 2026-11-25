# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# Drivers for two automotive protocols: an SAE J2716 SENT sensor's
# transmitter, and a node sending SAE J1850 VPW frames, the GM and
# Chrysler OBD-II bus. The firmware does the line coding, the timing and
# the CRC of each; the host sends the payload. Each takes a Chip from
# protocol_emulator.py and a firmware image, as the drivers there do.
#
# A module of its own for the reason more_protocols.py is one: the Pico's
# memory. Copy the files you use to the board.

import protocol_emulator as pe


def _crc_register(chip, poly, init):
    """Thread 0's CRC register: its polynomial and the value it starts
    from, each the low half then the high half."""
    for k, (p, i) in enumerate(((poly, init), (0, 0))):
        chip.write(pe.CRC_POLY + k, p)
        chip.write(pe.CRC_INIT + k, i)


class SentTx:
    """SAE J2716 SENT, a sensor's side (sent_tx.hex), on pin 0, push-pull:
    frames of a calibration pulse, a status nibble, [nibbles] data nibbles
    and the CRC-4 nibble, which the chip computes, each frame followed by
    a pause pulse. A tick is [tick_us], 3 to 90; the chip counts half
    ticks, so a half tick must be a whole number of clock cycles."""

    CRC_POLY, CRC_INIT = 0b1011, 0b1100  # Firmware.sent_crc_poly, sent_crc_init

    def __init__(self, chip, image, nibbles=6, tick_us=3, clock_hz=10_000_000):
        clkdiv = clock_hz * tick_us // 2_000_000
        if not 1 <= nibbles <= 6:
            raise ValueError("1 to 6 data nibbles")
        if not 3 <= tick_us <= 90 or clkdiv * 2_000_000 != clock_hz * tick_us or clkdiv > 65535:
            raise ValueError("a tick of %d us is not a whole number of half ticks" % tick_us)
        self.chip = chip
        self.nibbles = nibbles
        chip.stop()
        chip.load(image)
        chip.configure(set_base=0, set_count=1, threshold=16, out_msb_first=True, clkdiv=clkdiv)
        _crc_register(chip, self.CRC_POLY, self.CRC_INIT)
        chip.run()
        while chip.status()["pc"] == 0:  # the first instruction puts the line high
            pass
        chip.set_pin_modes({0: pe.PUSH_PULL})
        chip.push(nibbles - 1)

    def words(self, status, data):
        """The TX words for one frame: the status nibble and the data
        nibbles, four to a word, the first in bits 15:12."""
        nibbles = [status] + list(data)
        if len(nibbles) != self.nibbles + 1 or not all(0 <= n <= 15 for n in nibbles):
            raise ValueError("a status nibble and %d data nibbles, each 0 to 15" % self.nibbles)
        words = []
        for i in range(0, len(nibbles), 4):
            w = 0
            for k, n in enumerate(nibbles[i:i + 4]):
                w |= n << (12 - 4 * k)
            words.append(w)
        return words

    def send(self, status, data):
        """Queue one frame. The line keeps the pause pulse after the last
        frame until the next one."""
        for w in self.words(status, data):
            self.chip.push(w)


class J1850Vpw:
    """SAE J1850 VPW at 10.4 kbit/s (j1850_tx.hex): pin 0, push-pull, to a
    bus transceiver's input, high for active. The chip makes the start of
    frame, the symbols, the CRC-8 and the end of data. It only sends: it
    neither waits for an idle bus nor gives way in arbitration."""

    CRC_POLY = 0xB8  # Firmware.j1850_crc_poly: 0x1D reversed

    def __init__(self, chip, image, clock_hz=10_000_000):
        clkdiv = clock_hz // 1_000_000  # a tick of 1 us
        if clkdiv * 1_000_000 != clock_hz:
            raise ValueError("the core clock must be a whole number of MHz")
        self.chip = chip
        chip.stop()
        chip.load(image)
        # The CRC register reads inverted (auto bit 4).
        chip.configure(set_base=0, set_count=1, threshold=8, out_msb_first=True,
                       auto=4, clkdiv=clkdiv)
        _crc_register(chip, self.CRC_POLY, 0xFF)
        chip.run()
        while chip.status()["pc"] == 0:  # the first instruction puts the bus passive
            pass
        chip.set_pin_modes({0: pe.PUSH_PULL})

    @staticmethod
    def words(data):
        """The TX words for a frame of [data], the bytes before the CRC:
        the header (priority, target, source), then the mode and its data,
        1 to 11 bytes in all."""
        if not 1 <= len(data) <= 11 or not all(0 <= b <= 255 for b in data):
            raise ValueError("1 to 11 bytes before the CRC")
        return [len(data)] + [b << 8 for b in data]

    def send(self, data):
        """Send one frame and return when its last symbol has ended."""
        for w in self.words(data):
            self.chip.push(w)
        self.chip.pop()
