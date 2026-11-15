# Layout metrics

From the GDS build reports. Timing is checked at the flow's target clock,
50 MHz (20 ns) for the builds below and 40 MHz (25 ns) from the ttihp27a
flow on, at the worst (slow, hot) corner; the chip is specified for 10 MHz.

| Design | Std cells | Utilisation (6x4; last row 8x4) | Setup slack | Hold slack |
|--------|-----------|-------------------|-------------|------------|
| UART bring-up | 328 | 0.5% | +12.4 ns | +0.17 ns |
| Full chip v0 (SPI + 1-thread core, 32 words) | 8,002 | 12.5% | +6.3 ns | +0.14 ns |
| Full chip v1.1 (1 thread, 64 words, side-set) | 11,838 | 19.1% | +3.87 ns | +0.13 ns |
| Full chip v1.3 (2 threads, divider, CHAIN, input synchronisers) | 17,665 | 27.2% | +0.77 ns | +0.12 ns |
| Full chip v1.4 (adds shift direction), first build | 18,830 | 28.3% | **−0.14 ns** | +0.12 ns |
| Full chip v1.4, current build (same logic; registers named for the formal proofs) | 18,817 | 28.3% | +1.19 ns | +0.12 ns |
| Full chip v1.4 on the ttihp27a flow, 8x4, 25 ns target (the layout submitted) | 17,925 | 20.8% | +6.85 ns | +0.12 ns |

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

One signoff warning remains and is left in. At the slow corner only (1.08 V,
125 C), 36 pins on 9 high-fanout nets switch more slowly than the cell
library's limit: 3.33 ns at worst against 2.51 ns. The typical and fast
corners are clean, and setup slack at that same slow corner is +6.85 ns.
Two repairs were tried and measured: a second repair pass after global
routing, which found nothing because the resizer checks the typical corner,
and a 40% repair margin, which resized 17 nets, added an hour to the build
and did not clear the warning. Neither is kept.

Every v1.4 build has 0 DRC and 0 LVS errors and passes the
Tiny Tapeout precheck and the cocotb suite on the gate-level netlist,
including the third-party controller tests that drive the chip as an I2C and
an SPI device; from the current build on, the netlist is also formally
proven equal to the RTL. On 6x4 tiles a two-thread layout took
4 to 5 hours, most of it detailed routing (v1.1 took 91 minutes); on 8x4 it
takes under 3.
