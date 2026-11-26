"""Exact Python port of the character atlas import (tests/tools/prepare_swordsman_art.ps1 and
prepare_class_characters.ps1): grid/row cutting, alpha cutoff, largest 8-connected component, bounds and the
GDI+ nearest-neighbour placement into FRAME x FRAME frames with foot origin (OX, OY).
Since 25.11.2026 the frames are drawn 1:1 in the world (pixel density 1 art px = 1 world unit): the former 96x96
frames were drawn with player_scale 1.65, so the factor is scaled by DENSITY and the frame grows to 160.

The point of the port: any additional layer painted in atlas space (base clothing, equipment, weapon) can be
cut with the ORIGINAL cell's keep-mask/bounds and scaled with the identical pixel mapping, so every layer lands
on exactly the same 96x96 pixels as the body it belongs to.
"""
from __future__ import annotations

import json
from collections import deque
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
import sys as _sys_ap; _sys_ap.path.insert(0, str(ROOT / 'tests' / 'tools' / 'assets')); import art_paths as AP  # noqa: E402
ART = AP.ART
DIRS = ['right', 'up_right', 'up', 'up_left', 'left', 'down_left', 'down', 'down_right']
SOURCES = ['walk', 'combat', 'mobility', 'reaction']

# action -> atlas columns, per actor and source (copied from the two import scripts)
SETS = {
    'swordsmanv3': {
        'walk': {'walk': [0, 1, 2, 3, 4, 5, 6, 7], 'run': [0, 1, 2, 3, 4, 5, 6, 7]},
        'combat': {'idle': [0], 'turn': [0], 'attack1': [1, 2], 'attack2': [3, 4], 'attack3': [5, 6, 7]},
        'mobility': {'dodge': [0, 1, 2, 3], 'slide': [0, 1, 2, 3], 'jump': [4, 5, 6], 'fall': [5, 6], 'dive': [6], 'landing': [7]},
        'reaction': {'hurt': [0, 1, 2], 'death': [3, 4, 5, 6, 7]},
    },
    'magev3': {
        'walk': {'walk': [0, 1, 2, 3, 4, 5, 6, 7], 'run': [0, 1, 2, 3, 4, 5, 6, 7]},
        'combat': {'idle': [0], 'turn': [0], 'attack1': [0, 1, 2], 'attack2': [3, 4, 5], 'attack3': [0, 5, 7], 'attack4': [0, 6, 7]},
        'mobility': {'jump': [0, 1, 2], 'fall': [2, 3], 'landing': [4, 0], 'dodge': [5, 6, 7], 'slide': [5, 6, 7], 'dive': [3, 5, 6]},
        'reaction': {'hurt': [0, 1, 2], 'death': [3, 4, 5, 6, 7]},
    },
    'rangerv3': {
        'walk': {'walk': [0, 1, 2, 3, 4, 5, 6, 7], 'run': [0, 1, 2, 3, 4, 5, 6, 7]},
        'combat': {'idle': [0], 'turn': [0], 'attack1': [1, 2, 3, 4], 'attack2': [2, 3, 4, 5], 'attack3': [0, 6, 7]},
        'mobility': {'jump': [0, 1, 2], 'fall': [2, 3], 'landing': [4, 0], 'dodge': [5, 6, 7], 'slide': [5, 6, 7], 'dive': [3, 5, 6]},
        'reaction': {'hurt': [0, 1, 2], 'death': [3, 4, 5, 6, 7]},
    },
}


# Frame spec (density 1:1 in the world). Old spec: 96x96, origin (48,88), drawn at 1.65.
DENSITY = 1.65
FRAME = 160
OX, OY = 80, 145


def cs_round(v: float) -> int:
    """C# Math.Round(double): banker's rounding."""
    return int(np.round(v))  # numpy rounds half to even like .NET


def source_path(actor: str, source: str) -> Path:
    if actor == 'swordsmanv3':
        return AP.SWORDSMAN_V3 / 'sources' / f'{source}.png'
    return AP.CLASS_OVERHAUL / 'sources' / f'{actor[:-2]}_{source}.png'


def base_neutral_path(actor: str, source: str) -> Path:
    """Delivered slim base clothing atlas for this actor and source (same grid, poses and feet as source_path), see
    docs/Design/Assets & Pipeline.md 7.1. Cut with the same Atlas mapping, it lands pixel-aligned in the 160x160 frames,
    so equipment layers and attach points keep fitting. The file may not exist yet."""
    name = {'swordsmanv3': 'swordsman', 'magev3': 'mage', 'rangerv3': 'ranger'}[actor]
    return AP.CHARACTER_BASE_NEUTRAL / f'{name}_{source}_base.png'


def load_rgba(p: Path) -> np.ndarray:
    return np.asarray(Image.open(p).convert('RGBA')).copy()


def row_cuts(atlas: np.ndarray, rows: int) -> list[int]:
    """ClassAtlas.Prepare: row cuts at low-density scanlines near the nominal grid lines."""
    h = atlas.shape[0]
    rgb = atlas[..., :3].astype(int)
    chroma = rgb.max(2) - rgb.min(2)
    density = ((atlas[..., 3] >= 180) & (chroma > 30)).sum(1)
    cuts = [0] * (rows + 1); cuts[rows] = h
    for i in range(1, rows):
        centre = cs_round(i * h / rows); radius = int(h / rows * .43)
        lo = max(cuts[i - 1] + 20, centre - radius); hi = min(h - 2, centre + radius)
        mn = min(density[p] for p in range(lo, hi + 1))
        best, best_score = centre, 1 << 62
        for p in range(lo, hi + 1):
            score = density[p] * 30 + abs(p - centre)
            if density[p] <= mn + 3 and score < best_score:
                best, best_score = p, score
        cuts[i] = best
    return cuts


def largest_component(mask: np.ndarray) -> np.ndarray:
    """8-connected largest component; ties keep the first found in row-major scan order (like the C# loop)."""
    h, w = mask.shape
    seen = np.zeros_like(mask, bool)
    best = None; best_n = 0
    ys, xs = np.nonzero(mask)
    for y0, x0 in zip(ys, xs):  # nonzero is row-major, same visiting order as the C# j/i loops
        if seen[y0, x0]:
            continue
        comp = []; q = deque([(y0, x0)]); seen[y0, x0] = True
        while q:
            y, x = q.popleft(); comp.append((y, x))
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    ny, nx = y + dy, x + dx
                    if 0 <= ny < h and 0 <= nx < w and not seen[ny, nx] and mask[ny, nx]:
                        seen[ny, nx] = True; q.append((ny, nx))
        if len(comp) > best_n:
            best, best_n = comp, len(comp)
    keep = np.zeros_like(mask, bool)
    if best:
        yy, xx = zip(*best); keep[list(yy), list(xx)] = True
    return keep


@dataclass
class Cell:
    actor: str
    source: str
    column: int
    row: int
    rect: tuple            # x0, y0, x1, y1 in atlas pixels
    keep: np.ndarray       # bool mask in cell space (after alpha cut + largest component)
    bounds: tuple          # l, t, r, b (exclusive) in cell space
    factor: float
    dest: tuple            # x, y, w, h in the 96x96 frame
    rgba: np.ndarray = field(repr=False, default=None)  # opaque cell pixels (alpha forced 255 where keep)

    def to_frame(self, layer: np.ndarray, keep: np.ndarray | None = None) -> np.ndarray:
        """Map a cell-space RGBA layer into the 96x96 frame exactly like GDI+ DrawImage(NearestNeighbor, Half)."""
        l, t, r, b = self.bounds
        x, y, w, h = self.dest
        out = np.zeros((FRAME, FRAME, 4), np.uint8)
        sx = l + np.floor((np.arange(w) + .5) * (r - l) / w).astype(int)
        sy = t + np.floor((np.arange(h) + .5) * (b - t) / h).astype(int)
        src = layer[np.ix_(sy, sx)]
        if keep is not None:
            src = src * keep[np.ix_(sy, sx)][..., None]
        out[y:y + h, x:x + w] = src
        return out


class Atlas:
    """All 64 (72 for ranger combat) cells of one actor/source."""

    def __init__(self, actor: str, source: str):
        self.actor, self.source = actor, source
        self.img = load_rgba(source_path(actor, source))
        H, W = self.img.shape[:2]
        if actor == 'swordsmanv3':
            self.alpha_cut = 128
            self.rows = 8
            self.cuts = [cs_round(r * H / 8.0) for r in range(9)]
        else:
            self.alpha_cut = 180
            self.rows = 9 if (actor == 'rangerv3' and source == 'combat') else 8
            self.cuts = row_cuts(self.img, self.rows)
        self.cols = [cs_round(c * W / 8.0) for c in range(9)]
        self.factor = self._factor()

    def raw(self, column, row):
        x0, x1 = self.cols[column], self.cols[column + 1]
        y0, y1 = self.cuts[row], self.cuts[row + 1]
        return (x0, y0, x1, y1), self.img[y0:y1, x0:x1]

    def _keep(self, column, row):
        rect, px = self.raw(column, row)
        keep = largest_component(px[..., 3] >= self.alpha_cut)
        ys, xs = np.nonzero(keep)
        bounds = (int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1)
        return rect, px, keep, bounds

    def _factor(self):
        if self.actor == 'swordsmanv3':
            ref_col = {'walk': 0, 'combat': 0, 'mobility': 3, 'reaction': 2}[self.source]
            _, _, _, b = self._keep(ref_col, 6)
            return 52.0 / (b[3] - b[1])
        ext = json.loads((AP.CLASS_OVERHAUL / 'character-extraction.json').read_text(encoding='utf-8-sig'))
        e = next(e for e in ext if e['actor'] == self.actor and e['source'] == self.source)
        return float(e['scale'])

    def cell(self, column, row) -> Cell:
        rect, px, keep, bounds = self._keep(column, row)
        l, t, r, b = bounds
        f = self.factor * DENSITY
        w, h = cs_round((r - l) * f), cs_round((b - t) * f)
        cw = rect[2] - rect[0]
        if self.actor == 'swordsmanv3':
            x = OX + cs_round((l - cw / 2.0) * f)
        else:
            x = OX - int(w / 2)
        y = OY - h
        rgba = px.copy(); rgba[..., 3] = np.where(keep, 255, 0); rgba[~keep] = 0
        return Cell(self.actor, self.source, column, row, rect, keep, bounds, f, (x, y, w, h), rgba)


def frame_plan(actor: str):
    """[(sprite_name, frame_index, source, column, row)] in the order the importer wrote them."""
    out = []
    for source in SOURCES:
        for row, d in enumerate(DIRS):
            for action, cols in SETS[actor][source].items():
                for i, col in enumerate(cols):
                    out.append((f'spr_fg_{actor}_{action}_{d}', i, source, col, row))
    return out
