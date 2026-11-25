#!/usr/bin/env bash
# Fetches the sigrok protocol decoders that the packaged sigrok-cli 0.7.2
# does not ship, each at a fixed commit, into test/extra_decoders/. The tests
# that use them (sigrok.Trace.decode with extra=True) run sigrok-cli with
# SIGROKDECODE_DIR pointing there; every other test uses the packaged ones.
# Nothing here is part of the chip, and nothing is copied into this
# repository: the decoders keep their own licences (GPL-3.0 for sigrok's,
# the DShot and I3C decoders; MIT for the SENT decoder).
#
#   libsigrokdecode  sigrok's own decoder source, newer than the 0.5.3
#                    package: AD5626, AD79x0, ADXL345, LTC242x, LTC26x7,
#                    MCP230xx, nRF905, ST25R39xx, Sony SIRC, SAE J1850 VPW,
#                    XY2-100, SDQ, caliper, cJTAG, PJDL, PJON, SLE44xx ...
#   sent-decoder     SAE J2716 SENT, by enp6s0
#   dshot            DShot, by hyp0dermik-code
#   i3c              MIPI I3C, by xyphro
#   sigrok pull requests not merged: #28 MIL-STD-1553 (Michel Pollet),
#                    #82 SpaceWire (Theo Hussey), #88 TPM TIS over SPI
#                    (Tobias Peter), #136 SMPTE linear timecode (Simon Wood)
#   iso7816          ISO 7816-3 smart cards, by svenso and by arthursimas1
#   arinc429         ARINC 429, by Aleksandr-Kai and by FrancescoTalotta
#   spi_tpm          TPM over SPI, by ghecko
#   knx              KNX TP1, by mwalle and by the selfbus project
#   mvb              IEC 61375 Multifunction Vehicle Bus, by yeckel
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/extra_decoders"
SRC="$HERE/extra_decoders.src"

fetch() {  # fetch NAME URL COMMIT
    local dir="$SRC/$1"
    if [ "$(git -C "$dir" rev-parse HEAD 2>/dev/null || true)" != "$3" ]; then
        rm -rf "$dir"
        git init -q "$dir"
        git -C "$dir" fetch -q --depth 1 "$2" "$3"
        git -C "$dir" checkout -q FETCH_HEAD
    fi
    [ "$(git -C "$dir" rev-parse HEAD)" = "$3" ]
}

mkdir -p "$SRC"
fetch libsigrokdecode https://github.com/sigrokproject/libsigrokdecode 71f451443029322d57376214c330b518efd84f88
fetch sent https://github.com/enp6s0/sent-decoder 620dd1fa794dce75e35781e350bea18e2424ca17
fetch dshot https://github.com/hyp0dermik-code/sigrok-decoder-dshot 7145f2aa1db97c84d49417507a69e40c491ca574
fetch i3c https://github.com/xyphro/Sigrok-I3C-decoder 0b43721ec0e52f79bdacb6453bbd6dec28907679
L=https://github.com/sigrokproject/libsigrokdecode
fetch pr28 "$L" 535d50a9efe8fad94c13971e2937ff720c8badba
fetch pr82 "$L" 04d7ea2c1f8a16b35461376c7b1eaa2d2719b202
fetch pr88 "$L" 032306cc35ec31130b1e4ec1946e64de2fb73ff1
fetch pr136 "$L" 176102a0c7d4ca1e4d91c101153e06a34b92b57c
fetch iso_svenso https://github.com/svenso/sigrok_iso7816 e364a79b4d58a40905e4dfce2f445ada00a72ec8
fetch iso_arthur https://github.com/arthursimas1/sigrok_iso7816 32ab9c32371f61c9b292c77a7508d5ba690ac8d1
fetch a429_kai https://github.com/Aleksandr-Kai/DSView_ARINC429_Decoder d19f65c0d98eb4f6c09008a3b1efa312553e5109
fetch a429_ft https://github.com/FrancescoTalotta/ARINC-429 9aee7981c4b84d5bd44facd49e69422464463b45
fetch tpm_ghecko https://github.com/ghecko/libsigrokdecoder_spi-tpm 663bd8b9474318fcf8fd99a7f2db40f92ba543b6
fetch knx_mwalle https://github.com/mwalle/libsigrokdecode-knx-tp1 fa752b0f3c164848ef3d843772995e51a4e57726
fetch knx_selfbus https://github.com/selfbus/development-tools 49240e349ce0aa313442ce3c1ecec65188837b18
fetch mvb https://github.com/yeckel/sigrok_mvb_decoder 5b7119c3117065ab4d47f8c5a16f9099fa34767d

rm -rf "$OUT"
mkdir -p "$OUT"
cp -r "$SRC/libsigrokdecode/decoders/." "$OUT/"
# sigrok-cli loads a decoder by importing the folder named as the id it is
# given, so a folder must have its decoder's id for its name.
mkdir "$OUT/sae_j2716_sent" "$OUT/dshot"
cp "$SRC/sent/__init__.py" "$SRC/sent/pd.py" "$SRC/sent/crc4.py" "$OUT/sae_j2716_sent/"
cp "$SRC/dshot/__init__.py" "$SRC/dshot/pd.py" "$OUT/dshot/"
cp -r "$SRC/i3c/i3c" "$OUT/i3c"
for d in mil-std-1553:pr28 spacewire:pr82 tpm_tis_spi:pr88 tpm_fifo_tis:pr88 ltc:pr136; do
    cp -r "$SRC/${d#*:}/decoders/${d%%:*}" "$OUT/${d%%:*}"
done
copy_py() {  # copy_py ID FROM_DIR: the decoder's Python files only
    mkdir -p "$OUT/$1"
    cp "$2"/*.py "$OUT/$1/"
    rm -f "$OUT/$1"/test_*.py
}
copy_py iso7816 "$SRC/iso_svenso"
copy_py arthur_iso7816 "$SRC/iso_arthur"
copy_py arinc429 "$SRC/a429_kai"
# This one ships without the package file every decoder folder needs.
[ -e "$OUT/arinc429/__init__.py" ] || echo "from .pd import Decoder" > "$OUT/arinc429/__init__.py"
# The second ARINC 429 decoder's id differs only in case: on a filesystem
# that ignores case the two folders would be one, so it is left out there.
[ -e "$OUT/ARINC429" ] || copy_py ARINC429 "$SRC/a429_ft/sigrok"
copy_py spi_tpm "$SRC/tpm_ghecko"
copy_py spi_tpm_sniff "$SRC/tpm_ghecko/spi_tpm_sniff"
copy_py knx-tp1 "$SRC/knx_mwalle"
copy_py knx "$SRC/knx_selfbus/sigrok/decoders/knx"
copy_py mvb "$SRC/mvb/mvb"
echo "extra decoders in $OUT"
