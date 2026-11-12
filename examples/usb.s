; usb: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; Low-speed USB engine (1.5 Mbit/s, so a 12 MHz core clock: 8 clocks per
; bit). It runs commands from its TX FIFO: send a packet, or receive one.
; Everything above the wire (SYNC, PID, CRC5, CRC16, bit stuffing, NRZI)
; is the host's ([Usb_model], and UsbHost in the board driver), the split
; RP2040 PIO-USB uses too; the engine owns the bit timing, EOP, the bus
; turnaround and clock recovery, which the host is far too slow for.
;
; The chip cannot release a push-pull pin by itself (pin modes are the
; host's), so it drives the bus through a standard USB 1.1 transceiver in
; its VO/FSE0 mode, as FPGA and microcontroller USB cores do: VO is the
; differential data (1 = D+ high = K at low speed), FSE0 forces SE0, OE_N
; enables the drivers, and VP / VM are the transceiver's single-ended
; receivers (D+ and D-).
;
; Pins: P0 = VP, P1 = VM (inputs, through the synchroniser); P2 = VO,
; P3 = FSE0, P4 = OE_N (push-pull; FSE0 and OE_N by side-set, value bit 0
; is FSE0). Config: [usb_config].
;
; Commands (TX FIFO):
;   send    : N - 1 (bit 15 clear), for N line states (the packet without
;             its EOP), then ceil(N / 16) words, bit k = VO for the k-th
;             bit time ([usb_send_words]). The engine waits until the bus
;             has been idle for at least two bit times, sends the packet at
;             exactly 8 clocks per bit, word boundaries included, adds EOP
;             (two bit times of SE0, one of J) and releases the bus.
;   receive : [usb_receive] (bit 15 set). The engine waits for a packet
;             (the first K of SYNC), records the line level of every bit
;             (1 = K) until EOP, and pushes them 16 to a word, first in
;             bit 0, the last word ending with a single 1 after the last
;             bit ([usb_levels] reads them back). It waits as long as it
;             takes: a host that gets no answer stops and restarts the
;             thread.
;
; Receive timing: in each bit the engine waits for the edge that would
; leave the current level (VP falling on K, VM falling on J) with a timed
; wait of TIMEOUT = 2. An edge re-aligns it: two clocks after the edge is
; seen it samples both pins, so SE0 (EOP) is told from the new level. No
; edge: the timeout vector samples again one bit time on. Every sample is
; two to three clocks after the latest edge the synchroniser shows, which
; keeps it inside the bit whatever the sender's clock does between edges
; (bit stuffing guarantees one at least every seven bits).
;
; Turnaround: before sending, the bus is idle for 37 clocks after one of
; the engine's own packets and about 23 after a received one: 2 to 7.5 bit
; times, as USB 1.1 requires (7.1.18).
        .side_set 2
next:   pull                side 2     ; a command; bus released
        out x, 15           side 2     ; X <- line states - 1
        out y, 1            side 2     ; bit 15: receive
        jmp !y send         side 2
        set y, 2            side 2     ; receive. Y = J, as {VM, VP}
        wait 1 pin 0        side 2     ; until the first K of SYNC
        jmp tok             side 2
tok:    mov osr, pins       side 2     ; the line went K (or SE0):
        out x, 2            side 2     ; X <- {VM, VP}: K 1, J 2, SE0 0
        jmp !x eop          side 2
        in x, 1             side 2     ; record VP
        jmp !isrf kw        side 2
        push                side 2
kw:     wait 0 pin 0 timeout side 2    ; on K, until VP falls
        jmp toj             side 2
toj:    mov osr, pins       side 2     ; the line went J (or SE0)
        out x, 2            side 2
        jmp !x eop          side 2
        in x, 1             side 2
        jmp !isrf jw        side 2
        push                side 2
        jmp jw              side 2
tmo:    mov osr, pins       side 2     ; timeout vector: no edge for a bit,
        out x, 2            side 2     ; the same level again
        in x, 1             side 2
        jmp !isrf same      side 2
        push                side 2
same:   jmp x!=y kw         side 2     ; still K; still J falls through, so
jw:     wait 0 pin 1 timeout side 2    ; both reach their wait in the same
        jmp tok             side 2     ; clocks. On J, until VM falls
eop:    set x, 1            side 2
        in x, 1             side 2     ; a 1 after the last bit marks the end
        push                side 2
        jmp next            side 2
send:   set y, 9            side 2     ; bus idle first: two bit times at
idle:   jmp y-- idle        side 2 [2] ; least after a received packet's EOP
        pull                side 2     ; the first 16 line states
        jmp bit             side 2
more:   jmp !osre pad       side 0
        pull                side 0 [1] ; word boundary, in the same 8 clocks
bit:    out pins, 1         side 0 [3] ; VO for this bit time, drivers on
        jmp x-- more        side 0
        nop                 side 0 [2] ; the last bit's 8 clocks
        set x, 4            side 1     ; EOP: SE0 for two bit times,
se0:    jmp x-- se0         side 1 [2]
        set pins, 0         side 0 [3] ; then J (VO = 0) for one,
        nop                 side 0 [3]
        jmp next            side 2     ; then release the bus
pad:    jmp bit             side 0 [1]
