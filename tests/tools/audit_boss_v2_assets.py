"""Verify actual new files and byte-preservation against the successful prior native snapshot."""
from pathlib import Path
import hashlib,json,struct,sys
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads
ROOT=Path(__file__).resolve().parents[2]
import sys as _sys_ap; _sys_ap.path.insert(0, str(ROOT / 'tests' / 'tools' / 'assets')); import art_paths as AP  # noqa: E402
def main():
 project=loads((ROOT/'FirstGame.yyp').read_text(encoding='utf-8'));registered={r['id']['name'] for r in project['resources']};manifest=json.loads((AP.BOSS_V2/'manifest.json').read_text());errors=[];frames=0
 for item in manifest:
  name=item['name'];folder=ROOT/'sprites'/name;data=loads((folder/(name+'.yy')).read_text())
  if name not in registered:errors.append('Unregistered '+name)
  for frame in data['frames']:
   raw=(folder/(frame['name']+'.png')).read_bytes();frames+=1
   if raw[:8]!=b'\x89PNG\r\n\x1a\n' or struct.unpack('>II',raw[16:24])!=(data['width'],data['height']):errors.append('Invalid PNG '+name)
 preserved=0;mismatches=[];prior=ROOT/'output/class-dragon-smoke/20261122-224716/project/sprites'
 for folder in prior.iterdir():
  if not folder.name.startswith(('spr_fg_swordsmanv3_','spr_fg_magev3_','spr_fg_rangerv3_','spr_fg_dragonboss_','spr_fg_dragonextra_')):continue
  for path in folder.rglob('*'):
   if path.is_file():
    target=ROOT/'sprites'/path.relative_to(prior);preserved+=1
    if not target.is_file() or path.read_bytes()!=target.read_bytes():mismatches.append(str(target.relative_to(ROOT)))
 refs={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (AP.REFERENCES).glob('ChatGPT-Bild*23_00_*.png')}
 cues=[f'sfx_fg_{family}_{i}' for family in ['twins','swamp'] for i in range(1,10)]
 for cue in cues:
  if cue not in registered or not (ROOT/f'sounds/{cue}/{cue}.wav').is_file():errors.append('Missing cue '+cue)
 report=dict(passed=not errors and not mismatches,status='PASS' if not errors and not mismatches else 'FAIL',new_sprites=len(manifest),new_native_frames=frames,new_cues=len(cues),preserved_hero_dragon_files=preserved,preservation_mismatches=mismatches,errors=errors,reference_sha256=refs)
 (ROOT/'tests/reports/boss-v2-assets.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(json.dumps(report,ensure_ascii=False))
 if not report['passed']:raise SystemExit(1)
if __name__=='__main__':main()
