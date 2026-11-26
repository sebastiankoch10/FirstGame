"""IDE resource tree for FirstGame (virtual GameMaker folders, no file moves).

The GameMaker resource tree is only a view: every .yy names its parent folder, every folder is
listed in FirstGame.yyp. Code references resources by name, so sorting is safe for builds.

  python tests/tools/assets/ide_folders.py --check   # report misfiled resources, change nothing
  python tests/tools/assets/ide_folders.py --apply   # sort sprites and scripts, add folders, drop empty sprite folders

Importers call folder_for(kind, name) (see tests/tools/levels/gm_project.py) so new resources land
in the right folder. Rules are ordered; first match wins; unmatched resources keep their folder.
Folder names are ASCII on purpose (the IDE and some tools mangle umlauts).
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]

SPRITE_RULES = [
    (r'^spr_fg_swordsmanv3_', 'Sprites/Charaktere/Schwertkaempfer'),
    (r'^spr_fg_magev3_', 'Sprites/Charaktere/Zaubermeisterin'),
    (r'^spr_fg_rangerv3_', 'Sprites/Charaktere/Waldlaeufer'),
    (r'^(spr_eqv_icons_|spr_eq_icons)', 'Sprites/Ausruestung/Icons'),
    (r'^spr_eqv_swordsmanv3_', 'Sprites/Ausruestung/Schwertkaempfer'),
    (r'^spr_eqv_magev3_', 'Sprites/Ausruestung/Zaubermeisterin'),
    (r'^spr_eqv_rangerv3_', 'Sprites/Ausruestung/Waldlaeufer'),
    (r'^spr_master_skeleton_', 'Sprites/Gegner/Wald_Skelette'),
    (r'^spr_lv_en_', 'Sprites/Gegner/Sumpf_und_Ruinen'),
    # ArtPack 0.1 monster strips: still used by minibosses (boar, golem) and fallback spawns.
    (r'^spr_fg_(slime|mushroom|boar|goblin|bat|wisp|lizard|spider|skeleton|plant|beetle|imp|golem|blob|bandit|dragon)_',
     'Sprites/Gegner/ArtPack_0_1_Streifen'),
    (r'^(spr_fg_dragonboss|spr_fg_dragonextra|spr_dragon_fx|spr_fg_boss_dragon|spr_drg_)', 'Sprites/Bosse/Drache'),
    (r'^spr_bv2b_(fire|ice)_', 'Sprites/Bosse/Zwillingshexen'),
    (r'^spr_bv2b_behemoth_', 'Sprites/Bosse/Sumpfbehemoth'),
    (r'^spr_font_', 'Sprites/UI/Schrift'),
    (r'^spr_bv2_(twins|fire|ice)', 'Sprites/Bosse/Zwillingshexen'),
    (r'^spr_bv2_(behemoth|swamp|brood)', 'Sprites/Bosse/Sumpfbehemoth'),
    (r'^spr_fg_boss_', 'Sprites/Bosse/Minibosse'),
    (r'^(spr_class_fx|spr_v2_fx|spr_master_slash|spr_mage_star|spr_fg_firebolt|spr_fg_icebolt)', 'Sprites/Effekte'),
    (r'^spr_master_', 'Sprites/Welt/Wald'),
    (r'^spr_lv_sw_', 'Sprites/Welt/Sumpf'),
    (r'^spr_lv_af_', 'Sprites/Welt/Aschenfrost'),
    (r'^(spr_lv_forest|spr_fg_ground|spr_fg_landscape|spr_fg_environment)', 'Sprites/Welt/Allgemein'),
    (r'^(icon_v2_|icon_fg_)', 'Sprites/UI/Zauber_Icons'),
    (r'^(spr_fg_portrait|spr_fg_class_selection)', 'Sprites/UI/Menue'),
    (r'^(spr_fg_coin|spr_fg_chest|spr_fg_magnet)', 'Sprites/Beute'),
    # ArtPack 0.1 heroes: no code path selects these actors any more (player_artpack uses *v3).
    (r'^spr_fg_(warrior|mage|ranger|knightv2)_', 'Sprites/Legacy/ArtPack_0_1_Helden'),
]

SCRIPT_RULES = [
    (r'^(gameplay|gameplay_polish|reset_round|player_artpack|apply_passives|hud|progression_audit|render_pipeline|render_fx|fx_character)$', 'Skripte/Kern_und_Spieler'),
    (r'^(review_center|review_registry_data)$', 'Skripte/Entwicklung_Review'),
    (r'^(hazard_fx|fx_attacks)$', 'Skripte/Kampf_und_Klassen'),
    (r'^(master_combat|class_weapons|combat_feedback|attack_telegraph|attack_timeline)$', 'Skripte/Kampf_und_Klassen'),
    (r'^(spell|spell_v2|spell_v2_catalog|spell_vfx|spell_world_v2|spell_choices_v2|spell_ui_v2|cast_spell|get_spell_data|hotbar_assign|run_spell_stats|handle_chest_selection)$',
     'Skripte/Zauber'),
    (r'^(boss_|dragon_)', 'Skripte/Bosse'),
    (r'^(master_skeleton|survivor_balance)$', 'Skripte/Gegner'),
    (r'^(level_|master_world|atmosphere|weather|atmos_fx|fx_particles)', 'Skripte/Welt_und_Atmosphaere'),
    (r'^(talents|equipment|equipment_visual|equipment_visual_data|equipment_ui|equipment_attach_data)$', 'Skripte/Fortschritt_und_Ausruestung'),
    (r'^audio_manager$', 'Skripte/Audio'),
]

SHADER_RULES = [(r'^sh_', 'Shader')]

RULES = {'sprites': SPRITE_RULES, 'scripts': SCRIPT_RULES, 'shaders': SHADER_RULES}
# Two .yy dialects exist in the project ("parent":{"name":"x","path":"y",} and "parent": {"name": "x", "path": "y"}).
PARENT_RE = re.compile(r'("parent":\s*\{\s*"name":\s*")([^"]*)(",\s*"path":\s*")([^"]*)("\s*,?\s*\})')


def folder_for(kind: str, name: str) -> str | None:
    """Target IDE folder path (without 'folders/' and '.yy') or None if no rule matches."""
    for pattern, folder in RULES.get(kind, []):
        if re.match(pattern, name):
            return folder
    return None


def folder_entry(path: str) -> dict:
    name = path.rsplit('/', 1)[-1]
    return {'$GMFolder': '', '%Name': name, 'folderPath': f'folders/{path}.yy', 'name': name,
            'resourceType': 'GMFolder', 'resourceVersion': '2.0'}


def ensure_folders(yyp: dict, path: str) -> int:
    """Add path and all its ancestors to yyp['Folders']; returns the number added."""
    have = {f['folderPath'] for f in yyp['Folders']}
    parts = path.split('/'); added = 0
    for i in range(1, len(parts) + 1):
        sub = '/'.join(parts[:i])
        if f'folders/{sub}.yy' not in have:
            yyp['Folders'].append(folder_entry(sub)); have.add(f'folders/{sub}.yy'); added += 1
    return added


def set_parent_text(text: str, folder: str) -> str:
    name = folder.rsplit('/', 1)[-1]
    return PARENT_RE.sub(lambda m: f'{m.group(1)}{name}{m.group(3)}folders/{folder}.yy{m.group(5)}', text, count=1)


def current_parent(text: str) -> str | None:
    m = PARENT_RE.search(text)
    return m.group(4)[len('folders/'):-len('.yy')] if m else None


def main(argv):
    apply = '--apply' in argv
    sys.path.insert(0, str(Path.home() / 'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
    from gms_helpers.gm_json import dumps, loads  # noqa: E402
    yyp_path = ROOT / 'FirstGame.yyp'
    yyp = loads(yyp_path.read_text(encoding='utf-8-sig'))
    moved = {}; unmatched = []; total = 0
    for kind in ('sprites', 'scripts'):
        for d in sorted((ROOT / kind).iterdir()):
            yy = d / f'{d.name}.yy'
            if not yy.is_file():
                continue
            total += 1
            target = folder_for(kind, d.name)
            if target is None:
                unmatched.append(f'{kind}/{d.name}'); continue
            text = yy.read_text(encoding='utf-8-sig')
            if current_parent(text) == target:
                continue
            moved[target] = moved.get(target, 0) + 1
            if apply:
                ensure_folders(yyp, target)
                new = set_parent_text(text, target)
                if new == text:
                    raise RuntimeError(f'parent block not found in {yy}')
                yy.write_text(new, encoding='utf-8')
    dropped = []
    if apply:
        # Drop sprite/script folders that no resource and no subfolder uses any more.
        used = set()
        for kind in ('sprites', 'scripts', 'objects', 'sounds', 'rooms', 'tilesets', 'fonts', 'shaders', 'paths', 'sequences', 'animcurves', 'notes', 'extensions', 'timelines', 'particles'):
            base = ROOT / kind
            if not base.is_dir():
                continue
            for d in base.iterdir():
                yy = d / f'{d.name}.yy'
                if yy.is_file():
                    p = current_parent(yy.read_text(encoding='utf-8-sig'))
                    while p:
                        used.add(p); p = p.rsplit('/', 1)[0] if '/' in p else None
        keep = []
        for f in yyp['Folders']:
            path = f['folderPath'][len('folders/'):-len('.yy')]
            if '/' in path and path.split('/')[0] in ('Sprites', 'Skripte') and path not in used:
                dropped.append(path); continue
            keep.append(f)
        yyp['Folders'] = sorted(keep, key=lambda f: f['folderPath'].lower())
        yyp_path.write_text(dumps(yyp), encoding='utf-8')
    print(f'{total} sprites+scripts; {"moved" if apply else "would move"} {sum(moved.values())}; unmatched {len(unmatched)}')
    for k in sorted(moved):
        print(f'  {moved[k]:5d} -> {k}')
    if unmatched:
        print('unmatched (left where they are):', ', '.join(unmatched[:40]))
    if dropped:
        print('dropped empty folders:', ', '.join(dropped))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
