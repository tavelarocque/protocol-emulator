#!/usr/bin/env python3
# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
"""The memories the tests and proofs use are the memories IHP describes.

The chip's program memories and its packet buffer are IHP's SRAM macros. The OCaml tests and the
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
BEHAVIOURAL = "RM_IHPSG13_1P_core_behavioral_bm_bist.v"
# Each memory on the chip: what memory_verilog.exe is asked for, its size,
# what the description's registers are called, and its macro instance.
MEMORIES = [
    ("a program memory", [], 256, "t0_prog", "sram0"),
    ("the packet buffer", ["buffer"], 1024, "buf", "sram_buf"),
]


def script(model, macro, words, prefix, instance):
    ihp = [f"RM_IHPSG13_1P_{words}x16_c2_bm_bist.v", BEHAVIOURAL]
    core = instance + ".i_SRAM_1P_behavioral_bm_bist"  # IHP's storage, inside the macro
    # Pair the two by name: each flip-flop of the description takes the name
    # of the IHP storage element it stands for. Hardcaml's generated wire
    # names (_123) mean nothing and would pair by accident, so hide them.
    hide = "rename -hide w:_* w:vdd w:gnd"
    # pmuxtree: the description reads through one wide parallel multiplexer,
    # which the solver would walk a word at a time, 1024 deep, and run out of
    # stack. As a tree it is ten deep.
    lines = [f"read_verilog {model}", "hierarchy -top memory_model", "proc", "pmuxtree",
             "opt_clean", "cd memory_model", hide]
    lines += [f"rename {prefix}_{n} \\{core}.memory[{n}]" for n in range(words)]
    lines += [f"rename {prefix}_dout \\{core}.dr_r", "cd ..", "design -stash gold",
              f"read_verilog -DFUNCTIONAL {macro} {' '.join(ihp)}",
              "hierarchy -top memory_macro", "proc", "flatten", "memory_map", "opt_clean",
              "cd memory_macro", hide, "cd ..", "design -stash gate",
              "design -copy-from gold -as gold memory_model",
              "design -copy-from gate -as gate memory_macro",
              "equiv_make gold gate equiv", "hierarchy -top equiv",
              "equiv_simple", "equiv_induct", "equiv_status -assert"]
    return "\n".join(lines) + "\n"


def prove(yosys, model, macro, work, name, memory):
    ys = os.path.join(work, name + ".ys")
    with open(ys, "w") as f:
        f.write(script(model, macro, *memory))
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
    for f in os.listdir(os.path.join(ROOT, "test", "sram_model")):
        if f.endswith(".v"):
            shutil.copy(os.path.join(ROOT, "test", "sram_model", f), work)
    for what, extra, words, prefix, instance in MEMORIES:
        memory = (words, prefix, instance)
        paths = {}
        for which in ("model", "macro"):
            paths[which] = f"{prefix}_{which}.v"
            with open(os.path.join(work, paths[which]), "w") as f:
                f.write(subprocess.run([args.tool, which] + extra, capture_output=True,
                                       text=True, check=True).stdout)
        ok, log = prove(args.yosys, paths["model"], paths["macro"], work, prefix + "_equal", memory)
        if not ok:
            print(log[-3000:])
            sys.exit(f"FAIL: the flip-flop description of {what} differs from IHP's model")
        print(f"proved, {what}: {words} words of 16 bits and the output register equal "
              "IHP's model")

        text = open(os.path.join(work, paths["model"])).read()
        planted, n = re.subn(r"= we \? " + prefix + r"_dout : (\w+);", r"= \1;", text)
        assert n == 1, "the description's output mux was not found"
        bad = prefix + "_planted.v"
        with open(os.path.join(work, bad), "w") as f:
            f.write(planted)
        ok, _ = prove(args.yosys, bad, paths["macro"], work, prefix + "_planted", memory)
        if ok:
            sys.exit(f"FAIL, {what}: a planted bug (output not held on a write) was not noticed")
        print(f"planted bug, {what} (output not held on a write): proof fails, as it must")


if __name__ == "__main__":
    main()
