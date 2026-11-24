# FirstGame – Abschlussbericht Zaubersystem 2.0

Neuere Klassen-, Drachen- und Countdown-Änderungen stehen in [CLASS_DRAGON_REPORT.md](CLASS_DRAGON_REPORT.md). Die folgenden Zahlen und das Paket dokumentieren den vorherigen Zaubersystem-Stand.

Stand: 22.11.2026. **PASS: 36 funktionierende Fähigkeiten, 322 native Prüfungen und normaler Windows-Produktionsbuild.** [Spiel herunterladen](output/production-build/20261122-215808/FirstGame.zip). Das Paket enthält keine Testharness-Injektion. [Vollständiger Zauberkatalog mit allen neun Stufen](SPELL_CATALOG.md).

## 1–4. Fähigkeiten, tatsächliche Umsetzung und Upgrades

Alle vorgesehenen Fähigkeiten sind implementiert, auswählbar und auf Stufe 1–9 ausbaubar. Sechs aktive und sechs passive Slots sind feste Grenzen. Die Klassenwaffe bleibt separat. Es gibt keine neuen Klassen oder Bossmonster.

Aktiv: Fireball, Iceball, Lightning, Frost Nova, Arcane Barrage, Healing Pulse, Ember Field, Piercing Lance, Orbit Blades, Stone Spikes, Wisp Sentinel, Thunder Seal, Starfall, Gravity Well, Ice Prison, Returning Glaive, Prismatic Seed, Solar Verdict.

Passiv: Orbit Shield, Power Up, Fleet Footed, Quick Hands, Vitality, Split Runes, Keen Focus, Swift Sigils, Wide Glyphs, Deep Rhythm, Ember Oath, Storm Conductor, Winter Heart, Iron Ward, Renewal, Scavenger, Lingering Hex, Resonant Core.

Die zwölf neuen aktiven Mechaniken umfassen periodischen Bodenbrand, durchdringende Linie, echte umlaufende Klingen, versetzte Steinspitzen, einen angreifenden Begleitgeist, verzögertes Blitzsiegel, Meteore, einen schadenden Zugwirbel, pulsierendes Frostgefängnis, Hin-/Rückweg-Klinge, explodierenden Splitterkern und einen großen Sonnenangriff. Normale Gegner können gezogen beziehungsweise kurz festgehalten werden; Bosse widerstehen diesen beiden Kontrollen. Die zwölf neuen Passiven verändern echte Kampf-, Status-, Heilungs-, Sammel- und Projektilwerte. Details und Zahlen stehen im Katalog.

Die bestehenden sechs aktiven und sechs passiven Fähigkeiten wurden mitgeprüft und an dieselbe Datenquelle angeschlossen. Fireball explodiert am Treffer und brennt; Iceball verlangsamt; Lightning verbindet verschiedene Ziele; Nova trifft im Umkreis; Barrage erzeugt getrennte Geschosse; Healing Pulse erfasst nur wirklich geheilte HP. Orbit Shield erhält auf jeder Stufe mehr echten Orbitschaden, auch nach Erreichen seines Reduktionslimits. Vitality heilt ausschließlich den neu gewonnenen Maximal-HP-Betrag. Split Runes gibt zusätzlich zu Geschossstufen auf jeder Stufe flachen Projektilschaden. Neuberechnung stapelt passive Boni nicht mehrfach.

Zentrale Definitionen und Generator: `tests/tools/build_spell_v2_catalog.py`. Runtime-Werte werden gemeinsam für Ausführung, Upgrade-Vorschau und Tooltip verwendet. Schaden steigt grundsätzlich um 16% des Basisschadens pro Stufe, Cooldown sinkt um 1,2% der Basis; zusätzliche Radien, Kettenziele, Projektile und Mehrfacheinschläge sind einzeln dokumentiert. Kritische Treffer, stärkster laufender Brand, Statusverstärkung und tatsächliche statt überzähliger HP-Schaden sind berücksichtigt.

Auswahl: cyan aktive, violett passive Fähigkeiten, Goldmarkierung für Besitz. Karten zeigen NEU oder UPGRADE sowie aktuelle → nächste Stufe. Eine eigene reproduzierbare Zufallsfolge verhindert Einflüsse durch Partikelzufall. Wenn beide Pools verfügbar sind, erscheinen eine vorhandene und eine neue Fähigkeit; die dritte Auswahl bevorzugt Upgrades mit 65%. Keine Duplikate oder Angebote über Stufe 9; volle Slotgruppen bekommen keine neuen Einträge.

## 5–6. Erfahrungskurve und erwartete Spielerlevel

Der erste Levelaufstieg kostet 1 XP, die nächsten Schwellen 16 und 24. Für Level 4–14: ceil(36 + 10 × (Level−4)). Ab Level 15: ceil(146 + 2,3 × n + 0,012 × n²), n = Level−15. Nach einer bestätigten Auswahl vergehen mindestens sechs echte Gameplay-Sekunden bis zum nächsten Levelangebot; Pausen zählen nicht. XP kann erhalten bleiben, führt aber nicht zu sofortigen Auswahlketten.

Direkte Boss-XP sind auf min(12% der aktuellen Schwelle, 2 beim Miniboss / 5 beim Hauptboss) begrenzt. Truhe und Orb werden weiterhin genau einmal ausgegeben. Ein voller Build benötigt 108 Fähigkeitsschritte, einschließlich neuer Fähigkeiten und Truhenentscheidungen; danach werden keine nutzlosen Levelauswahlen mehr geöffnet. Bis Spielerlevel 102 werden 24.922 Schwellen-XP benötigt.

Die folgende Tabelle trennt **Modellprognose und native XP-Budget-Wiedergabe**. Rechts wurde dieselbe XP-Zufuhr in echte GameMaker-Progression samt Auswahlroutine eingespeist. Das misst die Funktion der Kurve, nicht den langfristigen Ertrag eines menschlichen Spielers.

| Minute | Langsamer: Modell / nativ | Mittlerer Lauf: Modell / nativ | Sehr erfolgreich: Modell / nativ |
|---|---|---|---|
| 1 | 4 / 4 | 5 / 5 | 5 / 5 |
| 3 | 7 / 7 | 9 / 9 | 10 / 10 |
| 5 | 10 / 10 | 13 / 13 | 15 / 15 |
| 10 | 17 / 17 | 23 / 23 | 30 / 30 |
| 15 | 25 / 25 | 36 / 36 | 48 / 48 |
| 20 | 35 / 35 | 49 / 49 | 67 / 67 |
| 25 | 46 / 46 | 64 / 64 | 87 / 87 |
| 29 | 55 / 55 | 75 / 75 | 102 / 102 |

Angenommene Münzerträge pro Minute bei Spielminute t: langsam 45+18t, mittel 80+30t, sehr erfolgreich 70+55t, zuzüglich der modellierten Bossbelohnungen. Der volle 6+6-Build erreicht ausschließlich im sehr erfolgreichen Profil nach **28,83 Minuten** alle zwölf Stufen 9. Bei derselben Mindest-XP-Menge wie dem gemeldeten alten Level 47 nach fünf Minuten (1.507 XP) entsteht jetzt ungefähr Level 18. Erwartungswert nach fünf Minuten unter dem mittleren Profil: etwa Level 13.

Zusätzlich wurden echte Spawner, Waffen, automatische Zauber, Gegner und Projektile in zwei kurzen kontrollierten Kampffenstern ausgeführt: jeweils vier Sekunden Aufwärmen und zehn Sekunden Messung bei 60 Simulationsschritten/s. Start nur mit Waffe: 26 Kills, hochgerechnet 156/min. Voller 6+6-Level-9-Build mit Gegner-HP von Minute 25: 281 Kills, hochgerechnet 1.686/min. Diese stationären unverwundbaren Testfiguren sind keine menschlichen 30-Minuten-Läufe; ihre Kurzzeitwerte garantieren die Zielprogression nicht.

Nachweise: `tests/reports/spell-v2-progression.json`, `tests/reports/spell-v2-native.json`. Reproduktion: `analyze_spell_v2_progression.py` und `run_combat_smoke.py` unter `tests/tools`.

## 7. Effekte, Licht und Audio

36 neue Rastericons und sechs elementare Vierframe-Rastereffekte sind als echte GameMaker-Sprites importiert. Fireball hat sichtbaren Flug und Einschlag; Lightning mehrfache hell umrandete Verzweigungen; neue Felder besitzen eigene Runen, Wirbel, Kristalle, Spitzen, Umlaufklingen und Sonnenwirkung. Treffer erzeugen begrenzte farbige Lichtimpulse. Die Effektpools sind auf 48 Felder, 64 Bursts und 48 Verbindungen begrenzt.

**Tatsächlich neu erzeugt und integriert:** `Audio/Spells/skill_101.wav` bis `skill_118.wav`, 18 eigenständige kurze 32-kHz/16-Bit-Mono-PCM-Cues, jeweils über `sfx_fg_skill_ID`. Sie werden beim tatsächlichen erfolgreichen Cast ausgelöst. Quelle: `Audio/Sources/compose_spell_v2.py`. Das sind programmatische Synthese-Prototypen; eine menschliche Hörabnahme wurde nicht durchgeführt. Insgesamt existieren jetzt 54 gültige WAVs: 3 Musikstücke und 51 Effekte. Technische Dateiprüfung und tatsächliches Erzeugen von Audiostimmen bestanden. Der bestehende Mixer begrenzt Stimmen (16 global, zwei je Cue), sperrt zu dichte Wiederholungen und berücksichtigt getrennte Musik-/Effektlautstärken. Bestehende Musikwechsel und Loop-Verwaltung bleiben aktiv.

Editierbare Artquellen, Prompts und Zuschnittwerkzeuge liegen unter `FirstGame_ArtPack/spell_v2` und `tests/tools/prepare_spell_v2_art.ps1`; importiert wird mit `import_spell_v2.py`. Keine heruntergeladenen Original-Spielmelodien, bezahlten APIs oder alten Grafikfallbacks wurden ergänzt.

## 8. Pause-Menü und Statistik

Die linke Navigation, mittlere Fähigkeitenliste und rechte Hover-Detailkarte sind getrennte UI-Komponenten. Die Liste zeigt Icon, Name und neun Stufenorbs. Das Detailfeld nennt Wirkung, aktuelle Werte, Gesamtschaden, Gesamtheilung, Treffer, Auslösungen und nächstes Upgrade ausgeschrieben; keine D/H/A/T-Kurzformen. Verstärker erfinden keine eigenen Schadenssummen. [Native Detailansicht](tests/reports/spell-v2-pause-details.png), [Auswahlkarten](tests/reports/spell-v2-offers.png).

## 9. Charakter-Sprites und Schwertfortschritt

640 aktive Charakterframes wurden untersucht. In 20 Mage-/Rangerframes wurden insgesamt 24 isolierte sichtbare Störpixel entfernt, beispielsweise oberhalb des Rangerhaars und bei Mage-Dive/Slide. Zusammenhängende Figurenkonturen, echte graue Rüstung und farbige Angriffseffekte wurden erhalten. Die Schwertframes benötigten bei dieser konservativen Prüfung keine Reparatur. Das ist keine Behauptung, sämtliche künstlerischen Kanten jedes Frames manuell nachgezeichnet zu haben. Originale der geänderten Frames und bereinigte Quellen sind im Artpack gesichert. Prüfprotokoll: `tests/reports/spell-v2-character-edges.json`.

Drei sichtbare Schwert-Effektstufen ab Spielerlevel 1, 34 und 68 steigern Leuchtkraft und goldene Nachzeichnung. Diese visuelle Progression multipliziert den tatsächlichen Kombo-Schaden nicht. Die drei separaten Kombo-Treffer bleiben erhalten.

## 10. Spielwelt und Sichtbarkeit

Room1 verwendet ein reproduzierbares organisches Layout mit Baumgruppen, Waldpfaden und Lichtungen statt regelmäßigem Raster. 1.087 neue Master-Style-Props, darunter 242 Bäume; Architektur konzentriert sich auf zwei Orte mit vier Säulen, vier Wänden, zwei Bögen, vier Feuerschalen und zehn Pflasterelementen. Säulen sind 1,6-fach skaliert, etwa 237 px hoch gegenüber etwa 86 px Heldenhöhe. Säulen-/Mauerfüße und Bogenbeine haben skalierte physische Kollisionsbereiche, die Bogenmitte bleibt passierbar. Auch zurückgezogene Gegner respektieren diese Hindernisse.

Verdeckte Münzen bekommen eine dezente Markierung im Draw-End-Pass; ihre tatsächliche Tiefensortierung bleibt erhalten. Lebende Minibosse erhalten einen kleinen violetten, leicht schwebenden Richtungspfeil. Der bestehende Hauptbossindikator bleibt separat. Layoutgenerator: `tests/tools/natural_world_layout.py`, Seed 712403. Keine alten Dekorationen oder alten normalen Gegnertypen wurden reaktiviert.

## 11. Drachenangriffe und Sprünge

Gerader Feuerstrahl mindestens 1.200 px lang; falls nötig bis über die gegenüberliegende sichtbare Kamerakante verlängert. Sweep 650 px, Arc 360 px, Strahlbreite 48 px. Warnung für Strahl/Sweep/Arc 0,72 s, in Phase 2 etwa 0,634 s; Konturaufbau innerhalb der ersten 0,08 s dieser gesamten Warnphase. Der Schaden beginnt beim Übergang in die aktive Phase, ohne zusätzliche unsichtbare Wartezeit. Gerader Strahl 1 s aktiv, Sweep 1,45 s, Arc 1,25 s; Erholung 0,85/0,60 s.

Magmaflächen haben Radius 125 statt 52 px, also rund 2,4-fachen Durchmesser. Drei getrennte Zonen lassen sichere Zwischenräume. Ihre Warnphase beträgt in beiden Phasen 0,9 s; auch die langsamste Grundklasse kann bei unmittelbarer Reaktion den Radius verlassen. Riesige Trefferzonen erhalten entsprechend große sichtbare Warnung und Einschlagsgrafik. Die stationäre Figur stirbt weiterhin an wiederholten Drachenangriffen; daraus wird kein Nachweis einer menschlichen Bossbesiegbarkeit abgeleitet.

Sprungdauer 0,66 statt 0,58 s, Höhe 68 statt 48 px, horizontale Bewegung 1,25 statt 0,95 × Basistempo. Beim Schwertkämpfer etwa 158 statt 106 px Grundsprungweite. Das 80-ms-Fenster für die zweite Eingabe am Scheitelpunkt bleibt erforderlich. Eine einzelne Eingabe löst keinen Slide aus; Erholungszeiten und Ausweichbegrenzung bleiben aktiv.

## 12. Tatsächlich ausgeführte Prüfungen

| Status | Prüfung und Beleg |
|---|---|
| PASS | 322 native Windows-VM-Prüfungen, Exitcode 0, neun Klassen-/Raumkombinationen; `tests/reports/spell-v2-native.json` |
| PASS | Alle 18 aktiven Fähigkeiten auf 1 und 9 mit echter HP-/Heilungsänderung, Cooldown, Icon, Audioressource und tatsächlichen Audiostimmen |
| PASS | Alle 18 Passiven, stabile Neuberechnung, Zwischenstufen, Krits, echte Regeneration, Projektile, Statussynergien, Brandzuordnung, Glaive-Doppeltreffer und Boss-Kontrollimmunität |
| PASS | Reproduzierbare gewichtete Auswahl, Slotgrenzen, Maximalstufen, 200 Angebote, drei native XP-Budget-Wiedergaben |
| PASS | Echter Magnetkontakt sammelt genau 30 Münzen für 30 XP; Münzmarkierung, Minibosspfeil, Säulenkollision und freie Bogenmitte |
| PASS | Bildschirmfüllender Drachenstrahl, Magmagröße/-abstände, Schadensbeginn, Warnzeit für langsamste Klasse, Sprung/zweite Eingabe |
| PASS | 150 Gegner mit Wetter: 60 gemessene Frames, Mittel 16,666 ms, Maximum 16,86 ms; kurze Stichprobe, kein Langzeitbenchmark |
| PASS | Native Screenshots von Effekten, Menüs und Drachen erzeugt und ausgewählte Bilder visuell geprüft; `output/combat-smoke/20261122-215455` |
| PASS | 54 echte WAV-Dateien geprüft; `tests/reports/audio-files.json` |
| PASS | GameMaker-Projektintegrität: 608 Ressourcen, null Probleme und null Warnungen; `tests/reports/spell-v2-project.json` |
| PASS | Normaler Produktionsbuild, Compile/Package erfolgreich, ohne Testhooks; `tests/reports/production-build.json` |
| NOT RUN | Menschlicher 30-Minuten-Lauf und langfristige XP-/Buildbalance |
| NOT RUN | Menschlicher Boss-Siegtest und subjektive Audio-/Musik-Hörabnahme |

Native Tests verwenden isolierte Kopien, injizierte Eingaben und für kurze Benchmarks einen festen Zeitschritt. Hoch-HP-Visualisierungsfixtures dienen nur Screenshots. Produktionsdateien enthalten diese Testinjektionen nicht. Historische Berichte beschreiben frühere Zwischenstände; dieser Bericht ersetzt deren Fähigkeiten-, XP-, Welt- und Angriffswerte.

## 13. Noch offen

Alle 36 Fähigkeiten sind funktional integriert; keine geplante Fähigkeit ist als leere Option stehen geblieben. Offen sind die menschliche Langzeit-Balanceprüfung verschiedener Builds, subjektive Bossfairness, künstlerische Feinabnahme sämtlicher Animationsframes und Hörabnahme beziehungsweise hochwertigeres Sounddesign. Die 28–29-Minuten-Ausbauzeit ist modelliert und mit eingespeistem XP nativ reproduziert, noch nicht als menschlicher Komplettlauf nachgewiesen. Kein automatischer Git-Push wurde ausgeführt.
