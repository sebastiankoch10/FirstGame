"""Level 3 – Die Aschenfrost-Ruinen: procedural props, deterministic layout and hazards (ground bake: ashfrost_ground.py)."""
from __future__ import annotations

import math
import random

import numpy as np

from pixsdf import (box, capsule, cone, cylinder, ellipsoid, fbm2, hexramp, Material, rot, sphere, torus)
from props_common import (ASH, CRYSTAL_CYAN, CRYSTAL_VIOLET, EMBER, ICE, SNOW, STONE_COLD, column, dead_tree, masonry_block,
                          mats_common, rock)
from worldgen import (START, WORLD, point_seg_distance, poisson_points, seg_distance, segments, wiggly_path)

SEED = 7319
LEVEL = 'ashfrost'


def mats():
    m = mats_common()
    m['stone_ruin'] = Material(hexramp('15181e', '1e222a', '282d37', '333944', '3f4652', '4d5562', '5e6674', '737b89'),
                               top=(SNOW, 0.66, 0.035, 0.85, 51), vary=0.12, grain=0.05, cracks=(0.07, 1, 1, 1, 0.93, 2, 52), specks=(0.5, 0.84, 1, 53))
    m['stone_ash'] = Material(hexramp('141313', '1d1b1b', '272423', '322e2c', '3e3936', '4b4541', '5a534e'),
                              top=(ASH, 0.55, 0.05, 0.9, 54), vary=0.12, grain=0.05, cracks=(0.07, 1, 1, 1, 0.92, 2, 55), specks=(0.5, 0.85, 1, 56))
    m['stone_dark'] = Material(hexramp('101216', '171a20', '20242c', '2a2f38', '353b45'), vary=0.1, grain=0.05, cracks=(0.09, 1, 1, 1, 0.92, 1, 57))
    m['rune_glow'] = Material(hexramp('1c7896', '2ea6c0', '5dd2e0', 'a6f2f4', 'e8ffff'), emit=True)
    m['flame_blue'] = Material(hexramp('2a5a9a', '4a8ad0', '8cc4f0', 'd8f0ff'), emit=True)
    m['flame_orange'] = Material(hexramp('a03a0c', 'e06a18', 'ffa840', 'ffe090'), emit=True)
    m['cloth_red'] = Material(hexramp('1e0a0b', '2e1012', '42171a', '581f22', '702a2c'), vary=0.1, grain=0.08)
    m['wood_old'] = Material(hexramp('140f0d', '1f1712', '2b2019', '392a20', '473429'), top=(SNOW, 0.7, 0.06, 0.7, 58), grain=0.06, cracks=(0.25, 1, 0.12, 1, 0.88, 1, 59))
    m['ice_spike'] = Material(ICE, spec=0.7, rim=0.35, grain=0.03)
    return m


# --------------------------------------------------------------------------- prop builders
def broken_column(seed, h=86, r=12, mat='stone_ruin', broken=18):
    P = column((0, 0, 0), r, h, mat, broken=broken, seed=seed)
    rng = random.Random(seed)
    for i in range(rng.randint(2, 4)):
        a = rng.uniform(0, math.tau)
        P.append(box((math.cos(a) * (r + 12), math.sin(a) * (r + 10), 4), (5 + rng.random() * 4, 4 + rng.random() * 3, 3.5), mat,
                     rotm=rot(yaw=rng.uniform(0, 90), roll=rng.uniform(-20, 20)), round_=1.2, disp=(0.8, 0.12, seed + i, 1, 1, 1)))
    return P


def toppled_column(seed, length=120, r=11, mat='stone_ruin'):
    rng = random.Random(seed); P = []
    x = -length / 2
    for i in range(3):
        seg = length / 3 - 4
        P.append(cylinder((x + seg / 2, rng.uniform(-3, 3), r), r, seg / 2, mat, rotm=rot(pitch=90, yaw=rng.uniform(-6, 6)), round_=1.0, disp=(0.8, 0.12, seed + i, 1, 1, 0.3)))
        x += seg + 4
    P.append(box((-length / 2 - 6, 0, 10), (8, 15, 10), mat, round_=1.5))
    return P


def arcade(seed, span=130, h=96, mat='stone_ruin'):
    rng = random.Random(seed); P = []
    for sx in (-span / 2, span / 2):
        P += column((sx, 0, 0), 10, h, mat, broken=0, seed=seed + int(sx))
    steps = 9
    for i in range(steps):
        if 0.35 < i / steps < 0.6 and rng.random() < 0.6:
            continue  # collapsed keystones
        a = math.pi * (i + 0.5) / steps
        cx = -math.cos(a) * span / 2; cz = h + 16 + math.sin(a) * span * 0.42
        P.append(box((cx, 0, cz), (span / steps * 0.62, 9, 6), mat, rotm=rot(pitch=-math.degrees(a) + 90), round_=1.0))
    return P


def ruin_wall(seed, width=150, h=88, mat='stone_ruin', window=True):
    rng = random.Random(seed); P = []
    rows = int(h / 16)
    for r in range(rows):
        n = int(width / 30) + 1
        for c in range(n):
            x = -width / 2 + c * 30 + (15 if r % 2 else 0)
            if abs(x) > width / 2:
                continue
            gone = rng.random() < 0.05 + max(0, (r - rows * 0.55)) * 0.18 + (0.25 if abs(x) > width * 0.42 else 0) * (r / rows)
            if gone:
                continue
            P.append(masonry_block((x, 0, 8 + r * 16), (14.3, 9, 7.6), mat, yaw=rng.uniform(-2, 2), chip=1.1, seed=seed + r * 31 + c))
    if window:
        P.append(box((0, 0, h * 0.58), (16, 20, h * 0.22), mat, neg=True))
        P.append(cylinder((0, 0, h * 0.58 + h * 0.22), 16, 20, mat, rotm=rot(roll=90), neg=True))
    for i in range(4):
        P.append(box((rng.uniform(-width / 2, width / 2), rng.uniform(-30, -14), 4), (rng.uniform(5, 10), rng.uniform(4, 8), 4), mat,
                     rotm=rot(yaw=rng.uniform(0, 90), roll=rng.uniform(-15, 15)), round_=1.2))
    return P


def crystals(seed, kind='crystal_cyan', glow='glow_cyan', n=6, size=34):
    rng = random.Random(seed); P = []
    for i in range(n):
        a = rng.uniform(0, math.tau); d = rng.uniform(0, size * 0.45) if i else 0
        h = size * rng.uniform(0.6, 1.25) * (1.25 if i == 0 else 1)
        tilt = rng.uniform(-28, 28); yaw = math.degrees(a)
        base = (math.cos(a) * d, math.sin(a) * d * 0.8, 0)
        m = rot(yaw=yaw, pitch=tilt)
        tip = np.array(base) + m @ np.array((0, 0, h))
        P.append(cone(base, tuple(tip), h * 0.2, 0.6, kind))
        P.append(cone(base, tuple(np.array(base) + m @ np.array((0, 0, h * 0.55))), h * 0.09, 0.3, glow))
    P.append(rock(seed, size=size * 0.42, mat='stone_dark', lumps=2)[0])
    return P


def knight_statue(seed, broken=True, mat='stone_ruin'):
    P = [box((0, 0, 8), (22, 18, 8), mat, round_=1.5),
         cone((0, 0, 16), (0, 0, 64), 15, 10, mat, k=3, disp=(1.0, 0.12, seed, 1, 1, 0.3)),
         ellipsoid((0, 0, 70), (12, 9, 7), mat, k=2),
         box((-14, -9, 44), (3, 9, 16), mat, rotm=rot(roll=8), round_=1),  # shield
         box((12, -6, 58), (1.6, 1.6, 26), mat, rotm=rot(roll=-15), round_=0.5)]  # sword
    if not broken:
        P.append(ellipsoid((0, 0, 84), (7.5, 7, 9), mat))
    else:
        P.append(box((6, 0, 72), (14, 14, 6), mat, rotm=rot(roll=25), neg=True))
        P.append(ellipsoid((30, -12, 7), (7.5, 7, 8), mat, rotm=rot(pitch=70)))
    return P


def stairs(seed, mat='stone_ruin', steps=5):
    P = []
    for i in range(steps):
        P.append(box((0, -i * 9, 4 + i * 8), (48 - i * 2, 9 + (steps - i) * 0.0, 4 + i * 0.5), mat, round_=1.0, disp=(0.6, 0.1, seed + i, 1, 1, 1)))
    P.append(box((-40, -14, 16), (6, 26, 16), mat, round_=1.2))
    P.append(box((40, -14, 12), (6, 26, 12), mat, round_=1.2, disp=(1.2, 0.1, seed + 9, 1, 1, 1)))
    return P


def magic_brazier(seed, flame='flame_blue'):
    return [cylinder((0, 0, 6), 13, 6, 'stone_dark', round_=1.5), cone((0, 0, 12), (0, 0, 34), 7, 5, 'stone_ruin', k=2),
            cylinder((0, 0, 38), 15, 5, 'stone_ruin', round_=2), cylinder((0, 0, 41), 11, 3, 'stone_dark', neg=True),
            cone((0, 0, 40), (0, 0, 60), 9, 1.5, flame), cone((-4, 2, 40), (-5, 2, 52), 5, 1, flame), cone((4, -2, 40), (6, -2, 54), 5, 1, flame)]


def ice_spikes(seed, n=7, size=26):
    rng = random.Random(seed); P = []
    for i in range(n):
        a = rng.uniform(0, math.tau); d = rng.uniform(0, size * 0.5)
        h = size * rng.uniform(0.5, 1.1)
        base = (math.cos(a) * d, math.sin(a) * d * 0.7, -2)
        m = rot(yaw=math.degrees(a), pitch=rng.uniform(-30, 30))
        P.append(cone(base, tuple(np.array(base) + m @ np.array((0, 0, h))), h * 0.22, 0.5, 'ice_spike'))
    return P


def rubble(seed, n=7, size=20, mat='stone_ruin'):
    rng = random.Random(seed); P = []
    for i in range(n):
        a = rng.uniform(0, math.tau); d = rng.uniform(0, size)
        s = rng.uniform(3, 8)
        P.append(box((math.cos(a) * d, math.sin(a) * d * 0.8, s * 0.5), (s, s * 0.8, s * 0.6), mat, rotm=rot(yaw=rng.uniform(0, 90), roll=rng.uniform(-25, 25), pitch=rng.uniform(-25, 25)), round_=1.0))
    return P


def market_stall(seed):
    rng = random.Random(seed); P = []
    for sx in (-34, 34):
        for sy in (-18, 18):
            if rng.random() < 0.2 and sx > 0:
                continue
            P.append(box((sx, sy, 24), (2.2, 2.2, 24), 'wood_old', round_=0.5))
    P.append(box((0, 0, 50), (40, 24, 1.5), 'cloth_red', rotm=rot(roll=10, pitch=-6), round_=0.5, disp=(1.6, 0.1, seed, 1, 1, 1)))
    P.append(box((0, 4, 14), (34, 14, 2), 'wood_old', round_=0.5))
    for i in range(3):
        P.append(box((rng.uniform(-40, 40), rng.uniform(-34, -22), 7), (7, 7, 7), 'wood_old', rotm=rot(yaw=rng.uniform(0, 40)), round_=0.8))
    P.append(cylinder((44, -30, 10), 8, 10, 'wood_old', round_=1.5))
    return P


def obelisk(seed):
    return [box((0, 0, 6), (16, 16, 6), 'stone_dark', round_=1.5), box((0, 0, 50), (8, 8, 40), 'stone_dark', round_=1.0),
            cone((0, 0, 90), (0, 0, 104), 8.5, 0.5, 'stone_dark'), box((0, -8.3, 48), (1.6, 0.6, 26), 'rune_glow'),
            box((0, -8.3, 62), (5, 0.6, 1.4), 'rune_glow'), box((0, -8.3, 36), (4, 0.6, 1.2), 'rune_glow')]


def ritual_circle(seed):
    rng = random.Random(seed)
    P = [cylinder((0, 0, 1), 92, 1.2, 'stone_dark', round_=0.5), torus((0, 0, 2.2), 78, 1.6, 'rune_glow'), torus((0, 0, 2.2), 54, 1.2, 'rune_glow')]
    for i in range(8):
        a = i / 8 * math.tau
        P.append(box((math.cos(a) * 66, math.sin(a) * 66, 2.4), (5, 1.2, 0.6), 'rune_glow', rotm=rot(yaw=math.degrees(a) + 90)))
        P.append(cylinder((math.cos(a + 0.2) * 98, math.sin(a + 0.2) * 98, 8), 5, 8, 'stone_ruin', round_=1.0, disp=(0.8, 0.12, seed + i, 1, 1, 1)))
    return P


def cathedral(seed):
    P = ruin_wall(seed, width=260, h=150, window=False)
    for wx in (-70, 70):
        P.append(box((wx, 0, 86), (22, 20, 40), 'stone_ruin', neg=True))
        P.append(cylinder((wx, 0, 126), 22, 20, 'stone_ruin', rotm=rot(roll=90), neg=True))
    P.append(box((0, 0, 60), (24, 20, 60), 'stone_ruin', neg=True))
    P.append(cylinder((0, 0, 120), 24, 20, 'stone_ruin', rotm=rot(roll=90), neg=True))
    for sx in (-135, 135):
        P += column((sx, -6, 0), 14, 150, 'stone_ruin', broken=30 if sx > 0 else 0, seed=seed + sx)
    return P


def tower(seed):
    rng = random.Random(seed)
    P = [cylinder((0, 0, 50), 46, 50, 'stone_ruin', round_=2, disp=(1.5, 0.08, seed, 1, 1, 0.5)),
         cylinder((0, 0, 60), 36, 62, 'stone_ruin', neg=True)]
    for i in range(7):
        a = i / 7 * math.tau
        P.append(box((math.cos(a) * 50, math.sin(a) * 50, 104), (16, 16, 14 + rng.uniform(0, 26)), 'stone_ruin', rotm=rot(yaw=math.degrees(a), roll=rng.uniform(-20, 20)), neg=True))
    P.append(box((0, -44, 26), (11, 12, 20), 'stone_ruin', neg=True))
    P += rubble(seed + 3, n=9, size=70)
    return P


def frost_tree(seed, h=150):
    return dead_tree(seed, height=h, trunk_r=17, mat='bark_frost', twig='bark_twig_frost', hang='ice_spike', hang_count=0)


def catalogue():
    C = {}
    for i in range(2):
        C[f'column_{i}'] = (lambda i=i: broken_column(600 + i, h=80 + i * 26, broken=14 + i * 6), ('c', 14), 0, None, 'sort', (26, 100))
        C[f'stump_{i}'] = (lambda i=i: broken_column(610 + i, h=26 + i * 10, broken=8, mat='stone_ash' if i else 'stone_ruin'), ('c', 14), 0, None, 'sort', None)
        C[f'wall_{i}'] = (lambda i=i: ruin_wall(620 + i, width=130 + i * 40, h=72 + i * 22, mat='stone_ruin' if i == 0 else 'stone_ash', window=i == 1), ('r', 66 + i * 20, 10), 0, None, 'sort', (70 + i * 20, 90 + i * 16))
        C[f'statue_{i}'] = (lambda i=i: knight_statue(630 + i, broken=i == 1, mat='stone_ruin' if i == 0 else 'stone_ash'), ('c', 20), 0, None, 'sort', (30, 90))
        C[f'rubble_{i}'] = (lambda i=i: rubble(640 + i, n=6 + i * 3, size=16 + i * 8, mat='stone_ruin' if i == 0 else 'stone_ash'), None, 0, None, 'sort', None)
        C[f'frosttree_{i}'] = (lambda i=i: frost_tree(650 + i, h=140 + i * 30), ('c', 15), 0, None, 'sort', (60, 130))
        C[f'ice_{i}'] = (lambda i=i: ice_spikes(660 + i, n=5 + i * 3, size=20 + i * 10), None, 0, (150, 210, 255, 80, 0.3), 'sort', None)
    C['column_down'] = (lambda: toppled_column(670), ('r', 64, 12), 0, None, 'sort', None)
    C['arcade'] = (lambda: arcade(671), ('multi', [(-65, 0, 12), (65, 0, 12)]), 0, None, 'sort', (80, 150))
    C['crystal_cyan'] = (lambda: crystals(680, 'crystal_cyan', 'glow_cyan'), ('c', 18), 0, (90, 210, 240, 150, 0.7), 'sort', None)
    C['crystal_violet'] = (lambda: crystals(681, 'crystal_violet', 'glow_violet'), ('c', 18), 0, (170, 120, 255, 150, 0.7), 'sort', None)
    C['crystal_ember'] = (lambda: crystals(682, 'crystal_ember', 'glow_ember', n=5, size=28), ('c', 16), 0, (255, 140, 60, 140, 0.7), 'sort', None)
    C['crystal_small'] = (lambda: crystals(683, 'crystal_cyan', 'glow_cyan', n=3, size=16), None, 0, (90, 210, 240, 90, 0.45), 'sort', None)
    C['stairs'] = (lambda: stairs(690), ('r', 46, 16), 0, None, 'sort', None)
    C['brazier_blue'] = (lambda: magic_brazier(691, 'flame_blue'), ('c', 12), 0, (110, 170, 255, 190, 0.8), 'sort', None)
    C['brazier_orange'] = (lambda: magic_brazier(692, 'flame_orange'), ('c', 12), 0, (255, 150, 60, 190, 0.85), 'sort', None)
    C['stall'] = (lambda: market_stall(693), ('r', 40, 16), 0, None, 'sort', (46, 70))
    C['obelisk'] = (lambda: obelisk(694), ('c', 14), 0, (90, 210, 240, 120, 0.55), 'sort', (24, 100))
    C['ritual'] = (lambda: ritual_circle(695), None, 0, (90, 210, 240, 230, 0.6), 'ground', None)
    C['cathedral'] = (lambda: cathedral(696), ('r', 150, 12), 0, None, 'sort', (150, 170))
    C['tower'] = (lambda: tower(697), ('c', 50), 0, None, 'sort', (60, 110))
    return C


# --------------------------------------------------------------------------- layout
class AshfrostLayout:
    hazard_kinds = ['ember', 'ice', 'fissure']

    def __init__(self, seed=SEED):
        self.seed = seed
        rng = random.Random(seed)
        sx, sy = START
        kinds = ['cathedral', 'tower', 'crystals', 'statues', 'market', 'ritual', 'tower', 'crystals']
        rng.shuffle(kinds)
        sites = []
        base = rng.uniform(0, math.tau)
        names = {'cathedral': 'Verfallene Kathedrale', 'tower': 'Eingestuerzter Turm', 'crystals': 'Kristallhain', 'statues': 'Platz der Statuen',
                 'market': 'Verlassener Marktplatz', 'ritual': 'Alter Ritualkreis'}
        for i, kind in enumerate(kinds):
            for _ in range(400):
                a = base + i / len(kinds) * math.tau + rng.uniform(-0.25, 0.25)
                d = rng.uniform(760, 1650)
                x = sx + math.cos(a) * d; y = sy + math.sin(a) * d
                if not (380 < x < WORLD - 380 and 380 < y < WORLD - 380):
                    continue
                if any(math.hypot(x - q['x'], y - q['y']) < 700 for q in sites):
                    continue
                sites.append({'kind': kind, 'x': x, 'y': y, 'name': names[kind]})
                break
        self.sites = sites
        self.paths = []
        order = sorted(sites, key=lambda s: math.atan2(s['y'] - sy, s['x'] - sx))
        for s in order:
            self.paths.append(wiggly_path((sx, sy), (s['x'], s['y']), rng, amp=90, steps=3))
        for a, b in zip(order, order[1:] + order[:1]):
            if math.hypot(a['x'] - b['x'], a['y'] - b['y']) < 1900:
                self.paths.append(wiggly_path((a['x'], a['y']), (b['x'], b['y']), rng, amp=110, steps=3))
        self.path_segs = segments(self.paths)
        # Plazas: every site plus a few open squares; the start is a plaza too.
        self.plazas = [(sx, sy, 300)] + [(s['x'], s['y'], 260) for s in sites]
        for _ in range(7):
            x = rng.uniform(400, WORLD - 400); y = rng.uniform(400, WORLD - 400)
            if all(math.hypot(x - p[0], y - p[1]) > 600 for p in self.plazas):
                self.plazas.append((x, y, rng.uniform(170, 240)))
        self.hazards = []
        self.coarse = None
        self._place_hazards(rng)

    def frost_ember(self, X, Y):
        s = self.seed
        frost = fbm2(X / 720.0, Y / 720.0, 4, s + 1) + (fbm2(X / 160.0, Y / 160.0, 2, s + 2) - 0.5) * 0.25
        ember = fbm2(X / 640.0, Y / 640.0, 4, s + 3) + (fbm2(X / 150.0, Y / 150.0, 2, s + 4) - 0.5) * 0.25
        return frost, ember

    def build_coarse(self, step=8):
        n = WORLD // step
        Y, X = np.mgrid[0:n, 0:n].astype(np.float64) * step + step / 2
        self.coarse_step = step
        self.cf, self.ce = self.frost_ember(X, Y)
        self.cpath = seg_distance(X, Y, self.path_segs)
        return self.cf

    def _cidx(self, x, y):
        return int(min(max(y // self.coarse_step, 0), self.cf.shape[0] - 1)), int(min(max(x // self.coarse_step, 0), self.cf.shape[1] - 1))

    def frost_c(self, x, y):
        i, j = self._cidx(x, y); return float(self.cf[i, j])

    def ember_c(self, x, y):
        i, j = self._cidx(x, y); return float(self.ce[i, j])

    def path_c(self, x, y):
        i, j = self._cidx(x, y); return float(self.cpath[i, j])

    def _place_hazards(self, rng):
        self.build_coarse()
        sx, sy = START
        placed = []

        def free(x, y, r):
            if math.hypot(x - sx, y - sy) < 520 or point_seg_distance(x, y, self.path_segs) < r + 70:
                return False
            if any(math.hypot(x - s['x'], y - s['y']) < 320 for s in self.sites):
                return False
            return all(math.hypot(x - p[0], y - p[1]) > 330 for p in placed)

        def place(kind, count, rr, cond):
            n = 0; tries = 0
            while n < count and tries < 6000:
                tries += 1
                x = rng.uniform(260, WORLD - 260); y = rng.uniform(260, WORLD - 260); r = rng.uniform(*rr)
                if not cond(x, y) or not free(x, y, r):
                    continue
                h = {'kind': kind, 'x': x, 'y': y, 'r': r, 'phase': rng.uniform(0, 4)}
                if kind == 'fissure':
                    a = rng.uniform(0, math.pi); ln = rng.uniform(170, 260)
                    h.update(x=x - math.cos(a) * ln / 2, y=y - math.sin(a) * ln / 2, x2=x + math.cos(a) * ln / 2, y2=y + math.sin(a) * ln / 2, r=16)
                placed.append((x, y)); self.hazards.append(h); n += 1

        place('ember', 10, (52, 72), lambda x, y: self.ember_c(x, y) > 0.5)
        place('ice', 10, (90, 130), lambda x, y: self.frost_c(x, y) > 0.5)
        place('fissure', 8, (16, 16), lambda x, y: True)

    def scatter(self):
        rng = random.Random(self.seed + 99)
        props = []
        sx, sy = START

        def add(name, x, y, flip=None):
            props.append((name, round(x), round(y), (1 if rng.random() < 0.5 else -1) if flip is None else flip))

        def frosty(x, y):
            return self.frost_c(x, y) > self.ember_c(x, y)

        for s in self.sites:
            x, y = s['x'], s['y']
            k = s['kind']
            if k == 'cathedral':
                add('cathedral', x, y - 40, 1)
                for i in range(4):
                    add('column_' + str(i % 2), x - 160 + i * 107, y + 120)
                add('rubble_1', x + 180, y + 40); add('rubble_0', x - 190, y + 20); add('brazier_blue', x - 60, y + 70, 1); add('brazier_blue', x + 60, y + 70, -1)
            elif k == 'tower':
                add('tower', x, y, 1); add('rubble_1', x + 90, y + 60); add('rubble_0', x - 100, y + 40); add('column_down', x + 40, y + 140)
            elif k == 'crystals':
                for i in range(7):
                    a = i / 7 * math.tau + rng.uniform(-0.3, 0.3); r = rng.uniform(40, 170)
                    add(rng.choice(['crystal_cyan', 'crystal_violet', 'crystal_small', 'crystal_cyan']), x + math.cos(a) * r, y + math.sin(a) * r * 0.75)
                add('obelisk', x, y, 1)
            elif k == 'statues':
                for i in range(6):
                    a = i / 6 * math.tau; add('statue_' + str(i % 2), x + math.cos(a) * 150, y + math.sin(a) * 105)
                add('ritual', x, y, 1)
            elif k == 'market':
                for gx in (-1, 0, 1):
                    for gy in (-1, 1):
                        if rng.random() < 0.8:
                            add('stall', x + gx * 120, y + gy * 90)
                add('brazier_orange', x, y, 1)
            elif k == 'ritual':
                add('ritual', x, y, 1)
                for i in range(4):
                    a = i / 4 * math.tau + math.pi / 4
                    add('obelisk', x + math.cos(a) * 150, y + math.sin(a) * 110, 1)
                add('crystal_violet', x + 210, y - 40)
        site_pts = [(s['x'], s['y']) for s in self.sites]
        hz = [(h['x'], h['y'], h.get('r', 16) + 50) for h in self.hazards]

        def open_ok(x, y, path_clear=70, start_clear=320):
            if math.hypot(x - sx, y - sy) < start_clear or self.path_c(x, y) < path_clear:
                return False
            if any(math.hypot(x - a, y - b) < 250 for a, b in site_pts):
                return False
            return all(math.hypot(x - a, y - b) > r for a, b, r in hz)

        blocking = []
        for x, y in poisson_points(rng, 70, lambda x, y: open_ok(x, y), 170):
            add('column_' + str(rng.randint(0, 1)), x, y); blocking.append((x, y))
        for x, y in poisson_points(rng, 40, lambda x, y: open_ok(x, y, 90), 170, existing=blocking):
            add('stump_' + str(rng.randint(0, 1)), x, y); blocking.append((x, y))
        for x, y in poisson_points(rng, 26, lambda x, y: open_ok(x, y, 110), 260, existing=blocking):
            add('wall_' + str(rng.randint(0, 1)), x, y); blocking.append((x, y))
        for x, y in poisson_points(rng, 14, lambda x, y: open_ok(x, y, 110), 300, existing=blocking):
            add('arcade', x, y, 1); blocking.append((x, y))
        for x, y in poisson_points(rng, 18, lambda x, y: open_ok(x, y, 90), 240, existing=blocking):
            add('column_down', x, y); blocking.append((x, y))
        for x, y in poisson_points(rng, 16, lambda x, y: open_ok(x, y, 90), 260, existing=blocking):
            add('statue_' + str(rng.randint(0, 1)), x, y); blocking.append((x, y))
        for x, y in poisson_points(rng, 12, lambda x, y: open_ok(x, y, 100), 300, existing=blocking):
            add('stairs', x, y, 1); blocking.append((x, y))
        for x, y in poisson_points(rng, 46, lambda x, y: open_ok(x, y) and frosty(x, y), 170, existing=blocking):
            add('frosttree_' + str(rng.randint(0, 1)), x, y); blocking.append((x, y))
        for x, y in poisson_points(rng, 34, lambda x, y: open_ok(x, y), 200, existing=blocking):
            add(rng.choice(['crystal_cyan', 'crystal_violet']) if frosty(x, y) else 'crystal_ember', x, y); blocking.append((x, y))
        for x, y in poisson_points(rng, 22, lambda x, y: open_ok(x, y, 60) and self.path_c(x, y) < 110, 330, existing=blocking):
            add('brazier_blue' if frosty(x, y) else 'brazier_orange', x, y, 1); blocking.append((x, y))
        # Non-blocking detail.
        for x, y in poisson_points(rng, 340, lambda x, y: math.hypot(x - sx, y - sy) > 140 and self.path_c(x, y) > 34, 62):
            add('rubble_' + str(rng.randint(0, 1)), x, y)
        for x, y in poisson_points(rng, 210, lambda x, y: frosty(x, y) and self.path_c(x, y) > 40 and math.hypot(x - sx, y - sy) > 160, 70):
            add('ice_' + str(rng.randint(0, 1)), x, y)
        for x, y in poisson_points(rng, 130, lambda x, y: math.hypot(x - sx, y - sy) > 160 and self.path_c(x, y) > 40, 100):
            add('crystal_small', x, y)
        # Start plaza: readable, no blockers.
        for i in range(4):
            a = i / 4 * math.tau + math.pi / 4
            add('brazier_blue' if i % 2 else 'brazier_orange', sx + math.cos(a) * 250, sy + math.sin(a) * 180, 1)
        add('rubble_0', sx - 150, sy + 120); add('crystal_small', sx + 170, sy - 110)
        self.props = props
        return props

    def water_points(self, n=420):
        """Frost glitter points (the runtime reuses the swamp ripple list as twinkling ice sparkles)."""
        rng = random.Random(self.seed + 7)
        pts = []; tries = 0
        while len(pts) < n and tries < n * 80:
            tries += 1
            x = rng.uniform(40, WORLD - 40); y = rng.uniform(40, WORLD - 40)
            if self.frost_c(x, y) > 0.56:
                pts.append((round(x), round(y)))
        return pts

    def preview_center(self):
        for kind in ('cathedral', 'crystals', 'statues'):
            for s in self.sites:
                if s['kind'] == kind:
                    return s['x'], s['y'] + 60
        return START


Layout = AshfrostLayout
