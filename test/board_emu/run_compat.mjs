// SPDX-FileCopyrightText: © 2026 Tave La Rocque
// SPDX-License-Identifier: Apache-2.0
//
// The driver under MicroPython and under CPython must compute the same
// things: runs compat.py after host/protocol_emulator.py in both and
// compares, then compat_more.py after host/more_protocols.py, with the
// first module still loaded as it is on a board. No chip is needed, so
// this takes seconds of emulated time.
//
//   node run_compat.mjs [--driver FILE] [--cpu-slowdown K]

import { readFileSync } from 'fs';
import { execFileSync } from 'child_process';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';
import { Board } from './board.mjs';

const HERE = dirname(fileURLToPath(import.meta.url));
const i = process.argv.indexOf('--driver');
const driverPath = i < 0 ? join(HERE, '..', '..', 'host', 'protocol_emulator.py') : process.argv[i + 1];
const driver = readFileSync(driverPath, 'latin1');
const compat = readFileSync(join(HERE, 'compat.py'), 'latin1');

const cpython = execFileSync('python3', ['-c', driver + '\n' + compat], { encoding: 'latin1' }).trim();

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
const cpython2 = execFileSync('python3', ['-c', driver + '\n' + second], { encoding: 'latin1' }).trim();
const [o2, e2] = board.exec(second);
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
process.exit(0);
