"""Host side of st7735.s: turn ST7735 transfers into TX FIFO words.

One 16-bit word per byte sent, shifted out by the chip from bit 15 down:

  bits 15..12  pin state before the first clock: CSX (always 0), D/CX, 0, bit 7
  bits 11..5   bits 6..0 of the byte
  bits 4..1    pin state after the eighth clock: CSX, D/CX, 0, bit 0
  bit  0       unused, 0

D/CX is 0 for the command byte and 1 for data bytes. The "CSX after" bit is 1
only in the last byte of a transfer, which ends the transfer.
"""


def word(byte, is_data, is_last):
    byte &= 0xFF
    d = 1 if is_data else 0
    last = 1 if is_last else 0
    return (
        (d << 14)
        | ((byte >> 7) << 12)
        | ((byte & 0x7F) << 5)
        | (last << 4)
        | (d << 3)
        | ((byte & 1) << 1)
    )


def encode(transfers):
    words = []
    for command, data in transfers:
        data = list(data)
        words.append(word(command, False, not data))
        for i, b in enumerate(data):
            words.append(word(b, True, i == len(data) - 1))
    return words


if __name__ == "__main__":
    import ast
    import sys

    for w in encode(ast.literal_eval(sys.argv[1])):
        print(w)
