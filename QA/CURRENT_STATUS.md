# QA – aktueller Stand (24.11.2026)

Ergebnisse sind ehrlich gekennzeichnet: PASS / FAIL / BLOCKED / NOT RUN. Ein erfolgreicher Build ist kein Gameplay-Nachweis. Alle nativen Tests bauen isolierte Projektkopien außerhalb des Projektordners (`%LOCALAPPDATA%\FirstGame-Tests\`). Die Kopien werden danach gelöscht.

| Test | Befehl | Ergebnis |
|---|---|---|
| Kompilierung des echten Projekts | `python tests/tools/levels/compile_check.py` | PASS |
| Statische Projektprüfung | `python QA/tools/validate_project.py` | PASS: 1.380 Ressourcen, keine neuen Fehler. Drei bekannte alte verwaiste Kollisionsdateien. |
| Grafikerhalt | `python QA/tools/audit_visual_preservation.py` | PASS: 0 von 5.102 PNGs verändert, 0 von 258 Drachen-PNGs. Status „REVIEW“ nur wegen 407 hinzugefügter Ressourcen. |
| Bestehende Regression (Codex) | `python QA/tools/run_qa_regression.py` | **PASS 811/811**. Die Drachenstrahl-Vorlage wurde an den gewollten Schwenkstrahl angepasst. |
| Level-Smoke (3 Level) | `python tests/tools/run_level_smoke.py` | **PASS 166/166**, Ø 17 ms/Frame bei 80 Gegnern. Parallel zu anderen Echtzeit-Tests einmal 165/166 (Timing-Ausreißer, Konstrukt-Treffer). |
| Talente, Ausrüstung, Effekte, Charakterbildschirm | `python tests/tools/run_native_harness.py feature` | **PASS 129/129** (3 Klassen) |
| Boss-Mechaniken (Muster, Orakel, Kiting, Aufholattacken, Eskalationsregel) | `python tests/tools/run_native_harness.py boss` | **PASS 141/141** (endgültiger Code) |
| Vollständige Bot-Runs (v3) | `QA/tools/run_cohort.py … --label v3-cohort-a` | **1.080/1.080 abgeschlossen** (Commit `92855ef0`). Kein signifikanter Unterschied der Überlebenszeit zur Codex-Baseline (alle p > 0,05). Bericht: `QA/V3_SIMULATION_REPORT.md` |
| Isolierte Bosskämpfe v3 | `QA/tools/run_boss_mc.py --phase after --cases 270 … --out QA/data/v3-boss.jsonl` | **270/270 abgeschlossen** mit dem endgültigen Code. Bot-Siegquoten Drache 44/17/8 % in Minute 5/10/15 (Codex 50/54/37 %), Hexen 44/50/25 %, Behemoth 61/50/50 %. Vier Vorläufe deckten Fairness-Probleme auf; sie wurden ohne Zahlenänderungen korrigiert, die Zwischenstände sind archiviert. |
| Alter Kampf-Smoke | `python tests/tools/run_combat_smoke.py` | FAIL, schon vor diesem Auftrag (veraltete Vorlage `v2_passive_behaviour`). Nicht angefasst. |
| Menschlicher Spieltest | – | NOT RUN |

Ältere Detailberichte der Codex-QA (Stand 23.11.) bleiben gültig für ihren damaligen Code-Stand: `QA_SUMMARY.md`, `SIMULATION_REPORT.md`, `BOSS_BALANCE.md`, `ABILITY_BALANCE.md`, `CLASS_BALANCE.md`.
