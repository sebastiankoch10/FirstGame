"""One Windows VM compile, using the installed Igor directly; never launches the game."""
from pathlib import Path
import subprocess
import sys
import json
import time

sys.path.insert(0, str(Path.home() / 'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.runner import GameMakerRunner
from gms_helpers.gamemaker_machine_lock import gamemaker_machine_operation

root = Path(__file__).resolve().parents[2]
runner = GameMakerRunner(root, runtime_version='2024.14.4.268')
igor = runner.find_gamemaker_runtime()
license_file = runner.find_license_file()
if not igor or not license_file:
    raise SystemExit('Igor or GameMaker license unavailable')
work = root / 'output/art-build'
for part in ('cache','temp'):
    (work/part).mkdir(parents=True,exist_ok=True)
command = [str(igor), f'/lf={license_file}', f'/uf={license_file.parent}',
           f'/rp={runner.runtime_path}', f'/project={root / "FirstGame.yyp"}',
           f'/cache={work / "cache"}', f'/temp={work / "temp"}',
           f'/of={work / "FirstGame"}', f'--tf={work / "FirstGame.zip"}', '--', 'Windows', 'PackageZip']
with gamemaker_machine_operation('compile', root):
    build_started_ns = time.time_ns()
    with (root/'tests/reports/art-build.log').open('w',encoding='utf-8') as log:
        result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, cwd=root)
log_text = (root/'tests/reports/art-build.log').read_text(encoding='utf-8',errors='replace')
def fresh(path):
    return path.is_file() and path.stat().st_mtime_ns >= build_started_ns
compiled = 'Final Compile finished.' in log_text and fresh(work/'data.win')
launchable = compiled and fresh(work/'FirstGame.exe')
packaged = launchable and 'Exception' not in log_text and result.returncode == 0
status = dict(igor_exit_code=result.returncode, compile_success=compiled, launchable_fresh_build=launchable, package_success=packaged,
              log='tests/reports/art-build.log')
(root/'tests/reports/art-build-status.json').write_text(json.dumps(status,indent=2)+'\n',encoding='utf-8')
print(json.dumps(status))
raise SystemExit(0 if launchable else 1)
