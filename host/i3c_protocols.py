# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# Driver for the I3C SDR controller (i3c.hex). It takes a Chip from
# protocol_emulator.py and a firmware image, as the drivers there do.
#
# A module of its own for the same reason more_protocols.py is one: the
# Pico's memory. Copy the files you use to the board.

import protocol_emulator as pe


class I3c:
    """MIPI I3C controller, SDR (i3c.hex): SDA on pin 0, open-drain; SCL on
    pin 1, push-pull. The chip does the bits: START, repeated START and
    STOP, the T bit after each byte written (odd parity, from the CRC
    register), the end of a read in the target's T bit, and ENTDAA's 64
    arbitrated bits and the parity bit after a dynamic address. This class
    builds the words: a segment (an address and, for a read, how many
    bytes), the bytes to write, and STOP.

    The bus needs a pull-up on SDA: the chip cannot switch a pin between
    open-drain and push-pull while a frame runs, so SDA is open-drain
    throughout and every bit is timed to the specification's open-drain
    limits. A tick must be 100 ns or more: SCL is then 2 MHz (5 ticks a
    bit), at any core clock. A pure I3C bus only: no I2C devices."""

    IDLE = 3  # Firmware.i3c_idle
    ENDED = 35  # Firmware.i3c_ended
    BROADCAST = 0x7E
    STOP = 0x4000
    RSTDAA, ENTDAA, SETDASA = 0x06, 0x07, 0x87

    def __init__(self, chip, image, clock_hz=10_000_000, scl_hz=2_000_000):
        clkdiv = clock_hz // (5 * scl_hz)
        if clkdiv < 1 or clock_hz > 10_000_000 * clkdiv:
            raise ValueError("a tick must be 100 ns or more: SCL at most 2 MHz")
        self.chip = chip
        self.open = False  # a frame is under way: the next segment gets a repeated START
        chip.stop()
        chip.load(image)
        chip.configure(start=self.IDLE, out_base=0, set_base=0, in_base=0, sideset_base=1,
                       sideset_count=1, threshold=16, timeout_vector=self.ENDED, timeout=0,
                       clkdiv=clkdiv, out_msb_first=True, in_msb_first=True, auto=4)
        # The CRC register as a parity bit: polynomial 1, from 0, read inverted.
        for k, w in enumerate((1, 0)):
            chip.write(pe.CRC_POLY + k, w)
            chip.write(pe.CRC_INIT + k, 0)
        chip.set_pin_modes({0: pe.OPEN_DRAIN, 1: pe.PUSH_PULL})
        chip.run()

    @staticmethod
    def segment(address, read, count=0):
        """A segment word: [count] is a read's most bytes (1 to 63), 0 for an
        ENTDAA round."""
        if not 0 <= address <= 0x7F or not 0 <= count <= 63:
            raise ValueError("address or count out of range")
        return 0x8000 | (((address << 1) | int(read)) << 7) | (int(read) << 6) | count

    @staticmethod
    def data(byte):
        return (byte & 0xFF) << 6

    @staticmethod
    def odd_parity(value, bits=8):
        ones = 0
        for k in range(bits):
            ones += (value >> k) & 1
        return 1 - (ones & 1)

    @staticmethod
    def valid_address(address):
        """A dynamic address may not be reserved (0 to 7, 0x7E) or one bit
        away from the broadcast address 0x7E."""
        if not 0x08 <= address <= 0x7D:
            return False
        return address not in (0x3E, 0x5E, 0x6E, 0x76, 0x7A, 0x7C)

    def stop(self):
        """End the frame with STOP."""
        if self.open:
            self.chip.push(self.STOP)
            self.open = False

    def _ack(self):
        return self.chip.pop() == 0

    def write(self, address, data, stop=True):
        """A private write (or, at 0x7E, a broadcast CCC and its data).
        Returns whether the address was ACKed; if not, the bytes are not
        sent. Without [stop] the frame stays open for a repeated START."""
        self.chip.push(self.segment(address, False))
        self.open = True
        for b in data:
            self.chip.push(self.data(b))
        acked = self._ack()
        if stop:
            self.stop()
        return acked

    def read(self, address, n, stop=True):
        """A private read of up to [n] bytes (1 to 63). Returns the bytes,
        fewer where the target ended the read with T = 0, or None if no
        target ACKed the address."""
        if not 1 <= n <= 63:
            raise ValueError("a read is 1 to 63 bytes")
        self.chip.push(self.segment(address, True, n))
        self.open = True
        got = None
        if self._ack():
            got = []
            while len(got) < n:
                w = self.chip.pop()
                got.append((w >> 1) & 0xFF)
                if not w & 1:
                    break
        if stop:
            self.stop()
        return got

    def write_read(self, address, data, n):
        """A write, a repeated START and a read: a register read."""
        if not self.write(address, data, stop=False):
            self.stop()
            return None
        return self.read(address, n)

    def ccc(self, code, data=(), stop=True):
        """A broadcast CCC; whether any target ACKed 0x7E."""
        return self.write(self.BROADCAST, [code] + list(data), stop=stop)

    def rstdaa(self):
        """Every target forgets its dynamic address."""
        return self.ccc(self.RSTDAA)

    def setdasa(self, static, dynamic):
        """The target at static address [static] takes [dynamic]."""
        if not self.valid_address(dynamic):
            raise ValueError("reserved dynamic address")
        self.ccc(self.SETDASA, stop=False)
        return self.write(static, [dynamic << 1])

    def entdaa(self, addresses):
        """Dynamic address assignment: each target that has no address
        answers, the one with the lowest provisioned ID first, and gets the
        next of [addresses]. Returns [(provisioned ID, BCR, DCR, address,
        ACKed)], one for each target that answered. Once every address is
        given out the frame ends, and any target still without one waits
        for the next ENTDAA."""
        for a in addresses:
            if not self.valid_address(a):
                raise ValueError("reserved dynamic address")
        got = []
        self.ccc(self.ENTDAA, stop=False)
        for a in addresses:
            self.chip.push(self.segment(self.BROADCAST, True, 0))
            if not self._ack():
                break
            self.chip.push(a << 9)
            w = [self.chip.pop() for _ in range(4)]
            pid = (w[0] << 32) | (w[1] << 16) | w[2]
            got.append((pid, w[3] >> 8, w[3] & 0xFF, a, self._ack()))
        self.stop()
        return got
