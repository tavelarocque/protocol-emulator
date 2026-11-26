import json,os,shutil,subprocess,sys
S=sys.argv[1]; W=f'{S}/mutants/classify'
d=json.load(open(f'{S}/mutants/results.json'))
def prep(src_dir, name, dst, prog=None):
    shutil.rmtree(dst,ignore_errors=True); os.makedirs(dst)
    for f in ['run_args.txt','TASK.md','isa.md']: shutil.copy(f'{src_dir}/{f}',dst)
    shutil.copy(prog or f'{src_dir}/{name}.s', f'{dst}/{name}.s')
    real=os.path.realpath(f'{S}/runs/{name}/full/pe_sim')
    shutil.copy(real,f'{dst}/pe_sim.real'); shutil.copy(f'{W}/logsim.py',f'{dst}/pe_sim'); os.chmod(f'{dst}/pe_sim',0o755)
    r=subprocess.run(['python3','accept.py',dst],cwd=f'{S}/hidden/{name}',capture_output=True,text=True,timeout=900)
    logs=sorted(os.listdir(f'{dst}/log')) if os.path.isdir(f'{dst}/log') else []
    return ('ACCEPT PASS' in r.stdout+r.stderr), [open(f'{dst}/log/{l}','rb').read() for l in logs]
out={}
for n,rs in d.items():
    surv=[(k,r) for k,r in enumerate(rs) if r['verdict']=='PASS']
    if not surv: continue
    ok,base=prep(f'{S}/runs/{n}/full',n,f'{W}/{n}/orig')
    for k,r in surv:
        ok2,mut=prep(f'{S}/runs/{n}/full',n,f'{W}/{n}/m{k}',prog=f'{S}/mutants/{n}/{k}/{n}.s')
        same=sum(a==b for a,b in zip(base,mut)); 
        out[f'{n}/{k}']={'runs':len(base),'identical':same,'pass':ok2,'from':r['from'],'to':r['to']}
        print(n,k,'calls',len(base),len(mut),'identical',same,flush=True)
json.dump(out,open(f'{W}/classify.json','w'),indent=1)
