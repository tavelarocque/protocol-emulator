# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# The same for host/misc_protocols.py, run after compat_extra.py: it uses
# compat_more.py's recorder. Expects the module's names in scope.


def _answers(chip, words):
    """pop returns [words] in order, then 0xFFFF."""
    words = list(words)
    chip.pop = lambda thread=0: words.pop(0) if words else 0xFFFF
    return chip


# Sony SIRC: a frame of each length, sent twice, and what is refused.
_chip = _Recorder()
_s = SircTx(_chip, _image)
SircTx(_chip, _image, clock_hz=12_000_000)
_s.send(0x15, 0x01)
_s.send(0x2A, 0xA5, bits=15, repeat=2)
_s.send(0x1A, 0x1A, bits=20, extended=0xE2)
print("sirc", SircTx.words(0x7F, 0x1F), SircTx.words(0, 0xFF, bits=15),
      SircTx.words(0x7F, 0x1F, bits=20, extended=0xFF))
for _bad in [(0x80, 0, 12, 0), (0, 0x20, 12, 0), (0, 0, 16, 0), (0, 0, 20, 0x100), (0, 0, 12, 1)]:
    try:
        SircTx.words(*_bad)
    except ValueError as e:
        print("sirc error:", _bad, e)
_show("sirc", _chip)

# SLE 4442: a reset, a read of the last eight bytes, the protection and
# security memories; a missing card; what is refused.
_chip = _answers(_Recorder(), [0xA2, 0x13, 0x10, 0x91] + list(range(0xE0, 0xE8))
                 + [0x00, 0xFF, 0xFF, 0xFF, 0x07, 0x00, 0x00, 0x00])
_r = Sle4442(_chip, _image)
Sle4442(_chip, _image, clock_hz=12_000_000)
print("sle4442", list(_r.reset()), list(_r.read_main(0xF8)), list(_r.read_protection()),
      list(_r.read_security()))
try:
    _r.reset()
except Sle4442Error as e:
    print("sle4442 error:", e)
for _bad in [lambda: Sle4442(_Recorder(), _image, clock_hz=12_100_000), lambda: _r.read_main(256),
             lambda: Sle4442.words(512), lambda: Sle4442.words(4, reset=True, command=(0x30, 0, 0))]:
    try:
        _bad()
    except ValueError as e:
        print("sle4442 error:", e)
print("sle4442 words", Sle4442.words(4, reset=True), Sle4442.words(8, command=(0x30, 0xF8, 0)),
      Sle4442.words(3))
_show("sle4442", _chip)

# The BQ2022A on the 1-Wire engine: its ROM, the end of its memory with
# both CRCs, and a CRC that is wrong.
_rom = [0x09, 0x5A, 0x3C, 0x81, 0x00, 0x24, 0x7E]
_rom.append(pe.onewire_crc8(_rom))
_data = [0x41, 0x5E]
_cmd = [0xF0, 0x7E, 0x00]
_chip = _answers(_Recorder(), [0, 0] + _rom + [0, 0, 0, 0, 0, pe.onewire_crc8(_cmd)] + _data
                 + [pe.onewire_crc8(_data), 0, 0, 0, 0, 0, 0x55])
_b = Bq2022a(pe.OneWire(_chip, _image))
print("bq2022a", list(_b.read_rom()), list(_b.read_memory(0x7E)))
try:
    _b.read_memory(0x7E)
except pe.OneWireError as e:
    print("bq2022a error:", e)
try:
    _b.read_memory(128)
except ValueError as e:
    print("bq2022a error:", e)
_show("bq2022a", _chip)
