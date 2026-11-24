"""Check completed native boss exports without inventing absent encounters."""
from pathlib import Path
import argparse, collections, json, math

ROOT=Path(__file__).resolve().parents[2]

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('input',type=Path)
    ap.add_argument('--out',type=Path,default=ROOT/'QA/data/boss-validation.json')
    args=ap.parse_args()
    rows=[json.loads(s)for s in args.input.read_text(encoding='utf-8').splitlines()if s.strip()]
    rows=[r for r in rows if r.get('record_type')=='boss_encounter']
    errors=[]
    if len(set(r['run_id']for r in rows))!=len(rows):errors.append('Duplicate encounter IDs')
    for r in rows:
        m=r['metrics'];label=r['run_id']
        if r['boss_hp_initial']<=0:errors.append(label+': missing actual boss initialization')
        if r['end_reason']=='boss_defeated' and r['boss_hp_remaining']>0:errors.append(label+': win with remaining boss HP')
        if r['end_reason']=='player_death' and r['player_hp']>0:errors.append(label+': death with positive player HP')
        if r['end_reason']=='timeout_600_seconds' and (not r['censored'] or r['completed']):errors.append(label+': timeout must be censored and incomplete')
        if not math.isclose(sum(x['damage']for x in m['sources'].values()),m['damage_out'],rel_tol=1e-8,abs_tol=1e-5):errors.append(label+': outgoing source sums differ')
        if not math.isclose(sum(x['damage']for x in m['incoming'].values()),m['damage_in'],rel_tol=1e-8,abs_tol=1e-5):errors.append(label+': incoming source sums differ')
        if sum(x['fatal_hits']for x in m['incoming'].values())!=(1 if r['end_reason']=='player_death' else 0):errors.append(label+': fatal source count differs')
        if any(x['kind']=='unattributed' and x['damage']>0 for x in m['incoming'].values()):errors.append(label+': incoming damage has unknown origin')
        if not math.isclose(m['seconds'],r['seconds'],abs_tol=1e-5):errors.append(label+': tick and telemetry clocks differ')
    result={'passed':not errors,'encounters':len(rows),'completed':sum(r['completed']for r in rows),
        'censored':sum(r['censored']for r in rows),'classes':dict(collections.Counter(r['class_name']for r in rows)),
        'bosses':dict(collections.Counter(r['boss']for r in rows)),'policies':dict(collections.Counter(r['persona']for r in rows)),
        'minutes':dict(collections.Counter(r['spawn_minute']for r in rows)),'errors':errors,
        'scope':'Integrity checks on actual native encounters; no formal unavoidability proof or human playtest claim.'}
    args.out.parent.mkdir(parents=True,exist_ok=True)
    args.out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result,indent=2))
    if errors:raise SystemExit(1)

if __name__=='__main__':main()
