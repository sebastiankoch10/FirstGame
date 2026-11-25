"""Static check: every telemetry anchor of QA/tools/telemetry_injections.py still matches the project code.

The simulations (run_native_mc.py, run_cohort.py, run_boss_mc.py) inject telemetry at exact code anchors and
fail late when a code change moved one. This check applies all injections in memory (nothing is written) and
fails with the broken anchor. Runs in a second, no build; part of `tests/tools/qa.py` (suite `anchors`).
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'QA' / 'tools'))
from telemetry_injections import apply_injections  # noqa: E402


def main():
    files = sorted(ROOT.glob('scripts/*/*.gml')) + sorted(ROOT.glob('objects/*/*.gml'))
    broken = []
    for f in files:
        try:
            apply_injections(f.read_text(encoding='utf-8-sig'), f)
        except RuntimeError as e:
            broken.append(f'{f.relative_to(ROOT).as_posix()}: {e}')
    for b in broken:
        print('FAIL', b[:240])
    print(f'Telemetrie-Anker: {len(files)} Dateien geprueft, {len(broken)} fehlerhaft')
    return 1 if broken else 0


if __name__ == '__main__':
    sys.exit(main())
