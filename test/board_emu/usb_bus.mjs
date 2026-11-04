// SPDX-FileCopyrightText: © 2026 Tave La Rocque
// SPDX-License-Identifier: Apache-2.0
//
// Packets on the USB bus, from cosim.node's log of line changes, and the
// timing the device sees between them. Low speed: J = D- high, K = D+ high,
// 1.5 Mbit/s.

export const BIT_NS = 1e9 / 1.5e6;

const J = 2, K = 1, SE0 = 0;

// [t_ns, line, host] steps from the raw [t_ps, state] pairs.
export function steps(log) {
  const out = [];
  for (let i = 0; i < log.length; i += 2) {
    const s = log[i + 1];
    out.push([log[i] / 1000, s & 3, (s >> 2) & 1, (s >> 3) & 1]);
  }
  return out;
}

// Packets: { start, end (end of EOP), host (who drove), bytes or error }.
export function packets(st) {
  const res = [];
  const at = (t, from) => {
    let i = from;
    while (i + 1 < st.length && st[i + 1][0] <= t) i++;
    return [st[i][1], i];
  };
  let i = 0;
  while (i < st.length) {
    // A packet starts where the line leaves J for K.
    if (!(st[i][1] === K && i > 0 && st[i - 1][1] === J)) { i++; continue; }
    const start = st[i][0];
    let host = st[i][2];
    const levels = [];
    let k = 0, j = i, line;
    for (;;) {
      [line, j] = at(start + (k + 0.5) * BIT_NS, j);
      if (line === SE0) break;
      if (line !== J && line !== K) break;
      levels.push(line);
      k++;
      if (k > 2000) break;
    }
    // EOP: two bits of SE0 then J.
    let end = start + (k + 3) * BIT_NS;
    let e = j;
    while (e < st.length && st[e][1] === SE0) e++;
    if (e < st.length) end = st[e][0];
    for (let q = i; q < e && q < st.length; q++) host = host || st[q][2];
    res.push({ start, end, host: !!host, ...decode(levels) });
    i = Math.max(e, i + 1);
  }
  return res;
}

function decode(levels) {
  let prev = J, run = 0;
  const bits = [];
  for (const lv of levels) {
    const b = lv === prev ? 1 : 0;
    prev = lv;
    if (run === 6) {
      if (b) return { error: 'stuffing' };
      run = 0;
      continue;
    }
    run = b ? run + 1 : 0;
    bits.push(b);
  }
  const s = bits.indexOf(1);
  if (s < 0) return { error: 'no SYNC' };
  const rest = bits.slice(s + 1);
  if (rest.length % 8) return { error: rest.length + ' bits' };
  const bytes = [];
  for (let n = 0; n < rest.length; n += 8) {
    let v = 0;
    for (let b = 0; b < 8; b++) v |= rest[n + b] << b;
    bytes.push(v);
  }
  return { bytes };
}

const PID = { 0xe1: 'OUT', 0x69: 'IN', 0x2d: 'SETUP', 0xc3: 'DATA0', 0x4b: 'DATA1',
  0xd2: 'ACK', 0x5a: 'NAK', 0x1e: 'STALL' };

export function pidName(p) { return p.bytes ? PID[p.bytes[0]] || 'pid ' + p.bytes[0].toString(16) : p.error; }

export function describe(p, t0 = 0) {
  const who = p.host ? 'host  ' : 'device';
  const body = p.bytes ? p.bytes.slice(1).map((b) => b.toString(16).padStart(2, '0')).join(' ') : '';
  return `${((p.start - t0) / 1000).toFixed(3).padStart(10)} us  ${who} ${pidName(p).padEnd(6)} ${body}`;
}
