# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# The same for host/card_protocols.py, run after compat_extra.py: it uses
# compat_more.py's recorder. Expects the module's names in scope.


def _try(what, f):
    try:
        print(what, f())
    except (ValueError, Iso7816Error, TpmError) as e:
        print(what, "error:", e)


# ISO 7816: a cold reset and its answer to reset, SELECT, READ BINARY with
# a NULL procedure byte, a warm reset whose answer has a TCK, the inverse
# convention, and what is refused.
_chip = _Recorder(words=[0x3B, 0x92, 0x11, 0x00, 0x31, 0xC0, 0xA4, 0x90, 0x00,
                         0x60, 0xB0, 1, 2, 3, 0x90, 0x00, 0x6A, 0x82])
_r = Iso7816(_chip, _image, _image)
Iso7816(_Recorder(), _image, _image, clock_hz=12_000_000, card_hz=3_000_000)
print("iso7816 atr", list(_r.reset()))
_data, _sw = _r.command(0x00, 0xA4, 0x00, 0x00, data=b"\x3f\x00")
print("iso7816 select", list(_data), hex(_sw))
_data, _sw = _r.command(0x00, 0xB0, 0x00, 0x10, le=3)
print("iso7816 read binary", list(_data), hex(_sw))
_data, _sw = _r.command(0x00, 0xA4, 0x00, 0x00, data=b"\x2f\x00")
print("iso7816 select", list(_data), hex(_sw))
_show("iso7816", _chip)
_chip = _Recorder(words=[0x3B, 0x80, 0x01, 0x81])
_r = Iso7816(_chip, _image, _image)
_r.started = True  # a warm reset: thread 0 stopped and started, CLK running on
print("iso7816 warm atr", list(_r.reset()))
_show("iso7816 warm", _chip)
_chip = _Recorder(words=[iso7816_line(b, True) for b in (0x3F, 0x10, 0x11)])
print("iso7816 inverse atr", list(Iso7816(_chip, _image, _image, inverse=True).reset()))
print("iso7816 line", [iso7816_line(b, True) for b in (0x3F, 0x3B, 0x01, 0x80)])
_try("iso7816 bad TS", lambda: Iso7816(_Recorder(words=[0x3F]), _image, _image).reset())
_try("iso7816 bad TCK", lambda: Iso7816(_Recorder(words=[0x3B, 0x80, 0x01, 0x80]), _image, _image).reset())
_try("iso7816 mute", lambda: Iso7816(_Recorder(), _image, _image).reset(polls=6))
_try("iso7816 6 MHz", lambda: Iso7816(_Recorder(), _image, _image, card_hz=6_000_000))
_try("iso7816 odd divider", lambda: Iso7816(_Recorder(), _image, _image, card_hz=4_000_000))
_try("iso7816 case 4", lambda: _r.command(0, 0xB0, 0, 0, data=b"\x01", le=1))
_r = Iso7816(_Recorder(words=[0x3B, 0x00, 0x42]), _image, _image)
_r.reset()
_try("iso7816 procedure", lambda: _r.command(0x00, 0xB0, 0x00, 0x00, le=1))


class _Spi:
    pass


def _tx(data, waits=0):
    """What MISO brings back for one TIS transaction: the header's bytes,
    the last ending in 1 unless there are wait states, those, the data."""
    return ([0, 0, 0, 0 if waits else 1] + [0] * max(0, waits - 1) + ([1] if waits else [])
            + list(data))


# TPM TIS: the locality, DID_VID, TPM_STS, TPM2_Startup with two wait
# states on its last write, and what is refused.
_chip = _Recorder()
_chip.reads = {pe.STATUS: [0x40] * 400,
               pe.RX_FIFO: _tx([0]) + _tx([0xA1]) + _tx([0xD1, 0x15, 0x1B, 0x00]) + _tx([0x80])
               + _tx([0]) + _tx([0xC0, 64, 0, 4]) + _tx([0] * 12) + _tx([0x80]) + _tx([0])
               + _tx([0x90]) + _tx([0x80, 1, 0, 0, 0, 10, 0, 0, 0, 0]) + _tx([0x80])
               + _tx([0], waits=2)}
_spi = _Spi()
_spi.chip = _chip
_t = TpmTis(_spi)
print("tpm access", hex(_t.request_locality()), "did vid", _t.did_vid(), "sts", hex(_t.status()))
_rsp = _t.command(tpm2_startup())
print("tpm startup", list(_rsp), tpm2_response_code(_rsp), "waits", _t.waits, list(tpm2_startup(False)))
_show("tpm", _chip)
_chip = _Recorder()
_chip.reads = {pe.STATUS: [0x40] * 100, pe.RX_FIFO: _tx([], waits=40)}
_spi.chip = _chip
_try("tpm held", lambda: TpmTis(_spi, max_waits=3).read(TpmTis.STS, 1))
_try("tpm locality", lambda: TpmTis(_spi, locality=5))
_try("tpm size", lambda: TpmTis(_spi).read(TpmTis.DATA_FIFO, 65))
