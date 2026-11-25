; mil1553_bc: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; MIL-STD-1553B, the bus of military aircraft and spacecraft: the chip as
; the bus controller (BC), sending commands and data words to remote
; terminals (RTs), with a second thread that hears every word on the bus,
; the RTs' answers included, and hands each to the host.
;
; A word is 20 bit times at 1 Mbit/s in Manchester II: a sync of three
; bit times, 16 bits most significant first, and odd parity. A bit is
; high then low for a 1, low then high for a 0. A command or status word's
; sync is high for a bit and a half and then low for as long; a data
; word's is the opposite. The words of one message follow one another
; with no gap.
;
; This program, on thread 0, is the transmitter. The host gives it a
; command word and, for a receive command, the data words that go with
; it. The firmware makes each word's sync, its Manchester code and its
; parity (the CRC register with polynomial 1 follows the 16 bits OUT
; shifts, and its bit 0 is then their parity), and reads the command word
; to know how many data words follow it: none for a transmit command (T/R
; set, the RT answers with the data); for a receive command the word
; count, 0 meaning 32, or for a mode command (subaddress 0 or 31) one if
; the mode code is 16 or above. After the message it waits until the bus
; has been quiet for the response timeout before it takes the next
; command, so an RT's answer is never talked over: each wait on RX either
; sees the bus rise within the timeout, and starts again once it is low,
; or times out to [next]. The monitor ([mil1553_mon]) on thread 1 reads
; the answers.
;
; On a real bus the pins drive a 1553 transceiver (an HI-1573 or similar)
; and through it a coupling transformer onto the twisted pair: TX and
; TX-bar are its inputs, both low to keep its transmitter off, and RX is
; its receiver's positive output, which shows every word on the bus, this
; chip's own included.
;
; Pins: P0 = TX, P1 = TX-bar, push-pull; P2 = RX, an input. Config:
; [mil1553_bc_config]: set_base 0, set_count 2; threshold 16; out most
; significant bit first; crc_poly 1, crc_init 0; timeout_vector
; [mil1553_bc_next], timeout 140 (14 us, the standard's least
; no-response timeout); a bit is 10 ticks, so CLKDIV 1 at 10 MHz and 5 at
; 50 MHz give 1 Mbit/s exactly.
;
; Host protocol on the TX FIFO: a command word, then for a receive
; command its data words. Words of one message must follow each other
; with no gap on the bus, so a data word is taken during the sync before
; it: the host must have it there by then (one every 20 us), or that sync
; is stretched.
        set pins, 0             ; the transmitter off: TX and TX-bar low
next:   pull                    ; a command word
        mov isr, osr            ; kept to send
        out null, 5             ; the RT address
        out x, 1                ; T/R
        set y, 0
        jmp !x rcv
        jmp send                ; transmit: the RT sends the data, no data words here
rcv:    out y, 5                ; the subaddress
        jmp !y mode
        set x, 31
        jmp x!=y count
mode:   out y, 1                ; a mode code: one data word for codes 16 to 31
        jmp send
count:  out y, 5                ; the word count
        jmp !y w32
        jmp send
w32:    set x, 1                ; 0 means 32: 1 shifted up five places
        mov osr, x
        out null, 5
        mov y, osr
send:   mov osr, isr            ; Y: data words to follow
        mov crc, null
        set pins, 1 [14]        ; command sync: high for a bit and a half,
        set pins, 2 [11]        ; then low
        jmp bit
bit:    out x, 1                ; a bit, most significant first; the CRC takes it
        jmp !x zero
        set pins, 1 [4]         ; a 1: high,
        set pins, 2             ; then low
        jmp tail
zero:   set pins, 2 [4]         ; a 0: low,
        set pins, 1             ; then high
        jmp tail
tail:   jmp !osre bit
        mov x, crc              ; the parity of the 16
        jmp !x pone
        set pins, 2 [4]         ; odd already: the parity bit is a 0
        set pins, 1 [2]
        jmp ptail
pone:   set pins, 1 [4]         ; even: a 1
        set pins, 2 [2]
        jmp ptail
ptail:  jmp y-- dword           ; a data word follows at once
        set pins, 0             ; the end of the message: transmitter off
quiet:  wait 0 pin 2            ; until the bus has been quiet for the timeout
        wait 1 pin 2 timeout
        jmp quiet
dword:  set pins, 2 [12]        ; data sync: low for a bit and a half,
        pull                    ; the data word
        mov crc, null
        set pins, 1 [11]        ; then high
        jmp bit
