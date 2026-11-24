# Automatische Zauber, HUD und Boss-Framework – Abschlussbericht

Aktueller Grafik-, Boss-, Kontakt- und XP-Stand: [ATMOSPHERE_REPORT.md](ATMOSPHERE_REPORT.md). Ältere abweichende Balancewerte unten sind historisch.
> Audio wurde anschließend ergänzt. Aktueller Audio-Stand, Build und Testgrenzen: [Audio/README.md](Audio/README.md).

Stand: 22.11.2026. Aktueller Stand nach dem HUD-/Boss-Auftrag; ersetzt die abweichenden Aussagen des historischen `GAMEPLAY_REPORT.md` zu Startauswahl und manuellen Zaubern.

## Abschnitt A – implementiert

- **Spieler-HP:** eigener roter Lebensbalken mit tatsächlichen aktuellen/maximalen HP, sofortiger Änderung, kurzem goldenen Schadensnachlauf und Trefferrahmen. Der alte Textblock oben rechts mit Waffenstatus ist entfernt. Die Anzeige liest echte HP, keine Kopie als Schadensquelle.
- **Level/Münzen:** kompakter gemeinsamer Bereich links oben, Fortschrittsbalken zum nächsten Münz-Level-up. Aktive/passive Slots sind zwei kleine Reihen am unteren Rand; die Spielfläche bleibt weitgehend frei.
- **Autozauber:** alle sechs vorhandenen aktiven Fähigkeiten unabhängig von Klasse und Bewegung. Projektilzauber wählen erreichbare Ziele, Fireball bewertet Gruppen, Nova benötigt ein Ziel im Radius, Heilung benötigt ein sinnvolles HP-Defizit. Eigener Cooldown je Eintrag; keine Zaubertasten. Pause, Menüs, Game Over und fehlende Ziele verbrauchen keine Casts.
- **Radiale Cooldowns:** dunkler, quadratisch begrenzter Icon-Wipe; Freigabe im Uhrzeigersinn ab zwölf Uhr, aus dem echten Cooldownwert berechnet. Kurzer Bereitschaftsrahmen nach Ablauf. Keine permanenten Sekunden-/Tastenblöcke; passive Slots ohne künstliche Cooldowns.
- **Krieger:** 40 freigegebene Richtungs-/Aktionsressourcen auf Fußursprung 32/51 geprüft. Zehn linke Zustände verwenden jetzt gespiegelt die kanonischen rechten Zustände; beide Seiten erhalten denselben Größenabgleich 1,10. Nicht proportionale Bewegungsdehnung ist beim Krieger deaktiviert, Masken bleiben stabil. Magierdesign unverändert. Bestehende ArtPack-Frames bleiben erhalten, keine alten Grafiken als Fallback.
- **Schwert:** Reichweite 92 Pixel und Sektor ±58 Grad unverändert; die zusätzliche Darstellung ist ein abgestufter eisblau-weißer Schlagbogen mit wandernder heller Klinge statt Drahtgitter-Fächer.
- **Progression:** sofortige zusätzliche Startauswahl entfernt. Neue Runden beginnen unmittelbar mit Klassenwaffe und leeren sechs aktiven/sechs passiven Slots. Erst der reguläre Münz-Level-up öffnet die erste Auswahl; spätere Truhen bleiben Teil der Progression.

## Abschnitte B/C – implementiert

Zentrales, pausierbares Boss-Framework mit Einmal-Spawnmarkern, zwei Minibossen bei 1:00/3:00 und Hauptboss-Slots bei 5:00 bis 30:00. Alte fest platzierte Boss- und Feuerball-Testinstanzen aus allen drei Spielräumen entfernt, damit sie die Planung nicht umgehen. Levelgrafik und übrige funktionierende Systeme bleiben erhalten.

Der **Sturmhüter bei Minute fünf ist als vollständiger Komponenten-Boss spielbar**: Intro, feste Phase-1-Rotation, verzögerte Blitze mit exakten Warnkreisen, eskalierende Fächer, getrennte Boden-/Höhendarstellung des Wurfs, zweite Phase unter 50 % mit sichtbarem Übergang, erweiterter Rotation und Ring mit sicherer Gasse. Bossname, HP, Phase und aktuelle Ansage liegen im eigenen HUD. Tod beendet Gefahren und vergibt Münzen plus Truhe einmalig.

Normale Gegnergruppen bleiben erhalten; während eines Bosses reduziert der Spawner ihre Nachschubrate. Alle gegnerischen Treffer verwenden dieselben Schutz-/Schadensregeln. Begrenzte Struct-Arrays verwalten feindliche Geschosse/Zonen ohne unnötige Einzelinstanzen. Der optierte Entwicklungsmodus erlaubt direkte Bosswahl, Phase, HP-Anteil, einzelne Muster, Slowdown und Fehlerlogs. Details: `BOSS_CATALOG.md`.

## Abschnitt D – ausdrücklich teilweise / offen

Bei Minute 10/15/20/25/30 existieren eindeutige, skalierte und spawnfähige Framework-Prototypen mit den wiederverwendbaren Angriffen. Sie sind **keine fünf fertig gestalteten individuellen Hauptbosse**. Eigene Rotationen, neue Mechaniken, individuelles Artwork, finales Schwierigkeitstuning und ein eigener finaler Rundenabschluss bleiben spätere Arbeit.

## Tatsächliche Verifikation

| Status | Prüfung / Ergebnis |
|---|---|
| **PASS** | Frischer normaler Produktions-Build ohne Testhooks, inklusive erfolgreicher ZIP-Paketierung und Igor-Endcode 0: `tests/reports/production-build.json`. Cache liegt außerhalb des Paket-Eingabeverzeichnisses und verursacht keinen bisherigen Selbst-ZIP-Dateikonflikt mehr. |
| **PASS** | **3.378 Runtime-Assertions**, Prozessende 0: `tests/reports/gameplay-smoke-result.json`. Frisch gebaute isolierte Windows-VM, neun echte Menü-/Raumkombinationen, keine Produktions-Testhooks. |
| **PASS** | Kein fest platzierter Boss/Fireball beim Start, keine vorgezogene Zauberauswahl; regulärer Münz-Level-up und Erwerb. Autoauslösung aller sechs Zauber in Krieger/Magier/Waldläufer sowie in sechs Bewegungsvarianten. Ziel-/Heilbedingungen, unabhängiger Cooldown und Bereitschaftsimpuls. |
| **PASS** | Tatsächliche HP-Messungen für Spieler, aktive Fähigkeiten und Bossangriffe; Schutz während Sprung/Fall/Dive/Slide/Dodge und danach wieder möglicher Schaden. Bildlicher HP-Nachlauf und Cooldownzustände 0/25/50/75/100 % gerendert und visuell geprüft. |
| **PASS** | Zeitplan, Identität und Spawnabstände; kein Mehrfachspawn; Pause friert Uhr und Warnzeit ein. Blitz verursacht vor Warnablauf keinen Schaden, danach exakten HP-Abzug; kein Schaden außerhalb des Kreises oder wiederholt durch denselben Einschlag. |
| **PASS** | Fächer-Ansage und echte 1/3/5-Projektile, Phase-2-Übergang und Cleanup, drei Phase-2-Blitzzonen, sichere Ringgasse, Ballistik/Schaden bei Landung, schnelle Projektil-Streckenkollision, 512er-Grenze/Lebensdauer und Boss-Tod/Belohnung. |
| **PASS** | Beide kompletten Hauptboss-Rotationen über je 900 deterministische Updates; die stark defensive, kontinuierlich bewegte Fixture überlebt. Keine Behauptung, dies ersetze manuelles Soulslike-/Bullet-Hell-Balancing. |
| **PASS** | 40 Krieger-Ressourcen und Spiegel-/Ursprungsregeln; Screenshots für Richtungen/Zustände, HUD, radiale Wipes, Kampf, Boss, Charakterauswahl und Game Over bei 800×600 visuell kontrolliert. |
| **PASS** | GameMaker-Projektintegrität: 250 Ressourcen, keine Probleme oder Warnungen. |
| **FAIL** | Keine verbleibende fehlgeschlagene Prüfung im letzten Lauf. Die während der Entwicklung gefundenen Compiler-Namenskonflikte und HUD-Überlappungen wurden korrigiert. |
| **BLOCKED** | Keine ausstehende technische Blockade. |
| **NOT RUN** | Vollständiger manueller Spieltest mit echten OS-Eingaben; subjektive Schwierigkeit aller Klassen/Builds, 30 Minuten Echtspiel, Maximallast-/Langzeit-Performance, sämtliche Auflösungen/Tooltipvarianten und interaktiver Nutzerlauf der F6–F9-Entwicklungstasten. |

## Aktuelle Artefakte und lokale Befehle

```powershell
python tests/tools/run_gameplay_smoke.py
python tests/tools/build_production.py
```

Der aktuelle normale Build liegt unter `output/production-build/20261122-145100/game/FirstGame.exe`, das verteilbare Paket daneben unter `FirstGame.zip`. Für direkte Bossprüfung mit unverändert normalem Menüablauf:

```powershell
& './output/production-build/20261122-145100/game/FirstGame.exe' --boss-dev
```

Klasse/Level wählen, danach **F6** für direkten Bossstart, **F7** für Phase 2, **F8** für Muster, **F9** für 35-%-Bosszeit. Ohne Flag/Debugger greifen diese Tasten nicht in den normalen Verlauf ein. Die Startauswahl bleibt auch im normalen Build entfernt.

## Wesentliche Änderungen

- `scripts/hud/`, `objects/ObjectOverlay/`: HP-/Münzfortschritt, kompakte Slots und radiale Cooldowns; Overlay initialisiert keinen konkurrierenden Spielzustand mehr.
- `scripts/hotbar_assign/`, `scripts/cast_spell/`, Controller-Step, Reset und Auswahlskript: automatische Ziel-/Auslösebedingungen, eigene Timer und reguläre erste Auswahl.
- `scripts/player_artpack/`, Player-Step/Draw, SwordHitbox-Draw und Krieger-`.yy`-Metadaten: kanonische Richtungsdarstellung, Fußursprünge und Slash.
- `scripts/boss_combat/`, Boss-Create/Step/Draw/Destroy, Controller-World-Draw, Spawner und `FirstGame.yyp`: Zeitplan, Phasen, Muster, Gefahren, Schadens- und Cleanup-Pfade. Die eigentliche Boss-Zeit wird einmalig vom Controller fortgeschrieben.
- `rooms/Room1`, `RoomCrypt`, `RoomRuins`: ausschließlich alte Boss-/Fireball-Start-Testinstanzen samt Erstellreihenfolge entfernt; kein Level-Art-Rewrite.
- `tests/boss_harness.gml`, aktualisierte Gameplay-Fixture/-Runner, `build_production.py`, Kataloge und Berichte: wiederholbare lokale Tests und verwendbarer normaler Build.

Kein automatischer Git-Push, keine kostenpflichtigen APIs, keine QA-KI-Subagents. Bekannte Grenzen sind Verifikations-/Balancingaufgaben und die ausdrücklich prototypischen späteren Bosse; aus dem letzten Lauf sind keine offenen Runtimefehler bekannt.
