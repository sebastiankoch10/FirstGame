# QA – laufender Arbeitsstand

Stand UTC: 2026-11-23T22:04:41.396148+00:00

- Gültige vollständige native Runs: **192**, davon 180 primäre V2-Runs und 12 V1-Kalibrierungen.
- Laufende Einzelzähler werden aus vollständig gespeicherten JSONL-Zeilen gebildet; eine noch laufende Runde zählt nicht.

| Kohorte | Vollständig | Ziel |
|---|---:|---:|
| baseline-v2-a | 36 | 36 |
| baseline-v2-b | 36 | 36 |
| after-v2-a | 36 | 36 |
| after-v2-b | 36 | 36 |
| holdout-v2 | 36 | 36 |

- Primäre isolierte Bosskämpfe: Baseline 180, unabhängige Seeds 180, ausgewählte Nachher-Prüfungen 15.
- Zusätzlich 195 gültige Boss-Ausführungen mit erster Bot-Strategie und 15 wiederholte V2-Piloten archiviert; nicht als unabhängige primäre Stichprobe vermischt. 15 frühe Bossläufe mit falscher Engine-Zeitbasis sind ungültig und ausgeschlossen.
- 654 kontrollierte native Fähigkeitsfenster und zehn bekannte HP-/Quellenprüfungen bestanden.
- Aktuelle allgemeine native Regression: 811 Prüfungen bestanden; Steuerung, Sprung/Slide/Ausweichen, Beute, Auswahl, Pause, Neustarts, Bossmechaniken, GUI-Aufnahmen und kurzer gerenderter Stressfall.
- Beschleunigung: gleiche Zustände bei Batch 1/60/600; alle drei Klassen mit verbesserter Strategie geprüft. Engine und Logik bleiben bei 60 Hz. Nachher-Mage-Abgleich ebenfalls identisch.
- Bestätigte Spieländerungen: normale Münzen 252 → 420 Pixel/Sekunde; Boss-Hurt-Frames auf tatsächliche Sprite-Länge begrenzt. Spieler-/Boss-HP und Schadenswerte bleiben unverändert.
- Münz-Fixture: vorher zwei tatsächliche Ranger-Sammelfehler; nachher alle vier Bewegungsfälle bestanden.
- Grafik: 826 Sprites/2.551 Frames geprüft; alle 5.102 PNGs einschließlich 258 Drachen-Dateien unverändert. Native GUI-Prüfzustände bei 1280×720 und 800×600 gesichtet.

Status: Auswertung, Berichte und finale Prüfungen abgeschlossen; Grenzen und priorisierte Resttests stehen in QA_SUMMARY.md.
