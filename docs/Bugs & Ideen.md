---
tags: [bugs, ideen, backlog]
updated: 2026-11-27
---
# Bugs & Ideen

Nur Notizen, **nichts davon wurde behoben**. Gefunden beim Lesen von Code und Doku (Claude, 24.–26.11.2026). Status: offen, wenn nicht anders vermerkt. Größere Arbeiten stehen geordnet in [[Roadmap & Vertical Slice]].

## Mögliche Bugs und Aufräumpunkte
- **Minibosse nutzen 0.1-Gegnerstreifen** (Eber, Golem; 64×64, ohne Blickrichtungen), Stilbruch. Anforderungen für neue Grafik: [[Assets & Pipeline]] 7.6. → [[Roadmap & Vertical Slice]] Schritt 9.
- **MCP-Zeitlimit:** `MCP_TIMEOUT` in `.claude/settings.json` wirkt nicht (25.11. geprüft). Abhilfe per `setx` nur mit Zustimmung des Nutzers. → [[Tests & QA]]
- **Boss-Testmenü im Release:** `#macro BOSS_TEST_MENU_ENABLED true` in `scripts/boss_test_mode`. Vor einer Veröffentlichung auf `false` setzen. → [[Boss-Testmodus]]
- **Drei Boss-Codepfade** (Audit 26.11., größtes Wartungsrisiko): `boss_combat` (Minibosse, alte Muster), `dragon_encounter` (eigener Treffertest und eigene Darstellung) und `boss_encounters_v2` auf den gemeinsamen `bv2`-Gefahren.
  - Entschärft: gemeinsame Ringgeometrie `dragon_ring_geometry`; das Orakel prüft jetzt auch die geometrischen Altangriffe des Drachen.
  - Seit 26.11. sieht das Orakel auch Wind, Leere und Salve (Projektile): 0 unsichere Bilder in allen Fällen ([[Bosse]]).
  - Vorschlag: die Altangriffe des Drachen einzeln auf `bv2_sector`/`bv2_zone`/Ring umziehen, je Angriff mit dem vorhandenen Orakel-Fall als Absicherung; zuerst Fächer und Bodenschlag (rein geometrisch), zuletzt die Projektile.
  → [[Bosse]]
- **Pausenansicht in Review- und Testszenarien:** Die Zeile „Klasse | Leben“ des Pausen-Inventars (unten, etwa y 673) liegt auf den Statuszeilen von Review- und Boss-Testmodus. Nur Lesbarkeit; im normalen Spiel ohne Statuszeilen tritt es nicht auf. → [[UI, HUD & Menüs]]
- **Münz-Belastungstest unter 60 FPS** (`perf`, Szenario `horde_coins`: Horde plus 2.500 liegende Münzen; schon vor dem Overhaul 57–62 FPS):
  - Stand 27.11.: 18,2–18,4 ms je Bild (fps_real 56), Horde ohne Münzen 16,9 ms. Vor dem Overhaul 17,2–17,5 ms.
  - Geprüft 27.11.: Ohne Nachbearbeitung nur 0,3–0,6 ms schneller; halb so viele aktive Münzen (Rand 96 statt 260 px) brachten nichts messbares (zurückgenommen). Der Rest liegt also nicht bei den aktiven Münzen, Verdacht: die Verwaltung der etwa 2.200 deaktivierten Instanzen (`instance_activate_region` alle 10 Bilder) oder Tiefensortierung.
  - Vorschlag: Münzen als Datenfeld statt als Instanzen (ein Zeichendurchgang, keine Kollisionsereignisse); größerer Umbau, nur auf Auftrag. → [[Progression & Level-up]]
- **Befunde der visual-qa vom 27.11. (schon vorher vorhanden, nicht Teil des Overhaul-Blocks):**
  - Schadenszahlen stapeln sich und überdecken Lebensleisten (z. B. Waldläufer, Bosskampf). → [[UI, HUD & Menüs]]
  - Arkanistin: Der Bogen ist fast deckend (etwa 0,68), und der Kreis mit gepunktetem Rand ähnelt der Formsprache gegnerischer Warnungen ([[Kampf & Begegnungen]] 5.7, 8). → [[Klassen & Startwaffen]]
  - Pflanzenwiegen: Bei schwachem Wind springt die Spitze nur zwischen 0 und 1 Pixel; ob das als Wiegen oder als Zucken wirkt, ist UNKLAR. Nächster Schritt: Aufnahme mit starkem Wind. → [[Level & Welten]]
  - Der Szenen-Recorder speichert Bilder mit 1280×720 statt 960×540 (gleichmäßig hochskaliert, jede dritte Pixelspalte doppelt); schon in einer Aufnahme vom 26.11. Das Spiel selbst ist nicht betroffen: Die Level-Suite prüft seit 27.11. in allen drei Leveln die Bildfläche 960×540 (PASS). Der Fehler liegt im Aufnahmeweg des Recorders und erschwert die Beurteilung des Pixelrasters in Aufnahmen. → [[Tests & QA]]
- **Diktieren im Urteilsdialog ungetestet** (seit 26.11. abends): Die Windows-Spracheingabe (Win+H) sollte direkt ins Kommentarfeld schreiben (`keyboard_string`); automatisch nicht prüfbar, bisher nicht ausprobiert. → [[Review-Center]]
- **Grafik-Overhaul, Restpunkte der visual-qa-Zweitmeinung (26.11.):**
  - Rauch über einem waagerechten Feuerstrahl könnte die Fläche nach oben verlassen; nicht geprüft, weil die Aufnahme nur senkrechte und schräge Strahlen zeigt.
  - Die 1-px-Ränder der Gefahrenflächen sind feiner als die Weltgrafik; das war schon vorher so.
  - Der getönte Strahlbereich ist auf hell beleuchtetem Boden nur über Farbton und Rand vom Boden abgesetzt (Tönung inzwischen 0,65).
  → [[Visuelles Leitbild & Animation]] 7
- **Gegnerzustand per Existenzprüfung:** `ObjectMonster` unterscheidet Art und Zustand über etwa 12 `variable_instance_exists`-Abfragen je Gegner und Bild (`boss_twin`, `boss_minion`, `lvl_kind`, `hit_stun`, `lvl_hover` …). Das ist fehleranfällig bei neuen Gegnerarten und kostet Zeit. Vorschlag: alle Felder in `ObjectMonster/Create_0` mit Standardwerten anlegen und die Abfragen schrittweise durch Feldvergleiche ersetzen, abgesichert durch Level- und Regression-Suite. → [[Gegner & Spawns]]
- **Drachenkopf bei steilen Winkeln:** Die Kopfansichten entstehen durch Drehen der Seitenansicht; nach unten gerichtet wirkt der Kopf flach. Besser: eigene Draufsicht-Variante des Kopfes; Anforderungen in [[Assets & Pipeline]] 7.4. → [[Bosse]]

- **Performance bei vielen Gegnern** (26.11., `tests/tools/profile_perf.py`): Szenerie-Kollision mit Zellindex, Skelett-Sprite gecacht, Texturen im Menü vorgeladen. 148 Gegner unbegrenzt etwa 73–75 FPS (vorher 64–66), Bosskämpfe mit 60 Gegnern 87–100. Bewusst nicht optimiert, weil Pixel oder Review-Inhalte betroffen wären: Schatten in `enemy_draw` (4 Ellipsen je Gegner, etwa 0,5 ms) und `bv2_hazards_draw` im Drachenkampf (etwa 2,4 ms). Weitere Optimierung nur bei Bedarf; das Verhalten darf sich nicht ändern. → [[Gegner & Spawns]]

- **Boss-Kennzahl „Muster erzwingen Bewegung“** ist ein Schwellenwert-Test (Hälfte der Fälle über 20 px). Nach dem Bossdruck lag die Hexen-Kennzahl kurz bei 8 von 17; behoben durch die Eisflut-Regel (Spielerbahn zuerst). Bei künftigen Taktänderungen im Blick behalten. → [[Tests & QA]]

## Balancing-Beobachtungen (nur Empfehlungen, keine Zahlen geändert)
- **Drache ab Minute 10** für Bots sehr schwer: 17 % bzw. 8 % Siege. → [[Bosse]]
- **Waldläufer räumt in Bot-Händen deutlich langsamer** (Audit 26.11., 1.188 Bot-Läufe): Kills bis Minute 10 im Median 2.954 gegenüber 4.596 (Schwertkämpfer) und 5.160 (Arkanistin); Level in Minute 5 bei 12–14 statt 17–18. Der Boss-Schaden der drei Klassen liegt dagegen nah beieinander (97,5 bis 109,2 pro Sekunde, stehendes Ziel, Klassen-Suite). Der Rückstand entsteht also bei den Horden, nicht am Einzelziel. Bots sind keine Menschen; vor einer Zahlenänderung mit echten Läufen gegenprüfen. → [[Klassen & Startwaffen]]
- **Behemoth-Doppelstampfer:** trifft bedrohte Bots zu 79 %. Mehr Reaktionszeit oder deutlichere Warnung prüfen. → [[Bosse]]
- **Zauber-DPS-Spreizung:** Lightning, Iceball, Arcane Barrage und Wisp liegen weit hinter Ice Prison, Ember Field und Gravity Well (`QA/V3_SIMULATION_REPORT.md`). → [[Zauber & Passiva]]
- **Talent- und Ausrüstungswerte** sind neue Designwerte, nicht ausbalanciert. → [[Talente]] · [[Ausrüstung]]

## Ideen
- Eigene Talent-Icons; derzeit werden Zauber-Icons wiederverwendet. → [[Talente]]
- ~~Eigene Meta-Punkte für ein langsameres Fortschrittstempo zwischen Runs~~ umgesetzt am 25.11. (zwei Punkte-Töpfe, siehe [[Talente]]). → [[Progression & Builds]]
- Menschliche Spieltests der neuen Bossmuster und Rückmeldungen hier sammeln. → [[HANDOFF]]
