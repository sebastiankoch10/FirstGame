---
tags: [system, effekte]
updated: 2026-11-26
---
# Licht, Wetter & Effekte

## Zweck
Multiplikatives Weltlicht, Wetter, Kampf-Feedback, Zauberpartikel.

## Wichtige Dateien
- `scripts/atmosphere`:
  - Lichtoberfläche in halber Auflösung, `light_pulse`, `atmosphere_source` (Budget 72 Quellen)
  - Boss-Navigation und Notfall-Teleport
- `scripts/weather`: Nebel, Regen und Wind je Level.
- `scripts/spell_vfx`: begrenzter Partikelpool (420), Spuren, Feld-Emitter, dauerhafte Zauberlichter.
  - Pixel-Bausteine `vfx_pixel_ring|shard|streak`, `vfx_px`, Elementpaletten `vfx_palette` (dunkler Rand, Körper, heller Kern).
  - Seit 25.11. zusammengesetzte Effekte je Zauber, aufgerufen aus `spell_v2_draw`: `vfx_lance_draw`, `vfx_orbit_draw`, `vfx_glaive_draw`, `vfx_gravity_draw`, `vfx_pillar_draw` (Donnersiegel, Sonnenurteil), `vfx_ember_field_draw`. Band über `vfx_field_band`.
  - Projektile über `vfx_projectile_draw` (aus `projectile_draw`), Flächeneffekte aus `effect_add(..., style)` über `vfx_area_effect_draw` (Stile `nova`, `heal`, `fire`). Irrlicht `vfx_wisp_draw`, Prismensamen `vfx_seed_draw`. Hilfen `vfx_pixel_line`, `vfx_glow_line`, `vfx_glow_disc`.
- `scripts/combat_feedback`: Schadenszahlen (seit 25.11. Pixelschrift `world_font()` aus `spr_font_world`, erzeugt mit `tests/tools/art/build_pixel_font.py`), Einschläge, Trefferreaktion.
- Drachenfeuer als Pixel-Komposite in `scripts/dragon_boss`: `vfx_fire_tongue` (Strahl, Schwenk), `vfx_fire_cone` (Feuerbogen, füllt genau den Sektor).
- Übrige Drachen-Effekte über `dragon_fx_sprite` (`scripts/dragon_encounter`) als Pixel-Komposite: `vfx_meteor`, `vfx_eruption` (Einschlag, Magma), `vfx_wind_blade`, `vfx_void_orb`, `vfx_fire_bolt`, `vfx_vortex`. Klassen-Projektile über `class_fx_sprite`: `vfx_arcane_bolt`, `vfx_arrow_shot`, `vfx_dust_puff`.
- Hexen- und Sumpf-Effekte über `bv2_fx` (`scripts/boss_hazards_v2`): `vfx_element_orb` (Geschosse, Perlen), `vfx_element_burst` (Flächen; Feuer, Eis, Säure, Erde). Die Hexen-Projektile sind ebenfalls Pixel-Kugeln. Gemalte Effekt-Sheets werden nirgends mehr skaliert gezeichnet.
- `vfx_pixel_line` zeichnet seit 25.11. ein einzelnes Linien-Primitiv (im Weltraster pixelgenau).
- **Effektqualität** `vfx_quality` (0 Niedrig, 1 Mittel, 2 Hoch; `vfx_quality_cycle`, gespeichert in `firstgame_settings.ini`, siehe [[Speichern & Einstellungen]]): steuert Partikelanteil, Poolgröße und Glühen. `vfx_secondary_motion` (Haare, Umhang, Boss-Rigs) ab Mittel.
- **Intensitätsbänder** in `scripts/gameplay_polish`: `vfx_band` teilt Zauberstufen in 1–3, 4–6, 7–9; `vfx_band_alpha` (0,55 / 0,8 / 1) wirkt nur auf Deckkraft und Glühen. `global.vfx_band_override` erzwingt ein Band für Vorschauen und Tests. Dort auch der Kettenblitz (`chain_segment_add`) und `vfx_hash` (deterministischer Zufall ohne globalen RNG).
- `scripts/attack_telegraph`: Warnflächen mit Countdown (zusammen mit [[Bosse]]).

- **Seit 26.11. (Phase 2A):**
  - Gegnerwarnungen und Gefahrenflächen zeichnet [[Telegraphs & Gefahrenflächen]] (`scripts/hazard_fx`).
  - `light_flash` (starker kurzer Lichtblitz, Glanz, Anhebung der Umgebung; Einstellung `blitze`) neben `light_pulse`.
  - Aufladelicht am Drachenmaul in `atmosphere_draw`.

## Abhängigkeiten
[[Zauber & Passiva]] · [[Bosse]] · [[Level & Welten]] · [[Klassen & Startwaffen]] · [[Rendering & Pixelraster]] · [[Speichern & Einstellungen]]

## Bekannte Probleme
- Partikel nutzen das globale `random()`. Das ändert die Zufallsfolge geseedeter Runs gegenüber älteren Ständen (siehe [[Bugs & Ideen]]).
