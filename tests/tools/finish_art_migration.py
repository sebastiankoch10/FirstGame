"""Deterministic ArtPack import and editable room bake. Run after prepare_artpack.ps1."""
import copy
import json
import math
from pathlib import Path
import random
import re
import shutil
import subprocess
import uuid
import zipfile
import sys

# Preserve GameMaker's compact native layout when its local tooling is installed.
sys.path.insert(0, str(Path.home() / 'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import dumps as gm_dumps

ROOT = Path(__file__).resolve().parents[2]
import sys as _sys_ap; _sys_ap.path.insert(0, str(ROOT / 'tests' / 'tools' / 'assets')); import art_paths as AP  # noqa: E402
def read(path):
    return json.loads(re.sub(r',\s*([}\]])', r'\1', (ROOT / path).read_text(encoding='utf-8-sig')))
def write(path, data):
    path = ROOT / path
    path.parent.mkdir(parents=True, exist_ok=True)
    text = gm_dumps(data) if path.suffix in ('.yy','.yyp') else json.dumps(data, ensure_ascii=False, indent=2) + '\n'
    path.write_text(text, encoding='utf-8')
def ref(kind, name):
    return dict(name=name, path=f'{kind}/{name}/{name}.yy')

project = read('FirstGame.yyp')
template = read('sprites/spr_fg_coin_idle/spr_fg_coin_idle.yy')

def sprite(name, sources, width=64, height=64, origin=(32, 52)):
    data = copy.deepcopy(template)
    data['name'] = data['%Name'] = data['sequence']['name'] = name
    data.update(width=width, height=height, bboxMode=0, bbox_left=0, bbox_top=0,
                bbox_right=width-1, bbox_bottom=height-1, origin=9)
    seq = data['sequence']
    seq.update(xorigin=origin[0], yorigin=origin[1], seqWidth=float(width), seqHeight=float(height), length=float(len(sources)))
    frame_template = copy.deepcopy(data['frames'][0])
    key_template = copy.deepcopy(seq['tracks'][0]['keyframes']['Keyframes'][0])
    data['frames'] = []
    keys = []
    layer = data['layers'][0]['name']
    folder = ROOT / 'sprites' / name
    folder.mkdir(exist_ok=True)
    for i, source in enumerate(sources):
        uid = str(uuid.uuid5(uuid.NAMESPACE_URL, f'FirstGame/{name}/{i}'))
        frame = copy.deepcopy(frame_template)
        frame['name'] = frame['%Name'] = uid
        data['frames'].append(frame)
        key = copy.deepcopy(key_template)
        key['id'] = str(uuid.uuid5(uuid.NAMESPACE_URL, f'FirstGame/key/{name}/{i}'))
        key['Key'] = float(i)
        key['Channels']['0']['Id'] = dict(name=uid, path=f'sprites/{name}/{name}.yy')
        keys.append(key)
        shutil.copyfile(source, folder / f'{uid}.png')
        dest = folder / 'layers' / uid
        dest.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, dest / f'{layer}.png')
    seq['tracks'][0]['keyframes']['Keyframes'] = keys
    write(f'sprites/{name}/{name}.yy', data)
    if not any(r['id']['name'] == name for r in project['resources']):
        project['resources'].append(dict(id=ref('sprites', name)))

art = AP.ART
sprite('spr_fg_landscape', [art / 'environment' / f'detail_{i:02}.png' for i in range(13)])
sprite('spr_fg_chest', [art / 'environment' / 'detail_13.png'])
sprite('spr_fg_firebolt', [art / 'environment' / 'detail_14.png'], origin=(32,32))
sprite('spr_fg_icebolt', [art / 'environment' / 'detail_15.png'], origin=(32,32))
sprite('spr_fg_ground_v2', [art / 'environment' / 'ground_tiles_v2.png'], 256, 256, (0,0))
tileset = read('tilesets/Grass/Grass.yy')
tileset['spriteId'] = ref('sprites', 'spr_fg_ground_v2')
write('tilesets/Grass/Grass.yy', tileset)
for obj, spr in [('ObjectEnvironmentDecoration','spr_fg_landscape'), ('ObjectChest','spr_fg_chest'), ('ObjectFireball','spr_fg_firebolt'), ('ObjectIceball','spr_fg_icebolt'), ('ObjectLightningball','spr_fg_icebolt')]:
    data = read(f'objects/{obj}/{obj}.yy')
    data['spriteId'] = ref('sprites', spr)
    write(f'objects/{obj}/{obj}.yy', data)

base = read('rooms/Room1/Room1.yy')
game_layer = next(l for l in base['layers'] if l['resourceType'] == 'GMRInstanceLayer')
game_layer['instances'] = [i for i in game_layer['instances'] if i['objectId']['name'] != 'ObjectEnvironmentDecoration']
tile_template = next(l for l in base['layers'] if l['resourceType'] == 'GMRTileLayer')
inst_template = copy.deepcopy(game_layer['instances'][0])
stats = []
for level, name in enumerate(('Room1', 'RoomCrypt', 'RoomRuins')):
    rng = random.Random(20261122 + level * 7919)
    room = copy.deepcopy(base)
    room['name'] = room['%Name'] = name
    active = copy.deepcopy(game_layer)
    active['name'] = active['%Name'] = 'Instances'
    for inst in active['instances']:
        # Room-local IDs remain stable and unique across rooms.
        inst['name'] = inst['%Name'] = re.sub(r'_l\d+$', '', inst['name']) + f'_l{level}'
    def field(x,y):
        return math.sin(x/13+level)*0.45 + math.cos(y/17-level)*0.35 + math.sin((x+y)/9)*0.2
    def path(x,y):
        horizontal = abs(y - (62 + 9*math.sin(x/21 + level))) < 2.4
        vertical = abs(x - (66 + 12*math.sin(y/25 + level))) < 1.8
        return horizontal or vertical
    ground, details, paths = [], [], []
    for y in range(128):
        for x in range(128):
            ground.append(1 + (int((field(x,y)+1)*2) + rng.randrange(3)) % 8)
            details.append(rng.randrange(9,13) if field(x,y) > .38 and rng.random()<.42 else 0)
            mask = sum(bit for bit,dx,dy in ((1,0,-1),(2,1,0),(4,0,1),(8,-1,0)) if path(x+dx,y+dy))
            paths.append(17+mask if path(x,y) else 0)
    layers = [active]
    for label, depth, values in [('Ground',400,ground),('Ground_Details',300,details),('Paths',200,paths)]:
        layer = copy.deepcopy(tile_template)
        layer.update(name=label, depth=depth)
        layer['%Name'] = label
        layer['tiles']['TileSerialiseData'] = values
        layers.append(layer)
    groups = {label: [] for label in ('Vegetation','Decorations','Obstacles','Collisions')}
    occupied = []
    # Each landscape has its own plant/rock/ruin distribution, across the full room.
    for cluster in range(180):
        cx, cy = rng.uniform(80,4016), rng.uniform(80,4016)
        category = rng.choices(['tree','flower','bush','rock','ruin'], [30,30,22,12+level*3,6+level*5])[0]
        for _ in range(rng.randrange(3,9)):
            x,y = round(cx+rng.gauss(0,100)), round(cy+rng.gauss(0,100))
            if not (48<x<4048 and 64<y<4048): continue
            if (x-2112)**2+(y-1952)**2 < 145**2 or path(x/32,y/32): continue
            spacing = 68 if category=='tree' else 35
            if any((x-a)**2+(y-b)**2 < max(spacing,s)**2 for a,b,s in occupied): continue
            occupied.append((x,y,spacing))
            index = {'tree':rng.randrange(4),'flower':rng.choice([6,7]),'bush':rng.choice([4,5]),'rock':rng.choice([8,9]),'ruin':rng.choice([10,11,12])}[category]
            inst = copy.deepcopy(inst_template)
            uid = f'inst_land_{level}_{len(occupied)}'
            scale = {'tree':1.8,'flower':0.55,'bush':0.9,'rock':1.0,'ruin':1.2}[category]
            inst.update(name=uid, x=x, y=y, imageIndex=index, imageSpeed=0.0, scaleX=scale, scaleY=scale)
            inst['%Name'] = uid
            inst['objectId'] = ref('objects','ObjectEnvironmentDecoration')
            label = 'Vegetation' if category in ('tree','bush') else ('Decorations' if category=='flower' else 'Obstacles')
            groups[label].append(inst)
    for index,(label,instances) in enumerate(groups.items()):
        layer = copy.deepcopy(active)
        layer.update(name=label, depth=100+index, instances=instances)
        layer['%Name'] = label
        layers.append(layer)
    room['layers'] = sorted(layers, key=lambda l:l['depth'])
    all_instances = [i for l in room['layers'] for i in l.get('instances',[])]
    room['instanceCreationOrder'] = [dict(name=i['name'],path=f'rooms/{name}/{name}.yy') for i in all_instances]
    write(f'rooms/{name}/{name}.yy',room)
    if not any(r['id']['name']==name for r in project['resources']):
        project['resources'].append(dict(id=ref('rooms',name)))
        project['RoomOrderNodes'].append(dict(roomId=ref('rooms',name)))
    stats.append(dict(room=name, seed=20261122+level*7919, decorations=len(occupied), tiles=16384))

# Replace every old sprite only after proving HEAD contains a restorable copy.
old = [r['id']['name'] for r in project['resources'] if r['id']['path'].startswith('sprites/') and not r['id']['name'].startswith(('spr_fg_','icon_fg_'))]
old += ['spr_fg_environment_tiles','spr_fg_environment_decorations']
previous_report = ROOT/'tests/reports/art-migration-assets.json'
if previous_report.exists():
    old += json.loads(previous_report.read_text(encoding='utf-8'))['deleted_sprites']
old = sorted(set(old))
references = []
for path in list((ROOT/'objects').rglob('*')) + list((ROOT/'scripts').rglob('*')) + list((ROOT/'rooms').rglob('*.yy')):
    if path.is_file() and path.suffix in ('.gml','.yy'):
        for symbol in old:
            if re.search(r'(?<![\w])'+re.escape(symbol)+r'(?![\w])', path.read_text(encoding='utf-8-sig')):
                references.append(f'{path.relative_to(ROOT)}: {symbol}')
if references:
    raise RuntimeError('Old references remain: '+repr(references))
backup = ROOT/'output'/'art-migration-backup.zip'
backup.parent.mkdir(exist_ok=True)
if not backup.exists():
    with zipfile.ZipFile(backup,'w',zipfile.ZIP_DEFLATED) as archive:
        archive.writestr('HEAD.txt',subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT))
        archive.writestr('working.patch',subprocess.check_output(['git','diff','--binary'],cwd=ROOT))
        for symbol in old:
            for path in (ROOT/'sprites'/symbol).rglob('*'):
                if path.is_file(): archive.write(path,path.relative_to(ROOT).as_posix())
project['resources'] = [r for r in project['resources'] if r['id']['name'] not in old]
project['resources'].sort(key=lambda r:r['id']['name'].lower())
write('FirstGame.yyp',project)
for symbol in old:
    folder = ROOT/'sprites'/symbol
    if not folder.exists(): continue
    tracked = subprocess.check_output(['git','ls-tree','-r','--name-only','HEAD',f'sprites/{symbol}'],cwd=ROOT).strip()
    if not tracked and not symbol.startswith('spr_fg_environment_'):
        raise RuntimeError(f'Not recoverable in Git: {symbol}')
    assert folder.resolve().is_relative_to((ROOT/'sprites').resolve())
    shutil.rmtree(folder)
write('tests/reports/art-migration-assets.json',dict(levels=stats,deleted_sprites=old))
print(json.dumps(stats,indent=2))
