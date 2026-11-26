"""Acceptance check for delivered base models without equipment (docs/Design/Assets & Pipeline.md 7.1).

  python tests/tools/characters/check_base_neutral.py

For every class (swordsmanv3, magev3, rangerv3) and atlas (walk, combat, mobility, reaction) whose base file exists in
FirstGame_ArtPack/characters/base_neutral/, compared with the original atlas cell by cell (8 x 8 grid):
  1. same image size as the original atlas;
  2. readable for the importer: cells and alpha cut are the importer's own for the ORIGINAL atlas (atlas.Atlas:
     swordsman 8 equal rows and alpha 128; mage and ranger rows from the image gutters and alpha 180; ranger combat
     has 9 rows, the first 8 are used), so the figure must sit where it sits in the original cell;
  3. same feet: the lowest opaque row of each cell lies within 2 px of the original's;
  4. slimmer, not larger: at least 90 % of the opaque base pixels lie inside the original silhouette (grown by 3 px);
  5. not empty: the base covers at least 20 % of the original's opaque area in each cell (low on purpose: the base
     has no cape, robe or quiver, which made up much of the original silhouette, 26.11.).
Whether any equipment is still baked in (cape, robe, scarf, quiver, armour, weapon) cannot be measured here: that is
the visual review with the contact sheets (docs/Design/Visuelles Leitbild & Animation.md 5.5a).
Prints PASS / FAIL per file, NOT RUN when nothing is delivered. Technical acceptance only; the artistic
acceptance stays with the user (docs/Design/Qualitätsstandard.md).
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
from atlas import SOURCES, Atlas, base_neutral_path  # noqa: E402

# Optional: --dir PATH checks atlases with the same file names in another folder (probes without touching the handover)
BASE_DIR = Path(sys.argv[sys.argv.index('--dir') + 1]) if '--dir' in sys.argv else None


def grow(m: np.ndarray, r: int) -> np.ndarray:
    out = m.copy()
    for dy in range(-r, r + 1):
        for dx in range(-r, r + 1):
            out |= np.roll(np.roll(m, dy, 0), dx, 1)
    return out


def check(actor: str, source: str) -> tuple[str, list[str]]:
    base_p = base_neutral_path(actor, source)
    if BASE_DIR is not None:
        base_p = BASE_DIR / base_p.name
    if not base_p.is_file():
        return 'NOT RUN', []
    # The importer's own cell grid and alpha cut of the ORIGINAL atlas (atlas.Atlas): sword 8 equal rows and alpha 128;
    # mage and ranger rows from the image gutters, alpha 180, ranger combat 9 rows of which the first 8 are used.
    org = Atlas(actor, source)
    base = np.asarray(Image.open(base_p).convert('RGBA'))
    orig = org.img
    errs = []
    if base.shape[:2] != orig.shape[:2]:
        return 'FAIL', [f'Groesse {base.shape[1]}x{base.shape[0]} statt {orig.shape[1]}x{orig.shape[0]}']
    bm, om = base[..., 3] >= org.alpha_cut, orig[..., 3] >= org.alpha_cut
    for row in range(8):
        for col in range(8):
            x0, x1, y0, y1 = org.cols[col], org.cols[col + 1], org.cuts[row], org.cuts[row + 1]
            b, o = bm[y0:y1, x0:x1], om[y0:y1, x0:x1]
            if not o.any():
                continue
            if not b.any():
                errs.append(f'Zelle {row},{col} leer'); continue
            if abs(np.nonzero(b.any(1))[0].max() - np.nonzero(o.any(1))[0].max()) > 2:
                errs.append(f'Zelle {row},{col}: Fusspunkt weicht ab')
            inside = (b & grow(o, 3)).sum() / b.sum()
            if inside < .90:
                errs.append(f'Zelle {row},{col}: {100 * (1 - inside):.0f} % ausserhalb der Original-Silhouette')
            if b.sum() < .20 * o.sum():
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
