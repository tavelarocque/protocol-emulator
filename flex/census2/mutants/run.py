"""Mutation check of the hidden tests: for each passing hand-in, make up to
5 mutants by changing one number in one instruction line of the program
(seeded, reproducible), keep the ones that still assemble, and run the
hidden test on each. A judge that is strong should fail most of them."""
import os, re, random, shutil, subprocess, sys, json
S = sys.argv[1]
names = [l.split('|')[2].strip() for l in open(f'{S}/RESULTS2-log.md') if l.startswith('| A |') and l.split('|')[3].strip() == 'PASS']
out = {}
for n in names:
    run = f'{S}/kits/{n}'
    src = open(f'{run}/{n}.s').read().split('\n')
    cand = [i for i, l in enumerate(src) if re.search(r'\d', l.split(';')[0]) and not l.strip().startswith(('.', ';')) and l.split(';')[0].strip()]
    rng = random.Random(f'mut:{n}')
    res = []
    tries = 0
    while len(res) < 5 and tries < 40:
        tries += 1
        i = rng.choice(cand)
        code, _, com = src[i].partition(';')
        nums = list(re.finditer(r'\b\d+\b', code))
        if not nums: continue
        m = rng.choice(nums)
        v = int(m.group()); nv = v + rng.choice([-1, 1]) if v > 0 else 1
        new = code[:m.start()] + str(nv) + code[m.end():]
        d = f'{S}/mutants/{n}/{len(res)}'
        shutil.rmtree(d, ignore_errors=True); os.makedirs(d)
        for f in ['pe_sim', 'run_args.txt', 'TASK.md', 'isa.md']:
            shutil.copy(f'{run}/{f}', d)
        lines = list(src); lines[i] = new + (';' + com if com else '')
        open(f'{d}/{n}.s', 'w').write('\n'.join(lines))
        if subprocess.run([f'{d}/pe_sim', 'asm', f'{d}/{n}.s'], capture_output=True).returncode != 0:
            shutil.rmtree(d); continue
        try:
            r = subprocess.run(['python3', 'accept.py', d], cwd=f'{S}/hidden/{n}', capture_output=True, text=True, timeout=600)
            verdict = 'PASS' if 'ACCEPT PASS' in r.stdout + r.stderr else 'FAIL'
        except subprocess.TimeoutExpired:
            verdict = 'TIMEOUT'
        res.append({'line': i + 1, 'from': src[i].strip(), 'to': new.strip(), 'verdict': verdict})
    out[n] = res
    k = sum(r['verdict'] != 'PASS' for r in res)
    print(f'{n}: {k}/{len(res)} mutants rejected', flush=True)
json.dump(out, open(f'{S}/mutants/results.json', 'w'), indent=1)
