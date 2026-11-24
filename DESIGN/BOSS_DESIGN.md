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

## Analysestand (23.11.2026, vor Umsetzung)

Statische Code-Analyse, noch kein Laufzeittest:
- Bodenangriffe zielen auf die Spielerposition zu Beginn des Windups, und die Warnzeit beträgt mindestens 0,85 s. Wer ständig läuft (Ranger 252 px/s, Mage 168 px/s), verlässt Zonen mit 65–155 px Radius automatisch.
- Angriffe, die um den Boss zentriert sind, reichen nur 310–365 px; Spieler halten 400–580 px Abstand.
- Verfolgung: Drache 65 px/s nur in der Erholung, Behemoth 32 px/s; das Formationszentrum der Hexen hängt einem laufenden Ranger etwa 360 px hinterher.
- Der Teleport greift erst ab 850 px Abstand außerhalb des Bildes, also nie im Band 400–580 px. Außerdem ist er ein technischer Reset ohne Bossidentität.
- Der Feuerstrahl ist bereits lang genug, aber statisch und beim Windup fixiert. Ein Schwenk (`sweep`) existiert, gehört aber nicht zu den neun Fähigkeiten.
- Die QA-Bots hielten 190–250 px Abstand und hatten keine Max-Range- oder Kiting-Strategie. Die 360 Bosskämpfe sagen deshalb nichts über dieses Problem aus.
- Konsequenz für Schwenkstrahlen: Auf 580 px bewegt sich ein Schwenk mit 40°/s mit 405 px/s, schneller als jede Klasse läuft. Gegenwehr ist daher ein angekündigter Sektor mit sicheren Bereichen außerhalb oder das Durchqueren per Slide/Dodge (der Strahl trifft auf Höhe „hoch“).
