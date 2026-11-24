"""Isolated Windows VM checks for combat, actual pickup collision, mouse choices, statistics, dragon and weather.
Run: python tests/tools/run_combat_smoke.py
Input hooks exist only in the copied test project.
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
    work = ROOT/'output/combat-smoke'/time.strftime('%Y%m%d-%H%M%S')
    project = work/'project'
    project.mkdir(parents=True)
    for name in ('objects','scripts','sprites','sounds','tilesets','rooms','options'):
        shutil.copytree(ROOT/name, project/name)
    yyp = loads((ROOT/'FirstGame.yyp').read_text(encoding='utf-8'))
    yyp['name'] = yyp['%Name'] = 'FirstGameCombatSmoke'
    write(project/'FirstGameCombatSmoke.yyp', dumps(yyp))
    options_path = project/'options/main/options_main.yy'
    options = loads(options_path.read_text(encoding='utf-8'))
    options['option_gameguid'] = 'f7f6de45-d2e5-49a7-aeaa-882243be8405'
    write(options_path, dumps(options))
    windows_path = project/'options/windows/options_windows.yy'
    options = loads(windows_path.read_text(encoding='utf-8'))
    options['option_windows_display_name'] = 'FirstGame Combat Smoke Test'
    write(windows_path, dumps(options))

    init=project/'objects/ObjectMainMenu/Create_0.gml'
    write(init,'global.sv_preview='+('true' if '--preview' in sys.argv else 'false')+'; global.master_volume=0; global.music_volume=0; global.effects_volume=0;\n'+init.read_text(encoding='utf-8-sig')+'\nexception_unhandled_handler(function(ex) { show_debug_message("GAMEPLAY_EXCEPTION "+json_stringify(ex)); game_end(); return true; });\n')
    helper=project/'scripts/gameplay/gameplay.gml'
    write(helper,helper.read_text(encoding='utf-8-sig')+'\n'+(ROOT/'tests/combat_harness.gml').read_text(encoding='utf-8-sig')+'\n'+(ROOT/'tests/spell_v2_harness.gml').read_text(encoding='utf-8-sig'))
    for relative,prefix in [('objects/ObjectMainMenu/Step_0.gml','sv_menu_tick();\n'),('objects/ObjectController/Step_0.gml','sv_controller_tick();\n')]:
        path=project/relative
        write(path,prefix+path.read_text(encoding='utf-8-sig'))
    draw=project/'objects/ObjectController/Draw_64.gml'
    write(draw,draw.read_text(encoding='utf-8-sig')+'\nif(global.game_paused) global.sv_native_modal_frames++;ap_render_capture();\n')
    # Route only the isolated game's input reads to deterministic fixtures.
    import re
    for path in project.rglob('*.gml'):
        code=path.read_text(encoding='utf-8-sig')
        for source,target in [('keyboard_check_pressed','gp_key_pressed'),('keyboard_check','gp_key_down'),('mouse_check_button_pressed','gp_mouse_pressed'),('mouse_check_button','gp_mouse_down'),('device_mouse_x_to_gui','gp_gui_x'),('device_mouse_y_to_gui','gp_gui_y')]:
            code=code.replace(source+'(',target+'(')
        code=re.sub(r'\bmouse_x\b','gp_mouse_x()',code)
        code=re.sub(r'\bmouse_y\b','gp_mouse_y()',code)
        # Fixed timestep is enabled only by short combat benchmarks in this copied test project.
        code=re.sub(r'\bdelta_time\s*/\s*1000000(?:\.0)?\b','gp_sim_dt()',code)
        write(path,code)
    write(helper,helper.read_text(encoding='utf-8')+'\nfunction gp_sim_dt(){return variable_global_exists("bench_dt") && global.bench_dt>0 ? global.bench_dt : delta_time/1000000;}\n')
    runner = GameMakerRunner(project, runtime_version='2024.14.4.268')
    igor = runner.find_gamemaker_runtime()
    license_file = runner.find_license_file()
    if not igor or not license_file:
        raise RuntimeError('Installed Igor/runtime or GameMaker license unavailable')
    build = work/'build'
    build.mkdir(parents=True)
    for name in ('cache','temp'):
        (work/name).mkdir(parents=True)
    cmd = [str(igor),f'/lf={license_file}',f'/uf={license_file.parent}',f'/rp={runner.runtime_path}',
           f'/project={project/"FirstGameCombatSmoke.yyp"}', f'/cache={work/"cache"}',f'/temp={work/"temp"}',
           f'/of={build/"FirstGameCombatSmoke"}',f'--tf={build/"FirstGameCombatSmoke.zip"}', '--','Windows','PackageZip']
    print('Building isolated Windows smoke executable...', flush=True)
    with gamemaker_machine_operation('combat-smoke-build',project):
        with (work/'build.log').open('w',encoding='utf-8') as log:
            result = subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,cwd=project,timeout=120)
    log_text = (work/'build.log').read_text(encoding='utf-8',errors='replace')
    exe = build/'FirstGameCombatSmoke.exe'
    if 'Final Compile finished.' not in log_text or not exe.is_file():
        raise RuntimeError(f'Fresh smoke build failed: {work/"build.log"}')
    if not (build/'data.win').is_file():
        raise RuntimeError('Fresh data.win missing')
    print('Running actual Windows VM: nine starts/progression flows, automatic spells and boss attack fixtures...',flush=True)
    started = time.time()
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 4  # shown without activation; no simulated OS input
    runtime_log = work/'runtime.log'
    with runtime_log.open('w',encoding='utf-8') as log:
        process = subprocess.Popen([str(exe),'-output',str(work/'runner.log')],cwd=build,
                                   stdout=log,stderr=subprocess.STDOUT,startupinfo=startup)
        try:
            exit_code = process.wait(timeout=180)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait()
            raise RuntimeError(f'Smoke timeout/runtime dialog: see {runtime_log}')

    import base64, zlib
    import struct
    def save_rgba(data,path):
        def chunk(kind,value):return struct.pack('>I',len(value))+kind+value+struct.pack('>I',zlib.crc32(kind+value)&0xffffffff)
        scan=b''.join(b'\x00'+data[y*800*4:(y+1)*800*4] for y in range(600))
        Path(path).write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',800,600,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(scan))+chunk(b'IEND',b''))
    for log_path in (runtime_log,work/'runner.log'):
        if log_path.exists():
            match=re.search(r'GAMEPLAY_RGBA ([A-Za-z0-9+/=]+)',log_path.read_text(encoding='utf-8',errors='replace'))
            if match:
                save_rgba(zlib.decompress(base64.b64decode(match.group(1))),work/'gameover-800.png')
                break
    for log_path in (runtime_log,work/'runner.log'):
        if log_path.exists():
            for match in re.finditer(r'GAMEPLAY_IMAGE ([a-z-]+) ([A-Za-z0-9+/=]+)',log_path.read_text(encoding='utf-8',errors='replace')):
                save_rgba(zlib.decompress(base64.b64decode(match.group(2))),work/(match.group(1)+'-800.png'))
    result_data = None
    for path in (runtime_log,work/'runner.log'):
        if path.exists():
            text = path.read_text(encoding='utf-8',errors='replace')
            match = re.search(r'GAMEPLAY_RESULT (\{[^\r\n]+\})',text)
            if match:
                result_data=json.loads(match.group(1))
                break
    if result_data is None:
        # GameMaker writes relative files into its own sandbox save directory.
        local = Path(os.environ['LOCALAPPDATA'])
        for save_dir in local.glob('FirstGame*'):
            if save_dir.is_dir():
                for path in save_dir.rglob('combat-smoke-result.json'):
                    if path.stat().st_mtime >= started:
                        result_data=json.loads(path.read_text(encoding='utf-8-sig'))
                        break
    if result_data is None:
        raise RuntimeError(f'No explicit runtime result (exit={exit_code}): {work}')
    local=Path(os.environ['LOCALAPPDATA'])
    for save_dir in local.glob('FirstGame*'):
        if save_dir.is_dir():
            for capture in save_dir.rglob('fgcapture-*.png'):
                if capture.stat().st_mtime>=started:
                    shutil.copyfile(capture,work/(capture.stem.removeprefix('fgcapture-')+'-800.png'))
    result_data['rendered'] = [p.name for p in work.glob('*-800.png')]
    required={'field-800.png','master-combo-first-800.png','master-combo-second-800.png','master-combo-finisher-800.png','master-north-ruins-800.png','raincrowd-800.png','v2-chain-800.png','v2-pause-details-800.png','v2-hidden-coin-800.png','v2-screen-beam-800.png'}
    if not required.issubset(result_data['rendered']):
        raise RuntimeError('Native world/three-hit combo PNG evidence is missing')
    result_data['assertions_passed'] = result_data['passed']
    result_data['passed'] = result_data['assertions_passed'] and exit_code == 0 and len(result_data['classes']) == 3
    result_data.update(exit_code=exit_code, test_type='native Windows VM: nine class/room starts; authored swordsman octants and resources; actual orb collision and exact 30 coin XP; mouse choices; weapons/statistics; aimed dragon; bounded weather. Injected input, not manual gameplay E2E.',
                       artifact=str(exe.relative_to(ROOT)), logs=str(work.relative_to(ROOT)))
    report=ROOT/'tests/reports/combat-smoke-result.json'
    write(report,json.dumps(result_data,indent=2)+'\n')
    print(json.dumps(result_data,indent=2),flush=True)
    if not result_data['passed'] or len(result_data['classes']) != 3 or exit_code != 0:
        raise RuntimeError('Smoke assertions failed')
    print(f'PASS: {report}',flush=True)

if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        write(ROOT/'tests/reports/combat-smoke-result.json', json.dumps({'passed':False,'status':'FAILED','error':str(error)},indent=2)+'\n')
        print(f'FAIL: {error}',file=sys.stderr,flush=True)
        raise SystemExit(1)

