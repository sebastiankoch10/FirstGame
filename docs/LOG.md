---
tags: [log]
updated: 2026-11-26
---
# Änderungslog (neueste Einträge oben, je 2–5 Zeilen)

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

### 2026-11-25 · Claude · Pixelraster, Drache als Verbund, Pixel-Effekte, Testmodus (`77f68e40` und folgende)
- Rendering Variante B (`scripts/render_pipeline`, `ObjectRender`): Welt 960×540, Ausgabe ganzzahlig/sharp-bilinear; Szenen-Aufnahme `record_scene.py`, Aufräumen `clean_test_artifacts.py`; erster Push von `entwicklung`.
- Drache aus Teilen (`scripts/dragon_parts`, `dragon_parts_data`, `tests/tools/bosses/build_dragon_parts.py`, `spr_drg_*`), Behemoth in Spielgröße (`build_boss_baked.py`, `spr_bv2b_*`), Pixel-Werkzeug `tests/tools/art/pixelize.py`.
- Pixel-Komposite: Feueratem/Feuerkegel (`dragon_boss`), Schwerthiebe (`master_combat`), Klasseneffekte (`class_weapons`), Pixelschrift für Schadenszahlen (`spr_font_world`).
- Testmodus mit „Freie Szene“ (`boss_test_mode`, Hauptmenü „Testmodus“). Figuren-Palette geprüft und verworfen (DECISIONS).

### 2026-11-25 · Claude · Helme als Kopf-Komposit, saubere Figurenkanten (Nutzerauftrag)
- Kopf und Helm als ein Stück (`helmet_composite` in `build_characters.py`, Daten `hcut`); Laufzeit lässt die oberen Zeilen des Basismodells weg (`eqv_hcut`, `eqv_draw_base_cut`, `rig_draw_frame(..., _cut)`).
- Kantenreinigung in `render.py`: `clean_fringe` (heller Saum → Konturton, alle Klassen), `clean_matte` (graue Hintergrundreste, nur Schwertmeister). Alle Figuren neu gebaut.
- QA: Helm-Stand Stufe 3 PASS (8 Suiten); nach dem Schwertmeister-Neubau visual 75 und classes 151 PASS.

### 2026-11-25 · Claude · Gegner-Pixeldichte, letzte Zauber, Effektqualität, Pfadtabelle (`d461d3e4` und folgende)
- Pixeldichte 1:1 für Kriecher, Pilzkreatur, Eisgeist, Konstrukt (`enemies.py` `creature_spec`, `level_worlds` `baked`/`monster_art_div`); Skelett-Gegner bleiben (A/B ohne Gewinn).
- Irrlicht und Prismensamen als Pixel-Effekte (`vfx_wisp_draw`, `vfx_seed_draw`), Verbindungsstrahl als Pixellinie: alle 18 Zauber fertig.
- Grafikoption Effektqualität Niedrig/Mittel/Hoch (`vfx_quality*` in `spell_vfx`, Menüs in `gameplay` und `ObjectMainMenu`, `firstgame_settings.ini`), Feature-Test 160.
- Asset-Migration Schritt 1: Pfadtabelle `tests/tools/assets/art_paths.py`, 24 Werkzeuge umgestellt, Regel in AGENTS.md.

### 2026-11-25 · Claude · Haar/Umhang, Attack Timeline, Zauber-Effekte (`e7c2cc31` bis `3a701c4e` und folgende)
- Gemeinsamer Rig (`rig_mesh`/`rig_draw_frame`) für Drache, Zwillingshexen, Sumpfbehemoth und das Basismodell der Spielfigur: Haar und Umhang federn über Knochen je Zelle (`eqv_bones`, Pipeline `build_characters.py`).
- S1 Attack Timeline (`scripts/attack_timeline`): Schwertkette und Klassen-Kombos laufen als Zeitachsen, Werte unverändert; neue Klassenprüfung (151).
- Zusammengesetzte Pixel-Effekte für 16 von 18 Zaubern (`spell_vfx`: `vfx_*_draw`, `vfx_projectile_draw`, `vfx_area_effect_draw`); Altaufrufe von `spell_fx_burst` übergeben das Band.
- Zwei kaputte Telemetrie-Anker repariert; neue QA-Suite `anchors` (`QA/tools/check_telemetry_anchors.py`). ArtPack: Altbestand nach `_legacy/`, Referenzen nach `references/`.

### 2026-11-25 · Claude · Meilensteine 3 und 4 (`aa35461e` und folgende)
- Meta-Progression mit zwei Punktetöpfen, Elitegegner (`elite_*`), Drachen-Nahangriffe (`dragon_melee_*`), Waffen-Upgrades (`weapon_upgrade_*`, WAFFE-Karten).
- Pixeldichte 1:1: Pipeline `atlas.py` (`DENSITY`/`FRAME`/`OX`/`OY`), Neubau aller Figuren und Ausrüstungen (160 px), `eqv_frame()`, `player_scale` 1.
- Bug gefunden und behoben: `combat_mask()` hatte feste 96er-Koordinaten; jetzt relativ zum Ursprung. QA Stufe 3 PASS.

### 2026-11-25 · Claude · Nutzerentscheidungen und Roadmap-Schritte (Commits `fcc27f13`, `710bb348` und folgende)
- Kamera 960×540 (`VIEW_W/VIEW_H`), Namen Schwertmeister/Arkanistin, dauerhafte Talente (`talent_persistent`, `talent_respec`, Taste R), 164 Legacy-Sprites und `output/` gelöscht.
- Kettenblitz zusammengesetzt in 3 Bändern (`gameplay_polish`), Intensitäts-Bänder für alle Zauber (`spell_v2`, `spell_vfx`), Pixel-Partikel, Tonvariation und Musikabsenkung bei Bosswarnungen (`audio_manager`).
- Drachen-Rig per 2D-Skinning (`dragon_rig_*` in `dragon_boss`), Lebendigkeit der Spielfigur (`player_motion_life`, Ebenen drehen mit), A/B-Vergleich Pixeldichte.
- QA Stufe 3 nach jedem Meilenstein: alle Suiten PASS (Details in den Commit-Texten).

### 2026-11-25 · Claude · Design-Kanon, Audit, Terranigma-Referenz, IDE-Ordnung
- Neuer verbindlicher Kanon `docs/Design/` (11 Dokumente, Vorrang im [[Leitbild]]). `DESIGN/*.md` dorthin verschoben (`Boss-Design.md`, `Progression & Builds.md`), `DESIGN/` entfällt.
- Audit früherer Aufträge (15 Codex-Anhänge, Claude-Prompts) gegen Doku und Code; Widersprüche aufgelöst (Leitbild Abschnitt 6). Gemessen: Bild um 33 % verzerrt (800×600 auf 1280×720), Pixeldichte 0,25–1,65.
- IDE-Ressourcenbaum nach Kategorien (1.381 `.yy`-`parent`, `tests/tools/assets/ide_folders.py`, `gm_project.py` sortiert neue Ressourcen ein). Keine Datei verschoben.
- `AGENTS.md`, `CLAUDE.md`, QA-Agenten, README, Index, Systemnotizen aktualisiert; Export `tests/tools/export_design.py` → `docs/_export/`; 47 versionierte `.pyc` aus Git entfernt.

### 2026-11-24 · Claude · Charaktermodelle + sichtbare Ausrüstung
- Basismodelle aller 3 Klassen ohne Rüstung/Waffe (Frames in `spr_fg_<actor>_*` ersetzt, Originale im ArtPack); Saum der Walk-Frames entfernt.
- 4 Stufen × Kopf/Brust/Hände/Füße/Waffe je Klasse als gepackte Atlanten `spr_eqv_*`, Startwaffe als Ebene, Seltenheit als Akzentfarbe, Item-Icons `spr_eqv_icons_*`.
- Laufzeit `scripts/equipment_visual` (+ generiert `equipment_visual_data`), Pipeline `tests/tools/characters/`, Suite `visual` (75). Details: [[Charaktergrafik & Ausrüstungs-Layer]].

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
