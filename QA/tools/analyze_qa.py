"""Deterministic summaries/charts from completed native JSONL checkpoints only.

Usage: QA/.venv/Scripts/python.exe QA/tools/analyze_qa.py --runs ... --boss ... --bench ... --charts
No balancing constants, damage model, synthetic observations or external data are used.
"""
from pathlib import Path
from collections import defaultdict, Counter
import argparse, csv, hashlib, json, math, random, statistics

ROOT=Path(__file__).resolve().parents[2]
CLASSES=['Sword','Mage','Ranger']

def read(paths):
    rows=[]
    for path in paths:
        for number,line in enumerate(path.read_text(encoding='utf-8-sig').splitlines(),1):
            if line.strip():
                row=json.loads(line)
                row['_file']=str(path.relative_to(ROOT)) if path.is_relative_to(ROOT) else str(path)
                row['_line']=number
                rows.append(row)
    return rows

def wilson(k,n):
    if not n:return [None,None]
    z=1.959963984540054;p=k/n;den=1+z*z/n
    center=(p+z*z/(2*n))/den
    half=z*math.sqrt(p*(1-p)/n+z*z/(4*n*n))/den
    return [max(0,center-half),min(1,center+half)]

def interval(values):
    if not values:return None
    # Seeded bootstrap of the observed sample, not generated game runs.
    rng=random.Random(751903)
    estimates=sorted(statistics.mean(rng.choices(values,k=len(values))) for _ in range(1000))
    return [estimates[24],estimates[974]]

def describe(values):
    if not values:return {'n':0}
    values=sorted(values)
    return dict(n=len(values),mean=statistics.mean(values),median=statistics.median(values),
                minimum=values[0],maximum=values[-1],sd=statistics.stdev(values) if len(values)>1 else 0,
                q25=values[(len(values)-1)//4],q75=values[(len(values)-1)*3//4],mean_bootstrap95=interval(values))

def grouped(rows,keys):
    out=defaultdict(list)
    for row in rows:out[tuple(row.get(k,'unknown') for k in keys)].append(row)
    return out

def summary_runs(rows):
    out=[]
    for (phase,klass,persona),rs in grouped(rows,['phase','class_name','persona']).items():
        milestones=[]
        for minute in [1,3,5,10,15,20,25,30]:
            reached=sum(r['seconds']+1e-5>=minute*60 for r in rs)
            milestones.append(dict(minute=minute,reached=reached,n=len(rs),fraction=reached/len(rs),wilson95=wilson(reached,len(rs))))
        damage=sum(r.get('metrics',{}).get('damage_out',0) for r in rs)
        base=sum(sum(s.get('damage',0) for s in r.get('metrics',{}).get('sources',{}).values() if s.get('sid')==0) for r in rs)
        out.append(dict(phase=phase,class_name=klass,persona=persona,n=len(rs),
                        restricted_survival_seconds=describe([r['seconds'] for r in rs]),
                        level=describe([r['level'] for r in rs]),kills=describe([r['kills'] for r in rs]),
                        damage_out=damage,base_weapon_damage=base,base_weapon_share=base/damage if damage else None,
                        end_reasons=dict(Counter(r['end_reason'] for r in rs)),milestones=milestones))
    return out

def source_totals(rows):
    out={}
    for row in rows:
        for key,s in row.get('metrics',{}).get('sources',{}).items():
            target=out.setdefault(key,dict(sid=s.get('sid'),stage=s.get('stage'),observations=0))
            target['observations']+=1
            for k,v in s.items():
                if k not in ('sid','stage') and isinstance(v,(float,int)):target[k]=target.get(k,0)+v
    return out

def summary_bosses(rows):
    out=[]
    for (phase,boss,klass,persona,minute),rs in grouped(rows,['phase','boss','class_name','persona','spawn_minute']).items():
        won=[r for r in rs if r.get('won')]
        out.append(dict(phase=phase,boss=boss,class_name=klass,persona=persona,minute=minute,n=len(rs),
                        wins=len(won),censored=sum(bool(r.get('censored')) for r in rs),
                        win_fraction=len(won)/len(rs),win_wilson95=wilson(len(won),len(rs)),
                        duration_all=describe([r['seconds'] for r in rs]),duration_wins=describe([r['seconds'] for r in won]),
                        phases_seen=sorted(set(p for r in rs for p in r.get('phases_seen',[])))))
    return out

def attack_totals(rows):
    out={}
    for row in rows:
        for activation in row.get('metrics',{}).get('boss_activations',[]):
            key=str(activation.get('boss'))+':'+str(activation.get('ability'))
            target=out.setdefault(key,dict(boss=activation.get('boss'),ability=activation.get('ability'),activations=0,
                threatened=0,activations_hit=0,hits=0,damage=0,fatal_hits=0,avoided_threatened=0,censored=0,warnings=[],first_possible=[]))
            target['activations']+=1
            target['threatened']+=bool(activation.get('threatened'))
            target['activations_hit']+=activation.get('hits',0)>0
            for name in ['hits','damage','fatal_hits']:target[name]+=activation.get(name,0)
            target['avoided_threatened']+=bool(activation.get('avoided_while_threatened'))
            target['censored']+=bool(activation.get('censored'))
            if activation.get('warning',-1)>=0:target['warnings'].append(activation['warning'])
            if activation.get('first_possible',-1)>=0:target['first_possible'].append(activation['first_possible'])
    for target in out.values():
        n=target['threatened'];k=target['activations_hit']
        target['hit_fraction_threatened']=k/n if n else None
        target['hit_fraction_wilson95']=wilson(k,n) if k<=n else None
        target['warning_seconds']=describe(target.pop('warnings'))
        target['first_possible_seconds']=describe(target.pop('first_possible'))
    return out

def export_csv(path,rows,fields):
    with path.open('w',encoding='utf-8-sig',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=fields,extrasaction='ignore');writer.writeheader();writer.writerows(rows)

def charts(runs,bosses,bench,analysis):
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt
    dest=ROOT/'QA/charts';dest.mkdir(exist_ok=True)
    plt.rcParams.update({'figure.figsize':(10,5.5),'axes.spines.top':False,'axes.spines.right':False,'font.size':10})
    colors={'Sword':'#ba6239','Mage':'#7060be','Ranger':'#398f65'}
    def save(name):
        plt.tight_layout();plt.savefig(dest/(name+'.png'),dpi=150);plt.savefig(dest/(name+'.svg'));plt.close()
    phases=sorted(set(r.get('phase','unknown') for r in runs))
    for phase in phases:
        rs=[r for r in runs if r.get('phase')==phase]
        for klass in CLASSES:
            sub=[r for r in rs if r['class_name']==klass]
            if not sub:continue
            xs=sorted({0,30,*[r['seconds']/60 for r in sub]})
            ys=[sum(r['seconds']>m*60+1e-5 or r['end_reason']=='survived_1800_seconds_censored' for r in sub)/len(sub) for m in xs]
            plt.step(xs,ys,where='post',color=colors[klass],label=f'{klass} (n={len(sub)})')
            bounds=[wilson(round(y*len(sub)),len(sub)) for y in ys]
            plt.fill_between(xs,[b[0] for b in bounds],[b[1] for b in bounds],step='post',alpha=.10,color=colors[klass])
        plt.ylim(-.02,1.02);plt.xlim(0,30);plt.xlabel('Spielminute');plt.ylabel('Anteil erreicht');plt.title(f'Native Bot-Runs: Überleben ({phase})');plt.legend();save('survival-'+phase)
        for klass in CLASSES:
            observations=defaultdict(list)
            for row in rs:
                if row['class_name']!=klass:continue
                prior_time=0;prior_damage=0
                for point in row.get('timecourse',[]):
                    seconds=point['seconds'];damage=point['damage_out']
                    observations[seconds/60].append((damage-prior_damage)/max(.001,seconds-prior_time))
                    prior_time=seconds;prior_damage=damage
            if observations:
                xs=sorted(observations);ys=[statistics.mean(observations[x]) for x in xs]
                plt.plot(xs,ys,marker='o',color=colors[klass],label=klass)
                for x,y in zip(xs,ys):plt.annotate(f'n={len(observations[x])}',(x,y),xytext=(2,5),textcoords='offset points',fontsize=7,color=colors[klass])
        plt.xlabel('Spielminute');plt.ylabel('Effektiver HP-Schaden / s im vorigen Messintervall')
        plt.title(f'Native Klassen-DPS ({phase})\nNur bis zum Messpunkt überlebende Runs; wechselnde Stichprobe')
        plt.legend();save('class-dps-stages-'+phase)
    active=[r for r in bench if r.get('kind')=='active' and r.get('level')==5]
    if active:
        for position,count in enumerate([1,8]):
            sub=sorted([r for r in active if r.get('target_count')==count],key=lambda r:r['sid'])
            plt.bar([i+(position-.5)*.4 for i in range(len(sub))],[r['dps'] for r in sub],width=.4,label=f'{count} stationäre Ziele')
            plt.xticks(range(len(sub)),[str(int(r['sid'])) for r in sub])
        plt.title('Kontrollierter nativer Schaden – aktive Fähigkeiten Stufe 5');plt.xlabel('Fähigkeit-ID (106 ist Heilung)');plt.ylabel('Tatsächlicher Schaden / s');plt.legend();save('active-ability-dps')
    weapons=[r for r in bench if r.get('kind')=='base_weapon']
    if weapons:
        for position,count in enumerate([1,8]):
            sub=sorted([r for r in weapons if r.get('target_count')==count],key=lambda r:r['class_name'])
            plt.bar([i+(position-.5)*.35 for i in range(len(sub))],[r['dps'] for r in sub],width=.35,label=f'{count} stationäre Ziele')
            plt.xticks(range(len(sub)),[r['class_name'] for r in sub])
        plt.title('Native Startwaffen: kontrolliertes 15-s-Fenster');plt.ylabel('Tatsächlicher Schaden / s');plt.legend();save('base-weapon-dps')
    if bosses:
        names=sorted(set(r['boss'] for r in bosses))
        for idx,klass in enumerate(CLASSES):
            values=[]
            for name in names:
                sub=[r for r in bosses if r['boss']==name and r['class_name']==klass]
                values.append(sum(bool(r['won']) for r in sub)/len(sub) if sub else float('nan'))
            plt.bar([i+(idx-1)*.25 for i in range(len(names))],values,width=.25,label=klass,color=colors[klass])
        plt.xticks(range(len(names)),names,rotation=15);plt.ylim(0,1);plt.ylabel('Sieganteil');plt.title('Native isolierte Bosskämpfe (gemischte Testbedingungen)');plt.legend();save('boss-win-rates')
    attacks=sorted(analysis['boss_abilities'].items())
    if attacks:
        plt.figure(figsize=(15,6))
        xs=list(range(len(attacks)))
        for offset,field,label in [(-.3,'activations','Aktivierungen'),(-.1,'activations_hit','Mit Treffer'),(.1,'avoided_threatened','Bedroht, vermieden'),(.3,'fatal_hits','Tödliche Treffer')]:
            plt.bar([x+offset for x in xs],[v[field] for _,v in attacks],width=.2,label=label)
        plt.xticks(xs,[k for k,_ in attacks],rotation=70,ha='right');plt.title('Gemessene Bossattacken (keine Unvermeidbarkeitsbehauptung)');plt.ylabel('Anzahl');plt.legend();save('boss-ability-hits')
    fatal=Counter()
    for r in runs:
        source=r.get('metrics',{}).get('last_fatal') or {}
        source=source.get('source',{})
        if r.get('end_reason') in ('death','player_death'):fatal[str(source.get('kind','nicht zugeordnet'))+':'+str(source.get('boss',''))]+=1
    if fatal:
        names,values=zip(*fatal.most_common());plt.barh(names,values,color='#94594e');plt.xlabel('Todesfälle');plt.title('Tatsächliche letzte tödliche Schadensquelle');save('death-causes')
    matched=analysis['paired_before_after']
    if matched:
        for klass in CLASSES:
            sub=[r for r in matched if r['class_name']==klass]
            if sub:
                stats=[describe([x[k] for x in sub]) for k in ['before','after']]
                means=[s['mean'] for s in stats]
                lower=[s['mean']-s['mean_bootstrap95'][0] for s in stats];upper=[s['mean_bootstrap95'][1]-s['mean'] for s in stats]
                plt.errorbar([0,1],means,yerr=[lower,upper],marker='o',capsize=4,color=colors[klass],label=f'{klass} (n={len(sub)})')
        plt.xticks([0,1],['Vorher','Nachher']);plt.ylim(bottom=0)
        plt.ylabel('Beobachtete Überlebenszeit / s');plt.title('Gleiche Seeds und Bot-Regeln – gepaarter Vergleich\nMittelwerte mit 95%-Bootstrapintervallen');plt.legend();save('before-after')

def main():
    parser=argparse.ArgumentParser()
    for name in ['runs','boss','bench']:parser.add_argument('--'+name,type=Path,nargs='*',default=[])
    parser.add_argument('--charts',action='store_true');args=parser.parse_args()
    raw_runs=read(args.runs);raw_boss=read(args.boss);raw_bench=read(args.bench)
    runs=[r for r in raw_runs if r.get('completed') and r.get('end_reason') in ['death','survived_1800_seconds_censored'] and r.get('record_type','full_run')=='full_run']
    bosses=[r for r in raw_boss if r.get('record_type')=='boss_encounter']
    bench=[r for r in raw_bench if r.get('record_type')=='controlled_benchmark']
    ids=[r['run_id'] for r in runs]
    if len(ids)!=len(set(ids)):raise RuntimeError('Duplicate full-run IDs: supply nonoverlapping checkpoint files')
    before={(r['seed'],r['class_name'],r['persona']):r for r in runs if r.get('phase')=='baseline'}
    pairs=[]
    for r in runs:
        key=(r['seed'],r['class_name'],r['persona'])
        if r.get('phase')=='after' and key in before:pairs.append(dict(seed=key[0],class_name=key[1],persona=key[2],before=before[key]['seconds'],after=r['seconds'],delta=r['seconds']-before[key]['seconds']))
    analysis=dict(full_runs=len(runs),boss_encounters=len(bosses),boss_completed=sum(bool(r.get('completed')) for r in bosses),
                  controlled_benchmark_cells=len(bench),excluded_run_records=len(raw_runs)-len(runs),
                  class_persona=summary_runs(runs),class_pooled=summary_runs([dict(r,persona='pooled') for r in runs]),
                  boss_groups=summary_bosses(bosses),sources=source_totals(runs),
                  sources_by_phase={phase:source_totals([r for r in runs if r.get('phase')==phase]) for phase in sorted(set(r.get('phase','unknown') for r in runs))},
                  boss_abilities=attack_totals(bosses),
                  paired_before_after=pairs,input_files={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in args.runs+args.boss+args.bench},
                  statistical_notes=['95% Wilson intervals for binary outcomes; seeded 1000-resample bootstrap intervals for means.',
                    '1800-second survivors are right-censored. Reported mean is the observed/restricted mean to 30 minutes.',
                    'Bots and isolated stationary benchmarks do not establish human skill, human survival or universal ability rankings.',
                    'Equal production RNG seeds across classes do not force identical worlds: combat/cosmetic RNG consumption can differ.',
                    'No attack is labelled technically unavoidable merely because a greedy bot was hit.'])
    out=ROOT/'QA/data';out.mkdir(exist_ok=True)
    (out/'analysis.json').write_text(json.dumps(analysis,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    export_csv(out/'runs.csv',runs,['run_id','phase','seed','class_name','persona','end_reason','seconds','level','kills','bosses_defeated','hp','max_hp','min_hp','xp_earned','coins','state_hash','native_artifact'])
    export_csv(out/'boss-encounters.csv',bosses,['run_id','phase','seed','boss','class_name','persona','spawn_minute','end_reason','won','censored','seconds','boss_hp_initial','boss_hp_remaining'])
    export_csv(out/'controlled-benchmarks.csv',bench,['kind','sid','level','target_count','tested_passive','comparison_level','variant','passive','passive_level','class_name','seconds','damage','dps','healing'])
    if args.charts:charts(runs,bosses,bench,analysis)
    print(json.dumps({k:analysis[k] for k in ['full_runs','boss_encounters','boss_completed','controlled_benchmark_cells','excluded_run_records']},indent=2))

if __name__=='__main__':main()
