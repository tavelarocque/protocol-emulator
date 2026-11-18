; dmx_tx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; DMX512 transmitter (stage lighting, on RS-485): a break, a mark, then a
; start code and up to 512 slots, each one start bit, 8 data bits LSB
; first and two stop bits at 250 kbit/s.
;
; Pins: P0 = the line, push-pull (to an RS-485 driver). Config: threshold
; 9, the rest as reset.
;
; Host protocol on the TX FIFO:
;   word 0  : bit time - 4, in clock cycles: 36 for 250 kbit/s at 10 MHz
;   then    : one word per slot: bit 0 = 1 to send a break and the mark
;             after it first (so: on the start code), bits 8:1 the byte
;             ([dmx_word])
;
; Timing: every bit is exactly one bit time, and back-to-back slots have
; two stop bits and one cycle more. (Two exactly is legal, but a receiver
; that samples on the bit boundaries then sees the next start bit in the
; sample where it looks for the idle line; sigrok's decoder is one.) The
; break is 9 x (4 x (bit time - 3) + 3) cycles,
; 136 us at 10 MHz (the standard asks a transmitter for 92 us or more),
; and the mark after it 4 bit times, 16 us (12 us or more). Between slots
; the line idles high for as long as the host takes, which the standard
; allows up to a second.
        set pins, 1
        pull                ; bit time - 4
        mov y, osr
next:   pull                ; the line stays high while waiting
        out x, 1            ; break first?
        jmp !x slot
        set pins, 0         ; break: 9 rounds of about 4 bit times
brk:    mov x, y
b:      jmp x-- b [3]
        in null, 1          ; count the rounds in the ISR's bit counter
        jmp !isrf brk
        set pins, 1         ; mark after break
        mov x, y
m:      jmp x-- m [3]
        mov isr, null       ; clear the round counter
slot:   set pins, 0 [1]     ; start bit
        mov x, y
start:  jmp x-- start
bit:    out pins, 1         ; data bit, LSB first
        mov x, y
hold:   jmp x-- hold
        jmp !osre bit
        set pins, 1 [1]     ; two stop bits and a cycle
        mov x, y
stop:   jmp x-- stop [1]
        jmp next
