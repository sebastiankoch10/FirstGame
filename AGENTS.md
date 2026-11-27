# FirstGame – Anleitung für KI-Agenten (Claude Code und Codex)

**Einzige Hauptquelle** für beide Agenten. `CLAUDE.md` importiert nur diese Datei. Projektsprache, Doku und Berichte sind **Deutsch**. Laufender Stand: `docs/HANDOFF.md`.

## Projekt
- **Spiel:** Pixel-Art-Action-RPG im Run-Format: Top-down, Runs von 30 Minuten, Horden, Builds, anspruchsvolle Bosskämpfe. Leitbild und alle Designregeln: `docs/Design/` (siehe „Design-Kanon“).
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
- **Git:** Branch `entwicklung`, Remote `origin` (GitHub); Pushen von `entwicklung` erlaubt (seit 25.11.).

## Ordner
| Pfad | Inhalt |
|---|---|
| `FirstGame.yyp` | Ressourcenliste. Jede neue Ressource muss hier registriert sein. |
| `scripts/<name>/<name>.gml` | Spiellogik, je Skript eine `.gml` und eine `.yy` |
| `objects/<Objekt>/` | Events wie `Create_0`, `Step_0`, `Draw_0` (Welt), `Draw_64` (GUI), `Draw_73` (nach dem Licht) |
| `rooms/` | `RoomMenu` (Start), `Room1`, `RoomSwamp`, `RoomAshfrost`; `RoomCrypt` und `RoomRuins` sind Fallbacks |
| `sprites/`, `sounds/`, `tilesets/`, `options/` | GameMaker-Assets. Drachen-PNGs und ArtPack-Originale nicht verändern. IDE-Ordnerbaum nach Kategorien (`tests/tools/assets/ide_folders.py`). |
| `FirstGame_ArtPack/`, `Audio/`, `Assets/` | Quell-, Referenz- und generierte Grafik bzw. Tonquellen. Einordnung je Unterordner und Zielstruktur: `docs/Design/Assets & Pipeline.md` |
| `tests/` | Test-Harnesses (`*_harness.gml`), Runner und Werkzeuge (`tests/tools/`, Levelgrafik in `tests/tools/levels/`, Figuren in `tests/tools/characters/`, Asset-Ordnung in `tests/tools/assets/`) |
| `QA/` | Bot-Simulationen, Daten (`QA/data/`), Berichte (`QA/*.md`), Werkzeuge (`QA/tools/`) |
| `docs/Design/` | **Design-Kanon (verbindlich):** Leitbild, Kampf, Boss-Design, Klassen, Progression, Visuelles Leitbild, Fähigkeiten/VFX/Audio, Technische Architektur, Assets, Qualitätsstandard, Roadmap |
| `docs/` | Obsidian-Vault mit Übergabe (`HANDOFF.md`, `LOG.md`, `DECISIONS.md`), Systemnotizen (`docs/Systeme/`), Archiv, Export (`docs/_export/`, nur Momentaufnahme) |
| `output/` | Alte Codex-Builds (ca. 820 MB), gitignored. Keine neuen Builds hier ablegen; kann vom Nutzer gelöscht werden. |
| `DEVELOPMENT_PROGRESS.md`, `TODO.md`, `QA/CURRENT_STATUS.md` | Ausführlicher Stand bis 2026-11-24. Wird nicht mehr laufend gepflegt; der aktuelle Stand steht in `docs/HANDOFF.md`. |
| `LEVEL_EXPANSION_PROGRESS.md`, `QA/QA_SUMMARY.md`, `QA/README.md` | Level-Stand, Bot-Simulationen und Regression aus der Codex-Zeit |
| übrige Root-`*_REPORT.md` | Frühere Stände. Werte können veraltet sein; im Zweifel gilt der Code. |

## Design-Kanon (verbindlich)
- **Ort:** `docs/Design/`. Einstieg ist `Leitbild.md`: Identität, Säulen, globale Grundsätze G1–G14 und die **Vorrangregeln**.
- **Vorrang bei Widersprüchen:**
  1. `Leitbild.md`
  2. übrige `docs/Design/*` im eigenen Fachgebiet
  3. `docs/DECISIONS.md` (neuere Entscheidung gilt sofort)
  4. `docs/Systeme/*` (nur Ist-Beschreibung)
  5. HANDOFF und LOG (Stand)
  6. `Bugs & Ideen` (unverbindlich)
  7. Root-`*_REPORT.md`, `DEVELOPMENT_PROGRESS.md`, `TODO.md`, `QA/*.md`, `FirstGame_ArtPack/**/*.md`, `docs/_archive/`, `docs/_export/` (historisch, Momentaufnahme)
- **Geltungsbereich:**
  - **Global** gilt, was im Leitbild steht.
  - **Systemspezifisch** gelten Kampf, Boss-Design, Progression, Fähigkeiten/VFX/Audio, Technische Architektur und Assets.
  - **Klassenspezifisch** gilt nur Abschnitt 3 in `Klassen.md`.
  - Anforderungen, die für eine Klasse formuliert sind, aber alle betreffen, gehören ins Leitbild bzw. in `Klassen.md` Abschnitt 2.
- **Neue Designentscheidungen** aus Nutzeraufträgen werden im selben Auftrag mit Datum in das passende Designdokument übernommen, dazu eine Zeile in `DECISIONS.md`. Nichts Wesentliches bleibt nur im Chat.
- **Soll gegen Ist:** Designdokumente sind das Soll, der Code ist das Ist. Abweichungen kommen in die Roadmap oder in `Bugs & Ideen`, statt das Soll stillschweigend anzupassen.
- **Fertig** ist ein Inhalt erst nach `docs/Design/Qualitätsstandard.md` (Statusskala). „Künstlerisch abgenommen“ und „vollständig“ setzt nur der Nutzer.

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
- **Native Tests:** Jede Suite baut eine eigene Kopie mit injiziertem Test-GML. Normalerweise über `tests/tools/qa.py` starten, siehe unten.
  - `python QA/tools/run_qa_regression.py`: 811 Prüfungen aus der Codex-Zeit
  - `python tests/tools/run_level_smoke.py`: 3 Level, 166 Prüfungen
  - `python tests/tools/run_native_harness.py feature`: Talente, Ausrüstung und Effekte, 129 Prüfungen
  - `python tests/tools/run_native_harness.py boss`: Bossmuster, Ausweich-Orakel, Kiting und Aufholattacken, 141 Prüfungen
  - `python tests/tools/run_class_dragon_smoke.py`: Startwaffen und Kombos, 150 Prüfungen
  - `python QA/tools/validate_project.py`: statische Ressourcenprüfung, 1–3 min
  - `python QA/tools/audit_visual_preservation.py`: prüft, dass keine PNG gegenüber der QA-Baseline verändert wurde
- **Simulationen:**
  - Vollständige Runs: `QA/tools/run_cohort.py --reuse <Artefakt> …`
  - Isolierte Bosskämpfe: `QA/tools/run_boss_mc.py`
  - Auswertung: `QA/tools/analyze_v3.py`
  - Artefakte liegen unter `%LOCALAPPDATA%\FirstGame-Tests\native-mc-*`.
  - Lange Läufe als eigenständigen Prozess starten (PowerShell `Start-Process`).
- **Archiviert (26.11.):** veraltete Harnesses und Runner liegen in `tests/_legacy/` (Gründe im dortigen README); keine QA-Stufe nutzt sie.
- **Weitere Werkzeuge:**
  - Szenen-Aufnahme: `python tests/tools/record_scene.py walk|combat|spell|boss|horde` (feste 60-Hz-Bildzeit, WebP und Übersichtsbild unter `%LOCALAPPDATA%\FirstGame-Tests\scene\`). Für Bewegung, Timing und Effekte statt Einzelbildern.
  - Produktions-ZIP nur auf ausdrücklichen Wunsch: `python tests/tools/build_production.py`.
  - Grafik- und Weltgenerierung: `tests/tools/levels/`, siehe `LEVEL_EXPANSION_PROGRESS.md`.
  - Pfade zu Quellgrafik unter `FirstGame_ArtPack/` liest jedes Werkzeug nur aus `tests/tools/assets/art_paths.py`. Prüfung: `python tests/tools/assets/art_paths.py --check` (0 Verweise außerhalb der Tabelle).

## Regeln
- **Keine Zahlenänderungen am Balancing** (HP, Schaden, XP, Klassenwerte, Skalierung) ohne ausdrücklichen Auftrag. Empfehlungen nur dokumentieren.
- **Testergebnisse** immer als PASS / FAIL / BLOCKED / NOT RUN angeben. Nichts erfinden.
- **Git** auf `entwicklung`: am Ende jeder abgeschlossenen Aufgabe committen (siehe unten), sofern die Aufgabe nichts anderes sagt; vor größeren Änderungen committen statt ein ZIP anzulegen.
  - Pushen von `entwicklung` nach `origin` ist erlaubt (Nutzerfreigabe 25.11.). Kein Force-Push, `main` nicht verändern.
- **Qualitätsanspruch des Nutzers (25.11.):** Alles auf den höchsten fachlichen Standard bringen, auch frühe Festlegungen aus der Zeit vor der KI-Nutzung (z. B. Pixelgrößen). Wo ein Nutzervorschlag erkennbar ohne Fachwissen entstanden ist, kurz sagen, wie es besser ginge.
  - Der Nutzer hat für Umsetzungsentscheidungen generell zugestimmt. Weiterhin vorher fragen: kostenpflichtige Dienste, Balancing-Zahlen, künstlerische Abnahme.
  - Spiel starten, Testläufe und Simulationen sind ohne Rückfrage erlaubt.
- **Speicherplatz:** Testartefakte nicht anhäufen. `tests/tools/clean_test_artifacts.py` läuft nach `qa.py` und `record_scene.py` automatisch; Aufnahmen, die nicht mehr gebraucht werden, löschen.
- **Arbeitsweise des Nutzers:** Änderungen direkt im Projekt. Test-Builds nie im Projektordner ablegen und danach löschen.
- **Offenes melden statt abarbeiten (seit 27.11.):**
  - Am Ende jedes Auftrags im Bericht kurz auflisten, was offen geblieben ist, und es in die Roadmap (`docs/Design/Roadmap & Vertical Slice.md`) bzw. `docs/Bugs & Ideen.md` eintragen.
  - Offenes nicht ungefragt abarbeiten, auch nicht in späteren Sitzungen und auch nicht, wenn HANDOFF, Roadmap oder `Bugs & Ideen` es nennen. Was als Nächstes kommt, entscheidet der Nutzer.
  - Zum laufenden Auftrag gehört, was er ausdrücklich verlangt, und die Behebung von Fehlern, die er selbst verursacht hat.
- **Bossarbeit** folgt `docs/Design/Boss-Design.md` und `docs/Design/Kampf & Begegnungen.md`. Gefahren laufen über eine Uhr je Boss (`v2_clock`), sodass Warnung und Treffer synchron bleiben.
- **Grafik-, Animations-, Effekt- und Tonarbeit** folgt `docs/Design/Visuelles Leitbild & Animation.md` und `Fähigkeiten, VFX & Audio.md`. Bewegungsreferenz Terranigma nur für Bewegungsqualität, nie Assets oder Stil kopieren.
- **Größere Umbauten** an Rendering, Animation oder Kampfsystem nur nach `docs/Design/Technische Architektur.md` und `Roadmap & Vertical Slice.md`. Mit „Offen“ markierte Entscheidungen trifft der Agent nach bestem Standard (Generalfreigabe 25.11.) und begründet sie in `docs/DECISIONS.md`.

## Review-Workflow (Development Review Center, verbindlich seit 26.11., neu gefasst 27.11.)
Details: `docs/Systeme/Review-Center.md`. Der Nutzer prüft Inhalte im Spiel (Hauptmenü → Review-Center) und urteilt im Escape-Menü mit **„Gut“** oder **„Nicht gut“**, jeweils mit Kommentar. Bei „Nicht gut“ wählt er „komplett weg“ oder „anders umsetzen“.
1. **Vor der Arbeit:** `python tests/tools/review/review.py sync`. Claude erledigt das per SessionStart-Hook, Codex führt den Befehl selbst aus.
   - Der Befehl überträgt neue Urteile aus `%LOCALAPPDATA%\FirstGame\` in `review/registry.json`: „Gut“ wird Status `processed`, „Nicht gut“ wird Status `rejected` (Feld `feedback`).
   - `status` zeigt Offenes und alle Kommentare: „NICHT GUT“ und „GUT MIT WUNSCH“.
   - **Kommentare sind Arbeitsaufträge des Nutzers:**
     - „Nicht gut, komplett weg“: den Inhalt entfernen oder abschalten.
     - „Nicht gut, anders umsetzen“: nach dem Kommentar überarbeiten, dann `bump`.
     - „Gut“ mit Wunsch (z. B. „genau so, nur schneller“): umsetzen, dann `bump`, weil sich ein freigegebener Inhalt sichtbar ändert.
     - Ist ein Kommentar unklar, beim Nutzer nachfragen, statt zu raten.
2. **Neue Einträge nur auf ausdrücklichen Wunsch des Nutzers (seit 27.11.).**
   - Sonst beurteilt und entscheidet der Agent Inhalte selbst nach dem Design-Kanon (`docs/Design/`, Statusskala in `Qualitätsstandard.md`). Technische QA und visual-qa laufen wie bisher.
   - Ein gewünschter Eintrag trägt das Feld `requested` (Datum und Wortlaut des Wunsches); `review.py check` lehnt neue Einträge ohne dieses Feld ab.
   - Das Szenario startet mit den echten Systemen, mit realistischer Ausrüstung, Level und Talenten (Konfiguration siehe Systemnotiz); danach `review.py build` und QA.
   - Keine Einträge für nicht Umgesetztes. Ein Eintrag für eine Einzelattacke gibt nicht den ganzen Boss frei.
3. **Freigegebene Inhalte sind die verbindliche Qualitätsreferenz.**
   - Ohne nachvollziehbaren Grund nicht wesentlich verändern.
   - Erlaubt: Fehlerkorrekturen, Performance, interne Refactorings ohne sichtbare Wirkung, ausdrücklich neue Anforderungen.
   - Ändert sich ein freigegebener oder bewerteter Inhalt sichtbar oder spielerisch wesentlich: `review.py bump ID --reason "…"`. Nie eine alte Freigabe übertragen.
     - Ohne `--request` bekommt die neue Revision den Status `withdrawn` (Agent entscheidet nach Kanon).
     - Mit `--request "Datum: Wortlaut"` ist sie wieder offen; nur wenn der Nutzer sie sehen will.
4. **Status `withdrawn`** bedeutet „zurückgezogen, vom Agenten nach Design-Kanon entschieden“.
   - Das ist keine Freigabe und wird nie als Urteil des Nutzers ausgegeben.
   - Das Szenario bleibt im Reiter „Archiv“ startbar; ein Urteil, das der Nutzer dort abgibt, überträgt `sync` wie jedes andere.
   - Am 27.11. wurden alle damals offenen 43 Einträge so zurückgezogen (Nutzerauftrag). Weitere offene Einträge zieht der Agent nur auf Auftrag zurück: `review.py withdraw ID|--all-open --reason "…"`.
5. **Persönliche Urteile („Gut“ und „Nicht gut“) setzt ausschließlich der Nutzer im Spiel.** Agenten schreiben nie in `review_approvals.*` und simulieren keine Freigabe.
   - Technische QA ist keine Freigabe.
   - Tests nutzen nur gekennzeichnete Testfreigaben in Testkopien (`review_e2e.py`). `--include-test` ist nur mit einer Registry-Kopie erlaubt.
6. **Entfernen aus der offenen Liste geschieht nur über den Status** (`processed`, `rejected`, `superseded`, `withdrawn`).
   - Die produktive Implementierung wird dabei nie gelöscht.
   - Verarbeitete und zurückgezogene Szenarien bleiben startbar (Reiter „Archiv“).

## Code-Konventionen (GML)
- **Stil:** dichtes GML, kurze Hilfsfunktionen.
- **Präfixe je System:** `talent_`, `equipment_`, `bc_` (Choreografie), `bv2_` (Bossgefahren), `dragon_`, `level_`, `spell_v2_`, `spell_vfx_`, `boss_test_`.
- **Daten** als statische Struct-Arrays in Funktionen, z. B. `talent_definitions()` oder `level_definitions()`.
- **Kommentare** im Code auf Englisch, UI-Texte auf Deutsch ohne Umlaute (ae/oe/ue).
- **Asset-Namen sind globale Bezeichner.** Ein bloßes `if(master_skeleton)` liefert die Skript-Referenz, nicht die Instanzvariable. Deshalb `self.<name>` verwenden oder solche Namen meiden.
  - Auch jede Skriptfunktion ist eine globale Variable: `global.vfx_quality` ist die Funktion `vfx_quality`, und `variable_global_exists("vfx_quality")` ist immer wahr. Globale Werte nie wie eine Funktion benennen (z. B. `global.vfx_quality_level`).
- **Reservierte Namen** wie `other`, `speed`, `score`, `mean`, `all` (Schlüsselwort) und eingebaute Funktionsnamen wie `real` nicht als Variablen nutzen. Folgefehler zeigen sonst irreführende Zeilen („Unknown token eArrayRef“).
- **Neue Skripte, Sprites und Objekte** in `FirstGame.yyp` registrieren, z. B. mit `tests/tools/levels/gm_project.py`. Unbekannte Funktionen kompilieren sonst als Variablen und scheitern erst zur Laufzeit.
- **Die IDE-Diagnose** meldet bei einzeiligen `if(...)return` und Komma-`var`-Listen viele Fehlalarme („unreachable“, „argument-count“).
- **Telemetrie-Anker:** `QA/tools/telemetry_injections.py` braucht exakte Code-Anker. Nach Änderungen an `class_weapons`, `spell`, `boss_hazards_v2` usw. die Anker prüfen.
- **Shell:** Bash-Heredocs mit Python-Code, der `'''` enthält, brechen im Tool-Wrapper ab; solche Skripte als Datei schreiben. Der GMS-MCP-Server kann beim Start in einen Timeout laufen; die Python-Runner rufen Igor direkt auf.

## Synchron bleiben und Token sparen (gilt für Claude **und** Codex)

### Lesen: nur so viel wie nötig, in dieser Reihenfolge
1. **Start:**
   - `docs/HANDOFF.md` (Claude bekommt sie per Hook eingeblendet, Codex liest sie selbst)
   - Review-Freigaben: `python tests/tools/review/review.py sync` (Claude: per Hook; siehe „Review-Workflow“)
   - `git log --oneline -5` und `git status --short`
   - **Nicht** die ganze Doku.
2. **Bei Design-, Inhalts- oder Grafikaufgaben:** `docs/Design/Leitbild.md` (Abschnitte 4–5 genügen meist) plus das **eine** passende Designdokument und `Qualitätsstandard.md`. Nicht den ganzen Kanon lesen.
3. **Passende Systemnotiz:** die eine Notiz in `docs/Systeme/`, die zur Aufgabe gehört (Liste in `docs/00_Index.md`).
   - `[[Name]]` ist die Datei `docs/**/Name.md`.
   - Obsidian ist nur die Ansicht für den Nutzer. Agenten lesen die Notizen als normale Dateien.
4. **Erst dann Code, und gezielt:**
   - Nach Funktionsnamen aus der Notiz suchen (`rg -n` oder `grep -n`) und nur die betroffenen Zeilenbereiche lesen.
   - Nie ganze Skripte oder den ganzen Code „zur Orientierung“ durchgehen.
- **Nicht komplett lesen:**
  - `docs/LOG.md`: nur die obersten ~15 Zeilen
  - `docs/DECISIONS.md`: nur gezielt per Suche
  - `docs/ai-activity.log` (lokal, seit 26.11. nicht mehr versioniert), `docs/_archive/`, `docs/_export/`, `QA/data/`, `QA/logs/`
  - generierte Dateien (`level_layout_*`, `spell_v2_catalog`)
  - Root-`*_REPORT.md`, `DEVELOPMENT_PROGRESS.md`, `TODO.md`, `QA/CURRENT_STATUS.md`
- **Ausgaben klein halten:**
  - Lange Ausgaben kürzen (`| tail -30`, `| head`).
  - Testläufe nur über die PASS/FAIL-Zahlen auswerten.
  - Gerade geschriebene Dateien nicht erneut lesen.

### Testen: nur passend zur Änderung, über den Stufen-Runner
- `python tests/tools/qa.py --plan` zeigt die Stufe und die passenden Suiten für den aktuellen Diff; `python tests/tools/qa.py` führt sie aus.
- **Stufen:**
  - 1: kleiner Fix, die eine passende Suite
  - 2: Systemänderung, die betroffenen Suiten
  - 3: Architektur, alle Suiten
  - 4: Simulationen, **nur auf Auftrag**
- **Cache:** Unveränderte Build-Eingaben nutzen das letzte PASS wieder.
- **Suiten:** `regression`, `feature`, `boss`, `level`, `classes`, `visual`. Details in `docs/Systeme/Tests & QA.md`.
  - `docs` (Sekunden, ohne Build): Vault-Links, Frontmatter, Review-Registry, IDE-Ordner, Kunstpfade, Systemnotiz-Abdeckung. Läuft bei jeder relevanten Änderung automatisch mit, auch bei reinen Doku-Änderungen.
  - `review` (Review-Center Ende-zu-Ende): nur wenn Review-Code oder Review-/Pausenmenü-Zeilen geändert wurden.
  - `perf` (Lastmessung, `run_native_harness.py perf`): nur auf Anlass und ohne parallele Last.
- **Technische QA ist keine persönliche Freigabe.** Stufen: technisch funktionsfähig → zur Laufzeit überprüft → visuell technisch geprüft → spielerisch durch automatisierte Tests analysiert → persönlich vom Game Designer freigegeben (nur der Nutzer).
- **QA-Prüfer** (nur lesend): `.codex/agents/qa.toml` (Codex) und `.claude/agents/qa.md` (Claude), mit demselben Inhalt.

### Schreiben: am Ende jeder abgeschlossenen Aufgabe, nicht nach jeder Nachricht
`docs/` ist der Obsidian-Vault des Nutzers. Nach jeder abgeschlossenen Aufgabe kurz die betroffenen Systemnotizen, HANDOFF und LOG aktualisieren und neue Notizen im Index verlinken:
- a) `docs/HANDOFF.md` **überschreiben**, höchstens 40 Zeilen:
  - Stand, zuletzt gearbeitet an, halb fertig, Bugs, offene Punkte (nur zur Information; was als Nächstes kommt, entscheidet der Nutzer)
  - `Zuletzt dran: Claude/Codex, Datum`
- b) **Oben** in `docs/LOG.md` 2–5 Zeilen: `### Datum · Agent · Thema`, dazu die geänderten Dateien.
- c) Nur bei echten Entscheidungen eine Zeile in `docs/DECISIONS.md`.
- d) Eine Systemnotiz nur ändern, wenn sich Dateien, Funktionen, Abhängigkeiten oder bekannte Probleme des Systems geändert haben.
  - Nur die betroffenen Zeilen ändern und `updated:` anpassen.
  - Neues System: neue Notiz nach dem Muster der bestehenden und einen Link in `docs/00_Index.md`.
  - Betroffen ist jede Notiz, die eine geänderte Datei nennt: `grep -l <name> docs/Systeme/*.md`.
- e) Neue Bugs und Ideen als eine Zeile in `docs/Bugs & Ideen.md`. Erledigtes dort entfernen.
- f) Committen, die Nachricht beginnt mit `[Claude]` oder `[Codex]`; danach `entwicklung` pushen ist erlaubt.

### Grundsätze
- **Neue Anforderungen in das Bestehende einarbeiten (verbindlich seit 26.11.):**
  - Neue bestätigte Anforderungen gehören in das jeweils maßgebliche vorhandene Dokument (Boss → `Boss-Design.md`, Talente und Ausrüstung → `Progression & Builds.md`, Klassen → `Klassen.md` usw.), nicht in neue Dateien oder zusätzliche Erinnerungen.
  - Vorher prüfen, ob sie bestehende Regeln **ergänzen, präzisieren oder ersetzen**. Widersprüchliche aktive Vorgaben entfernen; Ersetztes kurz in `DECISIONS.md` vermerken (Historie bleibt nachvollziehbar, wirkt aber nicht mehr als Anweisung). Nicht eindeutig Entschiedenes als „offen“ führen.
  - Keine Prioritätsinflation: Designphilosophie, konkrete Anforderung, technische Entscheidung, aktiver Auftrag, künftige Idee und offene Entscheidung unterscheiden. Die Roadmap ändert sich nur bei einer echten neuen Priorität.
  - Design (Soll), geplant, implementiert und getestet klar trennen; nichts Geplantes als fertig und keinen nicht gelaufenen Test als bestanden ausgeben.
  - Nur betroffene Abschnitte lesen und ändern; keine Neugenerierung des Vaults, keine redundanten Zusammenfassungen.
- **Jede Information steht an genau einer Stelle:**
  - Arbeitsregeln: AGENTS.md
  - Designregeln (Soll): `docs/Design/`
  - Stand: HANDOFF
  - Verlauf: LOG und git
  - Begründungen: DECISIONS
  - Systemkarte: `docs/Systeme/`
  - Backlog: Bugs & Ideen
- Verlinken statt kopieren. Keine neuen Status- oder Berichtsdateien anlegen.
- **Nicht gegeneinander arbeiten:** Fremde, nicht committete Änderungen (`git status`) nicht überschreiben. Wer zuletzt dran war, steht in HANDOFF.
- **Pflege:**
  - Wächst `docs/LOG.md` über ~150 Zeilen, ältere Einträge nach `docs/_archive/LOG_<Jahr>.md` verschieben.
  - Jede Notiz unter `docs/` hat Frontmatter (`tags`, `updated`) und verlinkt mit `[[Notiz]]`. `docs/.obsidian/` nicht anfassen.
