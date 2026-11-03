#!/usr/bin/env python3
# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
"""Formal equivalence of the post-layout gate netlist and the RTL.

Two Yosys proofs, which together cover every run from reset:

  base.ys   from any state, after one clock with rst_n low, every paired
            signal (all 24 output pins and every flip-flop) agrees, for any
            inputs;
  step.ys   if every paired signal agrees in one cycle, it agrees in the
            next, for any state and any inputs.

So from the first cycle after a reset, the netlist and the RTL drive the
same value on every output pin, forever, whatever the inputs.

With --mutants, it also plants bugs in the netlist and requires each to
break the proof, so the proof is shown to be able to fail.

Usage:
  check.py --netlist tt_submission/<top>.v --lib <sg13cmos5l_stdcell>.lib
           [--mutants] [--yosys CMD]
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(HERE, "..", "src")


# --- Planted netlist bugs ----------------------------------------------------
# Each returns the mutated netlist. [half] is the proof that must fail.

def gate_function_changed(g):
    """A logic gate computes the wrong function: the first NAND becomes a NOR
    (same pins A, B, Y)."""
    i = g.index("sg13cmos5l_nand2_1 ")
    return g[:i] + "sg13cmos5l_nor2_1 " + g[i + len("sg13cmos5l_nand2_1 "):]


def flop_stuck_in_reset(g):
    """A flip-flop's asynchronous reset is tied active, so it holds 0."""
    t = re.search(r"sg13cmos5l_tiehi (\S+) \(\.L_HI\((\S+)\)\);", g)
    return (g[:t.start()] + "sg13cmos5l_tielo %s (.L_LO(%s));" % t.groups()
            + g[t.end():])


def flop_inputs_crossed(g):
    """Two flip-flops' D inputs swapped (a routing mistake)."""
    ds = list(re.finditer(
        r"sg13cmos5l_dfrbpq_1 \S+ \(\.RESET_B\(\S+\),\s*\.D\((\S+?)\)", g))
    a, b = ds[100], ds[900]
    return (g[:a.start(1)] + b.group(1) + g[a.end(1):b.start(1)] + a.group(1)
            + g[b.end(1):])


def wrong_reset_value(g):
    """The host port's chip-select synchroniser, which resets to 1 (idle),
    held in reset at 0 instead: wrong from the first cycle."""
    m = re.search(r"sg13cmos5l_dfrbpq_1 \S+ \(\.RESET_B\((\S+)\),\s*\.D\(\S+\),"
                  r"\s*\.Q\(\\u_protocol_emulator\.host_cs_n_s1 \)", g)
    net = m.group(1)
    t = re.search(r"sg13cmos5l_tiehi (\S+) \(\.L_HI\(" + re.escape(net) + r"\)\);", g)
    return (g[:t.start()] + "sg13cmos5l_tielo %s (.L_LO(%s));" % (t.group(1), net)
            + g[t.end():])


MUTANTS = [
    ("a gate's function changed", gate_function_changed, "step"),
    ("a flip-flop stuck in reset", flop_stuck_in_reset, "step"),
    ("two flip-flops' inputs crossed", flop_inputs_crossed, "step"),
    ("a wrong reset value", wrong_reset_value, "base"),
]


# --- Running Yosys -------------------------------------------------------------

def run(yosys, netlist_text, lib, half, workdir):
    os.makedirs(workdir)
    for f in ("project.v", "protocol_emulator.v"):
        shutil.copy(os.path.join(SRC, f), workdir)
    for f in ("setup.ys", "step.ys", "base.ys"):
        shutil.copy(os.path.join(HERE, f), workdir)
    shutil.copy(lib, os.path.join(workdir, "cells.lib"))
    with open(os.path.join(workdir, "gate.v"), "w") as f:
        f.write(netlist_text)
    # Paths relative to workdir: the WebAssembly build of Yosys sees only it.
    r = subprocess.run(yosys + ["-q", "-l", half + ".log", half + ".ys"],
                       cwd=workdir, stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL)
    with open(os.path.join(workdir, half + ".log")) as f:
        text = f.read()
    return r.returncode == 0, text


def summary(half, text):
    if half == "step":
        m = re.findall(r"Of those cells (\d+) are proven and (\d+) are unproven", text)
        return "%s proven, %s unproven" % m[-1] if m else "no result"
    if "SUCCESS" in text:
        return "no counterexample"
    return "counterexample found" if "model found: FAIL" in text else "no result"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--netlist", required=True)
    ap.add_argument("--lib", required=True)
    ap.add_argument("--mutants", action="store_true")
    ap.add_argument("--yosys", default=os.environ.get("YOSYS", "yosys"))
    args = ap.parse_args()
    yosys = args.yosys.split()
    with open(args.netlist) as f:
        netlist = f.read()

    jobs = [("netlist", "step", netlist, True), ("netlist", "base", netlist, True)]
    if args.mutants:
        jobs += [(name, half, mutate(netlist), False) for name, mutate, half in MUTANTS]

    tmp = tempfile.mkdtemp(prefix="gl_equiv_")
    with ThreadPoolExecutor(max_workers=os.cpu_count() or 2) as pool:
        futures = [pool.submit(run, yosys, text, args.lib, half,
                               os.path.join(tmp, "%d_%s" % (k, half)))
                   for k, (_, half, text, _) in enumerate(jobs)]
        results = [f.result() for f in futures]

    failed = False
    for (name, half, _, want_pass), (passed, log) in zip(jobs, results):
        ok = passed == want_pass
        failed |= not ok
        verdict = ("proved" if passed else "FAILED") if want_pass else \
                  ("caught" if not passed else "MISSED")
        print("%-32s %-4s  %-8s %s" % (name, half, verdict, summary(half, log)))
    print("logs in", tmp)
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
