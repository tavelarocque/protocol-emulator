; cec: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; HDMI-CEC initiator: the one-wire control bus between HDMI devices. It
; sends messages and reads each block's acknowledgement.
;
; A message is a start bit (low 3.7 ms, high 0.8 ms) and then blocks of
; ten bits: eight of data, most significant first, EOM (1 on the last
; block) and ACK. Every bit is 2.4 ms long and begins with the line low:
; for 0.6 ms it is a 1, for 1.5 ms a 0. The initiator sends the ACK bit
; as a 1, and a follower that accepts the block holds the line low to
; make it a 0.
;
; Pins: P0 = the CEC line, open-drain. Config: [cec_config]: set_base 0,
; set_count 1; in_base 0; out most significant bit first; CLKDIV makes a
; tick 0.1 ms: 1000 at 10 MHz.
;
; Host protocol:
;   TX : one word for each block: the byte in bits 15:8, EOM in bit 7,
;        and in bit 6 a 1 if the message is to everyone (address 15).
;        The first block of a message is its header: the initiator's
;        address in the top four bits, the destination's in the low four.
;   RX : one word for each block sent: the line 1.0 ms into its ACK bit,
;        0 if a follower held it low.
; A message to one device is acknowledged by a 0; in a message to
; everyone a 0 is a follower's objection. Either way a block that fails
; ends the message there, as the standard asks: the blocks still queued
; for it are taken from the FIFO and not sent, so the host sees fewer
; words than it queued blocks, the last of them the failure.
;
; The next block must be in the FIFO before the last one's ACK bit is
; over, or the line stays idle and the followers give the message up.
; After a message the program keeps off the bus for seven bit times, as
; an initiator that wants to send again must.
;
; It does not listen before it sends, or give way to another initiator.
idle:   pull                    ; a message's first block
        set pins, 0 [15]        ; start bit: low for 3.7 ms,
        nop [15]
        nop [4]
        set pins, 1 [5]         ; then high for 0.8 ms
block:  set y, 8                ; 9 bits: the block's 8 and EOM
bit:    out x, 1
        set pins, 0 [4]         ; every bit begins low: 0.6 ms for a 1,
        jmp !x zero
        set pins, 1 [14]        ; and high for the rest of its 2.4 ms
        jmp next
zero:   nop [8]                 ; 1.5 ms for a 0
        set pins, 1 [6]
next:   jmp y-- bit
        nop                     ; (the last bit's high time, as inside the loop)
        set pins, 0 [5]         ; ACK bit: sent as a 1,
        set pins, 1 [3]
        in pins, 1              ; and 1.0 ms after its edge the line is low if a follower holds it
        mov y, isr
        push                    ; the line as it was read
        jmp !y low
        out y, 1                ; high: right only in a message to everyone
        jmp !y abort
        jmp cont
low:    out y, 1 [1]            ; low: right only in a message to one device
        jmp !y cont
        jmp abort
cont:   jmp !x more             ; X is the bit sent last: EOM
end:    set y, 10               ; end of message: seven bit times off the bus
free:   jmp y-- free [15]
        jmp idle
more:   pull [2]                ; the next block: its first bit begins 2.4 ms after the ACK bit did
        jmp block
abort:  jmp x-- end             ; the message ends here; was that its last block?
        pull                    ; no: take the rest of it from the FIFO, unsent
        out null, 8
        out x, 1
        jmp abort
