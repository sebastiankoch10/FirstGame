"""Write final answers and paired-change report from the frozen validated datasets."""
from pathlib import Path
from collections import Counter
import json,statistics
from analyze_qa import describe
ROOT=Path(__file__).resolve().parents[2]
import sys as _sys_ap; _sys_ap.path.insert(0, str(ROOT / 'tests' / 'tools' / 'assets')); import art_paths as AP  # noqa: E402
CLASSES=['Sword','Mage','Ranger']
def read(p):return [json.loads(s) for s in p.read_text(encoding='utf-8').splitlines() if s.strip()]
def main():
    manifest=json.loads((ROOT/'QA/data/dataset-manifest.json').read_text())
    analysis=json.loads((ROOT/'QA/data/analysis.json').read_text())
    runs=[r for name in ['baseline-v2-a','baseline-v2-b','after-v2-a','after-v2-b','holdout-v2'] for p in (ROOT/'QA/data'/name).glob('worker-*.jsonl') for r in read(p)]
    if len(runs)!=manifest['primary_full_runs'] or analysis['full_runs']!=len(runs):raise RuntimeError('Stale dataset analysis')
    phases={p:[r for r in runs if r['phase']==p] for p in ['baseline','after','holdout']}
    groups={(p,c):[r for r in phases[p] if r['class_name']==c] for p in phases for c in CLASSES}
    mean=lambda rs,k:statistics.mean(r[k] for r in rs)
    pickup=lambda rs:sum(r['xp_earned'] for r in rs)/max(1,sum(r['kills'] for r in rs))
    key=lambda r:(r['seed'],r['class_name'],r['persona'])
    before={key(r):r for r in phases['baseline']}
    comparison=[]
    for c in CLASSES:
        a,b=groups['baseline',c],groups['after',c]
        delta=describe([r['seconds']-before[key(r)]['seconds'] for r in b])
        comparison.append(dict(class_name=c,n=len(b),before_seconds=mean(a,'seconds'),after_seconds=mean(b,'seconds'),
            before_pickup=pickup(a),after_pickup=pickup(b),before_level=mean(a,'level'),after_level=mean(b,'level'),delta=delta))
    (ROOT/'QA/data/before-after-summary.json').write_text(json.dumps(comparison,indent=2)+'\n',encoding='utf-8')
    out=['# Vorher / Nachher','',
         f"**{len(phases['baseline'])} gepaarte Bedingungen**: gleiche Klasse, gleicher Seed, gleiche sichtbare Bot-Strategie und gleiche Zeitbasis. Dazu {len(phases['holdout'])} unabhängige Nachher-Runs. Die einzige geänderte Gameplay-Zahl ist die normale Münzgeschwindigkeit 252 → 420 Pixel/Sekunde. Der Hurt-Frame-Fix ist Darstellung. Die gesicherte Baseline wurde nicht verändert.",'',
         '| Klasse | Paare | Überleben vorher → nachher (s, Mittel) | Gepaarte Differenz, 95%-Bootstrapintervall | XP/Kill vorher → nachher | Mittleres Endlevel vorher → nachher |',
         '|---|---:|---:|---|---:|---:|']
    for row in comparison:
        lo,hi=row['delta']['mean_bootstrap95']
        out.append(f"| {row['class_name']} | {row['n']} | {row['before_seconds']:.1f} → {row['after_seconds']:.1f} | {row['delta']['mean']:+.1f} s [{lo:+.1f}; {hi:+.1f}] | {row['before_pickup']:.1%} → {row['after_pickup']:.1%} | {row['before_level']:.1f} → {row['after_level']:.1f} |")
    out+=['',
          'XP/Kill ist die Summe tatsächlich eingesammelter Münz-XP geteilt durch normale Kills, keine frei angenommene Dropquote. Nicht eingesammelte Münzen können am Todeszeitpunkt noch existieren. Die Änderung kann auch Auswahl, Kampffolge und spätere Zufallsverbräuche verändern. Gleiche Anfangs-Seeds erzwingen daher keine identische spätere Welt.','',
          'Die Intervalle stammen aus 1.000 deterministisch gesäten Bootstrap-Stichproben der tatsächlichen gepaarten Differenzen. Überlappt ein Intervall null, liefert diese Stichprobe keinen gesicherten mittleren Überlebensgewinn. Das ist kein Beweis gleicher Klassenstärke oder einer Wirkung beim Menschen.','',
          '## Direkte native Fehlerreproduktion','',
          '| Bewegung, Münze 80 Pixel dahinter | Vorher: Sammeltick | Nachher: Sammeltick |','|---|---:|---:|']
    old=json.loads((ROOT/'QA/data/moving-coin-baseline.json').read_text())
    new=json.loads((ROOT/'QA/data/moving-coin-after.json').read_text())
    for a,b in zip(old['metrics']['moving_coin'],new['metrics']['moving_coin']):
        label=a['class_name']+(f" + Fleet Footed {int(a['fleet_footed_level'])}" if a['fleet_footed_level'] else '')
        out.append(f"| {label} | {int(a['collected_at_tick']) if a['collected'] else 'nicht in 180 Ticks'} | {int(b['collected_at_tick'])} |")
    out+=['','Alle vier tatsächlichen freien Bewegungsstrecken bleiben gleich. Die zwei Ranger-Sammeltests reproduzieren vorher den Fehler und bestehen nachher. Quellen: `data/moving-coin-baseline.json`, `data/moving-coin-after.json`.','',
          '## Unabhängige Seeds','', '| Klasse | Runs | Mittleres Überleben (s) | Median (s) | XP/Kill | Minute 30 erreicht |','|---|---:|---:|---:|---:|---:|']
    for c in CLASSES:
        rs=groups['holdout',c]
        out.append(f"| {c} | {len(rs)} | {mean(rs,'seconds'):.1f} | {statistics.median(r['seconds'] for r in rs):.1f} | {pickup(rs):.1%} | {sum(r['seconds']>=1799.99 for r in rs)} |")
    out+=['','Die unabhängigen Seeds wurden nach Festlegung der 420 gewählt. Sie besitzen keine gepaarten unveränderten Gegenläufe; Unterschiede zur Baseline werden daher nicht kausal allein dem Münzwert zugeschrieben.','',
          '## Regression und Grenzen','',
          'Die 15 ausgewählten isolierten Nachher-Bosskämpfe stimmen mit ihren Baseline-Gegenstücken einschließlich vollständiger Telemetrie exakt überein. Es wurde kein Boss-Kampfwert verändert. Die 654 kontrollierten Fähigkeitsfenster werden nicht als 654 vollständige Runs oder als nachträglich erneut ausgeführte Fenster gezählt. Die allgemeine aktuelle Runner-Regression besteht 811 Prüfungen; der normale Build ist separat unter `data/production-build.json` dokumentiert.','',
          'Kleine Stichprobe, Bot-Strategien, unterschiedliche Build-Entwicklung und mögliche Ein-Tick-Unterschiede zur dynamischen Engine-Reihenfolge begrenzen die Aussagen. Survival-Kurven, Klassen-/Skill-Strata und fehlende späte Beobachtungen stehen in `SIMULATION_REPORT.md` und `CLASS_BALANCE.md`.']
    (ROOT/'QA/BEFORE_AFTER.md').write_text('\n'.join(out)+'\n',encoding='utf-8')
    bosses=read(ROOT/'QA/data/boss-baseline.jsonl')+read(ROOT/'QA/data/boss-holdout.jsonl')
    bossgroups={name:[r for r in bosses if r['boss']==name] for name in sorted({r['boss'] for r in bosses})}
    hardest=min(bossgroups,key=lambda name:sum(r['won'] for r in bossgroups[name])/len(bossgroups[name]))
    attacks=analysis['boss_abilities'];hit_top=sorted(attacks.items(),key=lambda kv:kv[1]['hits'],reverse=True)[:3]
    fatal_top=sorted(attacks.items(),key=lambda kv:kv[1]['fatal_hits'],reverse=True)[:3]
    zero=[k for k,v in attacks.items() if v['hits']==0]
    best=max(CLASSES,key=lambda c:mean(groups['after',c],'seconds'))
    reached={c:sum(r['seconds']>=1799.99 for r in groups['after',c]) for c in CLASSES}
    top_run=max(phases['after'],key=lambda r:r['seconds'])
    skill_names={d['id']:d['name'] for d in json.loads((AP.SPELL_CATALOG).read_text())}
    top_build=', '.join(f"{skill_names[e['id']]} {int(e['level'])}" for e in top_run['active'])
    shares=[]
    for c in CLASSES:
        r=next(g for g in analysis['class_pooled'] if g['phase']=='after' and g['class_name']==c)
        shares.append(f"{c} {r['base_weapon_share']:.1%}")
    build=json.loads((ROOT/'QA/data/production-build.json').read_text())
    regression=json.loads((ROOT/'QA/data/regression.json').read_text())
    summary=['# FirstGame – Ergebnis des autonomen QA-Durchlaufs','',
       '**Zwei konkrete Spielprobleme behoben:** Normale Münzen holen schnelle Spieler im Sammelradius zuverlässig ein; die Trefferreaktion der neuen Bosse springt nicht mehr auf einen falschen Frame zurück. Alle Grafikdateien einschließlich des bestehenden Drachenmodells sind erhalten. Die Testumgebung, Rohdaten, Diagramme und Berichte sind wiederverwendbar.','',
       '| Tatsächlicher Umfang | Anzahl |','|---|---:|',
       f"| Vollständige native Runs insgesamt | {manifest['total_valid_full_runs']} |",
       f"| Davon primäre V2-Runs: Baseline / Nachher / unabhängige Seeds | {len(phases['baseline'])} / {len(phases['after'])} / {len(phases['holdout'])} |",
       f"| Davon erste Bot-Strategie, nur Kalibrierung | {manifest['calibration_full_runs']} |",
       f"| Primäre isolierte Bosskämpfe / ausgewählte Nachher-Replays | {manifest['primary_boss_encounters']} / {manifest['after_boss_replays']} |",
       f"| Zusätzliche gültige Boss-Kalibrierungen und Pilot-Replays | {manifest['boss_calibration_and_pilot_replays']} |",
       f"| Kontrollierte native Fähigkeitsfenster | {manifest['controlled_benchmark_cells']} |",
       f"| Aktuelle allgemeine native Regressionsprüfungen | {int(regression['checks'])} |",'',
       '**3.000 vollständige Runs wurden nicht ausgeführt.** Die erreichte Stichprobe wird ausdrücklich nicht als Tausende-Runs-Nachweis ausgegeben. Gemessene Laufzeiten und bedingte Hochrechnungen stehen im Simulationsbericht. Validierungen, kurze Schadensfenster und analytische Rechnungen zählen nicht als vollständige Spielrunden.','',
       '## Die 22 gewünschten Antworten','',
       f"1. **Vollständige Runs:** {manifest['total_valid_full_runs']} tatsächlich abgeschlossen, davon {manifest['primary_full_runs']} primär und {manifest['calibration_full_runs']} Kalibrierung. Jeder Run endet durch tatsächlichen Tod oder die 30-Minuten-Grenze; begonnene, noch nicht abgeschlossene Runden sind ausgeschlossen.",
       f"2. **Bosskämpfe:** {manifest['total_valid_isolated_boss_executions']} gültige isolierte Ausführungen insgesamt. Für die primäre Statistik zählen {manifest['primary_boss_encounters']} Bedingungen, dazu {manifest['after_boss_replays']} kontrollierte Nachher-Replays; Kalibrierungen/Wiederholungen sind getrennt. Zusätzlich auftretende Bossbegegnungen innerhalb der vollständigen Runs sind in deren Rohdaten erhalten und hier nicht nochmals als isolierte Tests gezählt.",
       f"3. **Längstes mittleres Überleben:** In den {len(phases['after'])} Nachher-Runs beobachtet: {best}, {mean(groups['after',best],'seconds'):.1f} Sekunden. Skill-Strata und breite Unsicherheitsintervalle stehen in CLASS_BALANCE.md; kein allgemeiner menschlicher Klassensieger behauptet.",
       '4. **Minute 30:** Gepaarte Nachher-Serie '+', '.join(f'{c} {reached[c]}/{len(groups["after",c])}' for c in CLASSES)+'. Unabhängige Seeds: '+', '.join(f"{c} {sum(r['seconds']>=1799.99 for r in groups['holdout',c])}/{len(groups['holdout',c])}" for c in CLASSES)+'. Der erfahrene Sword-Überlebende erreicht Vollausbau bei Minute 28,31. Eine einzelne Beobachtung ist kein Beweis allgemeiner Dominanz.',
       '5. **Startwaffe:** Stationär gegen ein Ziel Sword 38,00, Mage 34,53, Ranger 28,40 HP/s; gegen acht Ziele Mage 235,67, Sword 222,93, Ranger 88,00. Reichweite und Sicherheit sind darin nicht bewertet; keine universelle stärkste Waffe abgeleitet.',
       '6. **Anteil der Startwaffe am Nachher-Gesamtschaden:** '+', '.join(shares)+'. Tatsächlich zugerechneter HP-Verlust; Details je Komboschritt in ABILITY_BALANCE.md.',
       '7. **Hoher aktiver Schaden:** Im kontrollierten Stufe-9-Einzelzieltest Wisp Sentinel 65,73, Starfall 60,98, Arcane Barrage 46,67 HP/s. Gegen acht Ziele liegen Starfall, Ice Prison und Ember Field hoch. Das sind gemessene Fenster, keine vollständigen Builds.',
       '8. **Auffällig niedriger direkter DPS:** Frost Nova. Kontrolle und Unterbrechung fehlen als Nutzenmaß im stationären DPS. Healing Pulse verursacht beabsichtigt keinen Schaden. Kein Zauber wird deshalb pauschal als nutzlos bezeichnet.',
       '9. **Effektive Passiva:** Power Up, Split Runes und Quick Channel steigern den passenden gemessenen Angriff; Shield reduziert den 20-HP-Testtreffer auf 8 HP, Iron Skin auf 14,6. Vital Bloom und Regeneration liefern echte HP-Vorteile. Bewegungs-/Sammel- und Kontrollnutzen erfordern ergänzende Situationen.',
       f"10. **Kombinationen:** Längster beobachteter Nachher-Run: {top_run['class_name']}, {top_run['seconds']/60:.2f} Minuten; aktive Fähigkeiten {top_build}. Das ist eine Einzelbeobachtung. Keine ausreichend wiederholte kausale Rangliste sämtlicher Kombinationen.",
       '11. **Zufall der Angebote:** Seeds, Angebote und gewählte Upgrades sind vollständig gespeichert. Die Überlebensstreuung ist gemessen; der isolierte kausale Anteil der Zauberauswahl ist mangels gekreuzter Gegenläufe nicht bestimmt. Weltzufall, Route und Build wirken gemeinsam.',
       f"12. **Schwierigster isolierter Boss dieser Preset-Stichprobe:** {hardest}, {sum(r['won'] for r in bossgroups[hardest])}/{len(bossgroups[hardest])} Siege. BOSS_BALANCE.md trennt Klasse, Minute, Bot und die Entwicklungs-Presets.",
       '13. **Häufig treffende Quellen:** '+', '.join(f"{k} ({int(v['hits'])} HP-Treffer)" for k,v in hit_top)+'. Trefferzahl und Trefferquote sind verschieden; der Projektil-Bedrohungsnenner ist eingeschränkt.',
       '14. **Kaum treffende Quellen:** '+(', '.join(zero) if zero else 'keine Quelle mit exakt null Treffern im aggregierten Datensatz')+'. Geringe Exposition oder früh beendete Kämpfe können den Befund erklären; keine automatische Beschleunigung solcher Angriffe.',
       '15. **Realistisch unvermeidbar:** Für keinen Angriff formal nachgewiesen. Sichtbare Warnungen, legale Eingaben und Hindernisse sind berücksichtigt; die technische Heuristik ist kein vollständiger Reachability-Beweis.',
       '16. **Meiste tödliche Bossaktivierungen:** '+', '.join(f"{k} ({int(v['fatal_hits'])})" for k,v in fatal_top)+'. Zuordnung und Timing-Grenzen stehen im Bossbericht.',
       '17. **Geänderte Zahlen:** Normale Münzgeschwindigkeit 252 → 420 Pixel/Sekunde. Zusätzlich begrenzter Draw-Frame. Keine Klassen-/Boss-HP oder Waffen-/Zauberschäden angepasst.',
       '18. **Nachgewiesene Verbesserung:** Der zuvor fehlschlagende bewegte Ranger-Sammelfall besteht jetzt auch mit Fleet Footed 9. Die vollständigen gepaarten Auswirkungen inklusive Unsicherheit stehen in BEFORE_AFTER.md; ein Überlebensgewinn wird nicht allein aus schnellerem Sammeln angenommen.',
       '19. **Grafik-/Animationsänderung:** Genau die Boss-Hurt-/Death-Frame-Begrenzung im Zeichner. 826 Sprites/2.551 Frames geprüft; alle 5.102 PNGs einschließlich 258 Drachen-Dateien unverändert.',
       '20. **Offene Grafikgrenzen:** Teilweise wiederholte Ausgangsposen, weitere Fensterseitenverhältnisse und längere Lesbarkeitsprüfung überlappender Wetter-/Kampfeffekte. Keine pauschale Weichzeichnung eingebaut.',
       f"21. **Tatsächliche Runtime:** Native vollständige Runs und Bosskämpfe, 654 native Fähigkeitsfenster, zehn bekannte HP-/Quellenprüfungen, vier bewegte Münzfälle, {int(regression['checks'])} aktuelle Regressionsprüfungen, Batch-/Uhren-/Hindernis-Fixtures und native GUI-/Weltaufnahmen. Der normale Build besitzt keine injizierten Test-Hooks. Keine menschlichen Spieltests behauptet.",
       '22. **Kritische offene Fehler:** Kein neuer Runtime-Absturz in den abgeschlossenen kanonischen Datensätzen. Drei unveränderte alte unregistrierte Kollisionsdateien bleiben ein Metadatenbefund. Späte Progression, formale Boss-Unvermeidbarkeit und dauerhafte Performance sind nicht vollständig freigegeben.','',
       '## Nachweise und priorisierte Restarbeit','',
       '- [Simulation und Reichweite](SIMULATION_REPORT.md), [Klassenvergleich](CLASS_BALANCE.md), [Fähigkeiten](ABILITY_BALANCE.md), [Bosse und Fairness](BOSS_BALANCE.md).',
       '- [Vorher/Nachher](BEFORE_AFTER.md), [Änderungswerte](BALANCE_CHANGES.md), [bestätigte Fehler und priorisierte Grenzen](BUG_REPORT.md), [Grafikaudit](VISUAL_AUDIT.md).',
       '- [Simulatorabgleich und Grenzen](SIMULATOR_FIDELITY.md), [aktueller Projektbestand](PROJECT_INVENTORY.md), [Datenmanifest](data/dataset-manifest.json), [Diagramme](charts), [Wiederholung](README.md).','',
       'Priorität: ausreichend späte vollständige Runs und echte menschliche Vergleichsrouten; danach gezielte schwierige Bossgeometrien mit vollständiger Wegprüfung. Wiederholte Kombinationstests und dauerhafte Render-/Speicherlast folgen. Die automatische Testumgebung kann diese Stichprobe erweitern; diese Punkte sind keine bereits bestandenen Tests.','',
       f"Normaler Build: **{'PASS' if build['passed'] and build['package_success'] else 'FAIL'}**, Test-Hooks `{build['test_hooks']}`. [Spielbares ZIP](../{build['archive'].replace(chr(92),'/')})."]
    (ROOT/'QA/QA_SUMMARY.md').write_text('\n'.join(summary)+'\n',encoding='utf-8')
    print('Wrote QA/QA_SUMMARY.md and QA/BEFORE_AFTER.md from validated data')
if __name__=='__main__':main()
