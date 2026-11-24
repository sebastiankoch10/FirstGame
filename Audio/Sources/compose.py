"""Original FirstGame compositions and SFX; deterministic local synthesis, no sampled music.
Requires the locally installed NumPy. Run: python Audio/Sources/compose.py
These are layered chiptune prototypes, not a sampled SNES orchestra or mastered soundtrack.
"""
from pathlib import Path
import hashlib
import json
import math
import wave
import numpy as np

ROOT=Path(__file__).resolve().parents[2]
RATE=32000
TAU=2*np.pi
RNG=np.random.default_rng(221126)
MANIFEST=[]


def write_wav(relative,signal,category,**details):
    signal=np.asarray(signal,dtype=np.float64)
    signal-=np.mean(signal,axis=0)
    peak=float(np.max(np.abs(signal)))
    signal*=0.86/max(peak,0.001)
    pcm=np.round(np.clip(signal,-0.95,0.95)*32767).astype('<i2')
    path=ROOT/'Audio'/relative
    path.parent.mkdir(parents=True,exist_ok=True)
    channels=1 if pcm.ndim==1 else pcm.shape[1]
    with wave.open(str(path),'wb') as f:
        f.setnchannels(channels);f.setsampwidth(2);f.setframerate(RATE);f.writeframes(pcm.tobytes())
    MANIFEST.append(dict(file=str(path.relative_to(ROOT)).replace('\\','/'),category=category,
        rate=RATE,channels=channels,frames=len(pcm),seconds=len(pcm)/RATE,
        peak=float(np.max(np.abs(pcm.astype(float))))/32768,
        rms=float(np.sqrt(np.mean((pcm.astype(float)/32768)**2))),
        boundary_step=float(np.max(np.abs(pcm[0].astype(float)-pcm[-1].astype(float))))/32768,
        sha256=hashlib.sha256(path.read_bytes()).hexdigest(),**details))


def envelope(t,duration,attack=0.012,release=0.12):
    return np.minimum(1,t/max(attack,0.0001))*np.minimum(1,np.maximum(0,(duration-t)/max(release,0.0001)))


def voice(note,duration,instrument):
    t=np.arange(max(2,round(duration*RATE)))/RATE
    freq=440*2**((note-69)/12)
    phase=TAU*freq*t+0.018*np.sin(TAU*5.1*t)*np.minimum(1,t/0.3)
    if instrument=='lead':
        s=np.sin(phase+0.65*np.sin(phase*2)*np.exp(-t*3))+.17*np.sin(phase*2)+.07*np.sin(phase*3)
        env=envelope(t,duration,.018,.11)*(0.8+0.2*np.exp(-t*4))
    elif instrument=='bell':
        s=np.sin(phase)+.32*np.sin(phase*2.002)+.11*np.sin(phase*3.99)
        env=envelope(t,duration,.004,.16)*np.exp(-t*2.6)
    elif instrument=='pad':
        s=(np.sin(phase)+.5*np.sin(phase*1.003)+.25*np.sin(phase*2))/1.75
        env=envelope(t,duration,.16,.3)*.65
    elif instrument=='bass':
        s=np.sin(phase)+.3*np.sin(2*phase)+.12*np.sin(3*phase)
        env=envelope(t,duration,.004,.045)*np.exp(-t*.65)
    elif instrument=='pluck':
        s=np.sin(phase)+.35*np.sin(phase*2)+.18*np.sin(phase*3)+.08*np.sin(phase*5)
        env=envelope(t,duration,.003,.06)*np.exp(-t*5)
    else:
        s=sum(np.sin(phase*k)/k for k in [1,3,5,7])
        env=envelope(t,duration,.008,.07)*np.exp(-t*.6)
    return (s*env).astype(np.float32)


def drum(kind,duration=.18):
    t=np.arange(round(duration*RATE))/RATE
    noise=RNG.uniform(-1,1,len(t))
    high=noise-np.concatenate(([0],noise[:-1]))
    if kind=='kick':
        s=np.sin(TAU*(44*t+9*(1-np.exp(-t*32))))*np.exp(-t*23)+noise*.08*np.exp(-t*85)
    elif kind=='snare':
        s=high*.4*np.exp(-t*24)+np.sin(TAU*178*t)*.36*np.exp(-t*31)
    elif kind=='tom':
        s=np.sin(TAU*(80*t+2*(1-np.exp(-t*25))))*np.exp(-t*16)
    else:
        s=high*.16*np.exp(-t*70)
    return (s*envelope(t,duration,.0008,.025)).astype(np.float32)


# Authored degree/rhythm motifs. No input recordings, commercial samples or quoted melodies.
MENU=[[(0,2,1.5),(2,7,.5),(2.5,9,.5),(3,4,.9)],[(.5,5,1),(2,2,.75),(3,0,.8)],
      [(0,4,1),(1.5,7,.5),(2,11,1),(3,9,.7)],[(0,7,1.3),(2,4,.7),(3,2,.7)],
      [(0,0,.8),(1,4,.7),(2,5,1.4)],[(0,9,1),(1.5,7,.5),(2,4,1.3)],
      [(.5,2,.5),(1,5,.6),(2,4,1),(3,0,.8)],[(0,-1,1),(1.5,2,.5),(2,0,1.6)]]
FIELD=[[(0,0,.7),(.75,4,.25),(1,7,.7),(2,9,.4),(2.5,7,.4),(3,4,.8)],
       [(0,5,.8),(1,4,.5),(2,2,.7),(3,7,.8)],[(0,9,.5),(.75,12,.7),(2,7,.5),(3,5,.8)],
       [(.0,4,1),(1.5,2,.5),(2.5,0,1.2)],[(0,5,.5),(1,9,.5),(1.75,12,.75),(3,11,.7)],
       [(0,7,.8),(1,4,.7),(2,2,.5),(3,5,.8)],[(0,4,.5),(1,7,.5),(2,9,.5),(3,4,.7)],
       [(0,2,.7),(1,1,.5),(2,0,1.7)]]
BOSS=[[(0,0,.35),(.5,7,.35),(1,3,.7),(2,10,.35),(2.5,7,.35),(3,2,.7)],
      [(0,3,.35),(.5,7,.35),(1,12,.7),(2,10,.4),(3,7,.75)],[(0,8,.6),(1,7,.4),(2,3,.6),(3,5,.6)],
      [(0,2,.35),(.5,-1,.35),(1,2,.7),(2,7,.4),(3,11,.7)],
      [(0,12,.5),(1,7,.5),(2,15,.5),(3,14,.5)],[(0,10,.6),(1,7,.35),(1.5,3,.35),(2,0,1.3)],
      [(0,8,.5),(1,12,.5),(2,7,.5),(3,3,.75)],[(0,2,.3),(.5,5,.3),(1,11,.5),(2,7,.5),(3,-1,.7)]]


def compose(name,title,bpm,bars,tonic,progression,motifs):
    beat=60/bpm;length=round(bars*4*beat*RATE)
    mix=np.zeros((length,2),dtype=np.float64);events=[]
    def add(at,sig,gain,pan):
        start=round(at*beat*RATE)%length
        stereo=np.stack((sig*math.sqrt((1-pan)/2),sig*math.sqrt((1+pan)/2)),axis=1)*gain
        end=start+len(stereo)
        if end<=length:mix[start:end]+=stereo
        else:mix[start:]+=stereo[:length-start];mix[:end-length]+=stereo[length-start:]
    def note(at,midi,duration,inst,gain,pan=0):
        add(at,voice(midi,duration*beat,inst),gain,pan)
        events.append(dict(beat=at,note=midi,duration=duration,instrument=inst,gain=gain,pan=pan))
    for bar in range(bars):
        root,intervals=progression[bar%len(progression)];base=bar*4
        for j,semitone in enumerate(intervals):note(base,tonic+root+semitone,4.25,'pad',.09,(-.5,0,.5,.2)[j%4])
        pattern=[0,7,12,7,3,7,12,7]
        for step in range(8):
            pitch=intervals[step%len(intervals)]+(12 if step%4==3 else 0)
            note(base+step*.5,tonic+root+12+pitch,.45,'pluck',.055 if name=='menu' else .075,(-.45 if step%2==0 else .45))
        for pos,pitch,duration in [(0,root,1.35),(1.5,root+7,.4),(2,root, .8),(3,root+12,.5),(3.5,root+7,.4)]:
            note(base+pos,tonic-12+pitch,duration,'bass',.19 if name!='menu' else .12)
        motif=motifs[bar%8]
        # A/A'/B/A variation with a contrasting high response in the second half.
        for at,pitch,duration in motif:
            lift=12 if bars==32 and 16<=bar<24 and bar%2==0 else 0
            note(base+at,tonic+12+pitch+lift,duration,'bell' if name=='menu' else ('reed' if name=='boss' else 'lead'),.19 if name!='menu' else .15,.08)
        if name=='menu':
            if bar%2==1:add(base+3,drum('hat',.12),.12,.3)
        else:
            for pos in ([0,1.5,2.75] if name=='boss' else [0,2.5]):add(base+pos,drum('kick',.22),.4,0)
            for pos in [1,3]:add(base+pos,drum('snare',.2),.21,-.1)
            for step in range(8 if name=='level' else 16):add(base+step*(.5 if name=='level' else .25),drum('hat',.075),.16 if step%2==0 else .09,.35)
            if bar%8==7:
                for step in [2.5,3,3.5]:add(base+step,drum('tom',.22),.18,-.4+step*.15)
    # Circular delays carry tails over the exact loop boundary rather than adding silence.
    dry=mix.copy()
    mix+=np.roll(dry,round(beat*RATE*.75),axis=0)*.16
    mix+=np.roll(dry,round(beat*RATE*1.5),axis=0)[:,::-1]*.09
    mix=np.tanh(mix*.9)
    write_wav(f'Music/{name}.wav',mix,'Music',title=title,bpm=bpm,bars=bars,loop=True,status='original synthesized chiptune prototype')
    (ROOT/'Audio/Sources'/f'{name}.score.json').write_text(json.dumps(dict(title=title,bpm=bpm,bars=bars,tonic_midi=tonic,progression=progression,note_events=events),indent=2)+'\n',encoding='utf-8')


def effect(name,category,kind,duration,notes):
    t=np.arange(round(duration*RATE))/RATE
    noise=RNG.uniform(-1,1,len(t))
    env=envelope(t,duration,.002,min(.09,duration*.4))
    if kind=='noise':
        f0,f1=notes
        phase=TAU*(f0*t+(f1-f0)*t*t/(2*duration))
        sig=(.65*noise+.35*np.sin(phase))*env*np.exp(-t/(duration*.6))
    elif kind=='impact':
        f0,f1=notes
        phase=TAU*(f1*t+(f0-f1)*duration*.22*(1-np.exp(-t/(duration*.22))))
        sig=(.65*np.sin(phase)+.35*noise*np.exp(-t*10))*env*np.exp(-t/(duration*.45))
    else:
        sig=np.zeros(len(t))
        span=duration/len(notes)
        for i,n in enumerate(notes):
            start=round(i*span*RATE);end=round((i+1)*span*RATE)
            sig[start:end]+=voice(n,(end-start)/RATE,'bell' if kind=='chime' else 'reed')*.7
        sig*=env
    # Short stereo-like delays are not used for mono game FX; predictable onset and ending.
    write_wav(f'{category}/{name}.wav',sig,category,loop=False,status='original procedural SFX',synthesis=kind)


def main():
    compose('menu','Nebelarchiv',80,16,57,[(0,[0,3,7,14]),(-5,[0,4,7,11]),(-7,[0,3,7,10]),(-2,[0,3,7,10])],MENU)
    compose('level','Windpfade',112,32,62,[(0,[0,3,7,10]),(5,[0,4,7,12]),(-2,[0,4,7,11]),(-5,[0,3,7,10]),(3,[0,4,7,11]),(5,[0,4,7,12]),(2,[0,3,7,10]),(7,[0,4,7,10])],FIELD)
    compose('boss','Runensturm',148,32,52,[(0,[0,3,7,10]),(-4,[0,4,7,11]),(5,[0,3,7,10]),(7,[0,4,7,10])],BOSS)
    specs=[
      ('ui_hover','UI','chime',.075,[88]),('ui_click','UI','chime',.13,[76,83]),('ui_back','UI','chime',.18,[79,71]),
      ('character_select','UI','chime',.28,[64,71,76]),('game_start','UI','chime',.55,[60,67,72,79]),
      ('sword_swing','Weapons','noise',.17,[900,230]),('sword_hit','Weapons','impact',.12,[260,72]),
      ('crossbow','Weapons','impact',.12,[470,105]),('arrow_hit','Weapons','noise',.10,[1500,300]),
      ('magic_projectile','Spells','chime',.22,[72,79,84]),('fireball','Spells','noise',.28,[180,520]),
      ('explosion','Spells','impact',.48,[135,32]),('lightning','Spells','noise',.19,[2100,500]),
      ('ice','Spells','chime',.30,[91,86,98]),('player_hit','Enemies','impact',.24,[230,65]),
      ('enemy_death','Enemies','impact',.23,[240,38]),('coin','UI','chime',.16,[90,97]),
      ('level_up','UI','chime',.72,[64,67,71,76,79]),('spell_select','UI','chime',.30,[72,76,83]),
      ('spell_upgrade','UI','chime',.44,[72,79,84,88]),('jump','Weapons','tone',.18,[48,55,64]),
      ('dodge','Weapons','noise',.16,[1500,300]),('slide','Weapons','noise',.26,[550,130]),
      ('game_over','UI','tone',1.12,[64,60,55,48]),('boss_spawn','Bosses','tone',.95,[40,47,46,52]),
      ('boss_phase','Bosses','tone',.72,[52,55,59,64,65]),('boss_defeated','Bosses','chime',1.20,[60,67,72,76,79,84])]
    for spec in specs:effect(*spec)
    (ROOT/'Audio/manifest.json').write_text(json.dumps(dict(version=1,sample_rate=RATE,seed=221126,
        provenance='Original authored motifs and procedural instruments; no downloads, samples, remixes or external music inputs.',
        files=MANIFEST),indent=2)+'\n',encoding='utf-8')
    print(f'Generated {len(MANIFEST)} real PCM WAV files; music durations: '+', '.join(f'{m["file"]}: {m["seconds"]:.2f}s' for m in MANIFEST if m['category']=='Music'),flush=True)


if __name__=='__main__':main()
