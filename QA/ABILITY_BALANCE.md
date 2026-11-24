# Fähigkeiten: native kontrollierte Messungen

**654 Messfenster tatsächlich ausgeführt:** 18 aktive Fähigkeiten × 9 Stufen × 1/8 Ziele = 324; 18 passive Fähigkeiten × 3 Stufen × 1/8 Ziele × 3 Varianten = 324; drei Startwaffen × 1/8 Ziele = 6. Jedes Fenster dauert 900 echte Produktionsschritte / 15 simulierte Sekunden. Dazu bestehen zehn native Prüfungen mit bekannten HP-Werten. Integrität: `data/ability-validation.json` PASS.

Die Ziele stehen bei 100 Pixel Entfernung, bei acht Zielen in einer Gruppe mit 44 Pixel Streuung; sie haben einen großen HP-Vorrat und deaktivierte Angriffs-/Bewegungs-KI. Dies sind tatsächliche HP-Verluste im nativen Runner, keine vollständigen Runs, menschlichen Kämpfe oder universellen Ranglisten. Ein kurzer Ausschnitt bevorzugt bestimmte Cooldown-Phasen. Heilung und Kontrolle sind gesondert zu lesen.

Rohdaten: `data/ability-baseline.jsonl`; sämtliche Stufen und Quellen bleiben maschinenlesbar. Tabellenexport: `data/controlled-benchmarks.csv`. Diagramm: `charts/active-ability-dps.png`.

## Aktive Fähigkeiten

| ID | Fähigkeit | DPS 1 Ziel St. 1 | St. 5 | St. 9 | DPS 8 Ziele St. 5 |
|---|---|---:|---:|---:|---:|
| 101 | Fireball | 12.60 | 19.80 | 29.98 | 99.00 |
| 102 | Iceball | 11.33 | 18.00 | 26.40 | 18.00 |
| 103 | Lightning | 10.67 | 17.07 | 22.93 | 68.27 |
| 104 | Frost Nova | 3.47 | 5.60 | 9.33 | 44.80 |
| 105 | Arcane Barrage | 16.80 | 33.60 | 46.67 | 33.60 |
| 106 | Healing Pulse | 0.00 | 0.00 | 0.00 | 0.00 |
| 107 | Ember Field | 12.84 | 24.69 | 38.79 | 197.55 |
| 108 | Piercing Lance | 9.00 | 14.33 | 19.67 | 114.67 |
| 109 | Orbit Blades | 7.20 | 10.80 | 15.00 | 39.60 |
| 110 | Stone Spikes | 12.80 | 20.27 | 41.60 | 192.53 |
| 111 | Wisp Sentinel | 16.80 | 38.13 | 65.73 | 38.13 |
| 112 | Thunder Seal | 10.00 | 16.20 | 22.20 | 129.60 |
| 113 | Starfall | 13.87 | 36.61 | 60.98 | 242.28 |
| 114 | Gravity Well | 7.47 | 13.33 | 19.93 | 106.67 |
| 115 | Ice Prison | 14.40 | 28.00 | 45.60 | 224.00 |
| 116 | Returning Glaive | 11.73 | 18.67 | 25.60 | 149.33 |
| 117 | Prismatic Seed | 6.60 | 14.13 | 18.93 | 90.67 |
| 118 | Solar Verdict | 11.47 | 18.67 | 25.87 | 149.33 |

Healing Pulse heilt in diesen Fenstern Stufe 1/5/9 tatsächlich 38/62/126 HP. Sein Schaden von null ist beabsichtigt. Die Heil-Fixture besitzt dafür einen großen echten Fehl-HP-Vorrat.

Wisp Sentinel, Starfall und Arcane Barrage liefern in diesem stationären Einzelziel-Fenster viel Schaden. Starfall, Ice Prison und Ember Field treffen die Gruppe stark. Frost Nova hat geringeren direkten DPS, bietet aber Verlangsamung/Unterbrechung; diese Kontrolle wird im unbewegten Zieltest nicht als Überlebensnutzen gemessen. Eine reine DPS-Rangliste würde diese Unterschiede unterschlagen.

Alle aktiven Fähigkeiten verursachen in jeder getesteten Stufe tatsächlich Schaden oder Heilung. Ein kleiner nicht monotoner Befund: Orbit Blades fällt bei acht Zielen von 40,8 DPS auf Stufe 4 auf 39,6 auf Stufe 5, danach steigt der Wert wieder. Das kurze Fenster, Kreisbahn und Zielanordnung können dies erklären; ohne längere Bahn-/Fensterprüfung wird daraus keine numerische Korrektur abgeleitet.

## Passive A/B-Vergleiche

Verglichen werden ausschließlich `active_control` und `active_plus_passive` bei gleicher aktiver Fähigkeit/Stufe 5, Zielzahl, Seed und Fensterdauer. Die dritte Variante enthält zusätzlich die Klassenwaffe; ohne separaten gleichzeitigen Waffen-Kontrolllauf ist deren Mehrschaden kein isolierter Effekt des Passivums. Nach dem Fenster wird ein tatsächlicher 20-HP-Treffer auf den Spieler ausgeführt; dessen HP-Verlust steht in der Tabelle.

| ID | Passivum St. 9 | Test-Aktiv | DPS ohne → mit | HP-Verlust bei 20 Schaden | Weitere gemessene Größe |
|---|---|---:|---:|---:|---|
| 201 | Orbit Shield | 101 | 19.80 → 19.80 | 8.00 |  |
| 202 | Power Up | 101 | 19.80 → 33.60 | 20.00 |  |
| 203 | Fleet Footed | 101 | 19.80 → 19.80 | 20.00 | Bewegung 4.28 px/Tick |
| 204 | Quick Hands | 101 | 19.80 → 19.80 | 20.00 | Waffen-Haste +45 % |
| 205 | Vitality | 101 | 19.80 → 19.80 | 20.00 | Maximal-HP +108 |
| 206 | Split Runes | 101 | 19.80 → 74.40 | 20.00 |  |
| 207 | Keen Focus | 101 | 19.80 → 24.87 | 20.00 |  |
| 208 | Swift Sigils | 101 | 19.80 → 19.80 | 20.00 | Projektilfaktor 1.50 |
| 209 | Wide Glyphs | 101 | 19.80 → 19.80 | 20.00 | Flächenfaktor 1.31 |
| 210 | Deep Rhythm | 101 | 19.80 → 30.75 | 20.00 |  |
| 211 | Ember Oath | 101 | 19.80 → 27.84 | 20.00 |  |
| 212 | Storm Conductor | 103 | 17.07 → 24.00 | 20.00 |  |
| 213 | Winter Heart | 102 | 18.00 → 25.33 | 20.00 |  |
| 214 | Iron Ward | 101 | 19.80 → 19.80 | 14.60 |  |
| 215 | Renewal | 101 | 19.80 → 19.80 | 20.00 | 32.40 echte Regenerations-HP/15 s |
| 216 | Scavenger | 101 | 19.80 → 19.80 | 20.00 | Sammelradius 204 px |
| 217 | Lingering Hex | 102 | 18.00 → 18.00 | 20.00 | Statusfaktor 1.72 |
| 218 | Resonant Core | 107 | 24.69 → 28.49 | 20.00 |  |

Power Up, Split Runes und Quick Channel zeigen in ihrer passenden Testkonfiguration einen deutlichen offensiven Effekt. Orbit Shield reduziert den tatsächlichen 20-HP-Treffer auf 8 HP; Iron Skin auf 14,6 HP. Vital Bloom erhöht das HP-Maximum um 108; Regeneration stellt im verletzten Testzustand 32,4 HP wieder her. Dies beschreibt die Stufe-9-Fixtures, keinen bewiesenen besten vollständigen Build.

Bewegung, Sammelradius, Zielkontrolle und Verweildauer werden nicht durch stationären DPS vollständig bewertet. Insbesondere kann Arcane Duration beim Iceball die Kontrolle verlängern, ohne hier den Schaden zu erhöhen. Orbit Shields eigener Umlauftreffer erreicht den 100-Pixel-Testpunkt nicht; dessen Schaden wird mit dieser Zielanordnung nicht vollständig charakterisiert.

## Startwaffen und einzelne Komboschritte

| Klasse | DPS 1 Ziel | DPS 8 Ziele |
|---|---:|---:|
| Sword | 38.00 | 222.93 |
| Mage | 34.53 | 235.67 |
| Ranger | 28.40 | 88.00 |

Die Startwaffen sind hier ohne andere aktive/passive Fähigkeiten gemessen. Reichweite, Laufgeschwindigkeit, Sicherheit und tatsächliche Angriffszeit im bewegten Spiel sind darin nicht enthalten. Der Ranger hat im Test weniger Flächenschaden, kann im tatsächlichen Spiel dafür aus größerer Entfernung und schnellerer Bewegung angreifen.

| Klasse | Schritt | Tatsächlicher Schaden/15 s (1 Ziel) | Auslösungen | Erzeugte Projektile |
|---|---:|---:|---:|---:|
| Sword | 1 | 154.00 | 14 | 0 |
| Sword | 2 | 169.00 | 13 | 0 |
| Sword | 3 | 247.00 | 13 | 0 |
| Mage | 1 | 87.00 | 3 | 3 |
| Mage | 2 | 123.00 | 3 | 0 |
| Mage | 3 | 104.00 | 2 | 0 |
| Mage | 4 | 204.00 | 2 | 0 |
| Ranger | 1 | 30.00 | 5 | 5 |
| Ranger | 2 | 30.00 | 5 | 5 |
| Ranger | 3 | 72.00 | 4 | 12 |
| Ranger | 4 | 24.00 | 4 | 4 |
| Ranger | 5 | 24.00 | 4 | 4 |
| Ranger | 6 | 24.00 | 4 | 4 |
| Ranger | 7 | 24.00 | 4 | 4 |
| Ranger | 8 | 24.00 | 4 | 4 |
| Ranger | 9 | 72.00 | 4 | 20 |
| Ranger | 10 | 24.00 | 4 | 4 |
| Ranger | 11 | 24.00 | 4 | 4 |
| Ranger | 12 | 54.00 | 4 | 0 |

## Attributionsregeln und Grenzen

Versuchter Schaden, tatsächlicher HP-Verlust, Overkill, Treffer, normale/Boss-Ziele, kritische Treffer, DoT, echte Projektile und deren Ablauf bleiben je Quelle erhalten. Verzögerte Klassenangriffe behalten ihren ursprünglichen Komboschritt; anhaltende Bossgefahren behalten ihre Geburtsfähigkeit. Passive Verstärkung wird beim ursprünglichen Angriff gezählt, nicht nochmals als erfundener passiver Schaden. Eigene tatsächlich treffende Mechaniken eines Passivums bleiben eigene Mechaniken.

Ein Projektil-Fehlschuss bedeutet ausschließlich ein tatsächlich abgelaufenes Projektil ohne irgendeinen Treffer. Am Fensterende noch fliegende Projektile sind ausstehend, keine Fehlschüsse. Flächenfähigkeiten besitzen keine vergleichbare Projektil-Fehlschussquote. Overkill wird nicht als effektiver DPS ausgegeben.

Eine vollständig kausale Rangliste sämtlicher Zauberkombinationen und aller passiven Überlebenseffekte ist mit dieser Matrix nicht gemessen. Der vollständige Run-Bericht liefert ergänzende Beobachtungen; seltene Kombinationen werden nicht als statistisch bewiesene beste Builds bezeichnet.
