# Erster Hauptboss: Aschenflügel

Stand: 22.11.2026. Der erste große Hauptboss bleibt im bestehenden Encounter-Zeitplan ab Minute 5 vorgesehen. Noch lebende frühere Begegnungen werden zuerst beendet. Die bestehende interne ID `storm_warden` bleibt kompatibel; angezeigt wird **ASCHENFLUEGEL**. Nur diese Begegnung verwendet den neuen Drachenkampf. Andere Hauptbosse bleiben nachrangige Prototypen.

## Bossbasis und Präsenz

4800 Basis-HP, etwa 300 Weltpixel Höhe, stabile Körper-Halbbreite 108 px. Neue große Körpergrafiken statt hochskalierter normaler Monstersprites. 24 neue Posen für Atmen, vier schwere Schritte, Ausrichten, Aufladen, mehrere Feueratemrichtungen, Stampfen, Treffer, Phase und dreistufigen Tod. Zusätzlich kontinuierliche subtile Brust-/Körperbewegung. Links und rechts verwenden gespiegelte konsistente Grafiken.

Der Drache verfolgt mit geglätteter Geschwindigkeit während der Erholungsfenster und versucht, seitlich mit seinem Maul auf Spielerhöhe zu kommen. Während Warnung und Feuer bleibt seine Bodenposition stabil. Normale Treffer verschieben ihn nicht. Bestehende sichere Anti-Kiting-Repositionierung, Richtungsanzeiger und größere Körpermasken bleiben erhalten. Die aktuelle Animation und die Atemrichtung bestimmen den passenden Maulanker.

Unter 50 % HP folgt ein eigener 1,8-sekündiger Phasenwechsel. Aktive Gefahren werden dabei entfernt. Phase zwei variiert die Reihenfolge und verkürzt Vorwarn-/Erholungszeiten; die angekündigten Gebiete und Schadensregeln bleiben nachvollziehbar.

## Vier tatsächliche Angriffe

| Angriff | Warnung und Ablauf | Trefferregeln |
|---|---|---|
| Horizontaler Feuerstrahl | Ausrichten, 1,25 s Aufladen, 420 px langer Strahl über 1,65 s. Richtung bleibt links oder rechts fest. Etwa 52,5 % der 800 px breiten Kamera. | 32 px breiter Kern, präzise Segmentdistanz mit Spieler-Körperradius; 22 Basisschaden, mindestens 0,4 s Abstand je erfolgreichem Strahltreffer. Hoher Angriff: Slide/Dodge schützen. |
| Sweeping Fire Beam | Eigene Atempose und Warnsektor; 520 px Reichweite. Dreht über 2,8 s langsam durch 110 Grad. Der Spieler wird nach Beginn nicht nachverfolgt. | 19 Basisschaden, dieselbe begrenzte Trefferfrequenz. Kopfpose, Maulanker und Feuer folgen dem tatsächlichen Winkel. Hinter dem Drachen bleibt ein Fluchtweg. |
| Feuerbogen | Angekündigter Halbkreis. Eine breitere Feuerfront schwenkt über 2,5 s durch 180 Grad, Reichweite 275 px. | Tatsächlicher aktueller Feuersektor ±18 Grad, 24 Basisschaden. Bodenangriff: Sprung und Dodge schützen. Der gesamte angekündigte Halbkreis wird nicht gleichzeitig unsichtbar beschädigt. |
| Magmastampfer | Fuß heben, schwer aufsetzen; exakt drei getrennte Bodenfelder mit 52 px Radius. 1,05 s weitere Kreiswarnung, dann 0,65 s Eruption mit eigener Grafik. | 42 Basisschaden je konkreter Eruption, höchstens ein erfolgreicher Treffer je Feld. Boden-/Luftbewegung alleine schützt nicht; markierte Zone verlassen oder Dodge nutzen. Zonen werden auch an Raumrändern getrennt platziert. |

Phase zwei verwendet 88 % der normalen Aufladezeit. Die Basiswerte werden mit dem vorhandenen Level-Schadensmultiplikator verrechnet. Warnungen richten sich nach echter Angriffsgeometrie, nicht nach zufälligen Effektpositionen. Zentrale Parameter: `scripts/dragon_boss/dragon_boss.gml`.

## Eigene Effekte

Vier neue animierte Feuersegmente, zwei Maulzündungen, zwei Magmaeruptionen. Strahl und Sweep richten das eigene Feuerbild entlang der tatsächlichen Schadenslinie aus; der Feuerbogen verwendet mehrere animierte Feuerbahnen innerhalb der aktuellen Front. Eigene Warnlinien, Sektorgrenzen und Kreisfüllungen zeigen den Angriff vorher an.

Feuer erhellt Maul, Strahlmitte und Strahlende über das vorhandene zentrale Lichtsystem. Stampfen und Magma erzeugen zusätzliche warme Impulse. Telegraphen und Angriffe werden nach der Lichtfläche gezeichnet. Grafikquellen, Prompts, Maulanker und Importschritte: `FirstGame_ArtPack/dragon_boss/README.md`.

## Magnet-Orb korrigiert

Die Orb-Ressource hatte fälschlich Kollisionsobjekt-Verweise an Create-, Step- und Draw-Events. Diese normalen Events sind jetzt korrekt registriert. Die Aufnahmeprüfung berücksichtigt die sichtbare Berührung mit 38 px Abstand.

Ein zentraler, wiederholungssicherer Boss-Todesabschluss erzeugt **genau eine Truhe und einen Orb 42 px daneben**. Beim Drachen passiert das sofort beim tatsächlichen HP-Tod; die kurze Todesanimation bleibt danach als ungefährlicher Körper bestehen. Wiederholte Todesverarbeitung erzeugt keine weiteren Belohnungen. Mini- und andere Bosse verwenden dieselbe einmalige Belohnungsfunktion. Normale Gegner und die frühere Zufallsroutine erzeugen keine Orbs mehr.

Bei Aufnahme werden alle zu diesem Zeitpunkt vorhandenen Münzen markiert. Ihre Bewegung folgt in jedem Step der aktuellen Spielerposition, ohne Überschießen, falsche Zielrichtung oder doppelte Gutschrift. Truhenauswahl pausiert die Welt; nach deren Bestätigung kann der danebenliegende Orb regulär aufgenommen werden.

Normaler Pickup-Radius weiterhin 96 px. Münzanziehung erhöht von 150 auf 210 px/s, Magnetflug von 720 auf 960 px/s. Zentrale Audiobegrenzung bleibt erhalten.

## Echte Run-Statistiken im bestehenden Pausemenü

Beim Hover über eine Fähigkeit zeigt derselbe Detail-Tooltip jetzt zuerst:

- Tatsächlich verursachten Gesamtschaden im aktuellen Run, ohne Overkill.
- Tatsächlich wiederhergestellte HP, ohne Überheilung.
- Anzahl direkter erfolgreicher Treffer.
- Anzahl erfolgreicher aktiver Auslösungen.
- Bei Orbit Shield zusätzlich tatsächlich verhinderten Schaden.
- Bei Split Runes zusätzlich erzeugte Zusatzgeschosse.

Feuerexplosion und nachfolgendes Brennen zählen beide zum Feuerball; Brenn-Ticks erhöhen die Schadenssumme, nicht künstlich die Anzahl direkter Treffer. Eis, Kettenblitz, Nova, Barrage und Orbit haben eigene Zuordnung. Heilung und Vitality zählen nur ihren realen HP-Zuwachs. Waffen bleiben eine getrennte Schadensquelle. Indirekte passive Modifikatoren werden als solche bezeichnet; ihr Angriffsschaden wird nicht doppelt gezählt. Neue Runde setzt sämtliche Werte zurück.

## Testmethode und Grenzen

Die lokale Suite `python tests/tools/run_dragon_smoke.py` baut eine isolierte Windows-VM-Projektkopie. Eingaben und Szenensteuerung werden ausschließlich dort injiziert. Neun Klassen-/Levelstarts und vorhandene Regressionen bleiben enthalten. Hinzu kommen direkte Schadens-/Warnzonenprüfungen für alle vier Drachenangriffe, Animationstimer, Phase, Todesanimation, einmalige Belohnung, tatsächliche Orb-Aufnahme, Münzflug und exakte Statistikwerte.

Der native Szenenlauf führt die Produktionszustände aus und exportiert Draw-Ausgaben für Idle, Strahlwarnung, Strahl, Sweep, Feuerbogen, drei Magmawarnungen, Eruption, Phase, Tod und Pause-Statistik. Er führt anschließend eine echte Truhenauswahl mit Bestätigung und Orb-Berührung aus. Für die lange visuelle Folge besitzt ausschließlich diese Fixture eine erhöhte HP-Basis, damit sie alle Zustände zeigen kann. Schadenswerte werden vorher unabhängig mit exakten HP-Deltas geprüft. Das ist keine menschlich gewonnene Bossrunde und kein Beweis abschließenden Balancings.

Die zusätzliche Betriebssystem-Fensteraufnahme konnte das kurzlebige Testfenster vor dessen Ende nicht erfassen. Die nativen Draw-Exporte bilden daher den visuellen Nachweis; eine manuelle vollständige Bossrunde bleibt **NOT RUN**.

Weitere flüssige Zwischenwinkel und zusätzliche gezeichnete Zwischenframes bleiben eine mögliche Qualitätsverbesserung. Keine weiteren Bosse, Klassen oder Level wurden neu entwickelt; kein Git-Push und keine externe kostenpflichtige API.

## Abschließender Prüfstatus

**PASS:** 259 Runtime-Prüfungen, neun Klassen-/Levelkombinationen, Exitcode 0. Projektprüfung: 348 Ressourcen, keine Fehler oder Warnungen. Normaler Windows-Build und ZIP erfolgreich, ohne Test-Hooks: `output/production-build/20261122-174903/FirstGame.zip`.

| Teil | Status | Tatsächlicher Nachweis |
|---|---|---|
| Spawn, Größe, Atmen, Verfolgung | PASS | Reale Encounter-Erzeugung, Animationszeitgeber und native Draw-Bilder. |
| Horizontaler Strahl | PASS | Warnzeit ohne Schaden, 420 px Reichweite, exakter HP-Abzug, Tick-Abstand und sichere Positionen außerhalb des Strahls. |
| Sweep und Feuerbogen | PASS | Gradueller 110-Grad-Sweep, aktueller breiter Feuersektor, Innen-/Außentests und native Renderbilder. |
| Stampfen und drei Magmafelder | PASS | Genau drei getrennte Zonen, inklusive Raumrand; kein Warnschaden, echter Eruptionsschaden, keine wiederholten Frame-Treffer. |
| Phase und Tod | PASS | 50-%-Übergang, eigene Posen, ungefährlicher sterbender Körper und anschließendes Entfernen. |
| Truhe und genau ein Orb | PASS | Sofort beim HP-Tod, auch Mini; wiederholte Aufrufe duplizieren weder Belohnungen noch XP. |
| Orb-Kontakt und Münzen | PASS | Tatsächliches Step-Event; native Truhenbestätigung vor Orb-Aufnahme; alle 60 entfernten Münzen im laufenden Spiel angeliefert. Zusätzlich 500 Münzen direkt durch die Produktionslogik einmalig gutgeschrieben. |
| Run-Statistik | PASS | Overkill-/Overheal-Begrenzung, Brennzuordnung, direkte Treffer/Auslösungen, Schildreduktion und Reset; im Pause-Tooltip sichtbar. |
| Vollständig interpolierte Kopfbewegung | PARTIAL | Mehrere eigene Winkelposen und passende Maulanker; keine kontinuierliche Skelettanimation. |
| Zusätzliche OS-Fensteraufnahme | BLOCKED | Capture meldete „foreground window did not report a process id“; bei der Erholung war das kurzlebige Testfenster bereits geschlossen. Native Renderexporte liegen vor. |
| Menschlich gewonnene vollständige Bossrunde | NOT RUN | Abschließendes Schwierigkeits-/Fairnessgefühl bleibt einem Spieltest vorbehalten. |

Der native achtsekündige Waldläufer-Regressionslauf mit zeitgesteuertem Sprung/Dodge sah bis zu 29 Gegner und lieferte im Mittel 16.6666 ms pro Frame. Das ist keine separate GPU-Leistungsmessung des gesamten Bosskampfs. Es wurde keine 30-Minuten-Simulation durchgeführt.

Maschinenlesbare Ergebnisse: [Runtime](tests/reports/dragon-smoke-result.json), [Statusübersicht](tests/reports/dragon-verification.json).

Geprüfte native Bilder: [Idle](tests/reports/dragonidle.png), [Warnung](tests/reports/dragonwarning.png), [Feuerstrahl](tests/reports/dragonbeam.png), [Sweep](tests/reports/dragonsweep.png), [Feuerbogen](tests/reports/dragonarc.png), [drei Zonen](tests/reports/magmazones.png), [Magma](tests/reports/magmaeruption.png), [Phase](tests/reports/dragonphase.png), [Tod mit Orb](tests/reports/dragondeath.png), [Pause-Statistik](tests/reports/dragonstats.png).

## Direkt selbst testen

Der erste Hauptdrache erscheint regulär ab Minute 5. Für den bestehenden Entwicklungsmodus die EXE mit `--boss-dev` starten, eine Runde beginnen und F6 drücken. F7 setzt Phase zwei, F8 startet nacheinander die vier Drachenmuster, F9 schaltet die vorhandene Zeitlupe um. Ohne Entwicklungsflag bleiben diese Shortcuts im normalen Build gesperrt. Alle bisherigen Smoke-Einstiege leiten auf die aktuelle Drachen-Suite weiter.
