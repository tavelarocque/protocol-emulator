; stepper: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; Step and direction, for stepper motor drivers (A4988, DRV8825 and the
; like): a direction level and one pulse for each step, at an exact
; period.
;
; Pins: P0 = STEP (side-set), P1 = DIR, both push-pull. Config:
; [stepper_config]: sideset_base 0, sideset_count 1; out_base 1, out_count
; 1; out most significant bit first; CLKDIV sets the tick: 10 for 1 us at
; 10 MHz.
;
; Host protocol, for each move at one speed:
;   TX : the direction in bit 15 and the number of steps, less one, in
;        bits 14:0; then the period of a step in ticks, less four.
;   RX : one word, 0, when the move's last step has been made.
; STEP is high for two ticks of every period, and DIR is set three ticks
; before a move's first step. A ramp is several moves, each at its own
; speed; a move's first step comes six ticks after the last period of the
; move before has run out, while the next two words are fetched.
        .side_set 1
next:   pull                side 0     ; a move: direction, and steps less one
        out pins, 1         side 0     ; DIR
        out y, 15           side 0
        pull                side 0     ; the period, less four
step:   mov x, osr          side 1     ; STEP rises
        nop                 side 1     ; and is high for two ticks
low:    jmp x-- low         side 0     ; low for the rest of the period
        jmp y-- step        side 0
        push                side 0     ; the move is made
        jmp next            side 0
