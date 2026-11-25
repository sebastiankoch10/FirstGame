"""FirstGame QA runner with tiers (Stufe 1-4), test selection from the diff and reuse of valid PASS results.

  python tests/tools/qa.py --plan            # show what would run for the current changes (no build)
  python tests/tools/qa.py                   # auto tier from `git diff HEAD` (+ untracked files), then run
  python tests/tools/qa.py --since <rev>     # changes since a commit instead of HEAD
  python tests/tools/qa.py --tier 3          # force a tier (1 small, 2 system, 3 large; 4 = simulations, only listed)
  python tests/tools/qa.py --suites feature,visual [--force]

Tiers
  0  only docs/reports changed                     -> nothing to run
  1  small fix (<=40 changed GML lines, 1 system)  -> the ONE most relevant suite (its build is the compile check)
  2  system change                                 -> all suites mapped to the touched systems
  3  architecture / >=3 systems / core files       -> every maintained suite (+ visual when art/drawing changed)
  static (validate_project, 1-3 min) is added only when resources (.yy/.yyp) were added/changed/removed, and always in tier 3.
  anchors (telemetry anchors of the simulations, seconds, no build) runs in every tier >= 1.
  4  simulations (run_cohort, run_boss_mc)         -> never automatic; commands are printed, the user must order them

A suite is skipped when its last PASS was produced from byte-identical build inputs (cache in
%LOCALAPPDATA%/FirstGame-Tests/qa-cache.json). --force ignores the cache. Every suite still builds its own
isolated copy outside the project folder. Output: one line per suite; details stay in the suite's report/log.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LOCAL = Path(os.environ.get('LOCALAPPDATA', str(Path.home()))) / 'FirstGame-Tests'
CACHE = LOCAL / 'qa-cache.json'
INDEX = LOCAL / 'qa-hash-index.json'
PY = sys.executable
BUILD_DIRS = ('objects', 'scripts', 'rooms', 'sprites', 'sounds', 'tilesets', 'options')

# name: command, report json (relative to ROOT), extra input files, typical minutes, what it covers
SUITES = {
    'static': dict(cmd=['QA/tools/validate_project.py'], report=None, inputs=[], minutes=.1,
                   covers='Ressourcen/yyp-Konsistenz (ohne Build)'),
    'anchors': dict(cmd=['QA/tools/check_telemetry_anchors.py'], report=None,
                    inputs=['QA/tools/check_telemetry_anchors.py', 'QA/tools/telemetry_injections.py'], minutes=.02,
                    covers='Telemetrie-Anker der Simulationen passen zum Code (ohne Build, Sekunden)'),
    'compile': dict(cmd=['tests/tools/levels/compile_check.py'], report=None, inputs=[], minutes=2,
                    covers='Igor-Build des echten Projekts (nur wenn keine Suite laeuft)'),
    'regression': dict(cmd=['QA/tools/run_qa_regression.py'], report='QA/data/regression.json',
                       inputs=['QA/tools/run_qa_regression.py', 'QA/tools/qa_regression_harness.gml', 'tests/boss_v2_harness.gml'],
                       minutes=4, covers='811 Kernpruefungen: Bewegung, Kampf, Zauber, Muenzen, Pause, Game Over, Bosse v2'),
    'feature': dict(cmd=['tests/tools/run_native_harness.py', 'feature'], report='tests/reports/feature-harness-result.json',
                    inputs=['tests/tools/run_native_harness.py', 'tests/feature_harness.gml'], minutes=3,
                    covers='Talente, Ausruestung, Zauber-VFX'),
    'boss': dict(cmd=['tests/tools/run_native_harness.py', 'boss'], report='tests/reports/boss-harness-result.json',
                 inputs=['tests/tools/run_native_harness.py', 'tests/boss_harness.gml'], minutes=6,
                 covers='Bossmuster, Ausweich-Orakel, Kiting, Aufholattacken'),
    'level': dict(cmd=['tests/tools/run_level_smoke.py'], report='tests/reports/level-smoke-result.json',
                  inputs=['tests/tools/run_level_smoke.py', 'tests/level_harness.gml'], minutes=6,
                  covers='3 Level: Menue->Welt->Gegner->Gefahren->Bosse->Neustart'),
    'classes': dict(cmd=['tests/tools/run_class_dragon_smoke.py'], report='tests/reports/class-dragon-native.json',
                    inputs=['tests/tools/run_class_dragon_smoke.py', 'tests/class_dragon_harness.gml'], minutes=3,
                    covers='Startwaffen/Kombos aller Klassen (Schwert 3, Magierin 4, Waldlaeufer 12), Warnflaechen-Rendering, Klassen-DPS'),
    'visual': dict(cmd=['tests/tools/run_native_harness.py', 'visual'], report='tests/reports/visual-harness-result.json',
                   inputs=['tests/tools/run_native_harness.py', 'tests/visual_harness.gml'], minutes=4,
                   covers='Charakter- und Ausruestungs-Layer: Laufzeit-Aufnahmen aller Klassen/Zustaende/Sets'),
}
MAINTAINED = ['regression', 'feature', 'boss', 'level', 'classes', 'visual']
# Not part of any tier (kept for history): reason
LEGACY = {
    'tests/tools/run_combat_smoke.py': 'veraltet, Absturz 0xC0000005 seit 2026-11-24, baut in output/',
    'tests/tools/run_boss_v2_smoke.py': 'doppelt: boss_v2_harness laeuft in regression mit',
    'tests/tools/run_player_animation_legacy.py': 'alte Figurenanimation vor v3',
}

# (path regex, system note in docs/Systeme, suites)
RULES = [
    (r'^scripts/(talents|equipment|spell_vfx)/', 'Talente/Ausruestung/Effekte', ['feature']),
    (r'^scripts/(equipment_visual|player_layers)/|^sprites/spr_(fg_(swordsmanv3|magev3|rangerv3)|eqv_)', 'Charakter & Ausruestungsgrafik', ['visual', 'classes']),
    (r'^scripts/player_artpack/|^objects/ObjectPlayer/Draw', 'Charakter & Ausruestungsgrafik', ['visual', 'classes']),
    (r'^scripts/(boss_|dragon_|attack_telegraph)|^objects/ObjectBossMonster/', 'Bosse', ['boss', 'regression']),
    (r'^scripts/(level_|survivor_balance|master_world|master_skeleton|weather)|^rooms/|^objects/(ObjectLevel|ObjectMaster|ObjectSpawner|ObjectEnvironment)', 'Level/Gegner', ['level']),
    (r'^scripts/(class_weapons|master_combat)/|^objects/(ObjectSwordHitbox|ObjectLightningball)/', 'Klassen & Startwaffen', ['classes', 'regression']),
    (r'^scripts/(spell|spell_v2|spell_v2_catalog|spell_choices_v2|apply_passives|cast_spell|get_spell_data|run_spell_stats|hotbar_assign|spell_world_v2|spell_ui_v2)/', 'Zauber & Passiva', ['regression', 'feature']),
    (r'^scripts/(gameplay|gameplay_polish|reset_round|progression_audit|hud|combat_feedback|audio_manager|atmosphere|handle_chest_selection)/', 'Kern/UI/Ablauf', ['regression']),
    (r'^objects/(ObjectController|ObjectMainMenu|ObjectPlayer)/', 'Kern/UI/Ablauf', ['regression']),
    (r'^objects/', 'Objekte', ['regression']),
    (r'^scripts/', 'Sonstige Skripte', ['regression']),
    (r'^(sprites|sounds|tilesets|options)/|^FirstGame\.yyp$', 'Assets/Projekt', ['static']),
    (r'^tests/(\w+)_harness\.gml$|^tests/tools/run_', 'Testcode', []),
]
CORE = re.compile(r'^(objects/ObjectController/Step_0|objects/ObjectPlayer/Step_0|scripts/gameplay/|scripts/reset_round/|scripts/apply_passives/|FirstGame\.yyp)')
HARNESS_SUITE = {'tests/feature_harness.gml': 'feature', 'tests/boss_harness.gml': 'boss', 'tests/level_harness.gml': 'level',
                 'tests/class_dragon_harness.gml': 'classes', 'tests/visual_harness.gml': 'visual',
                 'QA/tools/qa_regression_harness.gml': 'regression', 'tests/boss_v2_harness.gml': 'regression',
                 'QA/tools/run_qa_regression.py': 'regression', 'tests/tools/run_level_smoke.py': 'level',
                 'tests/tools/run_class_dragon_smoke.py': 'classes', 'tests/tools/run_native_harness.py': 'feature'}
# Most relevant single suite per system for tier 1
TIER1_PICK = ['classes', 'visual', 'feature', 'boss', 'level', 'regression']


def git(*a):
    r = subprocess.run(['git', '-c', 'core.quotepath=off', *a], cwd=ROOT, capture_output=True, text=True, encoding='utf-8', errors='replace')
    return r.stdout


def changed_files(since: str):
    """[(path, changed_lines)] for tracked changes since `since` plus untracked files."""
    out = {}
    for line in git('diff', '--numstat', '--no-renames', since).splitlines():
        a, b, p = (line.split('\t') + ['', ''])[:3]
        out[p] = (int(a) if a.isdigit() else 50) + (int(b) if b.isdigit() else 50)
    for p in git('ls-files', '--others', '--exclude-standard').splitlines():
        f = ROOT / p
        try:
            out[p] = sum(1 for _ in f.open(encoding='utf-8', errors='ignore')) if p.endswith(('.gml', '.py', '.yy')) else 50
        except OSError:
            out[p] = 50
    return sorted(out.items())


def classify(files):
    systems, suites, gml_lines = set(), set(), 0
    art = core = res = False
    for p, n in files:
        if p.endswith('.gml'):
            gml_lines += n
        if p in HARNESS_SUITE:
            suites.add(HARNESS_SUITE[p]); systems.add('Testcode'); continue
        if p.startswith('sprites/spr_fg_') or p.startswith('sprites/spr_eqv_') or 'Draw' in p or 'player_layers' in p or 'equipment_visual' in p:
            art = True
        if CORE.match(p) and n > 40:
            core = True
        if p.endswith(('.yy', '.yyp')) or (re.match(r'^(sprites|sounds|objects|scripts|rooms|tilesets)/', p) and not (ROOT / p).exists()):
            res = True
        for rx, sysname, ss in RULES:
            if re.search(rx, p):
                systems.add(sysname); suites.update(ss); break
    return systems, suites, gml_lines, art, core, res


def auto_tier(files, systems, gml_lines, core):
    relevant = [p for p, _ in files if re.match(r'^(objects|scripts|rooms|sprites|sounds|tilesets|options|tests|QA/tools)/|^FirstGame\.yyp$', p)]
    if not relevant:
        return 0
    if core or len(systems - {'Testcode', 'Assets/Projekt'}) >= 3:
        return 3
    if gml_lines <= 40 and len(systems) <= 1 and not any(p == 'FirstGame.yyp' for p in relevant):
        return 1
    return 2


def plan(tier, suites, art, res):
    """static (validate_project, 1-3 min) only when resources (.yy/.yyp) changed; every native suite build is itself a compile check."""
    st = ['anchors'] + (['static'] if res or tier >= 3 else [])
    if tier <= 0:
        return []
    if tier == 1:
        pick = next((s for s in TIER1_PICK if s in suites), None)
        return st + ([pick] if pick else ['compile'])
    if tier == 2:
        chosen = [s for s in MAINTAINED if s in suites]
        return st + (chosen or ['compile'])
    return st + [s for s in MAINTAINED if s != 'visual' or art or 'visual' in suites]


# ---------------- input hashing (stat index keeps this ~1 s) ----------------
def file_hash(p: Path, idx: dict):
    st = p.stat(); key = str(p)
    e = idx.get(key)
    if e and e[0] == st.st_size and e[1] == st.st_mtime_ns:
        return e[2]
    h = hashlib.sha256(p.read_bytes()).hexdigest()
    idx[key] = [st.st_size, st.st_mtime_ns, h]
    return h


def inputs_hash(extra):
    idx = json.loads(INDEX.read_text(encoding='utf-8')) if INDEX.exists() else {}
    h = hashlib.sha256()
    files = [ROOT / 'FirstGame.yyp'] + [p for d in BUILD_DIRS for p in sorted((ROOT / d).rglob('*')) if p.is_file()]
    files += [ROOT / e for e in extra if (ROOT / e).is_file()]
    for p in files:
        h.update(str(p.relative_to(ROOT)).replace('\\', '/').encode()); h.update(file_hash(p, idx).encode())
    LOCAL.mkdir(parents=True, exist_ok=True)
    INDEX.write_text(json.dumps(idx), encoding='utf-8')
    return h.hexdigest()


def load_cache():
    try:
        return json.loads(CACHE.read_text(encoding='utf-8'))
    except (OSError, ValueError):
        return {}


def run_suite(name, force, cache):
    s = SUITES[name]
    script = ROOT / s['cmd'][0]
    if not script.is_file() or any(not (ROOT / i).is_file() for i in s['inputs']):
        return dict(suite=name, status='NOT RUN', detail='Suite-Dateien fehlen')
    key = inputs_hash(s['inputs'])
    c = cache.get(name)
    if key and not force and c and c.get('hash') == key and c.get('status') == 'PASS':
        return dict(suite=name, status='PASS', cached=True, checks=c.get('checks'), detail=f"wiederverwendet vom {c.get('date')} (Eingaben unveraendert)")
    LOCAL.mkdir(parents=True, exist_ok=True)
    log = LOCAL / f'qa-{name}.log'
    t = time.time()
    with log.open('w', encoding='utf-8') as fh:
        code = subprocess.run([PY, *[str(ROOT / s['cmd'][0])], *s['cmd'][1:]], cwd=ROOT, stdout=fh, stderr=subprocess.STDOUT).returncode
    secs = time.time() - t
    res = dict(suite=name, status='PASS' if code == 0 else 'FAIL', seconds=round(secs), log=str(log))
    if s['report'] and (ROOT / s['report']).is_file() and (ROOT / s['report']).stat().st_mtime >= t - 1:
        r = json.loads((ROOT / s['report']).read_text(encoding='utf-8'))
        res['checks'] = r.get('checks')
        fails = r.get('failures') or []
        if fails:
            res['detail'] = '; '.join(str(f)[:140] for f in fails[:3]) + (f' (+{len(fails) - 3})' if len(fails) > 3 else '')
        if r.get('exceptions'):
            res['detail'] = (res.get('detail', '') + ' EXC ' + str(r['exceptions'][0])[:160]).strip()
        if not r.get('passed'):
            res['status'] = 'FAIL'
    elif s['report']:
        res['status'] = 'FAIL' if code else 'BLOCKED'
        tail = log.read_text(encoding='utf-8', errors='replace').strip().splitlines()[-3:]
        res['detail'] = ' | '.join(l[:160] for l in tail)
    elif code:
        tail = log.read_text(encoding='utf-8', errors='replace').strip().splitlines()[-4:]
        res['detail'] = ' | '.join(l[:160] for l in tail)
    if key:
        cache[name] = dict(hash=key, status=res['status'], checks=res.get('checks'), date=time.strftime('%Y-%m-%d %H:%M'))
        CACHE.write_text(json.dumps(cache, indent=1), encoding='utf-8')
    return res


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--plan', action='store_true'); ap.add_argument('--since', default='HEAD')
    ap.add_argument('--tier', type=int); ap.add_argument('--suites'); ap.add_argument('--force', action='store_true')
    a = ap.parse_args()
    files = changed_files(a.since)
    systems, suites, gml_lines, art, core, res = classify(files)
    tier = a.tier if a.tier is not None else auto_tier(files, systems, gml_lines, core)
    todo = [s.strip() for s in a.suites.split(',')] if a.suites else plan(tier, suites, art, res)
    print(f"QA Stufe {tier} | {len(files)} geaenderte Dateien seit {a.since} | {gml_lines} GML-Zeilen | Systeme: {', '.join(sorted(systems)) or '-'}")
    if tier >= 4:
        print('Stufe 4 laeuft nie automatisch. Auf ausdruecklichen Auftrag z. B.:\n'
              '  python QA/tools/run_cohort.py --reuse <Artefakt> --phase holdout ...   (vollstaendige Runs)\n'
              '  python QA/tools/run_boss_mc.py --reuse <Artefakt> ...                  (isolierte Bosskaempfe)')
        todo = plan(3, suites, art, res)
    if not todo:
        print('Nichts zu testen (nur Doku/Berichte geaendert).'); return 0
    est = sum(SUITES[s]['minutes'] for s in todo)
    print('Plan: ' + ', '.join(todo) + f'  (~{est:.0f} min ohne Cache)')
    for s in todo:
        print(f'  - {s:10s} {SUITES[s]["covers"]}')
    if a.plan:
        return 0
    cache = load_cache(); results = []
    for s in todo:
        r = run_suite(s, a.force, cache); results.append(r)
        extra = f" {int(r['checks'])} Pruefungen" if r.get('checks') else ''
        took = ' (Cache)' if r.get('cached') else (f" {r['seconds']}s" if 'seconds' in r else '')
        print(f"{r['status']:8s} {s:10s}{extra}{took}" + (f" | {r['detail']}" if r.get('detail') else ''), flush=True)
    summary = dict(date=time.strftime('%Y-%m-%d %H:%M'), commit=git('rev-parse', '--short', 'HEAD').strip(), tier=tier,
                   dirty=bool(files), results=results)
    (ROOT / 'tests/reports').mkdir(parents=True, exist_ok=True)
    (ROOT / 'tests/reports/qa-last.json').write_text(json.dumps(summary, indent=1, ensure_ascii=False) + '\n', encoding='utf-8')
    bad = [r for r in results if r['status'] != 'PASS']
    print('GESAMT: ' + ('PASS' if not bad else 'FAIL/BLOCKED: ' + ', '.join(r['suite'] for r in bad)))
    return 1 if bad else 0


if __name__ == '__main__':
    raise SystemExit(main())
