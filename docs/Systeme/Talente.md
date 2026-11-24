---
tags: [system, talente]
updated: 2026-11-24
---
# Talente

## Zweck
Datengetriebene Talentbäume: ein allgemeiner Baum mit 9 Talenten und je 8 pro Klasse. Charakterbildschirm mit Taste T.

## Wichtige Dateien
- `scripts/talents/talents.gml`:
  - `talent_config` (Punktequelle, `persistent`), `talent_definitions`
  - Regeln: `talent_block_reason`, `talent_invest`, `talent_stat`
  - Wirkung: `talent_equipment_apply`, Oberfläche: `talent_menu_*`
  - Bots: `talent_bot_invest`
- Klassenmechaniken in `scripts/master_combat` und `scripts/class_weapons`.
- Vollständige Doku: `DESIGN/TALENTS_AND_EQUIPMENT.md`. Test: `tests/feature_harness.gml`.

## Abhängigkeiten
[[Zauber & Passiva]] (`apply_passives`) · [[Klassen & Startwaffen]] · [[Ausrüstung]] (gemeinsamer Bildschirm) · [[UI, HUD & Menüs]] · [[Progression & Level-up]]

## Offene Entscheidungen
- Pro Run oder dauerhaft?
- Punktetempo
- Respec
- Zahlenwerte (neue Designwerte, nicht ausbalanciert)
