---
tags: [system, bosse]
updated: 2026-11-24
---
# Boss-Testmodus

## Zweck
Entwicklermenü „Boss testen“ im Hauptmenü.

## Wichtige Dateien
- `scripts/boss_test_mode`:
  - Menü: Boss oder Zufallsboss, Minute, Klasse, Build, Schwierigkeit, Einzelangriff, Seed
  - Direktstart: „Drache / Minute 15 / alle neun“
- Tasten im Test:
  - F1 Unverwundbarkeit, F2 Heilen, F3 Phase, F4 Boss-HP 25 %, F5 Attacke
  - F6 Attacke wechseln, F7 Aufholattacke, F8 +5 Talentpunkte, F9 Testgegenstand, F10 Körperboxen
- Schalter: `#macro BOSS_TEST_MENU_ENABLED true`.

## Abhängigkeiten
[[Bosse]] · [[Talente]] · [[Ausrüstung]] · [[UI, HUD & Menüs]]

## Bekannte Probleme
- Der Menüpunkt ist auch in normalen Builds sichtbar, solange das Makro auf `true` steht.
