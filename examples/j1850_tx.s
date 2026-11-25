; j1850_tx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; SAE J1850 VPW, the GM and Chrysler OBD-II bus, a transmitting node at
; 10.4 kbit/s: start of frame, the bytes as symbols that alternate between
; active and passive, each 64 or 128 us, the CRC-8 byte, end of data.
;
; Pins: P0 = the bus driver's input, push-pull, high = active. The bus
; idles passive (low); a transceiver turns this into the bus's 7 V. A
; passive symbol is a 0 when short and a 1 when long, an active one the
; other way round, so a byte (eight symbols, the first passive) always
; ends active. Config: [j1850_tx_config]: set_base 0, set_count 1;
; threshold 8; out most significant bit first; the CRC register at
; SAE J1850's 0x1D reversed ([j1850_crc_poly]) from 0xFF, read inverted.
; A thread tick is 1 us: CLKDIV 10 at 10 MHz, 50 at 50 MHz.
;
; Host protocol, for each frame:
;   TX : N, the number of bytes before the CRC (1 to 11), then the bytes,
;        one to a word in bits 15:8 ([j1850_words]): the header (priority,
;        target, source), the mode and the data.
;   RX : one word, 0, once the frame's last symbol has ended.
;
; Ticks are counted from the instruction that drives a symbol, tick 0.
; Start of frame: active for 200. Then each symbol runs to the next's
; tick 0, at 64 or 128. The end of each active symbol is spent on the
; bookkeeping, 35 ticks on every path: whether the byte has bits left,
; whether there is another byte, and fetching it. The CRC register
; follows every bit OUT shifts. After the last data byte it is read into
; the OSR, where its bits are in the reverse of the order they go out in,
; so the same 35 ticks turn them round: each goes through Y into the ISR,
; which shifts the other way, and back to the OSR. Then the CRC goes out
; like any byte. End of data: passive. The next frame's start comes 312
; us or more later, past the 300 of the interframe space; so does the
; first, after the thread starts.
;
; It sends only: it does not watch the bus for an idle one before it
; starts, or give way to a node that wins arbitration. A word the host
; is late with stretches the active symbol that ends a byte.
        set pins, 0             ; passive
        jmp quiet               ; and quiet for as long as between frames
next:   pull                    ; N
        mov isr, osr            ; bytes after this one, the CRC counted
        pull                    ; the first byte
        mov crc, null           ; the CRC from 0xFF
        set pins, 1             ; 0: start of frame, active
        set x, 23               ; 1
sof:    jmp x-- sof [7]         ; 2..193
        nop [5]                 ; 194..199
pas:    set pins, 0             ; 0: a passive symbol
        out y, 1                ; 1: its bit; the CRC takes it
        jmp !y p0               ; 2
        set x, 14               ; 3: a 1 is long, 64 ticks more
p1:     jmp x-- p1 [3]          ; 4..63
        nop [2]                 ; 64..66
p0:     set x, 14               ; 3
pw:     jmp x-- pw [3]          ; 4..63
act:    set pins, 1             ; 0: an active symbol
        out y, 1                ; 1
        jmp !y a0               ; 2
a1:     set x, 5                ; 3: a 1 is short
aw:     jmp x-- aw [3]          ; 4..27
        nop                     ; 28
        jmp !osre bits          ; 29: the 35 ticks before the next symbol
        mov x, isr              ; 30
        jmp x-- byte            ; 31
        nop [15]                ; 32..47: the CRC has gone
        nop [15]                ; 48..63
        set pins, 0             ; 0: end of data, passive
        push                    ; 1: the frame is sent
quiet:  set x, 18               ; 2
ifs:    jmp x-- ifs [15]        ; 3..306
        jmp next                ; 307: the next start of frame at 312
byte:   mov isr, x              ; 32
        jmp !x crc8             ; 33: the CRC is next
        pull                    ; 34: the next byte
        nop [15]                ; 35..50
        nop [11]                ; 51..62
        jmp pas                 ; 63
crc8:   mov osr, crc            ; 34: inverted; the CRC stops
        out null, 8             ; 35: the top half, all ones
        set x, 7                ; 36
rev:    out y, 1                ; 37..60: eight bits from the OSR's top,
        in y, 1                 ;   each into the ISR's top
        jmp x-- rev
        mov osr, isr            ; 61: the CRC, first bit topmost
        mov isr, null           ; 62: no byte after it
        jmp pas                 ; 63
bits:   nop [15]                ; 30..45
        nop [15]                ; 46..61
        jmp pas [1]             ; 62..63
a0:     set x, 14               ; 3: a 0 is long, 64 ticks more
al:     jmp x-- al [3]          ; 4..63
        jmp a1 [2]              ; 64..66
