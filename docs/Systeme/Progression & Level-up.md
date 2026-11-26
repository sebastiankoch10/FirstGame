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
  - **Münz-Culling** (seit 26.11., `coin_cull_step` in `scripts/combat_feedback`, Aufruf in `ObjectController/Step_0`): Münzen verfallen nie und haben keine Obergrenze. Alle 10 Bilder werden Münzen außerhalb von Bildausschnitt plus Rand (mindestens 260 px, mindestens der Sammelradius) deaktiviert und im Ausschnitt wieder aktiviert. Wert, Position und Anzahl bleiben gleich; `magnet_collect` und `reset_round` aktivieren zuerst alle Münzen. Gemessen mit 2.500 liegenden Münzen: 56,7 → 66,7 FPS unbegrenzt. Wichtig für neuen Code: `instance_number(ObjectCoin)` und `with(ObjectCoin)` sehen nur aktive Münzen; wer alle braucht, ruft vorher `instance_activate_object(ObjectCoin)` auf.
- `scripts/handle_chest_selection` leitet an `spell_choices_v2` weiter.
- **Waffen-Upgrades** (seit 25.11.): `spell_choices_v2` mischt die Karte „<Waffe> verbessern“ (`id -2`) ins Level-up- und Truhenangebot, solange die Startwaffe unter Stufe 5 ist. `learn_spell(-2)` ruft `weapon_upgrade_take` auf, Detailansicht `weapon_upgrade_detail_draw` (`scripts/spell_ui_v2`). Siehe [[Klassen & Startwaffen]].
- Talentpunkte: Nur Punkte von Hauptbossen bleiben dauerhaft, Punkte aus Levelaufstiegen gelten nur im Run (`talent_on_level`, siehe [[Talente]]).
- `scripts/progression_audit`: speichert Messpunkte des Runs als JSON (siehe [[Speichern & Einstellungen]]).

## Abhängigkeiten
[[Zauber & Passiva]] · [[Talente]] · [[Bosse]] (Belohnung) · [[UI, HUD & Menüs]] · [[Klassen & Startwaffen]] (Waffen-Upgrades)

## Bekannte Probleme
- `progression_audit` schreibt im normalen Spiel an 11 festen Zeitpunkten je Run (Minute 1 bis 30) eine kleine JSON-Datei. Das ist gewollt, denn so entstehen Messdaten echter Läufe für die Kalibrierung. Geprüft am 26.11.: kein Leistungsproblem, Entwicklungssitzungen schreiben nichts.
- Die Werte der Waffen-Upgrades sind neue, ungetestete Designwerte.
