import os,sys,collections
W=sys.argv[1]
def ev(b): return [(int(p[1]),p[2]) for p in (l.split() for l in b.decode().split('\n')) if len(p)==3 and p[0]=='pins']
for n,m in [('flexray','m0'),('flexray','m1'),('flexray','m3'),('maple_bus','m2'),('maple_bus','m4'),('rc_encode','m4'),('t55xx','m3'),('usb_power_delivery','m4'),('iec','m3')]:
    c=collections.Counter(); where=collections.Counter()
    for f in sorted(os.listdir(f'{W}/{n}/orig/log')):
        a=ev(open(f'{W}/{n}/orig/log/{f}','rb').read()); b=ev(open(f'{W}/{n}/{m}/log/{f}','rb').read())
        for i in range(1,len(a)):
            d=(b[i][0]-b[i-1][0])-(a[i][0]-a[i-1][0])
            if d: c[d]+=1; where[(a[i][0]-a[i-1][0])]+=1
    print(n,m,'interval deltas',dict(c),'orig interval lengths where changed (top)',where.most_common(4))
