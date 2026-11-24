# FirstGame – Bosskampf-Designphilosophie (verbindlich, höchste Priorität für alle Hauptbosse)

Quelle: Vorgabe des Projektinhabers vom 23.11.2026. Gilt vor jeder Entwicklung, Überarbeitung oder umfassenden Prüfung von Bossangriffen.

## Leitbild

FirstGame ist ein Survivors-Spiel mit anspruchsvollen, mechanisch durchdachten Action-RPG-Bosskämpfen. Bezugspunkt ist die **spielerische Struktur** anspruchsvoller Final-Fantasy-XIV-Begegnungen, nicht deren Effekte. Die Schwierigkeit entsteht aus Bewegung, räumlichem Denken, Timing und erlernbaren Mustern. Sie entsteht nicht aus hohen Schadenswerten, Zufallsspam oder künstlich begrenzter Spielerreichweite.

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

## B – Seltene Aufholattacken

Jeder Hauptboss hat eine eigene, sichtbar animierte Aufhol- bzw. Repositionierungsbewegung:
- **Drache:** Flügel ausbreiten, abheben, Flug oder Sturzflug zum Spieler. Die Landezone wird angekündigt; bei der Landung gibt es Staub, Erschütterung und einen Einschlag.
- **Zwillingshexen:** Sie lösen die Formation auf, verschwinden in Feuer- und Eiswirbeln oder machen ein schnelles Flugmanöver und bilden danach eine neue Formation.
- **Sumpfbehemoth:** Er versinkt im Sumpf und bricht woanders hervor, oder er macht einen schweren Sprung. Die Austrittsstelle wird angekündigt.

Regeln:
- Nur bei sinnvoll großem Abstand.
- Eigene Animation und langer Cooldown.
- Nie Schaden ohne Vorwarnung.
- Danach geht normales Verhalten weiter.
- Kein Teleport direkt auf den Spieler; die Aufholattacke ist lernbar und ausweichbar.
- Die Boss-Richtungsanzeige funktioniert weiter.

## C – Extrem weit reichende Strahlen

- Feuer-, Eis- und Energiestrahlen haben konzeptionell unbegrenzte Reichweite. Sie reichen mindestens über den gesamten relevanten Spielbereich, auch außerhalb der Kamera.
- Umsetzung über Strahlgeometrie bzw. Kollisionsrechnung, nicht über weltlange Sprites.
- Ablauf: Ausrichtung → Ankündigung von Winkel und Richtung → dezenter Countdown → Positionieren → aktiver Strahl direkt bei Ablauf → begrenzte Dauer → Abschlussanimation.
- Strahlen dürfen schwenken (z. B. links nach rechts, kurzer Stillstand und dann Schwenk, zwei Schwenks, begrenzter Sektor). Der Schwenk passt zur Animation, ist erkennbar und nicht unvorhersehbar schnell.
- Kein permanentes perfektes Nachverfolgen; es sind bewusst designte Muster.

## D – Bodenattacken bleiben lokal

Meteore, Magma, Säure, Wurzeln, Explosionen und Einschlagkreise treffen nur ihre angekündigten Flächen.

Ablauf:
1. Ziel festlegen.
2. Dezente Zone zeigen.
3. Zeitabhängiger Countdown.
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

- Es soll regelmäßig Positionsdruck geben (Strahl blockiert eine Seite, Bodenexplosion bedroht den Standort, eine zweite Warnung markiert die nächste Gefahr).
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

## H – Technische Grundarchitektur

- **Angriffe als geplante, mehrstufige Sequenzen:** positionieren → Zonen ankündigen → Countdown → aktivieren → nächste Zonen ankündigen → alte deaktivieren → zweite Aktivierung → Abschluss → Bewegungspause. Zeitlich präzise.
- **Weiterhin genau neun Fähigkeiten je Hauptboss.** Eine Fähigkeit darf mehrere Schritte haben.
- **Freischaltung:** Minute 5 → 1–3, Minute 10 → 1–6, ab Minute 15 → 1–9. Früh freigeschaltete Fähigkeiten dürfen später komplexere Varianten bekommen.
- **Warnungen zeigen** Fläche, Zeitpunkt, die danach sicheren Flächen und die bereits vorbereitete nächste Gefahr. Sie bleiben dezent, ohne grelle Vollflächen.
- **Überlappende Phasen** (A aktiv, B angekündigt, A endet, B aktiv) sind ausdrücklich möglich. Es dürfen nie versehentlich alle sicheren Positionen gleichzeitig verschwinden.

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

**Einbau in die bestehenden neun Fähigkeiten.** Die Freischaltung 3/6/9 ist unverändert. Ab Phase 2 bzw. 3 kommen komplexere Varianten hinzu:

| Boss | Fähigkeit | Neue Choreografie |
|---|---|---|
| Drache | 1 Feuerstrahl | Schwenkstrahl 64° (ab Phase 2: 84°), Richtung wechselt. Ab Phase 3 zusätzlich 4 Meteore um den Spieler (Strahl plus Boden). |
| Drache | 2 Feuerbogen | Ab Phase 3 zusätzlich wechselnde lange Feuerkegel (900 px): drei Kegel bei −70°/0°/+70°, danach die Lücken bei ±35°. |
| Drache | 3 Magmaeruption | Ab Phase 2: Magma-Schachbrett, danach das invertierte Brett (1,2 s versetzt, überlappende Warnung). |
| Drache | 4 Meteoritenregen | Ab Phase 2: Einschlagkette vom Drachen durch die Spielerposition hindurch (12 × 92 px). Ab Phase 3 zusätzlich außen/innen. |
| Hexen | 3 Meteor-/Eisregen | Ab Phase 2: Feuer auf dem Schachbrett, danach Eis auf den zuvor sicheren Feldern. |
| Hexen | 4 Verbindungsstrahl | Die Hexen kreisen gegenläufig um die angekündigte Spielerposition. Der Strahl zwischen ihnen überstreicht sie fortlaufend (38°/s, ab Phase 3 46°/s). |
| Hexen | 6 Kreuzschlag | Beide Strahlen reichen 2.600 px weit durch den Zielpunkt. Ab Phase 3 vereist zusätzlich der Boden in Streifen. |
| Hexen | 8 Zonenflut | Ab Phase 2: Feuer auf zwei gegenüberliegenden Quadranten, danach Eis auf den anderen beiden. |
| Behemoth | 2 Säurepfützen | Ab Phase 2: Säurestreifen, dann die versetzten Streifen. Zwischen beiden liegen 0,7 s Lücke zum Spurwechsel. |
| Behemoth | 3 Packende Wurzeln | Ab Phase 2: Wurzeln brechen nacheinander vom Behemoth bis über den Spieler hinaus hervor (10 × 95 px). Ab Phase 3 sind es zwei Linien. |
| Behemoth | 5 Sumpfstampfer | Ab Phase 2: zwei Schockwellen mit Lücken; die zweite Lücke ist um 120° versetzt. |
| Behemoth | 6 Sumpfbrut | Ab Phase 3: Ein Giftring schließt sich um den Behemoth. Der sichere Radius schrumpft von 640 auf 320 px; das verkleinert den Raum gegen Kiting. |
| Behemoth | 7 Giftatem | Ab Phase 2: Der Atem schwenkt um 64°. |
| Behemoth | 8 Sumpfwelle | Die Welle rollt 1.500 px weit statt 650 px. Man kann sie überspringen oder ihre Bahn verlassen. |

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
