; can_rx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; CAN (ISO 11898 classical CAN, through a transceiver): a transmitter and a
; listen-only receiver, on the two threads. Firmware alone, on the finished
; hardware. What it is not: a full node. It does not acknowledge other
; nodes' frames or send error frames, which need the frame decoded as it
; arrives; that does not fit in what is left of 64 instructions.
;
; Pins: P0 = RXD (input, through the synchroniser), P1 = TXD (push-pull;
; 0 is dominant). A bit is 10 ticks, so CLKDIV = core clock / (10 x bit
; rate): 8 for 125 kbit/s at 10 MHz, 1 for 1 Mbit/s. As with USB, the host
; does everything above the wire (identifier, length, CRC15, bit stuffing:
; [Can.frame_bits] here, Can in the board driver) and the engines own what
; the host is too slow for: bit timing, arbitration, the ACK slot, and
; resynchronisation.
;
; The receiver, [can_rx], on thread 0, records every frame on the bus, the
; transmitter's own included. It waits for a start of frame (RXD falling on
; an idle bus), then samples each bit about 70% of the way through and
; pushes the levels 15 to a word, the first in bit 0. Eight recessive bits
; in a row end the frame: the bits left over are pushed as a last short
; word (0 if there are none), then 0xFFFF, which no data word can be. The
; stuffed bits come out as they were on the wire; [Can.decode] removes the
; stuffing and checks the frame.
; Resynchronisation: straight after each sample the receiver waits for
; RXD to be low, for up to TIMEOUT = 4 ticks. After a dominant sample that
; passes at once, and the next sample is 10 ticks after the last. After a
; recessive one it is a watch for the falling edge that ends the bit: an
; edge puts the next sample 7 ticks after itself; with none, the timeout
; vector, [can_rx_same], samples again 10 ticks after the last. Which of
; the two it was is read back from the bit just recorded (the receiver's
; OUT takes the newest bit of a copy of the ISR, so its SHIFT has OUT most
; significant first). Every path takes the same time whether or not a
; word is pushed. Stuff bits guarantee a falling edge every 10 bits at
; least, and the watch reaches 2 ticks either side of where the edge is
; due, so the sender's clock may differ by 2%; CAN allows 1.58%.
;
; The transmitter, [can_tx], on thread 1. TX words: N - 1, then the N bits
; of a frame after its start-of-frame bit, up to its ACK delimiter,
; stuffed, 16 to a word, the first in bit 0 ([Can.tx_words]). It waits
; until the bus has been recessive for 11 bit times, looks once more, and
; 2 ticks later is driving the start-of-frame bit itself; then the N bits
; at exactly 10 ticks each. A node that started in those 2 ticks is at
; most a quarter of a bit ahead, and the two arbitrate as CAN intends. Six
; ticks into every recessive bit it has sent, the transmitter reads RXD: if
; the bus is dominant, another node is driving, and it stops at once and
; leaves the bus alone. One RX word reports where:
;   0       in the ACK slot: a receiver acknowledged the frame
;   0xFFFF  never: the frame went out and nobody acknowledged it
;   k       N - 2 - k bits in: arbitration lost to a frame with a lower
;           identifier (or another node signalled an error); send it again
; A wait with TIMEOUT = 0 is the branch on RXD; [can_tx_lost] is the vector,
; used while waiting for an idle bus as well, which X being 0 tells apart.
; After stopping it still takes the rest of the frame's words from the TX
; FIFO, so the next command is read as one.
idle:   wait 1 pin 0            ; the bus recessive...
        wait 0 pin 0            ; ...then a start of frame
        set y, 7 [5]
smp:    in pins, 1              ; record RXD
        wait 0 pin 0 timeout    ; recessive: watch for a falling edge
        mov osr, isr            ; dominant, or it fell: which did we record?
        out x, 1
        jmp !x dom              ; recessive, so that was an edge: 7 ticks on
chk:    jmp !isrf nf
        push                    ; a full word, in the same 3 ticks
        jmp smp
nf:     jmp smp [1]
dom:    set y, 7                ; dominant: 10 ticks after the last sample
        jmp chk
same:   jmp y-- chk             ; timeout vector: still recessive, no edge
        push                    ; the 8th in a row: the frame is over
        in y, 16                ; Y is 0xFFFF
        push
        jmp idle
