# Gameplay-Überarbeitung – Abschlussbericht

Aktueller Grafik-, Boss-, Kontakt- und XP-Stand: [ATMOSPHERE_REPORT.md](ATMOSPHERE_REPORT.md). Ältere abweichende Balancewerte unten sind historisch.
> Historischer Bericht zum vorherigen Auftrag. Startauswahl und manuelle Zauber wurden inzwischen ersetzt. Der aktuelle Stand steht in **BOSS_IMPLEMENTATION_REPORT.md**, **SPELL_CATALOG.md** und **BOSS_CATALOG.md**.

Stand 22.11.2026. Änderungen sind im bestehenden Projekt implementiert. Keine KI-Subagents, keine kostenpflichtigen APIs, kein Git-Push, keine Neugestaltung der drei Levels.

## Umsetzung nach Auftrag

| Punkte | Stand der Implementierung |
|---|---|
| 1–2 Hauptmenü und Charakterauswahl | Umgesetzt: Neues Spiel → Charakter → Level → richtiger Raum; direkte Levelauswahl entfernt. Obere Bildleiste entfernt, Namensauswahl mit Hover/Markierung und großem rechten Portrait bleibt. Beschreibungsbereich überschneidet das Portrait nicht mehr. |
| 3–5 Waffen, Startfähigkeit, Autoangriff, Mausbewegung | Umgesetzt: Schwert/Stab/Armbrust unabhängig von Zauberslots und -cooldowns. Start mit sechs leeren aktiven Slots und aktiver Erstauswahl. Automatische Suche nach nächstem lebendem Gegner/Boss in Waffenreichweite. WASD/Pfeile haben Vorrang vor gehaltener linker Maustaste; keine Geschwindigkeitsaddition; 12-Pixel-Stoppzone. Nach Menüs ist für Mausbewegung eine Freigabe der Taste nötig; ein kurzer Eingabeschutz verhindert den Sprung durch die Bestätigungstaste. |
| 6–8 Hitboxen, Schwert und Lebensbalken | Umgesetzt: schmale stabile Körpermaske statt animierender 64-Pixel-Frames. Zusätzliche Kontaktprüfung mit Radien 10/11/24 px (Spieler/Monster/Boss), 30 Schritte Schadensimmunität nach einem Treffer. Schwertsektor 92 px, ±58 Grad, größerer zusätzlicher Bogen; pro Schlag/Ziel ein Treffer. Held sichtbar auf 1,65 skaliert, Maske bleibt unvergrößert. Einheitlicher Gegnerbalken, größerer Bossbalken, Spieler-HP im HUD statt danebenliegendem World-Balken. |
| 9 Einstellungen und Game Over | Umgesetzt: Vollbild/Lautstärke erhalten, sichtbare Titel-Schaltfläche im Titel- und Runden-Einstellungsmenü, Rückkehr aus Runden-Einstellungen zur pausierten Runde. Game Over mit Maus-/Tastaturbuttons für Neustart und Hauptmenü, sauberem Reset. |
| 10–12 Statusgrafik, Power Up, Feuerball-AOE | Umgesetzt: je Status bis drei kleine prozedurale Pixelpartikel pro Gegner; Flammen orange, Eis hellblau, Schock gelb. Sichtbarkeit hängt direkt am Statuszähler. Lightning gibt nun explizit 20 % Schock-Slow für 24 Schritte; im Tooltip angegeben. Power Up beschreibt additive Waffen-/Zauber-/Heilboni mit konkreten Werten. Fireball explodiert mit Radius 64 +4/Stufe; einmaliger Schaden je Gegner/Boss im Radius plus Brennen und sichtbarer Explosion. |
| 13–14 Dodge, Sprung und Slide | Umgesetzt: Strg-Dodge 10 Schritte ×8,5 px, 90 Schritte eigener Cooldown. Sprung/Dive/Slide und tatsächlicher Dodge schützen vor Kontakt. Keine nachträglich fortbestehenden Bewegungs-Iframes; Schutz wird aus dem aktuellen Zustand abgeleitet. Nach Slide 50 Schritte Mobilitätspause, nach Dodge mindestens 35; Zustände lassen sich nicht beliebig geschützt verketten. Angriffe sind von ihnen unabhängig. |
| 15 Gegnerverfolgung | Umgesetzt: etwas höhere Basisgeschwindigkeiten 1,05 normal /1,55 schnell /0,8 Tank /1,1 Boss; gedämpfte Verfolgungsvektoren und lokale, begrenzte Separation statt harter globaler Verschiebungen. Spawner aktualisiert tatsächliche Basisgeschwindigkeit korrekt. Gameplaygefühl/Maximalmengen-Performance braucht weiteren manuellen Spieltest. |
| 16 Fähigkeitenpool | Umgesetzt: sechs aktive und sechs passive Fähigkeiten. Ergänzt: Frost Nova, Arcane Barrage, Healing Pulse sowie Quick Hands, Vitality, Split Runes. Alle mit vorhandenen Icons, zentralen Werten, Tooltip, Wirkung und Upgrades. Maximal sechs Slots pro Typ bleiben erhalten. |
| 17 Waffen-Upgrades | Wie angefordert NICHT implementiert. Eigene Waffendefinitionen und Laufzeitwerte sind getrennt vorbereitet; Idee und mögliche Upgradeachsen im Katalog dokumentiert. |
| 18–20 Stabilität, Test und Bericht | Build und gezielte lokale Runtime-Tests ausgeführt; siehe unten. Keine behaupteten manuellen Langzeit-/OS-E2E-Tests. |

## Tatsächlich ausgeführte Prüfungen

**PASS: 3.191 Assertions**, echte lokale Windows-VM aus einer frisch gebauten isolierten Projektkopie; Prozessende 0. Ergebnis und konkrete Artefaktpfade: [gameplay-smoke-result.json](tests/reports/gameplay-smoke-result.json).

- Alle neun Charakter-Level-Kombinationen wechseln über die produktiven Menüaktionen nach Room1 / RoomCrypt / RoomRuins. Charakterwahl, Levelwahl, richtige Klassenwaffe, leere Startslots, aktive Erstangebote und tatsächliche Registrierung durch den Controller-Bestätigungspfad geprüft.
- Auto-Waffen reduzieren echte Gegner-HP am Boden, bei Aufstieg, Fall, Dive, Slide und Dodge; Fernkampfgeschosse bewegen sich über tatsächliche Projektile-Steps bis zum Treffer. Wiederholter unmittelbarer Waffenaufruf bleibt durch den Cooldown gesperrt.
- Bewegung: Tastaturtempo, gehaltene Maus, Maus-Stoppzone, Loslassen, Tastaturvorrang, Sperre nach Menü. Native Player-Steps für Sprung/Landung/Slide und Dodge, tatsächliche Kontaktschadensblockade während Schutz, wieder erlaubter Schaden danach, gleicher Frame ohne Doppelschaden, kein Schaden aus 45 Pixel Abstand, Dodge-Cooldown.
- Alle zwölf Fähigkeiten registrieren/verbessern sich auf L1–9, Maximalgrenzen, sechs aktive plus sechs passive Einträge, vollständige Hotbar, gültige Icons und berechnete Tooltiptexte. Kombinierte Passivwerte und idempotente Anwendung einschließlich Vitality; Haste verändert das echte Waffenintervall, Split Runes die tatsächliche Fernkampfwaffen-Projektilanzahl.
- Fireball: mehrere normale Gegner und Boss nehmen je einmal denselben berechneten Explosionsschaden; entferntes Ziel bleibt unversehrt, alle betroffenen Ziele brennen. Iceball, Nova, Lightning, Barrage und Heilung messen wirkliche Wirkung/HP. Ablauf von Slow, Schock und Brennen geprüft; 60 Schritte Brennen reduzieren HP exakt um 1.
- Game-Over-Neustart und Rückkehr zum Hauptmenü wurden über den echten Maus-Hit-Test mit deterministisch eingespeisten Eingabewerten geprüft. Einstellungsmenü aus laufender Runde, Lautstärkeänderung, Rückkehr zur Pause und Fortsetzen geprüft.
- Charakterauswahl, Kampf einschließlich Slash/Status/Balken und Game Over als 800×600-Bilder über echte Draw-Funktionen gerendert und visuell geprüft. Dabei gefundene Text-/Portrait- und Cooldown-/Passivslot-Überlappungen behoben.
- GameMaker-Projektprüfung: PASS, 248 Ressourcen, keine Probleme oder Warnungen. Ein normaler Produktions-Build erzeugte ebenfalls frische ausführbare VM-Dateien. Dessen zusätzlicher ZIP-Paketierungsschritt meldete einen gesperrten vorhandenen Cache; die aktuellen isolierten Testbuilds werden in jeweils frischen Verzeichnissen gebaut und erfolgreich ausgeführt.

Tests verwenden keine Produktions-Testschalter. `tests/tools/run_gameplay_smoke.py` kopiert das Projekt und ersetzt Eingabeleser ausschließlich in dieser Kopie. Die frühere Spielerversion mit Klickangriffen wurde nicht als aktueller Test weiterverwendet: alte Einstiegsnamen verweisen auf die neue Suite, ursprüngliche Animationsfixture ist explizit als Legacy erhalten. Historische ältere JSON-Berichte sind keine Ergebnisse der aktuellen Version.

## Teilweise verifiziert / noch offen

- **NOT RUN:** manueller kompletter Durchlauf mit echten OS-Maus-/Tastaturereignissen, alle Portraits/Tooltipvarianten und andere GUI-Auflösungen. Die neun Raumwechsel und Game-Over-Aktionen wurden im Runner ausgeführt, mit Testeingaben bzw. Menüaktionsaufrufen.
- **NOT RUN:** Langzeitspiel, maximale Gegnermenge, finales Balancing und subjektives Kiting-/Waffengefühl. Die neue Verfolgung ist implementiert; ihre Langzeit-Performance ist nicht behauptet.
- **NOT RUN:** Vollbildwechsel in der Testsession; die vorhandene `window_set_fullscreen`-Funktion bleibt angebunden. Lautstärke wurde tatsächlich geändert.
- **NOT RUN:** jede Effekt-/Waffen-/Passivkombination auf jeder einzelnen Stufe gegen jeden Gegnertyp. L1–9-Registrierung/Upgrade/Tooltip wurde für alle Fähigkeiten geprüft; gesonderte neue Effektmessungen erfolgen überwiegend auf L9. Orbit-Einzelschaden/Defensivbonus sind aus dem vorherigen Auftrag bekannt und hier nicht erneut separat gemessen.
- Bekannte technische Grenze: Die Pixelschrift zeigt deutsche Sonderzeichen nicht vollständig. UI-Texte verwenden deshalb ae/oe/ue/ss. Stab/Lightning/Barrage verwenden passend getönte vorhandene ArtPack-Geschosse; ein eigenes neues Blitz- oder Waffen-Artset wurde nicht erzeugt.
- Waffen-Upgrades sind bewusst zukünftige Arbeit. Keine weiteren unimplementierten Pflichtmechaniken bekannt; die genannten Verifikations- und Balancingpunkte bleiben offen.

## Wesentlich geänderte Dateien

- `scripts/gameplay/gameplay.gml` / `.yy`, `FirstGame.yyp`: eigene Waffen, Zielsuche, Kontakt/Schutzregeln, Effekte, Gegnerbewegung und gemeinsame Menüaktionen; neue Skriptressource registriert.
- `objects/ObjectMainMenu/{Step_0,Draw_64}.gml`, `objects/ObjectController/{Create_0,Step_0,Draw_64}.gml`: Menüfolge, erste Auswahl, Pause/Einstellungen/Game Over.
- `objects/ObjectPlayer/{Create_0,Step_0,Draw_0,Collision_ObjectMonster,Collision_ObjectBossMonster}.gml`, `scripts/player_artpack/player_artpack.gml`, `scripts/reset_round/reset_round.gml`: Eingaben, Bewegung, unabhängige Angriffe, Masken und Reset.
- `objects/ObjectSwordHitbox/*.gml`, Monster-/Boss-Create/Step/Draw, Spawner-Step: Schlagsektor/Anzeige, Verfolgung, Kontaktkörper, einheitliche Balken und Statuspartikel.
- `scripts/{spell,get_spell_data,cast_spell,apply_passives,handle_chest_selection}/*.gml`, Projektil-Create/Draw und Overlay: 6+6-Fähigkeiten, AOE, Boni, HUD und Werteanzeigen.
- `tests/gameplay_harness.gml`, `tests/tools/run_gameplay_smoke.py`, Kompatibilitätseinstiege, `SPELL_CATALOG.md`, dieser Bericht und `.gitignore`: wiederholbarer Test, Dokumentation, generierte Testkopien vom Git-Status ausgeschlossen.
