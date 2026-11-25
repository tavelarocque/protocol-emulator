# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# The same for host/link_protocols.py, run after compat_extra.py: it uses
# compat_more.py's recorder. Expects the module's names in scope.

# Compact JTAG: online, a reset, an IDCODE read, an IR scan, the words of a
# scan, and what is refused.
_chip = _Recorder(words=[0x3D, 0xE8, 0xA0, 0x15, 0x05])
_j = CJtagController(_chip, _image)
CJtagController(_chip, _image, clkdiv=2)
_j.activate()
_j.reset()
print("cjtag idcode", hex(_j.shift_dr(0, 32)), "ir", _j.shift_ir(0b1111, 4))
print("cjtag words", CJtagController.words([1, 0, 0, 1, 1, 0, 0, 0, 1], [0, 1, 1, 0, 1, 0, 1, 0, 1]))
for _bad in [([], []), ([1, 0], [1])]:
    try:
        CJtagController.words(*_bad)
    except ValueError as e:
        print("cjtag error:", e)
_show("cjtag", _chip)

# PJON over PJDL: packets with and without a sender, the CRC8, and a packet
# too long for it.
_chip = _Recorder(line=0xCC)
_p = PjonPjdl(_chip, _image)
PjonPjdl(_chip, _image, mode=1, clock_hz=12_000_000)
print("pjdl sent", hex(_p.send(42, [0x68], sender=1)), hex(_p.send(0, [1, 2, 3])))
print("pjdl words", PjonPjdl.words(7, [0xFF] * 9, sender=255), pjon_crc8([42, 2, 7]),
      pjon_crc8([42, 2, 7, 0x2F, 1, 0x68]))
for _bad in [(1, [0] * 10, 2), (1, [256])]:
    try:
        PjonPjdl.words(*_bad)
    except ValueError as e:
        print("pjdl error:", e)
_show("pjdl", _chip)

# SIPI over LFAST: a write, a read and an ID request through the packet
# buffer, and what is refused.
_chip = _Recorder()
_l = LfastSipi(_chip, _image)
LfastSipi(_chip, _image, clock_hz=10_000_000, bit_rate=2_000_000)
_l.send([LfastSipi.write_frame(0x40001000, 0xDEADBEEF, tag=1, channel=1),
         LfastSipi.read_frame(0x40001000, tag=2, channel=1), LfastSipi.id_frame(tag=3)])
print("lfast words", LfastSipi.words([LfastSipi.header(0b10111, 5, 7)] + [0] * 16))
try:
    LfastSipi.words([0, 0])
except ValueError as e:
    print("lfast error:", e)
try:
    LfastSipi(_chip, _image, clock_hz=12_000_000)
except ValueError as e:
    print("lfast error:", e)
_show("lfast", _chip)
