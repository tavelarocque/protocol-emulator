# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# The same for host/auto_protocols.py, run after compat_extra.py: it uses
# compat_more.py's recorder and compat_extra.py's _ready. Expects the
# module's names in scope.

# SENT: frames, other lengths and ticks, and what is refused.
_chip = _ready(_Recorder())
_s = SentTx(_chip, _image)
SentTx(_chip, _image, nibbles=3, tick_us=90, clock_hz=50_000_000)
_s.send(0x5, [0x0, 0xF, 0x8, 0x7, 0x1, 0xE])
_s.send(0xA, [3, 12, 5, 10, 6, 9])
print("sent words", SentTx(_chip, _image, nibbles=1).words(0xF, [0xF]),
      SentTx(_chip, _image, nibbles=4).words(1, [2, 3, 4, 5]))
for _bad in [(16, [0] * 6), (0, [0] * 5), (0, [0, 0, 16, 0, 0, 0]), (0, [-1, 0, 0, 0, 0, 0])]:
    try:
        _s.words(*_bad)
    except ValueError as e:
        print("sent error:", _bad, e)
for _bad in [{"nibbles": 0}, {"nibbles": 7}, {"tick_us": 2}, {"tick_us": 91},
             {"clock_hz": 12_345_678}]:
    try:
        SentTx(_chip, _image, **_bad)
    except ValueError as e:
        print("sent error:", sorted(_bad.items()), e)
_show("sent", _chip)

# J1850 VPW: a frame, the words of others, and what is refused.
_chip = _ready(_Recorder(line=0))
_v = J1850Vpw(_chip, _image)
J1850Vpw(_chip, _image, clock_hz=50_000_000)
_v.send([0x68, 0x6A, 0xF1, 0x03])
print("j1850 words", J1850Vpw.words([0x48, 0x6B, 0x10, 0x43, 0x01]), J1850Vpw.words([0xFF] * 11))
for _bad in [[], [0] * 12, [256], [-1]]:
    try:
        J1850Vpw.words(_bad)
    except ValueError as e:
        print("j1850 error:", _bad, e)
try:
    J1850Vpw(_chip, _image, clock_hz=12_500_000)
except ValueError as e:
    print("j1850 error:", e)
_show("j1850", _chip)
