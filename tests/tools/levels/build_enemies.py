"""Render and register all eight level enemy types (320 GameMaker sprites).
Usage: python tests/tools/levels/build_enemies.py
"""
from __future__ import annotations

import sys
import time
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import enemies as E  # noqa: E402
from gm_project import ROOT, Project  # noqa: E402

DERIVED = {'swskel': 'Level_Swamp', 'knight': 'Level_Swamp', 'ashwar': 'Level_Ashfrost', 'armor': 'Level_Ashfrost'}
CREATURES = {'crawler': 'Level_Swamp', 'shroom': 'Level_Swamp', 'spirit': 'Level_Ashfrost', 'construct': 'Level_Ashfrost'}


def _derived(v):
    return v, E.build_derived(v)


def main():
    t0 = time.time()
    out = ROOT / 'FirstGame_ArtPack' / 'level_enemies'
    out.mkdir(parents=True, exist_ok=True)
    sprites = {}
    with ProcessPoolExecutor(max_workers=16) as ex:
        for v, frames in ex.map(_derived, list(DERIVED)):
            for (action, d), fl in frames.items():
                sprites[(v, action, d)] = fl
        jobs = [(k, a, d, i) for k in CREATURES for a, n in E.CR_ACTIONS.items() for d in E.DIRS for i in range(n)]
        for (k, a, d, i), img in ex.map(E.render_creature_frame, jobs, chunksize=4):
            sprites.setdefault((k, a, d), [None] * E.CR_ACTIONS[a])[i] = img
    print(f'rendered {len(sprites)} sequences ({time.time() - t0:.1f}s)', flush=True)
    proj = Project()
    for (k, a, d), frames in sorted(sprites.items()):
        group = DERIVED.get(k) or CREATURES[k]
        proj.ensure_texture_group(group)
        proj.sprite(f'spr_lv_en_{k}_{a}_{d}', frames, E.ORIGIN, texgroup=group)
        if d == 'down':
            Image.fromarray(frames[0], 'RGBA').save(out / f'{k}_{a}_down_0.png')
    proj.save()
    print(f'registered {len(proj.added)} new sprites ({time.time() - t0:.1f}s)', flush=True)


if __name__ == '__main__':
    main()
