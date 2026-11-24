# FirstGame – Simulationen v3 (Talente, Ausrüstung, Boss-Choreografie)

Eingelesene Zeilen: 1080; davon **vollständige Runs: 1080** (Tod oder 1.800 s). Doppelte IDs: 0. Unvollständige Zeilen (abgebrochene letzte Runs) zählen nicht.

Alle Werte stammen aus nativen GameMaker-Runs mit festen 1/60-s-Schritten und Bots (Anfänger/Durchschnitt/Erfahren). Bots spenden Talentpunkte deterministisch (Klassenbaum zuerst) und legen gefundene Ausrüstung automatisch an. Das sind Bot-Beobachtungen, keine menschlichen Erfolgswahrscheinlichkeiten.

## Klassen

| Klasse | n | Mittel s | Median s | Min 5 | Min 10 | Min 15 | Min 20 | Min 25 | Min 30 | Level (Mittel) | Kills (Mittel) | DPS (Mittel) | Startwaffenanteil | Talentpunkte | Gegenstände |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Mage | 360 | 195,8 | 194,5 | 20 % | 3 % | 1 % | 1 % | 0 % | 0 % | 12,4 | 1 108 | 400,5 | 51,6 % | 2,8 | 2,1 |
| Mage/average | 120 | 239,6 | 203,4 | 19 % | 5 % | 1 % | 0 % | 0 % | 0 % | 14,4 | 1 293 | 445,7 | 53,2 % | 3,3 | 2,6 |
| Mage/beginner | 120 | 54,5 | 51,0 | 0 % | 0 % | 0 % | 0 % | 0 % | 0 % | 5,2 | 159 | 224,8 | 81,8 % | 0,9 | 0,3 |
| Mage/experienced | 120 | 293,2 | 246,0 | 41 % | 4 % | 3 % | 2 % | 1 % | 0 % | 17,6 | 1 872 | 531,0 | 48,8 % | 4,2 | 3,5 |
| Ranger | 360 | 191,3 | 146,2 | 14 % | 2 % | 2 % | 0 % | 0 % | 0 % | 7,7 | 568 | 219,0 | 52,5 % | 1,6 | 0,9 |
| Ranger/average | 120 | 246,0 | 185,8 | 17 % | 5 % | 4 % | 1 % | 1 % | 1 % | 9,3 | 796 | 249,7 | 50,4 % | 2,0 | 1,3 |
| Ranger/beginner | 120 | 71,9 | 71,7 | 0 % | 0 % | 0 % | 0 % | 0 % | 0 % | 3,8 | 117 | 142,0 | 83,3 % | 0,7 | 0,1 |
| Ranger/experienced | 120 | 255,8 | 226,0 | 27 % | 2 % | 1 % | 0 % | 0 % | 0 % | 10,0 | 790 | 265,3 | 50,9 % | 2,1 | 1,2 |
| Sword | 360 | 229,3 | 131,7 | 24 % | 8 % | 5 % | 5 % | 3 % | 2 % | 14,7 | 1 784 | 422,5 | 43,2 % | 3,6 | 2,8 |
| Sword/average | 120 | 219,3 | 133,8 | 15 % | 6 % | 3 % | 3 % | 2 % | 2 % | 14,2 | 1 451 | 392,4 | 44,3 % | 3,4 | 2,6 |
| Sword/beginner | 120 | 29,4 | 27,7 | 0 % | 0 % | 0 % | 0 % | 0 % | 0 % | 3,9 | 59 | 164,5 | 80,1 % | 0,7 | 0,1 |
| Sword/experienced | 120 | 439,1 | 309,4 | 56 % | 18 % | 12 % | 11 % | 6 % | 4 % | 26,1 | 3 841 | 710,7 | 42,5 % | 6,7 | 5,8 |

## Fähigkeiten (Summen aller Runs mit der Fähigkeit)

DPS = Gesamtschaden / Überlebenszeit der Runs, in denen die Fähigkeit im Endbuild war. Auswahlhäufigkeit und Spielzeit unterscheiden sich – keine intrinsische Rangliste.

| Fähigkeit | Runs | Aktivierungen | Treffer | Treffer/Akt. | Schaden | Schaden/Akt. | Schaden/Min | DPS | Heilung |
|---|---|---|---|---|---|---|---|---|---|
| Ice Prison (115) | 148 | 5 826 | 449 326 | 77,12 | 13 722 879 | 2 355,5 | 17 932 | 298,9 | 0 |
| Ember Field (107) | 142 | 7 919 | 674 268 | 85,15 | 13 316 176 | 1 681,5 | 16 833 | 280,6 | 0 |
| Gravity Well (114) | 135 | 4 996 | 682 649 | 136,64 | 9 564 006 | 1 914,3 | 12 681 | 211,3 | 0 |
| Thunder Seal (112) | 124 | 5 054 | 103 142 | 20,41 | 7 314 068 | 1 447,2 | 11 042 | 184,0 | 0 |
| Fireball (101) | 201 | 23 970 | 264 851 | 11,05 | 8 927 069 | 372,4 | 10 192 | 169,9 | 0 |
| Starfall (113) | 150 | 4 739 | 129 795 | 27,39 | 6 741 290 | 1 422,5 | 8 784 | 146,4 | 0 |
| Solar Verdict (118) | 149 | 2 404 | 69 339 | 28,84 | 5 768 532 | 2 399,6 | 8 541 | 142,4 | 0 |
| Stone Spikes (110) | 171 | 7 735 | 132 304 | 17,10 | 5 136 524 | 664,1 | 6 599 | 110,0 | 0 |
| Prismatic Seed (117) | 126 | 5 064 | 78 558 | 15,51 | 2 138 018 | 422,2 | 3 477 | 57,9 | 0 |
| Piercing Lance (108) | 155 | 7 237 | 53 435 | 7,38 | 2 003 939 | 276,9 | 3 436 | 57,3 | 0 |
| Returning Glaive (116) | 151 | 6 409 | 71 074 | 11,09 | 2 212 306 | 345,2 | 3 364 | 56,1 | 0 |
| Frost Nova (104) | 141 | 6 052 | 77 547 | 12,81 | 1 619 250 | 267,6 | 2 613 | 43,6 | 0 |
| Orbit Blades (109) | 152 | 4 340 | 81 919 | 18,88 | 1 644 469 | 378,9 | 2 504 | 41,7 | 0 |
| Lightning (103) | 139 | 14 352 | 53 104 | 3,70 | 1 668 134 | 116,2 | 2 487 | 41,4 | 0 |
| Wisp Sentinel (111) | 163 | 5 212 | 50 874 | 9,76 | 1 032 302 | 198,1 | 1 248 | 20,8 | 0 |
| Arcane Barrage (105) | 157 | 13 207 | 44 303 | 3,35 | 780 424 | 59,1 | 1 043 | 17,4 | 0 |
| Iceball (102) | 138 | 18 130 | 23 023 | 1,27 | 669 112 | 36,9 | 970 | 16,2 | 0 |
| Orbit Shield (201) | 1080 | 25 906 | 25 906 | 1,00 | 128 267 | 5,0 | 35 | 0,6 | 0 |
| Vitality (205) | 82 | 200 | 0 | 0,00 | 0 | 0,0 | 0 | 0,0 | 2 388 |
| Iron Ward (214) | 1080 | 0 | 0 | – | 0 | – | 0 | 0,0 | 0 |
| Healing Pulse (106) | 191 | 4 751 | 0 | 0,00 | 0 | 0,0 | 0 | 0,0 | 126 784 |
| Keen Focus (207) | 133 | 84 533 | 84 533 | 1,00 | 0 | 0,0 | 0 | 0,0 | 0 |
| Renewal (215) | 315 | 59 267 | 0 | 0,00 | 0 | 0,0 | 0 | 0,0 | 11 933 |
| Split Runes (206) | 54 | 9 013 | 0 | 0,00 | 0 | 0,0 | 0 | 0,0 | 0 |
| Resonant Core (218) | 29 | 179 334 | 0 | 0,00 | 0 | 0,0 | 0 | 0,0 | 0 |
| Startwaffe (0) | 0 | 0 | 0 | – | 0 | – | – | – | 0 |

## Bosse innerhalb der vollständigen Runs

| Boss | Begegnungen | Besiegt | Siegquote | Dauer Median s |
|---|---|---|---|---|
| mini_sentinel | 857 | 567 | 66 % | 38,6 |
| mini_warden | 501 | 217 | 43 % | 41,3 |
| storm_warden | 80 | 2 | 2 % | 193,6 |
| twins | 96 | 33 | 34 % | 181,3 |
| behemoth | 116 | 70 | 60 % | 259,8 |

## Bossfähigkeiten (Aktivierungen in den Runs)

| Boss:Fähigkeit | Aktivierungen | bedroht | ausgewichen (bedroht) | Treffer | Schaden | tödlich |
|---|---|---|---|---|---|---|
| behemoth:1 | 2121 | 775 | 332 | 2186.0 | 10 834 | 14.0 |
| behemoth:2 | 1579 | 1579 | 849 | 4125.0 | 11 826 | 12.0 |
| behemoth:3 | 1516 | 1246 | 1138 | 105.0 | 1 993 | 2.0 |
| behemoth:4 | 304 | 152 | 132 | 98.0 | 579 | 2.0 |
| behemoth:5 | 299 | 216 | 144 | 74.0 | 3 273 | 0.0 |
| behemoth:6 | 289 | 61 | 14 | 78.0 | 538 | 0.0 |
| behemoth:7 | 139 | 119 | 53 | 527.0 | 2 864 | 0.0 |
| behemoth:8 | 138 | 138 | 88 | 50.0 | 1 604 | 0.0 |
| behemoth:9 | 132 | 132 | 31 | 140.0 | 4 892 | 1.0 |
| mini_sentinel:automatic_projectile | 27208 | 1482 | 78 | 1403.0 | 11 850 | 53.0 |
| mini_sentinel:lightning | 12949 | 12949 | 12471 | 404.0 | 14 993 | 133.0 |
| mini_sentinel:lob | 6433 | 6433 | 6317 | 81.0 | 1 833 | 18.0 |
| mini_warden:fan | 8844 | 1439 | 70 | 1453.0 | 15 978 | 129.0 |
| mini_warden:lightning | 4480 | 4480 | 4257 | 144.0 | 6 589 | 92.0 |
| storm_warden:1 | 339 | 339 | 110 | 262.0 | 11 667 | 41.0 |
| storm_warden:2 | 180 | 169 | 140 | 31.0 | 1 100 | 11.0 |
| storm_warden:3 | 169 | 169 | 136 | 41.0 | 2 923 | 17.0 |
| storm_warden:4 | 76 | 75 | 71 | 3.0 | 118 | 0.0 |
| storm_warden:5 | 69 | 43 | 43 | 0.0 | 0 | 0.0 |
| storm_warden:6 | 66 | 27 | 0 | 44.0 | 850 | 0.0 |
| storm_warden:7 | 29 | 18 | 0 | 34.0 | 1 031 | 1.0 |
| storm_warden:8 | 24 | 11 | 11 | 0.0 | 0 | 0.0 |
| storm_warden:9 | 25 | 24 | 0 | 49.0 | 1 365 | 3.0 |
| twins:1 | 736 | 437 | 45 | 570.0 | 9 388 | 27.0 |
| twins:2 | 504 | 169 | 147 | 24.0 | 629 | 3.0 |
| twins:3 | 501 | 426 | 217 | 263.0 | 8 134 | 8.0 |
| twins:4 | 134 | 95 | 21 | 102.0 | 3 046 | 2.0 |
| twins:5 | 122 | 108 | 75 | 37.0 | 1 094 | 2.0 |
| twins:6 | 115 | 99 | 64 | 49.0 | 1 737 | 5.0 |
| twins:7 | 56 | 56 | 56 | 0.0 | 0 | 0.0 |
| twins:8 | 58 | 54 | 31 | 29.0 | 830 | 1.0 |
| twins:9 | 56 | 55 | 26 | 29.0 | 1 845 | 0.0 |

## Vergleich mit der Codex-Baseline (Überlebenszeit, Bots)

Mann-Whitney-U (zweiseitig, Normalapproximation). Andere Seeds und ein anderer Code-Stand: Ein p-Wert misst nur, ob sich die beobachteten Verteilungen unterscheiden, nicht die Ursache.

| Klasse/Persona | n vorher | n nachher | Median vorher s | Median nachher s | Mittel vorher | Mittel nachher | p |
|---|---|---|---|---|---|---|---|
| Sword/beginner | 12 | 120 | 20,5 | 27,7 | 24,2 | 29,4 | 0,123 |
| Sword/average | 12 | 120 | 155,7 | 133,8 | 439,3 | 219,3 | 0,162 |
| Sword/experienced | 12 | 120 | 262,5 | 309,4 | 430,0 | 439,1 | 0,635 |
| Mage/beginner | 12 | 120 | 58,3 | 51,0 | 58,6 | 54,5 | 0,328 |
| Mage/average | 12 | 120 | 243,2 | 203,4 | 265,4 | 239,6 | 0,055 |
| Mage/experienced | 12 | 120 | 220,0 | 246,0 | 249,0 | 293,2 | 0,363 |
| Ranger/beginner | 12 | 120 | 76,8 | 71,7 | 87,2 | 71,9 | 0,244 |
| Ranger/average | 12 | 120 | 226,7 | 185,8 | 340,3 | 246,0 | 0,139 |
| Ranger/experienced | 12 | 120 | 215,6 | 226,0 | 306,8 | 255,8 | 0,658 |

## Isolierte Bosskämpfe (270 Kämpfe)

Bot-Spieler mit Entwicklungs-Preset je Minute (Boss-Testmodus). Keine menschlichen Siegquoten.

| Boss | Minute | Kämpfe | Siege | Siegquote (95 %-Wilson) | Dauer Median s |
|---|---|---|---|---|---|
| behemoth | 5 | 18 | 11 | 61 % (39–80 %) | 110,0 |
| behemoth | 10 | 12 | 6 | 50 % (25–75 %) | 83,1 |
| behemoth | 15 | 24 | 12 | 50 % (31–69 %) | 114,0 |
| mini_sentinel | 5 | 18 | 15 | 83 % (61–94 %) | 7,1 |
| mini_sentinel | 10 | 12 | 9 | 75 % (47–91 %) | 6,9 |
| mini_sentinel | 15 | 24 | 18 | 75 % (55–88 %) | 7,0 |
| mini_warden | 5 | 18 | 15 | 83 % (61–94 %) | 13,3 |
| mini_warden | 10 | 12 | 9 | 75 % (47–91 %) | 12,7 |
| mini_warden | 15 | 24 | 18 | 75 % (55–88 %) | 12,1 |
| storm_warden | 5 | 18 | 8 | 44 % (25–66 %) | 103,4 |
| storm_warden | 10 | 12 | 2 | 17 % (5–45 %) | 66,9 |
| storm_warden | 15 | 24 | 2 | 8 % (2–26 %) | 52,1 |
| twins | 5 | 18 | 8 | 44 % (25–66 %) | 121,6 |
| twins | 10 | 12 | 6 | 50 % (25–75 %) | 135,9 |
| twins | 15 | 24 | 6 | 25 % (12–45 %) | 90,9 |

### Bossfähigkeiten in den isolierten Kämpfen

„bedroht“ = der Bot stand in der angekündigten Gefahr; „getroffen“ = davon mit Treffer. Hohe Quoten bei Projektilen sind Bot-Grenzen (die Bots weichen Geschossen nur begrenzt aus).

| Boss:Fähigkeit | Aktivierungen | bedroht | getroffen | Trefferquote bedroht | tödlich | Warnzeit Median s |
|---|---|---|---|---|---|---|
| behemoth:1 | 363 | 195 | 98 | 50 % | 5.0 | 0,00 |
| behemoth:2 | 293 | 293 | 29 | 10 % | 7.0 | 1,34 |
| behemoth:3 | 269 | 261 | 17 | 7 % | 5.0 | 1,25 |
| behemoth:4 | 96 | 17 | 2 | 12 % | 0.0 | 2,09 |
| behemoth:5 | 95 | 91 | 72 | 79 % | 7.0 | 2,18 |
| behemoth:6 | 84 | 11 | 7 | 64 % | 0.0 | 1,14 |
| behemoth:7 | 54 | 53 | 3 | 6 % | 1.0 | 1,32 |
| behemoth:8 | 51 | 51 | 16 | 31 % | 0.0 | 1,14 |
| behemoth:9 | 49 | 49 | 3 | 6 % | 0.0 | 4,07 |
| mini_sentinel:automatic_projectile | 246 | 43 | 43 | 100 % | 3.0 | 0,00 |
| mini_sentinel:lightning | 113 | 113 | 14 | 12 % | 1.0 | 1,15 |
| mini_sentinel:lob | 60 | 60 | 12 | 20 % | 8.0 | 1,40 |
| mini_warden:fan | 235 | 42 | 40 | 95 % | 7.0 | – |
| mini_warden:lightning | 115 | 115 | 19 | 17 % | 5.0 | 1,15 |
| storm_warden:1 | 281 | 281 | 74 | 26 % | 12.0 | 1,06 |
| storm_warden:2 | 203 | 202 | 19 | 9 % | 10.0 | 0,88 |
| storm_warden:3 | 192 | 192 | 18 | 9 % | 14.0 | 1,05 |
| storm_warden:4 | 85 | 85 | 0 | 0 % | 0.0 | 1,58 |
| storm_warden:5 | 66 | 65 | 0 | 0 % | 0.0 | 1,32 |
| storm_warden:6 | 61 | 12 | 12 | 100 % | 0.0 | 0,79 |
| storm_warden:7 | 41 | 17 | 17 | 100 % | 6.0 | 0,70 |
| storm_warden:8 | 28 | 25 | 0 | 0 % | 0.0 | 1,49 |
| storm_warden:9 | 19 | 6 | 5 | 83 % | 0.0 | 0,57 |
| twins:1 | 357 | 164 | 147 | 90 % | 13.0 | 0,51 |
| twins:2 | 260 | 136 | 21 | 15 % | 4.0 | 1,20 |
| twins:3 | 263 | 204 | 41 | 20 % | 2.0 | 1,97 |
| twins:4 | 103 | 58 | 25 | 43 % | 6.0 | 1,14 |
| twins:5 | 106 | 73 | 17 | 23 % | 7.0 | 1,40 |
| twins:6 | 90 | 78 | 22 | 28 % | 0.0 | 1,31 |
| twins:7 | 43 | 43 | 0 | 0 % | 0.0 | 1,62 |
| twins:8 | 45 | 36 | 8 | 22 % | 1.0 | 2,65 |
| twins:9 | 46 | 40 | 1 | 2 % | 1.0 | 3,68 |

## Todesursachen (letzte Schadensquelle)

- unbekannt: 1071
