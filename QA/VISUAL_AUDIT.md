# Grafik- und Animationsaudit

Stand: 23.11.2026. Die maschinelle Prüfung umfasst alle registrierten Sprite-Ressourcen. Die anschließende Sichtprüfung ist eine Stichprobe, keine Behauptung, jede Animation unter sämtlichen Spielbedingungen gesehen zu haben.

## Nachweise und Umfang

| Prüfung | Ergebnis | Nachweis |
|---|---:|---|
| Registrierte Sprites | 826 | `data/visual-audit.json` |
| Composite-Frames auf Existenz, Größe, Alpha und sichtbaren Inhalt geprüft | 2.551 | `data/visual-frames.csv` |
| Zugehörige Ein-Layer-PNGs gegen Composite verglichen | 2.551 identisch | `data/visual-audit.json` |
| Fehlende, vollständig leere oder falsch dimensionierte Frames | 0 | maschinelle Prüfung |
| Sprite-Ursprünge außerhalb der jeweiligen Bildfläche | 0 | Metadatenprüfung |
| Aktivierte Sprite-Kantenfilterung | 0 | `data/visual-preservation.json` |
| Native Sprite-PNGs gegen den gesicherten Ausgangsstand geprüft | 5.102 unverändert | `data/visual-preservation.json` |
| Davon Drachen-PNGs | 258 unverändert | gleiche Prüfsummenprüfung |
| Erzeugte Kontaktbögen | 33 | `screenshots/visual-*.png`, `sequence-*.png` |

Die Ressourcenmenge bleibt bei 973 identischen Einträgen. `FirstGame.yyp` hat gegenüber der Baseline eine andere Reihenfolge dieser Einträge; es wurden dabei keine Ressourcen hinzugefügt, entfernt oder umdefiniert. Die Prüfung erhält diese aktuelle Reihenfolge.

Die Familienzuordnung des Prüfskripts ist eine Namensgruppierung, kein Beweis einer tatsächlichen Nutzung. `other_registered` enthält beispielsweise frühere Spieler- und Gegner-Sets. Der aktuelle Spieler-Step wählt `swordsmanv3`, `magev3` und `rangerv3`; der reguläre Room1-Spawn wählt die `master_skeleton`-Familie. Andere Ressourcen bleiben für bestehende andere Räume, ältere Pfade oder Fallbacks registriert.

| Grafikfamilie | Registrierte Composite-Frames | Unterschiedliche PNG-Inhalte |
|---|---:|---:|
| Schwertkämpfer v3 | 384 | 256 |
| Zaubermeisterin v3 | 432 | 256 |
| Waldläufer v3 | 424 | 256 |
| Master-Skelette | 128 | 128 |
| Drache | 48 | 48 |
| Zwillingshexen einschließlich Geschosse | 80 | 72 |
| Behemoth | 48 | 48 |
| Klassen-Effekte | 72 | 72 |
| Neue Boss-Effekte und Brut | 76 | 76 |
| Drachen-Effekte | 64 | 64 |
| Zauber-Effekte | 24 | 24 |
| Master-Welt einschließlich Schwertbögen | 29 | 29 |

Mehrere registrierte Frames sind bewusst dieselben Ausgangsposen. Diese Zahlen zählen keine prozedurale Atmung oder Spiegelung als zusätzliche handgezeichnete Frames. Für mehrere Bewegungen stehen somit weniger eigenständige Posen zur Verfügung als registrierte Frame-Einträge.

## Durchgeführte Sichtprüfung

Direkt betrachtet wurden 13 aktuelle Kontaktbögen: `visual-twins-01`, `visual-behemoth-01`, `visual-world-01`, `sequence-mage-01`, `sequence-ranger-02`, `sequence-swordsman-02`, `visual-icons-01`, `visual-items_projectiles-01`, `visual-class_fx-01`, `visual-boss_fx-01`, `visual-dragon-01`, `visual-dragon_fx-01` und `visual-spell_fx-01`.

Die neuen Klassen, Skelette, Bossfamilien und Weltobjekte verwenden detailreiche Konturen und eigene, gut unterscheidbare Farbgruppen. In den betrachteten aktuellen Charakterbögen sind keine weißen Rechteckhintergründe sichtbar. Die transparente Vorschau zeigt keine Gründe für eine pauschale Weichzeichnung. Effekte dürfen ihre Silhouette und Ausdehnung während einer Explosion, eines Bogens oder eines Todesablaufs stark verändern; ein Unterschied der sichtbaren Bildhöhe allein ist kein Ursprungsfehler.

Die 36 aktuellen `icon_v2_*` besitzen einen gemeinsamen Rahmenstil und klar getrennte Motive. Einige ältere `icon_fg_*` haben sichtbar helle Hintergründe beziehungsweise eine andere Gestaltung. Diese älteren Icons werden von der aktuellen kataloggesteuerten Zauber-Icon-Funktion nicht ausgewählt; ein pauschaler Austausch wäre deshalb keine belegte Verbesserung des aktiven HUDs.

## Behobener Animationsfehler

**Bestätigter Darstellungsfehler: Die Trefferreaktion der Zwillingshexen und des Behemoths sprang vor dem Ende zurück auf Frame 0.**

Alle drei `spr_bv2_*_hurt`-Ressourcen besitzen zwei Frames. `bv2_actor_animation` lieferte bei `hurt_flash_timer` von 6 bis 1 die Folge `0,0,1,1,2,2`. Der Draw-Aufruf mit Index 2 wiederholte aufgrund des Frame-Wrappings die erste Pose. Die vorhandenen Todes-Ressourcen besitzen dagegen vier Frames; dort lag der zunächst vermutete Fehler nicht vor.

`bv2_actor_draw` begrenzt nun ausschließlich die einmaligen Treffer- und Todesreaktionen auf den letzten tatsächlich verfügbaren Frame. Die Trefferfolge wird dadurch `0,0,1,1,1,1`. Schleifenanimationen behalten ihre bisherige Behandlung. Die Änderung betrifft weder Zeiten noch Schaden, Bewegung, Kollisionsmasken, Ressourcen noch das Drachenmodell.

Die vorherige Fehlfolge ist durch Baseline-Quelltext und tatsächliche Ressourcenanzahl belegt. Der korrigierte Renderer wurde danach im nativen Runner geprüft. Die festgehaltenen Zustände mit Treffer-Timer 4 und 2 zeigen die gehaltene Endpose:

- [Trefferreaktion bei Timer 4](screenshots/qacapture-twins-hurt-timer4.png)
- [Trefferreaktion bei Timer 2](screenshots/qacapture-twins-hurt-timer2.png)

Es gibt keinen neu aufgenommenen Vorher-Runtime-Film; der Vorher-Nachher-Nachweis kombiniert den gesicherten alten Code mit den neuen nativen Bildern. Der gezielte aktuelle Regressionstest bestand **811 Prüfungen ohne Fehler**, darunter native Boss-/Waffen-/Statusprüfungen. Das ist kein vollständiger menschlicher Spieltest (`data/regression.json`).

## Tatsächliche Welt-Darstellung

Zusätzlich wurden die nativen Aufnahmen [Zaubermeisterin im Wald](screenshots/qacapture-mage-current-world.png) und [Waldläufer im Wald](screenshots/qacapture-ranger-current-world.png) betrachtet. Sie zeigen die vorhandenen Steinübergänge, Vegetation, Ruinen, Lichtquellen, Bodenschatten und Klassensilhouetten in derselben aktuellen Room1-Szene. Die Beleuchtung ist deutlich dunkel, die hellen Klassenfarben bleiben in dieser Szene erkennbar. Die Bilder zeigen keinen abgeschnittenen Spieler und keinen rechteckigen Sprite-Hintergrund.

Diese vier ursprünglichen Weltaufnahmen stammen von der `application_surface` und enthalten **keine GUI**. Die nachfolgend beschriebenen zusätzlichen GUI-Aufnahmen prüfen diese Ebene gesondert. Die älteren Boss-System-Aufnahmen im Verzeichnis `tests/reports` bleiben historische Nachweise und werden nicht als neu ausgeführte Grafiktests gezählt.

## Zusätzliche native HUD- und Auswahlprüfung

Der aktuelle Runner erzeugte anschließend fünf weitere Bilder mit den tatsächlichen Produktionsfunktionen `hud_draw`, `ui_modal_draw` und `boss_test_draw_gui`. Diese Funktionen wurden im nativen Draw-GUI-Kontext in eine eigene Surface mit 1280×720 beziehungsweise 800×600 gerendert und mit der aktuellen Welt-Surface kombiniert. Das sind native Renderergebnisse der Produktionsfunktionen, **keine Aufnahme eines tatsächlich auf 800×600 umgestellten Betriebssystemfensters** und kein manueller Langzeitspieltest.

Der gezielt initialisierte Prüfzustand besitzt sechs aktive und sechs passive Slots auf Stufe 5, Spielerlevel 36 und einen bei Minute 15 erzeugten Drachen. „Full build“ im Bildnamen bezeichnet gefüllte Plätze; es ist kein vollständig auf Stufe 9 ausgebauter Build und kein natürlicher 15-Minuten-Run. Die Schadensstatistik von 0 im Tooltip passt zum frisch initialisierten Zustand.

Alle fünf Bilder wurden direkt betrachtet:

- [HUD mit zwölf belegten Slots, Timer, Minimap und Bossbalken bei 1280×720](screenshots/qacapture-hud-full-build-1280.png)
- [Aktiver Fireball-Tooltip bei 1280×720](screenshots/qacapture-hud-tooltip-1280.png)
- [Level-up mit langem Resonant-Core-Text bei 1280×720](screenshots/qacapture-levelup-1280.png)
- [Dieselbe Level-up-Auswahl bei 800×600](screenshots/qacapture-levelup-800.png)
- [Passiver Orbit-Shield-Tooltip und HUD bei 800×600](screenshots/qacapture-hud-tooltip-800.png)

In diesen geprüften Zuständen sind die sechs aktiven und sechs passiven Plätze getrennt erkennbar, Timer und Bossbalken lesbar, die Minimap innerhalb des Bildes und die langen Texte vollständig innerhalb ihrer Panels. Der ausführliche Voraussetzungstext wird bei 800×600 auf zusätzliche Zeilen umgebrochen. Es ist kein Textabschluss am Panelrand abgeschnitten; Tooltip und Slots überlappen sich nicht. Die nativen Funktionsprüfungen sind weiterhin **811/811 bestanden**, zuletzt unter `QA/logs/regression-20261123-223202` (`data/regression.json`).

Damit sind diese konkreten HUD-/Tooltip-/Level-up-Zustände bei zwei Größen visuell geprüft. Aktuelles Hauptmenü, Charakterauswahl, Einstellungen, Pause und Game-Over-Layout wurden in dieser ergänzten Serie nicht als neue GUI-Bilder aufgenommen. Ebenso sind eine echte Fensterverkleinerung, weitere Seitenverhältnisse und sämtliche denkbaren Tooltip-Inhalte damit nicht vollständig geprüft.

## Ausgewertete automatische Auffälligkeiten

| Flag | Anzahl Frames bzw. Ressourcen | Einordnung |
|---|---:|---|
| Sichtbare Pixel berühren die Bildkante | 122 Frames | Icons, kachelbarer Boden und auslaufende Effekte dürfen Kanten erreichen; keine automatische Fehlerzahl |
| Vollständig deckende Fläche | 42 Frames | überwiegend gerahmte Icons, Boden bzw. ältere Vollflächen |
| Teiltransparente Pixel | 371 Frames | Alpha ist bei Leuchten und Effekten erwünscht; kein Beweis eines Farbrandes |
| Sichtbare Höhe variiert um mehr als 35 % | 163 Sprites | überwiegend Effekte, Sprung-/Ausweichposen und Todesabläufe; keine pauschale Skalierungskorrektur |

Beispielsweise erreicht der vorhandene Drachen-Flammenstreifen die Bildkante. Er wird gezielt auf eine Strahllänge gestreckt. Das ist kein hinreichender Grund, die Grafik oder das Drachenmodell zu ersetzen. Auch geringe weiße Kantenpixel an diesem Flammenstreifen sind allein kein Nachweis eines sichtbaren weißen Saums in der Szene.

## Verbliebene Grafikarbeit, nach Priorität

1. **Noch nicht getestete Funktion:** Aktuelle Hauptmenü-/Charakterauswahl-/Einstellungs-/Pause-/Game-Over-GUI gesondert aufnehmen; zusätzlich echte Fenstergrößenänderung und weitere Seitenverhältnisse prüfen. HUD, lange Tooltips und Level-up sind bereits durch die oben genannten nativen 1280×720- und 800×600-Surfaces geprüft.
2. **Grafikqualität:** Die drei Klassen nutzen für einige Bewegungen wiederholte Ausgangsposen. Für weichere Bewegung sind zusätzliche eigenständige Lauf-/Übergangsposen sinnvoll; keine bestehende Pose wurde durch einen schlechteren Ersatz überschrieben.
3. **Grafik-/Lesbarkeitsprüfung:** Kontrast bei Starkregen, dunkler Tagesphase und mehreren überlappenden Effekten länger im tatsächlichen Spiel prüfen. Die einzelne aktuelle Waldszene liefert keine Freigabe für jede Wetter- und Angriffskombination.
4. **Legacy-Ressourcen:** Frühere Icons und Gegner-/Klassen-Sets gesondert katalogisieren, bevor eine spätere Bereinigung erfolgt. Registrierung oder ein Alpha-Flag allein rechtfertigen weder Löschen noch einen globalen Stilumbau.

Keine Rastergrafik wurde in diesem Audit neu generiert, weichgezeichnet oder überschrieben. Es wurden keine kostenpflichtigen APIs verwendet. Das bestehende Drachenmodell und alle nativen Sprite-PNGs sind unverändert.

## Wiederholung

`python QA/tools/audit_visuals.py` erzeugt das vollständige Metadaten-/Pixelinventar und die Kontaktbögen erneut. `python QA/tools/audit_visual_preservation.py` prüft Ressourcen und PNG-Prüfsummen gegen die unveränderte Baseline. Die Kontaktbögen verwenden eine Pixelvorschau; sie sind Prüfartefakte und keine Ersatzgrafiken für das Spiel.
