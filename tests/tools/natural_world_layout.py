"""Authored biome clusters and two coherent ruin sites; no regular field of monuments."""
import math,random

def generate_layout():
 rng=random.Random(712403);layout=[];trees=[]
 def add(prop,x,y,scale=1):layout.append(dict(prop=prop,x=round(x,2),y=round(y,2),scale=round(scale,3)))
 def clear(x,y):
  if math.hypot(x-2100,y-2050)<350:return True
  if abs(x-(2048+180*math.sin(y/650)))<140:return True
  if abs(y-(1952+90*math.sin(x/700)))<130:return True
  return False
 centres=[(380,380),(1120,360),(2850,460),(3670,600),(550,1260),(3130,1270),(390,2480),(1230,2700),(3100,2740),(3760,2350),(480,3550),(1630,3670),(2850,3550),(3670,3660)]
 for cluster,(cx,cy) in enumerate(centres):
  species=['oak','ancient'] if cluster%3==0 else (['maple','oak'] if cluster%3==1 else ['pine','oak'])
  for _ in range(42):
   x=cx+rng.gauss(0,155);y=cy+rng.gauss(0,145)
   if not (75<x<4020 and 180<y<4020) or clear(x,y):continue
   if any(math.hypot(x-a,y-b)<85 for a,b in trees):continue
   trees.append((x,y));add(rng.choice(species),x,y,rng.uniform(.9,1.25))
   for n in range(rng.randint(2,4)):
    a=rng.random()*math.tau;radius=rng.uniform(25,80)
    add(rng.choice(['ferns','redshrub','blueflowers','goldbush','leaves']),x+math.cos(a)*radius,y+math.sin(a)*radius*.6,rng.uniform(.65,1.05))
  if cluster%2==0:add('rocks',cx+140,cy+85,rng.uniform(.85,1.1))
  if cluster%3==0:add('stump',cx-110,cy+140,.95)
 # Small understory islands, placed around clearings rather than a room-wide grid.
 for cx,cy in [(1660,1560),(2520,2250),(1490,2250),(2400,960),(1980,2850),(2680,3230)]:
  for n in range(14):
   a=rng.random()*math.tau;r=rng.uniform(15,100)
   add(rng.choice(['ferns','blueflowers','leaves']),cx+math.cos(a)*r,cy+math.sin(a)*r*.65,rng.uniform(.6,.95))
 # Two readable architectural remnants: an eastern cloister and a northwestern gateway.
 for cx,cy in [(2140,1660),(1010,970)]:
  add('arch',cx,cy,1.25)
  add('pillar',cx-185,cy+145,1.6);add('pillar',cx+185,cy+145,1.6)
  add('wall',cx-230,cy+40,1.2);add('wall',cx+230,cy+40,1.2)
  add('brazier',cx-140,cy+210,.9);add('brazier',cx+140,cy+210,.9)
  for dx,dy in [(-90,65),(0,100),(85,80),(-30,170),(65,220)]:add('paving',cx+dx,cy+dy,1.15)
  for dx in [-260,250]:add('redshrub',cx+dx,cy+90,.9)
 return layout

if __name__=='__main__':
 from collections import Counter
 data=generate_layout();print(len(data),Counter(x['prop'] for x in data))
