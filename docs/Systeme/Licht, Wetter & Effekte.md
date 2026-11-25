---
tags: [system, effekte]
updated: 2026-11-25
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
- `scripts/attack_telegraph`: Warnflächen mit Countdown (zusammen mit [[Bosse]]).

## Abhängigkeiten
[[Zauber & Passiva]] · [[Bosse]] · [[Level & Welten]] · [[Klassen & Startwaffen]]

## Bekannte Probleme
- Partikel nutzen das globale `random()`. Das ändert die Zufallsfolge geseedeter Runs gegenüber älteren Ständen (siehe [[Bugs & Ideen]]).
