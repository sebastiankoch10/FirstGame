"""Player level per game minute from bot cohorts (deterministic, no AI): mean, median, spread, per class and persona,
compared with boss_test_preset. Reads the progression_samples of every run (level at fixed game seconds).

  python QA/tools/analyze_levels.py LABEL [LABEL ...]        e.g. v3-cohort-a v3-cohort-b level-cohort-2026-11-26
  python QA/tools/analyze_levels.py --all                    every QA/data/*/cohort.json

Writes QA/data/level-per-minute-<first label>.json and prints a Markdown summary. Samples exist only for runs that are
still alive at that time, so n shrinks with the minute (survivorship); n is always shown.
Balancing values are never changed by this tool; it only reports and proposes.
"""
from __future__ import annotations

import json
import re
import statistics as st
import sys
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def preset() -> dict[int, int]:
    """boss_test_preset from the game code: minute threshold -> level (single source, parsed)."""
    gml = (ROOT / 'scripts/boss_test_mode/boss_test_mode.gml').read_text(encoding='utf-8-sig')
    body = gml[gml.index('function boss_test_preset'):gml.index('function boss_test_bosses')]
    out = {int(m): int(l) for m, l in re.findall(r'_minute<=(\d+)\)return \{level:(\d+)', body)}
    last = re.search(r'return \{level:(\d+),decisions:\d+\};\s*\}', body)
    if last:
        out[30] = int(last.group(1))
    return out


def rows_of(labels: list[str]) -> list[dict]:
    rows = []
    for lab in labels:
        for f in sorted((ROOT / 'QA/data' / lab).glob('worker-*.jsonl')):
            rows += [json.loads(x) for x in f.read_text(encoding='utf-8').splitlines() if x.strip()]
    return rows


def describe(v: list[float]) -> dict:
    v = sorted(v)
    if not v:
        return {'n': 0}
    q = lambda p: v[min(len(v) - 1, int(p * (len(v) - 1) + .5))]
    return {'n': len(v), 'mean': round(st.fmean(v), 1), 'median': q(.5), 'p10': q(.1), 'p90': q(.9), 'sd': round(st.pstdev(v), 1) if len(v) > 1 else 0}


def main() -> None:
    args = sys.argv[1:]
    labels = [p.parent.name for p in sorted((ROOT / 'QA/data').glob('*/cohort.json'))] if args == ['--all'] else args
    if not labels:
        raise SystemExit(__doc__)
    rows = rows_of(labels)
    by = defaultdict(lambda: defaultdict(list))   # group -> second -> levels
    for r in rows:
        for s in r.get('progression_samples') or []:
            sec = int(round(s['seconds']))
            for g in ('all', 'class:' + r['class_name'], 'persona:' + r['persona'], f"{r['class_name']}/{r['persona']}"):
                by[g][sec].append(s['level'])
    secs = sorted(by['all'])
    result = {'labels': labels, 'runs': len(rows), 'preset': preset(), 'groups': {g: {str(s): describe(by[g][s]) for s in secs} for g in sorted(by)}}
    out = ROOT / 'QA/data' / f'level-per-minute-{labels[0]}.json'
    out.write_text(json.dumps(result, indent=1) + '\n', encoding='utf-8')
    pre = result['preset']
    print(f"## Level je Spielminute ({', '.join(labels)}; {len(rows)} Laeufe)\n")
    print('| Minute | n | Mittel | Median | P10-P90 | SD | Beginner | Average | Experienced | Sword | Mage | Ranger | Preset |')
    print('|---|---|---|---|---|---|---|---|---|---|---|---|---|')
    for s in secs:
        d = result['groups']['all'][str(s)]
        g = lambda k: result['groups'].get(k, {}).get(str(s), {}).get('median', '-')
        m = s / 60
        pl = next((pre[k] for k in sorted(pre) if m <= k), '-') if m >= 5 else '-'
        print(f"| {m:g} | {d['n']} | {d['mean']} | {d['median']:g} | {d['p10']:g}-{d['p90']:g} | {d['sd']} | {g('persona:beginner')} | {g('persona:average')} | "
              f"{g('persona:experienced')} | {g('class:Sword')} | {g('class:Mage')} | {g('class:Ranger')} | {pl} |")
    print(f'\nDetails: {out.relative_to(ROOT)}')


if __name__ == '__main__':
    main()
