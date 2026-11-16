#!/usr/bin/env python3
# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
"""The program memory the proofs use is the memory IHP describes.

The chip's program memories are IHP's SRAM macro. The OCaml tests and the
formal proofs of the chip cannot contain the macro, so they build the same
circuit around a description of it in flip-flops ([Pe_core.Memory.Model]).
This proves, with Yosys, that the description and IHP's own behavioural
model of the macro (test/sram_model), tied off exactly as the chip ties it,
are the same machine: every word of storage and the output register take
the same next value, for every state and every input. Since they then
agree on every state bit after every clock, they agree for ever from any
common state.

Both sides are emitted by bin/memory_verilog.exe from the one function the
chip is built from, so the tie-offs proved here are the chip's.

It then plants a bug in the description (the output no longer holds on a
write cycle, which IHP's model says it does) and requires the proof to
fail.

What this does not show: that the silicon macro behaves as IHP's
behavioural model says.

Usage: sram_equiv.py [--yosys CMD] [--tool PATH/TO/memory_verilog.exe]
"""

import argparse
import os
import re
import subprocess
import sys
import shutil

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
IHP = ["RM_IHPSG13_1P_256x16_c2_bm_bist.v", "RM_IHPSG13_1P_core_behavioral_bm_bist.v"]
CORE = "sram0.i_SRAM_1P_behavioral_bm_bist"  # IHP's storage, inside the macro instance
WORDS = 256


def script(model, macro):
    # Pair the two by name: each flip-flop of the description takes the name
    # of the IHP storage element it stands for. Hardcaml's generated wire
    # names (_123) mean nothing and would pair by accident, so hide them.
    hide = "rename -hide w:_* w:vdd w:gnd"
    lines = [f"read_verilog {model}", "hierarchy -top memory_model", "proc", "opt_clean",
             "cd memory_model", hide]
    lines += [f"rename t0_prog_{n} \\{CORE}.memory[{n}]" for n in range(WORDS)]
    lines += [f"rename t0_prog_dout \\{CORE}.dr_r", "cd ..", "design -stash gold",
              f"read_verilog -DFUNCTIONAL {macro} {' '.join(IHP)}",
              "hierarchy -top memory_macro", "proc", "flatten", "memory_map", "opt_clean",
              "cd memory_macro", hide, "cd ..", "design -stash gate",
              "design -copy-from gold -as gold memory_model",
              "design -copy-from gate -as gate memory_macro",
              "equiv_make gold gate equiv", "hierarchy -top equiv",
              "equiv_simple", "equiv_induct", "equiv_status -assert"]
    return "\n".join(lines) + "\n"


def prove(yosys, model, macro, work, name):
    ys = os.path.join(work, name + ".ys")
    with open(ys, "w") as f:
        f.write(script(model, macro))
    # Run in the work directory with relative names: yowasp-yosys sees only
    # the directory it starts in.
    r = subprocess.run(yosys.split() + ["-q", "-s", os.path.basename(ys)], cwd=work,
                       capture_output=True, text=True)
    return r.returncode == 0, r.stdout + r.stderr


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--yosys", default="yowasp-yosys")
    ap.add_argument("--tool", default=os.path.join(ROOT, "_build", "default", "bin",
                                                   "memory_verilog.exe"))
    args = ap.parse_args()
    work = os.path.join(ROOT, "_build", "sram_equiv")
    shutil.rmtree(work, ignore_errors=True)
    os.makedirs(work)
    for f in IHP:
        shutil.copy(os.path.join(ROOT, "test", "sram_model", f), work)
    if True:
        paths = {}
        for which in ("model", "macro"):
            paths[which] = which + ".v"
            with open(os.path.join(work, paths[which]), "w") as f:
                f.write(subprocess.run([args.tool, which], capture_output=True, text=True,
                                       check=True).stdout)
        ok, log = prove(args.yosys, paths["model"], paths["macro"], work, "equal")
        if not ok:
            print(log[-3000:])
            sys.exit("FAIL: the flip-flop description differs from IHP's model")
        print(f"proved: {WORDS} words of 16 bits and the output register equal IHP's model")

        text = open(os.path.join(work, paths["model"])).read()
        planted, n = re.subn(r"= we \? t0_prog_dout : (\w+);", r"= \1;", text)
        assert n == 1, "the description's output mux was not found"
        bad = "planted.v"
        with open(os.path.join(work, bad), "w") as f:
            f.write(planted)
        ok, _ = prove(args.yosys, bad, paths["macro"], work, "planted")
        if ok:
            sys.exit("FAIL: a planted bug (output not held on a write) was not noticed")
        print("planted bug (output not held on a write): proof fails, as it must")


if __name__ == "__main__":
    main()
