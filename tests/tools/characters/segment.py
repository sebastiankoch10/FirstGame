"""Part segmentation of character atlas cells (high resolution, before the 96x96 import mapping).

Labels (uint8):
  0 BG, 1 KEEP (face, cape, scarf, quiver, robe skirt ... stays in the base model), 2 CHEST (torso, shoulders, upper arms),
  3 HANDS (forearms + hands), 4 FEET (lower legs + feet), 5 WEAPON (start weapon), 6 HALO (light matte fringe, removed),
  7 LEGS (hips/thighs: base clothing; covered by chest armour on classes with long armour), 8 HAIR (KEEP, used for headgear)
Approach: per-class colour rules find the identity parts (cape, scarf, hair, skin) and the weapon; the remaining
clothing/armour pixels are split into slots by zones along the body axis (head -> feet), arms by a per-row torso core.
"""
from __future__ import annotations

from dataclasses import dataclass, field

import numpy as np

from morph import close, components, depth, dilate, drop_small, erode, fill_holes, hsv, hue_in, shift

BG, KEEP, CHEST, HANDS, FEET, WEAPON, HALO, LEGS, HAIR = range(9)
NAMES = ['bg', 'keep', 'chest', 'hands', 'feet', 'weapon', 'halo', 'legs', 'hair']


@dataclass
class Seg:
    labels: np.ndarray
    grip: tuple | None = None          # weapon hand point (y, x) in cell space
    head: tuple | None = None          # (top_y, bottom_y, left_x, right_x) of hair+face
    lying: bool = False
    info: dict = field(default_factory=dict)


def halo_mask(rgb, fig, mode='warm'):
    """Light matte fringe left by the generator around some figures (walk atlases).
    warm: swordsman matte is warm (R-B ~ 12-20, R-G ~ 8-13), steel is neutral/cool (R-B ~ -2) -> strict warm test.
    neutral: ranger matte is unsaturated grey (s ~ .06, v ~ .77); hair (lavender) and shirt (bright white) stay."""
    h, s, v = hsv(rgb)
    r, g, b = (rgb[..., i].astype(int) for i in range(3))
    if mode == 'warm':
        light = fig & (s < .19) & (v > .52) & (v < .88) & (r - g >= 5) & (r - b >= 9)
    elif mode == 'loose':   # only for side tests of blades (may also take blade highlights)
        light = fig & (s < .19) & (v > .52) & (v < .88) & (r - g >= 4) & (r - b >= 6)
    else:
        light = fig & (s < .11) & (v > .56) & (v < .87)
    border = fig & ~erode(fig, 1, disk=False)
    ratio = (light & border).sum() / max(1, border.sum())
    halo = np.zeros_like(fig)
    if ratio < .20:
        return halo, ratio
    cur = fig.copy()
    for _ in range(7):  # peel matte pixels from the outside inwards
        edge = cur & ~erode(cur, 1, disk=False)
        peel = edge & light
        if not peel.any():
            break
        halo |= peel; cur &= ~peel
    return halo, ratio


def axis_coords(body, head_mask):
    """Normalised position along the body (0 head end .. 1 foot end) for upright and lying poses."""
    ys, xs = np.nonzero(body)
    top, bottom, left, right = ys.min(), ys.max(), xs.min(), xs.max()
    hgt, wid = bottom - top + 1, right - left + 1
    gy, gx = np.mgrid[0:body.shape[0], 0:body.shape[1]]
    lying = wid > 1.3 * hgt
    if not lying:
        return (gy - top) / hgt, False, (top, bottom, left, right)
    hx = np.nonzero(head_mask)[1].mean() if head_mask.any() else left
    if hx < (left + right) / 2:
        return (gx - left) / wid, True, (top, bottom, left, right)
    return (right - gx) / wid, True, (top, bottom, left, right)


def _protrusion(fig, p0, u, lo, hi, width, extra=0.0):
    """(both, one): length (px) of the segment with background on both sides / on at least one side."""
    h, w = fig.shape
    nrm = np.array([-u[1], u[0]]); off = width / 2 + 3.0 + extra
    both = one = 0
    for t in np.arange(lo, hi + 1, 1.0):
        q = p0 + u * t
        bg = 0
        for sgn in (-1, 1):
            y, x = int(round(q[0] + nrm[0] * off * sgn)), int(round(q[1] + nrm[1] * off * sgn))
            bg += (not (0 <= y < h and 0 <= x < w)) or (not fig[y, x])
        both += bg == 2; one += bg >= 1
    return both, one


def blade_from_steel(fig2, steel, body_c, min_len=22, max_width=10.5, seed=7, iters=2500, value=None, one_side=True, extra=0.0, core=None, trim=True, inlier=4.0, min_free=10, head_zone=None):
    """Sword blade = straight, narrow run of steel pixels that sticks out of the figure (both sides background).
    RANSAC over all steel pixels (blades vary 3-9 px wide and are often split by the hand).
    Returns (mask, inner_end, outer_end, width) or None."""
    ys, xs = np.nonzero(steel)
    if len(ys) < min_len:
        return None
    pts = np.stack([ys, xs], 1).astype(float)
    bright = value[ys, xs] if value is not None else np.ones(len(ys))
    rng = np.random.default_rng(seed)
    best = None
    for _ in range(iters):
        i = rng.integers(0, len(pts))
        near = np.nonzero((np.abs(pts[:, 0] - pts[i, 0]) < 40) & (np.abs(pts[:, 1] - pts[i, 1]) < 40))[0]
        j = near[rng.integers(0, len(near))]
        dvec = pts[j] - pts[i]; L = np.hypot(*dvec)
        if L < 8:
            continue
        u = dvec / L; nrm = np.array([-u[1], u[0]])
        dist = np.abs((pts - pts[i]) @ nrm)
        inl = dist <= inlier
        if inl.sum() < min_len:
            continue
        proj = np.sort((pts[inl] - pts[i]) @ u)
        gaps = np.nonzero(np.diff(proj) > 7)[0]
        cuts = np.concatenate([[0], gaps + 1, [len(proj)]])
        k = np.argmax(np.diff(cuts)); lo, hi = proj[cuts[k]], proj[cuts[k + 1] - 1]
        length = hi - lo; n_run = cuts[k + 1] - cuts[k]
        width = n_run / max(1.0, length)
        if length < min_len or width > max_width:
            continue
        if core is not None and core[ys[inl], xs[inl]].mean() < .25:
            continue
        both, one = _protrusion(fig2, pts[i], u, lo, hi, width, extra)
        long_bright = one_side and length >= 30 and both >= 4 and bright[inl].mean() > .55
        if both < min_free and not (one_side and one >= 13 and both >= 1 and bright[inl].mean() > .52) and not long_bright:
            continue
        if head_zone is not None:
            e0 = pts[i] + u * lo; e1 = pts[i] + u * hi
            top_y = min(e0[0], e1[0])
            in_head = max(e0[0], e1[0]) < head_zone[0]          # whole line inside the head band
            raised = top_y < head_zone[1] - 4 and length >= 26  # sticks out above the head
            if in_head and not raised:
                continue
        free = both + .5 * one
        score = 6 * free + 2 * length + n_run
        if best is None or score > best[0]:
            best = (score, pts[i], u, lo, hi, width)
    if best is None:
        return None
    _, p0, u, lo, hi, width = best
    nrm = np.array([-u[1], u[0]])
    e0 = p0 + u * lo; e1 = p0 + u * hi
    if np.hypot(*(e0 - body_c)) > np.hypot(*(e1 - body_c)):
        t_out, t_in, step = lo, hi, 1.0     # walk from the outer end towards the body
    else:
        t_out, t_in, step = hi, lo, -1.0
    # trim: follow the blade inwards while the line stays steel; a run of non-steel pixels is the hand/guard
    hgt, wid = fig2.shape; miss = 0; entry = None
    t = t_out
    while (t - t_in) * step <= 0:
        q = p0 + u * t; hit = False
        for a in (-1, 0, 1):
            y, x = int(round(q[0] + nrm[0] * a)), int(round(q[1] + nrm[1] * a))
            hit |= 0 <= y < hgt and 0 <= x < wid and bool(steel[y, x])
        miss = 0 if hit else miss + 1
        if miss >= 4:
            entry = t - step * 4
            break
        t += step
    if entry is not None and trim:
        t_in = entry + step * 3
    lo2, hi2 = min(t_out, t_in), max(t_out, t_in)
    if not trim:
        # untrimmed (staffs): keep only the free stretches plus a short run into the body at each free stretch
        hgt, wid = fig2.shape; off = width / 2 + 3.0; free_t = []
        for tt in np.arange(lo, hi + 1, 1.0):
            q = p0 + u * tt; bg = 0
            for sgn in (-1, 1):
                y, x = int(round(q[0] + nrm[0] * off * sgn)), int(round(q[1] + nrm[1] * off * sgn))
                bg += (not (0 <= y < hgt and 0 <= x < wid)) or (not fig2[y, x])
            if bg == 2:
                free_t.append(tt)
        if free_t:
            ft = np.array(free_t); mid = (lo + hi) / 2
            a_side = ft[ft < mid]; b_side = ft[ft >= mid]
            if len(a_side) and len(b_side):
                lo2, hi2 = ft.min() - 2, ft.max() + 2          # crosses the body: whole shaft
            elif len(a_side):
                lo2, hi2 = ft.min() - 2, min(hi, ft.max() + 26)
            else:
                lo2, hi2 = max(lo, ft.min() - 26), ft.max() + 2
            t_out, t_in = (lo2, hi2) if step > 0 else (hi2, lo2)
    proj_all = (pts - p0) @ u; dist_all = np.abs((pts - p0) @ nrm)
    sel = (dist_all <= width / 2 + 1.5) & (proj_all >= lo2 - 1) & (proj_all <= hi2 + 1)
    outer = p0 + u * t_out; inner = p0 + u * t_in
    m = np.zeros_like(fig2); m[ys[sel], xs[sel]] = True
    grip = p0 + u * (t_in + step * 4)
    return m, inner, outer, width, grip


def capsule(shape, p0, p1, radius, extend0=0.0, extend1=0.0):
    gy, gx = np.mgrid[0:shape[0], 0:shape[1]]
    d = np.array(p1, float) - np.array(p0, float); L = np.linalg.norm(d) + 1e-6; u = d / L
    rel = np.stack([gy - p0[0], gx - p0[1]], -1).astype(float)
    along = rel @ u; across = np.abs(rel @ np.array([-u[1], u[0]]))
    return (along > -extend0) & (along < L + extend1) & (across <= radius), along, across


def arms_lateral(clothing, body_no_cape, coord, lo, hi, core_depth=7):
    """Clothing pixels left/right of the per-row torso core inside the arm band."""
    d = depth(body_no_cape, 14)
    out = np.zeros_like(clothing)
    rows = []
    for y in range(clothing.shape[0]):
        row = (coord[y] > lo) & (coord[y] < hi)
        if not row.any():
            continue
        core = np.nonzero((d[y] >= core_depth) & row)[0]
        if len(core):
            rows.append((y, core.min(), core.max()))
    if len(rows) < 4:
        return out
    ys = np.array([r[0] for r in rows]); ls = np.array([r[1] for r in rows], float); rs = np.array([r[2] for r in rows], float)
    # robust torso core: per-row bounds smoothed with a running median, then widened to a stable minimum width
    k = 7
    lsm = np.array([np.median(ls[max(0, i - k):i + k + 1]) for i in range(len(ls))])
    rsm = np.array([np.median(rs[max(0, i - k):i + k + 1]) for i in range(len(rs))])
    wmin = np.percentile(rsm - lsm, 60)
    mid = (lsm + rsm) / 2
    lsm = np.minimum(lsm, mid - wmin / 2); rsm = np.maximum(rsm, mid + wmin / 2)
    for y, l, r in zip(ys, lsm, rsm):
        row = (coord[y] > lo) & (coord[y] < hi)
        xs = np.nonzero(clothing[y] & row)[0]
        out[y, xs[(xs < l - 3) | (xs > r + 3)]] = True
    return out


def hands_region(clothing, body_no_cape, coord, grip, shape, lo=.40, hi=.72, forearm=15, grip_r=10):
    """Weapon hand (disk around the grip) + hanging arms beside the torso (tall lateral components, lower part)."""
    out = np.zeros(shape, bool)
    lat = arms_lateral(clothing, body_no_cape, coord, lo, hi)
    for ys, xs in components(lat):
        hgt = ys.max() - ys.min() + 1; wid = xs.max() - xs.min() + 1
        if len(ys) < 25 or hgt < 9 or hgt < .8 * wid:
            continue
        sel = ys >= ys.max() - forearm
        out[ys[sel], xs[sel]] = True
    if grip is not None:
        out |= clothing & disk(shape, grip, grip_r) & (coord > lo - .1)
    return out & clothing


def disk(shape, c, r):
    gy, gx = np.mgrid[0:shape[0], 0:shape[1]]
    return (gy - c[0]) ** 2 + (gx - c[1]) ** 2 <= r * r


# ---------------------------------------------------------------- swordsman
def seg_swordsman(rgba):
    rgb = rgba[..., :3]; fig = rgba[..., 3] > 0
    h, s, v = hsv(rgb)
    halo, hr = halo_mask(rgb, fig)
    fig2 = fig & ~halo
    red = fig2 & hue_in(h, 328, 18) & (s > .36) & (v > .10)
    gold = fig2 & hue_in(h, 22, 58) & (s > .30) & (v > .30)
    steel = fig2 & (s < .22) & (v > .30)
    steel_full = fig & (s < .22) & (v > .30)   # incl. matte pixels: halo peeling must not eat a light blade
    skin = fig2 & hue_in(h, 6, 34) & (s > .16) & (s < .56) & (v > .60)
    body_c = np.array(np.nonzero(fig2)).mean(1)
    weapon = np.zeros_like(fig); grip = None; blade_ends = None
    fy0 = np.nonzero(fig2)[0]
    hz = (fy0.min() + .36 * (fy0.max() - fy0.min()), fy0.min())   # (lower edge of the head band, figure top)
    loose, _ = halo_mask(rgb, fig, 'loose')
    side_fig = fig & ~loose if hr >= .20 else fig2              # matte around a blade must not hide its free stretch
    bl = blade_from_steel(side_fig, steel, body_c, value=v, head_zone=hz)
    if bl is not None:
        fy, fx = np.nonzero(fig2)
        upright = (fy.max() - fy.min()) >= .8 * (fx.max() - fx.min())
        if upright and (bl[1][0] - fy.min()) / (fy.max() - fy.min() + 1) > .80:
            bl = None
    if bl is not None:
        blade, inner, outer, width, gp = bl
        band, along, across = capsule(fig.shape, inner, outer, width / 2 + 2.2, 1, 2)
        weapon = blade | (band & fig2 & ~red & ~skin & (steel | (v < .45) | gold))
        guard, along, across = capsule(fig.shape, inner, inner - (outer - inner) / (np.linalg.norm(outer - inner) + 1e-6) * 6, 7.5, 0, 0)
        weapon |= guard & fig2 & ~red & ~skin & (gold | steel)
        grip = (int(gp[0]), int(gp[1]))
        blade_ends = (tuple(map(float, inner)), tuple(map(float, outer)))
    halo &= ~dilate(weapon, 1)
    fig2 = fig & ~halo
    body = fig2 & ~weapon
    # head (hair + face, holes filled so eyes/mouth stay with the face)
    ys = np.nonzero(body)[0]; top = ys.min(); H = ys.max() - top + 1
    upper = (np.arange(fig.shape[0])[:, None] - top) / H < .46
    hairish = body & upper & ~red & ~steel & (hue_in(h, 14, 58) & (s > .22) | (hue_in(h, 0, 60) & (v < .40) & (s > .25)))
    hair = np.zeros_like(fig)
    comps = components(hairish)
    for k, (cy, cx) in enumerate(comps[:4]):
        if cy.min() <= top + 6 or (k == 0 and len(cy) >= 60):   # raised fists can sit above the head
            hair[cy, cx] = True
    face = body & upper & skin
    head = fill_holes(close(hair | face, 2)) & body & ~red & ~(steel & ~upper)
    head &= ~(steel & dilate(drop_small(depth(steel, 6) >= 3, 10), 2))  # pauldrons poking into the head box
    hair &= head
    coord, lying, bb = axis_coords(body, head)
    cape = fill_holes(close(red, 1)) & body & ~head
    clothing = body & ~cape & ~head
    chest = clothing & (coord < .60)
    legs = clothing & (coord >= .60) & (coord < .77)
    feet = clothing & (coord >= .77)
    hands = hands_region(clothing, body & ~cape, coord, grip, fig.shape) & ~feet
    lab = np.zeros(fig.shape, np.uint8)
    lab[fig2] = KEEP
    lab[chest] = CHEST; lab[legs] = LEGS; lab[feet] = FEET; lab[hands] = HANDS
    lab[hair] = HAIR
    # undetected blade fragments (thin, elongated bright steel) stay original instead of being re-dressed as cloth
    core = drop_small(depth(steel, 8) >= 4, 8)
    loose = steel & ~dilate(core, 4) & ~weapon & (v > .5)
    for ys_, xs_ in components(loose):
        n = len(ys_); diag = np.hypot(ys_.max() - ys_.min(), xs_.max() - xs_.min())
        if diag >= 14 and n / max(diag, 1) < 4.5:
            lab[ys_, xs_] = KEEP
    lab[weapon] = WEAPON
    lab[halo] = HALO
    hy = np.nonzero(head)
    hb = (int(hy[0].min()), int(hy[0].max()), int(hy[1].min()), int(hy[1].max())) if len(hy[0]) else None
    return Seg(lab, grip, hb, lying, dict(halo_ratio=round(float(hr), 3), blade=blade_ends, cape=cape))


# ---------------------------------------------------------------- mage
def seg_mage(rgba):
    rgb = rgba[..., :3]; fig = rgba[..., 3] > 0
    h, s, v = hsv(rgb)
    halo, hr = halo_mask(rgb, fig)
    fig2 = fig & ~halo
    gold = fig2 & hue_in(h, 18, 60) & (s > .28) & (v > .34)
    skin = fig2 & hue_in(h, 4, 36) & (s > .12) & (s < .50) & (v > .66)
    lav = fig2 & hue_in(h, 230, 330) & (s < .48) & (v > .62)          # hair (light lavender)
    purple = fig2 & hue_in(h, 230, 335) & ~lav
    body_c = np.array(np.nonzero(fig2)).mean(1)
    weapon = np.zeros_like(fig); grip = None; blade_ends = None
    # the shaft is dark violet with gold rings: find it by geometry (long, perfectly straight, free on both sides)
    shaft = fig2 & ~lav & ~skin
    bl = blade_from_steel(fig2, shaft, body_c, min_len=40, max_width=6.5, value=None, trim=False, one_side=False, iters=3000, inlier=2.6, min_free=16)
    if bl is not None:
        line, inner, outer, width, gp = bl
        band, _, _ = capsule(fig.shape, inner, outer, width / 2 + 1.6, 2, 2)
        weapon = line | (band & fig2 & ~skin & ~lav & (gold | (v < .40)))
        # staff head: the end with more crystal/ornament around it gets a 13 px head zone
        cry = fig2 & ((hue_in(h, 215, 300) & (v > .50) & (s > .45)) | ((v > .90) & (s < .25)) | gold)
        ends = sorted([inner, outer], key=lambda e: -int((cry & disk(fig.shape, e, 14)).sum()))
        head_end, foot_end = ends
        headz = disk(fig.shape, head_end, 17) & fig2 & ~skin & ~(lav & ~cry)
        headz &= cry | (v < .38) | dilate(cry, 1)
        weapon |= headz
        blade_ends = (tuple(map(float, foot_end)), tuple(map(float, head_end)))
        grip = (int(gp[0]), int(gp[1]))
        # grip: the shaft point closest to the body centre between the ends
        seg_pts = np.linspace(0, 1, 40)[:, None] * (np.array(head_end) - np.array(foot_end)) + np.array(foot_end)
        dd = np.hypot(*(seg_pts - body_c).T); gpt = seg_pts[int(np.argmin(dd))]
        grip = (int(gpt[0]), int(gpt[1]))
    halo &= ~dilate(weapon, 1)
    fig2 = fig & ~halo
    body = fig2 & ~weapon
    ys = np.nonzero(body)[0]; top = ys.min(); H = ys.max() - top + 1
    zrow = (np.arange(fig.shape[0])[:, None] - top) / H
    upper = zrow < .42
    hairish = body & lav
    hair = np.zeros_like(fig)
    comps = components(hairish & (zrow < .55))
    for k, (cy, cx) in enumerate(comps[:5]):
        if cy.min() <= top + 8 or (k == 0 and len(cy) >= 60):
            hair[cy, cx] = True
    hair = close(hair, 1) & body & (lav | (hue_in(h, 230, 330) & (v > .45) & (s < .55)))
    face = body & upper & skin
    head = fill_holes(close((hair & upper) | face, 2)) & body & upper
    coord, lying, bb = axis_coords(body, head)
    long_hair = hair & ~head                     # flowing hair below the head stays identity (KEEP)
    clothing = body & ~head & ~long_hair
    chest = clothing & (coord < .56)
    legs = clothing & (coord >= .56) & (coord < .87)     # skirt: base dress, no slot
    feet = clothing & (coord >= .87)
    hands = hands_region(clothing, body & ~long_hair, coord, grip, fig.shape, lo=.30, hi=.66, forearm=12, grip_r=9) & ~feet & ~legs
    lab = np.zeros(fig.shape, np.uint8)
    lab[fig2] = KEEP
    lab[chest] = CHEST; lab[legs] = LEGS; lab[feet] = FEET; lab[hands] = HANDS
    lab[hair & head] = HAIR
    lab[weapon] = WEAPON
    lab[halo] = HALO
    hy = np.nonzero(head)
    hb = (int(hy[0].min()), int(hy[0].max()), int(hy[1].min()), int(hy[1].max())) if len(hy[0]) else None
    return Seg(lab, grip, hb, lying, dict(halo_ratio=round(float(hr), 3), blade=blade_ends))


# ---------------------------------------------------------------- ranger
def seg_ranger(rgba):
    rgb = rgba[..., :3]; fig = rgba[..., 3] > 0
    h, s, v = hsv(rgb)
    halo, hr = halo_mask(rgb, fig, 'neutral')
    fig2 = fig & ~halo
    green = fig2 & hue_in(h, 48, 175) & (s > .16) & (v > .08)
    gold = fig2 & hue_in(h, 22, 60) & (s > .38) & (v > .45)
    wood = fig2 & hue_in(h, 14, 52) & (s > .30) & (v > .30)
    skin = fig2 & hue_in(h, 4, 34) & (s > .14) & (s < .52) & (v > .64)
    light = fig2 & (s < .30) & (v > .62)                     # white hair, white shirt, bow string
    lavh = fig2 & hue_in(h, 230, 340) & (s < .45) & (v > .45)
    body_c = np.array(np.nonzero(fig2)).mean(1)
    # --- bow: the long thin wooden curve that is free (background on two opposite sides) along much of its length
    weapon = np.zeros_like(fig); grip = None; blade_ends = None
    bg = ~fig2
    opp = np.zeros_like(fig)
    for dy, dx in ((0, 1), (1, 0), (1, 1), (1, -1)):
        a = np.zeros_like(fig); b = np.zeros_like(fig)
        for k in (2, 3, 4):
            a |= shift(bg, dy * k, dx * k, True); b |= shift(bg, -dy * k, -dx * k, True)
        opp |= a & b
    cand = (wood | gold) & ~green
    seeds = [(ys, xs) for ys, xs in components(cand & opp, conn8=True) if len(ys) >= 10]
    best = None
    if seeds:
        seed = np.zeros_like(fig)
        for ys, xs in seeds:
            seed[ys, xs] = True
        grown = seed.copy()
        for _ in range(5):     # grow along the wood into the hand / over the body, max 5 px
            grown |= dilate(grown, 1) & cand
        ys, xs = np.nonzero(grown)
        diag = np.hypot(ys.max() - ys.min(), xs.max() - xs.min())
        if diag >= 26 and len(ys) >= 30:
            best = (diag, ys, xs)
    if best is not None:
        _, ys, xs = best
        bow = np.zeros_like(fig); bow[ys, xs] = True
        box = np.zeros_like(fig); box[max(0, ys.min() - 2):ys.max() + 3, max(0, xs.min() - 2):xs.max() + 3] = True
        string = box & light & opp & ~lavh
        weapon = bow | (dilate(bow, 1) & fig2 & (v < .35) & ~green & opp) | string
        pts = np.stack([ys, xs], 1).astype(float); c = pts.mean(0)
        _, sv, vt = np.linalg.svd(pts - c, full_matrices=False)
        proj = (pts - c) @ vt[0]
        e0, e1 = pts[proj.argmin()], pts[proj.argmax()]
        blade_ends = (tuple(map(float, e0)), tuple(map(float, e1)))
        k = int(np.argmin(np.hypot(*(pts - body_c).T))); grip = (int(pts[k, 0]), int(pts[k, 1]))
    halo &= ~dilate(weapon, 1)
    fig2 = fig & ~halo
    body = fig2 & ~weapon
    ys = np.nonzero(body)[0]; top = ys.min(); H = ys.max() - top + 1
    zrow = (np.arange(fig.shape[0])[:, None] - top) / H
    upper = zrow < .42
    hairish = body & upper & (light | lavh) & ~green
    hair = np.zeros_like(fig)
    for k, (cy, cx) in enumerate(components(hairish)[:4]):
        if cy.min() <= top + 6 or (k == 0 and len(cy) >= 60):
            hair[cy, cx] = True
    hair = close(hair, 1) & body & ~green
    face = body & upper & skin
    head = fill_holes(close(hair | face, 2)) & body & upper & ~green
    coord, lying, bb = axis_coords(body, head)
    greenish = green | (body & (v < .30) & dilate(green, 3))
    cape = fill_holes(close(greenish, 2)) & body & ~head
    shirt = body & light & ~head & ~cape & (coord < .62)
    clothing = body & ~head & ~cape & ~shirt
    chest = clothing & (coord < .58)
    legs = clothing & (coord >= .58) & (coord < .76)
    feet = clothing & (coord >= .76)
    hands = hands_region(clothing, body & ~cape, coord, grip, fig.shape, lo=.38, hi=.70, forearm=14, grip_r=9) & ~feet
    lab = np.zeros(fig.shape, np.uint8)
    lab[fig2] = KEEP
    lab[chest] = CHEST; lab[legs] = LEGS; lab[feet] = FEET; lab[hands] = HANDS
    lab[hair] = HAIR
    lab[weapon] = WEAPON
    lab[halo] = HALO
    hy = np.nonzero(head)
    hb = (int(hy[0].min()), int(hy[0].max()), int(hy[1].min()), int(hy[1].max())) if len(hy[0]) else None
    return Seg(lab, grip, hb, lying, dict(halo_ratio=round(float(hr), 3), blade=blade_ends, cape=cape))


SEGMENTERS = {'swordsmanv3': seg_swordsman, 'magev3': seg_mage, 'rangerv3': seg_ranger}


def segment(actor, rgba):
    return SEGMENTERS[actor](rgba)
