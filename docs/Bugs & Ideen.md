---
tags: [bugs, ideen, backlog]
updated: 2026-11-26
---
# Bugs & Ideen

Nur Notizen, **nichts davon wurde behoben**. Gefunden beim Lesen von Code und Doku (Claude, 24.–26.11.2026). Status: offen, wenn nicht anders vermerkt. Größere Arbeiten stehen geordnet in [[Roadmap & Vertical Slice]].

## Mögliche Bugs und Aufräumpunkte
- **Helm fehlt in einzelnen Frames:** Wo die Segmentierung kaum Haar findet (manche Rückansichten), entsteht kein Helm und das Haar bleibt sichtbar. Abhilfe: Helmform aus dem Nachbarframe derselben Animation übernehmen. → [[Charaktergrafik & Ausrüstungs-Layer]]
- **Minibosse nutzen 0.1-Gegnerstreifen** (Eber, Golem; 64×64, ohne Blickrichtungen), Stilbruch. Anforderungen für neue Grafik: [[Assets & Pipeline]] 7.6. → [[Roadmap & Vertical Slice]] Schritt 9.
- **MCP-Zeitlimit:** `MCP_TIMEOUT` in `.claude/settings.json` wirkt nicht (25.11. geprüft). Abhilfe per `setx` nur mit Zustimmung des Nutzers. → [[Tests & QA]]
- **Boss-Testmenü im Release:** `#macro BOSS_TEST_MENU_ENABLED true` in `scripts/boss_test_mode`. Vor einer Veröffentlichung auf `false` setzen. → [[Boss-Testmodus]]
- **Alte Drachenangriffe** (Bogen, Bodeneinschlag, Flügelsturm, Void, Wirbel, Salven) laufen nicht über bv2. Das Ausweich-Orakel im Boss-Test prüft sie nicht. → [[Bosse]]
- **Drachenkopf bei steilen Winkeln:** Die Kopfansichten entstehen durch Drehen der Seitenansicht; nach unten gerichtet wirkt der Kopf flach. Besser: eigene Draufsicht-Variante des Kopfes; Anforderungen in [[Assets & Pipeline]] 7.4. → [[Bosse]]

- **Performance bei vielen Gegnern** (26.11., `tests/tools/profile_perf.py`): Szenerie-Kollision mit Zellindex, Skelett-Sprite gecacht, Texturen im Menü vorgeladen. 148 Gegner unbegrenzt etwa 73–75 FPS (vorher 64–66), Bosskämpfe mit 60 Gegnern 87–100. Bewusst nicht optimiert, weil Pixel oder Review-Inhalte betroffen wären: Schatten in `enemy_draw` (4 Ellipsen je Gegner, etwa 0,5 ms) und `bv2_hazards_draw` im Drachenkampf (etwa 2,4 ms). Weitere Optimierung nur bei Bedarf; das Verhalten darf sich nicht ändern. → [[Gegner & Spawns]]

- **Boss-Kennzahl „Muster erzwingen Bewegung“** ist ein Schwellenwert-Test (Hälfte der Fälle über 20 px). Nach dem Bossdruck lag die Hexen-Kennzahl kurz bei 8 von 17; behoben durch die Eisflut-Regel (Spielerbahn zuerst). Bei künftigen Taktänderungen im Blick behalten. → [[Tests & QA]]

## Balancing-Beobachtungen (nur Empfehlungen, keine Zahlen geändert)
- **Drache ab Minute 10** für Bots sehr schwer: 17 % bzw. 8 % Siege. → [[Bosse]]
- **Behemoth-Doppelstampfer:** trifft bedrohte Bots zu 79 %. Mehr Reaktionszeit oder deutlichere Warnung prüfen. → [[Bosse]]
- **Zauber-DPS-Spreizung:** Lightning, Iceball, Arcane Barrage und Wisp liegen weit hinter Ice Prison, Ember Field und Gravity Well (`QA/V3_SIMULATION_REPORT.md`). → [[Zauber & Passiva]]
- **Talent- und Ausrüstungswerte** sind neue Designwerte, nicht ausbalanciert. → [[Talente]] · [[Ausrüstung]]

## Ideen
- Eigene Talent-Icons; derzeit werden Zauber-Icons wiederverwendet. → [[Talente]]
- ~~Eigene Meta-Punkte für ein langsameres Fortschrittstempo zwischen Runs~~ umgesetzt am 25.11. (zwei Punkte-Töpfe, siehe [[Talente]]). → [[Progression & Builds]]
- Menschliche Spieltests der neuen Bossmuster und Rückmeldungen hier sammeln. → [[HANDOFF]]
