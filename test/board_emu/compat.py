# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# Runs the driver's pure functions (packets, CRCs, line states, decoding)
# over fixed inputs and prints the results. run_compat.mjs runs this under
# CPython and under MicroPython on the emulated board; the outputs must be
# identical, so code that only CPython accepts (int.bit_length, say) shows.
# Expects the driver's names in scope (exec'd after it, or imported as *).

_seed = [12345]


def _rand(n):
    _seed[0] = (_seed[0] * 1103515245 + 12345) & 0x7FFFFFFF
    return _seed[0] % n


def _received(states):
    # The engine's words for a packet it received: line levels (1 = K), 16
    # to a word, then a 1 marking the end.
    levels = list(states)
    words, w, k = [], 0, 0
    for lv in levels + [1]:
        w |= lv << k
        k += 1
        if k == 16:
            words.append(w)
            w, k = 0, 0
    if k:
        words.append(w)
    return words


_out = []
_out.append([rev8(b) for b in range(256)])
for _ in range(60):
    pid = [USB_SETUP, USB_IN, USB_OUT][_rand(3)]
    addr, endp = _rand(128), _rand(16)
    tok = usb_token(pid, addr, endp)
    data = [_rand(256) for _ in range(_rand(9))]
    pkt = usb_data([USB_DATA0, USB_DATA1][_rand(2)], data)
    hs = usb_handshake([USB_ACK, USB_NAK, USB_STALL][_rand(3)])
    for p in (tok, pkt, hs):
        states = usb_line_states(p)
        _out.append([p, usb_words(p), usb_decode(_received(states))])
    _out.append(usb_crc16(data))


# 1-Wire: the OneWire class on a bus simulated a word at a time (what the
# engine would return), with three DS18B20s above the bit level.
class _Ds18b20:
    def __init__(self, serial, raw):
        rom = [0x28] + [(serial >> (8 * i)) & 0xFF for i in range(6)]
        self.rom = rom + [onewire_crc8(rom)]
        pad = [raw & 0xFF, (raw >> 8) & 0xFF, 0x4B, 0x46, 0x7F, 0xFF, 0x0C, 0x10]
        self.pad = pad + [onewire_crc8(pad)]
        self.mode, self.rx, self.tx = "idle", [], []

    @staticmethod
    def bits(data):
        return [(b >> k) & 1 for b in data for k in range(8)]

    def reset(self):
        self.mode, self.rx, self.tx = "rom", [], []

    def to_send(self):
        if self.mode == "send":
            return self.tx[0]
        if self.mode == "search":
            b = self.rb[self.i]
            return (b, 1 - b, 1)[self.ph]
        if self.mode == "busy":
            return 0 if self.busy else 1
        return 1

    def slot(self, line):
        m = self.mode
        if m == "send":
            self.tx.pop(0)
            if not self.tx:
                self.mode = self.after
        elif m in ("rom", "match", "function"):
            self.rx.append(line)
            if len(self.rx) == (64 if m == "match" else 8):
                v, self.rx = self.rx, []
                self.command(m, v)
        elif m == "search":
            if self.ph < 2:
                self.ph += 1
            elif line != self.rb[self.i]:
                self.mode = "idle"
            else:
                self.i, self.ph = self.i + 1, 0
                if self.i == 64:
                    self.mode = "function"
        elif m == "busy" and self.busy:
            self.busy -= 1

    def command(self, m, bits):
        v = 0
        for k in range(len(bits)):
            v |= bits[k] << k
        if m == "rom":
            if v == 0x33:
                self.mode, self.tx, self.after = "send", self.bits(self.rom), "function"
            elif v == 0xCC:
                self.mode = "function"
            elif v == 0x55:
                self.mode = "match"
            elif v == 0xF0:
                self.mode, self.rb, self.i, self.ph = "search", self.bits(self.rom), 0, 0
            else:
                self.mode = "idle"
        elif m == "match":
            self.mode = "function" if bits == self.bits(self.rom) else "idle"
        elif v == 0x44:
            self.mode, self.busy = "busy", 3
        elif v == 0xBE:
            self.mode, self.tx, self.after = "send", self.bits(self.pad), "idle"
        else:
            self.mode = "idle"


class _OneWireBus:
    def __init__(self, devices):
        self.devices, self.rx = devices, []

    def stop(self):
        pass

    def load(self, image):
        pass

    def configure(self, **kw):
        self.clkdiv = kw["clkdiv"]

    def set_pin_modes(self, modes):
        pass

    def run(self):
        pass

    def push(self, v):
        if v & 1:
            for d in self.devices:
                d.reset()
            self.rx.append(0 if self.devices else 1)
            return
        r = 0
        for k in range(((v >> 1) & 7) + 1):
            line = (v >> (4 + k)) & 1
            for d in self.devices:
                line &= d.to_send()
            for d in self.devices:
                d.slot(line)
            r |= line << k
        self.rx.append(r)

    def pop(self):
        return self.rx.pop(0)


_devs = [_Ds18b20(0xA5C1, 0x0191), _Ds18b20(0xA5C3, 0xFF5E), _Ds18b20(0x4213F0, 0x0550)]
_ow = OneWire(_OneWireBus(_devs), [], 12_000_000)
_roms = _ow.search()
_out.append([list(r) for r in _roms])
_out.append([_ow.ds18b20_temperature(r) for r in _roms])
_one = OneWire(_OneWireBus(_devs[:1]), [])
_out.append([list(_one.read_rom()), _one.ds18b20_temperature(), OneWire(_OneWireBus([]), []).reset()])
_out.append(onewire_crc8(bytes([0x02, 0x1C, 0xB8, 0x01, 0, 0, 0])))
print(repr(_out))
