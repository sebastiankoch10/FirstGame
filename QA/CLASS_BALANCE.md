# Klassenbalance aus nativen vollständigen Runs

Diese Auswertung gilt für die drei dokumentierten Bot-Regeln und die beobachteten Seeds. Sie bestimmt keine universell stärkste Klasse für Menschen. Vorher und Nachher verwenden dieselben Klasse/Seed/Bot-Kombinationen; der Holdout verwendet neue Seeds. Methodik, Stichprobenumfang und Grenzen stehen in [SIMULATION_REPORT.md](SIMULATION_REPORT.md).

## Überleben, Streuung und Rangfolge

Alle Zeiten sind Sekunden. Der Mittelwert ist auf 1.800 s beschränkt; Überlebende am Zeitdeckel wären rechtszensiert. Die 95-%-Intervalle des Mittelwerts sind ein deterministischer Bootstrap mit 1.000 Wiederholungen der beobachteten Runs. Min–Max und Standardabweichung zeigen die Streuung; kleine Gruppen erlauben keine präzise Rangordnung.

| Kohorte | Klasse | n | Mittel | Median | 95-%-KI Mittel | SD | Min–Max |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Vorher | Schwertkämpfer | 24 | 157,2 | 120,4 | 98,1–226,2 | 171,6 | 14,1–778,0 |
| Vorher | Zaubermeisterin | 24 | 177,1 | 193,3 | 132,4–222,2 | 112,9 | 23,5–511,3 |
| Vorher | Waldläufer | 24 | 199,8 | 188,3 | 148,9–256,0 | 136,7 | 55,0–643,5 |
| Nachher, gepaart | Schwertkämpfer | 24 | 285,5 | 147,6 | 151,8–449,5 | 391,8 | 14,2–1 414,9 |
| Nachher, gepaart | Zaubermeisterin | 24 | 191,7 | 206,4 | 142,3–240,1 | 123,1 | 38,0–503,2 |
| Nachher, gepaart | Waldläufer | 24 | 277,1 | 207,5 | 172,7–405,4 | 304,4 | 47,8–1 302,5 |
| Nachher, Holdout | Schwertkämpfer | 12 | 322,5 | 161,2 | 111,8–636,3 | 494,6 | 11,3–1 800,0 |
| Nachher, Holdout | Zaubermeisterin | 12 | 189,6 | 198,0 | 126,1–250,2 | 115,7 | 43,7–387,6 |
| Nachher, Holdout | Waldläufer | 12 | 180,1 | 117,9 | 98,3–303,8 | 196,7 | 38,8–776,3 |

Nach mittlerer beobachteter Überlebenszeit lautet die Rangfolge der gepaarten Nachher-Stichprobe: Schwertkämpfer → Waldläufer → Zaubermeisterin. Im unabhängigen Holdout: Schwertkämpfer → Zaubermeisterin → Waldläufer. Das sind deskriptive Bot-Ergebnisse. HP, Bewegung, Waffenreichweite, Upgrade-Angebote, Sammelverhalten und die Anpassung der Bot-Regel an eine Klasse wirken gemeinsam.

Eine konkrete statische Grenze der Klassenpolitik: Der Bot bevorzugt für die Zaubermeisterin etwa 190 Einheiten Abstand zum nächsten Gegner; der eigene Stab-Bogen reicht 155, der Kreis 130 Einheiten. Beide können andere nahe Gegner treffen, aber diese Zielabstandsregel nutzt den gesamten Waffenzyklus nicht garantiert optimal. Wegwahl, Zielabstand und die Anpassung der KI sind mögliche Störfaktoren. Daraus folgt weder ein nachgewiesener Produktionsfehler noch eine belastbare Forderung nach höheren Klassen-HP.

## Drei Bot-Strata

Die Bezeichnungen sind technische Profile, keine empirisch gemessenen menschlichen Skillgruppen. Reaktionszeit / Gefahrgewicht: Anfänger 0,65 s / 0,65, Durchschnitt 0,30 s / 1,0, erfahren 0,12 s / 1,2. Anfänger nutzen weder Sprung noch Dodge; die beiden anderen verwenden legale, zeitlich geplante Eingaben. Alle nutzen eine lokale Bewertung von acht Bewegungsrichtungen. Die Reihenfolge der Ergebnisse muss deshalb nicht monoton mit dem Profilnamen steigen.

| Kohorte | Klasse | Bot | n | Mittel s | Median s | 95-%-KI Mittel s |
| --- | --- | --- | --- | --- | --- | --- |
| Vorher | Schwertkämpfer | Anfänger-Bot | 8 | 21,5 | 20,7 | 18,0–24,6 |
| Vorher | Schwertkämpfer | Durchschnitts-Bot | 8 | 237,2 | 120,4 | 100,5–409,6 |
| Vorher | Schwertkämpfer | Erfahrener Bot | 8 | 212,8 | 206,0 | 177,5–245,6 |
| Vorher | Zaubermeisterin | Anfänger-Bot | 8 | 65,8 | 61,0 | 39,5–95,0 |
| Vorher | Zaubermeisterin | Durchschnitts-Bot | 8 | 246,5 | 207,5 | 172,3–333,5 |
| Vorher | Zaubermeisterin | Erfahrener Bot | 8 | 218,9 | 213,6 | 176,2–254,4 |
| Vorher | Waldläufer | Anfänger-Bot | 8 | 76,7 | 78,4 | 65,5–87,8 |
| Vorher | Waldläufer | Durchschnitts-Bot | 8 | 277,7 | 215,1 | 185,3–393,9 |
| Vorher | Waldläufer | Erfahrener Bot | 8 | 244,9 | 235,3 | 187,3–303,8 |
| Nachher, gepaart | Schwertkämpfer | Anfänger-Bot | 8 | 23,2 | 20,5 | 18,1–28,8 |
| Nachher, gepaart | Schwertkämpfer | Durchschnitts-Bot | 8 | 531,7 | 147,6 | 123,3–908,0 |
| Nachher, gepaart | Schwertkämpfer | Erfahrener Bot | 8 | 301,7 | 262,5 | 220,6–399,9 |
| Nachher, gepaart | Zaubermeisterin | Anfänger-Bot | 8 | 54,4 | 53,3 | 44,9–63,7 |
| Nachher, gepaart | Zaubermeisterin | Durchschnitts-Bot | 8 | 271,0 | 240,3 | 222,6–321,8 |
| Nachher, gepaart | Zaubermeisterin | Erfahrener Bot | 8 | 249,7 | 220,0 | 196,3–326,0 |
| Nachher, gepaart | Waldläufer | Anfänger-Bot | 8 | 95,0 | 74,6 | 65,2–138,9 |
| Nachher, gepaart | Waldläufer | Durchschnitts-Bot | 8 | 343,5 | 240,0 | 178,4–571,2 |
| Nachher, gepaart | Waldläufer | Erfahrener Bot | 8 | 392,7 | 259,8 | 223,2–661,5 |
| Nachher, Holdout | Schwertkämpfer | Anfänger-Bot | 4 | 26,3 | 27,6 | 13,5–36,9 |
| Nachher, Holdout | Schwertkämpfer | Durchschnitts-Bot | 4 | 254,7 | 244,5 | 127,0–376,4 |
| Nachher, Holdout | Schwertkämpfer | Erfahrener Bot | 4 | 686,4 | 384,1 | 190,5–1 407,5 |
| Nachher, Holdout | Zaubermeisterin | Anfänger-Bot | 4 | 67,0 | 71,0 | 48,2–81,3 |
| Nachher, Holdout | Zaubermeisterin | Durchschnitts-Bot | 4 | 254,0 | 266,8 | 132,5–352,1 |
| Nachher, Holdout | Zaubermeisterin | Erfahrener Bot | 4 | 247,6 | 234,0 | 196,4–297,3 |
| Nachher, Holdout | Waldläufer | Anfänger-Bot | 4 | 71,6 | 80,9 | 48,7–84,8 |
| Nachher, Holdout | Waldläufer | Durchschnitts-Bot | 4 | 333,8 | 211,9 | 149,1–629,9 |
| Nachher, Holdout | Waldläufer | Erfahrener Bot | 4 | 134,9 | 132,3 | 85,6–179,2 |

## Erreichte Meilensteine

Jede Zelle enthält erreichte Runs / n und das 95-%-Wilson-Intervall des Anteils. Ein gemessener Anteil von 0 % bedeutet bei diesen Stichproben keine bewiesene Unmöglichkeit.

| Kohorte | Klasse | 5 min | 10 min | 15 min | 20 min | 25 min | 30 min |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Vorher | Schwertkämpfer | 2/24 (2,3–25,8 %) | 1/24 (0,7–20,2 %) | 0/24 (0,0–13,8 %) | 0/24 (0,0–13,8 %) | 0/24 (0,0–13,8 %) | 0/24 (0,0–13,8 %) |
| Vorher | Zaubermeisterin | 2/24 (2,3–25,8 %) | 0/24 (0,0–13,8 %) | 0/24 (0,0–13,8 %) | 0/24 (0,0–13,8 %) | 0/24 (0,0–13,8 %) | 0/24 (0,0–13,8 %) |
| Vorher | Waldläufer | 3/24 (4,3–31,0 %) | 1/24 (0,7–20,2 %) | 0/24 (0,0–13,8 %) | 0/24 (0,0–13,8 %) | 0/24 (0,0–13,8 %) | 0/24 (0,0–13,8 %) |
| Nachher, gepaart | Schwertkämpfer | 5/24 (9,2–40,5 %) | 3/24 (4,3–31,0 %) | 3/24 (4,3–31,0 %) | 2/24 (2,3–25,8 %) | 0/24 (0,0–13,8 %) | 0/24 (0,0–13,8 %) |
| Nachher, gepaart | Zaubermeisterin | 4/24 (6,7–35,9 %) | 0/24 (0,0–13,8 %) | 0/24 (0,0–13,8 %) | 0/24 (0,0–13,8 %) | 0/24 (0,0–13,8 %) | 0/24 (0,0–13,8 %) |
| Nachher, gepaart | Waldläufer | 6/24 (12,0–44,9 %) | 2/24 (2,3–25,8 %) | 2/24 (2,3–25,8 %) | 1/24 (0,7–20,2 %) | 0/24 (0,0–13,8 %) | 0/24 (0,0–13,8 %) |
| Nachher, Holdout | Schwertkämpfer | 4/12 (13,8–60,9 %) | 1/12 (1,5–35,4 %) | 1/12 (1,5–35,4 %) | 1/12 (1,5–35,4 %) | 1/12 (1,5–35,4 %) | 1/12 (1,5–35,4 %) |
| Nachher, Holdout | Zaubermeisterin | 2/12 (4,7–44,8 %) | 0/12 (0,0–24,2 %) | 0/12 (0,0–24,2 %) | 0/12 (0,0–24,2 %) | 0/12 (0,0–24,2 %) | 0/12 (0,0–24,2 %) |
| Nachher, Holdout | Waldläufer | 1/12 (1,5–35,4 %) | 1/12 (1,5–35,4 %) | 0/12 (0,0–24,2 %) | 0/12 (0,0–24,2 %) | 0/12 (0,0–24,2 %) | 0/12 (0,0–24,2 %) |

## Gepaarter Vorher/Nachher-Vergleich

Die Änderung betrifft den normalen Münz-Zug von 252 auf 420 Einheiten/s; die zusätzliche Boss-Draw-Frame-Begrenzung ändert keine beabsichtigte Kampfregel. Die folgende Differenz ist Nachher minus Vorher bei identischem Start-Seed, Klasse und Bot. Der zufällige Spielverlauf kann nach einer veränderten Einsammlung divergieren.

| Klasse | Paare | Δ Mittel s | Δ Median s | 95-%-KI Δ Mittel s | Länger | Kürzer | Gleich |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Schwertkämpfer | 24 | 128,4 | 9,6 | 37,0–245,8 | 16 | 8 | 0 |
| Zaubermeisterin | 24 | 14,6 | 6,5 | -15,6–45,1 | 13 | 11 | 0 |
| Waldläufer | 24 | 77,3 | 12,8 | 5,3–174,8 | 13 | 11 | 0 |

Ein positiver Mittelwert belegt keinen garantierten Vorteil in jedem Run. Der unabhängige Holdout prüft neue Seeds nach der Korrektur und besitzt keinen gepaarten Vorher-Gegenpart.

## Tatsächlicher Schadensbeitrag der Startwaffe

Anteile sind aus summiertem tatsächlich abgezogenem Gegner-HP berechnet, nicht aus Nennschaden oder dem Mittel einzelner Prozentwerte. Der DoT-Anteil ist bereits im effektiven Schaden enthalten. Kills bezeichnen den der letzten Schadensquelle zugeordneten Kill, keinen alleinigen Verdienst.

| Kohorte | Klasse | Versuchter Schaden | Effektiver Schaden | Startwaffe Schaden | Startwaffe Kills | DoT Schaden |
| --- | --- | --- | --- | --- | --- | --- |
| Vorher | Schwertkämpfer | 2 104 540 | 1 905 748 | 45,3 % | 45,8 % | 1,2 % |
| Vorher | Zaubermeisterin | 2 356 493 | 1 711 085 | 70,2 % | 75,2 % | 0,4 % |
| Vorher | Waldläufer | 1 323 563 | 1 238 978 | 57,4 % | 55,7 % | 0,8 % |
| Nachher, gepaart | Schwertkämpfer | 8 162 125 | 7 190 174 | 32,2 % | 34,4 % | 0,5 % |
| Nachher, gepaart | Zaubermeisterin | 2 821 463 | 2 089 277 | 60,3 % | 65,7 % | 0,6 % |
| Nachher, gepaart | Waldläufer | 2 936 877 | 2 695 730 | 45,1 % | 45,8 % | 0,3 % |
| Nachher, Holdout | Schwertkämpfer | 7 077 326 | 6 218 638 | 21,7 % | 25,8 % | 0,1 % |
| Nachher, Holdout | Zaubermeisterin | 1 337 219 | 983 367 | 66,9 % | 73,6 % | 0,0 % |
| Nachher, Holdout | Waldläufer | 1 003 356 | 914 257 | 32,4 % | 33,2 % | 0,2 % |

Das kontrollierte native 15-s-Fenster ohne hinzugewählte Fähigkeiten ergibt gegen ein stationäres Ziel 38,00 / 34,53 / 28,40 DPS für Schwert / Magie / Waldläufer, gegen acht stationäre Ziele 222,93 / 235,67 / 88,00 DPS. Diese Fixtures erklären Zielgeometrie und Mehrzielwirkung, ersetzen weder bewegte Runs noch menschliche Klassenstärke. Details: [ABILITY_BALANCE.md](ABILITY_BALANCE.md).

## Kills, eingesammelte XP und Auswahlfortschritt

Endwerte hängen stark von der Überlebensdauer ab. XP/Kill ist hier das Verhältnis der Summen, kein gleichzeitiger Test bei gleicher Kampfdauer. Münzen am Boden, Bossanteile, Entfernen ferner Gegner und verzögerte Einsammlung verhindern die Gleichsetzung Kills = eingesammelte XP. `coins` ist der exportierte aktuelle Rundenzähler; `xp_earned` zählt verdiente Münz-XP.

| Kohorte | Klasse | Level Ø | Kills Ø | XP Ø | XP/Kill | coins Ø | Auswahlen Ø | Max. Level |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Vorher | Schwertkämpfer | 10,5 | 747,5 | 728,4 | 97,4 % | 45,4 | 10,2 | 41 |
| Vorher | Zaubermeisterin | 10,8 | 759,6 | 640,0 | 84,3 % | 55,8 | 10,4 | 22 |
| Vorher | Waldläufer | 7,5 | 511,3 | 344,8 | 67,4 % | 39,8 | 6,8 | 23 |
| Nachher, gepaart | Schwertkämpfer | 17,0 | 2 123,6 | 2 055,5 | 96,8 % | 39,7 | 17,1 | 74 |
| Nachher, gepaart | Zaubermeisterin | 11,8 | 900,9 | 772,2 | 85,7 % | 60,8 | 11,6 | 29 |
| Nachher, gepaart | Waldläufer | 9,5 | 901,0 | 656,2 | 72,8 % | 63,5 | 9,0 | 36 |
| Nachher, Holdout | Schwertkämpfer | 18,7 | 3 100,2 | 3 034,6 | 97,9 % | 268,5 | 19,0 | 102 |
| Nachher, Holdout | Zaubermeisterin | 11,2 | 861,2 | 678,9 | 78,8 % | 48,8 | 10,7 | 23 |
| Nachher, Holdout | Waldläufer | 8,2 | 653,6 | 535,6 | 81,9 % | 22,5 | 7,5 | 37 |

Der Waldläufer bewegt sich bereits ohne Passivbonus mit 252 Einheiten/s. Eine normale Münze mit ebenfalls 252 Einheiten/s konnte ihn in der kontrollierten geraden Verfolgung aus 80 Einheiten Rückstand nicht einholen. Die echte Player-/Coin-Step-Fixture scheiterte vorher in beiden Waldläufer-Fällen, nach der Korrektur bestehen alle vier Fälle, einschließlich Fleet Footed 9. Das belegt den konkreten Einsammelfehler; die Run-Tabellen messen dessen mögliche Gesamtfolgen. Daten: [moving-coin-baseline.json](data/moving-coin-baseline.json), [moving-coin-after.json](data/moving-coin-after.json).

## Zufallsangebote und Build-Vergleiche

Angebote nutzen den separaten reproduzierbaren Produktions-`choice_rng`. Der Bot wählt jeweils den höchsten Wert aus einem Zufallsanteil 0–3; die beiden fortgeschrittenen Profile bevorzugen frühe aktive Fähigkeiten, vorhandene Upgrades und bei niedrigen HP Heilung/Schutz. Beim Waldläufer erhalten die vorhandenen IDs 204/202/206/208 zusätzlich 0,5. Diese kleine Klassenvorliebe ist ein Bestandteil des Tests und ein möglicher Störfaktor, kein Beleg für eine optimale Buildstrategie.

| Kohorte | Klasse | Verschiedene Endbuilds | Verschiedene Angebotsdreier | Häufigste gewählte IDs (Anzahl Investitionen) |
| --- | --- | --- | --- | --- |
| Vorher | Schwertkämpfer | 24 | 244 | 101 (37), 111 (25), 106 (25), 112 (17), 114 (16) |
| Vorher | Zaubermeisterin | 24 | 246 | 101 (36), 110 (28), 102 (24), 106 (24), 113 (17) |
| Vorher | Waldläufer | 24 | 163 | 106 (29), 108 (23), 117 (19), 101 (16), 105 (12) |
| Nachher, gepaart | Schwertkämpfer | 24 | 405 | 106 (40), 101 (39), 110 (26), 108 (25), 116 (21) |
| Nachher, gepaart | Zaubermeisterin | 24 | 272 | 110 (39), 101 (30), 107 (27), 106 (22), 108 (18) |
| Nachher, gepaart | Waldläufer | 24 | 217 | 106 (36), 108 (22), 101 (16), 117 (14), 110 (13) |
| Nachher, Holdout | Schwertkämpfer | 12 | 219 | 106 (27), 103 (26), 109 (19), 101 (15), 112 (13) |
| Nachher, Holdout | Zaubermeisterin | 12 | 128 | 109 (19), 114 (13), 106 (13), 104 (12), 112 (10) |
| Nachher, Holdout | Waldläufer | 12 | 90 | 115 (14), 111 (9), 106 (9), 110 (5), 103 (5) |

Die längsten beobachteten Nachher-Runs je Klasse sind Beispiele, keine als optimal bestätigten Builds. Notation: aktive IDs:Level / passive IDs:Level.

| Klasse | Run | Sekunden | Level | Endbuild |
| --- | --- | --- | --- | --- |
| Schwertkämpfer | holdout-Sword-760103-experienced | 1 800,0 | 102 | 101:9, 103:9, 106:9, 110:9, 112:9, 115:9 / 201:9, 202:9, 205:9, 209:9, 210:9, 214:9 |
| Zaubermeisterin | after-Mage-750124-experienced | 503,2 | 29 | 101:9, 106:2, 107:9, 110:4, 113:1 / 201:4, 211:1 |
| Waldläufer | after-Ranger-750112-experienced | 1 302,5 | 36 | 103:3, 106:9, 108:6, 113:2, 116:4, 118:2 / 204:2, 205:2, 207:2, 208:1, 210:1, 212:3 |

Länger überlebende Runs erhalten mehr Angebote und können stärkere Builds erst dadurch erreichen. Eine Korrelation zwischen Auswahl und Überleben ist daher keine kausale Tier-Liste. Die Zahl möglicher Builds übersteigt diese Stichprobe erheblich. Gleiche Seeds balancieren die Startbedingungen der Klassen, aber unterschiedliche Angriffe und Effekte verbrauchen den gemeinsamen Welt-Zufallsstrom verschieden; dieselben Seeds erzwingen keine identischen Spawnfolgen. Aus diesen Daten folgt keine formale menschliche Fairnessbewertung.
