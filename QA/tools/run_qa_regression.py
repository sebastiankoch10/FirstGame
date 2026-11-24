"""Focused current-source native regression. All hooks exist in a disposable copy only."""
from pathlib import Path
import json, os, re, shutil, subprocess, sys, time

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path.home() / 'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads, dumps
from gms_helpers.runner import GameMakerRunner
from gms_helpers.gamemaker_machine_lock import gamemaker_machine_operation

def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8')

def inputs(source):
    for old, new in [('keyboard_check_pressed','qr_key_pressed'),('keyboard_check','qr_key'),
                     ('mouse_check_button_pressed','qr_mouse_pressed'),('mouse_check_button','qr_mouse'),
                     ('device_mouse_x_to_gui','qr_gui_x'),('device_mouse_y_to_gui','qr_gui_y')]:
        source = re.sub(r'\b' + old + r'\b', new, source)
    source = re.sub(r'\bmouse_x\b', 'global.qr_mouse_x', source)
    return re.sub(r'\bmouse_y\b', 'global.qr_mouse_y', source)

def main():
    coin_fixture = next((x.split('=',1)[1] for x in sys.argv if x.startswith('--coin-fixture=')), None)
    if coin_fixture not in (None,'baseline','after'): raise ValueError('Use --coin-fixture=baseline or after')
    stress_only = '--stress-only' in sys.argv
    work = ROOT/'QA/logs'/('regression-'+time.strftime('%Y%m%d-%H%M%S'))
    project = work/'project'
    project.mkdir(parents=True)
    for name in ('objects','scripts','sprites','sounds','tilesets','rooms','options'):
        shutil.copytree(ROOT/name, project/name)
    yyp = loads((ROOT/'FirstGame.yyp').read_text(encoding='utf-8'))
    yyp['name'] = yyp['%Name'] = 'FirstGameQARegression'
    write(project/'FirstGameQARegression.yyp', dumps(yyp))
    p = project/'options/main/options_main.yy'
    d = loads(p.read_text(encoding='utf-8'))
    d['option_gameguid'] = 'cbac5732-d210-4107-b5ae-7e4be9bf35a2'
    write(p, dumps(d))
    p = project/'options/windows/options_windows.yy'
    d = loads(p.read_text(encoding='utf-8'))
    d['option_windows_display_name'] = 'FirstGame QA regression'
    write(p, dumps(d))
    controller = (project/'objects/ObjectController/Step_0.gml').read_text(encoding='utf-8-sig')
    p = project/'scripts/gameplay/gameplay.gml'
    harness = (ROOT/'tests/boss_v2_harness.gml').read_text(encoding='utf-8-sig')
    harness += '\n' + (ROOT/'QA/tools/qa_regression_harness.gml').read_text(encoding='utf-8-sig')
    harness += '\nfunction qr_controller_production(){\n' + inputs(controller) + '\n}\n'
    write(p, p.read_text(encoding='utf-8-sig')+'\n'+harness)
    p = project/'objects/ObjectMainMenu/Create_0.gml'
    write(p, 'global.bt_capture_only=false;global.master_volume=0;global.music_volume=0;global.effects_volume=0;\n'+p.read_text(encoding='utf-8-sig')+'\nexception_unhandled_handler(function(ex){show_debug_message("QA_REGRESSION_EXCEPTION "+json_stringify(ex));game_end();return true;});\n')
    write(project/'objects/ObjectMainMenu/Step_0.gml', 'bt_menu_tick();')
    entry = 'qr_coin_controller_tick();' if coin_fixture else ('qr_stress_controller_tick();' if stress_only else 'qr_controller_tick();')
    write(project/'objects/ObjectController/Step_0.gml', entry)
    p = project/'objects/ObjectController/Draw_64.gml'
    write(p, p.read_text(encoding='utf-8-sig')+'\nqr_capture_draw();')
    p = project/'scripts/hud/hud.gml'
    write(p, inputs(p.read_text(encoding='utf-8-sig')))
    for obj in ['ObjectPlayer','ObjectSpawner','ObjectMonster','ObjectBossMonster','ObjectFireball','ObjectIceball','ObjectLightningball','ObjectCoin','ObjectChest','ObjectMagnetOrb']:
        p = project/f'objects/{obj}/Step_0.gml'
        source = p.read_text(encoding='utf-8-sig')
        if obj == 'ObjectPlayer': source = inputs(source)
        write(p, 'if(variable_global_exists("bt_hold") && global.bt_hold)exit;\n'+source)
    for p in project.rglob('*.gml'):
        source = p.read_text(encoding='utf-8-sig')
        source = re.sub(r'\bdelta_time\s*/\s*1000000(?:\.0)?\b', 'bt_sim_dt()', source)
        write(p, source)
    p = project/'scripts/gameplay/gameplay.gml'
    write(p, p.read_text(encoding='utf-8')+'\nfunction bt_sim_dt(){return variable_global_exists("bt_dt")?global.bt_dt:delta_time/1000000;}\n')
    runner = GameMakerRunner(project, runtime_version='2024.14.4.268')
    igor, license_file = runner.find_gamemaker_runtime(), runner.find_license_file()
    if not igor or not license_file: raise RuntimeError('Installed runtime/license missing')
    for name in ('build','cache','temp'): (work/name).mkdir()
    stem = work/'build/FirstGameQARegression'
    cmd = [str(igor), f'/lf={license_file}', f'/uf={license_file.parent}', f'/rp={runner.runtime_path}',
           f'/project={project/"FirstGameQARegression.yyp"}', f'/cache={work/"cache"}', f'/temp={work/"temp"}',
           f'/of={stem}', f'--tf={stem}.zip', '--', 'Windows', 'PackageZip']
    print('Building isolated native QA regression...', flush=True)
    with gamemaker_machine_operation('qa-regression-build', project):
        with (work/'build.log').open('w', encoding='utf-8') as log:
            subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, cwd=project, timeout=180)
    exe = stem.with_suffix('.exe')
    if not exe.exists(): raise RuntimeError(f'Compile failed: {work}/build.log')
    started = time.time()
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 4
    with (work/'runtime.log').open('w', encoding='utf-8') as log:
        proc = subprocess.Popen([str(exe),'-output',str(work/'runner.log')], cwd=exe.parent,
                                stdout=log, stderr=subprocess.STDOUT, startupinfo=startup)
        try: code = proc.wait(timeout=120)
        except subprocess.TimeoutExpired:
            proc.kill(); proc.wait()
            raise RuntimeError(f'Runtime timeout: {work}/runtime.log')
    result = None
    for p in [work/'runtime.log', work/'runner.log']:
        if p.exists():
            match = re.search(r'QA_REGRESSION_RESULT (\{[^\r\n]+\})', p.read_text(encoding='utf-8', errors='replace'))
            if match: result = json.loads(match.group(1)); break
    if result is None: raise RuntimeError(f'No result: {work}/runtime.log')
    images = ROOT/'QA/screenshots'
    images.mkdir(exist_ok=True)
    captures=[]
    for save in Path(os.environ['LOCALAPPDATA']).glob('FirstGame*'):
        if save.is_dir():
            for p in save.rglob('qacapture-*.png'):
                if p.stat().st_mtime >= started:
                    shutil.copyfile(p, images/p.name)
                    captures.append(p.name)
    result.update(exit_code=code, logs=str(work.relative_to(ROOT)), screenshots=captures)
    result['passed'] = result['passed'] and code == 0
    report = 'moving-coin-'+coin_fixture+'.json' if coin_fixture else ('performance.json' if stress_only else 'regression.json')
    write(ROOT/'QA/data'/report, json.dumps(result, indent=2)+'\n')
    # Keep logs, drop the re-creatable project copy and test executable (no EXEs inside the project folder).
    for n in ('project','build','cache','temp'):
        shutil.rmtree(work/n, ignore_errors=True)
    print(json.dumps({k:result[k] for k in ['passed','checks','failures','logs','screenshots']}, indent=2), flush=True)
    if not result['passed']: raise RuntimeError('Native regression assertions failed')

if __name__ == '__main__':
    try: main()
    except Exception as exc:
        print('FAIL:', exc, file=sys.stderr, flush=True)
        raise SystemExit(1)
