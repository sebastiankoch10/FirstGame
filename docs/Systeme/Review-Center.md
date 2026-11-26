---
tags: [system, review, qa, entwicklung]
updated: 2026-11-26
---
# Review-Center (Development Review Center)

## Zweck
Dynamische To-do-Liste im Hauptmenü („Review-Center (N offen)“). Jeder Eintrag startet ein spielbares Szenario mit den echten Spielsystemen. Der Nutzer prüft es und gibt es im Escape-Menü mit dem grünen Haken frei. Agenten lesen die Freigaben beim nächsten Auftrag automatisch ein. Verbindlicher Ablauf: AGENTS.md, Abschnitt „Review-Workflow“.

## Datenfluss und Speicherorte
| Was | Wo | Wer schreibt |
|---|---|---|
| Szenarien (einzige Quelle) | `review/registry.json` im Projekt | Agenten, nur über `tests/tools/review/review.py` (`build`, `bump`, `sync`) |
| Spieldaten | `scripts/review_registry_data` (generiert, nicht von Hand ändern) | `review.py build` |
| Persönliche Freigaben | `%LOCALAPPDATA%\FirstGame\review_approvals.json` plus Protokoll `review_approvals.log` (nur anhängen) | ausschließlich das Spiel, beim Klick des Nutzers |
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
  - Im Spiel zeigt der Reiter „Freigegeben“ eigene, noch nicht synchronisierte Freigaben.
- **Revisionen:** Eine Freigabe gilt nur für die freigegebene Revision. `review.py bump ID --reason …` erhöht die Revision bei wesentlichen Änderungen. Der Eintrag ist danach wieder offen; alte Freigaben werden nicht übertragen.

## Wichtige Dateien
- `scripts/review_center`:
  - Registry-Zugriff: `review_entries`, `review_find`, `review_state`.
  - Lokale Freigaben: `review_local_load`, `review_local_approved`, `review_approve_current`.
  - Szenariostart: `review_start` → `boss_test_pending_start` → `review_after_start` (Overrides).
  - Pausenmenü: `review_pause_labels`, `review_pause_activate`, `review_approve_button_draw`.
  - Listenbildschirm: `review_center_step`, `review_center_draw`.
  - Abschalten für öffentliche Builds: `#macro REVIEW_CENTER_ENABLED`.
- `tests/tools/review/review.py`: `status`, `sync`, `build`, `bump`, `check`.
- `tests/tools/review/review_e2e.py` und `tests/review_harness.gml`: End-to-End-Test mit Testfreigaben.
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
