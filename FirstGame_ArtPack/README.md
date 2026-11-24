# FirstGame ArtPack 0.1 – Import-Prototyp

Neue Krieger-, Boss- und Magnetgrafiken mit Quellen und Importskripten: [atmosphere_v2/README.md](atmosphere_v2/README.md).

## Verbindlicher Integrationsstand 2026-11-22

Nur dieses ArtPack und darin abgelegte neue Ableitungen sind freigegeben. Die frühere Empfehlung weiter unten, alte Effekte beizubehalten, ist aufgehoben. Alte FirstGame-Sprites sind aus dem aktiven Projekt entfernt. Neue Landschaftsquellen, Einzelbilder, Bodenatlas und Herkunft liegen unter `environment`; Details in `environment/ART_DIRECTION.md` und `../tests/reports/art-migration-final.md`.

## Inhalt
- 3 Helden (Krieger, Magier, Waldläufer), 4 Blickrichtungen, je 10 Aktionen: idle, walk, run, attack, jump, fall, dive, slide, hurt, death.
- 16 Gegnertypen, je 5 Aktionsstreifen (idle, walk, attack, hurt, death): Slime, Pilz, Eber, Goblin, Fledermaus, Irrlicht, Echse, Spinne, Skelett, Pflanze, Käfer, Imp, Golem, Blob, Bandit, Drache.
- Die 16 ursprünglich ausgewählten Monsterdesigns als Konzept-Ausschnitte, 3 Klassenillustrationen, zusätzlich Ritter-Illustration, Auswahlbanner, Münze, 8 UI-Icons, Quellen und GIF-Vorschauen.
- manifest.json enthält jede importierbare Datei samt Raster, Bildanzahl, FPS, Ursprung, Status und Hinweisen.

## Technische Daten
Alle Helden- und Monsterstreifen: transparente RGBA-PNG, horizontale Reihe, 64×64 pro Frame, kein Abstand, Ursprung als Vorschlag (32,51). Die Pixelgrafiken sind aus KI-Entwürfen herausgetrennt und nearest-neighbor skaliert. Münze 32×32. Icons 48×48 (teils eigener Hintergrund). Bilddateien in portraits, references, monster_originals und previews nicht als Frame-Streifen importieren.

## Import in GameMaker
In GameMaker neues Sprite anlegen → Edit Image → Image → Import Strip Image. Framegröße laut Manifest, Columns=frames, Rows=1, Spacing=0, Offset=0. Playback-Speed als FPS einstellen. Origin und Kollisionsmaske passend zu vorhandener Spiellogik setzen. Alternativ Codex die Ressourcen mit korrekten .yy-Dateien und Projektregistrierung importieren lassen; die Vorlage CODEX_IMPORT.md nutzen.

## Qualitätsstand (wichtig)
Dies ist ein **Art-Prototyp**, kein fertig getestetes Produktionspaket. Die Helden-Posen sind neu generiert und den ursprünglichen Charakteren angenähert. Nicht jede Aktion hat neu gezeichnete Zwischenframes; Fall, Dive und Tod verwenden wiederverwendete Posen. Idle ist ein Einzelbild. Monsterstreifen sind neue Interpretationen der ausgewählten Konzepte und können sich in Farbe/Details unterscheiden; die Originalentwürfe liegen gesondert bei. Die Monsterstreifen haben keine vier separaten Blickrichtungen. Nicht jede Waffe, Angriffskette oder jeder Zauber hat einen eigenen neuen Effekt. Bestehende Effekte und alte Animationen für fehlende Varianten behalten. Die Projekt-ZIP ist der frühere Stand (u.a. spr_adventurer_attack1/2/3, spr_adventurer_run, spr_adventurer_idle); der aktuelle Projektstand muss vor Integration geprüft werden. PNG-Raster, Transparenz und nichtleere Frames geprüft; keine Ausführung in GameMaker, keine Gameplay- oder Importvalidierung. Einige Frames können kleine KI-Artefakte enthalten.

## Herkunft
KI-generierte Originalkonzepte und abgeleitete Sprite-Streifen; keine aus Zelda oder Terranigma extrahierten Grafiken. Die visuellen Referenzen sind innerhalb dieses Projekts erzeugte Konzeptblätter. Rechtliche Exklusivität ist nicht garantiert.

Aktueller erster Hauptdrachenkampf, Boss-Orbs und Run-Statistiken: [DRAGON_REPORT.md](../DRAGON_REPORT.md).
