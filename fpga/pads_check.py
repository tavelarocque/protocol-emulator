# SPDX-FileCopyrightText: © 2026 Tave La Rocque
# SPDX-License-Identifier: Apache-2.0
"""Check that every bit of every top-level port reaches a placed pad.

Usage: pads_check.py ROUTED.json EXPECTED_PINS

Reads nextpnr's routed netlist, finds each port bit's pad cell (IBUF,
OBUF, TBUF or IOBUF) and the IO site it was placed on, prints one line per
pin, and fails if a bit has no pad, two bits share a site, or the number
of pins is not the one expected.
"""
import json
import sys

PADS = {"IBUF": "I", "OBUF": "O", "TBUF": "O", "IOBUF": "IO"}


def main(path, expected):
    with open(path) as f:
        modules = json.load(f)["modules"]
    (top,) = modules.values()
    site_of_net = {}
    for cell in top["cells"].values():
        pin = PADS.get(cell["type"])
        if pin is None:
            continue
        bel = cell.get("attributes", {}).get("NEXTPNR_BEL", "unplaced")
        for net in cell["connections"].get(pin, []):
            site_of_net.setdefault(net, []).append(bel)
    bad, seen, count = [], {}, 0
    for name, port in sorted(top["ports"].items()):
        for i, net in enumerate(port["bits"]):
            label = f"{name}[{i}]" if len(port["bits"]) > 1 else name
            count += 1
            sites = site_of_net.get(net, [])
            if len(sites) != 1 or sites[0] == "unplaced":
                bad.append(f"{label}: pads {sites}")
                continue
            if sites[0] in seen:
                bad.append(f"{label}: shares {sites[0]} with {seen[sites[0]]}")
            seen[sites[0]] = label
            print(f"  {label:10} {sites[0]}")
    if count != expected:
        bad.append(f"{count} pins, {expected} expected")
    for b in bad:
        print("FAIL: " + b, file=sys.stderr)
    if bad:
        sys.exit(1)
    print(f"pads: all {count} pins placed")


if __name__ == "__main__":
    main(sys.argv[1], int(sys.argv[2]))
