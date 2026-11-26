# ir_irmp: out of reach, no runnable judge

Protocol: infrared remote control, judged through the IRMP library.
Decoder id: `ir_irmp`, from sigrok's own libsigrokdecode at 71f45144, as
committed in DECODERS (commit d058999, "as fetched").

## Verdict

No runnable judge. PREREG2 ("Judges that do not run") names this exact case:
a decoder that needs a native library sigrok-cli 0.7.2 does not have is
reported as out of reach. No TASK.md was written, and nothing was added to
the kit.

## Why

The decoder is a thin Python wrapper. `ir_irmp/irmp_library.py` loads a
native C library with `ctypes.cdll.LoadLibrary('libirmp.so')` on Linux and
hands it every sample through `irmp_add_one_sample()`. All of the protocol
recognition (which of the IRMP protocols a frame is, its address, command and
repeat flags) happens inside that C library, not in Python. `libirmp` was
added to libsigrokdecode's source tree after the 0.5.3 release and is built
and installed only by later libsigrokdecode builds.

What is installed here:

- sigrok-cli 0.7.2 (Debian package 0.7.2-1build2)
- libsigrokdecode 0.5.3 (package libsigrokdecode4 0.5.3-4build3), runtime
  `libsigrokdecode.so.4.2.1`, which exports no `irmp_*` symbols (`nm -D`
  finds none)
- no `libirmp.so` anywhere on the system (`ldconfig -p` and a filesystem
  search find nothing)

The decoder itself loads fine (`sigrok-cli -L` lists `ir_irmp  IR IRMP`), so
no Python port is needed or would help. It fails at the first call to
`decode()`.

## Exact error

Command (1 MHz, one channel, 20000 samples of a plain high/low/high line):

    SIGROKDECODE_DIR=DECODERS sigrok-cli -I binary:numchannels=1:samplerate=1000000 \
        -i cap.bin -P ir_irmp:ir=0 -A ir_irmp

Output:

    srd: LibraryError: Protocol decoder instance ir_irmp-1: : libirmp.so: cannot open shared object file: No such file or directory
    srd: Traceback (most recent call last):
      File ".../decoders/ir_irmp/pd.py", line 113, in decode
        self.irmp = irmp_library.IrmpLibrary()
      File ".../decoders/ir_irmp/irmp_library.py", line 111, in __init__
        self._lib = ctypes.cdll.LoadLibrary(filename)
      ...
    OSError: libirmp.so: cannot open shared object file: No such file or directory

sigrok-cli still exits with status 0 and prints no annotations, so a judge
built on it would see "nothing decoded" for every input, correct or not.

## What would be needed

A `libirmp.so` built from libsigrokdecode's `irmp/` sources (the IRMP C code
plus its sigrok glue, exporting `irmp_get_sample_rate`,
`irmp_instance_alloc`, `irmp_add_one_sample`, `irmp_get_result_data` and the
rest that `irmp_library.py` declares), installed where the dynamic loader
finds it. That is a native library sigrok-cli 0.7.2 does not ship, and
building one is not a mechanical change to the decoder, so PREREG2 rules it
out. A census that allowed it (for example a later sigrok-cli built against a
libsigrokdecode that includes libirmp) could judge this protocol.

## State left behind

- KIT (`kits/ir_irmp/`): untouched, holds only `isa.md` and `pe_sim`. No
  TASK.md.
- DECODERS `ir_irmp/`: no tracked file changed (`git diff` is empty). Running
  sigrok-cli made Python write an untracked `ir_irmp/__pycache__/`, as it
  does for every decoder it loads; it does not affect any decode.
- No PORT.diff, no accept.py: there is no judge to port or to validate.

## Feasibility, for the record

The chip side would not have been the obstacle. A typical IRMP protocol such
as NEC is a single line (one pin, P0), a 38 kHz carrier or, as IRMP samples
it, the demodulated envelope, with a 9 ms leader, 562.5 us bit marks and
0.5625 or 1.6875 ms spaces. At a 50 MHz core that is tens of thousands of
cycles per symbol, well inside what a cycle-counting thread can time. Only
the judge is missing.
