"""Original short combat cues, synthesized locally with Python standard library. Prototypes."""
from pathlib import Path
import math,random,wave,struct,json,hashlib,sys
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads,dumps
from gms_helpers.asset_types.media import SoundAsset
ROOT=Path(__file__).resolve().parents[2]
CUES={'magic_hit':(.14,780,190,.35),'ice_hit':(.18,1600,600,.5),'arcane_hit':(.17,980,310,.3),'nova_cast':(.32,300,1100,.2),'heal_cast':(.42,520,1040,.05),'shock_hit':(.1,2200,240,.55)}
def main():
 manifest=json.loads((ROOT/'Audio/manifest.json').read_text(encoding='utf-8'));project=loads((ROOT/'FirstGame.yyp').read_text(encoding='utf-8'));rate=32000
 for name,(duration,start,end,noise) in CUES.items():
  rng=random.Random(421+len(name));samples=[];phase=0
  for i in range(int(rate*duration)):
   p=i/(rate*duration);frequency=start+(end-start)*p;phase+=2*math.pi*frequency/rate
   envelope=min(1,p*50)*(1-p)**2
   value=.46*envelope*((1-noise)*(math.sin(phase)+.25*math.sin(phase*2.01))/1.25+noise*rng.uniform(-1,1))
   samples.append(max(-32767,min(32767,round(value*32767))))
  path=ROOT/'Audio/Spells'/(name+'.wav');payload=struct.pack('<'+'h'*len(samples),*samples)
  with wave.open(str(path),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(payload)
  resource='sfx_fg_'+name;folder=ROOT/'sounds'/resource;folder.mkdir(exist_ok=True);(folder/(resource+'.wav')).write_bytes(path.read_bytes())
  d=SoundAsset().create_yy_data(resource,'folders/Audio/Spells.yy',sample_rate=rate,format=2);d.update(duration=duration,channelFormat=0,compression=0,preload=True);(folder/(resource+'.yy')).write_text(dumps(d),encoding='utf-8')
  if not any(x['id']['name']==resource for x in project['resources']):project['resources'].append({'id':{'name':resource,'path':f'sounds/{resource}/{resource}.yy'}})
  entry={'file':str(path.relative_to(ROOT)).replace('\\','/'),'category':'Spells','rate':rate,'channels':1,'frames':len(samples),'seconds':duration,'peak':max(abs(x) for x in samples)/32768,'rms':math.sqrt(sum((x/32768)**2 for x in samples)/len(samples)),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'resource':resource,'quality':'original synthesized 16-bit effect prototype'}
  manifest['files']=[x for x in manifest['files'] if x['file']!=entry['file']];manifest['files'].append(entry)
 project['resources'].sort(key=lambda x:x['id']['name'].lower());(ROOT/'FirstGame.yyp').write_text(dumps(project),encoding='utf-8');(ROOT/'Audio/manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
 print('Generated and imported six original WAV cues')
if __name__=='__main__':main()
