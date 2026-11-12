; spi_fast: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; SPI controller at 2 cycles per bit, using side-set for SCK.
;
; Same pins, host protocol and RX format as [spi_controller], minus the
; half-period word: it always runs at full speed (core clock / 2, so
; 5 Mbit/s at 10 MHz). Config: sideset_base 0, sideset_count 1 (SCK);
; out_base 1, out_count 3; in_base 2; threshold 8.
;
; Each bit is two instructions: OUT puts MOSI out while side-set holds SCK
; low, then IN samples MISO while side-set raises SCK. The byte is unrolled
; so no loop instruction sits between bits.
;
; Timing limit: IN samples MISO one core clock after SCK falls, so the
; slave's clock-to-output time plus pad delays must be under one clock
; period (100 ns at 10 MHz). Slower slaves need [spi_controller]. For the
; same reason MISO must bypass the input synchroniser (SYNC_BYPASS), whose
; two-cycle delay would make every sample stale; that is safe here because
; MISO changes only after SCK falls, a full clock before it is sampled.
        .side_set 1
idle:   set x, 4            side 0 ; SCK low
        mov pins, x         side 0 ; CS_N high, MOSI low: deselected
        pull                side 0 ; first byte of a transfer
        mov pins, null      side 0 ; CS_N low: select
byte:
        out pins, 1         side 0 ; bit 7: MOSI while SCK is low
        in pins, 1          side 1 ; SCK high: both sides sample
        out pins, 1         side 0 ; bit 6: MOSI while SCK is low
        in pins, 1          side 1 ; SCK high: both sides sample
        out pins, 1         side 0 ; bit 5: MOSI while SCK is low
        in pins, 1          side 1 ; SCK high: both sides sample
        out pins, 1         side 0 ; bit 4: MOSI while SCK is low
        in pins, 1          side 1 ; SCK high: both sides sample
        out pins, 1         side 0 ; bit 3: MOSI while SCK is low
        in pins, 1          side 1 ; SCK high: both sides sample
        out pins, 1         side 0 ; bit 2: MOSI while SCK is low
        in pins, 1          side 1 ; SCK high: both sides sample
        out pins, 1         side 0 ; bit 1: MOSI while SCK is low
        in pins, 1          side 1 ; SCK high: both sides sample
        out pins, 1         side 0 ; bit 0: MOSI while SCK is low
        in pins, 1          side 1 ; SCK high: both sides sample
        push                side 0 ; byte received
        out x, 1            side 0 ; X = deselect flag (word bit 8)
        jmp !x next         side 0
        jmp idle            side 0
next:   pull                side 0 ; next byte; SCK stays low until it arrives
        jmp byte            side 0
