---
tags: [log]
updated: 2026-11-27
---
# Änderungslog (neueste Einträge oben, je 2–5 Zeilen). Ältere Einträge: [[LOG_2026]]

### 2026-11-27 · Claude · Punkt 4: Zauber und Passiva auf den Overhaul-Bausteinen (Roadmap 16)
- Neu `scripts/fx_spells`: Pixelpartikel für Einschläge und Feldtreffer, lebende Zauber und sichtbar wirkende Passiva; Hooks in `spell_v2`, `spell`, `cast_spell`, `apply_passives`, `gameplay`, `reset_round`, Controller-Step.
- Eigene Lichtblitze und -pulse gedämpft (`light_flash` mit Glanz-Parameter, `gameplay_polish`, `spell_v2`), Arkan-Einschlag schwächer, eigene Druckringe nur ohne Boss.
- visual-qa (Spellsheet vorher/nachher, Stufe 1 und 9, Drache mit Kettenblitz); QA-Suiten PASS. Doku: Fähigkeiten, VFX & Audio, Zauber & Passiva, Licht, Roadmap 16, DECISIONS, Bugs & Ideen.

### 2026-11-27 · Claude · Block 3: „Die Attacke ist die Warnung“ am Drachen (Pilot), HD-2D-Angriffe
- `scripts/hazard_looks`: Vorzeichen (`hz_pre_*`: Flammen, Rissnetz `hz_crack_net`, Meteor-Schatten und Fels, Glut-Zündschnur, Staub, Hitzeschimmer, Licht `hz_pre_lights`) und aktive Darstellung (`hz_dragon_active`: Flammenteppich, Kruste, Staubwand, Hiebspur) für alle 9 Drachenattacken plus Biss und Schweif; offene Fragen aus Kampf 5.0 entschieden.
- Zeichenreihenfolge: aktive Bossgefahren über allen Ankündigungen (`bv2_hazards_draw(_pass)`, `Draw_73`); Elemente nie auf Spielerfigur und Drachenkörper; Zündblitze gedämpft, ein Licht je Angriffsbild.
- Sieben Aufnahmerunden, zwei visual-qa-Runden (Befunde umgesetzt, Rest in [[Bugs & Ideen]]); QA 9 Suiten PASS, Boss-Suite 190 mit Orakel.
- Doku: Kampf & Begegnungen 5.0 und 8, Boss-Design B2, Roadmap 15, DECISIONS, Telegraphs, Bugs & Ideen.

### 2026-11-27 · Claude · Block 2: Boss-Codepfade auf bv2 zusammengeführt, Bildflächen-Korrektur
- Drache (`dragon_encounter`: `dragon_enc_hazards`, Melee) und Minibosse (`boss_combat`: Zonen, Ankündigung `mini_cast`) laufen über die gemeinsamen `bv2`-Gefahren auf der Uhr je Boss; neue Stelle für Looks und Zündung: `scripts/hazard_looks`; `boss_hazards_v2` mit Kernbereich, Ring-Funktion, Farb-Override und Look-Hooks.
- Orakel (`tests/boss_harness.gml`) ohne Drachen-Sonderzweig, sieht Projektile aller Bosse; `boss_v2_harness`, Telemetrie-Anker, Bot-Simulationen (`QA/tools/*_mc_harness.gml`) angepasst.
- `render_present` setzt die Bildfläche auf 960×540 zurück (Fenstergröße im laufenden Raum); Recorder liefert 960×540, neue Option `--orbit`.
- Doku: Bosse, Telegraphs, Rendering, Technische Architektur, DECISIONS, Bugs & Ideen.

### 2026-11-27 · Claude · „Mach das alles“, Block 1: Roadmap 14 (Welt-Feedback, Startwaffen), Drachen-Befunde, Leistung
- Neu `scripts/fx_world`: Treffer, Tode, Münzen, Pickups, Level-up, pixelgenaues Pflanzenwiegen, Startwaffen-Partikel; Partikelfarben aus Tabellen (`fxp_lut`), Gedränge-Entlastung, Trefferaufblitzen auf der Spieluhr (`fx_flash_tick`), Sternenorb neu (`vfx_star_orb`).
- Drache: Fächer von Leere und Wind treffen die Zielposition auch bei gerader Projektilzahl; Sequenzen neu zusammengestellt (`bc_sequences`); Salven-Bahnen folgen der Projektilzahl.
- Münzen: schneller Pfad im Step (`ObjectCoin`), Glitzern zentral. Leistung: Horde 16,9 ms wie vor dem Overhaul, Münz-Stresstest 18,2–18,4 ms (offen).
- Geänderte Dateien: `spell`, `spell_v2`, `class_weapons`, `master_combat`, `fx_particles`, `fx_character`, `atmosphere`, `level_world`, `master_world`, `reset_round`, `dragon_encounter`, `boss_choreo`, Objekte `ObjectCoin`, `ObjectMonster`, `ObjectController`, `ObjectEnvironmentDecoration`; Level-Suite prüft das 960×540-Raster; Regel „bei Widersprüchen erst fragen“ (AGENTS.md, DECISIONS).

### 2026-11-27 · Claude · Arbeitsweise und Review-Center neu, Grafik-Overhaul abgeschlossen, Designentscheidung „Die Attacke ist die Warnung“
- Review-Center: neuer Status `withdrawn` (zurückgezogen, vom Agenten nach Design-Kanon entschieden, keine Freigabe); alle 43 offenen Einträge zurückgezogen und im Archiv startbar. `review.py` mit `withdraw`, `bump --request` (ohne Prüfwunsch → `withdrawn`), Pflichtfeld `requested` für neue Einträge; `review_center.gml` zeigt den Status im Archiv und kürzt lange Listentitel vor der Spalte Lv/Rev.; `review_e2e.py` und `tests/review_harness.gml` prüfen den neuen Ablauf.
- Regeln: AGENTS.md (Review-Workflow neu gefasst, „Offenes melden statt abarbeiten“), CLAUDE.md, `.claude/agents/*`, `.codex/agents/*`, Systemnotizen Review-Center, Tests & QA, UI, Zauber & Passiva.
- Overhaul: Richtung bestätigt, Ausrollen beendet; Zauber/Passiva und Gegnerangriffe herausgelöst (Roadmap 14–16, Visuelles Leitbild 7.4).
- Design (nur festgehalten): Leitbild G19, Kampf & Begegnungen 5.0, Boss-Design B2; ersetzte Marker-Regeln durchgestrichen (auch Visuelles Leitbild 3a, Technische Architektur 4.5, Qualitätsstandard Status „nach Kanon entschieden“); DECISIONS, Bugs & Ideen.

### 2026-11-26 nachts · Claude · Grafik-Overhaul HD-2D, Schritte 0–3 (Grundlage und Schaustück) plus Ergänzung Figuren und Gefahrenflächen
- Neu:
  - `scripts/render_fx` mit den Shadern `sh_fx_bright`, `sh_fx_blur`, `sh_fx_composite`: Nachbearbeitung nur der Weltebene, die Lesbarkeitsebene bleibt unverändert;
  - `scripts/fx_particles` (Pixelpartikel), `scripts/atmos_fx` (Atmosphäre je Level), `scripts/fx_attacks` (Feueratem-Dekor);
  - `scripts/fx_character` mit `sh_fx_char` (Randlicht, Trefferaufblitzen, Schatten, Staub, Aura, Waffenglühen);
  - `vfx_beam_fire_hd` (neue Gefahrenfläche des Feuerstrahls).
- Geändert:
  - `atmosphere` (verstärkbares Licht, Lichtmessung für die Figur);
  - `ObjectController` Step und Draw End (Weltebene, Nachbearbeitung, Lesbarkeitsebene, `FXP_TOP`);
  - `ObjectPlayer/Draw_0`;
  - `spell`, `gameplay_polish` (Feuerball, Eisball, Kettenblitz);
  - `reset_round`.
- Werkzeuge: `shaders/` in allen Testkopien und den `qa.py`-Eingaben, `gm_project.shader`, IDE-Ordnerregeln, Aufräumer behält `overhaul/` und `reference/`. Referenzbilder lokal unter `FirstGame_ArtPack/reference/octopath/` (gitignored).
- Doku: Leitbild G10, Visuelles Leitbild 7, Fähigkeiten/VFX, Technische Architektur, Assets & Pipeline (Referenzordner, 7.8), Roadmap 14, DECISIONS, Systemnotizen. Review: 8 neue Einträge, `boss.dragon.beam` Rev. 3 und `boss.twins.checker` Rev. 2 per bump.
- Tests: QA Stufe 3 PASS (docs, anchors, static, Regression 811, Feature 219, Boss 190, Level 174, Klassen 151, Visual 77, Review 18); perf PASS laut Suite; Bosskämpfe und Horde wie vorher (16,7–17,3 ms), Münz-Belastungstest 17,2–17,5 → 18,4–18,6 ms (FAIL gegen 60 FPS, war schon vorher knapp darunter); visual-qa: Strahlrand PASS (klarer als vorher); Gegner am Rand nach Korrektur der Schutzmaske wieder scharf (±9 % Helligkeit). Messung der Gegner am Rand nach visual-qa-Hinweis korrigiert (Schutzmaske als feste Körperform). Spar-Maßnahmen: ein Weichzeichner-Durchgang je Kette, Schwebeteilchen gruppenweise und bei Horden ausgedünnt, Gegnerschatten als ein Sprite, Feuerstrahl gröber segmentiert.

### 2026-11-26 abends · Claude · Basemodels verworfen, Rüstung unsichtbar, Review-Urteil mit Kommentar
- Spiel: `equipment_visual` (`EQUIPMENT_ARMOR_VISIBLE false`, nur Waffe gezeichnet), `review_center` (Urteilsdialog „Gut“ / „Nicht gut“ mit Kommentar, „komplett weg“ / „anders“, Reiter „Nicht gut“), `gameplay` und `ObjectController/Step_0` (Dialog besitzt Eingabe, Esc schließt nur ihn).
- Werkzeuge und Tests: `review.py` (Status `rejected`, `feedback`, Kommentare in `status`), `review_e2e.py` und `review_harness.gml` (Dialog, Kommentar, Abbruch), `visual_harness.gml` (Rüstung pixelgleich unsichtbar, Waffe sichtbar). Review: `char.armor.hidden` neu; die ersten beiden Nutzerfreigaben sind verarbeitet.
- Doku: Visuelles Leitbild 5.5a, Klassen, Assets & Pipeline 7.1/7.7, Roadmap 11, Progression & Builds, DECISIONS, AGENTS „Review-Workflow“, Systemnotizen (Charaktergrafik, Ausrüstung, Review-Center, Tests & QA), ArtPack-READMEs, HANDOFF; LOG bis 24.11. nach `_archive/LOG_2026.md`.
- Nachgebessert: Pausenliste mit beiden Urteilszeilen rückt zusammen (`pause_row_pitch` in `gameplay_polish`, normales Pausenmenü unverändert), weil „Einstellungen“ sonst unter den Hilfezeilen lag. Testcode `review_harness` (Bildtakt, kein Funktionsname `real`).
- Tests: QA Stufe 3 PASS (docs, anchors, static, Regression 811, Feature 195, Boss 190, Level 174, Klassen 151, Visual 77, Review 18).

### 2026-11-26 · Claude · Orakel für Drachen-Projektile, Codex-Übergabe geprüft
- `tests/boss_harness.gml`: Das Orakel sieht die Projektile des Drachen (gleiche Trefferregel wie `boss_hazards_step`), Zählung `bullets` und `bullet_frames` je Fall. Spielcode unverändert.
- Übergabe: Pfade existieren. Korrigiert sind die Atlasgrößen (5 von 12 abweichend, Waldläufer combat 9 Reihen) und der Alpha-Schnitt 128/180 in `Assets & Pipeline.md` 7.1 und `base_neutral/README.md`. `check_base_neutral.py` nutzt jetzt die Zellgrenzen des Importers und hat die Option `--dir`.
- Doku: Bosse (Tabelle Projektile), Bugs & Ideen (Prüffrage Leere/Wind), Tests & QA, HANDOFF.
- Tests: QA PASS (docs, anchors, Boss 190); 0 unsichere Bilder in allen Drachenfällen. Probe `check_base_neutral` PASS bzw. FAIL wie erwartet.

### 2026-11-26 · Claude · Kurskorrektur: Basemodel ohne Ausrüstung (Priorität 1), Erzeugung blockiert
- Regel zentral verankert: `Visuelles Leitbild & Animation.md` 5.5a (Verbots- und Erlaubnisliste, Ebenen-Stapel mit 10 Ebenen). Die heutigen Figuren sind als ausgerüstete Startfiguren eingestuft.
- Widersprüche bereinigt: `Klassen.md` (Aussehen ohne Umhang, Robe, Köcher als Identität), `DECISIONS.md` („Umhänge bleiben im Basismodell“ ersetzt), `Assets & Pipeline.md` 7.1 und 7.7, `Progression & Builds.md`, Roadmap 11, Systemnotizen Charaktergrafik und Ausrüstung, ArtPack-README, `base_neutral/README.md`.
- Werkzeuge: `check_base_neutral.py` (Schwellen für Figuren ohne Umhang und Robe), `atlas.py` und `art_paths.py` (Beschreibung). Review: `char.equipment.mage` und `.ranger` ersetzt (34 offen).
- Nicht erzeugt: die Basemodels selbst (kein Bildwerkzeug in dieser Umgebung). Tests: docs PASS, Registry gültig.

### 2026-11-26 · Claude · Qualitätsaudit: Münz-Culling, Ringgeometrie des Drachen, Orakel für Altangriffe
- Spiel: `combat_feedback` (`coin_cull_step`) und `ObjectController/Step_0` (Aufruf); `dragon_encounter` (`dragon_ring_geometry` für Treffer und Bild).
- Tests: `tests/boss_harness.gml` (Orakel sieht geometrische Altangriffe), `tests/perf_harness.gml` (Szenario `horde_coins`), `tests/level_harness.gml` (Münz-Culling in 3 Leveln), `profile_perf.py` (Anker).
- Doku: Bosse, Progression & Level-up, Tests & QA, Bugs & Ideen (drei Boss-Codepfade, Gegnerzustand, Sequenz-Vielfalt, Waldläufer), DECISIONS.
- Tests: QA Stufe 2 PASS (Regression 811, Boss 190, Level 174); perf: 2.500 Münzen 56,7 → 66,7 FPS unbegrenzt, übrige Szenarien unverändert.

### 2026-11-26 · Claude · Folgeauftrag: Drachen-Sequenzen, Nutzerentscheidungen, Trefferstopp, Grafik-Anforderungen
- Spiel:
  - `boss_choreo` (Sequenzen), `dragon_encounter` (Anbindung), `boss_encounters_v2` (`bv2_motion_offset`), `combat_feedback` und `ObjectMonster/Draw_0` (Trefferstopp).
  - `render_pipeline`, `ObjectMainMenu/Step_0` und `ObjectController/Create_0` (Texturen im Menü).
  - `spell_vfx`, `weather`, `level_world` und `master_combat` (`vfx_random`); `boss_test_mode` (Preset, Sequenzanzeige); `master_skeleton` und `player_artpack` (Cache, Rollen-Präfix); `level_worlds` (`monster_art_div`); `review_center` (`sequence`, `magnet_orb`).
- Tests und Werkzeuge:
  - `tests/boss_harness.gml` (Lauf `sequences`), `tests/visual_harness.gml` (Trefferstopp), `tests/perf_harness.gml` (Menü-Vorladen), `tests/scene_harness.gml` und `record_scene.py` (`spellsheet`), `run_native_harness.py` (Feature mit fester Bildzeit).
  - `tests/tools/characters/check_base_neutral.py`, `atlas.base_neutral_path`, `art_paths.CHARACTER_BASE_NEUTRAL`, `profile_perf.py`.
  - `review/registry.json` (+11), `.gitignore` (Obsidian workspace), `docs/.obsidian/` versioniert.
- Doku: Boss-Design H2, Assets & Pipeline 7, Kampf & Begegnungen 9, Roadmap 4/9/11/12, DECISIONS, Systemnotizen (Bosse, Boss-Testmodus, Review-Center, Spielablauf, Gegner & Spawns, Licht/Effekte, Zauber & Passiva, Tests & QA), Bugs & Ideen.
- Tests: QA Stufe 3 PASS (Regression 811, Feature 195, Boss 190, Level 168, Klassen 151, Visual 86, Review 12); perf: Horde 72 FPS unbegrenzt, Hexen 102, Drache 96, keine Ausreißer.

### 2026-11-26 · Claude · Performance bei vielen Gegnern, Textur-Vorladen, ArtPack-Pfade
- Spiel: `spell_world_v2` (Zellindex `scenery_grid_build` für die Wald-Kollision, Ergebnis identisch), `master_world` und `ObjectMasterWorld` (Index mitbauen und zurücksetzen), `gameplay` (gemeinsame Nachbarliste in `enemy_pursue`), `ObjectController/Create_0` (Texturgruppen vorladen, vorläufig, etwa 5,1 s beim ersten Run).
- Werkzeuge und Tests: `tests/tools/profile_perf.py` (neu), `tests/perf_harness.gml` (Ausreißer, Texturlog), `tests/level_harness.gml` (Raster gegen Vollsuche), `QA/tools/native_mc_harness.gml`; `art_paths.py --check` prüft `.ps1`-Pfade, 12 PowerShell-Skripte auf die Zielstruktur gezogen; `atmosphere_v2` → `FirstGame_ArtPack/bosses/`.
- Tests: QA Stufe 3 PASS (docs, anchors, static, Regression 811, Feature 195, Boss 141, Level 168, Klassen 151); perf: Horde 148 Gegner 73–75 FPS unbegrenzt (vorher 64–66), keine Ausreißer über 50 ms.

### 2026-11-26 · Claude · Offene Aufgaben, QA-Optimierung, Dokumentationsregel
- Messungen: `tests/perf_harness.gml` (Suite `perf`), `QA/tools/analyze_levels.py`, Kohorte `QA/data/level-cohort-2026-11-26/`; Vorschlag für `boss_test_preset` in der Notiz Boss-Testmodus.
- Spiel: `spell_v2` (`spell_impact_light`, Sammelphase), `level_worlds` und `master_skeleton` (Wald-Skelette, allokationsfreie Bewegung), `equipment_visual` (`eqv_attach_draw`), `boss_test_mode` (F10-Anker), `audio_manager` (Lautstärken speichern), `combat_feedback` und `build_pixel_font.py` (Buchstaben, „MAGNET“).
- Aufräumen und QA: Kollisions-Events der Altprojektile entfernt, `tests/_legacy/`, ArtPack in Zielstruktur (`art_paths.py`), `qa.py` (Suiten `docs`, `review`), `tests/tools/vault_check.py`, `validate_project.py`, `audit_boss_v2_assets.py`, `export_design.py`, Agenten `qa`/`visual-qa`, `docs/ai-activity.log` nicht mehr versioniert.
- Tests: QA Stufe 3 PASS (docs, anchors, static, Regression 811, Feature 195, Boss 141, Level 166, Klassen 151, Visual 84); perf: Horde 148 Gegner 64–66 FPS unbegrenzt, Bosse mit 60 Gegnern 79–91.

### 2026-11-26 · Claude · Phase 2A/2B: Telegraphs, Gefahrenflächen, Licht, Bossdruck, Schachbrett, Ringe, Pfeile, Ankerpunkte
- Neu: `scripts/hazard_fx`, `scripts/equipment_attach_data`, `tests/tools/characters/build_attach_points.py`, Systemnotiz `Telegraphs & Gefahrenflächen`.
- Geändert: `attack_telegraph`, `boss_hazards_v2`, `boss_choreo`, `boss_encounters_v2`, `dragon_encounter`, `dragon_parts`, `atmosphere`, `class_weapons`, `combat_feedback`, `spell_v2`, `spell_vfx`, `gameplay`, `player_artpack`, `equipment_visual`, `level_worlds` (Gegner-Bewegungsidentität), Tests (Boss-Orakel, Klassen-Flush, Visual-Anker, Level-Suite mit fester Bildzeit), `record_scene.py --boss-hp`, `ide_folders.py`.
- Doku: Leitbild G15–G18, Kampf & Begegnungen, Boss-Design A2/A3, Fähigkeiten/VFX/Audio, Visuelles Leitbild (Referenz 3a, modulare Figur 5.5a), Roadmap, Assets, DECISIONS. Review-Registry: 25 Szenarien.
- Tests: QA Stufe 3 PASS (Regression 811, Feature 195, Boss 141, Level 166, Klassen 151, Visual 81); Review-E2E PASS 12/12.

### 2026-11-26 · Claude · Phase 1: Review-Center und Inventar
- Review-Center (`scripts/review_center`, `review/registry.json`, generiert `scripts/review_registry_data`, Werkzeuge `tests/tools/review/review.py` und `review_e2e.py`, `tests/review_harness.gml`). Hauptmenü, Pausenmenü mit grünem Freigabeknopf, Hook in `.claude/settings.json`.
- Inventar (`scripts/equipment_ui`): Drag-and-drop, Rechtsklick legt ab, Tooltips, Shift-Vergleich. `equipment_menu_step` und `equipment_tooltip_draw` leiten weiter.
- Isolation: `dev_session_active` in `talent_persistent` und `progression_audit_step`. `run_native_harness.py` in Bausteine zerlegt.
- Tests: QA Stufe 3 PASS (Regression 811, Feature 195 mit 33 Inventarprüfungen, Boss 141, Level 166, Klassen 151, Visual 75); Review-E2E PASS 12/12.

### 2026-11-26 · Claude · Vault-Prüfung (nur Doku, Code nur gelesen, nicht committet)
- 12 Systemnotizen an den Code-Stand angeglichen: Audio, Ausrüstung, Level & Welten, Progression & Level-up, Spielablauf & Zustände, Zauber & Passiva, Talente, Gegner & Spawns, Licht/Wetter/Effekte, Klassen & Startwaffen, Speichern & Einstellungen, Spieler & Bewegung.
- Frontmatter für `_archive/CLAUDE_2026-11-24.md` und `_export/Designphilosophie_2026-11-25.md`; beide im `00_Index` verlinkt. Nachtrag in `SETUP_REPORT`, zwei Einträge in `Bugs & Ideen`.
- `AGENTS.md`: Vault-Satz im Abschnitt „Schreiben“, Regel zum Finden betroffener Notizen, `docs/.obsidian/` nicht anfassen.

### 2026-11-25 · Claude · Zwillingshexen gebacken, alle Boss-Effekte als Pixel-Komposite, deterministische Boss-Tests
- Hexen aus den Quellbögen in Spielgröße (`build_boss_baked.py twins`); `dragon_fx_sprite`, `class_fx_sprite`, `bv2_fx` und Hexen-Projektile als Pixel-Komposite (`dragon_encounter`, `class_weapons`, `boss_hazards_v2`, `boss_combat`).
- `vfx_pixel_line` als ein Primitiv (`spell_vfx`); Boss-Suite mit fester Bildzeit (`run_native_harness.py` `FIXED_DT_SUITES`), nachdem die Hexen-Kennzahl von der Bildrate abhing (8/17 → 10/17).
