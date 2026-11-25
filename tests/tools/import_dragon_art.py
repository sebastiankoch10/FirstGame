"""Import the 24 new dragon poses and eight dedicated VFX frames into native resources."""
from pathlib import Path
import sys,copy,uuid,shutil,json
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads,dumps
R=Path(__file__).resolve().parents[2];project=loads((R/'FirstGame.yyp').read_text(encoding='utf-8'));template=loads((R/'sprites/spr_fg_coin_idle/spr_fg_coin_idle.yy').read_text())
import sys as _sys_ap; _sys_ap.path.insert(0, str(R / 'tests' / 'tools' / 'assets')); import art_paths as AP  # noqa: E402
def sprite(name,paths,width,height,origin):
 d=copy.deepcopy(template);d['name']=d['%Name']=d['sequence']['name']=name
 d.update(width=width,height=height,bboxMode=0,bbox_left=0,bbox_top=0,bbox_right=width-1,bbox_bottom=height-1,origin=9)
 seq=d['sequence'];seq.update(xorigin=origin[0],yorigin=origin[1],seqWidth=float(width),seqHeight=float(height),length=float(len(paths)))
 ft=copy.deepcopy(d['frames'][0]);kt=copy.deepcopy(seq['tracks'][0]['keyframes']['Keyframes'][0]);d['frames']=[];keys=[];layer=d['layers'][0]['name'];folder=R/'sprites'/name;folder.mkdir(exist_ok=True)
 for i,source in enumerate(paths):
  uid=str(uuid.uuid5(uuid.NAMESPACE_URL,f'FirstGame/dragon/{name}/{i}'));f=copy.deepcopy(ft);f['name']=f['%Name']=uid;d['frames'].append(f)
  k=copy.deepcopy(kt);k['id']=str(uuid.uuid5(uuid.NAMESPACE_URL,f'FirstGame/dragon/key/{name}/{i}'));k['Key']=float(i);k['Channels']['0']['Id']={'name':uid,'path':f'sprites/{name}/{name}.yy'};keys.append(k)
  shutil.copyfile(source,folder/f'{uid}.png');dest=folder/'layers'/uid;dest.mkdir(parents=True,exist_ok=True);shutil.copyfile(source,dest/f'{layer}.png')
 seq['tracks'][0]['keyframes']['Keyframes']=keys;(folder/f'{name}.yy').write_text(dumps(d),encoding='utf-8')
 if not any(r['id']['name']==name for r in project['resources']):project['resources'].append({'id':{'name':name,'path':f'sprites/{name}/{name}.yy'}})
frames=AP.DRAGON_BOSS/'frames'
for action in ['idle','walk','turn','hurt','phase','charge','breath','breath_up','breath_down','stomp','death']:
 paths=sorted(frames.glob(action+'-[0-9].png'));assert paths,action;sprite('spr_fg_dragonboss_'+action,paths,512,512,(256,480))
for name,w,h,origin in [('flame',128,64,(64,32)),('muzzle',96,96,(48,48)),('magma',96,160,(48,150))]:sprite('spr_fg_dragonboss_'+name,sorted(frames.glob(name+'-*.png')),w,h,origin)
project['resources'].sort(key=lambda r:r['id']['name'].lower());(R/'FirstGame.yyp').write_text(dumps(project),encoding='utf-8')
anchors=json.loads((AP.DRAGON_BOSS/'anchors.json').read_text(encoding='utf-8-sig'))
code='/// Editable mouth anchors from source pose annotations and import transform.\nfunction dragon_art_anchor(_action,_frame) {\n static data={'+','.join(action+':'+json.dumps(values) for action,values in anchors.items())+'};\n if(!variable_struct_exists(data,_action))return [150,-300];\n var points=variable_struct_get(data,_action);return points[clamp(_frame,0,array_length(points)-1)];\n}\n'
(AP.DRAGON_BOSS/'anchors.gml.txt').write_text(code,encoding='utf-8')
# GameMaker compiles the primary file; append generated helper in it, retaining editable source.
p=R/'scripts/dragon_boss/dragon_boss.gml';s=p.read_text(encoding='utf-8');marker='/// Editable mouth anchors';s=s.split(marker)[0]+code;p.write_text(s,encoding='utf-8')
