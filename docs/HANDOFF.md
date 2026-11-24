---
tags: [handoff, status]
updated: 2026-11-24
agent: Claude
---
# Übergabe (wird nach jeder Aufgabe überschrieben, max. ~40 Zeilen)

**Zuletzt dran:** Claude, 2026-11-24. Aufgabe: Doku- und Übergabestruktur, Hooks, Obsidian-Vault, Token-Regeln für beide Agenten. Kein Spielcode geändert, kein Commit.

## Stand
- Spielbar per F5: 3 Klassen, 3 Level, Talente (T), Ausrüstung, Zauber-Partikel, Bosse mit FFXIV-artigen Mustern ([[Bosse]]).
- Git: Branch `entwicklung`, letzter Commit `40e446bb`. Die neue Doku-Struktur ist noch **nicht committet**.
- Tests auf dem letzten Code-Stand: Regression 811/811, Boss 141/141, Feature 129/129, Level 166/166 (alles PASS).
- Simulationen: 1.080 vollständige Bot-Runs und 270 isolierte Bosskämpfe, siehe `QA/V3_SIMULATION_REPORT.md`.

## Zuletzt gearbeitet an
- `AGENTS.md` ist die einzige Hauptquelle, `CLAUDE.md` importiert sie nur.
- `docs/` als Obsidian-Vault mit Systemnotizen, `LOG`, `DECISIONS` und `Bugs & Ideen`.
- Claude-Hooks: SessionStart zeigt diese Datei an, der Stop-Hook schreibt `docs/ai-activity.log`.
- `AGENTS.md`, Abschnitt „Synchron bleiben und Token sparen“: Lesereihenfolge, Tests nach Änderung, Commit mit `[Claude]`/`[Codex]` pro Aufgabe.
- Der Nutzer hat einen Einstiegs-Prompt für Codex bekommen. Codex soll danach einmal aufholen und in höchstens 8 Zeilen bestätigen.

## Halb fertig / offen
- Die Doku-Struktur ist noch nicht committet; der Nutzer prüft sie zuerst ([[SETUP_REPORT]]).
- Designentscheidungen zu Talenten und Ausrüstung sind offen: pro Run oder dauerhaft, Punktetempo, Respec, Zahlenwerte.
- Für die neuen Bossmuster fehlt der menschliche Spieltest.

## Bekannte Bugs / Risiken
- Der Drache ist ab Minute 10 für Bots sehr schwer: 17 % bzw. 8 % Siege, früher 54 % bzw. 37 %.
- `tests/tools/run_combat_smoke.py` ist veraltet (FAIL vor 2026-11-24).
- Der Level-Test liefert unter paralleler CPU-Last einmal 165/166 (Timing-Ausreißer).
- Mehr in [[Bugs & Ideen]].

## Nächste Schritte
1. Nutzer: Setup prüfen, dann committen. Prüfen, ob `docs/ai-activity.log` in die `.gitignore` gehört.
2. Spieltest der Bosse ab Minute 10 (Boss testen, F3/F6).
3. Entscheidungen aus [[Talente]] und [[Ausrüstung]] treffen.
4. Simulationen mit dem aktuellen Stand fortsetzen (Ziel 3.000 Runs).
