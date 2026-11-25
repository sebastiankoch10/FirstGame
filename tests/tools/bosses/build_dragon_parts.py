"""Dragon as a composite unit (user decision 25.11.): body without head and neck, head (closed and open), neck ring
and dorsal spike as separate parts, all baked at in-game size (1 art pixel = 1 world pixel, render_pipeline) with one
shared 48-colour palette and an outline on the original silhouette. Head, ring and spike get 32 RotSprite rotation
frames each, so nothing is rotated (and smeared) at runtime. Poses that stay whole (stomp, death, leap, ...) are baked
at the same size. The source sprites spr_fg_dragon* and the ArtPack originals stay untouched.

  python tests/tools/bosses/build_dragon_parts.py            # writes sprites spr_drg_* and scripts/dragon_parts_data
  python tests/tools/bosses/build_dragon_parts.py --preview  # only a preview sheet (no project writes)
"""
from __future__ import annotations

import argparse
import json
import math
import os
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tests' / 'tools' / 'art'))
sys.path.insert(0, str(ROOT / 'tests' / 'tools' / 'characters'))
sys.path.insert(0, str(ROOT / 'tests' / 'tools' / 'levels'))
import pixelize as P  # noqa: E402
from morph import components  # noqa: E402

S = 300 / 430            # visual_height 300 of the reference height 430 (dragon_draw)
STEPS = 32               # rotation frames per part (11.25 degrees)
SRC_ORIGIN = (256, 480)  # feet of the 512 px source frames
COLORS = 48

# Source geometry, measured on the 512 px frames (see docs/Systeme/Bosse.md).
HEAD_IDLE = [(236, 54), (364, 54), (386, 122), (402, 188), (392, 208), (362, 218), (332, 216), (305, 206), (288, 188),
             (268, 152), (236, 118)]
NECK_UPPER = [(232, 96), (300, 90), (382, 138), (378, 222), (226, 222), (226, 150)]          # moves with the head
NECK_LOWER = [(226, 200), (378, 200), (376, 236), (352, 247), (300, 250), (256, 246), (226, 214)]  # moves with the chest
SOCKET_IDLE = (306, 236)          # where the neck leaves the chest
HEAD_REST = (314, 207)            # where the original head sits on the neck (idle frame 0)
TRACK_BOX = (255, 95, 400, 215)   # head area used to follow the head through other body frames
CHEST_BOX = (268, 244, 352, 300)  # chest plates: the neck socket follows the chest, not the head
HEADS = {  # pose frame, outline polygon, neck joint (pivot), mouth
    'closed': ('charge', 0, [(226, 48), (300, 40), (360, 60), (400, 90), (424, 110), (424, 140), (412, 152), (380, 156),
                             (345, 160), (320, 164), (290, 160), (260, 150), (232, 128), (226, 90)], (325, 160), (412, 133)),
    'open': ('charge', 1, [(226, 48), (330, 42), (385, 68), (414, 98), (414, 124), (402, 150), (402, 174), (372, 180),
                           (340, 172), (312, 166), (285, 160), (255, 150), (232, 128), (226, 90)], (315, 153), (400, 138)),
}
RING = ((309.5, 235.5), (43.5, 9.6))  # ellipse across the neck (idle frame 0): centre, radii
SPIKE = ([(222, 214), (236, 196), (264, 186), (268, 206), (250, 226), (226, 228)], (260, 212))
BODY_POSES = {'idle': 'spr_fg_dragonboss_idle', 'walk': 'spr_fg_dragonboss_walk'}  # hurt: idle body + flash
FULL_POSES = {'stomp': 'spr_fg_dragonboss_stomp', 'phase': 'spr_fg_dragonboss_phase', 'death': 'spr_fg_dragonboss_death',
              'leap': 'spr_fg_dragonextra_leap', 'wingbeat': 'spr_fg_dragonextra_wingbeat',
              'channel': 'spr_fg_dragonextra_channel', 'summon': 'spr_fg_dragonextra_summon'}


def load(sprite: str) -> list[np.ndarray]:
    d = ROOT / 'sprites' / sprite
    yy = json.loads(re.sub(r',(\s*[}\]])', r'\1', (d / f'{sprite}.yy').read_text(encoding='utf-8')))
    return [np.asarray(Image.open(d / f"{f['name']}.png").convert('RGBA')).copy() for f in yy['frames']]


def poly(pts, off=(0, 0)) -> np.ndarray:
    m = Image.new('L', (512, 512), 0)
    ImageDraw.Draw(m).polygon([(x + off[0], y + off[1]) for x, y in pts], fill=255)
    return np.asarray(m) > 0


def track(ref: np.ndarray, frame: np.ndarray, box=TRACK_BOX, search=36) -> tuple[int, int]:
    """Offset of the head area of ref inside frame (sum of squared differences on premultiplied colour)."""
    def pm(a):
        f = a.astype(np.float64)
        return f[..., :3] * (f[..., 3:4] / 255)
    x0, y0, x1, y1 = box
    t = pm(ref[y0:y1, x0:x1])
    F = pm(frame)
    best, arg = None, (0, 0)
    for dy in range(-search, search + 1, 2):
        for dx in range(-search, search + 1, 2):
            if y0 + dy < 0 or x0 + dx < 0 or y1 + dy > 512 or x1 + dx > 512:
                continue
            s = float(((F[y0 + dy:y1 + dy, x0 + dx:x1 + dx] - t) ** 2).mean())
            if best is None or s < best:
                best, arg = s, (dx, dy)
    cx, cy = arg
    for dy in range(cy - 1, cy + 2):
        for dx in range(cx - 1, cx + 2):
            s = float(((F[y0 + dy:y1 + dy, x0 + dx:x1 + dx] - t) ** 2).mean())
            if s < best:
                best, arg = s, (dx, dy)
    return arg


def bake(part: np.ndarray, whole: np.ndarray, box=None):
    """Part and its uncut source, cropped to the same box and downscaled together (same pixel grid)."""
    if box is None:
        ys, xs = np.nonzero(part[..., 3])
        box = (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)
    x0, y0, x1, y1 = box
    p = P.sharpen(P.premul_down(Image.fromarray(np.ascontiguousarray(part[y0:y1, x0:x1]), 'RGBA'), S))
    w = P.premul_down(Image.fromarray(np.ascontiguousarray(whole[y0:y1, x0:x1]), 'RGBA'), S)
    return p, np.asarray(w)[..., 3] > 0, box


def strip_islands(a: np.ndarray) -> np.ndarray:
    for ys, xs in components(a[..., 3] > 0)[1:]:
        a[ys, xs] = 0
    return a


def build(preview: bool):
    idle = load(BODY_POSES['idle'])
    ref = idle[0]
    raw = {}   # name -> list of (part image, original alpha)
    sockets = {}
    full_box = (0, 0, 512, 512)
    for pose, spr in BODY_POSES.items():
        raw[f'body_{pose}'] = []
        sockets[pose] = []
        for fr in load(spr):
            off, chest = track(ref, fr), track(ref, fr, CHEST_BOX, 20)
            alive = fr[..., 3] > 0
            cut = (poly(HEAD_IDLE, off) | poly(NECK_UPPER, off) | poly(NECK_LOWER, chest)) & alive
            body = fr.copy()
            body[cut] = 0
            body = strip_islands(body)
            img, orig, _ = bake(body, fr, full_box)
            raw[f'body_{pose}'].append((img, orig))
            sockets[pose].append(((SOCKET_IDLE[0] + chest[0]) * S - SRC_ORIGIN[0] * S, (SOCKET_IDLE[1] + chest[1]) * S - SRC_ORIGIN[1] * S))
    heads = {}
    for key, (pose, i, pts, pivot, mouth) in HEADS.items():
        fr = load(f'spr_fg_dragonboss_{pose}')[i]
        m = poly(pts) & (fr[..., 3] > 0)
        part = fr.copy()
        part[~m] = 0
        img, orig, box = bake(part, fr)
        heads[key] = dict(img=img, orig=orig, pivot=((pivot[0] - box[0]) * S, (pivot[1] - box[1]) * S),
                          snout=math.degrees(math.atan2(-(mouth[1] - pivot[1]), mouth[0] - pivot[0])),
                          mouth=math.hypot(mouth[0] - pivot[0], mouth[1] - pivot[1]) * S)
    yy, xx = np.mgrid[0:512, 0:512]
    (cx, cy), (rx, ry) = RING
    rm = (((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2 <= 1) & (ref[..., 3] > 0)
    ring = ref.copy()
    ring[~rm] = 0
    ring_img, ring_orig, ring_box = bake(ring, ref)
    sm = poly(SPIKE[0]) & (ref[..., 3] > 0)
    spike = ref.copy()
    spike[~sm] = 0
    spike_img, spike_orig, spike_box = bake(spike, ref)
    for pose, spr in FULL_POSES.items():
        raw[f'full_{pose}'] = [bake(fr, fr, full_box)[:2] for fr in load(spr)]

    pal = P.palette_of([raw['body_idle'][0][0], heads['closed']['img'], heads['open']['img'], ring_img, spike_img,
                        raw['full_stomp'][0][0]], COLORS)

    def finish(img, orig):
        return P.outline(P.quantize(img, pal), orig)
    sprites = {}
    origin = (round(SRC_ORIGIN[0] * S), round(SRC_ORIGIN[1] * S))
    for name, frames in raw.items():
        sprites[f'spr_drg_{name}'] = ([finish(i, o) for i, o in frames], origin)
    for key, h in heads.items():
        frames, size = P.centred_rotations(finish(h['img'], h['orig']), h['pivot'], STEPS, h['snout'])
        sprites[f'spr_drg_head_{key}'] = (frames, (size // 2, size // 2))
    ring_f = finish(ring_img, ring_orig)
    frames, size = P.centred_rotations(ring_f, ((cx - ring_box[0]) * S, (cy - ring_box[1]) * S), STEPS, 90)
    sprites['spr_drg_neck'] = (frames, (size // 2, size // 2))
    frames, size = P.centred_rotations(finish(spike_img, spike_orig), ((SPIKE[1][0] - spike_box[0]) * S, (SPIKE[1][1] - spike_box[1]) * S), STEPS, 90)
    sprites['spr_drg_spike'] = (frames, (size // 2, size // 2))

    spec = dict(
        scale=round(S, 4), steps=STEPS, origin=list(origin),
        sockets={k: [[round(x, 1), round(y, 1)] for x, y in v] for k, v in sockets.items()},
        rest=[round((HEAD_REST[0] - SOCKET_IDLE[0]) * S, 1), round((HEAD_REST[1] - SOCKET_IDLE[1]) * S, 1)],
        head={k: dict(mouth=round(h['mouth'], 1), radius=round(h['img'].height * .34, 1)) for k, h in heads.items()},
        ring=dict(spacing=8, half=round(ring_f.width / 2, 1), radius=round(ring_f.width * .36, 1), taper=.16),
        full=list(FULL_POSES))
    return sprites, spec


def gml(spec: dict) -> str:
    def v(x):
        if isinstance(x, dict):
            return '{' + ','.join(f'{k}:{v(y)}' for k, y in x.items()) + '}'
        if isinstance(x, list):
            return '[' + ','.join(v(y) for y in x) + ']'
        if isinstance(x, str):
            return f'"{x}"'
        return repr(x)
    return ('/// Generated by tests/tools/bosses/build_dragon_parts.py: do not edit by hand.\n'
            '/// Baked dragon parts: sockets per body frame and the rest/hit geometry, in world pixels (facing right,\n'
            '/// relative to the boss origin). Frame k of spr_drg_head_*, spr_drg_neck and spr_drg_spike points k*360/steps.\n'
            'function dragon_parts_spec() {\n    static s=' + v(spec) + ';\n    return s;\n}\n')


def preview_sheet(sprites: dict, out: Path):
    tiles = []
    for name, k in (('spr_drg_body_idle', 0), ('spr_drg_body_idle', 2), ('spr_drg_body_walk', 0), ('spr_drg_body_walk', 2), ('spr_drg_full_leap', 0)):
        tiles.append(sprites[name][0][k])
    for name in ('spr_drg_head_closed', 'spr_drg_head_open', 'spr_drg_neck', 'spr_drg_spike'):
        for k in (0, 2, 4, 8, 28):
            tiles.append(sprites[name][0][k])
    w = max(t.width for t in tiles)
    h = max(t.height for t in tiles)
    cols = 5
    sheet = Image.new('RGBA', (w * cols, h * ((len(tiles) + cols - 1) // cols)), (40, 48, 40, 255))
    for i, t in enumerate(tiles):
        sheet.alpha_composite(t, ((i % cols) * w, (i // cols) * h))
    sheet.convert('RGB').save(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--preview', action='store_true')
    a = ap.parse_args()
    sprites, spec = build(a.preview)
    out = Path(os.environ['LOCALAPPDATA']) / 'FirstGame-Tests' / 'dragon-parts'
    out.mkdir(parents=True, exist_ok=True)
    preview_sheet(sprites, out / 'preview.png')
    (out / 'spec.json').write_text(json.dumps(spec, indent=1), encoding='utf-8')
    print('preview:', out / 'preview.png')
    print(json.dumps(spec)[:900])
    if a.preview:
        return
    from gm_project import Project
    pj = Project()
    for name, (frames, origin) in sprites.items():
        pj.sprite(name, [np.asarray(f) for f in frames], origin, texgroup='Default')
    data = 'dragon_parts_data'
    pj.script(data, gml(spec))
    pj.save()
    print('written:', len(sprites), 'sprites +', data, '| new:', pj.added)


if __name__ == '__main__':
    main()
