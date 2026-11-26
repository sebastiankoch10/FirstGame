"""Acceptance check for delivered neutral base clothing atlases (docs/Design/Assets & Pipeline.md 7.1).

  python tests/tools/characters/check_base_neutral.py

For every class (swordsmanv3, magev3, rangerv3) and atlas (walk, combat, mobility, reaction) whose base file exists in
FirstGame_ArtPack/characters/base_neutral/, compared with the original atlas cell by cell (8 x 8 grid):
  1. same image size as the original atlas;
  2. readable for the importer: the figure is what atlas.py keeps (alpha >= 128, like the originals, which are soft
     AI atlases with background alpha around 10-20), so every check below uses that mask;
  3. same feet: the lowest opaque row of each cell lies within 2 px of the original's;
  4. slimmer, not larger: at least 95 % of the opaque base pixels lie inside the original silhouette (grown by 2 px);
  5. not empty: the base covers at least 45 % of the original's opaque area in each cell.
Prints PASS / FAIL per file, NOT RUN when nothing is delivered. Technical acceptance only; the artistic
acceptance stays with the user (docs/Design/Qualitätsstandard.md).
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
from atlas import SOURCES, base_neutral_path, source_path  # noqa: E402


def grow(m: np.ndarray, r: int) -> np.ndarray:
    out = m.copy()
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            out |= np.roll(np.roll(m, dy, 0), dx, 1)
    return out


def check(actor: str, source: str) -> tuple[str, list[str]]:
    base_p, orig_p = base_neutral_path(actor, source), source_path(actor, source)
    if not base_p.is_file():
        return 'NOT RUN', []
    base = np.asarray(Image.open(base_p).convert('RGBA'))
    orig = np.asarray(Image.open(orig_p).convert('RGBA'))
    errs = []
    if base.shape != orig.shape:
        return 'FAIL', [f'Groesse {base.shape[1]}x{base.shape[0]} statt {orig.shape[1]}x{orig.shape[0]}']
    a = base[..., 3]
    bm, om = a >= 128, orig[..., 3] >= 128   # the importer's alpha cut (atlas.Atlas.alpha_cut)
    h, w = a.shape
    for row in range(8):
        for col in range(8):
            y0, y1, x0, x1 = row * h // 8, (row + 1) * h // 8, col * w // 8, (col + 1) * w // 8
            b, o = bm[y0:y1, x0:x1], om[y0:y1, x0:x1]
            if not o.any():
                continue
            if not b.any():
                errs.append(f'Zelle {row},{col} leer'); continue
            if abs(np.nonzero(b.any(1))[0].max() - np.nonzero(o.any(1))[0].max()) > 2:
                errs.append(f'Zelle {row},{col}: Fusspunkt weicht ab')
            inside = (b & grow(o, 2)).sum() / b.sum()
            if inside < .95:
                errs.append(f'Zelle {row},{col}: {100 * (1 - inside):.0f} % ausserhalb der Original-Silhouette')
            if b.sum() < .45 * o.sum():
                errs.append(f'Zelle {row},{col}: deckt nur {100 * b.sum() / o.sum():.0f} % der Figur')
    return ('FAIL' if errs else 'PASS'), errs


def main() -> int:
    results = []
    for actor in ('swordsmanv3', 'magev3', 'rangerv3'):
        for source in SOURCES:
            status, errs = check(actor, source)
            results.append(status)
            if status != 'NOT RUN':
                print(f'{status} {actor} {source}' + (': ' + '; '.join(errs[:6]) if errs else ''))
    if all(s == 'NOT RUN' for s in results):
        print('NOT RUN: keine Lieferung in FirstGame_ArtPack/characters/base_neutral/')
        return 0
    return 1 if 'FAIL' in results else 0


if __name__ == '__main__':
    raise SystemExit(main())
