---
tags: [system, qa]
updated: 2026-11-25
---
# Tests & QA

## Zweck
Native GameMaker-Tests in isolierten Kopien unter `%LOCALAPPDATA%\FirstGame-Tests\`, dazu Bot-Simulationen. Ergebnisse immer als PASS / FAIL / BLOCKED / NOT RUN.

## Einstieg: Stufen-Runner `tests/tools/qa.py`
- **Aufruf:** `--plan` zeigt Stufe und Suiten für den aktuellen Diff (`git diff HEAD` plus neue Dateien); ohne Option wird ausgeführt. Optionen: `--since <rev>`, `--tier N`, `--suites a,b`, `--force`.
- **Stufen:**

| Stufe | Auslöser | Was läuft |
|---|---|---|
| 0 | nur Doku | nichts |
| 1 | ≤40 GML-Zeilen, 1 System | eine Suite |
| 2 | Systemänderung | Suiten der Systeme |
| 3 | Kerndateien oder ≥3 Systeme | alle Suiten |
| 4 | Simulationen | nie automatisch; Befehle werden nur angezeigt |

- **`static`** (`validate_project`, 1–3 min) läuft nur bei geänderten `.yy`/`.yyp` und in Stufe 3. Jede Suite baut das Projekt ohnehin selbst, das ist der Compile-Check.
- **Cache:** `%LOCALAPPDATA%\FirstGame-Tests\qa-cache.json`.
  - Schlüssel ist der SHA-256 aller Build-Eingaben plus Harness. Ein stat-Index hält den Hash bei etwa 1 s.
  - Bei unveränderten Eingaben wird das letzte PASS wiederverwendet.
- **Ausgabe:** eine Zeile pro Suite. Die Zusammenfassung steht in `tests/reports/qa-last.json`, das Log unter `%LOCALAPPDATA%\FirstGame-Tests\qa-<suite>.log`.

| Suite | Runner | Inhalt |
|---|---|---|
| `regression` | `QA/tools/run_qa_regression.py` | 811 Kernprüfungen (Codex-Zeit), inklusive `tests/boss_v2_harness.gml` |
| `feature` | `run_native_harness.py feature` | Talente, Ausrüstung, VFX |
| `boss` | `run_native_harness.py boss` | Muster, Orakel, Kiting, Aufholattacken |
| `level` | `tests/tools/run_level_smoke.py` | 3 Level inklusive Neustart |
| `classes` | `tests/tools/run_class_dragon_smoke.py` | Startwaffen und Kombos, Warnflächen-Rendering, Klassen-DPS (150) |
| `visual` | `run_native_harness.py visual` | Charakter- und Ausrüstungs-Layer (75): Datenintegrität, Anlegen/Ablegen/Wechsel, Pixelvergleich, Kontaktbögen 8 Richtungen × 11 Zustände × 5 Sets, Weltbild |

- **QA-Prüfer** (nur lesend, gleicher Inhalt): `.codex/agents/qa.toml` und `.claude/agents/qa.md`. `.github/agents/qa.agent.md` ist Legacy (Copilot).
- **Abnahme von Inhalten:** Statusskala und Kriterien Q1–Q11 in [[Qualitätsstandard]].
- **Simulationen** (Stufe 4): `QA/tools/run_cohort.py`, `run_boss_mc.py`, `analyze_v3.py`.

## QA-Agent: Überprüfung 2026-11-24 (Claude)
**Vorher**
- `.codex/agents/qa.toml` war ein guter, nur lesender Codex-Prüfer mit sauberen Beweisregeln.
- Sein Fokus stammte aber aus der Zeit vor Talenten, Ausrüstung, Bossen v2 und Levels. Er kannte die vorhandenen Suiten nicht und hatte keine Stufen; jede Prüfung hätte die Testwege neu erarbeitet.
- Der Bericht hatte immer 5 Abschnitte. Ein Claude-Gegenstück fehlte.

**Ineffizient oder veraltet**
- 6 Runner (`run_atmosphere`/`dragon`/`gameplay`/`player`/`spell`/`survivor_smoke.py`) waren Aliase auf den abstürzenden `run_combat_smoke.py` und wurden entfernt.
- Alte Runner bauten in `output/` im Projekt; `classes` baut jetzt außerhalb und räumt immer auf.
- `classes` brach an veralteten Drachen-Fixtures ab. Jetzt sind diese optional (`global.cd_with_dragon`), weil der Drache in `boss` und `regression` geprüft wird.
- Der Warnflächen-Check prüft jetzt das aktuelle Design: sichtbar ab 0 %, Rand-Countdown wächst monoton.
- Jede Suite baute neu, auch bei unverändertem Code; jetzt greift der Cache.
- `static` lief 1–3 min als „Schnellcheck“; jetzt nur bei Ressourcenänderung.

**MCP**
- `gms-mcp` braucht 13–15 s bis zur ersten Antwort und reißt beim Sitzungsstart das 30-s-Limit von Claude.
- `.claude/settings.json` setzt `MCP_TIMEOUT=60000`. **Geprüft am 25.11.: wirkt nicht**; der Server brach nach dem Neustart wieder nach 30.000 ms ab. Vermutlich wird der Wert gelesen, bevor die Projekteinstellungen greifen. Abhilfe nur mit Zustimmung des Nutzers: Windows-Umgebungsvariable `setx MCP_TIMEOUT 60000`.
- Die Test-Runner brauchen das MCP nicht, sie rufen Igor direkt auf.

**Legacy** (in keiner Stufe):
- `run_combat_smoke.py`: Absturz
- `run_boss_v2_smoke.py`: doppelt zu `regression`
- `run_player_animation_legacy.py`: vor v3

## Abhängigkeiten
Alle Systeme, besonders [[Bosse]] · [[Talente]] · [[Ausrüstung]] · [[Level & Welten]] · [[Klassen & Startwaffen]]

## Bekannte Probleme
- Echtzeit-Harnesses nicht parallel unter Last laufen lassen (Level-Smoke 165/166 als Timing-Ausreißer).
- Die Telemetrie-Anker in `QA/tools/telemetry_injections.py` sind empfindlich.
- `audit_visual_preservation.py` vergleicht mit der alten QA-Baseline. Absichtlich neu erzeugte Figuren-PNGs melden dort Abweichungen.
