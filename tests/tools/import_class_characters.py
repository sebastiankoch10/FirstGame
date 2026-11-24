"""Import prepared class character frames. Run sequentially after other YYP writers."""
from pathlib import Path
import copy,json,shutil,sys,uuid
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads,dumps
ROOT=Path(__file__).resolve().parents[2]
def main():
 project=loads((ROOT/'FirstGame.yyp').read_text(encoding='utf-8'))
 template=loads((ROOT/'sprites/spr_fg_coin_idle/spr_fg_coin_idle.yy').read_text(encoding='utf-8'))
 base=ROOT/'FirstGame_ArtPack/class_overhaul/frames';manifest=[]
 dirs=['right','up_right','up','up_left','left','down_left','down','down_right']
 actions=['idle','turn','walk','run','attack1','attack2','attack3','jump','fall','dive','landing','slide','dodge','hurt','death']
 for actor in ['magev3','rangerv3']:
  for action in actions+(['attack4'] if actor=='magev3' else []):
   for direction in dirs:
    paths=sorted((base/actor).glob(f'{action}-{direction}-*.png'));assert paths,(actor,action,direction)
    name=f'spr_fg_{actor}_{action}_{direction}';d=copy.deepcopy(template)
    d['name']=d['%Name']=d['sequence']['name']=name
    d.update(width=96,height=96,bboxMode=0,bbox_left=0,bbox_top=0,bbox_right=95,bbox_bottom=95,origin=9)
    seq=d['sequence'];seq.update(xorigin=48,yorigin=88,seqWidth=96.0,seqHeight=96.0,length=float(len(paths)))
    ft=copy.deepcopy(d['frames'][0]);kt=copy.deepcopy(seq['tracks'][0]['keyframes']['Keyframes'][0]);d['frames']=[];keys=[];layer=d['layers'][0]['name'];folder=ROOT/'sprites'/name;folder.mkdir(exist_ok=True)
    for i,p in enumerate(paths):
     uid=str(uuid.uuid5(uuid.NAMESPACE_URL,f'FirstGame/classes/{name}/{i}'));f=copy.deepcopy(ft);f['name']=f['%Name']=uid;d['frames'].append(f)
     k=copy.deepcopy(kt);k['id']=str(uuid.uuid5(uuid.NAMESPACE_URL,f'FirstGame/classes/key/{name}/{i}'));k['Key']=float(i);k['Channels']['0']['Id']={'name':uid,'path':f'sprites/{name}/{name}.yy'};keys.append(k)
     shutil.copyfile(p,folder/f'{uid}.png');dest=folder/'layers'/uid;dest.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,dest/f'{layer}.png')
    seq['tracks'][0]['keyframes']['Keyframes']=keys;(folder/(name+'.yy')).write_text(dumps(d),encoding='utf-8')
    if not any(x['id']['name']==name for x in project['resources']):project['resources'].append({'id':{'name':name,'path':f'sprites/{name}/{name}.yy'}})
    manifest.append(dict(name=name,actor=actor,action=action,direction=direction,frames=len(paths),canvas=[96,96],origin=[48,88]))
 project['resources'].sort(key=lambda r:r['id']['name'].lower());(ROOT/'FirstGame.yyp').write_text(dumps(project),encoding='utf-8')
 (base.parent/'character-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
 print('Imported',len(manifest),'class sprites,',sum(d['frames'] for d in manifest),'frames')
if __name__=='__main__':main()
