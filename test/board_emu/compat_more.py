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

    def load(self, image):
        self.log.append(("load", len(image)))

    def configure(self, **fields):
        self.log.append(("configure", sorted(fields.items())))

    def set_pin_modes(self, modes):
        self.log.append(("modes", sorted(modes.items())))

    def run(self):
        self.log.append("run")

    def write(self, addr, value):
        self.log.append(("write", addr, value))

    def push(self, value):
        self.log.append(("push", value))

    def pop(self):
        return self.line

    def try_pop(self):
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
