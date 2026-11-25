---
tags: [design, verbindlich, progression, talente, ausruestung]
updated: 2026-11-25
status: verbindlich (Fachgebiet Progression); Talent- und Ausrüstungsteil bis 24.11. unter DESIGN/TALENTS_AND_EQUIPMENT.md
---
# Progression & Builds

Rang 2 unter [[Leitbild]]. Technik: [[Talente]], [[Ausrüstung]], [[Zauber & Passiva]], [[Progression & Level-up]].

## Grundsätze der Progression (Soll)

- **Build-Tiefe nach dem Vorbild Path of Exile:**
  - Synergien zwischen aktiven Zaubern, Passiva, Talenten und Ausrüstung;
  - unterschiedliche Spezialisierungen;
  - bedeutsame Entscheidungen statt reiner Zahlenschritte.
  - Kein Talentsystem, das alle Klassen gleich macht (Auftrag 24.11.).
- **Zauberpool:** 18 aktive und 18 passive Fähigkeiten, Stufe 1–9, je 6 Slots. Der Spieler kann einen gewünschten Build gezielt verfolgen, ohne dass jeder Run gleich verläuft (Auftrag 22.11.).
  - **Vorgesehen, aber noch nicht umgesetzt:** Rerolls und weitere Auswahlmechaniken.
- **Level-ups sind Ereignisse:**
  - Der erste kommt schnell.
  - Eine neue Fähigkeit soll man einige Sekunden erleben, bevor die nächste Wahl kommt (Ist: mindestens 6 s Abstand).
  - Danach dauern Level-ups zunehmend länger.
  - Keine automatische Heilung beim Level-up.
  - Die XP-Kurve zielt auf vollständige Builds gegen Ende eines erfolgreichen 30-Minuten-Runs (Aufträge 22.11.).
- **Schwierigkeit steigt kontinuierlich.** Es soll nicht passieren, dass:
  - die ersten 15 Minuten trivial sind;
  - die Schwierigkeit plötzlich sprunghaft steigt;
  - der Spieler nach einigen Upgrades unbesiegbar ist;
  - Bosse unabhängig vom Build in Sekunden sterben (Auftrag 23.11.).
- **Waffen-Upgrade-System** (Auftrag 22.11.):
  - Die Klassenwaffen sollen später unabhängig von den sechs Zaubern aufgewertet werden können: Schaden, Tempo, Reichweite, Projektilzahl, Schlaggröße, Durchschlag, Zusatzeffekte.
  - **Offen:** noch nicht umgesetzt. Die Architektur muss es zulassen.
- **Mechanische und visuelle Progression gehören zusammen:**
  - Jede mechanische Stufe hat eine erkennbare, aber verdiente visuelle Entsprechung.
  - Qualitative Veränderungen (neue Phasen, Projektiltypen, Verkettungen, Elemente, Ton) sind ebenso Progression wie Größe.
  - Regeln und Stufenbänder: [[Fähigkeiten, VFX & Audio]] Abschnitt 4.
- **Keine Zahlenänderungen ohne Auftrag.** Werte unten sind Designwerte vom 24.11., nicht ausbalanciert. Empfehlungen werden nur dokumentiert.

## Talentbäume und Ausrüstung (Stand 24.11.2026, Pflege laufend)

### Herkunft der Regeln (wichtig)

**Gefundene Vorgaben:** keine. Durchsucht wurden:
- alle Projekt- und QA-Dokumente
- die Git-Historie
- die 14 früheren Codex-Aufträge (`~/.codex/attachments`) und die Codex-Sitzungsprotokolle

Gesucht wurde nach Talentbaum, Skill Tree, Talentpunkten, Talenten, Freischaltungen, Meta-Progression und Ausrüstung. „Ausrüstung“ kam nur als Wort für die zwölf Zauberslots und in der Optik des Schwertkämpfers vor.

**Neu ergänzt** auf Basis des Auftrags vom 24.11.2026 und deines Wunsches „ohne Rüstung anfangen, Ausrüstung finden“:
- die gesamte technische Grundlage
- 33 Talente
- Punkteregeln
- das Ausrüstungssystem

Alle Zahlenwerte sind **neue, bewusst moderate Designwerte**. Sie sind nicht durch Simulationen ausbalanciert. Siehe „Offene Entscheidungen“.

### Architektur Talente (`scripts/talents/talents.gml`)

- **Daten:** `talent_definitions()` ist eine statische Liste. Jeder Eintrag hat:
  - `id` (eindeutig), `tree` (`general`, `Sword`, `Mage` oder `Ranger`), `name`, `icon` (Sprite-Name)
  - `col`/`row` für die Lage im 3×4-Raster, `max` als maximalen Rang
  - `req` als Voraussetzungen `[[id, Mindestrang], …]`
  - `fx` als `{Schlüssel: Wert pro Rang}`
  - `desc` mit Platzhaltern `{Schlüssel}`, die zur Anzeige mit dem tatsächlichen Wert gefüllt werden
- **Zustand pro Run:** `global.talent_ranks` (id → Rang), `talent_points`, `talent_spent`, `talent_earned`. Der Cache `talent_cache` summiert Rang × Wert aller Knoten aus dem Allgemein-Baum und dem Baum der aktuellen Klasse.
- **Regeln:**
  - `talent_block_reason(id)` liefert `""` oder einen lesbaren Grund: fremde Klasse, maximaler Rang, Voraussetzung fehlt, keine Punkte.
  - `talent_invest` prüft diese Regeln immer, auch wenn die Bots investieren.
- **Wirkung:** `talent_equipment_apply()` läuft am Ende von `apply_passives` jeden Frame. Es baut auf den neu berechneten Zauberwerten auf, damit sich nichts aufaddiert.
  - Klassenmechaniken stecken in `master_combat` (Schwert) und `class_weapons` (Stab, Bogen).
  - Rang 0 ist überall neutral.
- **Punkte:** `talent_config()`
  - `first_point_level=4`, `level_interval=4`: Punkte auf Stufe 4, 8, 12 usw.
  - `boss_points=1` je Hauptboss, `miniboss_points=0`
  - `persistent=false`: Die Talente gelten nur für einen Run. Mit `true` werden Ränge und Punkte je Klasse in `firstgame_talents.ini` gespeichert und geladen. Die Funktionen dafür existieren, sind aber nicht aktiv.
- **Bots:** `talent_bot_invest()` verteilt Punkte deterministisch, erst im Klassenbaum, dann im Allgemein-Baum. Das nutzen nur die QA-Simulationen.

### Oberfläche

**Charakterbildschirm:** Taste **T** während des Spiels oder im Pausenmenü „Talente & Ausrüstung“. Das Spiel pausiert. Schließen mit T, Esc oder dem Knopf.
- **Links Ausrüstung**, Mitte der Allgemein-Baum, rechts der Baum der eigenen Klasse. Fremde Klassenbäume werden nicht angezeigt.
- **Knotenzustände:**
  - gesperrt: dunkel, mit Schloss
  - verfügbar: goldener pulsierender Rahmen
  - investiert: Rahmen in Klassenfarbe
  - maximal: hell, mit Schein
- **Darstellung:**
  - Meistertalente (zwei Voraussetzungen) sind Rauten.
  - Rangpunkte stehen unter dem Knoten.
  - Verbindungslinien leuchten, sobald die Voraussetzung erfüllt ist.
- **Tooltip:**
  - Name, Rang x/max, aktuelle und nächste Wirkung
  - Voraussetzungen mit [x]/[ ]
  - der Grund, warum nicht investiert werden kann
- **HUD:**
  - „Talentpunkte: N [T]“ neben der Stufe
  - Einblendung „+1 Talentpunkt (Stufe 8) – [T]“

### Talentdefinitionen

Die Wirkung ist pro Rang angegeben.

#### Allgemein (alle Klassen)

| Talent | Rang | Wirkung | Voraussetzung |
|---|---|---|---|
| Zähigkeit | 3 | +6 max. Leben | – |
| Leichtfüßig | 3 | +3 % Bewegung | – |
| Sammlerblick | 2 | +12 px Sammelradius | – |
| Schutzhaut | 3 | +0,4 flache Rüstung | Zähigkeit 2 |
| Zweiter Atem | 3 | Ausweichrolle 0,1 s schneller bereit; Untergrenze 0,6 s | Leichtfüßig 2 |
| Konzentration | 3 | −2 % Zauber-Abklingzeit | Sammlerblick 1 |
| Lebenskraft | 2 | +0,15 Leben/s | Schutzhaut 1 |
| Glückstreffer | 3 | +2 % Krit-Chance | Konzentration 2 |
| **Überlebenswille** | 1 | einmal pro Run ein tödlicher Treffer → 1 Leben und 1,5 s unverwundbar | Lebenskraft 1, Zweiter Atem 2 |

#### Schwertkämpfer

| Talent | Rang | Wirkung | Voraussetzung |
|---|---|---|---|
| Klingenschärfe | 3 | +6 % Schwertschaden | – |
| Weiter Schwung | 3 | +6 % Hiebreichweite | – |
| Kampfrhythmus | 3 | +4 % Angriffstempo | – |
| Wellenfinale | 2 | der 3. Hieb löst eine Druckwelle aus (Radius 95, 35 % Schaden) | Klingenschärfe 2 |
| Eiserne Haltung | 2 | +0,5 Rüstung | Weiter Schwung 1 |
| Sturmangriff | 2 | +20 % auf die nächste Kette innerhalb 1,5 s nach einer Ausweichrolle | Kampfrhythmus 2 |
| Blutrausch | 2 | ein Finale, das trifft, heilt 2 Leben | Wellenfinale 1 |
| **Klingensturm** | 1 | jede 4. Kette endet mit einem 360°-Rundumhieb | Wellenfinale 2, Sturmangriff 1 |

#### Zaubermeisterin

| Talent | Rang | Wirkung | Voraussetzung |
|---|---|---|---|
| Arkane Macht | 3 | +1 Power | – |
| Weite Glyphen | 3 | +5 % Wirkfläche | – |
| Arkaner Schild | 2 | −4 % erlittener Schaden (Gesamtgrenze 60 %) | – |
| Sternenkunde | 2 | Sternenorb (Kombo 4): +12 % Radius und Schaden | Arkane Macht 2 |
| Zauberfluss | 3 | −3 % Zauber-Abklingzeit | Weite Glyphen 1 |
| Bannkreis | 2 | Magiekreis (Kombo 3) verlangsamt 1,2 s um 30 % | Weite Glyphen 2 |
| Elementarfokus | 3 | +5 % Feuer-, Kälte- und Blitzbonus | Zauberfluss 2 |
| **Supernova** | 1 | Implosion zieht normale Gegner an, zweite Explosion mit 50 % Schaden | Sternenkunde 2, Elementarfokus 1 |

#### Waldläufer

| Talent | Rang | Wirkung | Voraussetzung |
|---|---|---|---|
| Scharfe Spitzen | 3 | +8 % Pfeilschaden | – |
| Schnelle Sehne | 3 | +4 % Angriffstempo | – |
| Falkenauge | 2 | +10 % Waffenreichweite | – |
| Breite Salve | 2 | 3er- und 5er-Salven: +1 Pfeil | Schnelle Sehne 2 |
| Jägerinstinkt | 3 | +3 % Bewegung | Falkenauge 1 |
| Dichter Hagel | 2 | Pfeilhagel: +1 Einschlagwelle | Scharfe Spitzen 2 |
| Präzision | 3 | +3 % Krit-Chance | Jägerinstinkt 1 |
| **Sturmköcher** | 1 | jeder Pfeilhagel feuert zusätzlich einen Fächer aus 7 Pfeilen | Breite Salve 1, Dichter Hagel 1 |

**Klassenidentität:**
- Schwert: Nahkampf, Bewegung (Sturmangriff) und kontrollierte Fläche (Druckwelle, Rundumhieb).
- Zaubermeisterin: langsame, wuchtige Kombos und große Effekte.
- Waldläufer: Tempo, Salven und Pfeilhagel.

Die 12er-Kombo des Waldläufers bleibt ohne Talente exakt: 1, 1, 3, 1, 1, 1, 1, 1, 5, 1, 1, Hagel.

### Ausrüstung (`scripts/equipment/equipment.gml`)

- **Start:** Jeder Run beginnt ohne Ausrüstung.
- **Slots:** Waffe, Kopf, Brust, Hände, Füße, Talisman.
- **Seltenheit:**

  | Seltenheit | Werte | Faktor |
  |---|---|---|
  | Gewöhnlich | 1 | ×1,00 |
  | Magisch | 2 | ×1,10 |
  | Selten | 3 | ×1,22 |
  | Episch | 4 | ×1,38 |

- **Werte je Slot:** Der erste ist fest.
  - Waffe: Waffenschaden %, Krit, Tempo, Power
  - Kopf: Rüstung, Leben, Abklingzeit, Regeneration
  - Brust: Rüstung, Leben, Schadensreduktion, Regeneration
  - Hände: Rüstung, Tempo, Krit, Power
  - Füße: Rüstung, Bewegung, Ausweich-Abklingzeit, Sammelradius
  - Talisman: Regeneration, Power, Fläche, Elementarbonus, Sammelradius, Leben
- **Gegenstandsstufe:** 1 + Spielminute / 2,5. Wert = (Basis + Stufe × Zuwachs) × Seltenheit × Zufall (0,88–1,12) aus einem eigenen deterministischen RNG.
- **Quellen:**
  - Hauptboss: 2 Gegenstände, einer mindestens selten (30 % episch)
  - Miniboss: 1 Gegenstand, mindestens magisch
  - normale Gegner: 0,3 % (75 % gewöhnlich, 20 % magisch, 5 % selten)
- **Aufnahme:**
  - Man läuft darüber (34 px). Ein leerer Slot wird angelegt. Ist der Fund **klar besser** als das Angelegte (höhere Seltenheit oder mindestens 20 % höhere Wertsumme), wird er direkt angelegt und das alte Teil kommt in den Rucksack. Ein gewöhnliches altes Teil wird bei vollem Rucksack verworfen. Alles andere geht in den Rucksack (8 Plätze). Ist der voll, bleibt der Gegenstand liegen und es erscheint ein Hinweis.
  - Im Charakterbildschirm legt Linksklick an oder tauscht, Rechtsklick wirft weg. Der Tooltip vergleicht Wert für Wert mit dem angelegten Gegenstand.
- **Darstellung:**
  - Drops mit Lichtsäule in Rarity-Farbe, eigener Lichtquelle und Punkt auf der Minimap
  - HUD-Leiste mit den sechs Slots über den Zauberslots
- **Sichtbarkeit am Charakter (seit 24.11.2026):**
  - Kopf, Brust, Hände, Füße und Waffe erscheinen als Ebenen auf dem Basismodell. Das Aussehen hängt an der Stufe aus der Gegenstandsstufe, die Seltenheit färbt die Akzente.
  - Der Talisman ist nicht sichtbar.
  - Details und Grenzen: [[Charaktergrafik & Ausrüstungs-Layer]].

### Tests

`python tests/tools/run_native_harness.py feature` prüft nativ für alle drei Klassen:
- Startzustand
- Punktevergabe auf Stufe 3, 4, 5 und 8 sowie für Haupt- und Miniboss
- fremde Klasse gesperrt, Voraussetzungen, maximaler Rang
- Wirkungen auf Leben, Tempo und Power
- Klassenmechaniken: Druckwelle, Sternradius, 3→5- und 5→7-Salven
- Überlebenswille
- Anlegen, Rucksack, Tausch, Waffenmultiplikator
- Boss- und Miniboss-Drops, Aufnahme durch Darüberlaufen
- Charakterbildschirm per T, Mausklick und Esc
- Partikel

### Offene Entscheidungen
1. **Punktevergabe:** pro Stufe, pro Boss oder als dauerhafte Meta-Progression zwischen Runs. Umschaltbar über `talent_config().persistent`.
2. **Respec:** Ob Talente zurückgesetzt werden können, ist nicht vorgesehen und offen.
3. **Zahlenwerte von Talenten und Gegenständen:** Sie brauchen menschliche Spieltests und gezielte Simulationen.
4. **Ausrüstungsoptik am Charakter:** seit 24.11. umgesetzt (prozedural abgeleitet). Offen sind die künstlerische Feinabnahme und handgezeichnete Varianten.
5. **Weitere Talentquellen:** Ob es zusätzliche Quellen geben soll, etwa Truhen, ist offen.
