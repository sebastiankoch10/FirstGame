"""Weapon attachment points per animation cell, derived from the existing layered character data (Phase 1, 7.3).

For every actor and cell: the start-weapon layer pixels (spr_eqv_<actor>_wpn_s) are fitted with a principal axis;
the end nearer to the hand layer (hands0) is the grip. Output: grip point in frame coordinates, direction (GML degrees,
pointing from the grip to the weapon tip), length and the hand side. Used by eqv_attach() so that any future weapon
type, off-hand item or shield can be drawn at the hand with the body's own per-frame pose instead of floating.

  python tests/tools/characters/build_attach_points.py            -> scripts/equipment_attach_data (generated)
  python tests/tools/characters/build_attach_points.py --preview  -> preview sheet only (scratch path printed)
"""
from __future__ import annotations

import base64
import json
import math
import re
import struct
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
ACTORS = ('swordsmanv3', 'magev3', 'rangerv3')


def load_data() -> dict:
    gml = (ROOT / 'scripts/equipment_visual_data/equipment_visual_data.gml').read_text(encoding='utf-8')
    # The data is a GML struct literal: quote the bare keys and read it as JSON.
    body = gml[gml.index('static d =') + len('static d ='):gml.rindex('return d')].strip().rstrip(';').strip()
    body = re.sub(r'([{,]\s*)([A-Za-z_][A-Za-z0-9_]*)\s*:', lambda m: m.group(1) + '"' + m.group(2) + '":', body)
    body = re.sub(r',(\s*[}\]])', lambda m: m.group(1), body)  # GML allows trailing commas, JSON does not
    return json.loads(body)


def atlas(name: str) -> np.ndarray | None:
    folder = ROOT / 'sprites' / name
    pngs = [p for p in folder.glob('*.png')]
    return np.asarray(Image.open(pngs[0]).convert('RGBA')) if pngs else None


def piece_pixels(rects: bytes, img: np.ndarray, cell: int) -> np.ndarray:
    ax, ay, w, h, ox, oy = struct.unpack_from('<HHBBBB', rects, cell * 8)
    if w == 0 or img is None:
        return np.zeros((0, 2))
    a = img[ay:ay + h, ax:ax + w, 3]
    ys, xs = np.nonzero(a > 0)
    return np.stack([xs + ox, ys + oy], axis=1).astype(float)


def analyse(data: dict) -> dict:
    out = {}
    for actor in ACTORS:
        src = data['actors'][actor]
        cells = src['cells']
        wr = base64.b64decode(src['rects']['wpn_s']); hr = base64.b64decode(src['rects']['hands0'])
        wimg, himg = atlas(f'spr_eqv_{actor}_wpn_s'), atlas(f'spr_eqv_{actor}_hands0')
        rows = []
        for c in range(cells):
            wp = piece_pixels(wr, wimg, c)
            if len(wp) < 8:
                rows.append(None); continue
            mean = wp.mean(axis=0); cov = np.cov((wp - mean).T); vals, vecs = np.linalg.eigh(cov)
            axis = vecs[:, np.argmax(vals)]; proj = (wp - mean) @ axis
            lo, hi = mean + axis * proj.min(), mean + axis * proj.max()
            hp = piece_pixels(hr, himg, c)
            conf = 1 if len(hp) >= 4 else 0
            hand = hp.mean(axis=0) if conf else np.array([80.0, 100.0])   # no visible hand: body centre, low confidence
            # grip = the hand projected onto the weapon axis (sword hilt, middle of a staff or bow alike)
            t_hand = float(np.clip((hand - mean) @ axis, proj.min(), proj.max()))
            grip = mean + axis * t_hand
            span = proj.max() - proj.min(); rel = (t_hand - proj.min()) / max(1e-6, span)
            if .2 < rel < .8:   # held in the middle (staff, bow): the upper end is the head/tip
                tip_end = hi if hi[1] <= lo[1] else lo
            else:               # held at one end (sword hilt): the far end is the tip
                tip_end = hi if np.linalg.norm(hi - grip) >= np.linalg.norm(lo - grip) else lo
            length = float(np.linalg.norm(tip_end - grip))
            ang = math.degrees(math.atan2(-(tip_end[1] - grip[1]), tip_end[0] - grip[0])) % 360
            rows.append([round(float(grip[0]), 1), round(float(grip[1]), 1), round(ang, 1), round(length, 1), conf])
        out[actor] = rows
    return out


def preview(data: dict, anchors: dict, path: Path) -> None:
    tiles = []
    for actor in ACTORS:
        src = data['actors'][actor]
        base_name = next(iter(src['sprites']))
        sprites = src['sprites']
        # draw 16 cells of the idle/walk sprites: base frame + anchor line
        for name in list(sprites)[:4]:
            folder = ROOT / 'sprites' / name
            frames = sorted(folder.glob('*.png'), key=lambda p: p.stat().st_mtime)
            yy = json.loads(re.sub(r',(\s*[}\]])', lambda m: m.group(1), (folder / f'{name}.yy').read_text(encoding='utf-8'))) if (folder / f'{name}.yy').exists() else None
            order = [f['name'] for f in yy['frames']] if yy else []
            for k, fn in enumerate(order[:4]):
                im = Image.open(folder / f'{fn}.png').convert('RGBA').resize((320, 320), Image.NEAREST)
                cell = sprites[name][k] if k < len(sprites[name]) else -1
                a = anchors[actor][cell] if 0 <= cell < len(anchors[actor]) else None
                d = ImageDraw.Draw(im)
                if a:
                    gx, gy, ang, ln, cf = a
                    tx, ty = gx + math.cos(math.radians(ang)) * max(10, ln), gy - math.sin(math.radians(ang)) * max(10, ln)
                    d.line([(gx * 2, gy * 2), (tx * 2, ty * 2)], fill=(255, 0, 255, 255), width=2)
                    d.ellipse([gx * 2 - 4, gy * 2 - 4, gx * 2 + 4, gy * 2 + 4], outline=(0, 255, 255, 255) if cf else (255, 160, 0, 255), width=2)
                tiles.append(im)
    cols = 8; rows = (len(tiles) + cols - 1) // cols
    sheet = Image.new('RGBA', (320 * cols, 320 * rows), (30, 34, 40, 255))
    for i, t in enumerate(tiles):
        sheet.alpha_composite(t, ((i % cols) * 320, (i // cols) * 320))
    sheet.save(path)


def main() -> None:
    data = load_data(); anchors = analyse(data)
    found = {a: sum(1 for r in anchors[a] if r) for a in ACTORS}
    print('anchors found:', found, 'of', {a: len(anchors[a]) for a in ACTORS})
    if '--preview' in sys.argv:
        out = Path(sys.argv[sys.argv.index('--preview') + 1]) if len(sys.argv) > sys.argv.index('--preview') + 1 else ROOT / 'attach_preview.png'
        preview(data, anchors, out); print('preview', out); return
    payload = json.dumps(anchors, separators=(',', ':'))
    target = ROOT / 'scripts/equipment_attach_data/equipment_attach_data.gml'
    target.parent.mkdir(exist_ok=True)
    target.write_text('/// GENERATED by tests/tools/characters/build_attach_points.py - do not edit by hand.\n'
                      '/// Per actor and cell: [grip_x, grip_y, angle_deg, length] in frame coordinates, or undefined (no weapon visible).\n'
                      f"function equipment_attach_data() {{\n    static d=json_parse(@'{payload}');\n    return d;\n}}\n", encoding='utf-8')
    print('written', target)


if __name__ == '__main__':
    main()
