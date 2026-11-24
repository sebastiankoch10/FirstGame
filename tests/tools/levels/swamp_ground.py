"""Der verfluchte Sumpf – baked ground chunks and stamped micro details."""
from __future__ import annotations

import random

import numpy as np

from pixsdf import Material, box, capsule, cell2, cylinder, ellipsoid, fbm2, hexramp, render_fit, rot, sphere, vnoise2
from props_common import mushroom
from swamp import (G_ALGAE, G_BANK, G_GRASS, G_LEAF, G_MOSS, G_MUD, G_MUD_GLOSS, G_PATH, G_SOIL, G_SPORE, G_TOXIC, G_WATER,
                   G_WATER_DEEP, G_WATER_HI, mats)
from worldgen import CHUNK, jitter_grid_points, ramp_pick, shift2, stamp


def grass_tuft(seed):
    """Small tuft of blades as a hand-style pixel pattern."""
    rng = random.Random(seed)
    w, h = 11, 12
    a = np.zeros((h, w, 4), dtype=np.uint8)
    for b in range(rng.randint(4, 6)):
        x = rng.randint(2, w - 3); top = rng.randint(1, 6); lean = rng.choice((-1, 0, 1))
        for y in range(top, h - 1):
            xx = x + (lean if y < (top + h) // 2 else 0)
            c = G_GRASS[min(len(G_GRASS) - 1, 1 + (h - y) * 3 // h + (1 if y == top else 0))]
            a[y, xx] = (*c, 255)
    return a


def lily_pad(seed):
    """Flat lily pad seen in 3/4 view: notched ellipse, lit rim, darker veins, optional pale flower."""
    rng = random.Random(seed)
    rx = rng.uniform(6, 10); ry = rx * 0.62
    w = int(rx * 2 + 4); h = int(ry * 2 + 6)
    a = np.zeros((h, w, 4), dtype=np.uint8)
    cx = w / 2; cy = h / 2 + 1
    notch = rng.uniform(0, 360)
    ramp = [(20, 48, 26), (29, 66, 34), (40, 84, 43), (54, 104, 54), (70, 124, 64)]
    for y in range(h):
        for x in range(w):
            dx = (x + 0.5 - cx) / rx; dy = (y + 0.5 - cy) / ry
            d = dx * dx + dy * dy
            if d > 1:
                continue
            ang = (np.degrees(np.arctan2(-dy, dx)) - notch + 360) % 360
            if ang < 22 and d > 0.05:
                continue
            shade = 2 + (1 if dx < -0.2 and dy < 0 else 0) - (1 if dx > 0.3 and dy > 0.2 else 0)
            if d > 0.78:
                shade = 4 if (dx < 0 and dy < 0.2) else 1
            if abs(ang - 180) < 4 or abs(ang - 90) < 3 or abs(ang - 270) < 3:
                shade -= 1
            a[y, x] = (*ramp[max(0, min(4, shade))], 255)
    if seed % 2 == 1:
        fx, fy = int(cx - rx * 0.2), int(cy - ry * 0.4)
        for oy, ox, c in ((0, 0, (236, 228, 240)), (0, 1, (205, 190, 220)), (-1, 0, (250, 246, 252)), (0, -1, (205, 190, 220)), (1, 0, (170, 150, 190)), (0, 0, (240, 220, 120))):
            if 0 <= fy + oy < h and 0 <= fx + ox < w:
                a[fy + oy, fx + ox] = (*c, 255)
    return a


def build_stamps():
    m = mats()
    m['lily'] = Material(hexramp('14301a', '1d4222', '28552b', '336835', '407a3f', '518e4a'), grain=0.05)
    m['lily_flower'] = Material(hexramp('6a5f74', '8f84a0', 'bdb3cf', 'e8e2f2'), grain=0.02)
    m['leaf0'] = Material(hexramp('2b1d10', '3a2714', '4b3318', '5e3f1c'), grain=0.06)
    m['leaf1'] = Material(hexramp('2a120c', '3b1a10', '4f2414', '623019'), grain=0.06)
    m['leaf2'] = Material(hexramp('22200f', '302c14', '3f3a19', '4e481f'), grain=0.06)
    m['pebble'] = Material(hexramp('1d2020', '282c2b', '343938', '434847', '545958'), grain=0.06)
    st = {}
    st['pebble'] = [render_fit([ellipsoid((0, 0, 2), (3 + i, 2.5 + i * 0.7, 2), 'pebble', rotm=rot(yaw=i * 40))], m, 32, 32, base=(16, 20), inner_lines=False)[0] for i in range(3)]
    st['lily'] = [lily_pad(i) for i in range(4)]
    st['leaf'] = [render_fit([ellipsoid((0, 0, 0.6), (3.2, 1.6, 0.5), 'leaf' + str(i % 3), rotm=rot(yaw=i * 47))], m, 24, 24, base=(12, 14), inner_lines=False)[0] for i in range(6)]
    st['skull'] = [render_fit([ellipsoid((0, 0, 3), (4, 3.6, 3.4), 'bone'), sphere((-1.4, -3.2, 3.2), 1.0, 'cloth'), sphere((1.4, -3.2, 3.2), 1.0, 'cloth')], m, 24, 24, base=(12, 16))[0]]
    st['mushroom'] = [render_fit(mushroom((0, 0, 0), 5 + i, 4 + i, 'fungus_cap_plain', seed=i), m, 32, 32, base=(16, 24))[0] for i in range(2)]
    st['twig'] = [render_fit([capsule((-7, 0, 1), (7, i * 2 - 2, 1), 0.9, 'bark_twig_wet'), capsule((1, 0, 1), (5, 4 - i * 3, 1), 0.6, 'bark_twig_wet')], m, 32, 32, base=(16, 18), inner_lines=False)[0] for i in range(2)]
    st['tuft'] = [grass_tuft(i) for i in range(4)]
    return st


def lumps(X, Y, scale, seed):
    """Cell clods: (cell id, f1, lit-edge mask, shadow-edge mask)."""
    f1, f2, cid = cell2(X / scale, Y / scale, seed)
    up = shift2(cid, 1, 0, -1.0); left = shift2(cid, 0, 1, -1.0)
    down = shift2(cid, -1, 0, -1.0); right = shift2(cid, 0, -1, -1.0)
    lit = (up != cid) | (left != cid)
    shade = (down != cid) | (right != cid)
    return cid, f1, lit & ~shade, shade


def bake_chunk(layout, cx, cy, stamps):
    pad = 24
    x0 = cx * CHUNK - pad; y0 = cy * CHUNK - pad
    n = CHUNK + pad * 2
    Y, X = np.mgrid[0:n, 0:n].astype(np.float64)
    X += x0; Y += y0
    gx = (X.astype(np.int64)) & 3; gy = (Y.astype(np.int64)) & 3
    s = layout.seed
    f = layout.fields(X, Y)
    wv = f['water']; pd = f['path']
    water = wv > 0.04
    deep = wv > 0.75
    bank = (wv > -0.1) & ~water
    moss_v = fbm2(X / 95.0, Y / 95.0, 3, s + 11) + (fbm2(X / 24.0, Y / 24.0, 2, s + 12) - 0.5) * 0.35
    leaf_v = fbm2(X / 130.0, Y / 130.0, 3, s + 13)
    tone = fbm2(X / 34.0, Y / 34.0, 3, s + 14)
    broad = fbm2(X / 260.0, Y / 260.0, 2, s + 20)
    fine = vnoise2(X / 2.3, Y / 2.3, s + 15)
    path = (pd < 30) & ~water
    moss = (moss_v > 0.55) & ~water & ~path & ~bank
    toxic = np.zeros(X.shape, bool); mud = np.zeros(X.shape, bool); spores = np.zeros(X.shape, bool)
    hz_noise = fbm2(X / 26.0, Y / 26.0, 2, s + 17)
    for h in layout.hazards:
        if X.min() > h['x'] + h['r'] * 1.6 or X.max() < h['x'] - h['r'] * 1.6 or Y.min() > h['y'] + h['r'] * 1.6 or Y.max() < h['y'] - h['r'] * 1.6:
            continue
        d = np.hypot(X - h['x'], Y - h['y']) / h['r'] + (hz_noise - 0.5) * 0.35
        if h['kind'] == 'toxic':
            toxic |= d < 1.0
        elif h['kind'] == 'mud':
            mud |= d < 1.0
        else:
            spores |= d < 1.0
    img = np.zeros((n, n, 3), dtype=np.uint8)
    # Soil: calm large-scale tone + shaded clods (lit upper-left edge, shadowed lower-right edge).
    cid, f1, lit, shade = lumps(X, Y, 5.5, s + 16)
    v = 0.38 + (tone - 0.5) * 0.5 + (broad - 0.5) * 0.35 + (cid - 0.5) * 0.07 + (fine - 0.5) * 0.08
    v = v + np.where(lit & (cid > 0.45), 0.09, 0) - np.where(shade & (cid < 0.6), 0.07, 0)
    img[:] = ramp_pick(G_SOIL, np.clip(v, 0, 0.999), gx, gy, 0.25)
    # Moss cushions.
    mcid, mf1, mlit, mshade = lumps(X, Y, 4.2, s + 21)
    mv = 0.42 + (moss_v - 0.62) * 1.2 + (mcid - 0.5) * 0.25 + np.where(mlit, 0.22, 0) - np.where(mshade, 0.2, 0)
    img[moss] = ramp_pick(G_MOSS, np.clip(mv, 0, 0.999), gx, gy, 0.25)[moss]
    # Muddy trails with small puddles.
    pv = 0.48 + (tone - 0.5) * 0.4 + (cid - 0.5) * 0.1 + np.where(lit, 0.08, 0) - np.where(shade, 0.08, 0)
    img[path] = ramp_pick(G_PATH, np.clip(pv, 0, 0.999), gx, gy, 0.2)[path]
    puddle = path & (fbm2(X / 22.0, Y / 22.0, 2, s + 22) > 0.8)
    img[puddle] = ramp_pick(G_WATER, np.clip(0.55 + (fine - 0.5) * 0.3, 0, 0.999), gx, gy, 0.2)[puddle]
    # Wet bank ring.
    bv = 0.3 + (tone - 0.5) * 0.3 + (cid - 0.5) * 0.15 + np.where(lit, 0.12, 0)
    img[bank] = ramp_pick(G_MUD, np.clip(bv, 0, 0.999), gx, gy, 0.2)[bank]
    # Water: depth gradient, algae rafts and sparse short glints (motion is added at runtime).
    wvv = 0.62 - np.clip(wv, 0, 1.5) * 0.3 + (tone - 0.5) * 0.18
    img[water] = ramp_pick(G_WATER, np.clip(wvv, 0, 0.999), gx, gy, 0.3)[water]
    img[deep] = ramp_pick(G_WATER_DEEP, np.clip(wvv + 0.25, 0, 0.999), gx, gy, 0.3)[deep]
    algae_v = fbm2(X / 40.0, Y / 40.0, 3, s + 19)
    acid, af1, alit, ashade = lumps(X, Y, 3.5, s + 23)
    algae = water & (algae_v > 0.64) & ~deep
    img[algae] = ramp_pick(G_ALGAE, np.clip(0.35 + (acid - 0.5) * 0.4 + np.where(alit, 0.25, 0), 0, 0.999), gx, gy, 0.2)[algae]
    glint_n = vnoise2(X / 3.0, Y / 1.2, s + 24)
    glint = water & ~algae & (glint_n > 0.9) & (fbm2(X / 70.0, Y / 70.0, 2, s + 25) > 0.62)
    img[glint] = ramp_pick(G_WATER_HI, np.clip(glint_n - 0.3, 0, 0.999), gx, gy, 0.0)[glint]
    # Hazards with distinct palettes and rims.
    mudv = 0.35 + (tone - 0.5) * 0.4 + np.where(lit, 0.05, 0)
    img[mud] = ramp_pick(G_MUD, np.clip(mudv, 0, 0.999), gx, gy, 0.2)[mud]
    gloss = mud & (fine > 0.78) & (np.sin(X * 0.21 + Y * 0.13 + tone * 6) > 0.55)
    img[gloss] = ramp_pick(G_MUD_GLOSS, np.clip(fine, 0, 0.999), gx, gy, 0.0)[gloss]
    tcid, tf1, tlit, tshade = lumps(X, Y, 4.0, s + 26)
    tv = 0.4 + (tone - 0.5) * 0.4 + (tcid - 0.5) * 0.3 + np.where(tlit, 0.25, 0) - np.where(tshade, 0.15, 0)
    img[toxic] = ramp_pick(G_TOXIC, np.clip(tv, 0, 0.999), gx, gy, 0.25)[toxic]
    scid, sf1, slit, sshade = lumps(X, Y, 3.6, s + 27)
    sv = 0.35 + (scid - 0.5) * 0.4 + np.where(slit, 0.25, 0) - np.where(sshade, 0.2, 0)
    img[spores] = ramp_pick(G_SPORE, np.clip(sv, 0, 0.999), gx, gy, 0.25)[spores]
    spore_dots = spores & (sf1 < 0.13) & (scid > 0.6)
    img[spore_dots] = np.array([150, 210, 90], dtype=np.uint8)
    # Relief: visible north bank faces, wet south edges, moss cushion shadows.
    above_land = ~shift2(water, 1, 0, True) | ~shift2(water, 2, 0, True)
    face = water & above_land & ~toxic
    img[face] = ramp_pick(G_BANK, np.clip(0.45 + (cid - 0.5) * 0.5, 0, 0.999), gx, gy, 0.2)[face]
    wet_edge = water & ~shift2(water, -1, 0, True) & ~toxic
    img[wet_edge] = ramp_pick(G_WATER_HI, np.clip(0.1 + fine * 0.35, 0, 0.999), gx, gy, 0.0)[wet_edge]
    moss_shadow = moss & ~shift2(moss, -1, 0, False)
    img[moss_shadow] = (img[moss_shadow].astype(np.int32) * 6 // 10).astype(np.uint8)
    edge_out = ~moss & shift2(moss, 1, 0, False) & ~water
    img[edge_out] = (img[edge_out].astype(np.int32) * 7 // 10).astype(np.uint8)
    toxic_rim = toxic & ~shift2(toxic, 1, 0, False)
    img[toxic_rim] = np.array([190, 236, 120], dtype=np.uint8)
    toxic_out = ~toxic & (shift2(toxic, 1, 0, False) | shift2(toxic, -1, 0, False) | shift2(toxic, 0, 1, False) | shift2(toxic, 0, -1, False))
    img[toxic_out] = np.array([16, 24, 10], dtype=np.uint8)
    mud_out = ~mud & (shift2(mud, -1, 0, False) | shift2(mud, 0, 1, False) | shift2(mud, 0, -1, False) | shift2(mud, 1, 0, False))
    img[mud_out] = np.array([52, 47, 36], dtype=np.uint8)
    # Stamped details (deterministic jittered grid, chunk-border safe).
    for px, py, r in jitter_grid_points(x0, y0, x0 + n, y0 + n, 18, s + 31):
        lx = int(px - x0); ly = int(py - y0)
        if not (0 <= lx < n and 0 <= ly < n):
            continue
        roll = r.random()
        if toxic[ly, lx] or mud[ly, lx] or spores[ly, lx]:
            continue
        if water[ly, lx]:
            if roll < 0.05 and not deep[ly, lx]:
                src = stamps['lily'][r.randrange(len(stamps['lily']))]
            else:
                continue
        elif path[ly, lx]:
            if roll < 0.05:
                src = stamps['pebble'][r.randrange(3)]
            else:
                continue
        else:
            leafy = leaf_v[ly, lx] > 0.55
            if roll < (0.22 if leafy else 0.03):
                src = stamps['leaf'][r.randrange(len(stamps['leaf']))]
            elif roll < (0.27 if leafy else 0.12):
                src = stamps['tuft'][r.randrange(len(stamps['tuft']))]
            elif roll < (0.285 if leafy else 0.14):
                src = stamps['pebble'][r.randrange(3)]
            elif roll < (0.30 if leafy else 0.155):
                src = stamps['twig'][r.randrange(2)]
            elif roll < (0.31 if leafy else 0.165):
                src = stamps['mushroom'][r.randrange(2)]
            elif roll < (0.313 if leafy else 0.168):
                src = stamps['skull'][0]
            else:
                continue
        stamp(img, src, lx - src.shape[1] // 2, ly - src.shape[0] // 2)
    out = np.zeros((CHUNK, CHUNK, 4), dtype=np.uint8)
    out[:, :, 0:3] = img[pad:pad + CHUNK, pad:pad + CHUNK]
    out[:, :, 3] = 255
    return out
