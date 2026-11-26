"""Current resource graph check; classify only byte-proven baseline orphans as preexisting."""
from pathlib import Path
import json,sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.project_validation import validate_project_after_mutation
from gms_helpers.gm_json import loads

def main():
    result=validate_project_after_mutation(ROOT).to_dict()
    baseline=ROOT/'QA/baseline/project';known=[]
    for name in ['ObjectFireball','ObjectIceball','ObjectLightningball']:
        event=f'objects/{name}/Collision_ObjectMonster.gml';asset=f'objects/{name}/{name}.yy'
        # the orphaned event files were removed on 2026-11-26; the exception only applies while such a file still exists
        if (ROOT/event).is_file() and (ROOT/event).read_bytes()==(baseline/event).read_bytes() and (ROOT/asset).read_bytes()==(baseline/asset).read_bytes():
            known.append(f'{asset}: orphaned event file: Collision_ObjectMonster.gml')
    result['preexisting_errors']=[e for e in result['errors'] if e in known]
    result['new_errors']=[e for e in result['errors'] if e not in known]
    result['resources']=len(loads((ROOT/'FirstGame.yyp').read_text(encoding='utf-8'))['resources'])
    result['no_new_errors']=not result['new_errors']
    (ROOT/'QA/data/project-validation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:result[k] for k in ['resources','preexisting_errors','new_errors','no_new_errors']},indent=2))
    if result['new_errors']:raise SystemExit(1)
if __name__=='__main__':main()
