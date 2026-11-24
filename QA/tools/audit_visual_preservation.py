"""Read-only preservation and frame-content counts for the current visual audit."""
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None

def main():
    baseline = json.loads((ROOT/'QA/baseline/manifest.json').read_text(encoding='utf-8-sig'))
    before = loads((ROOT/'QA/baseline/project/FirstGame.yyp').read_text(encoding='utf-8-sig'))
    current = loads((ROOT/'FirstGame.yyp').read_text(encoding='utf-8-sig'))
    old = {x['id']['path']:x for x in before['resources']}
    new = {x['id']['path']:x for x in current['resources']}
    sprites = baseline['sprite_hashes']
    changed_pngs = [p for p,h in sprites.items() if digest(ROOT/p) != h]
    dragon = [p for p in sprites if 'dragon' in p.lower()]
    audit = json.loads((ROOT/'QA/data/visual-audit.json').read_text(encoding='utf-8-sig'))
    families = {}
    for family in sorted({x['family'] for x in audit['frames']}):
        frames = [x for x in audit['frames'] if x['family'] == family]
        families[family] = {'registered_frames':len(frames),
                            'unique_png_contents':len({digest(Path(x['path'])) for x in frames})}
    result = {
        'created_utc':datetime.now(timezone.utc).isoformat(),
        'resources':len(new),
        'resource_types':dict(Counter(p.split('/')[0] for p in new)),
        'resource_order_unchanged':before['resources'] == current['resources'],
        'resource_entries_unchanged':old == new,
        'resources_added':sorted(set(new)-set(old)),
        'resources_removed':sorted(set(old)-set(new)),
        'resources_modified':sorted(p for p in set(old)&set(new) if old[p] != new[p]),
        'changed_sources':[p for p,h in baseline['source_hashes'].items() if digest(ROOT/p) != h],
        'native_pngs_checked':len(sprites),
        'native_pngs_changed':changed_pngs,
        'dragon_pngs_checked':len(dragon),
        'dragon_pngs_changed':[p for p in dragon if p in changed_pngs],
        'frame_content_counts':families,
        'sprite_edge_filtering_enabled':sum(bool(x['edge_filtering']) for x in audit['sprites']),
    }
    result['status'] = 'PASS' if result['resource_entries_unchanged'] and not changed_pngs else 'REVIEW'
    (ROOT/'QA/data/visual-preservation.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(result,indent=2))

if __name__ == '__main__':
    main()
