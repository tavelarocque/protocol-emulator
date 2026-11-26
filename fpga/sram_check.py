#!/usr/bin/env python3
# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
"""The FPGA build's memories are IHP's SRAM macros, as the chip uses them.

fpga/sram_fpga.v stands in for the three SRAM macros on the FPGA. This
proves, with Yosys, that each of its two modules and IHP's behavioural
model of the same macro (test/sram_model) are the same machine when both
are tied off exactly as src/protocol_emulator.v ties the macro (A_MEN and
A_DLY high, A_BM all ones, BIST off): every word of storage and the output
register take the same next value, for every state and every input. It is
the method of formal/sram_equiv.py, which proves the same of the
flip-flop description the chip's proofs use.

It then plants a bug in the FPGA module (no write-through when a write and
a read come together, which IHP's model does) and requires the proof to
fail.

What this does not show: that the FPGA's block RAM behaves as Yosys's
model of the inferred memory says, or that the silicon macro behaves as
IHP's model says.

Usage: sram_check.py [--yosys CMD]
"""

import argparse
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
BEHAVIOURAL = "RM_IHPSG13_1P_core_behavioral_bm_bist.v"
MEMORIES = [(256, 8), (1024, 10)]  # words, address bits

WRAPPER = """
module memory_wrap (input clk, input wen, input ren, input [{a}:0] addr,
                    input [15:0] din, output [15:0] dout);
  RM_IHPSG13_1P_{n}x16_c2_bm_bist m (
    .A_CLK(clk), .A_MEN(1'b1), .A_WEN(wen), .A_REN(ren), .A_ADDR(addr),
    .A_DIN(din), .A_DLY(1'b1), .A_DOUT(dout), .A_BM(16'hffff),
    .A_BIST_CLK(1'b0), .A_BIST_EN(1'b0), .A_BIST_MEN(1'b0), .A_BIST_WEN(1'b0),
    .A_BIST_REN(1'b0), .A_BIST_ADDR({a1}'d0), .A_BIST_DIN(16'd0), .A_BIST_BM(16'd0));
endmodule
"""


def script(fpga, words, abits):
    core = "m.i_SRAM_1P_behavioral_bm_bist"  # IHP's storage, inside the macro
    lines = [f"read_verilog {fpga} wrap_{words}.v", "hierarchy -top memory_wrap", "proc",
             "flatten", "memory_map", "opt_clean", "cd memory_wrap"]
    # Pair the two sides by name: each word and the output register of the
    # FPGA module takes the name of the IHP storage element it stands for.
    lines += [f"rename m.mem[{k}] \\{core}.memory[{k}]" for k in range(words)]
    lines += [f"rename m.A_DOUT \\{core}.dr_r", "cd ..", "design -stash gold",
              f"read_verilog -DFUNCTIONAL RM_IHPSG13_1P_{words}x16_c2_bm_bist.v {BEHAVIOURAL} "
              f"wrap_{words}.v",
              "hierarchy -top memory_wrap", "proc", "flatten", "memory_map", "opt_clean",
              "design -stash gate",
              "design -copy-from gold -as gold memory_wrap",
              "design -copy-from gate -as gate memory_wrap",
              "equiv_make gold gate equiv", "hierarchy -top equiv",
              "equiv_simple", "equiv_induct", "equiv_status -assert"]
    return "\n".join(lines) + "\n"


def prove(yosys, work, fpga, words, abits, name):
    ys = os.path.join(work, name + ".ys")
    with open(ys, "w") as f:
        f.write(script(fpga, words, abits))
    r = subprocess.run(yosys.split() + ["-q", "-s", os.path.basename(ys)], cwd=work,
                       capture_output=True, text=True)
    return r.returncode == 0, r.stdout + r.stderr


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--yosys", default="yosys")
    args = ap.parse_args()
    work = os.path.join(ROOT, "_build", "fpga_sram_check")
    shutil.rmtree(work, ignore_errors=True)
    os.makedirs(work)
    for f in os.listdir(os.path.join(ROOT, "test", "sram_model")):
        if f.endswith(".v"):
            shutil.copy(os.path.join(ROOT, "test", "sram_model", f), work)
    text = open(os.path.join(HERE, "sram_fpga.v")).read()
    with open(os.path.join(work, "sram_fpga.v"), "w") as f:
        f.write(text)
    planted = text.replace("if (A_REN) A_DOUT <= A_DIN;", "")
    assert planted.count("A_DOUT <= A_DIN") == 0 and planted != text, "write-through not found"
    with open(os.path.join(work, "sram_planted.v"), "w") as f:
        f.write(planted)
    failed = False
    for words, abits in MEMORIES:
        with open(os.path.join(work, f"wrap_{words}.v"), "w") as f:
            f.write(WRAPPER.format(n=words, a=abits - 1, a1=abits))
        ok, log = prove(args.yosys, work, "sram_fpga.v", words, abits, f"equal_{words}")
        if not ok:
            print(log[-3000:])
            print(f"FAIL: the FPGA {words}-word memory differs from IHP's model")
            failed = True
            continue
        print(f"proved: the FPGA {words}-word memory and its output register equal IHP's model")
        ok, _ = prove(args.yosys, work, "sram_planted.v", words, abits, f"planted_{words}")
        if ok:
            print(f"FAIL: a planted bug in the {words}-word memory (no write-through) was not noticed")
            failed = True
        else:
            print(f"planted bug, {words} words (no write-through): proof fails, as it must")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
