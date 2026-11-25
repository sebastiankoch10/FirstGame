---
tags: [system, bosse]
updated: 2026-11-25
---
# Boss-Testmodus

## Zweck
Entwicklermenü „Testmodus“ im Hauptmenü (bis 25.11. „Boss testen“). Zwei Modi, umschaltbar in der ersten Zeile.

## Wichtige Dateien
- `scripts/boss_test_mode`:
  - **Bosskampf:** Boss oder Zufallsboss, Minute, Klasse, Build, Schwierigkeit, Einzelangriff, Seed; Direktstart „Drache / Minute 15 / alle neun“.
  - **Freie Szene** (seit 25.11.): Level, Spielminute (0–30), Klasse, Build (leer, ausgewogen, zufällig), ein zusätzlicher Zauber auf Stufe 1/3/5/7/9, volle Ausrüstung (magisch, selten, episch), Gegner normal oder keine. Ohne geplante Bosse. Funktionen `scene_test_start`, `scene_test_pending_start`, `scene_test_spells`.
- Tasten im Test:
  - F1 Unverwundbarkeit, F2 Heilen, F3 Phase, F4 Boss-HP 25 %, F5 Attacke
  - F6 Attacke wechseln, F7 Aufholattacke, F8 +5 Talentpunkte, F9 Testgegenstand, F10 Körperboxen
  - In der freien Szene gelten F1, F2, F8, F9, F10.
- Schalter: `#macro BOSS_TEST_MENU_ENABLED true`.

## Abhängigkeiten
[[Bosse]] · [[Talente]] · [[Ausrüstung]] · [[Zauber & Passiva]] · [[UI, HUD & Menüs]]

## Bekannte Probleme
- Der Menüpunkt ist auch in normalen Builds sichtbar, solange das Makro auf `true` steht.
- Die Build-Voreinstellungen sind Entwicklungswerte (Spielerstufe je Minute), keine gemessene Progression.
