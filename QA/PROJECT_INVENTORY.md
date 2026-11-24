# Tatsächlicher Projektstand und Baseline-Inventar

Am 23.11.2026 wurden das vorhandene GameMaker-Projekt und die aktuellen Produktionsquellen gelesen. Dieses Inventar beschreibt implementierte Regeln, keine Messung ihrer Spielstärke. Die unveränderte Ausgangsbasis liegt unter `baseline/project`; `baseline/manifest.json` enthält die Quell- und PNG-Prüfsummen. Nachträgliche Balancing-Änderungen gehören in `BALANCE_CHANGES.md`.

## Projekt und Testbasis

`FirstGame.yyp` enthält 973 Ressourcen: 19 Objekte, 35 Skriptressourcen, vier Räume, 826 Sprites, 88 Sounds und ein Tileset. Verwendete lokale Runtime: GameMaker 2024.14.4.268. Die aktuelle Ressourcenmenge und alle Ressourcen-Einträge entsprechen der Baseline; lediglich deren Reihenfolge in der Projektdatei ist verändert.

Die vorhandenen isolierten Testwerkzeuge unter `tests/tools` bauen gesonderte Projektkopien. Der historische Boss-System-Test meldete 830 gezielte Assertions; das waren keine 830 vollständigen Spielrunden. Der neue aktuelle zielgerichtete Regressionstest meldet 811 bestandene Assertions (`data/regression.json`). Vollständige Runs, Bosskämpfe, Schadensfenster, statische Prüfungen und analytische Hochrechnungen müssen in den nachfolgenden Berichten getrennt gezählt werden.

## Klassen und automatische Startwaffen

Die Klassenbasis wird in `scripts/reset_round/reset_round.gml` gesetzt. Die Startwaffe belegt keinen der sechs aktiven Zauberplätze.

| Klasse | Basis-HP | Bewegung pro 60-Hz-Schritt | Basis-Power | Automatische Waffe |
|---|---:|---:|---:|---|
| Schwertkämpfer | 120 | 3,2 | 2 | gerichtete dreiteilige Nahkampfkette |
| Zaubermeisterin | 70 | 2,8 | 4 | fester Viererzyklus aus Projektil, Bogen, Kreis und Stern |
| Waldläufer | 82 | 4,2 | 1 | fester Zwölferzyklus aus Pfeilen, Mehrfachschüssen und Pfeilregen |

Beim Schwert wird die Kette in `scripts/master_combat` ausgeführt. Die tatsächlichen Multiplikatoren sind 0,5 / 0,6 / 0,9 auf den gerundeten Waffenschaden. Mit der Basis-Power ergeben sich 11 / 13 / 19 Schaden vor gegnerspezifischen Effekten und kritischen Treffern. Auslösende Kombouhr: 0, 4, 16, 22, 34, 42, 56; neue Kette frühestens nach `ceil(68/(1+weapon_haste))`, mindestens 24 Frames. Der statische Waffen-Definitionswert 44 ist deshalb nicht der tatsächliche Intervall einer vollständigen Schwertkette.

Die Zaubermeisterin verwendet Basiswert `25 + Power`, Grundintervall 96 Frames und die vier festen Schritte: normales Projektil; 1,4-facher Sektortreffer nach 0,09 s bei Radius 155; 1,8-facher Kreistreffer nach 0,3 s bei Radius 130; 3,5-facher Sterneneinschlag nach 1,0 s bei Radius 170. Das Intervall wird durch Waffen-Haste geteilt und auf mindestens zwölf Frames begrenzt. Die Luftbahn des Sterns und sein verzögerter Treffer sind implementiert.

Der Waldläufer verwendet den gerundeten Basiswert `6 + 0,5*Power`, Grundintervall 18 Frames und die feste Folge `1,1,3,1,1,1,1,1,5,1,1,Pfeilregen`. Der Regen verursacht fünf Flächentreffer mit je 0,55-fachem Basiswert; Radius 125, Beginn nach 0,4 s, Abstand 0,16 s. Pfeile besitzen eine Liste bereits getroffener Ziele und durchbohren Gegner ohne denselben Gegner auf jedem Teilbewegungsschritt erneut zu treffen. Split Runes verändert bei diesen festen Klassenzyklen den Zusatzschaden, nicht die 3-/5-Schuss-Schritte.

## Fähigkeiten und Upgrades

Der aktuelle Katalog umfasst 18 aktive und 18 passive Fähigkeiten, jeweils maximal Stufe 9. Quellen: `scripts/spell_v2_catalog`, `scripts/spell_v2`, `scripts/spell`, `scripts/apply_passives`; die editierbare Katalogquelle liegt unter `FirstGame_ArtPack/spell_v2/catalog.json` und wird durch das bestehende Katalogwerkzeug gepflegt.

| Aktive ID | Name | Implementierter Mechaniktyp | Grund-Cooldown in Frames |
|---|---|---|---:|
| 101 | Fireball | Projektil, Explosion, Brennen | 105 |
| 102 | Iceball | Projektil, Verlangsamung | 96 |
| 103 | Lightning | Kette mit besuchten Zielen | 126 |
| 104 | Frost Nova | Nova / Kältekontrolle | 240 |
| 105 | Arcane Barrage | mehrere Projektile | 144 |
| 106 | Healing Pulse | Heilung | 480 |
| 107 | Ember Field | wiederholtes Feld | 300 |
| 108 | Piercing Lance | Linie | 210 |
| 109 | Orbit Blades | Umlaufbewegung | 360 |
| 110 | Stone Spikes | Bodenspitzen | 285 |
| 111 | Wisp Sentinel | zeitlich begrenzter Wächter | 420 |
| 112 | Thunder Seal | verzögertes Siegel | 390 |
| 113 | Starfall | Einschlag | 450 |
| 114 | Gravity Well | Feld und Zug auf normale Gegner | 420 |
| 115 | Ice Prison | Kältefeld und Kontrolle | 360 |
| 116 | Returning Glaive | Hin- und Rückflug | 270 |
| 117 | Prismatic Seed | verzögerte Saat | 300 |
| 118 | Solar Verdict | großer verzögerter Treffer | 780 |

Grund-Cooldowns sind keine gemessenen DPS-Werte. Stufe, Power, Passiva, Fläche, Reisedauer, Zielzahl und Trefferwahrscheinlichkeit verändern die tatsächliche Wirkung. Heilung ist kein Schaden.

| Passive ID | Name | Baseline-Effekt / Voraussetzung |
|---|---|---|
| 201 | Orbit Shield | Schadensreduktion, maximal 60 %, dazu tatsächlicher Umlaufschild |
| 202 | Power Up | +2 Power je Stufe |
| 203 | Fleet Footed | +0,12 Bewegung je Stufe |
| 204 | Quick Hands | +0,05 Waffen-Haste je Stufe |
| 205 | Vitality | +12 maximale HP je Stufe; tatsächliche neue Bonus-HP werden gutgeschrieben |
| 206 | Split Runes | Zusatzprojektile für passende Zauber und Zusatzschaden; benötigt 101, 102 oder 105 |
| 207 | Keen Focus | +0,02 Krit-Chance je Stufe |
| 208 | Swift Sigils | +0,055 Projektilfaktor je Stufe |
| 209 | Wide Glyphs | +0,035 Flächenfaktor je Stufe |
| 210 | Deep Rhythm | −0,035 Cooldown-Faktor je Stufe, mit Kataloguntergrenze |
| 211 | Ember Oath | +0,045 Feuerbonus je Stufe; benötigt 101, 107 oder 113 |
| 212 | Storm Conductor | +0,045 Blitzbonus je Stufe; benötigt 103 oder 112 |
| 213 | Winter Heart | +0,045 Kältebonus je Stufe; benötigt 102, 104 oder 115 |
| 214 | Iron Ward | +0,6 flache Rüstung je Stufe |
| 215 | Renewal | +0,12 HP/s je Stufe |
| 216 | Scavenger | +12 Sammelradius je Stufe |
| 217 | Lingering Hex | +0,08 Statusdauer je Stufe; benötigt passenden vorhandenen Statuszauber |
| 218 | Resonant Core | +0,025 Resonanz je Stufe; benötigt passenden vorhandenen Statuszauber |

Die letzten beiden Voraussetzungen akzeptieren jeweils mindestens einen der aktiven Zauber 101, 102, 103, 104, 107, 112, 113, 115. `spell_passive_eligible` prüft Voraussetzungen sowohl für neue Angebote als auch für Upgrades. Die drei Angebote verwenden einen eigenen reproduzierbaren `choice_rng`: wenn verfügbar ein eigenes Upgrade, eine neue Fähigkeit und ein weiterer gewichteter Eintrag, danach deterministische Positionsmischung. Bei leerem aktiven Build wird mindestens ein aktiver Angriff angeboten. Vollständige Builds erhalten den vorgesehenen Informationseintrag. `learn_spell` begrenzt Plätze und Stufen; der normale Angebotsweg prüft die Voraussetzungen davor.

## Gegner, Spawns und Erfahrung

Room1 verwendet im regulären Spawn nur die aktuellen Master-Skelette. Innerhalb dieser Familie gibt es Basisrollen, keine hier neu eingeführten Gegnertypen:

| Rolle | Basis-HP | Basisschaden | Basisbewegung |
|---|---:|---:|---:|
| Krieger | 78 | 11 | 1,12 |
| Späher | 50 | 8 | 1,55 |
| Wache | 165 | 15 | 0,82 |

HP werden mit `base_monster_hp_multiplier*(1+Minute*0,07)` und Schaden mit `base_monster_damage_multiplier*(1+Minute*0,06)` multipliziert. Die Verfolgungsbewegung berücksichtigt zusätzlich `combat_config().monster_speed = 1,08` und Status. Skelette starten innerhalb von 48 Einheiten eine vorbereitete Attacke; tatsächlicher Schlagkontakt ist bei 0,20 bis unter 0,36 s und höchstens 43 Einheiten möglich. Der gesamte Angriff endet bei 0,72 s. Der Kontakt ist außerhalb dieses Schlagfensters harmlos.

Die Zielpopulation interpoliert über die Zeiten 0 / 60 / 180 / 300 / 600 / 1200 / 1800 s auf 18 / 24 / 40 / 60 / 80 / 110 / 150 Gegner. Die Sichtbarkeitsuntergrenze beträgt 60 % davon, das technische Limit 180. Alle 0,20 s werden höchstens sechs Gegner außerhalb der Kamera nachgefüllt; blockierte Positionen werden verworfen. Entfernte Gegner werden ohne Belohnung entfernt. Der Laufzeitdeckel sinkt bei längeren langsamen Frames und erholt sich später; die festen 60-Hz-Tests bilden absichtliche Lastanpassung an eine langsame echte Maschine damit nicht automatisch ab.

Ein gewöhnlicher Tod erzeugt eine XP-Münze. Normale Münzen bewegen sich mit 252 Einheiten/s im Sammelradius; Magnetmünzen beschleunigen von 1000 bis 2400 Einheiten/s bei 1800 Einheiten/s². Nur Bossbelohnungen erzeugen regulär Magnetorbs. Der Orb markiert alle bestehenden Münzen, einschließlich zuvor deaktivierter Münzinstanzen, mit der aktuellen Sammelgeneration. Alte Rundentokens werden zurückgewiesen.

Die XP-Kosten lauten für Level 1 bis 3: 1 / 16 / 24; für Level 4 bis 14: `ceil(36 + 10*(Level−4))`; anschließend mit `n=Level−15`: `ceil(146 + 2,3*n + 0,012*n*n)`. Zwischen normalen XP-Auswahlen liegen mindestens sechs Spielsekunden. Das ist eine implementierte Kurve, kein Beweis dafür, wann durchschnittliche Spieler eine bestimmte Stufe erreichen. Vollständiger Ausbau bedeutet sechs aktive plus sechs passive Fähigkeiten auf Stufe 9, also 108 gültige Investitionen ohne bereits gewährte Startinvestitionen. Die normale Runde beginnt mit leeren Zauberlisten und eigener Startwaffe.

## Boss-System

Es gibt zwei vorhandene Minibosse (`mini_sentinel`, `mini_warden`) und drei vorhandene Hauptbosse (`storm_warden`, `twins`, `behemoth`). Zeitplan: Minute 1 / 3 / 5 / 10 / 15 / 20 / 25 / 30; ein laufender Boss wird über die vorhandene Verwaltung berücksichtigt. Die Minibosse besitzen Basis-HP 650 bzw. 1100.

Die Hauptbosse haben je neun implementierte Fähigkeiten. Freigabe wird beim Spawn eingefroren: drei ab Minute 5, sechs ab Minute 10, neun ab Minute 15. Basis-HP: Drache 9200, Hexen 13000 gemeinsamer Pool, Behemoth 9200. Die sechs HP-Faktoren ab Minute 5 sind 1,35 / 1,9 / 2,5 / 3,4 / 4,5 / 5,8; Schwierigkeit und Raum-Basisfaktor kommen hinzu. Die beim Spawn gespeicherten Werte werden nicht mit sinkenden HP nachträglich neu berechnet.

Drache und Hexen wechseln bei 75 / 50 / 25 % Rest-HP in die nächsten der vier Phasen. Beim Behemoth sind es 70 / 40 / 10 %. Die Hexen sind zwei tatsächlich anvisierbare Akteure mit einem gemeinsamen HP-Pool und einer einmaligen Belohnung. Hauptboss-Init setzt den passiven Körperschaden aktuell auf 0; die Angriffsgefahren verursachen ihren eigenen Schaden. Dies ist tatsächliches Verhalten, keine pauschale Fairnessbewertung.

Die neun Drachenfähigkeiten heißen intern `beam`, `arc`, `stomp`, `meteor`, `slam`, `wind`, `void`, `vortex`, `volley`. Der zusätzliche Konfigurationsfall `sweep` ist kein zehnter freigeschalteter Katalogangriff. Hexen: Doppelsalve, Elementring, Paarregen, Verbindungsstrahl, Gegenwirbel, Kreuzstrahlen, brennender Froststoß, Zonenflut, dreistufige Nova. Behemoth: Giftgespucke, Säurepfützen, Wurzeln, Pilze, Stampfer, Brut, Giftatem, Sumpfwelle, Verfallsblüte.

Gefahren verwenden gemeinsame Geometrien für Kreis, Ring, Sektor, Linie und Rechteck. Die Warnuhr wird im Update fortgeschrieben; Zeichnen selbst aktiviert keinen Schaden. Projektile, verbleibende Bodenfelder und spätere Status-Ticks können nach einer neuen Bossattacke noch wirken. Deshalb muss die Messung ihren ursprünglichen Besitzer und Angriff erhalten. Maximal 128 neue Bossgefahren, 256 feindliche Geschosse und sechs Behemoth-Begleiter begrenzen diese Komponenten.

Der vorhandene Menüpunkt „Boss testen“ erlaubt unter anderem Drache / Minute 15 / alle neun Fähigkeiten. F1-Unverwundbarkeit und weitere Entwicklungshilfen sind an diesen Testzustand gebunden; normale Tests dürfen sie nicht als natürliche Überlebensleistung zählen. Das Drachenmodell ist bei diesem Auftrag unverändert.

## Bewegung, Treffer und UI-Zustände

WASD/Pfeile und nach Freigabe die gehaltene linke Maustaste steuern die Bewegung. Richtungsdiagonalen erhalten dieselbe Gesamtgeschwindigkeit. Ein Sprung dauert 0,66 s, erreicht rechnerisch 68 Einheiten Höhe und bewegt mit 1,25-facher Klassengeschwindigkeit. Ein zweiter Tastendruck im 80-ms-Fenster um den Scheitelpunkt startet den Sturz; darauf folgt der zeitlich begrenzte Slide. Ein einzelner Sprung erzeugt keinen automatischen Slide. Strg startet einen 0,16-s-Dodge mit 510 Einheiten/s, 1,5 s Cooldown und anschließender Bewegungserholung.

`player_protected_from` unterscheidet Boden-, hohe und alle Höhen treffende Angriffe: Dodge schützt gegen alle; hohe Geschosse können durch Slide vermieden werden; Sprung-/Slide-Zustände schützen gegen Bodengefahren, jedoch nicht gegen `all`. Gewöhnliche Treffer erzeugen keine pauschale globale Unverwundbarkeit; jeder Angreifer besitzt seinen Kontaktabstand von 0,65 s. Schaden wird zuerst um flache Rüstung reduziert, auf mindestens 1 begrenzt und anschließend mit der Schildreduktion verrechnet.

Die tatsächliche Spielfigur verwendet eine eigene feste Körpermaske statt der großen Kunstfläche. Gegner-/Boss-Targeting, präzise Projektilproben, Schwertsektoren und gemeinsame Flächengeometrien sind getrennte Produktionspfade; eine reine Distanzsimulation würde sie nicht vollständig ersetzen.

Pause, Level-up, Truhe und Game Over werden durch aktuelle Zustände im Controller behandelt. Die Auswahl lernt nur den tatsächlich bestätigten angebotenen Eintrag. Bewegung wird nach Menü-/Auswahlklick mit einem Eingabeguard neu aktiviert. Der HUD liest Lebenswerte, sechs aktive und sechs passive Plätze, Cooldowns, Erfahrung, Level, Timer, Bossbalken und Minimap aus dem aktuellen Zustand. Zusätzlich zu den GUI-freien Weltbildern wurden die tatsächlichen HUD-/Tooltip-/Level-up-Produktionsfunktionen nativ auf 1280×720- und 800×600-Surfaces geprüft; die gefüllten zwölf Plätze und die betrachteten langen Texte sind lesbar und ohne Abschneiden. Dies ist keine Aufnahme einer echten Betriebssystem-Fenstergrößenänderung. Neue GUI-Bilder von Hauptmenü, Charakterauswahl, Einstellungen, Pause und Game Over fehlen in dieser Serie; Einzelheiten und Bildlinks stehen in `VISUAL_AUDIT.md`.

## Audio und Grafik

Die 88 vorhandenen Sound-Ressourcen bestehen aus drei Musikstücken und 85 Effekten. Der zentrale Mixer begrenzt Effekte auf 16 Stimmen und zwei Stimmen je Cue; Menü-/Level-/Bossmusik hat eine 0,65-s-Überblendung und Schutz vor demselben wiederholten Start. Musik und Effekte besitzen getrennte Lautstärken. Die vorhandenen programmatisch synthetisierten Musik-/Effektdateien bleiben Prototypen; eine Ressourcenprüfung ist keine musikalische Hörprüfung.

Das Grafik-Inventar, die native Prüfung der korrigierten Trefferreaktion und die aktuellen Waldaufnahmen sind in `VISUAL_AUDIT.md` dokumentiert. Keine bestehende Drachen-PNG wurde verändert. Der aktuelle Grafikfeinschliff betrifft ausschließlich die Begrenzung des Draw-Frames bei einmaligen Reaktionen der neuen Bosse.
