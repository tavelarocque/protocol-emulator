# Census order

Drawn as `flex/PREREG.md` fixes it.

- Chain: drand default mainnet, 8990e7a9aaed2ffed73dbd7092123d6f289930540d7651336225dc172e51b2ce (genesis 1595431050, period 30 s).
- Round 6674006, timestamp 2026-11-26 00:00:00 UTC: the first round at or after that time (round 6674005 is 23:59:30).
- Randomness: f8c9bf93e8dfd97013298435f853477a0bfd529ed777bfc8b669ebbf0f19c838
- Signature: b54ed5264eded26541a344c5cd7b4d100f54a0afd7e1d73d6c7caa7a87e6d3ae7de50579fa00b5bddebe868b1e82a8210c1433b0f37a396a96ca7a834c7c292ea29d24f9af1d4b1aeeeb8069cf32e242a63d2673208ecb98024bf09a27604dfa
- Read from api.drand.sh and drand.cloudflare.com on 2026-11-26 at 00:24 UTC; both gave the same round. SHA-256 of the signature equals the randomness.
- Order: names sorted by SHA-256 of the randomness in hex, a colon, and the name.

| # | Protocol | SHA-256 prefix |
|---|---|---|
| 1 | ac97 | 024920ba4c7bebaf |
| 2 | ook | 23cee1bbe2cd3e43 |
| 3 | aud | 24a711c150af2dab |
| 4 | rc_encode | 348dcab68e27a18a |
| 5 | lpc | 3942aa5b7a645400 |
| 6 | avr_pdi | 3de59fd0bb7a4f03 |
| 7 | dsi | 433879bdaea9a8a9 |
| 8 | maple_bus | 47408bfa5f68ed50 |
| 9 | em4305 | 48a1d29ea3769b81 |
| 10 | seven_segment | 558a402bffb42b3e |
| 11 | iec | 59fbdca1a768035b |
| 12 | flexray | 64929f8bf3a2366e |
| 13 | usb_power_delivery | 67312813c4b0396a |
| 14 | t55xx | 863e27d4de2f8354 |
| 15 | dcf77 | 8bf1c1dc2e2639f7 |
| 16 | mcs48 | 9115a1ffd027837c (out of reach: 14 lines) |
| 17 | swim | d93eb7dd8cf9e713 |
| 18 | z80 | dd13015076213755 (out of reach: 11 lines) |
| 19 | sda2506 | ed8a625aaa057788 |
| 20 | sdcard_sd | f7f8acf8189e3c82 |

Kit at the draw: every kit's `isa.md` has SHA-256 f2f860f2f6fd4ee9f3b36813dcca66d5a48fc21a82c1b7aedc9ee763f7f9ffc7, the same as `docs/isa.md` on `main` (0aa4814, which includes the reset paragraph of 94507e5); every kit's `pe_sim` has SHA-256 82b00ea2f4208ecdaa20510978a7d5e2e172be983717806be367b617f6baef6c.
