"""Preserve the actual current dirty-worktree gameplay sources before QA mutations."""
from pathlib import Path
import hashlib,json,shutil,subprocess,sys,datetime
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads
def main():
 out=ROOT/'QA/baseline';out.mkdir(parents=True,exist_ok=True);dest=out/'project';dest.mkdir(exist_ok=True)
 if (out/'manifest.json').exists():print('Baseline already saved; left immutable');return
 files=[ROOT/'FirstGame.yyp'];files += [p for name in ['scripts','objects','rooms','options'] for p in (ROOT/name).rglob('*') if p.is_file() and p.suffix in ('.gml','.yy')]
 manifest={}
 for p in files:
  key=str(p.relative_to(ROOT));data=p.read_bytes();manifest[key]=hashlib.sha256(data).hexdigest();target=dest/key;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(data)
 assets={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in (ROOT/'sprites').rglob('*.png')}
 project=loads((ROOT/'FirstGame.yyp').read_text(encoding='utf-8'))
 data=dict(status='BASELINE_SAVED',created_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),source_hashes=manifest,sprite_hashes=assets,resources=len(project['resources']),full_runs_this_task=0,completed_boss_encounters_this_task=0,prior_evidence='tests/reports/boss-v2-native.json: 830 targeted assertions, not full-run Monte Carlo')
 (out/'manifest.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
 (out/'git-status.txt').write_text(subprocess.run(['git','status','--short'],cwd=ROOT,capture_output=True,text=True,encoding='utf-8',errors='replace').stdout,encoding='utf-8')
 shutil.copyfile(ROOT/'tests/reports/boss-v2-native.json',out/'prior-native-tests.json');print('BASELINE_SAVED',len(files),'source files;',len(assets),'sprite PNGs;',len(project['resources']),'resources')
if __name__=='__main__':main()
