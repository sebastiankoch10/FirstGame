"""Isolated native 60 Hz gameplay runs; never edits production resources.

The model is the copied production GML, not a Python combat simulation. A saved
native artifact can be reused with --reuse so sampling never rebuilds per run.
"""
from pathlib import Path
import argparse, codecs, hashlib, importlib.util, json, os, re, shutil, subprocess, sys, time

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path.home() / 'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gm_json import loads, dumps
from gms_helpers.runner import GameMakerRunner
from gms_helpers.gamemaker_machine_lock import gamemaker_machine_operation


def _rel(p):
    try:
        return str(Path(p).resolve().relative_to(ROOT))
    except ValueError:
        return str(p)


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8')


def replace_function(source, name, body):
    match = re.search(r'function\s+' + re.escape(name) + r'\s*\([^)]*\)\s*\{', source)
    if not match:
        raise RuntimeError('Missing function ' + name)
    start = match.end()
    depth, pos = 1, start
    while depth:
        if source[pos] == '{': depth += 1
        if source[pos] == '}': depth -= 1
        pos += 1
    return source[:start] + '\n' + body + '\n' + source[pos - 1:]


def build(work, phase):
    project = work / 'project'
    project.mkdir(parents=True)
    snapshot = ROOT / 'QA/baseline/project' if phase == 'baseline' else ROOT
    # The baseline checkpoint owns gameplay and room data; unchanged bitmap/audio
    # resources come from the original workspace and are copied, never modified.
    for name in ('objects', 'scripts', 'sprites', 'sounds', 'tilesets', 'rooms', 'options', 'shaders'):
        src = snapshot / name
        if not src.exists(): src = ROOT / name
        shutil.copytree(src, project / name)
    yyp = loads((snapshot / 'FirstGame.yyp').read_text(encoding='utf-8-sig'))
    yyp['name'] = yyp['%Name'] = 'FirstGameNativeMC'
    write(project / 'FirstGameNativeMC.yyp', dumps(yyp))
    p = project / 'options/main/options_main.yy'
    d = loads(p.read_text(encoding='utf-8-sig'))
    d['option_gameguid'] = 'a7103f8f-9d9b-44e7-b6fd-467d90267d63'
    write(p, dumps(d))
    p = project / 'options/windows/options_windows.yy'
    d = loads(p.read_text(encoding='utf-8-sig'))
    d['option_windows_display_name'] = 'FirstGame Native Monte Carlo'
    write(p, dumps(d))
    controller = (project / 'objects/ObjectController/Step_0.gml').read_text(encoding='utf-8-sig')
    for old, new in [('keyboard_check_pressed', 'qa_key_pressed'), ('keyboard_check', 'qa_key'),
                     ('mouse_check_button_pressed', 'qa_mouse_pressed'), ('mouse_check_button', 'qa_mouse')]:
        controller = re.sub(r'\b' + old + r'\b', new, controller)
    # All simulation events run only inside qa_world_tick. Engine dispatch after
    # the accelerated batch cannot add contacts, projectile hits or extra Steps.
    for p in (project / 'objects').rglob('*.gml'):
        if p.name.startswith(('Step_', 'Collision_')):
            write(p, 'if(!variable_global_exists("qa_inside_tick") || !global.qa_inside_tick)exit;\n' + p.read_text(encoding='utf-8-sig'))
    p = project / 'objects/ObjectPlayer/Step_0.gml'
    s = p.read_text(encoding='utf-8-sig')
    for old, new in [('keyboard_check_pressed', 'qa_key_pressed'), ('keyboard_check', 'qa_key'),
                     ('mouse_check_button_pressed', 'qa_mouse_pressed'), ('mouse_check_button', 'qa_mouse')]:
        s = re.sub(r'\b' + old + r'\b', new, s)
    s = re.sub(r'\bmouse_x\b', 'global.qa_mouse_x', s)
    s = re.sub(r'\bmouse_y\b', 'global.qa_mouse_y', s)
    write(p, s)
    # Audio has no RNG or gameplay side effects. Keep all weather/cosmetic Step
    # code because it consumes production RNG; Draw events are disabled in MC.
    p = project / 'scripts/audio_manager/audio_manager.gml'
    s = p.read_text(encoding='utf-8-sig')
    for name in ('fg_sfx', 'fg_music_set', 'fg_audio_tick', 'fg_audio_stop_effects'):
        s = replace_function(s, name, 'return -1;')
    write(p, s)
    write(project / 'objects/ObjectMainMenu/Step_0.gml', 'qa_menu_tick();')
    write(project / 'objects/ObjectController/Step_0.gml', 'qa_controller_tick();')
    p = project / 'objects/ObjectMainMenu/Create_0.gml'
    write(p, 'global.qa_inside_tick=false;global.master_volume=0;global.music_volume=0;global.effects_volume=0;\n'
          + p.read_text(encoding='utf-8-sig')
          + '\nexception_unhandled_handler(function(ex){show_debug_message("QA_MC_EXCEPTION "+json_stringify(ex));game_end();return true;});\n')
    p = project / 'objects/ObjectController/Draw_64.gml'
    write(p, p.read_text(encoding='utf-8-sig') + '\nqa_capture_draw();\n')
    p = project / 'scripts/gameplay/gameplay.gml'
    extra = '\nfunction qa_controller_production_step(){\n' + controller + '\n}\n'
    write(p, p.read_text(encoding='utf-8-sig') + extra)
    injector = None
    helper = ROOT / 'QA/tools/telemetry_injections.py'
    if helper.exists():
        spec = importlib.util.spec_from_file_location('qa_telemetry_injections', helper)
        injector = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(injector)
    for p in project.rglob('*.gml'):
        s = p.read_text(encoding='utf-8-sig')
        s = re.sub(r'\bdelta_time\s*/\s*1000000(?:\.0)?\b', '(1/60)', s)
        if injector: s = injector.apply_injections(s, str(p.relative_to(project)).replace('\\', '/'))
        write(p, s)
    p = project / 'scripts/gameplay/gameplay.gml'
    telemetry_path = ROOT / 'QA/tools/qa_telemetry.gml'
    telemetry = telemetry_path.read_text(encoding='utf-8-sig') if telemetry_path.exists() else '\nfunction qa_metrics_reset(_c,_s,_p){}\nfunction qa_metrics_export(){return {};}'
    extra_harness = ''
    for filename, entry in [('boss_mc_harness.gml', 'qa_boss_suite_step'), ('ability_bench_harness.gml', 'qa_bench_suite_step')]:
        h = ROOT / 'QA/tools' / filename
        extra_harness += '\n' + (h.read_text(encoding='utf-8-sig') if h.exists() else 'function ' + entry + '(){show_debug_message("QA_MC_EXCEPTION missing optional harness");game_end();}')
    write(p, p.read_text(encoding='utf-8-sig') + '\n' + telemetry + '\n' + (ROOT / 'QA/tools/native_mc_harness.gml').read_text(encoding='utf-8-sig') + extra_harness)
    runner = GameMakerRunner(project, runtime_version='2024.14.4.268')
    igor, license_file = runner.find_gamemaker_runtime(), runner.find_license_file()
    if not igor or not license_file: raise RuntimeError('Installed native runtime/license unavailable')
    for name in ('build', 'cache', 'temp'): (work / name).mkdir()
    cmd = [str(igor), f'/lf={license_file}', f'/uf={license_file.parent}', f'/rp={runner.runtime_path}',
           f'/project={project / "FirstGameNativeMC.yyp"}', f'/cache={work / "cache"}', f'/temp={work / "temp"}',
           f'/of={work / "build/FirstGameNativeMC"}', f'--tf={work / "build/FirstGameNativeMC.zip"}', '--', 'Windows', 'PackageZip']
    print('Building isolated native gameplay artifact: ' + str(work), flush=True)
    with gamemaker_machine_operation('native-mc-build', project):
        with (work / 'build.log').open('w', encoding='utf-8') as log:
            result = subprocess.run(cmd, stdout=log, stderr=subprocess.STDOUT, cwd=project, timeout=240)
    exe = work / 'build/FirstGameNativeMC.exe'
    if result.returncode or not exe.exists() or 'Final Compile finished.' not in (work / 'build.log').read_text(encoding='utf-8', errors='replace'):
        raise RuntimeError('Native build failed: ' + str(work / 'build.log'))
    manifest = {'phase': phase, 'runtime': '2024.14.4.268', 'source': str(snapshot), 'telemetry': bool(injector),
                'harness_sha256': hashlib.sha256((ROOT / 'QA/tools/native_mc_harness.gml').read_bytes()).hexdigest(),
                'cosmetics': 'Audio no-op and drawing off. Weather, feedback, animation and their RNG consumption retained.',
                'physics': 'Actual production Steps at1/60; copied engine Step/collision events gated outside qa_inside_tick.'}
    write(work / 'manifest.json', json.dumps(manifest, indent=2))
    return exe


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--phase', choices=['baseline', 'after', 'holdout'], default='baseline')
    ap.add_argument('--runs-per-class', type=int, default=1)
    ap.add_argument('--seedstart', type=int, default=710101)
    ap.add_argument('--batchsize', type=int, default=60)
    ap.add_argument('--out', type=Path, default=ROOT / 'QA/data/native-pilot.jsonl')
    ap.add_argument('--reuse', type=Path)
    ap.add_argument('--mode', choices=['runs', 'validation', 'fixture', 'boss', 'bench'], default='runs')
    ap.add_argument('--probe-ticks', type=int, default=600)
    ap.add_argument('--persona', choices=['cycle','beginner','average','experienced'], default='cycle')
    ap.add_argument('--class-name', choices=['Sword','Mage','Ranger'], default='Sword', help='Class used for parity validation probes only')
    ap.add_argument('--timeout', type=int, default=900)
    args = ap.parse_args()
    if min(args.runs_per_class, args.batchsize, args.probe_ticks) < 1: ap.error('Counts must be positive')
    if args.phase == 'holdout' and not args.reuse:
        ap.error('Holdout requires --reuse of an already reviewed baseline/after artifact')
    # Native artefacts live outside the project folder (the owner tests the real project with F5 in the IDE).
    work = args.reuse.resolve() if args.reuse else Path(os.environ['LOCALAPPDATA']) / 'FirstGame-Tests' / ('native-mc-' + args.phase) / time.strftime('%Y%m%d-%H%M%S')
    exe = work / 'build/FirstGameNativeMC.exe' if args.reuse else build(work, args.phase)
    if not exe.is_file(): raise RuntimeError('Missing reusable native executable: ' + str(exe))
    manifest = json.loads((work / 'manifest.json').read_text(encoding='utf-8'))
    if args.phase != 'holdout' and manifest['phase'] != args.phase:
        raise RuntimeError('Cannot relabel a reused artifact from ' + manifest['phase'] + ' as ' + args.phase)
    tag = f'{args.phase}-{args.mode}-{args.class_name}-{args.persona}-b{args.batchsize}-s{args.seedstart}-{time.strftime("%H%M%S")}-{os.getpid()}'
    log_path = work / (tag + '.log')
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 4
    command = [str(exe), '-output', str(work / (tag + '-runner.log')),
               f'-qa_phase={args.phase}', f'-qa_runs={args.runs_per_class}', f'-qa_seed={args.seedstart}',
               f'-qa_batch={args.batchsize}', f'-qa_mode={args.mode}', f'-qa_probe={args.probe_ticks}',
               f'-qa_persona={args.persona}', f'-qa_class={args.class_name}', f'-qa_checkpoint=qa-native-{tag}-{os.getpid()}.jsonl']
    started = time.time()
    print('Launching ' + tag + ' from ' + str(work), flush=True)
    rows, parse_errors = [], []
    args.out.parent.mkdir(parents=True, exist_ok=True)
    position, pending = 0, ''
    decoder = codecs.getincrementaldecoder('utf-8')(errors='replace')
    def drain_checkpoints(final=False):
        nonlocal position, pending
        with log_path.open('rb') as source:
            source.seek(position)
            pending += decoder.decode(source.read(), final=final)
            position = source.tell()
        lines = pending.split('\n')
        pending = lines.pop()
        if final and pending:
            lines.append(pending); pending = ''
        for line in lines:
            if 'QA_MC_ROW ' not in line: continue
            try: row = json.loads(line.split('QA_MC_ROW ', 1)[1])
            except json.JSONDecodeError as exc:
                parse_errors.append(str(exc)); continue
            row.update(native_artifact=_rel(work), phase=args.phase, source_phase=manifest['phase'])
            row.setdefault('record_type', 'full_run' if args.mode == 'runs' else args.mode)
            rows.append(row)
            # Durable checkpoints survive a later slow run, timeout or interruption.
            with args.out.open('a', encoding='utf-8') as output:
                output.write(json.dumps(row, separators=(',', ':')) + '\n')
                output.flush()
    with log_path.open('w', encoding='utf-8') as log:
        process = subprocess.Popen(command, cwd=exe.parent, stdout=log, stderr=subprocess.STDOUT, startupinfo=startup)
        deadline = time.monotonic() + args.timeout
        while process.poll() is None:
            drain_checkpoints()
            if time.monotonic() >= deadline:
                process.kill(); process.wait(); break
            try: process.wait(timeout=min(1, max(.01, deadline-time.monotonic())))
            except subprocess.TimeoutExpired: pass
        code = process.returncode
        if time.monotonic() >= deadline: code = -99
        drain_checkpoints(final=True)
    content = log_path.read_text(encoding='utf-8', errors='replace')
    captures = []
    for save in Path(os.environ['LOCALAPPDATA']).glob('FirstGame*'):
        if save.is_dir():
            for p in save.rglob('qa-mc-capture-*.png'):
                if p.stat().st_mtime >= started:
                    dest = work / p.name
                    shutil.copyfile(p, dest); captures.append(_rel(dest))
    result = {'work': _rel(work), 'log': _rel(log_path), 'rows': len(rows),
              'completed_runs': sum(r.get('completed', False) for r in rows), 'elapsed_wall_seconds': time.time() - started,
              'exit_code': code, 'mode': args.mode, 'phase': args.phase, 'source_phase': manifest['phase'], 'captures': captures,
              'errors': [x for x in content.splitlines() if 'QA_MC_EXCEPTION' in x], 'parse_errors': parse_errors}
    fixture = re.search(r'QA_MC_FIXTURE (\{[^\r\n]+\})', content)
    if fixture:
        result['fixture'] = json.loads(fixture.group(1))
        for flag in ('contact_pass','coin_mask_pass','clock_pass','scenery_footprint_pass'):
            if not result['fixture'].get(flag, False): result['errors'].append('Native fixture failed: '+flag)
    write(work / (tag + '-summary.json'), json.dumps(result, indent=2))
    print(json.dumps(result, indent=2), flush=True)
    if code or result['errors'] or parse_errors or 'QA_MC_DONE ' not in content: raise RuntimeError('Native run incomplete; checkpoints preserved at ' + str(args.out))


if __name__ == '__main__':
    try: main()
    except Exception as ex:
        print('FAIL:', ex, file=sys.stderr, flush=True)
        raise SystemExit(1)
