# FirstGame – Boss-System 2.0

Stand: 23.11.2026. Der bestehende Klassen-/Drachenstand wurde übernommen und um zwei Hauptboss-Begegnungen, gemeinsame Skalierung und einen direkten Boss-Testmodus erweitert. Zentrale Fähigkeiten- und Mechanikdokumentation: [BOSS_CATALOG.md](BOSS_CATALOG.md).

## 1–3. Referenzen, tatsächliche Grafiken und spielbare Bosse

Die beiden tatsächlich geöffneten Konzepttafeln sind `FirstGame_ArtPack/ChatGPT-Bild 22. Nov. 2026, 23_00_30.png` (Zwillingshexen) und `ChatGPT-Bild 22. Nov. 2026, 23_00_42.png` (Sumpfbehemoth). Die Originale bleiben unverändert.

Tatsächlich erzeugt und importiert: acht neue Rasteratlanten, 196 unterschiedliche vorbereitete Ausgangsframes, daraus **54 GameMaker-Sprites mit 204 nativen Frame-Dateien**. Enthalten sind beide Hexen, 48 Behemoth-Posen, neun Vierframe-Effektfolgen pro neuer Begegnung, Feuer-/Eis-Flugprojektile und eine eigene Sumpfbrut. Quellen, Prompts, Zuschnitt-/Importwerkzeuge und Alpha-Prüfung liegen unter `FirstGame_ArtPack/boss_v2`. Die Konzepttafeln wurden nicht als beschriftete Spielsprites zugeschnitten. Vorhandene Spieler- und Drachenressourcen wurden bytegenau gegen den vorherigen erfolgreichen nativen Snapshot geprüft: **2.962 Dateien unverändert**.

Vollständig technisch spielbar und im Hauptbosspool: **Aschenflügel, Zwillingshexen und Sumpfbehemoth**. Die bisherigen beiden Minibosse bleiben erhalten. Frühere generische Echo-Platzhalter sind aus dem regulären Hauptbossplan entfernt und im Katalog ausdrücklich als frühere Varianten beschrieben.

## 4. Zwillingshexen

Neun tatsächlich ausgeführte Fähigkeiten: Doppelte Geschosssalve, rotierender Feuer-Eis-Ring, Meteoriten-/Eissplitterregen, Verbindungsstrahl, dualer Spiralwirbel, Kreuzschlag-Strahlen, brennender Froststoß, vereinigte Zonenflut und duale Nova.

Eine Instanz koordiniert zwei separat treffbare Figuren. Schaden an Feuer- oder Eishexe reduziert denselben gemeinsamen HP-Pool; Tod und Belohnung erfolgen einmal für die Begegnung. Die Hexen fliegen in liegender Acht, Kreis, diagonaler Kreuzung, gemeinsamem Sturz, getrennter Positionierung oder verketteter Verfolgung. Bewegte Strahlen verwenden die tatsächlichen Handpositionen für Darstellung und Kollisionsgeometrie. Gegenläufige Spiralringe besitzen sichere Lücken. Die Nova wechselt äußeren Gefahrenring, inneren Einschlag und abschließenden äußeren Energiestoß.

Die Figuren besitzen eigene Idle-, Flug-, schnellen Flug-, Vorbereitungs-, Cast-, Ritual-, Treffer-/Phasen- und Todesframes. Einzelne Turn-/Reaktionsposen werden wiederverwendet; das wird nicht als zusätzliche unabhängig gezeichnete Animation ausgegeben.

## 5. Sumpfbehemoth

Neun tatsächliche Mechaniken: Giftgespucke mit Flug/Flächenaufprall und Giftstatus, endliche Säurepfützen mit wiederholtem Schaden, angekündigte Wurzeln mit kurzer Bewegungsbegrenzung, wachsende/explodierende Pilze mit Sporenwolken, springbare Bodenschockwelle, auf sechs Kreaturen begrenzte Sumpfbrut, Giftatem, bewegte Sumpfwelle und mehrstufige Verfallsblüte.

Der Behemoth bewegt sich langsam und verwendet eigene Holz-/Knochen-/Pilz-Körperposen für Lauf, Drehung, Wurzeln, Spucken, Stampfen, Beschwören, Atem, Welle, Blüte, Treffer, Phasen und Tod. Die Unterstützungskreaturen gehören ausschließlich zum Boss, verschwinden mit ihm beziehungsweise nach 18 Sekunden und verändern den normalen Gegnerpool nicht.

## 6–7. Zeitfreischaltung und zufällige Auswahl

Beim tatsächlichen Spawn werden gespeichert: Spielzeit, freigeschalteter Pool und sämtliche Skalierungsfaktoren. Minute 5: Fähigkeiten **1–3**, Minute 10: **1–6**, ab Minute 15: **1–9**. Auch spätere HP-Phasen können diese Grenze nicht umgehen. Ein laufender Kampf bekommt bei einem globalen Minutenwechsel keine neuen Fähigkeiten.

Zeitplan: Miniboss Minute 1 und 3, anschließend ein zufälliger verfügbarer Hauptboss bei Minute 5/10/15/20/25/30. Es gibt nur eine aktive Begegnung; verspätete Termine werden nacheinander abgearbeitet. Eine eigene Zufallsfolge ist von Partikeln unabhängig. Normale Runden bekommen einen neuen Seed; Testbegegnungen sind mit ihrem Seed reproduzierbar.

Der Pool verlangt neun implementierte Profile und tatsächlich vorhandene Körperanimationen, VFX und Audiocues. Eine unvollständige Definition beziehungsweise fehlende Ressource wird nicht als regulär verfügbar ausgewählt.

## 8–9. Dezenter Countdown und gewöhnliche Projektile

Die zentrale Komponente unterstützt Kreis, Fächer, Linie, Rechteck und Ring sowie bewegte Geometrie. Die gesamte Gefahrenzone ist sehr schwach sichtbar, die Kontur dünn und dezent. Ein kleiner heller Uhrzeiger läuft von zwölf Uhr im Uhrzeigersinn. Beim Abschluss blitzt die Zone kurz auf; aktive Trefferprüfung beginnt ohne zusätzliche Wartephase. Der Besitzer-Zeitwert steuert Warnung und Schaden gemeinsam, einschließlich Pause. Neue Felder werden nicht schon im Erzeugungsframe um einen zusätzlichen Simulationsschritt vorgerückt.

Keine zusätzlichen Bodenwarnungen für gewöhnliche Feuer-/Eisgeschosse der Hexen, Giftgespucke, Waldwächter-Autoschüsse sowie sichtbare Drachen-Void-/Salven-/Windprojektile. Ihre Abschussanimation und tatsächlichen Geschosse bleiben sichtbar. Große Strahlen, Regen-Einschläge, Magma, Giftflächen, Wurzeln und Schockwellen verwenden weiterhin den Countdown.

## 10. Passive Voraussetzungen

Zentrale `requirements_any`-/`requirements_all`-Listen stehen in der gemeinsamen Fähigkeitsdefinition. Sie filtern neue und vorhandene Upgrade-Angebote; die gewichtete Auswahl bleibt reproduzierbar. Allgemeine Passiven bleiben verfügbar. Tooltips nennen die tatsächlichen aktiven Zaubernamen.

Abhängig sind **Split Runes, Ember Oath, Storm Conductor, Winter Heart, Lingering Hex und Resonant Core**. Split Runes erscheint nur mit mindestens Fireball, Iceball oder Arcane Barrage, unabhängig von seinem zusätzlichen Klassen-Projektilbonus. Vollständige Voraussetzungsliste und Stufen: [SPELL_CATALOG.md](SPELL_CATALOG.md) beziehungsweise die zentrale `catalog.json` im Spell-Artpack.

## 11. Waldwächter

Die früher als große Fächer-Spezialattacke verwendeten Geschosse sind aus seiner normalen Sonderrotation entfernt. Stattdessen besitzt er einen einfachen sichtbaren automatischen Einzelschuss alle 1,6 Sekunden ohne Bodenwarnung. Seine Bodenblitz-/Wurfmechaniken bleiben erhalten. Der Runenwächter wurde nicht unnötig umgebaut.

## 12–13. Boss-Testmodus

Hauptmenü → **Boss testen**. Auswahl für Boss, Spielminute 5/10/15/20/25/30, Klasse, ausgewogenen/zufälligen gültigen Build, Schwierigkeit, einzelne Fähigkeit und Seed. Der Direktknopf **Drache / Minute 15 / alle neun** wurde nativ gestartet und geprüft. Gesperrte Einzelfähigkeiten werden abgewiesen.

Die ersten Presets verwenden Level 13/23/36 mit 15/26/40 Fähigkeitsentscheidungen für Minute 5/10/15. Spätere Testpresets sind ausdrücklich Entwicklungs-Konfigurationen. Ein Test beginnt mit den passenden aktiven/passiven Fähigkeiten und vollen, durch Passiven angepassten HP. Gleicher Seed erzeugt denselben zufälligen Boss, dieselbe Klasse und denselben gültigen Build.

Hilfen: F1 Schutz, F2 heilen/wiederbeleben, F3 nächste HP-Phase, F4 Boss auf 25%, F5 ausgewählte Attacke wiederholen, F10 Körperboxen. Verlassen beziehungsweise normaler Neustart entfernt die Testkonfiguration. Mit `BOSS_TEST_MENU_ENABLED` lässt sich der Entwicklungszugang später für Release-Pakete deaktivieren. Direkte lokale Testfunktionen sind im Katalog dokumentiert; Desktop-Mausautomation war nicht nötig.

## 14. Skalierung und Kampfdauer

Basis-HP: Drache/Behemoth 9.200, gemeinsamer Hexen-Pool 13.000. Bei Minute 5/10/15 und normalem Room1 entstehen daraus **12.420/17.480/23.000 HP** beziehungsweise **17.550/24.700/32.500 gemeinsame Hexen-HP**. Spätere Faktoren stehen im Katalog. Gegner-Schadensfaktor, Angriffshäufigkeit, Zusatzprojektile und Projektilgeschwindigkeit werden ebenfalls beim Spawn festgelegt. Keine versteckte Anpassung an den tatsächlichen Spielerschaden während des Kampfes; keine künstliche Mindestdauer.

Die nativen Schadensfenster verwenden echte Startwaffen, aktive Fähigkeiten, Passive, kritische Treffer und Produktion-DOT. Vergleich: zwölf Sekunden volle Angriffsmöglichkeiten und zwanzig Sekunden mit sieben Sekunden neuen Angriffsmöglichkeiten je zehn Sekunden. Bereits laufende Kombos, Geschosse und Felder laufen weiter. Ziele stehen still und die feindliche KI ist für diese Messungen ausgeschaltet. Die daraus berechnete HP/DPS-Kampfzeit ist **eine analytische Schätzung aus echter Runtime-Schadensmessung, kein menschlicher vollständiger Bosskampf**.

| Boss / Minute | Schwertkämpfer | Zaubermeisterin | Waldläufer |
|---|---|---|---|
| Drache / 5 | 123.2 s | 122.7 s | 133.2 s |
| Drache / 10 | 143.8 s | 144.3 s | 157.8 s |
| Drache / 15 | 155.9 s | 160.0 s | 160.1 s |
| Zwillingshexen / 5 | 130.7 s | 112.9 s | 113.3 s |
| Zwillingshexen / 10 | 148.7 s | 132.3 s | 134.4 s |
| Zwillingshexen / 15 | 160.3 s | 147.2 s | 135.4 s |
| Sumpfbehemoth / 5 | 123.2 s | 122.7 s | 133.2 s |
| Sumpfbehemoth / 10 | 143.8 s | 144.3 s | 157.8 s |
| Sumpfbehemoth / 15 | 155.9 s | 160.0 s | 160.1 s |

Die Tabelle nutzt das Fenster mit 70% neuen Angriffsmöglichkeiten. Die vollständigen gemessenen DPS, HP und beide Profile stehen im nativen JSON. Zwei Trefferkörper erhöhen insbesondere bei stationären Hexen die Flächeneffizienz. Ihre tatsächlichen Flugformationen verringern die Trefferquote; das ist hier nicht als vollständiger Kampf simuliert. Starke Builds dürfen die Zielzeit unterschreiten.

## 15. Tatsächlich ausgeführte Prüfungen

**PASS: 830 native Prüfungen, Exitcode 0, keine fehlgeschlagene Assertion.** Beleg: `tests/reports/boss-v2-native.json`, isolierter Lauf `output/boss-v2-smoke/20261123-061818`.

| Status | Nachweis |
|---|---|
| PASS | Alle drei Hauptbosse bei Minute 5, 10 und 15, Freischaltung 3/6/9 und unveränderliche Spawn-Skalierung |
| PASS | Alle 27 Fähigkeiten mit tatsächlichem Schaden beziehungsweise beschworenen angreifenden Kreaturen |
| PASS | Gemeinsame Hexen-HP, sechs Flugformationen, bewegter Strahl und genau eine Truhe/ein Orb |
| PASS | Säure-DOT, Gift-Aufprall, tatsächliche Wurzel-Bewegungsbegrenzung, sechs-Minions-Grenze und Cleanup |
| PASS | Countdown/Schaden bei 30/60/144 Hz synchron, keine frühe Feldschädigung, Pause hält beide an |
| PASS | Passive Voraussetzungen einschließlich kombinierter Any-/All-Regeln, gewichtete Angebote und echte Namen |
| PASS | Hauptmenü-Einstieg, direkter Drachenstart Minute 15, gezielte Attacke, reproduzierbare Tests und Rückkehr zur normalen Runde |
| PASS | Tatsächlich erzeugte Audiostimmen aller 18 neuen Cues; insgesamt 88 gültige WAVs |
| PASS | Unveränderte Schwert-Kombo mit echten HP-Treffern 11/13/19 |
| PASS | 150 Gegner mit KI, Regen und Bossfeldern: 60 Frameintervalle, Mittel 16,665 ms, Maximum 17,289 ms; kurze Stichprobe |
| PASS | Separater kurzer Aufnahmelauf für vollständiges Testmenü und aktive Verfallsblüten; ersetzt den Gameplay-Nachweis nicht |
| PASS | Neue Ressourcen-/Originalprüfung: 54 Sprites, 204 native Frames, 18 Cues; 2.962 vorherige Spieler-/Drachendateien bytegleich |
| FAIL, bereits vorhanden | Der strenge lokale Quellgraph-Validator meldet drei unregistrierte alte `Collision_ObjectMonster.gml`-Dateien bei Fireball/Iceball/Lightningball. Dateien und Eventregistrierungen sind bytegleich mit dem vorherigen erfolgreichen 505-Prüfungen-Snapshot. Sie wurden zur Erhaltung vorhandener Änderungen nicht verschoben oder aktiviert; neue Bossressourcen erzeugen keine zusätzlichen Graphfehler. |
| NOT RUN | Menschliche vollständige Bosskämpfe, langfristige Performance und subjektive Hörabnahme |

Die 18 neuen WAVs sind eigene mehrschichtige Synthese-Prototypen. Quellen: `Audio/Sources/compose_boss_v2.py`, tatsächliche Dateien `Audio/Bosses/twins_1.wav` bis `twins_9.wav` und `swamp_1.wav` bis `swamp_9.wav`. Farbige Lichtimpulse und die bestehende Stimmen-/Lautstärkenbegrenzung sind integriert. Alle Rasterquellen, Prompts und Generatoren bleiben editierbar erhalten.

## 16. Fertig, geteilt und noch offen

Alle drei Hauptbosse, ihre 27 Fähigkeiten, Zeitfreischaltung, Auswahl, Countdown, Testmodus und passive Voraussetzungen sind technisch integriert und nativ geprüft. Keine neue normale Karte wurde ergänzt, keine kostenpflichtige API verwendet und kein Git-Push ausgeführt.

Generierte Körperanimationen sind nutzbar, aber nicht jeder Stoff-/Pilz-/Gesichtsframe manuell pixelweise abgenommen. Turn sowie einzelne Hurt-/Phasenposen teilen Ausgangsframes; das wird nicht als zusätzliche unabhängige Animation dargestellt. Offen bleiben künstlerischer Feinschliff, menschliche Bossfairness-/Langzeit-Spieltests, Hörabnahme und die drei bereits vorhandenen Quellgraph-Funde. Kampfdauern bleiben bis zu echten vollständigen Spieltests als analytische Werte gekennzeichnet.

**PASS: normaler Windows-Build, Compile und Paket erfolgreich, ohne injizierten Testharness.** [Aktuelles Spielpaket](output/production-build/20261123-062150/FirstGame.zip). [Buildnachweis](tests/reports/boss-v2-build.json). Das gewünschte Entwicklungsmenü ist enthalten. ZIP-CRC vollständig geprüft.

[Boss-Testmenü](tests/reports/boss-v2-test-menu.png) · [Bewegter Hexenstrahl](tests/reports/boss-v2-twins-link-active.png) · [Verfallsblüte](tests/reports/boss-v2-behemoth-bloom-active.png) · [Dezenter Countdown](tests/reports/boss-v2-subtle-warning-50.png)
