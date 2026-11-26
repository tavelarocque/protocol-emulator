#!/usr/bin/env python3
import os,sys,subprocess
here=os.path.dirname(os.path.realpath(__file__))
r=subprocess.run([os.path.join(here,'pe_sim.real')]+sys.argv[1:],capture_output=True)
if sys.argv[1:2]==['run'] or (sys.argv[1:2] and 'run'.startswith(sys.argv[1]) and sys.argv[1]!='' ):
    logd=os.path.join(here,'log'); os.makedirs(logd,exist_ok=True)
    k=len(os.listdir(logd))
    open(os.path.join(logd,'%04d.out'%k),'wb').write(r.stdout)
sys.stdout.buffer.write(r.stdout); sys.stderr.buffer.write(r.stderr); sys.exit(r.returncode)
