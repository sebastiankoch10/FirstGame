"""CPU profile of the perf scenarios (tests/perf_harness.gml) without touching the project: in an isolated copy every
Step/Draw event and the listed functions are wrapped in get_timer() accumulators; the result is ms per frame and calls
per frame for each scenario (horde 150 enemies, twins/dragon phase 3 with 60 enemies).

  python tests/tools/profile_perf.py                        default function list (enemy step and draw path)
  python tests/tools/profile_perf.py --funcs a,b,c          profile these functions (must be `function name(` in scripts/)

Writes tests/reports/perf-profile.json. The wrappers add about 1 us per call, so compare runs of this tool with each
other, not with the plain perf suite. Run without parallel load (real frame time). Collision events keep `other`, so
they are timed inline and skipped when they contain `exit`.
"""
from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'tests/tools'))
import run_native_harness as rnh  # noqa: E402

DEFAULT_FUNCS = ['enemy_pursue', 'enemy_draw', 'enemy_reaction_step', 'scenery_resolve', 'enemy_motion_offset', 'level_enemy_step',
                 'master_skeleton_step', 'elite_step', 'elite_outline_draw', 'element_tint', 'master_shadow_draw']
EVENTS = ('Step_0', 'Draw_0', 'Draw_64', 'Draw_73', 'Draw_77', 'Collision_ObjectMonster', 'Collision_ObjectCoin', 'Collision_ObjectPlayer')


def instrument(project: Path, funcs: list[str]) -> None:
    keys, extra = [], []

    def key(k):
        k = re.sub(r'[^A-Za-z0-9_]', '_', k)
        keys.append(k)
        return k

    for obj in sorted((project / 'objects').iterdir()):
        if obj.name == 'ObjectMainMenu':
            continue
        for ev in EVENTS:
            p = obj / f'{ev}.gml'
            if not p.is_file():
                continue
            body = p.read_text(encoding='utf-8-sig')
            if re.search(r'^\s*(function |#macro)', body, re.M):
                continue
            if ev.startswith('Collision'):
                if re.search(r'\bexit\b', body):
                    continue
                k = key(f'ev_{obj.name}_{ev}')
                p.write_text(f'var __t=get_timer();\n{body}\nglobal.__pf_{k}+=get_timer()-__t;global.__pfn_{k}++;\n', encoding='utf-8')
                continue
            k = key(f'ev_{obj.name}_{ev}')
            extra.append(f'function __pfev_{k}() {{\n{body}\n}}\n')
            p.write_text(f'var __t=get_timer();__pfev_{k}();global.__pf_{k}+=get_timer()-__t;global.__pfn_{k}++;\n', encoding='utf-8')
    for f in funcs:
        for p in (project / 'scripts').rglob('*.gml'):
            code = p.read_text(encoding='utf-8-sig')
            m = re.search(r'^function ' + re.escape(f) + r'\(([^)]*)\)', code, re.M)
            if not m:
                continue
            params = m.group(1)
            names = ','.join(x.split('=')[0].strip() for x in params.split(',') if x.strip())
            k = key('fn_' + f)
            code = code[:m.start()] + f'function {f}__raw({params})' + code[m.end():]
            code += f'\nfunction {f}({params}) {{var __t=get_timer();var __r={f}__raw({names});global.__pf_{k}+=get_timer()-__t;global.__pfn_{k}++;return __r;}}\n'
            p.write_text(code, encoding='utf-8')
            break
        else:
            print(f'Funktion nicht gefunden: {f}')
    gp = project / 'scripts/gameplay/gameplay.gml'
    init = ''.join(f'global.__pf_{k}=0;global.__pfn_{k}=0;' for k in keys)
    rep = ','.join(f'{k}:[global.__pf_{k}/1000/_n,global.__pfn_{k}/_n]' for k in keys)
    code = gp.read_text(encoding='utf-8-sig') + '\n' + ''.join(extra) + f'\nfunction __pf_reset() {{{init}}}\nfunction __pf_report(_n) {{return {{{rep}}};}}\n'
    gp.write_text(init + '\n' + code, encoding='utf-8')   # globals exist before the first frame


def main() -> None:
    funcs = sys.argv[sys.argv.index('--funcs') + 1].split(',') if '--funcs' in sys.argv else DEFAULT_FUNCS
    harness = (ROOT / 'tests/perf_harness.gml').read_text(encoding='utf-8-sig')
    for old, new in (('if (global.pf_frame > 120 && global.pf_frame <= 720) {', 'if (global.pf_frame == 121) __pf_reset();\n    if (global.pf_frame > 120 && global.pf_frame <= 720) {'),
                     ('spikes_over_50ms: acc.spikes};', 'spikes_over_50ms: acc.spikes, prof: __pf_report(n)};')):
        if old not in harness:
            raise SystemExit(f'Anker im perf_harness fehlt: {old}')
        harness = harness.replace(old, new, 1)
    tmp = Path(os.environ['LOCALAPPDATA']) / 'FirstGame-Tests' / 'profile-harness.gml'
    tmp.parent.mkdir(parents=True, exist_ok=True)
    tmp.write_text(harness, encoding='utf-8')
    work, project = rnh.prepare_copy('perf-profile', str(tmp), 'pf', 'PERF', 'FirstGamePerf', [])
    instrument(project, funcs)
    exe = rnh.build_copy('perf-profile', work, project, 'FirstGamePerf')
    code, texts, _ = rnh.run_exe(work, exe, 'PERF', 900)
    result, exc, _ = rnh.parse_result(texts, 'PERF')
    rnh.cleanup(work)
    tmp.unlink(missing_ok=True)
    out = {'exit_code': code, 'exceptions': exc[:5], 'funcs': funcs, 'metrics': (result or {}).get('metrics'), 'logs': str(work)}
    rnh.write(ROOT / 'tests/reports/perf-profile.json', json.dumps(out, indent=1) + '\n')
    if not result:
        raise SystemExit(f'Kein PERF_RESULT; Logs: {work}')
    for scn, m in result['metrics'].items():
        if 'prof' not in m:   # e.g. menu_warmup
            continue
        print(f"\n## {scn}: fps_real {m['fps_real_mean']:.0f} (min {m['fps_real_min']:.0f}), Bildzeit {m['frame_ms_mean']:.1f} ms, Gegner {m['enemies']:.0f}")
        for k, (ms, n) in sorted(m['prof'].items(), key=lambda kv: -kv[1][0])[:20]:
            print(f'  {ms:7.3f} ms  x{n:7.1f}  {k}')


if __name__ == '__main__':
    main()
