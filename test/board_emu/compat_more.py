# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# Runs every driver in host/more_protocols.py against a chip that only
# records what it is asked to do, and prints the record. run_compat.mjs runs
# this under CPython and under MicroPython on the emulated board; the two
# records must be identical, and MicroPython must have compiled the module.
# Expects the module's names in scope.


class _Recorder:
    """Stands in for protocol_emulator.Chip. [line] is what pop returns."""

    def __init__(self, line=0xFFFE, words=()):
        self.log = []
        self.line = line
        self.words = list(words)  # what try_pop finds, in order

    def stop(self):
        self.log.append("stop")

    def load(self, image, threads=(0, 1)):
        self.log.append(("load", len(image)))

    def configure(self, **fields):
        self.log.append(("configure", sorted(fields.items())))

    def set_pin_modes(self, modes):
        self.log.append(("modes", sorted(modes.items())))

    def run(self, threads=(0,)):
        self.log.append("run")

    def write(self, addr, value):
        self.log.append(("write", addr, value))

    def write_many(self, writes):
        self.log.append(("write_many", list(writes)))

    def read(self, addr):
        # What the test put in [reads] for this address, in order; then 0.
        queue = getattr(self, "reads", {}).get(addr)
        value = queue.pop(0) if queue else 0
        self.log.append(("read", addr, value))
        return value

    def status(self):
        return {"pc": getattr(self, "pc", 0)}

    def push(self, value, thread=0):
        self.log.append(("push", value))

    def pop(self):
        return self.line

    def try_pop(self, thread=0):
        # Every third look finds a word, as when frames are still arriving.
        self.looks = getattr(self, "looks", 0) + 1
        if self.looks % 3 or not self.words:
            return None
        return self.words.pop(0)


def _show(name, chip):
    print(name, chip.log)


_image = [0] * 8

_chip = _Recorder()
I2sTx(_chip, _image, first=[(0x1234, -2)]).write([(1, 2), (-32768, 32767)])
_show("i2s", _chip)

_chip = _Recorder()
DmxTx(_chip, _image, pin=3).send([0, 255, 0x55], start_code=0x17)
_show("dmx", _chip)

_chip = _Recorder()
_w = WiegandTx(_chip, _image, clock_hz=12_000_000)
_w.send26(0x9C, 0xB1E5)
_w.send([1, 0, 1] * 11 + [1])
_show("wiegand", _chip)

_chip = _Recorder()
NecTx(_chip, _image).send(0x04, 0x08)
NecTx(_chip, _image, clock_hz=12_000_000, carrier_hz=36_000).send(0xFF, 0x00)
_show("nec", _chip)

_chip = _Recorder()
_m = Mdio(_chip, _image)
_m.write(5, 0, 0x1140)
print("mdio read", _m.read(31, 2))
_show("mdio", _chip)
try:
    Mdio(_Recorder(line=0xFFFF), _image).read(6, 2)
    print("mdio: no error")
except MdioError as e:
    print("mdio error:", e)

_chip = _Recorder()
_d = DaliTx(_chip, _image)
_d.send(0xFF, 0x05)
_d.send(0x02, 0xA5)
_show("dali", _chip)

_chip = _Recorder()
_r = Rc5Tx(_chip, _image)
_r.send(5, 0x35)
_r.send(5, 0x35, new_press=False)
_r.send(31, 63)
_show("rc5", _chip)

_chip = _Recorder()
_l = LinMaster(_chip, _image)
_l.send(0x23, [0x11, 0x22, 0x33, 0x44])
_l.send(0x3C, [0xFF] * 8)
print("lin ids", [LinMaster.protected_id(k) for k in range(64)])
_show("lin", _chip)

_chip = _Recorder(words=[0xCE58, 0x03CB, 0x1234, 0xABCD, 0x0002, 0xCA58, 0x03CB, 0x0001])
_w = WiegandRx(_chip, _image)
_w.expect(26)
print("wiegand rx", _w.read26())
_w.expect(34)
print("wiegand rx", _w.read())
_w.expect(26)
try:
    print("wiegand rx", _w.read26())
except WiegandError as e:
    print("wiegand rx error:", e)
_w.expect(26)
try:
    print("wiegand rx", _w.read(patience=5))
except WiegandError as e:
    print("wiegand rx error:", e)
_show("wiegand rx", _chip)

_chip = _Recorder(words=[0xFB04, 0xF708, 0x1234, 0x5AA5, 0xFB04, 0x0000, 0xFB04, 0x1234])
_n = NecRx(_chip, _image, clock_hz=12_000_000)
for _ in range(5):
    try:
        print("nec rx", _n.read(patience=30))
    except NecError as e:
        print("nec rx error:", e)
_show("nec rx", _chip)

print("modbus", [hex(modbus_crc16(bytes([k] * k))) for k in range(1, 9)])
print("modbus", list(modbus_frame(0x11, 0x03, [0x00, 0x6B, 0x00, 0x03])))

_chip = _Recorder()
_p = Pwm(_chip, _image)
_p.set(300, 1000)
_p.servo(1500)
_show("pwm", _chip)

_chip = _Recorder(line=0b01101110)
print("nes", NesPad(_chip, _image, clock_hz=12_000_000).read())
_show("nes", _chip)

_chip = _Recorder()
_b = Buffer(_chip)
_b.load([1, 2, 3], at=1020)
_b.play(3, thread=1, at=1020)
_b.record(10)
_chip.reads = {BUF_PTR: [7], BUF_DATA: [0x1111, 0x2222]}
print("buffer", _b.position(), _b.read(2, at=5))
_show("buffer", _chip)

_chip = _Recorder()
_e = EthernetTx(_chip, _image)
EthernetTx(_chip, _image, link_ticks=400)
_e.send(bytes(range(60)))
_e.send(bytes(range(7)))  # padded to 60
_e.send(bytes(range(61)))  # an odd length
_chip.pc = EthernetTx.LINK
print("ethernet tx sent", _e.sent())
_show("ethernet tx", _chip)

_chip = _Recorder()
set_sampler(_chip, pin=4, blank=0, sample=9, wrap=19, sync=0x7E, misses=7, invert=True)
set_sampler(_chip, pin=7, blank=3, sample=1, wrap=6)
set_sampler(_chip, pin=0, blank=0, sample=13, wrap=19, misses=7, prescale=4, shift=2, stuff=5)
_show("sampler", _chip)

_chip = _Recorder()
_e = EthernetRx(_chip, _image)
EthernetRx(_chip, _image, clock_hz=50_000_000)
_e.listen()
_chip.pc = EthernetRx.WAITING
print("ethernet rx waiting", _e.waiting())
# Two frames as the program leaves them: five bytes with a good CRC, then
# two bytes with a wrong one. Then a recording cut short.
_chip.reads = {BUF_PTR: [10], BUF_DATA: [0x0201, 0x0403, 0x0005, 0xFFD8, 0x20E3, 0xDEBB,
                                         0xBBAA, 0xFFF0, 0x1234, 0x5678]}
print("ethernet rx", _e.frames())
_chip.reads = {BUF_PTR: [4], BUF_DATA: [0x0201, 0xFFD8, 0x20E3, 0xDEBB]}
print("ethernet rx", _e.frames())
_show("ethernet rx", _chip)

# v2.3: DALI and RC-5 received through the sampler's prescaler. The words are
# what the programs leave: an idle bus's report, the answer 0xA5, the frame
# 0x5A as its two words and count, a bus held low; then three RC-5 frames,
# the second extended, the third without its start bit.
_chip = _Recorder(words=[0x0007, 0xFFFD, 0x59A6, 0x0007, 0xFFEC, 0x6659, 0x0017, 0xFFEB,
                         0x0000, 0xFFFD])
_d = DaliRx(_chip, _image)
DaliRx(_chip, _image, clock_hz=12_000_000)
for _ in range(4):
    try:
        print("dali rx", _d.read(patience=40))
    except DaliError as e:
        print("dali rx error:", e)
print("dali rx frame", DaliRx.frame([0x59A6, 0x0007, 0xFFEC]), DaliRx.frame([0x0007, 0xFFFD]))
_show("dali rx", _chip)

_chip = _Recorder(words=[0x3975, 0x2001, 0x1975])
_r = Rc5Rx(_chip, _image)
Rc5Rx(_chip, _image, clock_hz=12_000_000)
for _ in range(4):
    try:
        print("rc5 rx", _r.read(patience=3))
    except Rc5Error as e:
        print("rc5 rx error:", e)
_show("rc5 rx", _chip)

# A DALI controller on both threads: a query whose answer comes, one that
# nothing answers, and one where the bus did not carry the chip's frame.
_chip = _Recorder(words=[0x6AA9, 0x5A6A, 0x0017, 0xFFDB, 0x56A6, 0x0017, 0xFFEB,
                         0x6AA6, 0x5A6A, 0x0017, 0xFFDB])
_c = Dali(_chip, _image, _image)
Dali(_chip, _image, _image, clock_hz=12_000_000)
for _address in (0x03, 0x05, 0x03):
    try:
        print("dali query", _c.query(_address, 0x90, patience=40, wait=12))
    except DaliError as e:
        print("dali query error:", e)
_show("dali controller", _chip)
