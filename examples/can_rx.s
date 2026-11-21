; can_rx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; CAN (ISO 11898 classical CAN, through a transceiver): a node, on the two
; threads and the bit sampler. It sends data frames, receives every other
; node's and acknowledges them. Firmware alone, 11-bit identifiers.
;
; What it leaves out: error frames and the error counters behind them (it
; stays silent about a frame it finds wrong, as a node in the standard's
; error-passive state does, and simply does not acknowledge it); overload
; frames; extended identifiers, whose frames it neither receives nor
; acknowledges; answering remote frames, which is the host's business.
;
; Pins: P0 = RXD (input, through the synchroniser), P1 = TXD (push-pull;
; 0 is dominant). P2 and P3 are taken: the sampler listens to P0 and shows
; what it recovers there, two pins on, so that P0 is still the line itself
; for the transmitter. A bit is 20 ticks for both threads and 20 samples
; for the sampler: one CLKDIV for all three, the core clock / (20 x bit
; rate): 4 for 125 kbit/s at 10 MHz. [Can.sampler] has the sampler's
; settings: every edge restarts its phase, the bit is taken 13 samples
; on, runs of equal bits are kept time through, and stuff bits are taken
; out, so the receiver sees a frame's bits and nothing else.
;
; The receiver, [can_rx], on thread 0. A pulse lasts one sample, which is
; one tick of this thread, so each `wait 1 pin 3` meets the next bit. The
; CRC register follows IN: every bit of the frame goes through it, and
; after the last bit of the CRC it holds 0 if the frame is good.
;
; It waits for a dominant bit, the start of a frame, and takes the 14 bits
; ID, RTR, IDE, r0. In r0, which is dominant in every frame, it looks at
; TXD: low means thread 1 is sending this very frame (it cannot still be
; low after losing arbitration, which is over by then), and a node does
; not receive or acknowledge its own frame. Then the DLC, as many bytes as
; it says (none in a remote frame; eight for 8 and above), and the 15 bits
; of the CRC. If the CRC register holds 0, it drives TXD low for the ACK
; slot: from 7 ticks after the pulse of the CRC delimiter, which is the
; end of that bit or a tick past it, for 20 ticks.
; After its own frame, after an extended one, and when it starts, it
; waits for the line to stay recessive for ten bit times before it takes
; a dominant bit for a start of frame. (After a frame with a wrong CRC it
; does not wait: the next frame may come eleven bit times after that
; one's last dominant bit, which can be five bits before its end. If the
; next dominant bit is another node's ACK or an error flag instead, what
; follows it reads as an extended frame or one more bad one.) That is a wait on RXD itself with
; TIMEOUT = 200 ticks, and [Can.rx_idle] is its vector: the recovered
; bits would not do, since with the stuff bits gone a frame's data can
; be recessive for any number of them.
;
; RX words for a frame: the 14 bits ID, RTR, IDE, r0; then DLC, data and
; CRC, 15 bits to a word, the last word short, and an empty word after it
; when they fill their words exactly; then 0xFFFF if the frame was good
; and acknowledged, 0xFFFE if not. Every other word is below 0x8000, so
; the two marks cannot be taken for data ([Can.rx_frames]).
;
; The transmitter, [can_tx], on thread 1, is described below.
integ:  wait 1 pin 0            ; the line itself recessive...
        wait 0 pin 0 timeout    ; ...and for ten bit times: between frames
        jmp integ               ; it fell first: again
idle:   wait 1 pin 2            ; timeout vector. (An ACK may still show)
        wait 0 pin 2            ; a dominant bit: the start of a frame
        mov crc, null
        mov isr, null
        set y, 13
h:      wait 1 pin 3
        in pins, 1
        jmp y-- h               ; ID, RTR, IDE, r0
        mov osr, pins           ; r0 is on the bus now, dominant: whose?
        out null, 1
        out y, 1                ; TXD
        jmp !y integ            ; thread 1's: not received, not acknowledged
        mov osr, isr
        out null, 1             ; r0
        out x, 1                ; IDE
        jmp !x std
        jmp integ               ; an extended frame: not for this receiver
std:    out x, 1                ; RTR, kept in X
        push                    ; the first word
        set y, 3
d:      wait 1 pin 3
        in pins, 1
        jmp y-- d
        mov y, isr              ; the DLC
        jmp !x data
        jmp crc                 ; a remote frame has no data
data:   mov osr, isr
        out null, 3
        out x, 1                ; the DLC's top bit: 8 and above, 8 bytes
        jmp !x byte
        set y, 8
byte:   jmp y-- more
        jmp crc
more:   set x, 7
b:      wait 1 pin 3
        in pins, 1
        jmp x-- b
        jmp byte
crc:    set y, 14
c:      wait 1 pin 3
        in pins, 1
        jmp y-- c
        mov x, crc              ; 0: nothing left over, the frame is good
        wait 1 pin 3            ; the CRC delimiter
        jmp !x ack
        push                    ; bad: the bits left, then 0xFFFE
        jmp y-- bad
bad:    in y, 16
        jmp idle                ; the next dominant bit may be a new frame
ack:    nop [4]                 ; to the end of the delimiter
        set pins, 0 [15]        ; the ACK slot, one bit long
        nop [3]
        set pins, 1
        push                    ; the bits left, then 0xFFFF
        in y, 16
        jmp idle
