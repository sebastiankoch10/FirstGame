# FirstGame – Arbeitsregeln für Claude

GameMaker-2024-Projekt (Runtime 2024.14.4.268), Top-down-Survivor mit Runs von 30 Minuten. Projektsprache und Berichte: Deutsch. Der Code ist dicht geschriebenes GML.

## Verbindliche Dokumente

- `DESIGN/BOSS_DESIGN.md`: Bosskampf-Philosophie. Höchste Priorität für jede Bossarbeit.
- `LEVEL_EXPANSION_PROGRESS.md`: Stand der drei Level, Tests, offene Punkte.
- `QA/QA_SUMMARY.md`, `QA/README.md`: Bot-Simulationen und Regression (Codex-Ära).
- Die übrigen `*_REPORT.md` im Root dokumentieren frühere Stände. Werte darin können veraltet sein; im Zweifel gilt der Code.

## Regeln

- Keine numerischen Balancing-Änderungen (HP, Schaden, XP, Klassenwerte, Skalierung) ohne ausdrücklichen Auftrag.
- Kein Git-Commit und kein Push ohne Auftrag. Der Arbeitsstand ist groß und weitgehend uncommittet; vor größeren Änderungen ein ZIP unter `output/` anlegen.
- Kein Build ist ein Gameplay-Nachweis. Ergebnisse als PASS / FAIL / BLOCKED / NOT RUN berichten.
- Vorhandene Drachen-PNGs und ArtPack-Originale nicht verändern.

## Architektur (Kurzfassung)

- **Level:** `scripts/level_worlds` (Definitionen, Gegnerpools, Levelauswahl) und `scripts/level_world` (Laufzeit der generierten Welten). Index 0 ist der Wald (`Room1`, eigener `master_world`-Renderer), 1 `RoomSwamp`, 2 `RoomAshfrost`.
- **Bosse:**
  - `boss_combat`: Zeitplan 1/3 Minibosse, ab 5/10/…/30 zufälliger Hauptboss
  - `boss_framework_v2`: Freischaltung 3/6/9, Skalierung, Auswahl
  - `boss_encounters_v2`: Hexen/Behemoth
  - `dragon_encounter`: Drache
  - `boss_hazards_v2`, `attack_telegraph`: gemeinsame Gefahren und Countdown
- **Gegner:** `ObjectMonster`. Room1 nutzt `master_skeleton`, die neuen Level nutzen `lvl_kind` und `level_enemy_step`.
- **Spawn:** `survivor_balance` (`population_profile`, `population_step`).

## Fallstricke

- **Asset-Namen sind globale Bezeichner.** Ein bloßes `if(master_skeleton)` liefert die Skript-Referenz (immer wahr), nicht die Instanzvariable. Deshalb `self.<name>` verwenden oder Variablennamen meiden, die einem Asset gleichen.
- **Neue Skripte, Sprites und Objekte** müssen im `FirstGame.yyp` registriert sein. Unbekannte Funktionsnamen kompilieren trotzdem, nämlich als Instanzvariablen, und scheitern erst zur Laufzeit. Zum Registrieren `tests/tools/levels/gm_project.py` verwenden.
- **Die IDE-Diagnose** meldet bei einzeiligen `if(...)return` und Komma-`var`-Listen viele Fehlalarme („unreachable“, „argument-count“).
- **Bash-Heredocs** mit Python-Code, der `'''` enthält, bricht der Tool-Wrapper ab. Solche Skripte als Datei schreiben.

## Werkzeuge

- Build: `python tests/tools/levels/compile_check.py`. Produktions-ZIP: `python tests/tools/build_production.py`.
- Level-Laufzeittests: `python tests/tools/run_level_smoke.py` (isolierte Kopie unter `output/level-smoke/`).
- Bestehende Regression: `python QA/tools/run_qa_regression.py` (811 Prüfungen), weitere unter `tests/tools/run_*_smoke.py`.
- Grafik- und Weltgenerierung: `tests/tools/levels/` (siehe `LEVEL_EXPANSION_PROGRESS.md`).
- Der GMS-MCP-Server (`.mcp.json`) kann beim Start in einen Timeout laufen. Die Python-Runner rufen Igor direkt auf und brauchen ihn nicht.
