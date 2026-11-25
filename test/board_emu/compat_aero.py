# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# The same for host/aero_protocols.py, run after compat_extra.py: it uses
# compat_more.py's recorder. Expects the module's names in scope.


class _AeroRecorder(_Recorder):
    """The recorder, with CHAIN in run() and a thread's status as the 1553
    driver reads it: the BC waiting for a command after [busy] looks."""

    def __init__(self, busy=0):
        _Recorder.__init__(self)
        self.busy = busy

    def run(self, threads=(0,), chain=False):
        self.log.append(("run", list(threads), chain))

    def status(self, thread=0):
        self.busy -= 1
        pc = 0 if self.busy >= 0 else MIL1553_BC_NEXT
        self.log.append(("status", thread, pc))
        return {"pc": pc, "enabled": True, "rx_level": 0, "tx_level": 0}


# MIL-STD-1553B: the clocks, commands, how many data words each takes,
# messages short and long, what the monitor recorded, and what is refused.
_chip = _AeroRecorder(busy=2)
_bc = Mil1553Bc(_chip, _image, _image)
Mil1553Bc(_AeroRecorder(), _image, _image, clock_hz=50_000_000)
_cmds = [Mil1553Bc.command(5, False, 2, 3), Mil1553Bc.command(5, True, 2, 32),
         Mil1553Bc.command(31, False, 4, 1), Mil1553Bc.command(5, False, 0, 17),
         Mil1553Bc.command(5, False, 31, 2), Mil1553Bc.command(5, False, 9, 0)]
print("1553 commands", [hex(c) for c in _cmds], [Mil1553Bc.data_words(c) for c in _cmds])
_bc.receive(5, 2, [0x1234, 0xABCD, 0x0001])
_bc.transmit(5, 2, 3)
_bc.send(Mil1553Bc.command(5, False, 0, 17), [0x00FF])
_bc.receive(5, 9, [0x9000 + k for k in range(6)])
_chip.reads = {BUF_PTR: [8], BUF_DATA: [0x2843, 7, 0x1234, 2, 0x2800, 7, 0x1235, 4]}
print("1553 heard", _bc.heard())
for _bad in [lambda: Mil1553Bc(_AeroRecorder(), _image, _image, clock_hz=25_000_000),
             lambda: Mil1553Bc.command(32, False, 2, 1), lambda: Mil1553Bc.command(5, False, 2, 33),
             lambda: _bc.send(Mil1553Bc.command(5, False, 2, 3), [1, 2]),
             lambda: _bc.send(Mil1553Bc.command(5, True, 2, 3), [1]),
             lambda: _bc.receive(5, 2, [0x10000])]:
    try:
        _bad()
        print("1553: no error")
    except ValueError as e:
        print("1553 error:", e)
_show("1553", _chip)

# ARINC 429: both rates at two clocks, the words, and what is refused.
_chip = _AeroRecorder()
_a = Arinc429Tx(_chip, _image)
Arinc429Tx(_AeroRecorder(), _image, rate=12_500, clock_hz=50_000_000)
_a.send(0o205, 0x12345, sdi=1, ssm=3)
_a.send(0o001, 1)
print("arinc words", Arinc429Tx.words(0o310, 0x7FFFF, 2, 0), Arinc429Tx.words(0o377, 0x40000, 3, 1))
for _bad in [lambda: Arinc429Tx(_AeroRecorder(), _image, rate=50_000),
             lambda: Arinc429Tx(_AeroRecorder(), _image, clock_hz=10_000_001),
             lambda: Arinc429Tx.words(0o400, 0), lambda: Arinc429Tx.words(1, 1 << 19),
             lambda: Arinc429Tx.words(1, 0, sdi=4)]:
    try:
        _bad()
        print("arinc: no error")
    except ValueError as e:
        print("arinc error:", e)
_show("arinc", _chip)

# SpaceWire: the words of a packet, playing it, and what is refused.
_chip = _AeroRecorder()
_chip.reads = {BUF_PTR: [3, 8, 2, 4]}  # where the play has got
_s = SpaceWireTx(_chip, _image, _image)
print("spacewire bitrates", _s.bitrate, SpaceWireTx(_AeroRecorder(), _image, _image, clkdiv=1,
                                                     clock_hz=50_000_000).bitrate)
print("spacewire words", SpaceWireTx.words([0, 0x5B, 0xFF]), SpaceWireTx.words([1], 0, 0),
      hex(SpaceWireTx.nulls(255)))
_s.send([0x00, 0x5B, 0xFF, 0x80, 0x42], nulls_before=3, nulls_after=2)
_s.send([0x42])
_s.wait()
for _bad in [lambda: SpaceWireTx(_AeroRecorder(), _image, _image, clkdiv=0),
             lambda: SpaceWireTx.words([256]), lambda: SpaceWireTx.nulls(0),
             lambda: SpaceWireTx.nulls(256), lambda: _s.send([0] * 1021)]:
    try:
        _bad()
        print("spacewire: no error")
    except ValueError as e:
        print("spacewire error:", e)
_show("spacewire", _chip)
