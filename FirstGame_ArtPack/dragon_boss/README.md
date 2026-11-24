# Aschenflügel: eigene Bossanimationen und Feuer-VFX

Erzeugt am 22.11.2026 mit dem eingebauten Imagegen-Werkzeug, ausgehend vom freigegebenen großen Drachenmodell unter `../atmosphere_v2/frames/boss-dragon-0.png`. Keine fremden Spielgrafiken, keine externe kostenpflichtige API. Die vollständigen Prompts stehen in `prompts.json`.

## Tatsächlicher Umfang

24 unterschiedliche neue Körperposen, auf drei transparenten RGBA-Quellen zusammen mit acht neuen Effektframes:

| Animation | Neue Körperframes |
|---|---:|
| Idle / Atmen | 4 |
| Schweres Verfolgen | 4 |
| Ausrichten / Drehen | 2 |
| Trefferreaktion | 1 |
| Phasenwechsel / Brüllen | 2 |
| Feueratem vorbereiten | 2 |
| Feueratem waagerecht / leicht gesenkt | 2 |
| Feueratem nach oben | 1 |
| Feueratem nach unten | 1 |
| Stampfen, Fuß heben und aufsetzen | 2 |
| Zusammenbrechen / Tod | 3 |

Die Linksansicht spiegelt dieselben neuen Frames. Atmen, leichte Körperbewegung und die anhaltende Animation verwenden den Simulationszeitgeber; Pause friert sie ein. Die Feuerpose folgt der tatsächlichen Strahlrichtung. Horizontale Strahlen behalten eine stabile Atempose, damit die Gefahrenlinie nicht zwischen verschieden hohen Maulposen springt.

Die vier neuen Feuersegment-Frames werden für Strahl, Sweep und Feuerbogen animiert. Dazu kommen zwei Maulzündungen und zwei eigene Magmaeruptionen. Warnsektoren und Kreisfelder sind präzise im Code gezeichnete Boss-Telegraphen.

## Quellen und reproduzierbarer Import

- `sources/life.png`: zwölf Körperposen für Grundbewegung, Treffer und Phase.
- `sources/attacks.png`: zwölf Körperposen für Feuer, Stampfen, Phase und Tod.
- `sources/vfx.png`: vier Feuersegmente, zwei Maulzündungen, zwei Eruptionen.
- `frames/`: 32 tatsächlich importierte Einzelbilder. Körperbilder 512 × 512, Ursprung (256,480); Feuer 128 × 64, Ursprung (64,32); Maul 96 × 96, Ursprung (48,48); Magma 96 × 160, Ursprung (48,150).
- `anchors.json` und `anchors.gml.txt`: aus dem Importtransform berechnete Maulanker für die Atemposen. Die Quellenannotation im Vorbereitungsskript ist editierbar.
- `prompts.json`: Generierungsanweisungen und Referenz.

Vorbereitung: `tests/tools/prepare_dragon_art.ps1`. Registrierung: `python tests/tools/import_dragon_art.py`. Das Raster wird anhand der tatsächlich gelieferten Bildabmessungen ausgeschnitten; transparente Ränder, Nearest-Neighbor-Skalierung und gemeinsame Körpergröße bleiben erhalten. Ressourcen heißen ausschließlich `spr_fg_dragonboss_*`; normale Drachenmonster behalten ihre bisherigen kleinen Sprites.

## Qualitätsgrenzen

Es sind 24 eigenständige Posen mit kurzen Animationsfolgen und zusätzlicher kontinuierlicher Körperbewegung. Es handelt sich nicht um hunderte einzeln handgezeichnete Zwischenbilder oder ein vollständiges Skelett-Rig. Kopfbewegungen nutzen verschiedene Atemposen und deren Maulanker; feinere Zwischenwinkel sowie zusätzliche Treffer-/Stampfframes können später ergänzt werden. Die grafischen Quellen und Importskripte bleiben erhalten.
