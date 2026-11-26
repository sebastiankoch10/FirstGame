---
tags: [system, gegner]
updated: 2026-11-26
---
# Gegner & Spawns

## Zweck
Normale Gegner, Bevölkerungssteuerung und Tod (Münze, Ausrüstungs-Drop).

## Wichtige Dateien
- `objects/ObjectMonster`: Tod, Brennen, Schritt. `Room1` nutzt `master_skeleton`, die anderen Level `lvl_kind`.
- `scripts/master_skeleton`: die Skelettfamilie des Walds (Krieger, Späher, Wache).
  - Seit 26.11. wird das Sprite nur neu gesucht, wenn Aktion oder Richtung wechseln (vorher Textsuche je Bild), und `player_visual_direction` nutzt ein statisches Richtungs-Array.
  - Vorbereitet für neue Grafik in Pixeldichte 1:1: `master_skeleton_prefix` nutzt Rollen-Sets `spr_master_skeleton_<rolle>_*`, sobald sie existieren, und zeichnet sie unskaliert (`skeleton_baked` → `monster_art_div`, auch für Überreste). Anforderungen in [[Assets & Pipeline]] 7.5.
- **Trefferstopp** (seit 26.11., `hit_reaction` und `enemy_hitstop_begin`/`_end` in `scripts/combat_feedback`): Bei physischen Treffern der Grundwaffe (nicht Arkanistin, nicht Bosse) friert das Gegnerbild `HITSTOP_FRAMES` = 2 Bilder ein und zittert 1 px. Das ist rein visuell; Position, Stun und Rückstoß laufen weiter. Nach jedem Trefferstopp folgt eine Sperre von 0,1 s.
- `scripts/level_worlds`: Gegnerarten von Sumpf und Ruinen (`level_enemy_kinds`, `level_enemy_step`).
  - Seit 25.11. Pixeldichte 1:1 für Kriecher, Pilzkreatur, Eisgeist, Konstrukt: Feld `baked` in der Gegnerart, Pipeline `tests/tools/levels/enemies.py` (`creature_spec` liest `scale` aus `level_worlds`), Zeichnen mit `monster_scale/monster_art_div()` (`enemy_draw`, `elite_outline_draw`, Überreste). Skelettbasierte Gegner bleiben gestreckt, bis es neue Grafik gibt.
- `scripts/survivor_balance`: `population_profile` und `population_step`, Zielanzahl über die Zeit, technisches Limit 180.
  - **Elitegegner** (seit 25.11., `elite_*`): `population_spawn_enemy` macht ab Minute 3 jeden 60. Gegner zur Elite (mehr Leben, Schaden und Größe, goldener Umriss `elite_outline_draw`). Abwechselnd mit Sprungangriff oder Giftlache beim Tod, beide über die gemeinsamen Bossgefahren `bv2_*` (Warnung und Countdown wie bei Bossen, [[Bosse]]). Beim Tod 10 % Chance auf Ausrüstung ([[Ausrüstung]]). Werte in `elite_config`.
- `scripts/gameplay`: `enemy_pursue` (Verfolgung, Trennung, Schweben).
  - Leistung (26.11.): Die Trennung nutzt eine gemeinsame Nachbarliste (`global.enemy_neighbors`, je Abfrage geleert) statt einer neuen `ds_list` pro Gegner und Bild. Der größte Posten war die Szenerie-Kollision (`scenery_resolve`, zweimal je Gegner), jetzt mit Zellindex ([[Spieler & Bewegung]]). Messung mit 148 Gegnern: unbegrenzt 64–66 → 73–75 FPS, P95 der Bildzeit 19,5 → 17,0 ms. Verhalten unverändert.
- Objekte: `ObjectSpawner`, `ObjectSkeletonRemains`.

- **Bewegungsidentität** (seit 26.11., Schalter `#macro ENEMY_MOTION_ENABLED`): `enemy_motion_profile` und `enemy_motion_offset` (`scripts/level_worlds`), ganzpixelige Versätze je Art mit Ausholen und Vorstoß. Wird in `enemy_draw` und `elite_outline_draw` angewendet (`motion_dx`, `motion_dy`).

- **Wald-Skelette (seit 26.11.):** Bewegungsprofile je Rolle (`forest_warrior` steif-ruckig, `forest_scout` schnell und vorgebeugt, `forest_guard` schwer), Ausholen und Vorstoß im Schlagfenster 0,20–0,36 s, Klappern mit Rückstoß bei Treffern, kurzes Knochenrasseln im Stand. Die Laufanimation läuft je Rolle mit 13, 10 bzw. 7,5 Bildern/s (`master_skeleton_step`). Verhalten und Werte unverändert.

## Abhängigkeiten
[[Level & Welten]] · [[Progression & Level-up]] · [[Ausrüstung]] · [[Bosse]] (Brut, Zwillings-Akteur)

## Bekannte Probleme
- Asset-Namenskollision: Ein bloßes `master_skeleton` ist das Skript, nicht die Variable. Immer `self.master_skeleton` schreiben.
- Skelett-Gegner sind noch nicht in Pixeldichte 1:1; dafür braucht es neue Grafik ([[Roadmap & Vertical Slice]]).
- Die Elite-Werte sind neue, ungetestete Designwerte.
