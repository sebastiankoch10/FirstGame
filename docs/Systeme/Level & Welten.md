---
tags: [system, level]
updated: 2026-11-26
---
# Level & Welten

## Zweck
Drei Welten: Wald (`Room1`, handgebauter Master-Wald), Verfluchter Sumpf, Aschenfrost-Ruinen (je 4096², prozedural vorberechnet).

## Wichtige Dateien
- `scripts/level_worlds`: Leveldefinitionen (Schwierigkeit, Wetter, Musik, Boss-Gewichte), Gegnerpools, Levelauswahl mit Vorschau.
  - Levelindex: 0 = Wald (`Room1`, eigener Renderer `master_world`), 1 = `RoomSwamp`, 2 = `RoomAshfrost`.
  - Gegnerarten tragen `scale` und optional `baked` (in Zielgröße gerenderte Grafik); `monster_art_div()` rechnet beim Zeichnen um, siehe [[Gegner & Spawns]].
- `scripts/level_world`: Laufzeit (Bodenchunks, Requisiten, Kollisionsraster, Umweltgefahren, Lichter, Minimap).
- `scripts/level_layout_swamp` und `scripts/level_layout_ashfrost`: generierte Daten, **nicht von Hand ändern**. Erzeugt mit `tests/tools/levels/build_level.py`.
- `scripts/master_world`: der Wald. Objekte: `ObjectMasterWorld`, `ObjectMasterScenery`, `ObjectEnvironmentDecoration`, `ObjectLevelWorld`, `ObjectLevelProp`.
- Räume: `Room1`, `RoomSwamp`, `RoomAshfrost`; Fallbacks `RoomCrypt` und `RoomRuins`.
- Doku: `LEVEL_EXPANSION_PROGRESS.md`. Test: `tests/level_harness.gml`.

## Abhängigkeiten
[[Gegner & Spawns]] · [[Licht, Wetter & Effekte]] · [[Audio]] · [[Spieler & Bewegung]] · [[Rendering & Pixelraster]]

## Bekannte Probleme
- Die Layoutdaten sind generiert: Änderungen nur über `build_level.py`, sonst gehen sie beim nächsten Erzeugen verloren.
- `RoomCrypt` und `RoomRuins` sind Fallbacks aus der Codex-Zeit; ob sie noch gebraucht werden, ist offen ([[Bugs & Ideen]]).
