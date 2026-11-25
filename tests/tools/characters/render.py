"""Frame-level painting (96x96) of the base model, the start weapon and every equipment piece.

Everything is derived from the segmented atlas cell and mapped with the importer's exact pixel mapping, so all
layers share the body's pixels frame by frame. Painting keeps the original form shading (normalised luminance per
source material) and swaps the material ramp; patterns are authored at final pixel size (mail rings, scales,
rivets, runes, stitches). Accent pixels (trims, guards, gems) go to a separate grey layer that the game tints
with the item's rarity colour.
"""
from __future__ import annotations

from dataclasses import dataclass

import numpy as np

from atlas import FRAME  # frame size of the drawn sprites (density 1:1)

from morph import close, dilate, erode, fill_holes, hsv, hue_in, luma
from segment import BG, CHEST, FEET, HAIR, HALO, HANDS, KEEP, LEGS, WEAPON

# ------------------------------------------------------------------ material ramps (dark -> light, 7 steps)
RAMPS = {
    'outline':   [(14, 12, 16)],
    # base clothing
    'gambeson':  [(20, 22, 34), (31, 36, 54), (43, 51, 74), (57, 68, 96), (74, 88, 118), (94, 110, 140), (118, 134, 162)],
    'trousers':  [(22, 17, 18), (35, 27, 27), (50, 38, 36), (66, 51, 46), (84, 66, 58), (104, 83, 72), (126, 104, 90)],
    'wraps':     [(30, 20, 16), (48, 32, 24), (68, 46, 33), (90, 62, 44), (112, 80, 57), (136, 101, 73), (160, 124, 92)],
    'shoes':     [(24, 16, 12), (40, 27, 19), (58, 39, 27), (78, 53, 36), (99, 68, 46), (122, 86, 58), (146, 106, 74)],
    'dress':     [(26, 15, 46), (42, 25, 74), (62, 39, 104), (86, 57, 136), (112, 80, 166), (142, 110, 194), (180, 150, 218)],
    'linen':     [(62, 50, 40), (92, 76, 62), (124, 106, 88), (154, 136, 114), (182, 164, 140), (208, 192, 168), (232, 220, 198)],
    'silver':    [(30, 32, 40), (56, 60, 72), (88, 94, 108), (124, 130, 144), (162, 168, 180), (200, 206, 216), (240, 244, 250)],
    'gold':      [(48, 30, 10), (86, 56, 18), (128, 88, 30), (170, 124, 46), (206, 162, 70), (234, 198, 108), (252, 232, 170)],
    'ice':       [(20, 40, 70), (34, 70, 110), (56, 110, 160), (88, 156, 206), (134, 200, 236), (186, 230, 250), (236, 250, 255)],
    'void':      [(10, 4, 18), (24, 10, 40), (44, 18, 72), (70, 30, 110), (104, 50, 156), (146, 88, 206), (196, 150, 246)],
    'amber':     [(60, 26, 6), (100, 46, 10), (146, 74, 18), (190, 108, 30), (226, 148, 50), (248, 190, 90), (255, 230, 160)],
    'darkwood':  [(18, 10, 8), (32, 20, 14), (50, 32, 22), (70, 46, 32), (92, 62, 44), (116, 82, 60), (142, 106, 80)],
    'moon':      [(28, 34, 56), (48, 58, 90), (74, 88, 128), (106, 124, 166), (146, 164, 204), (192, 206, 236), (238, 244, 255)],
    'storm':     [(8, 30, 34), (14, 52, 58), (22, 78, 84), (34, 108, 112), (54, 142, 140), (86, 180, 170), (140, 220, 204)],
    # armour tiers
    'leather':   [(30, 18, 11), (52, 32, 19), (76, 48, 28), (102, 66, 38), (128, 86, 50), (156, 110, 66), (186, 138, 88)],
    'iron':      [(24, 26, 31), (42, 46, 54), (64, 70, 80), (90, 98, 110), (120, 128, 140), (154, 162, 172), (194, 200, 208)],
    'steel':     [(20, 23, 32), (38, 44, 60), (62, 72, 94), (96, 108, 130), (138, 150, 170), (184, 194, 210), (232, 238, 246)],
    'runesteel': [(12, 14, 24), (22, 26, 42), (34, 40, 62), (50, 60, 88), (70, 84, 116), (96, 112, 146), (128, 146, 180)],
    'scale':     [(10, 20, 22), (17, 34, 36), (26, 52, 52), (38, 74, 70), (54, 100, 90), (78, 130, 112), (112, 166, 138)],
    'shadow':    [(12, 8, 20), (22, 15, 36), (34, 24, 54), (48, 34, 74), (64, 46, 98), (86, 64, 126), (116, 90, 160)],
    'bone':      [(52, 42, 34), (86, 74, 60), (122, 108, 88), (158, 146, 122), (194, 182, 156), (222, 212, 188), (244, 238, 220)],
    'bronze':    [(36, 22, 12), (64, 40, 20), (96, 62, 30), (130, 88, 42), (164, 118, 58), (196, 152, 82), (228, 190, 120)],
    'oak':       [(30, 18, 10), (50, 31, 17), (72, 46, 26), (96, 63, 36), (120, 82, 48), (146, 104, 64), (172, 130, 84)],
}
RUNE_GLOW = (112, 226, 255)
RUNE_CORE = (210, 250, 255)
VOID_GLOW = (178, 118, 255)
EMBER = (255, 112, 64)


def ramp(name, t):
    """t: array 0..1 -> uint8 colours from the named ramp (pixel-art quantised)."""
    r = np.array(RAMPS[name], float)
    idx = np.clip(np.round(np.asarray(t) * (len(r) - 1)), 0, len(r) - 1).astype(int)
    return r[idx].astype(np.uint8)


# ------------------------------------------------------------------ frame data
@dataclass
class Frame:
    rgba: np.ndarray        # 96x96 original pixels (my port of the importer)
    lab: np.ndarray         # 96x96 labels
    blade: tuple | None     # ((y_in, x_in), (y_out, x_out)) frame coords, inner = guard end
    grip: tuple | None
    actor: str


def cell_to_frame_point(cell, p):
    l, t, r, b = cell.bounds; x, y, w, h = cell.dest
    return (y + (p[0] - t + .5) * h / (b - t) - .5, x + (p[1] - l + .5) * w / (r - l) - .5)


def make_frame(cell, seg, actor):
    rgba = cell.to_frame(cell.rgba)
    lab4 = np.zeros(cell.rgba.shape, np.uint8)
    lab4[..., 0] = seg.labels; lab4[..., 3] = np.where(cell.keep, 255, 0)
    lab = cell.to_frame(lab4)[..., 0]
    lab[rgba[..., 3] == 0] = BG
    blade = None
    if seg.info.get('blade'):
        bi, bo = seg.info['blade']
        blade = (cell_to_frame_point(cell, bi), cell_to_frame_point(cell, bo))
    grip = cell_to_frame_point(cell, seg.grip) if seg.grip is not None else None
    return Frame(rgba, lab, blade, grip, actor)


# ------------------------------------------------------------------ shading helpers
def material_shade(rgb, mask, kinds, smooth=True):
    """Form shading 0..1 normalised per source material (steel, gold, dark cloth...), so a garment painted over
    plates, trims and cloth gets one consistent value range. A masked 3x3 median removes generator noise."""
    h, s, v = hsv(rgb)
    L = luma(rgb)
    shade = np.zeros(L.shape)
    for name, sel, lo, hi in kinds(h, s, v):
        m = mask & sel
        if m.sum() >= 18:   # local range of this material in this frame, softened towards the global range
            plo, phi = np.percentile(L[m], [6, 94])
            lo, hi = .5 * lo + .5 * plo, .5 * hi + .5 * max(phi, plo + .08)
        shade[m] = np.clip((L[m] - lo) / max(.05, hi - lo), 0, 1)
    if smooth and mask.any():
        stack = []; valid = []
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                stack.append(np.roll(np.roll(shade, dy, 0), dx, 1)); valid.append(np.roll(np.roll(mask, dy, 0), dx, 1))
        st = np.where(np.array(valid), np.array(stack), np.nan)
        med = np.nanmedian(st, axis=0)
        shade = np.where(mask, .35 * shade + .65 * np.nan_to_num(med), shade)
    return shade


def sword_kinds(h, s, v):
    steel = (s < .22) & (v > .30)
    gold = hue_in(h, 22, 58) & (s > .30) & (v > .30) & ~steel
    rest = ~steel & ~gold
    return [('steel', steel, .30, .92), ('gold', gold, .28, .80), ('cloth', rest, .05, .36)]


def mage_kinds(h, s, v):
    gold = hue_in(h, 18, 60) & (s > .28) & (v > .35)
    light = (v > .80) & (s < .35) & ~gold
    rest = ~gold & ~light
    return [('gold', gold, .30, .82), ('light', light, .70, 1.0), ('cloth', rest, .10, .70)]


def ranger_kinds(h, s, v):
    gold = hue_in(h, 22, 60) & (s > .38) & (v > .45)
    light = (v > .70) & (s < .30)
    rest = ~gold & ~light
    return [('gold', gold, .35, .85), ('light', light, .62, 1.0), ('leather', rest, .06, .55)]


KINDS = {'swordsmanv3': sword_kinds, 'magev3': mage_kinds, 'rangerv3': ranger_kinds}


def edge_dark(mask, alpha):
    """Region pixels on the silhouette or touching another part: drawn one step darker (keeps part separation)."""
    inner = erode(mask, 1, disk=False)
    return mask & ~inner


def outline_px(rgb):
    return luma(rgb) < .085


def paint(dst, mask, cols):
    dst[mask, :3] = cols
    dst[mask, 3] = 255


# ------------------------------------------------------------------ patterns (final pixel size)
def pat_mail(yy, xx):
    return np.where((xx + yy) % 2 == 0, .10, -.10) - np.where(yy % 3 == 0, .06, 0)


def pat_scale(yy, xx):
    sx = (xx + (yy // 2 % 2) * 2) % 4
    top = yy % 2 == 0
    return np.where(top & (sx == 1), .20, 0) + np.where(top & (sx == 2), .10, 0) + np.where(~top & ((sx == 0) | (sx == 3)), -.18, 0)


def pat_plate(yy, xx):
    return np.zeros(np.broadcast(yy, xx).shape)


def pat_leather(yy, xx):
    return ((xx * 7 + yy * 13) % 5 == 0) * -.06


# ------------------------------------------------------------------ armour pieces
ARMOR = {
    # slot tier: (ramp, pattern, contrast, glow)
    ('chest', 0): ('leather', pat_leather, .75, None),
    ('chest', 1): ('iron', pat_mail, .80, None),
    ('chest', 2): ('steel', pat_plate, 1.25, 'polish'),
    ('chest', 3): ('scale', pat_scale, 1.0, None),
    ('hands', 0): ('leather', pat_leather, .8, None),
    ('hands', 1): ('iron', pat_plate, .95, None),
    ('hands', 2): ('runesteel', pat_plate, 1.0, 'rune'),
    ('hands', 3): ('shadow', pat_scale, 1.0, 'claw'),
    ('feet', 0): ('leather', pat_leather, .8, None),
    ('feet', 1): ('oak', pat_leather, .85, 'toecap'),
    ('feet', 2): ('runesteel', pat_plate, 1.0, 'rune'),
    ('feet', 3): ('shadow', pat_plate, 1.05, 'void'),
}


def armor_layer(fr: Frame, region, slot, tier, kinds, light_bias=0.0):
    """Main + accent layer for one armour piece painted over `region`."""
    rgb = fr.rgba[..., :3]
    main = np.zeros((FRAME, FRAME, 4), np.uint8); acc = np.zeros((FRAME, FRAME, 4), np.uint8)
    if not region.any():
        return main, acc
    rname, pat, contrast, glow = ARMOR[(slot, tier)]
    sh = material_shade(rgb, region, kinds)
    yy, xx = np.mgrid[0:FRAME, 0:FRAME]
    t = np.clip(.5 + (sh - .5) * contrast + pat(yy, xx) + light_bias, 0, 1)
    t[edge_dark(region, fr.rgba[..., 3] > 0)] *= .55
    cols = ramp(rname, t)
    outl = outline_px(rgb) & region
    cols[outl] = RAMPS[rname][0]
    paint(main, region, cols[region])
    # trims (original gold pixels inside the region) -> accent layer (grey, tinted by rarity at runtime)
    h, s, v = hsv(rgb)
    trim = region & hue_in(h, 24, 56) & (s > .42) & (v > .55)
    trim &= ~erode(trim, 1, disk=False) | ~erode(region, 1, disk=False)   # thin lines, not blobs
    if trim.any():
        tv = np.clip(.55 + (luma(rgb)[trim] - .45) * 1.2, .35, 1.0)
        g = (tv * 255).astype(np.uint8)
        acc[trim] = np.stack([g, g, g, np.full_like(g, 255)], 1)
        main[trim, 3] = 255
        main[trim, :3] = ramp(rname, np.full(trim.sum(), .35))
    rows = np.nonzero(region.any(1))[0]
    if glow == 'rune' and len(rows):
        # one engraved, glowing band across the piece (cuff / shin), dashed every other pixel
        y0, y1 = rows.min(), rows.max(); band = int(round(y0 + (y1 - y0) * .45))
        rune = region & (yy == band) & ~edge_dark(region, None) & (xx % 2 == 0)
        main[rune, :3] = RUNE_GLOW
        main[region & (yy == band) & ~rune & ~edge_dark(region, None), :3] = RAMPS['runesteel'][1]
    if glow == 'void' and len(rows):
        # shadow steel: lit facets turn violet (light from the upper left), no outline noise
        lit = region & (t > .62) & ~edge_dark(region, None)
        main[lit, :3] = (np.array(VOID_GLOW) * .55 + main[lit, :3] * .45).astype(np.uint8)
    if glow == 'polish':   # polished plate: brighter, specular top-left facets
        spec = region & (sh > .72) & ~edge_dark(region, None)
        main[spec, :3] = RAMPS['steel'][6]
        main[region & ~spec & ~outl, :3] = ramp(rname, np.clip(t[region & ~spec & ~outl] + .12, 0, 1))
    if glow == 'toecap':
        rows = np.nonzero(region.any(1))[0]
        if len(rows):
            cap = region & (yy >= rows.max() - 1)
            main[cap, :3] = ramp('iron', np.clip(sh[cap] * .8 + .2, 0, 1))
    if glow == 'claw':
        # claw tips: extend the hand's outermost pixels one step outwards (only into empty space)
        base_alpha = fr.rgba[..., 3] > 0
        if fr.grip is not None:
            gy, gx = fr.grip
            far = region & ((yy - gy) ** 2 + (xx - gx) ** 2 <= 9)
            grow = dilate(far, 1) & ~base_alpha
            main[grow, :3] = RAMPS['bone'][5]; main[grow, 3] = 255
    return main, acc


# ------------------------------------------------------------------ helmets
def convex_fill(mask):
    ys, xs = np.nonzero(mask)
    if len(ys) < 3:
        return mask.copy()
    pts = sorted(set(zip(xs.tolist(), ys.tolist())))
    corners = []
    for x, y in pts:
        corners += [(x - .5, y - .5), (x + .5, y - .5), (x - .5, y + .5), (x + .5, y + .5)]
    corners = sorted(set(corners))

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lower, upper = [], []
    for p in corners:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    for p in reversed(corners):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    hull = lower[:-1] + upper[:-1]
    yy, xx = np.mgrid[0:mask.shape[0], 0:mask.shape[1]]
    inside = np.ones(mask.shape, bool)
    for i in range(len(hull)):
        a, b = hull[i], hull[(i + 1) % len(hull)]
        inside &= ((b[0] - a[0]) * (yy - a[1]) - (b[1] - a[1]) * (xx - a[0])) >= -1e-9
    return inside


HELMS = {0: 'leather', 1: 'iron', 2: 'runesteel', 3: 'scale'}


def helmet_layer(fr: Frame, tier, max_half_width=8.5, crown_frac=.62):
    """Fit a helmet dome over the hair down to the brow line; shade it as a sphere lit from the upper left."""
    main = np.zeros((FRAME, FRAME, 4), np.uint8); acc = np.zeros((FRAME, FRAME, 4), np.uint8)
    hair = fr.lab == HAIR
    if hair.sum() < 6:
        return main, acc
    rgb = fr.rgba[..., :3]
    h, s, v = hsv(rgb)
    ys, xs = np.nonzero(hair)
    top = ys.min(); hb = ys.max()
    rows = np.arange(FRAME)[:, None]
    # face skin only below the upper third of the hair mass (matte remnants above the hair are not skin)
    skin = (fr.lab == KEEP) & hue_in(h, 6, 34) & (s > .14) & (s < .58) & (v > .58) & (rows >= top + .3 * (hb - top)) & (rows <= hb + 3)
    skin &= dilate(hair, 2)
    if skin.sum() >= 3:
        brow = int(np.nonzero(skin)[0].min()) + 1
    else:
        brow = int(top + crown_frac * (hb - top + 1))
    brow = max(brow, int(top + .32 * (hb - top + 1)))
    above = hair & (rows <= brow)
    if above.sum() < 6:
        return main, acc
    ay, ax = np.nonzero(above)
    cx = float(np.median(ax)); cy = float(brow) + .5
    rx0 = max(3.0, min(max_half_width, (np.percentile(ax, 95) - np.percentile(ax, 5)) / 2 + 1.0))
    ry0 = max(3.0, cy - np.percentile(ay, 8))
    # smallest dome (fixed aspect) that still covers almost every hair pixel above the brow -> no spikes poke through
    k = np.percentile(np.sqrt(((ax - cx) / rx0) ** 2 + ((ay - cy) / ry0) ** 2), 97)
    k = float(np.clip(k, 1.0, 1.35))
    rx = min(max_half_width, rx0 * k); ry = min(ry0 * k, 1.05 * rx + 1.0)
    yy, xx = np.mgrid[0:FRAME, 0:FRAME]
    helm = (((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2 <= 1.0) & (yy <= brow)
    if helm.sum() < 6:
        return main, acc
    hy, hx = np.nonzero(helm)
    cy = hy.max()
    nx = (xx - cx) / rx; ny = (yy - cy) / ry
    nz = np.sqrt(np.clip(1 - nx ** 2 - ny ** 2, 0, 1))
    light = np.array([-.55, -.6, .58]); light /= np.linalg.norm(light)
    shade = np.clip(.18 + .9 * (nx * light[0] + ny * light[1] + nz * light[2]), 0, 1)
    rname = HELMS[tier]
    rim = helm & (yy >= cy - 0)
    edge = helm & ~erode(helm, 1, disk=False)
    t = shade.copy()
    if tier == 3:
        t = np.clip(t + pat_scale(yy, xx) * .9, 0, 1)
    if tier == 0:
        t = .15 + t * .7
    t[edge] *= .45
    t[rim] = np.minimum(t[rim], .42)
    cols = ramp(rname, t)
    paint(main, helm, cols[helm])
    # details
    if tier == 0:   # stitched centre seam
        seam = helm & (np.abs(xx - np.round(cx)) < .6) & (yy < cy - 1) & ~edge
        main[seam, :3] = RAMPS['leather'][1]
    if tier in (1, 2):   # rivets on the rim band -> accent
        riv = rim & ((xx % 2) == 0) & ~edge
        acc[riv] = (215, 215, 215, 255)
    if tier == 2:   # forehead rune
        ry0 = cy - 2
        rune = helm & (yy >= ry0 - 1) & (yy <= ry0) & (np.abs(xx - np.round(cx)) <= .6)
        main[rune, :3] = RUNE_GLOW
        top_glint = helm & (yy == hy.min() + 1) & (np.abs(xx - (cx - rx * .35)) < 1)
        main[top_glint, :3] = RUNE_CORE
    if tier == 3:   # crest ridge + horn tips (extend upwards into empty space only)
        base_alpha = fr.rgba[..., 3] > 0
        ridge = (np.abs(xx - np.round(cx)) < .6) & (yy < cy - 1) & helm
        main[ridge, :3] = RAMPS['scale'][6]
        acc[ridge & (yy % 2 == 0)] = (230, 230, 230, 255)
        crest_top = (np.abs(xx - np.round(cx)) < .6) & (yy == hy.min() - 1) & ~helm
        for m, col in ((crest_top, RAMPS['scale'][4]),):
            main[m, :3] = col; main[m, 3] = 255
        for sgn in (-1, 1):
            hxn = int(round(cx + sgn * (rx - .5)))
            hyn = int(hy.min() + ry * .35)
            for k in range(2):
                y0, x0 = hyn - k, hxn + sgn * (k + 1)
                if 0 <= y0 < FRAME and 0 <= x0 < FRAME and not helm[y0, x0]:
                    main[y0, x0] = (*RAMPS['bone'][4 - k], 255)
    return main, acc


# ------------------------------------------------------------------ swords
def blade_coords(fr: Frame):
    if fr.blade is None:
        return None
    (yi, xi), (yo, xo) = fr.blade
    d = np.array([yo - yi, xo - xi]); L = np.linalg.norm(d)
    if L < 3:
        return None
    u = d / L
    yy, xx = np.mgrid[0:FRAME, 0:FRAME]
    rel = np.stack([yy - yi, xx - xi], -1)
    along = rel @ u; across = rel @ np.array([-u[1], u[0]])
    return along, across, L, u


SWORDS = {0: 'iron', 1: 'steel', 2: 'runesteel', 3: 'bone'}


def sword_layer(fr: Frame, tier):
    """tier None = start weapon (original pixels). Tiers 0..3 = Kurzschwert, Langschwert, Runenklinge, Drachenzahn."""
    main = np.zeros((FRAME, FRAME, 4), np.uint8); acc = np.zeros((FRAME, FRAME, 4), np.uint8)
    W = fr.lab == WEAPON
    if not W.any():
        return main, acc
    rgb = fr.rgba[..., :3]
    if tier is None:
        main[W] = fr.rgba[W]
        return main, acc
    h, s, v = hsv(rgb)
    bc = blade_coords(fr)
    steel = W & (s < .24)
    guard = W & ~steel
    if bc is not None:
        along, across, L, u = bc
        guard |= W & (along < 2.2)
        blade = W & ~guard
    else:
        along = across = None; L = 0; blade = W & ~guard
    sh = material_shade(rgb, W, sword_kinds)
    yy, xx = np.mgrid[0:FRAME, 0:FRAME]
    keep_blade = blade.copy()
    if tier == 0 and bc is not None:          # short sword: cut at 62 %, taper the new tip
        keep_blade &= along <= L * .62
        tipzone = keep_blade & (along > L * .62 - 1.5) & (np.abs(across) > .7)
        keep_blade &= ~tipzone
    rname = SWORDS[tier]
    t = np.clip(.5 + (sh - .5) * (1.25 if tier == 1 else 1.0), 0, 1)
    if tier == 2 and bc is not None:
        t = t * .85
    cols = ramp(rname, t)
    paint(main, keep_blade, cols[keep_blade])
    if tier == 2 and bc is not None:          # rune line along the fuller + glowing edge glint
        rune = keep_blade & (np.abs(across) < .6) & (np.round(along) % 3 == 0) & (along > 3)
        main[rune, :3] = RUNE_GLOW
    if tier == 3 and bc is not None:          # dragon fang: ember edge on one side, longer, serrated
        edge = keep_blade & (across > .4)
        main[edge, :3] = np.array(EMBER, np.uint8)
        serr = edge & (np.round(along) % 3 == 0)
        main[serr, :3] = RAMPS['bone'][2]
        base_alpha = fr.rgba[..., 3] > 0
        ext = (along > L) & (along <= L + 2.5) & (np.abs(across) < .9 - (along - L) * .25) & ~base_alpha
        main[ext, :3] = RAMPS['bone'][5]; main[ext, 3] = 255
    # guard / grip: dark grip, guard as accent (rarity tint)
    gcol = ramp('bronze' if tier in (0, 3) else 'iron', np.clip(sh, 0, 1))
    paint(main, guard, gcol[guard])
    gv = (np.clip(.45 + sh[guard] * .6, .3, 1) * 255).astype(np.uint8)
    acc[guard] = np.stack([gv, gv, gv, np.full_like(gv, 255)], 1)
    return main, acc


# ------------------------------------------------------------------ base model
def inpaint_nearest(rgba, holes, known):
    """Fill `holes` with the colour of the nearest known pixel (pixel-art friendly, no blur)."""
    out = rgba.copy()
    filled = known.copy()
    todo = holes & ~known
    for _ in range(12):
        if not todo.any():
            break
        for dy, dx in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            src = np.roll(np.roll(filled, dy, 0), dx, 1)
            take = todo & src
            if take.any():
                ys, xs = np.nonzero(take)
                out[ys, xs] = out[(ys - dy) % FRAME, (xs - dx) % FRAME]
                filled[ys, xs] = True; todo[ys, xs] = False
    return out, filled


BASE_CLOTHES = {
    'swordsmanv3': {CHEST: ('gambeson', .70), HANDS: ('wraps', .75), LEGS: ('trousers', .70), FEET: ('shoes', .80)},
    'magev3': {CHEST: ('detrim', 0), HANDS: ('detrim', 0), LEGS: ('detrim', 0), FEET: ('shoes', .80)},
    'rangerv3': {CHEST: ('linen', .55), HANDS: ('linen', .60), FEET: ('shoes', .80)},
}
# chest armour also covers the hips/thighs (mail skirt, tassets) from this tier on; None = never
CHEST_COVERS_LEGS = {'swordsmanv3': 1, 'magev3': None, 'rangerv3': None}


def base_layer(fr: Frame, kinds):
    """Base model: halo removed, weapon removed (inpainted where it covered the body), armour regions re-dressed
    in plain class clothing with the original form shading."""
    out = fr.rgba.copy()
    lab = fr.lab.copy()
    out[lab == HALO] = 0; lab[lab == HALO] = BG
    W = lab == WEAPON
    body = (out[..., 3] > 0) & ~W
    inside = W & fill_holes(close(body, 1))
    out[W & ~inside] = 0
    lab_rgba = np.zeros((FRAME, FRAME, 4), np.uint8); lab_rgba[..., 0] = lab; lab_rgba[..., 3] = 255
    out, _ = inpaint_nearest(out, inside, body)
    lab2, _ = inpaint_nearest(lab_rgba, inside, body)
    lab = np.where(W, lab2[..., 0], lab)
    lab[W & ~inside] = BG
    # thin remnants (1 px wide outline strokes) next to the removed weapon -> gone
    alive0 = out[..., 3] > 0
    near = dilate(W & ~inside, 2) & alive0 & ~W
    thin = near & ~dilate(erode(alive0, 1, disk=False), 1, disk=False)
    out[thin] = 0; lab[thin] = BG
    # specks left around a removed blade (outline fragments) -> gone
    from morph import components
    alive = out[..., 3] > 0
    comps = components(alive)
    for ys, xs in comps[1:]:
        if len(ys) < 12:
            out[ys, xs] = 0; lab[ys, xs] = BG
    rgb = out[..., :3]
    yy, xx = np.mgrid[0:FRAME, 0:FRAME]
    for reg, (rname, contrast) in BASE_CLOTHES[fr.actor].items():
        m = lab == reg
        if not m.any():
            continue
        if rname == 'detrim':   # original garment, gold ornaments replaced by the surrounding cloth colours
            hh, ss, vv = hsv(rgb)
            gold = m & hue_in(hh, 18, 60) & (ss > .26) & (vv > .33)
            if gold.any():
                filled, _ = inpaint_nearest(out, gold, m & ~gold)
                out[gold] = filled[gold]
            continue
        sh = material_shade(rgb, m, kinds)
        t = np.clip(.45 + (sh - .5) * contrast, 0, 1)
        t[edge_dark(m, None)] *= .6
        cols = ramp(rname, t)
        cols[outline_px(rgb) & m] = RAMPS[rname][0]
        if reg == CHEST and rname == 'gambeson':   # quilting lines on the gambeson
            q = m & (((xx + yy) % 4 == 0) | ((xx - yy) % 4 == 0)) & ~edge_dark(m, None)
            cols[q] = ramp(rname, np.clip(t[q] - .16, 0, 1))
        paint(out, m, cols[m])
    return out, lab


# ------------------------------------------------------------------ staffs (mage)
STAFFS = {0: ('oak', 'amber', 'bronze'), 1: ('silver', 'ice', 'silver'), 2: ('gold', 'gold', 'gold'), 3: ('void', 'void', 'void')}


def staff_layer(fr: Frame, tier):
    """Eichenstab / Kristallstab / Sternenzepter / Leerenfokus: shaft + crystal + ornament frame (accent)."""
    main = np.zeros((FRAME, FRAME, 4), np.uint8); acc = np.zeros((FRAME, FRAME, 4), np.uint8)
    W = fr.lab == WEAPON
    if not W.any():
        return main, acc
    if tier is None:
        main[W] = fr.rgba[W]
        return main, acc
    rgb = fr.rgba[..., :3]; h, s, v = hsv(rgb)
    yy, xx = np.mgrid[0:FRAME, 0:FRAME]
    head = np.zeros_like(W)
    if fr.blade is not None:
        (yf, xf), (yh, xh) = fr.blade           # foot end, head end
        head = W & ((yy - yh) ** 2 + (xx - xh) ** 2 <= 7.5 ** 2)
    crystal = W & head & (((hue_in(h, 200, 320) & (s > .30)) | (v > .88)) & ~(hue_in(h, 18, 60) & (s > .3)))
    ornament = W & head & ~crystal
    shaft = W & ~head
    sh = material_shade(rgb, W, mage_kinds)
    shaft_r, cry_r, orn_r = STAFFS[tier]
    paint(main, shaft, ramp(shaft_r, np.clip(.25 + sh[shaft] * .65, 0, 1)))
    paint(main, ornament, ramp(orn_r, np.clip(.2 + sh[ornament] * .8, 0, 1)))
    paint(main, crystal, ramp(cry_r, np.clip(.35 + sh[crystal] * .75, 0, 1)))
    if tier == 2 and crystal.any():   # star sparkle in the crystal centre
        cy, cx = np.argwhere(crystal).mean(0).round().astype(int)
        for dy, dx in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
            if 0 <= cy + dy < FRAME and 0 <= cx + dx < FRAME and W[cy + dy, cx + dx]:
                main[cy + dy, cx + dx, :3] = (255, 250, 220) if dy == 0 and dx == 0 else (255, 226, 140)
    if tier == 3 and crystal.any():   # dark void core
        cy, cx = np.argwhere(crystal).mean(0).round().astype(int)
        core = crystal & ((yy - cy) ** 2 + (xx - cx) ** 2 <= 1.5)
        main[core, :3] = (8, 2, 14)
    gv = (np.clip(.45 + sh[ornament] * .6, .3, 1) * 255).astype(np.uint8)
    acc[ornament] = np.stack([gv, gv, gv, np.full_like(gv, 255)], 1)
    return main, acc


# ------------------------------------------------------------------ bows (ranger)
BOWS = {0: ('oak', (236, 230, 214)), 1: ('darkwood', (230, 224, 206)), 2: ('moon', (190, 230, 255)), 3: ('storm', (150, 255, 236))}


def bow_layer(fr: Frame, tier):
    """Jagdbogen / Kompositbogen / Mondbogen / Sturmbogen: limbs re-materialised, string recoloured, grip = accent."""
    main = np.zeros((FRAME, FRAME, 4), np.uint8); acc = np.zeros((FRAME, FRAME, 4), np.uint8)
    W = fr.lab == WEAPON
    if not W.any():
        return main, acc
    if tier is None:
        main[W] = fr.rgba[W]
        return main, acc
    rgb = fr.rgba[..., :3]; h, s, v = hsv(rgb)
    yy, xx = np.mgrid[0:FRAME, 0:FRAME]
    string = W & (s < .30) & (v > .62)
    limb = W & ~string
    sh = material_shade(rgb, W, ranger_kinds)
    rname, scol = BOWS[tier]
    paint(main, limb, ramp(rname, np.clip(.15 + sh[limb] * .85, 0, 1)))
    main[string, :3] = scol; main[string, 3] = 255
    grip = np.zeros_like(W)
    if fr.grip is not None:
        gy, gx = fr.grip
        grip = limb & ((yy - gy) ** 2 + (xx - gx) ** 2 <= 4)
    if tier == 1 and fr.blade is not None:   # horn tips at both limb ends
        for (ey, ex) in fr.blade:
            tip = limb & ((yy - ey) ** 2 + (xx - ex) ** 2 <= 4)
            main[tip, :3] = RAMPS['bone'][4]
    if tier == 3:   # storm sparks along the limbs
        spark = limb & ((xx * 5 + yy * 3) % 7 == 0)
        main[spark, :3] = (250, 240, 120)
    gv = (np.clip(.45 + sh[grip] * .6, .3, 1) * 255).astype(np.uint8)
    acc[grip] = np.stack([gv, gv, gv, np.full_like(gv, 255)], 1)
    return main, acc


WEAPON_LAYER = {'swordsmanv3': sword_layer, 'magev3': staff_layer, 'rangerv3': bow_layer}
