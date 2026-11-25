# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# The same for host/i2c2_protocols.py, run after compat_extra.py: it uses
# that file's _ready and compat_more.py's recorder. Expects the module's
# names in scope.

# SBUS: the bytes of a message, what is refused, and what the driver
# writes to send one through the packet buffer.
print("sbus message", SbusTx.message([992] * 16))
print("sbus message", SbusTx.message(list(range(0, 2048, 128)), ch17=True, failsafe=True))
print("sbus message", SbusTx.message([2047, 0] * 8, ch18=True, frame_lost=True))
for _bad in ([992] * 15, [992] * 15 + [2048], [-1] + [992] * 15):
    try:
        SbusTx.message(_bad)
    except ValueError as e:
        print("sbus error:", e)
for _clock, _baud in ((10_000_000, 3_000_000), (10_000_000, 300_000), (50_000_000, 100)):
    try:
        SbusTx(_ready(_Recorder()), _image, clock_hz=_clock, baud=_baud)
    except ValueError as e:
        print("sbus error:", e)
_chip = _ready(_Recorder())
SbusTx(_chip, _image, clock_hz=50_000_000)
_s = SbusTx(_chip, _image)
_chip.reads = {BUF_PTR: [3, 25]}  # the buffer part played, then all of it
_s.send([172, 992, 1811] * 5 + [1024], ch17=True)
_chip.reads = {BUF_PTR: [2]}
_s.send_bytes([0x55, 0xAA])
for _bad in ([], [0] * 1024):
    try:
        _s.send_bytes(_bad)
    except ValueError as e:
        print("sbus error:", e)
_show("sbus", _chip)
