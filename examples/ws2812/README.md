# Blind firmware test: WS2812 LEDs

How easy is this chip to program for a protocol nobody designed it for?
This folder is one measurement. A programmer who had never seen the
project was given only the instruction-set document and the simulator, and
asked to drive WS2812B addressable LEDs. The programmer was an AI agent
(in a fresh session with no access to the conversation that built the
chip), not a person. A person is the better test, and is still to do.

## The protocol

1. **The kit.** A folder holding only three things:
   - `docs/isa.md`, as it was at commit 495c838;
   - `pe_sim`, the command-line assembler and reference-model simulator
     (`bin/pe_sim.ml`);
   - the task sheet, [TASK.md](TASK.md): the WS2812B timing from its data
     sheet, the 10 MHz clock, and what to hand in.
2. **The rules.** Read and write only inside the kit; no repository, no
   existing firmware, no web. The agent ran on the same machine as the
   repository, so this was an instruction, not a sandbox: [notes.md](notes.md)
   is its own account of everything it read and ran. It reports one slip:
   a throwaway file written to its scratch folder and deleted unused.
3. **The hidden test.** [accept.py](accept.py) was written separately and
   not shown to the agent until it handed in. It runs the firmware on the
   reference model and decodes P0 the way a WS2812B does, at the data
   sheet's limits (each high pulse and low gap within +-150 ns, a latch of
   280 us or more, no other gaps), on random frames of 1 to 20 LEDs.
   It was checked first against a deliberately simple firmware with correct
   timing (passed) and with a 0 bit's high time out of range, and with too
   short a latch (both failed).

## The result

| | |
|---|---|
| Time from reading the task to handing in | about 5 minutes |
| Simulator runs | 18 (plus 4 to read help and assemble) |
| Program | 16 instructions of the 64 |
| Hidden test, first submission | passed: every case, on seeds 1, 2, 3, 7 and 11 |
| Bugs in the firmware it found itself | none; its first version worked |

The firmware ([ws2812.s](ws2812.s)) sends 13-cycle bits (a 1: 800 ns high,
500 ns low; a 0: 400 ns high, 900 ns low), side-set on P0, bits most
significant first, with the bit count of each frame as the first word so the
firmware itself ends the frame with a 310 us latch.
[host.py](host.py) packs frames into words; [check.py](check.py) is the
agent's own test, which it wrote before handing in.

## What it found unclear in the documents

The agent listed seven things in `isa.md`, all fixed since:

1. `pe_sim` did not list its `-config` keys. It now does.
2. `.side_set n` only tells the assembler; the host must also set SIDESET,
   or the pins silently never change. Now said where side-set is described.
3. `in` and `out` said bits go least significant first, without the SHIFT
   setting that reverses them. Now both are given.
4. The operand numbers for `in`, `out`, `mov` and `set` were missing. Now
   listed with the encoding.
5. The pin-level table's headings read like bit positions. Reworded.
6. Pins come out of reset high, which matters for a line that idles low.
   Now stated, with how to start such a pin cleanly.
7. The wait timeout's wording ("stalls at most T cycles") left the jump
   cycle unclear. Now exact.

## Run it

    dune build bin/pe_sim.exe
    PE_SIM=_build/default/bin/pe_sim.exe python3 examples/ws2812/accept.py examples/ws2812 1

CI runs this on every push (`.github/workflows/ocaml.yaml`).
