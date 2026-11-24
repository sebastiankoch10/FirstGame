"""Deterministic coin-budget model; kill rates are assumptions, not measured runtime DPS."""
import math,json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
cfg=(ROOT/"scripts/survivor_balance/survivor_balance.gml").read_text(encoding="utf-8")
COST_BASE=float(re.search(r"cfg=\{base:([0-9.]+)",cfg).group(1))
COST_SLOPE=float(re.search(r"base:[0-9.]+,slope:([0-9.]+)",cfg).group(1))
BOSSES=[(1,8),(3,12),(5,30),(10,35),(15,40),(20,45),(25,50),(30,60)]
def cost(lv):return lv if lv<=3 else math.ceil(COST_BASE+COST_SLOPE*(lv-4))
def simulate(base,growth,pickup):
 lv=1;pool=0.;chests=0;observed={};full=None
 for step in range(1,1801):
  minute=step/60
  pool+=(base+growth*minute)/60*pickup
  for at,reward in BOSSES:
   if step==at*60:pool+=reward;chests+=1
  while pool>=cost(lv):pool-=cost(lv);lv+=1
  upgrades=min(108,lv-1+chests)
  if upgrades==108 and full is None:full=round(minute,2)
  if step in [300,600,900,1200,1500,1680,1740,1800]:observed[str(int(minute))]={'level':lv,'available_upgrade_choices':upgrades,'boss_chests_assumed_collected':chests}
 return {'kill_rate_per_minute':f'{base}+{growth}*minute','coin_pickup_fraction':pickup,'full_build_minute':full,'milestones':observed}
result={'cost':{'first':[1,2,3],'base':COST_BASE,'slope':COST_SLOPE},'assumptions':['One XP coin per regular kill.','Kill rate increases linearly; rates are design assumptions.','Scheduled bosses die immediately and reward XP plus one collected upgrade chest.','All offered choices are spent on eligible upgrades; no forced unlocks.','Time is active gameplay; choice pauses excluded.'],'scenarios':{'struggling':simulate(25,5,.75),'steady':simulate(35,9,.9),'successful':simulate(45,14,1)}}
(ROOT/'tests/reports/atmosphere-progression.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps(result,indent=2))
