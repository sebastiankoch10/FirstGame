---
tags: [log]
updated: 2026-11-24
---
# Änderungslog (neueste Einträge oben, je 2–5 Zeilen)

### 2026-11-24 · Claude · QA-Agent modernisiert (Meilenstein 1)
- Neu `tests/tools/qa.py`: Stufen 0–4 aus dem Diff, Suiten-Auswahl je System, PASS-Cache über Eingabe-Hash, Einzeilen-Ausgabe.
- `.codex/agents/qa.toml` aktualisiert, `.claude/agents/qa.md` neu. Suite `classes` repariert (baut außerhalb, Drachen-Altteil optional, Warnflächen-Check aktuell): PASS 150.
- 6 Alias-Runner entfernt; `MCP_TIMEOUT=60000` in `.claude/settings.json`. Details: [[Tests & QA]].

### 2026-11-24 · Claude · Token-Regeln für Claude und Codex
- `AGENTS.md`: neuer Abschnitt „Synchron bleiben und Token sparen“ (Lesereihenfolge, Lese-Sperrliste, Tests je Änderung, Schreibpflichten a–f, Commit pro Aufgabe).
- Architekturteil auf einen Verweis auf `docs/Systeme/` gekürzt; der Levelindex steht jetzt in [[Level & Welten]]. Einstiegs-Prompt für Codex an den Nutzer übergeben.

### 2026-11-24 · Claude · Doku- und Übergabestruktur
- `AGENTS.md` angelegt als einzige Hauptquelle. `CLAUDE.md` ist jetzt nur noch Import plus 3 Claude-Zeilen; das Original liegt in `docs/_archive/`.
- `docs/` als Obsidian-Vault angelegt: Index, HANDOFF, LOG, DECISIONS, 16 Systemnotizen, Bugs & Ideen, [[SETUP_REPORT]].
- Hooks: `.claude/settings.json` (SessionStart, Stop) und `.claude/hooks/log-activity.sh`, direkt getestet (Testzeile `Stop TEST` in `docs/ai-activity.log`). Kein Spielcode geändert, kein Commit.

### 2026-11-24 · Claude · Tests und Simulationen (Commits `f46d9fde`…`40e446bb`)
- 1.080 vollständige Bot-Runs und 270 isolierte Bosskämpfe, Auswertung in `QA/V3_SIMULATION_REPORT.md`.
- Abschlusstests: Regression 811, Boss 141, Feature 129 und Level 166, alle PASS.

### 2026-11-24 · Claude · Boss-Fairness (Commits `b3a1a7d1`…`b5b216d8`)
- Schwenks treffen nur einmal, Mehrwellen-Muster haben mehr Reaktionszeit, das Drachen-Schachbrett ist überspringbar.
- Komplexe Varianten der Fähigkeiten 1–3 erst ab Minute 10. Dateien: `scripts/boss_choreo`, `dragon_encounter`, `boss_encounters_v2`.

### 2026-11-24 · Claude · Bosskampf-Philosophie (Commit `0af8993e` und folgende)
- Neu `scripts/boss_choreo`: Schachbrett, Streifen, Quadranten, innen/außen, Schwenkstrahlen (2.600 px), Aufholattacken.
- Warnungen mit Rand-Countdown. Boss-Testmodus F6–F9. Test `tests/boss_harness.gml`.

### 2026-11-24 · Claude · Talente, Ausrüstung, Zauber-Effekte (Commit `086862c0` und folgende)
- Neu: `scripts/talents`, `scripts/equipment`, `scripts/spell_vfx`, Sprite `spr_eq_icons`. Charakterbildschirm mit Taste T.
- Test `tests/feature_harness.gml`. Doku `DESIGN/TALENTS_AND_EQUIPMENT.md`.

### 2026-11-23/24 · Claude · Level-Erweiterung (in Commit `055cf95c`)
- Neu: Verfluchter Sumpf, Aschenfrost-Ruinen, Levelauswahl. Dateien: `scripts/level_worlds`, `scripts/level_world`, `rooms/RoomSwamp`, `rooms/RoomAshfrost`.
- Doku `LEVEL_EXPANSION_PROGRESS.md`.

### 2026-11-12…23 · Codex · Gesamter Ausbau vor Claude (in Commit `055cf95c` gesammelt)
- ArtPack-Grafik, Klassen v3, Zauber v2, Bosse v2, Drache, Atmosphäre, QA mit 811 Regressionsprüfungen und 192 Bot-Runs.
- Berichte: Root-`*_REPORT.md`, `QA/QA_SUMMARY.md`.
