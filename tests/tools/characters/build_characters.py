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
from atlas import DENSITY, FRAME, OX, OY, ROOT, SETS, SOURCES, Atlas, frame_plan  # noqa: E402
import sys as _sys_ap; _sys_ap.path.insert(0, str(ROOT / 'tests' / 'tools' / 'assets')); import art_paths as AP  # noqa: E402
import render as R  # noqa: E402
from segment import CHEST, FEET, HAIR, HANDS, LEGS, WEAPON, Seg, segment  # noqa: E402
from gm_project import Project, read, write  # noqa: E402

CACHE = Path(os.environ.get('LOCALAPPDATA', str(Path.home()))) / 'FirstGame-Tests' / 'charcache'
ART_OUT = AP.CHARACTER_LAYERS
ACTORS = ['swordsmanv3', 'magev3', 'rangerv3']
PIECES = ['wpn_s'] + [f'{k}{t}' for k in ('wpn', 'head', 'chest', 'hands', 'feet') for t in range(4)]
HELM = {'swordsmanv3': dict(max_half_width=8.5 * DENSITY), 'magev3': dict(max_half_width=8.0 * DENSITY), 'rangerv3': dict(max_half_width=8.0 * DENSITY)}


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


_ATLAS = {}


def _seg_worker(job):
    actor, src, col, row, ver = job
    f = CACHE / f'{actor}_{src}_{col}_{row}_{ver}.pkl'
    if f.exists():
        return 0
    a = _ATLAS.get((actor, src))
    if a is None:
        a = _ATLAS[(actor, src)] = Atlas(actor, src)
    seg_cached(actor, src, col, row, a.cell(col, row), ver)
    return 1


def presegment(actors, ver, workers):
    """Fill the segmentation cache in parallel (cells are independent)."""
    from multiprocessing import Pool
    jobs = [(a, src, col, row, ver) for a in actors for (src, col, row) in cells_of(a)
            if not (CACHE / f'{a}_{src}_{col}_{row}_{ver}.pkl').exists()]
    if not jobs:
        return
    CACHE.mkdir(parents=True, exist_ok=True)
    t = time.time()
    with Pool(workers) as pool:
        done = sum(pool.imap_unordered(_seg_worker, jobs, chunksize=2))
    print(f'segmented {done} cells in {time.time() - t:.0f}s with {workers} workers', flush=True)


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


def pack(items, width=1024):
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


def cell_to_frame(cell, ax, ay):
    """Atlas-cell pixel -> frame pixel (same mapping as Cell.to_frame)."""
    l, t, r, b = cell.bounds
    x, y, w, h = cell.dest
    return x + (ax - l + .5) * w / max(1, r - l), y + (ay - t + .5) * h / max(1, b - t)


def mask_bone(cell, mask, top=.35, bottom=.30, min_px=40):
    """Bone of a soft part: pivot = centroid of its upper band, tip = centroid of its lower band (frame pixels),
    radius = half its frame width. None when the part is too small to animate."""
    ys, xs = np.nonzero(mask)
    if len(ys) < min_px:
        return None
    y0, y1 = ys.min(), ys.max()
    if y1 - y0 < 6:
        return None
    up = ys <= y0 + (y1 - y0) * top
    lo = ys >= y1 - (y1 - y0) * bottom
    px, py = cell_to_frame(cell, xs[up].mean(), ys[up].mean())
    tx, ty = cell_to_frame(cell, xs[lo].mean(), ys[lo].mean())
    fx0, _ = cell_to_frame(cell, xs.min(), y0)
    fx1, _ = cell_to_frame(cell, xs.max(), y0)
    r = max(6.0, (fx1 - fx0) * .5)
    clamp = lambda v: int(max(0, min(255, round(v))))
    return [clamp(px), clamp(py), clamp(tx), clamp(ty), clamp(r)]


def encode_bones(bones):
    """10 bytes per cell: hair (px,py,tx,ty,r) then cape (px,py,tx,ty,r); all zero = no bone."""
    out = b''
    for hb, cb in bones:
        out += struct.pack('<BBBBB', *(hb or [0] * 5)) + struct.pack('<BBBBB', *(cb or [0] * 5))
    return base64.b64encode(out).decode('ascii')


def write_sprite_frames(name, frames_by_index):
    """Overwrite the PNGs of an existing sprite in place (frame ids and count unchanged)."""
    d = ROOT / 'sprites' / name
    yy = read(f'sprites/{name}/{name}.yy')
    layer = yy['layers'][0]['name']
    ids = [f['name'] for f in yy['frames']]
    assert len(ids) == len(frames_by_index), (name, len(ids), len(frames_by_index))
    # Frame spec (size, origin, full-frame bbox) follows atlas.FRAME/OX/OY.
    if yy.get('width') != FRAME or yy['sequence'].get('xorigin') != OX or yy['sequence'].get('yorigin') != OY:
        yy.update(width=FRAME, height=FRAME, bbox_left=0, bbox_top=0, bbox_right=FRAME - 1, bbox_bottom=FRAME - 1)
        yy['sequence'].update(xorigin=OX, yorigin=OY, seqWidth=float(FRAME), seqHeight=float(FRAME))
        write(f'sprites/{name}/{name}.yy', yy)
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
    stats = dict(cells=len(cells), weapon_cells=0, composite_diff_px=[], halo_px=0, hair_bones=0, cape_bones=0)
    bones = [(None, None)] * len(cells)
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
        # secondary motion: hair from its label, cape from the segmentation's cape mask (swordsman, ranger)
        hb = mask_bone(cell, sg.labels == HAIR)
        cape = sg.info.get('cape') if isinstance(sg.info, dict) else None
        cb = mask_bone(cell, cape, top=.20, bottom=.25, min_px=120) if cape is not None else None
        bones[i] = (hb, cb); stats['hair_bones'] += hb is not None; stats['cape_bones'] += cb is not None
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
    build_icons(actor, cells, layer_frames, acc_frames, project)
    sprite_map = {}
    for name, fi, src, col, row in frame_plan(actor):
        sprite_map.setdefault(name, {})[fi] = index[(src, col, row)]
    sprite_map = {k: [v[i] for i in sorted(v)] for k, v in sprite_map.items()}
    if previews:
        preview_sheet(actor, cells, base_frames, layer_frames, acc_frames)
    d = stats['composite_diff_px']
    stats.update(composite_diff_px=dict(mean=round(float(np.mean(d)), 1), max=int(np.max(d)), frames_over_20=int(sum(x > 20 for x in d))),
                 seconds=round(time.time() - t0), atlas_px=int(sum(h * w for h, w in sizes.values())), atlases=len(sizes))
    return dict(cells=len(cells), sprites=sprite_map, rects=rect_tables, bones=encode_bones(bones)), stats


RARITY = [(176, 138, 92), (110, 170, 255), (242, 200, 92), (196, 124, 255)]
ICON_SLOTS = ['wpn', 'head', 'chest', 'hands', 'feet']


def build_icons(actor, cells, layer_frames, acc_frames, project, size=32):
    """Item icons straight from the on-body pieces: spr_eqv_icons_<actor>, frame = slot_index*4 + tier
    (slot order weapon, head, chest, hands, feet). Showcase cell = the idle/walk view where the piece is largest."""
    show = [i for i, (src, col, row) in enumerate(cells) if src in ('combat', 'walk') and col in (0, 2) and row in (6, 7, 0, 5)]
    frames = []
    for slot in ICON_SLOTS:
        for t in range(4):
            key = f'{slot}{t}'
            best = max(show, key=lambda i: 0 if layer_frames[key][i] is None else int((layer_frames[key][i][0][..., 3] > 0).sum()))
            c = layer_frames[key][best]
            icon = np.zeros((size, size, 4), np.uint8)
            if c is not None:
                im = c[0].copy()
                ac = acc_frames.get(key)
                if ac is not None and ac[best] is not None:
                    a_im, ax, ay = ac[best]; ox, oy = c[1], c[2]
                    tint = np.array((214, 186, 128), float) / 255.0   # neutral trim; rarity is shown by the slot frame
                    for yy in range(a_im.shape[0]):
                        for xx in range(a_im.shape[1]):
                            if a_im[yy, xx, 3]:
                                ty, tx = ay - oy + yy, ax - ox + xx
                                if 0 <= ty < im.shape[0] and 0 <= tx < im.shape[1]:
                                    im[ty, tx, :3] = (a_im[yy, xx, :3] * tint).astype(np.uint8); im[ty, tx, 3] = 255
                h, w = im.shape[:2]
                f = max(1, min((size - 4) // max(h, 1), (size - 4) // max(w, 1)))
                big = np.kron(im, np.ones((f, f, 1), np.uint8))
                if big.shape[0] > size - 2 or big.shape[1] > size - 2:
                    big = np.asarray(Image.fromarray(im).resize((min(size - 2, w), min(size - 2, h)), Image.NEAREST))
                bh, bw = big.shape[:2]; y0, x0 = (size - bh) // 2, (size - bw) // 2
                icon[y0:y0 + bh, x0:x0 + bw] = big
                # 1 px dark outline around the item for readability on the slot frame
                a = icon[..., 3] > 0
                ring = np.zeros_like(a)
                for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    ring |= np.roll(np.roll(a, dy, 0), dx, 1)
                ring &= ~a
                icon[ring] = (12, 10, 14, 255)
            frames.append(icon)
    project.sprite(f'spr_eqv_icons_{actor}', frames, (size // 2, size // 2), texgroup='Equipment')


def uncrop(c):
    out = np.zeros((FRAME, FRAME, 4), np.uint8)
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
            sheet.alpha_composite(Image.fromarray(im).crop(tuple(round(v * DENSITY) for v in (16, 28, 80, 92))).resize((W, W), Image.NEAREST), (k * W, r * W))
    sheet.save(ART_OUT / f'preview_{actor}.png')


GML_HEAD = """/// GENERATED by tests/tools/characters/build_characters.py - do not edit by hand.
/// Per actor: base sprite name -> shared cell index per frame; per piece: base64 rect table, 8 bytes per cell
/// (u16 atlas x, u16 atlas y, u8 w, u8 h, u8 offset x, u8 offset y in the frame; frame size and origin in "frame").
"""


def write_gml(data, project):
    lines = [GML_HEAD, 'function equipment_visual_data() {', '    static d = {', f'        pieces: {json.dumps(PIECES)},', f'        frame: {{size: {FRAME}, ox: {OX}, oy: {OY}}},', '        actors: {']
    for actor, d in data.items():
        lines.append(f'            {actor}: {{')
        lines.append(f'                cells: {d["cells"]},')
        lines.append('                sprites: {')
        lines.extend(f'                    {k}: {json.dumps(v)},' for k, v in d['sprites'].items())
        lines.append('                },')
        if 'bones' in d:
            lines.append(f'                bones: "{d["bones"]}",')
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
    # FG_SEG_VER pins the segmentation cache (cells are segmented in atlas space; frame spec changes do not affect it).
    ver = os.environ.get('FG_SEG_VER') or code_hash()
    presegment(a.actors.split(','), ver, max(1, (os.cpu_count() or 2) - 2))
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
