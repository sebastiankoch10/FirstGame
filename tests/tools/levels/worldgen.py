"""Shared world-generation helpers: deterministic layout primitives, path geometry and ground baking."""
from __future__ import annotations

import math
import random

import numpy as np

from pixsdf import BAYER4, fbm2, vnoise2

WORLD = 4096
CHUNK = 512
START = (2112.0, 1952.0)


# --------------------------------------------------------------------------- geometry
def wiggly_path(a, b, rng, amp=120.0, steps=4):
    """Midpoint-displaced polyline between a and b."""
    pts = [a, b]
    for s in range(steps):
        out = [pts[0]]
        for p, q in zip(pts, pts[1:]):
            mx = (p[0] + q[0]) / 2; my = (p[1] + q[1]) / 2
            dx = q[0] - p[0]; dy = q[1] - p[1]; ln = math.hypot(dx, dy) + 1e-6
            off = rng.uniform(-1, 1) * amp / (1.7 ** s)
            out.append((mx - dy / ln * off, my + dx / ln * off))
            out.append(q)
        pts = out
    return [(min(max(x, 60), WORLD - 60), min(max(y, 60), WORLD - 60)) for x, y in pts]


def segments(polylines):
    segs = []
    for pl in polylines:
        for p, q in zip(pl, pl[1:]):
            segs.append((p[0], p[1], q[0], q[1]))
    return np.array(segs, dtype=np.float64) if segs else np.zeros((0, 4))


def seg_distance(x, y, segs, limit=400.0):
    """Distance from points (arrays) to the nearest segment; only segments near the points' bbox are evaluated."""
    d = np.full(x.shape, 1e9)
    if len(segs) == 0:
        return d
    x0, x1, y0, y1 = x.min() - limit, x.max() + limit, y.min() - limit, y.max() + limit
    for ax, ay, bx, by in segs:
        if max(ax, bx) < x0 or min(ax, bx) > x1 or max(ay, by) < y0 or min(ay, by) > y1:
            continue
        dx = bx - ax; dy = by - ay; den = dx * dx + dy * dy + 1e-9
        t = np.clip(((x - ax) * dx + (y - ay) * dy) / den, 0, 1)
        d = np.minimum(d, np.hypot(x - ax - dx * t, y - ay - dy * t))
    return d


def point_seg_distance(px, py, segs):
    best = 1e9
    for ax, ay, bx, by in segs:
        dx = bx - ax; dy = by - ay; den = dx * dx + dy * dy + 1e-9
        t = min(max(((px - ax) * dx + (py - ay) * dy) / den, 0), 1)
        best = min(best, math.hypot(px - ax - dx * t, py - ay - dy * t))
    return best


def blobs_field(x, y, blobs):
    """Sum of smooth radial bumps: blobs = [(cx, cy, radius, amplitude)]."""
    v = np.zeros(x.shape)
    for cx, cy, r, amp in blobs:
        if x.min() > cx + 2.2 * r or x.max() < cx - 2.2 * r or y.min() > cy + 2.2 * r or y.max() < cy - 2.2 * r:
            continue
        d2 = ((x - cx) ** 2 + (y - cy) ** 2) / (r * r)
        v += amp * np.exp(-d2 * 1.6)
    return v


# --------------------------------------------------------------------------- quantisation
def ramp_pick(ramp, value, gx, gy, dither=0.45):
    """Quantise value (0..1) onto a palette ramp with ordered dithering. Returns uint8 RGB."""
    r = np.asarray(ramp, dtype=np.uint8)
    n = len(r)
    b = BAYER4[gy % 4, gx % 4] - 0.5
    idx = np.clip((value * n + b * dither).astype(int), 0, n - 1)
    return r[idx]


def shift2(a, dy, dx, fill):
    out = np.empty_like(a); out[...] = fill
    h, w = a.shape[:2]
    out[max(dy, 0):h + min(dy, 0), max(dx, 0):w + min(dx, 0)] = a[max(-dy, 0):h + min(-dy, 0), max(-dx, 0):w + min(-dx, 0)]
    return out


def poisson_points(rng, count, accept, min_dist, tries=40, margin=80, existing=None, cell=64):
    """Rejection sampled points with a spatial hash; accept(x, y) -> bool."""
    pts = []
    grid = {}
    if existing:
        for p in existing:
            grid.setdefault((int(p[0] // cell), int(p[1] // cell)), []).append(p)

    def ok(x, y, md):
        cx, cy = int(x // cell), int(y // cell)
        rr = int(md // cell) + 1
        for gx in range(cx - rr, cx + rr + 1):
            for gy in range(cy - rr, cy + rr + 1):
                for q in grid.get((gx, gy), ()):
                    if (q[0] - x) ** 2 + (q[1] - y) ** 2 < md * md:
                        return False
        return True

    attempts = 0
    while len(pts) < count and attempts < count * tries:
        attempts += 1
        x = rng.uniform(margin, WORLD - margin); y = rng.uniform(margin, WORLD - margin)
        if not accept(x, y) or not ok(x, y, min_dist):
            continue
        p = (x, y)
        pts.append(p)
        grid.setdefault((int(x // cell), int(y // cell)), []).append(p)
    return pts


def stamp(dst, src, x, y):
    """Alpha-composite a small RGBA array into an RGB uint8 chunk at integer top-left (x, y)."""
    h, w = src.shape[:2]
    H, W = dst.shape[:2]
    x0 = max(0, x); y0 = max(0, y); x1 = min(W, x + w); y1 = min(H, y + h)
    if x1 <= x0 or y1 <= y0:
        return
    s = src[y0 - y:y1 - y, x0 - x:x1 - x]
    a = s[:, :, 3:4].astype(np.float32) / 255.0
    d = dst[y0:y1, x0:x1].astype(np.float32)
    dst[y0:y1, x0:x1] = np.clip(d * (1 - a) + s[:, :, 0:3].astype(np.float32) * a, 0, 255).astype(np.uint8)


def jitter_grid_points(x0, y0, x1, y1, cell, seed, density_fn=None):
    """Deterministic jittered-grid samples overlapping a rectangle (chunk-border safe)."""
    out = []
    gx0 = int(math.floor(x0 / cell)) - 1; gy0 = int(math.floor(y0 / cell)) - 1
    gx1 = int(math.floor(x1 / cell)) + 1; gy1 = int(math.floor(y1 / cell)) + 1
    for gx in range(gx0, gx1 + 1):
        for gy in range(gy0, gy1 + 1):
            h = (gx * 73856093 ^ gy * 19349663 ^ seed * 83492791) & 0xFFFFFFFF
            r = random.Random(h)
            px = (gx + r.random()) * cell; py = (gy + r.random()) * cell
            out.append((px, py, r))
    return out
