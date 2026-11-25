---
tags: [system, klassen]
updated: 2026-11-25
---
# Klassen & Startwaffen

## Zweck
Drei Klassen mit eigener automatischer Startwaffe: Schwertmeister (`Sword`), Arkanistin (`Mage`), Waldläufer (`Ranger`); Anzeigenamen in `menu_labels` (`scripts/gameplay`). Die Startwaffe belegt keinen Zauberslot.

## Wichtige Dateien
- `scripts/reset_round`: Basiswerte (Schwert 120 HP / Tempo 3,2 / Power 2; Magierin 70 / 2,8 / 4; Waldläufer 82 / 4,2 / 1).
- `scripts/gameplay`: `weapon_definition`, `weapon_auto_step`.
- `scripts/attack_timeline` (seit 25.11.): Zeitachsen der Startwaffen (`atl_definitions`, `atl_get`, `atl_due`, `atl_frame`, `atl_time`). Schwertkette `sword_chain`, Kombostufen `mage_1`…`mage_4`, `ranger_light|heavy|finisher`.
- `scripts/master_combat`: Schwertkette aus 3 Hieben, läuft als Zeitachse `sword_chain` auf `sword_combo_clock` (Cursor `sword_combo_event`); Körperpose über `master_sword_frame` aus denselben Ereignissen. `ObjectSwordHitbox`. Talent-Hooks: Druckwelle, Rundumhieb, Sturmangriff, Heilung. Hiebe seit 25.11. als Pixel-Halbmond (`vfx_slash_draw`, `vfx_slash_strip`) statt gestreckter `spr_master_slash_*`; Seltenheit der Waffe färbt den Rand.
- `scripts/class_weapons`:
  - Magierin-Kombo: Projektil → Bogen → Kreis → Sternenorb
  - Waldläufer-Kombo: 1,1,3,1,1,1,1,1,5,1,1,Hagel
  - Klasseneffekte (`class_effects_*`), seit 25.11. als Pixel-Komposite: `vfx_arc_sweep` (Bogen), `vfx_magic_circle` (Kreis), `vfx_star_orb` und `vfx_class_burst` (Sternenorb, Detonation), `vfx_arrow_fall`/`vfx_arrow_hit` (Hagel). `class_fx_sprite` wird von den Klassen nicht mehr benutzt.
  - Kombostufe → Zeitachse über `class_weapon_timeline` (Stufe, Körperdauer, Auslösezeitpunkt)
- Projektile laufen über `ObjectLightningball` (Stab und Pfeil).

## Abhängigkeiten
[[Spieler & Bewegung]] · [[Talente]] (Klassenbäume) · [[Ausrüstung]] (Waffenschaden %) · [[Licht, Wetter & Effekte]]

## Bekannte Probleme
- Die QA-Telemetrie braucht exakte Code-Anker in `class_weapons` und `master_combat` (siehe AGENTS.md).
