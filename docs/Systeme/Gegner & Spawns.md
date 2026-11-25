---
tags: [system, gegner]
updated: 2026-11-25
---
# Gegner & Spawns

## Zweck
Normale Gegner, Bevölkerungssteuerung und Tod (Münze, Ausrüstungs-Drop).

## Wichtige Dateien
- `objects/ObjectMonster`: Tod, Brennen, Schritt. `Room1` nutzt `master_skeleton`, die anderen Level `lvl_kind`.
- `scripts/master_skeleton`: die Skelettfamilie des Walds (Krieger, Späher, Wache).
- `scripts/level_worlds`: Gegnerarten von Sumpf und Ruinen (`level_enemy_kinds`, `level_enemy_step`).
  - Seit 25.11. Pixeldichte 1:1 für Kriecher, Pilzkreatur, Eisgeist, Konstrukt: Feld `baked` in der Gegnerart, Pipeline `tests/tools/levels/enemies.py` (`creature_spec` liest `scale` aus `level_worlds`), Zeichnen mit `monster_scale/monster_art_div()` (`enemy_draw`, `elite_outline_draw`, Überreste). Skelettbasierte Gegner bleiben gestreckt, bis es neue Grafik gibt.
- `scripts/survivor_balance`: `population_profile` und `population_step`, Zielanzahl über die Zeit, technisches Limit 180.
- `scripts/gameplay`: `enemy_pursue` (Verfolgung, Trennung, Schweben).
- Objekte: `ObjectSpawner`, `ObjectSkeletonRemains`.

## Abhängigkeiten
[[Level & Welten]] · [[Progression & Level-up]] · [[Ausrüstung]] · [[Bosse]] (Brut, Zwillings-Akteur)

## Bekannte Probleme
- Asset-Namenskollision: Ein bloßes `master_skeleton` ist das Skript, nicht die Variable. Immer `self.master_skeleton` schreiben.
