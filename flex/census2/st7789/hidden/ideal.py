#!/usr/bin/env python3
"""An ideal ST7789 host waveform, written in Python, for validating accept.py.

This is NOT firmware for the chip and says nothing about how to write it.
It draws the four lines directly, as a list of (cycle, pins) changes in the
format pe_sim prints ("pins CYCLE XX"), from the transfers themselves.

waveform(transfers, variant, cycles) gives the changes. Variant "good" is a
correct waveform with every limit of TASK.md met at its fewest whole cycles
(SCL high 2 and low 2, so its period is 4 cycles = 80 ns, the least above
66 ns); "good_relaxed" is correct with slack and with noise where the
display does not look. Every other variant plants one fault (see VARIANTS).

Run as a stand-in for pe_sim (validate.py installs it under that name in a
run directory): it then reads the transfers back from the -tx file, which
holds the task sheet's words (one per byte, bit 8 a command byte, bit 9 the
last byte of a transfer), and reads the variant from variant.txt beside it.
Its reading of the words (transfers_of below) is written apart from
accept.py's tx_words, and it stops with an error, which the judge counts as
a failure, if the stream is not what the sheet says."""
import os
import random
import sys

SDA, SCL, DCX, CSX = 0, 1, 2, 3

VARIANTS = {
    "good": "correct, every time at its fewest whole cycles",
    "good_relaxed": "correct, with random slack, a slower uneven clock, and noise on "
                    "SCL, SDA, D/CX while CSX is high and on P4 to P7 throughout",
    "bad_bit": "one data bit inverted",
    "bad_lsb": "bytes sent least significant bit first",
    "bad_dc_level": "data bytes sent with D/CX low",
    "bad_dc_cmd": "the first command byte sent with D/CX high",
    "bad_extra": "one extra NOP transfer at the end",
    "bad_missing": "the last byte of the last transfer left out",
    "bad_stray_bits": "three stray SCL pulses after the last byte of the first transfer",
    "bad_period_high": "one SCL pulse high for 1 cycle: period 60 ns (limit 66)",
    "bad_period_low": "one SCL low gap of 1 cycle: period 60 ns (limit 66)",
    "bad_sda_setup": "SDA changes in the same cycle as one SCL rising edge",
    "bad_dc_setup": "D/CX reaches its level in the same cycle as one 8th SCL rising edge",
    "bad_dc_hold": "D/CX changes in the same cycle as the falling edge after one 8th bit",
    "bad_cs_high": "CSX high for 20 ns between transfers (limit 40)",
    "bad_cs_split": "CSX pulses high between a command byte and its data",
    "bad_cs_stuck": "CSX never returns high after the last transfer",
    "bad_cs_early": "CSX rises in the same cycle as the last SCL falling edge",
    "bad_css": "the first SCL rising edge in the same cycle as CSX falls",
    "bad_scl_idle": "SCL only goes low in the same cycle as the first CSX falling edge",
    "bad_late": "starts so late that it is not finished when the run ends",
}


class Wave:
    def __init__(self):
        self.t, self.level, self.changes = 0, 0xFF, [(0, 0xFF)]

    def set(self, **pins):
        v = self.level
        for name, bit in pins.items():
            k = {"sda": SDA, "scl": SCL, "dcx": DCX, "csx": CSX}[name]
            v = (v & ~(1 << k)) | (bit << k)
        self.poke(v)

    def poke(self, v):
        if v != self.level:
            self.level = v
            if self.changes[-1][0] == self.t:
                self.changes[-1] = (self.t, v)
            else:
                self.changes.append((self.t, v))

    def wait(self, n):
        self.t += n


def rev8(b):
    return int("{:08b}".format(b)[::-1], 2)


def waveform(transfers, variant="good", cycles=None):
    assert variant in VARIANTS, variant
    relaxed = variant == "good_relaxed"
    rng = random.Random(len(transfers) * 1000 + sum(len(d) for _, d in transfers))
    transfers = [(c, list(d)) for c, d in transfers]
    if variant == "bad_extra":
        transfers.append((0x00, []))
    if variant == "bad_missing":
        c, d = transfers[-1]
        if d:
            transfers[-1] = (c, d[:-1])
        else:
            transfers.pop()
    # Where the planted fault goes: the last byte of the first transfer that
    # has data, or the command byte of the first transfer if none has.
    ft = next((i for i, (_, d) in enumerate(transfers) if d), 0)
    fb = len(transfers[ft][1]) if transfers else 0
    w = Wave()

    def slack(n=3):
        if relaxed:
            w.wait(rng.randint(0, n))

    def noise():
        """While CSX is high: the display looks at nothing."""
        if relaxed:
            for _ in range(rng.randint(0, 6)):
                w.set(sda=rng.randint(0, 1), scl=rng.randint(0, 1), dcx=rng.randint(0, 1))
                w.wait(rng.randint(1, 2))

    def upper():
        if relaxed:
            w.poke((w.level & 0x0F) | (rng.randrange(16) << 4))

    def coded(byte):
        return rev8(byte) if variant == "bad_lsb" else byte

    def dc_of(ti, bi):
        if bi == 0:
            return 1 if variant == "bad_dc_cmd" and ti == 0 else 0
        return 0 if variant == "bad_dc_level" else 1

    if variant == "bad_late":
        w.wait((cycles or 4000) - 60)
    w.wait(1)
    noise()
    if variant != "bad_scl_idle":
        w.set(scl=0)
        w.wait(1)
    slack()
    for ti, (cmd, data) in enumerate(transfers):
        w.set(csx=0, scl=0, dcx=dc_of(ti, 0), sda=(coded(cmd) >> 7) & 1)
        if not (variant == "bad_css" and ti == 0):
            w.wait(1)
            slack()
        body = [cmd] + data
        for bi, byte in enumerate(body):
            here = ti == ft and bi == fb
            if here and variant == "bad_bit":
                byte ^= 0x08
            byte = coded(byte)
            dc = dc_of(ti, bi)
            for k in range(7, -1, -1):
                bit = (byte >> k) & 1
                fault = here and k == 3
                if here and k == 0 and variant == "bad_dc_setup":
                    w.set(dcx=dc)
                if fault and variant == "bad_sda_setup":
                    w.set(sda=bit)
                w.set(scl=1)
                upper()
                w.wait(1 if fault and variant == "bad_period_high" else 2)
                slack(2)
                last = k == 0 and bi == len(body) - 1
                if last and ti == len(transfers) - 1 and variant == "bad_cs_early":
                    w.set(csx=1)
                w.set(scl=0)
                if k:
                    nxt = (byte >> (k - 1)) & 1
                    nfault = here and k - 1 == 3
                    if nfault and variant == "bad_sda_setup":
                        nxt ^= 1
                    w.set(sda=nxt)
                    if here and k == 1 and variant == "bad_dc_setup":
                        w.set(dcx=dc ^ 1)
                    w.wait(1 if nfault and variant == "bad_period_low" else 2)
                    slack(2)
                elif not last:
                    if here and variant == "bad_dc_hold":
                        w.set(dcx=dc ^ 1)
                    w.wait(1)
                    if bi == 0 and ti == ft and variant == "bad_cs_split":
                        w.set(csx=1)
                        w.wait(2)
                        w.set(csx=0)
                        w.wait(1)
                    slack(8)
                    w.set(dcx=dc_of(ti, bi + 1), sda=(coded(body[bi + 1]) >> 7) & 1)
                    w.wait(1)
                    slack()
                elif here and variant == "bad_dc_hold":
                    w.set(dcx=dc ^ 1)
        if variant == "bad_stray_bits" and ti == 0:
            for _ in range(3):
                w.wait(2)
                w.set(scl=1)
                w.wait(2)
                w.set(scl=0)
        if variant == "bad_cs_early" and ti == len(transfers) - 1:
            break
        w.wait(1)
        slack()
        if ti == len(transfers) - 1 and variant == "bad_cs_stuck":
            break
        w.set(csx=1)
        w.wait(1)
        if variant != "bad_cs_high":
            w.wait(1)
        if relaxed and ti < len(transfers) - 1:
            noise()
            w.set(scl=0)
            w.wait(1)
            slack(20)
    w.wait(3)
    noise()
    return [c for c in w.changes if cycles is None or c[0] < cycles]


# ---- the task sheet's TX words, read back into transfers ----
def transfers_of(words):
    out, open_transfer = [], None
    for n, w in enumerate(words):
        if w >> 10:
            raise ValueError("word %d (0x%04x) has a bit above bit 9 set" % (n, w))
        is_command, is_last, byte = (w >> 8) & 1, (w >> 9) & 1, w & 0xFF
        if is_command != (open_transfer is None):
            raise ValueError("word %d (0x%04x): bit 8 must be set on the first word of a "
                             "transfer and on no other" % (n, w))
        if is_command:
            open_transfer = (byte, [])
        else:
            open_transfer[1].append(byte)
        if is_last:
            out.append(open_transfer)
            open_transfer = None
    if open_transfer is not None:
        raise ValueError("the last word does not end a transfer")
    if not out:
        raise ValueError("no words")
    return out


def main(argv):
    """Stand-in for `pe_sim run FILE.s -tx FILE -cycles N ...`."""
    here = os.path.dirname(os.path.abspath(argv[0]))
    variant = open(os.path.join(here, "variant.txt")).read().strip()
    assert argv[1] == "run", argv
    tx = argv[argv.index("-tx") + 1]
    cycles = int(argv[argv.index("-cycles") + 1])
    words = [int(l, 0) for l in open(tx).read().split()]
    try:
        transfers = transfers_of(words)
    except ValueError as e:
        sys.exit("ideal: the TX words are not the task sheet's: %s" % e)
    for c, v in waveform(transfers, variant, cycles):
        print("pins %d %02x" % (c, v))


if __name__ == "__main__":
    main(sys.argv)
