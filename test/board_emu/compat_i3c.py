# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# The same for host/i3c_protocols.py, run after compat_extra.py: it uses
# compat_more.py's recorder. Expects the module's names in scope.


def _replies(chip, words):
    """The chip's RX words, in order; then 1 (a NACK)."""
    chip.pop = lambda thread=0: words.pop(0) if words else 1
    return chip


# RSTDAA; ENTDAA with two targets answering and a third round NACKed; a
# write, a register read the controller ends, one the target ends, and a
# read nobody answers.
_chip = _replies(_Recorder(), [0,  # RSTDAA
                               0, 0, 0x04A6, 0x1234, 0x5678, 0x0644, 0,  # ENTDAA, round 1
                               0, 0x04A6, 0x1234, 0x5679, 0x0745, 0, 1,  # round 2, round 3
                               0,  # the write
                               0, 0, 0x14B, 0x079,  # A5 and 3C, T = 1: the controller ends it
                               0, 0, 0x0EF, 0x110,  # 77, then 88 with T = 0
                               1])
_i = I3c(_chip, _image)
I3c(_chip, _image, clock_hz=50_000_000)
print("i3c rstdaa", _i.rstdaa())
print("i3c entdaa", _i.entdaa([0x09, 0x0A, 0x0B]))
print("i3c write", _i.write(0x09, [0x02, 0xA5, 0x3C]))
print("i3c write_read", _i.write_read(0x09, [0x02], 2))
print("i3c write_read", _i.write_read(0x09, [0x06], 4))
print("i3c read", _i.read(0x30, 2))
print("i3c words", hex(I3c.segment(0x7E, True)), hex(I3c.segment(0x09, False)), hex(I3c.data(0xA5)),
      [I3c.odd_parity(b) for b in (0x00, 0x06, 0x07, 0xFF)], I3c.odd_parity(0x09, 7))
print("i3c addresses", [a for a in range(128) if I3c.valid_address(a)][:4],
      [a for a in (0x3E, 0x5E, 0x7D, 0x7E) if I3c.valid_address(a)])
for _bad in [lambda: I3c(_Recorder(), _image, scl_hz=2_500_000), lambda: _i.read(0x09, 0),
             lambda: _i.read(0x09, 64), lambda: _i.entdaa([0x7E]), lambda: _i.setdasa(0x50, 0x3E)]:
    try:
        _bad()
        print("i3c: no error")
    except ValueError as e:
        print("i3c error:", e)
_show("i3c", _chip)
