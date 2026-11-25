# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# The same for host/motion_protocols.py, run after compat_extra.py: it uses
# compat_more.py's recorder. Expects the module's names in scope.


class _MotionRecorder(_Recorder):
    """The recorder, with CHAIN in run() as Xy2100 asks for it."""

    def run(self, threads=(0,), chain=False):
        self.log.append(("run", list(threads), chain))


# DShot: every rate at two clocks, the words, and what is refused.
_chip = _MotionRecorder()
_e = Dshot(_chip, _image)
print("dshot rates", [Dshot(_MotionRecorder(), _image, rate=r, clock_hz=c).bitrate
                      for c in (10_000_000, 50_000_000) for r in Dshot.RATES])
_e.send(1046)
_e.send(0)
_e.command(13)
_e.send(2047, telemetry=True)
print("dshot words", Dshot.word(1046), Dshot.word(13, True), Dshot.word(2047, 1))
for _bad in [(2048,), (-1,)]:
    try:
        _e.send(*_bad)
    except ValueError as e:
        print("dshot error:", _bad, e)
for _bad in (0, 48):
    try:
        _e.command(_bad)
    except ValueError as e:
        print("dshot error:", _bad, e)
for _bad in [dict(rate=500), dict(rate=1200, clock_hz=1_000_000)]:
    try:
        Dshot(_MotionRecorder(), _image, **_bad)
    except ValueError as e:
        print("dshot error:", sorted(_bad.items()), e)
_show("dshot", _chip)

# XY2-100: points queued first, through the FIFO, and from the buffer.
_chip = _MotionRecorder()
_chip.reads = {BUF_PTR: [3, 6]}
_s = Xy2100(_chip, _image, _image, first=[(1, -1)])
_s.write([(32767, -32768), (0x1234, 0)])
_s.play([(0, 0), (-5, 5), (100, -100)])
_s.write([(7, 7)])
print("xy2 words", Xy2100.words([(-1, 0), (-32768, 32767)]))
for _bad in [[(32768, 0)], [(0, -32769)]]:
    try:
        Xy2100.words(_bad)
    except ValueError as e:
        print("xy2 error:", _bad, e)
for _bad in [[], [(0, 0)] * 512]:
    try:
        _s.play(_bad)
    except ValueError as e:
        print("xy2 error:", len(_bad), e)
try:
    Xy2100(_MotionRecorder(), _image, _image, first=[(0, 0)] * 3)
except ValueError as e:
    print("xy2 error:", e)
_show("xy2", _chip)

# The caliper: readings in millimetres and inches, counts, and what is refused.
_chip = _MotionRecorder()
_c = Caliper(_chip, _image)
Caliper(_MotionRecorder(), _image, clock_hz=50_000_000)
_c.send(12.34)
_c.send(-0.5)
_c.send(0.5005, inches=True)
_c.send(-6.0, inches=True)
_c.send_counts(65535, negative=True)
print("caliper words", Caliper.words(0), Caliper.words(1001, True, True))
for _bad in (-1, 65536):
    try:
        Caliper.words(_bad)
    except ValueError as e:
        print("caliper error:", _bad, e)
try:
    _c.send(700.0)
except ValueError as e:
    print("caliper error:", e)
_show("caliper", _chip)
