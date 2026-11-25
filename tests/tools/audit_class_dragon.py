"""Read-only audit of real references, imported assets, and preserved dragon bytes."""
from pathlib import Path
import hashlib,json,struct,sys
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads
ROOT=Path(__file__).resolve().parents[2]
import sys as _sys_ap; _sys_ap.path.insert(0, str(ROOT / 'tests' / 'tools' / 'assets')); import art_paths as AP  # noqa: E402
def main():
 checks=[]
 def check(label,ok):checks.append(dict(label=label,passed=bool(ok)))
 refs={'Zaubermeisterin_Referenz.png':'ChatGPT-Bild 22. Nov. 2026, 21_17_51.png','Waldlaeufer_Referenz.png':'ChatGPT-Bild 22. Nov. 2026, 21_17_44.png','Drache_Attacken_Referenz.png':'Drachenangriffs-Atlas im Pixelstil.png'}
 for dest,src in refs.items():check('Original reference byte identity '+dest,(AP.REFERENCES/dest).read_bytes()==(AP.REFERENCES/src).read_bytes())
 hashes=json.loads((AP.CLASS_OVERHAUL/'dragon-preserved.json').read_text())
 check('All 67 approved dragon PNGs byte-identical',len(hashes)==67 and all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in hashes.items()))
 project=loads((ROOT/'FirstGame.yyp').read_text(encoding='utf-8'));registered={r['id']['name'] for r in project['resources']}
 count=0
 for folder in sorted((ROOT/'sprites').glob('*')):
  name=folder.name
  if not (name.startswith(('spr_fg_magev3_','spr_fg_rangerv3_','spr_class_fx_','spr_dragon_fx_','spr_fg_dragonextra_','spr_mage_star_'))):continue
  d=loads((folder/(name+'.yy')).read_text());check('Registered nonempty sprite '+name,name in registered and len(d['frames'])>0)
  for frame in d['frames']:
   raw=(folder/(frame['name']+'.png')).read_bytes();check('Valid PNG dimensions '+name+'/'+frame['name'],raw[:8]==b'\x89PNG\r\n\x1a\n' and struct.unpack('>II',raw[16:24])==(d['width'],d['height']));count+=1
 for name in ['attack_telegraph','class_weapons','dragon_encounter']:check('Runtime module '+name,name in registered and (ROOT/f'scripts/{name}/{name}.gml').is_file())
 manifest=json.loads((ROOT/'Audio/manifest.json').read_text(encoding='utf-8'));cues=[e for e in manifest['files'] if Path(e['file']).stem.startswith(('mage_','ranger_','dragon_'))]
 check('16 actual new audio cues',len(cues)==16 and all(e['resource'] in registered and (ROOT/e['file']).is_file() for e in cues))
 report=dict(passed=all(c['passed'] for c in checks),status='PASS' if all(c['passed'] for c in checks) else 'FAIL',checks=checks,new_native_sprite_frames=count,approved_dragon_pngs_preserved=len(hashes),new_cues=len(cues),project_resources=len(registered))
 (ROOT/'tests/reports/class-dragon-assets.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');print(json.dumps({k:v for k,v in report.items() if k!='checks'}))
 if not report['passed']:raise SystemExit(1)
if __name__=='__main__':main()
