# Bericht der nativen Monte-Carlo-Prüfung

Es liegen **180 gültige vollständige Runs der Hauptstichprobe** und **12 zusätzliche vollständige Kalibrierungsruns** vor, insgesamt **192**. Das gewünschte Ziel von 3.000 vollständigen Runs wurde nicht erreicht. Alle nachfolgend als Runs bezeichneten Beobachtungen sind echte Produktions-GML im nativen GameMaker-Runner, keine Python-Ersatzsimulation. Boss-Einzelkämpfe, Zeitfenster und Assertions sind getrennte Prüfeinheiten.

## Stichprobe und Abschlusskriterien

| Kohorte | Runs | Klassen | Botprofile | Echter Tod | Bei 30 min zensiert |
| --- | --- | --- | --- | --- | --- |
| Vorher | 72 | Sword: 24, Mage: 24, Ranger: 24 | beginner: 24, average: 24, experienced: 24 | 72 | 0 |
| Nachher, gepaart | 72 | Sword: 24, Mage: 24, Ranger: 24 | beginner: 24, average: 24, experienced: 24 | 72 | 0 |
| Nachher, Holdout | 36 | Sword: 12, Mage: 12, Ranger: 12 | beginner: 12, average: 12, experienced: 12 | 35 | 1 |

Ein vollständiger Run startet im normalen leeren Fähigkeitsbuild mit der eigenen Startwaffe, normalen HP, normalen Gegnern und unveränderter Spieluhr. Er endet durch tatsächlichen Tod oder nach 1.800 simulierten Sekunden als rechtszensierter Überlebender. Es gibt keinen erzwungenen Tod und kein verkürztes Run-Ende. Baseline- und Nachher-Paare besitzen identischen Seed, Klasse und Botprofil. Die Primärgruppen sind innerhalb jeder Klasse gleich über die drei Profile verteilt. Der Holdout startet mit neuen Seeds und wurde nicht als gepaarte Effektmessung behandelt.

Die 12 gültigen `visible-greedy-v1`-Kalibrierungsruns waren vollständige natürliche Runs, deckten jedoch zu frühes Dodge und unpassende Sprünge gegen `all`/hohe Angriffe im Bot auf. Sie zählen zum geleisteten vollständigen Testumfang, gehen aber nicht in Klassenrangfolgen oder Vorher/Nachher-Effekte ein. Frühere ungültige FPS-10.000-Piloten und unvollständige Fixtures werden weder hier noch in der Hauptstichprobe als gültige vollständige Runs gezählt.

## Ausführung und Reproduzierbarkeit

Die Runtime ist GameMaker 2024.14.4.268. Jeder logische Schritt dauert exakt 1/60 s, `room_speed` bleibt 60. Beschleunigung bündelt vollständige Steps; sie verändert nicht die Spielzeit. Batch-Parität 1/60/600 sowie die zusätzlichen v2-Klassenproben sind in [SIMULATOR_FIDELITY.md](SIMULATOR_FIDELITY.md) und [native-fidelity-v2.json](data/native-fidelity-v2.json) belegt. Batch-Parität beweist Reproduzierbarkeit, keine vollständig formale Gleichheit jeder Engine-Instanzreihenfolge mit einer menschlichen Sitzung.

Baseline-Artefakt: `output/native-mc-baseline/20261123-174801`. Nachher und Holdout: `output/native-mc-after/20261123-175857`. Diese kopierten Produktionsquellen unterscheiden sich nur durch die dokumentierte normale Münzgeschwindigkeit 252 → 420 und die Begrenzung des Boss-Trefferreaktions-Drawframes. Ressourcen, Klassen, Fähigkeiten und Gegnertypen wurden nicht erweitert. Die Änderungen und ihr konkreter Nachweis stehen in [BALANCE_CHANGES.md](BALANCE_CHANGES.md).

Die Rohdaten enthalten unter anderem Seed, Persona, Endgrund, HP, Level, Kills, XP, aktuelle Münzen, aktive/passive Stufen, alle angebotenen und gewählten IDs, Bossbegegnungen, Zeitstichproben, Schadensquellen, versuchten/effektiven/DoT-Schaden und den Zustands-Hash. `data/analysis.json` enthält Quellprüfsummen; `data/runs.csv` ist die flache Übersicht. Das Auswerteskript liest ausschließlich abgeschlossene Rohdatensätze, prüft eindeutige Run-IDs und erzeugt keine synthetischen Spielbeobachtungen.

| Rohdatenordner unter data/ | Runs | Seedstart | Worker | Batch | Wandzeit s | Abgeschlossen |
| --- | --- | --- | --- | --- | --- | --- |
| baseline-v2-a | 36 | 750101 | 4 | 600 | 522,6 | ja |
| baseline-v2-b | 36 | 750113 | 4 | 600 | 595,8 | ja |
| after-v2-a | 36 | 750101 | 4 | 600 | 1 665,4 | ja |
| after-v2-b | 36 | 750113 | 4 | 600 | 1 455,1 | ja |
| holdout-v2 | 36 | 760101 | 4 | 600 | 1 392,6 | ja |

Jeder Ordner enthält `cohort.json` mit Artefakt-/EXE-Prüfsumme und Worker-Logs sowie `worker-0.jsonl` bis `worker-3.jsonl`. Bei einer Wiederholung sind neue Ausgabeordner zu verwenden; vorhandene Checkpoints werden nicht als neue Beobachtungen dupliziert.

## Beobachtete Ergebnisse und Unsicherheit

Die vollständigen Klassen-/Bot-Tabellen einschließlich Mittelwert, Median, Streuung, 95-%-Bootstrap-Intervallen, Wilson-Meilensteinen, Startwaffenanteilen und XP/Kill stehen in [CLASS_BALANCE.md](CLASS_BALANCE.md). Die Konfidenzintervalle beschreiben die beobachtete Seed-Stichprobe unter festen Regeln; sie umfassen keine Modellunsicherheit über menschliches Verhalten. Ein Bootstrap-Resample ist keine zusätzliche Spielrunde. Es gibt keine Behauptung einer universellen besten Klasse oder eines universell besten Builds.

| Kohorte | n | Mittel s | Median s | Maximum s | 5 min | 10 min | 15 min | 30 min |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Vorher | 72 | 178,0 | 167,9 | 778,0 | 7 | 2 | 0 | 0 |
| Nachher, gepaart | 72 | 251,4 | 195,2 | 1 414,9 | 15 | 5 | 5 | 0 |
| Nachher, Holdout | 36 | 230,7 | 154,5 | 1 800,0 | 7 | 2 | 1 | 1 |

Die Gesamtzeilen mischen drei Klassen mit teilweise gemeinsamen Start-Seeds; deshalb wird hier kein unabhängiges Konfidenzintervall über alle Zeilen behauptet. Die ausgewiesenen Überlebensintervalle stehen je Klasse und je Bot-Stratum im Klassenbericht.

Die gewöhnlichen Gegner skalieren ihre HP mit `1 + Minute*0,07`, den Schaden mit `1 + Minute*0,06`; Population und Boss-HP skalieren zusätzlich nach dem vorhandenen Zeitplan. Das ist der implementierte Skalierungsmechanismus. Seine langfristige Fairness lässt sich nur für Zeitbereiche mit tatsächlich beobachteten Überlebenden bewerten.

## Tatsächlich beobachteter zeitlicher Fortschritt

Die folgenden Produktions-/Harness-Snapshots sind bedingt auf das Erreichen des Zeitpunkts. Die Mittelwerte der Überlebenden sind keine Prognose für den durchschnittlichen neuen Run. HP, Gegnerzahl und Gegnerwerte stammen aus `timecourse`, verdiente XP aus den vorhandenen `progression_samples`. Falls beide Proben um einen Tick auseinanderliegen, werden ihre jeweiligen exportierten Werte unverändert verwendet.

| Kohorte | Minute | n Snapshots | Level Ø | XP Ø | HP Ø | Investitionen Ø | Gegner Ø | Gegner-Rest-HP Ø | Gegner-Angriff Ø |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Vorher | 5 | 7 | 12,4 | 753,9 | 82,0 | 12,1 | 83,1 | 92,0 | 15,2 |
| Vorher | 10 | 2 | 26,0 | 2 900,0 | 81,5 | 26,5 | 120,5 | 107,7 | 17,8 |
| Vorher | 15 | 0 | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet |
| Vorher | 20 | 0 | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet |
| Vorher | 25 | 0 | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet |
| Vorher | 30 | 0 | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet |
| Nachher, gepaart | 5 | 15 | 13,9 | 939,4 | 80,4 | 13,9 | 71,5 | 93,8 | 14,8 |
| Nachher, gepaart | 10 | 5 | 26,6 | 2 995,4 | 100,9 | 27,8 | 117,6 | 110,8 | 18,0 |
| Nachher, gepaart | 15 | 5 | 39,4 | 5 526,4 | 93,2 | 41,2 | 109,6 | 140,7 | 21,4 |
| Nachher, gepaart | 20 | 3 | 54,0 | 9 022,3 | 104,5 | 57,0 | 146,7 | 157,1 | 24,5 |
| Nachher, gepaart | 25 | 0 | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet |
| Nachher, gepaart | 30 | 0 | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet | nicht beobachtet |
| Nachher, Holdout | 5 | 7 | 16,1 | 1 222,0 | 76,2 | 16,7 | 60,1 | 102,3 | 14,6 |
| Nachher, Holdout | 10 | 2 | 30,0 | 3 538,5 | 83,0 | 31,5 | 106,0 | 121,2 | 17,9 |
| Nachher, Holdout | 15 | 1 | 53,0 | 8 611,0 | 136,0 | 56,0 | 90,0 | 147,5 | 20,8 |
| Nachher, Holdout | 20 | 1 | 71,0 | 13 704,0 | 168,0 | 75,0 | 112,0 | 159,3 | 24,0 |
| Nachher, Holdout | 25 | 1 | 90,0 | 20 108,0 | 228,0 | 95,0 | 120,0 | 195,7 | 26,9 |
| Nachher, Holdout | 30 | 1 | 102,0 | 27 386,0 | 228,0 | 108,0 | 91,0 | 217,6 | 30,4 |

In der Hauptstichprobe erreichen 6 Runs Minute 15 und 1 Minute 30. Wo die Tabelle keine Beobachtungen enthält, fehlen gemessene Aussagen zu Level, XP, Slots, späten Bossen und Dauerüberleben ausdrücklich. Isolierte Boss-Tests schließen diese Lücke für vollständige Run-Progression nicht.

## Fähigkeitenbeiträge in vollständigen Nachher-Runs

Diese Tabellen summieren ausschließlich die **72 gepaarten Nachher-Runs**, ohne Holdout und ohne kontrollierte Benchmarks. Sie zeigen tatsächliche Nutzung und Wirkung im vorhandenen Spiel. Auswahlwahrscheinlichkeit, früh/spät erlernte Stufe, Klassen, Gegnerzahl und Überlebensdauer sind unterschiedlich: Die Summen sind **kein Vergleich bei gleicher Einsatzchance und keine intrinsische DPS-Rangliste**. Ein seltener gewählter Zauber kann trotz kleiner Gesamtsumme stark sein. „Runs gelernt“ zählt Runs mit der Fähigkeit im Endbuild; „0“ fasst die Startwaffen aller Klassen und Komboschritte zusammen.

| Quelle | Runs gelernt | Auslösungen | Projektile | Projektile mit Treffer | Ohne Treffer abgelaufen | Schadensereignisse | Heilung HP |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 0: Startwaffen aller Klassen | 72 | 43 577 | 31 989 | 27 324 | 4 653 | 459 638 | 0,0 |
| 101: Fireball | 21 | 2 515 | 2 962 | 2 958 | 2 | 782 383 | 0,0 |
| 102: Iceball | 8 | 1 688 | 2 836 | 2 773 | 63 | 2 773 | 0,0 |
| 103: Lightning | 11 | 1 822 | 0 | 0 | 0 | 5 767 | 0,0 |
| 104: Frost Nova | 7 | 569 | 0 | 0 | 0 | 7 207 | 0,0 |
| 105: Arcane Barrage | 13 | 756 | 2 320 | 2 246 | 74 | 2 246 | 0,0 |
| 106: Healing Pulse | 17 | 541 | 0 | 0 | 0 | 0 | 15 083,4 |
| 107: Ember Field | 10 | 525 | 0 | 0 | 0 | 1 350 795 | 0,0 |
| 108: Piercing Lance | 16 | 1 699 | 0 | 0 | 0 | 21 118 | 0,0 |
| 109: Orbit Blades | 11 | 412 | 0 | 0 | 0 | 11 621 | 0,0 |
| 110: Stone Spikes | 18 | 1 167 | 0 | 0 | 0 | 23 311 | 0,0 |
| 111: Wisp Sentinel | 11 | 197 | 0 | 0 | 0 | 1 632 | 0,0 |
| 112: Thunder Seal | 6 | 141 | 0 | 0 | 0 | 2 422 | 0,0 |
| 113: Starfall | 9 | 241 | 0 | 0 | 0 | 131 597 | 0,0 |
| 114: Gravity Well | 6 | 174 | 0 | 0 | 0 | 22 632 | 0,0 |
| 115: Ice Prison | 6 | 475 | 0 | 0 | 0 | 53 397 | 0,0 |
| 116: Returning Glaive | 8 | 753 | 0 | 0 | 0 | 12 045 | 0,0 |
| 117: Prismatic Seed | 9 | 350 | 0 | 0 | 0 | 4 492 | 0,0 |
| 118: Solar Verdict | 9 | 233 | 0 | 0 | 0 | 10 728 | 0,0 |
| 201: Orbit Shield | 4 | 1 971 | 0 | 0 | 0 | 1 971 | 0,0 |
| 205: Vitality | 2 | 7 | 0 | 0 | 0 | 0 | 84,0 |
| 215: Renewal | 6 | 149 | 0 | 0 | 0 | 0 | 22,4 |

Ein Schadensereignis kann ein einzelner Flächen-/Feld-/DoT-Tick sein. Eine Auslösung und ein Projektil sind unterschiedliche Einheiten. Noch fliegende Projektile zählen nicht als abgelaufene Fehlschüsse; mehrfach treffende Projektile zählen bei „mit Treffer“ einmal. Aus den Ereigniszahlen darf deshalb keine einheitliche Trefferwahrscheinlichkeit aller Fähigkeitentypen berechnet werden.

| Quelle | Versucht | Effektiver HP-Verlust | Overkill | DoT enthalten | Normale Gegner HP | Boss HP | Kills | Schadenanteil | Killanteil |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0: Startwaffen aller Klassen | 5 557 546 | 4 791 542 | 766 004 | 0 | 4 689 417 | 102 124 | 41 675 | 40,0 % | 44,2 % |
| 101: Fireball | 952 726 | 840 440 | 112 286 | 12 822 | 824 246 | 16 194 | 6 917 | 7,0 % | 7,3 % |
| 102: Iceball | 85 223 | 75 587 | 9 636 | 0 | 64 169 | 11 418 | 574 | 0,6 % | 0,6 % |
| 103: Lightning | 152 770 | 139 351 | 13 419 | 0 | 136 385 | 2 966 | 965 | 1,2 % | 1,0 % |
| 104: Frost Nova | 135 712 | 127 543 | 8 169 | 0 | 125 005 | 2 538 | 860 | 1,1 % | 0,9 % |
| 105: Arcane Barrage | 32 587 | 30 497 | 2 090 | 0 | 29 640 | 857 | 297 | 0,3 % | 0,3 % |
| 106: Healing Pulse | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0,0 % | 0,0 % |
| 107: Ember Field | 733 881 | 694 540 | 39 341 | 41 033 | 678 764 | 15 776 | 5 397 | 5,8 % | 5,7 % |
| 108: Piercing Lance | 1 026 450 | 896 050 | 130 400 | 0 | 876 920 | 19 130 | 5 258 | 7,5 % | 5,6 % |
| 109: Orbit Blades | 224 353 | 211 010 | 13 343 | 0 | 197 040 | 13 970 | 1 290 | 1,8 % | 1,4 % |
| 110: Stone Spikes | 968 915 | 842 826 | 126 089 | 0 | 812 489 | 30 337 | 6 183 | 7,0 % | 6,6 % |
| 111: Wisp Sentinel | 27 280 | 25 260 | 2 020 | 0 | 24 196 | 1 064 | 218 | 0,2 % | 0,2 % |
| 112: Thunder Seal | 148 390 | 117 816 | 30 574 | 0 | 116 622 | 1 194 | 990 | 1,0 % | 1,0 % |
| 113: Starfall | 200 088 | 164 427 | 35 661 | 2 808 | 161 670 | 2 756 | 1 614 | 1,4 % | 1,7 % |
| 114: Gravity Well | 249 812 | 239 811 | 10 001 | 0 | 235 174 | 4 636 | 1 811 | 2,0 % | 1,9 % |
| 115: Ice Prison | 1 491 753 | 1 358 305 | 133 448 | 0 | 1 326 544 | 31 760 | 8 923 | 11,3 % | 9,5 % |
| 116: Returning Glaive | 388 403 | 343 839 | 44 564 | 0 | 338 150 | 5 689 | 2 769 | 2,9 % | 2,9 % |
| 117: Prismatic Seed | 115 588 | 100 820 | 14 768 | 0 | 99 651 | 1 168 | 1 087 | 0,8 % | 1,2 % |
| 118: Solar Verdict | 1 416 058 | 962 892 | 453 166 | 0 | 942 636 | 20 256 | 7 420 | 8,0 % | 7,9 % |
| 201: Orbit Shield | 12 930 | 12 629 | 301 | 0 | 10 690 | 1 939 | 85 | 0,1 % | 0,1 % |
| 205: Vitality | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0,0 % | 0,0 % |
| 215: Renewal | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0,0 % | 0,0 % |

Effektiver Schaden ist tatsächlich abgezogenes Gegner-HP; Overkill ist versuchter Schaden oberhalb des noch verfügbaren HP. DoT ist bereits Teil des effektiven Schadens und wird nicht zusätzlich addiert. Normal-/Boss-Spalten teilen denselben effektiven Schaden auf. Die Anteile beziehen sich auf alle erfassten Schadens-/Killquellen dieser Kohorte; der letzte schädigende Treffer erhält den Kill. Heilung wird separat in tatsächlichen HP ausgewiesen, nicht als Schaden.

Passive Verstärkungen bleiben beim ursprünglichen Angriff und erhalten keinen erfundenen zusätzlichen Schaden. Passive Fähigkeiten erscheinen hier nur mit einer eigenen tatsächlich schädigenden/heilenden Mechanik, etwa Orbit Shield (201) oder Renewal (215). Rüstung, Geschwindigkeit, Abklingzeit und andere Modifikatoren werden dadurch nicht als wirkungslos bewertet. Ihre kontrollierten Vergleichstests stehen in [ABILITY_BALANCE.md](ABILITY_BALANCE.md).

## Vollausbau: statische Kosten und beobachtete Reichweite

Vorhanden sind 18 aktive und 18 passive Fähigkeiten, je maximal Stufe 9, bei sechs aktiven und sechs passiven Slots. Ein vollständiger Build benötigt somit **108 gültige Investitionen**. Die Startwaffe belegt keinen Slot und ersetzt keine dieser Investitionen. Bei sieben erfolgreich eingesammelten Boss-Truhen würden mindestens 101 normale Levelaufstiege benötigt, also Level 102. Die Summe der implementierten XP-Kosten bis dahin beträgt **24.922 XP**. Das ist eine statische Untergrenze unter diesen Annahmen, kein gemessener Zeitpunkt für Vollausbau und keine Garantie passender Angebote. Zwischen normalen XP-Auswahlen liegen mindestens sechs Spielsekunden.

Gemessenes höchstes Endlevel: **102**. Größter beobachteter Endbuild: **108/108 Investitionen**. Vollständig ausgebaute Hauptstichproben-Runs: **1/180**. Die Frage, ob gewöhnliche Spieler bis Minute 15/30 sinnvoll voll ausbauen können, bleibt damit ohne hinreichenden vollständigen Langzeitnachweis offen. Es wurden keine fiktiven späten Werte ergänzt.

Konkreter beobachteter Vollausbau: `holdout-Sword-760103-experienced`, Schwertkämpfer, Erfahrener Bot. Die 108. gültige Auswahl erfolgte bei 1 698,5 s (28,31 min). Der Run endete als `survived_1800_seconds_censored` bei 1 800,0 s mit 228,0/228,0 HP, 7 besiegten Bossen und 27387 verdienten Münz-XP. Das belegt Erreichbarkeit in diesem einen natürlichen Bot-Run, keine typische menschliche Ausbauzeit und kein besiegtes 30-Minuten-Endboss-Ereignis.

## Tatsächliche Todesquellen

Der letzte tödliche Treffer ist eine Attribution des Run-Endes. Frühere Schadenstypen können wesentlich beigetragen haben; diese Tabelle misst weder Unvermeidbarkeit noch alleinige Ursache.

| Kohorte | Letzte tödliche Quelle | Runs |
| --- | --- | --- |
| Vorher | enemy_contact:ObjectMonster | 43 |
| Vorher | boss_attack:mini_warden:fan | 8 |
| Vorher | boss_attack:mini_sentinel:lightning | 8 |
| Vorher | boss_attack:mini_warden:lightning | 5 |
| Vorher | boss_attack:mini_sentinel:automatic_projectile | 4 |
| Vorher | boss_attack:twins:1 | 1 |
| Vorher | boss_attack:mini_sentinel:lob | 1 |
| Vorher | boss_attack:twins:6 | 1 |
| Vorher | boss_attack:storm_warden:3 | 1 |
| Nachher, gepaart | enemy_contact:ObjectMonster | 33 |
| Nachher, gepaart | boss_attack:mini_warden:fan | 15 |
| Nachher, gepaart | boss_attack:mini_warden:lightning | 6 |
| Nachher, gepaart | boss_attack:mini_sentinel:lightning | 6 |
| Nachher, gepaart | boss_attack:storm_warden:3 | 4 |
| Nachher, gepaart | boss_attack:behemoth:1 | 2 |
| Nachher, gepaart | boss_attack:storm_warden:2 | 2 |
| Nachher, gepaart | boss_attack:mini_sentinel:automatic_projectile | 1 |
| Nachher, gepaart | boss_attack:behemoth:3 | 1 |
| Nachher, gepaart | boss_attack:storm_warden:7 | 1 |
| Nachher, gepaart | boss_attack:twins:2 | 1 |
| Nachher, Holdout | enemy_contact:ObjectMonster | 19 |
| Nachher, Holdout | boss_attack:mini_warden:fan | 6 |
| Nachher, Holdout | boss_attack:mini_sentinel:lightning | 4 |
| Nachher, Holdout | boss_attack:mini_warden:lightning | 2 |
| Nachher, Holdout | boss_attack:mini_sentinel:automatic_projectile | 1 |
| Nachher, Holdout | boss_attack:storm_warden:3 | 1 |
| Nachher, Holdout | boss_attack:twins:1 | 1 |
| Nachher, Holdout | boss_attack:mini_sentinel:lob | 1 |

Boss-Einzelkämpfe und Warn-/Trefferanalysen sind in [BOSS_BALANCE.md](BOSS_BALANCE.md) getrennt ausgewertet. Geometrische Flächenexposition und Kontaktzählung bei Projektilen besitzen verschiedene Nenner. Treffer eines lokalen Bots beweisen keine technische Unvermeidbarkeit.

## Gemessene Laufzeit und das nicht erreichte 3.000-Run-Ziel

Die folgende Hochrechnung verwendet ausschließlich die abgeschlossenen Kohorten auf dieser Maschine. Pro Zeile wird deren beobachtete Wandzeit mit `3000 / abgeschlossene Runs` multipliziert. Die vier Worker einer Kohorte liefen teils neben anderen Kohorten; Betriebssystemlast und Konkurrenz sind in diesen Zeiten enthalten. Es handelt sich um eine bedingte lineare Projektion für denselben Run-Mix und dieselben Bedingungen, nicht um einen nachgewiesenen Hardwaredeckel oder eine Ausrede mit erfundener Maximalleistung.

| Gemessene Kohorte | Runs | Wandzeit s | Runs/Stunde | Bedingt 3.000 Runs: Stunden |
| --- | --- | --- | --- | --- |
| baseline-v2-a | 36 | 522,6 | 248,0 | 12,10 |
| baseline-v2-b | 36 | 595,8 | 217,5 | 13,79 |
| after-v2-a | 36 | 1 665,4 | 77,8 | 38,55 |
| after-v2-b | 36 | 1 455,1 | 89,1 | 33,68 |
| holdout-v2 | 36 | 1 392,6 | 93,1 | 32,24 |

Die Hauptstichprobe umfasst 10,90 simulierte Spielstunden. Länger überlebende oder bis Minute 30 laufende Builds können erheblich mehr Zeit beanspruchen, weil mehr Gegner, Projektile und Fähigkeiten gleichzeitig aktiv werden. Von 3.000 fehlen gegenüber allen 192 gültigen vollständigen Runs noch 2808; gegenüber der einheitlichen Hauptstichprobe fehlen 2820. Weitere Runs wurden nicht durch Assertions, Benchmarks oder Bootstrap-Wiederholungen ersetzt. Der Auftrag ist hinsichtlich des geforderten Stichprobenziels und belastbarer später Run-Progression daher nur teilweise erfüllt.

## Dateien und Reproduktion

- [CLASS_BALANCE.md](CLASS_BALANCE.md): Klassen, Botprofile, Intervalle, Build-/XP-Vergleiche.
- [SIMULATOR_FIDELITY.md](SIMULATOR_FIDELITY.md): native Mechanik, Zeit-/Kollisionsnachweise und Grenzen.
- [PROJECT_INVENTORY.md](PROJECT_INVENTORY.md): statisch gelesene Produktionsregeln.
- [analysis.json](data/analysis.json), [runs.csv](data/runs.csv): maschinenlesbare Auswertung.
- [tools/run_cohort.py](tools/run_cohort.py), [tools/analyze_qa.py](tools/analyze_qa.py), [tools/write_simulation_reports.py](tools/write_simulation_reports.py): Runner und Auswertung.
- [survival-baseline.png](charts/survival-baseline.png), [survival-after.png](charts/survival-after.png), [survival-holdout.png](charts/survival-holdout.png), [before-after.png](charts/before-after.png): aus denselben Beobachtungen erzeugte Diagramme.

Regenerieren: `QA/.venv/Scripts/python.exe QA/tools/write_simulation_reports.py`, nachdem `analyze_qa.py` genau die fünf Hauptkohorten verarbeitet hat. Der Generator verweigert unvollständige Kohorten, veraltete Analyse-Prüfsummen und doppelte Run-IDs.
