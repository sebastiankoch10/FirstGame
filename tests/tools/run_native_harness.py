"""Generic isolated native GameMaker harness runner (Windows VM build of a project copy with injected test GML).
Builds and runs outside the project folder in %LOCALAPPDATA%/FirstGame-Tests/<name>/<stamp>; the copy is deleted afterwards.

  python tests/tools/run_native_harness.py feature   -> tests/feature_harness.gml  (prefix ft)
  python tests/tools/run_native_harness.py boss      -> tests/boss_harness.gml     (prefix bh)
  python tests/tools/run_native_harness.py visual    -> tests/visual_harness.gml   (prefix vh): layered characters, captures

The harness must define <prefix>_menu_tick, <prefix>_controller_tick, <prefix>_gui_capture_begin/_end, <prefix>_world_capture,
<prefix>_show_error and print "<TAG>_RESULT {json}" (TAG = FEATURE / BOSSMECH).
"""
from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path.home() / 'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gamemaker_machine_lock import gamemaker_machine_operation  # noqa: E402
from gms_helpers.gm_json import dumps, loads  # noqa: E402
from gms_helpers.runner import GameMakerRunner  # noqa: E402

SUITES = {
    'feature': ('tests/feature_harness.gml', 'ft', 'FEATURE', 'FirstGameFeatureSmoke', 900),
    'boss': ('tests/boss_harness.gml', 'bh', 'BOSSMECH', 'FirstGameBossMech', 3000),
    'visual': ('tests/visual_harness.gml', 'vh', 'VISUAL', 'FirstGameVisual', 900),
}
# Extra (regex, replacement) pairs applied to every GML file of the copy; used by record_scene.py for a fixed frame time.
EXTRA_REPLACEMENTS: list[tuple[str, str]] = []
# Suites whose checks compare boss and hazard timing with a bot that steps 1/60 s run on a fixed 60 Hz frame time, so
# frame-rate jitter of the test machine cannot move the results (twins repositioning metric drifted 10/9/8 of 17).
FIXED_DT_SUITES = {'boss'}


def write(p, s):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(s, encoding='utf-8')


def main():
    suite = sys.argv[1] if len(sys.argv) > 1 else 'feature'
    harness, px, tag, name, timeout = SUITES[suite]
    extra = list(EXTRA_REPLACEMENTS) + ([(r'\bdelta_time\b', '16667')] if suite in FIXED_DT_SUITES else [])
    work = Path(os.environ['LOCALAPPDATA']) / 'FirstGame-Tests' / suite / time.strftime('%Y%m%d-%H%M%S')
    project = work / 'project'
    project.mkdir(parents=True)
    for d in ('objects', 'scripts', 'sprites', 'sounds', 'tilesets', 'rooms', 'options'):
        shutil.copytree(ROOT / d, project / d)
    yyp = loads((ROOT / 'FirstGame.yyp').read_text(encoding='utf-8'))
    yyp['name'] = yyp['%Name'] = name
    write(project / f'{name}.yyp', dumps(yyp))
    p = project / 'options/main/options_main.yy'; d = loads(p.read_text(encoding='utf-8')); d['option_gameguid'] = '7a2d1f63-5b9c-4e1f-8d52-8b2a6c3e0f44'; write(p, dumps(d))
    helper = project / 'scripts/gameplay/gameplay.gml'
    write(helper, helper.read_text(encoding='utf-8-sig') + '\n' + (ROOT / harness).read_text(encoding='utf-8-sig'))
    p = project / 'objects/ObjectMainMenu/Create_0.gml'
    write(p, 'global.master_volume=0;global.music_volume=0;global.effects_volume=0;\n' + p.read_text(encoding='utf-8-sig') +
          f'\nexception_unhandled_handler(function(ex){{show_debug_message("{tag}_EXCEPTION "+json_stringify(ex));game_end();return true;}});\n')
    for rel, prefix in (('objects/ObjectMainMenu/Step_0.gml', f'{px}_menu_tick();\n'), ('objects/ObjectController/Step_0.gml', f'{px}_controller_tick();\n')):
        p = project / rel; write(p, prefix + p.read_text(encoding='utf-8-sig'))
    p = project / 'objects/ObjectController/Draw_64.gml'
    write(p, f'{px}_world_capture();{px}_gui_capture_begin();\n' + p.read_text(encoding='utf-8-sig') + f'\n{px}_gui_capture_end();\n')
    for path in project.rglob('*.gml'):
        code = path.read_text(encoding='utf-8-sig')
        for src, dst in (('keyboard_check_pressed', 'gp_key_pressed'), ('keyboard_check', 'gp_key_down'), ('mouse_check_button_pressed', 'gp_mouse_pressed'),
                         ('mouse_check_button', 'gp_mouse_down'), ('device_mouse_x_to_gui', 'gp_gui_x'), ('device_mouse_y_to_gui', 'gp_gui_y')):
            code = code.replace(src + '(', dst + '(')
        code = re.sub(r'\bmouse_x\b', 'gp_mouse_x()', code)
        code = re.sub(r'\bmouse_y\b', 'gp_mouse_y()', code)
        code = code.replace('show_error(', f'{px}_show_error(')
        for pattern, repl in extra:
            code = re.sub(pattern, repl, code)
        write(path, code)
    runner = GameMakerRunner(project, runtime_version='2024.14.4.268')
    igor = runner.find_gamemaker_runtime(); lic = runner.find_license_file()
    for n in ('build', 'cache', 'temp'):
        (work / n).mkdir()
    cmd = [str(igor), f'/lf={lic}', f'/uf={lic.parent}', f'/rp={runner.runtime_path}', f'/project={project / (name + ".yyp")}', f'/cache={work / "cache"}',
           f'/temp={work / "temp"}', f'/of={work / "build" / name}', f'--tf={work / "build" / (name + ".zip")}', '--', 'Windows', 'PackageZip']
    print(f'Building isolated {suite} copy...', flush=True)
    with gamemaker_machine_operation(f'{suite}-harness-build', project):
        with (work / 'build.log').open('w', encoding='utf-8') as log:
            subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, cwd=project, timeout=900)
    exe = work / 'build' / f'{name}.exe'
    blog = (work / 'build.log').read_text(encoding='utf-8', errors='replace')
    if 'Final Compile finished.' not in blog or not exe.is_file():
        errs = [l for l in blog.splitlines() if 'error' in l.lower()][:30]
        print('\n'.join(errs))
        for n in ('project', 'build', 'cache', 'temp'):
            shutil.rmtree(work / n, ignore_errors=True)
        raise RuntimeError(f'Build failed: {work / "build.log"}')
    print('Running native harness...', flush=True)
    started = time.time()
    si = subprocess.STARTUPINFO(); si.dwFlags |= subprocess.STARTF_USESHOWWINDOW; si.wShowWindow = 4
    with (work / 'runtime.log').open('w', encoding='utf-8') as log:
        proc = subprocess.Popen([str(exe), '-output', str(work / 'runner.log')], cwd=exe.parent, stdout=log, stderr=subprocess.STDOUT, startupinfo=si)
        try:
            code = proc.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            proc.kill(); proc.wait(); code = -1
    texts = [p.read_text(encoding='utf-8', errors='replace') for p in (work / 'runtime.log', work / 'runner.log') if p.exists()]
    result = None
    for text in texts:
        m = re.search(tag + r'_RESULT (\{[^\r\n]+\})', text)
        if m:
            result = json.loads(m.group(1)); break
    exc = [line for text in texts for line in text.splitlines() if f'{tag}_EXCEPTION' in line]
    fails = [line for text in texts for line in text.splitlines() if f'{tag} FAIL' in line]
    for save in Path(os.environ['LOCALAPPDATA']).glob('FirstGame*'):
        if save.is_dir() and save != work:
            for c in save.rglob(f'{px}capture-*.png'):
                if c.stat().st_mtime >= started:
                    shutil.move(c, work / c.name.removeprefix(f'{px}capture-'))  # move: no copies pile up in the save folder
    if result is None:
        result = {'passed': False, 'checks': 0, 'failures': fails, 'error': f'no {tag}_RESULT'}
    result.update(exit_code=code, logs=str(work), exceptions=exc[:5], captures=sorted(p.name for p in work.glob('*.png')),
                  test_type='native Windows VM, injected input; not manual play')
    result['passed'] = bool(result.get('passed')) and code == 0 and not exc
    write(ROOT / f'tests/reports/{suite}-harness-result.json', json.dumps(result, indent=2) + '\n')
    for n in ('project', 'build', 'cache', 'temp'):
        shutil.rmtree(work / n, ignore_errors=True)
    print(json.dumps({k: result.get(k) for k in ('passed', 'checks', 'failures', 'exceptions', 'metrics', 'captures', 'logs')}, indent=2), flush=True)
    if not result['passed']:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
