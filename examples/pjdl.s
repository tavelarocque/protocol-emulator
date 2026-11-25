; pjdl: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; A PJON node sending packets over PJDL (Padded Jittering Data Link), the
; one-wire link of the PJON protocol, in one of PJDL's four modes. The
; line idles low. A packet is a frame initializer, three synchronization
; pads (a pad bit high, then a data bit low), then its bytes, each a
; synchronization pad and eight data bits, least significant first. Every
; time is exact to the tick: the pad bit 116, 92, 88 or 60 us and the data
; bit 44, 40, 28 or 26 us in modes 1 to 4 ([pjdl_timing]). test/pjdl.hex
; is mode 4.
;
; The PJON packet: receiver ID, header configuration, length, the meta CRC
; (a CRC8 of the three bytes before it), then sender ID, port, packet ID
; and payload as the configuration has them, then the end CRC. The
; program puts in both CRCs, with PJON's CRC8 (polynomial 0x97, written
; low power first, from 0), which is the one PJON uses for packets of 15
; bytes or less; above that PJON asks for CRC32, which this program does
; not send. The CRC register follows each data bit as it goes out, and
; not the pads. After the meta CRC it starts again from 0, which is what
; it would hold anyway: a CRC from 0 with no final inversion, run over
; bytes and then their own CRC, comes back to 0. So the end CRC covers the
; whole packet, as PJON's does.
;
; The length byte is the host's, as CAN's DLC is: the program counts the
; bytes it sends by it. Before every packet the line is low for longer
; than a byte (a pad and ten data bits), the time PJDL asks a free line to
; have been quiet, and the time after which a receiver takes a frame to
; have ended. The program does not listen for a free line first, ask for
; or wait for an acknowledgement, or receive: its pin drives both levels,
; and PJDL's other nodes need the line released to a pull-down, which no
; pin mode of the chip does.
;
; Pins: P0 = the line, push-pull. Config: [pjdl_config]: set_base 0,
; set_count 1; out_base 0, out_count 1; threshold 8; crc_poly 0x97,
; crc_init 0; CLKDIV makes a tick 4 us (2 us in mode 4): 40 (20) at 10
; MHz, 200 (100) at 50 MHz.
;
; Host protocol: one TX word for each byte of the packet except the two
; CRCs, in order: receiver ID, header configuration, length (the whole
; packet's, CRCs included, 5 to 15), and the rest. Each byte must be in
; the FIFO by the time its pad begins. RX: one word for each packet when
; it has gone out, its end CRC.
start:  set pins, 0             ; the line low: idle
idle:   set y, 9
gap:    jmp y-- gap [15]        ; for longer than a byte before a packet
        pull                    ; the receiver ID: a packet begins
        mov crc, null           ; the CRC register from 0
        set y, 2
init:   set pins, 1 [15]        ; the frame initializer: three pads
        nop [13]
        set pins, 0 [11]        ; each with its low data bit
        jmp y-- init
        set pins, 1             ; tick 0 of a byte: its pad begins
        set y, 2                ; three bytes before the meta CRC
        jmp first
hdr:    pull
first:  mov x, osr              ; tick 3; the last of them is the length
        nop [15]
        nop [9]
        set pins, 0 [12]        ; the sync pad's low data bit
hbit:   out pins, 1 [11]        ; a data bit
        jmp !osre hbit
        set pins, 1             ; tick 0 of the next pad
        jmp y-- hdr
        mov osr, crc            ; tick 2: the meta CRC; the register stops
        jmp x-- m1              ; X: the length less 5, the bytes
m1:     jmp x-- m2              ; still to come from the host
m2:     jmp x-- m3
m3:     jmp x-- m4
m4:     jmp x-- m5
m5:
        nop [15]
        nop [5]
        set pins, 0 [12]
mbit:   out pins, 1 [11]
        jmp !osre mbit
        set pins, 1
        mov crc, null           ; tick 1: from 0 again, as it is over the bytes so far
pnext:  jmp !x end              ; tick 2: no more bytes from the host
        pull
        jmp x-- p1
p1:
        nop [15]
        nop [8]
        set pins, 0 [12]
pbit:   out pins, 1 [11]
        jmp !osre pbit
        set pins, 1
        jmp pnext
end:    mov osr, crc            ; tick 3: the end CRC
        mov x, osr
        in x, 8                 ; for the host too
        nop [15]
        nop [7]
        set pins, 0 [12]
ebit:   out pins, 1 [11]
        jmp !osre ebit
        set pins, 0             ; the line low again: the packet has gone
        push
        jmp idle
