"""Legacy manual-attack fixture from before the auto-weapon redesign; NOT a current gameplay gate."""
"""Local Windows VM runtime smoke test, no agents and no production test switches.

Run: python tests/tools/run_player_smoke.py
Builds an isolated copy, simulates real player Step inputs for all three classes,
and requires 720 actual frames AND >=10 seconds per class plus explicit results.
This is a technical runtime start, NOT an end-to-end menu test.
"""
from pathlib import Path
import json
import os
import re
import shutil
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads, dumps
from gms_helpers.runner import GameMakerRunner
from gms_helpers.gamemaker_machine_lock import gamemaker_machine_operation

def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8')

def main():
    # Each run has a new directory, so a stale executable can never pass.
    work = ROOT/'output/player-smoke'/time.strftime('%Y%m%d-%H%M%S')
    project = work/'project'
    project.mkdir(parents=True)
    for name in ('objects','scripts','sprites','tilesets','rooms','options'):
        shutil.copytree(ROOT/name, project/name)
    yyp = loads((ROOT/'FirstGame.yyp').read_text(encoding='utf-8'))
    yyp['name'] = yyp['%Name'] = 'FirstGamePlayerSmoke'
    write(project/'FirstGamePlayerSmoke.yyp', dumps(yyp))
    options_path = project/'options/main/options_main.yy'
    options = loads(options_path.read_text(encoding='utf-8'))
    options['option_gameguid'] = 'f7f6de45-d2e5-49a7-aeaa-882243be8405'
    write(options_path, dumps(options))
    windows_path = project/'options/windows/options_windows.yy'
    options = loads(windows_path.read_text(encoding='utf-8'))
    options['option_windows_display_name'] = 'FirstGame Player Smoke Test'
    write(windows_path, dumps(options))

    menu = project/'objects/ObjectMainMenu/Create_0.gml'
    write(menu, menu.read_text(encoding='utf-8') + '''
global.smoke_classes = ["Sword", "Mage", "Ranger"];
global.smoke_actors = ["warrior", "mage", "ranger"];
global.smoke_class_index = 0;
global.smoke_frame = 0;
global.smoke_results = [];
global.smoke_failure = "";
global.smoke_started = current_time;
global.selected_character = "Sword";
global.selected_level = 0;
reset_round();
room_goto(Room1);
''')
    helper = project/'scripts/player_artpack/player_artpack.gml'
    write(helper, helper.read_text(encoding='utf-8') + '\n' + (ROOT/'tests/player_smoke_harness.gml').read_text(encoding='utf-8'))
    step = project/'objects/ObjectPlayer/Step_0.gml'
    code = step.read_text(encoding='utf-8')
    code = code.replace('keyboard_check_pressed(', 'smoke_key_pressed(').replace('keyboard_check(', 'smoke_key_down(').replace('mouse_check_button_pressed(', 'smoke_mouse_pressed(')
    # Aim cycles through all four views; no OS-level or user-window input is used.
    code = code.replace('aim_angle = point_direction(x, y, mouse_x, mouse_y);', 'aim_angle = ((global.smoke_frame div 120) mod 4) * 90;')
    write(step, 'smoke_begin_step();\n' + code + '\nsmoke_end_step(visual_action);\n')

    runner = GameMakerRunner(project, runtime_version='2024.14.4.268')
    igor = runner.find_gamemaker_runtime()
    license_file = runner.find_license_file()
    if not igor or not license_file:
        raise RuntimeError('Installed Igor/runtime or GameMaker license unavailable')
    build = work/'build'
    for name in ('cache','temp'):
        (build/name).mkdir(parents=True)
    cmd = [str(igor),f'/lf={license_file}',f'/uf={license_file.parent}',f'/rp={runner.runtime_path}',
           f'/project={project/"FirstGamePlayerSmoke.yyp"}', f'/cache={build/"cache"}',f'/temp={build/"temp"}',
           f'/of={build/"FirstGamePlayerSmoke"}',f'--tf={build/"FirstGamePlayerSmoke.zip"}', '--','Windows','PackageZip']
    print('Building isolated Windows smoke executable...', flush=True)
    with gamemaker_machine_operation('player-smoke-build',project):
        with (work/'build.log').open('w',encoding='utf-8') as log:
            result = subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,cwd=project,timeout=120)
    log_text = (work/'build.log').read_text(encoding='utf-8',errors='replace')
    exe = build/'FirstGamePlayerSmoke.exe'
    if 'Final Compile finished.' not in log_text or not exe.is_file():
        raise RuntimeError(f'Fresh smoke build failed: {work/"build.log"}')
    if not (build/'data.win').is_file():
        raise RuntimeError('Fresh data.win missing')
    print('Running actual Windows VM: three classes, >=10 seconds each...',flush=True)
    started = time.time()
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 7  # minimized, no activation; never steals the user's game input
    runtime_log = work/'runtime.log'
    with runtime_log.open('w',encoding='utf-8') as log:
        process = subprocess.Popen([str(exe),'-output',str(work/'runner.log')],cwd=build,
                                   stdout=log,stderr=subprocess.STDOUT,startupinfo=startup)
        try:
            exit_code = process.wait(timeout=90)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
            raise RuntimeError(f'Smoke timeout/runtime dialog: see {runtime_log}')

    result_data = None
    for path in (runtime_log,work/'runner.log'):
        if path.exists():
            text = path.read_text(encoding='utf-8',errors='replace')
            match = re.search(r'PLAYER_SMOKE_RESULT (\{[^\r\n]+\})',text)
            if match:
                result_data=json.loads(match.group(1))
                break
    if result_data is None:
        # GameMaker writes relative files into its own sandbox save directory.
        local = Path(os.environ['LOCALAPPDATA'])
        for save_dir in local.glob('FirstGame*'):
            if save_dir.is_dir():
                for path in save_dir.rglob('player-smoke-result.json'):
                    if path.stat().st_mtime >= started:
                        result_data=json.loads(path.read_text(encoding='utf-8-sig'))
                        break
    if result_data is None:
        raise RuntimeError(f'No explicit runtime result (exit={exit_code}): {work}')
    result_data['assertions_passed'] = result_data['passed']
    result_data['passed'] = result_data['assertions_passed'] and exit_code == 0 and len(result_data['classes']) == 3
    result_data.update(exit_code=exit_code, test_type='technical runtime start; not menu E2E',
                       artifact=str(exe.relative_to(ROOT)), logs=str(work.relative_to(ROOT)))
    report=ROOT/'tests/reports/player-smoke-result.json'
    write(report,json.dumps(result_data,indent=2)+'\n')
    print(json.dumps(result_data,indent=2),flush=True)
    if not result_data['passed'] or len(result_data['classes']) != 3 or exit_code != 0:
        raise RuntimeError('Smoke assertions failed')
    print(f'PASS: {report}',flush=True)

if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print(f'FAIL: {error}',file=sys.stderr,flush=True)
        raise SystemExit(1)
