"""Register only actual new runtime modules; preserve the current resource registry."""
from pathlib import Path
import copy,sys
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads,dumps
ROOT=Path(__file__).resolve().parents[2]
def main():
 p=ROOT/'FirstGame.yyp';project=loads(p.read_text(encoding='utf-8'));template=loads((ROOT/'scripts/spell_v2/spell_v2.yy').read_text(encoding='utf-8'))
 for name in ['boss_framework_v2','boss_hazards_v2','boss_encounters_v2','boss_test_mode']:
  assert (ROOT/f'scripts/{name}/{name}.gml').is_file()
  data=copy.deepcopy(template);data['name']=data['%Name']=name;(ROOT/f'scripts/{name}/{name}.yy').write_text(dumps(data),encoding='utf-8')
  if not any(r['id']['name']==name for r in project['resources']):project['resources'].append({'id':{'name':name,'path':f'scripts/{name}/{name}.yy'}})
 project['resources'].sort(key=lambda r:r['id']['name'].lower());p.write_text(dumps(project),encoding='utf-8');print('Registered four real Boss System 2.0 runtime modules; resources:',len(project['resources']))
if __name__=='__main__':main()
