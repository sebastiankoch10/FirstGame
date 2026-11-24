"""Evaluate the v3 cohort (talents + equipment + boss choreography) without touching the Codex-era analysis files.

  python QA/tools/analyze_v3.py --runs QA/data/v3-*/worker-*.jsonl --out QA/data/v3-analysis.json --report QA/V3_SIMULATION_REPORT.md

Only completed full runs (death or 1800 s) are counted. Unfinished worker rows are ignored and reported as such.
Statistics reuse the helpers of analyze_qa.py (Wilson intervals, seeded bootstrap of observed values).
"""
from __future__ import annotations

import argparse
import glob
import json
import statistics
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from analyze_qa import describe, wilson, read, source_totals  # noqa: E402

SPELL_NAMES = {}


def spell_names():
    if SPELL_NAMES:
        return SPELL_NAMES
    cat = ROOT / 'FirstGame_ArtPack/spell_v2/catalog.json'
    try:
        data = json.loads(cat.read_text(encoding='utf-8'))
        for e in (data if isinstance(data, list) else data.get('spells', [])):
            SPELL_NAMES[int(e['id'])] = e.get('name', str(e['id']))
    except Exception:
        pass
    SPELL_NAMES[0] = 'Startwaffe'
    return SPELL_NAMES


def mann_whitney(a, b):
    import math
    allv = sorted([(v, 0) for v in a] + [(v, 1) for v in b])
    ranks = [0.0] * len(allv); i = 0; ties = 0.0
    while i < len(allv):
        j = i
        while j + 1 < len(allv) and allv[j + 1][0] == allv[i][0]:
            j += 1
        r = (i + j) / 2 + 1
        for k in range(i, j + 1):
            ranks[k] = r
        t = j - i + 1; ties += t ** 3 - t; i = j + 1
    n1, n2 = len(a), len(b); r1 = sum(r for r, (v, g) in zip(ranks, allv) if g == 0)
    u = r1 - n1 * (n1 + 1) / 2; mu = n1 * n2 / 2; n = n1 + n2
    sigma = math.sqrt(n1 * n2 / 12 * ((n + 1) - ties / (n * (n - 1)))) if n > 1 else 0
    if sigma == 0:
        return 1.0
    z = (abs(u - mu) - 0.5) / sigma
    return max(0.0, min(1.0, math.erfc(z / math.sqrt(2))))


def fmt(v, d=1):
    return '–' if v is None else (f'{v:,.{d}f}'.replace(',', ' ').replace('.', ',') if isinstance(v, (int, float)) else str(v))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--runs', nargs='+', required=True)
    ap.add_argument('--out', type=Path, default=ROOT / 'QA/data/v3-analysis.json')
    ap.add_argument('--report', type=Path, default=ROOT / 'QA/V3_SIMULATION_REPORT.md')
    ap.add_argument('--compare', nargs='*', default=[], help='Codex-era cohort files for a baseline comparison of survival times')
    ap.add_argument('--boss', nargs='*', default=[], help='isolated boss encounter JSONL (run_boss_mc.py)')
    args = ap.parse_args()
    paths = [Path(p) for pat in args.runs for p in glob.glob(pat)]
    raw = read(paths)
    runs = [r for r in raw if r.get('completed') and r.get('end_reason') in ('death', 'survived_1800_seconds_censored')]
    ids = [r['run_id'] for r in runs]
    dup = len(ids) - len(set(ids))
    names = spell_names()
    out = {'input_files': [str(p) for p in paths], 'raw_rows': len(raw), 'full_runs': len(runs), 'duplicate_ids': dup}
    # ---- classes and personas
    by_class = defaultdict(list)
    for r in runs:
        by_class[r['class_name']].append(r)
        by_class[r['class_name'] + '/' + r['persona']].append(r)
    classes = {}
    for key, rs in sorted(by_class.items()):
        secs = [r['seconds'] for r in rs]
        ms = []
        for minute in (5, 10, 15, 20, 25, 30):
            k = sum(s + 1e-5 >= minute * 60 for s in secs)
            ms.append({'minute': minute, 'reached': k, 'n': len(rs), 'fraction': k / len(rs), 'wilson95': wilson(k, len(rs))})
        dmg = [r.get('metrics', {}).get('damage_out', 0) for r in rs]
        dmg_in = [r.get('metrics', {}).get('damage_in', 0) for r in rs]
        dps = [d / max(1, r['seconds']) for d, r in zip(dmg, rs)]
        base = [sum(s.get('damage', 0) for s in r.get('metrics', {}).get('sources', {}).values() if s.get('sid') == 0) for r in rs]
        classes[key] = {'n': len(rs), 'survival_seconds': describe(secs), 'level': describe([r['level'] for r in rs]),
                        'kills': describe([r['kills'] for r in rs]), 'bosses_defeated': describe([r.get('bosses_defeated', 0) for r in rs]),
                        'damage_out': describe(dmg), 'damage_in': describe(dmg_in), 'dps': describe(dps),
                        'start_weapon_share': (sum(base) / sum(dmg)) if sum(dmg) else None, 'milestones': ms,
                        'end_reasons': dict(Counter(r['end_reason'] for r in rs)),
                        'talents_earned': describe([r.get('talent_earned', 0) for r in rs]),
                        'equipment_found': describe([r.get('equipment_found', 0) for r in rs])}
    out['classes'] = classes
    # ---- abilities (run_stats per spell id: casts, hits, damage, healing)
    abil = defaultdict(lambda: {'runs': 0, 'casts': 0, 'hits': 0, 'damage': 0.0, 'healing': 0.0, 'seconds': 0.0, 'boss_damage': 0.0, 'normal_damage': 0.0})
    for r in runs:
        rs = r.get('run_stats') or {}
        items = rs.items() if isinstance(rs, dict) else enumerate(rs)
        for sid, s in items:
            if not isinstance(s, dict):
                continue
            raw_key = str(s.get('id', sid)); raw_key = raw_key[1:] if raw_key.startswith('s') else raw_key
            key = int(raw_key) if raw_key.lstrip('-').isdigit() else sid
            a = abil[key]; a['runs'] += 1; a['seconds'] += r['seconds']
            for f in ('casts', 'hits', 'damage', 'healing'):
                a[f] += float(s.get(f, 0) or 0)
    src = source_totals(runs)
    for key, s in src.items():
        sid = s.get('sid')
        if sid is None:
            continue
        a = abil[int(sid)]
        a['boss_damage'] += s.get('boss_damage', 0) or 0
        a['normal_damage'] += s.get('normal_damage', 0) or 0
    abilities = []
    for sid, a in abil.items():
        casts = a['casts']; minutes = a['seconds'] / 60 if a['seconds'] else 0
        abilities.append({'id': sid, 'name': names.get(int(sid) if str(sid).isdigit() else -1, str(sid)), 'runs_with': a['runs'], 'activations': casts,
                          'hits': a['hits'], 'hit_rate': a['hits'] / casts if casts else None, 'damage': a['damage'], 'healing': a['healing'],
                          'damage_per_activation': a['damage'] / casts if casts else None, 'damage_per_minute': a['damage'] / minutes if minutes else None,
                          'dps': a['damage'] / a['seconds'] if a['seconds'] else None, 'boss_damage': a['boss_damage'], 'normal_damage': a['normal_damage']})
    abilities.sort(key=lambda x: -(x['dps'] or 0))
    out['abilities'] = abilities
    # ---- bosses inside full runs
    enc = defaultdict(lambda: {'n': 0, 'defeated': 0, 'durations': []})
    deaths = Counter()
    for r in runs:
        for e in r.get('boss_encounters', []):
            b = enc[e.get('boss')]; b['n'] += 1; b['defeated'] += bool(e.get('defeated'))
            if e.get('ended', -1) >= 0:
                b['durations'].append(e['ended'] - e['started'])
        if r['end_reason'] == 'death':
            last = (r.get('metrics') or {}).get('last_damage_source') or {}
            deaths[str(last.get('boss') or last.get('kind') or 'unbekannt')] += 1
    out['bosses_in_runs'] = {k: {'encounters': v['n'], 'defeated': v['defeated'], 'win_fraction': v['defeated'] / v['n'] if v['n'] else None,
                                 'duration': describe(v['durations'])} for k, v in enc.items()}
    out['death_sources'] = dict(deaths)
    acts = defaultdict(lambda: {'activations': 0, 'hits': 0, 'damage': 0.0, 'fatal': 0, 'threatened': 0, 'avoided': 0})
    for r in runs:
        for a in (r.get('metrics') or {}).get('boss_activations', []):
            t = acts[f"{a.get('boss')}:{a.get('ability')}"]
            t['activations'] += 1; t['hits'] += a.get('hits', 0); t['damage'] += a.get('damage', 0); t['fatal'] += a.get('fatal_hits', 0)
            t['threatened'] += bool(a.get('threatened')); t['avoided'] += bool(a.get('avoided_while_threatened'))
    out['boss_abilities'] = {k: dict(v, hit_fraction_threatened=((v['threatened'] - v['avoided']) / v['threatened']) if v['threatened'] else None,
                                     wilson95=wilson(v['threatened'] - v['avoided'], v['threatened']) if v['threatened'] else None) for k, v in acts.items()}
    # ---- baseline comparison (Mann-Whitney U, normal approximation with tie correction)
    comparison = []
    if args.compare:
        cpaths = [Path(p) for pat in args.compare for p in glob.glob(pat)]
        base = [r for r in read(cpaths) if r.get('completed') and r.get('end_reason') in ('death', 'survived_1800_seconds_censored')]
        for klass in ('Sword', 'Mage', 'Ranger'):
            for persona in ('beginner', 'average', 'experienced'):
                a_ = [r['seconds'] for r in base if r['class_name'] == klass and r['persona'] == persona]
                b_ = [r['seconds'] for r in runs if r['class_name'] == klass and r['persona'] == persona]
                if len(a_) < 3 or len(b_) < 3:
                    continue
                comparison.append(dict(class_name=klass, persona=persona, n_before=len(a_), n_after=len(b_), median_before=statistics.median(a_),
                                       median_after=statistics.median(b_), mean_before=statistics.mean(a_), mean_after=statistics.mean(b_), p_mann_whitney=mann_whitney(a_, b_)))
    out['baseline_comparison'] = comparison
    args.out.write_text(json.dumps(out, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    # ---- markdown report
    L = ['# FirstGame – Simulationen v3 (Talente, Ausrüstung, Boss-Choreografie)', '',
         f'Eingelesene Zeilen: {len(raw)}; davon **vollständige Runs: {len(runs)}** (Tod oder 1.800 s). Doppelte IDs: {dup}. Unvollständige Zeilen (abgebrochene letzte Runs) zählen nicht.', '',
         'Alle Werte stammen aus nativen GameMaker-Runs mit festen 1/60-s-Schritten und Bots (Anfänger/Durchschnitt/Erfahren). Bots spenden Talentpunkte deterministisch (Klassenbaum zuerst) und legen gefundene Ausrüstung automatisch an. Das sind Bot-Beobachtungen, keine menschlichen Erfolgswahrscheinlichkeiten.', '',
         '## Klassen', '', '| Klasse | n | Mittel s | Median s | Min 5 | Min 10 | Min 15 | Min 20 | Min 25 | Min 30 | Level (Mittel) | Kills (Mittel) | DPS (Mittel) | Startwaffenanteil | Talentpunkte | Gegenstände |', '|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|']
    for key, c in classes.items():
        m = {x['minute']: x['fraction'] for x in c['milestones']}
        L.append(f"| {key} | {c['n']} | {fmt(c['survival_seconds'].get('mean'))} | {fmt(c['survival_seconds'].get('median'))} | " + ' | '.join(fmt(m[k] * 100, 0) + ' %' for k in (5, 10, 15, 20, 25, 30)) +
                 f" | {fmt(c['level'].get('mean'))} | {fmt(c['kills'].get('mean'),0)} | {fmt(c['dps'].get('mean'))} | {fmt((c['start_weapon_share'] or 0)*100,1)} % | {fmt(c['talents_earned'].get('mean'))} | {fmt(c['equipment_found'].get('mean'))} |")
    L += ['', '## Fähigkeiten (Summen aller Runs mit der Fähigkeit)', '', 'DPS = Gesamtschaden / Überlebenszeit der Runs, in denen die Fähigkeit im Endbuild war. Auswahlhäufigkeit und Spielzeit unterscheiden sich – keine intrinsische Rangliste.', '',
          '| Fähigkeit | Runs | Aktivierungen | Treffer | Treffer/Akt. | Schaden | Schaden/Akt. | Schaden/Min | DPS | Heilung |', '|---|---|---|---|---|---|---|---|---|---|']
    for a in abilities:
        L.append(f"| {a['name']} ({a['id']}) | {a['runs_with']} | {fmt(a['activations'],0)} | {fmt(a['hits'],0)} | {fmt(a['hit_rate'],2)} | {fmt(a['damage'],0)} | {fmt(a['damage_per_activation'])} | {fmt(a['damage_per_minute'],0)} | {fmt(a['dps'])} | {fmt(a['healing'],0)} |")
    L += ['', '## Bosse innerhalb der vollständigen Runs', '', '| Boss | Begegnungen | Besiegt | Siegquote | Dauer Median s |', '|---|---|---|---|---|']
    for k, v in out['bosses_in_runs'].items():
        L.append(f"| {k} | {v['encounters']} | {v['defeated']} | {fmt((v['win_fraction'] or 0)*100,0)} % | {fmt(v['duration'].get('median'))} |")
    L += ['', '## Bossfähigkeiten (Aktivierungen in den Runs)', '', '| Boss:Fähigkeit | Aktivierungen | bedroht | ausgewichen (bedroht) | Treffer | Schaden | tödlich |', '|---|---|---|---|---|---|---|']
    for k, v in sorted(acts.items()):
        L.append(f"| {k} | {v['activations']} | {v['threatened']} | {v['avoided']} | {v['hits']} | {fmt(v['damage'],0)} | {v['fatal']} |")
    if comparison:
        L += ['', '## Vergleich mit der Codex-Baseline (Überlebenszeit, Bots)', '',
              'Mann-Whitney-U (zweiseitig, Normalapproximation). Andere Seeds und ein anderer Code-Stand: Ein p-Wert misst nur, ob sich die beobachteten Verteilungen unterscheiden, nicht die Ursache.', '',
              '| Klasse/Persona | n vorher | n nachher | Median vorher s | Median nachher s | Mittel vorher | Mittel nachher | p |', '|---|---|---|---|---|---|---|---|']
        for c in comparison:
            L.append(f"| {c['class_name']}/{c['persona']} | {c['n_before']} | {c['n_after']} | {fmt(c['median_before'])} | {fmt(c['median_after'])} | {fmt(c['mean_before'])} | {fmt(c['mean_after'])} | {fmt(c['p_mann_whitney'],3)} |")
    # ---- isolated boss fights
    if args.boss:
        from analyze_qa import summary_bosses, attack_totals
        bpaths = [Path(p) for pat in args.boss for p in glob.glob(pat)]
        brows = [r for r in read(bpaths) if r.get('record_type') == 'boss_encounter']
        out['isolated_boss'] = {'encounters': len(brows), 'completed': sum(bool(r.get('completed')) for r in brows)}
        groups = defaultdict(list)
        for r in brows:
            groups[(r.get('boss'), int(r.get('spawn_minute') or 0))].append(r)
        L += ['', f'## Isolierte Bosskämpfe ({len(brows)} Kämpfe)', '', 'Bot-Spieler mit Entwicklungs-Preset je Minute (Boss-Testmodus). Keine menschlichen Siegquoten.', '',
              '| Boss | Minute | Kämpfe | Siege | Siegquote (95 %-Wilson) | Dauer Median s |', '|---|---|---|---|---|---|']
        for (boss, minute), rs in sorted(groups.items()):
            w = sum(bool(r.get('won')) for r in rs); ci = wilson(w, len(rs))
            L.append(f"| {boss} | {minute} | {len(rs)} | {w} | {fmt(w/len(rs)*100,0)} % ({fmt(ci[0]*100,0)}–{fmt(ci[1]*100,0)} %) | {fmt(describe([r['seconds'] for r in rs]).get('median'))} |")
        at = attack_totals(brows)
        out['isolated_boss_abilities'] = at
        L += ['', '### Bossfähigkeiten in den isolierten Kämpfen', '', '„bedroht“ = der Bot stand in der angekündigten Gefahr; „getroffen“ = davon mit Treffer. Hohe Quoten bei Projektilen sind Bot-Grenzen (die Bots weichen Geschossen nur begrenzt aus).', '',
              '| Boss:Fähigkeit | Aktivierungen | bedroht | getroffen | Trefferquote bedroht | tödlich | Warnzeit Median s |', '|---|---|---|---|---|---|---|']
        for k, v in sorted(at.items()):
            L.append(f"| {k} | {v['activations']} | {v['threatened']} | {v['activations_hit']} | {fmt((v['hit_fraction_threatened'] or 0)*100,0)} % | {v['fatal_hits']} | {fmt(v['warning_seconds'].get('median'),2)} |")
    L += ['', '## Todesursachen (letzte Schadensquelle)', '']
    for k, v in deaths.most_common():
        L.append(f'- {k}: {v}')
    args.report.write_text('\n'.join(L) + '\n', encoding='utf-8')
    print(json.dumps({'raw_rows': len(raw), 'full_runs': len(runs), 'classes': {k: v['n'] for k, v in classes.items() if '/' not in k}}, indent=1))


if __name__ == '__main__':
    main()
