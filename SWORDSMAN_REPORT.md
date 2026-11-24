# Schwertkämpfer nach der neuen Bildvorlage

Stand: 22.11.2026. Dieser Auftrag folgt auf den abgeschlossenen [Kampf-/Magnet-/Wetterauftrag](COMBAT_REPORT.md). Die übermittelte Bildtafel wurde als Figuren- und Animationsvorlage für die vorhandene Schwertklasse umgesetzt.

## Grafik und Quellen

Eigene neu erzeugte Pixelgrafiken: blonde Haare, roter Schal und Umhang mit goldenem Zeichen, dunkle Rüstung mit silbernen Schulterplatten und goldenen Akzenten, Stahlschwert. Erzeugung mit dem eingebauten Imagegen-Werkzeug, keine heruntergeladenen Spielgrafiken, keine zusätzliche externe API. Die Quellatlanten bleiben unter [FirstGame_ArtPack/swordsman_v3/sources](FirstGame_ArtPack/swordsman_v3/sources) erhalten. Alle verwendeten Anweisungen stehen in [prompts.json](FirstGame_ArtPack/swordsman_v3/prompts.json).

Vier RGBA-PNG-Atlanten mit je 8 × 8 Feldern: `walk.png`, `combat.png`, `mobility.png`, `reaction.png`. Das ergibt 256 Quellfelder. Der reproduzierbare Import erzeugt **120 GameMaker-Sprites mit 384 registrierten Animationsbildern**; einige Quellposen werden bewusst in mehreren Zuständen wiederverwendet. Das sind keine 384 unabhängig gezeichneten Posen.

| Zustand | Bilder je Richtung | Verwendung |
|---|---:|---|
| Idle / Drehen | je 1 | eigene Ansicht für jede Richtung |
| Laufen / Rennen | je 8 | vollständige Schrittfolge; dieselbe Bildfolge |
| Kombo 1 / 2 / 3 | 2 / 2 / 3 | eigene Sequenz je aufeinanderfolgender automatischer Attacke |
| Ausweichen / Slide | je 4 | gemeinsame niedrige Posen, separate Bewegung und Zeitsteuerung |
| Sprung / Fall | 3 / 2 | tatsächlicher Flugfortschritt steuert die Pose |
| Dive / Landung | je 1 | Luftpose bzw. kurze Landung nach Bodenkontakt |
| Treffer | 3 | kurze Rückstoß-/Erholungsfolge |
| Tod | 5 | Einknicken bis zur liegenden Endpose |

Alle Zustände besitzen **acht eigenständige Richtungsressourcen**: rechts, rechts oben, oben, links oben, links, links unten, unten, rechts unten. Die neue Figur verwendet keine Laufzeitspiegelung für Linksansichten. Drehen geschieht durch die acht Blickrichtungen; eine zusätzliche lange Dreh-Zwischenanimation ist nicht enthalten.

## Integration

Die vorhandene Schwertklasse verwendet jetzt ausschließlich `spr_fg_swordsmanv3_*`; Magier und Waldläufer behalten ihre eigenen bestehenden Designs. Auch Charakterauswahl und Pausenansicht zeigen die neue Figur. Die Klassenbezeichnung lautet nun `Schwertkaempfer`, passend zum bestehenden ASCII-Schriftumfang.

Ursprung der Importbilder: **(48,88)** auf **96 × 96**. Die sichtbare Körperhöhe wird an Referenzposen auf 52 Pixel abgeglichen; gerendert wird mit der vorhandenen Spielerskalierung. Import mit Nearest Neighbor, Alpha-Schwelle 128 und Entfernung isolierter Bildreste. Unveränderte RGBA-Quellen bleiben editierbar erhalten. Das ist mechanische Aufbereitung, keine behauptete manuelle Pixelkorrektur.

Die unsichtbare Körpermaske bleibt physisch bei denselben relativen Koordinaten wie vorher. Umhang, Schwert und diagonale Posen vergrößern deshalb weder Kontakt- noch Magnetkollision. Der Maskenträger wird aus der neuen Grafik erzeugt; alte Figurenbilder werden nicht als sichtbarer Fallback verwendet.

Die drei vorhandenen aufeinanderfolgenden automatischen Schwertattacken wählen jetzt unterschiedliche Körperposen. Ihre Schwertbögen unterscheiden sich in Weiß/Violett, Orange und Gold; der dritte Hieb erhält eine stärkere Lichtkante und kurze Funken. Schadensradius und Schadenswerte bleiben zur abgeschlossenen Kampfprüfung konsistent. Eine einzelne automatische Attacke verursacht weiterhin einen Treffer pro Ziel, nicht drei versteckte Zusatztreffer.

Ausweichen und Slide normalisieren ihre vier Bilder auf ihre tatsächliche Dauer. Sprung/Fall verwenden die tatsächliche Flugphase; eine sechs Frames lange visuelle Landung folgt auf gewöhnlichen Bodenkontakt. Der Tod läuft über fünf Bilder und bleibt auf der Endpose stehen.

## Reproduktion

1. `powershell -NoProfile -ExecutionPolicy Bypass -File tests/tools/prepare_swordsman_art.ps1`
2. `python tests/tools/import_swordsman_art.py`
3. `python tests/tools/run_combat_smoke.py`
4. `python tests/tools/build_production.py`

Das [Ressourcenmanifest](FirstGame_ArtPack/swordsman_v3/manifest.json) enthält jeden Sprite, Richtung, Bildanzahl, Größe und Ursprung. Die Quellen sind KI-generierte Rasteranimationen und noch kein von Hand polierter Animationssatz. Kleine Posen- und Umhangabweichungen können bei einer späteren künstlerischen Nachbearbeitung geglättet werden. Die Bildtafel wurde als spielbare Figur umgesetzt; ihre dekorative Infografik und große Portraitillustration wurden nicht als neue Spieloberfläche nachgebaut.

## Prüfung

**PASS: 142 native Prüfungen**, davon elf zusätzliche Ressourcen-/Richtungstests für die neue Figur. Die tatsächlichen Player-Step-Ereignisse wählen alle acht Ansichten ohne Spiegelung und mit unveränderter Körpermaske. Sämtliche 120 Ressourcen sind im laufenden GameMaker mit den erwarteten Bildzahlen und Ursprüngen verfügbar. Drei Kombo-Stufen wählen drei unterschiedliche Sequenzen. Die neun Klassen-/Raumstarts und die bisherigen Kampf-, Drachen-, Mauswahl- und Magnetprüfungen bestehen weiterhin. Magnetnachweis nach Grafikwechsel: 1 echte Collision-Aktivierung, 30 Coins und exakt 30 XP.

Projektintegrität: **477 Ressourcen, null Probleme, null Warnungen**. Die native Bildausgabe wurde geprüft; die Pausenfigur überdeckt den Namen nicht mehr. Die Galerie zeigt exemplarische Posen aller acht Ansichten. Native Ergebnisse: [combat-smoke-result.json](tests/reports/combat-smoke-result.json).

Bilder: [Richtungs-/Aktionsgalerie](tests/reports/swordsman-swordsman-gallery.png), [Pausenansicht](tests/reports/swordsman-inlinepause.png), [Figur im Level](tests/reports/swordsman-field.png).

Die kurze Wetterlastszene besteht ebenfalls: 150 Gegner, 160 Regentropfen, 24 Blätter; Mittel 18,24 ms, Spitze 117,77 ms über 60 Frames. Dies ist keine durchgehend garantierte 60-FPS-Messung.

Eine menschliche Spiel- und Animationsabnahme, subjektive Hörabnahme und neue vollständige 30-Minuten-Progressionsrunde bleiben ausdrücklich offen. Kein Git-Push.

**Finaler normaler Windows-Build: PASS**, einschließlich ZIP-Erstellung, ohne Testeingaben oder Testharness. [FirstGame.zip](output/production-build/20261122-191806/FirstGame.zip), [FirstGame.exe](output/production-build/20261122-191806/game/FirstGame.exe), [Buildnachweis](tests/reports/production-build.json).

Nachfolgender vollständiger Welt-/Skelett-/Kombo-Umbau: [MASTER_WORLD_REPORT.md](MASTER_WORLD_REPORT.md). Dieser spätere Bericht ersetzt die älteren Aussagen zur aktiven Room1-Grafik und zur früheren Einzelschlagfolge.
