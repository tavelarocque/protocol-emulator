// SPDX-FileCopyrightText: © 2026 Tave La Rocque
// SPDX-License-Identifier: Apache-2.0
//
// The driver under MicroPython and under CPython must compute the same
// things: runs compat.py after host/protocol_emulator.py in both and
// compares, then compat_more.py after host/more_protocols.py and
// compat_extra.py after host/extra_protocols.py, with the modules before
// still loaded as they are on a board; then each later group's
// host/<group>_protocols.py with its compat_<group>.py (the list LATER),
// each on a fresh board beside the driver alone. No chip is needed, so
// this takes seconds of emulated time.
//
//   node run_compat.mjs [--driver FILE] [--cpu-slowdown K]

import { readFileSync } from 'fs';
import { execFileSync } from 'child_process';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';
import { Board } from './board.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
// CPython is given the code on stdin: with every driver it is too long for
// one command-line argument.
const py = (code) => execFileSync('python3', ['-'], { input: code, encoding: 'latin1' });
const i = process.argv.indexOf('--driver');
const driverPath = i < 0 ? join(HERE, '..', '..', 'host', 'protocol_emulator.py') : process.argv[i + 1];
const driver = readFileSync(driverPath, 'latin1');
const compat = readFileSync(join(HERE, 'compat.py'), 'latin1');

const cpython = py(driver + '\n' + compat).trim();

const j = process.argv.indexOf('--cpu-slowdown');
const cpuSlowdown = j < 0 ? 1 : Number(process.argv[j + 1]);
const board = new Board(join(HERE, 'build', 'tt-demo-rp2040-v2.0.4.uf2'), { cpuSlowdown });
board.boot();
const [o, e] = board.exec(driver + '\n' + compat);
const micropython = (o + e).trim();

if (micropython !== cpython) {
  console.log('MicroPython and CPython DIFFER');
  console.log('MicroPython:', micropython.slice(0, 2000));
  process.exit(1);
}
console.log(`MicroPython and CPython agree (${cpython.length} characters of results)`);

// The second module imports the first by name. Here neither is a file, so
// the namespace the driver was run in is given that name.
const asModule = 'import sys, __main__\nsys.modules["protocol_emulator"] = __main__\n';
const more = readFileSync(join(HERE, '..', '..', 'host', 'more_protocols.py'), 'latin1')
  ;
const compatMore = readFileSync(join(HERE, 'compat_more.py'), 'latin1');
const second = asModule + more + '\n' + compatMore;
const cpython2 = py(driver + '\n' + second).trim();
// The board compiles what it is given as it arrives, in the memory the
// first driver has left: the second driver goes in before its checks.
const [o2a, e2a] = board.exec(asModule + more);
const [o2b, e2b] = board.exec(compatMore);
const [o2, e2] = [o2a + o2b, e2a + e2b];
const micropython2 = (o2 + e2).replace(/\r\n/g, '\n').trim();  // the board's terminal ends lines with CR LF
if (micropython2 !== cpython2) {
  let at = 0;
  while (micropython2[at] === cpython2[at]) at++;
  console.log(`more_protocols.py: MicroPython and CPython DIFFER, first at character ${at}`);
  console.log('MicroPython:', JSON.stringify(micropython2.slice(Math.max(0, at - 200), at + 300)));
  console.log('CPython:    ', JSON.stringify(cpython2.slice(Math.max(0, at - 200), at + 300)));
  process.exit(1);
}
console.log(`more_protocols.py: they agree too (${cpython2.length} characters of results)`);

// The third module the same way, with the first two still loaded.
const extra = readFileSync(join(HERE, '..', '..', 'host', 'extra_protocols.py'), 'latin1');
const compatExtra = readFileSync(join(HERE, 'compat_extra.py'), 'latin1');
const cpython3 = py(driver + '\n' + second + '\n' + extra + '\n' + compatExtra).trim().slice(cpython2.length).trim();
const [o3a, e3a] = board.exec(extra);
const [o3b, e3b] = board.exec(compatExtra);
const micropython3 = (o3a + o3b + e3a + e3b).replace(/\r\n/g, '\n').trim();
if (micropython3 !== cpython3) {
  let at = 0;
  while (micropython3[at] === cpython3[at]) at++;
  console.log(`extra_protocols.py: MicroPython and CPython DIFFER, first at character ${at}`);
  console.log('MicroPython:', JSON.stringify(micropython3.slice(Math.max(0, at - 200), at + 300)));
  console.log('CPython:    ', JSON.stringify(cpython3.slice(Math.max(0, at - 200), at + 300)));
  process.exit(1);
}
console.log(`extra_protocols.py: and they agree (${cpython3.length} characters of results)`);

// Each later group's module on a board of its own, loaded with the first
// three modules and their checks (the later checks use their recorder and
// helpers) and then that module alone: every later module needs only
// protocol_emulator, and all of them together outgrow the memory
// MicroPython has for compiling on one board.
const LATER = ['i2c2', 'motion', 'i3c', 'auto', 'misc', 'link', 'aero', 'card', 'rail'];
const alone = driver + '\n' + second + '\n' + extra + '\n' + compatExtra;
const aloneOut = py(alone).trim();
for (const name of LATER) {
  const mod = readFileSync(join(HERE, '..', '..', 'host', `${name}_protocols.py`), 'latin1');
  const comp = readFileSync(join(HERE, `compat_${name}.py`), 'latin1');
  const cp = py(alone + '\n' + mod + '\n' + comp).trim().slice(aloneOut.length).trim();
  const fresh = new Board(join(HERE, 'build', 'tt-demo-rp2040-v2.0.4.uf2'), { cpuSlowdown });
  fresh.boot();
  fresh.exec(driver);
  fresh.exec(asModule + more);
  fresh.exec(compatMore);
  fresh.exec(extra);
  fresh.exec(compatExtra);
  const [oa, ea] = fresh.exec(mod);
  const [ob, eb] = fresh.exec(comp);
  const mp = (oa + ob + ea + eb).replace(/\r\n/g, '\n').trim();
  if (mp !== cp) {
    let at = 0;
    while (mp[at] === cp[at]) at++;
    console.log(`${name}_protocols.py: MicroPython and CPython DIFFER, first at character ${at}`);
    console.log('MicroPython:', JSON.stringify(mp.slice(Math.max(0, at - 200), at + 300)));
    console.log('CPython:    ', JSON.stringify(cp.slice(Math.max(0, at - 200), at + 300)));
    process.exit(1);
  }
  console.log(`${name}_protocols.py: and they agree (${cp.length} characters of results)`);
}
process.exit(0);
