"""Host-side encoder for ws2812.s.

Word format (16-bit TX words), per frame:
  1. N = number of bits in the frame = 24 * number of LEDs (0..65535,
     so at most 2730 LEDs per frame).
  2. ceil(N / 16) data words carrying the byte stream G, R, B of each LED in
     chain order, MSB first, two bytes per word: the first byte in bits 15..8,
     the second in bits 7..0. If the LED count is odd, the low byte of the last
     word is padding (ignored by the chip).
The chip sends the bits, then holds the line low for about 310 us (the latch)
before reading the next frame's count word. An empty frame (no LEDs) is a
count word of 0 and produces just a latch.
"""

MAX_LEDS = 0xFFFF // 24


def encode(frames):
    words = []
    for frame in frames:
        if len(frame) > MAX_LEDS:
            raise ValueError("at most %d LEDs per frame" % MAX_LEDS)
        data = bytearray()
        for r, g, b in frame:
            for v in (g, r, b):
                if not 0 <= v <= 255:
                    raise ValueError("colour component out of range: %r" % (v,))
                data.append(v)
        words.append(24 * len(frame))
        if len(data) % 2:
            data.append(0)
        for i in range(0, len(data), 2):
            words.append((data[i] << 8) | data[i + 1])
    return words
