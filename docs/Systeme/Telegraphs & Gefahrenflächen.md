---
tags: [system, telegraph, vfx, bosse]
updated: 2026-11-27
---
# Telegraphs & Gefahrenflächen

## Zweck
Ein gemeinsamer Renderer für alle gegnerischen Warnungen und Gefahrenflächen (Bosse, Minibosse, Eliten, Levelgefahren), seit 26.11. (Phase 2A/2B). Regeln (Soll): [[Kampf & Begegnungen]] 5.3–5.9, Leitbild G15.

## Wichtige Dateien
- `scripts/attack_telegraph`: Geometrie `telegraph_make` und Treffertest `telegraph_contains` (Kreis, Ring mit Lücke, Kegel, Linie bzw. Rechteck, Schachbrett `checker`). Gezeichnet wird hier nichts mehr.
- `scripts/hazard_looks` (seit 27.11.): je Gefahrenart Ankündigung (`hz_look_warning`), aktive Darstellung (`hz_look_active`) und Zündung (`hz_look_activate`); wachsende Ringe `hz_ring_at`; `bv2_clear_enc`, `bv2_cadence`. Fällt eine Art nicht darunter, zeichnet der allgemeine Renderer in `hazard_fx`.
- `scripts/hazard_fx`:
  - **Geometrie-Helfer:** `geo_fill`, `geo_fill_band` (Füllung vom Ursprung aus), `geo_edge` (1 oder 2 px), `geo_sample` (gleichmäßige Punkte in der Form), `geo_area`, `geo_checker_cells` (nur sichtbare Zellen, einmal je Bild zwischengespeichert).
  - **Warnungen:**
    - `telegraph_draw` stellt sie in eine Warteschlange.
    - `telegraph_flush` am Ende von `ObjectController/Draw_73` zeichnet sie sortiert nach Zeit bis zum Einschlag (`tg_render`): getönte Gesamtfläche, Füll-Countdown, Fokus-Umriss, Rand und innere Partikel.
    - Spätere Mechaniken erscheinen nur als Umriss.
  - **Aktive Flächen:** `hz_area_draw` (Grundfläche, Randband, Elementpartikel, Abklingen); `hz_particles` und `hz_crackle` (Blitz).
  - **Strahlen und Aufladung:** `vfx_beam_stream` (Strahlen) und `vfx_charge` (Energie sammeln).
  - **Element und Rand:** `hz_element_of` (Element aus Gefahrenart oder Farbe), `hz_edge_width` (2 px bei Höhe `all`).
  - **Budget:** höchstens 1100 Partikel je Bild (`global.hz_budget`), Effektqualität skaliert.
- **Nutzer:**
  - `bv2_hazards_draw` (`scripts/boss_hazards_v2`).
  - `bc_hazard_telegraph` und `bc_hazard_active_draw` (`scripts/boss_choreo`).
  - `dragon_encounter_draw`, Minibosse (`scripts/boss_combat`), Levelgefahren (`scripts/level_world`).
- **Spielerseite:** `vfx_player_target_mark` (`scripts/class_weapons`) statt Gegner-Telegraph.
- **Licht:** `light_flash` (`scripts/atmosphere`) am Schadensereignis, siehe [[Licht, Wetter & Effekte]].
- **Mechaniken aus Phase 2B** (`scripts/boss_choreo`):
  - `bc_field_checker` mit `bc_field_parity`: spielfeldweites Schachbrett als eine Gefahr.
  - `bc_closing_waves`: kontrahierende Ringe.
  - `bc_pressure`, `bc_recovery`, `bc_dragon_far_pick`: Druck nach Entfernung.
  - Treffertest bewegter Ringe mit überstrichenem Band (`sweep_prev` in `bv2_hazard_hit`).

## Abhängigkeiten
[[Bosse]] · [[Licht, Wetter & Effekte]] · [[Klassen & Startwaffen]] · [[Level & Welten]] · [[Review-Center]] (Szenarien `tg.*`, `boss.*`) · [[Tests & QA]]

## Bekannte Probleme
- Die älteren Drachenangriffe (Bullets, Wirbel-Sprite, Meteore) haben eigene Einschlagseffekte; die Fläche liegt jetzt darunter (`hz_area_draw`).
- `tests/class_dragon_harness.gml` muss nach `telegraph_draw` `telegraph_flush()` aufrufen, um Pixel lesen zu können.
- Aufnahmen: `record_scene.py boss --boss-hp 0.7` startet in Bossphase 2 (Schachbrett, Ringe).
