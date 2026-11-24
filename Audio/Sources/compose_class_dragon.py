"""Original layered synthesis prototypes; deterministic, no external samples or API."""
from pathlib import Path
import hashlib,json,math,random,struct,sys,wave
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads,dumps
from gms_helpers.asset_types.media import SoundAsset
ROOT=Path(__file__).resolve().parents[2]
CUES=['mage_bolt','mage_arc','mage_circle','mage_star','mage_implosion','ranger_arrow','ranger_volley','ranger_rain','dragon_fire','dragon_charge','dragon_meteor','dragon_slam','dragon_wind','dragon_void','dragon_magma','dragon_vortex']
def main():
 project=loads((ROOT/'FirstGame.yyp').read_text(encoding='utf-8'));manifest=json.loads((ROOT/'Audio/manifest.json').read_text(encoding='utf-8'));rate=32000
 for i,cue in enumerate(CUES):
  duration=.23+(i%4)*.08+(.25 if cue.startswith('dragon') else 0);rng=random.Random(80633+i);values=[];phase=0
  for n in range(round(duration*rate)):
   t=n/rate;p=t/duration;noise=rng.uniform(-1,1);base=(560 if cue.startswith('mage') else 240 if cue.startswith('ranger') else 85)*(1+.11*(i%5))
   phase+=2*math.pi*base*(1.5-p+.16*math.sin(12*p))/rate
   tone=(math.sin(phase)+.3*math.sin(phase*2.005)+.2*math.sin(phase*.5))/1.5
   noise_mix=.15 if cue.startswith('mage') else .55 if cue.startswith('ranger') else .65
   env=min(1,p*45)*(1-p)**1.6;values.append(env*((1-noise_mix)*tone+noise_mix*noise*.55))
  peak=max(abs(v) for v in values);samples=[round(v/peak*.65*32767) for v in values];name='sfx_fg_'+cue;category='Bosses' if cue.startswith('dragon') else 'Weapons';path=ROOT/f'Audio/{category}/{cue}.wav'
  with wave.open(str(path),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(struct.pack('<'+'h'*len(samples),*samples))
  folder=ROOT/'sounds'/name;folder.mkdir(exist_ok=True);(folder/(name+'.wav')).write_bytes(path.read_bytes());d=SoundAsset().create_yy_data(name,f'folders/Audio/{category}.yy',sample_rate=rate,format=2);d.update(duration=len(samples)/rate,channelFormat=0,compression=0,preload=True);(folder/(name+'.yy')).write_text(dumps(d),encoding='utf-8')
  if not any(r['id']['name']==name for r in project['resources']):project['resources'].append({'id':{'name':name,'path':f'sounds/{name}/{name}.yy'}})
  entry=dict(file=str(path.relative_to(ROOT)).replace('\\','/'),category=category,rate=rate,channels=1,frames=len(samples),seconds=len(samples)/rate,peak=max(abs(v) for v in samples)/32768,rms=math.sqrt(sum((v/32768)**2 for v in samples)/len(samples)),sha256=hashlib.sha256(path.read_bytes()).hexdigest(),resource=name,quality='original procedural class/dragon cue prototype')
  manifest['files']=[r for r in manifest['files'] if r['file']!=entry['file']]+[entry]
 project['resources'].sort(key=lambda r:r['id']['name'].lower());(ROOT/'FirstGame.yyp').write_text(dumps(project),encoding='utf-8');(ROOT/'Audio/manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8');print('Generated 16 actual class/dragon WAV cues')
if __name__=='__main__':main()
