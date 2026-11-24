---
tags: [setup, report, hooks, obsidian]
updated: 2026-11-24
agent: Claude
---
# Setup-Bericht: Doku, Übergabe und Obsidian (2026-11-24)

**Ergebnis:** Doku und Übergabe sind eingerichtet:
- `AGENTS.md` ist die gemeinsame Quelle für Claude Code und Codex.
- Zwei Claude-Hooks: SessionStart und Stop.
- `docs/` ist als Obsidian-Vault vorbereitet.

**Kein Spielcode, keine Assets, keine Build- oder Projektdateien geändert.** Nichts gelöscht, nichts committet, nichts installiert, kein Build, kein Spielstart. Start: [[00_Index]].

## 1. Angelegte und geänderte Dateien
| Datei | Neu / geändert | Grund |
|---|---|---|
| `AGENTS.md` | neu | Einzige Hauptquelle für beide Agenten. Inhalt: Projekt, Tech-Stack, Ordner, Architektur, Bauen/Starten/Testen (aus Skripten abgelesen, nicht ausgeführt), Regeln, Code-Konventionen, Übergabe-Protokoll. |
| `CLAUDE.md` | geändert | Nur noch `@AGENTS.md` plus 3 Claude-Zeilen (Hooks, Archiv). Der bisherige Inhalt steht vollständig in `AGENTS.md`. |
| `docs/_archive/CLAUDE_2026-11-24.md` | neu | Unveränderte Kopie der alten `CLAUDE.md`, byte-gleich geprüft mit `cmp`. |
| `docs/00_Index.md` | neu | Startseite des Vaults mit Wiki-Links auf alle Notizen. |
| `docs/HANDOFF.md` | neu | Aktueller Stand. Wird nach jeder Aufgabe überschrieben, höchstens etwa 40 Zeilen. |
| `docs/LOG.md` | neu | Änderungslog, neueste Einträge oben. Die Einträge vor heute sind aus den Git-Commits rekonstruiert. |
| `docs/DECISIONS.md` | neu | Arbeits- und Designentscheidungen, gesammelt aus der bisherigen Doku. |
| `docs/Bugs & Ideen.md` | neu | Auffälligkeiten beim Lesen. Nur Notizen, nichts behoben. |
| `docs/Systeme/*.md` (16 Notizen) | neu | Eine Notiz je Spielsystem: Zweck, Dateien, Abhängigkeiten, Probleme. Alle untereinander verlinkt. |
| `docs/SETUP_REPORT.md` | neu | Dieser Bericht. |
| `docs/ai-activity.log` | neu | Logdatei des Stop-Hooks. Enthält die markierte Testzeile `Stop TEST`. |
| `.claude/settings.json` | neu | Hooks SessionStart und Stop. Vorher gab es keinen Ordner `.claude/` im Projekt, also auch keine Einträge, die zu erhalten waren. |
| `.claude/hooks/log-activity.sh` | neu | Das Skript des Stop-Hooks. |

**Systemnotizen** (`docs/Systeme/`):
- Spielablauf & Zustände
- Spieler & Bewegung
- Klassen & Startwaffen
- Zauber & Passiva
- Progression & Level-up
- Talente
- Ausrüstung
- Gegner & Spawns
- Bosse
- Boss-Testmodus
- Level & Welten
- Licht, Wetter & Effekte
- UI, HUD & Menüs
- Audio
- Speichern & Einstellungen
- Tests & QA

## 2. Was archiviert wurde
- `CLAUDE.md` → `docs/_archive/CLAUDE_2026-11-24.md`. Das ist die einzige bestehende Agenten-Datei; eine `AGENTS.md` gab es vorher nicht.
- Beim Übernehmen bemerkt: Die alte Datei hatte einen kaputten Pfad (`FirstGame-Tests` + Zeilenumbruch + `ative-mc-*`). In `AGENTS.md` steht er korrigiert als `native-mc-*`.
- `README.md` und die übrigen MD-Dateien (`DESIGN/`, `QA/`, Root-Berichte) wurden **nicht** angefasst. Sie liegen nicht im erlaubten Bereich und werden aus `AGENTS.md` und `00_Index` nur verlinkt.

## 3. So funktionieren die Hooks
Beide Hooks laufen nur in Claude Code (Codex kennt sie nicht), ohne KI-Aufruf, ohne Netzwerk und ohne Tokenkosten.
- **SessionStart:** `cat "$CLAUDE_PROJECT_DIR/docs/HANDOFF.md"`.
  - Der Text landet automatisch im Kontext von Claude. Läuft bei Start, Fortsetzen, `/clear` und nach einer Komprimierung.
  - Fehlt die Datei, passiert nichts (`|| true`).
- **Stop:** `bash .claude/hooks/log-activity.sh`, nach jeder fertigen Antwort von Claude.
  - Hängt eine Zeile an `docs/ai-activity.log` an: `Zeit | Stop | git: N Aenderung(en) | <git status --short, höchstens 15 Einträge>`.
  - Die Logdatei selbst wird herausgefiltert.
  - Ohne git oder außerhalb eines Repos steht `git: nicht verfuegbar`. Ohne `docs/` wird nichts geschrieben.
  - `git status` hat 5 s Zeitlimit, der Hook 15 s. Das Skript liest kein stdin und endet **immer mit Exit 0**.

**Direkte Tests** (Ergebnisse vom 2026-11-24):
| Test | Ergebnis |
|---|---|
| `settings.json` mit Python als JSON geprüft | PASS |
| Stop-Skript im Projekt mit `TEST`, JSON auf stdin, Windows-Pfad in `CLAUDE_PROJECT_DIR` | PASS: Exit 0, 0,8 s, Zeile `Stop TEST` mit 7 Änderungen |
| Stop-Skript in einem Ordner ohne git-Repo (Scratchpad) | PASS: Exit 0, `git: nicht verfuegbar` |
| Stop-Skript, Ordner ohne `docs/` | PASS: Exit 0, keine Datei angelegt |
| Stop-Skript, git nicht im PATH | PASS: Exit 0, `git: nicht verfuegbar` |
| SessionStart-Befehl mit Windows-Pfad, ohne Variable und mit falschem Pfad | PASS: zeigt `HANDOFF.md` (36 Zeilen), Exit 0 |
| Hooks innerhalb einer laufenden Claude-Sitzung ausgelöst | NOT RUN |

Zum Test „git nicht im PATH“: Die kopierten Hilfsprogramme liefen ohne ihre DLLs nicht. Deshalb steht dort statt der Zeit ein `?`. Das zeigt zugleich, dass der Fallback greift.

Zur letzten Zeile: `.claude/` entstand erst während der Sitzung. Claude Code lädt die Hooks vermutlich erst nach einem Neustart oder nach einmal `/hooks` öffnen.

**Abschalten:**
- Alle Hooks: in `.claude/settings.json` `"disableAllHooks": true` ergänzen.
- Einzelner Hook: in `.claude/settings.json` den Eintrag `SessionStart` oder `Stop` entfernen.
- Interaktiv: in Claude Code `/hooks` öffnen und dort ansehen, ändern oder löschen.

## 4. .gitignore-Prüfung (nur Hinweis, nichts geändert)
- `git check-ignore` ergibt: `docs/`, `.claude/settings.json` und `.claude/hooks/` sind **nicht** ignoriert und würden mitcommittet. So ist es gewollt.
- `docs/ai-activity.log` ist ebenfalls nicht ignoriert. Vorschlag: in die `.gitignore` aufnehmen. Die Datei ändert sich mit jeder Antwort.
- Obsidian legt beim Öffnen `docs/.obsidian/` an. Vorschlag: mindestens `docs/.obsidian/workspace*.json` ignorieren.

## 5. Offene Punkte und Entscheidungen zum Prüfen
- **Nicht committet:** Nach dem Durchsehen z. B. `git add AGENTS.md CLAUDE.md docs .claude` und dann committen.
- **Hooks aktivieren:** Claude Code neu starten oder `/hooks` öffnen. Danach sollte `ai-activity.log` nach jeder Antwort wachsen.
- **Zeilenenden:** Im Repo gilt `core.autocrlf=true`, und `.gitattributes` hat keine Regel für `*.sh`.
  - Nach einem späteren Checkout könnte `log-activity.sh` CRLF bekommen. Bash bricht dann ab, der Hook läuft still ins Leere, blockiert aber nichts.
  - Vorschlag: in `.gitattributes` die Zeile `*.sh text eol=lf` ergänzen. Diese Datei lag nicht im erlaubten Bereich.
  - Derzeit hat das Skript LF; geprüft.
- **Codex:** Bitte prüfen, ob Codex `AGENTS.md` tatsächlich lädt.
  - `.codex/agents/qa.toml` hat eigene englische Anweisungen und verweist nicht auf das Übergabe-Protokoll.
  - Diese Datei lag nicht im erlaubten Bereich und blieb unverändert.
- **README veraltet:** Toter ZIP-Link und veralteter Combat-Smoke-Test. Durfte nicht geändert werden (siehe [[Bugs & Ideen]]).
- **Vault-Umfang:**
  - Die älteren Dokumente (`DESIGN/`, `QA/`, Root-Berichte) liegen außerhalb von `docs/`. Obsidian sieht sie nicht, sie sind nur als Pfad genannt.
  - Entscheidung: später in den Vault verschieben oder so lassen?
- **Dateinamen mit Umlauten und `&`:** z. B. `Ausrüstung.md`, `Spielablauf & Zustände.md`.
  - Obsidian und git kommen damit zurecht.
  - Falls ein Werkzeug Probleme macht, umbenennen; die Wiki-Links passt Obsidian dann mit an.
- **Zum Prüfen:**
  - Der Stop-Hook loggt **jede** Antwort, nicht nur das Aufgabenende. Die untracked Ordner `QA/logs/regression-*` erscheinen bis zum Commit oder Ignorieren in jeder Zeile.
  - SessionStart blendet HANDOFF auch nach Komprimierung und Fortsetzen ein, also etwa 36 Zeilen mehrfach pro Sitzung. Bei Bedarf einen Matcher `startup` setzen.
- **LOG-Einträge vor heute:** aus Commit-Nachrichten rekonstruiert, nicht vollständig.
- **Systemnotizen:** Die Einteilung in 16 Notizen ist ein Vorschlag aus dem Code-Lesen und kann zusammengelegt werden.

## 6. Obsidian öffnen (3 Schritte)
1. Obsidian öffnen.
2. **„Ordner als Vault öffnen“** wählen.
3. Den Ordner `C:\Users\sebas\Dokumente\FirstGame\docs` auswählen. Danach mit [[00_Index]] beginnen.
