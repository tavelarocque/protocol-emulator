; sbus_tx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; Futaba SBUS transmitter: the serial bus a radio control receiver sends
; its channels on, to a flight controller or to servos. It is a UART
; turned upside down: the line rests low, a start bit is high, then 8
; data bits least significant first, each sent as its opposite, an even
; parity bit sent as its opposite, and two stop bits low, at 100 kbit/s.
;
; The firmware makes each character from a plain byte: the start bit, the
; inversion of every bit, the parity and the stop bits are its work. No
; instruction inverts a pin or a register, so a data bit goes to X and
; [jmp x--] takes one from it: X's bit 0 is then the bit's opposite, and
; [mov pins, x] puts that on the line. The parity is kept by the CRC
; register, which takes every bit OUT shifts: with the polynomial 1 its
; bit 0 is the parity of the bits so far, and read with [crc_invert] it
; comes back as the level the line needs.
;
; Pins: P0 = the line, push-pull, low while there is nothing to send.
; Config: [sbus_tx_config]: threshold 8; crc_poly 1, crc_init 0,
; crc_invert; the rest as reset.
;
; Host protocol on the TX FIFO ([sbus_tx_words]):
;   word 0  : bit time - 6, in clock cycles: 94 for 100 kbit/s at 10 MHz,
;             494 at 50 MHz (both exact)
;   then    : one byte per word
; An SBUS message is 25 bytes: 0x0F, the sixteen 11-bit channels packed
; least significant bit first into 22 bytes, a byte of flags, 0x00. The
; host packs them ([sbus_message]); the firmware does not count bytes.
;
; Timing: every bit is exactly one bit time, and back-to-back bytes have
; exactly two stop bits, so a message is 3 ms at 100 kbit/s. Between
; bytes the line rests low for as long as the host takes.
        set pins, 0         ; the line rests low
        pull                ; bit time - 6
        mov y, osr
next:   pull                ; wait for a byte; the line stays low
        mov crc, null       ; the parity starts from 0
        set pins, 1 [1]     ; start bit: high
        mov x, y
start:  jmp x-- start
bit:    out x, 1            ; a data bit, LSB first; the CRC register takes it too
        jmp x-- inv         ; X = bit - 1: its bit 0 is the bit's opposite
inv:    mov pins, x         ; the bit, inverted
        mov x, y
hold:   jmp x-- hold
        jmp !osre bit       ; until all 8 are out
        mov x, crc [1]      ; the parity of the 8, read inverted
        mov pins, x         ; the parity bit, even, inverted
        mov x, y [3]
par:    jmp x-- par
        set pins, 0 [5]     ; two stop bits: low
        mov x, y
stop:   jmp x-- stop [1]
        jmp next
