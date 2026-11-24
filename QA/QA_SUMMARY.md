# FirstGame – Ergebnis des autonomen QA-Durchlaufs

**Zwei konkrete Spielprobleme behoben:** Normale Münzen holen schnelle Spieler im Sammelradius zuverlässig ein; die Trefferreaktion der neuen Bosse springt nicht mehr auf einen falschen Frame zurück. Alle Grafikdateien einschließlich des bestehenden Drachenmodells sind erhalten. Die Testumgebung, Rohdaten, Diagramme und Berichte sind wiederverwendbar.

| Tatsächlicher Umfang | Anzahl |
|---|---:|
| Vollständige native Runs insgesamt | 192 |
| Davon primäre V2-Runs: Baseline / Nachher / unabhängige Seeds | 72 / 72 / 36 |
| Davon erste Bot-Strategie, nur Kalibrierung | 12 |
| Primäre isolierte Bosskämpfe / ausgewählte Nachher-Replays | 360 / 15 |
| Zusätzliche gültige Boss-Kalibrierungen und Pilot-Replays | 210 |
| Kontrollierte native Fähigkeitsfenster | 654 |
| Aktuelle allgemeine native Regressionsprüfungen | 811 |

**3.000 vollständige Runs wurden nicht ausgeführt.** Die erreichte Stichprobe wird ausdrücklich nicht als Tausende-Runs-Nachweis ausgegeben. Gemessene Laufzeiten und bedingte Hochrechnungen stehen im Simulationsbericht. Validierungen, kurze Schadensfenster und analytische Rechnungen zählen nicht als vollständige Spielrunden.

## Die 22 gewünschten Antworten

1. **Vollständige Runs:** 192 tatsächlich abgeschlossen, davon 180 primär und 12 Kalibrierung. Jeder Run endet durch tatsächlichen Tod oder die 30-Minuten-Grenze; begonnene, noch nicht abgeschlossene Runden sind ausgeschlossen.
2. **Bosskämpfe:** 585 gültige isolierte Ausführungen insgesamt. Für die primäre Statistik zählen 360 Bedingungen, dazu 15 kontrollierte Nachher-Replays; Kalibrierungen/Wiederholungen sind getrennt. Zusätzlich auftretende Bossbegegnungen innerhalb der vollständigen Runs sind in deren Rohdaten erhalten und hier nicht nochmals als isolierte Tests gezählt.
3. **Längstes mittleres Überleben:** In den 72 Nachher-Runs beobachtet: Sword, 285.5 Sekunden. Skill-Strata und breite Unsicherheitsintervalle stehen in CLASS_BALANCE.md; kein allgemeiner menschlicher Klassensieger behauptet.
4. **Minute 30:** Gepaarte Nachher-Serie Sword 0/24, Mage 0/24, Ranger 0/24. Unabhängige Seeds: Sword 1/12, Mage 0/12, Ranger 0/12. Der erfahrene Sword-Überlebende erreicht Vollausbau bei Minute 28,31. Eine einzelne Beobachtung ist kein Beweis allgemeiner Dominanz.
5. **Startwaffe:** Stationär gegen ein Ziel Sword 38,00, Mage 34,53, Ranger 28,40 HP/s; gegen acht Ziele Mage 235,67, Sword 222,93, Ranger 88,00. Reichweite und Sicherheit sind darin nicht bewertet; keine universelle stärkste Waffe abgeleitet.
6. **Anteil der Startwaffe am Nachher-Gesamtschaden:** Sword 32.2%, Mage 60.3%, Ranger 45.1%. Tatsächlich zugerechneter HP-Verlust; Details je Komboschritt in ABILITY_BALANCE.md.
7. **Hoher aktiver Schaden:** Im kontrollierten Stufe-9-Einzelzieltest Wisp Sentinel 65,73, Starfall 60,98, Arcane Barrage 46,67 HP/s. Gegen acht Ziele liegen Starfall, Ice Prison und Ember Field hoch. Das sind gemessene Fenster, keine vollständigen Builds.
8. **Auffällig niedriger direkter DPS:** Frost Nova. Kontrolle und Unterbrechung fehlen als Nutzenmaß im stationären DPS. Healing Pulse verursacht beabsichtigt keinen Schaden. Kein Zauber wird deshalb pauschal als nutzlos bezeichnet.
9. **Effektive Passiva:** Power Up, Split Runes und Quick Channel steigern den passenden gemessenen Angriff; Shield reduziert den 20-HP-Testtreffer auf 8 HP, Iron Skin auf 14,6. Vital Bloom und Regeneration liefern echte HP-Vorteile. Bewegungs-/Sammel- und Kontrollnutzen erfordern ergänzende Situationen.
10. **Kombinationen:** Längster beobachteter Nachher-Run: Sword, 23.58 Minuten; aktive Fähigkeiten Healing Pulse 9, Iceball 7, Stone Spikes 6, Piercing Lance 9, Ice Prison 6, Orbit Blades 6. Das ist eine Einzelbeobachtung. Keine ausreichend wiederholte kausale Rangliste sämtlicher Kombinationen.
11. **Zufall der Angebote:** Seeds, Angebote und gewählte Upgrades sind vollständig gespeichert. Die Überlebensstreuung ist gemessen; der isolierte kausale Anteil der Zauberauswahl ist mangels gekreuzter Gegenläufe nicht bestimmt. Weltzufall, Route und Build wirken gemeinsam.
12. **Schwierigster isolierter Boss dieser Preset-Stichprobe:** storm_warden, 34/72 Siege. BOSS_BALANCE.md trennt Klasse, Minute, Bot und die Entwicklungs-Presets.
13. **Häufig treffende Quellen:** behemoth:1 (669 HP-Treffer), twins:1 (410 HP-Treffer), behemoth:2 (377 HP-Treffer). Trefferzahl und Trefferquote sind verschieden; der Projektil-Bedrohungsnenner ist eingeschränkt.
14. **Kaum treffende Quellen:** storm_warden:8, twins:7, behemoth:4, behemoth:6. Geringe Exposition oder früh beendete Kämpfe können den Befund erklären; keine automatische Beschleunigung solcher Angriffe.
15. **Realistisch unvermeidbar:** Für keinen Angriff formal nachgewiesen. Sichtbare Warnungen, legale Eingaben und Hindernisse sind berücksichtigt; die technische Heuristik ist kein vollständiger Reachability-Beweis.
16. **Meiste tödliche Bossaktivierungen:** storm_warden:1 (26), twins:1 (13), twins:5 (12). Zuordnung und Timing-Grenzen stehen im Bossbericht.
17. **Geänderte Zahlen:** Normale Münzgeschwindigkeit 252 → 420 Pixel/Sekunde. Zusätzlich begrenzter Draw-Frame. Keine Klassen-/Boss-HP oder Waffen-/Zauberschäden angepasst.
18. **Nachgewiesene Verbesserung:** Der zuvor fehlschlagende bewegte Ranger-Sammelfall besteht jetzt auch mit Fleet Footed 9. Die vollständigen gepaarten Auswirkungen inklusive Unsicherheit stehen in BEFORE_AFTER.md; ein Überlebensgewinn wird nicht allein aus schnellerem Sammeln angenommen.
19. **Grafik-/Animationsänderung:** Genau die Boss-Hurt-/Death-Frame-Begrenzung im Zeichner. 826 Sprites/2.551 Frames geprüft; alle 5.102 PNGs einschließlich 258 Drachen-Dateien unverändert.
20. **Offene Grafikgrenzen:** Teilweise wiederholte Ausgangsposen, weitere Fensterseitenverhältnisse und längere Lesbarkeitsprüfung überlappender Wetter-/Kampfeffekte. Keine pauschale Weichzeichnung eingebaut.
21. **Tatsächliche Runtime:** Native vollständige Runs und Bosskämpfe, 654 native Fähigkeitsfenster, zehn bekannte HP-/Quellenprüfungen, vier bewegte Münzfälle, 811 aktuelle Regressionsprüfungen, Batch-/Uhren-/Hindernis-Fixtures und native GUI-/Weltaufnahmen. Der normale Build besitzt keine injizierten Test-Hooks. Keine menschlichen Spieltests behauptet.
22. **Kritische offene Fehler:** Kein neuer Runtime-Absturz in den abgeschlossenen kanonischen Datensätzen. Drei unveränderte alte unregistrierte Kollisionsdateien bleiben ein Metadatenbefund. Späte Progression, formale Boss-Unvermeidbarkeit und dauerhafte Performance sind nicht vollständig freigegeben.

## Nachweise und priorisierte Restarbeit

- [Simulation und Reichweite](SIMULATION_REPORT.md), [Klassenvergleich](CLASS_BALANCE.md), [Fähigkeiten](ABILITY_BALANCE.md), [Bosse und Fairness](BOSS_BALANCE.md).
- [Vorher/Nachher](BEFORE_AFTER.md), [Änderungswerte](BALANCE_CHANGES.md), [bestätigte Fehler und priorisierte Grenzen](BUG_REPORT.md), [Grafikaudit](VISUAL_AUDIT.md).
- [Simulatorabgleich und Grenzen](SIMULATOR_FIDELITY.md), [aktueller Projektbestand](PROJECT_INVENTORY.md), [Datenmanifest](data/dataset-manifest.json), [Diagramme](charts), [Wiederholung](README.md).

Priorität: ausreichend späte vollständige Runs und echte menschliche Vergleichsrouten; danach gezielte schwierige Bossgeometrien mit vollständiger Wegprüfung. Wiederholte Kombinationstests und dauerhafte Render-/Speicherlast folgen. Die automatische Testumgebung kann diese Stichprobe erweitern; diese Punkte sind keine bereits bestandenen Tests.

Normaler Build: **PASS**, Test-Hooks `False`. [Spielbares ZIP](../output/production-build/20261123-223542/FirstGame.zip).
