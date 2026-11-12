; onewire: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; 1-Wire (Maxim/Analog Devices; DS18B20 temperature sensors, iButtons):
; the bus engine, at standard speed. A protocol this chip was not designed
; for: it was added as firmware alone, on the finished hardware.
;
; One wire, open-drain with a pull-up, carries everything. Every exchange
; starts with the host pulling the line low: a reset pulse (480 us or more,
; answered by every device's presence pulse) or a time slot (about 70 us).
; In a slot the host writes a 1 by releasing the line within 15 us, a 0 by
; holding it low for 60 us; it reads by writing a 1 and sampling the line
; 15 us after the slot began, while a device sending a 0 holds it low.
; Writes and reads are therefore one operation, and the engine does only
; that: reset pulses, and runs of 1 to 8 slots, each slot both writing a
; bit and sampling the line. ROM commands, the search algorithm and CRC8
; are the host's (OneWire in host/protocol_emulator.py), the same split as
; the SWD engine.
;
; Timing is in ticks of 1 us: the host sets CLKDIV to the core clock in
; MHz (10 at 10 MHz). The delays follow Maxim's application note 126:
;   reset : low 482 us; sample presence 70 us after release; then 413 us
;           of recovery before the next exchange can start
;   slot  : low 6 us; a 0 stays low to 65 us; sample at 15 us; release;
;           recover 11 us. 76 us a slot
; Pins: P0 = DQ (open-drain, pull-up required). Config: [onewire_config]:
; set_base 0 and out_base 0, count 1; in_base 0; threshold 16; CLKDIV.
;
; Host protocol, one TX word per exchange:
;   [0]     1 = a reset pulse; RX: 1 word, bit 0 = the line at the
;           presence sample (0: a device answered)
;   [3:1]   otherwise N - 1, for N slots (1 to 8)
;   [11:4]  the bits to write, first slot in bit 4 (1-Wire sends least
;           significant bit first). RX: 1 word, bit k = the line sampled
;           in slot k
next:   pull                    ; [0] reset, [3:1] slots - 1, [11:4] bits
        out x, 1
        jmp !x slots
        set pins, 0             ; reset pulse: low 482 us
        set y, 29
rlow:   jmp y-- rlow [15]       ; 30 x 16 us
        set pins, 1             ; release
        set y, 3 [2]
rwait:  jmp y-- rwait [15]      ; 4 x 16 us
        nop [2]
        in pins, 1              ; 70 us after release: presence
        set y, 24
rrec:   jmp y-- rrec [15]       ; 25 x 16 us
        push [9]
        jmp next
slots:  out x, 3                ; X = slots - 1
slot:   set pins, 0 [5]         ; the slot begins: low 6 us
        out pins, 1 [8]         ; a 1 releases the line, a 0 keeps it low
        in pins, 1              ; 15 us into the slot: sample
        set y, 2
swait:  jmp y-- swait [15]      ; 3 x 16 us
        set pins, 1 [9]         ; release (65 us into the slot), recover
        jmp x-- slot
        push
        jmp next
