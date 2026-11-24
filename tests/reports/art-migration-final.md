# Grafikumstellung – 2026-11-22

## Übernommener Zustand

Copilot hatte die drei Helden mit Richtungen/Aktionen, 16 Gegnertypen, Porträts, Münze und UI-Icons importiert und die visuelle Charakterauswahl angebunden. Die TX-Texturen und Plant-/Tree-Registrierungen waren bereits entfernt. Ein einfacher ArtPack-Boden und ein Baker waren vorhanden. Alle Levelauswahlen führten jedoch auf Room1; der Baker schrieb wegen seiner Einrückung nur eine Instanz je Cluster. Alte Projektil-, Truhen- und zahlreiche unbenutzte Sprite-Ressourcen waren noch enthalten.

## Fertiggestellt

- Vorhandene Helden-/Monsterimporte und Gameplay-Systeme weiterverwendet.
- Neue Originalgrafiken mit dem eingebauten Imagegen-Werkzeug erstellt und vollständig unter `FirstGame_ArtPack/environment` gespeichert. Keine kostenpflichtige API verwendet.
- Echter Sprite mit 13 Landschaftsframes statt einer zur Laufzeit ausgeschnittenen Dekorationszeile. Unterschiedliche Bäume, Büsche, Blumen, Felsen, Stämme, Stümpfe und Ruinensäulen.
- Bodenfarben angeglichen, transparente Blumendetails und zusammenhängende Wegstücke erstellt; alte Wasser-/Sand-Platzhalter werden nicht verwendet.
- Truhe, Feuer und Eis auf neue ArtPack-Grafiken umgestellt. Blitz verwendet den neuen ArtPack-Eisblitz als vorhandenen Ersatz. Das Schwert wird durch die ArtPack-Angriffspose dargestellt; die alten Linien des Hitbox-Draws entfallen.
- Tiefensortierung nach Fußposition für Landschaft, Spielfigur, Gegner und Projektile.
- Die Levelauswahl führt jetzt auf drei unterschiedliche persistierte Räume.

| Level | Room | Seed | Dekorationen | Bodenfläche |
|---|---|---:|---:|---:|
| Waldfeld | Room1 | 20261122 | 722 | 4096×4096 |
| Gruft | RoomCrypt | 20269041 | 662 | 4096×4096 |
| Verlassene Ruinen | RoomRuins | 20276960 | 650 | 4096×4096 |

Jede Karte ist vollständig mit 128×128 Bodenkacheln gefüllt. Echte editierbare Layer: Ground, Ground_Details, Paths, Vegetation, Decorations, Obstacles, Collisions sowie Instances für Gameplay. Verschiedene Clusterverteilungen und feste Seeds; Wege und Startpunkt werden ausgespart. Keine zufällige Laufzeitlandschaft.

Die Umgebung ist derzeit durchquerbare Kulisse. Die Obstacles-Ebene enthält sichtbare Felsen/Ruinen, keine neuen Bewegungssperren; Collisions ist vorbereitet und leer. Damit bleibt der freie Kampfraum erhalten. Eine zusätzliche Hindernis-Kollisionslogik wurde nicht eingeführt.

**Room-Editor-Änderungen bleiben beim normalen Spielen erhalten.** Den Baker nur bewusst ausführen: Er überschreibt manuelle Landschaftsänderungen in allen drei Räumen.

## Entfernung und Wiederherstellung

49 Sprite-Ressourcen wurden entfernt: spr_adventurer_* inklusive Angriffsketten, spr_blob_down, spr_Bossblob_down, spr_Cast, spr_chest, spr_coin, spr_fireball_1–34, spr_sword_attack1, Sprite15_1/2 und die beiden ersetzten einfachen Environment-Sprites. Vollständige Liste: `art-migration-assets.json`.

Vor der Löschung wurde die Wiederherstellbarkeit der alten Projektressourcen in Git HEAD geprüft. `output/art-migration-backup.zip` enthält zusätzlich die entfernten Sprite-Dateien, die damalige HEAD-ID und einen binären Working-Tree-Diff. ZIP-Integrität geprüft. Kein Commit, Reset oder Push durchgeführt. Die bereits vorher gelöschten TX-Quellen sind weiterhin aus Git wiederherstellbar.

Statische Abschlussprüfung: keine Referenz auf die entfernten Sprite-Namen in Objekten, Scripts oder Rooms; keine der entfernten Sprite-Verzeichnisse vorhanden. Alle registrierten Ressourcen existieren. Es sind ausschließlich `spr_fg_*`-/`icon_fg_*`-Sprites aktiv.

## Prüfung und Build

- GameMaker-Projektprüfung: **PASS**, null Probleme und null Warnungen.
- Quick-Diagnostik: **PASS**.
- Drei statische Kartenansichten erzeugt und visuell geprüft: `Room1-art-preview.png`, `RoomCrypt-art-preview.png`, `RoomRuins-art-preview.png`. Diese zeigen gebackene Landschaften, keine Gameplay-Screenshots.
- Windows-VM GML-/Asset-Compile mit Runtime 2024.14.4.268: **PASS**, `Final Compile finished.`, aktuelle `output/art-build/FirstGame.exe` und `data.win` erzeugt.
- ZIP-Paketexport: **nicht fehlerfrei**. Trotz Igor-Exitcode 0 meldet der nachgelagerte Export eine Dateisperre auf `cache/igor_output.zip`. Das ZIP gilt deshalb nicht als validiertes Auslieferungspaket. Buildlog: `art-build.log`.
- Kein Gameplay-Dauerlauf und kein QA-Subagent. Grafikbeurteilung im laufenden Spiel bleibt beim Nutzer.

## Verbleibende Grenzen

Das erwähnte linke Konzeptbild lag nicht vor; umgesetzt wurde die textlich beschriebene GBA-Richtung. Die drei Level sind unterschiedliche offene Landschaften in derselben Palette; Gruft ist kein neu gebauter Dungeon-Innenraum. Dedizierte Blitz- und zusätzliche Combo-Effektstreifen fehlen im ArtPack, deshalb ausschließlich vorhandene neue ArtPack-Darstellung. Keine alten Grafiken als Ersatz. Gameplay-Kollisionen der neuen Kulisse sind nicht ergänzt. Laufende Spielansicht und ZIP-Auslieferung sind nicht abschließend validiert.

Dieser Bericht ersetzt die früheren Aussagen in `environment-rebuild.md` zum gemeinsamen Room1-Baker.
