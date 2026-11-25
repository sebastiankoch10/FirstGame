"""Register only real v2 art and runtime scripts. No legacy visual fallback."""
from pathlib import Path
import copy,json,shutil,sys,uuid
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads,dumps
ROOT=Path(__file__).resolve().parents[2]
import sys as _sys_ap; _sys_ap.path.insert(0, str(ROOT / 'tests' / 'tools' / 'assets')); import art_paths as AP  # noqa: E402

def main():
 project=loads((ROOT/'FirstGame.yyp').read_text(encoding='utf-8'));template=loads((ROOT/'sprites/spr_fg_coin_idle/spr_fg_coin_idle.yy').read_text(encoding='utf-8'));frames=AP.SPELL_V2/'frames';manifest=[]
 def sprite(name,paths,size,origin):
  d=copy.deepcopy(template);d['name']=d['%Name']=d['sequence']['name']=name;d.update(width=size,height=size,bboxMode=0,bbox_left=0,bbox_top=0,bbox_right=size-1,bbox_bottom=size-1,origin=9)
  seq=d['sequence'];seq.update(xorigin=origin[0],yorigin=origin[1],seqWidth=float(size),seqHeight=float(size),length=float(len(paths)))
  ft=copy.deepcopy(d['frames'][0]);kt=copy.deepcopy(seq['tracks'][0]['keyframes']['Keyframes'][0]);d['frames']=[];keys=[];layer=d['layers'][0]['name'];folder=ROOT/'sprites'/name;folder.mkdir(exist_ok=True)
  for i,p in enumerate(paths):
   assert p.exists(),p
   uid=str(uuid.uuid5(uuid.NAMESPACE_URL,f'FirstGame/spellv2/{name}/{i}'));f=copy.deepcopy(ft);f['name']=f['%Name']=uid;d['frames'].append(f);k=copy.deepcopy(kt);k['id']=str(uuid.uuid5(uuid.NAMESPACE_URL,f'FirstGame/spellv2/key/{name}/{i}'));k['Key']=float(i);k['Channels']['0']['Id']={'name':uid,'path':f'sprites/{name}/{name}.yy'};keys.append(k)
   shutil.copyfile(p,folder/f'{uid}.png');dest=folder/'layers'/uid;dest.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,dest/f'{layer}.png')
  seq['tracks'][0]['keyframes']['Keyframes']=keys;(folder/(name+'.yy')).write_text(dumps(d),encoding='utf-8')
  if not any(x['id']['name']==name for x in project['resources']):project['resources'].append({'id':{'name':name,'path':f'sprites/{name}/{name}.yy'}})
  manifest.append(dict(name=name,frames=len(paths),size=size,origin=origin))
 for sid in list(range(101,119))+list(range(201,219)):sprite(f'icon_v2_{sid}',[frames/f'icon-{sid}.png'],64,[0,0])
 for row in range(6):sprite(f'spr_v2_fx_{row}',[frames/f'fx-{row}-{i}.png' for i in range(4)],256,[128,128])
 script_template=loads((ROOT/'scripts/player_artpack/player_artpack.yy').read_text(encoding='utf-8'))
 for name in ['spell_v2_catalog','spell_v2','spell_choices_v2','spell_ui_v2','spell_world_v2']:
  d=copy.deepcopy(script_template);d['name']=d['%Name']=name;(ROOT/'scripts'/name).mkdir(exist_ok=True);(ROOT/f'scripts/{name}/{name}.yy').write_text(dumps(d),encoding='utf-8')
  assert (ROOT/f'scripts/{name}/{name}.gml').exists()
  if not any(x['id']['name']==name for x in project['resources']):project['resources'].append({'id':{'name':name,'path':f'scripts/{name}/{name}.yy'}})
 project['resources'].sort(key=lambda x:x['id']['name'].lower());(ROOT/'FirstGame.yyp').write_text(dumps(project),encoding='utf-8')
 (frames.parent/'art-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8');print('Registered 36 icons, 6 animated effects and 5 runtime modules')

if __name__=='__main__':main()
