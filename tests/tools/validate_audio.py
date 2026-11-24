"""Validate actual PCM files and imported GameMaker copies, independently of the generator."""
from pathlib import Path
import array
import hashlib
import json
import math
import wave

ROOT=Path(__file__).resolve().parents[2]
manifest=json.loads((ROOT/'Audio/manifest.json').read_text(encoding='utf-8'))
results=[]
for entry in manifest['files']:
    source=ROOT/entry['file']
    imported=ROOT/'sounds'/entry['resource']/(entry['resource']+'.wav')
    with wave.open(str(source),'rb') as f:
        channels,width,rate,frames=f.getnchannels(),f.getsampwidth(),f.getframerate(),f.getnframes()
        raw=f.readframes(frames)
    samples=array.array('h',raw)
    peak=max(abs(x) for x in samples)
    rms=math.sqrt(sum(x*x for x in samples)/len(samples))/32768
    digest=hashlib.sha256(source.read_bytes()).hexdigest()
    checks=[width==2,rate==32000,channels==entry['channels'],frames==entry['frames'],len(raw)==frames*channels*width,
            peak>0,peak<32767,rms>0.01,digest==entry['sha256'],source.read_bytes()==imported.read_bytes()]
    if entry['category']=='Music':
        checks.extend([abs(frames/rate-entry['bars']*4*60/entry['bpm'])<=1/rate,
                       max(abs(samples[c]-samples[-channels+c]) for c in range(channels))/32768<0.04])
    result=dict(file=entry['file'],resource=entry['resource'],passed=all(checks),seconds=frames/rate,channels=channels,rate=rate,bits=width*8,peak=peak/32768,rms=rms)
    results.append(result)
report=dict(passed=len(results)==len(manifest['files']) and len({r['resource'] for r in results})==len(results) and all(r['passed'] for r in results),files=len(results),music=sum(e['category']=='Music' for e in manifest['files']),effects=sum(e['category']!='Music' for e in manifest['files']),results=results)
(ROOT/'tests/reports/audio-files.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in report.items() if k!='results'}))
raise SystemExit(0 if report['passed'] else 1)
