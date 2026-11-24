"""All cells with the weapon mask tinted red: python weapon_sheet.py actor out.png"""
import sys
import numpy as np
from PIL import Image, ImageDraw
from atlas import Atlas, SETS
from segment import segment, WEAPON, HANDS
actor, out = sys.argv[1], sys.argv[2]
tiles = []
for src in (sys.argv[3].split(',') if len(sys.argv) > 3 else ['walk', 'combat', 'mobility', 'reaction']):
    a = Atlas(actor, src)
    cols = sorted({c for v in SETS[actor][src].values() for c in v})
    for row in range(8):
        for col in cols:
            c = a.cell(col, row); sg = segment(actor, c.rgba); l, t, r, b = c.bounds
            im = c.rgba.copy().astype(float)
            w = sg.labels == WEAPON; hd = sg.labels == HANDS
            im[w, :3] = im[w, :3] * .3 + np.array([255, 0, 0]) * .7
            im[hd, :3] = im[hd, :3] * .5 + np.array([255, 220, 0]) * .5
            tiles.append((f'{src[:3]}{col}r{row}', Image.fromarray(im[t:b, l:r].astype(np.uint8))))
per = int(sys.argv[4]) if len(sys.argv) > 4 else 16; tw = th = int(sys.argv[5]) if len(sys.argv) > 5 else 104
sheet = Image.new('RGBA', (per * tw, ((len(tiles) + per - 1) // per) * th), (60, 70, 60, 255)); dr = ImageDraw.Draw(sheet)
for i, (m, im) in enumerate(tiles):
    im.thumbnail((tw - 2, th - 12)); x = (i % per) * tw; y = (i // per) * th
    sheet.alpha_composite(im, (x + 1, y + 11)); dr.text((x + 1, y), m, fill=(255, 255, 0, 255))
sheet.save(out)
