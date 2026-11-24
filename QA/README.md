# Reproduzierbare FirstGame-QA

> **Hinweis vom 24.11.2026:** Auf Wunsch des Projektinhabers liegen keine ausführbaren Test-Builds mehr im Projektordner.
> - Die alten Artefakte unter `output/native-mc-*` und `output/production-build` wurden entfernt; ihre Logs und Daten bleiben erhalten.
> - `run_native_mc.py` legt neue Artefakte unter `%LOCALAPPDATA%\FirstGame-Tests\native-mc-<phase>\<stamp>` an. Für `--reuse` den dort ausgegebenen Pfad verwenden.
> - `run_qa_regression.py` löscht seine Projektkopie nach dem Lauf.
> - Die neue Kohorte v3 (Talente, Ausrüstung, Boss-Choreografie) steht in `QA/data/v3-cohort-a` mit der Auswertung `QA/tools/analyze_v3.py` (→ `QA/V3_SIMULATION_REPORT.md`).

`QA_SUMMARY.md` beantwortet die 22 Abschlussfragen. `data/dataset-manifest.json` benennt die tatsächlich gezählten Dateien mit SHA256. Die Tabellen und Diagramme werden aus diesen nativen Rohdaten erzeugt; Validierungsproben, Kalibrierungen und vollständige Runs besitzen getrennte Zähler.

## Voraussetzungen und unveränderter Ausgangsstand

Python 3.10, die lokal lizenzierte GameMaker-Runtime 2024.14.4.268 und das bereits installierte Paket `gms-mcp` werden verwendet. Die Runner suchen die bestehende lokale Runtime/Lizenz. Es gibt keine bezahlte Musik-/Bild-/Cloud-API. Testkopien und Ausgabe liegen im Projekt; GameMaker benötigt Lesezugriff auf seine Installation und Lizenz außerhalb des Arbeitsordners.

`baseline/project` enthält die tatsächlichen Quell-/Raum-/Objektdateien vor diesem Auftrag. `baseline/manifest.json` enthält deren Prüfsummen und die Prüfsummen der 5.102 nativen PNGs. `save_baseline.py` überschreibt einen vorhandenen Ausgangsstand nicht. Eine neue Baseline benötigt bewusst ein anderes Verzeichnis und eine eigene Datensatzkennung.

Die Ausgangs- und Nachher-Artefakte dieses Durchlaufs sind:

- Baseline: `output/native-mc-baseline/20261123-174801`.
- Nachher: `output/native-mc-after/20261123-175857`.

Sie verwenden dieselbe verbesserte sichtbare Bot-Strategie. Die frühere Strategie bleibt ausschließlich als Kalibrierung erhalten. `SIMULATOR_FIDELITY.md` dokumentiert Uhren, Kollisionen, feste Schritt-Reihenfolge, RNG und verbleibende Grenzen. Die großen re-generierbaren Artefakt-/Cache-Verzeichnisse sind nicht für Git vorgesehen; Quellen, Prüfberichte und Rohdaten bleiben erhalten.

## Neue tatsächliche Runden ausführen

Eine neue Kennung und neue Seeds verhindern Überschreiben oder Doppelzählung. Folgender Aufruf verwendet die bereits geprüfte Nachher-Version für 36 unabhängige vollständige Runden, verteilt auf vier Prozesse:

```powershell
python QA/tools/run_cohort.py --reuse output/native-mc-after/20261123-175857 --phase holdout --workers 4 --runs-per-class-per-worker 3 --seedstart 990101 --label additional-holdout --timeout 3600
```

Jeder Prozess führt je drei Runden pro Klasse aus: je einen Anfänger-, durchschnittlichen und erfahrenen Bot. Jede Runde läuft mit tatsächlichen 1/60-Schritten bis zum Tod oder 1.800 simulierten Sekunden. Der Prozess-Timeout ist kein kürzeres gültiges Run-Ende; eine unterbrochene letzte Runde zählt nicht. Vollständige Checkpoints werden sofort geschrieben. Die Dateien nicht durch bloßes Zusammenkopieren erneut als unabhängige Beobachtungen zählen.

Für einen frischen isolierten Baseline-Build statt eines vorhandenen Artefakts:

```powershell
python QA/tools/run_native_mc.py --phase baseline --mode validation --class-name Mage --persona experienced --batchsize 600 --probe-ticks 600 --out QA/data/new-validation.jsonl
```

Validierung ist eine kurze Zustandsprobe und zählt nicht als vollständige Runde. `--phase after` baut aus den aktuellen Produktionsquellen; `--phase baseline` aus der gesicherten Quelle. Beim Wiederverwenden prüft der Runner die Quellphase. `--phase holdout` verlangt ein vorhandenes geprüftes Artefakt und speichert dessen tatsächliche `source_phase` zusätzlich.

## Boss-/Fähigkeitsprüfungen und Regression

```powershell
python QA/tools/run_boss_mc.py --reuse output/native-mc-after/20261123-175857 --phase after --cases 15 --seedstart 810101 --batchsize 600 --out QA/data/new-boss-replay.jsonl
python QA/tools/run_qa_regression.py
python QA/tools/validate_project.py
python QA/tools/audit_visual_preservation.py
python tests/tools/build_production.py
```

`run_qa_regression.py --coin-fixture=after` prüft vier tatsächliche bewegte Münzfälle; der Baseline-Test wurde vor der Korrektur ausgeführt und enthält absichtlich zwei nachgewiesene Sammelfehler. Ihn jetzt gegen geänderte Quellen erneut zu starten stellt die alte Quelle nicht automatisch wieder her.

`--stress-only` erzeugt einen separaten kurzen gerenderten 150-Gegner-Fall und schreibt `data/performance.json`. Er verwendet erhöhte Fixture-HP und ist ausdrücklich kein vollständiger Run. Für einen aussagekräftigen Rendervergleich sollten keine parallelen MC-Prozesse laufen.

Die kontrollierte Matrix liegt in `ability_bench_harness.gml`; `run_native_mc.py --mode bench` baut/führt sie aus. Der aktuelle Umfang sind 654 tatsächliche 15-Sekunden-Fenster; `validate_bench_data.py` prüft Matrix, Quellensummen und bekannte HP-Prüfungen. `validate_boss_data.py` prüft tatsächliche Boss-Endzustände und Telemetrie. Stationäre Ziele und Entwicklungs-Presets sind entsprechend gekennzeichnet.

## Tabellen, Diagramme und Berichte wieder erzeugen

Nur die Diagramme benötigen Matplotlib:

```powershell
python -m venv QA/.venv
QA/.venv/Scripts/python.exe -m pip install -r QA/requirements.txt
QA/.venv/Scripts/python.exe QA/tools/finalize_qa.py --charts
python QA/tools/write_ability_report.py
python QA/tools/write_boss_report.py
python QA/tools/write_simulation_reports.py
python QA/tools/write_completion_report.py
python QA/tools/update_progress.py --final
```

`finalize_qa.py` ist auf die fünf abgeschlossenen Kohorten dieses Durchlaufs festgelegt und verweigert unvollständige, doppelte, ungepaarte oder zeitlich inkonsistente Daten. Für andere künftige Kohorten können die Dateilisten gezielt an `analyze_qa.py --runs ... --boss ... --bench ... --charts` übergeben werden. PowerShell expandiert native Wildcard-Argumente nicht zuverlässig; konkrete Dateilisten verwenden oder die Python-Glob-Expansion wie im Finalisierungsskript nutzen.

Ausgaben: vollständige JSONL-Rohdaten; `runs.csv`, `boss-encounters.csv`, `controlled-benchmarks.csv`; `analysis.json`; PNG- und SVG-Diagramme unter `charts/`. 95%-Wilsonintervalle gelten für binäre Ereignisse, deterministisch gesäte Bootstrapintervalle für gemessene Mittelwerte/gepaarte Differenzen. Das sind Unsicherheiten der Bot-Stichprobe, keine menschlichen Erfolgswahrscheinlichkeiten.

`update_progress.py` aktualisiert jederzeit die tatsächlich abgeschlossenen Checkpoints. Bei einer Unterbrechung zuerst diesen Stand und die Kohorten-Manifeste lesen; einen vorhandenen Kohortennamen nicht erneut verwenden. Keine abgeschlossene Serie stillschweigend als neu zählen.
