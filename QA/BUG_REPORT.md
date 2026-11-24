# Bestätigte Fehler und verbleibende Prüfgrenzen

## Behoben: Normale Münzen holen den laufenden Ranger nicht ein

**Gameplay-Bug.** Normale Münzen hatten 252 Pixel/Sekunde. Der Ranger läuft bereits ohne Upgrade genauso schnell; eine 80 Pixel hinter ihm angezogene Münze bleibt deshalb dauerhaft hinter ihm. Fleet Footed verschärft das Problem und kann die Münze wieder aus dem normalen Sammelradius bringen.

Reproduktion im nativen Runner: `python QA/tools/run_qa_regression.py --coin-fixture=baseline` wurde vor der Änderung ausgeführt. Vier tatsächliche Player-/Coin-Step-Fälle, jeweils drei Sekunden freie Geradeausbewegung, gleiche Ausgangsdistanz. Die Bewegungsstrecken bestehen; die zwei Ranger-Sammelprüfungen schlagen gezielt fehl. Rohmessung: `data/moving-coin-baseline.json`. Eine frühere zu enge Positions-Toleranz ist separat unter `logs/moving-coin-initial-tight-tolerance.json` archiviert und kein weiterer Produktionsfehler.

Korrektur: ausschließlich `normal_coin_speed` auf 420 Pixel/Sekunde. Gleicher nativer Nachtest: alle zehn Assertions bestanden. Sword sammelt bei Tick 17 statt 64, Mage bei Tick 16 statt 46; Ranger bei Tick 23 statt gar nicht, Ranger mit Fleet Footed 9 bei Tick 38 statt gar nicht. Die Kontrollstrecke bleibt gleich. `data/moving-coin-after.json` und `BEFORE_AFTER.md` dokumentieren gezielten Nachtest und vollständige Runs.

Eine zusätzliche unabhängige reine Quellprüfung findet in den beiden Produktionsänderungen keine substantiierte Regression: `min(dist, speed*dt)` verhindert Überschießen; Sammelradius und Magnetwerte sind unverändert. Höchstes Ranger-Bodentempo mit Fleet Footed ist 316,8, Sprungtempo 396 Pixel/Sekunde. Kurze Dodge-/Dive-/Slide-Spitzen können 420 überschreiten; sie wurden von dieser Quellprüfung nicht als eigene Sammel-Fixtures ausgeführt. Diese Prüfung zählt nicht als zusätzlicher Runtime-Test.

## Behoben: Boss-Trefferpose springt zum ersten Frame zurück

**Grafikfehler.** Die Trefferreaktion der neuen Bosse berechnet zeitweise Index 2, die zugehörigen Sprites enthalten aber nur zwei Frames. Der Zeichner begrenzt Hurt-/Death-Frames jetzt auf die tatsächliche Sprite-Länge. Die vier vorhandenen Todesframes bleiben erhalten. Kein Sprite wurde geändert. Ressourcenbeleg, aktuelle native Aufnahmen bei Hurt-Timer 4/2 und Umfang stehen in `VISUAL_AUDIT.md`.

## Bereits vorhanden: Drei nicht registrierte Kollisionsdateien

**Metadatenbefund.** `ObjectFireball`, `ObjectIceball` und `ObjectLightningball` besitzen jeweils eine alte Datei `Collision_ObjectMonster.gml`, die nicht in ihrer `.yy`-Ereignisliste registriert ist. Die `.yy`-Dateien und diese drei Quellen sind gegenüber der gesicherten Baseline bytegleich. Der normale Trefferpfad verwendet die tatsächlich registrierten Step-Proben.

Diese Dateien werden weder neu registriert noch gelöscht. Registrieren könnte neben den bereits vorhandenen Trefferproben zusätzliche Treffer auslösen. Die strenge Ressourcenprüfung meldet den Altbestand weiter; `data/project-validation.json` trennt ihn von neuen Fehlern. Ein normaler erfolgreicher Build macht den Metadatenbefund nicht unsichtbar.

## Vor der gültigen Auswertung korrigierte Testwerkzeugfehler

Die erste Beschleunigung änderte `room_speed`; frühe Daten waren dadurch ungültig. Außerdem fehlte ohne Draw zunächst der Hindernis-Cache, die Testkopie führte kurzzeitig unregistrierte Kollisionsdateien aus, und die erste Bot-Strategie verwendete Sprung/Ausweichen unpassend gegen manche Warnungen. Ein Informationskarten-Randfall und reservierte GML-Bezeichner waren weitere Testfehler. Diese Befunde sind keine behaupteten neuen Gameplayfehler. `SIMULATOR_FIDELITY.md` beschreibt Korrekturen, ausgeschlossene Daten und Belege.

## Verbleibende Grenzen nach Priorität

1. **Noch nicht getestete Funktion / Balancing:** Eine belastbare vollständige 30-Minuten-Progression und vollständig ausgebaute Builds benötigen ausreichend späte Überlebende. Fehlende Beobachtungen dürfen nicht durch erfundene Level, DPS oder Erfolgschancen ersetzt werden. Aktuelle Reichweite: `SIMULATION_REPORT.md`.
2. **Boss-Fairnessproblem zur weiteren Prüfung:** Der technische Bot ist eine sichtbare, legale Heuristik, kein vollständiger Erreichbarkeitsbeweis. Bei Projektilen ist der Bedrohungsnenner eingeschränkt. Kein Angriff wird allein wegen eines Bot-Treffers als technisch unvermeidbar bezeichnet; `BOSS_BALANCE.md` benennt auffällige Kandidaten.
3. **Performancegrenze / weitere Prüfung:** Ein kurzer gerenderter 150-Gegner-Fall während paralleler Simulationen misst 19,44 ms im Mittel und 27,36 ms maximal über 60 Frames. Nach Abschluss aller Monte-Carlo-Prozesse misst derselbe kurze Fall **16,667 ms im Mittel und 17,044 ms maximal** (`data/performance.json`, drei Assertions bestanden). Das stützt rund 60 FPS in diesem kurzen ruhigen Prüffall, isoliert aber weder GPU- noch normale CPU-Grenzen und garantiert keine dauerhaften 60 FPS. Keine Langzeit-Speicherprüfung behauptet.
4. **Noch nicht getestete Funktion:** Die vollständige Reihenfolge dynamischer Engine-Instanzen ist nicht per End-to-End-Trace mit der festen Simulator-Gruppenreihenfolge gleichgesetzt. Ein Tick Treffer-/Drop-Verschiebung bleibt möglich. Native Batch-Parität und gezielte Runtime-Prüfungen sind dokumentiert.
5. **Grafikproblem / weitere Sichtprüfung:** Wiederholte Ausgangsposen einzelner Bewegungen; weitere Fensterseitenverhältnisse und längere Sichtprüfungen bei stark überlappenden Effekten. Keine pauschale Weichzeichnung oder schlechtere Ersatzzeichnung eingebaut.

Die Abschlussberichte unterscheiden nachgewiesene Fehler, auffällige Messungen und ungetestete Bereiche. Ein erfolgreicher Build allein wird nicht als Gameplay-Freigabe gewertet.
