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
- `scripts/boss_hazards_v2` und `scripts/attack_telegraph`: gemeinsame Gefahren, eine Uhr `v2_clock` je Boss, Countdown am Zonenrand.
- `scripts/boss_choreo`: Muster, Schwenkstrahlen mit 2.600 px, Aufholattacken und die Eskalationsregel `bc_complex`.
- Objekt: `ObjectBossMonster`. Regeln: [[Boss-Design]] und [[Kampf & Begegnungen]] (verbindlich). Test: `tests/boss_harness.gml`.

## Abhängigkeiten
[[Boss-Testmodus]] · [[Spieler & Bewegung]] · [[Licht, Wetter & Effekte]] · [[Ausrüstung]] · [[Talente]]

## Bekannte Probleme
- Der Drache ist ab Minute 10 für Bots sehr schwer: 17 % bzw. 8 % Siege.
- Der Doppelstampfer des Behemoth trifft bedrohte Bots zu 79 %.
- Die älteren Drachenangriffe (Bogen, Bodeneinschlag, Flügelsturm, Void, Wirbel, Salven) nutzen das alte Encounter-System; das Orakel im Boss-Test sieht sie nicht.
