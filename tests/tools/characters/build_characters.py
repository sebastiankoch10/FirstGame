"""Build the layered character art for swordsmanv3 / magev3 / rangerv3.

  python tests/tools/characters/build_characters.py [--actors swordsmanv3,magev3,rangerv3] [--previews]

Outputs (in the project, registered in FirstGame.yyp):
  * base models: the existing 360+ spr_fg_<actor>_<action>_<dir> sprites get new frame PNGs (same frame ids/counts);
    the untouched originals stay in FirstGame_ArtPack (swordsman_v3/frames, class_overhaul/frames).
  * spr_eqv_<actor>_<piece>: one packed atlas per equipment piece and its accent layer (texture group Equipment).
  * scripts/equipment_visual_data: frame map (base sprite -> shared cell index) + base64 rect tables (8 bytes per cell).
  * tests/reports/character-layers.json: coverage and consistency numbers.
Segmentation is cached in %LOCALAPPDATA%/FirstGame-Tests/charcache (keyed by the source code hash).
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
import pickle
import struct
import sys
import time
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE)); sys.path.insert(0, str(HERE.parent / 'levels'))
from atlas import ROOT, SETS, SOURCES, Atlas, frame_plan  # noqa: E402
import render as R  # noqa: E402
from segment import CHEST, FEET, HANDS, LEGS, WEAPON, Seg, segment  # noqa: E402
from gm_project import Project, read  # noqa: E402

CACHE = Path(os.environ.get('LOCALAPPDATA', str(Path.home()))) / 'FirstGame-Tests' / 'charcache'
ART_OUT = ROOT / 'FirstGame_ArtPack' / 'character_layers'
ACTORS = ['swordsmanv3', 'magev3', 'rangerv3']
PIECES = ['wpn_s'] + [f'{k}{t}' for k in ('wpn', 'head', 'chest', 'hands', 'feet') for t in range(4)]
HELM = {'swordsmanv3': dict(max_half_width=8.5), 'magev3': dict(max_half_width=8.0), 'rangerv3': dict(max_half_width=8.0)}


def code_hash():
    h = hashlib.sha1()
    for f in ('segment.py', 'morph.py', 'atlas.py'):
        h.update((HERE / f).read_bytes())
    return h.hexdigest()[:10]


def seg_cached(actor, src, col, row, cell, ver):
    CACHE.mkdir(parents=True, exist_ok=True)
    f = CACHE / f'{actor}_{src}_{col}_{row}_{ver}.pkl'
    if f.exists():
        return pickle.loads(f.read_bytes())
    sg = segment(actor, cell.rgba)
    f.write_bytes(pickle.dumps(sg))
    return sg


def cells_of(actor):
    """Ordered unique cells [(src, col, row)] -> canonical index."""
    out = []
    for src in SOURCES:
        cols = sorted({c for v in SETS[actor][src].values() for c in v})
        for row in range(8):
            for col in cols:
                out.append((src, col, row))
    return out


def layers_for(actor, fr, base, lab_base):
    fr2 = R.Frame(fr.rgba, lab_base, fr.blade, fr.grip, actor)
    alive = base[..., 3] > 0
    kinds = R.KINDS[actor]
    wl = R.WEAPON_LAYER[actor]
    covers = R.CHEST_COVERS_LEGS[actor]
    out = {'wpn_s': (wl(fr, None)[0], None)}
    for t in range(4):
        out[f'wpn{t}'] = wl(fr, t)
        chest = (lab_base == CHEST) | ((lab_base == LEGS) if covers is not None and t >= covers else False)
        out[f'chest{t}'] = R.armor_layer(fr2, chest & alive, 'chest', t, kinds)
        out[f'hands{t}'] = R.armor_layer(fr2, (lab_base == HANDS) & alive, 'hands', t, kinds)
        out[f'feet{t}'] = R.armor_layer(fr2, (lab_base == FEET) & alive, 'feet', t, kinds)
        out[f'head{t}'] = R.helmet_layer(fr2, t, **HELM[actor])
    return out


def crop(img):
    a = img[..., 3] > 0
    if not a.any():
        return None
    ys, xs = np.nonzero(a)
    y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
    return img[y0:y1, x0:x1], int(x0), int(y0)


def pack(items, width=512):
    """Shelf packer. items: list of (canon, crop|None). Returns atlas RGBA and rect table [(ax, ay, w, h, ox, oy)]."""
    rects = [(0, 0, 0, 0, 0, 0)] * len(items)
    order = sorted([i for i, c in enumerate(items) if c is not None], key=lambda i: -items[i][0].shape[0])
    x = y = shelf = 0; place = {}
    for i in order:
        im = items[i][0]; h, w = im.shape[:2]
        if x + w + 1 > width:
            x = 0; y += shelf + 1; shelf = 0
        place[i] = (x, y); x += w + 1; shelf = max(shelf, h)
    H = max(1, y + shelf + 1)
    atlas = np.zeros((H, width, 4), np.uint8)
    for i, (ax, ay) in place.items():
        im, ox, oy = items[i]; h, w = im.shape[:2]
        atlas[ay:ay + h, ax:ax + w] = im
        rects[i] = (ax, ay, w, h, ox, oy)
    return atlas, rects


def encode(rects):
    return base64.b64encode(b''.join(struct.pack('<HHBBBB', *r) for r in rects)).decode('ascii')


def write_sprite_frames(name, frames_by_index):
    """Overwrite the PNGs of an existing sprite in place (frame ids and count unchanged)."""
    d = ROOT / 'sprites' / name
    yy = read(f'sprites/{name}/{name}.yy')
    layer = yy['layers'][0]['name']
    ids = [f['name'] for f in yy['frames']]
    assert len(ids) == len(frames_by_index), (name, len(ids), len(frames_by_index))
    for uid, img in zip(ids, frames_by_index):
        im = Image.fromarray(img, 'RGBA')
        im.save(d / f'{uid}.png', optimize=True)
        (d / 'layers' / uid).mkdir(parents=True, exist_ok=True)
        im.save(d / 'layers' / uid / f'{layer}.png', optimize=True)


def build_actor(actor, ver, project, previews):
    t0 = time.time()
    cells = cells_of(actor); index = {c: i for i, c in enumerate(cells)}
    atlases = {}
    base_frames = [None] * len(cells); layer_frames = {p: [None] * len(cells) for p in PIECES}
    acc_frames = {p: [None] * len(cells) for p in PIECES if p != 'wpn_s'}
    stats = dict(cells=len(cells), weapon_cells=0, composite_diff_px=[], halo_px=0)
    for i, (src, col, row) in enumerate(cells):
        a = atlases.setdefault(src, Atlas(actor, src))
        cell = a.cell(col, row)
        sg = seg_cached(actor, src, col, row, cell, ver)
        fr = R.make_frame(cell, sg, actor)
        base, lab_base = R.base_layer(fr, R.KINDS[actor])
        base_frames[i] = base
        L = layers_for(actor, fr, base, lab_base)
        for p, (m, ac) in L.items():
            layer_frames[p][i] = crop(m)
            if ac is not None:
                acc_frames[p][i] = crop(ac)
        stats['weapon_cells'] += bool((fr.lab == WEAPON).any())
        # consistency: base + start weapon must reproduce the original except removed matte / weapon outline specks
        comp = base.copy(); w = L['wpn_s'][0][..., 3] > 0; comp[w] = L['wpn_s'][0][w]
        if previews:
            base_frames[i] = base
        orig = fr.rgba
        changed_shape = (comp[..., 3] > 0) != (orig[..., 3] > 0)
        stats['composite_diff_px'].append(int(changed_shape.sum()))
        stats['halo_px'] += int((fr.lab == 6).sum())
    # base models -> sprites (in place)
    by_sprite = {}
    for name, fi, src, col, row in frame_plan(actor):
        by_sprite.setdefault(name, {})[fi] = base_frames[index[(src, col, row)]]
    for name, frames in by_sprite.items():
        write_sprite_frames(name, [frames[k] for k in sorted(frames)])
    # equipment atlases
    rect_tables = {}; sizes = {}
    for p in PIECES:
        for kind, frames in (('', layer_frames[p]), ('_acc', acc_frames.get(p))):
            if frames is None:
                continue
            items = list(frames)
            if not any(items):
                continue
            atlas, rects = pack(items)
            sname = f'spr_eqv_{actor}_{p}{kind}'
            project.sprite(sname, [atlas], (0, 0), texgroup='Equipment')
            rect_tables[p + kind] = encode(rects)
            sizes[sname] = list(atlas.shape[:2])
    sprite_map = {}
    for name, fi, src, col, row in frame_plan(actor):
        sprite_map.setdefault(name, {})[fi] = index[(src, col, row)]
    sprite_map = {k: [v[i] for i in sorted(v)] for k, v in sprite_map.items()}
    if previews:
        preview_sheet(actor, cells, base_frames, layer_frames, acc_frames)
    d = stats['composite_diff_px']
    stats.update(composite_diff_px=dict(mean=round(float(np.mean(d)), 1), max=int(np.max(d)), frames_over_20=int(sum(x > 20 for x in d))),
                 seconds=round(time.time() - t0), atlas_px=int(sum(h * w for h, w in sizes.values())), atlases=len(sizes))
    return dict(cells=len(cells), sprites=sprite_map, rects=rect_tables), stats


RARITY = [(176, 138, 92), (110, 170, 255), (242, 200, 92), (196, 124, 255)]


def uncrop(c):
    out = np.zeros((96, 96, 4), np.uint8)
    if c is not None:
        im, ox, oy = c; out[oy:oy + im.shape[0], ox:ox + im.shape[1]] = im
    return out


def over(dst, src, tint=None):
    a = src[..., 3:4] / 255.0
    col = src[..., :3].astype(float) if tint is None else src[..., :3] / 255.0 * np.array(tint)
    dst[..., :3] = (dst[..., :3] * (1 - a) + col * a).astype(np.uint8)
    dst[..., 3] = np.maximum(dst[..., 3], src[..., 3])


def preview_sheet(actor, cells, base_frames, layer_frames, acc_frames):
    ART_OUT.mkdir(parents=True, exist_ok=True)
    pick = [i for i, (src, col, row) in enumerate(cells) if (src, col) in (('combat', 0), ('walk', 2), ('combat', 3)) and row in (0, 2, 4, 6)]
    sc = 3; W = 64 * sc
    sheet = Image.new('RGBA', (6 * W, len(pick) * W), (48, 56, 50, 255))
    for r, i in enumerate(pick):
        cols = [base_frames[i]]
        s = base_frames[i].copy(); over(s, uncrop(layer_frames['wpn_s'][i])); cols.append(s)
        for t in range(4):
            img = base_frames[i].copy()
            for p in (f'feet{t}', f'chest{t}', f'hands{t}', f'head{t}', f'wpn{t}'):
                over(img, uncrop(layer_frames[p][i]))
                if acc_frames.get(p) and acc_frames[p][i] is not None:
                    over(img, uncrop(acc_frames[p][i]), RARITY[t])
            cols.append(img)
        for k, im in enumerate(cols):
            sheet.alpha_composite(Image.fromarray(im).crop((16, 28, 80, 92)).resize((W, W), Image.NEAREST), (k * W, r * W))
    sheet.save(ART_OUT / f'preview_{actor}.png')


GML_HEAD = """/// GENERATED by tests/tools/characters/build_characters.py - do not edit by hand.
/// Per actor: base sprite name -> shared cell index per frame; per piece: base64 rect table, 8 bytes per cell
/// (u16 atlas x, u16 atlas y, u8 w, u8 h, u8 offset x, u8 offset y in the 96x96 frame, origin 48,88).
"""


def write_gml(data, project):
    lines = [GML_HEAD, 'function equipment_visual_data() {', '    static d = {', f'        pieces: {json.dumps(PIECES)},', '        actors: {']
    for actor, d in data.items():
        lines.append(f'            {actor}: {{')
        lines.append(f'                cells: {d["cells"]},')
        lines.append('                sprites: {')
        lines.extend(f'                    {k}: {json.dumps(v)},' for k, v in d['sprites'].items())
        lines.append('                },')
        lines.append('                rects: {')
        lines.extend(f'                    {k}: "{v}",' for k, v in d['rects'].items())
        lines.append('                }')
        lines.append('            },')
    lines += ['        }', '    };', '    return d;', '}', '']
    project.script('equipment_visual_data', '\n'.join(lines))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--actors', default=','.join(ACTORS)); ap.add_argument('--previews', action='store_true')
    a = ap.parse_args()
    ver = code_hash()
    project = Project(); project.ensure_texture_group('Equipment')
    data = {}; report = {}
    # keep already built actors in the data script when only some are rebuilt
    old = CACHE / 'character-layers-data.json'
    if old.exists():
        data.update(json.loads(old.read_text(encoding='utf-8')))
    for actor in a.actors.split(','):
        d, st = build_actor(actor, ver, project, a.previews)
        data[actor] = d; report[actor] = st
        print(actor, json.dumps(st), flush=True)
    data = {k: data[k] for k in ACTORS if k in data}
    write_gml(data, project)
    project.save()
    old.write_text(json.dumps(data), encoding='utf-8')
    rep = ROOT / 'tests/reports/character-layers.json'
    prev = json.loads(rep.read_text(encoding='utf-8')) if rep.exists() else {}
    prev.update(report); prev['segment_code'] = ver
    rep.write_text(json.dumps(prev, indent=1) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
