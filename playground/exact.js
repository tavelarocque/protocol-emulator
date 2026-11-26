// The exactness check: the reference model compiled to JavaScript (what
// docs/playground.html runs) against the native pe_sim, on the same
// programs, configurations, TX words and stimuli. Every preset of the
// playground runs both ways, once printing the output register and once
// the wire levels (-lines, what the playground draws), and the two outputs
// must be identical line for line. Every example program must also
// assemble to the same words both ways.
//
// Usage: node exact.js pe_js.bc.js pe_sim.exe presets.json EXAMPLES_DIR
// `dune test` runs it (playground/dune).

"use strict";
const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");

const [model, peSim, presetsFile, examples] = process.argv.slice(2).map((p) => path.resolve(p));
const pe = require(model).peModel;
const presets = JSON.parse(fs.readFileSync(presetsFile, "utf8"));
const dir = fs.mkdtempSync(path.join(os.tmpdir(), "pe-exact-"));
let failures = 0;

function fail(what) {
  failures++;
  console.error("exact.js: " + what);
}

function firstDifference(a, b) {
  const x = a.split("\n"), y = b.split("\n");
  for (let i = 0; i < Math.max(x.length, y.length); i++)
    if (x[i] !== y[i]) return "line " + (i + 1) + ": native " + JSON.stringify(x[i]) + ", JavaScript " + JSON.stringify(y[i]);
  return "none";
}

// The runs.
const coverage = { threads2: [], stimulus: [], long: [], rx: new Set(), firmware: new Set() };
for (const p of presets) {
  const file = (name, text) => { const f = path.join(dir, p.id + "." + name); fs.writeFileSync(f, text); return f; };
  const args = ["run", file("0.s", p.threads[0].source), "-cycles", String(p.cycles), "-inputs", p.inputs, "-bypass", p.bypass];
  if (p.threads[0].config) args.push("-config", p.threads[0].config);
  args.push("-tx", file("0.tx", p.threads[0].tx));
  for (const m of p.modes) args.push("-mode", m);
  if (p.stimulus) args.push("-stimulus", file("stim", p.stimulus));
  if (p.threads[1]) {
    args.push("-thread1", file("1.s", p.threads[1].source), "-tx1", file("1.tx", p.threads[1].tx));
    if (p.threads[1].config) args.push("-config1", p.threads[1].config);
  }
  for (const lines of [false, true]) {
    const native = execFileSync(peSim, lines ? args.concat(["-lines"]) : args, { encoding: "utf8", maxBuffer: 1 << 28 });
    const r = pe.run({ threads: p.threads, modes: p.modes, cycles: p.cycles, inputs: p.inputs, stimulus: p.stimulus, bypass: p.bypass, lines });
    if (!r.ok) { fail(p.id + ": JavaScript run failed: " + r.message); continue; }
    const kind = lines ? "-lines" : "pins";
    if (r.output !== native) fail(p.id + " (" + kind + "): outputs differ, first at " + firstDifference(native, r.output));
    else {
      const n = native.split("\n").length - 1;
      console.log("exact.js: " + p.id.padEnd(8) + " " + kind.padEnd(6) + " " + String(p.cycles).padStart(7) + " cycles, " + String(n).padStart(5) + " lines, identical");
    }
    if (native.split("\n").some((l) => l.startsWith("rx"))) coverage.rx.add(p.id);
  }
  if (p.threads.length === 2) coverage.threads2.push(p.id);
  if (p.stimulus) coverage.stimulus.push(p.id);
  for (const t of p.threads) {
    coverage.firmware.add(t.firmware);
    const words = pe.assemble(t.source);
    if (words.ok && words.words.length >= 100) coverage.long.push(p.id);
  }
}

// What the check must cover, so that dropping a preset cannot quietly
// narrow it.
if (coverage.firmware.size < 10) fail("only " + coverage.firmware.size + " firmware programs compared; at least 10 are required");
if (!coverage.threads2.length) fail("no preset runs both threads");
if (!coverage.stimulus.length) fail("no preset has a stimulus");
if (!coverage.long.length) fail("no preset has a long program (100 words or more)");
if (coverage.rx.size < 3) fail("RX words compared in only " + coverage.rx.size + " presets");

// The assembler on every example program.
let assembled = 0;
const sources = fs.readdirSync(examples).filter((f) => f.endsWith(".s")).map((f) => path.join(examples, f));
sources.push(path.join(examples, "ws2812", "ws2812.s"));
for (const f of sources) {
  const native = execFileSync(peSim, ["asm", f], { encoding: "utf8" });
  const r = pe.assemble(fs.readFileSync(f, "utf8"));
  if (!r.ok) { fail(f + ": JavaScript assembler failed: " + r.message); continue; }
  const js = r.words.map((w) => w + "\n").join("");
  if (js !== native) fail(f + ": assembled words differ, first at " + firstDifference(native, js));
  else assembled++;
}
// And an error, at its line.
const bad = pe.assemble("nop\n  set pins, 1\n  jmp nowhere_at_all\n");
if (bad.ok || bad.line !== 3) fail("an assembly error is not reported at its line: " + JSON.stringify(bad));

fs.rmSync(dir, { recursive: true, force: true });
console.log("exact.js: " + presets.length + " presets (" + coverage.firmware.size + " programs; two threads: " + coverage.threads2.join(", ") +
  "; stimulus: " + coverage.stimulus.join(", ") + "; long: " + coverage.long.join(", ") + "; RX words: " + [...coverage.rx].join(", ") + "), each run both ways; " +
  assembled + " of " + sources.length + " example programs assemble to the same words");
if (failures) { console.error("exact.js: " + failures + " failures"); process.exit(1); }
