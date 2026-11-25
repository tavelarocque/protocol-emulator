# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# A driver for Futaba SBUS, the serial bus of radio control receivers. It
# takes a Chip from protocol_emulator.py and a firmware image, as the
# drivers there do.
#
# A module of its own for the same reason more_protocols.py and
# extra_protocols.py are: the Pico's memory. Copy the files you use to the
# board.

import protocol_emulator as pe

# The packet buffer's registers (as in more_protocols.py, which need not
# be on the board for this).
BUF_CTRL, BUF_PTR, BUF_END, BUF_DATA = 0x68, 0x69, 0x6A, 0x6B
CRC_INVERT = 4  # for configure(auto=...)


class SbusTx:
    """Futaba SBUS transmitter (sbus_tx.hex) on pin 0, as a radio control
    receiver sends its channels: 100 kbit/s, the line resting low. The
    firmware makes each character (start bit, the 8 bits inverted, even
    parity, two stop bits); this class packs the channels into the 25
    bytes of a message and hands them over through the packet buffer, so
    that the bytes follow one another with no rest however slow the host
    is. A message is 3 ms long."""

    def __init__(self, chip, image, clock_hz=10_000_000, baud=100_000):
        bit = clock_hz // baud
        if clock_hz % baud or not 6 <= bit <= 65541:
            raise ValueError("%d Hz is not a whole bit time of 6 to 65541 clocks" % baud)
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(threshold=8, auto=CRC_INVERT)
        # The CRC register as a parity bit: polynomial 1, from 0.
        chip.write(pe.CRC_POLY, 1)
        chip.write(pe.CRC_POLY + 1, 0)
        chip.write(pe.CRC_INIT, 0)
        chip.write(pe.CRC_INIT + 1, 0)
        chip.write(BUF_CTRL, 0)
        chip.run()
        while chip.status()["pc"] == 0:  # the program's first instruction puts the line low
            pass
        chip.set_pin_modes({0: pe.PUSH_PULL})
        chip.push(bit - 6)

    @staticmethod
    def message(channels, ch17=False, ch18=False, frame_lost=False, failsafe=False):
        """The 25 bytes of a message: 0x0F, the sixteen channels (0 to
        2047 each) packed least significant bit first, the flags, 0x00."""
        if len(channels) != 16:
            raise ValueError("a message has 16 channels")
        packed, held, bits = [], 0, 0
        for value in channels:
            if not 0 <= value <= 2047:
                raise ValueError("a channel is 0 to 2047")
            held |= value << bits
            bits += 11
            while bits >= 8:
                packed.append(held & 0xFF)
                held >>= 8
                bits -= 8
        flags = int(ch17) | (int(ch18) << 1) | (int(frame_lost) << 2) | (int(failsafe) << 3)
        return [0x0F] + packed + [flags, 0x00]

    def send_bytes(self, data):
        """Send [data] (1023 bytes at most), each as one character, back
        to back, and return when the firmware has taken the last: it is
        then on the line, for 12 bit times at most."""
        data = list(data)
        if not 0 < len(data) < 1024:
            raise ValueError("1 to 1023 bytes")
        self.chip.write(BUF_CTRL, 0)
        self.chip.write(BUF_PTR, 0)
        self.chip.write_many([(BUF_DATA, b) for b in data])
        self.chip.write(BUF_PTR, 0)
        self.chip.write(BUF_END, len(data))
        self.chip.write(BUF_CTRL, 1)  # play into thread 0's TX FIFO
        while self.chip.read(BUF_PTR) != len(data) or self.chip.status()["tx_level"]:
            pass
        self.chip.write(BUF_CTRL, 0)

    def send(self, channels, ch17=False, ch18=False, frame_lost=False, failsafe=False):
        """One message. A receiver sends one every 7 or 14 ms."""
        self.send_bytes(self.message(channels, ch17, ch18, frame_lost, failsafe))
