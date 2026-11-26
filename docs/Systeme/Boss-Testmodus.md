---
tags: [system, bosse]
updated: 2026-11-26
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

- Seit 26.11. nutzt auch das [[Review-Center]] diese Start-Pipeline (`boss_test_pending_start` → `review_after_start`). Test- und Review-Sitzungen lesen und schreiben keine Talente mehr (`dev_session_active`).

- F10 zeigt seit 26.11. zusätzlich den Waffen-Ankerpunkt der Spielfigur (Griff cyan, bei verdeckter Hand orange; Linie zur Spitze), siehe [[Charaktergrafik & Ausrüstungs-Layer]].

## Abhängigkeiten
[[Bosse]] · [[Talente]] · [[Ausrüstung]] · [[Zauber & Passiva]] · [[UI, HUD & Menüs]]

## Bekannte Probleme
- Der Menüpunkt ist auch in normalen Builds sichtbar, solange das Makro auf `true` steht.
- Die Build-Voreinstellungen (`boss_test_preset`) sind Entwicklungswerte und weichen von der gemessenen Progression ab.
- **Messung 26.11.** (`QA/tools/analyze_levels.py`; 1080 Bot-Läufe vom 24.11. und 108 Läufe mit aktuellem Code; nur Läufe, die den Zeitpunkt erreichen, daher wenige Fälle ab Minute 15):

  | Minute | Level gemessen (Median alt / neu) | Preset heute | **Vorschlag Level** | Zauberstufen gemessen | Preset `decisions` | **Vorschlag `decisions`** |
  |---|---|---|---|---|---|---|
  | 5 | 18 / 17 | 13 | **17** | ≈19 | 15 | **19** |
  | 10 | 34 / 33 | 23 | **33** | ≈38 | 26 | **38** |
  | 15 | 52 / 52 | 36 | **51** | ≈55 | 40 | **53** |
  | 20 | 71 / 69 | 84 | **70** | ≈79 | 96 | **77** |
  | 25 | 90 / 86 | 94 | **87** | – | 104 | **95** |
  | 30 | 100 / 102 | 102 | **100** | – | 108 | **108** |

  - Klassen: Schwertmeister und Arkanistin liegen gleichauf, der Waldläufer deutlich darunter (Minute 5: 12–14, Minute 10: 20–26). Anfänger-Bots erreichen Minute 5 praktisch nie.
  - Ausrüstung und Talente der Bots: um Minute 5–7 etwa 4 Gegenstände und 4 Talentpunkte, um Minute 10–12 etwa 11 und 10, um Minute 15–17 etwa 13 und 14. Vorschlag für Testcharaktere: ab Minute 10 alle sechs Plätze belegt, Talentpunkte ≈ 0,9 je Minute.
  - **Nicht umgesetzt:** Die Zahlen ändert nur der Nutzer (Balancing-Regel). Das Review-Center übernimmt neue Werte automatisch, weil es dieselbe Tabelle liest.
