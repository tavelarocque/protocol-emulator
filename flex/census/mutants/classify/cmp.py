import os,sys,json
W=sys.argv[1]
def ev(b):
    e=[];rx=[]
    for l in b.decode().split('\n'):
        p=l.split()
        if len(p)==3 and p[0]=='pins': e.append((int(p[1]),p[2]))
        elif p and p[0]!='pins': rx.append(l)
    return e,rx
for n in sorted(os.listdir(W)):
    if not os.path.isdir(f'{W}/{n}/orig'): continue
    o=sorted(os.listdir(f'{W}/{n}/orig/log'))
    for m in sorted(x for x in os.listdir(f'{W}/{n}') if x.startswith('m')):
        seqsame=0; rxsame=0; maxshift=0; firstdiff=None
        for f in o:
            a,ra=ev(open(f'{W}/{n}/orig/log/{f}','rb').read()); b,rb=ev(open(f'{W}/{n}/{m}/log/{f}','rb').read())
            rxsame+= ra==rb
            if [v for _,v in a]==[v for _,v in b]:
                seqsame+=1; maxshift=max([maxshift]+[abs(x[0]-y[0]) for x,y in zip(a,b)])
            elif firstdiff is None:
                for i,(x,y) in enumerate(zip(a,b)):
                    if x[1]!=y[1]: firstdiff=(f,i,x,y,len(a),len(b)); break
                else: firstdiff=(f,'len',len(a),len(b))
        print(n,m,'value-seq same',seqsame,'/',len(o),'rx same',rxsame,'maxshift',maxshift,'first',firstdiff)
