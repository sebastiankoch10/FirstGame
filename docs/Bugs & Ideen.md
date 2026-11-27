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
- **Pausenansicht in Review- und Testszenarien:** Die Zeile „Klasse | Leben“ des Pausen-Inventars (unten, etwa y 673) liegt auf den Statuszeilen von Review- und Boss-Testmodus. Nur Lesbarkeit; im normalen Spiel ohne Statuszeilen tritt es nicht auf. → [[UI, HUD & Menüs]]
- **Münz-Belastungstest unter 60 FPS** (`perf`, Szenario `horde_coins`: Horde plus 2.500 liegende Münzen; schon vor dem Overhaul 57–62 FPS):
  - Stand 27.11.: 18,2–18,4 ms je Bild (fps_real 56), Horde ohne Münzen 16,9 ms. Vor dem Overhaul 17,2–17,5 ms.
  - Geprüft 27.11.: Ohne Nachbearbeitung nur 0,3–0,6 ms schneller; halb so viele aktive Münzen (Rand 96 statt 260 px) brachten nichts messbares (zurückgenommen). Der Rest liegt also nicht bei den aktiven Münzen, Verdacht: die Verwaltung der etwa 2.200 deaktivierten Instanzen (`instance_activate_region` alle 10 Bilder) oder Tiefensortierung.
  - Vorschlag: Münzen als Datenfeld statt als Instanzen (ein Zeichendurchgang, keine Kollisionsereignisse); größerer Umbau, nur auf Auftrag. → [[Progression & Level-up]]
- **Befunde der visual-qa vom 27.11. (schon vorher vorhanden, nicht Teil des Overhaul-Blocks):**
  - Schadenszahlen stapeln sich und überdecken Lebensleisten (z. B. Waldläufer, Bosskampf). → [[UI, HUD & Menüs]]
  - Arkanistin: Der Bogen ist fast deckend (etwa 0,68), und der Kreis mit gepunktetem Rand ähnelt der Formsprache gegnerischer Warnungen ([[Kampf & Begegnungen]] 5.7, 8). → [[Klassen & Startwaffen]]
  - Pflanzenwiegen: Bei schwachem Wind springt die Spitze nur zwischen 0 und 1 Pixel; ob das als Wiegen oder als Zucken wirkt, ist UNKLAR. Nächster Schritt: Aufnahme mit starkem Wind. → [[Level & Welten]]
- **Diktieren im Urteilsdialog ungetestet** (seit 26.11. abends): Die Windows-Spracheingabe (Win+H) sollte direkt ins Kommentarfeld schreiben (`keyboard_string`); automatisch nicht prüfbar, bisher nicht ausprobiert. → [[Review-Center]]
- **Grafik-Overhaul, Restpunkte der visual-qa-Zweitmeinung (26.11.):**
  - Rauch über einem waagerechten Feuerstrahl könnte die Fläche nach oben verlassen; nicht geprüft, weil die Aufnahme nur senkrechte und schräge Strahlen zeigt.
  - Die 1-px-Ränder der Gefahrenflächen sind feiner als die Weltgrafik; das war schon vorher so.
  - Der getönte Strahlbereich ist auf hell beleuchtetem Boden nur über Farbton und Rand vom Boden abgesetzt (Tönung inzwischen 0,65).
  → [[Visuelles Leitbild & Animation]] 7
- **Drache, Befunde der visual-qa vom 27.11. außerhalb der Gefahrenflächen (offen, nicht ungefragt bearbeiten):**
  - Ursprung von Strahl, Leere und Salve liegt nicht am gezeichneten Maul (Strahl etwa 65 px unter dem Kopf, Leere und Salve starten am Flügel, Windladung über dem Kopf); Verdacht: Maul-Anker der Bauteil-Figur bei Blick nach rechts (`dragon_parts_fire_mouth`). Spielrelevant (G1), weil der Ursprung die Trefferlinie bestimmt.
  - Biss: Bei weitem Ausfall wird der Hals als gerade Segmentsäule über mehr als 250 px gezeichnet (`dragon_parts`, Biss).
  - Navigation bricht laufende Ankündigungen ab (`bv2_clear_enc`), z. B. das zweite, invertierte Schachbrett; Verhalten wie vor der Zusammenführung, widerspricht aber Boss-Design H2 „Nie abbrechen“.
  → [[Boss-Design]], [[Bosse]]
- **Zauber, Befunde der visual-qa vom 27.11. (schon vorher vorhanden, offen):**
  - Eigene Zauber-Sprites verdecken teils die Spielerfigur (Stone Spikes, Frost Nova, Healing Pulse und Wisp auf Stufe 9), verstößt gegen Rang 1 in [[Kampf & Begegnungen]] 8.
  - Ember Field auf Stufe 9 ähnelt dem Feuerboden des Drachen (gleiches Element, ähnliche Form) und ist deckender als der Richtwert 0,35; ein gemeinsamer Test mit dem Drachen fehlt.
  - Alte Partikelformen ohne Pixelraster (hohle Quadrate, Vektorlinien in `spell_vfx`), sichtbar bei Thunder Seal und Solar Verdict.
  - Partikel der Passiva (Heilfunken, Schutzschimmer, Resonanz, Schwüre, Orbit Shield) sind in keiner Aufnahme geprüft (NOT RUN); der Recorder hat dafür keine Szene.
  → [[Fähigkeiten, VFX & Audio]]
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
