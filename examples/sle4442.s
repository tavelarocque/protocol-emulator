; sle4442: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; SLE 4442 memory card reader (the Siemens / Infineon "SLE 4432/4442"
; protected memory cards, and others with the same 3-wire protocol). The
; program is the card reader's side of it: the reset and the card's
; answer to it, a command with its START and STOP conditions, and the
; card's output clocked in, with the extra clock that ends it.
;
; The card's rules: I/O changes only on a falling edge of CLK (from the
; card) or while CLK is low (from the reader), except for START (I/O
; falling while CLK is high) and STOP (I/O rising while CLK is high). A
; reset is RST high with one clock pulse during it; when RST falls the
; card puts the first bit of its answer on I/O, and 31 more clocks give
; the rest of 32 bits; the 33rd releases I/O. A command is START, three
; bytes (control, address, data), each least significant bit first,
; taken as CLK rises, then a 25th clock during which STOP comes. A read
; command's output then starts on the next falling edge, one bit per
; clock, and one clock after the last bit releases I/O.
;
; Pins: P0 = RST, P1 = CLK, push-pull; P2 = I/O, open-drain (the card's
; output is open-drain too, so the line needs its pull-up). Config:
; [sle4442_config]: sideset_base 1, sideset_count 1; set_base 0,
; set_count 3 (RST, CLK under side-set, I/O); out_base 2, out_count 1;
; in_base 2; threshold 16; CLKDIV makes a tick 5 us (50 at 10 MHz, 250 at
; 50 MHz). CLK is then 40 kHz (25 us a clock, 15 low and 10 high; longer
; between bytes), inside the card's 7 to 50 kHz and its 9 us minimum
; high and low; I/O changes 5 us after CLK falls and 10 us before it
; rises; RST is high for 30 us.
;
; Host protocol, one operation at a time ([sle4442_words]):
;   TX word 0 : [8:0] the number of bytes to clock in at the end (0 to
;               511), [9] reset first, [10] a command first
;   TX word 1 : (a command) control byte in bits 7:0, address in 15:8
;   TX word 2 : (a command) data byte in bits 15:8, and bit 0 set
;   RX        : one word per byte clocked in, the byte in bits 7:0
; After the bytes comes one more clock, as the card asks to end its
; output. The answer to reset is 4 bytes; Read Main Memory (0x30) from
; address N is 256 - N.
;
; A command starts only when both its words are in hand. Then the program
; waits for no one but the RX FIFO: if the host lets it fill, CLK stays
; low until there is room.
        .side_set 1
        set pins, 4         side 0      ; RST low, I/O released
next:   pull                side 0      ; bytes, reset, command
        out y, 9            side 0
        out x, 1            side 0
        jmp !x nr           side 0
        set pins, 5         side 0 [1]  ; RST high, 10 us before CLK rises
        nop                 side 1 [1]  ; a clock pulse while RST is high
        nop                 side 0 [1]
        set pins, 4         side 0 [1]  ; RST low: the answer's first bit is on I/O
nr:     out x, 1            side 0
        jmp !x data         side 0
        pull                side 0      ; control and address
        mov isr, osr        side 0
        pull                side 0      ; data, then bit 0 set
        mov x, osr          side 0
        mov osr, isr        side 0
        nop                 side 1 [1]  ; CLK high, I/O released
        set pins, 0         side 1 [1]  ; I/O falls while CLK is high: START
cbit:   nop                 side 0      ; CLK falls; I/O held a tick
        out pins, 1         side 0 [1]  ; the next bit
        jmp !osre cbit      side 1 [1]  ; the card takes it as CLK rises
        jmp !x stop         side 1      ; both words sent?
        mov osr, x          side 1      ; no: the data byte, as the last 8
        out null, 8         side 1      ;   bits of the OSR
        set x, 0            side 1
        jmp cbit            side 1
stop:   nop                 side 0      ; CLK falls
        set pins, 0         side 0 [1]  ; I/O low
        nop                 side 1 [1]  ; the 25th clock
        set pins, 4         side 1 [1]  ; I/O rises while CLK is high: STOP
data:   jmp y-- byte        side 0      ; Y bytes from the card,
        nop                 side 0 [2]  ;   then one more clock
        nop                 side 1 [1]
        jmp next            side 0
byte:   set x, 7            side 0
bit:    nop                 side 0 [2]  ; CLK low 15 us: the card's next bit
        in pins, 1          side 1      ; read as CLK rises
        jmp x-- bit         side 1
        push                side 0
        jmp data            side 0
