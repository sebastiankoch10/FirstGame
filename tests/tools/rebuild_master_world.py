"""Rebuild Room1's active world from the new master art only. No legacy decoration/tile fallback."""
from pathlib import Path
import copy,json,math,random,shutil,sys,uuid
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads,dumps
ROOT=Path(__file__).resolve().parents[2]
import sys as _sys_ap; _sys_ap.path.insert(0, str(ROOT / 'tests' / 'tools' / 'assets')); import art_paths as AP  # noqa: E402
ART=AP.MASTER_WORLD

def read(path):return loads((ROOT/path).read_text(encoding='utf-8'))
def write(path,data):(ROOT/path).write_text(dumps(data),encoding='utf-8')

def main():
 project=read('FirstGame.yyp');template=read('sprites/spr_fg_coin_idle/spr_fg_coin_idle.yy');manifest=[]
 def register(name,paths,width,height,origin):
  data=copy.deepcopy(template);data['name']=data['%Name']=data['sequence']['name']=name
  data.update(width=width,height=height,bboxMode=0,bbox_left=0,bbox_top=0,bbox_right=width-1,bbox_bottom=height-1,origin=9)
  seq=data['sequence'];seq.update(xorigin=origin[0],yorigin=origin[1],seqWidth=float(width),seqHeight=float(height),length=float(len(paths)))
  ft=copy.deepcopy(data['frames'][0]);kt=copy.deepcopy(seq['tracks'][0]['keyframes']['Keyframes'][0]);data['frames']=[];keys=[]
  layer=data['layers'][0]['name'];folder=ROOT/'sprites'/name;folder.mkdir(exist_ok=True)
  assert paths,name
  for i,source in enumerate(paths):
   assert source.is_file(),source
   uid=str(uuid.uuid5(uuid.NAMESPACE_URL,f'FirstGame/master/{name}/{i}'));frame=copy.deepcopy(ft);frame['name']=frame['%Name']=uid;data['frames'].append(frame)
   key=copy.deepcopy(kt);key['id']=str(uuid.uuid5(uuid.NAMESPACE_URL,f'FirstGame/master/key/{name}/{i}'));key['Key']=float(i);key['Channels']['0']['Id']={'name':uid,'path':f'sprites/{name}/{name}.yy'};keys.append(key)
   shutil.copyfile(source,folder/f'{uid}.png');dest=folder/'layers'/uid;dest.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,dest/f'{layer}.png')
  seq['tracks'][0]['keyframes']['Keyframes']=keys;write(f'sprites/{name}/{name}.yy',data)
  if not any(x['id']['name']==name for x in project['resources']):project['resources'].append({'id':{'name':name,'path':f'sprites/{name}/{name}.yy'}})
  manifest.append(dict(name=name,frames=len(paths),width=width,height=height,origin=origin))
 frame=ART/'frames'
 register('spr_master_ground',[frame/'ground.png'],512,512,[0,0])
 props=['oak','maple','pine','ancient','ferns','redshrub','blueflowers','goldbush','pillar','arch','wall','brazier','rocks','stump','paving','leaves']
 for prop in props:register('spr_master_'+prop,[frame/f'{prop}.png'],256,320,[128,304])
 for action in ['idle','walk','attack','hurt','death']:
  for direction in ['right','up_right','up','up_left','left','down_left','down','down_right']:
   register(f'spr_master_skeleton_{action}_{direction}',sorted(frame.glob(f'skeleton-{action}-{direction}-*.png')),96,96,[48,88])
 for stage in range(1,4):register(f'spr_master_slash_{stage}',sorted(frame.glob(f'slash-{stage}-*.png')),256,256,[128,128])
 # New objects are isolated from the older rooms' scenery renderer.
 for name,events in [('ObjectMasterWorld',[(0,0),(8,0)]),('ObjectMasterScenery',[(0,0),(8,0)]),('ObjectSkeletonRemains',[(0,0),(3,0),(8,0)])]:
  data=read('objects/ObjectEnvironmentDecoration/ObjectEnvironmentDecoration.yy');data['name']=data['%Name']=name;data['spriteId']=None
  data['eventList']=[{'$GMEvent':'v1','%Name':'','collisionObjectId':None,'eventNum':num,'eventType':kind,'isDnD':False,'name':'','resourceType':'GMEvent','resourceVersion':'2.0'} for kind,num in events]
  (ROOT/'objects'/name).mkdir(exist_ok=True);write(f'objects/{name}/{name}.yy',data)
  if not any(x['id']['name']==name for x in project['resources']):project['resources'].append({'id':{'name':name,'path':f'objects/{name}/{name}.yy'}})
 for name in ['master_world','master_combat','master_skeleton']:
  data=read('scripts/player_artpack/player_artpack.yy');data['name']=data['%Name']=name
  (ROOT/'scripts'/name).mkdir(exist_ok=True);write(f'scripts/{name}/{name}.yy',data)
  if not any(x['id']['name']==name for x in project['resources']):project['resources'].append({'id':{'name':name,'path':f'scripts/{name}/{name}.yy'}})
 # Preserve the four gameplay objects. Remove every old scenery/tile layer, not merely hide it.
 room=read('rooms/Room1/Room1.yy');old_counts={'layers':len(room['layers']),'legacy_scenery':sum(len(l.get('instances',[])) for l in room['layers'][1:]),'tilesets':sorted({l['tilesetId']['name'] for l in room['layers'] if l.get('tilesetId')})}
 baseline=ART/'previous-active-assets.json'
 if baseline.exists():old_counts=json.loads(baseline.read_text(encoding='utf-8'))['removed']
 base=copy.deepcopy(room['layers'][0]);base['instances']=[i for i in base['instances'] if i['objectId']['name'] in ['ObjectController','ObjectOverlay','ObjectPlayer','ObjectSpawner']]
 item=copy.deepcopy(base['instances'][0])
 item['name']=item['%Name']='inst_master_world';item.update(x=0.0,y=0.0,objectId={'name':'ObjectMasterWorld','path':'objects/ObjectMasterWorld/ObjectMasterWorld.yy'})
 base['instances'].append(item)
 scenery=copy.deepcopy(base);scenery['name']=scenery['%Name']='MasterScenery';scenery['depth']=100;scenery['instances']=[]
 rng=random.Random(42187);layout=[]
 def add(prop,x,y,scale=1):
  name=f'inst_master_{len(layout):04d}';i=copy.deepcopy(item);i['name']=i['%Name']=name
  i.update(x=float(x),y=float(y),scaleX=scale,scaleY=scale,objectId={'name':'ObjectMasterScenery','path':'objects/ObjectMasterScenery/ObjectMasterScenery.yy'},imageIndex=props.index(prop),imageSpeed=0.0)
  scenery['instances'].append(i);layout.append(dict(prop=prop,x=x,y=y,scale=scale))
 # Natural biome clusters and only two coherent archaeological sites.
 from natural_world_layout import generate_layout
 for point in generate_layout():add(point['prop'],point['x'],point['y'],point['scale'])
 room['layers']=[base,scenery];room['instanceCreationOrder']=[{'name':i['name'],'path':'rooms/Room1/Room1.yy'} for l in room['layers'] for i in l['instances']]
 write('rooms/Room1/Room1.yy',room)
 project['resources'].sort(key=lambda x:x['id']['name'].lower());write('FirstGame.yyp',project)
 (ART/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
 (ART/'layout.json').write_text(json.dumps(layout,indent=2)+'\n',encoding='utf-8')
 report=dict(removed=old_counts,new_scenery=len(layout),room_layers=[l['name'] for l in room['layers']],resources=len(manifest),frames=sum(x['frames'] for x in manifest),seed=712403)
 (ROOT/'tests/reports/master-world-import.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(json.dumps(report,indent=2))

if __name__=='__main__':main()
