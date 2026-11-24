"""Build the normal project with no injected test hooks; keep cache outside package input.
Run: python tests/tools/build_production.py
"""
from pathlib import Path
import json
import subprocess
import sys
import time

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(Path.home()/'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.runner import GameMakerRunner
from gms_helpers.gamemaker_machine_lock import gamemaker_machine_operation


def main():
    work=ROOT/'output/production-build'/time.strftime('%Y%m%d-%H%M%S')
    for name in ('cache','temp','game'):
        (work/name).mkdir(parents=True,exist_ok=True)
    runner=GameMakerRunner(ROOT,runtime_version='2024.14.4.268')
    igor=runner.find_gamemaker_runtime()
    license_file=runner.find_license_file()
    if not igor or not license_file:
        raise RuntimeError('GameMaker runtime/license unavailable')
    command=[str(igor),f'/lf={license_file}',f'/uf={license_file.parent}',f'/rp={runner.runtime_path}',
             f'/project={ROOT/"FirstGame.yyp"}',f'/cache={work/"cache"}',f'/temp={work/"temp"}',
             f'/of={work/"game/FirstGame"}',f'--tf={work/"FirstGame.zip"}','--','Windows','PackageZip']
    with gamemaker_machine_operation('production-build',ROOT):
        with (work/'build.log').open('w',encoding='utf-8') as log:
            result=subprocess.run(command,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=120)
    log=(work/'build.log').read_text(encoding='utf-8',errors='replace')
    exe=work/'game/FirstGame.exe'
    compiled='Final Compile finished.' in log and exe.is_file() and (work/'game/data.win').is_file()
    report=dict(passed=compiled,compile_success=compiled,package_success=compiled and result.returncode==0 and 'Exception' not in log,
                igor_exit_code=result.returncode,artifact=str(exe.relative_to(ROOT)),archive=str((work/'FirstGame.zip').relative_to(ROOT)),
                log=str((work/'build.log').relative_to(ROOT)),test_hooks=False)
    (ROOT/'tests/reports/production-build.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report,indent=2),flush=True)
    if not compiled:
        raise RuntimeError('Fresh normal project build failed')


if __name__=='__main__':
    try:
        main()
    except Exception as error:
        print(f'FAIL: {error}',file=sys.stderr,flush=True)
        raise SystemExit(1)
