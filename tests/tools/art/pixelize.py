"""Shared pixel-art helpers for baking source art at its in-game size (Pixeldichte 1:1, render_pipeline).

- premul_down: area-average downscale with premultiplied alpha (no light or dark fringes), hard alpha afterwards.
- sharpen: unsharp mask on colour, restores the local contrast the area filter removes.
- palette_of / quantize: one shared, fixed palette (median cut) per character or boss: fewer, cleaner colours.
- outline: dark silhouette edge; only where the original art had transparency (cut edges stay open).
- rotsprite: RotSprite-style rotation (3x Scale2x = 8x, nearest rotation, block-centre sampling): rotated pixel art
  without smeared or doubled pixels; used to pre-render rotation frames instead of rotating at runtime.
"""
from __future__ import annotations

import numpy as np
from PIL import Image, ImageFilter


def premul_down(im: Image.Image, scale: float) -> Image.Image:
    a = np.asarray(im.convert('RGBA')).astype(np.float64) / 255
    rgb = a[..., :3] * a[..., 3:4]
    w, h = max(1, round(im.width * scale)), max(1, round(im.height * scale))
    pr = Image.fromarray((np.dstack([rgb, a[..., 3:4]]) * 255).round().astype(np.uint8), 'RGBA').resize((w, h), Image.BOX)
    b = np.asarray(pr).astype(np.float64) / 255
    al = b[..., 3:4]
    col = np.where(al > 0, b[..., :3] / np.maximum(al, 1e-6), 0)
    out = np.zeros((h, w, 4), np.uint8)
    out[..., :3] = np.clip(col * 255, 0, 255)
    out[..., 3] = np.where(b[..., 3] >= .5, 255, 0)
    return Image.fromarray(out, 'RGBA')


def sharpen(im: Image.Image, amount: float = .6, radius: float = .8) -> Image.Image:
    a = np.asarray(im.convert('RGBA')).copy()
    blur = np.asarray(im.convert('RGB').filter(ImageFilter.GaussianBlur(radius))).astype(np.float64)
    c = a[..., :3].astype(np.float64)
    a[..., :3] = np.clip(c + amount * (c - blur), 0, 255).astype(np.uint8)
    return Image.fromarray(a, 'RGBA')


def palette_of(images, colors: int = 48) -> Image.Image:
    px = np.concatenate([np.asarray(i.convert('RGBA'))[np.asarray(i.convert('RGBA'))[..., 3] > 0][:, :3] for i in images])
    n = int(np.ceil(np.sqrt(len(px))))
    sq = np.zeros((n * n, 3), np.uint8)
    sq[:len(px)] = px
    sq[len(px):] = px[0]
    return Image.fromarray(sq.reshape(n, n, 3), 'RGB').quantize(colors=colors, method=Image.MEDIANCUT, dither=Image.NONE)


def quantize(im: Image.Image, pal: Image.Image) -> Image.Image:
    a = np.asarray(im.convert('RGBA'))
    q = np.asarray(im.convert('RGB').quantize(palette=pal, dither=Image.NONE).convert('RGB'))
    out = a.copy()
    out[..., :3] = q
    out[a[..., 3] == 0] = 0
    return Image.fromarray(out, 'RGBA')


def _neighbour_transparent(alpha: np.ndarray) -> np.ndarray:
    pad = np.pad(alpha, 1)
    return ~(pad[:-2, 1:-1] & pad[2:, 1:-1] & pad[1:-1, :-2] & pad[1:-1, 2:])


def outline(im: Image.Image, original_alpha: np.ndarray | None = None, darken: float = .38) -> Image.Image:
    """Silhouette pixels take a dark tone of themselves. With original_alpha (same size, bool), only edges that border
    transparency of the original art count, so the open edge of a cut-out part is not outlined."""
    a = np.asarray(im.convert('RGBA')).copy()
    al = a[..., 3] > 0
    edge = al & _neighbour_transparent(al)
    if original_alpha is not None:
        edge &= _neighbour_transparent(original_alpha)
    a[edge, :3] = (a[edge, :3].astype(np.float64) * darken).astype(np.uint8)
    return Image.fromarray(a, 'RGBA')


def scale2x(a: np.ndarray) -> np.ndarray:
    h, w = a.shape[:2]
    p = np.pad(a, ((1, 1), (1, 1), (0, 0)), mode='edge')
    B, D, F, H = p[:-2, 1:-1], p[1:-1, :-2], p[1:-1, 2:], p[2:, 1:-1]

    def eq(x, y):
        return np.all(x == y, axis=-1)
    c = ~eq(B, H) & ~eq(D, F)
    out = np.zeros((h * 2, w * 2, a.shape[2]), a.dtype)
    out[0::2, 0::2] = np.where((c & eq(D, B))[..., None], D, a)
    out[0::2, 1::2] = np.where((c & eq(B, F))[..., None], F, a)
    out[1::2, 0::2] = np.where((c & eq(D, H))[..., None], D, a)
    out[1::2, 1::2] = np.where((c & eq(H, F))[..., None], F, a)
    return out


def rotsprite(im: Image.Image, angle: float, pivot: tuple[float, float] | None = None):
    """Rotate counter-clockwise by angle degrees. Returns (image, pivot in the new image)."""
    a = np.asarray(im.convert('RGBA'))
    for _ in range(3):
        a = scale2x(a)
    big = Image.fromarray(a, 'RGBA')
    px, py = pivot if pivot else (im.width / 2, im.height / 2)
    rot = big.rotate(angle, resample=Image.NEAREST, expand=True)
    cx, cy = big.width / 2, big.height / 2
    t = np.deg2rad(angle)
    dx, dy = px * 8 - cx, py * 8 - cy
    nx = rot.width / 2 + dx * np.cos(t) + dy * np.sin(t)
    ny = rot.height / 2 - dx * np.sin(t) + dy * np.cos(t)
    r = np.asarray(rot)
    return Image.fromarray(np.ascontiguousarray(r[4::8, 4::8]), 'RGBA'), (nx / 8, ny / 8)


def centred_rotations(im: Image.Image, pivot, steps: int, base_angle: float = 0.0):
    """steps rotation frames on one square canvas with the pivot in its centre (one sprite origin fits all frames).
    Frame k shows the source direction base_angle turned to k*360/steps. Returns (frames, canvas size)."""
    rots = [rotsprite(im, k * 360 / steps - base_angle, pivot) for k in range(steps)]
    half = 2 + int(np.ceil(max(max(abs(p[0]), abs(p[1]), abs(f.width - p[0]), abs(f.height - p[1])) for f, p in rots)))
    size = half * 2
    out = []
    for f, p in rots:
        c = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        c.alpha_composite(f, (int(round(half - p[0])), int(round(half - p[1]))))
        out.append(c)
    return out, size
