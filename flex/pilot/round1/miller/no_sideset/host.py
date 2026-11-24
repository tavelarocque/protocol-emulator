"""Host side of the Miller transmitter (miller.s).

Word format: every TX word is 16 line levels for P0, least significant bit
first, one level per half bit time (50 cycles at 10 MHz, 100 kbit/s). The
chip shifts one level out every 50 cycles and holds the last one when the
words run out. All Miller coding is done here.
"""

LEAD_IN_HALF_BITS = 8     # line high before the first start bit (400 cycles)
GAP_HALF_BITS = 12        # silence after each end bit (600 cycles, >= 400)
WORD_BITS = 16


def _message_levels(data, level):
    """Half-bit levels of one message, starting from line level `level`.

    Returns (levels, final_level)."""
    bits = [0]
    for byte in data:
        if not 0 <= byte <= 255:
            raise ValueError("byte out of range: %r" % (byte,))
        for i in range(8):
            bits.append((byte >> i) & 1)
    bits.append(0)

    levels = []
    prev = None
    for k, bit in enumerate(bits):
        if bit == 1:
            # one transition, in the middle of the bit
            levels.append(level)
            level ^= 1
            levels.append(level)
        else:
            # a 0: transition at its start if it is the start bit or follows a 0
            if k == 0 or prev == 0:
                level ^= 1
            levels.append(level)
            levels.append(level)
        prev = bit
    return levels, level


def encode(messages):
    level = 1                                   # the output register resets high
    stream = [level] * LEAD_IN_HALF_BITS
    for data in messages:
        levels, level = _message_levels(list(data), level)
        stream.extend(levels)
        stream.extend([level] * GAP_HALF_BITS)
    # fill the last word with the level the line already has
    while len(stream) % WORD_BITS:
        stream.append(level)
    words = []
    for i in range(0, len(stream), WORD_BITS):
        w = 0
        for j in range(WORD_BITS):
            w |= stream[i + j] << j
        words.append(w)
    return words


if __name__ == "__main__":
    import sys
    msgs = [[int(b, 0) for b in arg.split(",")] for arg in sys.argv[1:]]
    for w in encode(msgs):
        print(w)
