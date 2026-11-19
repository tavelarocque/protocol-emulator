; nec_rx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; NEC infrared receiver: the other end of [nec_tx], on the output of an IR
; receiver module, which is low while it sees carrier.
;
; Pins: P0 = the module's output (the program tests pin 0 by number).
; Config: [nec_rx_config]: start = [nec_rx_start]; in_base 0; threshold
; 16; timeout 128, timeout_vector 0; CLKDIV sets the tick to 1/16 of NEC's
; 562.5 us unit: 352 for 35.2 us at 10 MHz.
;
; Host protocol: RX words come in pairs. A frame is the address in bits
; 7:0 with its complement (or the high address byte) in 15:8, then the
; command and its complement. A frame that was cut short after its first
; word is completed with 0x0000, which no command word can be, so the
; pairs never slip. Checking the complements is the host's part.
;
; How a frame is told from everything else, times in units of 562.5 us:
;   - its first burst must still be there after 5 units (the leader is 16;
;     a bit's burst is 1);
;   - the silence after it must still be there after 4.5 units (it is 8;
;     a repeat code's is 4, and is ignored);
;   - each bit is read about 1.3 units after its burst ends: silence
;     still, a 1 (whose silence is 3 units); the next burst already, a 0
;     (1 unit). The thread is back waiting for that burst to end well
;     before it does: a remote may run 20% fast or slow, with room to
;     spare;
;   - a wait of more than 8 units for a bit's burst to begin or end
;     abandons the frame, through the timeout vector. X remembers whether
;     a word has gone to the host yet.
abort:  jmp !x start            ; cut short before any word went: start again
        mov isr, null
        in null, 16
        push                    ; after one: zeros in the command's place
start:  mov isr, null           ; nothing received yet
        wait 0 pin 0            ; a burst begins
        set x, 4
lead:   jmp x-- lead [15]       ; 5 units later
        mov osr, pins
        out x, 1
        jmp !x leader           ; still there: a frame's leading burst
        jmp start               ; gone: something else
leader: wait 1 pin 0            ; the leading burst ends
        set x, 3
gap:    jmp x-- gap [15]        ; 4.5 units later
        nop [4]
        mov osr, pins
        out x, 1
        jmp !x start            ; a burst already: a repeat code
        set x, 0                ; no word sent yet
        set y, 31               ; 32 bits
bit:    wait 0 pin 0 timeout    ; the bit's burst begins
        wait 1 pin 0 timeout    ; and ends
        jmp !isrf same          ; 16 bits waiting? Send them now, in the
        push                    ; silence, not after a read, when the next
        set x, 1                ; burst may already be on its way out
        jmp read
same:   nop [2]                 ; (as long as sending takes)
read:   nop [15]                ; about 1.3 units after the burst
        in pins, 1              ; silence still: a 1. The next burst: a 0
        jmp y-- bit
        push                    ; the second word
        jmp start
