---
tags: [design, verbindlich, kampf, gegner, bosse, lesbarkeit]
updated: 2026-11-26
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
3. **Flächen- und Spezialangriffe** (Formsprache seit 26.11., Phase 2A, Renderer `scripts/hazard_fx`):
   - **Ganze Fläche ab 0 %:** eine dezente, transparente Grundfärbung zeigt den vollständigen künftigen Gefahrenbereich, dazu ein 1-px-Rand. Der Rand unterstützt, ist aber nie das einzige Element.
   - **Integrierter Countdown statt Uhrzeiger:**
     - Dieselbe Form füllt sich vom Ursprung aus: Kreis und Kegel vom Zentrum bzw. von der Spitze, Strahl und Rechteck entlang der Länge, Ring über die Bandbreite.
     - Die Füllfront ist ein schmales, helleres Band.
     - Weil die Grundfärbung von Anfang an die ganze Fläche zeigt, erzeugt die Füllung keine scheinbar sicheren Bereiche.
   - **Zeitabhängige Intensität:** Grundfärbung und Sättigung nehmen mit dem Fortschritt zu.
     - In den letzten 25 % (Commitment) wird der Rand hell und pulsiert.
     - Bei 100 % blitzt die ganze Fläche auf, im selben Update wie der Schaden.
   - **Innere Energie:** spärliche Elementpartikel innerhalb der Form, die zur Mitte hin driften, gegen Ende dichter (Verdichtung).
   - Keine großen, deckenden Vollflächen. Farben unterscheiden sich nach Element und Boss; die zeitliche Sprache ist überall gleich.
3a. **WYSIWYG – gemeinsame Schadensgeometrie (verbindlich):**
   - Sichtbare Gefahrenfläche = tatsächliche Schadensfläche.
   - Warnung, aktive Fläche, Partikel und Treffertest lesen dasselbe Geometrie-Struct `g` (`telegraph_make`/`telegraph_contains`): Kreis, Ring mit optionaler Lücke, Kegel, Linie bzw. Rechteck.
   - Bewegte, rotierende, schrumpfende oder wachsende Formen ändern `g` vor Zeichnung und Treffertest im selben Update.
   - **Aktive Flächen sind zusammenhängend** (`hz_area_draw`): transparente Elementgrundfläche über genau der Geometrie, heller Rand, dichte Pixelpartikel strikt innerhalb der Form (jede Position wird gegen `telegraph_contains` geprüft).
     - Keine aneinandergereihten oder gestapelten Einzelsprites mit Lücken.
     - Explosionseffekte dürfen zusätzlich auf der Fläche liegen, ersetzen sie aber nicht.
   - **Abklingen:** Nach der aktiven Zeit wird die Fläche entsättigt und grau, Partikel steigen auf und verblassen (etwa 0,3 s). So sieht eine abgeklungene Fläche nicht mehr gefährlich aus.
3b. **Überlappende Mechaniken, zeitliche Priorität** (wie in Final Fantasy XIV):
   - Alle Gegnerwarnungen eines Bildes werden gesammelt und nach verbleibender Zeit bis zum Einschlag sortiert gezeichnet (`telegraph_flush`). Die nächste Mechanik liegt immer oben.
   - Warnungen, die mehr als 0,45 s nach der nächsten einschlagen, erscheinen nur als dünner Umriss: keine Füllung, kein Countdown, keine Partikel. Was gerade sicher ist, sieht sicher aus. Sobald eine Mechanik an der Reihe ist, bekommt sie ihre volle Darstellung. So bleibt erkennbar, was zuerst und was danach kommt (Aufnahme 26.11.: Eine gefüllte Vorschau der zweiten Schachbrettwelle ließ die sicheren Felder der ersten unsicher wirken).
   - Große Muster (spielfeldweite Bretter, breite Ringe ab 160.000 px²) werden um 25–30 % schwächer gefüllt, damit der Bildschirm nicht überflutet.
   - Countdown und Intensität laufen pro Mechanik unabhängig.
   - Keine additive Mischung von Warnflächen.
   - Warnungen werden nach allen Spieler- und Welteffekten gezeichnet; eigene Effekte verdecken sie nicht.
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
   - Getönte Fläche mit Füll-Countdown ist ausschließlich Gegnern, Eliten, Minibossen, Bossen und Levelgefahren vorbehalten.
   - Eigene Fähigkeiten zeigen nie solche Warnungen (seit 26.11.: Kegelwarnung des Magierbogens entfernt). Zielhilfen sind `vfx_player_target_mark`: dünne, drehende Runenstriche in Spielerfarbe, ohne Füllung und ohne Countdown, etwa für Sternenorb und Pfeilhagel.
8. **Mehrphasige Angriffe** (Phase 2A): Anticipation → Energy Gathering → Shape Formation → Commitment → Execution/Impact → Recovery/Dissipation.
   - **Zuordnung auf der Warnuhr:** Sammeln am Ursprung (`vfx_charge`: Partikel strömen zum Maul bzw. zur Hand, der Kern wächst, das Licht steigt), Formbildung mit Füll-Countdown, Commitment in den letzten 25 %, Einschlag bei 100 % mit Lichtimpuls.
   - Nicht jede Fähigkeit braucht alle Phasen. Schnelle physische Angriffe (Biss, Hieb, Schweif) bleiben direkt und werden über den Körper angekündigt.
   - Elementprofile (`vfx_palette`, `hz_particles`): Feuer (aufsteigende Glut, Flackern, warmes Licht), Eis (Kristallfunken, kühle Lichtimpulse), Blitz (Funken, kurze verästelte Bögen, weiß-blauer Lichtblitz), Arkan (wirbelnde Punkte, Runen), Gift (aufsteigende Blasen, klar begrenzt).
9. **Strahlen** (`vfx_beam_stream`): zusammenhängender, flackernder Strom statt eines gestreckten Sprites.
   - Kern, Körper und Rand in Schichten; Partikel fließen vom Ursprung nach außen.
   - Die seitlichen Grenzen liegen genau auf der Trefferbreite (1-px-Linie).
   - Gezeichnet wird bis zum Bildrand, die Trefferlinie darf weiter reichen; Entfernung allein schützt nicht.
   - Schwenk und Kopfdrehung verändern Bild und Hitbox gemeinsam.

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
- **Bewegungsidentität** (Ist seit 26.11., Schalter `ENEMY_MOTION_ENABLED`; `enemy_motion_profile`/`enemy_motion_offset` in `scripts/level_worlds`):
  - Je Art eigene, ganzpixelige Körperversätze über der Bildanimation.
    - Sumpfkriecher: schnelles Huschen.
    - Pilzkreatur: Hüpfen.
    - Skelett und Verfluchte Rüstung: steifes Rucken.
    - Ritter, Rüstung und Konstrukt: schwerer Tritt mit langem Bodenkontakt.
    - Eisgeist: seitliches Schweben, steigt vor dem Angriff.
  - Beim Angriff: Ausholen weg vom Ziel, Vorstoß zum Ziel während der Trefferphase.
  - Keine Rotation oder Stauchung (würden Pixelzeilen verschlucken).
- **Angriffe:**
  - Kontaktschaden ist die Grundlage.
  - Gegner mit eigenem Angriff kündigen ihn über den Körper an (kurzes Ausholen).
- **Lesbarkeit:** Statuseffekte bleiben in der Silhouette des Monsters. Die Grundfarbe bleibt erkennbar (Auftrag 22.11.).

### Elitegegner (Nutzerentscheidung 25.11., umgesetzt)
- **Auftreten:** Ab Minute 3 wird **jeder 60. neue Gegner** zur Elite (fester Zähler statt Zufall, Simulationen bleiben vergleichbar). Das gilt für alle Level.
- **Werte (neue, ungetestete Designwerte, `elite_config` in `scripts/survivor_balance`):**
  - 3-fache Lebenspunkte;
  - 1,25-facher Schaden;
  - 1,2-fache Größe;
  - 10 % Chance auf Ausrüstung, mindestens magisch.
- **Erkennbarkeit:** goldener, pulsierender Silhouettenrand (Fog-Umriss).
- **Fähigkeit,** abwechselnd eine von zwei:
  - **Sprungangriff:** In 120–360 px Abstand wird ein Zielkreis (70 px) auf deine Position angekündigt (0,9 s). Die Elite springt im Bogen dorthin; bei der Landung entsteht eine Bodenwelle, die ein Sprung überwindet. Danach 5 s Pause.
  - **Giftfläche beim Tod:** Ein Kreis (85 px) wird 0,6 s angekündigt und bleibt 3 s giftig.
- **Technik:** Beides läuft über das gemeinsame bv2-Gefahrensystem mit denselben Warn-, Treffer- und Pausenregeln wie bei Bossen. Uhrgeber ist der Spawner.

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
