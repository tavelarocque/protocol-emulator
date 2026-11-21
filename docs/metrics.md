# Layout metrics

From the GDS build reports. Timing is checked at each build's target clock
at the worst (slow, hot) corner: 50 MHz (20 ns) for the 6x4 builds, 40 MHz
(25 ns) for v1.4 on the ttihp27a flow, and 50 MHz again from v2.0 on. The
firmware and the tests in this repository run the chip at 10 MHz, 12 MHz
for USB and 40 MHz for Ethernet.

| Design | Std cells | Utilisation (6x4; last four rows 8x4) | Setup slack | Hold slack |
|--------|-----------|-------------------|-------------|------------|
| UART bring-up | 328 | 0.5% | +12.4 ns | +0.17 ns |
| Full chip v0 (SPI + 1-thread core, 32 words) | 8,002 | 12.5% | +6.3 ns | +0.14 ns |
| Full chip v1.1 (1 thread, 64 words, side-set) | 11,838 | 19.1% | +3.87 ns | +0.13 ns |
| Full chip v1.3 (2 threads, divider, CHAIN, input synchronisers) | 17,665 | 27.2% | +0.77 ns | +0.12 ns |
| Full chip v1.4 (adds shift direction), first build | 18,830 | 28.3% | **−0.14 ns** | +0.12 ns |
| Full chip v1.4, current build (same logic; registers named for the formal proofs) | 18,817 | 28.3% | +1.19 ns | +0.12 ns |
| Full chip v1.4 on the ttihp27a flow, 8x4, 25 ns target (the layout on `main`) | 17,925 | 20.8% | +6.85 ns | +0.12 ns |
| **Full chip v2.0** (program memory in two SRAM macros), 8x4, 20 ns target | 10,359, and 2 macros | 13.4% | about +4 ns | met |
| Full chip v2.1 (adds the packet buffer in a third macro, autopull and autopush, the CRC register), 8x4, 20 ns target | 13,787, and 3 macros | 22.9% | met | met |
| Full chip v2.2 (adds the bit sampler), 8x4, 20 ns target | 14,083, and 3 macros | 23.3% | met | met |
| **Full chip v2.3** (adds the sampler's prescaler, pin shift and stuff-bit removal), 8x4, 20 ns target | 14,837, and 3 macros | 23.8% | met | met |

The first v1.4 build missed 50 MHz by 0.14 ns on one path, at the slow
corner only (1.08 V, 125 °C). The current build, the same logic with its
registers named for the formal proofs, meets 50 MHz at every corner with
1.19 ns to spare at the slow one. A 1.3 ns swing with no logic change is
placement varying from one layout run to the next, so 50 MHz is not claimed:
the chip is specified for 10 MHz (100 ns, about 80 ns of slack in every
build). The 20 ns target was left as it was rather than relaxed to make the
report clean, until the move to Tiny Tapeout's ttihp27a flow, the one the
IHP shuttle uses. That flow's LibreLane (3.1.0.dev4) changed its default
synthesis strategy from AREA 0 to DELAY 4, which buffers and duplicates
logic: the same RTL routed with 4.4 m of wire rather than 1.5 m. On 6x4
tiles, one such build failed setup, two were still detail-routing when
GitHub stopped them at 6 hours, and one routed in over 5 hours and then
failed setup at the slow corner even at 25 ns. The older LibreLane cannot be
pinned: on this flow it has no CMOS5L support. The layout now sets
`SYNTH_STRATEGY` back to AREA 0 and takes the 8x4 tiles the competition
allows: 17,925 cells at 20.8% utilisation, 0.97 m of wire, routed with no
violations in under 3 hours, no setup or hold violations at any corner. The
target is 25 ns (40 MHz, still more than three times the 12 MHz USB needs)
for margin.

On v1.4, one signoff warning remains and is left in. At the slow corner only (1.08 V,
125 C), 36 pins on 9 high-fanout nets switch more slowly than the cell
library's limit: 3.33 ns at worst against 2.51 ns. The typical and fast
corners are clean, and setup slack at that same slow corner is +6.85 ns.
Two repairs were tried and measured: a second repair pass after global
routing, which found nothing because the resizer checks the typical corner,
and a 40% repair margin, which resized 17 nets, added an hour to the build
and did not clear the warning. Neither is kept. Two more were tried on
branches: a buffer every 200 um of wire (`slew-wirelen`), whose layout was
still running when GitHub stopped it at 6 hours, and repair at all three
corners with a fan-out limit of 8 (`slew-corners`), which finished in 3
hours with the same warning at the same corner.

Every v1.4 build has 0 DRC and 0 LVS errors and passes the
Tiny Tapeout precheck and the cocotb suite on the gate-level netlist,
including the third-party controller tests that drive the chip as an I2C and
an SPI device; from the current build on, the netlist is also formally
proven equal to the RTL. On 6x4 tiles a two-thread layout took
4 to 5 hours, most of it detailed routing (v1.1 took 91 minutes); on 8x4 it
takes under 3.

## v2.0: the program memory in SRAM

v1.4 kept its program in flip-flops: 64 words of 16 bits, 1,024 of the
chip's 1,796 flip-flops, read through two 64-way multiplexers. Two
measurements showed that memory could not grow. A flip-flop memory of 256
words with 16-deep FIFOs (`spike-256`) placed at 52% utilisation and then
could not be routed: 6.7 m of wire, Metal3 at 153% of its capacity, and
detailed routing stopped by GitHub at 6 hours. The same at 128 words with
the FIFOs left alone (`spike-128`) was also stopped at 6 hours. A design
on this shuttle gets a single horizontal signal layer, and the read
multiplexers of a memory that size need more of it than there is.

v2.0 puts each thread's program in one of IHP's SRAM macros
(`RM_IHPSG13_1P_256x16_c2_bm_bist`, 256 words of 16 bits), placed and
powered with Tiny Tapeout's SRAM example. A thread can now run a program
four times as long, and the two threads no longer share: eight times the
memory in all. The layout got smaller and faster:

| | v1.4 | v2.0 |
|---|---|---|
| Program memory | 64 words, shared, flip-flops | 256 words per thread, SRAM |
| Standard cells | 17,925 | 10,359 |
| Flip-flops | 1,796 | 796 |
| SRAM macros | none | 2, each 2% of the die |
| Utilisation | 20.8% | 13.4% |
| Wire | 0.97 m | 0.44 m |
| Layout time (the gds job) | under 3 hours | 20 to 30 minutes |
| Clock target met at every corner | 25 ns | 20 ns |

The 10,359 cells are 796 flip-flops, 6,847 gates of more than one input,
484 inverters, 2,060 buffers the tools added to repair timing, 139 clock
buffers and inverters, 23 other buffers and 10 antenna diodes. The power
report gives 3.2 mW at 50 MHz.

**The clock target was chosen by measurement.** The same RTL was laid out
at three targets. All three met setup and hold at all three corners with
no violations:

| Target | Slack between flip-flops, slow corner | Reported power |
|---|---|---|
| 25 ns (40 MHz) | about 9 ns | 2.6 mW |
| 20 ns (50 MHz) | about 4 ns | 3.2 mW |
| 16 ns (62.5 MHz) | under 1 ns | 4.0 mW |

The slack figures are approximate because the build log cuts the table's
digits off; the exact numbers are in each build's report files. 20 ns is
the target kept: it leaves a margin that 16 does not. The lesson from v1.4
stands, that slack within about a nanosecond moves from one layout run to
the next, so 62.5 MHz is not claimed. 50 MHz is what static timing
analysis says the layout can do, not something a test has shown: the
simulations have no gate delays in them, whatever clock they run.

**Signoff warnings on v2.0, not yet explained.** The checker reports
maximum-slew and maximum-capacitance warnings at all three corners, where
v1.4 had a slew warning at the slow corner only and none for capacitance.
Before repair the tools counted 32 slew and 10 capacitance violations; the
final table shows 4 capacitance violations at each corner. That they appear
at every corner and arrived with the macros points at the SRAM's pins, but
this has not been confirmed from the report files. Setup and hold are
unaffected: no violations at any corner.

On v2.0, LVS and the antenna check pass in the layout flow, and the Tiny
Tapeout precheck passes: it runs IHP's KLayout design-rule deck on the
finished layout. The flow's own Magic design-rule step is switched off,
because Magic flags the insides of the SRAM macro. Its overlap check
counts 52 illegal overlaps, all at the macros: Magic reads a macro from
its outline, not its contents, and sees the power stripes that cross it as
overlapping it. Tiny Tapeout's SRAM example sets the same two options. The
whole cocotb suite passes on the gate-level netlist with IHP's own model
of the SRAM, and the netlist is proven equal to the RTL after every
layout.

## v2.1 to v2.3: the packet buffer, the bit sampler and its settings

Two revisions added hardware for 10 Mbit Ethernet
([`isa.md`](isa.md), revision history). v2.1 added a third SRAM macro,
`RM_IHPSG13_1P_1024x16_c2_bm_bist`, 1024 words of 16 bits, as the packet
buffer, with the logic that plays it and records into it, the automatic
refill of the shift registers and a 32-bit CRC register for each thread.
v2.2 added the bit sampler.

v2.3 gave the sampler three settings, for CAN: a prescaler, a pin shift
and stuff-bit removal.

| | v2.0 | v2.1 | v2.2 | v2.3 |
|---|---|---|---|---|
| Standard cells | 10,359 | 13,787 | 14,083 | 14,837 |
| Flip-flops | 796 | 1,022 | 1,076 | 1,107 |
| SRAM macros | 2 | 3 | 3 | 3 |
| Utilisation | 13.4% | 22.9% | 23.3% | 23.8% |
| Wire | 0.44 m | 0.69 m | 0.70 m | 0.75 m |
| Reported power at 50 MHz | 3.2 mW | 4.1 mW | 4.3 mW | 4.5 mW |
| Setup and hold at 20 ns, every corner | met | met | met | met |
| Detailed routing, first run | 5 passes | 6 passes, then the router jumped to its 17th setting | 5 passes | 5 passes |
| Detailed routing time | about 12 minutes | 30 minutes | 18 minutes | 18 minutes |
| Layout time (the gds job) | 20 to 30 minutes | 37 minutes | 37 minutes | 42 minutes |

The 14,837 cells of v2.3 are 1,107 flip-flops, 9,771 gates of more than
one input, 793 inverters, 2,913 buffers the tools added to repair timing,
191 clock buffers and inverters, 23 other buffers and 39 antenna diodes.
Most of what v2.1 added is registers and the multiplexers that read them:
each thread's CRC register, polynomial and start value are 96 flip-flops.
The bit sampler was 54 flip-flops and about 300 cells in all on v2.2.
v2.3 added 31 flip-flops: 15 in the sampler (a 10-bit count for the
prescaler, a 4-bit run length and the level of the run) and its new
16-bit register. The cell count rose by 754, of which 389 are inverters
(404 on v2.2, 793 now) and 275 are gates. That is more than the new logic
needs, and why synthesis chose so many more inverters has not been looked
into.

**Routing has less room than the utilisation suggests.** v2.1's and
v2.2's placements both began with about 5% of the router's tiles over
capacity and v2.3's with about 6%, where v2.0's began with 0.5%. v2.1's detailed routing did not
clear its violations in its usual passes and the router escalated to a
later, more aggressive setting before it did; v2.2 and v2.3, each
slightly larger, cleared them in the same five passes as v2.0. That difference is one
placement against another, not a trend: the lesson from v1.4 is that
layout runs vary, and a design this close to a hard run can have one.

**The falling-edge flip-flop.** The bit sampler takes one sample of its
pin on the falling clock edge; every other flip-flop in the chip is on the
rising edge. The cell library has no falling-edge flip-flop, so synthesis
used the ordinary one behind a clock inverter. Static timing analysis
checks the half-cycle paths into it (from the pin, and from the register
that selects the pin) and out of it (to the rising-edge flip-flop that
takes its value), and reports no setup or hold violation at any corner.

**Exact slack is not known for v2.1, v2.2 and v2.3.** The checker reports no
violations at 20 ns at any corner, and that is what the table says. The
build log cuts the slack figures off, and the report files of these
three builds have not been read. Ethernet needs 40 MHz, 25 ns, so it has at
least 5 ns more than whatever the 20 ns figure is.

**The same warnings as v2.0.** Maximum-slew and maximum-capacitance
warnings are reported at all three corners in all three builds, still
unexplained. The overlap check counts 78 illegal overlaps on v2.1 and 80
on v2.2 and on v2.3, where v2.0 with two macros had 52. Twenty-six for each macro
accounts for 78 and not for 80, so that is not the whole explanation;
which shapes the other two are has not been looked up. LVS, the antenna
check and the Tiny Tapeout precheck, which runs IHP's KLayout design-rule
deck on the whole layout, pass on all three.

After each of the three layouts the netlist is proven equal to the RTL
(1,538 signals on v2.3: every output, all 1,107 flip-flops and every pin
of the three memories), and the whole cocotb suite, 76 tests on v2.3,
passes on the gate-level netlist, the Ethernet tests at a 40 MHz clock.
Those simulations have no gate delays in them: the speed rests on static
timing analysis.
