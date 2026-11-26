@AGENTS.md

Design-Kanon (verbindlich, mit Vorrangregeln): `docs/Design/`, Einstieg `docs/Design/Leitbild.md`. Details in AGENTS.md, Abschnitt „Design-Kanon“.

## Nur für Claude Code
- Der SessionStart-Hook (`.claude/settings.json`) blendet `docs/HANDOFF.md` automatisch ein. Sie muss nicht noch einmal gelesen werden.
- Ein zweiter SessionStart-Hook führt `tests/tools/review/review.py sync --brief` aus und meldet neue persönliche Review-Freigaben. Sie sind verbindlich (AGENTS.md „Review-Workflow“). Freigaben setzt nie der Agent.
- Der Stop-Hook `.claude/hooks/log-activity.sh` schreibt ohne KI-Aufruf eine Zeile nach `docs/ai-activity.log`. Die Datei ist lokal und seit 26.11. nicht mehr versioniert (kein Git-Diff). Das ersetzt **nicht** das Übergabe-Protokoll in AGENTS.md.
- Neue Anforderungen immer in die maßgebliche vorhandene Doku einarbeiten (ergänzen, präzisieren oder ersetzen), nie daneben ablegen: AGENTS.md, „Grundsätze“.
- Bisherige Fassung dieser Datei: `docs/_archive/CLAUDE_2026-11-24.md`. Ihr Inhalt steht vollständig in AGENTS.md.
