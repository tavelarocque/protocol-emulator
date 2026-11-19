#!/usr/bin/env bash
# Re-run every check behind the claims in docs/submission.md, in order, and
# print one line per claim. Stops at nothing: a failed stage is reported and
# the rest still run. Exit status is the number of failed stages.
#
#   ./reproduce.sh          everything that needs no layout build
#   ./reproduce.sh quick    skip the OCaml suite (random tests and the proof, the long part)
#
# Needs: opam with the packages in the README, z3, python3, Icarus Verilog,
# and `pip install -r test/requirements.txt`. With sigrok-cli installed, the
# cocotb stage also has sigrok's decoders judge SWD, PS/2, CAN and every
# protocol added on v2.0. With yowasp-yosys installed (pip), the memory the
# proofs use is proven equal to IHP's model of the SRAM macro. The board
# emulation (Verilator,
# Node 22) and the RTL-to-netlist proof (a layout build's netlist) run only
# in CI; section 8 of docs/design-and-verification.md has their commands.
set -u
cd "$(dirname "$0")"
mode="${1:-full}"
dune() { if command -v dune >/dev/null 2>&1; then command dune "$@"; else opam exec -- dune "$@"; fi; }
log=_reproduce; mkdir -p "$log"
fails=0; summary=""
stage() { # stage <id> <claim> <command...>
  local id="$1" claim="$2"; shift 2
  local t0=$SECONDS
  printf '%-10s %s ... ' "$id" "$claim"
  if "$@" >"$log/$id.log" 2>&1; then r=ok; else r=FAIL; fails=$((fails+1)); fi
  printf '%s (%ds)\n' "$r" $((SECONDS-t0))
  summary="$summary$r  $id  $claim\n"
}
missing=""
for t in python3 z3 iverilog; do command -v $t >/dev/null 2>&1 || missing="$missing $t"; done
command -v dune >/dev/null 2>&1 || command -v opam >/dev/null 2>&1 || missing="$missing dune/opam"
[ -n "$missing" ] && echo "missing tools:$missing (stages that need them will fail)"

examples() { for f in examples/*.s; do _build/default/bin/pe_sim.exe asm "$f" >/dev/null || return 1; done; }
blind() { for s in 1 2 3; do PE_SIM=_build/default/bin/pe_sim.exe python3 examples/ws2812/accept.py examples/ws2812 $s || return 1; done; }
cocotb() { make -C test clean >/dev/null 2>&1; (cd test && make && python3 -m cocotb_tools.check_results results.xml); }

stage build    "RTL, firmware images and examples build from source"       dune build
if [ "$mode" != quick ]; then
stage ocaml    "ISA, lockstep, coverage, firmware and the whole-chip proof" dune runtest --force
fi
stage examples "every example program assembles"                           examples
stage memory   "the memory in the proofs equals IHP's model of the SRAM"   python3 formal/sram_equiv.py
stage figures  "timing diagrams match the reference model"                 python3 docs/figures.py --check
stage blind    "blind-written WS2812 firmware passes its hidden test"      blind
stage drift    "generated files match the committed copies"                git diff --exit-code src/ test/ examples/
stage cocotb   "chip-level tests, third-party devices and the host driver" cocotb

printf '\n%b' "$summary"
echo "logs: $log/"
exit $fails
