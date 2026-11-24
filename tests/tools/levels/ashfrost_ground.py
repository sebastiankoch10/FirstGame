"""Die Aschenfrost-Ruinen – baked ground chunks: flagstones, plazas, roads, snow, ice, ash and glowing ember cracks."""
from __future__ import annotations

import math
import random

import numpy as np

from pixsdf import Material, box, cell2, cone, ellipsoid, fbm2, hexramp, render_fit, rot, sphere, vnoise2
from worldgen import CHUNK, jitter_grid_points, ramp_pick, seg_distance, shift2, stamp

G_FLAG = hexramp('14171d', '1a1e25', '21252d', '282d36', '30363f', '393f4a', '444b56')
G_PAVE = hexramp('191c22', '20242b', '282c34', '30353e', '393f49', '444a55')
G_SNOW = hexramp('465163', '536073', '616f83', '718095', '8391a6', '97a4b7', 'adb9c9')
G_ICE = hexramp('14304a', '1b3c5a', '244b6d', '2f5c82', '3e7097', '5287ad', '6fa2c4')
G_ICE_HI = hexramp('9fc8e0', 'c6e2f0', 'eaf6fc')
G_ASH = hexramp('151417', '1c1a1d', '232024', '2a272a', '332f31', '3c3739')
G_EMBER = hexramp('5e1408', '992708', 'd24a10', 'f27a1e', 'ffb04a', 'ffdc8a')
G_DIRT = hexramp('131116', '19161b', '1f1b20', '252126')
G_CHAR = hexramp('0c0a0a', '120e0d', '181311', '1f1815')
G_FISSURE = hexramp('0a080d', '120e18', '1d1528')
G_VIOLET = hexramp('3a2266', '5c37a0', '8c62d8', 'c4a4f4')


def build_stamps():
    m = {'chip': Material(hexramp('1d2128', '272c34', '323842', '3e4550', '4b535f'), grain=0.04),
         'chip_ash': Material(hexramp('1c1a1c', '262325', '302c2e', '3b3638'), grain=0.04),
         'bone': Material(hexramp('3a352a', '575041', '766d59', '958b73', 'b3a98f'), grain=0.04),
         'dark': Material(hexramp('050506', '0b0b0d'), grain=0.0),
         'shard': Material(hexramp('1c7896', '2ea6c0', '5dd2e0', 'a6f2f4'), emit=True),
         'frost': Material(hexramp('7f8ea2', '9eadc0', 'c3cfdc', 'e3ebf2'), grain=0.03)}
    st = {}
    st['chip'] = [render_fit([box((0, 0, 1.5), (2 + i, 1.6 + i * 0.6, 1.5), 'chip', rotm=rot(yaw=i * 37, roll=10), round_=0.4)], m, 24, 24, base=(12, 15), inner_lines=False)[0] for i in range(3)]
    st['chip_ash'] = [render_fit([box((0, 0, 1.5), (2 + i, 1.6 + i * 0.6, 1.5), 'chip_ash', rotm=rot(yaw=i * 53, roll=-12), round_=0.4)], m, 24, 24, base=(12, 15), inner_lines=False)[0] for i in range(2)]
    st['skull'] = [render_fit([ellipsoid((0, 0, 3), (4, 3.6, 3.4), 'bone'), sphere((-1.4, -3.2, 3.2), 1.0, 'dark'), sphere((1.4, -3.2, 3.2), 1.0, 'dark')], m, 24, 24, base=(12, 16))[0]]
    st['shard'] = [render_fit([cone((0, 0, 0), (0.6 * i, 0, 5 + i * 2), 1.6, 0.3, 'shard')], m, 24, 24, base=(12, 18), inner_lines=False)[0] for i in range(2)]
    st['frost'] = [render_fit([ellipsoid((0, 0, 1.0), (4 + i * 2, 2.5 + i, 1.0), 'frost', rotm=rot(yaw=i * 30))], m, 32, 32, base=(16, 18), inner_lines=False)[0] for i in range(2)]
    return st


def _cells(X, Y, scale, seed):
    f1, f2, cid = cell2(X / scale, Y / scale, seed)
    up = shift2(cid, 1, 0, -1.0); left = shift2(cid, 0, 1, -1.0)
    down = shift2(cid, -1, 0, -1.0); right = shift2(cid, 0, -1, -1.0)
    lit = ((up != cid) | (left != cid)); shade = ((down != cid) | (right != cid))
    return f1, f2, cid, lit & ~shade, shade


def bake_chunk(layout, cx, cy, stamps):
    pad = 24
    x0 = cx * CHUNK - pad; y0 = cy * CHUNK - pad
    n = CHUNK + pad * 2
    Y, X = np.mgrid[0:n, 0:n].astype(np.float64)
    X += x0; Y += y0
    gx = X.astype(np.int64) & 3; gy = Y.astype(np.int64) & 3
    s = layout.seed
    frost, ember = layout.frost_ember(X, Y)
    pd = seg_distance(X, Y, layout.path_segs)
    tone = fbm2(X / 36.0, Y / 36.0, 3, s + 14)
    fine = vnoise2(X / 2.3, Y / 2.3, s + 15)
    wob = (fbm2(X / 40.0, Y / 40.0, 2, s + 16) - 0.5) * 40
    plaza = np.zeros(X.shape, bool)
    for px, py, pr in layout.plazas:
        if X.min() > px + pr * 1.3 or X.max() < px - pr * 1.3 or Y.min() > py + pr * 1.3 or Y.max() < py - pr * 1.3:
            continue
        plaza |= np.hypot(X - px, (Y - py) * 1.15) + wob < pr
    road = (pd + wob * 0.4) < 34
    paved = plaza | road
    img = np.zeros((n, n, 3), dtype=np.uint8)
    # Irregular flagstones with mortar and per-stone tint.
    f1, f2, cid, lit, shade = _cells(X, Y, 17.0, s + 17)
    mortar = (f2 - f1) < 0.09
    v = 0.42 + (tone - 0.5) * 0.4 + (cid - 0.5) * 0.3 + np.where(lit, 0.14, 0) - np.where(shade, 0.12, 0) + (fine - 0.5) * 0.06
    img[:] = ramp_pick(G_FLAG, np.clip(v, 0, 0.999), gx, gy, 0.2)
    missing = (cid > 0.9) & ~paved
    img[missing] = ramp_pick(G_DIRT, np.clip(0.4 + (fine - 0.5) * 0.5, 0, 0.999), gx, gy, 0.3)[missing]
    img[mortar] = (12, 13, 17)
    # Regular paving on plazas and roads (staggered rows, occasional broken tiles).
    tw = 28.0; th = 22.0
    row = np.floor(Y / th); colf = (X + (row % 2) * tw / 2) / tw
    col = np.floor(colf)
    lx = colf - col; ly = Y / th - row
    tid = ((col * 73.13 + row * 19.7) % 1.0 + np.abs(np.sin(col * 12.9898 + row * 78.233)) * 0.7) % 1.0
    tmortar = (lx < 0.06) | (ly < 0.08)
    tlit = (lx < 0.13) | (ly < 0.16); tshade = (lx > 0.9) | (ly > 0.88)
    pv = 0.45 + (tid - 0.5) * 0.35 + np.where(tlit, 0.12, 0) - np.where(tshade, 0.12, 0) + (tone - 0.5) * 0.25
    pave_img = ramp_pick(G_PAVE, np.clip(pv, 0, 0.999), gx, gy, 0.2)
    img[paved] = pave_img[paved]
    img[paved & tmortar] = (13, 14, 18)
    broken = paved & (tid > 0.93)
    img[broken] = ramp_pick(G_DIRT, np.clip(0.35 + fine * 0.4, 0, 0.999), gx, gy, 0.3)[broken]
    crack_n = vnoise2(X / 9.0, Y / 9.0, s + 18)
    crack = paved & (np.abs(crack_n - 0.5) < 0.018) & (tid > 0.6)
    img[crack] = (14, 15, 19)
    # Ash: cool grey-brown cover with ember speckles and glowing ridge cracks.
    ash_amt = (ember - 0.55) * 6 + (fbm2(X / 22.0, Y / 22.0, 2, s + 19) - 0.5) * 1.4
    ash = ash_amt > 0.0
    av = 0.4 + (tone - 0.5) * 0.4 + (fine - 0.5) * 0.25 + np.where(lit, 0.06, 0)
    img[ash] = ramp_pick(G_ASH, np.clip(av, 0, 0.999), gx, gy, 0.3)[ash]
    img[ash & mortar & (ash_amt < 0.6)] = (10, 9, 10)
    rn = vnoise2(X / 34.0, Y / 34.0, s + 20); rn2 = vnoise2(X / 11.0, Y / 11.0, s + 21)
    ridge = 1 - np.abs(2 * (rn * 0.75 + rn2 * 0.25) - 1)
    sparse = fbm2(X / 95.0, Y / 95.0, 2, s + 30) > 0.56
    glow_core = ash & sparse & (ember > 0.64) & (ridge > 0.986)
    glow_halo = ash & sparse & (ember > 0.64) & (ridge > 0.968) & ~glow_core
    img[glow_halo] = ramp_pick(G_EMBER, np.clip(0.18 + fine * 0.2, 0, 0.999), gx, gy, 0.0)[glow_halo]
    img[glow_core] = ramp_pick(G_EMBER, np.clip(0.55 + fine * 0.45, 0, 0.999), gx, gy, 0.0)[glow_core]
    specks = ash & (ember > 0.6) & (fine > 0.975)
    img[specks] = (200, 80, 24)
    # Snow: settles in mortar first, then covers stones; soft drift edges.
    snow_amt = (frost - 0.58) * 6 + (fbm2(X / 26.0, Y / 26.0, 2, s + 22) - 0.5) * 1.6
    snow = (snow_amt > 0.85) | ((snow_amt > -0.05) & (mortar | tmortar & paved)) | ((snow_amt > 0.4) & lit)
    sv = 0.5 + (tone - 0.5) * 0.35 + np.clip(snow_amt - 0.55, 0, 1) * 0.25 + np.where(lit, 0.1, 0) + (fine - 0.5) * 0.1
    img[snow] = ramp_pick(G_SNOW, np.clip(sv, 0, 0.999), gx, gy, 0.25)[snow]
    snow_edge = snow & ~shift2(snow, -1, 0, True)
    img[snow_edge] = ramp_pick(G_SNOW, np.clip(sv - 0.35, 0, 0.999), gx, gy, 0.0)[snow_edge]
    ice = (frost > 0.71) & (fbm2(X / 45.0, Y / 45.0, 3, s + 23) > 0.68) & ~paved
    iv = 0.45 + (tone - 0.5) * 0.3 + (vnoise2(X / 6.0, Y / 2.5, s + 24) - 0.5) * 0.35
    img[ice] = ramp_pick(G_ICE, np.clip(iv, 0, 0.999), gx, gy, 0.25)[ice]
    ice_hi = ice & (vnoise2(X / 2.0, Y / 1.2, s + 25) > 0.9)
    img[ice_hi] = ramp_pick(G_ICE_HI, np.clip(fine, 0, 0.999), gx, gy, 0.0)[ice_hi]
    # Hazards with unmistakable surfaces.
    hz = fbm2(X / 24.0, Y / 24.0, 2, s + 26)
    for h in layout.hazards:
        if h['kind'] == 'fissure':
            if min(h['x'], h['x2']) - 60 > X.max() or max(h['x'], h['x2']) + 60 < X.min() or min(h['y'], h['y2']) - 60 > Y.max() or max(h['y'], h['y2']) + 60 < Y.min():
                continue
            segs = np.array([[h['x'], h['y'], h['x2'], h['y2']]])
            d = seg_distance(X, Y, segs) + (hz - 0.5) * 6
            rim = d < 14; core = d < 6; line = d < 2.2
            img[rim] = ramp_pick(G_CHAR, np.clip(0.4 + fine * 0.5, 0, 0.999), gx, gy, 0.2)[rim]
            img[core] = ramp_pick(G_FISSURE, np.clip(0.3 + fine * 0.6, 0, 0.999), gx, gy, 0.2)[core]
            img[line] = ramp_pick(G_VIOLET, np.clip(0.3 + fine * 0.5, 0, 0.999), gx, gy, 0.0)[line]
            continue
        if X.min() > h['x'] + h['r'] * 1.6 or X.max() < h['x'] - h['r'] * 1.6 or Y.min() > h['y'] + h['r'] * 1.6 or Y.max() < h['y'] - h['r'] * 1.6:
            continue
        d = np.hypot(X - h['x'], (Y - h['y']) / 0.92) / h['r'] + (hz - 0.5) * 0.3
        inside = d < 1.0
        if h['kind'] == 'ember':
            img[inside] = ramp_pick(G_CHAR, np.clip(0.3 + fine * 0.6, 0, 0.999), gx, gy, 0.2)[inside]
            ang = np.arctan2(Y - h['y'], X - h['x'])
            spokes = (np.abs(np.sin(ang * 5 + hz * 6)) < 0.12 + 0.1 * (1 - d)) & (d < 0.92)
            cracks = inside & ((ridge > 0.9) | spokes)
            img[cracks] = ramp_pick(G_EMBER, np.clip(0.35 + (1 - d) * 0.6 + fine * 0.15, 0, 0.999), gx, gy, 0.0)[cracks]
            ring = (d > 0.95) & (d < 1.05)
            img[ring] = (34, 16, 10)
        else:  # ice field
            v2 = 0.55 + (vnoise2(X / 8.0, Y / 3.0, s + 27) - 0.5) * 0.4 + (1 - d) * 0.15
            img[inside] = ramp_pick(G_ICE, np.clip(v2, 0, 0.999), gx, gy, 0.25)[inside]
            hi = inside & (vnoise2(X / 1.6, Y / 1.0, s + 28) > 0.88)
            img[hi] = ramp_pick(G_ICE_HI, np.clip(fine, 0, 0.999), gx, gy, 0.0)[hi]
            cr = inside & (np.abs(vnoise2(X / 14.0, Y / 14.0, s + 29) - 0.5) < 0.015)
            img[cr] = (200, 232, 248)
            rim = (d > 0.93) & (d < 1.06)
            img[rim] = ramp_pick(G_SNOW, np.clip(0.75 + fine * 0.2, 0, 0.999), gx, gy, 0.0)[rim]
    # Stamps.
    for px, py, r in jitter_grid_points(x0, y0, x0 + n, y0 + n, 20, s + 31):
        lx = int(px - x0); ly = int(py - y0)
        if not (0 <= lx < n and 0 <= ly < n):
            continue
        roll = r.random()
        if ash[ly, lx]:
            src = stamps['chip_ash'][r.randrange(2)] if roll < 0.08 else (stamps['skull'][0] if roll < 0.088 else None)
        elif snow[ly, lx]:
            src = stamps['frost'][r.randrange(2)] if roll < 0.06 else (stamps['shard'][r.randrange(2)] if roll < 0.075 else None)
        else:
            src = stamps['chip'][r.randrange(3)] if roll < 0.05 else (stamps['shard'][r.randrange(2)] if roll < 0.058 else None)
        if src is not None:
            stamp(img, src, lx - src.shape[1] // 2, ly - src.shape[0] // 2)
    out = np.zeros((CHUNK, CHUNK, 4), dtype=np.uint8)
    out[:, :, 0:3] = img[pad:pad + CHUNK, pad:pad + CHUNK]
    out[:, :, 3] = 255
    return out
