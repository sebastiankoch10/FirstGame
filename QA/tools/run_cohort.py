"""Run independent native seed blocks concurrently; reuse one reviewed artifact.

Every child still runs each production 1/60 tick until death or 1800 seconds.
Parallel workers change CPU scheduling only, never HP, timers or run length.
"""
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
import argparse, datetime, hashlib, json, subprocess, sys, time

ROOT=Path(__file__).resolve().parents[2]

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--reuse',type=Path,required=True)
    ap.add_argument('--phase',choices=['baseline','after','holdout'],default='baseline')
    ap.add_argument('--workers',type=int,default=4)
    ap.add_argument('--runs-per-class-per-worker',type=int,default=3)
    ap.add_argument('--seedstart',type=int,required=True)
    ap.add_argument('--batchsize',type=int,default=600)
    ap.add_argument('--timeout',type=int,default=3600)
    ap.add_argument('--label',required=True)
    args=ap.parse_args()
    if args.workers<1 or args.workers>8:ap.error('Use1..8 independent workers')
    if args.runs_per_class_per_worker<3 or args.runs_per_class_per_worker%3:
        ap.error('Use a positive multiple of3 for equal beginner/average/experienced counts')
    directory=ROOT/'QA/data'/args.label
    directory.mkdir(parents=True,exist_ok=True)
    if (directory/'cohort.json').exists():raise RuntimeError('Existing cohort label; choose a new label to avoid duplicate IDs')
    artifact=args.reuse.resolve();exe=artifact/'build/FirstGameNativeMC.exe'
    if not exe.is_file():raise RuntimeError('Missing native executable')
    manifest=dict(started_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),phase=args.phase,
        workers=args.workers,runs_per_class_per_worker=args.runs_per_class_per_worker,
        requested_total=args.workers*args.runs_per_class_per_worker*3,seedstart=args.seedstart,
        batchsize=args.batchsize,artifact=str(artifact.relative_to(ROOT)),
        exe_sha256=hashlib.sha256(exe.read_bytes()).hexdigest(),children=[],completed=False)
    target=directory/'cohort.json'
    def save():target.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    save();started=time.time()
    def worker(index):
        seed=args.seedstart+index*args.runs_per_class_per_worker
        out=directory/f'worker-{index}.jsonl';log=directory/f'worker-{index}.log'
        cmd=[sys.executable,str(ROOT/'QA/tools/run_native_mc.py'),'--reuse',str(artifact),
            '--phase',args.phase,'--mode','runs','--runs-per-class',str(args.runs_per_class_per_worker),
            '--seedstart',str(seed),'--batchsize',str(args.batchsize),'--timeout',str(args.timeout),'--out',str(out)]
        began=time.time()
        with log.open('w',encoding='utf-8') as stream:
            proc=subprocess.run(cmd,cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT)
        rows=[json.loads(x) for x in out.read_text(encoding='utf-8').splitlines() if x.strip()] if out.exists() else []
        return dict(worker=index,seedstart=seed,exit_code=proc.returncode,wall_seconds=time.time()-began,
                    rows=len(rows),completed_runs=sum(bool(r.get('completed')) for r in rows),
                    data=str(out.relative_to(ROOT)),log=str(log.relative_to(ROOT)))
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures=[pool.submit(worker,i) for i in range(args.workers)]
        for future in as_completed(futures):
            item=future.result();manifest['children'].append(item);save();print(json.dumps(item),flush=True)
    manifest['elapsed_wall_seconds']=time.time()-started
    manifest['completed_runs']=sum(x['completed_runs'] for x in manifest['children'])
    manifest['completed']=all(x['exit_code']==0 for x in manifest['children'])
    save();print(json.dumps({k:manifest[k] for k in ['requested_total','completed_runs','completed','elapsed_wall_seconds']},indent=2))
    if not manifest['completed']:raise SystemExit(1)

if __name__=='__main__':main()
