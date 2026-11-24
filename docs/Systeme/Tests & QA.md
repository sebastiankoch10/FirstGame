---
tags: [system, qa]
updated: 2026-11-24
---
# Tests & QA

## Zweck
Native GameMaker-Tests in isolierten Kopien und Bot-Simulationen. Ergebnisse immer als PASS / FAIL / BLOCKED / NOT RUN.

## Wichtige Dateien
- `tests/tools/run_native_harness.py` mit `feature` (`tests/feature_harness.gml`) und `boss` (`tests/boss_harness.gml`).
- `tests/tools/run_level_smoke.py` mit `tests/level_harness.gml`. `QA/tools/run_qa_regression.py` mit `QA/tools/qa_regression_harness.gml` und `tests/boss_v2_harness.gml`.
- Simulationen: `QA/tools/run_native_mc.py`, `run_cohort.py`, `run_boss_mc.py`, `native_mc_harness.gml`, `telemetry_injections.py`.
- Auswertung: `QA/tools/analyze_qa.py` (Codex) und `QA/tools/analyze_v3.py`.
- Status: `QA/CURRENT_STATUS.md`. Berichte: `QA/V3_SIMULATION_REPORT.md`, `QA/QA_SUMMARY.md`.

## Abhängigkeiten
Alle Systeme, besonders [[Bosse]] · [[Talente]] · [[Ausrüstung]] · [[Level & Welten]]

## Bekannte Probleme
- `run_combat_smoke.py` ist veraltet.
- Echtzeit-Harnesses bitte nicht parallel unter Last laufen lassen.
- Die Telemetrie-Anker sind empfindlich.
