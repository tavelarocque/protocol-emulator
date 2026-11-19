; pwm: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; PWM, and so RC servo pulses: a pin high for one count and low for
; another, over and over.
;
; Pins: P0, push-pull (side-set). Config: [pwm_config]: sideset_base 0,
; sideset_count 1; CLKDIV sets the tick.
;
; Host protocol: two TX words when the thread starts: H then L. The pin
; is then high for H + 2 ticks and low for L + 3, for as long as the thread
; runs ([pwm_words] does the sums). To change them the host stops the
; thread, which leaves the pin as it is, and starts it with two new
; words.
;
; A servo wants 1 to 2 ms high every 20 ms: with a tick of 1 us (CLKDIV
; 10 at 10 MHz), 1.5 ms is H = 1498 and L = 18497.
        .side_set 1
        pull             side 0
        mov isr, osr     side 0     ; the high count, kept in the ISR
        pull             side 0     ; the low count stays in the OSR
high:   mov x, isr       side 1
h:      jmp x-- h        side 1
        mov x, osr       side 0
l:      jmp x-- l        side 0
        jmp high         side 0
