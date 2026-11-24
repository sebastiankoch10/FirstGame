# Grafik, riesige Bosse und Spielbalance

Stand: 22.11.2026. Dieser Bericht ersetzt die XP- und Kontaktschadensangaben früherer Berichte.

## Grafik und Licht

Die vorhandene freigegebene Waldgrafik bleibt erhalten und erhält eine deutlich dunklere, kühle Grundbeleuchtung. Der Spieler hat ein schwaches Orientierungslicht. Keine alten Umgebungsgrafiken wurden zurückgeholt.

`scripts/atmosphere` berechnet eine gemeinsame Lichtfläche in halber Kameraauflösung und multipliziert sie mit dem bereits gezeichneten Weltbild. Radiale farbige Lichter erhöhen dort die Beleuchtung und hellen dadurch Boden, Figuren und Umgebung tatsächlich auf. Oberfläche und Radialtextur werden wiederverwendet; verlorene oder falsch große Oberflächen werden neu angelegt. Keine Schatten-/Normalmap-Simulation.

Maximal 72 Lichtquellen und 24 kurzlebige Impulse. Spieler, Einschläge, Projektile und Kettenblitze erhalten Vorrang vor Statuslichtern. Feuer und brennende Gegner leuchten warm und leicht schwankend; Eis leuchtet kühl; elektrische Zustände und Kettenblitze blauweiß. Magische Geschosse tragen wandernde Lichtquellen. Feuerexplosionen erzeugen größere Impulse. Bossblitze erhellen mit bis zu 700 px Radius einen großen Teil der Kamera, klingen schnell ab und überbelichten die ursprünglichen Farben nicht dauerhaft. Warnkreise, feindliche Projektile und Boss-Pfeil werden anschließend darüber gezeichnet; das HUD wird nicht abgedunkelt.

Volle HP-Leisten normaler Gegner werden ausgeblendet; nach tatsächlichen Treffern erscheinen kleine Leisten kurzzeitig. Dadurch verdecken Hunderte volle Balken nicht dauerhaft die Figuren.

Kleine Flammen, Glut, Eiskristalle und Funken sind an echte Status-Timer gekoppelt. Die frühere zusätzliche additive Lichtberechnung pro normalem Gegner entfällt. Der neue Lichtpass bündelt die Beleuchtung.

## Neuer Krieger und Bossmodelle

Neues Kriegerdesign mit gemeinsamen Proportionen und gleicher Skalierung in allen Richtungen, einschließlich gespiegelt dargestellter Seitenansicht. Neu importierte Ressourcen für Idle, Walk, Run, Attack, Jump, Fall, Dive, Slide, Dodge, Hurt und Death. Eigene Todesposen laufen auch hinter dem Game-Over-Menü ab. Charakterauswahl und Pause zeigen das neue Modell. Quellen und genaue Animationsgrenzen: `FirstGame_ArtPack/atmosphere_v2/README.md`.

Neue größere Waldgolem- und Sturmdrachenbilder statt beliebig hochskalierter normaler Monstersprites. Ungefähre sichtbare Höhe: Miniboss 108 Weltpixel, frühe Hauptbosse 220, späte Hauptbosse 310. Der späte Drache belegt bei 800 × 600 Kamera je nach Pose ungefähr ein Fünftel bis ein Viertel des Bildes. Die Posen können breiter als die Kollisionskörper sein; Flügel-/Geweihspitzen sind keine verpflichtenden Trefferflächen.

Stabile Körpermasken: Halbbreite 44/88/132 px und Körperhöhe entsprechend 80 % der definierten Modellhöhe. Masken werden nicht aus wechselnden Angriffsposen abgeleitet. Projektil-, Explosions-, Schwert- und Kontakttreffer berücksichtigen die größere Körpergeometrie. Auch ein Feuerball am äußeren Bosskörper muss wirklich Schaden verursachen.

Verfolgung während Erholungsphasen mit sanfter Geschwindigkeitsanpassung; im Windup steht der Boss für lesbare Warnungen. Ein horizontaler Abstand von 35 px verhindert hektisches Spiegeln um den Spieler herum.

## Bossnavigation

Zentrale Parameter: mindestens 850 px Abstand, vollständig außerhalb des Kamerabereichs für 2,5 s, danach 0,8 s sichtbare Ankunftswarnung. Ein gültiger Zielpunkt hält mindestens Körperradius plus 210 px Abstand zum Spieler und liegt innerhalb des Raums. Alte Bossgefahren werden bei Repositionierung entfernt. Nach Ankunft folgt eine kurze Intro-Pause; Teleport-Cooldown 12 s. Der Boss darf dadurch keinen unvermeidbaren Kontakttreffer erzeugen.

Ein kleiner goldener Pfeil nahe dem Spieler folgt geglättet der tatsächlichen Position des aktuellen Bosses. Er bleibt bei Offscreen-Bossen sichtbar und verschwindet nach deren Tod. Der vorhandene Encounter-Manager lässt weiterhin nur einen relevanten Boss gleichzeitig zu.

## Kontaktschaden und Magnet

Gewöhnliche Treffer setzen keine globale Unverwundbarkeit mehr. Jeder Gegner besitzt einen eigenen Kontaktangriffszeitpunkt mit 0,65 s Abstand. Verschiedene Gegner können daher im selben Frame Schaden verursachen; derselbe Gegner trifft innerhalb seines Intervalls nur einmal. Bosszonen besitzen weiterhin ihre individuelle Einmal-Sperre; feindliche Geschosse werden beim Treffer entfernt. Schaden endet regulär mit dem Tod des Spielers.

Sprung/Slide schützen weiterhin gegen gewöhnlichen Bodenkontakt, Dodge bleibt eine Schutzmechanik. Hohe Bossgeschosse können einen springenden Spieler treffen und lassen sich per Slide vermeiden. Vertikale Bossblitze treffen unabhängig von Sprung/Slide; ihre deutliche Bodenwarnung erlaubt das Verlassen der Zone. Dodge kann sie ebenfalls abfangen.

Der neue Magnet-Orb hat eine eigene Grafik. Jeder Mini-/Hauptboss hinterlässt garantiert einen, normale Gegner mit zentral konfigurierten 0,6 %. Einsammeln markiert alle zu diesem Zeitpunkt existierenden Münzen. Sie bewegen sich mit bis zu 720 px/s auf die aktuelle Spielerposition zu, ohne GameMaker-Eigenbewegung oder Überschießen. Reguläre einmalige Münzgutschrift, Pausensperre und zentrale Soundbegrenzung bleiben wirksam. Später neu erzeugte Münzen werden durch diesen bereits eingesammelten Orb nicht automatisch magnetisiert.

## Erfahrungskurve

Ein XP-Punkt pro normalem Gegner; vorhandene direkte Boss-XP und eine Auswahl aus der Bosstruhe bleiben erhalten. Die Startwaffe zählt nicht als Fähigkeitsauswahl. Erste Kosten 1, 2, 3 Münzen; ab Level 4 zentral:

`ceil(4 + 1.45 * (Level - 4))`

Keine kostenlose Startfähigkeit, keine erzwungene Reihenfolge, maximal zwölf Fähigkeiten mit jeweils neun Stufen. Ein Level-up verändert die HP nicht automatisch. Vitality erhöht weiterhin beim bewussten Erwerb das Maximum und die HP um seinen eigenen Bonus; Healing Pulse bleibt ein separater Zauber.

`tests/tools/simulate_atmosphere_progression.py` liest die Parameter direkt aus der GML-Konfiguration. Die folgenden Werte sind verfügbare Auswahlschritte aus einer Sekundenrechnung, keine gemessenen Spiel-Killraten. Angenommen werden sofort besiegte planmäßige Bosse mit eingesammelten Truhen; Menüpausen zählen nicht zur Spielzeit.

| Verlauf / angenommene Kills je Minute | Eingesammelte Münzen | 5 min | 10 min | 15 min | 20 min | 25 min | 28 min | 29 min | 30 min |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Schwach: 25 + 5 × Spielminute | 75 % | 19 | 29 | 39 | 48 | 58 | 62 | 64 | 67 |
| Solide: 35 + 9 × Spielminute | 90 % | 24 | 37 | 51 | 64 | 77 | 84 | 86 | 90 |
| Sehr erfolgreich: 45 + 14 × Spielminute | 100 % | 28 | 45 | 62 | 79 | 96 | 105 | 108 | 108 |

Im sehr erfolgreichen Modell werden 108 Schritte bei Minute 28,83 verfügbar. Das ist ein Balancing-Ziel unter diesen Annahmen, keine zeitliche Freischaltsperre und keine Garantie für jeden Build. Tatsächliche Kill- und Sammelraten über 30 Minuten müssen noch durch Spieltests ermittelt werden.

## Verifikation

Aktuelle Runtime-Ergebnisse stehen in `tests/reports/atmosphere-smoke-result.json`, die vollständige Rechentabelle in `tests/reports/atmosphere-progression.json`. Die Suite baut eine isolierte Windows-VM-Projektkopie mit Testeingaben; der normale Build enthält diese Eingaben nicht.

Geprüft werden neun echte Klassen-/Levelstarts, Münzkollision/erstes Level-up ohne Heilung, Pause/Fortsetzen, Kamera und Minimap, Fähigkeiten-UI, Kettenblitz, Statusablauf, Bewegungsfenster und Audiofokus. Neu hinzu kommen dreißig gleichzeitige Angreifer, individuelle Wiederholsperren, Boden-/Luftschutz, große physische Bossmasken mit tatsächlichen Randtreffern, Boss-Pfeil, angekündigte sichere Repositionierung/Cooldown, garantierte Mini-/Hauptboss-Orbs sowie 500 vollständig und exakt einmal eingesammelte Magnetmünzen.

Native Draw-Ausgaben zeigen den abgedunkelten Wald, den neuen Krieger, einen großen Drachen, Statuslichter und die deutliche Aufhellung durch den Blitzimpuls. Zusätzlich wird die reale Lichtfläche vor/nach dem Impuls ausgelesen. Ein kurzer Lastaufbau mit 153 normalen Gegnern, vielen aktiven Feuerzuständen und dem großen Drachen prüft die Grenze von 72 Quellen. Screenshot-/Base64-Logging liegt außerhalb des Framezeit-Messfensters. Die Messwerte werden im JSON ausgewiesen; daraus wird kein Dauerleistungsversprechen abgeleitet.

## Noch offen

Weitere gezeichnete Zwischenbilder für weichere Charakter- und Bossanimationen; individuelle Designs/Mechaniken für spätere Echo-Bosse; längere GPU-/Leistungstests und ein erfolgreicher vollständiger 30-Minuten-Spieltest mit tatsächlichen Kill-/Sammelraten. Keine neuen Lasermechaniken wurden hinzugefügt; die vorhandenen Blitz-, Fächer-, Ring- und Flächenangriffe wurden aufgewertet. Es wurden keine neuen Klassen/Level und kein Git-Push angelegt.

## Abschließender gemessener Stand

221 Prüfungen bestanden, neun Klassen-/Levelkombinationen, Runtime-Exitcode 0. Projektintegrität: 332 Ressourcen, keine Probleme/Warnungen. Normaler Build und ZIP erfolgreich, ohne Test-Hooks: `output/production-build/20261122-165520/FirstGame.zip`.

Native Waldläufersequenz: 480 Frames, bis zu 28 sichtbare Gegner, mittlere Framezeit 16.6656 ms. Synthetischer Lastaufbau: 153 normale Gegner plus großer Drache, 72 Lichtquellen, 45 gemessene Frames ohne Bildexport; Mittel 17.360 ms, Median 16.661 ms, langsamstes Bild 54.776 ms. Licht-Submission allein 0.259 ms CPU, kein separater GPU-Timer. Magnettest: 500 Münzen korrekt gutgeschrieben; schnelle direkte Logiksimulation, kein 30-Minuten-Spieltest.

Normales Windows-Spielfenster zusätzlich über echte Betriebssystemeingaben geprüft: Titel, neue Kriegerauswahl, Waldstart, dunkle Umgebung mit Spielerlicht, XP/Timer/Minimap und Game Over bei unbewegtem Stehen in der Horde. Pause mit Fähigkeiten, Boss-/Lichteffekte und die abschließende Bereinigung der Gegnerleisten wurden über native Runtime-Renderfixtures geprüft. Testfenster geschlossen.

Gespeicherte native Renderfixtures: [Dunkler Wald](tests/reports/atmosphere-darkforest.png), [Blitzimpuls](tests/reports/atmosphere-stormlight.png), [Synthetischer Lichtlastaufbau](tests/reports/atmosphere-litcrowd.png).

Aktueller erster Hauptdrachenkampf, Boss-Orbs und Run-Statistiken: [DRAGON_REPORT.md](DRAGON_REPORT.md).
