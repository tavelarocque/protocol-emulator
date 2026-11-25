# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# Drivers for Sony SIRC infrared remotes, SLE 4442 memory cards and TI's
# BQ2022A (an SDQ part, on the 1-Wire engine). Each takes a Chip from
# protocol_emulator.py and a firmware image, as the drivers there do.
#
# A module of its own for the reason extra_protocols.py is one: the Pico's
# memory. Copy the files you use to the board.

import protocol_emulator as pe


class SircTx:
    """Sony SIRC infrared transmitter with carrier (sirc_tx.hex): an IR LED
    on pin 0, lit when high. The firmware makes the whole frame and starts
    frames 45 ms apart, as a remote repeats them."""

    def __init__(self, chip, image, clock_hz=10_000_000, carrier_hz=40_000):
        self.chip = chip
        clkdiv = (clock_hz + carrier_hz) // (2 * carrier_hz)  # half a carrier period
        chip.stop()
        chip.load(image)
        chip.configure(sideset_base=0, sideset_count=1, threshold=16, in_msb_first=True,
                       clkdiv=clkdiv)
        chip.run()  # pins reset high: the firmware turns the LED off before the pin drives it
        chip.set_pin_modes({0: pe.PUSH_PULL})

    @staticmethod
    def words(command, address, bits=12, extended=0):
        """The TX words for one frame of [bits] (12, 15 or 20): a 7-bit
        command, then a 5-bit address (8 bits in a 15-bit frame), then in
        a 20-bit frame 8 extended bits."""
        width = {12: 5, 15: 8, 20: 5}.get(bits)
        if width is None:
            raise ValueError("a SIRC frame is 12, 15 or 20 bits")
        if not (0 <= command < 128 and 0 <= address < 1 << width
                and 0 <= extended < (256 if bits == 20 else 1)):
            raise ValueError("a field does not fit its bits")
        frame = command | (address << 7) | (extended << 12)
        return [bits, frame & 0xFFFF] + ([frame >> 16] if bits == 20 else [])

    def send(self, command, address, bits=12, extended=0, repeat=1):
        """Send the frame [repeat] times, 45 ms apart, as a remote does
        while its key is held."""
        w = self.words(command, address, bits, extended)
        for _ in range(repeat):
            for v in w:
                self.chip.push(v)


class Sle4442Error(Exception):
    pass


class Sle4442:
    """SLE 4442 memory card reader (sle4442.hex): RST on pin 0 and CLK on
    pin 1, push-pull; I/O on pin 2, open-drain, with the card's pull-up. A
    tick is 5 us, so the core clock must be a multiple of 200 kHz; CLK runs
    at 40 kHz."""

    READ_MAIN, READ_SECURITY, READ_PROTECTION = 0x30, 0x31, 0x34

    def __init__(self, chip, image, clock_hz=10_000_000):
        if clock_hz <= 0 or clock_hz % 200_000:
            raise ValueError("the core clock must be a multiple of 200 kHz")
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(sideset_base=1, sideset_count=1, set_base=0, set_count=3,
                       out_base=2, out_count=1, in_base=2, threshold=16,
                       clkdiv=clock_hz // 200_000)
        chip.run()  # RST low and I/O released before the pins drive
        chip.set_pin_modes({0: pe.PUSH_PULL, 1: pe.PUSH_PULL, 2: pe.OPEN_DRAIN})

    @staticmethod
    def words(n, reset=False, command=None):
        """The TX words for an operation: a reset, or a command (control,
        address, data), then [n] bytes clocked in from the card."""
        if not 0 <= n <= 511 or (reset and command is not None):
            raise ValueError("0 to 511 bytes, after a reset or a command")
        w = [n | (int(reset) << 9) | (int(command is not None) << 10)]
        if command is not None:
            control, address, data = command
            w += [control | (address << 8), (data << 8) | 1]
        return w

    def _run(self, n, reset=False, command=None):
        for v in self.words(n, reset, command):
            self.chip.push(v)
        return bytes([self.chip.pop() & 0xFF for _ in range(n)])

    def reset(self):
        """Reset the card; returns its 4-byte answer to reset. A card that
        is not there answers FF FF FF FF."""
        atr = self._run(4, reset=True)
        if atr == b"\xff\xff\xff\xff":
            raise Sle4442Error("no card")
        return atr

    def read_main(self, address=0):
        """Main memory from [address] to its end (address 255), as the
        card sends it."""
        if not 0 <= address <= 255:
            raise ValueError("address out of range")
        return self._run(256 - address, command=(self.READ_MAIN, address, 0))

    def read_protection(self):
        """The 32 protection bits, as 4 bytes: a 0 bit locks that byte of
        the first 32."""
        return self._run(4, command=(self.READ_PROTECTION, 0, 0))

    def read_security(self):
        """The 4 bytes of security memory: the error counter first (the
        reference data reads as zeros until the card is unlocked)."""
        return self._run(4, command=(self.READ_SECURITY, 0, 0))


class Bq2022a:
    """TI's BQ2022A, a 1-kbit EPROM on a single-wire SDQ interface, as in
    battery packs that identify themselves. Its reset, presence and time
    slots have 1-Wire's standard-speed timing, so it runs on the 1-Wire
    engine (onewire.hex) with no firmware of its own: [ow] is a
    protocol_emulator.OneWire. It answers READ ROM and SKIP ROM only, so
    it is alone on its wire."""

    READ_MEMORY = 0xF0  # with a CRC at the end of the field
    SIZE = 128  # bytes

    def __init__(self, ow):
        self.ow = ow

    def read_rom(self):
        """Family code (09h unless TI gave the customer another), 48-bit
        serial number and CRC8, checked."""
        return self.ow.read_rom()

    def read_memory(self, address=0):
        """The bytes from [address] to the end of the field. The part
        answers the command and address with their CRC8, and the data with
        its CRC8; both are checked."""
        if not 0 <= address < self.SIZE:
            raise ValueError("address out of range")
        self.ow.select()
        command = [self.READ_MEMORY, address & 0xFF, address >> 8]
        self.ow.write(command)
        if self.ow.read(1)[0] != pe.onewire_crc8(command):
            raise pe.OneWireError("the command and address came back with a bad CRC")
        data = self.ow.read(self.SIZE - address)
        if self.ow.read(1)[0] != pe.onewire_crc8(data):
            raise pe.OneWireError("data CRC error")
        return data
