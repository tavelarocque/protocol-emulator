; cjtag: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; Compact JTAG (IEEE 1149.7) as the debug probe: two pins, TCKC and TMSC,
; in the OScan1 format. The chip brings a TAP.7 online with escape
; sequences and the online activation code, then runs JTAG scans the way
; [jtag] does, each JTAG clock as an OScan1 packet of three TCKC clocks on
; the one data line: the inverse of TDI, then TMS, both from the chip, then
; TDO from the target.
;
; An escape is TMSC toggled while TCKC is high: eight edges reset the
; TAP.7, six select it. The activation is OpenOCD's for its cJTAG
; adapters: the reset escape, three clocks, the selection escape and
; twelve bits, the online activation code for OScan1 (0, 0, 1, 1, first
; bit first), the extension code (0, 0, 0, 1) and the check packet (0, 0,
; 0, 0). J-Link's short activation sends the same twelve bits.
;
; TMSC changes only while TCKC is low, a tick after it fell: never in a
; tick where TCKC moves, except at the start of the TDO bit, where the
; chip lets go of TMSC as TCKC falls and the target takes it over, as the
; standard has the two sides change over at that edge.
;
; Pins: P0 = TCKC (side-set, push-pull); P1 = TMSC (open-drain, with a
; pull-up: a 1 releases it, which is how the target gets the line for
; TDO). Config: [cjtag_config]: sideset_base 0, sideset_count 1; set_base
; 1, set_count 1; out_base 1, out_count 1; in_base 1; threshold 16.
;
; Host protocol:
;   TX word 0x8000 : bring the target online in OScan1 (no RX word).
;   TX word N - 1  : a scan of N JTAG clocks (1 to 32768), then ceil(N /
;                    8) words of (TDI, TMS) pairs, LSB first: bits 2k and
;                    2k + 1 are TDI and TMS for the k-th clock of the
;                    word ([cjtag_words] builds them).
;   RX             : ceil(N / 8) words of TDO, one bit per clock, LSB
;                    first, as [jtag] returns them.
;
; Timing: an OScan1 packet is 13 ticks, TCKC high for one tick in each of
; its three clocks: 770 kHz of JTAG clocks (2.3 MHz TCKC) at 10 MHz with
; CLKDIV 1, five times that at 50 MHz. TDO is sampled three ticks after
; TCKC falls, just before it rises; it passes the input synchroniser, so
; the target must drive it within one core clock of TCKC falling at
; CLKDIV 1 (CLKDIV 2 gives it three).
        .side_set 1
next:   pull                side 0     ; a command
        out x, 15           side 0     ; clocks - 1
        out y, 1            side 0     ; bit 15: bring the target online
        jmp !y word         side 0
        set pins, 0         side 0     ; TMSC low while TCKC is low
        set y, 3            side 1     ; TCKC rises
reset:  set pins, 1         side 1     ; reset escape: eight edges while TCKC is high
        set pins, 0         side 1
        jmp y-- reset       side 1
        set y, 2            side 0     ; TCKC falls
pad:    nop                 side 1     ; three clocks with TMSC low
        jmp y-- pad         side 0
        set y, 2            side 1     ; TCKC rises
select: set pins, 1         side 1     ; selection escape: six edges
        set pins, 0         side 1
        jmp y-- select      side 1
        set y, 1            side 0     ; TCKC falls
oac0:   nop                 side 1     ; OAC bits 0 and 1: 0
        jmp y-- oac0        side 0
        set pins, 1         side 0
        set y, 1            side 0
oac1:   nop                 side 1     ; OAC bits 2 and 3: 1
        jmp y-- oac1        side 0
        set pins, 0         side 0
        set y, 2            side 0
ec0:    nop                 side 1     ; EC bits 0 to 2: 0
        jmp y-- ec0         side 0
        set pins, 1         side 0
        nop                 side 1     ; EC bit 3: 1
        nop                 side 0
        set pins, 0         side 0
        set y, 3            side 0
cp:     nop                 side 1     ; the check packet: four 0s
        jmp y-- cp          side 0
        set pins, 1         side 0     ; TMSC released: online, in OScan1
        jmp next            side 0
word:   pull                side 0     ; up to 8 clocks of (TDI, TMS)
bit:    out y, 1            side 0     ; TDI
        jmp !y tdi0         side 0
        set pins, 0         side 0     ; nTDI: TMSC low for a 1
        jmp ntdi            side 1     ; TCKC rises: the target takes it
tdi0:   set pins, 1         side 0     ; and high for a 0
        nop                 side 1
ntdi:   nop                 side 0     ; TCKC falls
        out pins, 1         side 0     ; TMS
        nop                 side 1     ; TCKC rises: the target takes it
        set pins, 1         side 0     ; TCKC falls, TMSC released: the target drives TDO
        nop                 side 0 [1] ; through the input synchroniser
        in pins, 1          side 1     ; TCKC rises: TDO sampled just before
        jmp x-- more        side 0     ; TCKC falls: the target lets go
        push                side 0     ; the scan is done: its last TDO bits
        jmp next            side 0
more:   jmp !osre bit       side 0
        push                side 0     ; 8 TDO bits
        jmp word            side 0
