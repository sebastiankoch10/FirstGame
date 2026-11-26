# Master-Style: Waldruinen, Skelette und Schwertkombo

Die fünf Original-PNGs in `sources/` wurden mit dem eingebauten Imagegen-Werkzeug für diesen Auftrag neu erzeugt. Vollständige Anweisungen: `prompts.json`. Keine heruntergeladenen Spielgrafiken und keine zusätzliche externe API.

- `ground.png`: neuer, durchgehender Waldruinenboden mit Erde, Moos, gebrochenen Platten und Herbstlaub.
- `scenery.png`: 16 neue Umgebungsobjekte: vier Bäume, vier Pflanzen, vier Ruinenelemente/Feuerschale, vier Boden-/Steindetails.
- `skeleton-motion.png`: acht Richtungen mit Idle, Laufen und Angriff.
- `skeleton-reaction.png`: dieselben Richtungen mit Treffer und fünf Todesbildern.
- `slash.png`: drei Schwertbögen mit jeweils vier Effektbildern.

Reproduzierbarer Import:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/tools/prepare_master_world.ps1
python tests/tools/rebuild_master_world.py
```

Der erste Schritt schneidet an den tatsächlichen transparenten Zeilentrennern, entfernt Alpha-Rauschen und isolierte Fragmente und skaliert mit Nearest Neighbor. Die Originalquellen bleiben unverändert. Der zweite registriert 60 neue Grafikressourcen mit 157 Bildern, die drei neuen Objekte und drei neuen Skriptmodule; anschließend baut er Room1 vollständig neu auf.

`manifest.json` enthält Ressourcennamen, Bilderzahlen und Ursprünge. `layout.json` enthält sämtliche 1.146 platzierten neuen Requisiten. Die Platzierungsregeln und Seed 42187 stehen im Importskript: gewundene Wege, fünf Ruinenplätze und Vegetationsgruppen an deren Rändern. `previous-active-assets.json` bewahrt den Umfang des zuvor entfernten aktiven Mischbestands.

Eine gemeinsame Bodentextur wird abwechselnd gespiegelt, sodass an den Kachelgrenzen dieselben Randpixel aneinanderliegen. Es gibt in Room1 keine alten Grass-Tile-Layer und keine alten Landschaftsinstanzen mehr. Die alten Ressourcen bleiben für die anderen vorhandenen Räume erhalten und dienen nicht als Fallback für die neue Welt.

Die Grafiken sind erzeugte Rasterkunst und kein manuell nachgezeichneter, pixelidentischer Ausschnitt der Master-Vorlage. Entscheidend für die Abnahme sind die tatsächlichen neuen Room-Aufnahmen und der geprüfte aktive Spawn-/Renderpfad, siehe `../../MASTER_WORLD_REPORT.md`.
