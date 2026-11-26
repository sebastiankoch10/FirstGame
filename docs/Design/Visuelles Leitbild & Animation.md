---
tags: [design, verbindlich, grafik, animation, referenz]
updated: 2026-11-26
status: verbindlich (Fachgebiet Art Direction, Darstellung, Animationsqualität)
---
# Visuelles Leitbild & Animation

Rang 2 unter [[Leitbild]]. Die Technik (wie es gebaut wird) steht in [[Technische Architektur]], die Effekte stehen in [[Fähigkeiten, VFX & Audio]].

## 1. Das Problem und das Ziel

**Ist (Nutzerbeobachtung 25.11., durch das Audit bestätigt):**
- Figuren, Gegner und Fähigkeiten wirken wie statische Sprite-Blöcke, die je nach Aktion ausgetauscht werden.
- Sie bewegen sich, wirken aber nicht wie lebendige, zusammenhängende Körper.
- Es fehlt eine gemeinsame visuelle Identität. Assets wirken wie unabhängig voneinander erzeugt.

**Soll:**
- Die Bewegungsqualität, Körperlichkeit und räumliche Glaubwürdigkeit eines animierten 3D-Modells, in hochwertiger 2D/2.5D-Pixel-Art.
- Echte 3D-Modelle sind dafür nicht nötig; entscheidend ist das wahrgenommene Ergebnis.
- Die Lösung besteht **nicht** darin, nur immer mehr Sprites zu produzieren. Sie besteht aus einer Architektur, die alle visuellen Bausteine verbindet.

> **Das Ziel ist nicht mehr Pixel-Art, sondern besser inszenierte, lebendige und kohärente Pixel-Art.**

## 2. Art Direction (gesammelte, weiter gültige Regeln)

- **Quellen:** Nur das FirstGame-ArtPack und daraus abgeleitete eigene Grafik (Auftrag 22.11.).
  - Keine alten Projektgrafiken als Ersatz, kein Mischbetrieb im aktiven Spiel.
  - Konzeptbilder sind keine fertigen Spritesheets.
- **Stilreferenz:** Das Master-Referenzbild des Schwertkämpfers (Auftrag 22.11.) gilt für Gesamtstil, Figuren, Skelette, Slash-Effekte, Schatten, Licht und Umgebung.
  - Weitere Referenzen: Konzepttafeln in `FirstGame_ArtPack/references/` (Zaubermeisterin, Waldläufer, Drachenangriffe, Hexen, Behemoth).
- **Stil:**
  - hochwertige, detailreiche Fantasy-Pixel-Art im Geist klassischer SNES-Action-RPGs, modern umgesetzt;
  - dunkle Welt, die von Magie und Angriffen beleuchtet wird;
  - deutliche Charakter- und Objektschatten.
- **Ein Guss:**
  - einheitliche Pixelgröße (Abschnitt 4), konsistente Konturen, saubere Transparenz;
  - stimmige Paletten, gleichmäßige Schattierung, einheitliche Lichtrichtung (oben links);
  - passende Größenverhältnisse, klare Silhouetten, vergleichbare Detail- und Animationstiefe.
- **Kanten:**
  - keine pauschale Weichzeichnung, keine verschwommen hochskalierten Sprites;
  - keine farbigen Ränder durch falsche Alpha-Behandlung (Auftrag 23.11.).
- **Größe:**
  - Bosse sind sofort als Bosse erkennbar.
  - Sehr große Hauptbosse dürfen etwa ein Viertel des Bildes einnehmen.
  - Kleine Sprites werden **nicht** einfach hochskaliert (Auftrag 22.11.).
- **Bestehendes bewahren:** Das Drachenmodell und die ArtPack-Originale werden nicht verändert. Erweitert wird nur.

## 3a. Referenz Angriffsaufbau und Telegraphing (Auftrag 26.11., Phase 2A)
- **Quelle:** <https://www.youtube.com/watch?v=AbYWv1KrQwg>, Sequenz 03:43–03:58, besonders 03:56 (<https://www.youtube.com/watch?v=AbYWv1KrQwg&t=223s>). Es ist der Endkampf gegen Dark Gaia in Terranigma.
- **Zweck:** nur Aufbau, Formsprache und Timing von Angriffsankündigungen, keine Assets, Designs oder Musik.
- **Methode (ehrlich):** wie bei 3.1 die öffentlichen Storyboard-Bilder der Zeitleiste, hier 320×180 mit nur **einem Bild je ca. 4,9 s** (0:03:36, 03:41, 03:46, 03:51, 03:56, 04:01). Kein Download. Zwischenbilder, Partikel und Timing sind damit **nicht** sichtbar.
- **Tatsächlich beobachtet:**
  - 03:41: Der Boss breitet die Flügel mit magenta-gelben Energiestreifen aus.
  - 03:46: Vom Kern des Bosses geht eine große, flache, halbtransparente graue Trapezform über die Arena; dazu eine senkrechte cyanfarbene Energiesäule, und der Arenaboden hellt auf.
  - 03:51: Die Form ist auf ein schmaleres Dreieck mit Spitze am Boss **fokussiert**.
  - 03:56–04:01: Einschlag am Spieler (rot-orange).
- **Vermutung (nicht beobachtbar):** Das Zusammenziehen dient als Zeitanzeige und Zielfestlegung.
- **Die Beobachtungen des Nutzers** (Energie sammelt sich, Funken strömen zum Ursprung, Form füllt und verdichtet sich, innere Bewegung, Fokussierung, eindeutige sichere Bereiche, clean) sind die verbindliche Grundlage.
- **Umsetzung:**
  - `vfx_charge` (Sammeln am Ursprung).
  - Füll-Countdown und Verdichtung (`tg_render`).
  - Fokus-Umriss: Ein heller, ungefüllter Umriss läuft von außen auf die echte Kante zusammen (`tg_scaled`). Die getönte Fläche bleibt exakt die Schadensfläche.
  - Elementpartikel innerhalb der Form.

## 3. Verbindliche Bewegungsreferenz: Terranigma

**Quelle:**
- Video: Terranigma – Release Date Trailer, <https://www.youtube.com/watch?v=TyG0oysLGf4>, 118 s.
- **Besonders relevant:** die Bosssequenz ab 0:37, <https://www.youtube.com/watch?v=TyG0oysLGf4&t=37s>.
- **Weitere Ausschnitte:** 0:27–0:35 Dungeons mit Lichtkegeln und Treppen, 0:45–0:52 Kampf in einem Turm.

**Zweck:** Referenz **nur** für Bewegungsqualität, Animationsarchitektur und das Zusammenspiel von Bewegung, Effekt und Kampf. Kein Vorbild für Artstyle, Figurendesigns, Sprites, Musik oder andere geschützte Inhalte. Nichts davon wird kopiert.

### 3.1 Analysemethode und Grenzen (ehrlich)

- **Verfügbare Werkzeuge:**
  - kein Browser-Werkzeug mit Videowiedergabe;
  - kein `ffmpeg`, kein `yt-dlp`;
  - keine direkte Videoeingabe.
- **Nicht gemacht:** Das Video wurde **nicht heruntergeladen**. Ein Download von YouTube widerspricht den Nutzungsbedingungen und ist keine „rechtmäßig verfügbare Videodatei“ im Sinne des Auftrags.
- **Tatsächlich ausgewertet:**
  - die öffentlichen Storyboard-Vorschaubilder, die YouTube selbst für die Zeitleiste ausliefert;
  - Auflösung 320×180, **ein Bild pro Sekunde**, 118 Bilder;
  - die Sequenz 0:37–0:39 vergrößert nebeneinander.
- **Damit sichtbar:**
  - Silhouetten, Posen im Sekundenabstand;
  - Größenverhältnisse, Bildaufbau, Effektplatzierung;
  - Licht und Farbwirkung.
- **Damit nicht sichtbar:**
  - Zwischenbilder, Timing, Beschleunigung;
  - Vorbereitung, Nachschwung, Haar- und Stoffbewegung im Detail;
  - die Frame-Abfolge einer Animation.
- **Für das Timing** gelten deshalb die Beobachtungen des Nutzers (3.4) als Grundlage.
- **Wenn eine rechtmäßige Videodatei vorliegt**, z. B. eine eigene Aufnahme des Spiels: Frames mit `ffmpeg -ss 37 -t 6 -i <datei> -vf fps=30 frame_%03d.png` extrahieren. Daraus Kontaktbögen und Differenzbilder erstellen und diesen Abschnitt ergänzen.

### 3.2 Tatsächlich beobachtet (Storyboard, 1 Bild/s)

- **0:37–0:39, Bosskampf in einem schmalen Steinkorridor:**
  - Ein großer, insektenartiger, goldfarbener Boss mit dunklem Kopf und vielen Gliedmaßen sitzt am oberen Ende des Korridors.
  - **Er nimmt etwa die halbe Korridorbreite und rund 40 % der Spielfeldhöhe ein.** Die Spielfigur ist etwa ein Achtel so groß.
- **Pose 0:37:** Gliedmaßen seitlich gespreizt, Körper ruhig. Eine helle, bläuliche Spur zwischen Spielfigur und Boss (Angriff der Spielfigur). Schadenszahl am Boss.
- **Pose 0:38:** Die vorderen Gliedmaßen sind waagerecht weit aufgefächert; die Silhouette wird breiter als der Korridor. Der Rumpf bleibt an derselben Stelle.
  - In der Korridormitte liegt ein dunkler ovaler Schatten ohne Figur darüber; die Spielfigur steht weiter oben bei den Klauen des Bosses.
  - Vermutlich ist sie im Sprung, und der Schatten bleibt am Boden zurück.
- **Pose 0:39:** Die Gliedmaßen sind nach vorn unten zusammengeführt und reichen weit in den Korridor hinein. Am unteren Ende, nahe der Spielfigur, steht eine helle Staub- bzw. Einschlagwolke.
- **Daraus ablesbar:**
  - Der **Rumpf ist der ruhende Anker**. Die **Gliedmaßen ändern die Silhouette drastisch**: gespreizt, aufgefächert, nach vorn gestreckt.
  - Der Angriff **überbrückt sichtbar den Raum** zwischen Boss und Spielfigur.
  - Der **Einschlag sitzt am Boden** am Zielort.
  - **Höhe** wird über einen getrennten Bodenschatten vermittelt.
- **Allgemein (0:27–0:52):**
  - Kleine Spielfiguren in großen, dunklen Räumen.
  - Lokales Licht um die Spielfigur (Lichtkegel, Vignette).
  - Kurze Ganzbild-Effekte (Entsättigung, Aufhellen) zur Betonung.
  - Klare Trennung von Spielfeld und Oberfläche.
  - Bossgröße als Hauptmittel der Bedrohung.

### 3.3 Vermutungen (nicht belegt)

- Ob die Gliedmaßen als **getrennt animierte Teile** oder als **ganze Einzelbilder** gezeichnet sind, ist aus 1 Bild/s **nicht** erkennbar. Wir behaupten weder Skelett-Animation noch Sprite-Layering.
- Der konstante Rumpf bei stark wechselnden Gliedmaßen **spricht für** eine teilbasierte Darstellung. Ganze Frames mit festem Rumpf sind aber ebenso möglich.

### 3.4 Beobachtungen des Nutzers (Grundlage für das Timing)

- Beim Sprung ändert sich nicht nur das Sprite; der ganze Körper vermittelt eine zusammenhängende Bewegung. Haare, Kleidung, Haltung und Landung reagieren aufeinander.
- Der Boss holt mit den Armen sichtbar aus. Körperregionen wirken zusammen, die Bewegungen wirken räumlich, der Boss hat wahrgenommene Masse und glaubwürdige Angriffsanimationen.

### 3.5 Ableitungen für FirstGame (Soll)

| Beobachtung | Umsetzung in FirstGame |
|---|---|
| Ruhender Rumpf, stark wechselnde Gliedmaßen | Große Bosse als **artikulierte Körper**: Rumpf als Anker, Gliedmaßen als Teile mit eigener Bewegung, gemeinsam gerendert ([[Technische Architektur]], Rig-System) |
| Angriff überbrückt den Raum | Die Reichweite eines Nahangriffs ist am Körper sichtbar (gestreckte Gliedmaße, Schweifbahn). Die Hitbox folgt dem Körperteil. |
| Einschlag am Boden, Staub | Jeder schwere Treffer hat einen Bodenkontakt-Effekt (Staub, Riss, Lichtpuls) am echten Trefferort |
| Getrennter Bodenschatten bei Höhe | Höhe immer über einen Schatten vermitteln (Spieler, Projektile, Boss im Flug). Ist: teilweise vorhanden |
| Kleine Figur, großer Boss | Bossgrößen nach [[Kampf & Begegnungen]]; Spielerfigur nicht weiter vergrößern |
| Lokales Licht, kurze Ganzbild-Betonung | Vorhandenes Lichtsystem für Fokus nutzen. Ganzbild-Effekte nur sparsam für Schlüsselmomente (Phasenwechsel, Finisher) |

## 4. Pixelraster und Darstellung

### 4.1 Ist (gemessen am 25.11.2026, isolierte Testkopie)

- **Verzerrung (Hauptbefund):** Die Kamera zeigt **800×600** Welteinheiten (4:3). Ausgegeben wird auf **1280×720** (16:9).
  - Die Welt wird also mit **1,6 horizontal und 1,2 vertikal** skaliert, **um 33 % in die Breite gezogen**.
  - Gemessen: Pixelläufe sind horizontal im Mittel 1,32-mal länger als vertikal.
  - Kreise erscheinen als Ellipsen, Pixel sind nicht quadratisch.
  - Ursache: `ObjectPlayer/Create_0.gml` erzeugt eine 800×600-Kamera; die Räume haben 1366×768-Viewports, das Fenster ist 1280×720.
- **Gemischte Pixelgrößen.** Ein Artpixel entspricht je nach Asset unterschiedlich vielen Welteinheiten:

  | Asset | Welteinheiten pro Artpixel | Bildschirmpixel (x × y) bei 1280×720 |
  |---|---|---|
  | Spielerfiguren (96er-Canvas) | 1,65 → **seit 25.11. 1,0** (160er-Canvas) | 2,64 × 1,98 → 1,33 × 1,33 (720p), 2 × 2 (1080p) |
  | Normale Gegner | 1,15–1,65; **seit 25.11. Kreaturen von Sumpf und Ruinen 1,0** (in Zielgröße gerendert) | bis 2,64 × 1,98; Kreaturen 1,33 × 1,33 |
  | Umgebung (Wald, Sumpf, Ruinen) | 1,0 | 1,6 × 1,2 |
  | Bosse (512er-Sprites auf Zielhöhe skaliert) | ca. 0,25–0,8 | uneinheitlich |
  | Zaubereffekte (`spr_v2_fx`, auf Radius gestreckt) | beliebig (Radius·2/208) | beliebig |
  | Feuer- und Eisball | 0,65 | ca. 1,0 × 0,8 |

- **Weitere Ist-Punkte:**
  - **Partikel und viele Zaubereffekte** sind Vektorformen (Linien, Kreise, Dreiecke) mit beliebiger Position. Sie liegen auf keinem Pixelraster.
  - Keine Shader. Texturfilterung aus (außer der weichen Lichtfläche in halber Auflösung). *Seit 26.11. abends gibt es eine Nachbearbeitung mit Shadern auf der Weltebene, siehe Abschnitt 7.*

**Folge:** Das Bild kann trotz guter Einzel-Assets nicht „aus einem Guss“ wirken.

### 4.2 Soll

1. **Quadratische Pixel, gleichmäßige Skalierung.** Die Kamera hat dasselbe Seitenverhältnis wie die Ausgabe (16:9).
2. **Ein Weltraster für Sprites.** Für jede Asset-Klasse ist die Pixeldichte festgelegt: ein Artpixel entspricht einer ganzen Zahl von Welteinheiten. Neue Assets werden für diese Dichte gezeichnet, nicht nachträglich gestreckt.
3. **Genau zwei erlaubte Detailebenen** (Hybrid):
   - **Sprite-Raster:** Figuren, Gegner, Bosse, Umgebung, Projektile.
   - **Feinraster:** halbe Artpixel, nur für Effektpartikel, Funken, Blitzverästelungen und Spuren. Das sorgt für mehr Detailtiefe ohne Stilbruch.
   - **Weiche Lichtebene** (additives Licht, Glühen, seit 26.11. auch Bloom, Dunst und Tiefenunschärfe am Bildrand, Abschnitt 7) in Ausgabeauflösung. Sie ist kein Pixel-Art-Element und darf weich sein.
4. **Rotation und Skalierung** von Pixel-Art nur:
   - in ganzzahligen Schritten, oder
   - in einem Render-Ziel auf dem Sprite-Raster, sodass das Ergebnis wieder auf dem Raster liegt.
5. **Konkrete Auflösung:** **Vorschlag**; Entscheidung nach A/B-Prototyp, siehe [[Technische Architektur]] R1–R3.

## 5. Animationsqualität: Anforderungen (Soll)

### 5.1 Grundprinzipien (gelten für alles, was sich bewegt)

1. **Vorbereitung, Ausführung, Nachschwung, Erholung** bei jeder deutlichen Aktion. Die Vorbereitung ist bei Spielerangriffen extrem kurz (0–2 Frames), bei Gegnern und Bossen die eigentliche Ankündigung.
2. **Gewicht:** Beschleunigen und Abbremsen sichtbar machen. Schwere Körper bewegen sich träge, leichte federnd.
3. **Zeitversetzte Bewegung:** Haare, Stoff, Schweif, Flügel und Ausrüstung folgen dem Körper mit Verzögerung und schwingen nach.
4. **Bögen statt gerader Linien** bei Gliedmaßen, Waffen und Sprüngen.
5. **Zusammenhängender Körper:** Teile überlappen und verdecken sich glaubwürdig. Keine sichtbaren Nähte, kein Papierpuppen-Effekt.
6. **Silhouette zuerst:** Jede Schlüsselpose ist als Silhouette lesbar.
7. **Füße am Boden:** kein Rutschen der Standpunkte, stabiler Ursprung, keine springenden Bodenlinien.

### 5.2 Spielerfiguren
- **Bewegung:** dynamische Haltung beim Laufen; leichte Neigung beim Beschleunigen, Gegenneigung beim Abbremsen; natürliche Richtungswechsel mit Nachziehen von Umhang und Haar.
- **Sprung in Phasen:**
  - Vorbereitung: ein kurzes Einknicken, **ohne Eingabeverzögerung**;
  - Absprung;
  - Flug mit Gegenbewegung von Haar und Kleidung;
  - Scheitel;
  - Fall;
  - Landung mit Abfedern, Staub und Nachschwingen.
- **Angriffe:** Körperrotation und Gewichtsverlagerung, glaubwürdige Waffenführung, Nachbewegung nach schnellen Aktionen.
- **Auch in einer Richtung** wirkt die Figur nicht starr: Atmung im Idle, Mikrobewegung von Haar und Stoff.
- **Steuerung zuerst:**
  - Visuelle Phasen passen sich dem Gameplay-Takt an, nie umgekehrt.
  - Eine Eingabe unterbricht jede rein visuelle Phase sofort.

### 5.3 Normale Gegner
- **Anatomie bestimmt die Bewegung:**
  - Skelett: klappernd, ruckartige Gelenke;
  - Wolf/Eber: Sprungkraft, Galopp;
  - Spinne/Krabbler: viele Beine, Wellenrhythmus;
  - Flieger: Schweben, Flügelschlag, Höhe mit Schatten;
  - magische Kreaturen: Pulsieren, Partikelkörper.
- Jeder Typ hat einen eigenen Angriffsrhythmus und eine eigene Trefferreaktion (Knochen splittern, Schleim verformt sich, Rüstung funkt).
- **Billige Lebendigkeit:** prozedurales Wippen, Lehnen in Laufrichtung, Treffer-Wackeln. Sie gilt für alle Gegner und kostet kaum Leistung.

### 5.4 Bosse
- Artikulierte Körper, Angriff durch Körpereinsatz, wahrgenommene Masse. Details und Drachen-Anforderungen: [[Boss-Design]] G2.
- **Lebendig zwischen den Angriffen:** Atmung, Gewichtsverlagerung, Kopf folgt dem Spieler, Schweif und Flügel in Ruhe beweglich.

### 5.5 Waffen, Ausrüstung, Beschwörungen
- **Waffen** folgen der Hand (Ankerpunkt) und haben eigene Nachschwung- und Verwischungsbilder.
- **Ausrüstung** ist synchron zum Körper (Ist) und bekommt dieselbe Sekundärbewegung wie Kleidung (Soll, z. B. Schulterstücke, Umhangsaum).
- **Beschworene Kreaturen** folgen denselben Gegnerregeln. Ihr Erscheinen und Verschwinden ist inszeniert.

### 5.5a Charakterdarstellung und Ausrüstung (Nutzerentscheidung 26.11. abends; gilt für alle Klassen)
- **Die heutigen Figuren sind die Figuren.**
  - Schwertkämpfer, Arkanistin und Waldläufer behalten ihr Aussehen (`spr_fg_<klasse>v3_*`).
  - Umhang, Schal, Robe, Mantel und Köcher gehören zur Figur.
  - Basemodels ohne Ausrüstung gibt es nicht. Der Plan vom selben Tag ist verworfen ([[DECISIONS]]).
- **Rüstung ist unsichtbar:**
  - Kopf, Brust, Hände und Füße verändern das Aussehen nicht. Grund: Aufgesetzte Rüstungsebenen wirken auf der Pixel-Grafik nicht gut.
  - Umgesetzt über den Schalter `EQUIPMENT_ARMOR_VISIBLE` (false) in `scripts/equipment_visual`.
  - Gegenstände, Werte, Inventar, Icons und die Ebenen-Grafik bleiben erhalten. Es ist nichts gelöscht, der Schalter holt die Ebenen zurück.
  - Rüstung wieder sichtbar zu machen braucht eine neue Entscheidung des Nutzers.
- **Waffen bleiben sichtbar:**
  - Startwaffe und Waffengegenstände, als Waffen-Ebene je Stufe.
  - Die Grundstufe ist hochwertig, aber zurückhaltend; höhere Stufen sind komplexer. Seltenheit färbt nur Akzente, keine abweichenden Pixelgrößen.
- **Ankerpunkte:**
  - Waffen und künftige Nebenhand-Gegenstände hängen an Griffpunkten je Animationsbild: `eqv_attach`, Daten aus `tests/tools/characters/build_attach_points.py`.
  - Der Griff ist die Projektion der Hand auf die Waffenachse (Schwertheft, Stab- und Bogenmitte).
  - Bei verdeckter Hand (Konfidenz 0) bleibt ein angehängter Gegenstand verborgen.
  - Nie frei schwebend.
- **Bewegung:**
  - Haare, Umhang, Körper und Waffe reagieren gemeinsam: Neigung, Absprung, Steigen, Fallen, Landung, Wende (`player_motion_life`).
  - Ohne Eingabeverzögerung (nur Darstellung).
- **Ist-Stand 26.11.:**
  - Die Ebenen-Architektur (Zellen, Rüstungsebenen, Helm-Kopfschnitt `eqv_hcut`) bleibt im Code. Rüstungsebenen werden nur nicht gezeichnet, also auch kein Helm-Kopfschnitt.
  - Ankerpunkte für 222/212/230 von 256 Zellen (Schwert, Stab, Bogen) sind vorbereitet, aber noch an keine Zeichenstelle angeschlossen.

### 5.6 Fähigkeiten
Visuell relevante Fähigkeiten haben Phasen; siehe [[Fähigkeiten, VFX & Audio]].

## 6. Ist-Stand der Animation (Audit 25.11.)

- **Spielerfiguren:**
  - **Seit 25.11. prozedurale Lebendigkeit** (`player_motion_life` in `scripts/player_artpack`): Streckung beim Absprung, Abfedern bei der Landung, kurzes Stauchen beim Richtungswechsel, gefedertes Lehnen in Tempo und Beschleunigung (höchstens 2,8°). Die Ausrüstungsebenen drehen exakt mit. Rein visuell, keine Eingabeverzögerung.
  - 8 Richtungen × 8 Ausgangsposen je Klasse;
  - Laufen mit 8 Frames, Rennen als schneller abgespielter Lauf;
  - Sprung und Fall wählen Posen nach Fortschritt; Idle ist ein Frame mit Atembewegung;
  - **Seit 25.11. Sekundärbewegung:** Haar und Umhang (Schwertmeister, Waldläufer) bzw. Haar (Arkanistin) schwingen gefedert nach: beim Laufen, Abbremsen, Richtungswechsel und mit einem Impuls bei der Landung.
    - Pro Frame liefert die Pipeline je einen Knochen aus Haar-Label und Umhangmaske.
    - Die Laufzeit verformt das Basismodell über den gemeinsamen Rig (`player_layers_draw` mit Pose, `eqv_bones`).
    - Die Ausrüstungsebenen bleiben unverformt.
  - **Noch keine** gezeichneten Übergangsposen (Landung und Richtungswechsel sind prozedural).
  - Ausrüstung als synchrone Ebenen.
- **Skelette (Wald):** 8 Richtungen, 5 Aktionen, Frame-Animation.
- **Sumpf- und Ruinengegner:** 104er-Sprites, 5 Aktionen in 8 Richtungen, generiert.
- **Minibosse und ein Teil der Fallback-Gegner:** Streifen aus ArtPack 0.1 (64×64, ohne Richtungen), hochskaliert. **Stilbruch.**
- **Drache:**
  - Seit 25.11. **Körper-Rig per 2D-Skinning** (`dragon_rig_*` in `scripts/dragon_boss`): ein Gitter über dem Original-Frame, verformt durch Knochen.
  - In allen Posen: linker Flügel und zweigliedriger Schweif mit Nachlauf.
  - In der Ruhepose zusätzlich: Hals, Kopf (folgt der Höhe des Spielers) und rechter Flügel.
  - Bei Angriffen: Flügelschlag beim Flügelsturm, Aufrichten in der Vorbereitung, Rückstoß bei Treffern.
  - Keine Nähte, Original-PNGs unverändert.
  - In Feuerposen bleiben Kopf und Hals unbewegt, damit Maul-Anker und Strahl übereinstimmen.
- **Hexen, Behemoth:** Einzelsprites je Aktion (2–4 Frames), Richtung durch Spiegeln. Seit 25.11. ebenfalls über den gemeinsamen Rig (`rig_draw_frame`, `bv2_rig_*`): Hexen mit flatterndem Hut, Umhangzipfeln und Saum, Behemoth mit schwer wackelndem Pilzrücken und Kopf, Arme leicht, Klauen am Boden.
- **Zaubereffekte:** 4-Frame-Sprite auf Wirkradius gestreckt, dazu Vektorlinien und -kreise; Partikel als Vektorformen.

## 7. Licht, Atmosphäre und Effekte: Maßstab HD-2D (Grafik-Overhaul, Auftrag 26.11.)

**Maßstab:** Octopath Traveler (HD-2D) für Licht, Effekte, Tiefe und Atmosphäre. Referenzen: 24 Bildschirmfotos des Nutzers in `FirstGame_ArtPack/reference/octopath/` (nur lokal, nicht versioniert, nie im Spiel; [[Assets & Pipeline]]). Keine Assets, Figuren, Szenen oder Farbschemata kopieren; eigener Stil auf diesem Niveau (G10). Gameplay, Bewegung und Angriffsabläufe bleiben unverändert. ~~Figuren bleiben unverändert.~~ *Ergänzung 26.11. abends: Die Figuren gehören zum Overhaul (7.5); ihre Sprites bleiben die Grundlage, die Rüstung bleibt unsichtbar.* Frühere zurückhaltende Licht- und VFX-Vorgaben gelten nur noch, soweit sie hier nicht ersetzt sind ([[DECISIONS]] 26.11. abends).

### 7.1 Was die Referenzen zeigen (Auswertung 26.11.)
- **Licht im Raum:** dunkle Grundstimmung, starke farbige Lichtinseln (Lampen, Feuer, Zauber) auf Boden, Wänden und Figuren; Lichtstrahlen schräg von oben; helle Kerne glühen weich nach (Bloom).
- **Tiefe:** Vordergrund und oberer Bildrand unscharf (Tilt-Shift), dunkle Bildecken (Vignette), Lichter im Hintergrund als weiche Kreise.
- **Atmosphäre:** Staub, Pollen, Glühwürmchen und Schnee schweben und leuchten nur im Licht auf; Dunst in Lichtstrahlen.
- **Angriffe aus vielen Pixeln:** Dutzende bis Hunderte 1–3-px-Partikel statt weniger großer Formen. Weich ist nur das Licht um sie herum.

### 7.2 Aufbau eines Angriffs (abgeleitet aus den Angriffsbildern, verbindlich für alle neuen Effekte)
1. **Sammeln:** Der Kern wächst, Partikel strömen ein, eine Aura steigt um den Wirker oder Boss auf (Lichtsäule, Ringe). Uhr und Timing wie bisher (G1).
2. **Zünden:** weißer, überstrahlter Kern für wenige Bilder, Druckwelle (Verzerrungsring), bei großen Angriffen kurzer Farbumschlag der ganzen Szene in die Angriffsfarbe und leichter Farbversatz (RGB) an den Bildrändern.
3. **Tragen:** eine klare, helle Kernform (Linie, Kugel, Sichel) und darum herum Bewegung: Funken, Glut, Splitter, Lichtbänder, Hitzeflimmern, Licht auf dem Boden.
4. **Einschlagen:** weißer Kern mit Zacken, radialer Funkenstrahl aus länglichen Glutsplittern (Speed-Lines), Druckwelle, Boden leuchtet in der Angriffsfarbe, Rauch oder Splitter je Element; Gewicht über Trefferstopp und Bildschirmwackeln.
5. **Nachglühen:** Funken steigen oder fallen mit Schwerkraft, Splitter fallen, Rauch steigt im Licht auf, Brand- oder Frostmal am Boden verblasst.

### 7.3 Regeln
- **Zwei Ebenen:** Die Weltebene (Gelände, Figuren, eigene Effekte, Angriffsdekor) bekommt Licht, Glühen, Hitzeflimmern, Druckwellen, Farbversatz, Tiefenunschärfe, Farbgebung und Vignette. Die **Lesbarkeitsebene** (Warnungen, Gefahrenflächen mit Rändern, Boss-Geschosse, Marker, Schadenszahlen) wird danach gezeichnet und von keinem dieser Effekte verändert. ~~Neues Dekor eines gegnerischen Angriffs liegt immer unter seiner Gefahrenfläche.~~ *Seit der Ergänzung 26.11. abends:* Auch die Gefahrenflächen selbst (Warnungen, Strahlen, Flächen) dürfen im HD-2D-Stil neu gestaltet werden. Harte Bedingungen: Form = Trefferfläche, sichere Bereiche eindeutig, die nächste Mechanik liegt oben, mindestens so klar wie vorher; je umgestalteter Gefahr eine visual-qa-Zweitmeinung. Funken und Glut **innerhalb** einer deckenden Gefahrenfläche liegen über ihrer Füllung, aber unter jeder Warnung (`FXP_TOP`) (G5, G15).
- **Licht:** verstärkbares Weltlicht (eine Lichtquelle kann bis aufs Doppelte aufhellen). Die Umgebung je Level ist dafür dunkler; jede Flamme, jeder Zauber und jedes Geschoss beleuchtet Boden und Figuren.
- **Pixel:** Partikel, Splitter und Funken liegen auf ganzen Weltpixeln; Hitzeflimmern und Druckwellen verschieben ganze Pixel. Weich sind nur Licht, Glühen, Dunst und die Tiefenunschärfe am Rand.
- **Tiefenunschärfe** nur am oberen und unteren Rand, der Bereich um die Spielfigur bleibt scharf; Gefahren sind davon ausgenommen (Lesbarkeitsebene). Gegner und Bosse bleiben über eine Schutzmaske scharf und werden von der Vignette kaum abgedunkelt; unscharf wird nur Gelände.
- **Atmosphäre je Level:** Wald warm-golden (Staub, Pollen, Glühwürmchen, Lichtstrahlen), Sumpf grünlich (Sporen, Glühwürmchen, schwache Strahlen), Aschenfrost kalt (Asche, Schnee, aufsteigende Glut, kalte Strahlen).
- **Einstellungen:** „Effektqualität“ skaliert alles Neue (Niedrig: nur Farbgebung und Vignette, 30 % Partikel; Mittel: plus Glühen und Hitzeflimmern, 60 %; Hoch: alles). „Lichtblitze: Reduziert“ senkt Farbumschlag, Farbversatz und Blitze auf 35 %.
- **Leistung:** 60 FPS bei voller Horde und im Bosskampf (perf-Suite) bleiben Pflicht. Entlastung bei großen Horden (über 110 Gegner): Tiefenunschärfe und weites Glühen pausieren, Schwebeteilchen dünnen aus; Gegnerschatten sind ein einziges weiches Sprite statt vier Ellipsen.

### 7.5 Figuren (Ergänzung 26.11. abends)
Ziel: dasselbe HD-2D-Niveau wie Licht und Effekte. Die vorhandenen Sprites bleiben die Grundlage, die Rüstung bleibt unsichtbar. Verbessert wird über Shader, Licht und Effekte:
- **Randlicht** (1 px, auf ganzen Pixeln) auf der Seite zur stärksten Lichtquelle in deren Farbe; ohne nahe Quelle ein schwaches Himmelslicht von oben links;
- **farbiges Licht** von Zaubern und Angriffen über das verstärkbare Weltlicht;
- **weicher Bodenschatten**, bei starkem Licht zusätzlich ein längerer Schatten vom Licht weg;
- **Auren** beim Aufladen schwerer Angriffe und bei starken Fähigkeiten;
- **weißes Trefferaufblitzen** (skaliert mit „Lichtblitze“);
- **Waffenglühen:** ein Lichtfunke läuft über die Klinge, die Stabkugel pulsiert; stärker beim Angriff;
- **Staub und Funken** bei Laufen, Absprung, Landung und Ausweichrolle, je Level in passender Farbe (Erde, Sumpf, Asche).

Wo echte neue Pixel-Grafik nötig wäre (z. B. eigene Lichtseiten-Schattierung, Normal Maps, neue Posen), wird nichts vorgetäuscht; die Anforderungen stehen in [[Assets & Pipeline]] 7.8.

### 7.4 Ist-Stand (26.11. abends)
- **Grundlage umgesetzt:**
  - `scripts/render_fx` mit den Shadern `sh_fx_bright`, `sh_fx_blur` und `sh_fx_composite`;
  - `scripts/fx_particles` (gemeinsames Partikelsystem), `scripts/atmos_fx` (Atmosphäre), `scripts/fx_attacks` (Angriffsdekor);
  - verstärkbares Licht in `atmosphere_draw`.
- **Schaustück** (Review, wartet auf das Urteil des Nutzers): Drachen-Feueratem im Wald mit neu gestalteter Gefahrenfläche (`vfx_beam_fire_hd`), Feuerball (Schwertmeister), Kettenblitz (Arkanistin), Eisball (Waldläufer), Schwertmeister mit den Figuren-Effekten (`scripts/fx_character`, Shader `sh_fx_char`), Licht und Atmosphäre der drei Level.
- **Noch nicht umgestellt** (nach dem Urteil, Level für Level und Boss für Boss): alle übrigen Zauber und Passiva, die Startwaffen, alle übrigen Boss-, Miniboss- und Gegnerangriffe samt ihrer Gefahrenflächen, Gegnertreffer und -tode, Figuren-Effekte für Arkanistin und Waldläufer im Review, Münzen, Pickups, Level-up, sanft bewegte Vegetation. Liste in [[Roadmap & Vertical Slice]].
