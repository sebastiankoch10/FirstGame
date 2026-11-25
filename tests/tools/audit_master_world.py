"""Audit the saved first-room state and actual imported PNGs, independently of a successful build."""
from pathlib import Path
from collections import Counter
import hashlib,json,struct,sys
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads
ROOT=Path(__file__).resolve().parents[2]
import sys as _sys_ap; _sys_ap.path.insert(0, str(ROOT / 'tests' / 'tools' / 'assets')); import art_paths as AP  # noqa: E402

def main():
 room=loads((ROOT/'rooms/Room1/Room1.yy').read_text(encoding='utf-8'))
 objects=Counter(i['objectId']['name'] for layer in room['layers'] for i in layer.get('instances',[]))
 assert objects['ObjectEnvironmentDecoration']==0 and objects['ObjectMasterWorld']==1
 layout=json.loads((AP.MASTER_WORLD/'layout.json').read_text(encoding='utf-8'))
 assert objects['ObjectMasterScenery']==len(layout)
 assert not any(layer.get('tilesetId') or layer['resourceType']=='GMRTileLayer' for layer in room['layers'])
 assert set(objects)=={'ObjectController','ObjectOverlay','ObjectPlayer','ObjectSpawner','ObjectMasterWorld','ObjectMasterScenery'}
 manifest=json.loads((AP.MASTER_WORLD/'manifest.json').read_text(encoding='utf-8'))
 checked=0
 for entry in manifest:
  name=entry['name'];folder=ROOT/'sprites'/name;data=loads((folder/(name+'.yy')).read_text(encoding='utf-8'))
  assert len(data['frames'])==entry['frames']
  assert [data['sequence']['xorigin'],data['sequence']['yorigin']]==entry['origin']
  layer=data['layers'][0]['name']
  for frame in data['frames']:
   uid=frame['name'];image=folder/(uid+'.png');blob=image.read_bytes()
   assert blob[:8]==b'\x89PNG\r\n\x1a\n'
   assert struct.unpack('>II',blob[16:24])==(entry['width'],entry['height'])
   assert blob[25]==6 # real RGBA import files
   assert hashlib.sha256(blob).digest()==hashlib.sha256((folder/'layers'/uid/(layer+'.png')).read_bytes()).digest()
   checked+=1
 report=dict(passed=True,room='Room1',layers=[layer['name'] for layer in room['layers']],objects=dict(objects),old_tile_layers=0,old_scenery=0,new_sprites=len(manifest),verified_rgba_images=checked)
 (ROOT/'tests/reports/master-world-active.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
 print(json.dumps(report,indent=2))

if __name__=='__main__':main()
