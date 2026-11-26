---
tags: [system, spieler]
updated: 2026-11-26
---
# Spieler & Bewegung

## Zweck
Steuerung, Bewegung, Sprung, Sturz, Slide und Ausweichrolle, Treffer am Spieler, Klassensprites.

## Wichtige Dateien
- `objects/ObjectPlayer`:
  - Bewegung mit WASD oder Pfeiltasten, Sprung mit Leertaste, Ausweichrolle mit Strg, Maussteuerung nach Freigabe
  - Draw: Schatten, Ausrüstungsring, Sprite
- `scripts/gameplay_polish`: `movement_config` und `movement_step` (Sprung 0,66 s, Sturz im Scheitelfenster, Slide, Ausweichrolle mit 1,5 s Abklingzeit), Lebensleiste über dem Kopf, Minimap.
- `scripts/gameplay`:
  - `player_combat_init`
  - `player_receive_damage`: Schutz nach Höhe (Boden, hoch, alle), Rüstung, Schadensreduktion, Überlebenswille
  - `player_contact`
- `scripts/player_artpack`: Sprites `swordsmanv3`, `magev3`, `rangerv3` in 8 Richtungen.
- `scripts/spell_world_v2`: `scenery_resolve` und `scenery_point_blocked` (Kollision mit der Szenerie).

## Abhängigkeiten
[[Klassen & Startwaffen]] · [[Talente]] (Ausweich-Abklingzeit, Überlebenswille) · [[Ausrüstung]] · [[Level & Welten]] (Schlamm und Eis bremsen) · [[Bosse]] (Wurzeln, Gift)

## Bekannte Probleme
- Ausrüstung ist seit 2026-11-24 als Ebenen sichtbar ([[Charaktergrafik & Ausrüstungs-Layer]]).
- Keine Sekundärbewegung (Haar, Umhang) und keine Übergangsposen; Idle ist ein Frame mit Atembewegung. Soll: [[Visuelles Leitbild & Animation]].
- Kamera seit 2026-11-25: `VIEW_W`×`VIEW_H` = 960×540 (16:9, Makros in `scripts/gameplay`). Vorher 800×600, horizontal um 33 % verzerrt. Siehe R1 in [[Technische Architektur]].
- Die Kamera steht seit 25.11. abends auf ganzen Weltpixeln (`round` in `ObjectPlayer` Step), damit Ebenen nicht gegeneinander flimmern. Ausgabe über [[Rendering & Pixelraster]].
- Die Treffer-Höhen (`ground`, `high`, `all`) entscheiden über Sprung, Slide und Ausweichen. Bei neuen Angriffen bewusst wählen.
