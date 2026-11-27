---
tags: [system, review, qa, entwicklung]
updated: 2026-11-27
---
# Review-Center (Development Review Center)

## Zweck
Dynamische To-do-Liste im Hauptmenü („Review-Center (N offen)“). Jeder Eintrag startet ein spielbares Szenario mit den echten Spielsystemen.

**Seit 27.11. (Nutzerauftrag):** Die offene Liste enthält nur, was der Nutzer ausdrücklich prüfen will.
- Neue Einträge legen Agenten nur auf ausdrücklichen Wunsch an (Feld `requested` mit Datum und Wortlaut; `review.py check` lehnt neue Einträge ohne dieses Feld ab).
- Sonst beurteilt der Agent Inhalte selbst nach dem Design-Kanon; technische QA und visual-qa wie bisher.
- Alle 43 bis dahin offenen Einträge stehen im Status `withdrawn` („zurückgezogen, vom Agenten nach Design-Kanon entschieden“) im Reiter „Archiv“ und bleiben startbar. Das ist keine Freigabe.

**Urteil seit 26.11. abends:** Im Escape-Menü stehen zwei Zeilen:
- „Gut – freigeben“ (grüner Haken): Kommentarfeld für Wünsche, z. B. „genau so, nur etwas schneller“.
- „Nicht gut“ (rotes Kreuz): Auswahl „Komplett weg“ oder „Anders umsetzen“ (Pfeile, Tab oder Klick) plus Kommentar.

Bedienung des Dialogs:
- Enter oder „Speichern“ speichert, Esc schließt nur den Dialog.
- Diktieren mit der Windows-Spracheingabe (Win+H) schreibt direkt ins Feld, weil das Feld normale Tastatureingaben (`keyboard_string`) annimmt. Das ist nicht automatisch getestet.
- Umlaute werden unverändert gespeichert und in der Pixelschrift als ae/oe/ue angezeigt.
- Ein späteres Urteil derselben Revision ersetzt das frühere.

Agenten lesen Urteile und Kommentare beim nächsten Auftrag automatisch ein. Verbindlicher Ablauf: AGENTS.md, Abschnitt „Review-Workflow“.

## Datenfluss und Speicherorte
| Was | Wo | Wer schreibt |
|---|---|---|
| Szenarien (einzige Quelle) | `review/registry.json` im Projekt | Agenten, nur über `tests/tools/review/review.py` (`build`, `bump`, `withdraw`, `sync`) |
| Spieldaten | `scripts/review_registry_data` (generiert, nicht von Hand ändern) | `review.py build` |
| Persönliche Urteile | `%LOCALAPPDATA%\FirstGame\review_approvals.json` plus Protokoll `review_approvals.log` (nur anhängen). Je Datensatz `verdict` (good/bad), `decision` (keep/remove/change), `comment`, `at` | ausschließlich das Spiel, beim Speichern des Nutzers |
| Testfreigaben | Speicherordner der Testkopie, z. B. `%LOCALAPPDATA%\FirstGameReviewE2E\` (Feld `test: true`) | nur technische Tests |

- **GameMaker-Sandbox (geprüft 26.11.):** Das Spiel schreibt nur in seinen Speicherordner `%LOCALAPPDATA%\<Projektname>\`, nicht in den Projektordner. Deshalb liest `review.py sync` die Freigaben dort und überträgt sie in die Registry.
- **Robustes Schreiben:**
  - Das Spiel schreibt in eine Temp-Datei und benennt sie dann um; die Vorversion bleibt als `.bak` erhalten.
  - Zusätzlich hängt es jede Freigabe als eine Zeile an das Protokoll an.
  - Ist die JSON-Datei beschädigt, wird sie als `review_approvals_damaged_*.json` gesichert, nie überschrieben.
  - `review.py` liest beide Quellen und führt sie über die `uid` zusammen.
- **Status:**
  - `pending`: offen.
  - `approved`: freigegeben, Übernahme läuft.
  - `processed`: verarbeitet, archiviert, bleibt für Regressionstests startbar.
  - `superseded`: durch eine neue Revision ersetzt.
  - `rejected` (seit 26.11.): „Nicht gut“, mit `feedback` (Entscheidung, Kommentar). Der Agent entfernt den Inhalt oder setzt ihn um und erhöht dann die Revision (`bump`); Urteil und Kommentar wandern dabei in `revisions`.
  - `withdrawn` (seit 27.11.): aus der offenen Liste genommen, vom Agenten nach Design-Kanon entschieden, mit Datensatz `withdrawn` (`at`, `by: agent`, `reason`). Keine Freigabe, nichts gelöscht, Szenario im Archiv startbar (Liste: Präfix `[-]`; lange Titel werden in der Liste gekürzt, voller Titel im Detailfeld). Ein Urteil, das der Nutzer dort trotzdem abgibt, überträgt `sync` wie jedes andere.
  - Reiter im Spiel: „Offen“, „Freigegeben“ (auch eigene, noch nicht synchronisierte), „Nicht gut“, „Archiv“ (verarbeitet, ersetzt, zurückgezogen).
  - Verlauf und Kommentare gehen nicht in die generierten Spieldaten (`game_entry` in `review.py`), weil freier Text Apostrophe enthalten kann.
- **Revisionen:** Eine Freigabe gilt nur für die freigegebene Revision. `review.py bump ID --reason …` erhöht die Revision bei wesentlichen Änderungen; alte Freigaben werden nie übertragen.
  - Ohne `--request` bekommt die neue Revision den Status `withdrawn` (Agent entscheidet nach Kanon).
  - Mit `--request "Datum: Wortlaut"` (der Nutzer will sie sehen) ist sie wieder offen.
- **Zurückziehen:** `review.py withdraw ID --reason …` oder `withdraw --all-open --reason …` nimmt offene Einträge aus der Liste.

## Wichtige Dateien
- `scripts/review_center`:
  - Registry-Zugriff: `review_entries`, `review_find`, `review_state`.
  - Lokale Urteile: `review_local_load`, `review_local_verdict`, `review_local_approved`, `review_local_rejected`, `review_save_verdict`.
  - Szenariostart: `review_start` → `boss_test_pending_start` → `review_after_start` (Overrides).
  - Pausenmenü: `review_pause_labels`, `review_pause_activate`, `review_approve_button_draw` (Haken bzw. Kreuz).
  - Urteilsdialog: `review_feedback_open`, `review_feedback_step` (aufgerufen aus `round_menu_step`), `review_feedback_draw`, `review_ascii`. Esc-Sperre im `ObjectController`-Step.
  - Listenbildschirm: `review_center_step`, `review_center_draw`.
  - Abschalten für öffentliche Builds: `#macro REVIEW_CENTER_ENABLED`.
- `tests/tools/review/review.py`: `status`, `sync`, `build`, `bump` (`--request`), `withdraw` (`--all-open`), `check` (Pflichtfeld `requested` ab 27.11.).
- `tests/tools/review/review_e2e.py` und `tests/review_harness.gml`: End-to-End-Test mit Testurteilen (Dialog abbrechen, „Gut“ mit Kommentar und Umlaut, „Nicht gut / komplett weg“ mit Kommentar, Neustart, Sync, Bump mit Prüfwunsch, Zurückziehen und Bump ohne Prüfwunsch, Start aus dem Archiv, `check` ohne `requested`).
- Claude: Der SessionStart-Hook führt `review.py sync --brief` aus (`.claude/settings.json`). Codex führt den Befehl laut AGENTS.md selbst aus.

## Szenario-Konfiguration (`scenario`)
| Schlüssel | Bedeutung |
|---|---|
| `type` | `boss` (Bosskampf), `scene` (freie Szene), `showroom` (Testraum ohne Gegner) |
| `boss`, `ability` | Boss-ID und erzwungene Fähigkeit. Die Rotation wiederholt sie automatisch; dazu gibt es „Attacke erneut auslösen“. |
| `minute` | Fortschrittszeitpunkt. Daraus folgen Spielerlevel, Build-Umfang, Gegenstandsstufe und Gegnerstärke. |
| `class`, `seed`, `build` (`balanced`, `random`, `empty`), `difficulty` | Grundkonfiguration |
| `level` | Spielerlevel überschreiben, sonst `boss_test_preset(minute)` |
| `spells` [{id, level}], `spells_replace` | Zauber über `boss_test_add_skill` (echte Zauberliste) |
| `talents` [{id, rank}], `talent_points` | Talente über `talent_grant` und `talent_invest` (echte Regeln) |
| `weapon_upgrades` | Waffen-Upgrades über `weapon_upgrade_take` |
| `gear` (Seltenheit 0–3), `gear_items`, `backpack` | Ausrüstung über `equipment_generate` und `equipment_equip` |
| `enemies` (`none`, `normal`), `enemy_pack` {count, radius} | Gegner über `population_spawn_enemy` |
| `invulnerable`, `hp`, `boss_hp`, `boss_offset`, `arena` | Ausgangslage |
| `sequence` (Index), `magnet_orb` (true) | seit 26.11.: erzwingt die choreografierte Sequenz der Bossphase (`bc_seq_force`) bzw. legt eine Magnetkugel neben die Figur |

## Isolation
- Während eines Review- oder Testmodus-Laufs liefert `dev_session_active()` true.
  - `talent_persistent()` ist dann false: kein Laden oder Speichern von `firstgame_talents.ini`. Diese Lücke bestand bis 26.11. auch im Testmodus.
  - `progression_audit_step` schreibt nichts.
- Szenarien starten immer über `reset_round()` und einen Raumneustart. Dadurch bleiben keine Instanzen, Gefahren, Partikel oder Timer zurück.

## Abhängigkeiten
[[Boss-Testmodus]] (gemeinsame Startpipeline) · [[UI, HUD & Menüs]] · [[Talente]] · [[Ausrüstung]] · [[Speichern & Einstellungen]] · [[Tests & QA]] · [[Qualitätsstandard]]

## Bekannte Probleme
- Spielerlevel je Minute kommt aus `boss_test_preset` (Entwicklungswerte, nicht gemessen). Eine Kalibrierung über Bot-Simulationen steht in [[Bugs & Ideen]].
- Neue oder geänderte Szenarien erscheinen erst nach `review.py build` und einem neuen Build (F5).
