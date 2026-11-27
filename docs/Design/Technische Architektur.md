---
tags: [design, verbindlich, architektur, rendering, animation, performance]
updated: 2026-11-27
status: verbindlich als Zielarchitektur; Entscheidungen mit „Offen“ brauchen die Zustimmung des Nutzers
---
# Technische Architektur

Rang 2 unter [[Leitbild]]. Beschreibt, **wie** die Anforderungen aus [[Visuelles Leitbild & Animation]], [[Fähigkeiten, VFX & Audio]] und [[Kampf & Begegnungen]] in GameMaker 2024 (Runtime 2024.14.4.268) umgesetzt werden. Die Systemkarte im Detail steht in `docs/Systeme/`.

## 1. Ist-Architektur (Audit 25.11.2026)

| Bereich | Ist | Bewertung |
|---|---|---|
| Hauptschleife | `ObjectController` Step: Bosswelt, Zauber, Passiva, Talente/Ausrüstung. `Draw_73` zeichnet Zauber, Bossgefahren, Beute nach dem Licht | tragfähig |
| Bossgefahren | `bv2_zone/line/sector/ring/bullet` mit Warn- und Aktivzeit, Trefferhöhe, **einer Uhr je Boss** (`v2_clock`); Choreografie `boss_choreo`; Darstellung `attack_telegraph` | **Kernstück einer Zeitachse**, nativ getestet. Erweitern statt ersetzen. |
| Spielerangriffe | Schwert: festes Zeitraster in `master_combat` (`timings=[0,4,16,22,34,42,56]` Frames), `ObjectSwordHitbox`. Stab/Bogen: Kombozähler in `class_weapons`, Projektile als Objekte (`ObjectLightningball`) | Zeitachsen existieren, aber je System anders |
| Zauber | `spell_v2`: Felder, Einschläge und Verbindungen als Structs; Darstellung als gestrecktes 4-Frame-Sprite (`spell_fx_draw`) plus Vektorformen | funktional, visuell der Hauptmangel |
| Partikel | `spell_vfx`: eigener Struct-Pool (Grenze 420), Sichtfeld-Culling, additive Vektorformen | Pool und Culling gut; Darstellung nicht auf dem Pixelraster |
| Licht | `atmosphere`: multiplikative Lichtfläche in halber Auflösung, Budget 72 Quellen | gut |
| Spieleranimation | Zustand → Sprite `spr_fg_<figur>_<aktion>_<richtung>`; Sprung, Fall, Slide und Ausweichen wählen Posen nach Fortschritt | einfach; keine Ereignisse, keine Übergänge, keine Sekundärbewegung |
| Ausrüstung | `equipment_visual`: Ebenen aus gepackten Atlanten, Rechtecktabelle je Zelle, ein Frame-Takt | Vorlage für weitere Ebenen (Haar, Umhang) |
| Gegneranimation | Sprite je Aktion und Richtung, Frame-Index nach Zeit | einfach |
| Bossanimation | Drache: Aktion → Sprite (2–4 Frames), Spiegeln, Atmen per Skalierung, Flug per Höhenversatz, **Maul-Anker** (`dragon_art_anchor`) | kein artikulierter Körper; Anker sind ein erster Ansatzpunkt |
| Audio | `audio_manager`/`fg_sfx`: 16 Stimmen, 2 je Cue, Musik-Überblendung | Grundlage für eine Ereignisschicht |
| Shader, Partikelsysteme, Sequenzen, Skelett-Animation | **nicht verwendet** | — |
| Rendering | Kamera 800×600, Viewport 1366×768, Fenster und App-Surface 1280×720, Texturfilter aus | **Fehler:** nicht-uniforme Skalierung (siehe R1); behoben am 25.11. (R1, R2 Variante B) |

**Gemessen (Testkopie, Minute 0, Wald):**
- 1.115 Instanzen, überwiegend Szenerie, dabei 23 Gegner.
- `fps_real` ≈ 380 ohne VSync-Grenze.
- Frühere Messung mit 150 Gegnern: 16,7 ms (VSync-gedeckelt, grob).

## 2. Architekturdefizite

| Nr. | Defizit | Art |
|---|---|---|
| A1 | Verzerrte, nicht-uniforme Skalierung (4:3-Kamera auf 16:9-Ausgabe) | fundamental, Rendering |
| A2 | Kein gemeinsames Pixelraster (Artpixel = 0,25–1,65 Welteinheiten; Vektoreffekte) | fundamental, Rendering/Assets |
| A3 | Keine gemeinsame Zeitachse für Animation, Gameplay, Effekt und Ton. Boss, Schwert und Klassenwaffen lösen das jeweils anders. | fehlendes System |
| A4 | Keine Animationsereignisse, keine Übergänge, keine Sekundärbewegung | fehlendes System |
| A5 | Große Bosse sind Einzelsprites, kein artikulierter Körper | fehlendes System |
| A6 | VFX ohne Profile oder Bänder; Größe = Radius-Streckung | bestehendes System verbessern |
| A7 | Audio ohne Ereignisschicht (Drosselung, Priorität, Varianten nur teilweise) | bestehendes System verbessern |
| A8 | Keine Qualitätsstufen (LOD) für Effekte *(Ist 25.11.: Einstellung Effektqualität Niedrig/Mittel/Hoch)* | bestehendes System verbessern |

## 3. Vergleich der Animationstechniken (GameMaker 2024)

Bewertung: ++ sehr gut, + gut, o mittel, − schwach, −− ungeeignet.

| Technik | Qualität | Machbarkeit GM 2024 | Leistung | Aufwand | Wiederverwendung | Eignung | Pixel-Treue | Einsatz in FirstGame |
|---|---|---|---|---|---|---|---|---|
| Frame-by-Frame | ++ (wenn gut gezeichnet) | ++ | ++ | −− (je Frame und Richtung) | − | kleine Gegner, Spielerposen | ++ | **ja**: Spieler-Grundposen, normale Gegner |
| Hierarchische Sprite-Teile (Parent-Child) | + | ++ (eigene GML-Struktur) | + | o | ++ | große Bosse, Waffen | o (Rotation bricht das Raster, siehe R3) | **ja**: Bosse, Waffen, Anhänge |
| Skelett-Animation mit Spine | ++ | + (Laufzeit eingebaut) | + | o | ++ | Bosse, Menschen | o | **nein**: Der Editor ist kostenpflichtig. Nutzerentscheidung 25.11.: immer kostenlose Werkzeuge |
| Eigenes Bone-System in GML | + | + | + | o bis − (einmalig) | ++ | Bosse | o | **ja (entschieden 25.11.)**: schlanker Cutout-Rig |
| Mesh-Verformung (Vertex-Buffer, `draw_sprite_pos`) | + | o | + | − | + | Flügelhäute, Stoff, Schleim | − | punktuell: Flügel, Umhang-Saum |
| Prozedurale Animation (Sinus, Federn) | + | ++ | ++ | ++ | ++ | Atmung, Wippen, Nachschwingen | + (auf ganze Pixel runden) | **ja, überall** als billige Lebendigkeit |
| Inverse Kinematik (2-Glied, analytisch) | + | ++ | ++ | o | + | Beine und Füße großer Bosse, Hals | o | **ja**: Drachenbeine, Hals mit Blick |
| Sprite-Layering | + | ++ (Ist bei Ausrüstung) | + | o | ++ | Spieler | ++ | **ja**: Erweiterung um Haar und Umhang als eigene Ebenen |
| Ankerpunkte | ++ (für Synchronität) | ++ (Ist: Maul-Anker) | ++ | + | ++ | Waffen, Projektile, Effekte, Hitboxen | ++ | **ja, Pflicht** für alle Angriffsquellen |
| Sekundäranimation (Federketten) | ++ | ++ | + | o | ++ | Haar, Umhang, Schweif, Flügel | o | **ja** |
| Animations-Blending | o | o | + | o | o | Pixel-Frames lassen sich nicht überblenden | −− (Überblendung verschmiert) | **nein** für Pixel-Frames; stattdessen **Übergangsposen**. Für Rig-Posen (Winkel) ja |
| Kontrollierte Rotation/Skalierung | o | ++ | ++ | ++ | + | Zieldrehung, Atmen, Squash | − ohne Raster-Rendering | nur nach R3 |
| Shader-Effekte | + | + (GLSL ES) | + | o | ++ | Trefferblitz, Kontur, Palette, Hitze, Auflösen | + | **ja**, gezielt (R4) |
| Vorgerenderte 3D-Animation als Pixel-Art | ++ (Bewegung) | o (Pipeline außerhalb, Blender kostenlos) | ++ | −− (Modelle nötig) | o | große Bosse | o (Stilbruch-Gefahr) | **Offen**, nur als Experiment; passt nicht zu den vorhandenen gezeichneten Assets |

### Empfehlung: Hybrid je Inhaltstyp

| Inhalt | Technik |
|---|---|
| Spielerfiguren | Gezeichnete Grundposen (Ist) **plus** Übergangsposen (Landung, Richtungswechsel, Ausholen) **plus** eigene Ebenen für Haar und Umhang mit Federversatz (1–2 Artpixel, auf ganze Pixel gerundet) **plus** prozedurale Neigung und Atmung. Kein Rig, damit die gezeichnete Qualität erhalten bleibt. |
| Normale Gegner | Frame-Animation (Ziel: Lauf 6–8 Frames je Richtung), dazu prozedurales Wippen, Lehnen und Treffer-Wackeln, Anker für Angriffe |
| Elite und Minibosse | Frame-Animation plus Anker plus ein bis zwei getrennte Teile (Waffe, Schild, Kopf) |
| Hauptbosse | **Cutout-Rig in GML**: Teile als Pixel-Sprites je Körperregion, Bone-Hierarchie, Schlüsselposen mit Easing, IK für Beine und Hals, Federketten für Schweif und Flügel. Gerendert nach R3. Hitboxen an Bones. |
| Waffen und Ausrüstung | Ebenen (Ist) plus Anker an der Hand, Verwischungsbilder als eigene Effekt-Sprites |
| Effekte | VFX-Bausteine (siehe 4.4) |

## 4. Zielarchitektur: gemeinsame Bausteine

Prüfregel: zuerst Bestehendes erweitern, nur bei echtem Defizit neu bauen. Kein vorsorgliches Neuschreiben.

### 4.1 Attack Timeline (A3), Erweiterung des bv2-Prinzips
- **Daten:** Eine Fähigkeit oder ein Angriff ist eine Zeitachse aus Ereignissen auf **einer Uhr des Besitzers** (Spieler, Gegner, Boss):
  ```
  {length:0.9, events:[
    {t:0.00, ev:"pose", clip:"tail_windup"},
    {t:0.00, ev:"telegraph", shape:"sector", radius:260, span:120, warn:0.6, height:"ground"},
    {t:0.05, ev:"sfx", cue:"dragon_tail_windup"},
    {t:0.60, ev:"hitbox_on", bone:"tail_tip", radius:34, height:"ground"},
    {t:0.60, ev:"vfx", profile:"dust_sweep", bone:"tail_tip"},
    {t:0.82, ev:"hitbox_off"},
    {t:0.82, ev:"pose", clip:"tail_recover"}]}
  ```
- **Verarbeitung:** Gameplay, Animation, VFX und Audio lesen dieselbe Zeitachse. Pause hält die Uhr an. Bei variabler Bildrate werden Ereignisse nach Zeit ausgelöst, nicht nach Frames.
- **Bestehendes übernehmen:**
  - `bv2_*` sind die Ereignisse `telegraph`, `hitbox_on` und `hitbox_off` für Bossflächen.
  - Das `master_combat`-Raster wird zur Schwert-Zeitachse.
  - Die `class_weapons`-Kombos werden zur Zeitachse je Kombostufe.
  - **Migration schrittweise; Verhalten und Werte bleiben gleich.** Die Telemetrie-Anker in `QA/tools/telemetry_injections.py` werden mitgezogen.
- **Ist (25.11.), Kern:** `scripts/attack_timeline`.
  - Schwertkette (`sword_chain`) und alle Kombostufen von Arkanistin und Waldläufer laufen als Zeitachse, mit unveränderten Werten.
  - Uhr bleibt die des Besitzers (`sword_combo_clock` bzw. Countdown `class_release`); Einheit sind Spielschritte, wie bisher.
  - Offen: VFX- und Ton-Ereignisse als eigene Ereignisarten, Boss-Angriffe (`bv2_*`, Drache) auf dieselben Definitionen, Auslösung nach Zeit statt Schritt.

### 4.2 Animation Controller (A4)
- **Aufgabe:**
  - Zustand → Clip (Frames bzw. Rig-Pose, Wiedergabe nach Zeit oder nach Fortschritt);
  - Übergänge mit Übergangsposen;
  - **Ereignisse** je Frame bzw. Zeitpunkt (Fußaufsatz, Kontaktframe, Freigabe);
  - Abbruchregeln (Eingabe bricht jede rein visuelle Phase ab).
- **Gemeinsam genutzt** von Spieler, Gegnern und Bossen. Er ersetzt die verstreute Auswahl in `ObjectPlayer/Step_0`, `master_skeleton` und `dragon_animation`, schrittweise.
- **Sekundärbewegung:** ein Federmodul (Feder-Dämpfer je Ebene bzw. Kettenglied), aus dem Bewegungsvektor gespeist. Ausgabe auf ganze Artpixel gerundet.

### 4.3 Rig-System für große Bosse (A5)

**Ist (25.11.), erste Stufe für den Drachen:**
- 2D-Skinning statt Teilen: Ein 24-px-Gitter über dem Original-Frame wird durch Knochen mit weichen Distanzgewichten verformt (FK, Eltern-Kind). Gezeichnet als texturierte Dreiecksstreifen.
- Vorteile: Keine Zerlegung, keine verdeckten Lücken, keine Nähte, kein neues Artwork.
- Grenzen:
  - Knochenlage je Pose gemessen (Flügel links und Schweif überall, Kopf/Hals/Flügel rechts nur Ruhepose).
  - Große Winkel verzerren Pixel; deshalb kleine Amplituden.
  - Hitboxen hängen noch nicht an Knochen.
- Schalter: `#macro DRAGON_RIG_ENABLED`.

Ausbaustufe (Soll):
- **Daten:**
  - Bones (Elternteil, Länge, Ruhewinkel), Teil-Sprites mit Drehpunkt;
  - Zeichenreihenfolge je Blickrichtung;
  - Schlüsselposen je Aktion, Easing.
- **Prozedural:**
  - Federketten für Schweif, Hals und Flügel;
  - 2-Glied-IK für die Beine mit Fußankern am Boden;
  - Blickrichtung des Kopfes.
- **Hitboxen und Hurtboxen** als Kapseln an Bones, auf der Uhr des Bosses aktiv. Debug-Anzeige über das vorhandene F10-Körperbox-Overlay.
- **Teile-Quelle:** Zerlegung der vorhandenen Drachen-Grafik in Regionen mit dem Werkzeugansatz aus `tests/tools/characters/` (Segmentierung). Fehlende verdeckte Bereiche werden ergänzt. **Die Originale bleiben unverändert.**

### 4.4 VFX-System (A6, A8): Erweiterung von `spell_vfx`
- **Emitter-Profile (Daten):** Element, Bausteine, Partikelzahl, Lebensdauer, Licht, Deckkraft, Ton-Variante; **je Band** (Basis, Mittel, Endgame) plus Talent-Zusatzmerkmale.
- **Partikel:**
  - Pixel-Sprites (1–4 Artpixel, kleiner Atlas) statt Vektorformen;
  - Position auf das Raster gelegt (Sprite- bzw. Feinraster nach R2);
  - Pool mit Budget (Ist: 420).
- **Ebenen:**
  - Bodenmale (unter Figuren);
  - Welt (mit Tiefe);
  - additives Licht (weiche Ebene);
  - Gegnergefahren darüber (Hierarchie).
- **Qualitätsstufen:**
  - Partikel-Multiplikator, Sekundärbewegung an/aus, Lichtauflösung;
  - *Ist 25.11.:* `vfx_quality()` (0 Niedrig, 1 Mittel, 2 Hoch = Standard) in `spell_vfx`. Partikelanteil 35/65/100 % über einen festen Zähler (kein Zufall), Pool 150/280/420, weiches Glühen erst ab Mittel, Sekundärbewegung (Haar, Umhang, Boss-Rigs) erst ab Mittel. Lichtauflösung noch nicht;
  - automatische Dämpfung eigener Effekte bei aktiven Bossgefahren (Vorschlag).

### 4.5 Telegraph-System (vorhanden: `attack_telegraph` + `bv2`)
- **Erweiterung:**
  - Regel für die Intensivierung zum Ende hin;
  - Ankündigungston-Ereignis;
  - Prioritätsebene;
  - Nutzung für Elite- und normale Gegner mit großen Flächen.
- Keine zweite, parallele Warnlogik (Auftrag 22.11.).
- **Soll seit 27.11.:** Die Darstellung wechselt von Markern zu den Vorzeichen der Attacke selbst ([[Kampf & Begegnungen]] 5.0, Leitbild G19). Uhr, Geometrie und Treffertest bleiben; die Vorzeichen lesen dieselbe Uhr und dasselbe Geometrie-Struct.

### 4.6 Projektile
- **Ist:** Spielerprojektile als Objekte, Bossprojektile als Structs (`bv2_bullet`).
- **Vorschlag:** Spielerprojektile langfristig ebenfalls als Struct-Pool. Das bringt Leistung bei Ranger-Salven und gleiche Trefferlogik.
- Erst messen, dann umbauen.

### 4.7 Audio-Ereignisse (A7): Schicht über `fg_sfx`
`audio_event(id, x, y, band)` mit:
- Mindestabstand je Cue;
- Priorität;
- Zufallsvariante, Tonhöhenstreuung;
- Band-Varianten;
- Bündelung gleichzeitiger gleicher Ereignisse;
- Absenken der Musik bei Bossankündigungen.

### 4.8 Bossmechanik-Sequenzen
Vorhanden (`boss_choreo`). Künftig als Folge von Zeitachsen (4.1), damit Körper (4.3), Warnungen (4.5), Effekte (4.4) und Ton (4.7) automatisch synchron sind.

## 5. Rendering-Entscheidungen

### R1: Verzerrung beheben (Priorität 1)
- **Ist:**
  - Kamera 800×600 auf 1280×720 ergibt x×1,6, y×1,2.
  - Kamera und Folgelogik nutzen feste Zahlen (`x-400`, `y-300`, `800`, `600` in `ObjectPlayer`).
- **Optionen:**

  | Option | Sichtbarer Weltausschnitt | Skalierung 720p / 1080p | Folgen |
  |---|---|---|---|
  | a) 1067×600 | +33 % Breite, gleiche Höhe | 1,2 / 1,8 | mehr Horizont, Spawnabstände ändern sich |
  | **b) 960×540 (Vorschlag)** | Fläche ≈ heute (518k statt 480k): +20 % Breite, −10 % Höhe | 1,333 / **2,0** (ganzzahlig bei 1080p) | geringe Gameplay-Änderung; Raster bei 1080p perfekt |
  | c) 1280×720 | fast doppelte Fläche | 1,0 / 1,5 | starke Gameplay-Änderung |

- **Umsetzung:**
  - Kamerafläche aus einer Konstante, Folgelogik relativ zur Kameragröße;
  - Viewports aller Räume auf 16:9;
  - Prüfung aller Stellen, die die Sichtgröße nutzen (`survivor_balance` Spawnring, Boss-Notfallteleport außerhalb des Bildes, Minimap, Boss-Testmodus).
  - Tests: `level`, `boss`, `regression`, `visual`.
- **Entschieden und umgesetzt (25.11.):** Option b, 960×540.
  - `#macro VIEW_W/VIEW_H` in `scripts/gameplay`; Kamera und Folgelogik in `ObjectPlayer` nutzen die Konstanten.
  - Spiel-Räume haben 16:9-Viewports (1280×720).

### R2: Einheitliche Pixeldichte (Vorschlag, Entscheidung nach A/B-Prototyp)
- **Zielregel:** **1 Artpixel = 1 Welteinheit für alle Sprites**, so wie die Umgebung heute schon gezeichnet ist.
- **Machbarkeit:** Die Quellatlanten der Spielerfiguren haben bereits etwa 157 px je Zelle (1254/8). Das entspricht fast der heutigen Bildschirmgröße (96 × 1,65 ≈ 158).
  - Neu importiert mit Faktor 1,0 auf eine 160er-Leinwand werden sie **detailreicher und rastertreu**, ohne die Figur zu ändern.
  - Für Gegner und Bosse gilt dasselbe aus deren Quellen (Bosse: Export in Zielgröße statt 512er-Sprites mit Faktor 0,25–0,8).
- **Feinraster:**
  - **Variante A:** App-Surface in Ausgabeauflösung. Partikel dürfen auf halbe Welteinheiten (= 1 Bildschirmpixel bei 1080p).
  - **Variante B:** Welt in eine 960×540-Fläche rendern, ganzzahlig bzw. „sharp-bilinear“ hochskalieren, Effekte und Licht in Ausgabeauflösung darüber. Diese Variante ist rastertreuer bei 720p, kostet aber mehr Umbau.
  - **Entschieden und umgesetzt (25.11., Generalfreigabe des Nutzers): Variante B, abgewandelt.**
    - Befund vorher: Die 960×540-Welt wurde auf 1280×720 ausgegeben (Faktor 1,333), jede dritte Pixelspalte doppelt breit; beim Bewegen flimmerte es.
    - Welt, Effekte und Partikel liegen alle im Weltraster (App-Surface 960×540). Effekte in Ausgabeauflösung hätten wieder zwei Pixelgrößen gemischt; nur das Licht bleibt weich (eigene halbe Auflösung, gefiltert).
    - Ausgabe in `scripts/render_pipeline` über das persistente `ObjectRender` (Post-Draw): ganzzahlig mit Nearest, sonst sharp-bilinear (Nearest auf das nächste ganze Vielfache, dann ein bilinearer Schritt), zentriert mit schwarzem Rand.
    - Fenster: größtes ganzes Vielfaches, das auf den Desktop passt; auf 1080p-Desktops 1280×720 (sharp-bilinear), Vollbild dort exakt 2×. Vollbild wird in `firstgame_settings.ini` gespeichert.
    - GUI bleibt 1280×720 (scharfe Schrift). Kamera auf ganzen Weltpixeln (`round`), damit Ebenen nicht gegeneinander zittern.
    - Folge für Grafik: Was im Spiel skaliert oder gedreht wird, rastet auf das Weltraster. Bosse und Effekte werden deshalb in Zielgröße gebacken bzw. als Drehstufen vorberechnet (RotSprite, `tests/tools/art/pixelize.py`).
- **A/B-Vergleich (25.11., aus dem Schwertmeister-Quellatlas):**
  - Heute: 52-px-Figur ×1,65; bei 1080p sind die Pixel 3,3 px breit und 1,65-mal gröber als der Boden.
  - Mit Dichte 1,0: 86-px-Figur aus derselben Quelle, Pixel so groß wie der Boden, mehr Detail.
  - **Empfehlung: Dichte 1,0. Nutzerentscheidung 25.11.: umstellen. Umgesetzt am 25.11.** für Spielerfiguren und Ausrüstung:
    - Frames 160×160, Ursprung (80,145), `player_scale` 1,0.
    - Frame-Spezifikation in `tests/tools/characters/atlas.py` (`DENSITY`, `FRAME`, `OX`, `OY`); die Laufzeit liest sie aus den generierten Daten (`eqv_frame()`).
    - Gegner und Bosse folgen in eigenen Schritten (andere Quellen).
  - Umgesetzte Schritte:
    - Leinwand 96 → 160 px, Ursprung (48,88) → (80,147);
    - `atlas.py`/`render.py`/`build_characters.py` und alle Ausrüstungs-Atlanten neu bauen;
    - `eqv_piece_draw`-Konstanten und `player_scale` 1,65 → 1,0 anpassen;
    - Suite `visual` anpassen.
  - Hitboxen bleiben in Welteinheiten unverändert.

### R3: Rotation von Pixel-Art (Rig, Waffen)
Teile großer Rigs werden:
- (a) als vorgedrehte Varianten erzeugt (Pipeline, RotSprite-artig, 16–32 Schritte); oder
- (b) in ein eigenes Render-Ziel in Artpixel-Auflösung gezeichnet und als Ganzes auf das Raster gebracht.

**Vorschlag:** (b) für Bosse, weil einmal eine Fläche je Boss genügt; (a) für Waffen-Verwischungsbilder.

### R4: Shader (gezielt)
Trefferblitz (statt Farbmultiplikation), Kontur bzw. Randlicht zur Lesbarkeit des Spielers, Paletten- und Elementtausch, Auflösen beim Tod, Hitzeflimmern beim Feueratem, Windbewegung der Vegetation.

Alles optional und einzeln abschaltbar (Qualitätsstufen).

**Ist seit 26.11. abends (Grafik-Overhaul):** Nachbearbeitung der Weltebene in `scripts/render_fx` mit drei Shadern:
- `sh_fx_bright`: Helligkeitsauszug, viertel Auflösung, 4 Abtastungen je Bildpunkt; kein einzelnes helles Pixel geht verloren.
- `sh_fx_blur`: trennbarer Weichzeichner.
- `sh_fx_composite`: Hitzeflimmern, Druckwellen, Farbversatz, Tiefenunschärfe, Glühen, Farbgebung, Vignette.

Ablauf in `ObjectController` Draw End:
1. Weltebene zeichnen.
2. `fx_post_world()` kopiert die Weltfläche, bearbeitet sie und schreibt sie zurück.
3. Danach folgt die Lesbarkeitsebene (Warnungen, Gefahren), unbearbeitet.

Rückfall: Sind die Shader nicht kompiliert, entfällt die Nachbearbeitung.

## 6. Leistungsbudgets (Vorschlag, gemessen und angepasst im Vertical Slice)

| Budget | Ist | Ziel |
|---|---|---|
| Bildzeit bei 150 Gegnern und Bosskampf | 16,7 ms (VSync) | ≤ 12 ms CPU+GPU ohne VSync auf dem Entwicklungsrechner |
| Partikel gleichzeitig | 420 (Grenze); seit 26.11. abends zusätzlich `fx_particles` 420 / 1.000 / 1.800 (Niedrig / Mittel / Hoch) | Messung in der perf-Suite |
| Lichtquellen | 72 | unverändert |
| Stimmen | 16 (2 je Cue) | unverändert plus Ereignisschicht |
| Gegner (technische Grenze) | 180 | unverändert |
| Rig-Teile je Boss | — | ≤ 40 Teile, eine Render-Fläche |
| Draw-Aufrufe | nicht gemessen | Messung im Vertical Slice; Ausrüstung und Effekte in eigenen Texturgruppen |

- **Culling:** Effekte außerhalb des Bildes werden nicht gezeichnet. Ist: Partikel ja.
- **Pooling** über Structs statt Instanzen für Massenobjekte.

## 7. Verträglichkeit mit GameMaker 2024
Alle oben genannten Mittel stehen in GM 2024.14 unter Windows zur Verfügung:
- Surfaces, Shader (GLSL ES), Vertex-Buffer, `draw_sprite_pos`, Texturgruppen;
- Spine-Laufzeit, Partikelsysteme, Sequenzen.

**Einschränkungen:**
- Spine braucht einen kostenpflichtigen Editor (Freigabe nötig).
- Neue Ressourcen müssen in `FirstGame.yyp` registriert werden (`tests/tools/levels/gm_project.py`).
- Generierte Daten (`equipment_visual_data`, `level_layout_*`, `spell_v2_catalog`) werden nur über ihre Werkzeuge erzeugt.
