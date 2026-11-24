"""Run controlled native boss fights via the shared fixed-tick production harness.

--cases is a cap, not a fabricated target count. An interrupted final encounter
is excluded while earlier complete JSONL rows remain available.
"""
from pathlib import Path
import argparse, sys
import run_native_mc

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--cases',type=int,default=15)
    ap.add_argument('--phase',choices=['baseline','after','holdout'],default='baseline')
    ap.add_argument('--seedstart',type=int,default=810101)
    ap.add_argument('--batchsize',type=int,default=60)
    ap.add_argument('--reuse',type=Path)
    ap.add_argument('--out',type=Path)
    ap.add_argument('--timeout',type=int,default=900)
    args=ap.parse_args()
    if args.cases<1:ap.error('--cases must be positive')
    if args.out is None:args.out=run_native_mc.ROOT/f'QA/data/boss-{args.phase}.jsonl'
    sys.argv=[str(Path(run_native_mc.__file__)), '--mode','boss','--phase',args.phase,
        '--runs-per-class',str((args.cases+179)//180),'--probe-ticks',str(args.cases),
        '--seedstart',str(args.seedstart),'--batchsize',str(args.batchsize),'--out',str(args.out),
        '--timeout',str(args.timeout)]
    if args.reuse:sys.argv.extend(['--reuse',str(args.reuse)])
    run_native_mc.main()

if __name__=='__main__':main()
