"""Level enemies: four material variants derived from the authored master skeleton and four procedural creatures.

All sprites: 8 directions (right, up_right, up, up_left, left, down_left, down, down_right),
actions idle / walk / attack / hurt / death. Derived variants keep the source frame counts
(2/4/2/3/5); creatures use 4/6/4/2/6 frames.
"""
from __future__ import annotations

import colorsys
import zlib
import math
import random
from pathlib import Path

import numpy as np
from PIL import Image

from pixsdf import (box, capsule, cone, ellipsoid, hexramp, Material, render, rot, scale_prims, sphere, transform_prims)

ROOT = Path(__file__).resolve().parents[3]
import sys as _sys_ap; _sys_ap.path.insert(0, str(ROOT / 'tests' / 'tools' / 'assets')); import art_paths as AP  # noqa: E402
SKEL = AP.MASTER_WORLD / 'frames'
DIRS = ['right', 'up_right', 'up', 'up_left', 'left', 'down_left', 'down', 'down_right']
DIR_ANGLE = {d: i * 45 for i, d in enumerate(DIRS)}
SK_ACTIONS = {'idle': 2, 'walk': 4, 'attack': 2, 'hurt': 3, 'death': 5}
CR_ACTIONS = {'idle': 4, 'walk': 6, 'attack': 4, 'hurt': 2, 'death': 6}
CANVAS = 104
ORIGIN = (52, 92)


# --------------------------------------------------------------------------- derived humanoids
def _skeleton_frame(action, direction, i):
    im = Image.open(SKEL / f'skeleton-{action}-{direction}-{i}.png').convert('RGBA')
    out = Image.new('RGBA', (CANVAS, CANVAS))
    out.paste(im, (ORIGIN[0] - 48, ORIGIN[1] - 88))
    return np.asarray(out).copy()


def _classify(a):
    rgb = a[:, :, 0:3].astype(np.float64) / 255.0
    mx = rgb.max(axis=2); mn = rgb.min(axis=2)
    L = rgb @ np.array([0.299, 0.587, 0.114])
    sat = np.where(mx > 0, (mx - mn) / np.maximum(mx, 1e-6), 0)
    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    hue = np.zeros_like(L)
    d = np.maximum(mx - mn, 1e-6)
    hue = np.where(mx == r, ((g - b) / d) % 6, np.where(mx == g, (b - r) / d + 2, (r - g) / d + 4)) * 60
    op = a[:, :, 3] > 0
    bone = op & (L > 0.34) & (sat < 0.5) & (hue > 14) & (hue < 70)
    metal = op & ~bone & (sat < 0.16) & (L > 0.22)
    cloth = op & ~bone & ~metal & ((hue < 16) | (hue > 330)) & (sat > 0.28)
    other = op & ~bone & ~metal & ~cloth
    return L, op, bone, metal, cloth, other


def _remap(a, mask, L, ramp, lo=0.06, hi=0.75):
    if not mask.any():
        return
    r = np.asarray(ramp, dtype=np.uint8)
    t = np.clip((L[mask] - lo) / (hi - lo), 0, 0.999)
    a[mask, 0:3] = r[(t * len(r)).astype(int)]


def _dilate(a, px=1, darken=0.82):
    """Thicken a silhouette: new pixels copy a neighbour's colour (slightly darker)."""
    out = a.copy()
    for _ in range(px):
        op = out[:, :, 3] > 0
        grown = out.copy()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            sh = np.roll(np.roll(out, dy, 0), dx, 1)
            take = (~op) & (sh[:, :, 3] > 0) & (grown[:, :, 3] == 0)
            grown[take] = sh[take]
            grown[take, 0:3] = (grown[take, 0:3].astype(np.float64) * darken).astype(np.uint8)
        out = grown
    return out


def _top_edges(op):
    above = np.zeros_like(op); above[1:] = op[:-1]
    return op & ~above


def _hash_mask(shape, seed, p):
    rng = np.random.default_rng(seed)
    return rng.random(shape) < p


def _outline(a):
    op = a[:, :, 3] > 0
    ring = np.zeros_like(op)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        ring |= np.roll(np.roll(op, dy, 0), dx, 1)
    ring &= ~op
    a[ring] = (10, 10, 12, 255)
    return a


VARIANTS = {
    'swskel': dict(bone=hexramp('25271c', '34362a', '474a38', '5c5f48', '74765a', '8e8f6c', 'a6a682'),
                   cloth=hexramp('101309', '191e10', '232b17', '2e3a1f', '3a4827'),
                   metal=hexramp('101716', '18221f', '22302b', '2e3f38', '3c4f45', '506358'),
                   other=hexramp('15110c', '211a12', '2e2418', '3b2f1f', '4a3a27'),
                   moss=hexramp('1b2b14', '2a4119', '3a581f', '4d6f27'), mud=(28, 22, 15), dilate=0, glow=None),
    'knight': dict(bone=hexramp('1c1411', '2c1d16', '41281a', '57341f', '6e4325', '8a552d', 'a56b3a'),
                   cloth=hexramp('0b1615', '102321', '163330', '1e4540', '28584f'),
                   metal=hexramp('15171a', '202429', '2d333a', '3c434b', '4d555d'),
                   other=hexramp('1a1410', '281e17', '38291e', '493626', '5c4430'),
                   moss=hexramp('163019', '1f4223', '2a552d', '376a37'), mud=(20, 24, 18), dilate=1, glow=(90, 230, 190)),
    'ashwar': dict(bone=hexramp('0a0909', '100e0e', '161313', '1d1817', '251e1c', '2f2522', '3a2c27', '8a2a0c', 'e0661a', 'ffc04a'),
                   cloth=hexramp('120707', '1f0b09', '30100c', '45160f', '6a1f10'),
                   metal=hexramp('0d0d0e', '161617', '222122', '302d2c', '453d38'),
                   other=hexramp('0f0b0a', '1a1311', '271c18', '35251f'),
                   moss=hexramp('7a2008', 'c24410', 'f07a1c', 'ffc25a'), mud=None, dilate=0, glow=(255, 150, 50)),
    'armor': dict(bone=hexramp('161a22', '222835', '313949', '434d60', '59657a', '7a879c', 'a7b2c4'),
                  cloth=hexramp('150b20', '221333', '311c49', '432762', '5a347d'),
                  metal=hexramp('1a1e27', '272d39', '374050', '4c5769', '687589', '96a2b6'),
                  other=hexramp('12151c', '1d222c', '2a313e', '3a4352', '4f5a6b'),
                  moss=None, mud=None, dilate=2, glow=(190, 120, 255)),
}


def derive_frame(variant, action, direction, i):
    v = VARIANTS[variant]
    a = _skeleton_frame(action, direction, i)
    if v['dilate']:
        a = _dilate(a, v['dilate'])
    L, op, bone, metal, cloth, other = _classify(a)
    out = a.copy()
    _remap(out, bone, L, v['bone'][:7] if variant == 'ashwar' else v['bone'], 0.25, 0.78)
    _remap(out, cloth, L, v['cloth'], 0.05, 0.45)
    _remap(out, metal, L, v['metal'], 0.15, 0.8)
    _remap(out, other, L, v['other'], 0.03, 0.5)
    seed = zlib.crc32(f"{variant}{action}{direction}{i}".encode()) & 0xFFFF
    h = out.shape[0]
    ys = np.nonzero(op.any(axis=1))[0]
    if v['moss'] is not None:
        tops = _top_edges(op) & (bone | other | metal)
        ramp = np.asarray(v['moss'], dtype=np.uint8)
        sel = tops & _hash_mask(op.shape, seed, 0.75)
        out[sel, 0:3] = ramp[np.clip((L[sel] * len(ramp) * 1.6).astype(int), 0, len(ramp) - 1)]
        below = np.zeros_like(sel); below[1:] = sel[:-1]
        sel2 = below & op & _hash_mask(op.shape, seed + 1, 0.45)
        out[sel2, 0:3] = ramp[np.clip((L[sel2] * len(ramp)).astype(int), 0, len(ramp) - 1)]
    if v['mud'] is not None and len(ys):
        y0 = ys[0]; y1 = ys[-1]
        cut = int(y1 - (y1 - y0) * 0.24)
        lower = op.copy(); lower[:cut] = False
        out[lower, 0:3] = (out[lower, 0:3].astype(np.float64) * 0.55 + np.array(v['mud']) * 0.45).astype(np.uint8)
    if variant == 'knight':
        specks = op & _hash_mask(op.shape, seed + 3, 0.035) & (bone | other)
        out[specks, 0:3] = (150, 160, 140)
    if variant == 'ashwar':
        hot = bone & (L > 0.70)
        out[hot, 0:3] = np.asarray(v['bone'][-2:], dtype=np.uint8)[(L[hot] > 0.75).astype(int)]
        rim = _top_edges(op) & _hash_mask(op.shape, seed + 4, 0.3)
        out[rim, 0:3] = (176, 62, 18)
    if v['glow'] is not None and len(ys):
        # Hollow eye sockets / joints: darkest interior pixels of the upper body begin to glow.
        y0 = ys[0]; y1 = ys[-1]
        upper = np.zeros_like(op); upper[y0:int(y0 + (y1 - y0) * 0.22)] = True
        interior = op.copy()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            interior &= np.roll(np.roll(op, dy, 0), dx, 1)
        eyes = interior & upper & (L < 0.16)
        out[eyes, 0:3] = v['glow']
    return _outline(out)


def build_derived(variant):
    frames = {}
    for action, n in SK_ACTIONS.items():
        for d in DIRS:
            frames[(action, d)] = [derive_frame(variant, action, d, i) for i in range(n)]
    return frames


# --------------------------------------------------------------------------- creatures
def creature_mats():
    return {
        'crawler_skin': Material(hexramp('0e120b', '161d11', '1f2a17', '2a381d', '374824', '475a2c', '5a6e36'), spec=0.45,
                                 top=(hexramp('0b0f09', '12180d', '1a2312', '232f17', '2d3c1c'), 0.55, 0.12, 0.6, 5), grain=0.05, rim=0.12),
        'crawler_belly': Material(hexramp('2c2a1c', '3f3c27', '555134', '6d6842', '878053'), spec=0.3, grain=0.05),
        'eye_yellow': Material(hexramp('7a5a10', 'c8961e', 'f4d24a', 'fff3a6'), emit=True),
        'eye_cyan': Material(hexramp('1d6a7a', '3cb4c8', '8ff0ff', 'e8ffff'), emit=True),
        'eye_violet': Material(hexramp('4b2a8a', '8656d6', 'c49cff', 'f3e6ff'), emit=True),
        'shroom_cap': Material(hexramp('1a0f1d', '28172c', '38203d', '4a2a50', '5e3666', '76447e'), spec=0.3,
                               spots=(hexramp('5ea42a', '8fd43c', 'c8f878', 'f0ffc8'), 0.11, 0.66, 9, True), grain=0.05),
        'shroom_gill': Material(hexramp('241a1a', '342626', '483434', '5c4444'), grain=0.05),
        'shroom_stem': Material(hexramp('2b2a20', '3e3d2e', '55533f', '6e6b52', '8a8667', 'a6a27f'), grain=0.06),
        'spirit_robe': Material(hexramp('0b1826', '12263a', '1a3650', '25496a', '345f86', '4c7ba3', '76a3c4', 'b4dcf0'), spec=0.35, rim=0.55, grain=0.05, alpha=0.9),
        'spirit_face': Material(hexramp('22384e', '35536f', '4f7590', 'a6d4e6'), spec=0.3, rim=0.3),
        'ice_shard': Material(hexramp('1f4766', '2d6589', '4588ab', '67adc9', '95d2e4', 'c9eef6'), spec=0.8, rim=0.4, grain=0.02),
        'stone_golem': Material(hexramp('101216', '181b21', '22262d', '2d323b', '3a404b', '4b525e', '5f6773'),
                                top=(hexramp('4b5a6c', '62748a', '7f91a6', '9eafc2'), 0.9, 0.07, 0.3, 3), grain=0.05,
                                cracks=(0.12, 1, 1, 1, 0.92, 2, 4), specks=(0.4, 0.84, 1, 6)),
        'golem_crystal': Material(hexramp('0d2d3d', '13506a', '1c7896', '2ea6c0', '5dd2e0', 'a6f2f4'), spec=0.8, rim=0.35),
        'golem_glow': Material(hexramp('1c7896', '2ea6c0', '5dd2e0', 'a6f2f4', 'e8ffff'), emit=True),
        'golem_dead': Material(hexramp('0f2028', '173442', '214a5c', '2c6074'), spec=0.4),
        'dark': Material(hexramp('050506', '0b0b0d', '121215'), grain=0.0),
    }


def _gait(t, phase=0.0):
    return math.sin((t + phase) * math.tau)


def crawler_model(action, t):
    """Swamp crawler: segmented slimy salamander-leech, model faces +x. t in [0,1)."""
    P = []
    lunge = 0.0; jaw = 0.12; flat = 1.0; drop = 0.0; curl = 0.0
    if action == 'attack':
        lunge = [0, 3, 12, 6][min(3, int(t * 4))]; jaw = [0.15, 0.25, 0.6, 0.3][min(3, int(t * 4))]
    if action == 'hurt':
        lunge = -5; jaw = 0.4
    if action == 'death':
        k = min(1.0, t * 1.25); flat = 1 - 0.45 * k; drop = 4 * k; curl = k
    und = 0.0 if action in ('idle', 'death') else 1.0
    breathe = 1 + (0.04 * math.sin(t * math.tau) if action == 'idle' else 0)
    segs = [(-26, 7.5), (-16, 9.5), (-5, 11.0), (6, 10.0)]
    pts = []
    for i, (x, r) in enumerate(segs):
        y = math.sin(t * math.tau * (1 if action == 'walk' else 0) + i * 1.1) * 5 * und + curl * (i - 1.5) * 6
        z = r * 0.7 * flat * breathe - drop + 2
        pts.append((x + lunge * (i / 3), y, z, r))
    for (x, y, z, r), nxt in zip(pts, pts[1:] + [None]):
        P.append(ellipsoid((x, y, z), (r * 1.15, r, r * 0.72 * flat), 'crawler_skin', k=5))
        P.append(ellipsoid((x, y, z - r * 0.35), (r * 0.9, r * 0.75, r * 0.35 * flat), 'crawler_belly', k=3))
    hx, hy, hz, _ = pts[-1]
    hx += 11 + lunge * 0.4
    P.append(ellipsoid((hx, hy, hz + 1), (10, 8.5, 6.5 * flat), 'crawler_skin', k=4))
    P.append(ellipsoid((hx + 3, hy, hz - 3 - jaw * 4), (8, 7, 2.6), 'crawler_belly', rotm=rot(pitch=jaw * 30), k=1.5))
    for s in (-1, 1):
        P.append(sphere((hx + 6, hy + s * 4.5, hz + 4), 2.1, 'eye_yellow'))
    # Legs: three pairs with alternating gait.
    for li, (x, y, z, r) in enumerate(pts[:3]):
        for s in (-1, 1):
            ph = _gait(t, li * 0.33 + (0.5 if s > 0 else 0)) * (1 if action == 'walk' else 0.15)
            knee = (x + ph * 5, y + s * (r + 5), max(2.5, z * 0.6))
            foot = (x + 4 + ph * 9, y + s * (r + 10), 1.0 - drop * 0.2)
            if action == 'death':
                foot = (x + s * 3, y + s * (r + 4), z + 6 * curl)
            P.append(capsule((x, y + s * r * 0.6, z), knee, 2.4, 'crawler_skin'))
            P.append(capsule(knee, foot, 1.8, 'crawler_skin'))
    P.append(cone((pts[0][0], pts[0][1], pts[0][2]), (pts[0][0] - 16, pts[0][1] + math.sin(t * math.tau) * 6 * und, 3), 6, 1.2, 'crawler_skin', k=3))
    return P


def shroom_model(action, t):
    """Fungus creature: stubby stem body, glowing-spotted cap, little arms and feet; faces +x."""
    P = []
    bob = abs(math.sin(t * math.tau)) * 3 if action == 'walk' else math.sin(t * math.tau) * 1.0
    tilt = 0.0; squash = 1.0; sink = 0.0; cap_drop = 0.0
    if action == 'attack':
        tilt = [5, -12, 38, 20][min(3, int(t * 4))]
    if action == 'hurt':
        squash = 0.82; tilt = -15
    if action == 'death':
        k = min(1.0, t * 1.2); sink = 14 * k; squash = 1 - 0.4 * k; cap_drop = 10 * k; tilt = 30 * k
    stem_h = 22 * squash
    base_z = 6 + bob - sink * 0.3
    P.append(cone((0, 0, base_z), (1.5, 0, base_z + stem_h), 10.5, 8.5, 'shroom_stem', k=3))
    m = rot(pitch=tilt)
    cap_c = np.array((2, 0, base_z + stem_h + 4 - cap_drop))
    P.append(ellipsoid(tuple(cap_c), (19, 18, 9.5 * squash), 'shroom_cap', rotm=m, k=2, disp=(0.6, 0.18, 4, 1, 1, 1)))
    P.append(ellipsoid(tuple(cap_c + m @ np.array((0, 0, -3.5))), (16.5, 15.5, 3.5), 'shroom_gill', rotm=m, k=1))
    for s in (-1, 1):
        P.append(sphere((8.5, s * 4, base_z + stem_h * 0.62), 2.0, 'eye_yellow' if action != 'death' else 'shroom_gill'))
        arm = 0.0
        if action == 'walk':
            arm = _gait(t, 0.5 if s > 0 else 0) * 6
        if action == 'attack':
            arm = [0, -6, 10, 6][min(3, int(t * 4))]
        P.append(capsule((2, s * 9, base_z + stem_h * 0.5), (7 + arm, s * 14, base_z + stem_h * 0.25), 2.6, 'shroom_stem'))
        step = _gait(t, 0 if s > 0 else 0.5) * (5 if action == 'walk' else 0)
        P.append(capsule((0, s * 5, base_z + 1), (step, s * 6, 2.2), 3.2, 'shroom_stem'))
    if action == 'attack' and t > 0.45:
        rng = random.Random(int(t * 100))
        for i in range(6):
            P.append(sphere((14 + rng.uniform(0, 16), rng.uniform(-14, 14), base_z + stem_h + rng.uniform(-6, 10)), 1.6, 'eye_yellow'))
    return P


def spirit_model(action, t):
    """Ice spirit: hooded wraith with a dark face, glowing eyes, tattered robe and orbiting shards; floats in-game."""
    P = []
    sway = math.sin(t * math.tau) * 3
    reach = 0.0; shrink = 1.0
    if action == 'attack':
        reach = [0, -4, 12, 7][min(3, int(t * 4))]
    if action == 'hurt':
        reach = -6
    if action == 'death':
        shrink = 1 - 0.6 * min(1.0, t * 1.15)
    z0 = 8
    S = shrink
    P.append(cone((sway * 0.6 - 3, 0, z0), (0, 0, z0 + 28 * S), 15 * S, 8.5 * S, 'spirit_robe', k=4, disp=(2.6, 0.2, 7, 1, 1, 0.35)))
    P.append(ellipsoid((0, 0, z0 + 37 * S), (10.5 * S, 10 * S, 11.5 * S), 'spirit_robe', k=3))
    P.append(sphere((8.5 * S, 0, z0 + 36 * S), 6.2 * S, 'spirit_robe', neg=True))
    P.append(ellipsoid((3.5 * S, 0, z0 + 36 * S), (4.5 * S, 5.5 * S, 6 * S), 'dark'))
    for s in (-1, 1):
        P.append(sphere((7.6 * S, s * 2.5 * S, z0 + 37 * S), 1.6 * S, 'eye_cyan'))
        hand = (11 + reach, s * 12 * S, z0 + 20 * S + reach * 0.4)
        P.append(cone((1, s * 8.5 * S, z0 + 29 * S), hand, 3.6 * S, 2.0 * S, 'spirit_robe', k=1.5))
        for f in (-1, 0, 1):
            P.append(capsule(hand, (hand[0] + 4, hand[1] + f * 1.8, hand[2] - 2), 0.8, 'spirit_face'))
    for i in range(4):  # tattered tail wisps
        a = i / 4 * math.tau + t * math.tau
        P.append(cone((-2 + math.cos(a) * 6, math.sin(a) * 8, z0 + 3), (-12 + math.cos(a) * 7, math.sin(a) * 11, z0 - 5 + i), 3.0 * S, 0.6, 'spirit_robe'))
    for i in range(3):  # orbiting ice shards
        a = i / 3 * math.tau + t * math.tau * (2 if action == 'attack' else 1)
        rr = 19 + (8 if action == 'attack' and t > 0.4 else 0)
        zz = max(2, z0 + 24 - 30 * t) if action == 'death' else z0 + 26 + math.sin(a * 2) * 3
        P.append(ellipsoid((math.cos(a) * rr, math.sin(a) * rr, zz), (2.2, 2.2, 4.6), 'ice_shard', rotm=rot(roll=25, yaw=math.degrees(a))))
    return P


def construct_model(action, t):
    """Magical construct: chunky stone blocks around a glowing crystal core; faces +x."""
    P = []
    step = _gait(t) if action == 'walk' else 0.0
    arms = 0.0; slam = 0.0; fall = 0.0; dead = action == 'death'
    if action == 'attack':
        arms = [0.4, 1.0, 0.2, -0.6][min(3, int(t * 4))]
    if action == 'hurt':
        arms = -0.2
    if dead:
        fall = min(1.0, t * 1.2)
    bob = abs(step) * 2
    torso_z = 36 + bob - fall * 26
    glow = 'golem_dead' if dead and t > 0.5 else 'golem_glow'
    P.append(box((0, 0, torso_z), (11, 15, 13), 'stone_golem', rotm=rot(pitch=8 * fall, roll=-10 * fall), round_=3, disp=(0.9, 0.14, 2, 1, 1, 1)))
    P.append(box((2, 0, torso_z + 17 - fall * 6), (6.5, 7, 5.5), 'stone_golem', rotm=rot(yaw=fall * 25, pitch=fall * 40), round_=2))
    P.append(box((7.5, 0, torso_z + 17 - fall * 6), (1.0, 5.0, 1.0), glow))
    P.append(ellipsoid((11.5, 0, torso_z + 2), (3.5, 5.5, 6.5), 'golem_crystal' if not dead else 'golem_dead'))
    P.append(ellipsoid((13.8, 0, torso_z + 2), (1.6, 3.0, 3.8), glow))
    for s in (-1, 1):
        sh = (0, s * 19, torso_z + 9)
        lift = arms * 16
        hand = (8 + arms * 6 + fall * 6, s * 22, torso_z - 6 + lift - fall * 18)
        if action == 'attack' and arms < 0:
            hand = (14, s * 12, 4)
        P.append(ellipsoid(sh, (8, 8, 7.5), 'stone_golem', k=2, disp=(0.8, 0.15, 5 + s, 1, 1, 1)))
        P.append(capsule(sh, hand, 5.5, 'stone_golem', k=2))
        P.append(box(hand, (6, 6, 6), 'stone_golem', rotm=rot(yaw=20 * s, roll=15), round_=2))
        P.append(ellipsoid((hand[0] + 4, hand[1], hand[2] + 2), (2, 2.5, 3), glow))
        leg = step * (1 if s > 0 else -1) * 6
        hip = (0, s * 8, torso_z - 12)
        foot = (leg, s * 9, 5 if not dead else 4)
        P.append(capsule(hip, foot, 5.5 - fall * 0.5, 'stone_golem', k=2))
        P.append(box((foot[0] + 2, foot[1], 4), (8, 6, 4), 'stone_golem', round_=1.5))
    if dead and t > 0.3:
        rng = random.Random(7)
        for i in range(5):
            P.append(box((rng.uniform(-24, 24), rng.uniform(-22, 22), 4), (4 + rng.random() * 3, 3 + rng.random() * 3, 3), 'stone_golem', rotm=rot(yaw=rng.uniform(0, 90), roll=rng.uniform(-30, 30)), round_=1))
    return P


CREATURES = {'crawler': crawler_model, 'shroom': shroom_model, 'spirit': spirit_model, 'construct': construct_model}


def creature_spec(kind):
    """Canvas, integer origin and render scale of a creature, baked at its gameplay scale (pixel density 1:1).
    The scale is read from scripts/level_worlds (cfg.scale of the kind with this sprite prefix), so it cannot drift."""
    import re
    src = (ROOT / 'scripts' / 'level_worlds' / 'level_worlds.gml').read_text(encoding='utf-8')
    m = re.search(r'prefix:"spr_lv_en_' + kind + r'_",[^}]*?scale:([\d.]+)', src)
    k = float(m.group(1)) if m else 1.0
    return round(CANVAS * k), (round(ORIGIN[0] * k), round(ORIGIN[1] * k)), k


def render_creature_frame(args):
    kind, action, direction, i = args
    canvas, origin, k = creature_spec(kind)
    n = CR_ACTIONS[action]
    t = i / n
    if action == 'death':
        t = i / (n - 1)
    prims = CREATURES[kind](action, t)
    if kind == 'construct':
        prims = scale_prims(prims, 0.74)
    prims = transform_prims(prims, yaw=DIR_ANGLE[direction])
    img = render(prims, creature_mats(), canvas, canvas, origin, scale=k, max_steps=90)
    if kind == 'spirit' and action == 'death':
        img[:, :, 3] = (img[:, :, 3].astype(np.float64) * (1 - 0.8 * t)).astype(np.uint8)
    if kind == 'spirit':
        img[:, :, 3] = np.where(img[:, :, 3] > 0, np.maximum(img[:, :, 3], 200), 0).astype(np.uint8) if action != 'death' else img[:, :, 3]
    return (kind, action, direction, i), img
