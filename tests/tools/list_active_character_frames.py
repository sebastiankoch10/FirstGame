from pathlib import Path
import json,sys
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads
ROOT=Path(__file__).resolve().parents[2]
data=[]
for path in (ROOT/'sprites').glob('spr_fg_*/*.yy'):
 if not path.parent.name.startswith(('spr_fg_swordsmanv3_','spr_fg_mage_','spr_fg_ranger_')):continue
 d=loads(path.read_text(encoding='utf-8'));layer=d['layers'][0]['name']
 for f in d['frames']:
  uid=f['name'];data.append(dict(sprite=path.parent.name,frame=uid,path=f'sprites/{path.parent.name}/{uid}.png',layer=f'sprites/{path.parent.name}/layers/{uid}/{layer}.png'))
(ROOT/'output/character_frames.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
print(len(data),'active playable character PNG frames')
