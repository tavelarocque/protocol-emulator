; dht: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; AM2302 / DHT22 and DHT11 humidity and temperature sensors: one wire,
; the sensor answering a start pulse with 40 bits whose length is their
; value.
;
; Pins: P0 = the data line, open-drain, with the sensor's pull-up. Config:
; [dht_config]: threshold 16, autopush, in most significant bit first;
; timeout 60 and timeout_vector [dht_fail]; CLKDIV makes a tick 5 us: 50
; at 10 MHz.
;
; Host protocol:
;   TX : one word to take a reading: how long to hold the line low to
;        start, in units of 40 us, less one: 32 (1.3 ms) for an AM2302,
;        500 (20 ms) for a DHT11.
;   RX : four words: the humidity, the temperature, the checksum (8 bits),
;        and 0 if the sensor sent all 40 bits or 1 if it stopped
;        answering, with 0 for every bit after the one it stopped in.
;
; On the wire the sensor answers a released line with 80 us low and 80 us
; high, then sends each bit as 50 us low and a high of 26 us for a 0 or
; 70 us for a 1. The line is read 40 to 45 us after it rises: a 0 is over
; by then and a 1 is not. Any level that lasts 300 us ends the reading.
idle:   pull                    ; a reading: how long the start is
        mov x, osr
        set pins, 0             ; the start: the line held low,
low:    jmp x-- low [7]         ; 40 us at a time
        set pins, 1             ; and let go
        set y, 4                ; five bytes
        set x, 7                ; of eight bits
        wait 0 pin 0 timeout    ; the sensor's answer: low,
        wait 1 pin 0 timeout    ; and high
bit:    wait 0 pin 0 timeout    ; a bit begins: low,
        wait 1 pin 0 timeout    ; then high
        nop [6]
        in pins, 1              ; 40 to 45 us into the high
        jmp x-- bit
        set x, 7
        jmp y-- bit
        push                    ; the checksum: the last 8 bits
        in null, 16             ; all 40 read
        jmp idle
fail:   in null, 1              ; the sensor stopped: 0 for each bit not read,
        jmp x-- fail
        set x, 7
        jmp y-- fail
        push
        set x, 1
        in x, 16                ; and a 1 to say so
        jmp idle
