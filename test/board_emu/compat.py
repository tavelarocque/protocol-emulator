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
print(repr(_out))
