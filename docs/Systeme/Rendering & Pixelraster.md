---
tags: [system, darstellung]
updated: 2026-11-26
---
# Rendering & Pixelraster

## Zweck
Jedes Grafikpixel erscheint gleich groß: Die Welt wird in eine 960×540-Fläche gezeichnet und danach als Ganzes ins Fenster skaliert. Entscheidung: [[Technische Architektur]] R2, Variante B.

## Wichtige Dateien
- `scripts/render_pipeline`:
  - `render_init`: App-Surface von Hand ausgeben, GUI 1280×720, Fenstergröße bzw. gespeichertes Vollbild.
  - `render_room_start`: Viewport 0 und App-Surface auf `VIEW_W`×`VIEW_H` in jedem Raum.
  - `render_present` (Post-Draw): ganzzahlig mit Nearest, sonst sharp-bilinear über eine Zwischenfläche; Letterbox.
  - `render_window_default`, `render_set_fullscreen` (speichert `[Grafik] vollbild` in `firstgame_settings.ini`).
  - `global.render_info`: Skalierung, Modus und Zielrechteck der letzten Ausgabe.
- Objekt `ObjectRender` (persistent): Create, Raumstart, Post-Draw. Das Hauptmenü legt es an.
- `objects/ObjectPlayer/Step_0.gml`: Kamera auf ganzen Weltpixeln.
- **Seit 26.11. abends** `scripts/render_fx` mit den Shadern `sh_fx_bright`, `sh_fx_blur` und `sh_fx_composite`. Details: [[Technische Architektur]] R4.
  - `fx_post_world()` läuft in `ObjectController` Draw End zwischen der Weltebene und der Lesbarkeitsebene.
  - Er bearbeitet nur die Weltebene: Glühen, Hitzeflimmern (`fx_heat_line`), Druckwellen (`fx_shock`), Farbversatz (`fx_aberration`), Tiefenunschärfe am oberen und unteren Rand, Farbgebung je Level (`fx_level_profile`), Farbumschlag (`fx_scene_tint`) und Vignette.
  - Schutzmaske `keep` (halbe Auflösung): Gegner und Bosse werden nicht unscharf und kaum abgedunkelt.
  - Qualität über `fx_quality_flags` (ab 110 Gegnern ohne Tiefenunschärfe und weites Glühen), Lichtblitze über `fx_flash_k`; Messwert `global.fx.metrics`.

## Abhängigkeiten
[[Licht, Wetter & Effekte]] (Lichtfläche bleibt eigene, gefilterte Fläche) · [[UI, HUD & Menüs]] (GUI-Raum 1280×720) · [[Speichern & Einstellungen]] · [[Tests & QA]] (Aufnahmen sind 960×540)

## Bekannte Probleme
- Ohne kompilierte Shader entfällt die Nachbearbeitung (Meldung `FX_POST disabled`). Auf Rechnern ohne Shader-Unterstützung sieht das Spiel dann wie vor dem Overhaul aus, nur mit verstärkbarem Licht.
- Vektorprimitive (Linien, Kreise) liegen jetzt ebenfalls im Weltraster, also gröber als vorher. Für Effekte ist das gewollt; dünne Warnlinien prüfen.
- Schrift im Weltraum (Schadenszahlen, „MAGNET“) ist die Standardschrift im Weltraster und wirkt blockig. Besser: Pixel-Schrift oder Zahlen auf der GUI-Ebene.
