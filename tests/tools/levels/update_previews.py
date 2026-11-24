"""Replace level-select previews with real native frames from the latest level smoke run.
Usage: python tests/tools/levels/update_previews.py [output/level-smoke/<stamp>]
Uses preview-<id>.png (scenic landmark frame) when present, else start-<id>.png.
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from gm_project import ROOT, Project  # noqa: E402

TARGETS = {'forest': ('spr_lv_forest_preview', 'level_forest'), 'swamp': ('spr_lv_sw_preview', 'level_swamp'), 'ashfrost': ('spr_lv_af_preview', 'level_ashfrost')}


def main():
    run = Path(sys.argv[1]) if len(sys.argv) > 1 else sorted((ROOT / 'output/level-smoke').iterdir())[-1]
    proj = Project()
    for lid, (sprite, folder) in TARGETS.items():
        src = run / f'preview-{lid}.png'
        if not src.exists():
            src = run / f'start-{lid}.png'
        if not src.exists():
            print('missing', lid); continue
        im = Image.open(src).convert('RGBA')
        w, h = im.size
        tw = min(w, int(h * 16 / 9)); th = int(tw * 9 / 16)
        im = im.crop(((w - tw) // 2, (h - th) // 2, (w - tw) // 2 + tw, (h - th) // 2 + th)).resize((384, 216), Image.LANCZOS)
        out = ROOT / 'FirstGame_ArtPack' / folder / 'preview_native.png'
        out.parent.mkdir(parents=True, exist_ok=True)
        im.save(out)
        proj.sprite(sprite, [out], (192, 108))
        print(lid, 'preview <-', src.name)
    proj.save()


if __name__ == '__main__':
    main()
