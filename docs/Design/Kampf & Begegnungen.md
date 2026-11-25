---
tags: [design, verbindlich, kampf, gegner, bosse, lesbarkeit]
updated: 2026-11-25
status: verbindlich (Fachgebiet Kampf, Begegnungen, Lesbarkeit)
---
# Kampf & Begegnungen

Rang 2 unter [[Leitbild]]. Bossdetails stehen in [[Boss-Design]], die Darstellung der Effekte in [[Fähigkeiten, VFX & Audio]].

## 1. Der zentrale Gameplay-Loop: räumliche Entscheidungen unter Druck

Der Spieler soll sich regelmäßig fragen:
- Welche Fläche ist gerade sicher, welche wird als Nächstes gefährlich?
- Wo kann ich stehen bleiben und Schaden machen?
- Welche Gegner verfolgen mich, und wie viel freier Raum bleibt mir?
- Erreiche ich den sicheren Bereich rechtzeitig, oder muss ich springen, sliden oder ausweichen?
- Muss ich meine Position schon vor dem nächsten Angriff ändern?
- Verzichte ich kurz auf Schaden, um zu überleben?

**Das Zusammenspiel ist der Kern.** Beispiel: Ein Boss legt ein Schachbrettmuster, während die Horde den Spieler verfolgt. Der Spieler muss das Muster verstehen und zugleich entscheiden, wie er im verbleibenden sicheren Raum mit den Gegnern umgeht.

**Regel für Inhalte:** Jede neue Bossmechanik wird mit Horde gedacht und getestet, nicht nur isoliert.

**Herkunft:**
- Auftrag 22.11.: „die eigentliche Schwierigkeit von FirstGame“, Gegnergruppen schränken die sicheren Bewegungen ein.
- Bossphilosophie 23.11.
- Auftrag 25.11.

## 2. Bewegungswerkzeuge des Spielers

| Werkzeug | Ist (25.11.) | Soll |
|---|---|---|
| Laufen | Schwertkämpfer ca. 192, Zaubermeisterin 168, Waldläufer 252 px/s; freie Bewegung, Maussteuerung optional | Sichtbare Beschleunigung und Abbremsung **nur in der Darstellung**. Die Steuerung bleibt direkt (kein Rutschen, keine Eingabeverzögerung). |
| Sprung (Leertaste) | 0,66 s, Höhe nur visuell, überspringt Bodenangriffe | Werkzeug zur Positionierung mit begrenzter Weite, keine Endlosketten. Visuell: Vorbereitung, Flug, Landung (siehe [[Visuelles Leitbild & Animation]]). |
| Slide | nur durch zweite Eingabe im Zeitfenster, unterläuft hohe Angriffe | unverändert; nie automatisch nach einem Sprung |
| Ausweichrolle (Strg) | 1,5 s Abklingzeit, kurze, getrennt konfigurierbare Unverwundbarkeit | Bleibt das einzige Werkzeug mit pauschalem Schutz, klar begrenzt. |
| Automatische Angriffe | laufen in allen zulässigen Bewegungszuständen | Angriffe sperren die Bewegung nie. |

**Trefferhöhen** (G4): Jeder Gefahrenbereich hat `ground`, `high` oder `all`.
- **Sprung** schützt vor `ground` (Schockwellen).
- **Slide** schützt vor `high` (Strahlen über dem Boden).
- **`all`** trifft immer. Diese Höhe gilt für Magma, Meteore und große Flächen, die man verlassen muss.
- **Darstellung:** Die Höhe muss sichtbar sein, z. B. durch Bodenschatten, Flughöhe, die Form der Warnung oder einen Hinweis in der Animation.

## 3. Kiting und Distanz

- **Kiting, Fernkampf und freie Bewegung sind legitim.** Kein Zwang in den Nahkampf, keine künstliche Reichweitengrenze.
- **Gegen das „Kreisen auf maximaler Distanz“** helfen interessantere Mechaniken:
  - weit reichende, schwenkende Strahlen (über den sichtbaren Bereich hinaus);
  - gezielt platzierte Bodenangriffe;
  - großflächige Muster;
  - seltene, klar angekündigte Aufhol- und Repositionierungsangriffe.
- **Bodenangriffe bleiben lokal und zeitlich präzise lesbar.**
- Details und Umsetzungsstand: [[Boss-Design]] A–C.

## 4. Physische und magische Angriffe

Diese Einteilung ist eine Richtlinie, keine starre Regel. Entscheidend sind Abwechslung, Lesbarkeit und eine passende Inszenierung.

| | Physisch (Hieb, Klaue, Biss, Ansturm, Schweif) | Magisch (Strahl, Feld, Meteor, Nova) |
|---|---|---|
| Typische Ankündigung | **Körperbewegung**: Ausholen, Gewichtsverlagerung, kurzer Ton-Cue. Bodenmarkierung nur bei großer Reichweite. | Warnfläche mit Countdown, Aufladen, Lichtaufbau |
| Tempo | schnell, kurze aktive Fenster, verlangt Reaktion | oft mehrphasig, verzögert, verkettet; darf auch schnell sein |
| Fläche | klein bis mittel, folgt dem Körperteil (Schweifbahn, Klauenbogen) | mittel bis riesig, Muster, Zonen |
| Gegenspiel | rechtzeitig ausweichen, Sprung oder Slide nach Höhe | Position planen, sichere Fläche erreichen |
| Gefühl | kinetische Energie, Wucht, Trefferstopp | Energieaufbau, Entladung, Nachwirkung |

## 5. Warnungen (Telegraphs): globale Regeln

1. **Synchron (G1):** Warnung, Hitbox, Schaden, Effekt und Ton laufen über dieselbe Uhr des Besitzers.
   - Bei 100 % wird die Attacke im selben Update aktiv, ohne versteckte Wartezeit.
   - Vor 100 % gibt es keinen Schaden aus der angekündigten Fläche.
   - Pause hält alles gemeinsam an.
   - Ist: so umgesetzt für Bossgefahren (`v2_clock`, `attack_telegraph`, `bv2_*`), nativ getestet.
2. **Nicht jeder Angriff braucht eine Bodenwarnung.**
   - Normale Projektile haben eine sichtbare Flugbahn und Höhe (Schatten), aber keine Bodenwarnung.
   - Schnelle physische Angriffe werden über den Körper angekündigt.
3. **Flächen- und Spezialangriffe:**
   - voller Umriss ab 0 %;
   - dezenter Countdown am Rand;
   - kontrollierte Intensivierung zum Ende hin;
   - präzises Aufleuchten im Treffermoment.
   - Keine großen, deckenden Vollflächen.
4. **Strahlen:**
   - Konzeptionell unbegrenzte Reichweite (Geometrie, kein weltlanges Sprite).
   - Der Schwenk-Sektor wird angekündigt; der Schwenk ist erkennbar und nicht schneller als nötig.
   - Pro Überstreichen trifft ein Strahl höchstens einmal.
5. **Zielpunkte** werden zu einem nachvollziehbaren Zeitpunkt festgelegt (Zielerfassung, Ankündigung, Festlegung, Angriff).
   - Eine kontrollierte Nachführung ist nur erlaubt, wenn sie angekündigt und ausweichbar ist.
   - Felder springen nie ohne neue Warnung auf den Spieler.
6. **Warnzeiten-Richtwerte** (Ausgangswerte aus dem Auftrag vom 22.11., keine Balancing-Vorgabe):

   | Art | Richtwert |
   |---|---|
   | schneller Projektilangriff | 0,5 s |
   | gewöhnlicher Flächenangriff | 1,0 s |
   | großer Strahl | 1,2 s |
   | Meteoritenregen | 1,8 s |
   | besonders gefährlicher Spezialangriff | 2,5 s |

   Später kürzere Warnzeiten sind erlaubt, solange sie lesbar bleiben.
7. **Gegnerwarnung und Spielereffekt haben verschiedene Formsprachen.**
   - Die Kombination aus vollem Umriss und Rand-Countdown ist Gegnergefahren vorbehalten.
   - Spielerflächen (z. B. das Zielmal des Pfeilhagels) nutzen eine eigene Markierung.

## 6. Fairness und Dichte

- **Realistisch erreichbar:** Für jede Sequenz muss eine sichere Position erreichbar sein, mit:
  - der langsamsten Klasse;
  - der tatsächlichen Hitbox;
  - Hindernissen;
  - gleichzeitig verfolgenden Gegnern;
  - ohne perfektes Vorwissen.
- **Vorschlag als Testkriterium:**
  - Weglänge geteilt durch die Laufgeschwindigkeit der langsamsten Klasse plus 0,3 s Reaktionszeit muss kürzer sein als die Warnzeit.
  - Zählt ein Sprung oder Slide mit, gelten dessen Dauer und Abklingzeit.
  - Die Boss-Suite prüft das bereits für die Muster (Orakel); neue Mechaniken nutzen dasselbe Verfahren.
- **Wechsel der Intensität:** freie Bewegung → Einzelangriffe → Spezialangriff → kurze Kombination → Erholung.
- **Dichte:**
  - Kurze Spitzen mit hoher Projektil- oder Flächendichte sind erlaubt.
  - Dauerhaft fast vollständig gefährliche Bildschirme sind es nicht.
- **Überlappende Phasen sind erwünscht:** A aktiv, B angekündigt, A endet, B aktiv.
  - Es dürfen nie versehentlich alle sicheren Positionen gleichzeitig verschwinden.
  - Ein zufälliges Zusammentreffen zweier Mechaniken muss diese Regel ebenfalls einhalten. Das ist ein Grund, Bossrotationen zu planen statt zu würfeln.
- **Ursachenanalyse vor Zahlen:**
  - Trifft ein Angriff unverhältnismäßig oft, werden zuerst Warnzeit, Fläche, Animation, Synchronität und Überlappung geprüft, nicht der Schaden.
  - Trifft ein schwerer Angriff praktisch nie, ist er bedeutungslos. Auch das ist ein Fehler.

## 7. Gegnerdesign

### Normale Gegner
- **Rolle:** Sie bilden Horden, lassen sich sammeln und kiten und verengen den Raum. Ihre Bewegung ist flüssig, mit dezenter Trennung, ohne Zittern und ohne Stapeln.
- **Individualität (Soll, Auftrag 25.11.):** Gegner unterscheiden sich durch Anatomie, Masse, Bewegungsweise und Angriffscharakter, nicht nur durch Sprite, Schaden und Tempo. Ein Wolf bewegt sich anders als ein Skelett, eine Spinne, ein Flieger oder eine magische Kreatur.
- **Angriffe:**
  - Kontaktschaden ist die Grundlage.
  - Gegner mit eigenem Angriff kündigen ihn über den Körper an (kurzes Ausholen).
- **Lesbarkeit:** Statuseffekte bleiben in der Silhouette des Monsters. Die Grundfarbe bleibt erkennbar (Auftrag 22.11.).

### Elitegegner
**Vorschlag, noch nicht im Spiel:** ein normaler Gegnertyp mit einer zusätzlichen, gut lesbaren Mechanik:
- z. B. ein angekündigter Sprungangriff oder eine kleine Fläche beim Tod;
- dazu eine klare visuelle Markierung (Silhouettenrand, Größe, Aura) und ein eigener Ton-Cue.
- Elitegegner nutzen dieselben Warnregeln wie Bosse.
- **Offen:** Ob und wann sie kommen, entscheidet der Nutzer (Roadmap).

### Minibosse
- **Zeitplan:** Minute 1 und 3.
- **Größe:** deutlich größer als normale Gegner.
- **Angriff:** ein eigener automatischer Grundangriff plus Spezialangriffe.
- **Ist:** Sie nutzen teils noch die Gegnerstreifen aus ArtPack 0.1 (64×64, ohne Blickrichtungen). Das ist ein Stilbruch; siehe [[Roadmap & Vertical Slice]].

### Hauptbosse (Prinzipien; Details in [[Boss-Design]])
- **Fähigkeiten:**
  - genau neun je Hauptboss;
  - Freischaltung 3/6/9 in Minute 5/10/15;
  - früh freigeschaltete Fähigkeiten dürfen später komplexere Varianten bekommen.
- **Rotationen:** lernbare Abfolgen, keine Zufallsfolgen. Jeder Boss hat eine eigene spielerische Identität.
- **Körper als Kommunikation (Soll, Auftrag 25.11.):**
  - Große Bosse haben artikulierte Körper.
  - Der Angriff ist im Körper sichtbar: Ausholen, Gewichtsverlagerung, das Körperteil, das trifft.
  - Die Hitbox folgt dem sichtbaren Körperteil (z. B. der Schweifspitze).
- **Größe:**
  - Hauptbosse dominieren das Feld.
  - Besonders große Bosse dürfen etwa ein Viertel der sichtbaren Fläche einnehmen (Auftrag 22.11.).
- **Präsenz:** Der Spieler darf den Boss nicht dauerhaft aus dem Bild ziehen.
  - Aufholattacken haben Vorrang vor dem Teleport.
  - Der Teleport ist nur ein Notfall.

## 8. Visuelle Hierarchie und Lesbarkeit

Rangfolge, was bei Konflikten sichtbar bleiben muss (1 = höchste):

1. **Spielerfigur und ihr Bodenkreis/Schatten:** immer erkennbar, auch unter Effekten.
2. **Tödliche Bossmechaniken:** aktive Gefahrenflächen, Strahlen, Einschläge.
3. **Angekündigte Gefahren:** Warnumrisse, Countdown-Rand, nächste Gefahr.
4. **Angriffsvorbereitung von Gegnern:** Ausholen, Aufladen, Augenleuchten.
5. **Gegnerprojektile.**
6. **Gegner:** Silhouetten, Lebensleisten nur bei Bedarf.
7. **Eigene Fähigkeiten:** Kern und Einschlag.
8. **Sekundäre Partikel**, Nachglühen, eigene Lichter.
9. **Umgebung und Hintergrund.**

**Regeln:**
- **Zeichenreihenfolge folgt der Rangfolge.** Gegnerwarnungen und Bossgefahren liegen über den eigenen Effekten.
  - Ist: `ObjectController/Draw_73` zeichnet Zauber vor den Bossgefahren. Bossgefahren liegen also schon darüber.
- **Eigene Bodeneffekte** bleiben halbtransparent und unter einer Deckkraft-Obergrenze (Richtwerte in [[Fähigkeiten, VFX & Audio]]). Sie benutzen nie die Formsprache gegnerischer Warnungen.
- **Farben haben Bedeutung.** Elementfarben gelten für Freund und Feind. Unterschieden werden beide durch die Formsprache (Umriss plus Rand-Countdown = Gefahr) und die Intensität, nicht nur durch die Farbe.
- **Endgame-Effekte** dürfen beeindrucken, aber sichere Flächen bleiben erkennbar.
  - **Vorschlag:** Bei aktiven Bossgefahren werden eigene Effekte automatisch gedämpft (Deckkraft, Partikelzahl).
- **Ist-Mangel:** Die Darstellung ist derzeit horizontal um 33 % gestreckt. Kreise erscheinen als Ellipsen, und Entfernungen in x und y wirken verschieden.
  - Das verfälscht die Einschätzung von Abständen und sicheren Flächen.
  - Behebung: R1 in [[Technische Architektur]].

## 9. Trefferrückmeldung

- **Treffer sind spürbar:** Trefferreaktion des Gegners, Einschlagseffekt, Ton, Schadenszahlen.
- **Vorschlag für physische Treffer:**
  - kurzer Trefferstopp (Hitstop) von 1–3 Frames nur für Gegner und Effekt, nie für die Spielersteuerung;
  - kleiner Rückstoß;
  - Materialklang (Knochen, Rüstung, Fleisch, Stein).
- **Der Spieler** bekommt beim eigenen Treffer klares rotes Feedback. Ist: Trefferblitz und HUD.
