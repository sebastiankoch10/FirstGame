"""Run the installed GameMaker resource-graph validator locally, without MCP availability."""
from pathlib import Path
import sys,json
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.project_validation import validate_project_after_mutation
from gms_helpers.gm_json import loads
ROOT=Path(__file__).resolve().parents[2]
def main():
 report=validate_project_after_mutation(ROOT).to_dict();project=loads((ROOT/'FirstGame.yyp').read_text(encoding='utf-8'));report['resources']=len(project['resources'])
 # These unused event sources and their event registrations predate Boss2, proven byte-for-byte.
 prior=ROOT/'output/class-dragon-smoke/20261122-224716/project';baseline=[]
 for name in ['ObjectFireball','ObjectIceball','ObjectLightningball']:
  event=f'objects/{name}/Collision_ObjectMonster.gml';asset=f'objects/{name}/{name}.yy';finding=f'{asset}: orphaned event file: Collision_ObjectMonster.gml'
  if (prior/event).is_file() and (ROOT/event).read_bytes()==(prior/event).read_bytes() and (ROOT/asset).read_bytes()==(prior/asset).read_bytes():baseline.append(finding)
 report['preexisting_errors']=[e for e in report['errors'] if e in baseline];report['new_errors']=[e for e in report['errors'] if e not in baseline]
 report['boss_v2_success']=not report['new_errors'];report['status']='PASS' if report['boss_v2_success'] else 'FAIL'
 (ROOT/'tests/reports/boss-v2-project.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
 print(json.dumps(report,indent=2));
 if not report['boss_v2_success']:raise SystemExit(1)
if __name__=='__main__':main()
