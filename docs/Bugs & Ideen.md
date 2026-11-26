---
tags: [bugs, ideen, backlog]
updated: 2026-11-26
---
# Bugs & Ideen

Nur Notizen, **nichts davon wurde behoben**. Gefunden beim Lesen von Code und Doku (Claude, 24.–26.11.2026). Status: offen, wenn nicht anders vermerkt. Größere Arbeiten stehen geordnet in [[Roadmap & Vertical Slice]].

## Mögliche Bugs und Aufräumpunkte
- **Helm fehlt in einzelnen Frames:** Wo die Segmentierung kaum Haar findet (manche Rückansichten), entsteht kein Helm und das Haar bleibt sichtbar. Abhilfe: Helmform aus dem Nachbarframe derselben Animation übernehmen. → [[Charaktergrafik & Ausrüstungs-Layer]]
- **Minibosse nutzen 0.1-Gegnerstreifen** (Eber, Golem; 64×64, ohne Blickrichtungen), Stilbruch. → [[Roadmap & Vertical Slice]] Schritt 9.
- **MCP-Zeitlimit:** `MCP_TIMEOUT` in `.claude/settings.json` wirkt nicht (25.11. geprüft). Abhilfe per `setx` nur mit Zustimmung des Nutzers. → [[Tests & QA]]
- **Boss-Testmenü im Release:** `#macro BOSS_TEST_MENU_ENABLED true` in `scripts/boss_test_mode`. Vor einer Veröffentlichung auf `false` setzen. → [[Boss-Testmodus]]
- **progression_audit schreibt in jedem Run** `firstgame_progression_current.json`, auch in normalen Spielen. Harmlos, aber unnötige Dateizugriffe. → [[Progression & Level-up]]
- **Alte Drachenangriffe** (Bogen, Bodeneinschlag, Flügelsturm, Void, Wirbel, Salven) laufen nicht über bv2. Das Ausweich-Orakel im Boss-Test prüft sie nicht. → [[Bosse]]
- **Partikel und Zufall:** `spell_vfx` nutzt das globale `random()`. Geseedete Runs sind dadurch nicht mehr mit älteren Ständen vergleichbar. → [[Licht, Wetter & Effekte]]
- **`RoomCrypt` und `RoomRuins`** sind Fallbacks aus der Codex-Zeit. Prüfen, ob sie noch gebraucht werden. → [[Level & Welten]]
- **Test-Flake:** `run_level_smoke.py` lieferte unter paralleler CPU-Last einmal 165/166. → [[Tests & QA]]
- **Drachenkopf bei steilen Winkeln:** Die Kopfansichten entstehen durch Drehen der Seitenansicht; nach unten gerichtet wirkt der Kopf flach. Besser: eigene Draufsicht-Variante des Kopfes. → [[Bosse]]
- **`docs/.obsidian/` ist nicht ignoriert** und erscheint in `git status`. Vorschlag: `docs/.obsidian/workspace*.json` in die `.gitignore`. → [[SETUP_REPORT]]

- **`boss_test_preset` kalibrieren:** gemessene Level je Minute und Vorschlagswerte stehen in [[Boss-Testmodus]] (Minute 5/10/15: 17/33/51 statt 13/23/36; Minute 20: 70 statt 84). Umsetzung nur mit Freigabe des Nutzers.
- **Performance-Engpass Gegnerzahl** (Messung 26.11., `run_native_harness.py perf`): 148 Gegner lassen im Mittel nur etwa 6–10 % Reserve über 60 FPS (unbegrenzt 64–66 FPS, schlechtestes Bild 36), Bosskämpfe mit 60 Gegnern 79–91 FPS. Licht (0,2–0,3 ms) und Gefahren-Partikel (60–200) sind unkritisch. Nächster Schritt: `enemy_pursue` (Trennung der Gegner untereinander) und `enemy_draw` profilieren, etwa mit einem Raster für Nachbarn; Verhalten darf sich nicht ändern. → [[Gegner & Spawns]]

- **Level-Suite war zeitabhängig** (behoben am 26.11.): Die Verfolgen- und Treffer-Prüfungen zählen Bilder, liefen aber mit echter Bildzeit. Je nach Rechnerlast scheiterten wechselnd Konstrukt, Sumpfskelett oder Ritter. `run_level_smoke.py` setzt jetzt wie die Boss-Suite 60 Hz fest (danach 4 von 4 Läufen PASS). Weitere Suiten ohne feste Bildzeit (feature, classes) bei Auffälligkeiten ebenso umstellen. → [[Tests & QA]]
- **Boss-Kennzahl „Muster erzwingen Bewegung“** ist ein Schwellenwert-Test (Hälfte der Fälle über 20 px). Nach dem Bossdruck lag die Hexen-Kennzahl kurz bei 8 von 17; behoben durch die Eisflut-Regel (Spielerbahn zuerst). Bei künftigen Taktänderungen im Blick behalten. → [[Tests & QA]]

- **`FirstGame_ArtPack/atmosphere_v2/`** ist der letzte Quellordner außerhalb der Zielstruktur; prüfen, ob noch ein Werkzeug daraus liest, dann nach `_legacy/`. → [[Assets & Pipeline]]
- **Sichtbare Änderungen vom 26.11. ohne Review-Eintrag** (Auftrag: keine neuen Review-Fälle): mehrphasige Steinstacheln/Sternenfall/Prismensamen, Bewegungsprofile der Wald-Skelette, Pixelschrift „MAGNET“. Bei Bedarf Szenarien nachregistrieren. → [[Review-Center]]

## Balancing-Beobachtungen (nur Empfehlungen, keine Zahlen geändert)
- **Drache ab Minute 10** für Bots sehr schwer: 17 % bzw. 8 % Siege. → [[Bosse]]
- **Behemoth-Doppelstampfer:** trifft bedrohte Bots zu 79 %. Mehr Reaktionszeit oder deutlichere Warnung prüfen. → [[Bosse]]
- **Zauber-DPS-Spreizung:** Lightning, Iceball, Arcane Barrage und Wisp liegen weit hinter Ice Prison, Ember Field und Gravity Well (`QA/V3_SIMULATION_REPORT.md`). → [[Zauber & Passiva]]
- **Talent- und Ausrüstungswerte** sind neue Designwerte, nicht ausbalanciert. → [[Talente]] · [[Ausrüstung]]

## Ideen
- Eigene Talent-Icons; derzeit werden Zauber-Icons wiederverwendet. → [[Talente]]
- ~~Eigene Meta-Punkte für ein langsameres Fortschrittstempo zwischen Runs~~ umgesetzt am 25.11. (zwei Punkte-Töpfe, siehe [[Talente]]). → [[Progression & Builds]]
- Menschliche Spieltests der neuen Bossmuster und Rückmeldungen hier sammeln. → [[HANDOFF]]
