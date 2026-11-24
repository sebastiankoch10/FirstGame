"""Keep the files changed by the art migration in GameMaker's native format."""
from pathlib import Path
import json
import re
import sys
sys.path.insert(0, str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import dumps
root=Path(__file__).resolve().parents[2]
paths=[root/'FirstGame.yyp',root/'tilesets/Grass/Grass.yy']
paths += [root/f'rooms/{name}/{name}.yy' for name in ('Room1','RoomCrypt','RoomRuins')]
paths += [root/f'sprites/{name}/{name}.yy' for name in ('spr_fg_landscape','spr_fg_ground_v2','spr_fg_firebolt','spr_fg_icebolt','spr_fg_chest')]
paths += [root/f'objects/{name}/{name}.yy' for name in ('ObjectEnvironmentDecoration','ObjectChest','ObjectFireball','ObjectIceball','ObjectLightningball')]
for path in paths:
    data=json.loads(re.sub(r',\s*([}\]])',r'\1',path.read_text(encoding='utf-8-sig')))
    path.write_text(dumps(data),encoding='utf-8')
