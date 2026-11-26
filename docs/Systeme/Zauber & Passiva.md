---
tags: [system, zauber]
updated: 2026-11-26
---
# Zauber & Passiva

## Zweck
18 aktive und 18 passive Fähigkeiten, Stufe 1–9, je 6 Slots. Aktive Zauber lösen automatisch aus.

## Wichtige Dateien
- Daten: `scripts/spell_v2_catalog` (aus `FirstGame_ArtPack/vfx/spell_v2/catalog.json`), `scripts/get_spell_data`.
- `scripts/spell_v2`: Werte (`spell_v2_values`), Felder und Mechaniken (`spell_v2_step`), Zeichnung, `progression_try_level`.
- `scripts/spell`: Projektile, `apply_attack_damage`, `learn_spell` (`-2` ist die Waffen-Upgrade-Karte, siehe [[Klassen & Startwaffen]]). Nach den Kollisionsabfragen auf `ObjectBossMonster` prüft `boss_parts_collide` auch Kopf und Hals des Drachen ([[Bosse]]).
- `scripts/cast_spell` ist der ältere Castpfad für 101–106 mit den Objekten `ObjectFireball`, `ObjectIceball` und `ObjectLightningball` (Werte in `projectile_setup`, `scripts/combat_feedback`; Zeichnen über `projectile_draw`).
- `scripts/apply_passives`: setzt die Spielerwerte jeden Frame neu aus den Passiva und danach aus [[Talente]] und [[Ausrüstung]].
- `scripts/spell_choices_v2`: Angebote und Voraussetzungen, z. B. Split Runes nur mit 101, 102 oder 105.
- Weitere: `scripts/spell_ui_v2` (Tooltips und Run-Statistiken), `scripts/hotbar_assign`, `scripts/run_spell_stats`.
- Darstellung (seit 25.11.): alle 18 aktiven Zauber als zusammengesetzte Pixel-Effekte (`scripts/spell_vfx`, `spell_fx_core_draw` in `spell_v2`). Die Intensität folgt der Zauberstufe in drei Bändern (1–3, 4–6, 7–9; `vfx_band`), wirkt nur auf Deckkraft und Glühen, nie auf Trefferradien. Details: [[Licht, Wetter & Effekte]].

- **Seit 26.11. mehrphasig:** Donnersiegel und Sonnenurteil sammeln Energie am Zielpunkt (`vfx_charge` in `vfx_pillar_draw`) und lösen beim Schadensereignis Licht nach Band aus (`spell_v2_step`, Fall `seal`/`verdict`). Review: `spell.seal.l1|l5|l9`.

- Seit 26.11. ebenfalls mehrphasig, ohne Timing-Änderung: Steinstacheln, Sternenfall (Sammeln am nächsten Einschlagspunkt während der bestehenden Wartezeit) und Prismensamen; Licht am Schadensereignis über `spell_impact_light` (Band 0 Puls, 1–2 Blitz).

- **Grundstufe gegen Leitbild G17 geprüft (26.11.):**
  - Aufnahme: `record_scene.py spellsheet --spell-level 1 --level 0`, je Zauber 0,25 / 0,75 / 1,25 s nach dem Wirken.
  - Ergebnis: Keine Grundstufe ist zu dominant, keine Darstellung wurde zurückgenommen. Das ist eine technische Prüfung; das künstlerische Urteil macht der Nutzer.

  | Zauber | Stufe 1 |
  |---|---|
  | Feuerball, Eisball, Arkane Salve, Kreisklingen, Irrlicht, Glaive, Prismensamen | klein und kompakt (Projektil, Funken, Einschlag unter ~60 px) |
  | Frostnova | größte Fläche: weiche Scheibe ~200 px um die Figur (~7 % des Bilds), nach unter 0,75 s verblasst; vertretbar |
  | Heilpuls, Glutfeld | schwacher Ring bzw. warmer Fleck am Ziel, kompakt |
  | Steinstacheln | kleine Sammelfunken und Einschlag, sehr dezent |
  | Blitz, Durchbohrende Lanze, Donnersiegel, Sternenfall, Gravitationsbrunnen, Eisgefängnis, Sonnenurteil | zu den Messzeitpunkten kaum sichtbar (kurz oder sehr zurückhaltend). Eher zu wenig als zu viel; zur künstlerischen Beurteilung durch den Nutzer |

- **Grafik-Overhaul (26.11. abends, Schaustück):** Feuerball, Eisball und Kettenblitz nutzen die neuen Bausteine.
  - Spuren über `fxp_trail` in `spell_projectile_step`.
  - Einschläge über `fxp_impact` in `spell_projectile_hit` bzw. `chain_segment_add`. Im Endgame-Band kommen Farbumschlag (Feuerball) bzw. Farbversatz (Blitz) dazu.
  - Die übrigen 15 Zauber folgen nach dem Urteil des Nutzers ([[Visuelles Leitbild & Animation]] 7.4).

## Abhängigkeiten
[[Progression & Level-up]] · [[Licht, Wetter & Effekte]] (`spell_vfx`) · [[UI, HUD & Menüs]] · [[Bosse]] · [[Klassen & Startwaffen]]

## Bekannte Probleme
- Große DPS-Spreizung im Run: Lightning, Iceball und Arcane Barrage liegen weit unter Ice Prison, Ember Field und Gravity Well (`QA/V3_SIMULATION_REPORT.md`). Nur Empfehlung, nichts geändert.
- Die drei Altprojektil-Objekte haben je eine `Collision_ObjectMonster.gml`, die in ihrer `.yy` nicht registriert ist und daher nie läuft ([[Bugs & Ideen]]).
