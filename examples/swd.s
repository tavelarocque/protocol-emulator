; swd: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; SWD (Arm Serial Wire Debug) clock engine: drives SWCLK and SWDIO and
; samples SWDIO, one bit per clock, for any number of clocks. The SWD
; protocol itself (line reset, the JTAG-to-SWD switch, request packets,
; parity, ACK, turnaround) is built by the host from these clocks, the way
; a CMSIS-DAP probe or the RP2040's PIO-based probe splits the work: the
; chip owns the timing, the host owns the framing. [host/protocol_emulator.py]
; has the framing (SwdController).
;
; SWDIO is one wire driven by both sides in turn, so it is open-drain with
; a pull-up: a 1 releases it, which is also how the host lets the target
; drive during turnaround, ACK and read data.
;
; Pins: P0 = SWCLK (side-set, push-pull), P1 = SWDIO (open-drain, pull-up
; required). Config: [swd_config]: sideset_base 0, sideset_count 1;
; out_base 1, out_count 1; in_base 1; threshold 16.
;
; Host protocol, per batch of clocks:
;   TX word 0 : N - 1, for N clocks (1 to 65536)
;   then      : ceil(N / 16) words, bit k = the SWDIO level for the k-th
;               clock of the word (1 = released)
;   RX        : ceil(N / 16) words, bit k = SWDIO sampled just before the
;               k-th clock's rising edge (the target drives after a rising
;               edge and samples on one; so does this).
; SWCLK is high 2 ticks and low 3 (more at word boundaries): 2 MHz at
; 10 MHz with CLKDIV 1.
        .side_set 1
next:   pull                side 0     ; X <- clocks - 1
        out x, 16           side 0
word:   pull                side 0     ; up to 16 clocks of SWDIO bits
bit:    out pins, 1         side 0     ; SWDIO (1 = released) while SWCLK is low
        in pins, 1          side 1 [1] ; SWCLK rises: sample SWDIO just before
        jmp x-- more        side 0     ; SWCLK falls
        push                side 0     ; the batch is done: its last bits
        jmp next            side 0
more:   jmp !osre bit       side 0
        push                side 0     ; 16 sampled bits
        jmp word            side 0
