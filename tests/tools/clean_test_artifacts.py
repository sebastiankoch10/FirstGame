"""Disk hygiene for test artefacts; never touches project sources or the real game's save folder.

  python tests/tools/clean_test_artifacts.py            # prune (also run automatically by qa.py and record_scene.py)
  python tests/tools/clean_test_artifacts.py --dry-run  # only report
  python tests/tools/clean_test_artifacts.py --probes   # also remove one-off probe folders right away

Rules:
- %LOCALAPPDATA%/FirstGame-Tests/<folder>/<stamp>: the newest 2 runs per folder stay (native-mc-*: 1, scene: 6). One-off probe
  folders (not a known suite) go when their newest run is older than 3 days, or at once with --probes. The QA cache
  (qa-cache.json) and the character segmentation cache (charcache) stay.
- Capture PNGs (*capture-*.png) left in the build save folders %LOCALAPPDATA%/FirstGame<Name>/ are deleted.
- Untracked QA/logs/regression-* folders in the project: the newest 3 stay; tracked (committed) logs are never touched.
"""
from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LOCAL = Path(os.environ.get('LOCALAPPDATA', str(Path.home())))
TESTS = LOCAL / 'FirstGame-Tests'
SUITE_DIRS = {'feature', 'boss', 'visual', 'level-smoke', 'classes', 'scene', 'compile', 'regression', 'anchors', 'static'}
KEEP_DIRS = {'charcache'}
STAMP = re.compile(r'^\d{8}-\d{6}$')
KEEP_RUNS, KEEP_MC, KEEP_LOGS, PROBE_DAYS = 2, 1, 3, 3
KEEP_SPECIAL = {'scene': 6}  # recordings come in series; keep the newest six


def size(p: Path) -> int:
    if p.is_file():
        return p.stat().st_size
    return sum(f.stat().st_size for f in p.rglob('*') if f.is_file())


def remove(p: Path, dry: bool, out: list):
    out.append((p, size(p)))
    if not dry:
        shutil.rmtree(p, ignore_errors=True) if p.is_dir() else p.unlink(missing_ok=True)


def clean(dry: bool = False, probes: bool = False, quiet: bool = False) -> int:
    gone: list = []
    if TESTS.is_dir():
        for d in TESTS.iterdir():
            if not d.is_dir() or d.name in KEEP_DIRS:
                continue
            runs = sorted((r for r in d.iterdir() if r.is_dir() and STAMP.match(r.name)), key=lambda r: r.name, reverse=True)
            probe = d.name not in SUITE_DIRS and not d.name.startswith('native-mc')
            newest_age = (time.time() - runs[0].stat().st_mtime) / 86400 if runs else 999
            if probe and (probes or newest_age > PROBE_DAYS):
                remove(d, dry, gone); continue
            keep = KEEP_MC if d.name.startswith('native-mc') else KEEP_SPECIAL.get(d.name, KEEP_RUNS)
            for r in runs[keep:]:
                remove(r, dry, gone)
            if not dry and not any(d.iterdir()):
                d.rmdir()
    for save in LOCAL.glob('FirstGame*'):
        if save.is_dir() and save != TESTS and save.name != 'FirstGame':
            for c in save.rglob('*capture-*.png'):
                remove(c, dry, gone)
    logs = ROOT / 'QA' / 'logs'
    if logs.is_dir():
        tracked = subprocess.run(['git', 'ls-files', 'QA/logs'], cwd=ROOT, capture_output=True, text=True).stdout
        tracked_dirs = {line.split('/')[2] for line in tracked.splitlines() if line.count('/') >= 3}
        untracked = sorted((p for p in logs.glob('regression-*') if p.is_dir() and p.name not in tracked_dirs), reverse=True)
        for p in untracked[KEEP_LOGS:]:
            remove(p, dry, gone)
    freed = sum(s for _, s in gone)
    if not quiet or gone:
        print(f"{'Wuerde entfernen' if dry else 'Entfernt'}: {len(gone)} Eintraege, {freed / 1e6:.0f} MB")
    return freed


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--dry-run', action='store_true')
    ap.add_argument('--probes', action='store_true')
    a = ap.parse_args()
    clean(a.dry_run, a.probes)
