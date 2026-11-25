---
tags: [design, verbindlich, vfx, audio, faehigkeiten, progression]
updated: 2026-11-25
status: verbindlich (Fachgebiet Fähigkeiten-Inszenierung, Effekte, visuelle Progression, Ton)
---
# Fähigkeiten, VFX & Audio

Rang 2 unter [[Leitbild]]. Darstellungsregeln (Pixelraster, Animation): [[Visuelles Leitbild & Animation]]. Lesbarkeit und Hierarchie: [[Kampf & Begegnungen]] Abschnitt 8. Technik: [[Technische Architektur]].

## 1. Fähigkeiten als mehrphasige audiovisuelle Ereignisse

**Ist:** Viele Fähigkeiten folgen dem Muster „auslösen, Sprite erscheint, fliegt in eine Richtung“.

**Soll:** Eine Fähigkeit ist ein zusammenhängendes Ereignis aus Phasen. Nicht jede braucht alle.

| Phase | Inhalt | Beispiel-Ton |
|---|---|---|
| 1 Vorbereitung | Körper bzw. Waffe richtet sich aus | Rascheln, Klick |
| 2 Aktivierung | Rune, Zeichen, Mechanik startet | Auslöseton |
| 3 Aufladung | Energie sammelt sich (wächst, pulsiert) | ansteigendes Summen |
| 4 Freisetzung | Entladung, Rückstoß, Mündungsblitz | Knall, Zischen |
| 5 Flug oder Ausbreitung | Projektil mit Spur, Welle, Strahl | Flug-Loop (leise) |
| 6 Einschlag | Treffer-Effekt, Licht, Materialreaktion | Einschlag nach Material |
| 7 Sekundäreffekte | Splitter, Brand, Kette, Bodenfeld | Knistern |
| 8 Abklingen | Nachglühen, Rauch, Verblassen | Ausklang |

**Pflichtphasen je Art:**

| Art | Pflicht | Regel |
|---|---|---|
| Automatischer Grundangriff (Pfeil, Kristallprojektil, Hieb) | 4, 5, 6 | Höchstens 1–2 Vorbereitungsframes, **kein zusätzlicher Verzug**. Der Angriffstakt bleibt unverändert. |
| Kombo-Finisher (Sternenorb, Pfeilhagel, 3. Hieb) | 1, 4, 6, 8 (+3/7 je nach Fähigkeit) | Die Inszenierung darf länger sein, solange der Gameplay-Takt gleich bleibt. Vorbereitung läuft parallel zur Bewegung. |
| Aktive Zauber (automatisch) | 2, 4, 6 (+5/7) | Sofort als **dieser** Zauber erkennbar (Form, Farbe, Ton) |
| Bossangriffe | 1, 3 (Warnung), 4, 6, 8 | Warnregeln aus [[Kampf & Begegnungen]] |

- **Synchronität (G1):**
  - Alle Phasen hängen an einer Zeitachse (Attack Timeline, siehe [[Technische Architektur]]).
  - Gameplay-Ereignisse (Hitbox an/aus, Projektil erzeugen), Effekte und Ton werden aus derselben Zeitachse ausgelöst.
  - Ein Effekt läuft nie „nebenher“ mit eigenem Timer.

**Beispiele zur Verdeutlichung** (keine Implementierungsaufträge):
- **Schusswaffe:** ausrichten, mechanischer Klick, kurzes sichtbares Laden, Energie an der Mündung, Freisetzung, kontrollierter Rückstoß, dezente Flugspur, Einschlag mit Partikeln, Licht und Ton.
- **Artillerie:** ballistische Bahn mit Bodenschatten, sichtbarer Einschlagszeitpunkt, danach ein Bodeneffekt.

## 2. VFX-Philosophie

**Ist:**
- Viele Zauber wirken zu groß, zu massiv und wie einzelne zusammenhängende Sprite-Blöcke.
- Technisch: ein 4-Frame-Sprite, das auf den Radius gestreckt wird (`spell_fx_draw`), dazu Vektorkreise und -linien.
- Die Partikel sind Vektorformen (`spell_vfx`).

**Soll:** feiner, lebendiger, dynamischer, hochwertiger, ohne die Pixel-Art-Identität zu verlieren.

1. **Effekte sind zusammengesetzt**, wirken aber als **ein** Pixel-Art-Element. Bausteine (Kombination je Effekt):
   - **Kern:** animiertes Sprite auf dem Sprite-Raster;
   - **Detail:** feine Pixelpartikel, Funken, Verästelungen auf dem Feinraster;
   - **Licht:** additiver Lichtpuls bzw. Glühen auf der weichen Ebene, plus Weltlicht;
   - **Spur:** dynamische Trail-Linie aus Pixelsegmenten;
   - **Einschlag:** kurzer Blitz, Ring, Bodenkontakt;
   - **Nachglühen:** abklingende Partikel bzw. Bodenmal.
2. **Kohärenz:**
   - Alle Bausteine eines Effekts teilen Palette, Rhythmus und Richtung.
   - Partikel folgen der Bewegung des Kerns (keine beliebig verstreuten Punkte).
3. **Lebendigkeit durch Zeit, nicht durch Fläche:** Energiefluktuation, leuchtendes Vibrieren, wechselnde Intensität, Verformung über die Zeit.
4. **Pixel-Treue:**
   - Kein Strecken eines Sprites auf beliebige Größen. Ein Effekt hat **Größenvarianten** oder wird aus Bausteinen aufgebaut.
   - Vektorformen werden durch Pixel-Sprites ersetzt oder auf das Raster gelegt.
5. **Elementsprache** (Auftrag 22.11.: Elemente sofort erkennbar, egal ob Schwert, Projektil oder Zauber):

   | Element | Farbe (Richtung) | Form | Bewegung |
   |---|---|---|---|
   | Feuer | Orange bis Gelb, dunkelroter Rand | Zungen, Funken | aufsteigend, flackernd |
   | Eis | Weiß bis Cyan | Kristalle, Splitter | starr, dann splitternd |
   | Blitz | Weiß bis Hellblau oder Violett | Zickzack, Verästelung | sprunghaft, extrem kurz |
   | Gift/Natur | Grün | Blasen, Ranken | wabernd |
   | Leere (Void) | Violett bis Schwarz | Sog, Ringe | nach innen |
   | Arkan | Blau bis Violett | Runen, Kreise | rotierend |
   | Physisch | Weiß bis Stahl | Verwischungsbogen, Staub | Schwung |

   Statuseffekte bleiben in der Monster-Silhouette, ohne deckenden Farbüberzug (Auftrag 22.11.).

### Beispiel Blitz (Spezifikation des Vertical Slice)

| Baustein | Umsetzung |
|---|---|
| Kern | dynamischer Zickzack-Pfad aus Pixelsegmenten, jede 2–3 Frames neu erzeugt, 1–2 Artpixel breit |
| Verästelungen | 2–4 kurze Zweige auf dem Feinraster, leben jeweils 1–2 Frames |
| Lichtimpuls | additiver Puls an Start und Ziel, 0,1 s, plus Weltlicht |
| Partikel | 6–12 Funken (1 Artpixel) am Einschlag, fallen und verglimmen |
| Einschlag | heller 2-Frame-Kreuzblitz, kleiner Bodenruß |
| Nachglühen | Zielgegner zuckt, kurzes bläuliches Glimmen in der Silhouette |
| Ton | trockener Knall (Freisetzung) plus Knistern (Einschlag), Tonhöhe variiert |

Jeder Baustein für sich ist unscheinbar. Erst zusammen und zur selben Zeit wirken sie wie ein Blitz.

**Ist (25.11.): umgesetzt für Lightning (Zauber 103)** in `scripts/gameplay_polish`.
- Funktionen: `cast_chain_lightning`, `chain_segment_add`, `chain_visual_draw`, `vfx_band`, `vfx_spell_band`.
- Der Kern wird alle 45 ms neu gezackt und liegt auf ganzen Welteinheiten.
- **Bänder:**
  - Basis: Kern 2 px, 1 Zweig, 3 Funken, kein gestrecktes Burst-Sprite, Licht 110.
  - Mittel: Glühen, 2 Zweige, 6 Funken, kleiner Burst, Licht 150.
  - Endgame: doppeltes Glühen, 4 Zweige, 10 Funken, Burst, Licht 185.
- Die Pixelfunken sind die neue Partikelart 4 in `spell_vfx`.
- Schaden, Ziele, Sprungweite und Takt sind unverändert.
- Ohne Zufallszahlen aus dem globalen RNG (deterministischer Hash), seeded Runs bleiben vergleichbar.

## 3. Größendisziplin

- **Sichtbare Schadensfläche = Hitbox (G6).** Dekoratives Glühen darf den Rand höchstens leicht überschreiten (Richtwert 10 %). Es darf nie wie Schaden aussehen.
- **Kompaktheit ohne Balancing-Änderung (G12):** Radien und Werte bleiben unverändert. Gestaltet werden Füllung, Deckkraft, Rand, Partikelzahl und Licht.
  - Eine große Fläche auf Stufe 1 bekommt z. B. einen feinen Rand und eine schwache Füllung statt einer leuchtenden Vollfläche.
- **Obergrenzen eigener Effekte** (Richtwerte, Vorschlag):
  - Deckkraft von Bodenflächen ≤ 0,35;
  - Kernsprites voll deckend nur im Kern;
  - additives Licht nie weiß übersättigt über dem Spieler.

## 4. Visuelle Progression und Power Scaling

**Ist:**
- Viele Fähigkeiten sind schon auf niedriger Stufe zu groß und zu auffällig.
- Zauber haben **keine** visuellen Stufen; die Darstellung wächst nur mit dem Radius.
- Klassenwaffen haben drei Stufen nach Spielerstufe (1/34/68).

**Soll: drei Bänder**, die zusätzlich durch Talente und Spezialisierungen verfeinert werden.

**Ist (25.11.):**
- **Lightning:** vollständig als zusammengesetzter Effekt (siehe oben).
- **Alle übrigen Zauberfelder und Einschläge:** bekommen das Band ihrer Stufe als **Intensität** (`vfx_band_alpha`: Basis 0,55, Mittel 0,8, Endgame 1,0). Das gilt für:
  - Deckkraft von Burst-Sprite, Feldumriss und Bodenglühen;
  - Lichtpuls;
  - Partikelzahl (Basis: halbe Emission).
- Radien bleiben die Hitbox.
- Eigene zusammengesetzte Effekte je Zauber (wie beim Blitz) sind noch offen.

**Zielbild je Band:**

| Band | Zauberstufe (Vorschlag) | Charakter | Typische Merkmale |
|---|---|---|---|
| **Basis** | 1–3 | kompakt, dezent leuchtend, präzise | Kern plus wenig Partikel, kleines Licht, geringe Bildschirmabdeckung, sofort erkennbar, **nicht langweilig** |
| **Mittel** | 4–6 | sichtbar intensiver | zusätzliche Bausteine (Spur, Sekundäreffekt), stärkere Energie, erste qualitative Veränderung |
| **Endgame** | 7–9 | beeindruckend, Build-Identität | neue Phasen (Aufladung, Nachbeben), Verkettungen, eigener Ton-Layer, große Momente, aber Bossgefahren bleiben sichtbar |

- **Progression ist mehr als Größe:**
  - neue Angriffsphasen, zusätzliche Projektiltypen, neue Bewegungsmuster;
  - Verkettungen, Elementwechsel, neue Sekundäreffekte;
  - verändertes Audio, qualitativ neue visuelle Eigenschaften.
- **Talente und Ausrüstung** dürfen eigene visuelle Merkmale beisteuern, z. B. Supernova: zweite Explosion; Sturmköcher: Fächer. Die Ausrüstungsseltenheit färbt Waffenakzente (Ist).
- **Eskalation muss verdient wirken:** Sieht Stufe 1 schon wie ein Endgame-Effekt aus, fehlt der Raum für Fortschritt.
- **Datenmodell (Vorschlag):** Jede Fähigkeit bekommt ein **VFX-Profil** je Band (Bausteine, Partikelzahl, Lichtradius, Deckkraft, Ton-Variante). Talente setzen Zusatzmerkmale. Siehe [[Technische Architektur]].

## 5. Audio als Teil des Kampfgefühls

**Ist:**
- Zentraler Mixer `fg_sfx`: höchstens 16 Stimmen, 2 je Cue, Mindestabstand je Cue (70 ms, einige Cues eigene Werte), Vorrang für wichtige Ereignisse.
  - Seit 25.11. kommt eine deterministische Tonhöhen-Variation ±5 % für wiederholte Cues dazu.
  - Seit 25.11. senkt sich die Musik weich auf 72 %, solange eine Bossgefahr in ihrer Warnphase ist (`fg_audio_tick`).
  - Damit sind Drosselung, Priorität, Variation und Musikabsenkung vorhanden. Es fehlen noch Band-Varianten der Klänge und eine Hörabnahme.
- Alle Klänge sind programmatisch synthetisierte Prototypen, eine Hörabnahme gab es nicht.
- Musik für Menü, Level und Boss, Ambience für Sumpf und Ruinen.

**Soll:**
1. **Gemeinsam entworfen:** Ton und Bild einer Fähigkeit werden zusammen spezifiziert (Phasentabelle oben) und aus derselben Zeitachse ausgelöst.
2. **Bausteine:**
   - mechanische Geräusche, Aufladung, Waffenbewegung;
   - Energieaufbau und Freisetzung;
   - Einschlag mit **Materialreaktion** (Knochen, Metall, Stein, Fleisch, Schleim);
   - Bossvorbereitung als **Hinweis**.
3. **Informativ:** Gefährliche Bossangriffe haben einen eigenen, wiedererkennbaren Ankündigungston zum Warnbeginn. Er ist Teil der Warnung und läuft auf der Uhr.
4. **Gewicht:** Schwere Angriffe klingen tief und lang, schnelle hoch und kurz. Die Intensität wächst mit dem Band.
5. **Keine Überlastung:**
   - Drosselung je Cue (Mindestabstand), Variation (Tonhöhe ±, 2–3 Varianten);
   - Priorität: Bossgefahr > eigener Treffer > eigene Fähigkeit > Gegnergeräusch;
   - Absenken der Musik bei Bossankündigungen.
   - Gleichzeitige gleiche Ereignisse (z. B. 5 Pfeile, 3 Magmafelder) lösen **einen** Cue aus. Ist: bei Magma schon so.
6. **Fortschritt hörbar:** Endgame-Varianten bekommen zusätzliche Schichten statt nur mehr Lautstärke.
7. **Hörabnahme** durch den Nutzer ist Teil der Abnahme ([[Qualitätsstandard]]).
