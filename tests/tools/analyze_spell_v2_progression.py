"""Budget model from actual GML curve; expected levels are assumptions, not fabricated play measurements."""
from pathlib import Path
import json,math,re
ROOT=Path(__file__).resolve().parents[2]

def config():
 text=(ROOT/'scripts/survivor_balance/survivor_balance.gml').read_text(encoding='utf-8')
 raw=re.search(r'function progression_config\(\).*?static cfg=(\{.*?\});',text).group(1)
 return json.loads(re.sub(r'([A-Za-z_]+):',r'"\1":',raw))

def cost(lv,c):
 if lv<=3:return c['first'][lv-1]
 if lv<=c['early_end']:return math.ceil(c['early_base']+c['early_step']*(lv-4))
 n=lv-c['early_end']-1;return math.ceil(c['late_base']+c['late_step']*n+c['late_curve']*n*n)

def run(base,slope):
 c=config();level=1;pool=0;last=-999;choices=0;chests=0;full=None;samples={};bosses={60:2,180:2,300:5,600:5,900:5,1200:5,1500:5}
 for sec in range(1,1801):
  pool+=(base+slope*sec/60)/60
  if sec in bosses:
   pool+=min(bosses[sec],math.floor(cost(level,c)*.12));chests+=1;last=sec
   if choices+chests>=108 and full is None:full=sec/60
  if pool+1e-8>=cost(level,c) and sec-last>=c['min_gap'] and choices+chests<108:
   pool-=cost(level,c);level+=1;choices+=1;last=sec
   if choices+chests>=108 and full is None:full=sec/60
  if sec in [60,180,300,600,900,1200,1500,1740]:samples[str(sec//60)]=dict(level=level,ability_decisions=choices+chests,coins_per_minute=round(base+slope*sec/60,1))
 return dict(samples=samples,full_build_minute=full)

def main():
 c=config();old_spent=sum(l if l<=3 else math.ceil(4+1.45*(l-4)) for l in range(1,47))
 # Compare the exact same reported minimum XP budget under the new thresholds.
 level=1;pool=old_spent
 while pool>=cost(level,c):pool-=cost(level,c);level+=1
 result=dict(status='PASS_MODEL_NOT_PLAY_MEASUREMENT',config=c,observed_user_anchor=dict(minute=5,level_old=47,minimum_old_spent_xp=old_spent,new_level_at_same_xp=level),
  xp_to_level102=sum(cost(l,c) for l in range(1,102)),models={
   'slower_45_plus_18_per_minute':run(45,18),'ordinary_80_plus_30_per_minute':run(80,30),'very_successful_70_plus_55_per_minute':run(70,55)},
  assumptions=['One XP coin per regular kill, all coins collected.','Kill rate ramps linearly; these are explicit model inputs, not measured rates.','First seven bosses defeated and each chest collected.','Upgrades chosen toward twelve nine-level abilities; no wasted picks.','Minimum six gameplay seconds between XP choices; pause time excluded.','Successful late rate stays below the spawner refill ceiling of 1800 kills/minute.'])
 (ROOT/'tests/reports/spell-v2-progression.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps(result,indent=2))

if __name__=='__main__':main()
