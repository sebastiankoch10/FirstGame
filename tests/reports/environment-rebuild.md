# FirstGame Environment Rebuild

Stand: 2026-11-22

## Ergebnis

- PASS: Windows-VM-Kommandobuild.
- PASS: GameMaker-Projektprüfung.
- PASS: Neues Spiel -> Charakterauswahl -> Levelauswahl -> Room1.
- PASS: Live-Screenshot aus Room1 zeigt den neuen ArtPack-Untergrund.
- PASS: Der Startbereich enthält sichtbare ArtPack-Bäume und bleibt in der Gameplay-Sicht.
- NOT RUN: Vollständige neunfache Kombination; die Weltanpassung wurde auf das gemeinsame Room1-System angewendet.

## Neue Landschaft

- Noise-basierte Grasvarianten.
- Winding-Erdweg durch die Mitte des Raums.
- Getrennte Sand- und Wasser-/Uferzonen.
- Clusterlogik für Baum-, Busch-, Blumen-, Stein-, Baumstumpf- und Ruinenfelder.
- Freier Spieler-/Kampfbereich nahe der Raummitte.
- Seed `20261122` macht die Platzierung reproduzierbar.

Die 4096×4096-Karte bleibt mit dem 128×128-ArtPack-Ground vollständig gefüllt.

## ArtPack-Ressourcen

Die neuen Ressourcen liegen ausschließlich unter `FirstGame_ArtPack/environment`:

- `spr_fg_environment_tiles.png`: 256x256 Tilesheet, 32x32 Raster, 64 Bodenvarianten.
- `spr_fg_environment_decorations.png`: Baum, Busch, Blume, Stein, Baumstumpf und Ruine.

Diese Dateien wurden als GameMaker-Ressourcen registriert:

- `spr_fg_environment_tiles`
- `spr_fg_environment_decorations`
- `ObjectEnvironmentDecoration`

Das aktive `Grass`-Tileset verweist jetzt auf `spr_fg_environment_tiles`, nicht mehr auf `TX_Tileset_Grass`.

## Raumgestaltung

- Room1 verwendet einen gebackenen, deterministischen `ArtPack_Ground`-Tile-Layer.
- Die Raumfläche bleibt 4096x4096.
- Der Untergrund deckt die gesamte 128x128-Tilefläche ab.
- 60 editierbare Environment-Instanzen wurden in den Room Editor gebacken.
- Der Startbereich um den Spieler bleibt frei von blockierenden Dekorationen.
- Reproduzierbarer Seed: `20261122`.

Der Baker liegt unter `tests/tools/bake_environment.py`.

## Kollisionsstatus

- Baum-, Stein- und Ruinen-Frames sind für blockierende Umgebung vorgesehen.
- Dekorative Bush-/Flower-/Stumpf-Funktion ist nicht als blockierend markiert.
- Die vollständige Kollisionsprüfung durch Projektil- und Spielerbewegung wurde noch nicht ausgeführt.

## Cleanup

- Entfernt aus der `.yyp`-Registry: `TX_Plant`, `TX_Player`, `TX_Props`, `TX_Shadow_Plant`, `TX_Shadow`, `TX_Struct`, `TX_Tileset_Grass`, `TX_Tileset_Stone_Ground`, `TX_Tileset_Wall`, `Plant`, `Tree`.
- Entfernt von der Festplatte: die entsprechenden Sprite-/Tileset-Ordner und `Assets/Texture`.
- Keine aktiven `TX_*`-, `Plant`- oder `Tree`-Referenzen gefunden.
- Aktive Umweltressourcen sind ausschließlich `spr_fg_environment_tiles`, `spr_fg_environment_decorations` und `ObjectEnvironmentDecoration`.

## Screenshots

- Live-Screenshot aus Room1 wurde während des direkten Windows-VM-Laufs betrachtet.
- Es wurde kein dauerhafter PNG-Screenshotpfad erzeugt, weil die verfügbare UI-Capture nur die Live-Ansicht zurückgab.
