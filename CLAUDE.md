@AGENTS.md

Design-Kanon (verbindlich, mit Vorrangregeln): `docs/Design/`, Einstieg `docs/Design/Leitbild.md`. Details in AGENTS.md, Abschnitt „Design-Kanon“.

## Nur für Claude Code
- Der SessionStart-Hook (`.claude/settings.json`) blendet `docs/HANDOFF.md` automatisch ein. Sie muss nicht noch einmal gelesen werden.
- Der Stop-Hook `.claude/hooks/log-activity.sh` schreibt ohne KI-Aufruf eine Zeile nach `docs/ai-activity.log`. Das ersetzt **nicht** das Übergabe-Protokoll in AGENTS.md.
- Bisherige Fassung dieser Datei: `docs/_archive/CLAUDE_2026-11-24.md`. Ihr Inhalt steht vollständig in AGENTS.md.
