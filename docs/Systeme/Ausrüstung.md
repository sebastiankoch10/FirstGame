---
tags: [system, ausruestung]
updated: 2026-11-24
---
# Ausrüstung

## Zweck
Start ohne Ausrüstung. Gegenstände fallen, werden durch Darüberlaufen aufgenommen und angelegt oder kommen in den Rucksack.

## Wichtige Dateien
- `scripts/equipment/equipment.gml`:
  - Werte: `equipment_config`, Seltenheiten, Wertepools je Slot, `equipment_generate` (eigener RNG)
  - Drops: `equipment_boss_drop`, `equipment_enemy_drop`, `equipment_step`
  - Darstellung: Rucksack-Panel und Tooltip im Charakterbildschirm, HUD-Leiste, Bodenring, Einblendungen (`feedback_toast_*`)
- Icons: `sprites/spr_eq_icons`, erzeugt mit `tests/tools/levels/equip_icons.py`.

## Abhängigkeiten
[[Talente]] (gemeinsamer Bildschirm, `talent_equipment_apply`) · [[Bosse]] (garantierte Drops) · [[Gegner & Spawns]] (0,3 %) · [[Licht, Wetter & Effekte]]

## Bekannte Probleme
- Keine Rüstungsgrafik am Charakter.
- Drop-Raten und Werte sind neue, ungetestete Designwerte.
