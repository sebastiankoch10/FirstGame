---
tags: [index, start]
updated: 2026-11-26
---
# FirstGame – Startseite

Pixel-Art-Action-RPG im Run-Format in GameMaker 2024: 30-Minuten-Runs, 3 Klassen, 3 Level, Talente, Ausrüstung, Bosse mit 9 Fähigkeiten.
Die Arbeitsregeln für KI-Agenten stehen in `AGENTS.md` im Projektordner, außerhalb dieses Vaults. Dort steht auch, wie der Vault gepflegt wird (Abschnitt „Synchron bleiben“).

## Design-Kanon (verbindlich, Soll)
**Einstieg und Vorrangregeln:** [[Leitbild]]

| Fachgebiet | Dokument |
|---|---|
| Kampf, räumliche Entscheidungen, Warnungen, Gegner, Lesbarkeit | [[Kampf & Begegnungen]] |
| Hauptbosse | [[Boss-Design]] |
| Klassen | [[Klassen]] |
| Level-ups, Zauber, Talente, Ausrüstung | [[Progression & Builds]] |
| Art Direction, Terranigma-Referenz, Pixelraster, Animation | [[Visuelles Leitbild & Animation]] |
| Fähigkeiten-Inszenierung, VFX, visuelle Progression, Ton | [[Fähigkeiten, VFX & Audio]] |
| Ist-Architektur, Technikvergleich, Zielarchitektur, Budgets | [[Technische Architektur]] |
| Asset-Bestand, Struktur, Namen, Arbeitsablauf | [[Assets & Pipeline]] |
| Statusskala, Abnahme, Review | [[Qualitätsstandard]] |
| Reihenfolge und Vertical Slice | [[Roadmap & Vertical Slice]] |

Momentaufnahme des ganzen Kanons als ein Text: [[Designphilosophie_2026-11-25]] in `_export/` (nicht verbindlich, erzeugt mit `python tests/tools/export_design.py`).

## Übergabe zwischen Claude Code und Codex
- [[HANDOFF]]: aktueller Stand, wird nach jeder Aufgabe überschrieben. **Hier anfangen.**
- [[LOG]]: Änderungslog, neueste Einträge oben.
- [[DECISIONS]]: Architektur- und Designentscheidungen.
- [[Bugs & Ideen]]: gesammelte Auffälligkeiten, nichts davon behoben.
- [[SETUP_REPORT]]: wie diese Struktur und die Hooks eingerichtet wurden.
- `ai-activity.log` wird automatisch vom Stop-Hook geschrieben (Textdatei, keine Notiz).

## Spielsysteme (Ist-Zustand, beschreibend)
**Ablauf und Spieler**
- [[Spielablauf & Zustände]]
- [[Spieler & Bewegung]]
- [[Klassen & Startwaffen]]

**Fortschritt im Run**
- [[Zauber & Passiva]]
- [[Progression & Level-up]]
- [[Talente]]
- [[Ausrüstung]]
- [[Charaktergrafik & Ausrüstungs-Layer]]

**Welt und Gegner**
- [[Level & Welten]]
- [[Gegner & Spawns]]
- [[Bosse]]
- [[Boss-Testmodus]]

**Darstellung, Ton, Daten**
- [[Rendering & Pixelraster]]
- [[Licht, Wetter & Effekte]]
- [[Telegraphs & Gefahrenflächen]]
- [[UI, HUD & Menüs]]
- [[Audio]]
- [[Speichern & Einstellungen]]

**Qualität und Entwicklung**
- [[Tests & QA]]
- [[Review-Center]] (To-do-Liste im Hauptmenü, persönliche Freigaben)

## Historische Dokumente außerhalb des Vaults (nicht verbindlich)
- `DEVELOPMENT_PROGRESS.md`, `TODO.md`, `QA/CURRENT_STATUS.md`, `QA/V3_SIMULATION_REPORT.md`
- `LEVEL_EXPANSION_PROGRESS.md`, `QA/QA_SUMMARY.md`, ältere Root-`*_REPORT.md`

## Archiv und Export im Vault (nicht verbindlich)
- [[CLAUDE_2026-11-24]]: frühere `CLAUDE.md` (Ordner `_archive/`)
- [[Designphilosophie_2026-11-25]]: Export des Design-Kanons (Ordner `_export/`)
