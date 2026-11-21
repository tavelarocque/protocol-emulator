# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# The same for host/extra_protocols.py, run after compat_more.py: it uses
# that file's recorder. Expects the module's names in scope.


def _ready(chip):
    """A chip whose program is past its first instruction and whose TX
    FIFO is empty."""
    chip.status = lambda thread=0: {"pc": 1, "tx_level": 0}
    return chip


# Step and direction: a ramp, a move backwards, and what is refused.
_chip = _Recorder(words=[0, 0])
_m = Stepper(_chip, _image)
Stepper(_chip, _image, tick_us=5, clock_hz=12_000_000)
_m.ramp([(3, 400), (6, 100), (3, 400)])
_m.move(-32768, 65539)
print("stepper", _m.position, Stepper.words(1, 4), Stepper.words(-5, 250))
for _bad in [(0, 100), (32769, 100), (5, 3), (5, 65540)]:
    try:
        Stepper.words(*_bad)
    except ValueError as e:
        print("stepper error:", _bad, e)
_show("stepper", _chip)

# AM2302 and DHT11: readings, a negative temperature, a bad checksum, and a
# sensor that stopped.
_chip = _Recorder()
_d = Dht(_chip, _image)
_d11 = Dht(_chip, _image, dht11=True, clock_hz=12_000_000)
for _words, _dht11 in [([652, 0x8065, 0x73, 0], False), ([0x028C, 0x015F, 0xEE, 0], False),
                       ([0x2D00, 0x1703, 0x47, 0], True), ([652, 351, 0x00, 0], False),
                       ([0xFFFF, 0xE000, 0, 1], False)]:
    try:
        print("dht %.1f %.1f" % Dht.decode(_words, _dht11))
    except DhtError as e:
        print("dht error:", e)
_words = [0x028C, 0x015F, 0xEE, 0]
_chip.pop = lambda thread=0: _words.pop(0)
print("dht read %.1f %.1f" % _d.read())
_words = [0x2D00, 0x1703, 0x47, 0]
print("dht11 read %.1f %.1f" % _d11.read())
_show("dht", _chip)

# The level stream: cells into words, and the three codes sent with it.
_chip = _ready(_Recorder())
_b = Bitstream(_chip, _image, 7)
_b.send_cells([1, 0, 1, 1])
_b.send_cells([1] * 17, rest=1)
_b.flush()
for _bad in (0, 65536):
    try:
        Bitstream(_chip, _image, _bad)
    except ValueError as e:
        print("bitstream error:", e)
_show("bitstream", _chip)

_chip = _ready(_Recorder())
_q = Qi(_chip, _image)
Qi(_chip, _image, clock_hz=50_000_000)
print("qi lengths", [Qi.length(h) for h in (0x00, 0x1F, 0x20, 0x2F, 0x30, 0x7F, 0x80, 0xDF, 0xE0, 0xFF)])
print("qi cells", Qi.cells(0x01, [0x80]), Qi.cells(0x28, [0x12, 0x34], preamble=25))
_q.send(0x03, [0xFB])
try:
    _q.send(0x03, [1, 2])
except ValueError as e:
    print("qi error:", e)
_show("qi", _chip)

_chip = _ready(_Recorder())
_t = Em4100(_chip, _image)
Em4100(_chip, _image, field_hz=134_200, clock_hz=50_000_000)
print("em4100 bits", Em4100.bits(0x06, 0x001259E3), Em4100.bits(0xFF, 0xFFFFFFFF))
_t.send(0xA5, 0xDEADBEEF, repeats=2)
_show("em4100", _chip)

_chip = _ready(_Recorder())
_k = Morse(_chip, _image)
Morse(_chip, _image, unit_ms=0.5)
Morse(_chip, _image, unit_ms=240, clock_hz=50_000_000)
print("morse repeat", _k.repeat, Morse.cells("sos"), Morse.cells("Paris  73"))
_k.send("e t")
_show("morse", _chip)

# TDM audio: the slot count, frames, and a frame of the wrong length.
_chip = _Recorder()
_a = TdmTx(_chip, _image, slots=4, clkdiv=4)
_a.write([[0x8001, 0x1234, -1, 0], [1, 2, 3, 4]])
try:
    _a.write([[1, 2, 3]])
except ValueError as e:
    print("tdm error:", e)
_show("tdm", _chip)

# TLC5620: every field of a write, and what is refused.
_chip = _ready(_Recorder())
_c = Tlc5620(_chip, _image)
_c.write(0, 64, update=False)
_c.write(1, 128, double=True, update=False)
_c.write(3, 255)
for _bad in [(4, 0), (0, 256), (-1, 0)]:
    try:
        _c.write(*_bad)
    except ValueError as e:
        print("tlc5620 error:", _bad, e)
_show("tlc5620", _chip)
