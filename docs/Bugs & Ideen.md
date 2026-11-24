---
tags: [bugs, ideen, backlog]
updated: 2026-11-24
---
# Bugs & Ideen

Nur Notizen, **nichts davon wurde behoben**. Gefunden beim Lesen von Code und Doku am 2026-11-24 (Claude). Status: offen, wenn nicht anders vermerkt.

## Mögliche Bugs und Aufräumpunkte
- **README veraltet:** `README.md` verlinkt `output/production-build/20261123-223542/FirstGame.zip`, das nicht mehr existiert, und nennt `run_combat_smoke.py` als Test. Diese Doku-Aufgabe durfte die README nicht ändern.
- **Verwaiste Event-Dateien:** `objects/ObjectFireball/Collision_ObjectMonster.gml`, `ObjectIceball/…` und `ObjectLightningball/…` sind in den `.yy` der Objekte nicht registriert. GameMaker führt sie nicht aus. Prüfen, ob sie gelöscht werden können oder registriert werden müssen. → [[Zauber & Passiva]]
- **Boss-Testmenü im Release:** `#macro BOSS_TEST_MENU_ENABLED true` in `scripts/boss_test_mode`. Vor einer Veröffentlichung auf `false` setzen. → [[Boss-Testmodus]]
- **Lautstärken werden nicht gespeichert:** In `firstgame_audio.ini` steht nur „Ton im Hintergrund“, ein Speichern der Regler wurde im Code nicht gefunden. Vermutung; im Spiel prüfen. → [[Speichern & Einstellungen]]
- **progression_audit schreibt in jedem Run** `firstgame_progression_current.json`, auch in normalen Spielen. Harmlos, aber unnötige Dateizugriffe. → [[Progression & Level-up]]
- **Dauerhafte Talente ungetestet:** Der `persistent`-Zweig (ini) ist implementiert, aber nie im Spiel getestet. → [[Talente]]
- **Alte Drachenangriffe** (Bogen, Bodeneinschlag, Flügelsturm, Void, Wirbel, Salven) laufen nicht über bv2. Das Ausweich-Orakel im Boss-Test prüft sie nicht. → [[Bosse]]
- **Partikel und Zufall:** `spell_vfx` nutzt das globale `random()`. Geseedete Runs sind dadurch nicht mehr mit älteren Ständen vergleichbar. → [[Licht, Wetter & Effekte]]
- **`RoomCrypt` und `RoomRuins`** sind Fallbacks aus der Codex-Zeit. Prüfen, ob sie noch gebraucht werden. → [[Level & Welten]]
- **Test-Flake:** `run_level_smoke.py` lieferte unter paralleler CPU-Last einmal 165/166. → [[Tests & QA]]
- **`run_combat_smoke.py` veraltet** (FAIL schon vor 2026-11-24). → [[Tests & QA]]
- **`QA/logs/regression-*`** sammeln sich an (3 untracked Ordner vom 2026-11-24). Gelegentlich aufräumen oder in die `.gitignore` aufnehmen.
- **`docs/ai-activity.log`** wächst mit jedem Stop-Hook-Lauf. Gelegentlich kürzen; prüfen, ob die Datei in die `.gitignore` gehört. → [[SETUP_REPORT]]

## Balancing-Beobachtungen (nur Empfehlungen, keine Zahlen geändert)
- **Drache ab Minute 10** für Bots sehr schwer: 17 % bzw. 8 % Siege. → [[Bosse]]
- **Behemoth-Doppelstampfer:** trifft bedrohte Bots zu 79 %. Mehr Reaktionszeit oder deutlichere Warnung prüfen. → [[Bosse]]
- **Zauber-DPS-Spreizung:** Lightning, Iceball, Arcane Barrage und Wisp liegen weit hinter Ice Prison, Ember Field und Gravity Well (`QA/V3_SIMULATION_REPORT.md`). → [[Zauber & Passiva]]
- **Talent- und Ausrüstungswerte** sind neue Designwerte, nicht ausbalanciert. → [[Talente]] · [[Ausrüstung]]

## Ideen
- Ausrüstung am Charakter sichtbar machen (Overlay-Sprites je Slot). → [[Ausrüstung]]
- Eigene Talent-Icons; derzeit werden Zauber-Icons wiederverwendet. → [[Talente]]
- Talente neu verteilen (Respec), z. B. gegen Münzen oder einmal pro Run. → [[Talente]]
- Meta-Progression zwischen Runs, als Option über `talent_config().persistent`.
- Lautstärken in der ini speichern. → [[Audio]]
- Menschliche Spieltests der neuen Bossmuster und Rückmeldungen hier sammeln. → [[HANDOFF]]
