# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# The same for host/rail_protocols.py, run after compat_extra.py: it uses
# compat_more.py's recorder. Expects the module's names in scope.

# KNX TP1: a switch telegram and its acknowledgement as the chip reports
# it (0x2CC), one with a parity error, none at all, and what is refused.
_chip = _Recorder(line=0x2CC)
_k = KnxTp1(_chip, _image)
KnxTp1(_chip, _image, clock_hz=1_000_000, ack_timeout_us=3000)
_t = KnxTp1.group_write(KnxTp1.individual(1, 1, 1), KnxTp1.group(1, 2, 3), 1)
print("knx telegram", _t, KnxTp1.words(_t), knx_checksum(_t))
print("knx ack", _k.send(_t), KnxTp1(_Recorder(line=0x3CC), _image).send(_t),
      KnxTp1(_Recorder(line=0), _image).send(_t))
for _bad in [lambda: KnxTp1.group_write(0x1101, 0x0A03, 64), lambda: KnxTp1.words([1] * 6),
             lambda: KnxTp1(_chip, _image, clock_hz=12_500_000)]:
    try:
        _bad()
    except ValueError as e:
        print("knx error:", e)
_show("knx", _chip)

# MVB: a process data request and its answer through the packet buffer,
# the words of a long slave frame, and what is refused.
_chip = _Recorder()
_m = Mvb(_chip, _image)
Mvb(_chip, _image, clock_hz=96_000_000)
_m.send([Mvb.master(0x123, 4), Mvb.slave([0xCAFE, 0x0042])])
print("mvb words", Mvb.words(Mvb.master(0xFFF, 32)), Mvb.words(Mvb.slave(list(range(16)))))
for _bad in [lambda: Mvb.master(0x123, 3), lambda: Mvb.slave([1, 2, 3]), lambda: Mvb(_chip, _image, clock_hz=50_000_000)]:
    try:
        _bad()
    except ValueError as e:
        print("mvb error:", e)
_show("mvb", _chip)

# LTC: three frames with user bits, the words of one, and what is refused.
_chip = _Recorder()
_l = Ltc(_chip, _image)
Ltc(_chip, _image, clock_hz=400_000)
_l.send([((23, 59, 59, 22), (1, 2, 3, 4, 10, 11, 12, 13)), (23, 59, 59, 23)])
print("ltc words", Ltc.words(12, 34, 56, 24, user=(15,) * 8, colour=True))
for _bad in [lambda: Ltc.words(24, 0, 0, 0), lambda: Ltc.words(0, 0, 0, 25), lambda: Ltc(_chip, _image, clock_hz=1_000_000)]:
    try:
        _bad()
    except ValueError as e:
        print("ltc error:", e)
_show("ltc", _chip)
