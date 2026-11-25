"""Scene recorder: plays one fixed scene in an isolated native build and writes an animated WebP (optionally GIF) plus a
contact sheet to %LOCALAPPDATA%/FirstGame-Tests/scene/<stamp>/. delta_time is fixed at 60 Hz in the copy, so every
saved frame is exactly one game frame (saving PNGs slows the game, the film does not).

  python tests/tools/record_scene.py walk   [--class Sword|Mage|Ranger] [--level 0|1|2]
  python tests/tools/record_scene.py combat [--class ...] [--level ...]
  python tests/tools/record_scene.py spell  --spell LIGHTNING [--spell-level 1..9]
  python tests/tools/record_scene.py boss   [--boss storm_warden|twins|behemoth]
  python tests/tools/record_scene.py horde  [--minute 10]
  Options: --start N (game frames after setup), --frames N, --every N (2 = 30 fps), --crop WxH (centred, 0 = full),
           --scale F (nearest)

A capture tool, not a test: it fails only when the build fails or no frame was saved.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import run_native_harness as runner  # noqa: E402

# Older recordings are pruned automatically (newest 2 stay, clean_test_artifacts.py).
SCENES = {
    # Captures are the 960x540 world surface (render_pipeline): close-ups are cropped and shown at 2x, nearest.
    'walk': dict(start=0, frames=140, every=2, crop='480x270', scale=2.0),
    'combat': dict(start=20, frames=150, every=2, crop='480x270', scale=2.0),
    'spell': dict(start=0, frames=150, every=2, crop='560x315', scale=2.0),
    'boss': dict(start=90, frames=180, every=2, crop='0', scale=1.0),
    'horde': dict(start=60, frames=150, every=2, crop='0', scale=1.0),
}
CLASSES = {'sword': 'Sword', 'schwertmeister': 'Sword', 'mage': 'Mage', 'arkanistin': 'Mage', 'ranger': 'Ranger', 'waldlaeufer': 'Ranger'}


def spell_id(name: str) -> int:
    if name.isdigit():
        return int(name)
    text = (ROOT / 'scripts/spell/spell.gml').read_text(encoding='utf-8-sig')
    m = re.search(r'\b' + re.escape(name.upper()) + r'\s*=\s*(\d+)', text)
    if not m:
        raise SystemExit(f'Unknown spell {name!r} (see enum SPELL in scripts/spell/spell.gml)')
    return int(m.group(1))


def assemble(frames: list[Path], out: Path, crop: str, scale: float, every: int, want_gif: bool = False) -> dict:
    imgs = []
    for p in frames:
        im = Image.open(p).convert('RGB')
        if crop not in ('0', ''):
            w, h = (int(v) for v in crop.lower().split('x'))
            x0, y0 = max(0, (im.width - w) // 2), max(0, (im.height - h) // 2)
            im = im.crop((x0, y0, x0 + min(w, im.width), y0 + min(h, im.height)))
        if scale != 1.0:
            im = im.resize((round(im.width * scale), round(im.height * scale)), Image.NEAREST)
        imgs.append(im)
    ms = 1000 * every / 60
    # GIF stores 10 ms steps: round the running total so the average matches the game speed (30/30/40 ms at 30 fps).
    durations, shown = [], 0
    for i in range(len(imgs)):
        d = round((i + 1) * ms / 10) * 10 - shown
        durations.append(d); shown += d
    gif, webp, sheet = out / 'scene.gif', out / 'scene.webp', out / 'sheet.png'
    # Lossy WebP (q80) keeps a 5 s clip at a few MB for the phone; GIF is 5-8x larger on the noisy ground (opt-in).
    if want_gif:
        pal = [im.convert('P', palette=Image.ADAPTIVE, colors=255) for im in imgs]
        pal[0].save(gif, save_all=True, append_images=pal[1:], duration=durations, loop=0, disposal=1)
    imgs[0].save(webp, save_all=True, append_images=imgs[1:], duration=round(ms), loop=0, quality=80, method=4)
    pick = [imgs[i] for i in range(0, len(imgs), max(1, len(imgs) // 8))][:8]
    tw, th = pick[0].width, pick[0].height
    s = Image.new('RGB', (tw * 4, th * ((len(pick) + 3) // 4)), (20, 20, 20))
    for i, im in enumerate(pick):
        s.paste(im, ((i % 4) * tw, (i // 4) * th))
    s.save(sheet)
    return {'webp': str(webp), 'webp_mb': round(webp.stat().st_size / 1e6, 1),
            'gif': str(gif) if want_gif else None, 'gif_mb': round(gif.stat().st_size / 1e6, 1) if want_gif else None, 'sheet': str(sheet),
            'frames': len(imgs), 'size': f'{imgs[0].width}x{imgs[0].height}', 'fps': round(60 / every, 1)}


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('scene', choices=sorted(SCENES))
    ap.add_argument('--class', dest='cls', default='Sword')
    ap.add_argument('--level', type=int, default=0, help='0 Wald, 1 Sumpf, 2 Aschenfrost')
    ap.add_argument('--spell', default='LIGHTNING')
    ap.add_argument('--spell-level', type=int, default=9)
    ap.add_argument('--boss', default='storm_warden')
    ap.add_argument('--minute', type=int, default=10)
    for k in ('start', 'frames', 'every'):
        ap.add_argument('--' + k, type=int)
    ap.add_argument('--crop')
    ap.add_argument('--scale', type=float)
    ap.add_argument('--gif', action='store_true', help='also write a (large) GIF')
    a = ap.parse_args()
    cfg = dict(SCENES[a.scene])
    for k in ('start', 'frames', 'every', 'crop', 'scale'):
        if getattr(a, k) is not None:
            cfg[k] = getattr(a, k)
    cls = CLASSES.get(a.cls.lower(), a.cls)
    macros = {'SC_SCENE': f'"{a.scene}"', 'SC_CLASS': f'"{cls}"', 'SC_LEVEL_INDEX': a.level, 'SC_SPELL': spell_id(a.spell),
              'SC_SPELL_LEVEL': max(1, min(9, a.spell_level)), 'SC_BOSS': f'"{a.boss}"', 'SC_MINUTE': a.minute,
              'SC_START': cfg['start'], 'SC_FRAMES': cfg['frames'], 'SC_EVERY': max(1, cfg['every'])}
    base = Path(os.environ['LOCALAPPDATA']) / 'FirstGame-Tests' / 'scene'
    base.mkdir(parents=True, exist_ok=True)
    harness = base / f'_harness_{a.scene}.gml'
    harness.write_text(''.join(f'#macro {k} {v}\n' for k, v in macros.items()) +
                       (ROOT / 'tests/scene_harness.gml').read_text(encoding='utf-8-sig'), encoding='utf-8')
    total = 21 + cfg['start'] + cfg['frames'] * max(1, cfg['every'])
    runner.SUITES['scene'] = (str(harness), 'sc', 'SCENE', 'FirstGameScene', 240 + total // 2)
    runner.EXTRA_REPLACEMENTS = [(r'\bdelta_time\b', '16667')]
    sys.argv = ['run_native_harness.py', 'scene']
    started = time.time()
    try:
        runner.main()
    except SystemExit:
        pass
    report = ROOT / 'tests/reports/scene-harness-result.json'
    result = json.loads(report.read_text(encoding='utf-8')) if report.exists() else {}
    report.unlink(missing_ok=True)
    harness.unlink(missing_ok=True)
    work = Path(result.get('logs', ''))
    frames = sorted(p for p in work.glob('[0-9][0-9][0-9][0-9].png')) if work.is_dir() else []
    if not frames:
        print(json.dumps({'scene': a.scene, 'status': 'FAIL', 'reason': 'no frames', 'result': result}, indent=2))
        raise SystemExit(1)
    info = assemble(frames, work, cfg['crop'], cfg['scale'], max(1, cfg['every']), a.gif)
    for p in frames:
        p.unlink()
    info.update(scene=a.scene, macros=macros, seconds=round(time.time() - started), status='PASS', exceptions=result.get('exceptions'))
    print(json.dumps(info, indent=2))
    from clean_test_artifacts import clean
    clean(quiet=True)


if __name__ == '__main__':
    main()
