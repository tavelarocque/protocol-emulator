"""Host side of st7735.s: turn ST7735 transfers into TX FIFO words.

Word format (16 bits, one word per byte sent, in sending order):
    bit 15     1 if another byte of the same transfer follows this one,
               0 if this is the last byte of its transfer
    bits 14..7 the byte, most significant bit at bit 14
    bits 6..0  0 (never shifted out)
The first word of each transfer is its command byte; the firmware drives
D/CX low for it and high for every later byte of the transfer, and raises
CSX after the word whose bit 15 is 0.
"""


def encode(transfers):
    words = []
    for command, data in transfers:
        bytes_ = [command] + list(data)
        last = len(bytes_) - 1
        for i, b in enumerate(bytes_):
            more = 1 if i < last else 0
            words.append((more << 15) | ((b & 0xFF) << 7))
    return words
