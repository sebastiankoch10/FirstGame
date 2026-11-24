# Bossbalance – tatsächlich ausgeführte native Kämpfe

Stand 23.11.2026. **360 tatsächlich ausgespielte primäre Begegnungen**, davon 220 echte Boss-Siege und 140 echte Spielertode; kein Fight-Timeout. Gesamt-Sieganteil: **220/360 = 61.1% [56.0%; 66.0%]**. Die drei Hauptbosse haben jeweils neun Fähigkeiten; alle **27** wurden tatsächlich aktiviert. Die zwei Mini-Bosse ergänzen fünf beobachtete Angriffsarten.

Die Ergebnisse zeigen unter diesen Presets einen Vorteil für Sword und einen starken Einfluss der Ausweichsteuerung. Drache ist mit 34/72 Siegen der schwierigste Boss im gemischten Testplan. Die schnell reagierende technische Heuristik gewinnt 82/90 Begegnungen, scheitert also ebenfalls achtmal. Daraus folgt kein Beweis technisch unvermeidbarer Treffer. Boss-Kampfwerte wurden aufgrund dieser Stichprobe noch nicht geändert.

## Datengrundlage und Aussagegrenze

Primärdaten: [boss-baseline.jsonl](data/boss-baseline.jsonl) und [boss-holdout.jsonl](data/boss-holdout.jsonl), je 180 vollständige native Kämpfe im installierten GameMaker-Runner. Python erfasst und analysiert die Produktions-GML; keine nachgebaute Python-Kampfformel. Gleichwertige Initialisierung zum bestehenden Boss-Testmodus: tatsächliches `boss_spawn`, tatsächliche Boss-/Spieler-HP, legale Eingaben, keine Unverwundbarkeit. Logik und Engine bleiben bei 60 Hz; Batchgröße 600 beschleunigt die Verarbeitung. Details und nachgewiesene Grenzen: [SIMULATOR_FIDELITY.md](SIMULATOR_FIDELITY.md).

Testplan pro Datei: 5 Bosse × 3 Klassen × 4 Policies × Minuten 5/10/15 = 180 Zellen; **eine Beobachtung je Zelle und Datei, zusammen nur zwei je Zelle**. Die gewünschten 100 Beobachtungen je Kombination sind nicht erreicht. Alle 360 verwenden den festen ausgewogenen Minuten-Preset, keine Zufallsbuilds und keine normale Gegnerpopulation. Boss-eigene Beschwörungen bleiben Teil des Kampfes. Minuten unterscheiden sowohl Boss-Skalierung/Freischaltungen (3/6/9 Hauptfähigkeiten) als auch Spielerausbau; dies ist kein isolierter Effekt der Zeit.

Baseline-Seeds 810101–810160, Holdout-Seeds 910101–910160, ohne Überschneidung. Innerhalb einer Datei teilen sich die drei Klassen einer Boss/Minute/Policy-Gruppe den Seed. Verschiedene Policies haben verschiedene Seeds; Policy-Unterschiede sind deshalb ungepaarte Vergleiche. Unterschiedlicher RNG-Verbrauch der Klassen verhindert identische Ereignisfolgen trotz gleicher Seeds. Beide Exporte nennen intern `phase=baseline` und `source_phase=baseline`; die Holdout-Zuordnung folgt dem Dateipfad und dem unabhängigen Seedbereich, nicht diesen Metadaten.

Ausgeschlossen aus N=360: 195 gültige Ausführungen mit der alten Policy v1 (180 eindeutige Konfigurationen + 15 Wiederholungen; Kalibrierung), 15 v2-Piloten derselben ersten Konfigurationen sowie 15 ungültige frühe Boss-Piloten mit `room_speed=10000`. Weder Wiederholungen noch gezielte Regressionen werden als zusätzliche unabhängige Beobachtungen gezählt.

| Primärdatei | Kämpfe | Siege / N; 95%-Wilson-Intervall | Tode | Fight-Timeouts |
| --- | --- | --- | --- | --- |
| baseline | 180 | 109/180 = 60.6% [53.3%; 67.4%] | 71 | 0 |
| holdout | 180 | 111/180 = 61.7% [54.4%; 68.5%] | 69 | 0 |

Die Intervalle sind deskriptive binomiale 95%-Wilson-Intervalle für den festen Testmix. Gemeinsame Seeds der Klassentriplets und unterschiedliche Presets schränken die Unabhängigkeitsannahme ein; sie belegen keine menschliche Gewinnwahrscheinlichkeit und ersetzen keine gepaarte oder hierarchische Analyse. Bei n=2 reicht selbst 2/2 nur zu einem Wilson-Intervall von etwa 34–100 %. Keine Signifikanz- oder Äquivalenzbehauptung aus Einzelzellen.

## Sieganteile nach Klasse, Boss, Steuerung und Minute

| Dimension | Wert | Siege / N; 95%-Wilson-Intervall | Siegdauer Median [Min; Max] s |
| --- | --- | --- | --- |
| Klasse | Sword | 87/120 = 72.5% [63.9%; 79.7%] | 107.4 [6.3; 177.9] |
| Klasse | Mage | 66/120 = 55.0% [46.1%; 63.6%] | 12.7 [6.3; 188.9] |
| Klasse | Ranger | 67/120 = 55.8% [46.9%; 64.4%] | 14.3 [6.9; 221.6] |
| Boss | Drache (storm_warden) | 34/72 = 47.2% [36.1%; 58.6%] | 124.5 [105.2; 136.0] |
| Boss | Zwillinge | 39/72 = 54.2% [42.7%; 65.2%] | 171.8 [146.2; 221.6] |
| Boss | Behemoth | 39/72 = 54.2% [42.7%; 65.2%] | 120.2 [105.1; 161.8] |
| Boss | Mini Sentinel | 54/72 = 75.0% [63.9%; 83.6%] | 7.1 [6.3; 12.9] |
| Boss | Mini Warden | 54/72 = 75.0% [63.9%; 83.6%] | 12.6 [11.7; 31.7] |
| Policy | no_response | 0/90 = 0.0% [0.0%; 4.1%] | — [—; —] |
| Policy | average | 59/90 = 65.6% [55.3%; 74.6%] | 12.7 [6.3; 207.4] |
| Policy | experienced | 79/90 = 87.8% [79.4%; 93.0%] | 105.9 [6.9; 208.5] |
| Policy | technical_greedy | 82/90 = 91.1% [83.4%; 95.4%] | 111.0 [6.3; 221.6] |
| Minute | 5 | 80/120 = 66.7% [57.8%; 74.5%] | 105.7 [6.9; 207.4] |
| Minute | 10 | 76/120 = 63.3% [54.4%; 71.4%] | 119.8 [6.7; 208.5] |
| Minute | 15 | 64/120 = 53.3% [44.4%; 62.0%] | 12.4 [6.3; 221.6] |

Siegdauern enthalten ausschließlich tatsächlich gewonnene Kämpfe; frühe Tode verkürzen sie nicht. Die sehr kurzen Mini-Bosse beeinflussen den gemeinsamen Median erheblich. Aggregierte Klassenquoten gelten deshalb nur für diesen identischen Boss-/Policy-/Minutenmix.

### Klasse innerhalb jedes Bosses

| Boss | Sword | Mage | Ranger |
| --- | --- | --- | --- |
| Drache (storm_warden) | 18/24 = 75.0% [55.1%; 88.0%] | 8/24 = 33.3% [18.0%; 53.3%] | 8/24 = 33.3% [18.0%; 53.3%] |
| Zwillinge | 15/24 = 62.5% [42.7%; 78.8%] | 11/24 = 45.8% [27.9%; 64.9%] | 13/24 = 54.2% [35.1%; 72.1%] |
| Behemoth | 18/24 = 75.0% [55.1%; 88.0%] | 11/24 = 45.8% [27.9%; 64.9%] | 10/24 = 41.7% [24.5%; 61.2%] |
| Mini Sentinel | 18/24 = 75.0% [55.1%; 88.0%] | 18/24 = 75.0% [55.1%; 88.0%] | 18/24 = 75.0% [55.1%; 88.0%] |
| Mini Warden | 18/24 = 75.0% [55.1%; 88.0%] | 18/24 = 75.0% [55.1%; 88.0%] | 18/24 = 75.0% [55.1%; 88.0%] |

### Klasse innerhalb jeder Steuerung

| Policy | Sword | Mage | Ranger |
| --- | --- | --- | --- |
| no_response | 0/30 = 0.0% [0.0%; 11.4%] | 0/30 = 0.0% [0.0%; 11.4%] | 0/30 = 0.0% [0.0%; 11.4%] |
| average | 27/30 = 90.0% [74.4%; 96.5%] | 18/30 = 60.0% [42.3%; 75.4%] | 14/30 = 46.7% [30.2%; 63.9%] |
| experienced | 30/30 = 100.0% [88.6%; 100.0%] | 25/30 = 83.3% [66.4%; 92.7%] | 24/30 = 80.0% [62.7%; 90.5%] |
| technical_greedy | 30/30 = 100.0% [88.6%; 100.0%] | 23/30 = 76.7% [59.1%; 88.2%] | 29/30 = 96.7% [83.3%; 99.4%] |

### Steuerung innerhalb jedes Bosses

| Boss | no_response | average | experienced | technical_greedy |
| --- | --- | --- | --- | --- |
| Drache (storm_warden) | 0/18 = 0.0% [0.0%; 17.6%] | 6/18 = 33.3% [16.3%; 56.3%] | 14/18 = 77.8% [54.8%; 91.0%] | 14/18 = 77.8% [54.8%; 91.0%] |
| Zwillinge | 0/18 = 0.0% [0.0%; 17.6%] | 6/18 = 33.3% [16.3%; 56.3%] | 17/18 = 94.4% [74.2%; 99.0%] | 16/18 = 88.9% [67.2%; 96.9%] |
| Behemoth | 0/18 = 0.0% [0.0%; 17.6%] | 11/18 = 61.1% [38.6%; 79.7%] | 12/18 = 66.7% [43.7%; 83.7%] | 16/18 = 88.9% [67.2%; 96.9%] |
| Mini Sentinel | 0/18 = 0.0% [0.0%; 17.6%] | 18/18 = 100.0% [82.4%; 100.0%] | 18/18 = 100.0% [82.4%; 100.0%] | 18/18 = 100.0% [82.4%; 100.0%] |
| Mini Warden | 0/18 = 0.0% [0.0%; 17.6%] | 18/18 = 100.0% [82.4%; 100.0%] | 18/18 = 100.0% [82.4%; 100.0%] | 18/18 = 100.0% [82.4%; 100.0%] |

### Minuten-Preset innerhalb jedes Bosses

| Boss | Minute 5 | Minute 10 | Minute 15 |
| --- | --- | --- | --- |
| Drache (storm_warden) | 12/24 = 50.0% [31.4%; 68.6%] | 13/24 = 54.2% [35.1%; 72.1%] | 9/24 = 37.5% [21.2%; 57.3%] |
| Zwillinge | 16/24 = 66.7% [46.7%; 82.0%] | 13/24 = 54.2% [35.1%; 72.1%] | 10/24 = 41.7% [24.5%; 61.2%] |
| Behemoth | 16/24 = 66.7% [46.7%; 82.0%] | 14/24 = 58.3% [38.8%; 75.5%] | 9/24 = 37.5% [21.2%; 57.3%] |
| Mini Sentinel | 18/24 = 75.0% [55.1%; 88.0%] | 18/24 = 75.0% [55.1%; 88.0%] | 18/24 = 75.0% [55.1%; 88.0%] |
| Mini Warden | 18/24 = 75.0% [55.1%; 88.0%] | 18/24 = 75.0% [55.1%; 88.0%] | 18/24 = 75.0% [55.1%; 88.0%] |

Policies: `no_response` bleibt stehen und verwendet keine Mobilität, greift aber weiter automatisch an; `average` reagiert nach 0,30 s; `experienced` nach 0,12 s; `technical_greedy` nach 1/60 s. Die letzten drei benutzen denselben sichtbaren Kandidaten-/Countdown-Planer, keine getrennte optimale Wegsuche. Bewegungswahl aus acht Richtungen und legale Sprung-/Dodge-Eingaben; sichtbare aktuelle Projektile und Warnflächen, keine zukünftige Rotation oder unveröffentlichte Zufallsentscheidung. Das ist eine Botdefinition, keine Kalibrierung an menschlichem Können.

## Alle 27 Hauptfähigkeiten – Exposition und Treffer

`A` = gestartete Aktivierungen; `T` = jemals als bedrohend erfasst; `HA` = Aktivierungen mit mindestens einem tatsächlichen HP-Treffer; `H` = einzelne HP-Schadensereignisse, einschließlich wiederholtem Schaden/Gift. Trefferquote hier einheitlich `HA/A` über alle gestarteten Aktivierungen. `E/TD` = ohne HP-Verlust abgeschlossene bedrohte Aktivierungen / abgeschlossene bedrohte Aktivierungen. `C` = am Fight-Ende als möglicherweise offen markierte Aktivierungen: Die Telemetrie verwendet dafür die Heuristik `jetzt − last_seen < 0,5 s`, keinen exakten Lebenszyklusbeweis. Entsprechend sind auch E/TD nur nach dieser Heuristik abgeschlossen. Ein abgeschlossener Fight kann offene Angriffe enthalten; C zählt keine zusätzlichen Kämpfe.

**Nennergrenze:** Flächen zählen bereits geometrische Exposition während sichtbarer Warnungen; Projektile zählen bislang tatsächlichen oder geschützten Kontakt. Erfolgreich ohne Kontakt gemiedene Projektile fehlen im T-Nenner. Deshalb darf `HA/T` bei Projektilen weder als faire Trefferquote noch als Unvermeidbarkeitsmaß gelesen werden. `HA/A` enthält ihrerseits räumlich irrelevante und am Fight-Ende offene Angriffe. E umfasst auch Schutz durch Sprung/Dodge/Slide; es ist keine Zahl bewiesener sicherer Laufwege. Keine scheinpräzisen unabhängigen Konfidenzintervalle für innerhalb desselben Kampfes korrelierte Attacken.

| Boss:ID / Fähigkeit | A | T | HA | H | HA/A | E/TD | C |
| --- | --- | --- | --- | --- | --- | --- | --- |
| storm_warden:1 Feuerstrahl | 440 | 440 | 42 | 91 | 9.5% | 390/406 | 34 |
| storm_warden:2 Feuerbogen | 299 | 298 | 8 | 8 | 2.7% | 286/292 | 6 |
| storm_warden:3 Magmaeruption | 307 | 307 | 3 | 3 | 1.0% | 301/301 | 6 |
| storm_warden:4 Meteoritenregen | 166 | 166 | 8 | 9 | 4.8% | 158/165 | 1 |
| storm_warden:5 Bodeneinschlag | 147 | 142 | 1 | 1 | 0.7% | 134/135 | 8 |
| storm_warden:6 Flügelsturm | 129 | 27 | 26 | 49 | 20.2% | 1/24 | 8 |
| storm_warden:7 Void-Orbs | 63 | 20 | 18 | 26 | 28.6% | 2/16 | 9 |
| storm_warden:8 Feuerwirbel | 65 | 55 | 0 | 0 | 0.0% | 55/55 | 0 |
| storm_warden:9 Void-Salven | 33 | 18 | 18 | 29 | 54.5% | 0/18 | 0 |
| twins:1 Doppelte Geschosssalve | 534 | 263 | 221 | 410 | 41.4% | 39/233 | 43 |
| twins:2 Feuer-Eis-Ring | 418 | 213 | 35 | 44 | 8.4% | 173/205 | 16 |
| twins:3 Meteoriten/Eissplitterregen | 387 | 254 | 11 | 13 | 2.8% | 240/251 | 5 |
| twins:4 Verbindungsstrahl | 159 | 49 | 12 | 18 | 7.5% | 37/46 | 8 |
| twins:5 Dualer Spiralwirbel | 166 | 125 | 43 | 77 | 25.9% | 81/112 | 13 |
| twins:6 Kreuzschlag-Strahlen | 149 | 112 | 24 | 30 | 16.1% | 86/107 | 5 |
| twins:7 Brennender Froststoß | 49 | 49 | 0 | 0 | 0.0% | 48/48 | 1 |
| twins:8 Vereinigte Zonenflut | 45 | 29 | 1 | 2 | 2.2% | 28/29 | 0 |
| twins:9 Duale Nova | 48 | 45 | 15 | 15 | 31.2% | 29/44 | 1 |
| behemoth:1 Giftgespucke | 432 | 242 | 139 | 669 | 32.2% | 103/230 | 20 |
| behemoth:2 Säurepfützen | 342 | 342 | 39 | 377 | 11.4% | 287/309 | 33 |
| behemoth:3 Packende Wurzeln | 329 | 329 | 29 | 29 | 8.8% | 293/313 | 16 |
| behemoth:4 Pilzexplosion | 124 | 20 | 0 | 0 | 0.0% | 20/20 | 6 |
| behemoth:5 Sumpfstampfer | 126 | 125 | 100 | 100 | 79.4% | 23/121 | 4 |
| behemoth:6 Sumpfbrut | 116 | 0 | 0 | 0 | 0.0% | 0/0 | 2 |
| behemoth:7 Giftatem | 42 | 41 | 2 | 12 | 4.8% | 39/41 | 0 |
| behemoth:8 Sumpfwelle | 41 | 40 | 11 | 11 | 26.8% | 29/39 | 1 |
| behemoth:9 Verfallsblüte | 41 | 41 | 34 | 34 | 82.9% | 7/38 | 3 |

## Hauptfähigkeiten – tatsächlicher Schaden, Todesursachen und Zeiten

HP/A und HP/H sind tatsächlicher mittlerer HP-Verlust pro Aktivierung bzw. Schadensereignis, nach HP-Begrenzung; Max ist der größte einzelne HP-Verlust. Tod-% teilt die fatalen Treffer durch alle 140 Spielertode der Primärdaten, nicht durch besiegte Bosse. `Profil` ist die statisch geprüfte Basiswarnung vor Minuten-/Phasenskalierung. `Warn-Tel.` ist der erste gültig protokollierte Warnwert einer zugeordneten Teilgefahr: Bei gestaffelten Mustern kann die zuerst durchlaufene Teilgefahr eine späte Stufe sein, bei Behemoth-Gespucke der Splash mit 0 s. Das ist **keine einheitliche Messung der ersten sichtbaren Vorwarnung**. `Erstmals aktiv` ist der erste instrumentierte aktive Zeitpunkt relativ zum Start, kein Nachweis eines dort notwendigen Spielertreffers. Mittelwerte nur über gültige Werte, n in Klammern; — bedeutet nicht erfasst.

| Boss:ID | HP/A | HP/H | Max HP | Fatal | Tod-% | Profil s | Warn-Tel. Ø s (n) | Erstmals aktiv Ø s (n) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| storm_warden:1 | 9.6 | 46.6 | 68.4 | 26 | 18.6% | 1.20 | 1.090 (440) | 1.090 (434) |
| storm_warden:2 | 1.0 | 36.5 | 51.2 | 2 | 1.4% | 1.00 | 0.904 (299) | 0.907 (298) |
| storm_warden:3 | 0.9 | 88.0 | 100.0 | 3 | 2.1% | 1.05 | 1.006 (307) | 1.009 (306) |
| storm_warden:4 | 3.2 | 58.5 | 72.2 | 1 | 0.7% | 1.80 | 1.647 (166) | 1.649 (164) |
| storm_warden:5 | 0.5 | 67.2 | 67.2 | 0 | 0.0% | 1.50 | 1.369 (147) | 1.378 (141) |
| storm_warden:6 | 9.3 | 24.4 | 26.6 | 2 | 1.4% | 0.90 | 0.819 (129) | 0.821 (128) |
| storm_warden:7 | 17.6 | 42.6 | 45.6 | 4 | 2.9% | 0.80 | 0.702 (63) | 0.717 (62) |
| storm_warden:8 | 0.0 | — | 0.0 | 0 | 0.0% | 1.70 | 1.491 (65) | 1.471 (65) |
| storm_warden:9 | 33.4 | 38.0 | 38.0 | 0 | 0.0% | 0.65 | 0.570 (33) | 0.583 (33) |
| twins:1 | 16.2 | 21.1 | 26.6 | 13 | 9.3% | 0.55 | — (0) | 0.528 (534) |
| twins:2 | 3.4 | 32.0 | 41.8 | 2 | 1.4% | 1.20 | 1.156 (418) | 1.154 (415) |
| twins:3 | 1.3 | 40.0 | 47.5 | 0 | 0.0% | 1.40 | 2.087 (387) | 1.147 (385) |
| twins:4 | 4.0 | 34.9 | 41.8 | 3 | 2.1% | 1.30 | 1.188 (159) | 1.157 (157) |
| twins:5 | 18.0 | 38.9 | 45.6 | 12 | 8.6% | 1.50 | 1.372 (166) | 1.376 (165) |
| twins:6 | 9.3 | 46.0 | 53.2 | 3 | 2.1% | 1.40 | 1.280 (149) | 1.160 (149) |
| twins:7 | 0.0 | — | 0.0 | 0 | 0.0% | 1.50 | 1.616 (49) | 1.238 (48) |
| twins:8 | 1.9 | 41.8 | 41.8 | 0 | 0.0% | 1.60 | 1.764 (45) | 1.417 (45) |
| twins:9 | 23.8 | 76.0 | 76.0 | 0 | 0.0% | 1.80 | 3.679 (48) | 1.583 (48) |
| behemoth:1 | 11.8 | 7.6 | 34.2 | 10 | 7.1% | 0.70 | 0.000 (419) | 0.676 (431) |
| behemoth:2 | 5.9 | 5.4 | 15.2 | 9 | 6.4% | 1.10 | 1.299 (342) | 1.061 (339) |
| behemoth:3 | 1.9 | 21.4 | 32.3 | 9 | 6.4% | 1.10 | 1.206 (329) | 1.059 (321) |
| behemoth:4 | 0.0 | — | 0.0 | 0 | 0.0% | 1.60 | 2.152 (124) | 1.470 (119) |
| behemoth:5 | 45.5 | 57.3 | 64.6 | 1 | 0.7% | 1.40 | 1.283 (126) | 1.268 (124) |
| behemoth:6 | 0.0 | — | 0.0 | 0 | 0.0% | 1.30 | — (0) | — (0) |
| behemoth:7 | 2.2 | 7.8 | 34.2 | 0 | 0.0% | 1.50 | 1.316 (42) | 1.317 (42) |
| behemoth:8 | 14.0 | 52.3 | 53.2 | 1 | 0.7% | 1.30 | 1.140 (41) | 1.150 (41) |
| behemoth:9 | 55.6 | 67.1 | 68.4 | 3 | 2.1% | 1.90 | 4.067 (41) | 1.667 (41) |

Die Basiswarnungen werden durch den Produktions-Speedfaktor geteilt (Minute 5/10/15: 1,00/1,07/1,14). Dragon-Strahl/-Bogen verkürzen ab Phase 3 zusätzlich um 12 %; Mindestwarnung 0,55 s, für Magma 0,85 s. Twins/Behemoth mindestens 0,50 s, mit zusätzlichen Verzögerungen gestaffelter Teilflächen. Bewegte Salven besitzen keine Boden-Countdownfläche; Basis-Windup und sichtbare Projektilreaktionszeit sind unterschiedliche Größen. Diese statischen Konfigurationen ergänzen die Telemetrie, ersetzen aber keine gerenderte Messung der tatsächlich erkennbaren Warnung.

Die Schadenstraces stimmen pro Fight mit dem tatsächlichen HP-Verlust überein; genau eine fatale Quelle pro Spielertod. Größter einzelner Todesverursacher: Drachen-Feuerstrahl mit 26/140 Toden (18,6 %); danach Zwillinge-Salve 13, beide Spiralwirbel zusammen 12, Behemoth-Giftgespucke inklusive zugeordnetem Gift 10, Säurepfützen und Wurzeln je 9. Direkter Schaden und nachlaufendes Gift bleiben der konkreten Aktivierung zugeordnet. `Sumpfbrut` ist eine Beschwörung mit nominal 0 Direktschaden; 0 eigene HP-Treffer allein beweist keine wirkungslose Beschwörung.

### Mini-Bosse separat

| Boss:Angriff | A | T | HA | H | HA/A | E/TD | Fatal | C |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| mini_sentinel:automatic_projectile | 293 | 62 | 62 | 62 | 21.2% | 0/56 | 4 | 224 |
| mini_sentinel:lightning | 133 | 133 | 20 | 20 | 15.0% | 61/79 | 2 | 54 |
| mini_sentinel:lob | 73 | 73 | 19 | 19 | 26.0% | 53/60 | 12 | 13 |
| mini_warden:fan | 285 | 56 | 54 | 54 | 18.9% | 0/20 | 10 | 173 |
| mini_warden:lightning | 135 | 135 | 24 | 24 | 17.8% | 111/127 | 8 | 8 |

## Fähigkeiten- und Phasenabdeckung

| Boss / Minute | N | verschiedene aktivierte IDs | alle freigeschalteten IDs pro Fight | Phase 1 / 2 / 3 / 4 erreicht |
| --- | --- | --- | --- | --- |
| Drache (storm_warden) / 5 | 24 | 1, 2, 3 | 16/24 | 24 / 16 / 15 / 15 |
| Drache (storm_warden) / 10 | 24 | 1, 2, 3, 4, 5, 6 | 17/24 | 24 / 16 / 16 / 16 |
| Drache (storm_warden) / 15 | 24 | 1, 2, 3, 4, 5, 6, 7, 8, 9 | 16/24 | 24 / 15 / 15 / 13 |
| Zwillinge / 5 | 24 | 1, 2, 3 | 24/24 | 24 / 19 / 19 / 16 |
| Zwillinge / 10 | 24 | 1, 2, 3, 4, 5, 6 | 18/24 | 24 / 18 / 16 / 14 |
| Zwillinge / 15 | 24 | 1, 2, 3, 4, 5, 6, 7, 8, 9 | 12/24 | 24 / 12 / 12 / 11 |
| Behemoth / 5 | 24 | 1, 2, 3 | 24/24 | 24 / 18 / 17 / 17 |
| Behemoth / 10 | 24 | 1, 2, 3, 4, 5, 6 | 18/24 | 24 / 18 / 15 / 14 |
| Behemoth / 15 | 24 | 1, 2, 3, 4, 5, 6, 7, 8, 9 | 17/24 | 24 / 16 / 11 / 9 |

Abdeckung ist Überdeckung der Stichprobe, keine vollständige Prüfung jeder Fähigkeit in jeder Phase und jedem Überlappungszustand. Frühe Tode und die Freischaltung begrenzen spätere Fähigkeiten systematisch; Null Treffer kann geringe oder selektierte Exposition bedeuten. Vollständige Policy-Zähler und alle 180 Zellen stehen in [boss-combined-validation.json](data/boss-combined-validation.json).

## Drache – Minute 15, neun Fähigkeiten und vier Phasen

**9/24 = 37.5% [21.2%; 57.3%]**, 13/24 erreichten alle vier Phasen, 16/24 aktivierten alle neun Fähigkeiten. Alle neun Fähigkeiten und jede Phase sind insgesamt abgedeckt; nicht jede Begegnung gelangte dorthin. Echte Siege: Median 129.0 s, Bereich 125.9–136.0 s; **9/9 Siege im Ziel 120–180 s**. Das bestätigt erreichbare Zieldauer mit diesen festen Builds; 15/24 Tode verhindern eine pauschale Aussage über repräsentative erfolgreiche Spieler oder Zufallsbuilds.

| Policy / Klasse | Siege / N | alle 4 Phasen | alle 9 Fähigkeiten | Siegdauer(n) s |
| --- | --- | --- | --- | --- |
| no_response / Sword | 0/2 = 0.0% [0.0%; 65.8%] | 0 | 0 | — |
| no_response / Mage | 0/2 = 0.0% [0.0%; 65.8%] | 0 | 0 | — |
| no_response / Ranger | 0/2 = 0.0% [0.0%; 65.8%] | 0 | 0 | — |
| average / Sword | 2/2 = 100.0% [34.2%; 100.0%] | 2 | 2 | 129.17, 127.63 |
| average / Mage | 0/2 = 0.0% [0.0%; 65.8%] | 0 | 2 | — |
| average / Ranger | 0/2 = 0.0% [0.0%; 65.8%] | 0 | 1 | — |
| experienced / Sword | 2/2 = 100.0% [34.2%; 100.0%] | 2 | 2 | 127.53, 128.23 |
| experienced / Mage | 1/2 = 50.0% [9.5%; 90.5%] | 2 | 2 | 135.98 |
| experienced / Ranger | 0/2 = 0.0% [0.0%; 65.8%] | 2 | 2 | — |
| technical_greedy / Sword | 2/2 = 100.0% [34.2%; 100.0%] | 2 | 2 | 128.98, 125.92 |
| technical_greedy / Mage | 1/2 = 50.0% [9.5%; 90.5%] | 2 | 2 | 134.38 |
| technical_greedy / Ranger | 1/2 = 50.0% [9.5%; 90.5%] | 1 | 1 | 133.55 |

Phasenwechsel erfolgen bei 75/50/25 % Rest-HP. Maximal 16 gleichzeitig gezählte Gefahrenobjekte in diesen Kämpfen; der Zähler umfasst auch räumlich entfernte Projektile und ist keine Zahl gleichzeitig den Spieler bedrohender Flächen. Rotationen und Überlappungen liefen durch die Produktionslogik; gerenderte Wahrnehmbarkeit und sämtliche kritischen Kombinationen wurden mit diesen Daten nicht vollständig vermessen.

## Fairnessbefund und konkrete nächste Schritte

**Tatsächlich nicht vermeidbar:** Häufigkeit nicht bestimmt. Es gibt keinen vollständigen zeitabhängigen Erreichbarkeitstest mit allen Hindernissen, sicheren Bereichen und Mobilitäts-Cooldowns. Ein Treffer von `technical_greedy` ist ein Untersuchungsfall, kein Unvermeidbarkeitsbeweis. Die Heuristik bewertet sichtbare Geometrie, aktuelle Bewegungen und legale Schutzfenster; sie exportiert keine vollständigen Distanz-/Routenbeweise für jeden Treffer.

**Auffällig schwierig im Botmodell:** Behemoth-Sumpfstampfer trifft in 100/126 Aktivierungen (79,4 %), davon 40/49 bei `technical_greedy`; acht bedrohte technische Aktivierungen endeten dennoch ohne HP-Verlust. Verfallsblüte trifft in 34/41 Aktivierungen (82,9 %), bei der technischen Policy 18/18. Die Blüte wechselt von Außenblättern zum Kern und dann zum Sporenring. Beide brauchen gezielte Zustands-Replays mit verbleibender Warnzeit, Abstand zum sicheren Bereich, Sprung-/Dodge-Verfügbarkeit und überlagerten Gefahren. Die Stichprobe allein trennt schwierige Geometrie, unzureichende Botplanung und unmögliche Flucht nicht.

**Gefährlich mit dokumentierten Gegenbeispielen:** Feuerstrahl verursacht 26 Tode; zugleich wurden 42/440 Aktivierungen mit HP-Schaden beobachtet und zahlreiche bedrohte Aktivierungen ohne HP-Verlust beendet. 16 der 26 Strahltode betreffen die stillstehende Kontrolle; neun `average`, einer `experienced`, keiner `technical_greedy`. Das belegt hohe Gefahr für bestimmte Steuerungen, keine unfairen Zufallsschäden. Drachen-Void-Orbs, Wind und Salven sowie Twins-Salve sind bewegte Projektile: hohe kontaktbasierte T-Quoten erlauben keine technische Fairnessklassifikation. Produktionscode nutzt für alle Angriffe die Spieler-Schutzfunktion: aktiver Dodge schützt alle Höhen, Luft-/Slide-Zustände schützen Bodenangriffe, Slide schützt hohe Angriffe; `all` hat keinen Sprung-/Slide-Schutz ohne aktiven Dodge.

**Auffällig geringe Wirkung in erreichter Stichprobe:** Drachen-Feuerwirbel 0/65 HP-treffende Aktivierungen bei 55 bedrohten/erfolgreich ohne HP-Verlust abgeschlossenen Aktivierungen; Twins-Froststoß 0/49 bei 48 abgeschlossenen Vermeidungen; Behemoth-Pilzexplosion 0/124 bei nur 20 geometrisch bedrohten Aktivierungen. Das sind Kandidaten für zu leichtes Ausweichen oder Positionsauswahl der Bots, keine gesicherten wirkungslosen Angriffe. Die stillstehende Kontrolle stirbt vor diesen späteren Angriffen; ein sauberer Vergleich ohne gezielte Ausweichreaktion fehlt dort. Sumpfbrut separat als Beschwörung bewerten.

**Geometrie/Warnung statisch geprüft:** Reale Kreis-, Ring-, Sektor- und Linienproben, Spieler-Kontaktradius und Produktions-Hindernisse werden verwendet. Der Drache besitzt unter anderem einen fixierten Strahl (48 px Breite, mindestens 1.200 px Länge, bei Bedarf bis über den sichtbaren Bereich verlängert), gezielte Flächen und gestaffelte Muster; Twins und Behemoth ergänzen bewegte Linien, Ringlücken und Wellen. Die aktive Gefahr kann sich nach der Startwarnung ändern. Eine berechnete nominelle Warnzeit allein beweist daher keine erreichbare sichere Position oder passende Renderanzeige. Normales Rendering und menschliche Lesbarkeit sind getrennte Prüffelder.

Priorität: (1) **Boss-Fairnessproblem, offen:** Trefferzustände von Sumpfstampfer/Verfallsblüte reproduzieren und echte sichere Wege mit legalen Inputs prüfen; (2) **Balancingproblem, Hinweis:** Klassenunterschiede an Hauptbossen mit mehr unabhängigen Seeds und zusätzlichen Builds nachmessen; (3) **Noch nicht getestete Funktion:** späte Angriffe mit einer überlebensfähigen Vergleichssteuerung ohne gezielte Warnungsreaktion isoliert prüfen; (4) **Noch nicht getestete Funktion:** menschliche Wahrnehmung/Animation und ungünstige Überlappungen in normaler Engine-Sitzung. Keine dieser offenen Prüfungen ist als bestätigter Produktionsbug eingestuft.

## Änderungen, Vergleich und Reproduzierbarkeit

Produktionsänderungen dieses Auftrags betreffen die visuelle Hurt-Frame-Begrenzung und `normal_coin_speed` 252 → 420; keine Boss-HP-, Schadens-, Warnzeit-, Flächen- oder Rotationswerte wurden geändert. Diese isolierten Presetkämpfe liefern deshalb **keinen Nachweis einer Bossbalance-Verbesserung**. Der Holdout ist eine neue Seedstichprobe derselben Kampflogik, kein Nachherzustand.

Zusätzlich tatsächlich ausgeführt: **15 gepaarte Nachher-Replays**, [boss-after-selected.jsonl](data/boss-after-selected.jsonl), dieselben ersten 15 Baseline-Fälle (alle fünf Bosse × drei Klassen, Minute 15, `average`, Seeds 810101–810105). 15/15 stimmen nach JSON-Auswertung exakt überein bei Ergebnis, Dauer, Start-/Rest-HP, Phasen, Gefahrenmaximum, Build und vollständiger Kampftelemetrie einschließlich Quellen/Aktivierungen; Nachher 9 Siege, 6 Tode. Damit liegen **375 ausgewertete aktuelle Fight-Ausführungen vor, weiterhin N=360 in der primären Stichprobe**. Der Replay stützt Regressionstreue für diese Konfigurationen; er belegt weder eine Balanceverbesserung noch normale Renderleistung. [Replay-Integrität](data/boss-after-selected-validation.json) und paarweise Details im kombinierten Export.

Integrität: [Baseline-Validierung](data/boss-baseline-validation.json), [Holdout-Validierung](data/boss-holdout-validation.json), [kombinierter Plan-/Statistikexport](data/boss-combined-validation.json). Beide Dateivalidierungen prüfen echte HP-Endzustände, eindeutige IDs, vollständige Ein-/Ausgangsschadenssummen, genaue fatale Quellen und die Übereinstimmung der Tick-/Telemetriezeit. Der kombinierte Export prüft zusätzlich den vollständigen Zellplan, zwei Beobachtungen pro Zelle, Policy/Build-Konfiguration und getrennte Seedbereiche. SHA-256-Eingabehashes stehen dort.

Reproduktion aus dem Projektverzeichnis:

```powershell
python QA/tools/validate_boss_data.py QA/data/boss-baseline.jsonl --out QA/data/boss-baseline-validation.json
python QA/tools/validate_boss_data.py QA/data/boss-holdout.jsonl --out QA/data/boss-holdout-validation.json
python QA/tools/validate_boss_data.py QA/data/boss-after-selected.jsonl --out QA/data/boss-after-selected-validation.json
python QA/tools/write_boss_report.py
```

Rohdaten behalten Seeds, Builds, Policyversion, tatsächliche HP, Aktivierungen und Schadensquellen. Projektil-Fehlschüsse anderer Schadensquellen bedeuten ausschließlich tatsächlich abgelaufene Projektile ohne Treffer; am Kampfende noch fliegende Projektile zählen nicht als Fehlschuss. Quellen: `QA/tools/boss_mc_harness.gml`, `QA/tools/native_mc_harness.gml`, `QA/tools/qa_telemetry.gml`, `scripts/boss_framework_v2/`, `scripts/boss_encounters_v2/`, `scripts/dragon_encounter/`, `scripts/gameplay/`. Technisch unvermeidbare Treffer und menschliche Fairness sind **nicht bestimmt**, keine geschätzten Nullen.
