"""Validate actual native benchmark exports. Never supplies missing measurements."""
from pathlib import Path
import argparse, collections, json, math

ROOT=Path(__file__).resolve().parents[2]

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('input',type=Path)
    ap.add_argument('--out',type=Path,default=ROOT/'QA/data/ability-validation.json')
    args=ap.parse_args()
    rows=[json.loads(line)for line in args.input.read_text(encoding='utf-8').splitlines() if line.strip()]
    telemetry=[r for r in rows if r.get('record_type')=='telemetry_validation']
    cases=[r for r in rows if r.get('record_type')=='controlled_benchmark']
    errors=[]
    if len(telemetry)!=1 or not telemetry[0].get('passed'):errors.append('Expected one passing native telemetry validation record')
    ids=[r['run_id']for r in cases]
    if len(ids)!=len(set(ids)):errors.append('Duplicate benchmark IDs')
    observed=collections.Counter((r['sid'],r['level'],r['target_count'])for r in cases if r['kind']=='active')
    missing=[(s,l,t)for s in range(101,119)for l in range(1,10)for t in (1,8)if observed[(s,l,t)]!=1]
    if missing:errors.append(f'{len(missing)} missing or duplicated active matrix cells')
    for r in cases:
        m=r['metrics'];total=sum(s['damage']for s in m['sources'].values())
        if not math.isclose(total,m['damage_out'],rel_tol=1e-8,abs_tol=1e-5):errors.append(r['run_id']+': source damage does not reconcile')
        if not math.isclose(r['damage'],m['damage_out'],rel_tol=1e-8,abs_tol=1e-5):errors.append(r['run_id']+': exported damage does not reconcile')
        for source_field,total_field in [('healing','healing'),('attempted','attempted_out'),('overkill','overkill'),('critical_hits','critical_hits'),('kills','kills')]:
            if not math.isclose(sum(s[source_field]for s in m['sources'].values()),m[total_field],rel_tol=1e-8,abs_tol=1e-5):errors.append(r['run_id']+': '+source_field+' source totals do not reconcile')
        if r['seconds']<=0:errors.append(r['run_id']+': no positive observation window')
        if any(s['damage']<0 or s['overkill']<0 or s['projectiles_hit']>s['projectiles'] for s in m['sources'].values()):errors.append(r['run_id']+': invalid per-source counters')
    counts=collections.Counter(r['kind']for r in cases)
    if counts!=dict(active=324,passive_ab=324,base_weapon=6):errors.append('Controlled matrix row counts incomplete')
    result={'passed':not errors,'native_telemetry_checks':len(telemetry[0]['checks'])if telemetry else 0,
            'controlled_rows':len(cases),'counts':dict(counts),'errors':errors,
            'scope':'Data integrity only; controlled targets do not establish complete-run balance or human fairness.'}
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result,indent=2))
    if errors:raise SystemExit(1)

if __name__=='__main__':main()
