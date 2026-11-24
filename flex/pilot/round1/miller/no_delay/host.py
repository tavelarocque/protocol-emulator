"""Host side of the Miller transmitter (miller.s).

The firmware is a fixed-rate level streamer: every 50 cycles (half a bit at
100 kbit/s) it takes one bit from the TX stream and drives P0 to that level.
Each TX word carries 16 half-bit levels, the first one in bit 0.

So the Miller coding is done here: encode() turns the messages into the
sequence of line levels, half bit by half bit, and packs them into words.
"""

HALF_BITS_PER_WORD = 16
LEAD_IN = 16   # half bits of idle high before the first start bit (800 cycles)
GAP = 16       # half bits of silence between messages (800 cycles; 400..20000 allowed)


def message_bits(message):
    """Start bit, the bytes least significant bit first, end bit."""
    bits = [0]
    for byte in message:
        if not 0 <= byte <= 255:
            raise ValueError("byte out of range: %r" % (byte,))
        for i in range(8):
            bits.append((byte >> i) & 1)
    bits.append(0)
    return bits


def message_levels(message, level):
    """Line level in each half bit of a message, starting from `level`.

    Returns (levels, level after the message).
    """
    bits = message_bits(message)
    levels = []
    for k, bit in enumerate(bits):
        if k == 0:
            at_start, in_middle = True, False       # start bit: always an edge
        elif bit == 1:
            at_start, in_middle = False, True       # 1: edge in the middle
        else:
            at_start, in_middle = bits[k - 1] == 0, False   # 0 after 0: edge at start
        if at_start:
            level ^= 1
        levels.append(level)
        if in_middle:
            level ^= 1
        levels.append(level)
    return levels, level


def encode(messages):
    if not 1 <= len(messages) <= 8:
        raise ValueError("1 to 8 messages")
    level = 1                       # the output register resets high
    stream = [level] * LEAD_IN
    for i, message in enumerate(messages):
        if not 1 <= len(message) <= 32:
            raise ValueError("a message is 1 to 32 bytes")
        if i > 0:
            stream += [level] * GAP
        levels, level = message_levels(message, level)
        stream += levels
    # Hold the last level to the end of the last word. After that the
    # firmware stalls on the empty FIFO and the line stays where it is.
    while len(stream) % HALF_BITS_PER_WORD:
        stream.append(level)
    words = []
    for i in range(0, len(stream), HALF_BITS_PER_WORD):
        word = 0
        for j, lv in enumerate(stream[i:i + HALF_BITS_PER_WORD]):
            word |= lv << j
        words.append(word)
    return words


if __name__ == "__main__":
    import sys
    msgs = [[int(b, 0) for b in arg.split(",")] for arg in sys.argv[1:]]
    for w in encode(msgs):
        print(w)
