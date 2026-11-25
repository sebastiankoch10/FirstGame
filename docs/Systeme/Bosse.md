---
tags: [system, bosse]
updated: 2026-11-25
---
# Bosse

## Zweck
Zwei Minibosse in Minute 1 und 3. Ab Minute 5 alle 5 Minuten ein zufälliger Hauptboss: Drache, Zwillingshexen oder Sumpfbehemoth, je 9 Fähigkeiten, freigeschaltet 3/6/9.

## Wichtige Dateien
- `scripts/boss_combat`: Zeitplan, Belohnung (Truhe, Orb, Talentpunkt, Ausrüstung), Minibosse, `boss_world_step`.
- `scripts/boss_framework_v2`: Katalog, Freischaltung beim Spawn, Skalierung, Zufallsauswahl (`boss_v2_pick`).
- `scripts/boss_encounters_v2` (Hexen, Behemoth) sowie `scripts/dragon_encounter` und `scripts/dragon_boss` (Drache).
- `scripts/dragon_parts` (seit 25.11.): Drache als Verbund aus Teilen. Körper ohne Kopf, Halsglieder mit Rückenstacheln entlang einer Kurve, Kopf geschlossen oder offen mit 32 vorberechneten Drehstufen. Der Kopf zielt auf den Spieler, beim Feueratem sitzt das Maul exakt auf dem Ursprung des Strahls, beim Biss stößt der Kopf in den angekündigten Sektor. Kopf und Hals sind Trefferformen derselben Einheit (`dragon_parts_distance` in `combat_body_distance`, `boss_parts_collide` für Projektile): eine Lebensleiste, ein Flächentreffer zählt einmal.
  - Teile werden mit `tests/tools/bosses/build_dragon_parts.py` in Spielgröße gebacken (Sprites `spr_drg_*`, Daten `scripts/dragon_parts_data`). Ganze Posen (Stampfen, Sprung, Tod usw.) sind ebenfalls in Spielgröße gebacken (`spr_drg_full_*`).
  - Das frühere Skinning-Rig (`dragon_rig_*`) zeichnet den Drachen nicht mehr; `rig_draw_frame` nutzen weiter Hexen, Behemoth und die Spielfigur.
- Behemoth und Zwillingshexen werden seit 25.11. aus in Spielgröße gebackenen Frames gezeichnet (`spr_bv2b_*`, `tests/tools/bosses/build_boss_baked.py behemoth|twins`); die Rig-Knochen werden mit dem Backfaktor skaliert (`rig_bones_scaled`). Die Hexen kommen dabei aus den Quellbögen (Faktor ≈0,69 statt 0,46 × 1,5) und sind an den alten Frames ausgerichtet.
- `scripts/boss_hazards_v2` und `scripts/attack_telegraph`: gemeinsame Gefahren, eine Uhr `v2_clock` je Boss, Countdown am Zonenrand.
- `scripts/boss_choreo`: Muster, Schwenkstrahlen mit 2.600 px, Aufholattacken und die Eskalationsregel `bc_complex`.
- Objekt: `ObjectBossMonster`. Regeln: [[Boss-Design]] und [[Kampf & Begegnungen]] (verbindlich). Test: `tests/boss_harness.gml`.

## Abhängigkeiten
[[Boss-Testmodus]] · [[Spieler & Bewegung]] · [[Licht, Wetter & Effekte]] · [[Ausrüstung]] · [[Talente]]

## Bekannte Probleme
- Der Drache ist ab Minute 10 für Bots sehr schwer: 17 % bzw. 8 % Siege.
- Der Doppelstampfer des Behemoth trifft bedrohte Bots zu 79 %.
- Die älteren Drachenangriffe (Bogen, Bodeneinschlag, Flügelsturm, Void, Wirbel, Salven) nutzen das alte Encounter-System; das Orakel im Boss-Test sieht sie nicht.
