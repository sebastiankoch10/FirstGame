# Level-Erweiterung – Fortschritt und Übergabe

Stand: 24.11.2026. Auftrag: zwei neue spielbare Welten (Verfluchter Sumpf, Aschenfrost-Ruinen). Bossmechaniken bleiben laut Auftrag unverändert; die Bosskampf-Philosophie liegt verbindlich in `DESIGN/BOSS_DESIGN.md`.

## Sicherung

Vor der ersten Änderung: `output/level-expansion-backup/pre-level-expansion-20261123-232806.zip` (scripts, objects, rooms, sprites, sounds, tilesets, options, datafiles, FirstGame.yyp). Kein Git-Commit, kein Push.

## Status je Meilenstein

| Meilenstein | Status |
|---|---|
| 1 Analyse und gemeinsame Architektur | erledigt |
| 2 Sumpf spielbar | erledigt, native Tests PASS |
| 3 Sumpf ausarbeiten | erledigt: Pflanzen, Moos, Steine, Seerosen, Ambient-Loop |
| 4 Ruinen spielbar | erledigt, native Tests PASS |
| 5 Ruinen ausarbeiten | weitgehend erledigt (siehe offene Punkte) |
| 6 Qualitätskontrolle | Levelsuite 166/166 PASS, bestehende Regression 811/811 PASS, Produktions-Build PASS |
| 7 Verfeinerung | Funken über Feuerschalen, native Vorschaubilder, dichtere Ruinen-Details, Ambient-Prüfung |

## Architektur

- **`scripts/level_worlds`:** zentrale Leveldefinitionen. Enthält:
  - Name, Raum (mit Fallback), Vorschau, Tagline, Beschreibung, Palette
  - Schwierigkeitsfaktoren (unverändert 1 / 0,9+1,1 / 1,25+1,15)
  - Wetter, Umgebungslicht-Grenzen, Laubfarben, Musik, Ambient-Loop, Bossgewichte
  - Gegnerdefinitionen und zeitabhängige Gegnerzusammensetzung
  - Levelauswahl-Panel

  Der Wald behält seinen eigenen Renderer und seine Spawn-Regeln unverändert.
- **`scripts/level_world` + `ObjectLevelWorld` / `ObjectLevelProp`:** Laufzeit der generierten Welten. Umfasst:
  - 64 gebackene 512er-Boden-Chunks, Kamera-Culling (sichtbare Requisiten werden gezeichnet)
  - Kollisionsraster (256er-Zellen, Ellipsen-Fußabdrücke passend zur 40°-Ansicht)
  - Gefahren: dauerhaft (Gift, Schlamm, Eis) bzw. zyklisch mit dezentem Uhrzeiger-Countdown (Sporen, Glut, Energiespalten)
  - Sporenstöße sterbender Pilzkreaturen
  - Wasserringe und Blasen, Frostglitzern, Glühwürmchen und Funken, Asche und Schnee
  - Lichtquellen (zusammen max. 26), additive Glow-Halos
  - Verdeckungs-Fade großer Requisiten, Minikarte mit Landmarken, Ambient-Loop
- **Generierung:** `tests/tools/levels/`. Bestandteile:
  - eigener SDF-Pixel-Renderer `pixsdf.py`
  - Levelmodule `swamp.py` und `ashfrost.py` mit Requisiten, Layout und Gefahren
  - Bodenbacken `swamp_ground.py` und `ashfrost_ground.py`
  - Gegner `enemies.py`, Ambient-Synthese `ambience.py`, Projekt-Registrierung `gm_project.py`

  Alles ist deterministisch (feste Seeds).

## Inhalte

### Verfluchter Sumpf (RoomSwamp)

- **1.428 Requisiten aus 37 Sprites:**
  - Totbäume (3 Varianten + 2 uralte Riesen)
  - Stümpfe, Baumstämme, Wurzeln, Moosfelsen
  - Blattstauden, Farne, Schilf
  - Leuchtpilze (grün/türkis), Laternen
  - versunkene Mauern, Statuen, Säulen, Grabsteine
  - Schrein, Holzbrücke, Holzstege
- **8 Landmarken:** Uralter Totbaum ×2, Verfallener Schrein ×2, Überwucherter Friedhof, Halb versunkene Ruine ×2, Eingestürzte Holzbrücke über einem Wasserkanal.
- **Boden:** Erde mit Klumpen, Moospolster, Laub, Schlammpfade mit Pfützen, nasse Ufer mit sichtbaren Uferkanten, flaches und tiefes Wasser, Algen, Seerosen, Kiesel, Zweige, Schädel.
- **29 Gefahren:** 11 Gifttümpel (Schaden im Stand, Springen schützt), 10 Schlammfelder (76 % Bodentempo), 8 Sporenfelder (1,0 s Countdown, 0,35 s aktiv).
- **Gegner:** Sumpfkriecher (schnell, Zickzack, Rudel), Sumpfskelett (langsamer, zäher), Pilzkreatur (Sporenstoß beim Tod), Versunkener Ritter (langsam, schwerer Treffer).
- **Atmosphäre:** grünliches Dämmerlicht, Nebel, Regenphasen, Glühwürmchen, Gaspulse, Ambient-Loop.

### Aschenfrost-Ruinen (RoomAshfrost)

- **957 Requisiten aus 28 Sprites:**
  - Säulen, Säulenstümpfe, umgestürzte Säulen, Arkade
  - Mauern mit Fensterbogen, Ritterstatuen (ganz/zerbrochen), Treppen
  - Kristallgruppen (türkis/violett/glut), Eisspitzen
  - magische Feuerschalen (blau/orange), Marktstände, Obelisken mit Runen, Trümmer, gefrorene Totbäume
  - Kathedralenfront, eingestürzter Turm, Ritualkreis
- **8 Landmarken:** Verfallene Kathedrale, Eingestürzter Turm ×2, Kristallhain ×2, Platz der Statuen, Verlassener Marktplatz, Alter Ritualkreis.
- **Boden:** Die Bereiche wechseln organisch statt hälftig: unregelmäßige Steinplatten, Pflaster auf Plätzen und Straßen, Schnee (zuerst in den Fugen), Eis, Asche mit vereinzelten Glutspalten, Trümmer.
- **28 Gefahren:** 10 Glutschlote (zyklisch), 10 magische Eisflächen (84 % Bodentempo), 8 Energiespalten (Linien, 1,1 s Countdown).
- **Gegner:** Aschenkrieger (schnell), Verfluchte Rüstung (schwer), Eisgeist (schwebt über Hindernisse, weite Bögen), Magisches Konstrukt (langsam, Bodenschlag im Ring).
- **Atmosphäre:** kaltes Blaulicht mit warmen Impulsen, Asche und Schnee, Funken, Kristallglitzern, Ambient-Loop.

### Levelauswahl, Musik, Bosse

- **Levelauswahl:** Verzauberter Wald, Verfluchter Sumpf, Aschenfrost-Ruinen. Die Vorschaubilder sind **echte native Spielaufnahmen**: Sumpf am Schrein, Ruinen am Statuenplatz, Wald am Start.
- **Musik:** `mus_fg_level_swamp` und `mus_fg_level_ruins` sind vorbereitet. Solange sie fehlen, wird `mus_fg_level` verwendet. Es wurde keine Musik erfunden.
- **Ambient-Loops:** eigene Syntheseprototypen (`Audio/Ambience/`), an die Effektlautstärke gekoppelt. Eine menschliche Hörabnahme steht noch aus.
- **Bosse:** Die Zufallsauswahl bleibt erhalten. Im Sumpf ist der Behemoth doppelt gewichtet, in den Ruinen die Hexen. Freischaltung 3/6/9 ist unverändert und auf allen drei Leveln nativ geprüft.

## Gefundene und behobene Fehler

1. **Bestehender Fehler:** Skriptname `master_skeleton` und gleichnamige Instanzvariable kollidierten. `if(master_skeleton)` war außerhalb von Room1 immer wahr, sodass alle Gegner dort die Skelett-KI liefen. Jetzt steht dort `self.master_skeleton`; im Wald ist das Verhalten identisch.
2. **Eigener Fehler:** Angriffs-Auslösedistanz größer als die Trefferreichweite; stehende Spieler wurden nie getroffen. Die Auslösung liegt jetzt knapp unter der Reichweite.
3. **Eigener Fehler:** neue Skripte nicht im `.yyp` registriert. Der Build lief durch, erst der Laufzeittest hat es gefunden.
4. **Eigene Grafikfehler:** Konturpixel am oberen Bildrand durch `np.roll`-Umlauf; Stempel-Renderings außerhalb der Leinwand; überladene Glutrisse; zu helle Schneefelder. Alle behoben.

## Tests (ehrlich)

| Test | Ergebnis |
|---|---|
| `tests/tools/levels/compile_check.py` (echter Igor-Build) | PASS |
| `tests/tools/run_level_smoke.py` (nativ, injizierte Eingaben, 3 Level) | **PASS 166/166** |
| `QA/tools/run_qa_regression.py` (bestehende Codex-Regression) | **PASS 811/811** |
| `tests/tools/run_combat_smoke.py` (bestehend, veraltet) | **FAIL, bereits im Ausgangsstand.** Er bricht mit identischer Exception in `v2_passive_behaviour` ab, auch gegen das unveränderte Backup (Prüfkopie am 2026-11-24 wieder gelöscht). Der Test erwartet ein sofortiges Mage-Projektil; seit der Klassenwaffen-Überarbeitung feuert die Waffe verzögert. Nicht Teil dieses Auftrags, unverändert gelassen. |
| `tests/tools/build_production.py` | **PASS** (ohne Test-Hooks). Das ZIP wurde danach gelöscht: Der Nutzer testet direkt mit F5 in der IDE. Gegenprobe 2026-11-24: Ein Build des echten Projekts zeigt nach „Neues Spiel“ und Charakterwahl die neue Levelauswahl, und der Sumpf startet. |
| Menschlicher Spieltest | NOT RUN |
| Langzeit-Performance über 30 Minuten | NOT RUN |
| Hörabnahme Ambient | NOT RUN |

Was die Levelsuite je Level prüft:
- Menüablauf, eigener Raum, frischer Rundenzustand, Musik
- Welt bereit, Requisiten, Gefahren, 64 Chunks, freier Start
- WASD, Blockade durch Requisiten, natürlicher Spawn nur aus dem eigenen Pool
- jeder Gegnertyp einzeln: Verfolgung, eigenes Sprite-Set, angekündigter Treffer, Schaden, Tod, Kill, XP, Todesanimation, Sporenstoß
- Gifttümpel bzw. Glutschlot, Verlangsamung, Countdown vor Schaden bei zyklischen Gefahren
- Level-up, Pause, Bosse bei Minute 5/10/15 mit 3/6/9 Fähigkeiten, 80 Gegner bei Minute 10
- Tod, Neustart ohne Duplikate, Menü ohne Reste

Zusätzlich: Die Ambient-Schleife startet und stoppt beim Verlassen. Aufnahmen: `%LOCALAPPDATA%/FirstGame-Tests/level-smoke/<stamp>/*.png`; der ursprüngliche Lauf lag noch unter `output/` und ist gelöscht (Start, Vorschau, Gegner, Gefahr, Countdown, Boss 5/15, Masse Minute 10, Levelauswahl).

**Performance (nativ, 80 Gegner bei Minute 10):** mittlere Framezeit Wald 17,6 ms, Sumpf 17,1 ms, Ruinen 17,1 ms. Einzelne Spitzen von 100–345 ms treten auf allen Leveln auf, auch im unveränderten Wald (vermutlich das erste Laden von Texturen). Die Texturgruppe des Levels wird beim Start vorgeladen.

## Bewusste Grenzen

- **Grafikherkunft:** Es gab keinen Bildgenerator. Alle neuen Grafiken sind prozedural erzeugt (SDF-Renderer, Paletten, Dithering, Konturen). Die vier humanoiden Gegner sind Material-Varianten des vorhandenen Meister-Skeletts (eigene Paletten, Moos, Rost, Glut, violettes Glühen, verbreiterte Silhouetten), keine neu gezeichneten Figuren. Die Qualität ist konsistent, erreicht aber nicht überall die handgemalte Dichte der KI-generierten Waldrequisiten.
- **Weltgröße:** fest 4096 × 4096 wie der Wald, keine endlose Welt.
- **Wasser:** ist begehbar und nur Atmosphäre; Schaden verursacht ausschließlich Gift. Es gibt keine Wat-Animation des Spielers.
- **Alte Räume:** RoomCrypt und RoomRuins bleiben unverändert im Projekt (nur noch Fallback, nicht gelöscht).

## Reproduzieren

```
python tests/tools/levels/build_level.py swamp        # oder ashfrost; --skip-props / --skip-ground möglich
python tests/tools/levels/build_enemies.py
python tests/tools/levels/ambience.py
python tests/tools/levels/compile_check.py
python tests/tools/run_level_smoke.py
python tests/tools/levels/update_previews.py          # native Vorschauen aus dem letzten Smoke-Lauf
```

## Nächste konkrete Schritte

1. Den veralteten Test `tests/spell_v2_harness.gml` (`v2_passive_behaviour`) an die verzögerte Klassenwaffe anpassen; separater Auftrag.
2. Optional: animierte Flammen und Funken über Feuerschalen, Wat-Spritzer im Wasser, mehr gezeichnete Zwischenframes für die Kreaturen.
3. Menschlicher Spieltest beider Welten über 15–30 Minuten.
