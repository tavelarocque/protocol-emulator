# Related work

Papers and primary documents behind the design and verification of this
chip, each with what we take from it. Every entry was checked to exist at
the linked URL.

## What this changes in the project

The literature points at concrete next steps, in rough order of value per
hour:

1. **Shrink failing random programs to minimal reproducers**, as TestRIG does
   with QuickCheck [V1]. Our differential test currently reports the first
   divergence in a 32-word program; shrinking would cut that to the few
   instructions that matter.
2. **Prove, don't only test, the core against the model**, in the style of
   Arm's ISA-Formal [V11]. With total decode and a 16-bit instruction word,
   "one step of the RTL equals one step of the spec, for every instruction"
   is a tractable SAT problem with Hardcaml's own formal tools [V14].
3. **Discharge equivalent mutants formally** [V7]. Our "pop RX when empty"
   mutant survived because the FIFO already guards it; a SAT equivalence
   check would prove it is equivalent rather than leaving it as an argument.
4. **Close coverage holes with an LLM, judged by the existing oracle**
   [V9, V10]. Feed the coverage report's holes and `docs/isa.md` to a model,
   ask for programs targeting them, and run them through the same lockstep
   checker. The oracle keeps the LLM honest.
5. **Coverage on state transitions and control-state hashes**, not only
   instruction outcomes [V2, V4, V6].
6. **Characterise the silicon's timing** the way Starkey et al. measured
   RP2040 PIO [P8], and read RP2350's list of PIO changes [P5] before freezing
   the ISA.

## Verification

**Random programs and differential testing against an ISA model**

- [V1] Joannou et al., *Randomized Testing of RISC-V CPUs Using Direct
  Instruction Injection* (TestRIG), IEEE Design & Test 41(1), 2024.
  https://doi.org/10.1109/MDAT.2023.3262741
  Lockstep RTL-vs-Sail trace comparison with QuickCheck shrinking (median
  counterexample: 3 instructions). Closest prior art to our differential
  test.
- [V2] Hur et al., *DifuzzRTL: Differential Fuzz Testing to Find CPU Bugs*,
  IEEE S&P 2021. https://jaewonhur.github.io/files/jwhur-difuzzrtl.pdf
  RTL vs golden simulator, guided by hashing control registers every cycle.
- [V3] Solt, Ceesay-Seitz, Razavi, *Cascade: CPU Fuzzing via Intricate
  Program Generation*, USENIX Security 2024.
  https://www.usenix.org/conference/usenixsecurity24/presentation/solt
  Long, data-dependent programs reach states short uniform ones rarely do;
  automatic pruning to the minimal buggy instructions.
- [V4] Canakci et al., *ProcessorFuzz: Processor Fuzzing with Control and
  Status Registers Guidance*, IEEE HOST 2023. https://arxiv.org/abs/2209.01789
  Coverage on architectural state transitions, from the ISA simulator's
  trace. Also found a bug in the reference model itself.

**Coverage**

- [V5] Fine, Ziv, *Coverage Directed Test Generation for Functional
  Verification Using Bayesian Networks*, DAC 2003.
  https://doi.org/10.1145/775832.775907
  The founding paper for feeding coverage holes back into the generator.
- [V6] Laeufer et al., *RFUZZ: Coverage-Directed Fuzz Testing of RTL on
  FPGAs*, ICCAD 2018. https://doi.org/10.1145/3240765.3240842
  Mux-toggle coverage via compiler passes on an HDL embedded in a functional
  language; the Hardcaml analogue is instrumenting every `mux` select.

**Mutation testing**

- [V7] Madeyski et al., *Overcoming the Equivalent Mutant Problem*, IEEE TSE
  40(1), 2014. https://doi.org/10.1109/TSE.2013.44
  Detection of equivalent mutants is never complete; prove them, and report
  killed / (total minus proven-equivalent).
- [V8] Jasper et al., *BugGen: A Self-Correcting Multi-Agent LLM Pipeline for
  Realistic RTL Bug Synthesis*, arXiv 2025. https://arxiv.org/abs/2506.10501
  LLM-planted realistic bugs exposed 104 that existing regressions missed.

**AI-assisted verification**

- [V9] Zhang et al., *LLM4DV: Using Large Language Models for Hardware Test
  Stimuli Generation*, arXiv 2023. https://arxiv.org/abs/2310.04535
  LLMs prompted with uncovered bins generate stimuli to hit them.
- [V10] Kande et al., *(Security) Assertions by Large Language Models*, IEEE
  TIFS 2024. https://arxiv.org/abs/2306.14027
  LLM-drafted assertions are often subtly wrong; keep only those confirmed
  by simulation or proof.

**Formal and ISA specification**

- [V11] Reid et al., *End-to-End Verification of ARM Processors with
  ISA-Formal*, CAV 2016. https://doi.org/10.1007/978-3-319-41540-6_3
  Machine-readable ISA spec compiled to Verilog; model checker proves each
  retiring instruction matches it.
- [V12] Armstrong et al., *ISA Semantics for ARMv8-A, RISC-V, and
  CHERI-MIPS* (Sail), POPL 2019. https://doi.org/10.1145/3290384
  One executable ISA spec as the single source of truth for emulators and
  proofs: the role `model/isa.ml` plays here.
- [V13] Singh, Lin, Barrett, Mitra, *Logic Bug Detection and Localization
  Using Symbolic Quick Error Detection*, arXiv 2017.
  https://arxiv.org/abs/1711.06541
  Self-consistency checks with bounded model checking; finds bugs without a
  reference model, so it catches spec misreadings the model and RTL share.
- [V14] Ray, Devlin, Quah, Yesantharao, *Hardcaml: An OCaml Hardware
  Domain-Specific Language for Efficient and Robust Design*, arXiv 2023.
  https://arxiv.org/abs/2312.15035
  Jane Street's own paper on the toolchain this chip is written in.

## Programmable I/O

- [P1] May, *The XMOS Architecture and XS1 Chips*, IEEE Micro 32(6), 2012.
  https://research-information.bris.ac.uk/en/publications/the-xmos-architecture-and-xs1-chips/
  Ports, timers and events as ISA resources; conditional pin input is the
  nearest precedent for our timed waits.
- [P2] Nallin et al., *Exploring Embedded Systems' Dedicated Cores for
  Real-Time Applications*, ICALEPCS 2019.
  https://proceedings.jacow.org/icalepcs2019/papers/wempr003.pdf
  Measured PRU latency and jitter; keep program and data on the
  deterministic path, as our flop-based program memory does.
- [P3] Ubicom/Scenix SX *Virtual Peripherals* (community mirror).
  https://pic.hallikainen.org/techref/scenix/virtperf.htm
  The original software-peripheral idea, and its flaw: one shared CPU
  produces cross-task jitter that dedicated state machines avoid.
- [P4] Raspberry Pi, *RP2040 Datasheet*, chapter 3 (PIO).
  https://datasheets.raspberrypi.com/rp2040/rp2040-datasheet.pdf
  The baseline ISA. WAIT has no timeout; open-drain is emulated.
- [P5] Raspberry Pi, *RP2350 Datasheet*, chapter 11 (PIO), §11.1.1 "Changes
  from RP2040". https://datasheets.raspberrypi.com/rp2350/rp2350-datasheet.pdf
- [P6] Texas Instruments, *PRU Assembly Instruction User Guide* (SPRUIJ2) and
  *PRU Read Latencies* (SPRACE8A). https://www.ti.com/lit/pdf/spruij2 ·
  https://www.ti.com/lit/sprace8
  Hardware LOOP compares to our counter loops; TI warns its wait-for-bit can
  spin forever, which is the case for our timeouts.
- [P7] XMOS, *The XMOS XS3 Architecture* and *AN03000: XCORE Input and
  Output*. https://www.xmos.com/download/The-XMOS-XS3-Architecture.pdf
- [P8] Starkey et al., *Experimental timing and control using
  microcontrollers*, Rev. Sci. Instrum. 95, 2024.
  https://arxiv.org/abs/2406.17603
  Rigorous RP2040 PIO jitter measurements: the method to copy when the chip
  comes back.
- [P9] *Pico-PIO-USB* (open source). https://github.com/sekigon-gonnoc/Pico-PIO-USB
  USB low/full speed in 3 PIO state machines and 32 instructions: a budget
  for our USB stretch goal.
- [P10] *rv003usb* (open source). https://github.com/cnlohr/rv003usb
  Software low-speed USB and how tight its timing is.
- [P11] *Pico-10BASE-T* (open source). https://github.com/kingyoPiyo/Pico-10BASE-T
  Transmit-only 10BASE-T from PIO; receive (Manchester clock recovery) is the
  hard half.

## Open silicon

- [S1] Venn et al., *Tiny Tapeout: A Shared Silicon Tapeout Platform
  Accessible to Everyone*, IEEE Solid-State Circuits Magazine, 2024.
  https://ieeexplore.ieee.org/document/10584359
- [S2] Shalan, Edwards, *Building OpenLANE: A 130nm OpenROAD-based
  Tapeout-Proven Flow*, ICCAD 2020.
  https://github.com/The-OpenROAD-Project/OpenLane
- [S3] IHP, *Open Source PDK (SG13G2)*. https://github.com/IHP-GmbH/IHP-Open-PDK

## Why speed matters to the people running the competition

Jane Street's hardware team builds FPGAs and ASICs for low-latency trading.
These finance papers (from SSRN) explain the economics behind that.

- [F1] Aquilina, Budish, O'Neill, *Quantifying the High-Frequency Trading
  "Arms Race"*, QJE 2022.
  https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3636323
  Latency-arbitrage races last microseconds and make up about 20% of volume.
- [F2] Baron, Brogaard, Hagströmer, Kirilenko, *Risk and Return in
  High-Frequency Trading*. https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2433118
  Relative latency rank, not absolute speed, explains profits.
- [F3] Budish, Cramton, Shim, *The High-Frequency Trading Arms Race*, QJE
  2015. https://ideas.repec.org/a/oup/qjecon/v130y2015i4p1547-1621.html
- [F4] Laughlin, Aguirre, Grundfest, *Information Transmission between
  Financial Markets in Chicago and New York*.
  https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2227519
- [F5] Shkilko, Sokolov, *Every Cloud Has a Silver Lining: Fast Trading,
  Microwave Connectivity and Trading Costs*, J. Finance 2020.
  https://papers.ssrn.com/sol3/papers.cfm?abstract_id=2848562
- [F6] Brogaard, Hagströmer, Nordén, Riordan, *Trading Fast and Slow:
  Colocation and Liquidity*, RFS 2015.
  https://ideas.repec.org/a/oup/rfinst/v28y2015i12p3407-3443..html
  Speed bought by market makers improved liquidity for everyone.
