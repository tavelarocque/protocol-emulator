# The 13 surviving mutants, classified

Method: each survivor and its original were rerun through the hidden accept.py with a logging pe_sim that saved every simulator output (14 to 16 runs per protocol, the same cases the judge uses). The outputs were compared edge by edge: same sequence of pin values or not, and how far each edge moved. Each change was then read against the task sheet's limits. Scripts: classify/classify.py, cmp.py, iv.py.

Result: 2 make no change on the wire on any judged case; 11 change timing or merge edges but stay inside the task sheet's limits. No survivor breaks a rule of its task sheet, so no judge gap was found.

| protocol | mutant | change | on the wire | task sheet limit | class |
|---|---|---|---|---|---|
| dcf77 | 2 | `in y, 1` to `in y, 2` | identical on all 15 runs | n/a | no change |
| dcf77 | 4 | `wait 1 pin 0` to `wait 0 pin 0` | identical on all 15 runs (the stimulus never makes the two differ) | n/a | no change |
| flexray | 0, 1, 3 | one delay of 3 or 1 changed by 1 | one interval per frame 1 cycle longer or shorter | every edge within +-1 cycle of ideal | within tolerance |
| maple_bus | 2, 4 | a delay of 15 to 14 | idle between frames 1 cycle shorter (113 and 144 to 112 and 143) | idle 100 to 50000 cycles | within tolerance |
| rc_encode | 4 | wait-loop delay 7 to 6 | first frame's first rise 9200 cycles earlier (76001 to 66801) | first rise in cycles 50000 to 100000 | within tolerance |
| usb_power_delivery | 4 | gap counter 31 to 30 | gap between packets 16 cycles shorter (556 to 592 become 540 to 576) | gap at least 500 cycles | within tolerance |
| t55xx | 3 | a delay of 7 to 6 | write gaps 40 cycles shorter (1440 to 1400) | write gap 800 to 2400 | within tolerance |
| t55xx | 2 | `side 0` to `side 1` on a branch | one extra 80-cycle carrier period before some gaps; that bit 80 longer, the gap 80 shorter | bit and gap ranges (judge checks both) | within tolerance |
| iec | 2 | `side 0` to `side 1` after each bit | CLK falls 1 cycle later, in the same cycle as the next DATA change (edges merge) | "DATA may change in the same cycle as a CLK fall"; fall to fall 40 to 100 | within tolerance |
| iec | 3 | `side 1` to `side 0` at idle | CLK released 1 cycle later at the end | no limit that tight | within tolerance |

What this says about the judges: they are as strict as the task sheets, and the sheets give real protocols' tolerances, so a one-tick change in idle, setup or margin code is usually legal. The 86% kill rate is a floor on judge strength, not a sign of weak judges. One note for the write-up: dcf77 mutant 4 is equivalent only because every judged stimulus starts with the line in the same state.
