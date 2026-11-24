"""Reusable procedural prop builders (trees, rocks, mushrooms, masonry) for the level art pipeline."""
from __future__ import annotations

import math
import random

from pixsdf import (box, capsule, cone, cylinder, ellipsoid, hexramp, Material, rot, sphere, torus)

# --------------------------------------------------------------------------- palettes
BARK_DEAD = hexramp('100d0e', '1a1617', '26201f', '332b28', '433932', '574a3f', '6d5d4e')
BARK_WET = hexramp('0b0c0c', '131614', '1b201c', '252b25', '313830', '40483d', '535b4c')
MOSS = hexramp('0e150e', '152015', '1d2c1a', '263820', '304527', '3d5430', '4f663a')
MOSS_PALE = hexramp('161c15', '212a1f', '2e382a', '3c4836', '4d5a44', '617055')
STONE_SWAMP = hexramp('131617', '1f2425', '2c3233', '3b4243', '4d5555', '626a68', '7b827d')
STONE_COLD = hexramp('14171d', '1f242c', '2c333d', '3b4450', '4e5866', '66717f', '828c99', 'a2abb5')
STONE_WARM = hexramp('17130f', '241e19', '342b24', '463b31', '5a4c3f', '726150', '8d7a66')
SNOW = hexramp('5b6b80', '7a8ba0', '9aaabd', 'b9c7d6', 'd5e0ea', 'eef4f8')
ASH = hexramp('1a1817', '2a2725', '3b3735', '4e4a47', '64605b', '7c7771')
EMBER = hexramp('5a1408', '8a2508', 'c2440c', 'ee7418', 'ffaa3a', 'ffdc84')
ICE = hexramp('16304a', '1f4766', '2d6589', '4588ab', '67adc9', '95d2e4', 'c9eef6')
CRYSTAL_CYAN = hexramp('0d2d3d', '13506a', '1c7896', '2ea6c0', '5dd2e0', 'a6f2f4', 'e8ffff')
CRYSTAL_VIOLET = hexramp('211036', '3a1a5c', '582a86', '7b43ad', 'a46ad0', 'cf9fef', 'f1dcff')
TOXIC = hexramp('22420e', '3a7014', '5c9e1f', '86c932', 'b4e85a', 'e2ff9e')
FUNGUS_CAP = hexramp('140c14', '20131f', '2e1b2c', '3e263a', '50324a', '653f5b', '7c5070')
FUNGUS_STEM = hexramp('2a2a22', '3f3f31', '57563f', '717052', '8d8b68', 'a9a682')
WOOD = hexramp('150f0b', '231912', '33251a', '453223', '58412e', '6e533b')
WOOD_WET = hexramp('0f0d0b', '1a1612', '27211b', '352c23', '453a2d', '574939')
IRON_RUST = hexramp('1a1210', '2c1c16', '45281b', '62351f', '7f4724', '9c5f30', 'b97c45')
REED = hexramp('1b2112', '2a3318', '3c4720', '525d29', '6b7533', '868d42')
REED_HEAD = hexramp('1e140c', '2f1f12', '432c19', '573a22')
BONE = hexramp('3a352a', '575041', '766d59', '958b73', 'b3a98f', 'cfc6ab')
CLOTH_DARK = hexramp('140f12', '22181c', '322227', '442e33', '573a3f')


def mats_common():
    return {
        'bark': Material(BARK_DEAD, top=(MOSS, 0.72, 0.045, 0.7, 3), vary=0.12, grain=0.05, grain_freq=0.3, cracks=(0.16, 1.0, 1.0, 0.18, 0.86, 2, 3), specks=(0.42, 0.8, 1, 4)),
        'bark_wet': Material(BARK_WET, top=(MOSS, 0.62, 0.045, 0.8, 5), vary=0.12, grain=0.05, grain_freq=0.3, cracks=(0.16, 1.0, 1.0, 0.18, 0.86, 2, 3), specks=(0.42, 0.8, 1, 4)),
        'bark_frost': Material(BARK_DEAD, top=(SNOW, 0.55, 0.05, 0.8, 9), vary=0.10, grain=0.05, grain_freq=0.3, cracks=(0.16, 1.0, 1.0, 0.18, 0.86, 2, 3), specks=(0.42, 0.8, 1, 4)),
        'hangmoss': Material(MOSS_PALE, vary=0.15, grain=0.1, grain_freq=0.6, rim=0.05),
        'bark_twig': Material(BARK_DEAD, vary=0.08, grain=0.04, grain_freq=0.3, rim=0.05),
        'bark_twig_wet': Material(BARK_WET, vary=0.08, grain=0.04, grain_freq=0.3, rim=0.05),
        'bark_twig_frost': Material(BARK_DEAD, top=(SNOW, 0.75, 0.08, 0.5, 13), vary=0.08, grain=0.04, grain_freq=0.3, rim=0.05),
        'moss': Material(MOSS, vary=0.15, grain=0.1, grain_freq=0.5),
        'stone_swamp': Material(STONE_SWAMP, top=(MOSS, 0.66, 0.045, 0.9, 21), vary=0.14, grain=0.05, grain_freq=0.3, cracks=(0.07, 1, 1, 1, 0.93, 2, 22), specks=(0.5, 0.82, 1, 23)),
        'stone_cold': Material(STONE_COLD, top=(SNOW, 0.62, 0.04, 0.7, 23), vary=0.12, grain=0.05, grain_freq=0.3, cracks=(0.07, 1, 1, 1, 0.93, 2, 24), specks=(0.5, 0.82, 1, 25)),
        'stone_cold_ash': Material(STONE_COLD, top=(ASH, 0.5, 0.05, 0.9, 29), vary=0.12, grain=0.05, grain_freq=0.3, cracks=(0.07, 1, 1, 1, 0.93, 2, 26), specks=(0.5, 0.82, 1, 27)),
        'stone_plain': Material(STONE_COLD, vary=0.12, grain=0.05, grain_freq=0.3, cracks=(0.07, 1, 1, 1, 0.93, 2, 28), specks=(0.5, 0.82, 1, 29)),
        'stone_warm': Material(STONE_WARM, top=(MOSS, 0.6, 0.05, 1.0, 27), vary=0.12, grain=0.05, grain_freq=0.3, cracks=(0.07, 1, 1, 1, 0.93, 2, 30), specks=(0.5, 0.82, 1, 31)),
        'snow': Material(SNOW, vary=0.06, grain=0.05, grain_freq=0.4, rim=0.05),
        'ice': Material(ICE, spec=0.55, vary=0.08, grain=0.06, rim=0.25),
        'crystal_cyan': Material(CRYSTAL_CYAN, spec=0.7, vary=0.05, grain=0.04, rim=0.35),
        'crystal_violet': Material(CRYSTAL_VIOLET, spec=0.7, vary=0.05, grain=0.04, rim=0.35),
        'crystal_ember': Material(EMBER, spec=0.5, vary=0.05, grain=0.04, rim=0.3),
        'glow_cyan': Material(CRYSTAL_CYAN, emit=True, grain=0.02),
        'glow_violet': Material(CRYSTAL_VIOLET, emit=True, grain=0.02),
        'glow_toxic': Material(TOXIC, emit=True, grain=0.02),
        'glow_ember': Material(EMBER, emit=True, grain=0.02),
        'fungus_cap': Material(FUNGUS_CAP, spec=0.25, spots=(TOXIC, 0.09, 0.66, 41, True), vary=0.1, grain=0.08),
        'fungus_cap_plain': Material(FUNGUS_CAP, spec=0.25, vary=0.1, grain=0.08),
        'fungus_stem': Material(FUNGUS_STEM, vary=0.08, grain=0.08),
        'wood': Material(WOOD, top=(MOSS, 0.75, 0.06, 0.8, 31), vary=0.12, grain=0.05, grain_freq=0.3, cracks=(0.25, 1, 0.12, 1, 0.88, 1, 32)),
        'wood_wet': Material(WOOD_WET, top=(MOSS, 0.6, 0.06, 0.9, 33), vary=0.12, grain=0.05, grain_freq=0.3, cracks=(0.25, 1, 0.12, 1, 0.88, 1, 34)),
        'iron': Material(IRON_RUST, spec=0.25, vary=0.15, grain=0.18),
        'reed': Material(REED, vary=0.1, grain=0.1, rim=0.05),
        'reed_head': Material(REED_HEAD, vary=0.08, grain=0.1),
        'bone': Material(BONE, vary=0.1, grain=0.1),
        'cloth': Material(CLOTH_DARK, vary=0.1, grain=0.12),
        'ash': Material(ASH, vary=0.12, grain=0.15),
    }


# --------------------------------------------------------------------------- builders
def dead_tree(seed, height=150.0, trunk_r=17.0, mat='bark', twig='bark_twig', hang='hangmoss', hang_count=9, lean=0.0, depth=4):
    """Gnarled dead tree: flared mossy base, tapering trunk, thin forking branches and moss strands."""
    rng = random.Random(seed)
    prims = []
    segs = 6
    pts = [(0.0, 0.0, -6.0)]
    radii = [trunk_r * 1.35]
    sway = rng.uniform(0, math.tau)
    for i in range(1, segs + 1):
        f = i / segs
        z = height * 0.66 * f
        x = math.sin(sway + f * 2.4) * 10 * f + lean * f * 30
        y = math.cos(sway * 1.3 + f * 1.9) * 6 * f
        pts.append((x, y, z))
        radii.append(trunk_r * (1.0 - 0.66 * f))
    bark_disp = (1.8, 0.09, seed, 1.0, 1.0, 0.2)
    for i in range(segs):
        prims.append(cone(pts[i], pts[i + 1], radii[i], radii[i + 1], mat, k=4, disp=bark_disp))
    nroots = rng.randint(5, 7)
    for j in range(nroots):
        a = j / nroots * math.tau + rng.uniform(-0.3, 0.3)
        ln = rng.uniform(30, 52)
        mid = (math.cos(a) * ln * 0.45, math.sin(a) * ln * 0.45, 6)
        end = (math.cos(a) * ln, math.sin(a) * ln, -4)
        prims.append(cone((0, 0, 18), mid, trunk_r * 0.6, trunk_r * 0.3, mat, k=7, disp=bark_disp))
        prims.append(cone(mid, end, trunk_r * 0.3, 1.4, mat, k=4, disp=bark_disp))
    tips = []

    def branch(p0, ang, elev, length, radius, level):
        segs_b = 2
        cur = p0; r = radius
        for sgi in range(segs_b):
            ang += rng.uniform(-0.35, 0.35); elev += rng.uniform(-0.25, 0.12)
            nxt = (cur[0] + math.cos(ang) * math.cos(elev) * length / segs_b,
                   cur[1] + math.sin(ang) * math.cos(elev) * length / segs_b,
                   cur[2] + math.sin(elev) * length / segs_b)
            r2 = max(0.7, r * 0.72)
            prims.append(cone(cur, nxt, r, r2, twig if radius < trunk_r * 0.33 else mat, k=1.5 if r > 2 else 0.0,
                              disp=(0.7, 0.18, seed + level, 1, 1, 0.5) if r > 2.5 else None))
            cur = nxt; r = r2
            if rng.random() < 0.35 and level <= 2:
                tips.append(cur)
        if level == 0 or r < 1.0:
            tips.append(cur)
            return
        kids = 2 if rng.random() < 0.75 else 3
        for c in range(kids):
            branch(cur, ang + rng.uniform(-0.95, 0.95), elev + rng.uniform(-0.15, 0.5), length * rng.uniform(0.55, 0.72), r * 0.82, level - 1)

    nb = rng.randint(3, 4)
    for b in range(nb):
        a = b / nb * math.tau + rng.uniform(-0.4, 0.4)
        si = rng.randint(3, segs)
        branch(pts[si], a, rng.uniform(0.15, 0.7), height * rng.uniform(0.34, 0.44), radii[si] * 0.62, depth - 1)
    branch(pts[-1], sway, 1.15, height * 0.26, radii[-1] * 0.9, depth - 2)
    rng.shuffle(tips)
    # Thin, tapering moss strands (a few per tree) instead of thick sticks.
    for p in tips[:hang_count]:
        ln = rng.uniform(14, 30)
        ox = rng.uniform(-2, 2)
        top = (p[0] + ox, p[1], p[2])
        midp = (p[0] + ox + rng.uniform(-2, 2), p[1] - 0.5, p[2] - ln * 0.55)
        prims.append(cone(top, midp, 0.95, 0.6, hang))
        prims.append(cone(midp, (midp[0] + rng.uniform(-1.5, 1.5), midp[1], p[2] - ln), 0.6, 0.25, hang))
    return prims


def rock(seed, size=28.0, mat='stone_swamp', squash=0.7, lumps=3):
    """Angular boulder cluster made of chipped, rotated blocks."""
    rng = random.Random(seed)
    prims = [box((0, 0, size * squash * 0.45), (size * 0.8, size * 0.68, size * squash * 0.55), mat,
                 rotm=rot(yaw=rng.uniform(0, 360), roll=rng.uniform(-12, 12), pitch=rng.uniform(-14, 14)), round_=size * 0.12, k=3,
                 disp=(size * 0.07, 0.07, seed, 1, 1, 1))]
    for i in range(lumps):
        a = rng.uniform(0, math.tau); s2 = size * rng.uniform(0.35, 0.55)
        c = (math.cos(a) * size * 0.85, math.sin(a) * size * 0.7, s2 * squash * 0.4)
        prims.append(box(c, (s2 * 0.8, s2 * 0.7, s2 * squash * 0.55), mat, rotm=rot(yaw=rng.uniform(0, 360), roll=rng.uniform(-20, 20), pitch=rng.uniform(-20, 20)),
                         round_=s2 * 0.15, k=2, disp=(s2 * 0.08, 0.09, seed + i, 1, 1, 1)))
    return prims


def mushroom(c, h, cap_r, mat_cap='fungus_cap', mat_stem='fungus_stem', tilt=0.0, seed=0):
    x, y, z = c
    tx = math.sin(math.radians(tilt)) * h
    prims = [cone((x, y, z), (x + tx, y, z + h), cap_r * 0.28, cap_r * 0.2, mat_stem, k=2)]
    prims.append(ellipsoid((x + tx, y, z + h), (cap_r, cap_r * 0.92, cap_r * 0.5), mat_cap, k=2, disp=(0.6, 0.15, seed, 1, 1, 1)))
    prims.append(ellipsoid((x + tx, y, z + h - cap_r * 0.18), (cap_r * 0.9, cap_r * 0.82, cap_r * 0.22), mat_stem, k=1))
    return prims


def masonry_block(c, half, mat, yaw=0.0, chip=0.0, seed=0):
    return box(c, half, mat, rotm=rot(yaw=yaw), round_=1.2, disp=(chip, 0.09, seed, 1, 1, 1) if chip else None)


def column(c, radius, height, mat, broken=0.0, seed=0, fluted=True):
    x, y, z = c
    prims = [cylinder((x, y, z + 6), radius * 1.35, 6, mat, round_=1.0),
             cylinder((x, y, z + height * 0.5 + 6), radius, height * 0.5, mat, round_=1.0, disp=(1.0, 0.12, seed, 1, 1, 0.3))]
    if broken > 0:
        rng = random.Random(seed)
        prims.append(box((x + rng.uniform(-4, 4), y, z + height + 12), (radius * 1.6, radius * 1.6, broken), mat, rotm=rot(roll=rng.uniform(-35, 35), pitch=rng.uniform(-35, 35)), neg=True))
    else:
        prims.append(cylinder((x, y, z + height + 10), radius * 1.3, 4, mat, round_=1.0))
    return prims
