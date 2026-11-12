; jtag: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; JTAG controller (IEEE 1149.1): drives TCK, TMS and TDI and samples TDO,
; for any sequence of clocks the host asks for, so the host walks the TAP
; state machine, shifts instructions and reads or writes data registers.
;
; Pins: P0 = TCK (side-set), P1 = TMS, P2 = TDI (push-pull); P3 = TDO
; (input). Config: [jtag_config]: sideset_base 0, sideset_count 1;
; out_base 1, out_count 2; in_base 3; threshold 16.
;
; Host protocol, one scan at a time:
;   TX word 0 : N - 1, for a scan of N clocks (1 to 65536)
;   then      : ceil(N / 8) words of (TMS, TDI) pairs, LSB first: bits
;               2k and 2k + 1 are TMS and TDI for the k-th clock of the
;               word ([jtag_words] builds them)
;   RX        : ceil(N / 8) words of TDO, one bit per clock, LSB first,
;               the last word right-justified when N is not a multiple of 8.
; TDO is sampled just before TCK rises, which is when the device holds it
; steady (it changes on the falling edge). TMS and TDI change while TCK is
; low.
;
; Timing: TCK is high for 2 ticks and low for 3 (more at word boundaries),
; so it runs at core clock / 5 at CLKDIV 1: 2 MHz at 10 MHz. TDO must
; settle within one core clock of TCK falling at CLKDIV 1 (the input
; synchroniser takes the rest); CLKDIV 2 gives it four.
        .side_set 1
next:   pull                side 0     ; X <- clocks - 1
        out x, 16           side 0
word:   pull                side 0     ; up to 8 clocks of (TMS, TDI)
bit:    out pins, 2         side 0     ; TMS and TDI while TCK is low
        in pins, 1          side 1 [1] ; TCK high: the device samples TMS and TDI
        jmp x-- more        side 0     ; TCK falls: the device moves TDO
        push                side 0     ; the scan is done: its last TDO bits
        jmp next            side 0
more:   jmp !osre bit       side 0
        push                side 0     ; 8 TDO bits
        jmp word            side 0
