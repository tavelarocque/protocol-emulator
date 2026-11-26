#!/usr/bin/env bash
# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
#
# Rebuild the decoder folder that judged round 2, Part A: sigrok-cli 0.7.2's
# own decoders (libsigrokdecode 0.5.3), DSView's decoders at 2e9e2c8 named
# by decoder id, libsigrokdecode's ir_irmp at 71f45144, then the examiners'
# mechanical ports (ports.diff). Needs git and sigrok-cli 0.7.2.
#
#   flex/census2/fetch_decoders.sh [OUT]     # default OUT: flex/census2/decoders
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
out=$(mkdir -p "${1:-$here/decoders}" && cd "${1:-$here/decoders}" && pwd)
sys=${SIGROK_SYSTEM_DECODERS:-/usr/share/libsigrokdecode/decoders}
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

cp -r "$sys"/. "$out"/

git clone -q --filter=blob:none --no-checkout https://github.com/DreamSourceLab/DSView.git "$tmp/dsview"
git -C "$tmp/dsview" sparse-checkout set libsigrokdecode4DSL/decoders
git -C "$tmp/dsview" checkout -q 2e9e2c8e726df4ef5687d39b83d4f797cc44b574
dsl=$tmp/dsview/libsigrokdecode4DSL/decoders
# DSView folder -> decoder id
while IFS='|' read -r from id; do
  rm -rf "${out:?}/$id"; cp -r "$dsl/$from" "$out/$id"
done <<'MAP'
c2|C2
mipi_dsi|MIPI_DSI
can-fd|can-fd
eth_an|eth_auto_negotiation
fsi|fsi
mipi_rffe|mipi_rffe
pxx1|pxx1
qspi|qspi
smart qspi|smart_qspi
st7789|st7789
MAP

git clone -q --filter=blob:none --no-checkout https://github.com/sigrokproject/libsigrokdecode.git "$tmp/lsd"
git -C "$tmp/lsd" sparse-checkout set decoders/ir_irmp
git -C "$tmp/lsd" checkout -q 71f451443029322d57376214c330b518efd84f88
rm -rf "${out:?}/ir_irmp"; cp -r "$tmp/lsd/decoders/ir_irmp" "$out/ir_irmp"

find "$out" -name __pycache__ -prune -exec rm -rf {} +
(cd "$out" && patch -s -p1 < "$here/ports.diff")
echo "decoders in $out"
