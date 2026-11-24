# Spielerstart: Absturzkorrektur und Laufzeitnachweis

Stand: 22.11.2026. Ausschließlich Start-/Sprite-Stabilität; keine neuen Grafiken, Gameplay-Features, QA-Subagents oder Git-Pushes.

## Tatsächliche Ursache

`ObjectPlayer.yy` enthält `spriteId: null` und `spriteMaskId: null`. Sein Create-Event setzte nur `visual_sprite_index = -1`, aber keinen gültigen `sprite_index`. Die erste Zuweisung an `sprite_index` stand erst **nach** den ungeschützten Größenabfragen im Step-Event. Deshalb erreichte der erste Step `sprite_get_width/height(-1)`. Ein erfolgreicher Asset-Compile konnte diesen Initialisierungsfehler nicht erkennen.

Zusätzlich verwendete die Angriffslogik `sprite_get_number(sprite_index)`, obwohl der sichtbare Angriff separat über `visual_sprite_index` gezeichnet wurde. Die Round-Reset-Funktion setzte außerdem unabhängig von der Klasse zunächst den Krieger-Sprite.

Beim tatsächlich ausgeführten Menütest wurde danach derselbe Initialisierungsfehler bei `ObjectMonster` sichtbar: Ein im Spawner-Step erzeugter Gegner kann bereits vor seinem eigenen ersten Step gezeichnet werden. Sein Sprite war noch `-1`. Der Boss hatte denselben unsicheren Aufbau.

## Korrektur

- Gemeinsame Initialisierung im Player-Create und beim Round-Reset: passende Klasse und gültiger ArtPack-Idle-Sprite sofort gesetzt.
- Alle 40 Animationsressourcen einer Klasse werden bei ihrer Initialisierung mit `sprite_exists` und vorhandenen Frames geprüft. Ein fehlendes Asset wird mit seinem Namen gemeldet; kein alter Grafik-Fallback.
- Feste Bewegungsgrenzen von 32×32 Halbausdehnung statt Abfragen des aktuellen Animationsbildes. Feste, geprüfte ArtPack-Kollisionsmaske `spr_fg_warrior_idle_right`, die beim Klassen-/Animationswechsel erhalten bleibt. Keine neue Grafik dafür erstellt.
- Überflüssige Sprite-Frameabfragen der alten Angriffssteuerung entfernt. Angriffstimer und Hitbox-Zeitpunkte bleiben erhalten; Darstellung nutzt die bereits vorhandenen ArtPack-Angriffsframes.
- Eigene Draw-Events prüfen die tatsächliche Sprite-Existenz. Auch alle verbleibenden `sprite_get_width/height`-Stellen in Menü/HUD wurden geprüft und durch `sprite_exists` abgesichert.
- Monster und Boss initialisieren bereits in Create gültige ArtPack-Sprites; ihre Step-/Draw-Zugriffe werden ebenfalls geprüft.

## Tatsächlich ausgeführte Prüfungen

| Prüfung | Ergebnis |
|---|---|
| Projektregistrierung | PASS, 0 Probleme, 0 Warnungen |
| Quick-Diagnostik | PASS |
| Alle Spieleranimationsressourcen auf Disk und in `.yyp` | PASS, 120 Ressourcen |
| Windows-VM-Compile, Runtime 2024.14.4.268 | PASS |
| Echter GUI-Menüweg: Hauptmenü → Neues Spiel → Schwertkämpfer → Waldfeld → Room1 | Ausgeführt; fand zunächst den zusätzlichen Monster-Draw-Absturz, anschließend behoben |
| Aktueller normaler Windows-Build tatsächlich gestartet | Ja; laufenden Spielraum mit gezeichneten Gegnern beobachtet |
| Vollständiger erneuter GUI-Menütest aller drei Klassen | **Nicht abgeschlossen**; parallele manuelle Eingaben im Spielfenster erkannt, weitere UI-Steuerung beendet |
| Automatisierter technischer Windows-Runtime-Test aller drei Klassen | **PASS**, siehe Tabelle unten |

Der normale Build liegt unter `output/art-build/FirstGame.exe` mit `data.win`. Seine aktuelle EXE wurde um 12:43:12 erzeugt. Eine ältere noch laufende EXE hatte zwischenzeitlich das Überschreiben blockiert; die alten Testprozesse wurden beendet und der Build neu erzeugt. Der Build-Helfer prüft künftig explizit, ob **beide** ausführbaren Artefakte neu geschrieben wurden. ZIP-Export weiterhin mit Dateisperrenmeldung; dies ist kein Nachweis eines erfolgreichen Auslieferungspakets.

### Endgültiger Runtime-Smoke-Test

**Kein GUI-End-to-End-Menütest:** Eine isolierte Kopie des aktuellen Projekts startet technisch direkt in Room1. Nur in dieser Kopie werden Eingabeabfragen durch deterministische Eingaben ersetzt. Originale Create-/Step-/Draw-/Collision-Logik läuft im echten Windows-VM-Spiel. Der laufende Nutzer-Spielprozess erhält keinerlei Eingaben.

| Klasse | Tatsächliche Steps | Laufzeit im Level | Zurückgelegte Strecke | Angriff |
|---|---:|---:|---:|---|
| Schwertkämpfer | 720 | 12,679 s | 2059,36 px | Angriffsstatus und Schwert-Hitbox nachgewiesen |
| Magier | 720 | 11,967 s | 1820,44 px | Angriffsstatus und Feuerprojektil nachgewiesen |
| Waldläufer | 720 | 11,967 s | 2656,65 px | Angriffsstatus und Blitzprojektil nachgewiesen |

Jede Klasse durchlief Walk, Attack, Idle, Jump, Fall, Dive, Slide und Hurt. Pro Step werden gültige Engine-/Draw-Sprites, gültige unveränderte Kollisionsmaske und feste Bewegungsgrenzen geprüft. Der Test setzt `sprite_index` absichtlich einmal auf `-1`, um nachzuweisen, dass die Bewegungsberechnung nicht mehr von dieser visuellen Referenz abhängt und der Step eine gültige Darstellung herstellt. Monster-/Boss-Create und Draw vor ihrem ersten regulären Step werden ebenfalls explizit geprüft. Die Existenz aller Richtungen/Aktionen einschließlich Run und Death wird beim jeweiligen Klassen-Create geprüft; Run-/Death-Zustände werden nicht aktiv abgespielt.

Endgültiger Prozess: **Exitcode 0**, explizites Gesamtergebnis `passed: true`, Gesamtlaufzeit 36,767 s. Kein Runtime-Fehler im erfolgreichen Lauf.

Nachweise:

- `player-smoke-result.json`: maschinenlesbares Ergebnis.
- `player-smoke-runtime.log`: tatsächliche Step-Marker, Angriffs-/Schadensmeldungen, Gesamtergebnis und reguläres `game_end`.
- `player-smoke-build.log`: Compilerlog der isolierten Windows-EXE.
- Vollständiger Laufordner: `output/player-smoke/20261122-124938`.

Zwei frühere Smoke-Versuche wurden **nicht** als Erfolg gezählt: einmal Timeout durch einen falsch übergebenen lokalen Testzustand, einmal Exitcode 1 durch eine fehlerhafte Verzeichnisausgabe im Harness nach den Klassenprüfungen. Beide Harness-Fehler sind korrigiert; die obige Tabelle stammt ausschließlich aus dem danach regulär beendeten Lauf.

## Lokal wiederholen

Im Projektverzeichnis:

```powershell
python tests/tools/run_player_smoke.py
```

Benötigt die bereits lokal installierten GameMaker-Runtime/Lizenz und `gms_helpers`. Der Lauf baut in einen neuen isolierten Ordner, braucht normalerweise etwa eine Minute und prüft drei Klassen ohne zusätzlichen Agenten. Timeout, fehlendes explizites Ergebnis, fehlende Klasse, fehlgeschlagene Assertion oder Prozessfehler liefern Exitcode 1. Keine Änderung an Produktionsräumen oder Grafiken. Die Testinstrumentierung existiert nur in `output/player-smoke`, nicht im normalen Spiel.

## In dieser Korrektur geänderte Dateien

- `FirstGame.yyp`: Registrierung von `player_artpack`.
- `scripts/player_artpack/player_artpack.gml`, `scripts/player_artpack/player_artpack.yy`: neue gemeinsame validierte Initialisierung.
- `scripts/reset_round/reset_round.gml`: Initialisierung der gewählten Klasse beim Reset.
- `objects/ObjectPlayer/Create_0.gml`, `Step_0.gml`, `Draw_0.gml`.
- `objects/ObjectMonster/Create_0.gml`, `Step_0.gml`, `Draw_0.gml`.
- `objects/ObjectBossMonster/Create_0.gml`, `Step_0.gml`, `Draw_0.gml`.
- `objects/ObjectMainMenu/Draw_64.gml`, `objects/ObjectController/Draw_64.gml`, `objects/ObjectOverlay/Draw_64.gml`: Schutz der weiteren Größenabfragen.
- `tests/player_smoke_harness.gml`, `tests/tools/run_player_smoke.py`: dauerhafter kleiner Runtime-Test.
- `tests/tools/build_art_migration.py`: frisch erzeugte EXE/data.win statt bloß vorhandener Artefakte verlangen.
- `.gitignore`: isolierte Smoke-Builds ausschließen.
- Dieser Bericht, Smoke-Ergebnis/-Logs und die beim Build aktualisierten Build-Berichte.

Keine Sprite-, ArtPack- oder Room-Grafikdateien für diese Korrektur verändert. Die bereits vorgefundenen umfangreichen Grafikänderungen wurden nicht zurückgesetzt.
