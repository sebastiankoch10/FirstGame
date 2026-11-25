"""Register sliced new RGBA artwork; no legacy sprites used as visual fallback."""
import copy,sys,uuid,shutil
from pathlib import Path
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads,dumps
R=Path(__file__).resolve().parents[2]
import sys as _sys_ap; _sys_ap.path.insert(0, str(R / 'tests' / 'tools' / 'assets')); import art_paths as AP  # noqa: E402
project=loads((R/'FirstGame.yyp').read_text(encoding='utf-8'))
template=loads((R/'sprites/spr_fg_coin_idle/spr_fg_coin_idle.yy').read_text(encoding='utf-8'))
def sprite(name,paths,size,origin):
 d=copy.deepcopy(template);d['name']=d['%Name']=d['sequence']['name']=name
 d.update(width=size,height=size,bboxMode=0,bbox_left=0,bbox_top=0,bbox_right=size-1,bbox_bottom=size-1,origin=9)
 seq=d['sequence'];seq.update(xorigin=origin[0],yorigin=origin[1],seqWidth=float(size),seqHeight=float(size),length=float(len(paths)))
 ft=copy.deepcopy(d['frames'][0]);kt=copy.deepcopy(seq['tracks'][0]['keyframes']['Keyframes'][0]);d['frames']=[];keys=[];layer=d['layers'][0]['name'];folder=R/'sprites'/name;folder.mkdir(exist_ok=True)
 for i,source in enumerate(paths):
  uid=str(uuid.uuid5(uuid.NAMESPACE_URL,f'FirstGame/v2/{name}/{i}'));f=copy.deepcopy(ft);f['name']=f['%Name']=uid;d['frames'].append(f)
  k=copy.deepcopy(kt);k['id']=str(uuid.uuid5(uuid.NAMESPACE_URL,f'FirstGame/v2/key/{name}/{i}'));k['Key']=float(i);k['Channels']['0']['Id']={'name':uid,'path':f'sprites/{name}/{name}.yy'};keys.append(k)
  shutil.copyfile(source,folder/f'{uid}.png');dest=folder/'layers'/uid;dest.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,dest/f'{layer}.png')
 seq['tracks'][0]['keyframes']['Keyframes']=keys;(folder/f'{name}.yy').write_text(dumps(d),encoding='utf-8')
 if not any(r['id']['name']==name for r in project['resources']):project['resources'].append({'id':{'name':name,'path':f'sprites/{name}/{name}.yy'}})
frames=AP.ATMOSPHERE_V2/'frames'
for action in ['idle','walk','run','attack','jump','fall','dive','slide','dodge','hurt','death']:
 for direction in ['right','left','up','down']:
  actual='right' if direction=='left' else direction
  paths=sorted(frames.glob(f'knight-{action}-{actual}-*.png'));assert paths,(action,direction)
  sprite(f'spr_fg_knightv2_{action}_{direction}',paths,64,(32,58))
for actor in ['golem','dragon']:sprite(f'spr_fg_boss_{actor}',sorted(frames.glob(f'boss-{actor}-*.png')),384,(192,360))
sprite('spr_fg_magnet_orb',[frames/'magnet-orb.png'],40,(20,20))
project['resources'].sort(key=lambda r:r['id']['name'].lower());(R/'FirstGame.yyp').write_text(dumps(project),encoding='utf-8')
