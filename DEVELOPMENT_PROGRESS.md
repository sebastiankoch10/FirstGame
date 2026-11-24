# FirstGame – Entwicklungsfortschritt (Auftrag „Talentbäume, Gameplay, Bossmechaniken“, ab 24.11.2026)

Dieses Dokument wird nach jedem Abschnitt aktualisiert. Bei einem Kontext- oder Nutzungslimit hier weitermachen.
Arbeitsweise: Änderungen direkt im Projekt (F5 in GameMaker). Tests bauen isolierte Kopien unter `%LOCALAPPDATA%\FirstGame-Tests\`. Git nur lokal (Branch `entwicklung`), kein Push.

## 1. Bestandsaufnahme (vor Beginn)

| Bereich | Stand vor diesem Auftrag | Bewertung |
|---|---|---|
| Talentbaum | Nicht vorhanden. Keine Spezifikation im Projekt, in den QA-Dokumenten oder in den 14 früheren Codex-Aufträgen (`~/.codex/attachments`, `~/.codex/sessions` durchsucht nach Talent/Skill Tree/Talentpunkte/Ausrüstung). | Nicht vorhanden → neu implementiert |
| Ausrüstung („ohne Rüstung starten, Ausrüstung finden“, Nutzerwunsch vom 24.11.) | Nicht vorhanden. „Ausrüstung“ kam früher nur als Wort für die zwölf Zauberslots vor. | Nicht vorhanden → neu implementiert |
| 18 aktive / 18 passive Zauber, Stufe 1–9, max. 6+6 Slots | Implementiert und getestet (QA_SUMMARY, 811 Regressionsprüfungen) | Fertig → übersprungen |
| Abhängige Passiva (Split Runes nur mit 101/102/105 usw.) | `spell_passive_eligible` prüft zentral für Angebot und Upgrade | Fertig → übersprungen |
| Zauberstatistiken (Schaden, Treffer, Auslösungen, Heilung, Abklingzeit, Stufe) | Pausenmenü-Detailfenster per Hover (`spell_detail_draw`) | Fertig → übersprungen |
| Klassenkombos (Schwert 3er-Kette, Magierin 4er, Waldläufer 12er inkl. 3/5-Salve und Pfeilhagel) | Implementiert, in QA vermessen | Fertig → übersprungen |
| Zauber-Licht/Partikel | Nur kurze Lichtimpulse (max. 24) und Sprite-Bursts; Felder ohne dauerhaftes Licht, keine Partikel/Spuren | Teilweise → ergänzt |
| Bosse: 9 Fähigkeiten, Freischaltung 3/6/9 beim Spawn, Phasen, Zufallsauswahl | Implementiert (Drache, Hexen, Behemoth) | Fertig (Grundgerüst) |
| Boss-Designphilosophie (DESIGN/BOSS_DESIGN.md) | Analyse vorhanden, nicht umgesetzt (keine Schwenkstrahlen im Katalog, keine Schachbrett-/Streifen-/Quadrantenmuster, Teleport statt Aufholattacke) | Offen → in Arbeit |
| Boss-Testmodus | Menüpunkt „Boss testen“, Drache/Minute 15/alle 9, F1-Unverwundbarkeit | Weitgehend vorhanden → prüfen/ergänzen |
| 3.000 Simulationen | 192 vollständige native Runs (Codex), Infrastruktur `QA/tools/run_cohort.py` | Teilweise |

## 2. Neu abgeschlossen

### 2.1 Talentbaumsystem (Priorität 1) – FERTIG, nativ getestet
- **Datei:** `scripts/talents/talents.gml`.
- **Architektur:** datengetrieben, getrennt von den Zauberslots. Jede Definition hat:
  - `id`, `tree`, `name`, `desc` mit Platzhaltern, `icon`
  - Position `col`/`row`, maximalen Rang `max`
  - Voraussetzungen `req` als `[[id, Mindestrang], …]`
  - Wirkungen `fx` als `{schlüssel: Wert pro Rang}`
- **Bäume:**
  - Allgemein: 9 Talente.
  - Je Klasse 8 Talente:
    - Schwertkämpfer: Schaden, Reichweite, Tempo, Druckwelle beim Finale, Sturmangriff nach der Ausweichrolle, Rüstung, Heilung beim Finale. Meistertalent „Klingensturm“: jede 4. Kette endet mit einem 360°-Hieb.
    - Zaubermeisterin: Power, Fläche, Schadensreduktion, Sternenorb, Abklingzeit, Bannkreis-Verlangsamung, Elementarbonus. Meistertalent „Supernova“: Sog plus zweite Explosion.
    - Waldläufer: Pfeilschaden, Tempo, Reichweite, breitere Salven, dichterer Pfeilhagel, Bewegung, Krit. Meistertalent „Sturmköcher“: ein Fächer aus 7 Pfeilen beim Pfeilhagel.
- **Zustände:** gesperrt (Voraussetzung fehlt), verfügbar, investiert, maximal.
  - Fremde Klassenbäume sind unsichtbar und gesperrt.
  - `talent_block_reason` liefert den Grund als lesbaren Text.
- **Punkte (konfigurierbar in `talent_config()`):**
  - ab Spielerstufe 4 alle 4 Stufen 1 Punkt
  - +1 je besiegtem Hauptboss, 0 für Minibosse
  - `persistent=false`: Talente gelten pro Run. Mit `true` werden sie je Klasse in `firstgame_talents.ini` gespeichert; der Code dafür ist vorhanden.
- **Wirkung:** `talent_equipment_apply` ganz am Ende von `apply_passives`. Klassenmechaniken sitzen in `master_combat.gml` und `class_weapons.gml`. Rang 0 ist überall neutral.
- **Oberfläche:** Charakterbildschirm mit Taste **T** oder über den Pausenpunkt „Talente & Ausrüstung“.
  - Pixel-Knoten mit Rangpunkten, Verbindungslinien, Schloss-Symbol, Meistertalente als Raute
  - Tooltip mit aktueller und nächster Wirkung sowie Voraussetzungen; Investieren per Mausklick
  - Im HUD erscheint „Talentpunkte: N [T]“
- **Die Werte sind neue Designwerte**, da es keine frühere Vorgabe gab. Siehe Abschnitt 4 „Offene Designentscheidungen“.

### 2.2 Ausrüstung – FERTIG, nativ getestet
- **Datei:** `scripts/equipment/equipment.gml`. Icons: `spr_eq_icons`, 8 Frames, erzeugt mit `tests/tools/levels/equip_icons.py`.
- **Slots:** Waffe, Kopf, Brust, Hände, Füße, Talisman. Jeder Run startet **ohne Ausrüstung**.
- **Seltenheit** (bestimmt die Zahl der Werte):
  - Gewöhnlich: 1 Wert
  - Magisch: 2 Werte
  - Selten: 3 Werte
  - Episch: 4 Werte
- **Gegenstandsstufe:** 1 + Spielminute / 2,5.
- **Werte je Slot:** Der erste Wert ist fest, die übrigen werden zufällig gezogen. Der Zufall nutzt einen eigenen Park-Miller-RNG.
- **Quellen:**
  - Hauptboss: 2 Gegenstände, einer davon mindestens selten
  - Miniboss: 1 Gegenstand, mindestens magisch
  - normale Gegner: 0,3 %
- **Aufnahme durch Darüberlaufen:**
  - Ein leerer Slot wird automatisch belegt, sonst geht der Gegenstand in den Rucksack (8 Plätze).
  - Im Charakterbildschirm: Linksklick legt an oder tauscht, Rechtsklick wirft weg.
  - Der Tooltip vergleicht mit dem angelegten Gegenstand.
- **Darstellung:**
  - Drops in der Welt mit Lichtsäule in Rarity-Farbe und eigener Lichtquelle
  - Punkte auf der Minimap
  - Einblendungen „Angelegt/Gefunden“
- **Grenze:** Die Charaktersprites ändern sich durch Ausrüstung **nicht** optisch. Dafür bräuchte es Rüstungsvarianten aller Animationen in 8 Richtungen für 3 Klassen; das ist mit dem prozeduralen Werkzeug nicht in Produktionsqualität machbar.

### 2.3 Zauber-Licht und Partikel – FERTIG (visuell geprüft)
- **Datei:** `scripts/spell_vfx/spell_vfx.gml`.
- **Partikelpool:** begrenzt auf 420; additive Punkte, Striche, Rauten und Runen.
  - Burst-Partikel je Element bei jedem `spell_fx_burst`
  - Spuren für Feuerball, Eiskugel, Arkan, Stab und Pfeil
  - Dauer-Emitter für Feuerfeld (Glut und Flammenzungen), Schwerkraftbrunnen (Sog-Spirale), Eisgefängnis (Schneefall), Orbit-Klingen, Irrlicht, Siegel und Urteil (aufsteigende Runen), Gleve, Prismensaat und Sternenregen-Spuren
  - Klasseneffekte: Magiekreis-Runen, Sternenorb-Funken, Pfeilhagel-Staub
- **Dauerhafte Lichtquellen** für alle aktiven Felder und Klasseneffekte im bestehenden multiplikativen Lichtsystem.
- Das Limit der Lichtimpulse steigt von 24 auf 40. Das Budget von 72 Lichtquellen bleibt bestehen.

### 2.4 Bosskampf-Designphilosophie – UMGESETZT, nativ getestet
- **Dateien:** `scripts/boss_choreo/boss_choreo.gml` ist neu; eingebaut in `boss_hazards_v2`, `dragon_encounter`, `dragon_boss` und `boss_encounters_v2`.
- **Vollständige Übersicht:** `DESIGN/BOSS_DESIGN.md`, Abschnitt „Umsetzungsstand“.
- **Musterbibliothek** auf den bestehenden bv2-Gefahren, eine Uhr je Boss:
  - Schachbrett und invertiertes Schachbrett
  - Streifen
  - Quadranten
  - innen/außen
  - Explosionskette
  - schließender Giftring
  - Schwenkstrahl mit 2.600 px
- **13 Fähigkeiten** der drei Bosse haben phasenabhängige, komplexere Varianten. Es bleiben 9 Fähigkeiten je Boss, die Freischaltung 3/6/9 ist unverändert, und es gibt keine neuen HP- oder Schadenswerte.
- **Seltene Aufholattacken:** Sturzflug (Drache), Untertauchen (Behemoth), Formationswechsel (Hexen). Der Teleport bleibt nur als Notfall bei mehr als 850 px außerhalb des Bildes, nach 6 s statt 2,5 s.
- **Überlappende Wellen** sind lesbar: Die nächste Welle wird kräftig mit Countdown gezeigt, die spätere Welle nur blass mit Punktmarkierung.
- **Warnungen allgemein (Priorität 9):** Zusätzlich zum Zeiger in der Mitte läuft ein radialer Countdown am Zonenrand. Kurz vor dem Einschlag leuchtet die Kante auf. Es gilt dieselbe Uhr wie für den Treffer.
- **Waldwächter (Punkt 39):** war schon korrekt. Er hat einen eigenen automatischen Grundangriff, ein Einzelgeschoss alle 1,6 s ohne Bodenwarnung.
- **Boss-Testmodus (Priorität 10):** Vorhanden waren:
  - Auswahl von Boss, Zufallsboss, Minute, Klasse, Build, Schwierigkeit, Einzelangriff und Seed
  - Direktstart „Drache / Minute 15 / alle neun“
  - F1 Unverwundbarkeit, F2 Heilen, F3 Phase, F4 Boss-HP 25 %, F5 Attacke, F10 Körperboxen

  Neu sind F6 (Attacke wechseln), F7 (Aufholattacke erlauben), F8 (+5 Talentpunkte) und F9 (epischer Testgegenstand).

## 3. Tests (ehrlich gekennzeichnet)

| Test | Ergebnis |
|---|---|
| Kompilierung echtes Projekt (Igor, VM) | PASS |
| `python tests/tools/run_native_harness.py feature` – Talente/Ausrüstung/VFX/Charakterbildschirm für alle 3 Klassen, nativ | **PASS 129/129** (24.11. 07:03, erneut nach Bossarbeit PASS 129/129) |
| `python tests/tools/run_native_harness.py boss` – alle 9 Fähigkeiten × Phase 1/3 × 3 Bosse mit Orakel-Ausweich-Bot; Kiting 560 px je Boss mit der Rotation | **PASS 135/135**. Kein Frame ohne erreichbare sichere Position. Strahlreichweite 2.600 px, Schlammwelle 1.500 px. Kiter auf 560 px werden von 15–19 Gefahren je Boss erreicht. Natürliche Aufholattacken: Drache 2, Behemoth 2; die Hexen folgen per Formation (Ø 476 px). Ihre Aufholattacke lief erzwungen fehlerfrei. |
| `python QA/tools/validate_project.py` (statisch) | PASS: 1.380 Ressourcen, keine neuen Fehler (3 bekannte alte verwaiste Kollisionsdateien) |
| `python QA/tools/run_qa_regression.py` (811 Codex-Prüfungen) | 1. Lauf: 810/811. Fehlgeschlagen ist „Dragon beam causes real active HP loss“. Die Testvorlage stellte den Spieler auf die alte, starre Strahlrichtung. Sie wurde angepasst: Spieler auf der angekündigten Startkante des Schwenkstrahls, Treffer im ersten Aktivierungsframe. **2. Lauf: PASS 811/811** (24.11. 07:53) |
| `python tests/tools/run_level_smoke.py` (3 Level, Menü bis Neustart) | **PASS 166/166**. Framezeit bei 80 Gegnern: Ø 17,6 / 17,1 / 17,1 ms (vorher Ø ≈ 17 ms, also unverändert). Einzelne Spitzen bis 321 ms wie zuvor. |
| QA-Validierungsprobe neues Artefakt (`run_native_mc.py --mode validation`) | PASS (600 Ticks, keine Fehler, Talent- und Ausrüstungsfelder im Export) |
| Simulationskohorte `QA/data/v3-cohort-a`: 12 Worker × 30 Runs je Klasse = 1.080 Runs Ziel | gestartet 24.11. 08:02. Ergebnis: Abschnitt 5 und `QA/V3_SIMULATION_REPORT.md` |
| Menschlicher Spieltest | NOT RUN |

**Bekannte Grenzen der Bosstests:**
- Das Orakel sieht nur bv2-Gefahren. Die älteren Drachenangriffe (Bogen, Bodeneinschlag, Flügelsturm, Void, Wirbel, Salven) und alle Projektile sind darin nicht erfasst; sie sind unverändert und waren in der Codex-QA vermessen.
- Treffer des Orakels sind Bot-Treffer, kein Beweis für Unfairness. Sie entstanden nur bei bewusst beweglichen Mechaniken: rotierender Verbindungsstrahl, Säurestreifen, Projektilspritzer.

## 4. Offene Designentscheidungen (Talente/Ausrüstung)
- **Punktequelle und -tempo:** jetzt alle 4 Stufen plus Hauptboss. Ob Talente pro Run gelten oder dauerhaft sind (Meta-Progression), ist offen; umschaltbar über `talent_config().persistent`.
- **Respec:** Ein Zurücksetzen der Talente ist nicht vorgesehen.
- **Zahlenwerte von Talenten und Gegenständen:** Es sind neue, bewusst moderate Werte. Sie sind ausdrücklich nicht durch Simulation ausbalanciert.
- **Ausrüstungsoptik am Charakter:** nicht umgesetzt (siehe 2.2).

## 5. Nächste Schritte
1. Boss-Designphilosophie umsetzen: Choreografie-Muster, Schwenkstrahlen, Aufholattacken, Telegraph-Verbesserungen.
2. Boss-Testmodus prüfen und ergänzen.
3. Native Boss-Mechaniktests (Reichweite, Muster, sichere Zonen).
4. Regression (811) und Level-Smoke erneut.
5. Simulationen.
