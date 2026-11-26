# Schwertkämpfer v3

Eigene, mit dem eingebauten Imagegen-Werkzeug erzeugte RGBA-Atlanten nach der vom Benutzer übermittelten Figuren-/Animationsvorlage. Keine heruntergeladenen Spielgrafiken. Die vier unveränderten PNG-Quellen befinden sich in `sources/`, die vollständigen Generierungsanweisungen in `prompts.json`.

`walk.png`, `combat.png`, `mobility.png`, `reaction.png` besitzen jeweils ein Raster aus acht Richtungen und acht Posen. Reihenfolge der Richtungen: rechts, rechts oben, oben, links oben, links, links unten, unten, rechts unten.

Der reproduzierbare Import schneidet die Raster, entfernt Alpha-Rauschen und isolierte Fremdpixel, gleicht die Skalierung an Referenzposen ab und erzeugt 96×96-PNGs mit Fußursprung (48,88). Die Rohquellen werden dabei nicht überschrieben.

Ausführung im Projektverzeichnis:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/tools/prepare_swordsman_art.ps1
python tests/tools/import_swordsman_art.py
```

`manifest.json` beschreibt die 120 nativen Sprite-Ressourcen mit insgesamt 384 registrierten Bildern. Wiederverwendete Posen sind ausdrücklich im [Umsetzungsbericht](../../SWORDSMAN_REPORT.md) beschrieben. Die Figurenanimationen sind KI-generierte Rasterfolgen; eine manuelle künstlerische Feinabnahme bleibt sinnvoll.
