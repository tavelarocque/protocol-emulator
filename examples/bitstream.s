; bitstream: generated from model/firmware.ml by bin/firmware_src.ml.
; Assemble or run it with pe_sim (bin/pe_sim.ml). Names in [brackets]
; are definitions in model/firmware.ml.
;
; A stream of levels at an exact rate: each bit of each TX word is the
; level of one pin for one cell. The codes that are a line switched at a
; fixed rate are all made with it; which cells make a frame is the host's
; business. Qi packets ([qi_cells]), EM4100 tags ([em4100_cells]) and
; Morse code ([morse_cells]) are sent with it.
;
; Pins: P0 = the line, push-pull, low until the first word. Config:
; [bitstream_config]: threshold 16, autopull, out most significant bit
; first; a cell is two ticks, so CLKDIV is the clock over twice the cell
; rate.
;
; Host protocol: TX words, 16 cells each, the first cell in bit 15. A word
; is fetched as the last cell of the one before leaves, with no gap, as
; long as it is in the FIFO by then; if it is not, the line holds its
; level until a word comes. So a frame ends on the level the line should
; rest at, and the host has 16 cells to supply each word.
        set pins, 0             ; the line starts low
cell:   out pins, 1             ; a cell; the last of a word fetches the next
        jmp cell
