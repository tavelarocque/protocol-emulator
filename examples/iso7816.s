; iso7816: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; ISO 7816-3 smart card reader (the interface device), the character
; layer of T=0: the card's clock, its reset, and characters both ways on
; one open-drain I/O line with their parity, guard times and the error
; signal that asks for a character again.
;
; The card's rules (ISO/IEC 7816-3): an elementary time unit (etu) is
; F/D clock cycles, 372 until a PPS exchange changes it. A character is a
; start bit (low), 8 data bits and a parity bit, each one etu, then I/O
; high for the guard time: the next character starts 12 etu or more after
; the one before, and a character sent the other way 16 etu or more after
; it. A receiver that finds the parity wrong pulls I/O low 10.5 etu after
; the start for 1 to 2 etu (the error signal); the sender looks at I/O at
; 11 etu and, if it is low, sends the character again 2 etu or more
; later. A reset is RST low for 400 clock cycles or more with the clock
; running; the card's answer to reset starts 400 to 40,000 cycles after
; RST rises.
;
; Two threads. Thread 1 runs [iso7816_clk], the clock: CLK on P0, high
; one tick and low the next, so CLK is the core clock over 2 x its CLKDIV,
; 5 MHz at 10 MHz (CLKDIV 1) and at 50 MHz (CLKDIV 5), the most a card may
; be given during its answer to reset. Thread 0 runs this program with
; twice that CLKDIV, so one of its ticks is one period of CLK and an etu
; is 372 ticks, exactly, whatever the clock: 74.4 us at 5 MHz, 13,441
; bit/s, a character every 893 us. Both start in one CTRL write.
;
; The bit timing is the default F = 372, D = 1 only: the reader sends no
; PPS, which leaves a card in the negotiable mode at those values, and a
; card in the specific mode (TA2 in its answer) at other values needs
; another program. CLK runs as long as thread 1 does; the card's clock
; stop is not used.
;
; A reset is the thread starting: RST low for 2,118 ticks, then high
; (400 clock cycles is the least ISO 7816-3 allows; the rest covers the
; host's time to make the pins outputs after the first start). The host
; resets the card by stopping thread 0 and starting it again, which
; leaves thread 1 and CLK running.
;
; Then the program listens. A start bit is taken from a [wait] on I/O
; whose timeout (TIMEOUT ticks; 3 or more) lands on [poll], which looks
; for a word from the host without waiting for one: with autopull, the
; OUT that empties the OSR refills it only if the TX FIFO has a word, and
; [jmp !osre] tells which. So a character from the card is caught a few
; ticks after its start bit falls even while the host is silent, and a
; word from the host is sent as soon as the line is free.
;
; A character from the card is sampled in the middle of each bit, from
; 1.5 etu after its start bit falls; the CRC register (polynomial 1)
; follows the bits IN takes, so after the parity bit it holds 0 if the
; parity is right. Right: the byte goes to the host. Wrong: nothing goes
; to the host, I/O is pulled low from 10.5 etu for 1.46 etu (544 ticks),
; and the program listens for the card's repetition.
;
; A character to the card: the byte from the host; a start bit; 8 data
; bits, least significant first, each read back from the line as it ends
; so the CRC register follows what was sent; the parity bit from the CRC
; register; I/O released at 10 etu; and at 11 etu a [wait] for the card's
; error signal: if there is none, its timeout lands on [poll] again. If
; the card signals an error, the character goes again 2.4 etu after the
; signal is seen. Characters from the host follow one another 12.08 etu
; apart (TIMEOUT 31). The first one after a character from the card
; waits 6 etu more, so it starts 16 etu or more after that character's
; start bit: X is 0 when the last thing on the line was the card's.
;
; The convention is the host's: the CRC register's starting value is the
; parity, 0 for the direct convention (TS = 3Bh: a high level is a 1, the
; least significant bit first, an even number of 1s with the parity bit)
; and 1 for the inverse (TS = 3Fh: low is 1, most significant bit first,
; so the levels have an odd number of highs); in the inverse convention
; the host turns each byte round and inverts it. The program does not
; change convention on TS by itself.
;
; Pins: P0 = CLK (thread 1, push-pull, side-set); P1 = RST, push-pull;
; P2 = I/O, open-drain, with the card's pull-up. Config:
; [iso7816_config]: set_base 1, set_count 2 (RST and I/O: SET writes 2
; for RST low, 3 for RST high and I/O released, 1 to pull I/O low with
; RST high); out_base 2, out_count 1; in_base 2; threshold 8; autopull;
; crc_in, crc_poly 1, crc_init 0 or 1; timeout_vector [iso7816_poll];
; timeout 31. [iso7816_clk_config]: sideset_base 0, sideset_count 1.
;
; Host protocol: TX words are bytes to send, the line's bits in bits 7:0
; (the byte itself in the direct convention). RX words are the
; characters the card sent and the reader took: the line's bits in 7:0
; and the parity bit in bit 8. A full RX FIFO holds up the program, and
; a character from the card meanwhile is lost: the host takes each word
; within about 12 etu (893 us at 5 MHz).
        set pins, 2             ; RST low, I/O released: the card is reset
        set x, 3                ;   for 2,118 ticks,
rst1:   set y, 31         [15]
rst:    jmp y-- rst       [15]
        jmp x-- rst1
        set pins, 3             ;   then RST high: the answer to reset comes
        jmp idle
poll:   mov osr, null           ; the timeout vector: has the host a word?
        out null, 7
        out null, 1             ; the OSR empties: autopull refills it if there is one
        jmp !osre send
idle:   wait 0 pin 2 timeout    ; a start bit from the card, or after TIMEOUT ticks poll
        mov isr, null     [15]  ; a character from the card: R
        mov crc, null     [15]
        set y, 31         [13]
rs:     jmp y-- rs        [15]
rbit:   in pins, 1              ; the 8 data bits from R + 558, the middle of each
        set y, 29         [9]
rl:     jmp y-- rl        [11]
        jmp !isrf rbit
        in pins, 1              ; the parity bit, R + 3534
        mov x, crc              ; X: 0 if the parity is right
        jmp !x good
        mov isr, null     [15]  ; wrong: dropped, and from R + 3905
        set y, 20         [15]
el:     jmp y-- el        [15]
        set pins, 1       [15]  ;   I/O low, the error signal
        set y, 31         [15]
eh:     jmp y-- eh        [15]
        set pins, 3             ;   released 544 ticks later
        jmp idle                ;   the card sends it again
good:   push                    ; the byte, and its parity bit in bit 8
        wait 1 pin 2            ; the parity bit over
        jmp idle
send:   jmp x-- go              ; X is 0 after a character from the card:
        set x, 5                ;   six times
ta:     set y, 29         [9]
tal:    jmp y-- tal       [11]
        jmp x-- ta              ;   an etu, which leaves X not 0
go:     set y, 29               ; an etu: the guard time after a character sent
gl:     jmp y-- gl        [11]
again:  mov isr, osr            ; the byte
        mov crc, null
        set pins, 1       [10]  ; the start bit: T
        set y, 29
sl0:    jmp y-- sl0       [11]
sbit:   mov pins, isr     [8]   ; a data bit, from T + 372
        set y, 29
sl:     jmp y-- sl        [11]
        in pins, 1              ; read back as it ends, for the parity
        jmp !isrf sbit
        mov pins, crc     [10]  ; the parity bit, T + 3348
        set y, 29
pl:     jmp y-- pl        [11]
        set pins, 3       [10]  ; I/O released, T + 3720: the guard time
        set y, 29
gt:     jmp y-- gt        [11]
        wait 0 pin 2 timeout    ; T + 4092: the card's error signal? If not, poll
        set y, 31         [15]  ; it is: wait for it to end,
w:      jmp y-- w         [15]
        wait 1 pin 2
        jmp go                  ; and send the character again
