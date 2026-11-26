---
tags: [system, zauber]
updated: 2026-11-26
---
# Zauber & Passiva

## Zweck
18 aktive und 18 passive Fähigkeiten, Stufe 1–9, je 6 Slots. Aktive Zauber lösen automatisch aus.

## Wichtige Dateien
- Daten: `scripts/spell_v2_catalog` (aus `FirstGame_ArtPack/spell_v2/catalog.json`), `scripts/get_spell_data`.
- `scripts/spell_v2`: Werte (`spell_v2_values`), Felder und Mechaniken (`spell_v2_step`), Zeichnung, `progression_try_level`.
- `scripts/spell`: Projektile, `apply_attack_damage`, `learn_spell` (`-2` ist die Waffen-Upgrade-Karte, siehe [[Klassen & Startwaffen]]). Nach den Kollisionsabfragen auf `ObjectBossMonster` prüft `boss_parts_collide` auch Kopf und Hals des Drachen ([[Bosse]]).
- `scripts/cast_spell` ist der ältere Castpfad für 101–106 mit den Objekten `ObjectFireball`, `ObjectIceball` und `ObjectLightningball` (Werte in `projectile_setup`, `scripts/combat_feedback`; Zeichnen über `projectile_draw`).
- `scripts/apply_passives`: setzt die Spielerwerte jeden Frame neu aus den Passiva und danach aus [[Talente]] und [[Ausrüstung]].
- `scripts/spell_choices_v2`: Angebote und Voraussetzungen, z. B. Split Runes nur mit 101, 102 oder 105.
- Weitere: `scripts/spell_ui_v2` (Tooltips und Run-Statistiken), `scripts/hotbar_assign`, `scripts/run_spell_stats`.
- Darstellung (seit 25.11.): alle 18 aktiven Zauber als zusammengesetzte Pixel-Effekte (`scripts/spell_vfx`, `spell_fx_core_draw` in `spell_v2`). Die Intensität folgt der Zauberstufe in drei Bändern (1–3, 4–6, 7–9; `vfx_band`), wirkt nur auf Deckkraft und Glühen, nie auf Trefferradien. Details: [[Licht, Wetter & Effekte]].

## Abhängigkeiten
[[Progression & Level-up]] · [[Licht, Wetter & Effekte]] (`spell_vfx`) · [[UI, HUD & Menüs]] · [[Bosse]] · [[Klassen & Startwaffen]]

## Bekannte Probleme
- Große DPS-Spreizung im Run: Lightning, Iceball und Arcane Barrage liegen weit unter Ice Prison, Ember Field und Gravity Well (`QA/V3_SIMULATION_REPORT.md`). Nur Empfehlung, nichts geändert.
- Die drei Altprojektil-Objekte haben je eine `Collision_ObjectMonster.gml`, die in ihrer `.yy` nicht registriert ist und daher nie läuft ([[Bugs & Ideen]]).
