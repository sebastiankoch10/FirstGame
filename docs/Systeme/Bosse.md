---
tags: [system, bosse]
updated: 2026-11-26
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
  - Seit 26.11. choreografierte Sequenzen ([[Boss-Design]] H2): Daten in `bc_sequences`, Entscheidung über `bc_seq_decide`. Der Boss spielt nach je 2 regulären Angriffen eine Sequenz, als faire Pause dient `bc_owner_busy` plus `seq_gap`, nach der Sequenz ruht er `seq_rest` (`bc_seq_recovery`). Pilot ist der Drache, angebunden in `dragon_encounter_step`. Die Testanzeige zeigt „Sequenz Name n/m“, das Review-Szenario-Feld `sequence` erzwingt eine Sequenz.
  - Bewegungsidentität von Hexen und Behemoth beim Aufladen und Einschlag: `bv2_motion_offset` in `scripts/boss_encounters_v2`. Das ist nur Darstellung.
- Objekt: `ObjectBossMonster`. Regeln: [[Boss-Design]] und [[Kampf & Begegnungen]] (verbindlich). Test: `tests/boss_harness.gml`.

- **Seit 26.11. (Phase 2A/2B):**
  - Druck nach Entfernung (`bc_pressure`, schnellere Annäherung, kürzere Erholung, Aufholen nach 1,2 s, Abklingzeit 9 s, Fern-Pool des Drachen).
  - Spielfeldweites Schachbrett (Hexen 3, Drache 3, komplexe Varianten).
  - Kontrahierende Feuerringe (Drache 8, komplex).
  - Feueratem als Strom mit Aufladung und Ausholbewegung (`dragon_parts_breath_offset`).
  - Details: [[Telegraphs & Gefahrenflächen]], Regeln [[Boss-Design]] A2/A3.

## Abhängigkeiten
[[Boss-Testmodus]] · [[Spieler & Bewegung]] · [[Licht, Wetter & Effekte]] · [[Ausrüstung]] · [[Talente]]

## Bekannte Probleme
- Der Drache ist ab Minute 10 für Bots sehr schwer: 17 % bzw. 8 % Siege.
- Der Doppelstampfer des Behemoth trifft bedrohte Bots zu 79 %.
- Die älteren Drachenangriffe nutzen das alte Encounter-System: Treffertest und Darstellung laufen in `dragon_encounter_step` und `dragon_encounter_draw`, nicht über `bv2_*`. Stand nach dem Audit vom 26.11.:
  - Der wachsende Ring von Bodenschlag und Wirbel kommt aus einer Funktion, `dragon_ring_geometry`, für Treffer, Bild und Test. Vorher stand die Formel doppelt im Code.
  - Das Orakel der Boss-Suite sieht jetzt Fächer, Biss, Schweif, Stampf- und Meteorzonen und den Ring. Ergebnis: in allen 18 Drachenfällen 0 Bilder ohne erreichbare sichere Position.
  - Weiterhin unsichtbar für das Orakel sind die drei Projektilangriffe Wind, Leere und Salve (`hostile_bullets`).
  - Langfristig sollten diese Angriffe auf `bv2`-Gefahren umziehen, damit es nur einen Treffer- und Warnpfad gibt ([[Bugs & Ideen]]).
