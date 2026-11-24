# FirstGame – Klassenkombos und Drachen-Countdown

Neuere Hauptboss-/Freischaltungs-/Testmenü-Änderungen: [BOSS_V2_REPORT.md](BOSS_V2_REPORT.md). Dieser Bericht bewahrt den zuvor geprüften Klassenstand.

## Referenzen und unveränderte Ressourcen

Alle drei tatsächlichen Konzeptbilder wurden geöffnet und analysiert. Im Projekt lagen sie ursprünglich unter anderen Namen direkt im ArtPack. Unveränderte Kopien liegen jetzt unter den gewünschten Referenzpfaden:

| Verbindlicher Pfad unter `FirstGame_ArtPack/References` | Unveränderte Originaldatei unter `FirstGame_ArtPack` |
|---|---|
| `Zaubermeisterin_Referenz.png` | `ChatGPT-Bild 22. Nov. 2026, 21_17_51.png` |
| `Waldlaeufer_Referenz.png` | `ChatGPT-Bild 22. Nov. 2026, 21_17_44.png` |
| `Drache_Attacken_Referenz.png` | `Drachenangriffs-Atlas im Pixelstil.png` |

Die Charakterreferenzen bestimmen Frisur, Kleidung, Farben, Waffen und Angriffe. Der rote Drache der Angriffstafel wurde **nicht** übernommen. Alle 67 gesicherten bestehenden Drachen-PNGs sind bytegleich erhalten. Zusätzliche Posen wurden anhand des bereits vorhandenen blauen Drachen erzeugt und unter eigenen `spr_fg_dragonextra_*`-Namen ergänzt.

## Zaubermeisterin

Neue aktive Darstellung: `magev3`, silberviolettes Haar, violett-blaue Robe mit Goldverzierungen, weißer Unterrock und Sternenstab. Acht Richtungen, acht echte Laufposen je Richtung, eigene Angriffs-, Mobilitäts-, Treffer- und Todesposen. 128 neue Sprite-Sequenzen verwenden 432 Frame-Dateien mit 256 unterschiedlichen Ausgangsposen. Die Kollisionsmaske bleibt unabhängig von der Animation stabil; Canvas 96×96, Ursprung (48,88). [Geprüfte Charaktervorschau](FirstGame_ArtPack/class_overhaul/character-preview.png).

Die automatische Startwaffe benötigt keinen aktiven Zauberslot. Ablauf: **Kristallprojektil → aufsteigender Stabbogen → Runenkreis → ballistischer Sternenorb → wieder Kristallprojektil**. Vorbereitete Angriffe werden einmal freigegeben und bei Richtungswechseln nicht zurückgesetzt. Basis: 25 + Power Schaden, 96 Frames Abstand vor Waffenhaste bei 60 Hz. Der Aufwärtsschlag verursacht 1,4-fachen Schaden in einem 120°-Fächer, Radius 155; der Runenkreis 1,8-fachen Schaden mit Radius 130. Flächenradien reagieren auf Wide Glyphs.

Der Sternenorb speichert Start und Bodenziel getrennt. Seine sichtbare Höhe folgt einer 180-px-Bogenbahn, der Flug dauert 0,85 s; anschließend kontrahiert er 0,15 s. Bei 1,0 s verursacht die Entladung 3,5-fachen Flächenschaden, Radius 170. Licht, Schweif, Zielkreis und ein eigener Implosions-Cue sind integriert.

## Waldläufer

Neue Darstellung: `rangerv3`, helles silberviolettes Haar, grün-goldener Umhang, leichte Lederrüstung, Bogen und Köcher. Acht Richtungen, Lauf-/Sprintdarstellung, Schuss- und Finisherposen, Mobilität, Treffer und Tod. 120 Sprite-Sequenzen verwenden 424 Frame-Dateien mit 256 unterschiedlichen Ausgangsposen. Gleiche Canvas-/Ursprungs- und Maskenregeln wie bei der Zaubermeisterin.

Die Startwaffe hat 6 + 0,5 × Power Grundschaden und 18 Frames Grundabstand. Der Zyklus ist unveränderlich: **1, 1, 3, 1, 1, 1, 1, 1, 5, 1, 1, Pfeilhagel**, dann zurück zum einzelnen Pfeil. Eine Salve zählt als ein Schritt. Pfeile besitzen eigene Trefferlisten und durchdringen Gegner, ohne dass ein Pfeil dasselbe Ziel nochmals trifft. Split Runes verstärkt den Projektilschaden; es verändert die verbindlichen Salvenzahlen der Klassenwaffen nicht. Seine Zusatzgeschosse gelten weiterhin für die passenden aktiven Zauber.

Der Pfeilhagel markiert Radius 125, aktiviert nach 0,4 s und verursacht fünf Flächenpulse im Abstand von 0,16 s zu jeweils 55% Waffenschaden. Fallende Pfeile sind auf mehrere Positionen im markierten Bereich verteilt; Naturpartikel und ein eigener Finisher-Cue ergänzen die Wirkung.

## Gemeinsame visuelle Entwicklung

Die vorhandenen Schwellen 1, 34 und 68 gelten für beide neuen Darstellungen. Sichtbare Projektile, Schweife, Leuchtkraft, Orb, Runen und Pfeilhagel nehmen zu. Die Vierer-/Zwölferfolge bleibt erhalten. Es gibt keine zusätzliche Freischaltsperre und kein separates Waffenlevelsystem. Die Schwertkombo und ihre Grafikressourcen wurden erhalten.

## Neun Drachenangriffe und vier Phasen

| Angriff | Warnung (s), Phase 1/2 | Aktive Dauer (s) | Grundschaden | Höhenbereich |
|---|---|---|---|---|
| Feuerstrahl | 1,20 | 1,00 | 36 je Kontaktintervall | hoch; Slide hilft |
| Feuerbogen | 1,00 | 0,70 | 32 je Kontaktintervall | Boden |
| Meteoritenregen | 1,80 + 0,22 je Einschlag | 1,80 Gesamtphase, 0,55 je Einschlag | 38 je Zone | alle |
| Flug/Bodeneinschlag | 1,50 | 1,10 | 42 je Kontaktintervall | Boden; Sprung hilft |
| Flügelsturm | 0,90 | 1,70 | 14 je Windprojektil, mit Rückstoß | hoch |
| Void-Orbs | 0,80 | 1,60 | 24 je Projektil | hoch |
| Magmaeruptionen | 1,05 | 0,55 | 64 je Zone | alle |
| Rotierender Feuerwirbel | 1,70 | 1,60 | 32 je Kontaktintervall | Boden |
| Violette Projektilsalven | 0,65 | 1,70 | 20 je Projektil | hoch |

Schaden wird mit dem beim jeweiligen Spielstand geltenden Gegner-Schadensfaktor multipliziert; Rüstung und Schutzfähigkeiten wirken anschließend. Strahl, Bogen und bewegte Ringe haben 0,35 s Trefferabstand pro Angriff, einzelne Bodenfelder treffen einmal. Strahl mindestens 1.200 px, bei Bedarf über die gegenüberliegende sichtbare Kamerakante hinaus; tatsächlicher Ursprung ist die annotierte Maulposition. Keine feste Rechtsausrichtung.

Magma: drei getrennte Felder, Radius 125, in späteren Phasen 135. Meteore: vier beziehungsweise sechs versetzte Ziele, Radius 75, jeweils eigener Warn-/Trefferzustand. Der Feuerwirbel hat einen sicheren inneren Bereich; seine aktive Ringzone wandert von 60–100 bis 270–310 px. Der Bodeneinschlag erzeugt einen springbaren expandierenden Bodenring. Windprojektile bewegen sich und stoßen den Spieler mit Kollisionsauflösung zurück. Void-Salven beginnen mit drei parallelen Bahnen und folgen mit fünf gefächerten Projektilen; die parallelen Bahnen werden zusätzlich einzeln markiert.

Ab Phase 3 werden die Warnzeiten von Strahl und Bogen mit 0,88 multipliziert. Keine globale Verkürzung großer Bodenwarnungen. In Phase 4 folgen drei statt zwei Projektilwellen. Zusätzliche violette Projektile beim Feuerwirbel erhalten einen eigenen gleichzeitig sichtbaren Fächer-Countdown; es werden keine unangekündigten Zufallsattacken eingestreut.

| HP | Phase | Feste Rotation |
|---|---|---|
| 100–über 75% | Einführung | Strahl, Bogen, Magma, Strahl |
| 75–über 50% | neue Mechaniken | Meteore, Void, Einschlag, Wind, Bogen |
| 50–über 25% | Eskalation | Feuerwirbel, Salven, Meteore, Magma, Strahl |
| bis 25% | Enrage | Void, Strahl, Meteore, Einschlag, Magma, Salven, Feuerwirbel, Wind |

Phasenschwellen werden anhand der HP erkannt und nach Abschluss des laufenden Angriffs an der Erholungsgrenze übernommen. Dadurch ändern sich angekündigte Trefferzonen nicht mitten im Countdown. Der Boss bleibt auch beim Phasenwechsel durch echten Schaden besiegbar. Verfolgung, sichere Teleport-Ankündigung, Hauptboss-Pfeil, Truhe und Orb bleiben erhalten.

Zusätzliche vierframeige Animationen: Flügelschlag, Abheben/Sturz/Landung, Void-Kanalisierung und Meteor-Beschwörung. Beim Flug wird die sichtbare Körperhöhe separat angehoben und der Bodenschatten angepasst. Bestehende Idle-, Lauf-, Atem-, Feuer-, Treffer- und Todesressourcen bleiben im Einsatz.

## Zentrales Countdown-System

`scripts/attack_telegraph` enthält Geometrie, Fortschritt, Hitprüfung und Darstellung für **Kreis, Fächer, Linie, Rechteck und Ring**, mit Position, Winkel, Größe, Dauer und Farbe. Kreis und Ring füllen ab zwölf Uhr im Uhrzeigersinn. Fächer füllen vom ersten zum letzten Winkel, Linien vom Ursprung zum Endpunkt. Der vollständige Umriss ist ab 0% sichtbar; die Füllung bleibt halbtransparent und die aktuelle Kante hell.

`elapsed / duration` stammt direkt aus dem Angriffsstatus. Die Darstellung besitzt keinen eigenen fortlaufenden Timer. Derselbe Update, in dem der Countdown voll ist, wechselt zu aktiv und führt bereits Kontaktprüfung beziehungsweise Projektilfreigabe aus. Ein Treffer setzt weiterhin wirklichen Kontakt voraus. Pausen halten Logik und Warnfortschritt gemeinsam an. Alle Warnungen liegen in Weltkoordinaten und bewegen sich korrekt mit der Kamera. Auch bestehende allgemeine Boss-Kreis-/Fächerwarnungen verwenden die zentrale Darstellung; die alte schnelle Konturwarnung wurde entfernt.

## Audio, Licht und Lebensdauer

16 tatsächlich neu erzeugte und importierte 32-kHz/16-Bit-Mono-WAVs: fünf Mage-Cues, drei Ranger-Cues und acht Drachen-Cues. Editierbare Quelle: `Audio/Sources/compose_class_dragon.py`; Ressourcen heißen `sfx_fg_mage_*`, `sfx_fg_ranger_*`, `sfx_fg_dragon_*`. Alle nutzen die zentrale Lautstärke-/Stimmenverwaltung. Gleichzeitige Magmazonen lösen nur einen gemeinsamen Startsound je Update aus. **Die Sounds sind eigene programmatische Synthese-Prototypen; eine menschliche Hörabnahme ist noch offen.** Insgesamt sind 70 WAVs technisch validiert: drei Musikstücke und 67 Effekte.

Neue Rasterressourcen: acht elementare Klassen-VFX-Sequenzen und acht Drachen-VFX-Sequenzen mit je acht Frames sowie vier separate Sternenorb- und vier Implosionsframes, insgesamt 136 VFX-Frames. Violett-blaues Klassenlicht, grüne Pfeilakzente, warme Feuer-/Magmablitze und violette Void-Energie verwenden die bestehende Beleuchtung. Klassenfelder sind auf 48, Drachenprojektile auf 256 begrenzt; Besitzerprüfung und feste Lebensdauern entfernen abgelaufene Gefahren. Kein neues Level, kein zusätzlicher Boss und kein neuer normaler Gegnertyp wurden ergänzt.

## Quelldateien und Grenzen der Animationen

Alle zwölf neuen Rasterquellen, Prompts, vorbereiteten Frames und Importwerkzeuge sind im Projekt erhalten: `FirstGame_ArtPack/class_overhaul`, `tests/tools/prepare_class_characters.ps1`, `prepare_class_effects.ps1`, `import_class_characters.py`, `import_class_effects.py`. Erzeugt wurde mit dem eingebauten Imagegen-Werkzeug; Prompts in `prompts.json` und `mage-orb-prompt.txt`. Die Konzepttafeln wurden nicht als beschriftete Spielsprites zugeschnitten. Der Ranger-Kampfatlas enthielt eine zusätzliche neunte Zeile; diese wurde beim überprüften Zuschnitt ausgeschlossen.

856 verwendete Charakterframes bedeuten **512 unterschiedliche Ausgangsposen**, nicht 856 unabhängig gezeichnete Posen. Sprint verwendet den Laufzyklus mit schnellerer Wiedergabe; Dodge und Slide teilen Mobilitätsposen. Idle atmet mittels einer dezenten Laufzeitbewegung eines Ausgangsframes; Drehungen verwenden die acht Ansichten. Einzelne Angriffe besitzen kürzere Posenfolgen als die Effektanimationen. Die erzeugten Figuren sind technisch integriert und geprüft, eine manuelle künstlerische Feinabnahme aller Stoffdetails und Rückansichten bleibt sinnvoll. Details: `FirstGame_ArtPack/class_overhaul/CHARACTER_ART.md` und `character-audit.json`.

## Tests und Bossbalancing

**PASS: 505 native Prüfungen, Exitcode 0.** [Aktueller Windows-Produktionsbuild](output/production-build/20261122-224917/FirstGame.zip), ohne Testinjektionen. ZIP-CRC vollständig geprüft. Projektintegrität: 897 Ressourcen, keine Probleme/Warnungen. [Native Ergebnisse](tests/reports/class-dragon-native.json), [Ressourcen-/Originalprüfung](tests/reports/class-dragon-assets.json), [Buildnachweis](tests/reports/class-dragon-build.json).

Bossbasis auf 9.200 HP angepasst. Im normalen Room1 bei Minute fünf beträgt der bestehende Gegner-HP-Faktor 1,35, somit **12.420 tatsächliche Anfangs-HP**. Diese werden beim Spawn festgelegt und während des Kampfes nicht nach Schaden oder Build angepasst. Es gibt keine Mindestkampfdauer, Schadenssperre oder zeitabhängige Unverwundbarkeit.

Die folgende Messung verwendet je Klasse 15 Fähigkeitsentscheidungen: Fireball/Lightning/Barrage Stufe 2, Healing Pulse Stufe 1; Power/Quick Hands Stufe 2, Keen Focus/Vitality/Wide Glyphs/Deep Rhythm Stufe 1. Echte Produktionswaffen, Projektile, kritische Treffer, Zauber und Passiven werden im nativen GameMaker ausgeführt. Der Boss dient als stationäres Ziel in 110 px Abstand. Das Angriffsfenster ist entweder ständig offen oder pro zehn Sekunden für sieben Sekunden offen; laufende Effekte können anschließend weiter treffen.

| Klasse | gemessene DPS, volles Fenster | gemessene DPS, 70%-Fenster | HP/DPS-Prognose mit 70%-Fenster |
|---|---|---|---|
| Sword | 109.18 | 85.88 | 144.61 s |
| Mage | 104.50 | 83.07 | 149.52 s |
| Ranger | 97.53 | 78.02 | 159.20 s |

Zusätzlich gemessene Entleerung der 12.420 Ziel-HP bis zum letzten Treffer: **Sword 144.02 s, Mage 144.70 s, Ranger 160.02 s**. Feindliche Rotation und Bewegung sind in diesen kontrollierten Messungen ausgeschaltet. Das sind gemessene Simulationszeiten gegen ein stationäres Ziel, kein menschlicher kompletter Bosskampf. Unterschiede zur HP/DPS-Prognose entstehen durch diskrete Kombos, laufende Effekte und kritische Treffer. Starke Builds dürfen schneller sein als 120 Sekunden.

Kurze native Performance-Stichprobe mit 150 Gegnern, Regen, KI und neuen Klassen-Effekten: 60 Frameintervalle, Mittel 16.67 ms, Maximum 16.94 ms. PNG-Speicherung liegt außerhalb des Messfensters; kein Langzeitbenchmark.

| Status | Tatsächlich geprüft |
|---|---|
| PASS | Viererfolge bis zum erneuten ersten Angriff, echte HP bei allen vier Schritten, einmalige Freigabe, keine Richtungswechsel-Resets |
| PASS | Zwölferschritte bis Schuss 13; exakt drei/fünf Pfeile auf 3/9, ein Pfeil auf 6 und 13, echter Pfeilhagelschaden |
| PASS | Unveränderte Schwerttreffer 11/13/19, unabhängige Waffen-/Zauberslots |
| PASS | Alle neun Drachenangriffe mit wirklichem HP-Verlust, Ende der Schadensphase, vier HP-Phasen und feste Rotationen, angekündigte Enrage-Kombinationen |
| PASS | Sprung über Bodenwelle, Slide unter erhöhtem Strahl, keine pauschale Sprungimmunität gegen Magma |
| PASS | Fünf Warnformen bei 0/25/50/75/100%; tatsächliche gefüllte Bildpixel zusätzlich gezählt, nicht nur Fortschrittszahlen |
| PASS | Kontakt beim Wechsel zu aktiv im gleichen Update bei 30/60/144 Hz; vor Vollendung kein Warnflächenschaden, Pause stoppt beides |
| PASS | Acht Richtungen, vorhandene Frame-Dateien, Ursprünge und neue Effekte, begrenzte/auslaufende Effektpools |
| PASS | 16 neue Audiodateien und tatsächlich erzeugte Audiostimmen auf getrennten nativen Spielframes; 70 WAVs technisch validiert |
| NOT RUN | Menschlicher 120–180-s-Bosskampf mit aktiver vollständiger Rotation |
| NOT RUN | Langzeit-Performance, manuelle Feinabnahme aller Animationsframes und subjektive Hörabnahme |

Native Bilder: [Countdown 50%](tests/reports/class-dragon-warning-50.png), [Sternenorb](tests/reports/class-dragon-mage-star-flight.png), [Pfeilhagel](tests/reports/class-dragon-ranger-rain.png), [Drachenstrahl](tests/reports/class-dragon-dragon-beam-active.png). Weitere Warn-/Angriffsbilder liegen neben dem nativen JSON.

Die früheren 322 Prüfungen gehören zum vorherigen Zaubersystem-Stand und werden hier nicht als neue Ergebnisse gezählt. Die neue Suite baut isoliert aus dem aktuellen Projekt und enthält keine automatisch bedienten Desktop-Eingaben. Fehlgeschlagene frühere Testläufe sind in ihren eigenen Logordnern erhalten; der finale PASS bezieht sich ausschließlich auf den oben verlinkten Lauf. Offen bleiben die genannten menschlichen Abnahmen und künstlerischen Detailverbesserungen. Keine bezahlte API, kein Git-Push.
