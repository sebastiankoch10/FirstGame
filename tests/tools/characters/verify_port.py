"""Check that atlas.py reproduces the in-project character frames pixel-exactly (or report the mismatch)."""
import json
import re
import sys
from pathlib import Path

import numpy as np
from PIL import Image

sys.path.insert(0, str(Path(__file__).parent))
from atlas import ROOT, Atlas, frame_plan  # noqa: E402


def sprite_frames(name):
    d = ROOT / 'sprites' / name
    yy = json.loads(re.sub(r',(\s*[}\]])', r'\1', (d / f'{name}.yy').read_text(encoding='utf-8')))
    return [d / f"{f['name']}.png" for f in yy['frames']]


def main(actors):
    for actor in actors:
        atlases = {}
        exact = total = 0; worst = []
        for name, i, source, col, row in frame_plan(actor):
            a = atlases.setdefault(source, Atlas(actor, source))
            mine = a.cell(col, row).to_frame(a.cell(col, row).rgba)
            game = np.asarray(Image.open(sprite_frames(name)[i]).convert('RGBA'))
            diff = int((np.any(mine != game, axis=2)).sum())
            total += 1; exact += diff == 0
            if diff: worst.append((diff, name, i))
        worst.sort(reverse=True)
        print(f'{actor}: {exact}/{total} frames pixel-exact; worst {worst[:5]}')


if __name__ == '__main__':
    main(sys.argv[1:] or ['swordsmanv3', 'magev3', 'rangerv3'])
