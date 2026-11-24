"""Import supplementary effects and scripts; never overwrite approved dragon resources."""
from pathlib import Path
import copy,json,shutil,sys,uuid
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads,dumps
ROOT=Path(__file__).resolve().parents[2]
def main():
 project=loads((ROOT/'FirstGame.yyp').read_text(encoding='utf-8'));template=loads((ROOT/'sprites/spr_fg_coin_idle/spr_fg_coin_idle.yy').read_text());manifest=[]
 def sprite(name,paths,size,origin):
  d=copy.deepcopy(template);d['name']=d['%Name']=d['sequence']['name']=name;d.update(width=size,height=size,bboxMode=0,bbox_left=0,bbox_top=0,bbox_right=size-1,bbox_bottom=size-1,origin=9)
  seq=d['sequence'];seq.update(xorigin=origin[0],yorigin=origin[1],seqWidth=float(size),seqHeight=float(size),length=float(len(paths)));ft=copy.deepcopy(d['frames'][0]);kt=copy.deepcopy(seq['tracks'][0]['keyframes']['Keyframes'][0]);d['frames']=[];keys=[];layer=d['layers'][0]['name'];folder=ROOT/'sprites'/name;folder.mkdir(exist_ok=True)
  for i,p in enumerate(paths):
   assert p.exists(),p
   uid=str(uuid.uuid5(uuid.NAMESPACE_URL,f'FirstGame/classes2026/{name}/{i}'));f=copy.deepcopy(ft);f['name']=f['%Name']=uid;d['frames'].append(f);k=copy.deepcopy(kt);k['id']=str(uuid.uuid5(uuid.NAMESPACE_URL,f'FirstGame/classes2026/key/{name}/{i}'));k['Key']=float(i);k['Channels']['0']['Id']={'name':uid,'path':f'sprites/{name}/{name}.yy'};keys.append(k);shutil.copyfile(p,folder/f'{uid}.png');dest=folder/'layers'/uid;dest.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,dest/f'{layer}.png')
  seq['tracks'][0]['keyframes']['Keyframes']=keys;(folder/f'{name}.yy').write_text(dumps(d),encoding='utf-8')
  if not any(r['id']['name']==name for r in project['resources']):project['resources'].append({'id':{'name':name,'path':f'sprites/{name}/{name}.yy'}})
  manifest.append(dict(name=name,frames=len(paths),size=size,origin=origin))
 frames=ROOT/'FirstGame_ArtPack/class_overhaul/frames'
 for prefix,source in [('spr_class_fx','class_fx'),('spr_dragon_fx','dragon_fx')]:
  for row in range(8):sprite(f'{prefix}_{row}',[frames/source/f'{row}-{i}.png' for i in range(8)],256,[128,128])
 for row,action in enumerate(['wingbeat','leap','channel','summon']):sprite('spr_fg_dragonextra_'+action,[frames/'dragon_poses'/f'{row}-{i}.png' for i in range(4)],512,[256,480])
 for row,action in enumerate(['orb','implosion']):sprite('spr_mage_star_'+action,[frames/'mage_orb'/f'{row}-{i}.png' for i in range(4)],256,[128,128])
 st=loads((ROOT/'scripts/spell_v2/spell_v2.yy').read_text())
 for name in ['attack_telegraph','class_weapons','dragon_encounter']:
  d=copy.deepcopy(st);d['name']=d['%Name']=name;(ROOT/f'scripts/{name}/{name}.yy').write_text(dumps(d),encoding='utf-8')
  if not any(r['id']['name']==name for r in project['resources']):project['resources'].append({'id':{'name':name,'path':f'scripts/{name}/{name}.yy'}})
 project['resources'].sort(key=lambda r:r['id']['name'].lower());(ROOT/'FirstGame.yyp').write_text(dumps(project),encoding='utf-8');(frames.parent/'effects-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8');print('Imported',len(manifest),'supplementary sprites and three runtime modules')
if __name__=='__main__':main()
