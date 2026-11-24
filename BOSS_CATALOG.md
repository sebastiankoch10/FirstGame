# FirstGame – Boss-Katalog 2.0

Stand: 23.11.2026. Zentrale Laufzeitdefinitionen: `scripts/boss_framework_v2`, Mechanikprofile `scripts/boss_encounters_v2` und `scripts/dragon_encounter`. [Umsetzung und Testnachweise](BOSS_V2_REPORT.md).

## Gemeinsame Regeln

Drei volle Hauptboss-Begegnungen mit jeweils genau neun Fähigkeiten. Freischaltung beim tatsächlichen Spawn: vor Minute 10 Fähigkeiten 1–3, ab Minute 10 Fähigkeiten 1–6, ab Minute 15 Fähigkeiten 1–9. Der Spawnzeitpunkt und sämtliche Skalierungsfaktoren werden gespeichert. Zeit- und HP-Phasenwechsel ändern den freigeschalteten Pool nicht. Phasenrotationen werden gegen diesen Pool gefiltert.

Zeitplan: Minibosse bei Minute 1 und 3; danach ein zufällig ausgewählter verfügbarer Hauptboss bei Minute 5/10/15/20/25/30. Nur eine Begegnung gleichzeitig; überfällige Termine werden nacheinander abgearbeitet. Ein eigener Park-Miller-Zufallsgenerator hält Bossauswahl unabhängig von Partikeln. Normale Runden erhalten einen neuen Seed, Entwicklungstests einen expliziten reproduzierbaren Seed.

Verfügbarkeit verlangt implementierte neun Profile sowie die tatsächlich importierten Körperanimationen, Effekte und Audiocues. Frühere generische Echo-Varianten sind aus dem regulären Hauptbossplan entfernt.

## Skalierung

HP = Basis-HP × Tabellenfaktor × Level-Grundfaktor × gewählter Test-Schwierigkeitsfaktor. Im normalen Room1 ist der Level-Grundfaktor 1. Schaden = Fähigkeitsbasis × (1 + Spielminute × 0,06) × Level-Grundschadensfaktor × Testfaktor. Beide Faktoren bleiben nach Spawn fest. Es gibt keine Schadenssperre oder Mindestkampfdauer.

| Spawnminute | HP-Faktor | Drachen-/Behemoth-HP | Gemeinsame Hexen-HP | Tempo | Zusatzprojektile | Projektiltempo |
|---|---|---|---|---|---|---|
| 5 | 1.35 | 12420 | 17550 | 1× | 0 | 1× |
| 10 | 1.9 | 17480 | 24700 | 1.07× | 0 | 1.08× |
| 15 | 2.5 | 23000 | 32500 | 1.14× | 1 | 1.16× |
| 20 | 3.4 | 31280 | 44200 | 1.21× | 1 | 1.24× |
| 25 | 4.5 | 41400 | 58500 | 1.28× | 2 | 1.32× |
| 30 | 5.8 | 53360 | 75400 | 1.35× | 2 | 1.4× |

Das Tempolimit erhöht vor allem Angriffshäufigkeit und Muster; einzelne Warnungen haben Sicherheitsuntergrenzen. Große Bodenfelder bleiben angekündigt. Testschwierigkeiten: leicht 0,8, normal 1, hart 1,25. Radius, Warnzeit, Trefferhöhe und aktiver Zeitraum gehören zur jeweiligen Mechanik.

## Aschenflügel – `storm_warden`

Basis 9.200 HP, vorhandenes blaues Drachenmodell unverändert. Vier HP-Phasen bei 75/50/25%. Hauptform der Angriffe: direkte Feuerangriffe, Meteore, Bodenwellen und violette Projektile.

| Nr. | Fähigkeit | Grundwarnung (s) | Aktiv (s) | Grundschaden | Trefferhöhe |
|---|---|---|---|---|---|
| 1 | Feuerstrahl | 1,20 | 1,00 | 36 je Kontaktintervall | hoch |
| 2 | Feuerbogen | 1,00 | 0,70 | 32 je Kontaktintervall | Boden |
| 3 | Magmaeruptionen | 1,05 | 0,55 | 64 je Zone | alle |
| 4 | Meteoritenregen | 1,80 + Versatz | 1,80 | 38 je Zone | alle |
| 5 | Flug/Bodeneinschlag | 1,50 | 1,10 | 42 je Kontaktintervall | Boden |
| 6 | Flügelsturm | 0,90 Abschussvorbereitung | 1,70 | 14 je Windgeschoss | hoch |
| 7 | Void-Orbs | 0,80 Abschussvorbereitung | 1,60 | 24 je Geschoss | hoch |
| 8 | Feuerwirbel | 1,70 | 1,60 | 32 je Kontaktintervall | Boden |
| 9 | Violette Salven | 0,65 Abschussvorbereitung | 1,70 | 20 je Geschoss | hoch |

Nur großflächige Gefahren besitzen Boden-Countdowns. Sichtbare Void-/Salven-/Windprojektile verwenden ihre Abschussanimation. Feste Ausgangsrotationen bleiben erhalten und werden um fehlende freigeschaltete Fähigkeiten ergänzt; dadurch bleiben auch bei Minute fünf alle drei Grundfähigkeiten in späteren HP-Phasen nutzbar. Der ältere interne Sweep-Helfer ist kein zehnter auswählbarer Angriff und liegt außerhalb des neuen Pools.

## Die Zwillingshexen – `twins`

Basis 13.000 HP. Zwei getrennt treffbare fliegende Figuren, ein gemeinsam verknüpfter HP-Pool. Beide sterben gemeinsam; nur eine Truhe und ein Orb. Phasen bei 75/50/25%.

| Nr. | Fähigkeit | Mechanik | Vorbereitung (s) | Angriffszustand (s) | Grundschaden | Höhe | Animation |
|---|---|---|---|---|---|---|---|
| 1 | Doppelte Geschosssalve | `dual_salvo` | 0.55 | 1.1 | 14 | high | `cast` |
| 2 | Rotierender Feuer-Eis-Ring | `element_ring` | 1.2 | 2.4 | 22 | ground | `joint` |
| 3 | Meteoriten und Eissplitterregen | `paired_rain` | 1.4 | 1.8 | 25 | all | `cast` |
| 4 | Verbindungsstrahl | `moving_link` | 1.3 | 2.7 | 22 | high | `joint` |
| 5 | Dualer Spiralwirbel | `counter_spirals` | 1.5 | 2.7 | 24 | ground | `joint` |
| 6 | Kreuzschlag-Strahlen | `cross_beams` | 1.4 | 2 | 28 | high | `cast` |
| 7 | Brennender Froststoss | `burning_frost` | 1.5 | 2.5 | 36 | all | `joint` |
| 8 | Vereinigte Zonenflut | `paired_flood` | 1.6 | 3 | 22 | ground | `joint` |
| 9 | Duale Nova | `three_stage_nova` | 1.8 | 3.1 | 40 | all | `joint` |

Sechs Formationen: liegende Acht, Kreis, diagonales Kreuzen, gemeinsamer Sturz, getrennte Positionierung und verkettete Verfolgung. Bewegte Verbindungs-/Kreuzstrahlen verwenden die tatsächlichen Handpositionen beider Figuren für Darstellung und Trefferprüfung. Gegenläufige Spiralringe besitzen mitrotierende freie Winkel. Die Zonenflut lässt einen zentralen Korridor frei. Die Duale Nova wechselt von äußerem Ring zu innerem Kreis und erneut äußerem Energieband.

## Sumpfbehemoth – `behemoth`

Basis 9.200 HP. Schwerer Holz-/Knochen-/Pilzkoloss mit bleibenden Bodenfeldern. Phasen bei 70/40/10%. Sumpfbrut ist eine auf sechs Kreaturen begrenzte bossgebundene Unterstützung und kein neuer regulärer Gegnertyp.

| Nr. | Fähigkeit | Mechanik | Vorbereitung (s) | Angriffszustand (s) | Grundschaden | Höhe | Animation |
|---|---|---|---|---|---|---|---|
| 1 | Giftgespucke | `poison_spit` | 0.7 | 1 | 18 | high | `spit` |
| 2 | Saeurepfuetzen | `acid_pools` | 1.1 | 1.5 | 8 | ground | `spit` |
| 3 | Packende Wurzeln | `grasping_roots` | 1.1 | 0.55 | 17 | ground | `roots` |
| 4 | Pilzexplosion | `growing_mushrooms` | 1.6 | 3 | 27 | all | `summon` |
| 5 | Sumpfstampfer | `ground_shockwave` | 1.4 | 1.5 | 34 | ground | `stomp` |
| 6 | Sumpfbrut | `bounded_brood` | 1.3 | 1.1 | 0 | ground | `summon` |
| 7 | Giftatem | `poison_breath` | 1.5 | 1.9 | 18 | all | `breath` |
| 8 | Sumpfwelle | `travelling_mud_wave` | 1.3 | 2 | 28 | ground | `wave` |
| 9 | Verfallsbluete | `decay_bloom` | 1.9 | 4.1 | 30 | all | `bloom` |

Säurepfützen halten bis 4,5 s und ticken alle 0,65 s. Wurzeln begrenzen Bodentempo für 0,55 s auf 25%; Sprung und Dodge bleiben nutzbar. Pilze explodieren nach Wachstum und hinterlassen endliche Sporenwolken. Stampfwellen sind springbar, die Sumpfwelle bewegt eine 75 px tiefe Front durch einen angekündigten 650 px langen Korridor. Verfallsblüte: fünf äußere Blütenfelder, verzögerter Kern und abschließendes Sporenband mit freier Lücke. Minions verschwinden bei Bossende oder nach 18 s.

## Countdown, Lebensdauer und Status

Geometriekomponente `scripts/attack_telegraph`: Kreis, Fächer, Linie/Rechteck, Ring. Sehr schwache Flächenkennzeichnung, dünne dezente Kontur, heller kleiner Uhrzeiger von zwölf Uhr im Uhrzeigersinn. Bei Vollendung ein kurzer Flächenblitz ohne zusätzlichen Schadensaufschub. Bewegte Geometrie bleibt an den Bossfiguren gebunden. Gefahren verwenden denselben Besitzer-Zeitwert wie ihre Attacke; neue Warnungen werden nicht schon im Erzeugungsframe um einen Schritt vorgerückt. Pause stoppt beide. Es existieren maximal 128 neue Gefahrenfelder und 256 feindliche Projektile.

Die Profiltabelle beschreibt den Angriffszustand; unabhängige Bodenfelder dürfen länger anhalten oder versetzt auslösen. Gift, Säure und Kontrollzeiten werden anhand echter Kontakte gesetzt. Getroffene und abgelaufene Felder besitzen eigene Treffer- und Lebensdauerschranken.

## Minibosse und frühere Varianten

`mini_sentinel` (Waldwächter, Minute 1) und `mini_warden` (Runenwächter, Minute 3) bleiben erhalten. Der Waldwächter verschießt alle 1,6 s ein sichtbares gewöhnliches Geschoss ohne Bodenwarnung; seine Sonderrotation enthält Bodenblitz und Wurf, keine große Geschossspezialattacke. Die Neun-Regel gilt für Hauptbosse.

Die alten IDs `storm_echo`, `rune_echo`, `ember_echo`, `void_echo`, `final_echo` waren generische Wiederholungsplatzhalter. Sie sind keine separaten vollständig implementierten Neun-Fähigkeiten-Bosse und werden nicht mehr ausgewählt. Die neuen Zufallstermine ersetzen ihre früheren festen Auftritte.

## Direkt testen

Hauptmenü → **Boss testen**. Boss, Spielminute, Klasse, Build, Schwierigkeit, einzelne Fähigkeit und Seed wählen. Der Direktknopf startet **Drache / Minute 15 / alle neun**. Einzelfähigkeiten oberhalb der Zeitfreischaltung werden abgewiesen. Direkte lokale Schnittstelle: `boss_test_start("storm_warden",15,"Mage",1337, -1, false,1)`; `-1` bedeutet Gesamtkampf. `boss_v2_force_attack(b,1..9)` startet eine konkrete freigeschaltete Fähigkeit.

F1 Schutz, F2 heilen/wiederbeleben, F3 nächste HP-Phase, F4 Boss auf 25%, F5 ausgewählte Attacke erneut, F10 Körperboxen. `BOSS_TEST_MENU_ENABLED` in `scripts/boss_test_mode` deaktiviert den Entwicklungszugang für spätere Release-Pakete. Tests wirken nur auf diese Runde; normaler Neustart/Verlassen entfernt Schutz, Testzeit und Presets.

## Status und Grenzen

Technische Prüfungen und konkrete Kampfdauerwerte stehen im [Boss-2.0-Bericht](BOSS_V2_REPORT.md) und `tests/reports/boss-v2-native.json`. Native Zustands-/Kontaktprüfungen sind von analytischer HP/DPS-Kampfdauer und menschlichen Spieltests getrennt. Die neuen WAVs sind eigene Synthese-Prototypen mit ausstehender Hörabnahme; generierte Animationen benötigen weiterhin künstlerische Feinabnahme.
