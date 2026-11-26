# Neue Grafikressourcen: Krieger, Bosse und Magnet

Erzeugt am 22.11.2026 mit dem eingebauten Imagegen-Werkzeug, ohne externe API-Aufrufe oder heruntergeladene Spielgrafiken. Die Quellen sind echte RGBA-PNGs mit transparentem Hintergrund. Ihre RGB-Kanäle enthalten teilweise Hintergrundfarben in vollständig transparenten Pixeln; diese Farben werden im Spiel nicht gerendert.

## Verwendete Dateien

- `sources/knight-sheet.png`: neues, zusammenhängendes Kriegerdesign, drei Blickrichtungen mit je acht Posen. Rotbraunes Haar, türkisfarbene Tunika, goldene Schulterteile und Stahlschwert. Links wird die neue Rechtsansicht gespiegelt.
- `sources/knight-death-sheet.png`: sechs zusätzliche Kollaps-/Todesposen desselben Designs.
- `sources/boss-sheet.png`: neuer Waldgolem und neuer Sturmdrache, jeweils drei Posen auf einem größeren Quellraster.
- `sources/magnet-orb.png`: neue, vom freigegebenen arkanen ArtPack-Icon abgeleitete Grafik; türkise Kugel mit eindeutigem Hufeisenmagneten.
- `frames/`: reproduzierbar ausgeschnittene Importbilder. Krieger 64 × 64 mit Ursprung (32,58); Bosse 384 × 384 mit Ursprung (192,360); Magnet 40 × 40 mit Ursprung (20,20).
- `prompts.json`: verwendete Generierungs- und Bearbeitungsanweisungen.

Import: zuerst `tests/tools/prepare_atmosphere_art.ps1`, anschließend `python tests/tools/import_atmosphere_art.py`. Das erste Skript schneidet Raster aus und skaliert mit Nearest Neighbor; das zweite erstellt GameMaker-Ressourcen und registriert sie im Projekt. Beide verwenden ausschließlich lokale Werkzeuge. Die alten Kriegergrafiken werden nicht als visueller Fallback verwendet.

## Animationsumfang und Grenzen

Idle ist eine stehende Pose. Laufen/Rennen verwenden zwei neue Schrittposen, Angriff zwei Schwertposen, Tod zwei eigene Posen. Sprung/Fall teilen eine neue Luftpose; Dive/Slide/Dodge teilen eine neue niedrige Pose, deren Bewegung aus der tatsächlichen Spiellogik stammt. Treffer hat eine eigene Pose. Alle Ansichten verwenden dieselbe Skalierung; die frühere richtungsabhängige Größenkorrektur entfällt.

Das ist ein neues konsistentes Modell mit kurzen Animationsfolgen, kein vollständig von Hand animierter Produktionssatz. Weitere Idle-/Sprung-/Ausweich-Zwischenbilder und längere Lauf-/Angriffsfolgen bleiben eine Qualitätsverbesserung. Die beiden neuen Bossmodelle besitzen jeweils drei Posen; spätere Echo-Bosse verwenden diese Modelle erneut und sind weiterhin keine acht individuell ausgearbeiteten Bossdesigns.
