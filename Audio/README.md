# FirstGame – Audio-Prototypen und Integration

Stand: 22.11.2026. **Aktuell vorhanden: 3 Musik-WAVs und 85 Effekt-WAVs**, vollständig als 88 GameMaker-Soundressourcen registriert. Boss-System 2.0 ergänzt 18 tatsächliche Synthese-Prototypen unter `Audio/Bosses/twins_1.wav` bis `twins_9.wav` und `swamp_1.wav` bis `swamp_9.wav`; Quelle `Audio/Sources/compose_boss_v2.py`. Der aktuelle Klassen-/Drachenumbau ergänzt 16 tatsächliche Synthese-Prototypen unter Weapons/Bosses; Quelle: Audio/Sources/compose_class_dragon.py. [Aktueller Bericht](../CLASS_DRAGON_REPORT.md). Zaubersystem 2.0 ergänzt 18 tatsächlich erzeugte Synthese-Prototypen: `Audio/Spells/skill_101.wav` bis `skill_118.wav`. Quelle: `Audio/Sources/compose_spell_v2.py`. Technische Validierung bestanden; Hörabnahme ausstehend. Die folgenden Abschnitte beschreiben außerdem die ursprünglichen 36 Audiodateien. Keine Originalmusik, Remixes, externen Samples, Downloads oder kostenpflichtigen APIs. Sämtliche Motive und Instrumente sind lokal im Kompositionsskript definiert.

## Qualität und verfügbare Werkzeuge

Verfügbar waren Python 3.10 und lokal installiertes NumPy. Die geprüften Programme FFmpeg, FluidSynth, TiMidity, SoX und Audacity waren nicht über PATH verfügbar; keine SoundFont-/MIDI-Renderpipeline oder Musikgenerierungs-API wurde verwendet. Es wurden keine zusätzlichen Pakete heruntergeladen.

Die Musik ist **mehrstimmige programmatische Chiptune-Prototyp-Musik**, kein professionell gesampelter oder fertig gemasterter SNES-Soundtrack. Eigene ausgeschriebene Motive, Akkordfolgen, Bassfiguren und Percussion werden mit FM-/Sinus-/Dreieck-ähnlichen additiven Stimmen, Glocken, Pads und kurzen Zupfklängen arrangiert. Die Stilrichtung ist melodisches, teils melancholisches 16-Bit-Fantasy-Abenteuer. Eine menschliche Hörabnahme steht aus; aus technischen Tests wird keine hohe musikalische Qualität abgeleitet.

## Musik

| Datei | Eigenständiger Titel | Tempo / Form | Länge | Einsatz |
|---|---|---|---|---|
| [menu.wav](Music/menu.wav) | Nebelarchiv | 80 BPM, 16 Takte | 48.00 s | Ruhiges, geheimnisvolles Titelmenü |
| [level.wav](Music/level.wav) | Windpfade | 112 BPM, 32 Takte | 68.57 s | Abenteuerlicher Level-Loop; derzeit für alle drei Levels |
| [boss.wav](Music/boss.wav) | Runensturm | 148 BPM, 32 Takte | 51.89 s | Schneller, gespannter Bosskampf-Loop |

Alle Musikdateien sind Stereo, 16-Bit-PCM, 32 kHz. Effekte sind Mono im selben PCM-Format. Die Takte schließen exakt am Loop-Ende; Delay-Tails werden zirkulär um die Loopgrenze gelegt statt durch Stille verlängert. Die Grenze wurde numerisch geprüft (maximale Nachbarsample-Abweichung unter 0,04 Full Scale). Das ist eine technische Kontinuitätsprüfung, keine vollständige Hörprüfung. OGG wurde mangels lokalem Konverter nicht erzeugt.

## Tatsächlich erzeugte Effekte und Ereignisse

| Quelldatei | Dauer | GameMaker-Ressource | Tatsächlicher Auslöser |
|---|---:|---|---|
| `UI/ui_hover.wav` | 0.075 s | `sfx_fg_ui_hover` | Nur Auswahlwechsel in Titel-, Pause- und Fähigkeitenmenüs; kein Frame-Dauerton. |
| `UI/ui_click.wav` | 0.130 s | `sfx_fg_ui_click` | Bestätigen und Einstellungen bedienen. |
| `UI/ui_back.wav` | 0.180 s | `sfx_fg_ui_back` | Escape/Zurück/Titelbildschirm. |
| `UI/character_select.wav` | 0.280 s | `sfx_fg_character_select` | Klassenwahl bestätigen. |
| `UI/game_start.wav` | 0.550 s | `sfx_fg_game_start` | Levelwahl / Rundenneustart. |
| `Weapons/sword_swing.wav` | 0.170 s | `sfx_fg_sword_swing` | Automatische Schwertattacke startet. |
| `Weapons/sword_hit.wav` | 0.120 s | `sfx_fg_sword_hit` | Tatsächlicher erstmaliger Sektortreffer am Gegner. |
| `Weapons/crossbow.wav` | 0.120 s | `sfx_fg_crossbow` | Armbrust erzeugt ihre Geschosse. |
| `Weapons/arrow_hit.wav` | 0.100 s | `sfx_fg_arrow_hit` | Ein Armbrustbolzen trifft tatsächlich ein Ziel. |
| `Spells/magic_projectile.wav` | 0.220 s | `sfx_fg_magic_projectile` | Stabgeschoss, arkaner Zauber, Blitz-Abschuss oder Heilimpuls wird ausgelöst. |
| `Spells/fireball.wav` | 0.280 s | `sfx_fg_fireball` | Feuerball wird tatsächlich abgefeuert. |
| `Spells/explosion.wav` | 0.480 s | `sfx_fg_explosion` | Feuerball explodiert oder Bosswurf schlägt ein. |
| `Spells/lightning.wav` | 0.190 s | `sfx_fg_lightning` | Blitz-Schock trifft bzw. angekündigter Bossblitz schlägt ein. |
| `Spells/ice.wav` | 0.300 s | `sfx_fg_ice` | Eisball/Frost-Nova und tatsächlicher Eis-Treffer. |
| `Enemies/player_hit.wav` | 0.240 s | `sfx_fg_player_hit` | Angenommener Spielerschaden, nicht bei geblocktem Treffer. |
| `Enemies/enemy_death.wav` | 0.230 s | `sfx_fg_enemy_death` | Normaler Gegner erreicht den Todespfad, nicht beim Aufräumen einer Runde. |
| `UI/coin.wav` | 0.160 s | `sfx_fg_coin` | Münzen-Kollisionsereignis, einmal vor Entfernung. |
| `UI/level_up.wav` | 0.720 s | `sfx_fg_level_up` | Münzschwelle wird überschritten, Level steigt. |
| `UI/spell_select.wav` | 0.300 s | `sfx_fg_spell_select` | Eine neue gültige Fähigkeit wird registriert. |
| `UI/spell_upgrade.wav` | 0.440 s | `sfx_fg_spell_upgrade` | Vorhandene Fähigkeit steigt tatsächlich im Level; nicht bei Maximallevel. |
| `Weapons/jump.wav` | 0.180 s | `sfx_fg_jump` | Beginn des Sprungs. |
| `Weapons/dodge.wav` | 0.160 s | `sfx_fg_dodge` | Beginn des Strg-Dodges. |
| `Weapons/slide.wav` | 0.260 s | `sfx_fg_slide` | Übergang von Landung/Dive in Slide. |
| `UI/game_over.wav` | 1.120 s | `sfx_fg_game_over` | Tödlicher tatsächlicher Spielerschaden; andere Effektstimmen werden beendet. |
| `Bosses/boss_spawn.wav` | 0.950 s | `sfx_fg_boss_spawn` | Geplanter oder expliziter Entwicklungs-Boss wird erfolgreich gespawnt. |
| `Bosses/boss_phase.wav` | 0.720 s | `sfx_fg_boss_phase` | Echter Übergang in Phase 2. |
| `Bosses/boss_defeated.wav` | 1.200 s | `sfx_fg_boss_defeated` | Einmaliger erfolgreicher Boss-Todes-/Belohnungspfad. |

## Zentrale Audioverwaltung

- `scripts/audio_manager/audio_manager.gml` besitzt alle Wiedergabe-Handles. Titelmenü, Level und Boss besitzen je eine Musikressource. Wiederholtes Setzen desselben Kontexts startet sie nicht erneut. Während des 0,65-s-Crossfades sind maximal zwei bewusste Musikstimmen aktiv; danach nur die aktuelle. Rasche Wechsel stoppen einen bereits abgelösten Vorgänger.
- Bei Pause/Level-up wird Musik auf 45 % ihrer eingestellten Lautstärke abgesenkt. Game Over blendet Musik aus; beim Titelbildschirm kehrt der Menü-Loop zurück. Nach Boss-Tod wechselt die Musik wieder zum Level.
- Vorhandenes `global.master_volume` bleibt der Gesamtregler. Zusätzliche Regler `global.music_volume` und `global.effects_volume` stehen sowohl in den Titel-Einstellungen als auch in den Runden-Einstellungen. Vorgaben: Master 100 % (sofern noch nicht vorhanden), Musik 65 %, Effekte 80 %. Werte bleiben über Rundenwechsel erhalten; wie bei den bisherigen Einstellungen gibt es keine neue dauerhafte Konfigurationsdatei.
- Höchstens 16 verwaltete Effektstimmen, 24 Audio-Kanäle insgesamt. Eine einzelne Effektart besitzt eine kurze Wiederholsperre (normal 70 ms, Hover 35 ms, Münze 55 ms, Explosion 140 ms). Wichtige Fortschritts-/Boss-/Game-Over-Effekte dürfen eine alte Effektstimme ersetzen; Hintergrundmusik bleibt geschützt. Mehrfachgeschosse und AOE erzeugen deshalb keine unbeschränkte Klanglawine.
- Effekte sind an Start-/Treffer-/Todes-/Zustandswechsel gekoppelt. Kein dauerndes Geräusch aus einem Draw-Event oder kontinuierlich pro Statusframe. Physische Treffer, Projektile, Progression, Bosszustände und Menüauswahl verwenden ihre bestehenden Ereignispfade.

## Quellen und erneute Erzeugung

```powershell
python Audio/Sources/compose.py
python Audio/Sources/import_sounds.py
python tests/tools/validate_audio.py
python tests/tools/run_gameplay_smoke.py
python tests/tools/build_production.py
```

`compose.py` benötigt das bereits lokal vorhandene NumPy. Es ist die editierbare, kanonische Kompositions-/Synthesequelle: Motive, Rhythmen, Akkordfolgen, BPM, Instrumente, Mix und Effekte können dort geändert werden. Die erzeugten `*.score.json` enthalten die vollständigen Notenereignisse zur Inspektion/Weiterverarbeitung; Änderungen daran werden beim erneuten Komponieren überschrieben.

`Audio/manifest.json` enthält Ressourcenname, Format, Dauer, Pegel, Loopdaten und SHA-256 jeder Datei. `sounds/<Ressource>/` enthält die tatsächlich importierte WAV-Kopie und native `.yy`-Metadaten. Die Ordner `Audio/Music`, `Audio/UI`, `Audio/Weapons`, `Audio/Spells`, `Audio/Enemies`, `Audio/Bosses` sind zusätzlich in GameMakers Assetbrowser angelegt. Bestehende Grafik-/Gameplayressourcen wurden nicht entfernt.

## Ausgeführte Prüfungen

- **PASS:** 30 reale, nicht leere WAV-Dateien; korrekte PCM-Header, 32 kHz / 16 Bit, Kanalanzahl und Framezahl. Kein digital geclippter Dateipegel; geprüfte importierte Kopien sind bytegleich. Musik-Looplänge stimmt bis auf höchstens ein Sample mit BPM/Taktzahl überein. Bericht: `tests/reports/audio-files.json`.
- **PASS:** GameMaker-Projektintegrität, 281 Ressourcen / 44 Ordner, keine Probleme oder Warnungen; 30 native Soundressourcen.
- **PASS:** 3.448 Runtime-Assertions im echten Windows-Runner, einschließlich vorhandener Gameplay-/Bossregression und Audio-Fixture. Alle 27 Effekte besitzen positive Soundlänge und erzeugen aktive Playback-Handles. Echte Münz-, Gegner-Todes-, Fernkampf-/Treffer- und Game-Over-Pfade lösen Audioanforderungen aus.
- **PASS:** Gleichbleibende Menüauswahl erzeugt keine Hoveranforderung, Auswahlwechsel schon. Derselbe Musikkontext erzeugt keine zweite Musikinstanz. Echter Boss-Spawn wählt Bossmusik, echter Boss-Tod Levelmusik. Rasche Kontextwechsel beenden überholte Musik; der Crossfade endet mit einer Musikstimme. Musik-/Effektgain und Pause-Ducking wurden über die Audio-API nachgemessen.
- **PASS mit Grenze:** Während der Wiederholfixture überschritt die erfasste Effektliste nie 16 Stimmen. In der stummen Testsession wurden tatsächlich maximal 1 gleichzeitige Effektstimme beobachtet, weil die Engine Stimmen freigibt/virtualisiert; dies ist kein Nachweis eines hörbaren 16-Stimmen-Stressmixes. Die Begrenzungs-/Prioritätslogik bleibt zentral implementiert.
- **PASS:** normaler Windows-Build ohne Testhooks und ZIP-Paketierung, Igor-Endcode 0. `tests/reports/production-build.json` nennt den aktuellen Build.
- **NOT RUN:** menschliche Hör-/Lautsprecherprüfung, Mix auf unterschiedlichen Geräten, subjektive Kompositionsbewertung, eine komplette 30-Minuten-Hörsession und ein vollständig abgespielter 69-Sekunden-Runtime-Loop. Tests laufen mit stummem Masterausgang und prüfen die API und Daten, nicht das subjektive Hörergebnis.

## Was noch bessere Dateien benötigt

Die drei Musikstücke sollten nach einer Hörprobe weiter arrangiert, mit hochwertigeren eigenen Sample-Instrumenten/Synth-Patches ausgearbeitet und gemastert werden. Vor allem Langzeit-Abwechslung im Level, Instrumentenbalance und Boss-Dynamik sind Prototypenarbeit. Die 27 Effekte decken alle angefragten Kategorien ab; sie sind funktionale eigene Syntheseeffekte und sollten anschließend im hörbaren Kampf auf Verständlichkeit, Spitzen und Ermüdung abgestimmt werden. Eine künftige OGG-Konvertierung kann die Musikgröße reduzieren. Aktuell fehlen keine angefragten Effekttypen und keine der drei Musikdateien.

## Aktueller normaler Build

- EXE: `output/production-build/20261122-151253/game/FirstGame.exe`
- ZIP: `output/production-build/20261122-151253/FirstGame.zip`

Keine kostenpflichtigen APIs, keine heruntergeladene Originalmusik, keine KI-QA-Subagents und kein automatischer Git-Push.

## Hintergrundton und Fokus

„Ton im Hintergrund abspielen“ ist standardmäßig aus und wird unter Audio/background in firstgame_audio.ini gespeichert. Bei Fokusverlust wird nur die effektive Master-Ausgabe stummgeschaltet. Tracks laufen mit unveränderter Instanz weiter; Musik- und Effektlautstärken bleiben erhalten. Technische Tests siehe ../SURVIVOR_REPORT.md.

Sechs zusätzliche Kampf-Cues: `magic_hit`, `ice_hit`, `arcane_hit`, `nova_cast`, `heal_cast`, `shock_hit`. Editierbare Synthese: `Sources/compose_combat_cues.py`. Auch diese Klänge sind eigene programmatische Prototypen. Alle 36 Dateien bestehen die Format- und Ressourcenprüfung; subjektive Hörabnahme offen.
