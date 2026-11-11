#!/usr/bin/env python3
"""Acceptance test for the blind WS2812 firmware: decodes P0 the way a
WS2812B does (data-sheet limits), on random frames the author never saw.

Usage: accept.py KIT_DIR [seed]; pe_sim is KIT_DIR/pe_sim, or $PE_SIM.

This was written separately from the firmware and kept from its author
until the firmware was handed in (README.md).""" 
import importlib.util, random, subprocess, sys, tempfile, os

kit = sys.argv[1]
seed = int(sys.argv[2]) if len(sys.argv) > 2 else 1
NS = 100  # one cycle at 10 MHz
T0H, T1H = (250, 550), (650, 950)
T0L, T1L = (700, 1000), (300, 600)
LATCH = 280_000

spec = importlib.util.spec_from_file_location("host", os.path.join(kit, "host.py"))
host = importlib.util.module_from_spec(spec)
spec.loader.exec_module(host)
args = open(os.path.join(kit, "run_args.txt")).read().split()

rng = random.Random(seed)
cases = [
    [[(0, 0, 0)], [(255, 255, 255)]],
    [[(0x12, 0x34, 0x56), (0xFE, 0x01, 0x80)]],
]
for _ in range(6):
    cases.append([[tuple(rng.randrange(256) for _ in range(3)) for _ in range(rng.randint(1, 20))]
                  for _ in range(rng.randint(1, 3))])

failures = 0
for n, frames in enumerate(cases):
    words = host.encode(frames)
    with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False) as f:
        f.write("\n".join(str(w) for w in words))
    bits_total = sum(len(fr) * 24 for fr in frames)
    cycles = bits_total * 20 + len(frames) * 4000 + 6000
    out = subprocess.run([os.environ.get("PE_SIM", os.path.join(kit, "pe_sim")), "run", os.path.join(kit, "ws2812.s"),
                          "-tx", f.name, "-cycles", str(cycles)] + args,
                         capture_output=True, text=True, check=True).stdout
    edges = [(int(c), int(p, 16) & 1) for k, c, p in (l.split() for l in out.splitlines()) if k == "pins"]
    # The level of P0 from each change to the next; collapse repeats.
    seg, level0 = [], None
    for c, v in edges:
        if seg and seg[-1][1] == v:
            continue
        seg.append((c, v))
    seg.append((cycles, None))
    runs = [(seg[i][1], (seg[i + 1][0] - seg[i][0]) * NS) for i in range(len(seg) - 1)]
    errs, got, cur, bits = [], [], [], []
    # The chip's pins come out of reset high: a push-pull P0 is high until
    # the firmware first drives it. That is harmless only if a latch-length
    # low follows before any data.
    if runs and runs[0][0] == 1:
        if len(runs) > 1 and runs[1][1] >= LATCH:
            runs = runs[2:]
        else:
            errs.append(f"P0 starts high ({runs[0][1]} ns) and no latch follows before the data")
    i = 0
    while i < len(runs):
        v, t = runs[i]
        if v == 1:
            nxt = runs[i + 1] if i + 1 < len(runs) else (0, LATCH)
            low = nxt[1]
            if T0H[0] <= t <= T0H[1]:
                b = 0
            elif T1H[0] <= t <= T1H[1]:
                b = 1
            else:
                errs.append(f"high pulse of {t} ns")
                b = None
            if low < LATCH:
                lo = T0L if b == 0 else T1L
                if b is not None and not lo[0] <= low <= lo[1]:
                    errs.append(f"low gap of {low} ns after a {b}")
            bits.append(b)
            if low >= LATCH:
                got.append(bits)
                bits = []
            i += 2
        else:
            i += 1
    if bits:
        errs.append(f"{len(bits)} bits never latched (frame not ended with {LATCH} ns low)")
    want = [[b for (r, g, bb) in fr for x in (g, r, bb) for b in ((x >> (7 - k)) & 1 for k in range(8))]
            for fr in frames]
    if got != want:
        errs.append(f"decoded {len(got)} frames of {[len(g) for g in got]} bits, "
                    f"wanted {len(want)} of {[len(w) for w in want]}"
                    + ("" if len(got) != len(want) or any(len(a) != len(b) for a, b in zip(got, want))
                       else ": wrong bit values"))
    status = "PASS" if not errs else "FAIL: " + "; ".join(sorted(set(errs))[:4])
    print(f"case {n} ({len(frames)} frames, {bits_total} bits): {status}")
    failures += bool(errs)
print("ALL PASS" if not failures else f"{failures} of {len(cases)} cases failed")
sys.exit(1 if failures else 0)
