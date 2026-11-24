"""Preview sheet: original | base | base+start weapon | full sets T0..T3 (accents tinted by rarity).
python preview.py actor out.png "src:col,col;src:col" rows"""
import sys
import numpy as np
from PIL import Image, ImageDraw
from atlas import Atlas
from segment import segment, CHEST, HANDS, FEET, LEGS
import render as R

RARITY = [(150, 118, 78), (110, 170, 255), (242, 200, 92), (196, 124, 255)]


def over(dst, src):
    a = src[..., 3:4] / 255.0
    dst[..., :3] = (dst[..., :3] * (1 - a) + src[..., :3] * a).astype(np.uint8)
    dst[..., 3] = np.maximum(dst[..., 3], src[..., 3])
    return dst


def tint(acc, col):
    out = acc.copy().astype(float)
    out[..., :3] = out[..., :3] / 255.0 * np.array(col)
    return out.astype(np.uint8)


def compose(fr, tier, base, kinds, rarity, fr_orig):
    img = base.copy()
    chest_reg = (fr.lab == CHEST) | ((fr.lab == LEGS) & (tier >= 1))
    for reg, slot in ((fr.lab == FEET, 'feet'), (chest_reg, 'chest'), (fr.lab == HANDS, 'hands')):
        m, a = R.armor_layer(fr, reg & (base[..., 3] > 0), slot, tier, kinds)
        over(img, m); over(img, tint(a, rarity))
    m, a = R.helmet_layer(fr, tier); over(img, m); over(img, tint(a, rarity))
    m, a = R.sword_layer(fr_orig, tier); over(img, m); over(img, tint(a, rarity))
    return img


def main():
    actor, out, spec, rows = sys.argv[1], sys.argv[2], sys.argv[3], [int(r) for r in sys.argv[4].split(',')]
    kinds = R.sword_kinds
    lines = []
    for part in spec.split(';'):
        src, cols = part.split(':'); a = Atlas(actor, src)
        for row in rows:
            for c in map(int, cols.split(',')):
                cell = a.cell(c, row); sg = segment(actor, cell.rgba); fr = R.make_frame(cell, sg, actor)
                base, lab = R.base_layer(fr, kinds)
                fr2 = R.Frame(fr.rgba, lab, fr.blade, fr.grip, actor)
                start = over(base.copy(), R.sword_layer(fr, None)[0])
                imgs = [fr.rgba, base, start] + [compose(fr2, t, base, kinds, RARITY[t], fr) for t in range(4)]
                lines.append((f'{src[:3]}{c}r{row}', imgs))
    sc = 4; W = 64 * sc
    sheet = Image.new('RGBA', (7 * W + 60, len(lines) * W), (52, 60, 52, 255)); dr = ImageDraw.Draw(sheet)
    for i, (name, imgs) in enumerate(lines):
        dr.text((2, i * W + 2), name, fill=(255, 255, 0, 255))
        for k, im in enumerate(imgs):
            crop = Image.fromarray(im)  # 96x96 -> crop to the figure area
            crop = crop.crop((16, 28, 80, 92)).resize((W, W), Image.NEAREST)
            sheet.alpha_composite(crop, (60 + k * W, i * W))
    sheet.save(out)


main()
