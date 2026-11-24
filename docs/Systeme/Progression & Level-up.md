---
tags: [system, progression]
updated: 2026-11-24
---
# Progression & Level-up

## Zweck
XP-Münzen, Levelaufstieg, Zauberwahl, Truhen, Magnet-Orb.

## Wichtige Dateien
- `scripts/spell_v2`: `progression_try_level` (zwischen zwei Wahlen mindestens 6 s). Vergibt über `talent_on_level` auch Talentpunkte.
- XP-Kurve über `progression_cost`. Details in `QA/PROJECT_INVENTORY.md`.
- Objekte: `objects/ObjectCoin` (XP-Münze), `ObjectMagnetOrb` (nur von Bossen), `ObjectChest` (Bossbelohnung, löst eine Zauberwahl aus).
- `scripts/handle_chest_selection` leitet an `spell_choices_v2` weiter.
- `scripts/progression_audit`: speichert Messpunkte des Runs als JSON (siehe [[Speichern & Einstellungen]]).

## Abhängigkeiten
[[Zauber & Passiva]] · [[Talente]] · [[Bosse]] (Belohnung) · [[UI, HUD & Menüs]]
