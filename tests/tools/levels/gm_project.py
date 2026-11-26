"""Minimal, deterministic GameMaker 2024 resource writer for the level pipeline.

Uses the same JSON dialect helpers (gms_helpers.gm_json) and templates as the existing
Codex importers, so generated .yy files match the IDE format. Re-running is idempotent:
frame ids are uuid5-derived from the resource name and index.
"""
from __future__ import annotations

import copy
import shutil
import sys
import uuid
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path.home() / 'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import dumps, loads  # noqa: E402

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tests' / 'tools' / 'assets'))
from ide_folders import ensure_folders, folder_for  # noqa: E402


def read(rel):
    return loads((ROOT / rel).read_text(encoding='utf-8-sig'))


def write(rel, data):
    p = ROOT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(dumps(data), encoding='utf-8')


class Project:
    def __init__(self):
        self.yyp = read('FirstGame.yyp')
        self.sprite_template = read('sprites/spr_fg_coin_idle/spr_fg_coin_idle.yy')
        self.added = []

    def _register(self, name, path):
        if not any(r['id']['name'] == name for r in self.yyp['resources']):
            self.yyp['resources'].append({'id': {'name': name, 'path': path}})
            self.added.append(name)

    def _file_under(self, data, kind, name):
        """Put a new resource into its IDE folder (tests/tools/assets/ide_folders.py); keep the template's otherwise."""
        folder = folder_for(kind, name)
        if folder:
            ensure_folders(self.yyp, folder)
            data['parent'] = {'name': folder.rsplit('/', 1)[-1], 'path': f'folders/{folder}.yy'}

    def ensure_texture_group(self, name):
        groups = self.yyp['TextureGroups']
        if any(g['name'] == name for g in groups):
            return
        g = copy.deepcopy(next(g for g in groups if g['name'] == 'Default'))
        g['name'] = g['%Name'] = name
        groups.append(g)

    def sprite(self, name, frames, origin, texgroup='Default', bbox=None):
        """frames: list of RGBA uint8 arrays or PNG paths. origin: (x, y) in pixels."""
        from PIL import Image
        imgs = []
        for f in frames:
            if isinstance(f, (str, Path)):
                imgs.append(Image.open(f).convert('RGBA'))
            else:
                imgs.append(Image.fromarray(np.asarray(f, dtype=np.uint8), 'RGBA'))
        w = max(i.width for i in imgs); h = max(i.height for i in imgs)
        imgs = [i if i.size == (w, h) else _pad(i, w, h) for i in imgs]
        data = copy.deepcopy(self.sprite_template)
        data['name'] = data['%Name'] = data['sequence']['name'] = name
        self._file_under(data, 'sprites', name)
        if bbox is None:
            bbox = (0, 0, w - 1, h - 1)
        data.update(width=w, height=h, bboxMode=2 if bbox != (0, 0, w - 1, h - 1) else 0, bbox_left=int(bbox[0]), bbox_top=int(bbox[1]),
                    bbox_right=int(bbox[2]), bbox_bottom=int(bbox[3]), origin=9, collisionKind=1)
        data['textureGroupId'] = {'name': texgroup, 'path': f'texturegroups/{texgroup}'}
        seq = data['sequence']
        seq.update(xorigin=int(origin[0]), yorigin=int(origin[1]), seqWidth=float(w), seqHeight=float(h), length=float(len(imgs)))
        ft = copy.deepcopy(data['frames'][0])
        kt = copy.deepcopy(seq['tracks'][0]['keyframes']['Keyframes'][0])
        layer = data['layers'][0]['name']
        folder = ROOT / 'sprites' / name
        if folder.exists():
            shutil.rmtree(folder)
        folder.mkdir(parents=True)
        data['frames'] = []; keys = []
        for i, im in enumerate(imgs):
            uid = str(uuid.uuid5(uuid.NAMESPACE_URL, f'FirstGame/levels/{name}/{i}'))
            fr = copy.deepcopy(ft); fr['name'] = fr['%Name'] = uid; data['frames'].append(fr)
            key = copy.deepcopy(kt); key['id'] = str(uuid.uuid5(uuid.NAMESPACE_URL, f'FirstGame/levels/key/{name}/{i}'))
            key['Key'] = float(i); key['Channels']['0']['Id'] = {'name': uid, 'path': f'sprites/{name}/{name}.yy'}
            keys.append(key)
            im.save(folder / f'{uid}.png', optimize=True)
            (folder / 'layers' / uid).mkdir(parents=True, exist_ok=True)
            im.save(folder / 'layers' / uid / f'{layer}.png', optimize=True)
        seq['tracks'][0]['keyframes']['Keyframes'] = keys
        write(f'sprites/{name}/{name}.yy', data)
        self._register(name, f'sprites/{name}/{name}.yy')

    def script(self, name, code):
        data = read('scripts/master_world/master_world.yy')
        data['name'] = data['%Name'] = name
        self._file_under(data, 'scripts', name)
        write(f'scripts/{name}/{name}.yy', data)
        (ROOT / 'scripts' / name / f'{name}.gml').write_text(code, encoding='utf-8')
        self._register(name, f'scripts/{name}/{name}.yy')

    def shader(self, name, vsh, fsh):
        """GLSL ES shader resource (type 1) with its vertex and fragment source."""
        data = {'$GMShader': '', '%Name': name, 'name': name, 'parent': {'name': 'Shader', 'path': 'folders/Shader.yy'},
                'resourceType': 'GMShader', 'resourceVersion': '2.0', 'type': 1}
        self._file_under(data, 'shaders', name)
        write(f'shaders/{name}/{name}.yy', data)
        (ROOT / 'shaders' / name / f'{name}.vsh').write_text(vsh, encoding='utf-8')
        (ROOT / 'shaders' / name / f'{name}.fsh').write_text(fsh, encoding='utf-8')
        self._register(name, f'shaders/{name}/{name}.yy')

    def object(self, name, events, persistent=False, sprite=None):
        """events: list of (eventType, eventNum) -> created as empty files if missing."""
        data = read('objects/ObjectMasterScenery/ObjectMasterScenery.yy')
        data['name'] = data['%Name'] = name
        data['spriteId'] = None if sprite is None else {'name': sprite, 'path': f'sprites/{sprite}/{sprite}.yy'}
        data['persistent'] = persistent
        data['eventList'] = [{'$GMEvent': 'v1', '%Name': '', 'collisionObjectId': None, 'eventNum': num, 'eventType': kind, 'isDnD': False,
                              'name': '', 'resourceType': 'GMEvent', 'resourceVersion': '2.0'} for kind, num in events]
        write(f'objects/{name}/{name}.yy', data)
        self._register(name, f'objects/{name}/{name}.yy')

    def room_from(self, name, template, keep_objects, extra_instances, order_after=None):
        """Create a room by copying `template`'s settings and only the listed gameplay instances."""
        room = read(f'rooms/{template}/{template}.yy')
        room['name'] = room['%Name'] = name
        base = copy.deepcopy(room['layers'][0])
        keep = []
        for inst in base['instances']:
            if inst['objectId']['name'] in keep_objects:
                i = copy.deepcopy(inst)
                i['name'] = i['%Name'] = f"inst_{name.lower()}_{inst['objectId']['name'].lower()}"
                keep.append(i)
        tmpl = keep[0]
        for obj, x, y in extra_instances:
            i = copy.deepcopy(tmpl)
            i['name'] = i['%Name'] = f"inst_{name.lower()}_{obj.lower()}"
            i.update(x=float(x), y=float(y), objectId={'name': obj, 'path': f'objects/{obj}/{obj}.yy'}, imageIndex=0, imageSpeed=1.0,
                     scaleX=1.0, scaleY=1.0, rotation=0.0)
            keep.append(i)
        base['instances'] = keep
        room['layers'] = [base]
        room['instanceCreationOrder'] = [{'name': i['name'], 'path': f'rooms/{name}/{name}.yy'} for i in keep]
        write(f'rooms/{name}/{name}.yy', room)
        self._register(name, f'rooms/{name}/{name}.yy')
        nodes = self.yyp['RoomOrderNodes']
        if not any(n['roomId']['name'] == name for n in nodes):
            node = {'roomId': {'name': name, 'path': f'rooms/{name}/{name}.yy'}}
            idx = len(nodes)
            if order_after:
                for k, n in enumerate(nodes):
                    if n['roomId']['name'] == order_after:
                        idx = k + 1
            nodes.insert(idx, node)

    def save(self):
        self.yyp['resources'].sort(key=lambda x: x['id']['name'].lower())
        write('FirstGame.yyp', self.yyp)


def _pad(im, w, h):
    from PIL import Image
    out = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    out.paste(im, (0, 0))
    return out
