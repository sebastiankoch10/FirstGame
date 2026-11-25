"""18 original deterministic multi-part spell cues. Local synth prototypes, no paid API or samples."""
from pathlib import Path
import hashlib,json,math,random,struct,sys,wave
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads,dumps
from gms_helpers.asset_types.media import SoundAsset
ROOT=Path(__file__).resolve().parents[2]
import sys as _sys_ap; _sys_ap.path.insert(0, str(ROOT / 'tests' / 'tools' / 'assets')); import art_paths as AP  # noqa: E402

def main():
 catalog=json.loads((AP.SPELL_CATALOG).read_text(encoding='utf-8'))
 project=loads((ROOT/'FirstGame.yyp').read_text(encoding='utf-8'));manifest=json.loads((ROOT/'Audio/manifest.json').read_text(encoding='utf-8'));rate=32000
 for d in catalog[:18]:
  sid=d['id'];element=d['element'];rng=random.Random(sid*173);duration=.29+(sid%5)*.055+(.18 if sid in [103,118] else 0);phase=0;values=[]
  base=[340,150,900,1800,590,110,660,220][element]
  for n in range(int(rate*duration)):
   t=n/rate;p=t/duration;step=int(p*(3+(sid%3)));freq=base*(1+.08*(sid-101))*(1.0+.32*math.sin((step+1)*1.7))*(1+.4*(1-p))
   phase+=2*math.pi*freq/rate
   attack=min(1,p*50);envelope=attack*(1-p)**(1.3+(sid%3)*.3)
   tone=(math.sin(phase)+.3*math.sin(phase*2.01)+.15*math.sin(phase*.5))/1.45
   noise=rng.uniform(-1,1);crackle=(1 if (n//(71+sid%11))%3 else -1)
   blend=.52 if element in [1,3,5] else .13
   pulse=.72+.28*math.sin(p*(4+sid%4)*math.pi)**2
   values.append(envelope*pulse*((1-blend)*tone+blend*noise*.6+.12*crackle*math.exp(-p*10)))
  peak=max(abs(x) for x in values);samples=[round(x/peak*.72*32767) for x in values]
  name=f'sfx_fg_skill_{sid}';path=ROOT/f'Audio/Spells/skill_{sid}.wav'
  with wave.open(str(path),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(struct.pack('<'+'h'*len(samples),*samples))
  folder=ROOT/'sounds'/name;folder.mkdir(exist_ok=True);(folder/(name+'.wav')).write_bytes(path.read_bytes())
  data=SoundAsset().create_yy_data(name,'folders/Audio/Spells.yy',sample_rate=rate,format=2);data.update(duration=duration,channelFormat=0,compression=0,preload=True)
  (folder/(name+'.yy')).write_text(dumps(data),encoding='utf-8')
  if not any(x['id']['name']==name for x in project['resources']):project['resources'].append({'id':{'name':name,'path':f'sounds/{name}/{name}.yy'}})
  entry=dict(file=str(path.relative_to(ROOT)).replace('\\','/'),category='Spells',rate=rate,channels=1,frames=len(samples),seconds=duration,peak=max(abs(x) for x in samples)/32768,rms=math.sqrt(sum((x/32768)**2 for x in samples)/len(samples)),sha256=hashlib.sha256(path.read_bytes()).hexdigest(),resource=name,quality='original layered procedural spell cue prototype')
  manifest['files']=[x for x in manifest['files'] if x['file']!=entry['file']]+[entry]
 project['resources'].sort(key=lambda x:x['id']['name'].lower());(ROOT/'FirstGame.yyp').write_text(dumps(project),encoding='utf-8');(ROOT/'Audio/manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
 print('Generated and registered 18 actual unique spell WAVs')

if __name__=='__main__':main()
