Behavioural models of the IHP SRAM macro, copied unmodified from
IHP-Open-PDK (ihp-sg13g2/libs.ref/sg13g2_sram/verilog, commit 89d42ee6, which
ihp-sg13cmos5l/libs.ref/sg13cmos5l_sram links to). Apache-2.0, (c) IHP PDK Authors.
Used for RTL and gate level simulation only.

RM_IHPSG13_1P_1024x16_c2_bm_bist.v, the packet buffer's macro, is from the
same directory at commit e73adb40, also unmodified. It wraps the same
behavioural core as the 256-word macro, with a 10-bit address.
