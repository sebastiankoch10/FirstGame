"""Bake boss sprites at their in-game size (1 art pixel = 1 world pixel, render_pipeline): area downscale with
premultiplied alpha, one shared palette per boss and an outline. The game then draws them at scale 1 instead of
scaling 512 px frames on the GPU (which drops and doubles pixels). Sources stay untouched.

  python tests/tools/bosses/build_boss_baked.py behemoth     # spr_bv2_behemoth_* (x 340/430) -> spr_bv2b_behemoth_*
  python tests/tools/bosses/build_boss_baked.py twins        # witches from the 4x8 source sheets -> spr_bv2b_<fire|ice>_*

Twins: the 128 px frames were cut from the source cells (221.75 px) at about x0.46, figure centred, feet at y=116, and the
game drew them x1.5. They are re-baked from the source at the fitted scale x1.5 (192 px frames, origin 96,174) and
aligned to the old frame scaled x1.5, so anchors and hover stay where they were.
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tests' / 'tools' / 'art'))
sys.path.insert(0, str(ROOT / 'tests' / 'tools' / 'levels'))
import pixelize as P  # noqa: E402

BOSSES = {'behemoth': dict(prefix='spr_bv2_behemoth_', out='spr_bv2b_behemoth_', scale=340 / 430, colors=48)}


def load(sprite: str):
    d = ROOT / 'sprites' / sprite
    yy = json.loads(re.sub(r',(\s*[}\]])', r'\1', (d / f'{sprite}.yy').read_text(encoding='utf-8')))
    frames = [Image.open(d / f"{f['name']}.png").convert('RGBA') for f in yy['frames']]
    return frames, (yy['sequence']['xorigin'], yy['sequence']['yorigin'])


TWIN_ACTIONS = [('idle', 0, range(4)), ('fly', 1, range(4)), ('fast', 2, range(4)), ('turn', 1, range(4)), ('charge', 3, range(4)),
                ('cast', 4, range(4)), ('joint', 5, range(4)), ('hurt', 6, [0, 1]), ('phase', 6, [2, 3]), ('death', 7, range(4))]


def twin_frame(src, fam, r, c, up=1.5, size=192, origin=(96, 174)):
    """One witch frame re-baked from the source cell at in-game size, aligned to the old frame scaled by up."""
    sys.path.insert(0, str(ROOT / 'tests' / 'tools' / 'assets'))
    import art_paths as A
    cw = src.width / 4
    cell = src.crop((round(c * cw), round(r * cw), round((c + 1) * cw), round((r + 1) * cw)))
    old = Image.open(A.BOSS_V2 / 'frames' / fam / f'{r}-{c}.png').convert('RGBA')
    old_up = np.asarray(old.resize((round(old.width * up), round(old.height * up)), Image.NEAREST))[..., 3] > 128
    oy0 = origin[1] - round(116 * up)
    ref = np.zeros((size, size), bool)
    ref[max(0, oy0):max(0, oy0) + old_up.shape[0], origin[0] - old_up.shape[1] // 2:origin[0] - old_up.shape[1] // 2 + old_up.shape[1]] = old_up[:size - max(0, oy0)]
    best = None
    for s in np.arange(.44, .4801, .0025):
        img = P.sharpen(P.premul_down(cell, s * up))
        a = np.asarray(img)
        ys, xs = np.nonzero(a[..., 3] > 128)
        bx, by = origin[0] - (xs.min() + xs.max() + 1) / 2, origin[1] - (ys.max() + 1)
        for dy in range(-6, 7, 2):
            for dx in range(-6, 7, 2):
                cv = Image.new('RGBA', (size, size), (0, 0, 0, 0))
                cv.alpha_composite(img, (int(round(bx + dx)), int(round(by + dy))))
                al = np.asarray(cv)[..., 3] > 128
                iou = (al & ref).sum() / max(1, (al | ref).sum())
                if best is None or iou > best[0]:
                    best = (iou, cv)
    return best[1], best[0]


def bake_twins(pj, preview=False):
    sys.path.insert(0, str(ROOT / 'tests' / 'tools' / 'assets'))
    import art_paths as A
    out, ious = {}, []
    for fam in ('fire', 'ice'):
        src = Image.open(A.BOSS_V2 / 'sources' / f'{fam}.png').convert('RGBA')
        cache = {}
        for action, row, cols in TWIN_ACTIONS:
            frames = []
            for c in cols:
                if (row, c) not in cache:
                    cache[(row, c)] = twin_frame(src, fam, row, c)
                frames.append(cache[(row, c)][0]); ious.append(cache[(row, c)][1])
            out[f'spr_bv2b_{fam}_{action}'] = frames
        pal = P.palette_of([out[f'spr_bv2b_{fam}_{a}'][0] for a, _, _ in TWIN_ACTIONS], 48)
        for action, _, _ in TWIN_ACTIONS:
            n = f'spr_bv2b_{fam}_{action}'
            out[n] = [P.outline(P.quantize(f, pal)) for f in out[n]]
            if not preview:
                pj.sprite(n, [np.asarray(f) for f in out[n]], (96, 174))
    print('twins baked:', len(out), 'sprites; alignment IoU min %.2f mean %.2f' % (min(ious), sum(ious) / len(ious)))
    if preview:
        import os
        sys.path.insert(0, str(ROOT / 'tests' / 'tools' / 'assets'))
        import art_paths as A
        tiles = []
        for fam in ('fire', 'ice'):
            for action, row, cols in TWIN_ACTIONS[::3]:
                old = Image.open(A.BOSS_V2 / 'frames' / fam / f'{row}-{list(cols)[0]}.png').convert('RGBA').resize((192, 192), Image.NEAREST)
                tiles += [old, out[f'spr_bv2b_{fam}_{action}'][0]]
        sheet = Image.new('RGBA', (192 * len(tiles) // 2, 384), (40, 48, 40, 255))
        for i, im in enumerate(tiles):
            sheet.alpha_composite(im, ((i // 2) * 192, (i % 2) * 192))
        dst = Path(os.environ['LOCALAPPDATA']) / 'FirstGame-Tests' / 'boss-bake' / 'twins_preview.png'
        dst.parent.mkdir(parents=True, exist_ok=True)
        sheet.convert('RGB').save(dst)
        print('preview:', dst)


def main():
    from gm_project import Project
    which = sys.argv[1] if len(sys.argv) > 1 else 'behemoth'
    if which == 'twins':
        pj = Project()
        preview = '--preview' in sys.argv
        bake_twins(pj, preview)
        if not preview:
            pj.save()
        return
    cfg = BOSSES[which]
    names = sorted(p.name for p in (ROOT / 'sprites').iterdir() if p.name.startswith(cfg['prefix']))
    s = cfg['scale']
    baked = {}
    for n in names:
        frames, origin = load(n)
        baked[n] = ([P.sharpen(P.premul_down(f, s)) for f in frames], (round(origin[0] * s), round(origin[1] * s)))
    pal = P.palette_of([b[0][0] for b in baked.values()], cfg['colors'])
    pj = Project()
    for n, (frames, origin) in baked.items():
        out = [np.asarray(P.outline(P.quantize(f, pal))) for f in frames]
        pj.sprite(cfg['out'] + n[len(cfg['prefix']):], out, origin)
    pj.save()
    print(which, 'baked:', len(baked), 'sprites at x', round(s, 4), '| new:', len(pj.added))


if __name__ == '__main__':
    main()
