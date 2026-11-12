; ps2_rx: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; PS/2 (IBM keyboards and mice): the host side, on both threads. Like
; 1-Wire, a protocol this chip was not designed for, added as firmware alone
; on the finished hardware.
;
; Two open-drain lines with pull-ups, DATA and CLK. The device makes every
; clock pulse, at 10 to 16.7 kHz, in both directions. A frame is 11 bits:
; start (0), 8 data bits least significant first, odd parity, stop (1).
;   device to host : the device changes DATA while CLK is high; the host
;                    reads it when CLK falls
;   host to device : the host holds CLK low for at least 100 us, pulls DATA
;                    low (the start bit) and releases CLK. The device then
;                    clocks: the host changes DATA while CLK is low, the
;                    device reads it when CLK rises. After the stop bit the
;                    device pulls DATA low for one more clock, the ACK
; Pins: P0 = DATA, P1 = CLK, both open-drain; P2 push-pull, internal (see
; below). CLKDIV on both threads is the
; core clock in MHz, so a tick is 1 us, as for [onewire].
;
; The receiver, [ps2_rx], runs on thread 0 and never stops listening: it
; takes DATA at each falling edge of CLK and pushes 11 bits as one word,
;   bit 0 start, bits 8:1 the byte, bit 9 parity, bit 10 stop.
; Every wait inside a frame has a timeout (TIMEOUT = 150 ticks; a clock
; phase is 50 us at most), which jumps to [ps2_rx_abandon]: a frame the
; device gave up, or the host's own 100 us of CLK low, is dropped, never
; pushed short.
;
; The transmitter, [ps2_tx], runs on thread 1. One TX word a byte:
;   bits 7:0 the byte, bit 8 its odd parity, bit 9 a 1 (the stop bit, which
;   releases DATA): [ps2_tx_word]; threshold 10.
; and one RX word back: 0 = the device acknowledged, 1 = it did not,
; 3 = it never clocked (TIMEOUT, 20 ms; both lines released).
;
; The threads coordinate through a pin. A device counts its frame as sent
; once CLK has fallen for the 11th bit, and re-sends it if the host
; inhibits any earlier; so an inhibit that lands late in a frame, after
; the receiver has its 11 bits but before the device is done, would
; deliver a byte twice. The receiver therefore holds P2 (push-pull, by
; side-set, wired to nothing) low from a frame's first falling edge until
; it has pushed or abandoned it, and the transmitter waits for P2 to be
; high before it inhibits. A thread reads another's output with no delay,
; so the inhibit can land no later than a frame's second microsecond,
; where the device simply starts again.
;
; The receiver abandons the frame the
; inhibit looked like, then hears the device clock the host's byte and
; pushes that too, with the ACK where the stop bit would be: so the host
; reads back what was on the wire. For that the transmitter changes DATA
; 3 us after CLK falls, after the receiver's sample (1 or 2 us after).
        .side_set 1
idle:   wait 1 pin 1            side 1 ; CLK high: the bus is free, or a frame is over
        wait 0 pin 1            side 1 ; CLK falls: a frame begins
        jmp samp                side 0 ; P2 low from here: a frame is under way
next:   wait 1 pin 1 timeout    side 0 ; the rest of the clock pulse...
        wait 0 pin 1 timeout    side 0 ; ...and the next falling edge, or give up
samp:   in pins, 1              side 0 ; DATA at the falling edge
        jmp !isrf next          side 0
        push                    side 0 ; 11 bits
        jmp idle                side 1
gone:   mov isr, null           side 1 ; timeout vector: drop what was shifted in
        jmp idle                side 1
