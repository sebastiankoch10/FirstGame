"""Isolated native Windows checks for the three playable levels (forest, swamp, ash-frost ruins).
Run: python tests/tools/run_level_smoke.py
Hooks (menu driver, input fixtures, captures) exist only in the copied test project under
%LOCALAPPDATA%/FirstGame-Tests/level-smoke/<stamp>. Nothing is built inside the project folder; the copied
project and the test executable are deleted after the run (logs, captures and the result JSON stay).
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

NAME = 'FirstGameLevelSmoke'


def write(p, s):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(s, encoding='utf-8')


def main():
    work = Path(os.environ['LOCALAPPDATA']) / 'FirstGame-Tests/level-smoke' / time.strftime('%Y%m%d-%H%M%S')
    project = work / 'project'
    project.mkdir(parents=True)
    for name in ('objects', 'scripts', 'sprites', 'sounds', 'tilesets', 'rooms', 'options'):
        shutil.copytree(ROOT / name, project / name)
    yyp = loads((ROOT / 'FirstGame.yyp').read_text(encoding='utf-8'))
    yyp['name'] = yyp['%Name'] = NAME
    write(project / f'{NAME}.yyp', dumps(yyp))
    p = project / 'options/main/options_main.yy'; d = loads(p.read_text(encoding='utf-8')); d['option_gameguid'] = '6f1c0e52-4a8b-4d0e-9c41-7a1f5b2d9e33'; write(p, dumps(d))
    p = project / 'options/windows/options_windows.yy'; d = loads(p.read_text(encoding='utf-8')); d['option_windows_display_name'] = 'FirstGame Level Smoke'; write(p, dumps(d))
    helper = project / 'scripts/gameplay/gameplay.gml'
    write(helper, helper.read_text(encoding='utf-8-sig') + '\n' + (ROOT / 'tests/level_harness.gml').read_text(encoding='utf-8-sig'))
    p = project / 'objects/ObjectMainMenu/Create_0.gml'
    write(p, 'global.master_volume=0;global.music_volume=0;global.effects_volume=0;\n' + p.read_text(encoding='utf-8-sig') +
          '\nexception_unhandled_handler(function(ex){show_debug_message("LEVEL_EXCEPTION "+json_stringify(ex));game_end();return true;});\n')
    for rel, prefix in (('objects/ObjectMainMenu/Step_0.gml', 'lv_menu_tick();\n'), ('objects/ObjectController/Step_0.gml', 'lv_controller_tick();\n')):
        p = project / rel; write(p, prefix + p.read_text(encoding='utf-8-sig'))
    p = project / 'objects/ObjectController/Draw_64.gml'; write(p, p.read_text(encoding='utf-8-sig') + '\nlv_render_capture();\n')
    p = project / 'objects/ObjectMainMenu/Draw_64.gml'; write(p, 'lv_menu_capture_begin();\n' + p.read_text(encoding='utf-8-sig') + '\nlv_menu_capture_end();\n')
    # show_error would block on a dialog: route it into the exception handler path instead.
    for path in project.rglob('*.gml'):
        code = path.read_text(encoding='utf-8-sig')
        for src, dst in (('keyboard_check_pressed', 'gp_key_pressed'), ('keyboard_check', 'gp_key_down'), ('mouse_check_button_pressed', 'gp_mouse_pressed'),
                         ('mouse_check_button', 'gp_mouse_down'), ('device_mouse_x_to_gui', 'gp_gui_x'), ('device_mouse_y_to_gui', 'gp_gui_y')):
            code = code.replace(src + '(', dst + '(')
        code = re.sub(r'\bmouse_x\b', 'gp_mouse_x()', code)
        code = re.sub(r'\bmouse_y\b', 'gp_mouse_y()', code)
        code = code.replace('show_error(', 'lv_show_error(')
        # Fixed 60 Hz frame time (like the boss suite): the enemy chase/strike checks count frames, so real frame-time
        # jitter of the test machine made them flaky (26.11.: construct/skeleton/knight failing in turn, 1 of 2 runs).
        code = re.sub(r'\bdelta_time\b', '16667', code)
        write(path, code)
    runner = GameMakerRunner(project, runtime_version='2024.14.4.268')
    igor = runner.find_gamemaker_runtime(); lic = runner.find_license_file()
    if not igor or not lic:
        raise RuntimeError('Installed Igor/runtime or license unavailable')
    for n in ('build', 'cache', 'temp'):
        (work / n).mkdir()
    cmd = [str(igor), f'/lf={lic}', f'/uf={lic.parent}', f'/rp={runner.runtime_path}', f'/project={project / (NAME + ".yyp")}', f'/cache={work / "cache"}',
           f'/temp={work / "temp"}', f'/of={work / "build" / NAME}', f'--tf={work / "build" / (NAME + ".zip")}', '--', 'Windows', 'PackageZip']
    print('Building isolated level smoke copy...', flush=True)
    with gamemaker_machine_operation('level-smoke-build', project):
        with (work / 'build.log').open('w', encoding='utf-8') as log:
            subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, cwd=project, timeout=900)
    exe = work / 'build' / f'{NAME}.exe'
    if 'Final Compile finished.' not in (work / 'build.log').read_text(encoding='utf-8', errors='replace') or not exe.is_file():
        raise RuntimeError(f'Build failed: {work / "build.log"}')
    print('Running native levels (menu -> world -> enemies -> hazards -> bosses -> restart)...', flush=True)
    started = time.time()
    si = subprocess.STARTUPINFO(); si.dwFlags |= subprocess.STARTF_USESHOWWINDOW; si.wShowWindow = 4
    with (work / 'runtime.log').open('w', encoding='utf-8') as log:
        proc = subprocess.Popen([str(exe), '-output', str(work / 'runner.log')], cwd=exe.parent, stdout=log, stderr=subprocess.STDOUT, startupinfo=si)
        try:
            code = proc.wait(timeout=600)
        except subprocess.TimeoutExpired:
            proc.kill(); proc.wait(); code = -1
    result = None
    texts = []
    for p in (work / 'runtime.log', work / 'runner.log'):
        if p.exists():
            texts.append(p.read_text(encoding='utf-8', errors='replace'))
    for text in texts:
        m = re.search(r'LEVEL_RESULT (\{[^\r\n]+\})', text)
        if m:
            result = json.loads(m.group(1)); break
    exc = [line for text in texts for line in text.splitlines() if 'LEVEL_EXCEPTION' in line]
    fails = [line for text in texts for line in text.splitlines() if 'LEVEL FAIL' in line]
    for save in Path(os.environ['LOCALAPPDATA']).glob('FirstGame*'):
        if save.is_dir():
            for c in save.rglob('lvcapture-*.png'):
                if c.stat().st_mtime >= started:
                    shutil.copyfile(c, work / c.name.removeprefix('lvcapture-'))
    if result is None:
        result = {'passed': False, 'checks': 0, 'failures': fails, 'error': 'no LEVEL_RESULT', 'exceptions': exc[:5]}
    result.update(exit_code=code, logs=str(work), exceptions=exc[:5], captures=sorted(p.name for p in work.glob('*.png')),
                  test_type='native Windows VM, injected input and menu driver; not manual play')
    result['passed'] = bool(result.get('passed')) and code == 0 and not exc
    write(ROOT / 'tests/reports/level-smoke-result.json', json.dumps(result, indent=2) + '\n')
    for n in ('project', 'build', 'cache', 'temp'):
        shutil.rmtree(work / n, ignore_errors=True)
    print(json.dumps({k: result.get(k) for k in ('passed', 'checks', 'failures', 'exceptions', 'metrics', 'captures', 'logs')}, indent=2), flush=True)
    if not result['passed']:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
