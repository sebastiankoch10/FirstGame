---
tags: [bugs, ideen, backlog]
updated: 2026-11-25
---
# Bugs & Ideen

Nur Notizen, **nichts davon wurde behoben**. Gefunden beim Lesen von Code und Doku (Claude, 24./25.11.2026). Status: offen, wenn nicht anders vermerkt. Größere Arbeiten stehen geordnet in [[Roadmap & Vertical Slice]].

## Mögliche Bugs und Aufräumpunkte
- **Helm fehlt in einzelnen Frames:** Wo die Segmentierung kaum Haar findet (manche Rückansichten), entsteht kein Helm und das Haar bleibt sichtbar. Abhilfe: Helmform aus dem Nachbarframe derselben Animation übernehmen. → [[Charaktergrafik & Ausrüstungs-Layer]]
- **`tests/tools/audit_boss_v2_assets.py` scheitert:** vergleicht mit einer alten Testkopie unter `output/class-dragon-smoke/…`, die mit `output/` gelöscht wurde (25.11.). Läuft in keiner Suite; Vergleichsbasis auf `QA/baseline` umstellen oder Prüfung entfernen. → [[Tests & QA]]
- **Minibosse nutzen 0.1-Gegnerstreifen** (Eber, Golem; 64×64, ohne Blickrichtungen), Stilbruch. → [[Roadmap & Vertical Slice]] Schritt 9.
- **MCP-Zeitlimit:** `MCP_TIMEOUT` in `.claude/settings.json` wirkt nicht (25.11. geprüft). Abhilfe per `setx` nur mit Zustimmung des Nutzers. → [[Tests & QA]]
- **Verwaiste Event-Dateien:** `objects/ObjectFireball/Collision_ObjectMonster.gml`, `ObjectIceball/…` und `ObjectLightningball/…` sind in den `.yy` der Objekte nicht registriert. GameMaker führt sie nicht aus. Prüfen, ob sie gelöscht werden können oder registriert werden müssen. → [[Zauber & Passiva]]
- **Boss-Testmenü im Release:** `#macro BOSS_TEST_MENU_ENABLED true` in `scripts/boss_test_mode`. Vor einer Veröffentlichung auf `false` setzen. → [[Boss-Testmodus]]
- **Lautstärken werden nicht gespeichert:** In `firstgame_audio.ini` steht nur „Ton im Hintergrund“, ein Speichern der Regler wurde im Code nicht gefunden. Vermutung; im Spiel prüfen. → [[Speichern & Einstellungen]]
- **progression_audit schreibt in jedem Run** `firstgame_progression_current.json`, auch in normalen Spielen. Harmlos, aber unnötige Dateizugriffe. → [[Progression & Level-up]]
- **Alte Drachenangriffe** (Bogen, Bodeneinschlag, Flügelsturm, Void, Wirbel, Salven) laufen nicht über bv2. Das Ausweich-Orakel im Boss-Test prüft sie nicht. → [[Bosse]]
- **Legacy-Harnesses** `tests/atmosphere_harness.gml`, `dragon_harness.gml`, `player_smoke_harness.gml` verweisen auf gelöschte 0.1-Sprites. Sie laufen in keiner Suite; bei Bedarf entfernen. → [[Tests & QA]]
- **Partikel und Zufall:** `spell_vfx` nutzt das globale `random()`. Geseedete Runs sind dadurch nicht mehr mit älteren Ständen vergleichbar. → [[Licht, Wetter & Effekte]]
- **`RoomCrypt` und `RoomRuins`** sind Fallbacks aus der Codex-Zeit. Prüfen, ob sie noch gebraucht werden. → [[Level & Welten]]
- **Test-Flake:** `run_level_smoke.py` lieferte unter paralleler CPU-Last einmal 165/166. → [[Tests & QA]]
- **`run_combat_smoke.py` veraltet** (FAIL schon vor 2026-11-24). → [[Tests & QA]]
- **Noch gemalte, skaliert gezeichnete Effekte:** `dragon_fx_sprite` (Meteor, Wirbel, Bodeneinschlag, Flügelsturm, Magma), `spr_bv2_twins_fx_*`/`spr_bv2_swamp_fx_*`, Projektile der Hexen. Im Weltraster wirken sie unscharf; als Pixel-Komposite nachbauen wie Feueratem und Feuerkegel. → [[Licht, Wetter & Effekte]]
- **Schrift im Weltraum:** „MAGNET“ über Magnetkugeln nutzt noch die Standardschrift (nur Ziffern haben eine Pixelschrift). → [[Rendering & Pixelraster]]
- **Drachenkopf bei steilen Winkeln:** Die Kopfansichten entstehen durch Drehen der Seitenansicht; nach unten gerichtet wirkt der Kopf flach. Besser: eigene Draufsicht-Variante des Kopfes. → [[Bosse]]
- **`docs/ai-activity.log`** wächst mit jedem Stop-Hook-Lauf. Gelegentlich kürzen; prüfen, ob die Datei in die `.gitignore` gehört. → [[SETUP_REPORT]]

## Balancing-Beobachtungen (nur Empfehlungen, keine Zahlen geändert)
- **Drache ab Minute 10** für Bots sehr schwer: 17 % bzw. 8 % Siege. → [[Bosse]]
- **Behemoth-Doppelstampfer:** trifft bedrohte Bots zu 79 %. Mehr Reaktionszeit oder deutlichere Warnung prüfen. → [[Bosse]]
- **Zauber-DPS-Spreizung:** Lightning, Iceball, Arcane Barrage und Wisp liegen weit hinter Ice Prison, Ember Field und Gravity Well (`QA/V3_SIMULATION_REPORT.md`). → [[Zauber & Passiva]]
- **Talent- und Ausrüstungswerte** sind neue Designwerte, nicht ausbalanciert. → [[Talente]] · [[Ausrüstung]]

## Ideen
- Eigene Talent-Icons; derzeit werden Zauber-Icons wiederverwendet. → [[Talente]]
- Eigene Meta-Punkte für ein langsameres Fortschrittstempo zwischen Runs (Zahlenentscheidung). → [[Progression & Builds]]
- Lautstärken in der ini speichern. → [[Audio]]
- Menschliche Spieltests der neuen Bossmuster und Rückmeldungen hier sammeln. → [[HANDOFF]]
