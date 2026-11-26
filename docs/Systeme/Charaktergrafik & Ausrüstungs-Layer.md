---
tags: [system, grafik, ausruestung, charaktere]
updated: 2026-11-26
---
# Charaktergrafik & Ausrüstungs-Layer

## Zweck
Jede Klasse besteht aus einem **Basismodell** in einfacher Grundkleidung ohne Waffe sowie **sichtbaren Ausrüstungsteilen**:
- **Ebenen:** Kopf, Brust, Hände, Füße und Waffe, jeweils in 4 Stufen.
- **Startwaffe:** eine eigene Ebene, solange keine Waffe angelegt ist.

Alle Ebenen nutzen pro Frame exakt dieselben Pixel wie der Körper. Es gibt nur einen Animationstakt.

## Wichtige Dateien
- **Laufzeit:** `scripts/equipment_visual`
  - `player_layers_draw(actor, sprite, frame, x, y, xs, ys, col, alpha, equip?)` zeichnet Basis und Teile.
  - `eqv_pieces_for(equip)` liefert die sichtbaren Teile.
  - `eqv_cell` bildet einen Sprite-Frame auf die gemeinsame Zelle ab.
  - Reihenfolge: Füße → Brust → Hände → Kopf → Waffe. Akzente (Borten, Parierstange, Edelsteine) werden in der Seltenheitsfarbe eingefärbt.
- **Generierte Daten:** `scripts/equipment_visual_data`, nicht von Hand ändern. Enthält seit 25.11. auch `frame` (Größe und Ursprung) und `bones` (10 Byte je Zelle: Haar- und Umhang-Knochen für die Sekundärbewegung).
  - Enthält Frame → Zelle und je Teil eine Rechtecktabelle (base64, 8 Byte pro Zelle).
- **Atlanten:**
  - `sprites/spr_eqv_<actor>_<teil>[ _acc]`: 41 pro Klasse, Texturgruppe `Equipment`.
  - Icons: `spr_eqv_icons_<actor>` mit 20 Frames, Frame = Slot·4 + Stufe.
- **Basismodelle:** die bestehenden `spr_fg_<actor>_<aktion>_<richtung>`, Frames an Ort und Stelle ersetzt. Die Originale liegen unverändert in `FirstGame_ArtPack/characters/swordsman_v3/frames` und `class_overhaul/frames`.
- **Pipeline:** `tests/tools/characters/`
  - `atlas.py`: exakter Port des Atlas-Imports.
  - `segment.py`: Zerlegung in hoher Auflösung.
  - `render.py`: Materialien, Muster, Helme, Waffen.
  - `build_characters.py`: alles erzeugen und registrieren.
  - Vorschauen: `FirstGame_ArtPack/characters/character_layers/preview_<actor>.png`.
- **Zeichenstellen:** `objects/ObjectPlayer/Draw_0` (Spielfigur), `objects/ObjectMainMenu/Draw_64` (Porträt).
- **Item-Icons:** `equipment_item_icon` in `scripts/equipment`, genutzt im Inventar, im HUD und bei Bodenfunden.
- **Test:** `tests/visual_harness.gml` über `run_native_harness.py visual`, Suite `visual` in `tests/tools/qa.py`.

## Wie die Grafik entsteht (Kurzfassung)
1. Die Originalfiguren stammen aus 1254×1254-Atlanten (8 Richtungen × 8 Posen, 256 Posen je Klasse). `atlas.py` bildet den Import nach: Schnitt, Alphaschwelle, größte Komponente, GDI+-Nearest-Neighbor. Seit 25.11.2026 entstehen die Frames mit 160×160 und Ursprung (80, 145), gezeichnet 1:1 (Pixeldichte wie die Welt; vorher 96×96, Ursprung (48,88), Skalierung 1,65). Neu bauen: `FG_SEG_VER=<segment_code> python tests/tools/characters/build_characters.py --previews` nutzt den Zerlegungs-Cache.
2. **Zerlegung in Atlas-Auflösung** (`segment.py`):
   - Saum entfernen (warme Mattkante).
   - Waffe finden: Klinge bzw. Stab per RANSAC als gerade, frei herausragende Linie; Bogen als frei liegende Holzkurve.
   - Kopf (Haar und Gesicht), Umhang, Schal und Hemd bleiben erhalten.
   - Den Rest teilen Zonen entlang der Körperachse auf: Brust, Hände, Beine, Füße. Liegende Posen werden über die Achse erkannt.
3. **Malen in Frame-Auflösung** (`render.py`):
   - Die Formschattierung des Originals wird beibehalten, normiert je Ursprungsmaterial und median-geglättet.
   - Darauf kommt die Materialrampe der Stufe, plus Muster in Endpixelgröße: Ketten, Schuppen, Nieten, Runenband.
   - Helme sind Kuppeln über dem Haar bis zur Brauenlinie, mit Kugelschattierung von oben links.
   - **Seit 25.11. Kopf und Helm als ein Stück** (`helmet_composite` in `build_characters.py`): Das Kopfteil enthält die Zeilen des Basismodells bis zur Braue ohne Haar, darüber den Helm. Zur Laufzeit lässt `player_layers_draw` diese Zeilen im Basismodell weg (`eqv_hcut`, `eqv_draw_base_cut`; im Rig `rig_draw_frame(..., _cut)`), deshalb stehen keine Haare mehr um den Helm heraus.
   - **Kantenreinigung** (`clean_fringe` in `render.py`): heller, ungesättigter Saum am Umriss (Reste des alten Ausschnitts) bekommt den dunklen Konturton des Nachbarn; Haar ausgenommen. Beim Schwertmeister entfernt `clean_matte` zusätzlich graue Hintergrundreste (zwischen den Beinen, an den Stiefeln). Bei Arkanistin und Waldläufer nicht, weil dort echte weiße bzw. graue Kleidung mit erfasst würde.

## Stufen (Item-Stufe = Gegenstandsstufe 1–4 / 5–8 / 9–12 / 13+)

| Slot | Stufe 0 | 1 | 2 | 3 |
|---|---|---|---|---|
| Kopf | Lederkappe | Eisenhelm | Runenhelm | Schuppenhelm mit Kamm und Hörnern |
| Brust | Lederwams | Kettenhemd | Plattenpanzer | Schuppenpanzer |
| Hände | Leder | Eisen | Runen | Klauen |
| Füße | Leder | Wanderstiefel mit Eisenkappe | Runen | Schattentreter |
| Schwert | Kurzschwert | Langschwert | Runenklinge | Drachenzahn |
| Stab | Eichenstab | Kristallstab | Sternenzepter | Leerenfokus |
| Bogen | Jagdbogen | Kompositbogen | Mondbogen | Sturmbogen |

- **Seltenheit:** färbt die Akzente: gewöhnlich Bronze, magisch Blau, selten Gold, episch Violett.
- **Talisman:** nicht sichtbar am Körper.
- **Umhänge:** kein Ausrüstungsslot. Der rote Umhang (Schwertkämpfer) und der grüne Umhang (Waldläufer) bleiben Teil der Klassenidentität im Basismodell.

- **Ankerpunkte seit 26.11.:**
  - `tests/tools/characters/build_attach_points.py` erzeugt `scripts/equipment_attach_data`: je Klasse und Zelle Griffpunkt, Winkel, Länge und Konfidenz, aus Startwaffen- und Handebene.
  - `eqv_attach(actor, spr, frame, x, y, xs, ys)` liefert den Griff in Weltkoordinaten (gespiegelt mit der Blickrichtung).
  - Noch von keiner Zeichenstelle genutzt; vorbereitet für weitere Waffentypen, Nebenhand und Schilde.
  - Prüfung in der Suite `visual`.
- **Sprungreaktion seit 26.11.:** In `player_motion_life` (`scripts/player_artpack`) schwingen Haar und Umhang beim Absprung zurück, hängen beim Steigen nach und heben sich beim Fallen.

- **`eqv_attach_draw` (seit 26.11.):** zeichnet ein beliebiges Gegenstands-Sprite (nach rechts zeigend, Ursprung am Griff) an der Hand des aktuellen Bildes, mit Winkel und Spiegelung; liefert false bei verdeckter Hand. Kontrollanzeige im Testmodus mit F10. Die Waffenebenen der Startwaffen und Waffen-Items bleiben pixelgenaue Ebenen; die Ankerpunkte sind für zusätzliche Modelle (weitere Waffentypen, Nebenhand, Schild) gedacht.

## Abhängigkeiten
[[Ausrüstung]] (Slots, Gegenstandsstufe, Seltenheit) · [[Spieler & Bewegung]] (Animationszustände, ein Frame-Takt) · [[Klassen & Startwaffen]] (Startwaffe als Ebene) · [[UI, HUD & Menüs]] (Porträt, Icons) · [[Tests & QA]] (Suite `visual`)

## Bekannte Probleme / Grenzen
- **Prozedurale Grafik:** Die Ausrüstung ist aus den vorhandenen Figuren abgeleitet (Material, Muster, Silhouettenzusätze), nicht von Hand gezeichnet. Formen folgen den Originalrüstungen. Eine künstlerische Feinabnahme bleibt sinnvoll.
- **Waffenerkennung ist nicht in jedem Frame vollständig:** Schwert 223/256, Stab 212/256, Bogen 230/256 Zellen (`tests/reports/character-layers.json`).
  - Wo die Waffe nicht erkannt wurde, zeigt der Frame auch mit Item-Waffe die Originalwaffe. Nicht erkannte Klingenreste bleiben original statt umgefärbt.
  - Meist betroffen: verdeckte Waffen in Rückansichten, Todesposen und senkrecht nach unten gehaltene Klingen.
- **Basis der Magierin:** Originalrobe ohne Goldornamente. Schwertkämpfer und Waldläufer bekommen dagegen neue Grundkleidung (Waffenrock bzw. Leinenhemd).
- **Kollisionsmaske:** `combat_mask()` (`scripts/gameplay`) dupliziert ein Schwertmeister-Sprite. Die Box wird seit 25.11. aus dessen Ursprung berechnet; vorher feste 96er-Koordinaten, die bei der Umstellung auf 160 px die Projektiltreffer verschoben hätten (von der Suite `classes` gefunden).
- **Startwaffe:** Basis plus Startwaffe ergibt das Original. Ausnahmen sind der entfernte Saum und einzelne Umrisspixel der Waffe.
