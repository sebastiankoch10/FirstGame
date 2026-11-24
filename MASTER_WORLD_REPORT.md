# Level 1 vollständig auf den Master-Style umgestellt

Stand: 22.11.2026. Dieser Bericht ersetzt die früheren Aussagen zum aktiven ersten Level und zur Schwertkombo. Der Umbau betrifft den vorhandenen Room1; es wurden keine neuen Level oder Klassen angelegt.

## Entfernte aktive Nutzung

- Die drei alten Tile-Layer `Ground`, `Ground_Details` und `Paths` mit dem Tileset `Grass` wurden aus Room1 entfernt. Damit liegen dort auch dessen bisherige Bodengrafiken nicht mehr unter der neuen Welt.
- Alle **722** bisherigen `ObjectEnvironmentDecoration`-Instanzen und die alten Layer `Vegetation`, `Decorations`, `Obstacles` sowie der leere Kollisionslayer wurden aus Room1 entfernt. `spr_fg_landscape` wird dort nicht mehr gezeichnet.
- Room1 enthält jetzt ausschließlich die vier notwendigen Gameplay-Objekte, einen neuen `ObjectMasterWorld` und **1.146 neue `ObjectMasterScenery`-Instanzen**. Das ist ein Austausch des aktiven Raums, kein Overlay auf dem alten Room.
- Slime, Mushroom, Wisp, Lizard, Spider, Plant, Beetle, Bat, Goblin, Imp, Bandit, Boar, Golem und Blob sind aus dem aktiven normalen Spawnzweig für Room1 ausgeschlossen. Die bestehenden Bossbegegnungen bleiben erhalten. Die anderen beiden vorhandenen Räume behalten ihren bisherigen eigenen Inhalt; alte Ressourcen bleiben dafür auf Platte und sind kein Fallback für Room1.

## Neue Welt

Fünf neue Original-PNG-Quellen wurden mit dem eingebauten Imagegen-Werkzeug erzeugt. Es wurden keine externen Spielgrafiken heruntergeladen und keine zusätzliche kostenpflichtige API verwendet. [Quellen, Anweisungen und Importbeschreibung](FirstGame_ArtPack/master_world/README.md).

Der neue Boden enthält dunkle Erde, kleine Gras-/Moosstrukturen, unregelmäßige verwitterte Steinplatten und rotes/goldenes Laub. Die Bodentextur wird mit wechselnder Spiegelung gezeichnet, sodass Kachelgrenzen gemeinsame Randpixel besitzen. Das alte regelmäßige Pflasterraster und die alte grüne Wiese sind nicht mehr aktiv.

16 neue Umgebungstypen: vier große Bäume einschließlich rotem Ahorn und verwurzelten Eichen, vier Pflanzen-/Blütengruppen, Säule, Torbogen, Mauer, Feuerschale, moosige Felsen, Baumstumpf, verwitterte Platten und Laub-/Steindetails. Der Raum folgt einer reproduzierbaren Planung mit gewundenen Wegachsen und fünf Ruinenplätzen. Bäume und Unterwuchs bilden Gruppen an deren Rändern; Kampfbereiche bleiben offen. Layout und Importregeln liegen in [layout.json](FirstGame_ArtPack/master_world/layout.json) und `tests/tools/rebuild_master_world.py`, Seed 42187.

Die neue aktive Welt verwendet **60 neue Grafikressourcen mit 157 Bildern**. Das [Manifest](FirstGame_ArtPack/master_world/manifest.json) führt jede Ressource und ihren Ursprung auf. Die Grafiken wurden für das Spiel geschnitten und per Nearest Neighbor skaliert; Rohquellen und vollständige Generierungsanweisungen bleiben editierbar erhalten.

## Ausschließlich neue Skelette als normale Gegner

`ObjectMonster` startet in Room1 unmittelbar mit dem neuen Skelettsatz. Auch dessen Create-Ereignis lädt dort keinen alten Slime zwischenzeitlich als Grafik. Der Spawner hat für Room1 einen eigenen Skelettzweig und verlässt ihn, bevor die alten Arten ausgewählt werden können.

Das neue Modell trägt verwitterte Elfenbeinknochen, dunkle Rüstungsreste, einen beschädigten Rundschild und ein Schwert. Es besitzt **acht Richtungen**, jeweils zwei Idle-, vier Lauf-, zwei Angriffs-, drei Treffer- und fünf Todesbilder. Standard, schneller Späher und widerstandsfähiger Wächter nutzen denselben konsistenten Grafikpool mit passenden vorhandenen Tempo-/HP-Werten und Größen.

Der Skelettschlag hat eine harmlose Ausholphase von 0,20 s, ein aktives Fenster bis 0,36 s und Erholung bis 0,72 s. Die Blickrichtung wird vor dem Schlag fixiert, die Verfolgung währenddessen angehalten. Trefferstun verhindert Schaden; die Trefferpose unterbricht das aktive Angriffsbild. Schaden entsteht durch die tatsächliche Schlagphase und Reichweite, nicht durch dauerhaftes Berühren einer stehenden Figur.

Beim Tod werden Kill und Münze genau einmal vergeben. Eine eigene kurzlebige Leicheninstanz spielt die fünf Todesbilder ab und blendet anschließend aus. Sie gehört nicht mehr zum lebenden Gegnerpool und kann keinen Kontaktschaden verursachen. Maximal 32 solcher Instanzen bleiben gleichzeitig aktiv.

## Tatsächliche Dreier-Schwertkombo

Ein automatischer Angriff startet jetzt eine **zusammenhängende Kette aus drei Hieben**. Der frühere bloße Wechsel der Pose bei drei getrennten Einzelangriffen wurde ersetzt. Die Kette beginnt nur mit einem sichtbaren Ziel in Reichweite; sie besitzt Ausholen, drei separate aktive Treffer und eine abschließende Erholung.

| Phase | Beginn bei Basistempo | Tatsächlicher Treffer | Körperbilder | Effektbilder |
|---|---:|---:|---:|---:|
| Erster Hieb | Frame 0 | Frame 4 | 2 | 4 |
| Zweiter Hieb | Frame 16 | Frame 22 | 2 | 4 |
| Finisher | Frame 34 | Frame 42 | 3 | 4 |
| Erholung | Kettenende Frame 56 | kein weiterer Treffer | Endpose / Idle | Ausblenden |

Ein neuer Kettenstart ist bei Basistempo nach ungefähr 68 Frames möglich. Haste beschleunigt den gemeinsamen Zeitgeber und die Erholung. Die Körper-Kontaktpose verwendet denselben Zeitgeber wie der tatsächliche Schaden. Es gibt keine unabhängige, am Treffer vorbeilaufende Animationsschleife.

Jeder Hieb besitzt eine eigene Hitbox und eine eigene Trefferliste: Ein Ziel darf von allen drei Hieben getroffen werden, aber nicht mehrfach vom selben Hieb. Richtungen werden zu Beginn eines Hiebs erfasst und während des Kontakts gehalten. Erste Hiebe: Radius 116 px, Halbwinkel 58°; Finisher: 130 px und 70°. Bei Basis-Power 2 ergeben sich **11 + 13 + 19 = 43 tatsächlich abgezogene HP** an einem genügend widerstandsfähigen Ziel. Overkill bleibt korrekt begrenzt. Die Multiplikatoren sind 0,5 / 0,6 / 0,9 der bestehenden Waffenbasis; die schnellere Trefferfolge wurde nicht versehentlich mit dreimal vollem Einzelschaden versehen.

Neue echte Rastereffekte: weiß-violetter erster Bogen, orangefarbener zweiter Bogen, breiter goldener Finisher, jeweils vier Bilder. Die bisherigen generischen Dreiecksbögen sind aus dem aktiven Sword-Draw entfernt. Getroffene Ziele erhalten die vorhandenen kurzen Stun-/Knockback-Reaktionen, passende Impact-Funken und echte Schadenszahlen. Die neuen Slash-Bilder erzeugen außerdem kurze warme Lichtimpulse; bestehende Swing-/Hit-Sounds bleiben an tatsächlichen Schlag-/Trefferereignissen gekoppelt.

Die vorhandene blonde Schwertkämpferfigur mit rotem Umhang bleibt erhalten. Ihre Präsenz entsteht jetzt im zusammenhängenden neuen Umfeld, mit Bodenschatten, synchronisierten Komboposen und deutlich stärkeren Effekten.

## Schatten, Licht, Wetter und Darstellungskosten

Held und Skelette besitzen gemeinsame weiche mehrstufige Kontaktschatten; der Heldenschatten reagiert auf Sprunghöhe. Bäume werfen breitere gerichtete Bodenschatten, Ruinenelemente erhalten kompakte Fußschatten. Umgebungsbilder enthalten ihre eigene stilgerechte Volumenschattierung. Es handelt sich um eine begrenzte 2D-Schattenlösung, nicht um behauptetes dynamisches Raytracing.

Kühles blaues Umgebungslicht und warme Feuerschalen greifen in denselben bestehenden halbauflösenden Lichtpass ein. Schwertschläge, Projektile, Status und Drachenfeuer behalten ihre begrenzten dynamischen Lichtquellen. Hohe Baumkronen werden teilweise transparent, wenn sie den Spieler überdecken würden. GUI und Bosswarnungen bleiben oberhalb der Welt-/Wetterpasses lesbar.

Leichter Nebel, sanfter Wind, gelegentliche Böen und nun rot-/ockerfarbene Blätter sind aktiv. Die vorhandenen weichen Regen-/Aufhellungszyklen bleiben erhalten. Budgets: maximal 160 Regentropfen und 24 Blätter, keine zusätzlichen Wetterinstanzen.

Die Requisiten werden nach Kameranähe sichtbar geschaltet. Sichtbereich, sichtbare Baumgruppen und Feuerstellen werden zwischengespeichert; außerhalb des Sichtbereichs werden keine Deko-Draw-Skripte aufgerufen. Die technische Grenze für normale Gegner bleibt bei 180. Die native Bildprüfung exportiert PNGs direkt aus den tatsächlichen Framebuffer-Surfaces, statt die detailreichen Bilder als langsame Konsolen-Textblöcke zu übertragen.

## Prüfung und Abnahme

**PASS: 158 native Prüfungen** in einer frisch gebauten isolierten Windows-VM-Kopie. Nur diese Kopie besitzt Testeingaben und Szenensteuerung. Die Tests umfassen:

- Den tatsächlich geladenen Room1: **0 alte Landschaftsinstanzen, 1.146 neue Requisiten und alle 16 neuen Umgebungstypen**. Keine alten Boden-/Pfad-Layer.
- **36 tatsächliche Spawnproben** für frühe und spätere Rundenzeitpunkte: ausschließlich neue Skelette. Alle 40 Skelett-Richtungs-/Aktionsressourcen mit erwarteten Framezahlen verfügbar.
- Eine echte komplette Schwertkette an demselben widerstandsfähigen Ziel: zunächst harmloses Ausholen, dann gemessene **11 / 13 / 19 HP**. Jeder Hieb trifft genau einmal, der Finisher besitzt sein eigenes Kontaktfenster. Kontaktposen folgen exakt denselben Schaltzeitpunkten.
- Die drei tatsächlichen Hiebe wurden zusätzlich während normaler nativer Steps mit bewegten Skeletten gerendert und als PNG exportiert. Alle drei Aufnahmen sind verpflichtende Testnachweise; fehlende Bilder lassen die Suite scheitern.
- Skelett-Ausholen ohne Schaden, tatsächlicher aktiver Schlag, Tod mit genau einer Münze und separater Leiche, fünftes Todesbild vor dem Ausblenden.
- Die bestehenden neun Klassen-/Raumstarts, Mauswahl, Projektile, Statistiken, gerichteten Drachenangriffe und Magnetabläufe. Der Magnet liefert weiterhin über echte Kollision 30 Münzen und **exakt 30 XP**.

Die Bildfolgen wurden visuell geprüft: neue detaillierte Wald-/Ruinenwelt statt alter grüner Fläche und regelmäßiger Pflasterwege, neue Skelette statt alter Monster, klar unterscheidbare helle/orange/goldene Bögen. Die Aufnahmen stammen aus dem tatsächlichen GameMaker-Renderer, nicht aus Konzeptgrafiken. Für mehrteilige visuelle Tests erhalten Testfiguren erhöhte HP; das wird nicht als menschlich gewonnene Spielrunde ausgegeben.

Statische unabhängige Raum-/Dateiprüfung: **PASS**, nur die zwei neuen Room-Layer, keine alten Deko-/Tile-Layer, 157 vorhandene gültige RGBA-Importbilder samt übereinstimmenden Ebenenkopien. Projektintegrität: **543 Ressourcen, 0 Probleme, 0 Warnungen**.

Kurze native Lastszene, ohne PNG-Export im Messfenster: **150 Skelette, 160 Regentropfen, 24 Blätter**, 60 gemessene Frames. Mittel **22,64 ms**, Maximum **178,45 ms**. Der kurze Test bestätigt die begrenzten Mengen und funktionierende neue Szene, aber keine dauerhaft stabilen 60 FPS; einzelne deutliche Spitzen sind vorhanden.

Der normale Windows-Build und das ZIP-Paket sind erfolgreich. Keine Testeingaben oder Testharness im normalen Spielpaket. Die ZIP-Inhalte wurden zusätzlich per CRC geprüft.

Nachweise: [native Ergebnisse](tests/reports/master-world-smoke.json), [aktiver Room-/PNG-Audit](tests/reports/master-world-active.json), [Projektprüfung](tests/reports/master-world-project.json), [Windows-Build](tests/reports/master-world-build.json).

Sichtprüfung: [neue Welt](tests/reports/master-world-overview.png), [erster Hieb](tests/reports/master-world-combo-first.png), [zweiter Hieb](tests/reports/master-world-combo-second.png), [Finisher](tests/reports/master-world-combo-finisher.png), [150 Skelette bei Regen](tests/reports/master-world-crowd-rain.png), [Wind](tests/reports/master-world-gust.png), [bestehender Drache in neuer Welt](tests/reports/master-world-boss.png). Zum Vergleich: [vorheriger Room](tests/reports/swordsman-field.png).

## Verbleibende Grenzen

Die funktionale aktive Umstellung ist vollständig umgesetzt und geprüft. Offen bleiben die menschliche Spiel-/Stilabnahme sowie eine längere Performancebeobachtung und gegebenenfalls weitere Glättung der gemessenen Spitzen. Die Rastergrafiken sind KI-generiert; zusätzliche manuelle Pixel- und Animationsfeinpolitur ist weiterhin möglich. Eine pixelidentische Kopie des Masterbildes oder von Hand gezeichnete Vollanimationen werden nicht behauptet. Kein Git-Push.

Aktuelles vollständiges Windows-Paket: [FirstGame.zip](output/production-build/20261122-203226/FirstGame.zip).
