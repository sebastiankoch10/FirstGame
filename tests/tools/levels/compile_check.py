"""Compile the real project with Igor (Windows VM, no test hooks) into %LOCALAPPDATA%/FirstGame-Tests/compile/<stamp>.
Nothing is written into the project folder; the game/cache/temp copies are deleted afterwards (only build.log stays).
Usage: python tests/tools/levels/compile_check.py [--run SECONDS]
"""
from __future__ import annotations

import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(Path.home() / 'AppData/Local/pipx/pipx/venvs/gms-mcp/Lib/site-packages'))
from gms_helpers.gamemaker_machine_lock import gamemaker_machine_operation  # noqa: E402
from gms_helpers.runner import GameMakerRunner  # noqa: E402


def main():
    work = Path(os.environ['LOCALAPPDATA']) / 'FirstGame-Tests/compile' / time.strftime('%Y%m%d-%H%M%S')
    for n in ('cache', 'temp', 'game'):
        (work / n).mkdir(parents=True, exist_ok=True)
    runner = GameMakerRunner(ROOT, runtime_version='2024.14.4.268')
    igor = runner.find_gamemaker_runtime(); lic = runner.find_license_file()
    cmd = [str(igor), f'/lf={lic}', f'/uf={lic.parent}', f'/rp={runner.runtime_path}', f'/project={ROOT / "FirstGame.yyp"}',
           f'/cache={work / "cache"}', f'/temp={work / "temp"}', f'/of={work / "game/FirstGame"}', f'--tf={work / "FirstGame.zip"}', '--', 'Windows', 'PackageZip']
    t = time.time()
    with gamemaker_machine_operation('level-compile', ROOT):
        with (work / 'build.log').open('w', encoding='utf-8') as log:
            res = subprocess.run(cmd, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT, timeout=900)
    text = (work / 'build.log').read_text(encoding='utf-8', errors='replace')
    ok = 'Final Compile finished.' in text and (work / 'game/FirstGame.exe').is_file()
    errs = [l for l in text.splitlines() if 'error' in l.lower() and 'errors=0' not in l.lower()][:40]
    print(f'compile ok={ok} exit={res.returncode} {time.time() - t:.0f}s log={work / "build.log"}')
    for l in errs:
        print('  ', l[:300])
    if '--run' in sys.argv and ok:
        secs = float(sys.argv[sys.argv.index('--run') + 1])
        exe = work / 'game/FirstGame.exe'
        p = subprocess.Popen([str(exe), '-output', str(work / 'runner.log')], cwd=exe.parent)
        try:
            p.wait(timeout=secs)
        except subprocess.TimeoutExpired:
            p.kill()
        print((work / 'runner.log').read_text(encoding='utf-8', errors='replace')[-3000:] if (work / 'runner.log').exists() else 'no runner log')
    for n in ('game', 'cache', 'temp', 'FirstGame.zip'):
        p = work / n
        shutil.rmtree(p, ignore_errors=True) if p.is_dir() else p.unlink(missing_ok=True)
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
