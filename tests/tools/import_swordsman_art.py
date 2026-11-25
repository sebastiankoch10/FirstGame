"""Register the v3 swordsman frames as native GameMaker resources. No old art fallback."""
from pathlib import Path
import copy, json, shutil, sys, uuid
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads,dumps
ROOT=Path(__file__).resolve().parents[2]
import sys as _sys_ap; _sys_ap.path.insert(0, str(ROOT / 'tests' / 'tools' / 'assets')); import art_paths as AP  # noqa: E402

def main():
 project=loads((ROOT/'FirstGame.yyp').read_text(encoding='utf-8'))
 template=loads((ROOT/'sprites/spr_fg_coin_idle/spr_fg_coin_idle.yy').read_text(encoding='utf-8'))
 frames=AP.SWORDSMAN_V3/'frames'
 directions=['right','up_right','up','up_left','left','down_left','down','down_right']
 actions=['idle','turn','walk','run','attack1','attack2','attack3','jump','fall','dive','landing','dodge','slide','hurt','death']
 manifest=[]
 for action in actions:
  for direction in directions:
   paths=sorted(frames.glob(f'{action}-{direction}-[0-9].png'))
   assert paths,(action,direction)
   name=f'spr_fg_swordsmanv3_{action}_{direction}'
   data=copy.deepcopy(template)
   data['name']=data['%Name']=data['sequence']['name']=name
   data.update(width=96,height=96,bboxMode=0,bbox_left=0,bbox_top=0,bbox_right=95,bbox_bottom=95,origin=9)
   seq=data['sequence'];seq.update(xorigin=48,yorigin=88,seqWidth=96.0,seqHeight=96.0,length=float(len(paths)))
   frame_template=copy.deepcopy(data['frames'][0]);key_template=copy.deepcopy(seq['tracks'][0]['keyframes']['Keyframes'][0])
   data['frames']=[];keys=[];layer=data['layers'][0]['name'];folder=ROOT/'sprites'/name;folder.mkdir(exist_ok=True)
   for i,path in enumerate(paths):
    uid=str(uuid.uuid5(uuid.NAMESPACE_URL,f'FirstGame/swordsmanv3/{name}/{i}'))
    frame=copy.deepcopy(frame_template);frame['name']=frame['%Name']=uid;data['frames'].append(frame)
    key=copy.deepcopy(key_template);key['id']=str(uuid.uuid5(uuid.NAMESPACE_URL,f'FirstGame/swordsmanv3/key/{name}/{i}'));key['Key']=float(i)
    key['Channels']['0']['Id']={'name':uid,'path':f'sprites/{name}/{name}.yy'};keys.append(key)
    shutil.copyfile(path,folder/f'{uid}.png');dest=folder/'layers'/uid;dest.mkdir(parents=True,exist_ok=True);shutil.copyfile(path,dest/f'{layer}.png')
   seq['tracks'][0]['keyframes']['Keyframes']=keys
   (folder/f'{name}.yy').write_text(dumps(data),encoding='utf-8')
   if not any(r['id']['name']==name for r in project['resources']):project['resources'].append({'id':{'name':name,'path':f'sprites/{name}/{name}.yy'}})
   manifest.append(dict(name=name,action=action,direction=direction,frames=len(paths),width=96,height=96,origin=[48,88]))
 project['resources'].sort(key=lambda r:r['id']['name'].lower())
 (ROOT/'FirstGame.yyp').write_text(dumps(project),encoding='utf-8')
 (frames.parent/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
 print(f'Imported {len(manifest)} sprites / {sum(x["frames"] for x in manifest)} frames')

if __name__=='__main__':main()
