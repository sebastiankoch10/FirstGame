---
tags: [handoff, status]
updated: 2026-11-25
agent: Claude
---
# Übergabe (wird nach jeder Aufgabe überschrieben, max. ~40 Zeilen)

**Zuletzt dran:** Claude, 2026-11-25. Aufgabe: globale Designphilosophie, Audit, Terranigma-Referenz, Asset-Struktur, Qualitätsstandard, Roadmap.

## Stand
- **Neuer verbindlicher Design-Kanon** `docs/Design/` (11 Dokumente). Einstieg und Vorrangregeln: [[Leitbild]]. Alte `DESIGN/*.md` liegen jetzt dort (`Boss-Design.md`, `Progression & Builds.md`).
- **Spiel unverändert spielbar (F5).** Geändert wurden nur der IDE-Ordnerbaum (`parent` in 1.381 `.yy`, Ordner in der `.yyp`) und Kommentar-Pfade. Keine Logik, keine Werte.
- **Tests am 25.11. nach der IDE-Neuordnung:**
  - static PASS, regression 811 PASS.
  - feature, boss, level, classes, visual: NOT RUN (nur Kommentare und IDE-Ordner geändert, keine Logik). Letzter Vollstand 24.11.: alle PASS.

## Zuletzt gearbeitet an
- **Audit früherer Aufträge** (15 Codex-Anhänge, Claude-Prompts) gegen Doku und Code. Widersprüche aufgelöst: [[Leitbild]] Abschnitt 6.
- **Gemessen:**
  - Bild horizontal um 33 % verzerrt (Kamera 800×600 auf 1280×720);
  - Pixeldichte je Asset 0,25–1,65;
  - VFX als gestreckte Sprites und Vektorformen;
  - Drache als Einzelsprite mit 2–4 Frames.
- **Terranigma:** nur Storyboard-Vorschaubilder (1 Bild/s) ausgewertet, kein Video-Download. Grenzen dokumentiert.
- **Werkzeuge:**
  - `tests/tools/assets/ide_folders.py` (`--check`/`--apply`); `gm_project.py` sortiert neue Ressourcen automatisch ein;
  - `tests/tools/export_design.py` erzeugt `docs/_export/`.

## Offen: Entscheidungen des Nutzers (siehe [[Roadmap & Vertical Slice]])
1. R1: Kamera-Option (Vorschlag 960×540), danach A/B-Prototyp zur Pixeldichte.
2. Eigenes Rig in GML (Vorschlag) oder Spine (kostenpflichtig) für Bosse.
3. Klassennamen (Schwertmeister/Arkanistin?), Waffen-Upgrade-System, Elitegegner, Run-Format gegenüber Action-RPG.
4. Löschen der 164 Legacy-Sprites und von `output/` (820 MB)? Internetsperre in `.claude/settings.json`?

## Bekannte Bugs / Risiken
- `MCP_TIMEOUT` in `.claude/settings.json` wirkt nicht; `gms`-MCP bricht nach 30 s ab. Die Test-Runner brauchen ihn nicht.
- Minibosse nutzen noch 0.1-Gegnerstreifen (Stilbruch). Telemetrie-Anker bei einer Timeline-Migration mitziehen.

## Nächste Schritte
1. Nutzer: [[Leitbild]] und Export lesen, offene Entscheidungen 1–4 treffen.
2. Danach Roadmap-Auftrag 1 (R1 Verzerrung), dann 2 (A/B-Pixeldichte), dann 3 (Attack Timeline).
