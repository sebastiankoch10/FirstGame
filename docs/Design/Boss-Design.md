---
tags: [design, verbindlich, bosse]
updated: 2026-11-27
status: verbindlich (Fachgebiet Hauptbosse); bis 24.11. unter DESIGN/BOSS_DESIGN.md
---
# Boss-Design: Bosskampf-Philosophie und Umsetzungsstand

**Quelle:** Vorgabe des Projektinhabers vom 23.11.2026, ergänzt am 25.11.2026 um artikulierte Bosskörper (Abschnitt G2).

**Geltung:** Für Bossarbeit ist dieses Dokument maßgeblich (Rang 2 unter [[Leitbild]]). Die allgemeinen Kampf-, Warn- und Fairnessregeln für alle Gegner stehen in [[Kampf & Begegnungen]]. Hier stehen nur die Besonderheiten der Hauptbosse.

## Leitbild

FirstGame ist ein Survivors-Spiel mit anspruchsvollen, mechanisch durchdachten Action-RPG-Bosskämpfen. Bezugspunkt ist die **spielerische Struktur** anspruchsvoller Final-Fantasy-XIV-Begegnungen, nicht deren Effekte. Seit 27.11. zählt auch ihr **Flair** dazu, besonders das der Ultimate-Kämpfe: Die Attacke kündigt sich selbst an (B2). Die Schwierigkeit entsteht aus Bewegung, räumlichem Denken, Timing und erlernbaren Mustern. Sie entsteht nicht aus hohen Schadenswerten, Zufallsspam oder künstlich begrenzter Spielerreichweite.

Die Leitfragen für den Spieler:
- Wo stehe ich?
- Wohin kann ich ausweichen?
- Welche Zone wird gleich gefährlich, und welche danach wieder sicher?
- Muss ich springen, sliden oder laufen?
- Kann ich noch Schaden machen?

## A – Kiting erhalten, Max-Range-Exploits verhindern

- **Kiting bleibt erwünscht.** Das heißt: auf Distanz kämpfen, Gruppen umkreisen (im und gegen den Uhrzeigersinn), offene Flächen nutzen. Spieler werden nicht in den Nahkampf gezwungen.
- **Das Problem:** Ein Spieler bleibt dauerhaft maximal entfernt, kitet die Horde und weicht so allen Bossmechaniken aus.
- **Die Lösung sind interessantere Mechaniken**, keine künstliche Reichweitenbegrenzung.
- Jeder Hauptboss braucht Mittel gegen weit entfernte Spieler: weit reichende Strahlen, gezielt platzierte Bodenangriffe, großflächige Muster, Projektilkombinationen, kontrollierte Repositionierung und seltene Aufholattacken.

## A2 – Distanzabhängiger Druck (Auftrag 26.11., Phase 2B, verbindlich)
Entfernung allein darf keine dauerhaft risikofreie Strategie sein. Kiting, Fernkampf und Nahkampf bleiben legitim, verlangen aber aktives Ausweichen und Timing.
- **Druck mit Hysterese** (`bc_pressure`, `scripts/boss_choreo`):
  - Ab `far_distance` 420 px gilt der Spieler als fern, unter `far_exit` 330 px nicht mehr.
  - Der Druck wächst über `far_span` 520 px von 0,25 auf 1.
- **Wirkung** (Werte in `bc_config`, Startwerte des Auftrags, keine gemessene Balance):
  - **Erholung zwischen Angriffen** bis zu 45 % kürzer (`bc_recovery`). Verdiente Schadensfenster bleiben bestehen, nur nicht unbegrenzt lang.
  - **Annäherung:** Drache 65 → bis 295 px/s, Behemoth 32 → bis 202 px/s; die Hexen folgen bis zu viermal schneller.
  - **Aufholattacke:** nach 1,2 s Ferne statt 3,5 s, Abklingzeit 9 s statt 20 s. Die Ferne zählt in jedem Zustand; die Bewegung startet nur zwischen zwei Angriffen.
  - **Fern-Pool des Drachen** (`bc_dragon_far_pick`): Bei Druck ≥ 0,5 werden Nahmuster (Stampfen, Bodeneinschlag, Wirbel, Flügelsturm) abwechselnd durch Feuerstrahl oder Meteore ersetzt.
- **Fairness:**
  - Laufende, angekündigte Angriffe werden nie abgebrochen, um nachzusetzen.
  - Kein Teleport auf den Spieler.
  - Alle Aufholbewegungen sind angekündigt und ausweichbar.

## A3 – Von außen nach innen: kontrahierende Ringe, Schachbrett über das ganze Feld (Phase 2B)
- **Kontrahierende Ringwellen** (`bc_closing_waves`):
  - Mehrere Ringbänder starten außen und ziehen sich zum Boss hin zusammen, zeitlich versetzt, jedes mit einer Öffnung an anderer Stelle.
  - Sie treiben Kiter nach innen.
  - **Lösungen:** durch die Öffnung gehen, ein Band mit getimtem Sprung oder Ausweichrolle kreuzen (Höhe `ground`), mitlaufen, vorher positionieren.
  - Beim Drachen ist das die komplexe Variante des Feuerwirbels (ab Phase 2): drei Ringe von 820 auf 150 px, Band 40 px, 0,6 s Versatz.
- **Durchlauflose Trefferprüfung:** Bewegte Ringe prüfen auch das seit dem letzten Schritt überstrichene Band (`sweep_prev`), damit schnelle Ringe den Spieler bei niedriger Bildrate nicht überspringen.
- **Spielfeldweites Schachbrett** (`bc_field_checker`):
  - Eine einzige Gefahr pro Welle mit Form `checker`. Die Zellen hängen am Weltursprung, die Fläche ist die ganze Arena (Raum).
  - Der Treffertest gilt überall, gezeichnet werden nur sichtbare Zellen.
  - Unabhängig von Abstand, Kamera und Spielweise; Weglaufen entkommt nicht.
  - Im Einsatz bei Hexen-Attacke 3 und Drachen-Stampfen (komplexe Varianten), jeweils Feuer bzw. Magma, dann das invertierte Brett.
  - Gerade sichere Felder bleiben dunkel (spätere Welle nur als Umriss).
- **Sprung- und Ausweichregeln pro Angriff** (Höhe am Gefahren-Struct, `player_protected_from`):
  - `ground`: Sprung oder Ausweichrolle schützen.
  - `high`: Rutschen oder Ausweichrolle.
  - `all`: nur die Ausweichrolle (Unverwundbarkeit während `dodge_timer`).
  - Darstellung: Gefahren, die nur das Ausweichen löst, haben einen 2-px-Rand, alle anderen 1 px.

## B – Aufholattacken (seit 26.11. häufiger, siehe A2)

Jeder Hauptboss hat eine eigene, sichtbar animierte Aufhol- bzw. Repositionierungsbewegung:
- **Drache:** Flügel ausbreiten, abheben, Flug oder Sturzflug zum Spieler. Die Landezone wird angekündigt; bei der Landung gibt es Staub, Erschütterung und einen Einschlag.
- **Zwillingshexen:** Sie lösen die Formation auf, verschwinden in Feuer- und Eiswirbeln oder machen ein schnelles Flugmanöver und bilden danach eine neue Formation.
- **Sumpfbehemoth:** Er versinkt im Sumpf und bricht woanders hervor, oder er macht einen schweren Sprung. Die Austrittsstelle wird angekündigt.

Regeln:
- Nur bei sinnvoll großem Abstand.
- Eigene Animation und Cooldown (seit 26.11. 9 s, vorher 20 s; siehe A2).
- Nie Schaden ohne Vorwarnung.
- Danach geht normales Verhalten weiter.
- Kein Teleport direkt auf den Spieler; die Aufholattacke ist lernbar und ausweichbar.
- Die Boss-Richtungsanzeige funktioniert weiter.

## B2 – Die Attacke ist die Warnung (Designentscheidung des Nutzers, 27.11.2026)
**Ist seit 27.11. für den Drachen umgesetzt** (Pilot; die übrigen Bosse folgen nach Entscheidung des Nutzers). Die globale Regel steht in [[Kampf & Begegnungen]] 5.0 und Leitbild G19, hier nur die Bossbesonderheiten.
- **Drache, je Attacke** (`hz_dragon_look` in `scripts/hazard_looks`):
  - Feueratem: Glut-„Zündschnur“ in der Startbahn, Glutfunken treiben in Schwenkrichtung über den Fächer.
  - Feuerfächer und lange Kegel: Flammen keimen in der ganzen Fläche, werden höher und zittern vor dem Auslösen.
  - Stampfen und Magma-Schachbrett: Risse glühen auf, Magma blubbert, bei Treffern jeder Höhe hohe Flammen; im Schachbrett je Feld.
  - Meteor: Der Halbschatten ist von Beginn an genau die Trefferfläche, der Kernschatten wächst bis zum Einschlag, der Fels fällt sichtbar.
  - Bodenschlag: Ein unregelmäßiges Netz dunkler Risse durchzieht die ganze Fläche bis zum Endradius der Druckwelle, der Boden ist staubig getönt, Geröll hüpft und zittert; während der Welle bleibt der Endradius schwach sichtbar.
  - Wirbel und schließende Feuerringe: Glut kreist im Ring, die Öffnung bleibt leer.
  - Leere, Wind, Salve: Energie ihres Elements sammelt sich am Maul; die Projektile ziehen Spuren (keine Bodenwarnung, Grundsatz D).
  - Biss und Schweif: Staubschleier über dem Trefferkeil, Staub wirbelt darin auf, dazu die Ausholbewegung.
- **Drache, aktive Attacke** (`hz_dragon_active`, seit 27.11.):
  - Feuerfächer, lange Kegel, Feuerringe, Wirbel: brennender Boden mit Flammenteppich und Flammensaum; der Fächer glüht zum Maul hin heller.
  - Stampfen, Magma-Schachbrett, Meteor: dunkle Kruste, die entlang des Rissnetzes aus der Ankündigung aufbricht und glüht; Lavablasen, Ausbruchsflammen; beim Meteor ein heißer Einschlagkern. Die Fläche kühlt ab, solange sie aktiv ist.
  - Bodenschlag: wandernde Staubwand im Trefferband, Staub bleibt hinter der Front zurück.
  - Biss und Schweif: Hiebspuren in warmen Staubtönen (anders als die weißen Schwerthiebe des Spielers) über dem Trefferkeil.
  - Feueratem: unverändert der Feuerstrahl aus dem Schaustück.
- Bossattacken kündigen sich durch Körper, Ansetzen und die Elemente der Attacke selbst an. Marker, die genauso viel zeigen wie die Attacke, entfallen (z. B. Kegel plus wanderndes Rechteck beim Drachenatem, sich füllende Schachbrettfelder).
- **Beispiele des Nutzers:**
  - Schachbrett: In den Feldern bauen sich kleine Flammen auf, vibrieren und explodieren gleich; danach dasselbe invertiert mit Eis.
  - Drachenatem: Kopf, Ansetzen und Flammen sind zu sehen, ausgewichen wird den Flammen.
- **Fairness:** Form der Vorzeichen = Trefferfläche, genug Vorlaufzeit, sichere Bereiche erkennbar. Ablauf, Timing, Trefferflächen und die Uhr je Boss (`v2_clock`) bleiben unverändert; das Ausweich-Orakel der Boss-Suite gilt weiter.
- Ersetzt sind die Markerregeln in C, D, F, H und H2 (jeweils durchgestrichen). Die Beschreibung im Umsetzungsstand bleibt Ist bis zur Umsetzung.

## C – Extrem weit reichende Strahlen

- Feuer-, Eis- und Energiestrahlen haben konzeptionell unbegrenzte Reichweite. Sie reichen mindestens über den gesamten relevanten Spielbereich, auch außerhalb der Kamera.
- Umsetzung über Strahlgeometrie bzw. Kollisionsrechnung, nicht über weltlange Sprites.
- Ablauf: Ausrichtung → ~~Ankündigung von Winkel und Richtung → dezenter Countdown~~ Ansetzen (Kopf, Einatmen, Glut im Maul; Richtung daran lesbar, seit 27.11., B2) → Positionieren → aktiver Strahl direkt bei Ablauf → begrenzte Dauer → Abschlussanimation.
- Strahlen dürfen schwenken (z. B. links nach rechts, kurzer Stillstand und dann Schwenk, zwei Schwenks, begrenzter Sektor). Der Schwenk passt zur Animation, ist erkennbar und nicht unvorhersehbar schnell.
- Kein permanentes perfektes Nachverfolgen; es sind bewusst designte Muster.

## D – Bodenattacken bleiben lokal

Meteore, Magma, Säure, Wurzeln, Explosionen und Einschlagkreise treffen nur ihre angekündigten Flächen.

Ablauf:
1. Ziel festlegen.
2. ~~Dezente Zone zeigen.~~ Vorzeichen in der Trefferform aufbauen (seit 27.11., B2).
3. ~~Zeitabhängiger Countdown.~~ Die Vorzeichen steigern sich bis zur Auslösung.
4. Ausweichen möglich.
5. Kurzes Aufleuchten.
6. Einschlag.
7. Ende; eine Restzone bleibt nur, wenn die Attacke es ausdrücklich vorsieht.

Die Anzeige ist zeitlich exakt an die Schadenslogik gekoppelt. Normale, langsame Projektile bekommen keine Bodenwarnung.

## E – FFXIV-artige räumliche Mechaniken (wichtigste Philosophie)

Bosskämpfe zwingen wiederholt dazu, bewusst den nächsten sicheren Bereich zu suchen.

Muster:
- Schachbrett und invertiertes Schachbrett (das nächste Muster erscheint, während das erste aktiv wird)
- wechselnde Streifen
- innen/außen
- Quadranten
- diagonale Felder
- nacheinander explodierende Felder
- wandernde Sicherheitszone
- Kombination aus Strahl und Bodenmustern

Alle Muster sind an die offene Top-down-Welt angepasst; es gibt keine geschlossene Arena.

## F – Gezielte Zwickmühlen statt Zufallsspam, aber niemals grundsätzlich unfair

- Es soll regelmäßig Positionsdruck geben (Strahl blockiert eine Seite, Bodenexplosion bedroht den Standort, ~~eine zweite Warnung markiert die nächste Gefahr~~ die Vorzeichen der nächsten Gefahr bauen sich schon auf).
- Kein Kampf, in dem dauerhaft fast der ganze Bildschirm gefährlich ist. Im Wechsel: freie Bewegung, einzelne Angriffe, Spezialangriffe, kurze Kombinationen, Erholung.
- Sichere Bereiche müssen realistisch erreichbar sein. Dabei zählen Tempo, Weglänge, Hindernisse, Reaktionszeit, Sprung, Slide, Dodge, gleichzeitige Gegner, Vorbereitungs- und Aktivzeit sowie die Hitbox. Erreichbarkeit „nur mit perfektem Vorwissen“ gilt nicht.
- Zielbereiche werden zu einem nachvollziehbaren Zeitpunkt festgelegt; Felder springen nicht ohne neue Warnung auf den Spieler.

## G – Boss-spezifische Umsetzung (das Prinzip ist gemeinsam, die Ausführung unterscheidet sich)

- **Drache:** weit reichender Feuerstrahl mit langsamen Schwenks, lokale Magmaeruptionen, aufeinanderfolgende Bodenexplosionen, wechselnde sichere Bereiche, Meteoritenmuster, springbare Schockwellen, Kombinationen aus Strahl und Fläche, seltener Sturzflug. Das bestehende Drachenmodell bleibt erhalten.
- **Zwillingshexen:** Flugmuster kombiniert mit Angriffen. Dazu gehören:
  - drehender Verbindungsstrahl
  - gegenüberliegende Teilung des Kampfbereichs
  - Feuerfelder, danach Eisfelder auf den zuvor sicheren Stellen
  - Acht-Formation mit nachgezogenem Strahl
  - Feuerstrahl-Schwenk während eines Eis-Flächenmusters
  - koordinierte, versetzte Explosionen

  Das ergibt eine eigene Choreografie, keine zwei unabhängigen Gegner.
- **Sumpfbehemoth:** Flächenkontrolle durch nacheinander hervortretende Wurzeln, Giftflächen, die den Raum verkleinern, Säurefelder mit wechselnden Zwischenräumen, Schockwellen mit begrenzten sicheren Bereichen, kurz aufeinanderfolgende Pilzexplosionen und eine große Sumpfwelle. Weit entfernte Spieler erreicht er über gezielte Bodenattacken und eine seltene Aufholbewegung.

## G2 – Artikulierte Bosskörper (Soll, Auftrag 25.11.2026)

**Referenz:** Bosssequenz im Terranigma-Trailer ab 0:37. Analyse und Grenzen stehen in [[Visuelles Leitbild & Animation]].

Große Bosse haben Körper, deren Teile gezielt für Angriffe und Bewegungen eingesetzt werden. Die Animation übernimmt einen Teil der Angriffskommunikation.

**Grundregeln:**
- Die Körperteile sind optisch **ein zusammenhängender Körper**, keine Papierpuppe aus losen Teilen.
- Starke Bewegungen einzelner Teile lösen eine **Reaktion des Rumpfes** aus (Gewichtsverlagerung, Gegenbewegung).
- Hitboxen, Hurtboxen und Schadenszeitpunkte hängen an den sichtbaren Körperteilen und laufen auf der Uhr des Bosses.
- Ein Schweifschlag ist **sichtbar ausgeholt und räumlich nachvollziehbar** und kein eingeblendetes Angriffs-Sprite.

**Drache (Qualitätsreferenz):**
- Der Kopf richtet sich unabhängig vom Körper aus.
- Der Hals unterstützt die Kopfbewegung, z. B. als Kette mit Nachlauf.
- Der Rumpf reagiert auf Gewichtsverlagerung.
- Die Flügel haben eigene Bewegungsphasen: Ausbreiten, Schlag, Anlegen.
- Die Beine vermitteln Standfestigkeit und Gewicht; die Füße bleiben beim Stampfen und Laufen am Boden.
- Biss: Der ganze Vorderkörper geht mit (Ausholen zurück, Vorstoß, Rückzug).
- Atemangriff: Hals, Kopf und Rumpf bereiten ihn vor (Aufrichten, Einatmen, Vorbeugen), das Feuer entsteht am Maul-Anker.
- Schweifschlag: Ausholen zur Gegenseite, Schwung durch einen angekündigten Sektor, Nachschwingen. Die Hitbox folgt der Schweifspitze.

**Ist (25.11.):**
- Der Drache ist ein einzelnes Sprite je Aktion mit 2–4 Frames.
- Die Richtung entsteht nur durch Spiegeln.
- Es gibt eine Atembewegung per Skalierung.
- Annotierte Maul-Anker existieren (`dragon_art_anchor`).
- Hexen und Behemoth sind ebenfalls Einzelsprites.

**Nahangriffe (Nutzerentscheidung 25.11., umgesetzt):**
- Stehst du länger als 0,6 s näher als 230 px am Drachen, greift er statt der nächsten Rotationsfähigkeit im Nahkampf an (Abklingzeit 8 s).
- **Biss** und **Schweifschlag** wechseln sich ab:
  - Biss: Sektor 205 px, 70°, Warnung 0,6 s, trifft jede Höhe;
  - Schweifschlag: vom Hüftbereich, 250 px, 150°, Warnung 0,75 s, Bodenhöhe, also überspringbar.
- Der Schaden entspricht dem vorhandenen Feuerbogen. Die neun Fähigkeiten und die Rotation bleiben unverändert.
- Im Rig holt der Schweif aus und peitscht durch, beim Biss zieht der Hals zurück und stößt vor.
- **Noch offen:** Die Trefferzone ist ein angekündigter Sektor; eine Hitbox, die exakt der Schweifspitze folgt, kommt mit Rig-Stufe 2.
- Funktionen: `dragon_melee_config` und `dragon_melee_try` in `scripts/dragon_encounter`.

**Drache als Verbund aus Teilen (Nutzerentscheidung 25.11. abends, ersetzt das Skinning-Rig für den Drachen):**
- Wunsch des Nutzers: wie bei Terranigma-Bossen eigenständige Teile mit eigenen Hitboxen, die als eine Einheit zusammenarbeiten. Der Hals zieht sich aus, der Kopf dreht sich zu dir, egal wo du stehst, und wirkt groß und präsent.
- Umsetzung (`scripts/dragon_parts`):
  - Körper ohne Kopf und Hals; Hals aus überlappenden Gliedern mit Rückenstacheln entlang einer Kurve; Kopf geschlossen und offen.
  - Alle Teile vorab in Spielgröße gebacken; Drehungen als 32 vorberechnete Stufen (RotSprite), nie zur Laufzeit gedreht oder skaliert.
  - Der Kopf blickt zum Spieler. Feueratem, Feuerbogen und Salven entstehen exakt am gezeichneten Maul (G1); beim Biss holt der Kopf zurück und stößt in den angekündigten Sektor.
  - Kopf und Halsglieder sind Trefferformen des Bosses selbst. Fachlich besser als getrennte Objekte mit geteiltem Leben: Ein Flächenzauber, der Kopf und Rumpf berührt, trifft trotzdem nur einmal; Schaden und Balancing bleiben unverändert.
- Grenzen: Die Kopfansichten entstehen durch Drehen einer Seitenansicht; extreme Winkel nach unten wirken dadurch flacher. Flügel, Beine und Schweif sind noch Teil der Körperframes. Nächste Schritte: Schweif als Gliederkette mit Hitbox an der Spitze, Flügel als eigene Teile.

**Weg zum Soll:** Rig-System in [[Technische Architektur]], Drachen-Prototyp im [[Roadmap & Vertical Slice]].

**Wichtig:** Das bestehende Drachenmodell bleibt erhalten. Die Zerlegung in Körperteile nutzt die vorhandene Gestaltung, ohne sie zu ersetzen.

## H – Technische Grundarchitektur

- **Angriffe als geplante, mehrstufige Sequenzen:** positionieren → ~~Zonen ankündigen → Countdown~~ Vorzeichen aufbauen (seit 27.11., B2) → aktivieren → nächste Zonen ankündigen → alte deaktivieren → zweite Aktivierung → Abschluss → Bewegungspause. Zeitlich präzise.
- **Weiterhin genau neun Fähigkeiten je Hauptboss.** Eine Fähigkeit darf mehrere Schritte haben.
- **Freischaltung:** Minute 5 → 1–3, Minute 10 → 1–6, ab Minute 15 → 1–9. Früh freigeschaltete Fähigkeiten dürfen später komplexere Varianten bekommen.
- **~~Warnungen~~ Die Vorzeichen zeigen** (seit 27.11., B2) Fläche, Zeitpunkt, die danach sicheren Flächen und die bereits vorbereitete nächste Gefahr. Sie bleiben dezent, ohne grelle Vollflächen.
- **Überlappende Phasen** (A aktiv, B angekündigt, A endet, B aktiv) sind ausdrücklich möglich. Es dürfen nie versehentlich alle sicheren Positionen gleichzeitig verschwinden.

### H2 – Choreografierte Angriffssequenzen (bestätigte Designentscheidung des Nutzers, 26.11.2026)
- **Ergänzen, nicht ersetzen:** Dynamische Auswahl (Rotation, Distanzdruck, Nahangriff, Aufholattacke) und HP-Phasen bleiben. Zusätzlich gibt es feste, lernbare Sequenzen aus den vorhandenen neun Fähigkeiten, also keine neuen Angriffe.
- **Lernbar:** Je Phase 2–3 Sequenzen mit fester Reihenfolge. Der Boss spielt sie der Reihe nach, immer nach zwei regulären Angriffen. So erkennt man nach einigen Begegnungen „Strahl → Schachbrett → Ringe“ wieder.
- **Fair:**
  - Jeder Schritt ist die vollständige Fähigkeit mit ~~Warnung, Countdown~~ Vorzeichen (seit 27.11., B2) und Aktivierung.
  - Der nächste Schritt beginnt erst, wenn alle Gefahren des vorigen vorbei sind, plus eine Pause von 0,5 s.
  - Nach dem letzten Schritt ruht der Boss 2,2 s.
  - Es gibt immer eine machbare Überlebensstrategie; die Boss-Suite prüft das für jede Sequenz mit dem Ausweich-Orakel.
- **Nie abbrechen:** Ein angekündigter Schritt läuft immer zu Ende. Ein Phasenwechsel beendet eine Sequenz nur zwischen zwei Schritten.
- **Freischaltung:** Eine Sequenz wird nur genutzt, wenn alle ihre Fähigkeiten freigeschaltet sind. In jeder Phase gibt es mindestens eine Sequenz aus den Fähigkeiten 1–3, damit auch die Begegnung in Minute 5 Sequenzen hat.
- **Technik:** Daten in `bc_sequences` (`scripts/boss_choreo`), ausgewertet über `bc_seq_decide` in der bestehenden Entscheidung des Bosses. Es gibt kein Parallelsystem.
- **Pilot Drache:**

| Phase | Sequenzen (Schritte) |
|---|---|
| 1 | Feuerschneise (Feueratem → Fächer) · Glutboden (Stampfen → Feueratem) |
| 2 | Glutfächer (Fächer → Stampfen → Feueratem) · Sternenbahn (Meteore → Feueratem → Wind) · Erdbeben (Bodenschlag → Stampfen → Fächer) |
| 3 | Feuersturm (Feueratem → Magma-Schachbrett → kontrahierende Ringe) · Meteorhagel (Meteore → Salve → Bodenschlag) · Feuerwand (Stampfen → Fächer → Feueratem) |
| 4 | Inferno (Feueratem → Schachbrett → Ringe) · Sturmauge (Wind → Leere → Meteore) · Letzte Glut (Fächer → Feueratem → Stampfen) |

- **Offen:** Sequenzen für Zwillingshexen und Behemoth (gleiche Datenstruktur), nach dem Spieltest des Drachen-Piloten.

## I – Verbindliche Tests

- **Max-Range-Tests:** Reichen Strahlen? Funktionieren Bodenattacken auf Distanz? Funktioniert das Aufholen? Bleibt Kiting sinnvoll?
- **Kiting-Tests:** im und gegen den Uhrzeigersinn, Richtungswechsel, auf Distanz, gelegentliches Annähern. Prüfen, ob eine simple Strategie alles neutralisiert.
- **Komplexe Muster:** Schachbrett, Invertierung, Explosionsfolgen, Schwenkstrahlen, wechselnde Felder, Strahl plus Boden, bewegte Verbindungsstrahlen, Aufholattacken. Für jede Sequenz die Erreichbarkeit sicherer Bereiche prüfen.
- **Keine numerischen Balancing-Änderungen** (Spieler-HP/DPS, Zauberschaden, Boss- und Gegner-HP, Schadensskalierung, Erfahrung, Klassenwerte). Nötige Anpassungen werden nur als Empfehlung dokumentiert. Logik-, Hitbox-, Auslöse- und Warnfehler werden behoben.

## J – Reihenfolge und Abschlussbericht

**Reihenfolge:**
1. Mechaniken analysieren.
2. Max-Range- und Kiting-Probleme finden.
3. Choreografie-Architektur.
4. Lange Strahlen und Aufholmechaniken.
5. Versetzte Flächenmuster.
6. Bestehende Angriffe integrieren.
7. Fairness- und Wegtests.
8. Erst dann übrige QA, Simulation und Grafik.

Bossidentitäten respektieren:
- Drache: Feuer, Schwenkstrahlen, Sturzflüge, Magma
- Hexen: Formationen, Verbindungsstrahlen, Feuer-/Eis-Zonen
- Behemoth: Gift, Wurzeln, Sumpfwellen, Flächenkontrolle

**Der Abschlussbericht enthält:**
- Max-Range-Probleme
- Aufholmechaniken
- funktionierende Choreografien
- Strahlen mit großer Reichweite
- Mechaniken, die zu Zonenwechseln zwingen
- durchgeführte Tests
- verbleibende Unfairness und technische Probleme
- nur dokumentierte Balancing-Punkte

## Umsetzungsstand (24.11.2026)

**Technik:** `scripts/boss_choreo/boss_choreo.gml`. Alle Musterteile sind normale Gefahren aus Boss System 2.0. Warnung, Countdown-Zeiger, Aufleuchten und Treffer laufen über dieselbe Uhr des Besitzers (`v2_clock`), sodass Anzeige und Hitbox nicht auseinanderlaufen können. Der Drache treibt jetzt ebenfalls eine `v2_clock`. Der Schaden der Muster ist immer der bestehende Schaden der jeweiligen Fähigkeit. Es gibt keine neuen HP- oder Schadenswerte.

**Musterbibliothek:**
- Schachbrett und invertiertes Schachbrett (5×5 Felder à 118 px)
- Streifen mit wechselnden Lücken
- Quadranten (diagonaler Positionswechsel)
- Innen/außen
- Explosionskette
- sich schließender Giftring
- Schwenkstrahl mit 2.600 px Länge: Der ganze Fächer wird angekündigt, mit Startkante, Richtungspfeilen und Countdown-Zeiger.

**Eskalation über die Spielzeit:** Die komplexen Varianten der früh freigeschalteten Fähigkeiten 1–3 erscheinen erst bei Bossen ab Minute 10, also ab 6 Fähigkeiten. Das betrifft Drachen-Schachbrett, -Kegel und Strahl plus Meteore, die Hexen-Acht mit Strahl und das Hexen-Schachbrett sowie Säurestreifen und Wurzellinie des Behemoth. Der erste Hauptboss in Minute 5 zeigt nur den Schwenkstrahl und die ursprünglichen Fähigkeiten. So steht es in Abschnitt H: „Früh freigeschaltete Fähigkeiten dürfen später komplexere Varianten bekommen.“ Anlass war die Boss-Simulation vom 24.11.: Gegen den Drachen in Minute 5 gewannen die Bots 0 von 12 Kämpfen, bei Codex waren es 12 von 24. Ursache war vor allem das Schachbrett.

**Einbau in die bestehenden neun Fähigkeiten.** Die Freischaltung 3/6/9 ist unverändert. Ab Phase 2 bzw. 3 kommen komplexere Varianten hinzu:

| Boss | Fähigkeit | Neue Choreografie |
|---|---|---|
| Drache | 1 Feuerstrahl | Schwenkstrahl 64° (ab Phase 2: 84°), Richtung wechselt. Ab Phase 3 zusätzlich 4 Meteore um den Spieler (Strahl plus Boden). |
| Drache | 2 Feuerbogen | Ab Phase 3 zusätzlich wechselnde lange Feuerkegel (900 px): drei Kegel bei −70°/0°/+70°, danach die Lücken bei ±35°. |
| Drache | 3 Magmaeruption | Ab Phase 2: Magma-Schachbrett, danach das invertierte Brett (1,3 s versetzt, überlappende Warnung). Die Felder sind überspringbar (Bodenhöhe), weil sie eine große Fläche abdecken. Die ursprünglichen Magmakreise in Phase 1 treffen weiterhin jede Höhe. |
| Drache | 4 Meteoritenregen | Ab Phase 2: Einschlagkette vom Drachen durch die Spielerposition hindurch (12 × 92 px). Ab Phase 3 zusätzlich außen/innen. |
| Hexen | 1 Doppelte Geschosssalve | Normale Projektile ohne Bodenwarnung. Ab Phase 3 zieht die Acht-Formation zusätzlich einen Verbindungsstrahl hinter sich her. |
| Hexen | 3 Meteor-/Eisregen | Ab Phase 2: Feuer auf dem Schachbrett, danach Eis auf den zuvor sicheren Feldern. |
| Hexen | 4 Verbindungsstrahl | Die Hexen kreisen gegenläufig um die angekündigte Spielerposition. Der Strahl zwischen ihnen überstreicht sie fortlaufend (38°/s, ab Phase 3 46°/s). |
| Hexen | 6 Kreuzschlag | Beide Strahlen reichen 2.600 px weit durch den Zielpunkt. Ab Phase 3 vereist zusätzlich der Boden in Streifen, und der Feuerstrahl schwenkt dabei um 28° (Strahlschwenk über einem Eis-Flächenmuster). |
| Hexen | 8 Zonenflut | Ab Phase 2: Feuer auf zwei gegenüberliegenden Quadranten, danach Eis auf den anderen beiden. |
| Behemoth | 2 Säurepfützen | Ab Phase 2: Säurestreifen, dann die versetzten Streifen. Zwischen beiden liegen 0,7 s Lücke zum Spurwechsel. |
| Behemoth | 3 Packende Wurzeln | Ab Phase 2: Wurzeln brechen nacheinander vom Behemoth bis über den Spieler hinaus hervor (10 × 95 px). Ab Phase 3 sind es zwei Linien. |
| Behemoth | 5 Sumpfstampfer | Ab Phase 2: zwei Schockwellen mit Lücken; die zweite Lücke ist um 120° versetzt. |
| Behemoth | 6 Sumpfbrut | Ab Phase 3: Ein Giftring schließt sich um den Behemoth. Der sichere Radius schrumpft von 640 auf 320 px; das verkleinert den Raum gegen Kiting. |
| Behemoth | 7 Giftatem | Ab Phase 2: Der Atem schwenkt um 64°. |
| Behemoth | 8 Sumpfwelle | Die Welle rollt 1.500 px weit statt 650 px. Man kann sie überspringen oder ihre Bahn verlassen. |

**Fairness-Regel für Schwenks:** Ein schwenkender Strahl oder Atem trifft pro Überstreichen höchstens einmal. Grund: Die isolierten Boss-Simulationen vom 24.11. zeigten Mehrfachtreffer, wenn man nah am Drachen steht oder in Schwenkrichtung läuft. Der Schaden pro Treffer bleibt unverändert.

**Reaktionszeit bei Mehrwellen-Mustern:** Nach den ersten isolierten Boss-Simulationen bekamen die Muster mehr Zeit. Das Drachen-Schachbrett startet 0,6 s nach der Grundwarnung, das invertierte Brett 1,3 s später. Beim Drachen beginnt innen/außen 1,2 s nach der Grundwarnung, die zweite Stufe folgt 1,15 s später. Das Hexen-Schachbrett startet 0,45 s nach der Grundwarnung, die Eiswelle 1,3 s später. Schaden und HP sind unverändert.

**Seltene Aufholattacken** statt des technischen Teleports. Bedingung: mehr als 520 px Abstand für 3,5 s zwischen zwei Angriffen; danach mindestens 20 s Abklingzeit.
- **Drache:** Sturzflug mit „leap“-Animation und Flughöhe. Die Landezone (170 px) ist 1,6 s vorher angekündigt.
- **Behemoth:** Er versinkt 0,8 s lang und bricht dann an der angekündigten Stelle (190 px) hervor.
- **Hexen:** Sie lösen sich in Wirbeln auf und formieren sich an zwei angekündigten Flankenpunkten neu, nie auf dem Spieler.
- **Der Teleport** bleibt nur als Notfall bei mehr als 850 px außerhalb des Bildes. Seine Verzögerung steigt von 2,5 auf 6 s.

**Unverändert, weil schon passend:**
- Hexen-Nova (außen → innen → außen)
- rotierende Feuer-/Eisringe mit Lücke
- Drachen-Bodeneinschlag (springbar)
- Projektilangriffe ohne Bodenwarnung (Grundsatz D)
- Der Waldwächter (Miniboss) hat bereits einen eigenen automatischen Grundangriff (Einzelgeschoss alle 1,6 s), getrennt von seinen Spezialangriffen.

## Analysestand (23.11.2026, vor Umsetzung)

Statische Code-Analyse, noch kein Laufzeittest:
- Bodenangriffe zielen auf die Spielerposition zu Beginn des Windups, und die Warnzeit beträgt mindestens 0,85 s. Wer ständig läuft (Ranger 252 px/s, Mage 168 px/s), verlässt Zonen mit 65–155 px Radius automatisch.
- Angriffe, die um den Boss zentriert sind, reichen nur 310–365 px; Spieler halten 400–580 px Abstand.
- Verfolgung: Drache 65 px/s nur in der Erholung, Behemoth 32 px/s; das Formationszentrum der Hexen hängt einem laufenden Ranger etwa 360 px hinterher.
- Der Teleport greift erst ab 850 px Abstand außerhalb des Bildes, also nie im Band 400–580 px. Außerdem ist er ein technischer Reset ohne Bossidentität.
- Der Feuerstrahl ist bereits lang genug, aber statisch und beim Windup fixiert. Ein Schwenk (`sweep`) existiert, gehört aber nicht zu den neun Fähigkeiten.
- Die QA-Bots hielten 190–250 px Abstand und hatten keine Max-Range- oder Kiting-Strategie. Die 360 Bosskämpfe sagen deshalb nichts über dieses Problem aus.
- Konsequenz für Schwenkstrahlen: Auf 580 px bewegt sich ein Schwenk mit 40°/s mit 405 px/s, schneller als jede Klasse läuft. Gegenwehr ist daher ein angekündigter Sektor mit sicheren Bereichen außerhalb oder das Durchqueren per Slide/Dodge (der Strahl trifft auf Höhe „hoch“).
