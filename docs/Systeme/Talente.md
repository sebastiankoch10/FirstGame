---
tags: [system, talente]
updated: 2026-11-26
---
# Talente

## Zweck
Datengetriebene Talentbäume: ein allgemeiner Baum mit 9 Talenten und je 8 pro Klasse. Charakterbildschirm mit Taste T.

## Wichtige Dateien
- `scripts/talents/talents.gml`:
  - `talent_config` (Punktequelle, `persistent`), `talent_definitions`
  - Regeln: `talent_block_reason`, `talent_invest`, `talent_stat` (addiert auch die Waffen-Upgrades über `weapon_upgrade_stat`, siehe [[Klassen & Startwaffen]])
  - Wirkung: `talent_equipment_apply`, Oberfläche: `talent_menu_*`
  - Bots: `talent_bot_invest`
- Klassenmechaniken in `scripts/master_combat` und `scripts/class_weapons`.
- Design und vollständige Doku: [[Progression & Builds]]. Test: `tests/feature_harness.gml`.

- Seit 26.11. liefert `talent_persistent()` in Test- und Review-Sitzungen false (`dev_session_active`), damit dort nichts in `firstgame_talents.ini` landet.

## Abhängigkeiten
[[Zauber & Passiva]] (`apply_passives`) · [[Klassen & Startwaffen]] · [[Ausrüstung]] (gemeinsamer Bildschirm) · [[UI, HUD & Menüs]] · [[Progression & Level-up]]

## Persistenz
- Seit 2026-11-25 gibt es zwei Punkte-Töpfe: Punkte von Hauptbossen sind dauerhaft (`talent_ranks_meta`, je Klasse in `firstgame_talents.ini`, nur im Projekt „FirstGame“), Punkte aus Levelaufstiegen gelten nur im laufenden Run. Minibosse geben derzeit 0 Punkte (`miniboss_points`).
- `talent_persistent()`, `talent_respec()` per Taste R. Speicherort: [[Speichern & Einstellungen]].

## Offene Entscheidungen
- Entschieden am 25.11.: dauerhaft (nur Hauptboss-Punkte) und Respec per Taste R, siehe „Persistenz“ und [[DECISIONS]].
- Punktetempo
- Zahlenwerte (neue Designwerte, nicht ausbalanciert)
