# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# Drivers for the buses of aircraft and spacecraft: MIL-STD-1553B as the
# bus controller with a monitor of the bus, ARINC 429 as a transmitter, and
# SpaceWire as a transmitter. Each takes a Chip from protocol_emulator.py
# and firmware images, as the drivers there do. None of the chip's pins can
# drive these buses' lines directly: each names the line driver or
# transceiver it needs.
#
# A module of its own for the reason more_protocols.py is a second: the
# Pico's memory. Copy the files you use to the board.

import protocol_emulator as pe

# The packet buffer's registers (hw/top.ml), as in more_protocols.py.
BUF_CTRL, BUF_PTR, BUF_END, BUF_DATA = 0x68, 0x69, 0x6A, 0x6B
BUF_WORDS = 1024
AUTOPULL, AUTOPUSH, CRC_IN = 1, 2, 8  # for configure(auto=...)

# Firmware constants (model/firmware.ml; sim/test_mil1553.ml checks them).
MIL1553_BC_NEXT = 1  # Firmware.mil1553_bc_next
MIL1553_MON_IDLE = 1  # Firmware.mil1553_mon_idle


def _set_crc(chip, poly, init, thread=0):
    """A thread's CRC register: polynomial, low power first, and start."""
    bank = pe.BANK * thread
    chip.write(pe.CRC_POLY + bank, poly & 0xFFFF)
    chip.write(pe.CRC_POLY + 1 + bank, poly >> 16)
    chip.write(pe.CRC_INIT + bank, init & 0xFFFF)
    chip.write(pe.CRC_INIT + 1 + bank, init >> 16)


class Mil1553Bc:
    """MIL-STD-1553B bus controller (mil1553_bc.hex on thread 0) with a bus
    monitor (mil1553_mon.hex on thread 1), at 1 Mbit/s: TX on pin 0 and
    TX-bar on pin 1, push-pull, both low while the transmitter is off; RX
    on pin 2, an input. On a real bus these go to a 1553 transceiver and
    through a coupling transformer to the bus; RX is the transceiver's
    receiver output, which shows every word on the bus.

    The chip makes each word's sync, Manchester code and parity, and reads
    the command to know how many data words follow it. The monitor records
    every word on the bus, this chip's and the remote terminals', into the
    packet buffer; heard() returns them. The core clock must be a multiple
    of 10 MHz: a bit is 10 ticks."""

    def __init__(self, chip, bc_image, mon_image, clock_hz=10_000_000):
        if clock_hz % 10_000_000 or not 10_000_000 <= clock_hz <= 650_000_000:
            raise ValueError("1 Mbit/s needs a core clock that is a multiple of 10 MHz")
        clkdiv = clock_hz // 10_000_000
        self.chip = chip
        chip.stop()
        chip.write(BUF_CTRL, 0)
        chip.load(bc_image, threads=(0,))
        chip.load(mon_image, threads=(1,))
        chip.configure(thread=0, set_base=0, set_count=2, threshold=16, out_msb_first=True,
                       timeout_vector=MIL1553_BC_NEXT, timeout=140, clkdiv=clkdiv)
        chip.configure(thread=1, in_base=2, threshold=16, in_msb_first=True,
                       timeout_vector=MIL1553_MON_IDLE, timeout=8, clkdiv=clkdiv,
                       auto=AUTOPUSH | CRC_IN)
        for t in (0, 1):
            _set_crc(chip, 1, 0, thread=t)  # x + 1: bit 0 is the parity
        self._record()
        chip.run(threads=(0, 1))  # TX and TX-bar low from the first instruction
        chip.set_pin_modes({0: pe.PUSH_PULL, 1: pe.PUSH_PULL})

    def _record(self):
        self.chip.write(BUF_CTRL, 0)
        self.chip.write(BUF_PTR, 0)
        self.chip.write(BUF_END, BUF_WORDS - 2)
        self.chip.write(BUF_CTRL, 2 | (1 << 2))  # record thread 1's RX FIFO

    @staticmethod
    def command(rt, transmit, subaddress, count):
        """A command word. [count] is the word count (32 is sent as 0) or,
        with subaddress 0 or 31, the mode code."""
        if not (0 <= rt <= 31 and 0 <= subaddress <= 31 and 0 <= count <= 32):
            raise ValueError("RT address, subaddress and count are 5 bits")
        return (rt << 11) | (int(bool(transmit)) << 10) | (subaddress << 5) | (count & 31)

    @staticmethod
    def data_words(cmd):
        """How many data words the BC sends after [cmd], as the firmware
        reads it: none for a transmit command; for a mode command one if
        the code is 16 or above; else the word count, 0 meaning 32."""
        sa, wc = (cmd >> 5) & 31, cmd & 31
        if (cmd >> 10) & 1:
            return 0
        if sa in (0, 31):
            return wc >> 4
        return wc or 32

    def idle(self):
        """Whether the BC is waiting for a command: the bus has been quiet
        for the response timeout since the last message."""
        s = self.chip.status(0)
        return s["pc"] == MIL1553_BC_NEXT and s["tx_level"] == 0

    def send(self, cmd, data=()):
        """One message: [cmd] and, for a receive command, its data words.
        The words of a message go out with no gap, a data word every 20 us,
        which a slow host cannot keep up with: so the BC is held while the
        command and up to three data words are queued, and released with
        them all there. Words after those are pushed as it takes them."""
        data = list(data)
        if len(data) != self.data_words(cmd):
            raise ValueError("this command takes %d data words" % self.data_words(cmd))
        if any(not 0 <= w <= 0xFFFF for w in data):
            raise ValueError("data words are 16 bits")
        while not self.idle():
            pass
        words = [cmd] + data
        self.chip.write(pe.CTRL, pe.Chip.ctrl(threads=(1,)))  # hold the BC
        self.chip.write_many([(pe.TX_FIFO, w) for w in words[:pe.FIFO_DEPTH]])
        self.chip.run(threads=(0, 1))
        for w in words[pe.FIFO_DEPTH:]:
            self.chip.push(w)

    def receive(self, rt, subaddress, data):
        """A receive command: [data] (1 to 32 words) to an RT's subaddress."""
        self.send(self.command(rt, False, subaddress, len(data)), data)

    def transmit(self, rt, subaddress, count):
        """A transmit command: the RT is to send [count] words."""
        self.send(self.command(rt, True, subaddress, count))

    def heard(self):
        """Every word on the bus since the last call, oldest first, as
        (value, command or status sync, parity right). Call it with the bus
        quiet (idle() true): recording stops while the buffer is read."""
        while not self.idle():
            pass
        n = self.chip.read(BUF_PTR)
        self.chip.write(BUF_CTRL, 0)
        self.chip.write(BUF_PTR, 0)
        raw = [self.chip.read(BUF_DATA) for _ in range(n)]
        self._record()
        return [(raw[k], bool(raw[k + 1] & 1), bool(raw[k + 1] & 2))
                for k in range(0, n - 1, 2)]


class Arinc429Tx:
    """ARINC 429 transmitter (arinc429_tx.hex): HI on pin 0 and LO on pin 1,
    push-pull, both low for NULL. These are the two logic inputs of an
    ARINC 429 line driver (HI-8586 or similar), which makes the +-10 V
    line. The chip turns the label round, makes the parity and keeps four
    bit times of NULL between words. [rate] is 100_000 or 12_500; a bit is
    20 ticks, so the core clock must be a multiple of 20 times it."""

    def __init__(self, chip, image, rate=100_000, clock_hz=10_000_000):
        if rate not in (100_000, 12_500):
            raise ValueError("ARINC 429 runs at 100 or 12.5 kbit/s")
        if clock_hz % (20 * rate):
            raise ValueError("the core clock must be a multiple of 20 x the bit rate")
        clkdiv = clock_hz // (20 * rate)
        if not 1 <= clkdiv <= 65535:
            raise ValueError("core clock out of range")
        self.chip = chip
        chip.stop()
        chip.load(image)
        chip.configure(set_base=0, set_count=2, threshold=16, in_msb_first=True, clkdiv=clkdiv)
        _set_crc(chip, 1, 0)  # x + 1: bit 0 is the parity
        chip.run()  # NULL from the first instruction
        chip.set_pin_modes({0: pe.PUSH_PULL, 1: pe.PUSH_PULL})

    @staticmethod
    def words(label, data, sdi=0, ssm=0):
        """The two TX words. [label] is the octal label as a number
        (0o205); [data] the 19 bits 11 to 29, bit 11 lowest."""
        if not (0 <= label <= 0o377 and 0 <= data < 1 << 19 and 0 <= sdi <= 3 and 0 <= ssm <= 3):
            raise ValueError("label 8 bits, data 19, SDI and SSM 2")
        return [label | (sdi << 8) | ((data & 0x3F) << 10), (data >> 6) | (ssm << 13)]

    def send(self, label, data, sdi=0, ssm=0):
        for w in self.words(label, data, sdi, ssm):
            self.chip.push(w)


class SpaceWireTx:
    """SpaceWire transmitter (spacewire_chars.hex on thread 0, which makes
    the characters and their parity, and spacewire_ds.hex on thread 1,
    which puts them on D and S, with CHAIN): D on pin 0 and S on pin 1,
    push-pull, both low before the first bit. A real link is LVDS: each pin
    feeds an LVDS driver. A bit is 5 ticks: [clkdiv] 1 is 2 Mbit/s at
    10 MHz and 10 Mbit/s, the start-up rate, at 50 MHz. Transmit only: no
    FCT is sent or awaited, and after a packet's last NULL the lines hold
    still, which a receiver takes for a disconnect."""

    EOP = 0x100

    def __init__(self, chip, chars_image, ds_image, clkdiv=1, clock_hz=10_000_000):
        if not 1 <= clkdiv <= 65535:
            raise ValueError("clkdiv out of range")
        self.chip = chip
        self.bitrate = clock_hz // (5 * clkdiv)
        self._end = None
        chip.stop()
        chip.write(BUF_CTRL, 0)
        chip.load(chars_image, threads=(0,))
        chip.load(ds_image, threads=(1,))
        chip.configure(thread=0, threshold=2, auto=AUTOPUSH | CRC_IN)
        chip.configure(thread=1, set_base=0, set_count=2, threshold=2, clkdiv=clkdiv, auto=AUTOPULL)
        _set_crc(chip, 1, 0, thread=0)  # x + 1: bit 0 is the parity
        chip.run(threads=(0, 1), chain=True)  # D and S low from the first instruction
        chip.set_pin_modes({0: pe.PUSH_PULL, 1: pe.PUSH_PULL})

    @staticmethod
    def nulls(n):
        if not 1 <= n <= 255:
            raise ValueError("1 to 255 NULLs a word")
        return 0x200 | n

    @classmethod
    def words(cls, packet, nulls_before=8, nulls_after=2):
        """TX words for NULLs, [packet] (bytes) as data characters, EOP,
        and NULLs after it."""
        if any(not 0 <= b <= 255 for b in packet):
            raise ValueError("a packet is bytes")
        out = [cls.nulls(nulls_before)] if nulls_before else []
        out += list(packet) + [cls.EOP]
        return out + ([cls.nulls(nulls_after)] if nulls_after else [])

    def send(self, packet, nulls_before=8, nulls_after=2):
        """Play the words from the packet buffer: a data character goes out
        every 50 ticks, faster than the host port can push."""
        words = self.words(packet, nulls_before, nulls_after)
        if len(words) > BUF_WORDS - 1:
            raise ValueError("at most 1021 bytes a packet")
        self.wait()
        self.chip.write(BUF_CTRL, 0)
        self.chip.write(BUF_PTR, 0)
        self.chip.write_many([(BUF_DATA, w) for w in words])
        self.chip.write(BUF_PTR, 0)
        self.chip.write(BUF_END, len(words))
        self._end = len(words)
        self.chip.write(BUF_CTRL, 1)  # play into thread 0's TX FIFO

    def wait(self):
        """Until the buffer has handed the chip every word played."""
        if self._end is None:
            return
        while self.chip.read(BUF_PTR) != self._end:
            pass
        self.chip.write(BUF_CTRL, 0)
        self._end = None
