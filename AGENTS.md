# FirstGame – Anleitung für KI-Agenten (Claude Code und Codex)

**Einzige Hauptquelle** für beide Agenten. `CLAUDE.md` importiert nur diese Datei. Projektsprache, Doku und Berichte sind **Deutsch**. Laufender Stand: `docs/HANDOFF.md`.

## Projekt
- **Spiel:** Top-down-Survivor mit Runs von 30 Minuten.
  - Klassen: Schwertkämpfer `Sword`, Zaubermeisterin `Mage`, Waldläufer `Ranger`, jeweils mit automatischer Startwaffe.
  - Zauber: 18 aktive und 18 passive, Stufe 1–9, 6+6 Slots.
  - Talente (Taste T) und Ausrüstung (jeder Run startet ohne).
  - Level: Wald (`Room1`), Sumpf (`RoomSwamp`), Aschenfrost-Ruinen (`RoomAshfrost`).
  - Bosse: Minibosse in Minute 1 und 3. Ab Minute 5 alle 5 Minuten ein zufälliger Hauptboss (Drache, Zwillingshexen, Sumpfbehemoth) mit 9 Fähigkeiten, freigeschaltet 3/6/9 in Minute 5/10/15.
- **Tech-Stack:**
  - GameMaker 2024, Runtime 2024.14.4.268, Sprache GML.
  - Projektdatei `FirstGame.yyp`.
  - Werkzeuge in Python 3: Igor-Builds über das pipx-Paket `gms-mcp`; numpy/PIL für prozedurale Pixelgrafik.
  - Kein npm- oder pip-Projekt im Repo.
- **Git:** nur lokal, Branch `entwicklung`.

## Ordner
| Pfad | Inhalt |
|---|---|
| `FirstGame.yyp` | Ressourcenliste. Jede neue Ressource muss hier registriert sein. |
| `scripts/<name>/<name>.gml` | Spiellogik, je Skript eine `.gml` und eine `.yy` |
| `objects/<Objekt>/` | Events wie `Create_0`, `Step_0`, `Draw_0` (Welt), `Draw_64` (GUI), `Draw_73` (nach dem Licht) |
| `rooms/` | `RoomMenu` (Start), `Room1`, `RoomSwamp`, `RoomAshfrost`; `RoomCrypt` und `RoomRuins` sind Fallbacks |
| `sprites/`, `sounds/`, `tilesets/`, `options/` | Assets. Drachen-PNGs und ArtPack-Originale nicht verändern. |
| `FirstGame_ArtPack/`, `Audio/`, `Assets/` | Quellmaterial und Kataloge |
| `tests/` | Test-Harnesses (`*_harness.gml`), Runner und Werkzeuge (`tests/tools/`, Levelgrafik in `tests/tools/levels/`) |
| `QA/` | Bot-Simulationen, Daten (`QA/data/`), Berichte (`QA/*.md`), Werkzeuge (`QA/tools/`) |
| `DESIGN/` | Verbindliche Designs: `BOSS_DESIGN.md` (höchste Priorität für Bosse), `TALENTS_AND_EQUIPMENT.md` |
| `docs/` | Obsidian-Vault mit Übergabe (`HANDOFF.md`, `LOG.md`, `DECISIONS.md`), Systemnotizen und Archiv |
| `output/` | Alte Codex-Testausgaben, gitignored. Keine neuen Builds hier ablegen. |
| `DEVELOPMENT_PROGRESS.md`, `TODO.md`, `QA/CURRENT_STATUS.md` | Ausführlicher Stand bis 2026-11-24. Wird nicht mehr laufend gepflegt; der aktuelle Stand steht in `docs/HANDOFF.md`. |
| `LEVEL_EXPANSION_PROGRESS.md`, `QA/QA_SUMMARY.md`, `QA/README.md` | Level-Stand, Bot-Simulationen und Regression aus der Codex-Zeit |
| übrige Root-`*_REPORT.md` | Frühere Stände. Werte können veraltet sein; im Zweifel gilt der Code. |

## Architektur
- **Systemkarte:** `docs/00_Index.md`.
- **Je System eine Notiz** in `docs/Systeme/` (Zweck, Dateien, Funktionen, Abhängigkeiten, Probleme). **Dort zuerst nachsehen, statt den Code zu durchsuchen.**
- **Kern-Ablauf:**
  - `ObjectController` Step ruft `boss_world_step`, die Zauber und `apply_passives` auf.
  - `apply_passives` ruft am Ende `talent_equipment_apply` auf (Talente und Ausrüstung).
  - Bossgefahren laufen über `bv2_*`, eine Uhr je Boss.

## Bauen, Starten, Testen

Abgelesen aus den Skripten. Alle Builds sind isolierte Kopien unter `%LOCALAPPDATA%\FirstGame-Tests\`.

- **Starten (Nutzer):** `FirstGame.yyp` in GameMaker öffnen und F5 drücken. Keine EXE oder ZIP als Lieferung.
- **Kompilieren:** `python tests/tools/levels/compile_check.py` (Igor, Windows VM). Ein erfolgreicher Build ist kein Gameplay-Nachweis.
- **Native Tests** (bauen jeweils eine Kopie mit injiziertem Test-GML):
  - `python QA/tools/run_qa_regression.py`: 811 Prüfungen aus der Codex-Zeit
  - `python tests/tools/run_level_smoke.py`: 3 Level, 166 Prüfungen
  - `python tests/tools/run_native_harness.py feature`: Talente, Ausrüstung und Effekte, 129 Prüfungen
  - `python tests/tools/run_native_harness.py boss`: Bossmuster, Ausweich-Orakel, Kiting und Aufholattacken, 141 Prüfungen
  - `python QA/tools/validate_project.py`: statische Ressourcenprüfung
  - `python QA/tools/audit_visual_preservation.py`: prüft, dass keine PNG verändert wurde
- **Simulationen:**
  - Vollständige Runs: `QA/tools/run_cohort.py --reuse <Artefakt> …`
  - Isolierte Bosskämpfe: `QA/tools/run_boss_mc.py`
  - Auswertung: `QA/tools/analyze_v3.py`
  - Artefakte liegen unter `%LOCALAPPDATA%\FirstGame-Tests\native-mc-*`.
  - Lange Läufe als eigenständigen Prozess starten (PowerShell `Start-Process`).
- **Bekannt veraltet:** `tests/tools/run_combat_smoke.py` scheiterte schon vor 2026-11-24. Die Vorlage ist veraltet.
- **Weitere Werkzeuge:**
  - Produktions-ZIP nur auf ausdrücklichen Wunsch: `python tests/tools/build_production.py`.
  - Grafik- und Weltgenerierung: `tests/tools/levels/`, siehe `LEVEL_EXPANSION_PROGRESS.md`.

## Regeln
- **Keine Zahlenänderungen am Balancing** (HP, Schaden, XP, Klassenwerte, Skalierung) ohne ausdrücklichen Auftrag. Empfehlungen nur dokumentieren.
- **Testergebnisse** immer als PASS / FAIL / BLOCKED / NOT RUN angeben. Nichts erfinden.
- **Git nur lokal** auf `entwicklung`, **niemals pushen**. Am Ende jeder abgeschlossenen Aufgabe lokal committen (siehe unten), sofern die Aufgabe nichts anderes sagt. Vor größeren Änderungen committen statt ein ZIP anzulegen.
- **Arbeitsweise des Nutzers:** Änderungen direkt im Projekt. Test-Builds nie im Projektordner ablegen und danach löschen.
- **Bossarbeit** folgt `DESIGN/BOSS_DESIGN.md`. Gefahren laufen über eine Uhr je Boss (`v2_clock`), sodass Warnung und Treffer synchron bleiben.

## Code-Konventionen (GML)
- **Stil:** dichtes GML, kurze Hilfsfunktionen.
- **Präfixe je System:** `talent_`, `equipment_`, `bc_` (Choreografie), `bv2_` (Bossgefahren), `dragon_`, `level_`, `spell_v2_`, `spell_vfx_`, `boss_test_`.
- **Daten** als statische Struct-Arrays in Funktionen, z. B. `talent_definitions()` oder `level_definitions()`.
- **Kommentare** im Code auf Englisch, UI-Texte auf Deutsch ohne Umlaute (ae/oe/ue).
- **Asset-Namen sind globale Bezeichner.** Ein bloßes `if(master_skeleton)` liefert die Skript-Referenz, nicht die Instanzvariable. Deshalb `self.<name>` verwenden oder solche Namen meiden.
- **Reservierte Namen** wie `other`, `speed`, `score`, `mean` nicht als Variablen nutzen. Folgefehler zeigen sonst irreführende Zeilen („Unknown token eArrayRef“).
- **Neue Skripte, Sprites und Objekte** in `FirstGame.yyp` registrieren, z. B. mit `tests/tools/levels/gm_project.py`. Unbekannte Funktionen kompilieren sonst als Variablen und scheitern erst zur Laufzeit.
- **Die IDE-Diagnose** meldet bei einzeiligen `if(...)return` und Komma-`var`-Listen viele Fehlalarme („unreachable“, „argument-count“).
- **Telemetrie-Anker:** `QA/tools/telemetry_injections.py` braucht exakte Code-Anker. Nach Änderungen an `class_weapons`, `spell`, `boss_hazards_v2` usw. die Anker prüfen.
- **Shell:** Bash-Heredocs mit Python-Code, der `'''` enthält, brechen im Tool-Wrapper ab; solche Skripte als Datei schreiben. Der GMS-MCP-Server kann beim Start in einen Timeout laufen; die Python-Runner rufen Igor direkt auf.

## Synchron bleiben und Token sparen (gilt für Claude **und** Codex)

### Lesen: nur so viel wie nötig, in dieser Reihenfolge
1. **Start:**
   - `docs/HANDOFF.md` (Claude bekommt sie per Hook eingeblendet, Codex liest sie selbst)
   - `git log --oneline -5` und `git status --short`
   - **Nicht** die ganze Doku.
2. **Passende Systemnotiz:** die eine Notiz in `docs/Systeme/`, die zur Aufgabe gehört (Liste in `docs/00_Index.md`).
   - `[[Name]]` ist die Datei `docs/**/Name.md`.
   - Obsidian ist nur die Ansicht für den Nutzer. Agenten lesen die Notizen als normale Dateien.
3. **Erst dann Code, und gezielt:**
   - Nach Funktionsnamen aus der Notiz suchen (`rg -n` oder `grep -n`) und nur die betroffenen Zeilenbereiche lesen.
   - Nie ganze Skripte oder den ganzen Code „zur Orientierung“ durchgehen.
- **Nicht komplett lesen:**
  - `docs/LOG.md`: nur die obersten ~15 Zeilen
  - `docs/DECISIONS.md`: nur gezielt per Suche
  - `docs/ai-activity.log`, `docs/_archive/`, `QA/data/`, `QA/logs/`
  - generierte Dateien (`level_layout_*`, `spell_v2_catalog`)
  - Root-`*_REPORT.md`, `DEVELOPMENT_PROGRESS.md`, `TODO.md`, `QA/CURRENT_STATUS.md`
- **Ausgaben klein halten:**
  - Lange Ausgaben kürzen (`| tail -30`, `| head`).
  - Testläufe nur über die PASS/FAIL-Zahlen auswerten.
  - Gerade geschriebene Dateien nicht erneut lesen.

### Testen: nur passend zur Änderung
| Geändert | Test |
|---|---|
| Talente, Ausrüstung, Effekte | `run_native_harness.py feature` |
| Bosse | `run_native_harness.py boss` und `run_qa_regression.py` |
| Level, Gegner, Spawns | `run_level_smoke.py` |
| Klassen, Zauber, übergreifend, vor einem Meilenstein | alle vier |

### Schreiben: am Ende jeder abgeschlossenen Aufgabe, nicht nach jeder Nachricht
- a) `docs/HANDOFF.md` **überschreiben**, höchstens 40 Zeilen:
  - Stand, zuletzt gearbeitet an, halb fertig, Bugs, nächste Schritte
  - `Zuletzt dran: Claude/Codex, Datum`
- b) **Oben** in `docs/LOG.md` 2–5 Zeilen: `### Datum · Agent · Thema`, dazu die geänderten Dateien.
- c) Nur bei echten Entscheidungen eine Zeile in `docs/DECISIONS.md`.
- d) Eine Systemnotiz nur ändern, wenn sich Dateien, Funktionen, Abhängigkeiten oder bekannte Probleme des Systems geändert haben.
  - Nur die betroffenen Zeilen ändern und `updated:` anpassen.
  - Neues System: neue Notiz nach dem Muster der bestehenden und einen Link in `docs/00_Index.md`.
- e) Neue Bugs und Ideen als eine Zeile in `docs/Bugs & Ideen.md`. Erledigtes dort entfernen.
- f) Lokal committen, die Nachricht beginnt mit `[Claude]` oder `[Codex]`. Nie pushen.

### Grundsätze
- **Jede Information steht an genau einer Stelle:**
  - Regeln: AGENTS.md
  - Stand: HANDOFF
  - Verlauf: LOG und git
  - Begründungen: DECISIONS
  - Systemkarte: `docs/Systeme/`
  - Backlog: Bugs & Ideen
- Verlinken statt kopieren. Keine neuen Status- oder Berichtsdateien anlegen.
- **Nicht gegeneinander arbeiten:** Fremde, nicht committete Änderungen (`git status`) nicht überschreiben. Wer zuletzt dran war, steht in HANDOFF.
- **Pflege:**
  - Wächst `docs/LOG.md` über ~150 Zeilen, ältere Einträge nach `docs/_archive/LOG_<Jahr>.md` verschieben.
  - Jede Notiz unter `docs/` hat Frontmatter (`tags`, `updated`) und verlinkt mit `[[Notiz]]`.
