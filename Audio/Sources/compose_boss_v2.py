"""18 original short layered synthesis prototypes. No samples/API; no YYP mutation.
Run this before the sequential import_boss_v2_art.py importer.
"""
from pathlib import Path
import hashlib,json,math,random,struct,sys,wave
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import dumps
from gms_helpers.asset_types.media import SoundAsset
ROOT=Path(__file__).resolve().parents[2]
def main():
 manifest=json.loads((ROOT/'Audio/manifest.json').read_text(encoding='utf-8'));rate=32000
 for family in ['twins','swamp']:
  for ability in range(1,10):
   seed=(913 if family=='twins' else 1893)+ability*79;rng=random.Random(seed);duration=.35+ability*.032+(.18 if ability==9 else 0);values=[];phase1=0;phase2=0
   for n in range(round(duration*rate)):
    t=n/rate;p=t/duration;env=min(1,p*50)*(1-p)**1.5
    if family=='twins':
     # Warm descending FM body against crystalline rising minor-third overtones.
     freq=(160+ability*23)*(1.8-.95*p);phase1+=2*math.pi*freq/rate;phase2+=2*math.pi*(620+ability*67)*(1+.4*p)/rate
     warm=math.sin(phase1+.7*math.sin(phase1*2));cold=math.sin(phase2)+.2*math.sin(phase2*2.01)
     value=.44*warm+.30*cold+.17*rng.uniform(-1,1)*math.exp(-p*4)
    else:
     # Low wet resonances, cracking bark transients and an airy spore tail.
     freq=(68+ability*7)*(1.35-.55*p);phase1+=2*math.pi*freq/rate;phase2+=2*math.pi*(210+ability*11)*(1-.35*p)/rate
     tone=math.sin(phase1+.45*math.sin(phase2));noise=rng.uniform(-1,1);bubbles=.5+.5*math.sin((17+ability)*p*math.pi)**4
     value=.47*tone+.3*noise*bubbles+.13*math.sin(phase2)*math.exp(-p*5)
    values.append(value*env)
   peak=max(abs(v) for v in values);samples=[round(v/peak*.62*32767) for v in values];cue=f'{family}_{ability}';name='sfx_fg_'+cue;path=ROOT/f'Audio/Bosses/{cue}.wav'
   with wave.open(str(path),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(struct.pack('<'+'h'*len(samples),*samples))
   folder=ROOT/'sounds'/name;folder.mkdir(exist_ok=True);(folder/(name+'.wav')).write_bytes(path.read_bytes());data=SoundAsset().create_yy_data(name,'folders/Audio/Bosses.yy',sample_rate=rate,format=2);data.update(duration=len(samples)/rate,channelFormat=0,compression=0,preload=True);(folder/(name+'.yy')).write_text(dumps(data),encoding='utf-8')
   entry=dict(file=str(path.relative_to(ROOT)).replace('\\','/'),category='Bosses',rate=rate,channels=1,frames=len(samples),seconds=len(samples)/rate,peak=max(abs(v) for v in samples)/32768,rms=math.sqrt(sum((v/32768)**2 for v in samples)/len(samples)),sha256=hashlib.sha256(path.read_bytes()).hexdigest(),resource=name,quality='original layered procedural boss cue prototype; subjective hearing review pending')
   manifest['files']=[r for r in manifest['files'] if r['file']!=entry['file']]+[entry]
 (ROOT/'Audio/manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8');print('Generated18actualbossWAVcues/nativeYYs; project registration is deferred to sequential art importer.')
if __name__=='__main__':main()
