"""Level 2 – Der verfluchte Sumpf: procedural props, deterministic layout and baked ground."""
from __future__ import annotations

import math
import random

import numpy as np

from pixsdf import (box, capsule, cone, cylinder, ellipsoid, fbm2, hexramp, Material, rot, sphere, torus, vnoise2, cell2, render_fit)
from props_common import (BONE, MOSS, TOXIC, column, dead_tree, masonry_block, mats_common, mushroom, rock)
from worldgen import (CHUNK, START, WORLD, blobs_field, jitter_grid_points, point_seg_distance, poisson_points, ramp_pick,
                      seg_distance, segments, shift2, stamp, wiggly_path)

SEED = 4271
LEVEL = 'swamp'
PREFIX = 'spr_lv_sw_'

# --------------------------------------------------------------------------- ground palettes
G_SOIL = hexramp('121310', '171812', '1d1d16', '23231a', '2a291e', '323024', '3b382a')
G_MUD = hexramp('0d0c0a', '13110e', '191612', '201c16', '28231b', '312a20')
G_MUD_GLOSS = hexramp('2b2820', '3a3729', '4b4836')
G_MOSS = hexramp('101810', '152014', '1b2918', '22331d', '2a3e22', '334a28', '3e5830')
G_LEAF = hexramp('22180f', '2e2013', '3b2917', '4a321a', '583b1d', '6a4621')
G_GRASS = hexramp('172113', '1e2b17', '27371c', '314422', '3c5128')
G_WATER = hexramp('0a1517', '0d1a1d', '102024', '13272b', '172e32', '1c3639')
G_WATER_DEEP = hexramp('070f11', '091316', '0b171a', '0e1b1f')
G_WATER_HI = hexramp('2a4644', '3b5a56', '527268')
G_ALGAE = hexramp('16261a', '1d3220', '253f27', '2e4c2d')
G_BANK = hexramp('0b0a08', '110f0c', '17140f', '1d1913')
G_TOXIC = hexramp('19300b', '244410', '315a14', '41721a', '558e21', '6fa82c', '93c84a')
G_SPORE = hexramp('17111a', '1f1722', '281e2c', '322636', '3d2f42')
G_PATH = hexramp('16130f', '1c1813', '231e17', '2a241b', '322a1f', '3a3124')
G_STONE = hexramp('1b1e1e', '232727', '2c3131', '363b3a', '414645', '4d5251')


def mats():
    m = mats_common()
    m['lantern_glow'] = Material(hexramp('6b7d2a', '9fb83c', 'd4ea6a', 'f4ffb8'), emit=True)
    m['fungus_cyan'] = Material(hexramp('0b2228', '10343c', '17505a', '217480', '3aa0a6', '76d0cc'), spec=0.3, spots=(hexramp('4fd8d0', '9bfff2', 'e0fff9'), 0.11, 0.62, 44, True))
    m['bark_dark'] = Material(hexramp('0a0a0a', '111211', '191a18', '222420', '2c2f29', '383b33'), top=(MOSS, 0.6, 0.045, 0.8, 7), cracks=(0.16, 1.0, 1.0, 0.18, 0.86, 2, 3), grain=0.05)
    m['iron'] = Material(hexramp('0f0d0c', '1a1513', '2a1e18', '3c271b', '533320', '6d4428'), spec=0.3, grain=0.12)
    m['leaf_green'] = Material(hexramp('0f1a0f', '152414', '1d3119', '263f1f', '304d25', '3c5c2c', '4c6e36'), spec=0.15, grain=0.05, rim=0.08)
    m['leaf_dark'] = Material(hexramp('0b120b', '111a10', '172315', '1e2d1a'), grain=0.04)
    return m


# --------------------------------------------------------------------------- prop builders
def reeds(seed, n=9, h=46.0):
    rng = random.Random(seed); prims = []
    for i in range(n):
        a = rng.uniform(0, math.tau); r = rng.uniform(0, 16)
        x = math.cos(a) * r; y = math.sin(a) * r * 0.7
        hh = h * rng.uniform(0.55, 1.1); lean = rng.uniform(-6, 6)
        top = (x + lean, y, hh)
        prims.append(cone((x, y, -2), top, 1.6, 0.8, 'reed'))
        if rng.random() < 0.6:
            prims.append(capsule((top[0] - lean * 0.08, y, hh - 12), (top[0], y, hh - 2), 2.6, 'reed_head'))
    for i in range(n // 2 + 2):  # blade leaves
        a = rng.uniform(0, math.tau)
        ln = rng.uniform(22, 38)
        prims.append(box((math.cos(a) * 6, math.sin(a) * 4, ln * 0.45), (0.8, 2.2, ln * 0.5), 'reed',
                         rotm=rot(yaw=math.degrees(a), roll=rng.uniform(-28, 28), pitch=rng.uniform(-16, 16)), round_=0.4))
    return prims


def swamp_plant(seed, n=8, size=26.0):
    """Broad-leaved bog plant: arching lanceolate leaves rising from a dark crown."""
    rng = random.Random(seed); P = []
    for i in range(n):
        a = i / n * math.tau + rng.uniform(-0.25, 0.25)
        ln = size * rng.uniform(0.75, 1.15); up = math.radians(rng.uniform(28, 55))
        c = (math.cos(a) * ln * 0.42 * math.cos(up), math.sin(a) * ln * 0.42 * math.cos(up), 2 + ln * 0.42 * math.sin(up))
        P.append(ellipsoid(c, (ln * 0.5, ln * 0.15, 1.0), 'leaf_green', rotm=rot(yaw=math.degrees(a), pitch=-math.degrees(up)), k=0.8))
    P.append(ellipsoid((0, 0, 3), (6, 6, 4), 'leaf_dark'))
    return P


def fern(seed, fronds=6, size=30.0):
    """Swamp fern: curved fronds with alternating leaflets."""
    rng = random.Random(seed); P = []
    for f in range(fronds):
        a = f / fronds * math.tau + rng.uniform(-0.3, 0.3)
        ln = size * rng.uniform(0.8, 1.15)
        prev = (0.0, 0.0, 2.0)
        for k in range(1, 7):
            t = k / 6
            r = ln * t; h = 2 + math.sin(t * math.pi * 0.85) * ln * 0.55
            pt = (math.cos(a) * r, math.sin(a) * r, h)
            P.append(capsule(prev, pt, 0.9, 'leaf_dark'))
            if k < 6:
                for side in (-1, 1):
                    la = a + side * 1.25
                    lw = (1 - t) * 6 + 2.5
                    lc = (pt[0] + math.cos(la) * lw * 0.55, pt[1] + math.sin(la) * lw * 0.55, pt[2] - 0.5)
                    P.append(ellipsoid(lc, (lw * 0.55, 1.6, 0.6), 'leaf_green', rotm=rot(yaw=math.degrees(la), pitch=15)))
            prev = pt
    return P


def round_rock(seed, size=12.0):
    rng = random.Random(seed)
    P = [ellipsoid((0, 0, size * 0.42), (size, size * 0.85, size * 0.62), 'stone_swamp', rotm=rot(yaw=rng.uniform(0, 360)), k=3, disp=(size * 0.12, 0.09, seed, 1, 1, 1))]
    for i in range(rng.randint(1, 2)):
        a = rng.uniform(0, math.tau); s2 = size * rng.uniform(0.35, 0.55)
        P.append(ellipsoid((math.cos(a) * size, math.sin(a) * size * 0.8, s2 * 0.4), (s2, s2 * 0.9, s2 * 0.6), 'stone_swamp', k=2, disp=(s2 * 0.12, 0.12, seed + i, 1, 1, 1)))
    return P


def ground_roots(seed):
    rng = random.Random(seed); prims = []
    for i in range(rng.randint(3, 5)):
        a = rng.uniform(0, math.tau); ln = rng.uniform(40, 70)
        p0 = (math.cos(a) * 6, math.sin(a) * 6, 0)
        p1 = (math.cos(a) * ln * 0.5, math.sin(a) * ln * 0.5, rng.uniform(8, 16))
        p2 = (math.cos(a + 0.3) * ln, math.sin(a + 0.3) * ln, -3)
        prims.append(cone(p0, p1, 7, 5, 'bark_wet', k=2, disp=(1.0, 0.14, seed + i, 1, 1, 1)))
        prims.append(cone(p1, p2, 5, 2, 'bark_wet', k=2, disp=(0.8, 0.14, seed + i + 9, 1, 1, 1)))
    prims.append(ellipsoid((0, 0, 4), (12, 10, 8), 'bark_wet', k=3))
    return prims


def stump(seed):
    rng = random.Random(seed)
    prims = [cone((0, 0, -4), (rng.uniform(-3, 3), 0, 34), 16, 12, 'bark_wet', k=3, disp=(1.6, 0.1, seed, 1, 1, 0.25))]
    prims.append(box((0, 0, 44), (20, 20, 10), 'bark_wet', rotm=rot(roll=rng.uniform(-18, 18), pitch=rng.uniform(-18, 18)), neg=True))
    for j in range(5):
        a = j / 5 * math.tau + rng.uniform(-0.3, 0.3); ln = rng.uniform(24, 36)
        prims.append(cone((0, 0, 12), (math.cos(a) * ln, math.sin(a) * ln, -3), 8, 2, 'bark_wet', k=5, disp=(1.0, 0.12, seed + j, 1, 1, 1)))
    prims += mushroom((10, -10, 16), 7, 6, 'fungus_cap', seed=seed + 3)
    return prims


def fallen_log(seed, length=120.0):
    rng = random.Random(seed)
    prims = [cone((-length / 2, 0, 12), (length / 2, rng.uniform(-6, 6), 10), 13, 10, 'bark_wet', k=3, disp=(1.4, 0.1, seed, 0.2, 1, 1))]
    prims.append(sphere((-length / 2 - 2, 0, 12), 13.5, 'wood_wet'))
    for j in range(3):
        x = rng.uniform(-length * 0.35, length * 0.35)
        prims.append(cone((x, 0, 18), (x + rng.uniform(-10, 10), rng.uniform(-12, 12), 34), 4, 1.5, 'bark_twig_wet'))
    for j in range(4):
        a = rng.uniform(0, math.tau)
        prims.append(cone((length / 2, 0, 10), (length / 2 + 14 + math.cos(a) * 10, math.sin(a) * 18, -2), 5, 1.5, 'bark_wet', k=3))
    prims += mushroom((rng.uniform(-20, 20), -9, 20), 6, 5, 'fungus_cap', seed=seed + 4)
    return prims


def sunken_wall(seed, width=110.0, rows=3):
    rng = random.Random(seed); prims = []
    bw = 22.0; bh = 9.0
    for r in range(rows):
        n = int(width / (bw * 2)) + 1
        for c in range(n):
            if rng.random() < 0.18 + r * 0.22:
                continue
            x = -width / 2 + c * bw * 2 + (bw if r % 2 else 0) * 0.5
            prims.append(masonry_block((x, rng.uniform(-1, 1), bh + r * bh * 2), (bw * 0.96, 10, bh * 0.95), 'stone_swamp', yaw=rng.uniform(-3, 3), chip=1.4, seed=seed + r * 10 + c))
    for i in range(3):
        a = rng.uniform(-0.5, 0.5)
        prims.append(masonry_block((rng.uniform(-width / 2, width / 2), rng.uniform(-30, -16), 5), (bw * 0.6, 9, 5), 'stone_swamp', yaw=rng.uniform(0, 90), chip=1.2, seed=seed + 40 + i))
    return prims


def statue(seed, toppled=False):
    rng = random.Random(seed); prims = []
    body = [box((0, 0, 7), (20, 18, 7), 'stone_swamp', round_=1.5),
            cone((0, 0, 14), (0, 0, 70), 15, 8, 'stone_swamp', k=3, disp=(1.2, 0.12, seed, 1, 1, 0.3)),
            ellipsoid((0, 0, 82), (9, 8.5, 11), 'stone_swamp', k=3),
            ellipsoid((0, -1.5, 85), (11, 10, 12), 'stone_swamp', k=1),  # hood
            capsule((-9, -6, 58), (0, -9, 48), 4.2, 'stone_swamp', k=2),
            capsule((9, -6, 58), (0, -9, 48), 4.2, 'stone_swamp', k=2)]
    if toppled:
        m = rot(pitch=88, yaw=rng.uniform(-30, 30))
        out = [box((0, 0, 7), (20, 18, 7), 'stone_swamp', round_=1.5)]
        for p in body[1:]:
            pa = m @ (np.array(p.a) - np.array((0, 0, 14))) + np.array((30, 0, 12))
            pb = m @ (np.array(p.b) - np.array((0, 0, 14))) + np.array((30, 0, 12))
            if p.kind in ('cone', 'capsule'):
                out.append(type(p)(p.kind, p.mat, tuple(pa), tuple(pb), p.r, p.r2, p.size, None, p.k, p.neg, p.disp))
            else:
                out.append(type(p)(p.kind, p.mat, tuple(pa), tuple(pb), p.r, p.r2, p.size, m, p.k, p.neg, p.disp))
        return out
    body.append(box((rng.uniform(-6, 6), 0, 100), (16, 16, 10), 'stone_swamp', rotm=rot(roll=30, pitch=20), neg=True))
    return body


def gravestone(seed, kind=0):
    rng = random.Random(seed); tilt = rng.uniform(-12, 12)
    if kind == 2:  # cross
        return [box((0, 0, 4), (9, 7, 4), 'stone_swamp', round_=1),
                box((0, 0, 26), (3.2, 3, 20), 'stone_swamp', rotm=rot(pitch=tilt), round_=0.8),
                box((0, 0, 36), (11, 3, 3), 'stone_swamp', rotm=rot(pitch=tilt), round_=0.8)]
    h = 22 if kind == 0 else 30
    prims = [box((0, 0, 4), (13, 8, 4), 'stone_swamp', round_=1),
             box((0, 0, h * 0.5 + 6), (10, 3.5, h * 0.5), 'stone_swamp', rotm=rot(pitch=tilt, roll=rng.uniform(-6, 6)), round_=1.2, disp=(0.6, 0.15, seed, 1, 1, 1))]
    prims.append(cylinder((0, 0, h + 6), 10, 3.5, 'stone_swamp', rotm=rot(roll=90, pitch=tilt), round_=0.5))
    return prims


def glow_mushrooms(seed, cyan=False):
    rng = random.Random(seed); prims = []
    cap = 'fungus_cyan' if cyan else 'fungus_cap'
    for i in range(rng.randint(4, 6)):
        a = rng.uniform(0, math.tau); r = rng.uniform(0, 18)
        h = rng.uniform(9, 26); cr = h * rng.uniform(0.55, 0.8)
        prims += mushroom((math.cos(a) * r, math.sin(a) * r * 0.7, 0), h, cr, cap, tilt=rng.uniform(-22, 22), seed=seed + i)
    return prims


def lantern_post(seed):
    return [box((0, 0, 30), (3, 3, 30), 'wood_wet', round_=0.6), box((8, 0, 60), (10, 2, 2), 'wood_wet', round_=0.5),
            capsule((15, 0, 58), (15, 0, 52), 0.8, 'iron'), box((15, 0, 45), (5, 5, 6), 'iron', round_=1.0),
            sphere((15, -4.6, 45), 3.6, 'lantern_glow'), box((0, 0, 1), (7, 7, 2), 'stone_swamp', round_=1)]


def shrine(seed):
    rng = random.Random(seed); prims = []
    prims.append(box((0, 0, 5), (62, 46, 5), 'stone_swamp', round_=2, disp=(0.8, 0.1, seed, 1, 1, 1)))
    prims.append(box((0, 0, 13), (50, 36, 3), 'stone_swamp', round_=1.5))
    for sx in (-40, 40):
        for sy in (-26, 26):
            prims += column((sx, sy, 14), 6.5, 62, 'stone_swamp', broken=14 if (sx > 0 and sy > 0) else 0, seed=seed + sx + sy)
    prims.append(box((0, 0, 94), (54, 40, 5), 'stone_swamp', rotm=rot(roll=4), round_=1.5, disp=(1.0, 0.1, seed + 1, 1, 1, 1)))
    prims.append(box((36, 20, 98), (24, 26, 12), 'stone_swamp', rotm=rot(roll=25, pitch=20), neg=True))
    prims.append(box((0, 0, 22), (12, 9, 8), 'stone_swamp', round_=1.2))
    prims.append(sphere((0, 0, 37), 7.5, 'glow_toxic'))
    prims.append(torus((0, 0, 31), 9, 1.6, 'iron'))
    return prims


def bridge(seed, length=240.0):
    rng = random.Random(seed); prims = []
    n = int(length / 13)
    for i in range(n):
        x = -length / 2 + i * 13 + 6
        if 0.42 < i / n < 0.56 and rng.random() < 0.7:
            continue  # collapsed gap
        sag = -4 * math.sin(i / n * math.pi) + (rng.uniform(-3, 0) if 0.35 < i / n < 0.65 else 0)
        prims.append(box((x, rng.uniform(-1.5, 1.5), 12 + sag), (5.5, 22 + rng.uniform(-3, 2), 2.2), 'wood_wet', rotm=rot(yaw=rng.uniform(-4, 4), roll=rng.uniform(-6, 6)), round_=0.6))
    for i in range(0, n + 1, 4):
        x = -length / 2 + i * 13
        for sy in (-24, 24):
            h = rng.uniform(16, 30)
            prims.append(cylinder((x, sy, h / 2 - 4), 3.2, h / 2 + 4, 'wood_wet', round_=0.6))
    prims.append(box((-length * 0.3, -24, 26), (length * 0.18, 1.6, 1.6), 'wood_wet', rotm=rot(pitch=4), round_=0.5))
    prims.append(box((length * 0.32, 24, 24), (length * 0.15, 1.6, 1.6), 'wood_wet', rotm=rot(pitch=-6), round_=0.5))
    return prims


def boardwalk(seed, vertical=False, length=104.0):
    rng = random.Random(seed); prims = []
    n = int(length / 13)
    for i in range(n):
        x = -length / 2 + i * 13 + 6
        if rng.random() < 0.12:
            continue
        c = (x, rng.uniform(-1, 1), 5) if not vertical else (rng.uniform(-1, 1), x, 5)
        half = (5.5, 18, 2) if not vertical else (18, 5.5, 2)
        prims.append(box(c, half, 'wood_wet', rotm=rot(yaw=rng.uniform(-5, 5), roll=rng.uniform(-4, 4)), round_=0.5))
    for i in (0, n // 2, n - 1):
        x = -length / 2 + i * 13 + 6
        for s in (-20, 20):
            c = (x, s, 2) if not vertical else (s, x, 2)
            prims.append(cylinder(c, 2.6, 8, 'wood_wet', round_=0.5))
    return prims


# Catalogue: name -> (builder, block, sway, glow, depth, fade)
# block: ('c', radius) | ('r', half_w, half_h) | None ; glow: (r, g, b, radius, strength) | None
# depth: 'sort' (y-sorted), 'ground' (always under actors)
def catalogue():
    C = {}
    for i, (h, r) in enumerate(((150, 17), (178, 19), (205, 22))):
        C[f'tree_{i}'] = (lambda i=i, h=h, r=r: dead_tree(900 + i * 7, height=h, trunk_r=r, mat='bark_wet', twig='bark_twig_wet', hang_count=10),
                          ('c', r * 0.85), 0, None, 'sort', (60, h * 0.82))
    C['tree_giant'] = (lambda: dead_tree(977, height=250, trunk_r=30, mat='bark_dark', twig='bark_twig_wet', hang_count=16, depth=5),
                       ('c', 28), 0, None, 'sort', (90, 220))
    for i in range(2):
        C[f'stump_{i}'] = (lambda i=i: stump(300 + i), ('c', 13), 0, None, 'sort', None)
        C[f'log_{i}'] = (lambda i=i: fallen_log(320 + i, length=110 + i * 26), ('r', 58 + i * 12, 11), 0, None, 'sort', None)
        C[f'rock_big_{i}'] = (lambda i=i: rock(340 + i, size=28 + i * 6, mat='stone_swamp'), ('c', 24 + i * 5), 0, None, 'sort', None)
        C[f'roots_{i}'] = (lambda i=i: ground_roots(360 + i), None, 0, None, 'sort', None)
        C[f'plant_{i}'] = ((lambda i=i: swamp_plant(370 + i, size=24 + i * 6)) if i == 0 else (lambda i=i: fern(370 + i, size=30)), None, 1, None, 'sort', None)
        C[f'wall_{i}'] = (lambda i=i: sunken_wall(380 + i, width=100 + i * 30, rows=2 + i), ('r', 50 + i * 15, 12), 0, None, 'sort', (60 + i * 15, 70))
        C[f'statue_{i}'] = (lambda i=i: statue(390 + i, toppled=i == 1), ('c', 18) if i == 0 else ('r', 36, 16), 0, None, 'sort', (30, 110) if i == 0 else None)
    for i in range(3):
        C[f'rock_small_{i}'] = (lambda i=i: round_rock(400 + i, size=9 + i * 3), None, 0, None, 'sort', None)
        C[f'reeds_{i}'] = (lambda i=i: reeds(410 + i, n=7 + i * 3, h=40 + i * 8), None, 1, None, 'sort', None)
        C[f'grave_{i}'] = (lambda i=i: gravestone(420 + i, kind=i), None, 0, None, 'sort', None)
    C['mush_glow_0'] = (lambda: glow_mushrooms(430), None, 0, (120, 220, 70, 120, 0.55), 'sort', None)
    C['mush_glow_1'] = (lambda: glow_mushrooms(431, cyan=True), None, 0, (70, 210, 200, 120, 0.55), 'sort', None)
    C['mush_glow_2'] = (lambda: glow_mushrooms(432), None, 0, (120, 220, 70, 110, 0.5), 'sort', None)
    C['pillar_0'] = (lambda: column((0, 0, 0), 11, 70, 'stone_swamp', broken=16, seed=440), ('c', 14), 0, None, 'sort', (26, 90))
    C['pillar_1'] = (lambda: column((0, 0, 0), 11, 36, 'stone_swamp', broken=10, seed=441), ('c', 14), 0, None, 'sort', None)
    C['lantern'] = (lambda: lantern_post(450), ('c', 6), 0, (190, 230, 90, 150, 0.75), 'sort', None)
    C['shrine'] = (lambda: shrine(460), ('multi', [(-40, 6, 10), (40, 6, 10), (-40, -28, 10), (40, -28, 10)]), 0, (130, 235, 80, 210, 0.85), 'sort', (130, 130))
    C['bridge'] = (lambda: bridge(470), None, 0, None, 'ground', None)
    C['walk_h'] = (lambda: boardwalk(480, False), None, 0, None, 'ground', None)
    C['walk_v'] = (lambda: boardwalk(481, True), None, 0, None, 'ground', None)
    return C


# --------------------------------------------------------------------------- layout
class SwampLayout:
    hazard_kinds = ['toxic', 'mud', 'spores']

    def __init__(self, seed=SEED):
        self.seed = seed
        rng = random.Random(seed)
        self.rng = rng
        sx, sy = START
        # Landmark sites, kept away from the start clearing and from each other.
        kinds = ['giant_tree', 'shrine', 'graveyard', 'ruin', 'bridge', 'giant_tree', 'ruin', 'shrine']
        rng.shuffle(kinds)
        sites = []
        base_angle = rng.uniform(0, math.tau)
        for i, kind in enumerate(kinds):
            for _ in range(400):
                a = base_angle + i / len(kinds) * math.tau + rng.uniform(-0.25, 0.25)
                d = rng.uniform(780, 1650)
                x = sx + math.cos(a) * d; y = sy + math.sin(a) * d
                if not (380 < x < WORLD - 380 and 380 < y < WORLD - 380):
                    continue
                if any(math.hypot(x - q['x'], y - q['y']) < 700 for q in sites):
                    continue
                sites.append({'kind': kind, 'x': x, 'y': y})
                break
        self.sites = sites
        names = {'giant_tree': 'Uralter Totbaum', 'shrine': 'Verfallener Schrein', 'graveyard': 'Ueberwucherter Friedhof',
                 'ruin': 'Halb versunkene Ruine', 'bridge': 'Eingestuerzte Holzbruecke'}
        for s in sites:
            s['name'] = names[s['kind']]
        # Paths from the start to every site, plus a loop between neighbours.
        self.paths = []
        order = sorted(sites, key=lambda s: math.atan2(s['y'] - sy, s['x'] - sx))
        for s in order:
            self.paths.append(wiggly_path((sx, sy), (s['x'], s['y']), rng, amp=140))
        for a, b in zip(order, order[1:] + order[:1]):
            if math.hypot(a['x'] - b['x'], a['y'] - b['y']) < 1900:
                self.paths.append(wiggly_path((a['x'], a['y']), (b['x'], b['y']), rng, amp=170))
        self.path_segs = segments(self.paths)
        # Water: random ponds plus site-specific ponds and the bridge channel.
        ponds = []
        for i in range(16):
            for _ in range(200):
                x = rng.uniform(200, WORLD - 200); y = rng.uniform(200, WORLD - 200)
                if math.hypot(x - sx, y - sy) < 560:
                    continue
                if point_seg_distance(x, y, self.path_segs) < 170:
                    continue
                ponds.append((x, y, rng.uniform(90, 190), rng.uniform(1.1, 1.8)))
                break
        self.channel = []
        for s in sites:
            if s['kind'] == 'ruin':
                ponds.append((s['x'] + 30, s['y'] + 10, 190, 1.7))
            if s['kind'] == 'bridge':
                ang = rng.uniform(0, math.pi)
                d = 900
                a = (s['x'] - math.cos(ang) * d, s['y'] - math.sin(ang) * d)
                b = (s['x'] + math.cos(ang) * d, s['y'] + math.sin(ang) * d)
                self.channel.append(wiggly_path(a, (s['x'], s['y']), rng, amp=90, steps=3)[:-1] + wiggly_path((s['x'], s['y']), b, rng, amp=90, steps=3))
                s['angle'] = math.degrees(ang)
        self.ponds = ponds
        self.channel_segs = segments(self.channel)
        # Hazards (few, readable, far from the start and off paths).
        self.hazards = []
        self._place_hazards(rng)
        self.coarse = None

    def _place_hazards(self, rng):
        sx, sy = START
        placed = []

        def free(x, y, r):
            if math.hypot(x - sx, y - sy) < 520:
                return False
            if point_seg_distance(x, y, self.path_segs) < r + 70:
                return False
            if any(math.hypot(x - s['x'], y - s['y']) < 300 for s in self.sites):
                return False
            return all(math.hypot(x - p[0], y - p[1]) > 340 for p in placed)

        for kind, count, rr in (('toxic', 11, (52, 78)), ('mud', 10, (80, 120)), ('spores', 8, (58, 74))):
            n = 0; attempts = 0
            while n < count and attempts < 4000:
                attempts += 1
                x = rng.uniform(260, WORLD - 260); y = rng.uniform(260, WORLD - 260); r = rng.uniform(*rr)
                if not free(x, y, r):
                    continue
                placed.append((x, y))
                self.hazards.append({'kind': kind, 'x': x, 'y': y, 'r': r, 'phase': rng.uniform(0, 4)})
                n += 1

    # ---------------------------------------------------------------- fields
    def fields(self, X, Y):
        s = self.seed
        broad = fbm2(X / 640.0, Y / 640.0, 4, s + 1)
        detail = fbm2(X / 150.0, Y / 150.0, 3, s + 2)
        wv = (broad - 0.62) * 3.2 + (detail - 0.5) * 0.8 + blobs_field(X, Y, self.ponds)
        pd = seg_distance(X, Y, self.path_segs)
        wobble = (fbm2(X / 45.0, Y / 45.0, 2, s + 3) - 0.5) * 22
        cd = seg_distance(X, Y, self.channel_segs) if len(self.channel_segs) else np.full(X.shape, 1e9)
        wv = wv + np.clip(1 - (cd + wobble) / 70.0, 0, 1) * 2.4
        dry = np.clip(1 - (pd + wobble) / 95.0, 0, 1) * 2.2
        bridge_zone = cd < 90
        wv = np.where(bridge_zone, wv, wv - dry)
        start_d = np.hypot(X - START[0], Y - START[1])
        wv = wv - np.clip(1 - start_d / 420.0, 0, 1) * 3.5
        for site in self.sites:
            if site['kind'] in ('shrine', 'graveyard', 'giant_tree'):
                wv = wv - np.clip(1 - np.hypot(X - site['x'], Y - site['y']) / 260.0, 0, 1) * 3.0
        return {'water': wv, 'path': pd + wobble * 0.6, 'channel': cd}

    def water_at(self, x, y):
        X = np.array([x], dtype=np.float64); Y = np.array([y], dtype=np.float64)
        return float(self.fields(X, Y)['water'][0])

    def build_coarse(self, step=8):
        n = WORLD // step
        Y, X = np.mgrid[0:n, 0:n].astype(np.float64) * step + step / 2
        f = self.fields(X, Y)
        self.coarse_step = step
        self.coarse = f['water']
        self.coarse_path = f['path']
        return self.coarse

    def water_c(self, x, y):
        i = int(min(max(y // self.coarse_step, 0), self.coarse.shape[0] - 1)); j = int(min(max(x // self.coarse_step, 0), self.coarse.shape[1] - 1))
        return float(self.coarse[i, j])

    def path_c(self, x, y):
        i = int(min(max(y // self.coarse_step, 0), self.coarse.shape[0] - 1)); j = int(min(max(x // self.coarse_step, 0), self.coarse.shape[1] - 1))
        return float(self.coarse_path[i, j])

    def hazard_near(self, x, y, pad=0.0):
        for h in self.hazards:
            if math.hypot(x - h['x'], y - h['y']) < h['r'] + pad:
                return True
        return False

    # ---------------------------------------------------------------- props
    def scatter(self):
        if self.coarse is None:
            self.build_coarse()
        rng = random.Random(self.seed + 99)
        props = []
        blockers = []
        sx, sy = START

        def add(name, x, y, flip=None):
            if flip is None:
                flip = 1 if rng.random() < 0.5 else -1
            props.append((name, round(x), round(y), flip))

        # --- landmark compositions
        for s in self.sites:
            x, y = s['x'], s['y']
            if s['kind'] == 'giant_tree':
                add('tree_giant', x, y)
                for i in range(6):
                    a = i / 6 * math.tau + rng.uniform(-0.3, 0.3); r = rng.uniform(70, 140)
                    add('mush_glow_' + str(i % 3), x + math.cos(a) * r, y + math.sin(a) * r * 0.8)
                for i in range(3):
                    a = rng.uniform(0, math.tau); add('roots_' + str(i % 2), x + math.cos(a) * 90, y + math.sin(a) * 70)
            elif s['kind'] == 'shrine':
                add('shrine', x, y, 1)
                for sx_ in (-110, 110):
                    add('lantern', x + sx_, y + 90, 1 if sx_ < 0 else -1)
                for i in range(5):
                    a = rng.uniform(0, math.tau); r = rng.uniform(140, 200)
                    add('mush_glow_' + str(i % 2), x + math.cos(a) * r, y + math.sin(a) * r)
                add('pillar_1', x - 170, y - 40); add('statue_0', x + 175, y - 30)
            elif s['kind'] == 'graveyard':
                for gy in range(-2, 3):
                    for gx in range(-3, 4):
                        if rng.random() < 0.22:
                            continue
                        add('grave_' + str(rng.randint(0, 2)), x + gx * 58 + rng.uniform(-10, 10), y + gy * 64 + rng.uniform(-8, 8))
                add('tree_1', x - 240, y - 120); add('tree_2', x + 250, y + 40); add('lantern', x, y - 190, 1)
                add('statue_1', x + 30, y + 200)
            elif s['kind'] == 'ruin':
                add('wall_1', x - 40, y - 30); add('wall_0', x + 120, y + 70); add('pillar_0', x - 130, y + 60)
                add('statue_0', x + 20, y + 130); add('pillar_1', x + 160, y - 90); add('statue_1', x - 150, y - 120)
            elif s['kind'] == 'bridge':
                add('bridge', x, y, 1)
                s['bridge'] = True
        # Boardwalks where paths cross water (outside the bridge channel).
        for pl in self.paths:
            for p, q in zip(pl, pl[1:]):
                ln = math.hypot(q[0] - p[0], q[1] - p[1])
                steps = max(1, int(ln / 100))
                for k in range(steps):
                    t = (k + 0.5) / steps
                    x = p[0] + (q[0] - p[0]) * t; y = p[1] + (q[1] - p[1]) * t
                    if self.water_c(x, y) > 0.05 and min(math.hypot(x - s['x'], y - s['y']) for s in self.sites) > 160:
                        vertical = abs(q[1] - p[1]) > abs(q[0] - p[0])
                        add('walk_v' if vertical else 'walk_h', x, y, 1)
        site_pts = [(s['x'], s['y']) for s in self.sites]

        def clear_of_sites(x, y, r=230):
            return all(math.hypot(x - a, y - b) > r for a, b in site_pts)

        def land(x, y, margin=-0.15):
            return self.water_c(x, y) < margin

        def open_ok(x, y, path_clear=70, start_clear=300):
            return (math.hypot(x - sx, y - sy) > start_clear and self.path_c(x, y) > path_clear
                    and not self.hazard_near(x, y, 40) and clear_of_sites(x, y))

        grove = lambda x, y: float(fbm2(np.array([x / 520.0]), np.array([y / 520.0]), 3, self.seed + 50)[0])
        blocking = []
        # --- trees (blocking): groves, spacing keeps the swamp traversable
        trees = poisson_points(rng, 175, lambda x, y: open_ok(x, y) and (land(x, y) or rng.random() < 0.12) and grove(x, y) > 0.43, 150)
        for x, y in trees:
            add('tree_' + str(rng.randint(0, 2)), x, y); blocking.append((x, y))
        logs = poisson_points(rng, 34, lambda x, y: open_ok(x, y, 90) and land(x, y), 150, existing=blocking)
        for x, y in logs:
            add('log_' + str(rng.randint(0, 1)), x, y); blocking.append((x, y))
        stumps = poisson_points(rng, 42, lambda x, y: open_ok(x, y) and land(x, y), 140, existing=blocking)
        for x, y in stumps:
            add('stump_' + str(rng.randint(0, 1)), x, y); blocking.append((x, y))
        rocks = poisson_points(rng, 44, lambda x, y: open_ok(x, y) and land(x, y), 130, existing=blocking)
        for x, y in rocks:
            add('rock_big_' + str(rng.randint(0, 1)), x, y); blocking.append((x, y))
        walls = poisson_points(rng, 12, lambda x, y: open_ok(x, y, 120) and self.water_c(x, y) > -0.35, 220, existing=blocking)
        for x, y in walls:
            add('wall_' + str(rng.randint(0, 1)), x, y); blocking.append((x, y))
        # --- decoration (non-blocking)
        for x, y in poisson_points(rng, 170, lambda x, y: math.hypot(x - sx, y - sy) > 120 and self.path_c(x, y) > 30, 70):
            add('rock_small_' + str(rng.randint(0, 2)), x, y)
        reed_spots = poisson_points(rng, 420, lambda x, y: -0.35 < self.water_c(x, y) < 0.35 and math.hypot(x - sx, y - sy) > 200 and self.path_c(x, y) > 40, 34)
        for x, y in reed_spots:
            add('reeds_' + str(rng.randint(0, 2)), x, y)
        for x, y in poisson_points(rng, 260, lambda x, y: land(x, y) and math.hypot(x - sx, y - sy) > 150 and self.path_c(x, y) > 40, 60):
            add('plant_' + str(rng.randint(0, 1)), x, y)
        for x, y in poisson_points(rng, 90, lambda x, y: land(x, y) and math.hypot(x - sx, y - sy) > 180 and self.path_c(x, y) > 45, 120):
            add('mush_glow_' + str(rng.randint(0, 2)), x, y)
        for x, y in poisson_points(rng, 70, lambda x, y: land(x, y) and self.path_c(x, y) > 40 and math.hypot(x - sx, y - sy) > 160, 120):
            add('roots_' + str(rng.randint(0, 1)), x, y)
        for x, y in poisson_points(rng, 26, lambda x, y: land(x, y) and 40 < self.path_c(x, y) < 90 and math.hypot(x - sx, y - sy) > 300, 360):
            add('lantern', x, y)
        # Near the start: a few readable details, no blockers.
        for i in range(5):
            a = i / 5 * math.tau + 0.4; r = rng.uniform(200, 260)
            add('plant_' + str(i % 2), sx + math.cos(a) * r, sy + math.sin(a) * r * 0.8)
        add('mush_glow_1', sx + 210, sy - 140); add('lantern', sx - 230, sy + 60)
        self.props = props
        return props

    def water_points(self, n=520):
        rng = random.Random(self.seed + 7)
        pts = []
        tries = 0
        while len(pts) < n and tries < n * 60:
            tries += 1
            x = rng.uniform(40, WORLD - 40); y = rng.uniform(40, WORLD - 40)
            if self.water_c(x, y) > 0.18:
                pts.append((round(x), round(y)))
        return pts




def _preview_center(self):
    for kind in ('ruin', 'bridge', 'giant_tree'):
        for s in self.sites:
            if s['kind'] == kind:
                return s['x'] + 60, s['y'] + 40
    return START


SwampLayout.preview_center = _preview_center
Layout = SwampLayout
