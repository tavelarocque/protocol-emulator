"""Host side of st7735.s: turn ST7735 transfers into TX FIFO words.

Word format (16 bits), one word per byte sent:
    bits 15..8  the byte (command or data), sent most significant bit first
    bit  7      1 if another data byte of the same transfer follows this one,
                0 if this byte is the last of its transfer (CSX rises after it)
    bits 6..0   0
The first word of each transfer is its command byte (sent with D/CX low);
every later word of that transfer is a data byte (sent with D/CX high).
"""

MORE = 0x0080


def encode(transfers):
    words = []
    for command, data in transfers:
        seq = [command] + list(data)
        last = len(seq) - 1
        for i, byte in enumerate(seq):
            words.append(((byte & 0xFF) << 8) | (MORE if i < last else 0))
    return words
