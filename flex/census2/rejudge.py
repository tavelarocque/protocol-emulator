# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
"""Judge round 2's hand-ins again from the files in this folder.

Usage: python3 flex/census2/rejudge.py PE_SIM [NAME ...]

PE_SIM is the simulator built from commit 771319c (the frozen kit; its
SHA-256 starts 82b00ea2). The decoders must first be rebuilt with
fetch_decoders.sh. Each hidden test is used exactly as it ran: the only
change, made in a temporary copy, is the one line naming the decoder folder,
which pointed into the organiser's workspace. Each hand-in is put in a
temporary kit with its TASK.md, the frozen isa.md and PE_SIM, as the
programmer had it, and the hidden test's last line is printed.
"""
import hashlib, os, shutil, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
OLD = "/tmp/claude-0/-home-claude/2c77ffdf-e166-586f-82c8-96f140f92ea4/scratchpad/flex2/decoders"
OLD_SPLIT = ('"/tmp/claude-0/-home-claude/2c77ffdf-e166-586f-82c8-96f140f92ea4"\n'
             '                          "/scratchpad/flex2/decoders"')
NAMES = ["can_fd", "c2", "eth_an", "fsi", "mipi_dsi", "mipi_rffe", "pxx1", "qspi", "st7789"]


def sha(path):
    return hashlib.sha256(open(path, "rb").read()).hexdigest()


def main():
    pe_sim = os.path.abspath(sys.argv[1])
    names = sys.argv[2:] or NAMES
    decoders = os.path.join(HERE, "decoders")
    if not os.path.isdir(os.path.join(decoders, "can-fd")):
        sys.exit("run fetch_decoders.sh first")
    if not sha(pe_sim).startswith("82b00ea2"):
        print("warning: this pe_sim is not the frozen kit's (82b00ea2...)")
    bad = 0
    for n in names:
        tmp = tempfile.mkdtemp(prefix=f"census2-{n}-")
        hidden, kit = os.path.join(tmp, "hidden"), os.path.join(tmp, "kit")
        shutil.copytree(os.path.join(HERE, n, "hidden"), hidden)
        acc = os.path.join(hidden, "accept.py")
        src = open(acc).read()
        new = src.replace(OLD, decoders).replace(OLD_SPLIT, repr(decoders))
        if new == src or OLD in new:
            sys.exit(f"{n}: decoder path not found in accept.py")
        open(acc, "w").write(new)
        os.makedirs(kit)
        for f in os.listdir(os.path.join(HERE, n, "handin")):
            shutil.copy(os.path.join(HERE, n, "handin", f), kit)
        shutil.copy(os.path.join(HERE, n, "TASK.md"), kit)
        shutil.copy(os.path.join(HERE, "isa.md"), kit)
        shutil.copy(pe_sim, os.path.join(kit, "pe_sim"))
        r = subprocess.run([sys.executable, "accept.py", kit], cwd=hidden,
                           capture_output=True, text=True)
        last = (r.stdout.strip().splitlines() or ["(no output)"])[-1]
        print(f"{n:10} {last}")
        bad += r.returncode != 0
        shutil.rmtree(tmp)
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
