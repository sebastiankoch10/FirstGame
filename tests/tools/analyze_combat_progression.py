"""Budget sensitivity from real configured XP costs and the user's observed level anchor.
No kill rate below is falsely presented as measured gameplay telemetry.
"""
from pathlib import Path
import json,math,re
R=Path(__file__).resolve().parents[2]
s=(R/'scripts/survivor_balance/survivor_balance.gml').read_text(encoding='utf-8');base=float(re.search(r'cfg=\{base:([0-9.]+)',s).group(1));slope=float(re.search(r'base:[0-9.]+,slope:([0-9.]+)',s).group(1))
def cost(level):return level if level<=3 else math.ceil(base+slope*(level-4))
bosses=[(60,8),(180,12),(300,30),(600,35),(900,40),(1200,45),(1500,50),(1800,60)]
spent52=sum(cost(lv) for lv in range(1,52));rate=(spent52-50)/7

def simulate(kind):
 level=1;pool=0;chests=0;full=None;milestones={};earned=0
 for second in range(1,1801):
  t=second/60
  if kind=='prior_success_model':kpm=45+14*t
  elif kind=='observed_constant':kpm=rate
  elif kind=='observed_then_faster':kpm=rate if t<=7 else 396
  else:kpm=rate if t<=7 else 180
  pool+=kpm/60;earned+=kpm/60
  for at,reward in bosses:
   if second==at:pool+=reward;chests+=1
  while pool+1e-8>=cost(level):pool=max(0,pool-cost(level));level+=1
  steps=min(108,level-1+chests)
  if steps==108 and full is None:full=round(t,3)
  if second in [60,180,300,420,600,900,1200,1500,1680,1740,1800]:milestones[str(round(t))]={'level':level,'available_upgrade_choices':steps,'collected_regular_coin_xp':round(earned)}
 return {'full_build_minute':full,'milestones':milestones}
report={'curve_unchanged':True,'cost':{'first':[1,2,3],'base':base,'slope':slope},'observed_anchor':{'source':'user report; not a recovered runtime log','minute':7,'level':52,'minimum_spent_total_xp':spent52,'possible_unspent_xp_max':cost(52)-1,'assumed_first_three_boss_xp':50,'implied_regular_collected_coins_per_minute':rate,'ability_choices_with_three_chests':54},'xp_for_level102':sum(cost(lv) for lv in range(1,102)),'assumptions':['One coin per normal kill.','All scheduled bosses are defeated and each upgrade chest is collected.','Collected coin rates are models or observation-derived averages, not measured full-run kill rates.','No full thirty-minute runtime simulation was performed.'],'models':{name:simulate(name) for name in ['prior_success_model','observed_constant','observed_then_faster','observed_then_slower']}}
(R/'tests/reports/combat-progression.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
for name,data in report['models'].items():print(name,'full',data['full_build_minute'],[(minute,data['milestones'][str(minute)]['level'],data['milestones'][str(minute)]['available_upgrade_choices']) for minute in [1,3,5,7,10,30]])
