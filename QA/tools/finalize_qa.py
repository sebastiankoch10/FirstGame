"""Rebuild primary summaries/charts only after every declared cohort is complete."""
from pathlib import Path
import argparse,hashlib,json,math,subprocess,sys
ROOT=Path(__file__).resolve().parents[2]
NAMES=['baseline-v2-a','baseline-v2-b','after-v2-a','after-v2-b','holdout-v2']
def read(path):return [json.loads(s) for s in path.read_text(encoding='utf-8').splitlines() if s.strip()]
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--charts',action='store_true');args=ap.parse_args()
    files=[];runs=[]
    for name in NAMES:
        directory=ROOT/'QA/data'/name;manifest=json.loads((directory/'cohort.json').read_text())
        if not manifest.get('completed'):raise RuntimeError('Cohort is still running: '+name)
        paths=sorted(directory.glob('worker-*.jsonl'));rows=[r for p in paths for r in read(p)]
        if len(rows)!=manifest['requested_total']:raise RuntimeError('Incomplete checkpoint count: '+name)
        files+=paths;runs+=rows
    for r in runs:
        if not r.get('completed') or r.get('record_type')!='full_run' or r.get('policy_version')!='visible-countdown-v2':raise RuntimeError('Unqualified full-run row: '+r['run_id'])
        if r.get('source_phase')!=('baseline' if r['phase']=='baseline' else 'after'):raise RuntimeError('Wrong artifact source phase: '+r['run_id'])
        if r['end_reason'] not in ('death','survived_1800_seconds_censored') or not 0<=r['seconds']<=1800.01:raise RuntimeError('Invalid endpoint: '+r['run_id'])
        if r.get('native_room_speed')!=60 or r.get('logical_hz')!=60:raise RuntimeError('Invalid logical/engine clock')
        m=r['metrics']
        for key,field in [('sources','damage_out'),('incoming','damage_in')]:
            if not math.isclose(sum(v['damage'] for v in m[key].values()),m[field],rel_tol=1e-8,abs_tol=1e-5):raise RuntimeError('HP telemetry sum mismatch: '+r['run_id'])
        if r['end_reason']=='death' and (r['hp']!=0 or not m.get('last_fatal')):raise RuntimeError('Missing actual fatal endpoint')
    key=lambda r:(r['seed'],r['class_name'],r['persona'])
    before={key(r) for r in runs if r['phase']=='baseline'};after={key(r) for r in runs if r['phase']=='after'}
    holdout={key(r) for r in runs if r['phase']=='holdout'}
    if before!=after or before&holdout:raise RuntimeError('Paired/holdout seed design mismatch')
    if len(set(r['run_id'] for r in runs))!=len(runs):raise RuntimeError('Duplicate run IDs')
    calibration_files=sorted((ROOT/'QA/data').glob('native-policy-v1-calibration-*.jsonl'))
    calibration=[r for p in calibration_files for r in read(p) if r.get('completed')]
    boss_files=[ROOT/'QA/data/boss-baseline.jsonl',ROOT/'QA/data/boss-holdout.jsonl']
    selected=ROOT/'QA/data/boss-after-selected.jsonl'
    boss_cal_files=[ROOT/'QA/logs'/n for n in ['boss-policy-v1-calibration.jsonl','boss-policy-v1-pilot-replay.jsonl','boss-policy-v2-pilot-replay.jsonl']]
    boss_cal=sum(len(read(p)) for p in boss_cal_files)
    bench_count=sum(r.get('record_type')=='controlled_benchmark' for r in read(ROOT/'QA/data/ability-baseline.jsonl'))
    invalid_boss=ROOT/'QA/logs/invalid-room-speed-boss-pilot.jsonl'
    inventory=dict(primary_full_runs=len(runs),calibration_full_runs=len(calibration),total_valid_full_runs=len(runs)+len(calibration),
        paired_runs=len(before),independent_holdout_runs=len(holdout),primary_boss_encounters=sum(len(read(p)) for p in boss_files),
        after_boss_replays=len(read(selected)),boss_calibration_and_pilot_replays=boss_cal,
        total_valid_isolated_boss_executions=sum(len(read(p)) for p in boss_files)+len(read(selected))+boss_cal,
        controlled_benchmark_cells=bench_count,invalid_boss_pilots_excluded=len(read(invalid_boss)),all_full_run_telemetry_checks_passed=True,
        files={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in files+calibration_files+boss_files+[selected]+boss_cal_files},
        tool_sha256={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted((ROOT/'QA/tools').glob('*')) if p.is_file() and p.suffix in ('.py','.gml','.ps1')})
    (ROOT/'QA/data/dataset-manifest.json').write_text(json.dumps(inventory,indent=2)+'\n',encoding='utf-8')
    cmd=[sys.executable,str(ROOT/'QA/tools/analyze_qa.py'),'--runs',*[str(p) for p in files],
         '--boss',*[str(p) for p in boss_files],'--bench',str(ROOT/'QA/data/ability-baseline.jsonl')]
    if args.charts:cmd.append('--charts')
    subprocess.run(cmd,cwd=ROOT,check=True)
    print(json.dumps({k:v for k,v in inventory.items() if k!='files'},indent=2))
if __name__=='__main__':main()
