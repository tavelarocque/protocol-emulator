#!/usr/bin/env bash
# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# Bitstream of the whole chip for a Sipeed Tang Nano 20K: src/project.v and
# src/protocol_emulator.v unchanged, fpga/sram_fpga.v for the SRAM macros,
# fpga/tangnano20k/board.v for the pins. Needs Yosys, nextpnr-himbaechel and
# gowin_pack (the OSS CAD Suite has all three; .github/workflows/fpga.yaml
# pins a release).
#
#   fpga/build.sh            # clock from the Pico   -> fpga/build/pe_tangnano20k.fs
#   fpga/build.sh clk27      # the board's crystal   -> fpga/build/pe_tangnano20k_clk27.fs
#
# Load with: openFPGALoader -b tangnano20k fpga/build/pe_tangnano20k.fs
# (add -f to write it to the board's flash, so it survives a power cycle).
set -euo pipefail
cd "$(dirname "$0")/.."
out=fpga/build
mkdir -p "$out"
name=pe_tangnano20k
defs=""
if [ "${1:-}" = clk27 ]; then
  name=${name}_clk27
  defs="-DCLK27"
  # the crystal is on pin 4; every other pin as in pins.cst
  sed 's/^IO_LOC "clk" 77;.*/IO_LOC "clk27" 4;/; s/^IO_PORT "clk" /IO_PORT "clk27" /' \
    fpga/tangnano20k/pins.cst > "$out/pins_clk27.cst"
  cst=$out/pins_clk27.cst
else
  cst=fpga/tangnano20k/pins.cst
fi
SRC="src/project.v src/protocol_emulator.v fpga/sram_fpga.v fpga/tangnano20k/board.v"

yosys -l "$out/$name.synth.log" -q \
  -p "read_verilog $defs $SRC; synth_gowin -family gw2a -top pe_tangnano20k -json $out/$name.json"
# 27 MHz is the fastest the chip is asked to run on this board (its crystal);
# the Pico's clock is usually 10 MHz.
nextpnr-himbaechel -l "$out/$name.pnr.log" -q --json "$out/$name.json" --write "$out/$name.pnr.json" \
  --device GW2AR-LV18QN88C8/I7 --vopt family=GW2A-18C --vopt cst="$cst" --freq 27
gowin_pack -d GW2A-18C -o "$out/$name.fs" "$out/$name.pnr.json"

echo "== $name"
# The whole utilisation table (cells in use only), whatever its spacing.
sed -n '/Device utilisation/,/^Info: *$/p' "$out/$name.pnr.log" | grep -E "[0-9]+%" | grep -vE "[^0-9]0%$" || true
grep -E "Max frequency for clock" "$out/$name.pnr.log" | tail -1 || true
# Every pin of board.v must reach a pad: 20 of them (8 protocol pins,
# clock, reset, 4 host port pins, 6 status). A pin optimised away would
# still build, so count them.
iob=$(sed -n 's/^Info:[[:space:]]*IOB:[[:space:]]*\([0-9]*\)\/.*/\1/p' "$out/$name.pnr.log" | tail -1)
if [ "$iob" != 20 ]; then
  echo "FAIL: $iob pads in use, 20 expected" >&2
  exit 1
fi
