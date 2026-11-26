---
tags: [system, progression]
updated: 2026-11-26
---
# Progression & Level-up

## Zweck
XP-Münzen, Levelaufstieg, Zauberwahl, Truhen, Magnet-Orb.

## Wichtige Dateien
- `scripts/spell_v2`: `progression_try_level` (zwischen zwei Wahlen mindestens 6 s). Vergibt über `talent_on_level` auch Talentpunkte.
- XP-Kurve über `progression_cost`. Details in `QA/PROJECT_INVENTORY.md`.
- Objekte: `objects/ObjectCoin` (XP-Münze), `ObjectMagnetOrb` (nur von Bossen), `ObjectChest` (Bossbelohnung, löst eine Zauberwahl aus).
- `scripts/handle_chest_selection` leitet an `spell_choices_v2` weiter.
- **Waffen-Upgrades** (seit 25.11.): `spell_choices_v2` mischt die Karte „<Waffe> verbessern“ (`id -2`) ins Level-up- und Truhenangebot, solange die Startwaffe unter Stufe 5 ist. `learn_spell(-2)` ruft `weapon_upgrade_take` auf, Detailansicht `weapon_upgrade_detail_draw` (`scripts/spell_ui_v2`). Siehe [[Klassen & Startwaffen]].
- Talentpunkte: Nur Punkte von Hauptbossen bleiben dauerhaft, Punkte aus Levelaufstiegen gelten nur im Run (`talent_on_level`, siehe [[Talente]]).
- `scripts/progression_audit`: speichert Messpunkte des Runs als JSON (siehe [[Speichern & Einstellungen]]).

## Abhängigkeiten
[[Zauber & Passiva]] · [[Talente]] · [[Bosse]] (Belohnung) · [[UI, HUD & Menüs]] · [[Klassen & Startwaffen]] (Waffen-Upgrades)

## Bekannte Probleme
- `progression_audit` schreibt in jedem Run eine JSON-Datei, auch im normalen Spiel ([[Bugs & Ideen]]).
- Die Werte der Waffen-Upgrades sind neue, ungetestete Designwerte.
