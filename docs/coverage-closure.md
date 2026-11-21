# AI-assisted coverage closure

Random differential testing is the backbone of this project's verification:
400 random two-thread programs, each run for 300 cycles in lockstep against
the reference model. It is very good at instruction-level behaviour and poor
at combinations. A uniformly random program almost never sets up the
exact interplay of two threads, a clock divider, CHAIN and the FIFOs that a
real protocol bridge relies on. This document describes how those gaps were
found and closed, and how the result is kept honest.

## The loop

1. **Measure.** The lockstep harness (`sim/lockstep.ml`) counts two kinds of
   coverage on every cycle, from the reference model's state, so the counts
   never depend on the hardware being tested:
   - basic bins: what each thread did (every instruction outcome, stall,
     timeout, delay, divider gap, disabled cycle);
   - cross bins: combinations that matter for correctness, listed in
     `Lockstep.all_cross_bins` (both threads writing the same pin, CHAIN
     moving a word into each FIFO level, a timed wait expiring on a divided
     thread, a thread disabled in the middle of a delay, and so on).

   `sim/test_core.ml` prints both for the random trials.

2. **Generate.** An AI assistant read the cross-bin report and
   wrote one small two-thread scenario per weak bin: two programs, their
   configurations, pin modes, CHAIN, and the stimulus (pin inputs, host
   traffic, an enable script). It also wrote scenarios aimed at planted
   RTL bugs, three at first and more with each hardware revision. The
   scenarios are in `sim/directed.ml`, each with the list of bins or bugs
   it was written for.

   One caveat, stated plainly: the same assistant also wrote the RTL and
   the planted bugs, so the bug-targeted scenarios are not a blind search.
   What it shows is that the directed suite exercises those behaviours in
   thread 1, not that an independent generator discovered the bugs. The
   coverage-targeted scenarios do not have this problem: their success is
   measured by the model's own coverage counts, which the assistant cannot
   influence.

3. **Judge.** Nothing generated is trusted. `sim/test_closure.ml` runs every
   scenario through the same lockstep harness as the random trials, so the
   reference model judges every cycle, and then checks that:
   - every scenario matches the model under three seeds;
   - every scenario hits every cross bin it claims to target, or the build
     fails;
   - the directed suite alone closes every cross bin;
   - every scenario written for a planted bug catches that bug, and the suite
     as a whole catches all of them.

   The formal proof is the second judge for anything a scenario reveals in
   a thread's datapath: a divergence found by a directed test would be
   reproduced as a SAT counterexample against the specification.

## Results

The random trials run 120,000 cycles (400 programs of 300). The directed
suite is 19 scenarios, each run under 3 seeds for a few hundred cycles.

| Cross bin | Random trials | Directed suite |
|---|---:|---:|
| pins: both threads write the same pin | 5,248 | 399 |
| chain: move into thread 1 TX holding 0 | 179 | 12 |
| chain: move into thread 1 TX holding 1 | 58 | 36 |
| chain: move into thread 1 TX holding 2 | 45 | 33 |
| chain: move into thread 1 TX holding 3 | 78 | 1,230 |
| chain: move in a cycle thread 1 pulls | **3** | 420 |
| chain: move in a cycle thread 0 pushes | **4** | 558 |
| chain: thread 0 PUSH stalled behind a full chain | 1,040 | 1,626 |
| divider: timed wait expires on a divided thread | 450 | 42 |
| divider: delay counted on a divided thread | 10,447 | 534 |
| divider: side-set on a divided thread | 15,374 | 780 |
| enable: disabled during a delay | 198 | 9 |
| enable: disabled during a timed wait | 43 | 6 |
| enable: disabled between divider ticks | 211 | 6 |
| side-set: driven during a stall | 38,071 | 351 |
| fifo: both threads stalled on FIFOs | 1,029 | 1,176 |

The two bins random testing almost never reached, a word crossing the chain
in the same cycle that thread 1 pulls or thread 0 pushes, are the
simultaneous-access cases a FIFO is most likely to get wrong. Random trials
hit them 3 and 4 times in 120,000 cycles; the directed suite hits them
hundreds of times.

Planted RTL bugs caught by the directed suite (all 33; random trials needed
up to 23 programs to catch the slowest):

| Bug | Directed scenarios that catch it |
|---|---:|
| X never decrements (thread 1) | 2 of 19 |
| Wait timeout ignores its budget (thread 1) | 3 of 19 |
| Delay field ignored (thread 1) | 5 of 19 |
| SET writes one pin too many (thread 1) | 4 of 19 |
| PUSH not right-justified (thread 1) | 3 of 19 |
| Pin priority inverted | 1 of 19 |
| Thread 1 fetches from thread 0's PC | 19 of 19 |
| CHAIN moves a word into a full FIFO | 3 of 19 |
| PUSH ignores the IN shift direction (thread 1) | 1 of 19 |
| Synchroniser bypass read with inverted polarity | 3 of 19 |
| A jump ignores PAGE | 1 of 19 |
| A host write lands in a running thread's memory | 1 of 19 |
| No hold after a write to a thread's memory | 1 of 19 |
| Autopull fetches from an empty FIFO | 1 of 19 |
| Autopush pushes into a full FIFO | 2 of 19 |
| The CRC register ignores the shift direction | 1 of 19 |
| The CRC register keeps following after it is read | 1 of 19 |
| The buffer plays into a full FIFO | 2 of 19 |
| The buffer plays past its end | 2 of 19 |
| A recording buffer lets the host pop as well | 1 of 19 |
| A word is played in the cycle after a write | 1 of 19 |
| The sampler takes a cycle's two samples in the wrong order | 1 of 19 |
| The sampler accepts an edge one sample too soon | 1 of 19 |
| The sampler passes bits on before the sync word | 1 of 19 |
| The sampler keeps its carrier after a bit time with no edge | 1 of 19 |
| The sampler's pulse shows on the wrong pin | 2 of 19 |
| The sampler's prescaler counts one cycle too many | 1 of 19 |
| The prescaled sampler takes both of a cycle's samples | 1 of 19 |
| The sampler's pin shift is ignored | 1 of 19 |
| The prescaled sampler's pulse lasts one cycle, not until the next sample | 1 of 19 |
| The sampler takes a stuff bit out one bit late | 1 of 19 |
| The sampler drops the bit after a run whatever its level | 1 of 19 |
| A stuff bit does not start the next run | 2 of 19 |

Three bugs and the two scenarios written for them (one jumps between
pages, one rewrites a thread's program while it is stopped, while it
runs, and just before it starts) came with v2.0's program memory. Eight
bugs and five scenarios came with v2.1: the automatic refill, the CRC
register, and the buffer playing, recording, and written just before it
is set playing. Five bugs and one scenario came with v2.2's bit
sampler: a short Manchester transmission placed sample by sample, with one
edge on the last sample at which it must still be ignored. The last seven
bugs and one scenario came with v2.3's settings for it: a line sampled
once every three cycles, eight samples to the bit, with stuff bits to
take out after runs of five at both levels, a run that goes on past five,
the recovered bit shown two pins from the line, and one late edge.

**The checks rejected a generated test.** The first version of the
streaming scenario used two-instruction loops for both producer and
consumer. They ran phase-locked: words crossed the chain on odd cycles,
pushes and pulls happened on even ones, so the scenario never reached the
two bins it was written for, and `test_closure.ml` failed the build. The
fix (bursty loops whose phases drift) is in the scenario's comment. This is
the failure mode an AI-written test is most prone to, a plausible test that
does not test what it claims, and it is why every scenario's targets are
checked rather than assumed.

**A planted bug survived the first directed suite.** When the input
synchronisers were added (ISA v1.3), so was a planted bug in them. The
random trials caught it in the first program, but none of the first eight
directed scenarios did: none read the pins in a way where two cycles of
delay changed what the thread did. That is a gap in the suite, and the
closure check that every bug is caught failed the build. The ninth
scenario, which reads every pin on every cycle with half of them bypassing
the synchroniser, closes it.

## Why this design

The obvious alternative, letting a model write the expected outputs as
well, would make the AI the oracle, and an AI oracle is a second
implementation that can share the first one's misreadings. Here the AI only
proposes stimulus. The judge is the reference model, written independently
of the hardware and anchored to the formal specification, and the closure
checks above reject any scenario that does not do what it says it does.

The generated scenarios are committed source, not a run-time service, so CI
is deterministic and needs no API access. Re-running the loop means giving
an assistant the current cross-coverage report and adding what it writes to
`Directed.all`; the checks decide whether it stays.
