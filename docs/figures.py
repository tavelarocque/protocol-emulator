#!/usr/bin/env python3
"""Draws the timing diagrams in docs/img from the reference model.

Each diagram is a run of pe_sim (bin/pe_sim.ml: the model the RTL is checked
against every cycle) on a program in examples/, so the pictures show what
the firmware does, cycle for cycle, and are regenerated, not drawn by hand.

    dune build bin/pe_sim.exe
    python3 docs/figures.py            # writes docs/img/*.svg
    python3 docs/figures.py --check    # fails if a committed file differs
"""
import os
import subprocess
import sys
import tempfile

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
PE_SIM = os.environ.get("PE_SIM", os.path.join(ROOT, "_build/default/bin/pe_sim.exe"))
OUT = os.path.join(ROOT, "docs", "img")

INK, GRID, FAINT, ACCENT = "#1b1f24", "#d0d7de", "#6e7781", "#0969da"


def run(program, config, modes, words, cycles):
    """[(cycle, pins)] for every change of the 8 pins."""
    with tempfile.NamedTemporaryFile("w", suffix=".tx", delete=False) as f:
        f.write("\n".join(str(w) for w in words))
    args = [PE_SIM, "run", os.path.join(ROOT, program), "-config", config,
            "-tx", f.name, "-cycles", str(cycles)]
    for m in modes:
        args += ["-mode", m]
    out = subprocess.run(args, capture_output=True, text=True, check=True).stdout
    os.unlink(f.name)
    return [(int(c), int(p, 16)) for k, c, p in (l.split() for l in out.splitlines())
            if k == "pins"]


def level(changes, pin, cycle):
    v = 1
    for c, pins in changes:
        if c > cycle:
            break
        v = (pins >> pin) & 1
    return v


def svg(title, note, changes, signals, start, end, marks, per_cycle):
    """signals: [(label, pin)]. marks: [(cycle, text)] printed above the top
    trace, each with a dotted line down through the traces."""
    left, top, row, high = 76, 76, 44, 24
    width = max(left + (end - start) * per_cycle + 24, 30 + 8 * max(len(title), len(note)))
    height = top + row * len(signals) + 46
    x = lambda c: left + (c - start) * per_cycle
    o = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" '
         'font-family="ui-monospace, SFMono-Regular, Menlo, monospace" font-size="12">'
         % (width, height, width),
         '<rect width="100%%" height="100%%" fill="#ffffff"/>',
         '<text x="16" y="22" font-size="14" font-weight="600" fill="%s">%s</text>'
         % (INK, title),
         '<text x="16" y="40" fill="%s">%s</text>' % (FAINT, note)]
    bottom = top + row * len(signals) - (row - high)
    for c, text in marks:
        o.append('<line x1="%.1f" y1="%d" x2="%.1f" y2="%d" stroke="%s" '
                 'stroke-dasharray="2 3"/>' % (x(c), top - 4, x(c), bottom + 4, GRID))
        o.append('<text x="%.1f" y="%d" fill="%s">%s</text>' % (x(c) + 3, top - 8, ACCENT, text))
    for k, (label, pin) in enumerate(signals):
        y1 = top + row * k
        y0 = y1 + high
        o.append('<text x="16" y="%d" fill="%s">%s</text>' % (y0 - 6, INK, label))
        pts, v = [], level(changes, pin, start)
        pts.append((x(start), y1 if v else y0))
        for c in range(start + 1, end + 1):
            nv = level(changes, pin, c)
            if nv != v:
                pts += [(x(c), y1 if v else y0), (x(c), y1 if nv else y0)]
                v = nv
        pts.append((x(end), y1 if v else y0))
        o.append('<polyline fill="none" stroke="%s" stroke-width="1.6" points="%s"/>'
                 % (INK, " ".join("%.1f,%d" % p for p in pts)))
    axis = bottom + 16
    step = 10 if (end - start) <= 160 else 50
    for c in range(start, end + 1, step):
        o.append('<line x1="%.1f" y1="%d" x2="%.1f" y2="%d" stroke="%s"/>'
                 % (x(c), axis - 4, x(c), axis, FAINT))
        o.append('<text x="%.1f" y="%d" text-anchor="middle" fill="%s">%d</text>'
                 % (x(c), axis + 14, FAINT, c - start))
    o.append('<text x="16" y="%d" fill="%s">cycles</text>' % (axis + 14, FAINT))
    o.append("</svg>")
    return "\n".join(o) + "\n"


def first_fall(changes, pin, after=0):
    v = 1
    for c, pins in changes:
        nv = (pins >> pin) & 1
        if c >= after and v and not nv:
            return c
        v = nv
    raise ValueError("pin %d never falls" % pin)


def first_rise(changes, pin, after=0):
    v = level(changes, pin, after)
    for c, pins in changes:
        nv = (pins >> pin) & 1
        if c > after and not v and nv:
            return c
        if c > after:
            v = nv
    raise ValueError("pin %d never rises" % pin)


def uart():
    byte, div = 0xA5, 10
    ch = run("examples/uart_tx.s", "out_base=0,out_count=1,set_base=0,set_count=1,threshold=8",
             ["0=pp"], [div - 4, byte], 200)
    s = first_fall(ch, 0)
    marks = [(s, "start")] + [(s + div * (k + 1), "%d" % ((byte >> k) & 1)) for k in range(8)]
    marks.append((s + div * 9, "stop"))
    return svg("UART transmit: 0xA5, 8N1, 10 cycles a bit (examples/uart_tx.s, 15 instructions)",
               "Least significant bit first. Every bit is exactly the divisor the host sent.",
               ch, [("P0 TX", 0)], s - 10, s + div * 10 + 10, marks, 6)


def spi():
    byte = 0xA5
    ch = run("examples/spi_fast.s",
             "sideset_base=0,sideset_count=1,out_base=1,out_count=3,in_base=2,threshold=8,"
             "out_msb_first=1,in_msb_first=1",
             ["0=pp", "1=pp", "3=pp"], [(byte << 8) | 0x80], 80)
    s = first_fall(ch, 3, after=2)
    marks = [(s + 1 + 2 * k, "%d" % ((byte >> (7 - k)) & 1)) for k in range(8)]
    return svg("SPI controller, mode 0: 0xA5 at 2 cycles a bit (examples/spi_fast.s, 26 instructions)",
               "Side-set drives SCK from the same instruction that moves or samples data: "
               "5 Mbit/s at 10 MHz.",
               ch, [("P3 CS_N", 3), ("P0 SCK", 0), ("P1 MOSI", 1)], s - 4, s + 26, marks, 18)


def ws2812():
    sys.path.insert(0, os.path.join(ROOT, "examples", "ws2812"))
    import host
    green = 0xA5
    args = open(os.path.join(ROOT, "examples/ws2812/run_args.txt")).read().split()
    config = args[args.index("-config") + 1]
    ch = run("examples/ws2812/ws2812.s", config, ["0=pp"], host.encode([[(0, green, 0)]]), 4000)
    s = first_rise(ch, 0, after=first_fall(ch, 0))
    marks = [(s + 13 * k, "%d" % ((green >> (7 - k)) & 1)) for k in range(8)]
    return svg("WS2812 LED data: the first byte, 0xA5 (examples/ws2812/ws2812.s, 16 instructions)",
               "13 cycles a bit at 10 MHz. A 1 is high for 800 ns, a 0 for 400 ns. "
               "Written blind, from the instruction-set document alone.",
               ch, [("P0 DIN", 0)], s - 6, s + 13 * 8 + 6, marks, 7)


FIGURES = {"uart.svg": uart, "spi.svg": spi, "ws2812.svg": ws2812}

if __name__ == "__main__":
    check = "--check" in sys.argv
    stale = []
    for name, make in FIGURES.items():
        path, text = os.path.join(OUT, name), make()
        if check:
            if not os.path.exists(path) or open(path).read() != text:
                stale.append(name)
        else:
            open(path, "w").write(text)
    if stale:
        sys.exit("docs/img is out of date: %s (run python3 docs/figures.py)" % ", ".join(stale))
