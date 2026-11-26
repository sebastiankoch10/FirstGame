---
tags: [system, ausruestung]
updated: 2026-11-26
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

- Nicht verwechseln: Die Waffen-Upgrades der Startwaffe (Level-up-Karten) sind keine Ausrüstung, siehe [[Klassen & Startwaffen]].
- Sichtbarkeit am Charakter und Item-Icons: [[Charaktergrafik & Ausrüstungs-Layer]] (`scripts/equipment_visual`, `equipment_item_icon`).

## Abhängigkeiten
[[Talente]] (gemeinsamer Bildschirm, `talent_equipment_apply`) · [[Bosse]] (garantierte Drops) · [[Gegner & Spawns]] (0,3 %) · [[Licht, Wetter & Effekte]] · [[Charaktergrafik & Ausrüstungs-Layer]]

## Bekannte Probleme
- Ausrüstung ist sichtbar (Basismodell + Layer; seit 25.11. Pixeldichte 1:1 und Helme als Kopf-Komposit). Grenzen siehe [[Charaktergrafik & Ausrüstungs-Layer]].
- Drop-Raten und Werte sind neue, ungetestete Designwerte.
