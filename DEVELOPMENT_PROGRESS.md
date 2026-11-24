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

## 3. Tests (ehrlich gekennzeichnet)

| Test | Ergebnis |
|---|---|
| Kompilierung echtes Projekt (Igor, VM) | PASS |
| `python tests/tools/run_native_harness.py feature` – Talente/Ausrüstung/VFX/Charakterbildschirm für alle 3 Klassen, nativ | **PASS 129/129** (24.11. 07:03) |
| Menschlicher Spieltest | NOT RUN |

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
