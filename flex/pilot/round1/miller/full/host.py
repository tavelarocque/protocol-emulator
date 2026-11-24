"""Host side of the Miller transmitter in miller.s.

Word format (one 16-bit TX word per data byte):
    bits 7..0   the data byte (the chip sends it least significant bit first)
    bit  8      1 on the last byte of a message, 0 otherwise
    bits 15..9  0 (ignored by the chip)

The chip adds the start bit, the end bit and the silent gap between messages
itself, and stops with the line as it is when the words run out.
"""


def encode(messages):
    """messages: list of 1..8 messages, each a list of 1..32 ints 0..255.
    Returns the TX words (ints 0..65535) in the order the host pushes them."""
    words = []
    for message in messages:
        message = list(message)
        if not message:
            raise ValueError("a message needs at least one byte")
        last = len(message) - 1
        for i, byte in enumerate(message):
            byte = int(byte)
            if not 0 <= byte <= 255:
                raise ValueError("byte out of range: %r" % (byte,))
            words.append(byte | (0x100 if i == last else 0))
    return words


if __name__ == "__main__":
    print(encode([[0x16], [0xFF, 0x00]]))
