---
tags: [design, verbindlich, klassen]
updated: 2026-11-25
status: verbindlich (Fachgebiet Spielerklassen)
---
# Klassen

Rang 2 unter [[Leitbild]]. Technischer Ist-Stand: [[Klassen & Startwaffen]], [[Charaktergrafik & Ausrüstungs-Layer]].

## 1. Warum die Anforderungen bisher getrennt waren

- **Grund:** Der Auftrag vom 22.11. („Zaubermeisterin, Waldläufer, Drachenboss …“) überarbeitete nur Zaubermeisterin und Waldläufer, weil der Schwertkämpfer kurz vorher eigene Aufträge hatte (Master-Style, neues Modell). Deshalb standen dort für nur zwei Klassen Anforderungen, die für alle gelten müssten:
  - „in jeder Animation dieselbe Figur“;
  - „Robe, Haare und Umhang schwingen mit“;
  - „Kleidung zieht beim Richtungswechsel nach“;
  - „mindestens acht Richtungen“;
  - „Kombo mit Finisher“;
  - „eigene Sounds und Licht“;
  - „gleiche Logik für die visuelle Waffenentwicklung“.
- **Fundstellen:** `CLASS_DRAGON_REPORT.md` (Abschnitte Zaubermeisterin, Waldläufer) und `FirstGame_ArtPack/characters/class_overhaul/CHARACTER_ART.md`.
- **Neu (Auftrag 25.11.):** Diese Anforderungen gelten jetzt global (Abschnitt 2). Die Klassenprofile in Abschnitt 3 enthalten nur noch die echten Besonderheiten.

## 2. Anforderungen an jede Klasse (auch künftige)

### Identität und Spiel
- **Rolle:** eine klare Kampfrolle, z. B. Nahkampf/Bewegung, langsame Wucht oder schnelle Salven. Klassen spielen sich verschieden, sind aber über viele Runs ähnlich konkurrenzfähig (Auftrag 22.11.).
- **Startwaffe:**
  - eine eigene automatische Startwaffe, die keinen der sechs aktiven Zauberslots belegt;
  - eine feste, wiedererkennbare Kombofolge mit Finisher;
  - keine übersprungenen Schritte, keine Rücksetzung bei Richtungswechsel;
  - Schaden nur bei echtem Treffer.
- **Weitere Fortschrittsquellen:**
  - ein eigener Talentbaum, der die Identität vertieft statt die Klassen anzugleichen;
  - sichtbare Ausrüstung auf einem Basismodell ohne fest eingebaute austauschbare Rüstung (siehe [[Progression & Builds]]).
- **Angriffe sperren nie die Bewegung.** Automatische Angriffe laufen beim Laufen, Springen und Sliden weiter.

### Darstellung (G7, G8)
- **Richtungen:** acht Blickrichtungen. Die Figur ist in jeder Richtung und jedem Zustand **dieselbe Figur**: gleiche Proportionen, Größe, Farben und Details. Abweichungen höchstens 1 Artpixel bei Kopf- und Fußhöhe, siehe [[Qualitätsstandard]].
- **Zustände:**
  - Bewegung: Idle mit Atmung, Gehen, Laufen, Drehen/Richtungswechsel;
  - Sprung: Vorbereitung, Flug, Fall, Landung;
  - Ausweichen, Slide, Treffer, Tod;
  - jede Kombostufe mit Vorbereitung, Treffer und Nachschwung.
- **Sekundärbewegung:** Haare, Kleidung, Umhang und angelegte Ausrüstung reagieren zeitversetzt auf Bewegung, Richtungswechsel, Sprung und Landung.
- **Ebenen:** Grundkleidung als Basis, Ausrüstung als synchrone Ebenen, Startwaffe als eigene Ebene. Die Reihenfolge der Ebenen ist in allen Richtungen korrekt.
- **Schatten:** ein passender Bodenschatten, der sich bei Sprunghöhe anpasst.
- **Klassenfarbe:** eine eigene Licht- und Effektfarbe als Akzent (siehe Profile).

### Ton
- Eigene Cues je Kombostufe und Finisher, dazu Bewegungsgeräusche (Sprung, Landung, Ausweichen).
- Bei hoher Angriffsfrequenz gilt die Drosselung aus [[Fähigkeiten, VFX & Audio]].

### Visuelle Waffenentwicklung
- **Ist:** drei visuelle Stufen ab Spielerstufe 1, 34 und 68, gleich für alle Klassen (`sword_visual_tier`). Sie sind bewusst ohne Schadenswirkung (Auftrag 22.11.).
- **Seit 25.11. umgesetzt:** Die visuelle Stufe folgt dem tatsächlichen Fortschritt der Waffe, also den Waffen-Upgrades (Stufe 2 und 4, `weapon_visual_tier`). Details: [[Progression & Builds]].
  - Die Regeln der visuellen Progression gelten auch für Klassenwaffen.

### Checkliste für eine neue Klasse
Abnahme nach [[Qualitätsstandard]]:
- Rolle, Kombofolge, Finisher, Klassenfarbe und Talentbaum-Richtung sind schriftlich in diesem Dokument festgelegt.
- Basismodell, acht Richtungen, alle Zustände, Sekundärbewegung, Ausrüstungsebenen und Startwaffen-Ebene sind vorhanden.
- Für jede Kombostufe ist die Zeitachse (Attack Timeline) mit Gameplay-, Effekt- und Ton-Ereignissen definiert.
- Die Suiten `classes` und `visual` sind um die neue Klasse erweitert.

## 3. Klassenprofile (nur Besonderheiten)

### Schwertmeister (`Sword`, `swordsmanv3`; früher „Schwertkämpfer“)
- **Rolle:** Nahkampf, Bewegung, kontrollierte Fläche. Robust (Ist: 120 HP, Tempo 3,2, Power 2).
- **Startwaffe:** Kette aus drei Hieben mit festem Ablauf (`master_combat`, `ObjectSwordHitbox`). Slash-Effekte mit drei visuellen Stufen.
- **Talentrichtung:** Druckwelle am Finale, Rundumhieb, Sturmangriff nach Ausweichrolle, Heilung beim Finale.
- **Aussehen** (Basemodel ohne Ausrüstung, Regel in [[Visuelles Leitbild & Animation]] 5.5a):
  - Identität: blondes, kurzes, wildes Haar und eine kämpferische, breitbeinige Haltung mit tiefem Schwerpunkt.
  - Basis: schlichte, dunkle, eng anliegende Kleidung, Stoffschuhe.
  - Ausrüstung: Waffenrock oder Kettenhemd (Brust), roter Umhang (Rücken) und Schal (Accessoire) sind Ausrüstung, nicht Basis.
  - Klassenfarbe warm (Stahl, Glut).
- **Soll (Auftrag 25.11.):**
  - Hiebe mit sichtbarer Körperrotation und Gewichtsverlagerung.
  - Ausholen, Treffer und Nachschwung mit Verwischungsbild (Smear) statt eines einzelnen Slash-Sprites.
  - Trefferstopp bei Gegnern.
  - Erste Klasse des Vertical Slice.

### Arkanistin (`Mage`, `magev3`; früher „Zaubermeisterin“)
- **Rolle:** langsame, wuchtige Kombos. Zerbrechlich (Ist: 70 HP, Tempo 2,8, Power 4).
- **Startwaffe:** Vierer-Kombo, danach wieder von vorn:
  1. Kristallprojektil
  2. aufsteigender Stabbogen
  3. Runenkreis
  4. ballistischer Sternenorb mit Implosion
- **Talentrichtung:** Fläche (Weite Glyphen), Sternenorb, Bannkreis, Elementarfokus, Supernova.
- **Aussehen** (Basemodel ohne Ausrüstung):
  - Identität: langes, silber-lavendelfarbenes Haar und eine aufrechte, elegante Haltung mit ruhigen Gesten.
  - Basis: schlichte, eng anliegende Tunika und Hose, Stoffschuhe.
  - Ausrüstung: Die Robe gehört auf die Ebenen Brust und Beine, der Sternenstab ist die Waffen-Ebene; beides ist nicht Basis.
  - Klassenfarbe violett-blau.
- **Soll (Auftrag 25.11.):**
  - „Wuchtig“ heißt **Macht durch Phasen und Klarheit**: Aufladen, Entladung, Implosion. Bildschirmfläche ist kein Maßstab.
  - Auf niedriger Stufe sind die Effekte kompakt, der Sternenorb wird mit der Entwicklung sichtbar größer.
  - Robe und Haare schwingen spürbar nach (lange Stoffflächen sind ihr Hauptmerkmal für Sekundärbewegung).

### Waldläufer (`Ranger`, `rangerv3`)
- **Rolle:** schneller Fernkampf, viele kleine Treffer, Gruppenkontrolle. Beweglich (Ist: 82 HP, Tempo 4,2, Power 1).
- **Startwaffe:** fester Zwölf-Schuss-Zyklus:

  | Schuss | 1 | 2 | 3 | 4–8 | 9 | 10 | 11 | 12 |
  |---|---|---|---|---|---|---|---|---|
  | Angriff | Pfeil | Pfeil | 3er-Salve | je ein Pfeil | 5er-Salve | Pfeil | Pfeil | Pfeilhagel |

  - Eine Salve zählt als ein Schritt.
  - Ein Pfeil trifft dasselbe Ziel nur einmal.
- **Talentrichtung:** Tempo, Salvenbreite, Pfeilhagel, Sturmköcher.
- **Aussehen** (Basemodel ohne Ausrüstung):
  - Identität: helles Haar und eine leichtfüßige, federnde Haltung.
  - Basis: schlichtes Leinenhemd, eng anliegende Hose, Stoffschuhe.
  - Ausrüstung: Der grüne Kapuzenmantel liegt auf der Rücken-Ebene, Lederrüstung und Armschienen auf Brust und Händen, der Bogen auf der Waffen-Ebene. Vorschlag: Der Köcher gehört zur Bogen-Ausrüstung und wird auf der Rücken-Ebene gezeichnet. Nichts davon ist Basis.
  - Klassenfarbe grün mit Naturakzenten.
- **Soll (Auftrag 25.11.):**
  - Hohe Frequenz verlangt **kleine, präzise Projektile** mit feiner Spur.
  - Die Wucht steckt in Salve und Hagel, nicht im Einzelpfeil.
  - Ton gedrosselt und variiert, damit Dauerfeuer nicht ermüdet.

## 4. Offene Entscheidungen
1. ~~Klassennamen~~: entschieden am 25.11.: Schwertmeister, Arkanistin, Waldläufer (im Spiel umgesetzt).
2. ~~Waffen-Upgrade-System~~: entschieden und umgesetzt am 25.11. (Karten in der Level-up-Auswahl).
3. **Neue Ausrüstungsplätze** (statt „Umhang-Slot“; seit der Nutzer-Klarstellung vom 26.11. ist ein Umhang Ausrüstung):
   - Umhang bzw. Mantel liegt auf der Rücken-Ebene.
   - Offen ist, ob Rücken, Schultern, Beine und Nebenhand eigene Spielplätze werden (mehr Werte, also Balancing) oder Teil vorhandener Gegenstände sind ([[Visuelles Leitbild & Animation]] 5.5a, Ebenen-Stapel).
