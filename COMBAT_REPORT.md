# Kampfgefühl, Pickups, Wetter und Drachenkorrekturen

Stand: 22.11.2026. Dieser Bericht ersetzt abweichende Waffen-, Pickup-, Wetter- und Drachenwerte aus älteren Berichten. Die XP-Kurve wurde bewusst nicht verändert.

## Magnet-Orb und echte Berührung

Ein Boss-/Miniboss-Abschluss hinterlässt weiterhin wiederholungssicher eine Truhe und genau einen Orb daneben. Normale Gegner erzeugen keine Orbs. Der Orb wird vor Weltfiguren gezeichnet; ein dünner cyanfarbener Ring und eine Beschriftung in Spielnähe verhindern, dass er unter dem sterbenden Boss verschwindet.

Der sichtbare Orb schwebt zwölf Pixel über seinem Bodenpunkt. Seine eigene elliptische Kollisionsmaske berücksichtigt genau diesen Versatz. Normale Aufnahme läuft über `Collision_ObjectPlayer`. Der gemeinsame Handler prüft zusätzlich Objektart, tatsächlichen Spieler, Run-Zuordnung, Berührung, Pause und Einmal-Sperre. Ein entfernter Funktionsaufruf oder ein fremdes Objekt kann keinen Magneten auslösen. Eine ergänzende Streckenprüfung fängt schnelle Bewegungen durch den Orb ab; große Teleports zählen nicht als durchlaufener Weg.

Erst nach gültiger Aufnahme werden alle aktuellen Coin-Instanzen aktiviert und markiert. Das erfasst andere Instanz-Layer, Offscreen-Münzen und deaktivierte Altinstanzen. Neu erzeugte Münzen übernehmen den vergangenen Magneten nicht. Beim Rundenneustart werden auch deaktivierte alte Münzen und Orbs entfernt. Jeder Coin hat eine Einmal-Sperre für XP, unabhängig davon, ob Step oder Kollisionsereignis die Aufnahme auslöst.

Normalradius unverändert 96 px. Normales Anziehen jetzt 252 statt 210 px/s. Magnetflug beginnt bei 1000 px/s und beschleunigt mit 1800 px/s² auf höchstens 2400 px/s. Jede Bewegung ist auf die restliche Strecke begrenzt und folgt der aktuellen Spielerposition. Zentrale Parameter und Schutzprüfungen: `scripts/combat_feedback/combat_feedback.gml`.

## Die drei Startwaffen

| Klasse | Neue Ausführung | Grundlage bei 60 Hz |
|---|---|---|
| Krieger | Größerer Schwertsektor mit 116 statt 92 px Reichweite, sichtbarer Bogen und Trefferfunken. Jeder Gegner höchstens einmal je Schwung. | 18 + 1,5 × Power; 44 Schritte Cooldown. |
| Magier | Drei echte Projektile je Basisangriff, zentral und ±7 Grad. Seitliche Startpunkte machen den Fächer lesbarer. Ein gemeinsamer Cooldown. | 7 + 0,6 × Power je Geschoss; 64 Schritte. Bei Basis-Power 4: drei × 9 Schaden. |
| Waldläufer | Deutlich längerer sichtbarer Bolzen mit Spitze und Schaft. Durchdringt sämtliche gültigen Gegner bis zum Ende seiner Flugzeit/Reichweite. Eine Trefferliste verhindert erneuten Schaden am selben Ziel. | 16 + 0,8 × Power; 70 Schritte; Reichweite 580 px. |

Der Magier erhielt nicht einfach den bisherigen Einzelschaden dreimal: Bei Basiswerten steigt das theoretische Einzeltarget-DPS bei drei Treffern um etwa 53 %, nicht um 200 %. Der Fächer verteilt Treffer in normalen Gruppen; große Ziele können mehrere Projektile erhalten. Split Runes kommt zusätzlich zum jeweiligen Basisgeschossmuster hinzu.

## Darstellung, Trefferflächen und Rückstoß

Feuerprojektile werden nun mit 60 statt etwa 42 px Canvasbreite dargestellt, Eis mit 56 statt etwa 42 px. Stab-/arkane Projektile verwenden 104 statt etwa 83 px. Der Bolzen hat eine ungefähr 31 px lange klar gezeichnete Silhouette. Die freigegebenen aktuellen ArtPack-Grafiken bleiben die Quelle.

Geschosse bewegen sich in höchstens zwei Pixel langen Teilstrecken. Die Kollision sitzt am sichtbaren Geschosskopf statt am transparenten Spritezentrum: kleiner Kopf-Collider beim Bolzen, passende größere Kreis-Collider bei Magie, Feuer und Eis. Native alte Projektil-Kollisionsereignisse sind entfernt; die gemeinsame Bewegung führt Treffer genau einmal aus. Piercing-Bolzen prüfen alle überlagerten Ziele und überspringen bereits getroffene Instanzen.

Alle Fernkampftreffer erzeugen kurze, farblich passende Einschläge an der echten Kontaktposition. Schwert, Bolzen, blaues Magiegeschoss, violette arkane Magie, Feuer, Eis und Schock unterscheiden sich. Explosion, Nova, Heilpuls und Kettenblitz behalten ihre eigenen größeren Wirkungen. Maximal 72 kurze Einschläge und 96 Schadenslabels; Bosswarnungen werden nach diesen Effekten gezeichnet.

Gemeinsame Trefferreaktion: 0,12 s Hit-Stun, normale Rückstoßgeschwindigkeit 145 px/s mit raschem Abklingen. Eine 0,42-s-Sperre verhindert dauerhaftes Festhalten durch schnelle Folgetreffer. Normale Gegner werden sichtbar versetzt, große normale Gegner haben 65 % Widerstand; Bosse erhalten keine gewöhnliche Verschiebung oder Hit-Stun. Der Drache bleibt dadurch gewichtig. Stun stoppt auch gewöhnlichen Kontaktschaden während seiner kurzen Dauer; Statuszeiten laufen weiter.

Schadensquellen heißen zentral `Base Weapon`, `Active Spell`, `Passive Effect` und `Status Damage`. Grundangriffe bleiben weiß, auch mit einem passiven Wertebonus. Eigene aktive/passive Treffer und Statusschaden sind gelb. Alte doppelte Einzelanzeigen sind entfernt. Brenn-Ticks werden pro Ziel/Quelle in kurzen Zeitfenstern zusammengefasst.

## Audio

Vorhandene Start-/Treffergeräusche werden weiterverwendet. Zusätzlich tatsächlich neu erzeugt und importiert:

- `Audio/Spells/magic_hit.wav`
- `Audio/Spells/ice_hit.wav`
- `Audio/Spells/arcane_hit.wav`
- `Audio/Spells/nova_cast.wav`
- `Audio/Spells/heal_cast.wav`
- `Audio/Spells/shock_hit.wav`

Eigene kurze Synthese-Prototypen aus `Audio/Sources/compose_combat_cues.py`, keine Downloads oder externen APIs. Alle sind echte 32-kHz-/16-Bit-Mono-WAVs. Start und tatsächlicher Treffer lösen unterschiedliche Events aus; ein Fehlschuss erzeugt keinen Treffercue. Schwert, Armbrust, Stab und alle sechs aktiven Zauber haben passende Auslöser.

Bestehende Master-/Musik-/Effektlautstärke und Fokusoption bleiben wirksam. Zusätzlich höchstens zwei gleichzeitig laufende Stimmen desselben Cues, globale Grenze 16 Effekte und bestehende Mindestabstände. Die automatischen Dreifachschüsse starten den Abschusscue einmal je Angriff. Die unabhängige Dateiprüfung umfasst nun 36 reale Audiodateien: drei Musikstücke und 33 Effekte. Eine subjektive Hörabnahme bleibt offen.

## Mausauswahl und Run-Statistik

Level-up- und Truhenauswahl benötigen einen neuen Linksklick auf eine sichtbare Karte nach Loslassen der Taste. Leertaste, WASD, Sprung und Dodge bestätigen keine Fähigkeit. Während der Auswahl steht die Gameplay-Simulation. Gehaltene Maus kann keine weitere Auswahl verbrauchen; nach Bestätigung wird die Bewegungseingabe sauber wieder freigegeben.

Neben jeder aktiven/passiven Fähigkeit stehen jetzt ständig kompakte echte Run-Werte: **D** Schaden, **H** Heilung, **A** Auslösungen, **T** Treffer. Name, Icon, neun Orbs und Detail-Tooltip bleiben erhalten; eine kleine Legende erklärt die Kürzel. Hover zeigt zusätzlich die ausführlichen Werte einschließlich DoT-Anteil, verhinderten Schildschaden und Zusatzgeschosse.

Gezählt werden tatsächliche HP-Abzüge ohne Overkill sowie tatsächliche Heilung ohne Überheilung. Feuerball führt Explosion und Brennen unter derselben Quelle zusammen, ohne jeden Brenn-Tick als direkten Treffer zu zählen. Kettenblitz zählt alle real getroffenen Ziele. Orbit-Kontakte, Vitality-Heilungen und Zusatzgeschoss-Ereignisse haben passende passive Auslösungszähler. Reine Werteboni erhalten keinen erfundenen Schaden; ihre Beschreibung erläutert den Bonus, der Gesamtschaden bleibt beim tatsächlichen Angriff. Rundenneustart leert sämtliche Werte.

## Drachenziel und Phasensynchronisierung

Gerader Feueratem erfasst jetzt die wirkliche Spielerposition statt nur links/rechts waagerecht zu wählen. Kopfpose und Maulanker werden dazu gewählt, danach bleiben Zielwinkel und Ursprung für diesen Strahl fest. Er funktioniert auch schräg, aufwärts und abwärts. Sweep und Feuerbogen richten ihren angekündigten Bereich ebenfalls um das erfasste Ziel aus; anschließend laufen ihre festgelegten Schwenks ohne spontane Spieler-Nachführung.

Die Strahlwarnung ist ein korrekt senkrecht zur Strahlrichtung versetzter Korridor, auch bei vertikalen Angriffen. Warnungen sind harmlos. Beim Wechsel auf aktiv wird die Trefferprüfung noch im selben Step ausgeführt, also unmittelbar beim ersten sichtbaren aktiven Kontakt. Nach Wechsel in Erholung verursacht der Strahl keinen Schaden mehr.

Vorwarnung 0,95 s, in Phase zwei nochmals 12 % kürzer. Strahl 36, Sweep 30, Feuerbogen 36 Basisschaden je erfolgreichem Kontakt, mindestens 0,28 s zwischen Strahltreffern. Magma 64 Schaden mit 0,85 s Kreiswarnung und 0,55 s aktivem Feld. Strahl aktiv 1,3 s, Sweep 2,2 s, Bogen 1,9 s. Erholungsfenster 1,05/0,75 s, Verfolgung bis 78 px/s mit Glättung. Levelmultiplikatoren und bestehende Angriffs-Höhenregeln bleiben wirksam: Slide schützt vor hohen Strahlen, Sprung vor dem Bodenbogen, Dodge schützt passend; Magma verlangt Verlassen der Zone oder Dodge.

## Wetter und Beleuchtung

Zentrales, kamerabezogenes Wetter ohne Partikelinstanzen. Unterstützt klar, subtilen Nebel, Wind, kurze Böen, leichten/starken Regen und wechselnde Sonnenintensität. Übergänge werden weich angenähert statt abrupt umgeschaltet.

Waldprofil: leichte Nebelschichten, gelegentliche achtsekündige Böen mit Blättern, anschließende Bewölkung und Regen. Typische Regenfolge: 15 s Anregnen, 45 s stärkerer Regen, 15 s Abschwächen, danach 25 s Aufhellung. Dauer und Übergänge liegen zentral in `scripts/weather`; die anderen vorhandenen Karten haben eigene Nebel-/Wind-/Regenintensitäten und Umgebungsfarben.

Die Wald-Grundfarbe der Lichtfläche ist von (86,106,125) auf ungefähr (132,150,159) angehoben, mit begrenzter Wettermodulation und einem Helligkeitsminimum. Regen und Nebel verdunkeln Gegner nicht wieder bis zur Unlesbarkeit. Nur Pflanzen-/Baumframes der vorhandenen Dekoration schwingen leicht im Wind; Steine und Ruinen bleiben starr. Maximal 160 Regentropfen, 24 Blätter und sechs sanfte Nebelbereiche. Licht bleibt der gemeinsame halbauflösende Pass. Wetter und Kampfeffekte werden vor Boss-Telegraphen gezeichnet.

## Monster und XP-Auswertung

Normale Verfolgung verwendet zentral den Faktor **1,08**, also acht Prozent mehr Grundtempo. Bestehende geglättete Richtung, Trennung von Gruppen und Statusverlangsamung bleiben erhalten.

XP-Kosten unverändert: zuerst 1/2/3, danach `ceil(4 + 1.45 × (Level − 4))`. Level 52 bedeutet mindestens **1.856 ausgegebene XP**, nicht bereits einen halben 30-Minuten-Zeitbedarf. Mit drei erhaltenen Bosstruhen wären das 54 von 108 Auswahlschritten. Für Level 102 und sieben Bosstruhen – zusammen 108 Schritte – werden **7.336 Gesamt-XP** benötigt.

Unter der Annahme, dass bis Minute 7 die ersten drei Bosse 50 XP beigesteuert haben, entspricht die Beobachtung durchschnittlich 258 eingesammelten normalen Münzen pro Minute. Bei konstantem weiteren Durchschnitt wäre der volle Build ungefähr bei Minute **27,58** erreichbar. Ohne Kenntnis noch nicht ausgegebener Münzen und tatsächlich besiegter Bosse ist das eine Näherung.

Die Tabelle ist eine Sekunden-Budgetrechnung aus der tatsächlichen Konfiguration, keine nachträglich erfundene Messreihe deiner Runde. Werte sind Level / verfügbare Auswahlschritte, inklusive angenommener planmäßig besiegter Bosse und eingesammelter Truhen:

| Modell | 1 min | 3 min | 5 min | 7 min | 10 min | 30 min | Vollausbau |
|---|---|---|---|---|---|---|---|
| Bisheriges Erfolgsmodell: 45 + 14 × Minute Münzen/min | 10 / 10 | 18 / 19 | 26 / 28 | 32 / 34 | 42 / 45 | 106 / 108 | 28,83 min |
| Aus Beobachtung abgeleitet, danach konstant 258/min | 20 / 20 | 34 / 35 | 44 / 46 | 52 / 54 | 62 / 65 | 106 / 108 | 27,58 min |
| Gleicher Anker, danach 396/min | 20 / 20 | 34 / 35 | 44 / 46 | 52 / 54 | 66 / 69 | 125 / 108 | 20,92 min |
| Gleicher Anker, danach 180/min | 20 / 20 | 34 / 35 | 44 / 46 | 52 / 54 | 59 / 62 | 94 / 101 | nicht bis 30 min |

Damit wäre eine pauschale XP-Erhöhung allein wegen Level 52 nach sieben Minuten nicht begründet. Entscheidend ist die spätere tatsächliche Sammelrate. Die neuen stärkeren Klassenwaffen können diese verändern; deshalb wurden Messpunkte ergänzt, statt die Kurve blind zu ändern.

Künftige echte Runden speichern bei Minute 1/3/5/7/10/15/20/25/28/29/30 lokale Messwerte in `firstgame_progression_current.json` im GameMaker-Sandboxverzeichnis: Level, verdiente Münz-XP, Kills, Bosstode und tatsächlich vergebene Fähigkeitsstufen. Deine frühere Sieben-Minuten-Runde wurde zuvor nicht so aufgezeichnet und kann nicht rückwirkend rekonstruiert werden. Rechenquelle: `tests/tools/analyze_combat_progression.py`, Ausgabe `tests/reports/combat-progression.json`.

## Prüfungen und verbleibende Grenzen

Die aktuelle lokale Suite baut eine frische isolierte Windows-VM-Kopie. Eingabe- und Szenensteuerung existieren nur dort. Sie prüft neun Klassen-/Levelstarts, echte Mausbestätigung, gesperrte Tastaturwahl, drei funktionierende Magiergeschosse, fünf durchdrungene Gegner ohne zweiten Treffer, Rückstoß/Stun-Sperre, Quellenfarben, Audio-Engine-Aufrufe, Wetterprofile/-wechsel, vier Drachen-Zielrichtungen und sofortigen aktiven Schaden.

Der verbindliche native Magnettest verteilt 30 Münzen über den Raum, benutzt zwei Instanz-Layer und eine deaktivierte Münze. Zunächst bleibt alles ohne Orb unverändert. Danach bewegt eine normale Gameplay-Eingabe den Charakter durch den Orb; der Engine-Kollisionspfad wird separat gezählt. Der Test verlangt eine Aktivierung, 30 erfasste und angelieferte Coins, genau 30 XP und keine Reste. Ein direkter Funktionsaufruf ersetzt diesen Test nicht.

Weitere native Draw-Ausgaben zeigen Inline-Statistiken, helleren Wald, Windblätter, Regen, vertikale Warnung/Strahlen, Magma und sichtbaren Boss-Loot. Eine kurze zusätzliche Wetterlastszene enthält 150 Gegner, 160 Regentropfen und 24 Blätter; das Framezeit-Messfenster enthält keinen Screenshotexport.

Für die mehrteilige visuelle Bossfolge erhält ausschließlich die Testfixture erhöhte HP. Separat bleibt ein normaler unbewegter Charakter ungeschützt stehen und muss durch den korrekt gerichteten Feueratem sterben. Das ist ein Druck-/Schadensnachweis, keine menschlich gewonnene Bossrunde.

**NOT RUN:** vollständige menschliche Bossrunde, subjektive Audio-Hörabnahme, dauerhaftes GPU-Stressprofil und tatsächliche neue 1–30-Minuten-Spielmessreihe. Regenübergänge und die etwa einminütige Regenepisode werden zusätzlich beschleunigt durch die echte Zustandslogik geprüft; kein langer Echtzeit-KI-Dauerlauf.

 Keine neuen Klassen oder Level, keine bezahlten APIs, kein Git-Push.

## Abschlussprüfung

PASS: 131 gezielte Prüfungen in der tatsächlichen Windows-VM, einschließlich neun Klassen-/Raumstarts. Der native Magnetlauf meldet **1 Collision-Aktivierung, 0 Swept-Aktivierungen, 30 markierte und eingesammelte Coins, exakt 30 XP**. Die isolierte Handlerprüfung ruft den Handler mit explizitem Spieler auf; der getrennte Bewegungstest verwendet das echte Engine-Kollisionsereignis.

Wetterlast: 150 Gegner, 160 Regentropfen, 24 Blätter, 60 gemessene Frames: Mittel **18,28 ms**, Maximum **120,28 ms**. Dies belegt die begrenzten Effektmengen in einer kurzen Szene; die Spitze und fehlende Langzeitmessung erlauben keine Behauptung durchgehend stabiler 60 FPS.

Projektprüfung: **357 Ressourcen, keine Probleme oder Warnungen**. Audio: **36 gültige und korrekt registrierte WAVs**. Normaler Windows-Build und ZIP-Paket erfolgreich, ohne injizierte Testeingaben: [FirstGame.zip](output/production-build/20261122-190239/FirstGame.zip).

Nachweise: [Native Prüfergebnisse](tests/reports/combat-smoke-result.json), [Build](tests/reports/production-build.json), [XP-Modell mit Annahmen](tests/reports/combat-progression.json), [Audioprüfung](tests/reports/audio-files.json).

Bilder: [Magnetflug](tests/reports/combat-magnetflight.png), [Inline-Statistiken](tests/reports/combat-inlinepause.png), [gerichtete Warnung](tests/reports/combat-verticalwarning.png), [Wind](tests/reports/combat-gust.png), [Wetterlast](tests/reports/combat-raincrowd.png), [Boss-Loot](tests/reports/combat-loot.png).

## Nachfolgender Figurenauftrag

Die neue Schwertkämpferfigur und der darauf erneut geprüfte Gesamtstand stehen in [SWORDSMAN_REPORT.md](SWORDSMAN_REPORT.md). Danach bestehen 142 native Checks; der Magnet liefert weiterhin exakt 30 XP. Der obige Buildpfad bewahrt den Abschlussstand vor dem Figurenwechsel.

Nachfolgender vollständiger Welt-/Skelett-/Kombo-Umbau: [MASTER_WORLD_REPORT.md](MASTER_WORLD_REPORT.md). Dieser spätere Bericht ersetzt die älteren Aussagen zur aktiven Room1-Grafik und zur früheren Einzelschlagfolge.
