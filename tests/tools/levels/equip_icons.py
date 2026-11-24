"""Procedural pixel-art equipment icons (sword, staff, bow, helmet, chest, gloves, boots, amulet) -> spr_eq_icons.
Run: python tests/tools/levels/equip_icons.py   (registers the sprite in FirstGame.yyp)
"""
from __future__ import annotations

import math

import numpy as np

from pixsdf import (Material, Prim, box, capsule, cylinder, ellipsoid, hexramp, render, rot, sphere, torus, autocrop)
from gm_project import Project

STEEL = hexramp('15181e', '232831', '343b47', '4a5361', '65707f', '8692a0', 'abb6c2', 'd6dee6')
GOLD = hexramp('2a1a08', '4a2f0c', '6e4812', '956618', 'bd8a25', 'deb24a', 'f5d985')
LEATHER = hexramp('140c08', '24150d', '362013', '4a2d1b', '603d25', '7a5133', '946946')
WOOD = hexramp('150f0b', '231912', '33251a', '453223', '58412e', '6e533b', '8a6a4a')
CLOTH = hexramp('1c0a0c', '2e1015', '46161e', '621f28', '7f2b33', '9c3c40')
GEM_V = hexramp('211036', '3a1a5c', '582a86', '7b43ad', 'a46ad0', 'cf9fef', 'f1dcff')
GEM_C = hexramp('0d2d3d', '13506a', '1c7896', '2ea6c0', '5dd2e0', 'a6f2f4', 'e8ffff')
GEM_R = hexramp('300808', '5a0f10', '8a1a18', 'b82e24', 'e0503a', 'ff8a66', 'ffd0b8')
STRING = hexramp('3a352a', '766d59', 'b3a98f', 'e6dfc8')


def mats():
    return {
        'steel': Material(STEEL, spec=0.55, vary=0.05, grain=0.03, rim=0.22),
        'gold': Material(GOLD, spec=0.5, vary=0.05, grain=0.03, rim=0.2),
        'leather': Material(LEATHER, vary=0.1, grain=0.08, grain_freq=0.5, rim=0.1),
        'wood': Material(WOOD, vary=0.12, grain=0.08, grain_freq=0.45, rim=0.1),
        'cloth': Material(CLOTH, vary=0.1, grain=0.06, rim=0.08),
        'gem_v': Material(GEM_V, spec=0.7, emit=True, rim=0.3),
        'gem_c': Material(GEM_C, spec=0.7, emit=True, rim=0.3),
        'gem_r': Material(GEM_R, spec=0.7, emit=True, rim=0.3),
        'string': Material(STRING, vary=0.0, grain=0.0, rim=0.0),
    }


def rotate(prims, m):
    out = []
    for p in prims:
        a = m @ np.array(p.a, dtype=float); b = m @ np.array(p.b, dtype=float)
        rotm = None if p.kind in ('capsule', 'cone', 'sphere') else (m if p.rotm is None else m @ p.rotm)
        out.append(Prim(p.kind, p.mat, tuple(a), tuple(b), p.r, p.r2, p.size, rotm, p.k, p.neg, p.disp))
    return out


def tilt(prims, deg):  # rotate in the screen plane (about the y/depth axis)
    return rotate(prims, rot(pitch=deg))


def sword():
    p = [box((0, 0, 9), (2.4, 0.9, 14), 'steel', round_=0.4),
         box((0, -0.4, 9), (0.5, 0.9, 13), 'steel', round_=0.2),
         box((0, 0, -5.5), (8, 1.8, 1.4), 'gold', round_=0.6),
         cylinder((0, 0, -10), 1.6, 3.6, 'leather', round_=0.3),
         sphere((0, 0, -15), 2.5, 'gold')]
    return tilt(p, 42)


def staff():
    p = [cylinder((0, 0, -2), 1.7, 17, 'wood', round_=0.5),
         torus((0, 0, 14.5), 3.2, 1.0, 'gold', rotm=rot(roll=90)),
         sphere((0, 0, 19.5), 4.4, 'gem_v'),
         sphere((0, 0, -19), 2.0, 'gold')]
    return tilt(p, 32)


def bow():
    p = []
    n = 9
    for i in range(n):
        a0 = math.radians(-70 + 140 * i / n); a1 = math.radians(-70 + 140 * (i + 1) / n)
        r = 19
        w = 1.9 - 0.7 * abs(i - n / 2) / (n / 2)
        p.append(capsule((math.cos(a0) * r - 10, 0, math.sin(a0) * r), (math.cos(a1) * r - 10, 0, math.sin(a1) * r), w, 'wood'))
    top = (math.cos(math.radians(70)) * 19 - 10, 0, math.sin(math.radians(70)) * 19)
    bot = (top[0], 0, -top[2])
    p.append(capsule(top, bot, 0.45, 'string'))
    p.append(box((9, 0, 0), (1.6, 1.3, 3.2), 'leather', round_=0.5))
    return tilt(p, 30)


def helmet():
    p = [sphere((0, 0, 3), 10.5, 'steel'),
         box((0, 0, -10), (16, 16, 9), 'steel', neg=True),
         box((-8.6, -1, -4.5), (2.4, 6.5, 5.5), 'steel', round_=1.2),
         box((8.6, -1, -4.5), (2.4, 6.5, 5.5), 'steel', round_=1.2),
         torus((0, 0, -0.5), 10.6, 1.3, 'gold'),
         box((0, -10.5, 1.5), (6.5, 2.5, 1.0), 'steel', neg=True),
         box((0, -10.8, -3), (1.3, 1.0, 5), 'gold', round_=0.4),
         capsule((0, 1, 13.5), (0, 7, 15), 2.4, 'cloth'), capsule((0, 7, 15), (0, 12, 10), 2.0, 'cloth')]
    return rotate(p, rot(yaw=-18))


def chest():
    p = [box((0, 0, 1), (7.5, 4.2, 9.5), 'steel', round_=3.2),
         box((0, 0, -8), (6.2, 4.0, 2.5), 'steel', round_=1.6),
         sphere((0, -2.5, 12), 4.6, 'steel', neg=True),
         ellipsoid((-10, 0, 7.5), (5.2, 5.0, 3.6), 'steel', rotm=rot(pitch=-18)),
         ellipsoid((10, 0, 7.5), (5.2, 5.0, 3.6), 'steel', rotm=rot(pitch=18)),
         torus((-10, 0, 7.0), 4.6, 0.8, 'gold', rotm=rot(pitch=-18)), torus((10, 0, 7.0), 4.6, 0.8, 'gold', rotm=rot(pitch=18)),
         box((0, -0.3, -4.8), (7.6, 4.5, 1.3), 'leather', round_=0.5),
         box((0, -4.6, -4.8), (1.5, 0.5, 1.5), 'gold', round_=0.3),
         box((0, -4.1, 3), (0.8, 0.4, 5.5), 'gold', round_=0.3)]
    return p


def gloves():
    p = [box((0, 0, -6), (6.5, 4, 4), 'leather', round_=1.6),
         box((0, 0, 3), (6, 3.4, 5), 'leather', round_=2.2),
         torus((0, 0, -2.2), 6.2, 1.0, 'steel')]
    for i, x in enumerate((-4.2, -1.4, 1.4, 4.2)):
        p.append(capsule((x, -0.5, 7), (x * 1.08, -1.5, 13 - abs(x) * 0.5), 1.4, 'leather'))
    p.append(capsule((-6.5, -0.5, 2), (-9.5, -1.5, 7), 1.5, 'leather'))
    p.append(box((0, -3.6, 3), (4.5, 0.6, 3.2), 'steel', round_=0.5))
    return tilt(p, 12)


def boots():
    p = [box((0, 0, 3), (5, 5, 9), 'leather', round_=2.0),
         box((5, 0, -7.5), (9.5, 5, 2.8), 'leather', round_=2.4),
         box((5, 0, -10.2), (10, 5.4, 0.8), 'wood', round_=0.4),
         torus((0, 0, 11), 5.2, 1.2, 'steel'),
         box((-0.5, -5.2, 2), (3.2, 0.5, 1.0), 'gold', round_=0.3)]
    return tilt(p, -6)


def amulet():
    p = [torus((0, 0, 0), 7.5, 1.4, 'gold', rotm=rot(roll=90)),
         sphere((0, -1.2, 0), 5.2, 'gem_r')]
    for i in range(7):
        a = math.radians(30 + 120 * i / 6)
        p.append(sphere((math.cos(a) * 12, 0, 9 + math.sin(a) * 9), 1.1, 'gold'))
    return p


def render_icon(prims, size=48):
    m = mats()
    img = render(prims, m, 96, 96, (48, 56), scale=1.0, dither=0.25, ambient=0.3)
    img, (ox, oy) = autocrop(img, (48, 56))
    h, w = img.shape[:2]
    canvas = np.zeros((size, size, 4), dtype=np.uint8)
    y0 = max(0, (size - h) // 2); x0 = max(0, (size - w) // 2)
    hh = min(h, size); ww = min(w, size)
    canvas[y0:y0 + hh, x0:x0 + ww] = img[:hh, :ww]
    return canvas


def main():
    frames = [render_icon(f()) for f in (sword, staff, bow, helmet, chest, gloves, boots, amulet)]
    for i, f in enumerate(frames):
        a = f[..., 3] > 0
        ys, xs = np.nonzero(a)
        print(i, 'content', (xs.min(), ys.min(), xs.max(), ys.max()) if len(xs) else None)
    p = Project()
    p.sprite('spr_eq_icons', frames, (24, 24), texgroup='Default')
    p.save()
    from PIL import Image
    sheet = np.concatenate(frames, axis=1)
    Image.fromarray(sheet, 'RGBA').resize((sheet.shape[1] * 4, sheet.shape[0] * 4), Image.NEAREST).save('../../../output/eq_icons_preview.png') if False else None
    return frames


if __name__ == '__main__':
    fr = main()
    import sys
    from PIL import Image
    sheet = np.concatenate(fr, axis=1)
    out = sys.argv[1] if len(sys.argv) > 1 else None
    if out:
        Image.fromarray(sheet, 'RGBA').resize((sheet.shape[1] * 4, sheet.shape[0] * 4), Image.NEAREST).save(out)
