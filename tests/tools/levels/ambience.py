"""Synthesize the two ambient level loops (own procedural prototypes, no external recordings) and register them.
Usage: python tests/tools/levels/ambience.py
Outputs Audio/Ambience/amb_fg_swamp.wav, amb_fg_ruins.wav and sounds/amb_fg_*/ resources.
"""
from __future__ import annotations

import copy
import sys
import wave
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from gm_project import ROOT, Project, read, write  # noqa: E402

SR = 22050
LEN = 24.0


def _band(noise, lo, hi):
    spec = np.fft.rfft(noise)
    f = np.fft.rfftfreq(len(noise), 1 / SR)
    shape = np.exp(-0.5 * ((f - (lo + hi) / 2) / ((hi - lo) / 2)) ** 2)
    return np.fft.irfft(spec * shape, len(noise))


def _lowpass(noise, cutoff):
    spec = np.fft.rfft(noise)
    f = np.fft.rfftfreq(len(noise), 1 / SR)
    return np.fft.irfft(spec / (1 + (f / cutoff) ** 4), len(noise))


def _env_slow(n, rng, rate=0.15, depth=0.6):
    t = np.arange(n) / SR
    e = np.ones(n)
    for k in range(3):
        e += depth / 3 * np.sin(2 * np.pi * (rate * (k + 1) * rng.uniform(0.6, 1.4)) * t + rng.uniform(0, 6.28))
    return np.clip(e, 0.15, None)


def _place(buf, sig, at):
    i = int(at * SR)
    j = min(len(buf), i + len(sig))
    if i < len(buf):
        buf[i:j] += sig[:j - i]


def swamp(rng):
    n = int((LEN + 1.5) * SR); t = np.arange(n) / SR
    out = np.zeros(n)
    wind = _lowpass(rng.standard_normal(n), 380) * _env_slow(n, rng, 0.07, 0.8)
    out += 0.22 * wind / np.abs(wind).max()
    # Crickets: short pulse bursts on a high carrier.
    at = 0.2
    while at < LEN + 1:
        f = rng.uniform(4300, 5200); pulses = rng.integers(3, 6); amp = rng.uniform(0.02, 0.05)
        for p in range(pulses):
            m = int(0.014 * SR); tt = np.arange(m) / SR
            _place(out, amp * np.sin(2 * np.pi * f * tt) * np.hanning(m), at + p * 0.032)
        at += rng.uniform(0.45, 1.4)
    # Second insect layer: soft trill with tremolo.
    trill = 0.012 * np.sin(2 * np.pi * 6900 * t) * (0.5 + 0.5 * np.sin(2 * np.pi * 38 * t)) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.11 * t))
    out += trill
    # Frogs: low pulse-train croaks.
    at = rng.uniform(1, 3)
    while at < LEN:
        m = int(rng.uniform(0.18, 0.32) * SR); tt = np.arange(m) / SR
        f0 = rng.uniform(110, 190)
        croak = np.sign(np.sin(2 * np.pi * f0 * tt)) * (0.5 + 0.5 * np.sin(2 * np.pi * 24 * tt))
        croak = _lowpass(croak, 900) * np.hanning(m)
        _place(out, rng.uniform(0.06, 0.11) * croak / (np.abs(croak).max() + 1e-9), at)
        if rng.random() < 0.5:
            _place(out, rng.uniform(0.04, 0.08) * croak / (np.abs(croak).max() + 1e-9), at + 0.36)
        at += rng.uniform(2.5, 6.5)
    # Water drips and plops.
    at = 0.6
    while at < LEN + 1:
        m = int(0.09 * SR); tt = np.arange(m) / SR
        f = rng.uniform(800, 1500)
        drip = np.sin(2 * np.pi * (f * tt - 1800 * tt * tt)) * np.exp(-tt * 55)
        _place(out, rng.uniform(0.05, 0.11) * drip, at)
        at += rng.uniform(0.7, 2.8)
    # One distant wooden creak.
    m = int(1.1 * SR); tt = np.arange(m) / SR
    creak = _lowpass(np.sign(np.sin(2 * np.pi * (70 * tt + 18 * tt * tt))) + 0.3 * rng.standard_normal(m), 600) * np.hanning(m)
    _place(out, 0.05 * creak / np.abs(creak).max(), rng.uniform(8, 14))
    return out


def ruins(rng):
    n = int((LEN + 1.5) * SR); t = np.arange(n) / SR
    out = np.zeros(n)
    base = rng.standard_normal(n)
    whistle_a = _band(base, 640, 980); whistle_b = _band(rng.standard_normal(n), 1050, 1500)
    mix = 0.5 + 0.5 * np.sin(2 * np.pi * 0.045 * t + 1.3)
    gust = _env_slow(n, rng, 0.06, 0.9)
    wind = (whistle_a * mix + whistle_b * (1 - mix)) * gust
    out += 0.16 * wind / np.abs(wind).max()
    rumble = _lowpass(rng.standard_normal(n), 140)
    out += 0.12 * rumble / np.abs(rumble).max()
    # Ember crackle: sparse short filtered clicks.
    at = 0.0
    while at < LEN + 1:
        m = int(rng.uniform(0.002, 0.006) * SR)
        click = rng.standard_normal(m) * np.exp(-np.arange(m) / (m / 3))
        _place(out, rng.uniform(0.03, 0.12) * click, at)
        at += rng.exponential(0.16)
    # Magical hum with slow beating.
    out += 0.02 * (np.sin(2 * np.pi * 110 * t) + np.sin(2 * np.pi * 110.7 * t) + 0.6 * np.sin(2 * np.pi * 165.2 * t)) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.08 * t))
    # Two distant stone tumbles.
    for _ in range(2):
        m = int(0.9 * SR); tt = np.arange(m) / SR
        tumble = _lowpass(rng.standard_normal(m), 420) * (np.exp(-tt * 4) + 0.5 * np.exp(-((tt - 0.35) ** 2) * 80))
        _place(out, 0.09 * tumble / np.abs(tumble).max(), rng.uniform(3, LEN - 2))
    return out


def loopify(x):
    """Crossfade the tail into the head for a seamless loop of exactly LEN seconds."""
    n = int(LEN * SR); fade = int(1.2 * SR)
    head = x[:n].copy(); tail = x[n:n + fade]
    w = np.linspace(0, 1, fade)
    head[:fade] = head[:fade] * w + tail * (1 - w)
    head -= head.mean()
    return head / (np.abs(head).max() + 1e-9) * 0.5


def write_wav(path, x):
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = (np.clip(x, -1, 1) * 32767).astype('<i2')
    with wave.open(str(path), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())


def main():
    proj = Project()
    template = read('sounds/sfx_fg_coin/sfx_fg_coin.yy')
    for name, fn, seed in (('amb_fg_swamp', swamp, 31), ('amb_fg_ruins', ruins, 37)):
        x = loopify(fn(np.random.default_rng(seed)))
        src = ROOT / 'Audio/Ambience' / f'{name}.wav'
        write_wav(src, x)
        folder = ROOT / 'sounds' / name
        folder.mkdir(parents=True, exist_ok=True)
        write_wav(folder / f'{name}.wav', x)
        d = copy.deepcopy(template)
        d['name'] = d['%Name'] = name
        d.update(duration=round(LEN, 3), sampleRate=SR, soundFile=f'{name}.wav', preload=False, compression=0)
        d['parent'] = {'name': 'Audio', 'path': 'folders/Audio.yy'}
        write(f'sounds/{name}/{name}.yy', d)
        proj._register(name, f'sounds/{name}/{name}.yy')
        print(name, f'{len(x) / SR:.1f}s', 'peak', round(float(np.abs(x).max()), 3))
    proj.save()
    print('registered', proj.added)


if __name__ == '__main__':
    main()
