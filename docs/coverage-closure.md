# AI-assisted coverage closure

Random differential testing is the backbone of this project's verification:
400 random two-thread programs, each run for 300 cycles in lockstep against
the reference model. It is very good at instruction-level behaviour and poor
at combinations. A uniformly random 64-word program almost never sets up the
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

2. **Generate.** An AI assistant (Claude) read the cross-bin report and
   wrote one small two-thread scenario per weak bin: two programs, their
   configurations, pin modes, CHAIN, and the stimulus (pin inputs, host
   traffic, an enable script). It also wrote one scenario aimed at the
   planted RTL bugs. The scenarios are in `sim/directed.ml`, each with the
   list of bins or bugs it was written for.

   One caveat, stated plainly: the same assistant also wrote the RTL and
   the planted bugs, so the bug-targeted scenario is not a blind search.
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
suite is 8 scenarios, each run under 3 seeds for 200 to 400 cycles, about
9,600 cycles in all.

| Cross bin | Random trials | Directed suite |
|---|---:|---:|
| pins: both threads write the same pin | 4,896 | 399 |
| chain: move into thread 1 TX holding 0 | 138 | 12 |
| chain: move into thread 1 TX holding 1 | 69 | 36 |
| chain: move into thread 1 TX holding 2 | 39 | 33 |
| chain: move into thread 1 TX holding 3 | 47 | 1,230 |
| chain: move in a cycle thread 1 pulls | **2** | 420 |
| chain: move in a cycle thread 0 pushes | **7** | 558 |
| chain: thread 0 PUSH stalled behind a full chain | 745 | 1,626 |
| divider: timed wait expires on a divided thread | 315 | 42 |
| divider: delay counted on a divided thread | 9,198 | 534 |
| divider: side-set on a divided thread | 16,328 | 780 |
| enable: disabled during a delay | 185 | 9 |
| enable: disabled during a timed wait | 50 | 6 |
| enable: disabled between divider ticks | 206 | 6 |
| side-set: driven during a stall | 43,012 | 348 |
| fifo: both threads stalled on FIFOs | 2,166 | 1,176 |

The two bins random testing almost never reached, a word crossing the chain
in the same cycle that thread 1 pulls or thread 0 pushes, are the
simultaneous-access cases a FIFO is most likely to get wrong. Random trials
hit them 2 and 7 times; the directed suite hits them hundreds of times, with
about 8% of the simulated cycles.

Planted RTL bugs caught by the directed suite (all 8; random trials needed
up to 25 programs to catch the CHAIN bug):

| Bug | Directed scenarios that catch it |
|---|---:|
| X never decrements (thread 1) | 1 of 8 |
| Wait timeout ignores its budget (thread 1) | 3 of 8 |
| Delay field ignored (thread 1) | 4 of 8 |
| SET writes one pin too many (thread 1) | 2 of 8 |
| PUSH not right-justified (thread 1) | 2 of 8 |
| Pin priority inverted | 1 of 8 |
| Thread 1 fetches from thread 0's PC | 8 of 8 |
| CHAIN moves a word into a full FIFO | 3 of 8 |

**The checks rejected a generated test.** The first version of the
streaming scenario used two-instruction loops for both producer and
consumer. They ran phase-locked: words crossed the chain on odd cycles,
pushes and pulls happened on even ones, so the scenario never reached the
two bins it was written for, and `test_closure.ml` failed the build. The
fix (bursty loops whose phases drift) is in the scenario's comment. This is
the failure mode an AI-written test is most prone to, a plausible test that
does not test what it claims, and it is why every scenario's targets are
checked rather than assumed.

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
