; can_rx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; CAN (ISO 11898 classical CAN, through a transceiver): a transmitter and a
; listen-only receiver, on the two threads. Firmware alone. The
; transmitter makes the whole frame from the identifier and the data: bit
; stuffing, CRC, arbitration, the ACK slot. What the pair is not: a full
; node. It does not acknowledge other nodes' frames or send error frames,
; which need the frame decoded as it arrives, on a clock recovered from
; the bus, in the receiver.
;
; Pins: P0 = RXD (input, through the synchroniser), P1 = TXD (push-pull;
; 0 is dominant). The receiver's bit is 10 ticks, so its CLKDIV = core
; clock / (10 x bit rate): 8 for 125 kbit/s at 10 MHz. The transmitter's
; is 20 ticks, at half that CLKDIV, so the core clock is 20 x the bit rate
; x a whole number. The receiver hands the host what was on the wire, and
; the host removes the stuffing and checks the frame ([Can.decode] here,
; Can in the board driver).
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
; The transmitter, [can_tx], on thread 1, is described below.
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
