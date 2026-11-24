"""Debug sheet: original cells and label overlays. python debug_seg.py actor out.png [source:col,col;...]"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(Path(__file__).parent))
from atlas import Atlas  # noqa: E402
from segment import segment, NAMES  # noqa: E402

COL = {1: (90, 90, 90), 2: (40, 120, 255), 3: (255, 200, 0), 4: (0, 220, 120), 5: (255, 40, 40), 6: (255, 0, 255), 7: (0, 200, 220), 8: (255, 150, 60)}


def main():
    actor, out = sys.argv[1], sys.argv[2]
    spec = sys.argv[3] if len(sys.argv) > 3 else 'combat:0,1,3,5;walk:0,3;mobility:1,5;reaction:1,6'
    rows = [int(r) for r in (sys.argv[4] if len(sys.argv) > 4 else '0,2,4,6').split(',')]
    tiles = []
    for part in spec.split(';'):
        src, cols = part.split(':')
        a = Atlas(actor, src)
        for row in rows:
            for c in map(int, cols.split(',')):
                cell = a.cell(c, row); l, t, r, b = cell.bounds
                sg = segment(actor, cell.rgba)
                sub = cell.rgba[t:b, l:r]; lab = sg.labels[t:b, l:r]
                ov = np.zeros(sub.shape, np.uint8)
                for k, col in COL.items():
                    ov[lab == k] = (*col, 255)
                tiles.append((sub, ov, f'{src[:3]}{c} r{row}'))
    sc = 2; tw = max(t[0].shape[1] for t in tiles) * sc + 6; th = max(t[0].shape[0] for t in tiles) * sc
    per = 8
    nrow = (len(tiles) + per - 1) // per
    sheet = Image.new('RGBA', (per * tw, nrow * (2 * th + 14)), (55, 62, 55, 255)); dr = ImageDraw.Draw(sheet)
    for i, (sub, ov, name) in enumerate(tiles):
        x = (i % per) * tw; y = (i // per) * (2 * th + 14)
        im = Image.fromarray(sub).resize((sub.shape[1] * sc, sub.shape[0] * sc), Image.NEAREST)
        sheet.alpha_composite(im, (x, y + 12))
        o = Image.fromarray(ov).resize((sub.shape[1] * sc, sub.shape[0] * sc), Image.NEAREST)
        sheet.alpha_composite(o, (x, y + 12 + th))
        dr.text((x + 2, y), name, fill=(255, 255, 255, 255))
    sheet.save(out)
    print('legend:', {NAMES[k]: v for k, v in COL.items()})


if __name__ == '__main__':
    main()
