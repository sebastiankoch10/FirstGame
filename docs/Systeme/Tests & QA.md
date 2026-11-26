---
tags: [system, qa]
updated: 2026-11-26
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

- **`anchors`** (`QA/tools/check_telemetry_anchors.py`, Sekunden, ohne Build) läuft ab Stufe 1 immer: Alle Telemetrie-Anker der Simulationen müssen zum Code passen. Seit 25.11.
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
| `visual` | `run_native_harness.py visual` | Charakter- und Ausrüstungs-Layer: Datenintegrität, Anlegen/Ablegen/Wechsel, Pixelvergleich (seit 26.11. abends: volle Rüstung ohne Waffe ist pixelgleich zur Figur ohne Ausrüstung, die Waffe bleibt sichtbar), Kontaktbögen 8 Richtungen × 11 Zustände × 5 Sets, Weltbild |

- **QA-Prüfer** (nur lesend, gleicher Inhalt): `.codex/agents/qa.toml` und `.claude/agents/qa.md`. `.github/agents/qa.agent.md` ist Legacy (Copilot).
- **Abnahme von Inhalten:** Statusskala und Kriterien Q1–Q11 in [[Qualitätsstandard]].
- **Simulationen** (Stufe 4): `QA/tools/run_cohort.py`, `run_boss_mc.py`, `analyze_v3.py`.
- **Szenen-Aufnahme** (kein Test): `python tests/tools/record_scene.py walk|combat|spell|boss|horde` mit `--class`, `--level`, `--spell NAME --spell-level N`, `--boss`, `--minute`. Harness `tests/scene_harness.gml` (Präfix `sc`), `delta_time` fest auf 60 Hz, Ergebnis WebP plus Übersichtsbild unter `%LOCALAPPDATA%\FirstGame-Tests\scene\<Zeit>\`. Seit 25.11.
- **Aufräumen:** `tests/tools/clean_test_artifacts.py` (läuft nach `qa.py` und `record_scene.py`): je Ordner die 2 neuesten Läufe, Probe-Ordner nach 3 Tagen, Capture-PNGs in den Build-Speicherordnern, ungetrackte `QA/logs/regression-*` bis auf 3. `qa-cache.json` und `charcache` bleiben.
- `run_native_harness.py`: `EXTRA_REPLACEMENTS` für zusätzliche Code-Ersetzungen in der Testkopie; Captures werden verschoben statt kopiert.
- **Feste Bildzeit für `boss`** (`FIXED_DT_SUITES`, seit 25.11.): `delta_time` ist in der Testkopie 16667 µs. Grund: Der Orakel-Bot rechnet mit 1/60 s, die Bosse mit der echten Bildzeit; Bildraten-Schwankungen verschoben die Kennzahl „Muster erzwingen Umpositionierung“ (10/9/8 von 17).

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

- **Review-Center End-to-End** (seit 26.11.): `python tests/tools/review/review_e2e.py`. Zwei Builds und drei Starts mit Testurteilen: Dialog per Esc abbrechen, „Gut“ mit Kommentar (Umlaut) und „Nicht gut / komplett weg“ mit Kommentar per Klick und Enter, Persistenz nach Neustart, Sync genau einmal, Revision erneut offen, Archiv startbar, echter Speicherordner und Registry unverändert. Ergebnis in `tests/reports/review-e2e-result.json`, Nachweise unter `%LOCALAPPDATA%\FirstGame-Tests\review-e2e\`. Die Feature-Suite prüft seit 26.11. auch das Inventar (Ziehen, Tausch, ungültige Plätze, Abbruch, Rechtsklick, voller Rucksack, Vergleich).

- **Seit 26.11.:**
  - `record_scene.py --boss-hp` (Bossphase in Aufnahmen).
  - Die Klassen-Suite leert die Warteschlange (`telegraph_flush`) vor dem Pixeltest.
  - Die Boss-Suite zählt Feld-Gefahren (`field`) als Musterzellen.
  - `run_level_smoke.py` läuft mit fester Bildzeit (60 Hz), weil die Gegnerprüfungen zeitabhängig flackerten.
  - Seit 26.11. auch die Feature-Suite (`FIXED_DT_SUITES` in `run_native_harness.py`). Die Klassen-Suite hat mit `cd_sim_dt` schon eine simulierte Bildzeit.
  - Boss-Suite seit 26.11. mit dem Lauf `sequences` (Drache): Jede choreografierte Sequenz jeder Phase wird mit dem Orakel erzwungen. Geprüft wird: läuft vollständig und in Reihenfolge, jeder Schritt startet und erreicht die Aktivierung, sichere Position erreichbar. Danach ein natürlicher Lauf über 40 s: Sequenzen ergänzen, reguläre Angriffe bleiben.
  - Audit 26.11.:
    - Das Orakel der Boss-Suite sieht auch die geometrischen Altangriffe und die Projektile des Drachen (`legacy` in `bh_relevant`: Geometrie, Ring über `dragon_ring_geometry`, Flugbahn bis zum Horizont). Je Fall stehen `bullets` und `bullet_frames` im Bericht.
    - Die Perf-Suite hat das Szenario `horde_coins` (Horde plus 2.500 liegende Münzen, Kennzahl `active_coins`).
    - Die Level-Suite prüft das Münz-Culling in allen drei Leveln (`lv_coin_cull_check`).
  - `record_scene.py spellsheet --spell-level N`: alle 18 aktiven Zauber in einem Build, je 3 Zeitpunkte, beschriftetes Raster `spellsheet.png`.
  - `tests/tools/characters/check_base_neutral.py`: technische Abnahme von Basisfigur-Atlanten (echte Zellgrenzen und Alpha-Schnitt des Importers, `--dir` für Entwürfe). Seit 26.11. abends ohne Auftrag, weil die Basemodels verworfen sind ([[DECISIONS]]).

- **QA-Runner seit 26.11.:** Suiten `docs` (immer, Sekunden, `tests/tools/vault_check.py`), `review` (nur bei Review-Änderungen, Regeln `REVIEW_RX`/`REVIEW_TOUCH` in `qa.py`) und `perf` (`run_native_harness.py perf`, Lastmessung ohne parallele Last; GameMaker liefert weder Draw Calls noch Prozessspeicher an GML, Ersatz: `fps_real`, Lichtpass-Zeit, Instanzzahl). Level-Auswertung der Bots: `QA/tools/analyze_levels.py`.
  - CPU-Profil ohne Projektänderung: `python tests/tools/profile_perf.py [--funcs a,b]` umhüllt in einer Testkopie jedes Step-/Draw-Ereignis und die genannten Funktionen mit `get_timer()` und meldet ms und Aufrufe je Bild und Szenario (`tests/reports/perf-profile.json`). Die Hüllen kosten etwa 1 µs je Aufruf; nur Läufe dieses Werkzeugs untereinander vergleichen. Veraltete Harnesses und Runner liegen in `tests/_legacy/`. Prüf-Agenten: `qa` und `visual-qa` (je Claude und Codex).
  - `perf` meldet seit 26.11. zusätzlich Ausreißer über 50 ms (`spikes_over_50ms`, Logzeile `PERF SPIKE` mit Bildnummer). Mit `texture_debug_messages` stehen Texturlade-Meldungen im Log; `PERF WINDOW <Szenario>` markiert den Beginn jedes Messfensters. Ladezeit des Vorladens beim Run-Start: Logzeile `TEXTURE_PREFETCH ms`.
- **Grafik-Overhaul (26.11. abends):**
  - Die Testkopien aller Runner übernehmen jetzt auch `shaders/` (`run_native_harness`, `run_level_smoke`, `run_class_dragon_smoke`, `run_qa_regression`, `run_native_mc`; Hash-Eingaben in `qa.py`). Ohne den Ordner scheitert jeder Build.
  - `qa.py` ordnet `render_fx`, `fx_particles`, `atmos_fx`, `fx_attacks`, `render_pipeline` und `shaders/` den Suiten feature, visual und regression zu.
  - Die Feature-Suite prüft:
    - Partikelpool und Rate je Effektqualität;
    - die Nachbearbeitung je Stufe;
    - Lichtblitze reduziert auf 35 %;
    - die Obergrenze für Druckwellen;
    - dass die neuen Effekte den Spiel-Zufallsgenerator nicht berühren;
    - die Bausteine eines Einschlags;
    - kompilierte und aktive Shader sowie die Atmosphäre.
  - `clean_test_artifacts.py` behält `overhaul/` (Vorher-Nachher-Aufnahmen) und `reference/`.

## Abhängigkeiten
Alle Systeme, besonders [[Bosse]] · [[Talente]] · [[Ausrüstung]] · [[Level & Welten]] · [[Klassen & Startwaffen]]

## Bekannte Probleme
- Echtzeit-Harnesses nicht parallel unter Last laufen lassen (Level-Smoke 165/166 als Timing-Ausreißer).
- Die Telemetrie-Anker in `QA/tools/telemetry_injections.py` sind empfindlich. Die Suite `anchors` meldet Brüche jetzt sofort; am 25.11. waren zwei kaputt (Klassenprojektil nach den Waffen-Upgrades, Drachen-Nahangriff doppelter Anker) und sind repariert.
- `audit_visual_preservation.py` vergleicht mit der alten QA-Baseline. Absichtlich neu erzeugte Figuren-PNGs melden dort Abweichungen.
