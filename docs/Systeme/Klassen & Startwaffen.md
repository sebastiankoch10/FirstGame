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
- `scripts/master_combat`: Schwertkette aus 3 Hieben mit festem Ablauf, `ObjectSwordHitbox`. Talent-Hooks: Druckwelle, Rundumhieb, Sturmangriff, Heilung.
- `scripts/class_weapons`:
  - Magierin-Kombo: Projektil → Bogen → Kreis → Sternenorb
  - Waldläufer-Kombo: 1,1,3,1,1,1,1,1,5,1,1,Hagel
  - Klasseneffekte (`class_effects_*`)
- Projektile laufen über `ObjectLightningball` (Stab und Pfeil).

## Abhängigkeiten
[[Spieler & Bewegung]] · [[Talente]] (Klassenbäume) · [[Ausrüstung]] (Waffenschaden %) · [[Licht, Wetter & Effekte]]

## Bekannte Probleme
- Die QA-Telemetrie braucht exakte Code-Anker in `class_weapons` und `master_combat` (siehe AGENTS.md).
