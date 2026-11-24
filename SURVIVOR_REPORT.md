# Gegnerdichte, Fortschritt und HUD

Aktueller Grafik-, Boss-, Kontakt- und XP-Stand: [ATMOSPHERE_REPORT.md](ATMOSPHERE_REPORT.md). Ältere abweichende Balancewerte unten sind historisch.
Stand: 22.11.2026. Dieser Bericht ersetzt die Balanceangaben in älteren Gameplay-/Boss-Berichten.

## Umsetzung

- `scripts/survivor_balance` verwaltet Kamera-Rechteck, sichtbare Zielauswahl, Gegnerpopulation und XP-Kosten zentral. Gruppen erscheinen unmittelbar außerhalb der Kamera; Mindestabstand zum Spieler 190 px. Entfernte Nachzügler werden ohne Belohnung entfernt. Nachfüllen alle 0,20 s mit höchstens sechs Gegnern pro Durchlauf.
- Mindestpopulation nahe der Kamera: 18 zu Beginn, 24 nach 1 min, 40 nach 3 min, 60 nach 5 min, 80 nach 10 min, 110 nach 20 min und 150 nach 30 min; Zwischenwerte linear. Bei zu wenig sichtbaren Gegnern werden bis zu 25 % zusätzliche anrückende Gegner angefordert. Technische Obergrenze 180; bei anhaltend langsamen Frames sinkt sie schrittweise bis 80 und erholt sich bei stabilen Frames.
- Normale Gegner: 78 HP, 11 Schaden, Geschwindigkeit 1,12. Ab 20 s Läufer (50/8/1,55), ab 90 s Tanks (165/15/0,82). Dazu zeitliche HP-/Schadensskalierung und Levelmultiplikatoren. Jeder reguläre Gegner gibt eine XP-Münze.
- Automatische Zielauswahl berücksichtigt nur Körpermittelpunkte innerhalb der Kamera mit 22 px Sicherheitsrand. Bereits fliegende Geschosse bleiben physikalische Geschosse und können anschließend den Bildrand überqueren.
- Waffenbasis bei 60 Hz: Schwert 44 Schritte Cooldown, Stab 58, Armbrust 70. Haste erhöht nur die Waffenfrequenz um 5 % je Stufe. Zauber-Cooldowns: Feuer 105, Eis 96, Blitz 126, Nova 240, Barrage 144, Heilung 480 Schritte.
- XP-Kosten der ersten Aufstiege: 1, 2, 3 Münzen. Ab Level 4: `ceil(4 + 1.3*n + 0.42*n*n)` mit `n = Level - 4`. Kein zusätzlicher Startauswahldialog. Münzen haben keine unkontrollierte GameMaker-Eigenbewegung mehr.
- Dünner XP-Balken unten, kleine Levelanzeige, Timer oben, vorhandener dreisekündiger HP-Balken am Spieler. Minimap unten rechts in allen drei Levels sichtbar, ohne Freischaltmechanik.
- Pause mit Navigation links, Charakter/Klasse/HP/Waffe mittig sowie sechs aktiven und sechs passiven Fähigkeiten rechts. Vollständige Namen, tatsächlich erreichte 0–9 Upgrade-Punkte und Hover-Tooltips. „Neues Spiel“ startet dieselbe Klasse im selben Level neu. Die lange Titelbildschirm-Beschriftung wird bei schmalen Fenstern umgebrochen.
- Bossleiste ohne schwarzen Kasten. Blitz trifft 3/4/5 verschiedene sichtbare Ziele auf Stufe 1/5/9, Sprungreichweite 140 px, erstes Ziel bis 400 px. Blauweiße Verbindungen entsprechen den tatsächlich beschädigten Zielen; kein Mehrfachtreffer desselben Ziels pro Kette.
- Kleine statusabhängige Feuer-, Eis- und Blitzpartikel, Tönung und dezentes Leuchten. Keine eigenständigen Partikelinstanzen. Effekte enden mit ihrem tatsächlichen Status.
- „Ton im Hintergrund abspielen“ ist standardmäßig aus und wird in `firstgame_audio.ini` gespeichert. Fokusverlust senkt die Master-Ausgabe auf null; Musikinstanzen und getrennte Musik-/Effektlautstärken bleiben erhalten. Kein Neustart der Musik bei Fokuswechsel. Die vorhandenen 3 Musikprototypen und 27 Effekte bleiben erhalten.
- Zweiter Sprungdruck am Scheitelpunkt wird vor dem Physikfortschritt ausgewertet; dadurch stimmt das Zeitfenster auch bei 30 Hz. Kein automatischer Slide nach normalem Sprung.

## Prüfung und Messwerte

- Normaler Windows-VM-Build und ZIP erfolgreich: `output/production-build/20261122-155925/FirstGame.zip`. Keine Testeingaben im Produktionsbuild.
- `gm_project_check`: 283 Ressourcen, keine Probleme, keine Warnungen.
- `python tests/tools/run_survivor_smoke.py`: 186 erfolgreiche Prüfungen, neun echte Klassen-/Levelstarts, Exitcode 0. Eingaben werden ausschließlich in einer isolierten Projektkopie injiziert. Ergebnis: `tests/reports/survivor-smoke-result.json`.
- Geprüft: Pause/Fortsetzen, echte Münzkollision mit erstem Level-up, Auswahl, Kamera, Minimap aller Levels, Zielbegrenzung, eindeutige Kettentreffer mit realem HP-Abzug, Statusablauf, neun Upgrade-Punkte, HP-Anzeigedauer, Sprung bei 30/60/120 Hz, Fokus-Muting und unveränderte Musikinstanz, Spawngruppen und Nachfüllen.
- Frühe Population: 23 lebende und sichtbare Gegner. Native Waldläufersequenz über 480 Frames: maximal 26 lebende und sichtbare Gegner; mittlere gelieferte Framezeit 16,6664 ms, ungefähr 60 Hz.
- Separater Lastaufbau: 150 lebende Gegner, 150 kameranahe, 63 tatsächlich im Bild. Mittlere CPU-Zeit allein ihrer Step-Logik 2,09 ms. Das ist keine Messung der gesamten Render-/GPU-Leistung mit 180 Gegnern.
- Visuelle Fixtures bei 800 × 600: Pause mit allen zwölf Fähigkeiten, Tooltip, leere Pause, Level-up, Kettenblitz, Gameplay und Bossleiste. Bilder liegen im jüngsten `output/survivor-smoke`-Ordner.
- Zusätzlich normalen Build im tatsächlichen Windows-Fenster geprüft: Gameplay mit Timer/XP/Minimap, Game Over, dreispaltige Pause mit korrekter Charakter-/HP-Anzeige und Einstellungen mit Hintergrundton „Aus“. Testfenster danach geschlossen.

## Kurze Fortschrittsrechnung

Eine Münze je Kill, sofort eingesammelt; keine Truhen oder sonstigen Boni. Dies ist eine mathematische Budgetrechnung, keine gemessene Killrate.

| Kills/min | Level nach 1 min | Level nach 30 min |
|---|---:|---:|
| 60 | 9 | 26 |
| 120 | 11 | 32 |
| 240 | 14 | 39 |

## Verbleibende Grenzen

Kein vollständiger 30-Minuten-Spieltest und kein vollständiger GPU-Stresstest mit 180 Gegnern. Schwierigkeitskurve und langfristige Waffen-/Gegnerbalance benötigen weitere Spieltests. Fokuswechsel und Audioinstanzverwaltung wurden technisch geprüft; subjektive Hörqualität wurde dabei nicht bewertet. Die Musik bleibt ausdrücklich ein programmatisch synthetisierter Chiptune-Prototyp.

Die älteren Smoke-Einstiege leiten auf die aktuelle Survivor-Suite weiter. Frühere Harness-Dateien bleiben als historischer Stand erhalten.
