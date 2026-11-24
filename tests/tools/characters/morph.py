"""Small numpy-only image helpers (no scipy available): shifts, morphology, distances, components, HSV."""
from __future__ import annotations

from collections import deque

import numpy as np
from PIL import Image


def shift(m: np.ndarray, dy: int, dx: int, fill=False) -> np.ndarray:
    out = np.full_like(m, fill)
    h, w = m.shape[:2]
    ys, yd = (slice(0, h - dy), slice(dy, h)) if dy >= 0 else (slice(-dy, h), slice(0, h + dy))
    xs, xd = (slice(0, w - dx), slice(dx, w)) if dx >= 0 else (slice(-dx, w), slice(0, w + dx))
    out[yd, xd] = m[ys, xs]
    return out


def _offsets(r: int, disk: bool = True):
    return [(dy, dx) for dy in range(-r, r + 1) for dx in range(-r, r + 1) if not disk or dy * dy + dx * dx <= r * r + r]


def dilate(m: np.ndarray, r: int = 1, disk: bool = True) -> np.ndarray:
    out = m.copy()
    for dy, dx in _offsets(r, disk):
        out |= shift(m, dy, dx)
    return out


def erode(m: np.ndarray, r: int = 1, disk: bool = True) -> np.ndarray:
    out = m.copy()
    for dy, dx in _offsets(r, disk):
        out &= shift(m, dy, dx)
    return out


def close(m, r=1):
    return erode(dilate(m, r), r)


def open_(m, r=1):
    return dilate(erode(m, r), r)


def depth(m: np.ndarray, maxd: int = 12) -> np.ndarray:
    """Chessboard distance to the outside (1 = border pixel), capped at maxd."""
    d = np.zeros(m.shape, np.int16)
    cur = m.copy()
    for k in range(1, maxd + 1):
        if not cur.any():
            break
        d[cur] = k
        cur = erode(cur, 1, disk=False)
    return d


def components(m: np.ndarray, conn8: bool = True):
    """List of (ys, xs) index arrays, largest first."""
    h, w = m.shape
    seen = np.zeros_like(m, bool)
    nb = [(dy, dx) for dy in (-1, 0, 1) for dx in (-1, 0, 1) if (dy or dx) and (conn8 or dy == 0 or dx == 0)]
    comps = []
    for y0, x0 in zip(*np.nonzero(m)):
        if seen[y0, x0]:
            continue
        q = deque([(y0, x0)]); seen[y0, x0] = True; ys = []; xs = []
        while q:
            y, x = q.popleft(); ys.append(y); xs.append(x)
            for dy, dx in nb:
                ny, nx = y + dy, x + dx
                if 0 <= ny < h and 0 <= nx < w and m[ny, nx] and not seen[ny, nx]:
                    seen[ny, nx] = True; q.append((ny, nx))
        comps.append((np.array(ys), np.array(xs)))
    comps.sort(key=lambda c: -len(c[0]))
    return comps


def fill_holes(m: np.ndarray) -> np.ndarray:
    """m plus every background pocket not reachable from the image border (4-connected)."""
    h, w = m.shape
    outside = np.zeros_like(m)
    q = deque()
    for y in range(h):
        for x in (0, w - 1):
            if not m[y, x] and not outside[y, x]:
                outside[y, x] = True; q.append((y, x))
    for x in range(w):
        for y in (0, h - 1):
            if not m[y, x] and not outside[y, x]:
                outside[y, x] = True; q.append((y, x))
    while q:
        y, x = q.popleft()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and not m[ny, nx] and not outside[ny, nx]:
                outside[ny, nx] = True; q.append((ny, nx))
    return ~outside


def drop_small(m: np.ndarray, n: int) -> np.ndarray:
    out = np.zeros_like(m)
    for ys, xs in components(m):
        if len(ys) >= n:
            out[ys, xs] = True
    return out


def hsv(rgb: np.ndarray):
    """rgb uint8 HxWx3 -> (h degrees 0..360, s 0..1, v 0..1) float arrays."""
    a = np.asarray(Image.fromarray(rgb.astype(np.uint8), 'RGB').convert('HSV')).astype(float)
    return a[..., 0] * 360 / 256, a[..., 1] / 255, a[..., 2] / 255


def luma(rgb: np.ndarray) -> np.ndarray:
    rgb = rgb.astype(float)
    return (rgb[..., 0] * .299 + rgb[..., 1] * .587 + rgb[..., 2] * .114) / 255


def hue_in(h, lo, hi):
    return (h >= lo) & (h <= hi) if lo <= hi else (h >= lo) | (h <= hi)
