"""Sequential native asset importer. Run only after generation/preparation/composition are complete."""
from pathlib import Path
import copy,json,shutil,sys,uuid
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads,dumps
ROOT=Path(__file__).resolve().parents[2]
import sys as _sys_ap; _sys_ap.path.insert(0, str(ROOT / 'tests' / 'tools' / 'assets')); import art_paths as AP  # noqa: E402
def main():
 project=loads((ROOT/'FirstGame.yyp').read_text(encoding='utf-8'));template=loads((ROOT/'sprites/spr_fg_coin_idle/spr_fg_coin_idle.yy').read_text());manifest=[]
 for family in ['twins','swamp']:
  for i in range(1,10):assert (ROOT/f'sounds/sfx_fg_{family}_{i}/sfx_fg_{family}_{i}.yy').is_file(),'Run compose_boss_v2.py first'
 folder_path='folders/Sprites/Boss_System_2.yy'
 if not any(f['folderPath']==folder_path for f in project['Folders']):
  f=copy.deepcopy(project['Folders'][0]);f.update(name='Boss_System_2',folderPath=folder_path);f['%Name']='Boss_System_2';project['Folders'].append(f)
 project['Folders'].sort(key=lambda f:f['folderPath'])
 frames=AP.BOSS_V2/'frames'
 def sprite(name,paths,size,origin):
  assert paths and all(p.exists() for p in paths),(name,paths)
  d=copy.deepcopy(template);d['name']=d['%Name']=d['sequence']['name']=name;d.update(width=size,height=size,bboxMode=0,bbox_left=0,bbox_top=0,bbox_right=size-1,bbox_bottom=size-1,origin=9)
  d['parent']={'name':'Boss_System_2','path':folder_path}
  seq=d['sequence'];seq.update(xorigin=origin[0],yorigin=origin[1],seqWidth=float(size),seqHeight=float(size),length=float(len(paths)));ft=copy.deepcopy(d['frames'][0]);kt=copy.deepcopy(seq['tracks'][0]['keyframes']['Keyframes'][0]);d['frames']=[];keys=[];layer=d['layers'][0]['name'];folder=ROOT/'sprites'/name;folder.mkdir(exist_ok=True)
  for i,p in enumerate(paths):
   uid=str(uuid.uuid5(uuid.NAMESPACE_URL,f'FirstGame/bossv2/{name}/{i}'));f=copy.deepcopy(ft);f['name']=f['%Name']=uid;d['frames'].append(f);k=copy.deepcopy(kt);k['id']=str(uuid.uuid5(uuid.NAMESPACE_URL,f'FirstGame/bossv2/key/{name}/{i}'));k['Key']=float(i);k['Channels']['0']['Id']={'name':uid,'path':f'sprites/{name}/{name}.yy'};keys.append(k);shutil.copyfile(p,folder/f'{uid}.png');dest=folder/'layers'/uid;dest.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,dest/f'{layer}.png')
  seq['tracks'][0]['keyframes']['Keyframes']=keys;(folder/f'{name}.yy').write_text(dumps(d),encoding='utf-8')
  if not any(r['id']['name']==name for r in project['resources']):project['resources'].append({'id':{'name':name,'path':f'sprites/{name}/{name}.yy'}})
  manifest.append(dict(name=name,frames=len(paths),canvas=size,origin=origin))
 def row(source,index,columns=range(4)):return [frames/source/f'{index}-{i}.png' for i in columns]
 for family in ['fire','ice']:
  for action,index,cols in [('idle',0,range(4)),('fly',1,range(4)),('fast',2,range(4)),('turn',1,range(4)),('charge',3,range(4)),('cast',4,range(4)),('joint',5,range(4)),('hurt',6,[0,1]),('phase',6,[2,3]),('death',7,range(4))]:sprite(f'spr_bv2_{family}_{action}',row(family,index,cols),128,[64,116])
 for action,source,index,cols in [('idle','behemoth_life',0,range(4)),('walk','behemoth_life',1,range(4)),('turn','behemoth_life',2,range(4)),('death','behemoth_life',3,range(4)),('roots','behemoth_attacks',0,range(4)),('spit','behemoth_attacks',1,range(4)),('stomp','behemoth_attacks',2,range(4)),('summon','behemoth_attacks',3,range(4)),('breath','behemoth_attacks',4,range(4)),('wave','behemoth_attacks',5,range(4)),('bloom','behemoth_attacks',6,range(4)),('hurt','behemoth_attacks',7,[0,1]),('phase','behemoth_attacks',7,[2,3])]:sprite('spr_bv2_behemoth_'+action,row(source,index,cols),512,[256,480])
 for family in ['twins','swamp']:
  for index in range(9):sprite(f'spr_bv2_{family}_fx_{index}',row(family+'_fx',index),256,[128,128])
 sprite('spr_bv2_brood',row('brood',0),96,[48,88])
 for index,family in enumerate(['fire','ice']):sprite('spr_bv2_'+family+'_projectile',row('projectiles',index),128,[64,64])
 for family in ['twins','swamp']:
  for i in range(1,10):
   name=f'sfx_fg_{family}_{i}';assert (ROOT/f'sounds/{name}/{name}.yy').is_file(),name
   if not any(r['id']['name']==name for r in project['resources']):project['resources'].append({'id':{'name':name,'path':f'sounds/{name}/{name}.yy'}})
 project['resources'].sort(key=lambda r:r['id']['name'].lower());(ROOT/'FirstGame.yyp').write_text(dumps(project),encoding='utf-8');(frames.parent/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8');print('Imported',len(manifest),'actual new boss sprites /',sum(r['frames'] for r in manifest),'frames and 18 boss cues')
if __name__=='__main__':main()
