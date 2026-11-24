# Boss-System 2.0 – neue Rasterquellen

Die tatsächlichen Referenzbilder wurden geöffnet: `FirstGame_ArtPack/ChatGPT-Bild 22. Nov. 2026, 23_00_30.png` (Feuer-/Eishexen) und `ChatGPT-Bild 22. Nov. 2026, 23_00_42.png` (Sumpfbehemoth). Die Originale werden nicht verändert. Der bestehende Drache und die Spieler-Sprites werden durch diese Pipeline nicht angefasst.

Alle acht neuen Quellen unter `sources/` wurden mit dem eingebauten Imagegen-Werkzeug erzeugt; keine kostenpflichtige API oder zusätzlichen Downloads. Die verbindlichen Prompts stehen in `prompts.json`. Das sind neu erzeugte Spielgrafiken ohne Beschriftungen, keine ausgeschnittenen Konzepttafeln.

Vorbereitung: `powershell -NoProfile -ExecutionPolicy Bypass -File tests/tools/prepare_boss_v2_art.ps1`. Danach `python Audio/Sources/compose_boss_v2.py`, anschließend **sequentiell** `python tests/tools/import_boss_v2_art.py`. Der letzte Schritt registriert die neuen Ressourcen im aktuell gelesenen Projekt und erhält alle anderen Registrierungen. Er soll nicht parallel zu anderen YYP-Importern laufen.

## Tatsächliche Frames

- Feuerhexe und Eishexe: je 32 Ausgangsposen, acht Vierframe-Zeilen mit schwebendem Idle, Flug, schnellem Flug, Vorbereitung, Cast, Ritual, Reaktion/Phase und Tod. Turn verwendet denselben Flugzyklus; Hurt und Phase teilen jeweils zwei Frames der Reaktionszeile. Je zehn native Sequenzen mit zusammen 36 Frame-Dateien.
- Behemoth: 16 Lebenszyklus-Posen und 32 Angriffsposen, insgesamt 48 verschiedene Ausgangsframes. 13 native Sequenzen. Die Figuren bestehen aus eigenständigen Körperposen; angreifende Arme, Maul, Wurzeln und Pilze verändern ihre Stellung.
- Zwei VFX-Atlanten mit jeweils neun unterschiedlichen Vierframe-Angriffseffekten: 72 Frames.
- Eigene vierframeige Sumpfbrut und zwei getrennte vierframeige Feuer-/Eis-Flugprojektile: zwölf weitere Frames.

Insgesamt 196 Ausgangsframes; native Wiederverwendung einzelner Posen erzeugt 204 Frame-Dateien in 54 Sprite-Ressourcen. Witches: Canvas 128×128, Ursprung (64,116), Figur etwa 90 px vor Spielskalierung. Behemoth: Canvas 512×512, Ursprung (256,480), stehende Figur ungefähr 430 px. Brood: 96×96, Ursprung (48,88). Effekte: 256×256, Ursprung (128,128); Projektilbilder 128×128, Ursprung (64,64). Separate Gameplay-Masken sollen aus der Mechanik gewählt werden, nicht aus wechselnden Angriffs-Spritegrenzen.

Die Vorbereitung verwendet vorhandene Transparenz, entfernt Alpharauschen konservativ und skaliert mit Nearest-Neighbour. Figuren werden anhand ihrer sichtbaren Komponenten aus den neu generierten Atlanten isoliert. Es findet keine globale Entfernung grauer Rüstung/Haarfarben statt. `extraction.json` dokumentiert die tatsächlichen Atlasmaße, Rastergrenzen und Skalen. Alle acht Quellen wurden vor dem Zuschneiden visuell auf ihre tatsächlichen Raster und Inhalte geprüft.

Read-only-Dateiprüfung: `powershell -NoProfile -ExecutionPolicy Bypass -File tests/tools/audit_boss_v2_art.ps1`. Der gespeicherte Befund `art-audit.json` meldet PASS für alle 196 vorbereiteten Frames: richtige Canvasmaße, sichtbare Grafik, tatsächliche transparente Pixel und transparente vier Ecken. Stichproben der importierbaren Hexen-, Behemoth-, Wurzel- und Verbindungsstrahlbilder wurden zusätzlich mit dem Bildwerkzeug geöffnet. Das ist ein Assetnachweis, kein Beleg für funktionierende Gameplay-Treffer; dafür benötigt das Hauptprojekt die eigenen nativen Runtime-Tests.

## Qualität und offene Abnahme

Neue Rasteranimationen sind technisch nutzbar und deutlich mehr als ein einzelnes Konzeptbild. Wiederverwendete Posen werden oben ausdrücklich benannt. Generierte Stoff-, Pilz- und Gesichtsdetails können sich zwischen einzelnen Frames leicht verändern; eine vollständige manuelle Pixel-Feinabnahme bleibt sinnvoll. Mehrere Film-/Kamerarichtungen wurden nicht vorgetäuscht: die Figuren haben eine Hauptansicht und werden im Spiel bei Bedarf gespiegelt.

18 neue Boss-Soundcues entstehen durch das editierbare lokale Skript `Audio/Sources/compose_boss_v2.py`: `twins_1.wav` bis `twins_9.wav` und `swamp_1.wav` bis `swamp_9.wav`, 32 kHz, 16 Bit, Mono. Das sind eigene mehrschichtige Synthese-Prototypen. Technische Dateivalidierung ist möglich, subjektive Hörabnahme steht aus. Die Komposition registriert Ressourcen noch nicht im YYP; das macht der separate Importer.
