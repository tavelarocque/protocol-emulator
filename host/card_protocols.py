# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# Drivers for ISO 7816-3 smart cards (T=0) and for a TPM 2.0 on SPI (the
# TCG TIS protocol). Each takes a Chip from protocol_emulator.py, as the
# drivers there do: the card reader its two firmware images, the TPM a
# SpiController already set up.
#
# A module of its own for the reason extra_protocols.py is one: the Pico's
# memory. Copy the files you use to the board.

import protocol_emulator as pe

ISO7816_POLL = 7  # Firmware.iso7816_poll, the reader's timeout vector; sim/test_iso7816.ml checks it
AUTOPULL, CRC_IN = 1, 8  # for configure(auto=...)


def _set_crc(chip, poly, init, thread=0):
    """A thread's CRC register: polynomial, low power first, and start."""
    bank = pe.BANK * thread
    chip.write(pe.CRC_POLY + bank, poly & 0xFFFF)
    chip.write(pe.CRC_POLY + 1 + bank, poly >> 16)
    chip.write(pe.CRC_INIT + bank, init & 0xFFFF)
    chip.write(pe.CRC_INIT + 1 + bank, init >> 16)


def iso7816_line(byte, inverse=False):
    """A byte as the line carries it, least significant bit first: itself
    in the direct convention; turned round and inverted in the inverse.
    Its own inverse either way."""
    if not inverse:
        return byte & 0xFF
    r = 0
    for k in range(8):
        r |= ((byte >> k) & 1) << (7 - k)
    return ~r & 0xFF


class Iso7816Error(Exception):
    pass


class Iso7816:
    """An ISO 7816-3 smart card reader, T=0: iso7816.hex on thread 0 and
    iso7816_clk.hex on thread 1. CLK on pin 0 and RST on pin 1,
    push-pull; I/O on pin 2, open-drain, with a pull-up to the card's
    supply. The firmware makes the clock, the reset, each character's start
    bit, parity and guard time, the error signal and the repetition; this
    class reads the answer to reset and runs T=0's procedure bytes.

    CLK is [card_hz], 1 to 5 MHz, the core clock over an even number. The
    etu is 372 clock cycles, the default (F 372, D 1): no PPS is sent.
    [inverse]: the card uses the inverse convention (TS 3Fh); the reader
    must be told before the reset. Each character from the card must be
    taken within about 12 etu (893 us at 5 MHz) or the next one is lost."""

    def __init__(self, chip, image, clock_image, clock_hz=10_000_000, card_hz=5_000_000,
                 inverse=False):
        div, rest = divmod(clock_hz, 2 * card_hz)
        if rest or div < 1 or not 1_000_000 <= card_hz <= 5_000_000:
            raise ValueError("CLK must be 1 to 5 MHz, the core clock over an even number")
        self.chip, self.inverse = chip, inverse
        self.atr = None
        self.started = False
        chip.stop()
        chip.load(image, threads=(0,))
        chip.load(clock_image, threads=(1,))
        chip.configure(thread=0, set_base=1, set_count=2, out_base=2, out_count=1, in_base=2,
                       threshold=8, timeout_vector=ISO7816_POLL, timeout=31, clkdiv=2 * div,
                       auto=AUTOPULL | CRC_IN)
        _set_crc(chip, 1, int(inverse))  # the parity: polynomial 1, from 0 or 1
        chip.configure(thread=1, sideset_base=0, sideset_count=1, clkdiv=div)

    def _get(self, polls):
        for _ in range(polls):
            w = self.chip.try_pop()
            if w is not None:
                return iso7816_line(w, self.inverse)
        raise Iso7816Error("the card did not answer")

    def _send(self, data):
        for b in data:
            self.chip.push(iso7816_line(b, self.inverse))

    def reset(self, polls=100_000):
        """Reset the card and return its answer to reset, checked. The
        first time the reader starts, CLK with it (a cold reset); after that
        thread 0 is stopped and started again, CLK running on (a warm
        reset)."""
        chip = self.chip
        if self.started:
            chip.run(threads=(1,))  # thread 0 stops; RST holds, CLK runs on
            while chip.try_pop() is not None:  # nothing from before
                pass
        chip.run(threads=(0, 1))  # one write: thread 0's tick is a period of CLK
        if not self.started:
            chip.set_pin_modes({0: pe.PUSH_PULL, 1: pe.PUSH_PULL, 2: pe.OPEN_DRAIN})
            self.started = True
        ts = self._get(polls)
        if ts != (0x3F if self.inverse else 0x3B):
            raise Iso7816Error("TS is %02X: not the convention the reader was set to" % ts)
        atr = [ts, self._get(polls)]
        y, tck = atr[1] >> 4, False
        while y:
            for bit in (1, 2, 4):
                if y & bit:
                    atr.append(self._get(polls))
            if not y & 8:
                break
            td = self._get(polls)
            atr.append(td)
            y = td >> 4
            tck = tck or (td & 15) != 0
        for _ in range((atr[1] & 15) + int(tck)):
            atr.append(self._get(polls))
        if tck:
            check = 0
            for b in atr[1:]:
                check ^= b
            if check:
                raise Iso7816Error("TCK does not check")
        self.atr = bytes(atr)
        return self.atr

    def command(self, cla, ins, p1, p2, data=b"", le=None, polls=100_000):
        """A T=0 command: data to the card (case 3) or [le] bytes from it
        (case 2; 0 means 256), or neither. Returns (data, status word).
        NULL procedure bytes (60h) are waited out; INS takes all the rest,
        INS inverted one byte."""
        if data and le is not None:
            raise ValueError("T=0 sends data or reads it in one command, not both")
        want = 0 if le is None else (le or 256)
        self._send([cla, ins, p1, p2, len(data) if data else want & 0xFF])
        left, out = list(data), []
        while True:
            pb = self._get(polls)
            if pb == 0x60:
                continue
            if pb & 0xF0 in (0x60, 0x90):
                return bytes(out), (pb << 8) | self._get(polls)
            if pb == ins:
                if left:
                    self._send(left)
                    left = []
                while len(out) < want:
                    out.append(self._get(polls))
            elif pb == ins ^ 0xFF:
                if left:
                    self._send([left.pop(0)])
                elif len(out) < want:
                    out.append(self._get(polls))
            else:
                raise Iso7816Error("procedure byte %02X" % pb)


class TpmError(Exception):
    pass


class TpmTis:
    """A TPM 2.0 on SPI, the TCG PC Client Platform TPM Profile's TIS
    interface, on the SPI controller ([spi], a protocol_emulator
    SpiController: P0 SCK, P1 MOSI, P2 MISO, P3 CS_N). Each transaction is a
    4-byte header (read or write, the size less one, a 24-bit address in
    0xD4xxxx, locality in bits 15:12), then the data. The TPM can hold it
    with wait states: MISO low on the header's last clock, then bytes whose
    last bit is 0 until it is ready. The SPI controller keeps CS_N low while
    it waits for the host's next byte, so the host clocks the wait bytes
    one at a time inside the one selection, as a TPM driver does."""

    ACCESS, STS, DATA_FIFO, DID_VID = 0x00, 0x18, 0x24, 0xF00
    VALID, ACTIVE, REQUEST = 0x80, 0x20, 0x02  # TPM_ACCESS
    STS_VALID, COMMAND_READY, GO, DATA_AVAIL, EXPECT = 0x80, 0x40, 0x20, 0x10, 0x08  # TPM_STS

    def __init__(self, spi, locality=0, max_waits=16, polls=50):
        if not 0 <= locality <= 4:
            raise ValueError("locality 0 to 4")
        self.chip = spi.chip
        self.base = 0xD40000 | (locality << 12)
        self.max_waits, self.polls = max_waits, polls
        self.waits = 0  # wait states seen, all told

    def _answers(self, k):
        """The next [k] words from the RX FIFO, as many at a time as are
        there."""
        out = []
        while len(out) < k:
            level = (self.chip.read(pe.STATUS) >> 4) & 7
            for _ in range(min(level, k - len(out))):
                out.append(self.chip.read(pe.RX_FIFO))
        return out

    def _bytes(self, data, last=False):
        """Clock [data] out (at most FIFO_DEPTH bytes) and return what came
        back; [last] ends the selection after them. Between calls every
        byte sent has been answered, so the FIFO has room for them all."""
        n = len(data)
        self.chip.write_many([(pe.TX_FIFO, (b << 8) | (int(last and i == n - 1) << 7))
                              for i, b in enumerate(data)])
        return self._answers(n)

    def transfer(self, read, reg, data_or_n):
        """One transaction: read [data_or_n] bytes from [reg], or write the
        bytes [data_or_n] there. Returns what was read."""
        n = data_or_n if read else len(data_or_n)
        if not 1 <= n <= 64:
            raise ValueError("1 to 64 bytes a transaction")
        addr = self.base | reg
        flow = self._bytes([(0x80 if read else 0) | (n - 1), addr >> 16, (addr >> 8) & 0xFF, addr & 0xFF])[3]
        waits = 0
        while not flow & 1:  # MISO's last bit in the header 0: a wait state, a byte at a time until 1
            waits += 1
            if waits > self.max_waits:
                self._bytes([0], last=True)
                raise TpmError("the TPM held the transfer past %d wait states" % self.max_waits)
            flow = self._bytes([0])[0]
        self.waits += waits
        data = bytes(n) if read else bytes(data_or_n)
        out = []
        for i in range(0, n, pe.FIFO_DEPTH):
            out += self._bytes(data[i:i + pe.FIFO_DEPTH], last=i + pe.FIFO_DEPTH >= n)
        return bytes(out) if read else None

    def read(self, reg, n):
        return self.transfer(True, reg, n)

    def write(self, reg, data):
        self.transfer(False, reg, bytes(data))

    def request_locality(self):
        """Ask for the locality and wait until the TPM grants it."""
        self.write(self.ACCESS, [self.REQUEST])
        for _ in range(self.polls):
            access = self.read(self.ACCESS, 1)[0]
            if access & (self.VALID | self.ACTIVE) == self.VALID | self.ACTIVE:
                return access
        raise TpmError("locality not granted")

    def release_locality(self):
        self.write(self.ACCESS, [self.ACTIVE])

    def did_vid(self):
        """(device id, vendor id): 15D1h is Infineon's."""
        v = self.read(self.DID_VID, 4)
        return v[2] | (v[3] << 8), v[0] | (v[1] << 8)

    def status(self):
        return self.read(self.STS, 1)[0]

    def _until(self, mask, value):
        for _ in range(self.polls):
            sts = self.read(self.STS, 1)[0]
            if sts & (self.STS_VALID | mask) == self.STS_VALID | value:
                return sts
        raise TpmError("TPM_STS never showed %02X" % value)

    def command(self, cmd):
        """Send one TPM 2.0 command through the FIFO and return the
        response, its size checked."""
        self.write(self.STS, [self.COMMAND_READY])
        sts = self.read(self.STS, 4)  # status, then the burst count
        if not sts[0] & self.COMMAND_READY:
            sts = self._until(self.COMMAND_READY, self.COMMAND_READY)
            sts = self.read(self.STS, 4)
        burst = max(1, min(64, sts[1] | (sts[2] << 8)))
        for i in range(0, len(cmd), burst):
            self.write(self.DATA_FIFO, cmd[i:i + burst])
        if self.status() & (self.STS_VALID | self.EXPECT) != self.STS_VALID:
            raise TpmError("the TPM expects more of the command")
        self.write(self.STS, [self.GO])
        self._until(self.DATA_AVAIL, self.DATA_AVAIL)
        rsp = bytearray(self.read(self.DATA_FIFO, 10))
        size = (rsp[2] << 24) | (rsp[3] << 16) | (rsp[4] << 8) | rsp[5]
        while len(rsp) < size:
            rsp += self.read(self.DATA_FIFO, min(burst, size - len(rsp)))
        if self.status() & self.DATA_AVAIL:
            raise TpmError("the response is longer than its size says")
        self.write(self.STS, [self.COMMAND_READY])
        return bytes(rsp)


def tpm2_startup(clear=True):
    """TPM2_Startup(SU_CLEAR or SU_STATE): tag 8001h (no sessions), size,
    command code 144h, startup type."""
    return bytes([0x80, 0x01, 0, 0, 0, 12, 0, 0, 0x01, 0x44, 0, 0 if clear else 1])


def tpm2_response_code(rsp):
    return (rsp[6] << 24) | (rsp[7] << 16) | (rsp[8] << 8) | rsp[9]
