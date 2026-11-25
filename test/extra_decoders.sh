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

rm -rf "$OUT"
mkdir -p "$OUT"
cp -r "$SRC/libsigrokdecode/decoders/." "$OUT/"
mkdir "$OUT/sent_ext" "$OUT/dshot_ext"
cp "$SRC/sent/__init__.py" "$SRC/sent/pd.py" "$SRC/sent/crc4.py" "$OUT/sent_ext/"
cp "$SRC/dshot/__init__.py" "$SRC/dshot/pd.py" "$OUT/dshot_ext/"
cp -r "$SRC/i3c/i3c" "$OUT/i3c_ext"
echo "extra decoders in $OUT"
