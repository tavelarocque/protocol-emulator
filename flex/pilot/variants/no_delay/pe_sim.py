#!/usr/bin/env python3
"""pe_sim for a build of the chip that lacks one feature (FEATURE below).

Same command line as pe_sim.real, which sits beside this file and does all
the work. Before an `asm` or a `run` reaches it, the program is assembled
with pe_sim.real and its 16-bit words are checked; a program that uses the
missing feature is refused with exit status 2 and one line on stderr.
Every other command line goes to pe_sim.real untouched.

The instruction word (docs: "Encoding"):

     15  13 12   9 8        0
    +------+------+----------+
    |  op  | field| operands |
    +------+------+----------+

With side-set width n (0 to 3), the top n bits of the field, word bits
[12 : 13-n], are side-set values, and the low 4-n bits, word bits
[12-n : 9], are delay. The word does not hold n. It comes from two places:
`.side_set n` in the program (what the assembler packed) and
`sideset_count` in -config (what the thread unpacks). Both are found by
asking pe_sim.real, never by reading the program for keywords:

  declared n   the program is assembled once more with the line
               `nop side 7` added at the end. The assembler's answer names
               n: "side without .side_set" (0), "side value 7 does not fit
               in N bits" (N = 1 or 2), or no error (3).
  configured n pe_sim.real runs two `nop`s with the caller's -config (plus
               start=0, clkdiv=0, sideset_base=0, all pins push-pull). The
               pins it drives low are the side-set pins: their number is n.
"""

FEATURE = "delay"  # "sideset" or "delay"

import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.realpath(__file__))
REAL = os.path.join(HERE, "pe_sim.real")
NAME = {"sideset": "side-set", "delay": "delay field"}[FEATURE]

SUBCOMMANDS = ["asm", "run", "version", "help"]
# Flags of each subcommand: True if the flag takes an argument.
FLAGS = {
    "asm": {"-help": False, "-?": False},
    "run": {
        "-config": True,
        "-cycles": True,
        "-inputs": True,
        "-mode": True,
        "-tx": True,
        "-help": False,
        "-?": False,
    },
}
REPEATABLE = {"-mode"}

_tmp = None


def tmpdir():
    global _tmp
    if _tmp is None:
        _tmp = tempfile.mkdtemp(prefix="pe_sim.")
    return _tmp


def cleanup():
    global _tmp
    if _tmp is not None:
        shutil.rmtree(_tmp, ignore_errors=True)
        _tmp = None


def forward():
    """Hand the command line to pe_sim.real exactly as it came."""
    cleanup()
    os.execv(REAL, [sys.argv[0]] + sys.argv[1:])


def run_real(args):
    """Run pe_sim.real on [args] with our stdin, stdout and stderr, and
    finish as it finishes."""
    proc = subprocess.Popen([sys.argv[0]] + args, executable=REAL)

    def pass_on(sig, _frame):
        try:
            proc.send_signal(sig)
        except OSError:
            pass

    for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP, signal.SIGQUIT):
        signal.signal(sig, pass_on)
    status = proc.wait()
    cleanup()
    if status < 0:
        signal.signal(-status, signal.SIG_DFL)
        os.kill(os.getpid(), -status)
    sys.exit(status)


def refuse(why):
    cleanup()
    sys.stderr.write("pe_sim: refused: this build has no %s: %s\n" % (NAME, why))
    sys.exit(2)


def quiet(args):
    """pe_sim.real on [args], output captured: (status, stdout, stderr)."""
    p = subprocess.run(
        [REAL] + args,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return p.returncode, p.stdout, p.stderr


def expand(word, names):
    """The name [word] stands for: itself, or the one name it is a prefix
    of. None if there is no such name or more than one."""
    if word in names:
        return word
    found = [n for n in names if n.startswith(word)]
    return found[0] if len(found) == 1 else None


def parse(argv):
    """(subcommand, index in argv of the program, flag values), or None for
    any command line that does not get as far as assembling a program:
    help, another subcommand, or one pe_sim.real will reject."""
    if not argv:
        return None
    sub = expand(argv[0], SUBCOMMANDS)
    if sub not in FLAGS:
        return None
    flags = FLAGS[sub]
    seen = {}
    programs = []
    i = 1
    while i < len(argv):
        a = argv[i]
        if a.startswith("-") and a != "-":
            f = expand(a, list(flags))
            if f is None or not flags[f]:
                return None  # unknown or ambiguous flag, or help
            if i + 1 >= len(argv):
                return None  # missing argument
            if f in seen and f not in REPEATABLE:
                return None  # passed more than once
            seen.setdefault(f, []).append(argv[i + 1])
            i += 2
        else:
            programs.append(i)
            i += 1
    if len(programs) != 1:
        return None
    return sub, programs[0], seen


# --- what pe_sim.real says about a program -------------------------------


def write(name, data):
    path = os.path.join(tmpdir(), name)
    with open(path, "wb") as f:
        f.write(data)
    return path


def assemble(path):
    """The program's words, or None if it does not assemble."""
    status, out, _ = quiet(["asm", path])
    if status != 0:
        return None
    try:
        return [int(line, 16) for line in out.split()]
    except ValueError:
        return None


def source_lines(source):
    """(line number, text without comment or surrounding blanks), as the
    assembler splits a program."""
    out = []
    for k, raw in enumerate(source.split(b"\n")):
        text = raw.split(b";", 1)[0].strip()
        out.append((k + 1, text.decode("latin-1")))
    return out


def tokens(text):
    return [t for t in re.split(r"[ \t,]", text) if t]


def ocaml_int(s):
    m = re.fullmatch(r"([-+]?)(0[xXoObBuU])?([0-9a-fA-F][0-9a-fA-F_]*)", s)
    if not m:
        return None
    base = {"x": 16, "o": 8, "b": 2}.get((m.group(2) or "0d")[1].lower(), 10)
    try:
        v = int(m.group(3).replace("_", ""), base)
    except ValueError:
        return None
    return -v if m.group(1) == "-" else v


def side_set_lines(source):
    """Every `.side_set N` directive: (line number, text, N)."""
    out = []
    for line, text in source_lines(source):
        t = tokens(text)
        if len(t) == 2 and t[0] == ".side_set":
            out.append((line, text, ocaml_int(t[1])))
    return out


def declared_width(source, words):
    """The n of the program's `.side_set n`, asked of the assembler."""
    probe = write("declared.s", source + b"\nnop side 7\n")
    status, _, err = quiet(["asm", probe])
    if status == 0:
        return 3
    if b"side without .side_set" in err:
        return 0
    m = re.search(rb"side value 7 does not fit in (\d+) bits", err)
    if m:
        return int(m.group(1))
    # No room for the probe's word (a program of 256 words): read the
    # directive as the assembler does. The last one stands.
    n = 0
    for _line, _text, v in side_set_lines(source):
        if v is not None:
            n = v
    return n


def configured_width(config):
    """How many pins the thread drives from side-set under [config]: its
    sideset_count as the model uses it (8 stands for 8 or more). None if
    pe_sim.real does not accept the config."""
    probe = write("configured.s", b"nop\nnop\n")
    args = ["run", probe, "-cycles", "2"]
    args += ["-config", config + ",start=0,clkdiv=0,sideset_base=0"]
    for pin in range(8):
        args += ["-mode", "%d=pp" % pin]
    status, out, _ = quiet(args)
    if status != 0:
        return None
    pins = 0xFF
    for line in out.decode("latin-1").splitlines():
        part = line.split()
        if len(part) == 3 and part[0] == "pins":
            pins = int(part[2], 16)
    return 8 - bin(pins & 0xFF).count("1")


def instruction_lines(source, count):
    """For each word of the program, the line it was assembled from, or
    None if they cannot be matched up."""
    out = []
    for line, text in source_lines(source):
        t = tokens(text)
        if len(t) == 2 and t[0] in (".side_set", ".page"):
            continue
        if t == [".align"]:
            while len(out) % 64:
                out.append((line, ".align"))
            continue
        if ":" in text:
            label, rest = text.split(":", 1)
            label = label.strip()
            if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", label):
                text = rest.strip()
        if text:
            out.append((line, text))
    return out if len(out) == count else None


def where(k, word, lines):
    s = "word %d = %04x" % (k, word)
    if lines:
        line, text = lines[k]
        if len(text) > 60:
            text = text[:57] + "..."
        s += ' (line %d: "%s")' % (line, text)
    return s


# --- the two builds ------------------------------------------------------


def config_item(config, key):
    """The last `key=value` of a -config string, as written."""
    found = None
    for item in config.split(","):
        k, eq, v = item.partition("=")
        if eq and k.strip() == key:
            found = "%s=%s" % (key, v.strip())
    return found


def check_sideset(sub, source, words, config):
    # The thread applies side-set only with sideset_count above zero.
    if sub == "run" and config is not None:
        n = configured_width(config)
        if n is not None and n > 0:
            refuse("-config sets %s" % (config_item(config, "sideset_count") or "sideset_count above 0"))
    if words is None:
        return
    # The program packs side-set values only under `.side_set n`, n > 0.
    n = declared_width(source, words)
    if n > 0:
        said = [(line, text) for line, text, v in side_set_lines(source) if v != 0]
        at = 'line %d: "%s"' % said[-1] if said else ".side_set %d" % n
        bits = "bit 12" if n == 1 else "bits [12:%d]" % (13 - n)
        first = " (word 0 = %04x)" % words[0] if words else ""
        refuse("%s puts side-set values in %s of every word%s" % (at, bits, first))


def delay_mask(n):
    """Which bits of the 4-bit field are delay with side-set width n."""
    if 1 <= n <= 4:
        return (1 << (4 - n)) - 1
    return 0xF


def check_delay(sub, source, words, config):
    if words is None:
        return
    lines = instruction_lines(source, len(words))
    # As the program was written: delay is what `.side_set` leaves.
    n = declared_width(source, words)
    mask = delay_mask(n)
    for k, w in enumerate(words):
        d = (w >> 9) & mask
        if d:
            refuse("%s has delay %d" % (where(k, w, lines), d))
    # As the thread will read it: delay is what sideset_count leaves.
    if sub == "run":
        c = configured_width(config or "")
        if c is None:
            return
        mask = delay_mask(c)
        for k, w in enumerate(words):
            d = (w >> 9) & mask
            if d:
                refuse(
                    "with side-set width %s in -config, the thread reads %s as delay %d "
                    "(the program says .side_set %d: set sideset_count=%d)"
                    % ("8 or more" if c >= 8 else c, where(k, w, lines), d, n, n)
                )


def main():
    # Python starts with SIGPIPE ignored, and pe_sim.real would inherit that.
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    argv = sys.argv[1:]
    if "COMP_CWORD" in os.environ:
        forward()  # shell completion, not a command
    parsed = parse(argv)
    if parsed is None:
        forward()
    sub, at, flags = parsed
    try:
        with open(argv[at], "rb") as f:
            source = f.read()
    except OSError:
        forward()  # pe_sim.real reports it
    try:
        # One copy of the program is checked and then run, so the two
        # cannot differ.
        program = write("program.s", source)
        words = assemble(program)
        config = flags["-config"][0] if "-config" in flags else None
        if FEATURE == "sideset":
            check_sideset(sub, source, words, config)
        else:
            check_delay(sub, source, words, config)
    except SystemExit:
        raise
    except BaseException:
        cleanup()
        raise
    run_real(argv[:at] + [program] + argv[at + 1 :])


if __name__ == "__main__":
    main()
