# FirstGame – offene Punkte (Stand 24.11.2026)

Detailstand und Testergebnisse: `DEVELOPMENT_PROGRESS.md`. Bossregeln: `DESIGN/BOSS_DESIGN.md`. Talente/Ausrüstung: `DESIGN/TALENTS_AND_EQUIPMENT.md`.

## Entscheidungen des Projektinhabers nötig
- [ ] **Talente:** pro Run (jetzt) oder dauerhafte Meta-Progression zwischen Runs? Umschaltbar über `talent_config().persistent`.
- [ ] **Talentpunkte:** Tempo jetzt ab Stufe 4 alle 4 Stufen plus 1 je Hauptboss. Passt das?
- [ ] **Respec** (Talente zurücksetzen): gewünscht?
- [ ] **Ausrüstung:** Drop-Raten (Boss garantiert, normale Gegner 0,3 %), Rucksackgröße 8, Stärke der Werte.

## Spieltest (nur durch einen Menschen möglich)
- [ ] Bosskämpfe mit den neuen Choreografien: Lesbarkeit von Schachbrett, Streifen, Quadranten, Schwenkstrahl, Verbindungsstrahl und schließendem Giftring.
- [ ] Aufholattacken: Fühlen sich Sturzflug, Untertauchen und Formationswechsel fair an? Sind sie selten genug?
- [ ] Charakterbildschirm (T): Verständlichkeit, Mausbedienung.
- [ ] Neue Zauberpartikel und -lichter: Lesbarkeit in großen Kämpfen.

## Technik und Inhalte
- [ ] Ausrüstung optisch am Charakter (bräuchte Rüstungsvarianten aller Animationen).
- [ ] Ältere Drachenangriffe (Feuerbogen, Bodeneinschlag, Flügelsturm, Void, Feuerwirbel, Salven) nutzen noch das alte Encounter-System. Sie sind funktionsfähig, aber das Orakel im Boss-Test sieht sie nicht.
- [ ] `tests/tools/run_combat_smoke.py` ist veraltet: Er erwartet ein sofortiges Mage-Projektil und schlug schon vor diesem Auftrag fehl.
- [ ] Simulationen: Ziel 3.000 vollständige Runs. Der tatsächlich erreichte Stand steht in `QA/V3_SIMULATION_REPORT.md` und `DEVELOPMENT_PROGRESS.md`.
- [ ] Langzeit-Performance (30 Minuten mit vielen Effekten) messen.
