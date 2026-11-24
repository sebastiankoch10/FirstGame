---
tags: [index, start]
updated: 2026-11-24
---
# FirstGame – Startseite

Top-down-Survivor in GameMaker 2024: 30-Minuten-Runs, 3 Klassen, 3 Level, Talente, Ausrüstung, Bosse mit 9 Fähigkeiten.
Die Regeln für KI-Agenten stehen in `AGENTS.md` im Projektordner, außerhalb dieses Vaults.

## Übergabe zwischen Claude Code und Codex
- [[HANDOFF]]: aktueller Stand, wird nach jeder Aufgabe überschrieben. **Hier anfangen.**
- [[LOG]]: Änderungslog, neueste Einträge oben.
- [[DECISIONS]]: Architektur- und Designentscheidungen.
- [[Bugs & Ideen]]: gesammelte Auffälligkeiten, nichts davon behoben.
- [[SETUP_REPORT]]: wie diese Struktur und die Hooks eingerichtet wurden.
- `ai-activity.log` wird automatisch vom Stop-Hook geschrieben (Textdatei, keine Notiz).

## Spielsysteme
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
- [[Licht, Wetter & Effekte]]
- [[UI, HUD & Menüs]]
- [[Audio]]
- [[Speichern & Einstellungen]]

**Qualität**
- [[Tests & QA]]

## Weitere Dokumente außerhalb des Vaults (im Projektordner)
- `DESIGN/BOSS_DESIGN.md` (verbindlich für Bosse) und `DESIGN/TALENTS_AND_EQUIPMENT.md`
- `DEVELOPMENT_PROGRESS.md`, `TODO.md`, `QA/CURRENT_STATUS.md`, `QA/V3_SIMULATION_REPORT.md`
- `LEVEL_EXPANSION_PROGRESS.md`, `QA/QA_SUMMARY.md`, ältere Root-`*_REPORT.md`
- Archiv: `_archive/CLAUDE_2026-11-24.md` (frühere `CLAUDE.md`)
