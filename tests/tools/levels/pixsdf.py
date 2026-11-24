"""Procedural pixel-art renderer for FirstGame level assets.

Signed-distance primitives are ray-marched with an orthographic 3/4 top-down camera,
lit with a fixed upper-left key light, quantised onto hand-picked palette ramps with
ordered dithering and finished with selective dark outlines. World units equal in-game
pixels at scale 1. Axes: +x screen right, +y north (away from the viewer), +z up.

The renderer is deterministic: identical inputs always produce identical PNGs.
"""
from __future__ import annotations

import math
from dataclasses import dataclass, field

import numpy as np

ELEV = math.radians(40.0)
FWD = np.array([0.0, math.cos(ELEV), -math.sin(ELEV)])
RIGHT = np.array([1.0, 0.0, 0.0])
UP = np.array([0.0, math.sin(ELEV), math.cos(ELEV)])
LIGHT = np.array([-0.62, -0.28, 0.73])
LIGHT = LIGHT / np.linalg.norm(LIGHT)
VIEW = -FWD
HALF = (LIGHT + VIEW) / np.linalg.norm(LIGHT + VIEW)

BAYER4 = (np.array([[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]], dtype=np.float64) + 0.5) / 16.0


# --------------------------------------------------------------------------- noise
def _hash(ix, iy, iz, seed):
    h = (ix * 73856093) ^ (iy * 19349663) ^ (iz * 83492791) ^ (int(seed) * 2654435761 & 0xFFFFFFFF)
    h = h & 0xFFFFFFFF
    h = (((h >> 16) ^ h) * 0x45D9F3B) & 0xFFFFFFFF
    h = (((h >> 16) ^ h) * 0x45D9F3B) & 0xFFFFFFFF
    h = (h >> 16) ^ h
    return (h & 0xFFFFFF).astype(np.float64) / 16777216.0


def vnoise3(x, y, z, seed=0):
    xi = np.floor(x); yi = np.floor(y); zi = np.floor(z)
    xf = x - xi; yf = y - yi; zf = z - zi
    u = xf * xf * (3 - 2 * xf); v = yf * yf * (3 - 2 * yf); w = zf * zf * (3 - 2 * zf)
    ix = xi.astype(np.int64); iy = yi.astype(np.int64); iz = zi.astype(np.int64)
    c = [[[_hash(ix + a, iy + b, iz + cc, seed) for cc in (0, 1)] for b in (0, 1)] for a in (0, 1)]
    x00 = c[0][0][0] + (c[1][0][0] - c[0][0][0]) * u
    x10 = c[0][1][0] + (c[1][1][0] - c[0][1][0]) * u
    x01 = c[0][0][1] + (c[1][0][1] - c[0][0][1]) * u
    x11 = c[0][1][1] + (c[1][1][1] - c[0][1][1]) * u
    y0 = x00 + (x10 - x00) * v
    y1 = x01 + (x11 - x01) * v
    return y0 + (y1 - y0) * w


def fbm3(x, y, z, octaves=4, seed=0, lac=2.03, gain=0.5):
    total = np.zeros_like(x, dtype=np.float64); amp = 1.0; norm = 0.0; f = 1.0
    for o in range(octaves):
        total += amp * vnoise3(x * f, y * f, z * f, seed + o * 101)
        norm += amp; amp *= gain; f *= lac
    return total / norm


def vnoise2(x, y, seed=0):
    xi = np.floor(x); yi = np.floor(y)
    xf = x - xi; yf = y - yi
    u = xf * xf * (3 - 2 * xf); v = yf * yf * (3 - 2 * yf)
    ix = xi.astype(np.int64); iy = yi.astype(np.int64); z = np.zeros_like(ix)
    a = _hash(ix, iy, z, seed); b = _hash(ix + 1, iy, z, seed)
    c = _hash(ix, iy + 1, z, seed); d = _hash(ix + 1, iy + 1, z, seed)
    return (a + (b - a) * u) + ((c + (d - c) * u) - (a + (b - a) * u)) * v


def fbm2(x, y, octaves=4, seed=0, lac=2.03, gain=0.5):
    total = np.zeros_like(x, dtype=np.float64); amp = 1.0; norm = 0.0; f = 1.0
    for o in range(octaves):
        total += amp * vnoise2(x * f, y * f, seed + o * 131)
        norm += amp; amp *= gain; f *= lac
    return total / norm


def cell2(x, y, seed=0, jitter=0.85):
    """Worley noise: returns F1, F2 distances and the id hash of the nearest cell."""
    xi = np.floor(x).astype(np.int64); yi = np.floor(y).astype(np.int64)
    f1 = np.full(x.shape, 9.0); f2 = np.full(x.shape, 9.0); cid = np.zeros(x.shape)
    z = np.zeros_like(xi)
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            cx = xi + dx; cy = yi + dy
            px = cx + 0.5 + (_hash(cx, cy, z, seed) - 0.5) * jitter
            py = cy + 0.5 + (_hash(cx, cy, z + 7, seed) - 0.5) * jitter
            d = np.hypot(x - px, y - py)
            closer = d < f1
            f2 = np.where(closer, f1, np.minimum(f2, d))
            cid = np.where(closer, _hash(cx, cy, z + 13, seed), cid)
            f1 = np.where(closer, d, f1)
    return f1, f2, cid


# --------------------------------------------------------------------------- primitives
def _rot_z(deg):
    a = math.radians(deg); c = math.cos(a); s = math.sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1.0]])


def rot(yaw=0.0, pitch=0.0, roll=0.0):
    """Rotation matrix (degrees): roll about x, pitch about y, then yaw about z."""
    a, b, c = (math.radians(v) for v in (roll, pitch, yaw))
    rx = np.array([[1, 0, 0], [0, math.cos(a), -math.sin(a)], [0, math.sin(a), math.cos(a)]])
    ry = np.array([[math.cos(b), 0, math.sin(b)], [0, 1, 0], [-math.sin(b), 0, math.cos(b)]])
    rz = np.array([[math.cos(c), -math.sin(c), 0], [math.sin(c), math.cos(c), 0], [0, 0, 1]])
    return rz @ ry @ rx


@dataclass
class Prim:
    kind: str
    mat: str
    a: tuple = (0.0, 0.0, 0.0)
    b: tuple = (0.0, 0.0, 0.0)
    r: float = 1.0
    r2: float = 1.0
    size: tuple = (1.0, 1.0, 1.0)
    rotm: np.ndarray | None = None
    k: float = 0.0
    neg: bool = False
    disp: tuple | None = None  # (amp, freq, seed, sx, sy, sz)
    bbox: tuple = field(default=None)

    def __post_init__(self):
        a = np.array(self.a, dtype=float); b = np.array(self.b, dtype=float)
        pad = (self.disp[0] if self.disp else 0.0) + self.k + 1.0
        if self.kind in ("capsule", "cone"):
            rr = max(self.r, self.r2)
            lo = np.minimum(a, b) - rr - pad; hi = np.maximum(a, b) + rr + pad
        elif self.kind == "sphere":
            lo = a - self.r - pad; hi = a + self.r + pad
        else:
            ext = np.array(self.size, dtype=float)
            if self.rotm is not None:
                ext = np.abs(self.rotm) @ ext
            ext = ext + self.r
            lo = a - ext - pad; hi = a + ext + pad
        self.bbox = (lo, hi)
        self._a = a; self._b = b
        self._inv = None if self.rotm is None else self.rotm.T

    def dist(self, px, py, pz):
        a = self._a
        x = px - a[0]; y = py - a[1]; z = pz - a[2]
        if self._inv is not None and self.kind not in ("capsule", "cone", "sphere"):
            m = self._inv
            x, y, z = m[0, 0] * x + m[0, 1] * y + m[0, 2] * z, m[1, 0] * x + m[1, 1] * y + m[1, 2] * z, m[2, 0] * x + m[2, 1] * y + m[2, 2] * z
        k = self.kind
        if k == "sphere":
            d = np.sqrt(x * x + y * y + z * z) - self.r
        elif k == "ellipsoid":
            sx, sy, sz = self.size
            k0 = np.sqrt((x / sx) ** 2 + (y / sy) ** 2 + (z / sz) ** 2)
            k1 = np.sqrt((x / (sx * sx)) ** 2 + (y / (sy * sy)) ** 2 + (z / (sz * sz)) ** 2)
            d = k0 * (k0 - 1.0) / np.maximum(k1, 1e-6)
        elif k == "box":
            sx, sy, sz = self.size
            qx = np.abs(x) - sx; qy = np.abs(y) - sy; qz = np.abs(z) - sz
            d = np.sqrt(np.maximum(qx, 0) ** 2 + np.maximum(qy, 0) ** 2 + np.maximum(qz, 0) ** 2) + np.minimum(np.maximum(qx, np.maximum(qy, qz)), 0) - self.r
        elif k == "cylinder":  # vertical in local space; size=(radius, _, half height)
            rad, _, hh = self.size
            dx = np.sqrt(x * x + y * y) - rad; dz = np.abs(z) - hh
            d = np.minimum(np.maximum(dx, dz), 0) + np.sqrt(np.maximum(dx, 0) ** 2 + np.maximum(dz, 0) ** 2) - self.r
        elif k == "torus":  # size=(major, minor, _) lying in local xy
            q = np.sqrt(x * x + y * y) - self.size[0]
            d = np.sqrt(q * q + z * z) - self.size[1]
        elif k == "capsule":
            ba = self._b - a
            bax, bay, baz = ba
            den = max(float(ba @ ba), 1e-9)
            h = np.clip((x * bax + y * bay + z * baz) / den, 0, 1)
            dx = x - bax * h; dy = y - bay * h; dz = z - baz * h
            d = np.sqrt(dx * dx + dy * dy + dz * dz) - self.r
        elif k == "cone":  # round cone from a (radius r) to b (radius r2)
            ba = self._b - a
            l2 = float(ba @ ba); rr = self.r - self.r2; a2 = l2 - rr * rr; il2 = 1.0 / max(l2, 1e-9)
            y_ = x * ba[0] + y * ba[1] + z * ba[2]
            z_ = y_ - l2
            wx = x * l2 - ba[0] * y_; wy = y * l2 - ba[1] * y_; wz = z * l2 - ba[2] * y_
            x2 = wx * wx + wy * wy + wz * wz
            y2 = y_ * y_ * l2; z2 = z_ * z_ * l2
            kk = np.sign(rr) * rr * rr * x2
            d1 = np.sqrt(x2 + z2) * il2 - self.r2
            d2 = np.sqrt(x2 + y2) * il2 - self.r
            d3 = (np.sqrt(x2 * a2 * il2) + y_ * rr) * il2 - self.r
            d = np.where(np.sign(z_) * a2 * z2 > kk, d1, np.where(np.sign(y_) * a2 * y2 < kk, d2, d3))
        else:
            raise ValueError(k)
        if self.disp:
            amp, freq, seed, sx, sy, sz = self.disp
            d = d + amp * (fbm3(px * freq * sx, py * freq * sy, pz * freq * sz, 3, seed) - 0.5) * 2.0
        return d


def sphere(c, r, mat, **kw): return Prim("sphere", mat, a=c, r=r, **kw)
def ellipsoid(c, size, mat, rotm=None, **kw): return Prim("ellipsoid", mat, a=c, size=size, r=0.0, rotm=rotm, **kw)
def box(c, half, mat, rotm=None, round_=0.0, **kw): return Prim("box", mat, a=c, size=half, r=round_, rotm=rotm, **kw)
def cylinder(c, radius, half_h, mat, rotm=None, round_=0.0, **kw): return Prim("cylinder", mat, a=c, size=(radius, 0, half_h), r=round_, rotm=rotm, **kw)
def torus(c, major, minor, mat, rotm=None, **kw): return Prim("torus", mat, a=c, size=(major, minor, 0), r=0.0, rotm=rotm, **kw)
def capsule(a, b, r, mat, **kw): return Prim("capsule", mat, a=a, b=b, r=r, **kw)
def cone(a, b, ra, rb, mat, **kw): return Prim("cone", mat, a=a, b=b, r=ra, r2=rb, **kw)


def smin(a, b, k):
    h = np.clip(0.5 + 0.5 * (b - a) / k, 0.0, 1.0)
    return b + (a - b) * h - k * h * (1.0 - h)


def transform_prims(prims, yaw=0.0, offset=(0.0, 0.0, 0.0)):
    """Rotate a whole model about z (degrees, GameMaker convention: CCW from +x) and translate it."""
    m = _rot_z(yaw); off = np.array(offset, dtype=float); out = []
    for p in prims:
        a = m @ np.array(p.a, dtype=float) + off
        b = m @ np.array(p.b, dtype=float) + off
        rotm = m if p.rotm is None else m @ p.rotm
        if p.kind in ("capsule", "cone", "sphere"):
            rotm = None
        out.append(Prim(p.kind, p.mat, tuple(a), tuple(b), p.r, p.r2, p.size, rotm, p.k, p.neg, p.disp))
    return out


# --------------------------------------------------------------------------- scene evaluation
def _eval(prims, px, py, pz, want_mat=False):
    n = px.shape[0]
    d = np.full(n, 1e9); best = np.full(n, 1e9); mat = np.zeros(n, dtype=np.int32)
    for i, p in enumerate(prims):
        if p.neg:
            continue
        lo, hi = p.bbox
        qx = np.maximum(np.maximum(lo[0] - px, px - hi[0]), 0)
        qy = np.maximum(np.maximum(lo[1] - py, py - hi[1]), 0)
        qz = np.maximum(np.maximum(lo[2] - pz, pz - hi[2]), 0)
        db = np.sqrt(qx * qx + qy * qy + qz * qz)
        near = db < (d + p.k + 2.0)
        di = db.copy()
        if near.any():
            sel = np.nonzero(near)[0]
            di[sel] = p.dist(px[sel], py[sel], pz[sel])
        if want_mat:
            closer = di < best
            mat[closer] = i
            best = np.minimum(best, di)
        d = smin(d, di, p.k) if p.k > 0 else np.minimum(d, di)
    for p in prims:
        if p.neg:
            d = np.maximum(d, -p.dist(px, py, pz))
    return d, mat


@dataclass
class Material:
    ramp: list
    spec: float = 0.0
    emit: bool = False
    alpha: float = 1.0
    top: tuple | None = None      # (ramp, threshold, noise_freq, noise_amp, seed)
    spots: tuple | None = None    # (ramp, noise_freq, threshold, seed, emissive)
    vary: float = 0.10            # low-frequency value variation
    grain: float = 0.06           # pixel-scale value grain
    grain_freq: float = 0.22
    rim: float = 0.10
    outline: tuple | None = None  # explicit outline colour
    cracks: tuple | None = None   # (freq, sx, sy, sz, ridge_threshold, steps_darker, seed)
    specks: tuple | None = None   # (freq, threshold, steps_lighter, seed)
    top_specks: bool = True


def hexramp(*codes):
    out = []
    for c in codes:
        c = c.lstrip('#'); out.append((int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16)))
    return out



def shift(a, dy, dx, fill=0):
    """Shift a 2D/3D array without wrap-around (np.roll wraps edges into the opposite border)."""
    out = np.empty_like(a)
    out[...] = fill
    h, w = a.shape[:2]
    ys = slice(max(dy, 0), h + min(dy, 0)); yd = slice(max(-dy, 0), h + min(-dy, 0))
    xs = slice(max(dx, 0), w + min(dx, 0)); xd = slice(max(-dx, 0), w + min(-dx, 0))
    out[ys, xs] = a[yd, xd]
    return out

def render(prims, materials, width, height, origin, scale=1.0, max_steps=110, eps=0.35, step_scale=0.82,
           dither=0.32, ambient=0.24, outline=True, inner_lines=True, ao=True, alpha_cut=0.0, seed=0, gamma=1.35):
    """Return an RGBA uint8 array. origin=(ox, oy) is the pixel of world (0,0,0)."""
    mats = [materials[p.mat] for p in prims]
    ox, oy = origin
    jj, ii = np.meshgrid(np.arange(width), np.arange(height))
    sx = ((jj + 0.5) - ox) / scale
    sy = (oy - (ii + 0.5)) / scale
    sx = sx.ravel(); sy = sy.ravel()
    far = 2000.0
    rox = sx * RIGHT[0] + sy * UP[0] - far * FWD[0]
    roy = sx * RIGHT[1] + sy * UP[1] - far * FWD[1]
    roz = sx * RIGHT[2] + sy * UP[2] - far * FWD[2]
    # Scene bounds: clip rays to the union AABB.
    lo = np.min([p.bbox[0] for p in prims if not p.neg], axis=0)
    hi = np.max([p.bbox[1] for p in prims if not p.neg], axis=0)
    tmin = np.full(rox.shape, -1e9); tmax = np.full(rox.shape, 1e9)
    for axis, ro in enumerate((rox, roy, roz)):
        dirc = FWD[axis]
        if abs(dirc) < 1e-9:
            inside = (ro >= lo[axis]) & (ro <= hi[axis])
            tmin = np.where(inside, tmin, 1e9)
            continue
        t1 = (lo[axis] - ro) / dirc; t2 = (hi[axis] - ro) / dirc
        tmin = np.maximum(tmin, np.minimum(t1, t2)); tmax = np.minimum(tmax, np.maximum(t1, t2))
    valid = tmax > np.maximum(tmin, 0)
    t = np.maximum(tmin, 0.0)
    hit = np.zeros(rox.shape, dtype=bool)
    active = valid.copy()
    for _ in range(max_steps):
        idx = np.nonzero(active)[0]
        if idx.size == 0:
            break
        px = rox[idx] + t[idx] * FWD[0]; py = roy[idx] + t[idx] * FWD[1]; pz = roz[idx] + t[idx] * FWD[2]
        d, _ = _eval(prims, px, py, pz)
        done = d < eps
        hit[idx[done]] = True
        t[idx] += np.where(done, 0.0, np.maximum(d * step_scale, 0.05))
        gone = t[idx] > tmax[idx]
        active[idx[done | gone]] = False
    hidx = np.nonzero(hit)[0]
    rgba = np.zeros((width * height, 4), dtype=np.uint8)
    depth = np.full(width * height, np.inf)
    matid = np.full(width * height, -1, dtype=np.int32)
    if hidx.size == 0:
        return rgba.reshape(height, width, 4)
    px = rox[hidx] + t[hidx] * FWD[0]; py = roy[hidx] + t[hidx] * FWD[1]; pz = roz[hidx] + t[hidx] * FWD[2]
    _, mid = _eval(prims, px, py, pz, want_mat=True)
    h = 0.45
    nx = _eval(prims, px + h, py, pz)[0] - _eval(prims, px - h, py, pz)[0]
    ny = _eval(prims, px, py + h, pz)[0] - _eval(prims, px, py - h, pz)[0]
    nz = _eval(prims, px, py, pz + h)[0] - _eval(prims, px, py, pz - h)[0]
    nl = np.sqrt(nx * nx + ny * ny + nz * nz) + 1e-9
    nx /= nl; ny /= nl; nz /= nl
    diff = np.clip(nx * LIGHT[0] + ny * LIGHT[1] + nz * LIGHT[2], 0, 1)
    wrap = np.clip((nx * LIGHT[0] + ny * LIGHT[1] + nz * LIGHT[2]) * 0.5 + 0.5, 0, 1)
    lum = ambient + (1 - ambient) * (0.78 * diff + 0.22 * wrap)
    if ao:
        occ = np.zeros_like(lum)
        for hh, wgt in ((3.0, 0.5), (7.0, 0.3), (14.0, 0.2)):
            dd, _ = _eval(prims, px + nx * hh, py + ny * hh, pz + nz * hh)
            occ += wgt * np.clip((hh - dd) / hh, 0, 1)
        lum *= 1.0 - 0.55 * np.clip(occ, 0, 1)
    spec_term = np.clip(nx * HALF[0] + ny * HALF[1] + nz * HALF[2], 0, 1) ** 28
    rimv = (1 - np.clip(-(nx * FWD[0] + ny * FWD[1] + nz * FWD[2]), 0, 1)) ** 3
    gx = (jj.ravel()[hidx]) % 4; gy = (ii.ravel()[hidx]) % 4
    bay = BAYER4[gy, gx] - 0.5
    lowvar = (fbm3(px * 0.045, py * 0.045, pz * 0.045, 2, seed + 7) - 0.5)
    grain = (vnoise3(px * 0.6, py * 0.6, pz * 0.6, seed + 11) - 0.5)
    out = np.zeros((hidx.size, 4), dtype=np.float64)
    for mi in np.unique(mid):
        m = mats[mi]
        sel = mid == mi
        L = lum[sel] + m.vary * lowvar[sel] + m.grain * (vnoise3(px[sel] * m.grain_freq, py[sel] * m.grain_freq, pz[sel] * m.grain_freq, seed + 17) - 0.5) * 2
        L = L + m.spec * spec_term[sel] + m.rim * rimv[sel]
        ramp = np.array(m.ramp, dtype=np.float64)
        rsel = np.zeros(sel.sum(), dtype=np.int32)
        use_top = np.zeros(sel.sum(), dtype=bool); top_ramp = None
        if m.top:
            top_ramp_l, thr, freq, amp, tseed = m.top
            nn = fbm3(px[sel] * freq, py[sel] * freq, pz[sel] * freq, 3, tseed) - 0.5
            use_top = (nz[sel] + nn * amp) > thr
            top_ramp = np.array(top_ramp_l, dtype=np.float64)
        emit_mask = np.zeros(sel.sum(), dtype=bool); spot_ramp = None
        if m.spots:
            spot_ramp_l, freq, thr, sseed, emissive = m.spots
            sn = fbm3(px[sel] * freq, py[sel] * freq, pz[sel] * freq, 2, sseed)
            emit_mask = sn > thr
            spot_ramp = np.array(spot_ramp_l, dtype=np.float64)
        q = np.clip(np.clip(L, 0, 1.2) ** gamma + bay[sel] * dither / max(1, len(ramp) - 1) * 1.6, 0, 0.999)
        if m.emit:
            q = np.clip(0.55 + 0.45 * (L - 0.3) + bay[sel] * dither * 0.25, 0, 0.999)
        # Crisp pixel clusters: discrete ramp-step offsets instead of continuous grain.
        steps = np.zeros(sel.sum(), dtype=np.int32)
        if m.cracks:
            cf, csx, csy, csz, cthr, cst, cseed = m.cracks
            rn = vnoise3(px[sel] * cf * csx, py[sel] * cf * csy, pz[sel] * cf * csz, cseed)
            ridge = 1.0 - np.abs(2.0 * rn - 1.0)
            steps -= np.where(ridge > cthr, cst, 0)
        if m.specks:
            sf, sthr, sst, sseed = m.specks
            sn2 = vnoise3(px[sel] * sf, py[sel] * sf, pz[sel] * sf, sseed)
            steps += np.where((sn2 > sthr) & (diff[sel] > 0.35), sst, 0)
        base_idx = (q * len(ramp)).astype(int)
        col = ramp[np.clip(base_idx + steps, 0, len(ramp) - 1)]
        if top_ramp is not None and use_top.any():
            tq = q[use_top]
            tidx = (tq * len(top_ramp)).astype(int)
            # Clumpy top cover: light tips where the clump noise peaks.
            if m.top_specks:
                tn = vnoise3(px[sel][use_top] * 0.55, py[sel][use_top] * 0.55, pz[sel][use_top] * 0.55, 61)
                tidx = tidx + np.where(tn > 0.78, 1, 0) - np.where(tn < 0.16, 1, 0)
            col[use_top] = top_ramp[np.clip(tidx, 0, len(top_ramp) - 1)]
        if spot_ramp is not None and emit_mask.any():
            sq = np.clip(0.5 + 0.5 * q[emit_mask], 0, 0.999)
            col[emit_mask] = spot_ramp[(sq * len(spot_ramp)).astype(int)]
        out[sel, 0:3] = col
        out[sel, 3] = 255 * m.alpha
    rgba[hidx] = np.clip(out, 0, 255).astype(np.uint8)
    depth[hidx] = t[hidx]
    matid[hidx] = mid
    img = rgba.reshape(height, width, 4).copy()
    depth = depth.reshape(height, width)
    if inner_lines:
        # Darken the farther pixel at depth discontinuities so overlapping parts read clearly.
        dz = np.zeros((height, width), dtype=bool)
        for sy_, sx_ in ((1, 0), (0, 1), (-1, 0), (0, -1)):
            nb = shift(depth, sy_, sx_, np.inf)
            with np.errstate(invalid='ignore'):
                dz |= (depth - nb > 9.0) & np.isfinite(nb)
        dz &= img[:, :, 3] > 0
        img[dz, 0:3] = (img[dz, 0:3].astype(np.float64) * 0.55).astype(np.uint8)
    # Pixel-art key light: one brighter pixel on silhouette edges facing the upper-left light.
    a0 = img[:, :, 3] > 0
    edge = a0 & (~shift(a0, 1, 0, False) | ~shift(a0, 0, 1, False))
    if edge.any():
        e = img[edge, 0:3].astype(np.float64)
        img[edge, 0:3] = np.clip(e * 1.22 + 10, 0, 255).astype(np.uint8)
    if outline:
        alpha = img[:, :, 3] > 0
        ring = np.zeros_like(alpha)
        cols = np.zeros((height, width, 3), dtype=np.float64); cnt = np.zeros((height, width))
        for sy_, sx_ in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nb = shift(alpha, sy_, sx_, False)
            nbc = shift(img[:, :, 0:3].astype(np.float64), sy_, sx_, 0.0)
            add = nb & ~alpha
            ring |= add
            cols[add] += nbc[add]; cnt[add] += 1
        cols = cols / np.maximum(cnt, 1)[:, :, None]
        img[ring, 0:3] = np.clip(cols[ring] * 0.32 + np.array([6, 7, 10]), 0, 255).astype(np.uint8)
        img[ring, 3] = 255
    return img


def save_png(img, path):
    from PIL import Image
    Image.fromarray(img, "RGBA").save(path, optimize=True)


def trim_canvas(img, width, height, base_x, base_y, anchor):
    """Place an rendered image into a canvas so that anchor (ax, ay) lands at (base_x, base_y)."""
    out = np.zeros((height, width, 4), dtype=np.uint8)
    ax, ay = anchor
    h, w = img.shape[:2]
    x0 = base_x - ax; y0 = base_y - ay
    sx0 = max(0, -x0); sy0 = max(0, -y0)
    dx0 = max(0, x0); dy0 = max(0, y0)
    cw = min(w - sx0, width - dx0); ch = min(h - sy0, height - dy0)
    if cw > 0 and ch > 0:
        out[dy0:dy0 + ch, dx0:dx0 + cw] = img[sy0:sy0 + ch, sx0:sx0 + cw]
    return out


def autocrop(img, origin, margin=2):
    """Crop transparent borders; return (image, new_origin)."""
    a = img[:, :, 3] > 0
    if not a.any():
        return img[:1, :1].copy(), (0, 0)
    ys = np.nonzero(a.any(axis=1))[0]; xs = np.nonzero(a.any(axis=0))[0]
    y0 = max(0, ys[0] - margin); y1 = min(img.shape[0], ys[-1] + 1 + margin)
    x0 = max(0, xs[0] - margin); x1 = min(img.shape[1], xs[-1] + 1 + margin)
    return img[y0:y1, x0:x1].copy(), (origin[0] - x0, origin[1] - y0)


def render_fit(prims, materials, max_w=640, max_h=640, base=None, **kw):
    """Render into a generous canvas and crop to content. Returns (img, origin)."""
    ox, oy = (max_w // 2, max_h - 40) if base is None else base
    img = render(prims, materials, max_w, max_h, (ox, oy), **kw)
    return autocrop(img, (ox, oy))


def scale_prims(prims, s):
    """Uniformly scale a model about the origin (positions, radii, sizes, blend radii, displacement)."""
    out = []
    for p in prims:
        disp = None if p.disp is None else (p.disp[0] * s, p.disp[1] / s) + tuple(p.disp[2:])
        out.append(Prim(p.kind, p.mat, tuple(np.array(p.a) * s), tuple(np.array(p.b) * s), p.r * s, p.r2 * s,
                        tuple(np.array(p.size) * s), p.rotm, p.k * s, p.neg, disp))
    return out
