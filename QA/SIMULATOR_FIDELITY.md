# Abgleich der nativen Simulation

Die Simulationsumgebung verwendet die kopierte Produktions-GML im installierten GameMaker-Runner 2024.14.4.268. Python erstellt die isolierte Projektkopie, startet den Runner und liest dessen Ergebnisse; Python berechnet keine Ersatz-Kampflogik. Test-Hooks werden nicht im normalen Projekt registriert.

## Nachgewiesene Eigenschaften

- Logischer Schritt: 1/60 Sekunde. Die Engine bleibt ebenfalls auf 60 FPS; Beschleunigung erfolgt ausschließlich durch mehrere vollständige Spielschritte pro Engine-Frame.
- Derselbe Zustand nach 600 Ticks bei Batchgrößen **1, 60 und 600**: Hash `fbd362e1884e2bfcbe31b904e3dbd121`. Alle drei Exporte melden `native_room_speed=60`, `logical_hz=60` und zehn physische Umgebungsobjekte. Daten: `data/native-validation-v2.jsonl`.
- Gerenderte native Kollisions-/Zeit-Fixture: tatsächlicher Skelettkontakt verursacht elf HP; Münzen werden über die echte Körpermaske gesammelt; ein tatsächlicher Umgebungs-Fußabdruck blockiert. Bei 60 DPS verursachen 60 Monster-Steps beziehungsweise 60 Boss-Schritte von 1/60 s jeweils 60 HP; 60 Statusframes laufen in einer Sekunde ab.
- Die Fixture ist im Log `output/native-mc-baseline/20261123-173646/fixture-b1-s710101-173759.log` und der zugehörigen PNG dokumentiert. `data/native-fixtures.jsonl` ist ein **unvollständiger Fixture-Export**, keine vollständige Spielrunde.
- Produktionsbewegung, Spawner, Gegner, Trefferproben, Cooldowns, Beute, Schaden und Bossmechaniken werden aufgerufen. Weder Spieler-HP noch Gegner-HP werden für vollständige Runs erhöht; kein erzwungener Tod, kein verkürztes Run-Ende. Ein vollständiger Run endet durch echten Tod oder bei 1.800 simulierten Sekunden als rechtszensierter Überlebender.
- Unabhängig davon bestehen im aktuellen nativen Regressionstest **811 gezielte Prüfungen**, darunter echte Player-/Controller-Step-Ereignisse mit injizierten Eingaben und ein kurzer gerenderter 150-Gegner-Fall. `data/regression.json` beschreibt deren genaue Reichweite. Diese 811 Prüfungen sind keine vollständigen Runs.

Der oben genannte dreifache Hash ist der erste korrigierte Kernabgleich. Die anschließend verbesserte Strategie `visible-countdown-v2` wurde zusätzlich für **alle drei Klassen** bei Batch 1 und 600 über je 600 Ticks mit identischen Zuständen geprüft; Beleg: `data/native-fidelity-v2.json` und die dort benannten Einzeldateien. Nach der Münz-Korrektur stimmen auch die Mage-/Experienced-Proben `data/native-after-validation.jsonl` und `data/native-after-validation-b1.jsonl` überein: Hash `2237ba94bbd1e1b64426a47e6cba8354`. Alle melden native und logische 60 Hz.

## Vor der gültigen Stichprobe behobene Testfehler

1. Die erste Beschleunigung über Engine-FPS 10.000 änderte `room_speed` und damit Verbrennung und Statuszeiten. Solche Pilotdaten sind ungültig und werden ausgeschlossen. Insbesondere die 15 frühen Boss-Pilotkämpfe unter `logs/invalid-room-speed-boss-pilot.jsonl` zählen nicht.
2. Drei alte Projektil-Kollisionsdateien existieren auf der Platte, sind jedoch nicht in den Objektressourcen registriert. Sie manuell auszuführen hätte zusätzliche Treffer erzeugt. Der Simulator führt sie nicht aus; er verwendet die registrierten Produktions-Step-Proben.
3. Die normale Welt-Darstellung erzeugt den Cache physischer Umgebungsobjekte. Ohne Rendering fehlte dieser Cache. Die Testkopie initialisiert denselben Filter und dieselben tatsächlichen Fußabdrücke beim Reset. Hindernisse werden nicht entfernt.
4. Eine vollständig ausgebaute Fähigkeitenauswahl kann eine Informationskarte mit ID -1 enthalten. Der Bot behandelt diese ohne Zugriff auf eine fehlende Zauberdefinition.
5. Reservierte GML-Bezeichner verhinderten frühe Test-Builds. Das waren Testwerkzeug-Fehler, keine neu nachgewiesenen Produktionsfehler.

## Grenzen der Übereinstimmung

Der manuelle Tick ruft Controller/Welt, Spieler, Spawner, Gegner, Boss-Todesanimationen, Projektile, Beute und Kontaktprüfungen in einer festen Gruppenreihenfolge auf. Diese Reihenfolge ist reproduzierbar. Die normale Engine-Reihenfolge sämtlicher dynamisch erzeugter Instanzen wurde nicht vollständig per Trace gleichgesetzt. Ein Tick Unterschied zwischen Projektiltreffer, Gegner-Tod und Drop bleibt möglich. Batch-Parität beweist Konsistenz der Beschleunigung, keine vollständige End-to-End-Identität mit einer menschlich gespielten Engine-Sitzung.

Eine gesonderte Quellprüfung findet bei den aktuellen Körpermasken keine Abhängigkeit von automatisch fortgeschalteten Grafikframes: Spieler, normale Gegner und Bosse verwenden feste Körpermasken; Münze, Truhe und Magnetorb besitzen jeweils einen Frame; Projektile verwenden ihre tatsächlichen eigenen Trefferproben. Das ist eine **statische Prüfung**, kein zusätzlicher vollständiger Lauf.

Audioausgabe und Renderaufwand werden in der Testkopie unterdrückt. Visuelle Zustände und notwendige Weltmechanik bleiben erhalten. Vollständige Simulationsläufe messen keine normale Renderleistung. Die normalen nativen Bildaufnahmen und der Produktions-Build werden getrennt geprüft.

Die Auswertung gilt für die nominelle 60-Hz-Zeitbasis. Die vorhandene adaptive Spawn-Obergrenze erhält dabei 16,67 ms logische Schrittzeit, nicht die CPU-Zeit eines beschleunigten Tick-Blocks. Eine bei dauerhaft langsamen echten Frames reduzierte Gegnerobergrenze wird deshalb nicht als zusätzlicher Hardware-/Low-FPS-Fall simuliert. Das verhindert zugleich, dass ein langsamer Testrechner die Balance-Stichprobe künstlich erleichtert.

## Bot- und Statistikgrenzen

Die Bots verwenden sichtbare Gegner, aktuelle Projektile und sichtbare Warnflächen sowie legale Bewegungs-/Sprung-/Ausweicheingaben. Sie lesen keine zukünftige Bossrotation oder noch nicht ausgelösten Zufallsentscheidungen. Reaktionsverzögerungen und Auswahlregeln sind im Testskript gespeichert. Die technische Ausweichheuristik ist kein vollständiger Wegfindungs- oder Unvermeidbarkeitsbeweis.

Gleiche Seeds und Startbedingungen erlauben gepaarte Vergleiche. Verschiedene Klassen verbrauchen den gemeinsamen Produktions-Zufallsstrom jedoch unterschiedlich. Identische Seeds erzwingen deshalb keine bildidentischen Welten oder Spawnfolgen über alle Klassen hinweg. Die separate Zufallsfolge für Fähigkeitenangebote ist reproduzierbar; die vom Build abhängigen Auswahlmöglichkeiten können sich unterscheiden.

Bei Flächenattacken bedeutet „bedroht“ auch eine geometrische Exposition während der sichtbaren Warnung. Bei Projektilen wird bislang tatsächlicher oder geschützter Kontakt erfasst; erfolgreich weggelaufene Projektile ohne Kontakt sind nicht vollständig im Bedrohungsnenner enthalten. Diese beiden Trefferquoten dürfen nicht gleichgesetzt werden. Aus `Treffer / bedroht` bei Projektilen folgt weder Unvermeidbarkeit noch eine menschliche Trefferwahrscheinlichkeit.
