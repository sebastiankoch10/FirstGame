---
tags: [decisions, architektur, design]
updated: 2026-11-25
---
# Entscheidungen (kurz: Datum · Entscheidung · Grund)

## Arbeitsweise und Werkzeuge
- **2026-11-24 · `AGENTS.md` ist die einzige Hauptquelle, `CLAUDE.md` importiert sie.** Grund: Claude und Codex sollen dieselben Regeln lesen, damit nichts auseinanderläuft.
- **2026-11-24 · `docs/` ist der Obsidian-Vault, nicht das ganze Repo.** Grund: übersichtlich, keine Code- oder Assetflut im Vault. Die älteren Berichte bleiben an ihrem Ort und werden verlinkt.
- **2026-11-24 · Übergabe nur am Aufgabenende** über HANDOFF, LOG und DECISIONS. Grund: spart Tokens.
- **2026-11-24 · Hooks kosten keine Tokens.** SessionStart zeigt nur HANDOFF an, Stop schreibt nur eine Logzeile (kein KI-Aufruf).
- ~~**2026-11-24 · Git nur lokal (`entwicklung`), nie pushen.**~~ Ersetzt am 25.11.: Pushen von `entwicklung` nach `origin` ist erlaubt (Nutzer: Die Regel stammte nur aus der Sorge um Tokens). Kein Force-Push, `main` unverändert.
- **2026-11-24 · Token-Regeln:** Lesereihenfolge HANDOFF → eine Systemnotiz → gezielter Code. Jede Info an genau einer Stelle. Am Aufgabenende ein Commit mit `[Claude]` oder `[Codex]`. Grund: Beide Agenten bleiben synchron, ohne jedes Mal Doku oder Code komplett zu lesen. `git log` ist die billigste Synchronquelle.
- **2026-11-24 · `DEVELOPMENT_PROGRESS.md`, `TODO.md` und `QA/CURRENT_STATUS.md` werden nicht mehr laufend gepflegt.** Grund: Sie würden HANDOFF und Bugs & Ideen doppeln.
- **2026-11-24 · Test-Builds unter `%LOCALAPPDATA%\FirstGame-Tests\`, nie im Projektordner.** Grund: Der Nutzer will keine EXE oder ZIP im Projekt; er testet mit F5.

- **2026-11-25 · Design-Kanon in `docs/Design/` mit Vorrangregeln** (Leitbild > Fachdokumente > DECISIONS > Systemnotizen > Stand > Ideen > historisch). Grund: eine eindeutige Quelle für das Soll, im Obsidian-Vault sichtbar. Globale Regeln stehen im Leitbild, Klassendokumente enthalten nur Besonderheiten.
- **2026-11-25 · Neue Designentscheidungen aus Aufträgen werden im selben Auftrag in den Kanon übernommen.** Grund: Entscheidungen dürfen nicht nur im Chat stehen.
- **2026-11-25 · IDE-Ordner nach Kategorien, physische Quellordner bleiben vorerst.** Grund: Der IDE-Baum ist nur eine Ansicht (sicher). Das Verschieben von `FirstGame_ArtPack/` bräche über 30 Werkzeugpfade; erst eine Pfadtabelle, dann verschieben ([[Assets & Pipeline]]).
- **2026-11-25 · Export des Kanons wird erzeugt, nicht gepflegt** (`tests/tools/export_design.py`). Grund: keine zweite Wahrheitsquelle.
- **2026-11-25 · Telemetrie-Anker werden in jeder QA-Stufe geprüft (Suite `anchors`).** Grund: Zwei Anker waren nach Codeänderungen unbemerkt kaputt; die Simulationen wären erst spät gescheitert. Die Prüfung dauert Sekunden.
- **2026-11-25 · Attack Timeline: Uhr und Einheit bleiben die des Besitzers** (Spielerwaffen in Spielschritten, Bosse in Sekunden auf `v2_clock`). Grund: Migration ohne jede Verhaltensänderung; Auslösung nach Zeit folgt, wenn alle Angriffe auf der Zeitachse laufen.
- **2026-11-25 · Generalfreigabe und Qualitätsanspruch:** Der Nutzer will alles auf den höchsten fachlichen Standard, auch frühe Festlegungen aus der Zeit vor der KI-Nutzung. Umsetzungsentscheidungen trifft der Agent selbst und begründet sie hier; vorher gefragt werden nur kostenpflichtige Dienste, Balancing-Zahlen und die künstlerische Abnahme.
- **2026-11-25 · Szenen-Aufnahme statt Einzelbilder** (`tests/tools/record_scene.py`, feste 60-Hz-Bildzeit) und automatisches Aufräumen der Testartefakte (`clean_test_artifacts.py`, nach `qa.py` und Aufnahmen). Grund: Bewegung und Timing lassen sich nur in Folgen beurteilen; der Nutzer will keinen wachsenden Speicherverbrauch.

## Spieldesign
- **2026-11-25 · Helm = Kopf und Helm als ein Bild** (Auftrag des Nutzers): Das Kopfteil ersetzt die oberen Zeilen des Basismodells, statt darüber zu liegen. Grund: Haare standen um die Helmkuppel heraus. Haare unterhalb des Helmrands bleiben sichtbar.
- **2026-11-25 · Gegner-Pixeldichte 1:1 nur, wo echte Details entstehen.** Prozedurale Kreaturen werden in Zielgröße gerendert; gezeichnete Skelett-Gegner werden nicht neu abgetastet (A/B: kein Detailgewinn, eher weicher). Sie bleiben gestreckt, bis neue Grafik kommt.
- **2026-11-25 (2) · Nutzerentscheidungen:**
  - Pixeldichte 1 Artpixel = 1 Welteinheit umsetzen.
  - Drache bekommt Schweifschlag und Biss als **zusätzliche** Nahangriffe; die neun Fähigkeiten bleiben, der Schaden entspricht einer vorhandenen Drachenfähigkeit.
  - Minibosse zeichnet Codex neu; Claude liefert Vorgaben und Import.
  - Waffen-Upgrades als eigene Karten in der Level-up-Auswahl.
  - Elitegegner ab Minute 3, selten.
  - Langsamere Meta-Progression: Nur Hauptboss-Punkte sind dauerhaft, Stufenpunkte gelten nur im laufenden Run.
- **2026-11-25 · Nutzerentscheidungen:** Kamera nach Vorschlag (960×540); Werkzeuge immer kostenlos (eigenes Rig statt Spine); Klassen heißen Schwertmeister, Arkanistin, Waldläufer; Run-Format **und** Fortschritt zwischen Runs; Legacy-Sprites und `output/` gelöscht; keine Internetsperre.
- **2026-11-25 · Dauerhafte Talente nur im echten Spiel** (Projektname „FirstGame“). Grund: Native Suiten und Bot-Simulationen müssen reproduzierbar bleiben.
- **2026-11-25 · Drachen-Rig als 2D-Skinning des Original-Frames statt zerlegter Teile.** Grund: keine Nähte, kein neues Artwork, Originale bleiben unverändert. In Feuerposen keine Kopfbewegung, damit Maul-Anker und Strahl synchron bleiben.
- **2026-11-25 · Zauber-Bänder verändern nur die Intensität** (Deckkraft, Glühen, Licht, Partikelzahl), nie Radius oder Schaden. Grund: G12, keine Balancing-Änderung.
- **2026-11-25 · Pixeldichte-Empfehlung 1 Artpixel = 1 Welteinheit** nach A/B-Vergleich. Umsetzung ist ein eigener Auftrag (Pipeline-Umbau).
- **2026-11-25 · Hybride Animationsarchitektur:** gezeichnete Posen plus Übergangsposen plus Federebenen für Spieler; Frame-Animation plus prozedurale Lebendigkeit für Gegner; Cutout-Rig in GML für Hauptbosse; VFX aus Bausteinen auf dem Pixelraster. Grund: Qualität ohne Papierpuppe, machbar in GM 2024, keine kostenpflichtigen Werkzeuge. Details: [[Technische Architektur]].
- **2026-11-25 · Präsenz von Fähigkeiten durch Klarheit, Timing und Ton statt Fläche; drei visuelle Bänder (Stufe 1–3/4–6/7–9).** Ersetzt „größer und präsenter“ (22.11.). Werte und Radien bleiben unverändert. [[Fähigkeiten, VFX & Audio]].
- **2026-11-25 · Terranigma-Trailer als Bewegungsreferenz** (nur Bewegung, keine Assets oder Stil). Analysiert über öffentliche Storyboard-Vorschaubilder (1 Bild/s); kein Video-Download. [[Visuelles Leitbild & Animation]].
- **2026-11-25 · Vorschlag (Nutzerentscheidung offen): Kamera 960×540 (16:9) und 1 Artpixel = 1 Welteinheit.** Grund: Die Verzerrung beheben, ganzzahlige Skalierung bei 1080p, Fläche ähnlich wie heute. Entscheidung nach A/B-Prototyp.
- **2026-11-23 · Bossphilosophie** in `docs/Design/Boss-Design.md`, höchste Priorität für Bosse. Positionierung statt mehr HP oder Schaden. Keine Zahlenänderungen am Balancing ohne Auftrag.
- **2026-11-24 · Talente gelten pro Run**, persistent ist umschaltbar über `talent_config().persistent`. Punkte ab Stufe 4 alle 4 Stufen und je Hauptboss. Grund: Es gab keine Vorgabe; die Architektur bleibt konfigurierbar. Siehe [[Talente]].
- **2026-11-24 · Ausrüstung:** Start ohne, 6 Slots, 4 Seltenheiten. Bosse droppen garantiert, Gegner zu 0,3 %. Klar bessere Funde werden automatisch angelegt. Siehe [[Ausrüstung]].
- **2026-11-24 · Bossmuster sind normale bv2-Gefahren auf einer Uhr je Boss.** Grund: Warnung und Treffer können nicht auseinanderlaufen. Siehe [[Bosse]].
- **2026-11-24 · Schwenkstrahlen treffen pro Überstreichen nur einmal.** Grund: Die Simulationen zeigten Mehrfachtreffer.
- **2026-11-24 · Komplexe Varianten der Fähigkeiten 1–3 erst bei Bossen ab Minute 10.** Grund: Der erste Boss in Minute 5 soll zugänglich bleiben (laut `docs/Design/Boss-Design.md` Abschnitt H: „später komplexere Varianten“).
- **2026-11-24 · Aufholattacken ersetzen den Teleport.** Der Teleport bleibt nur als Notfall (über 850 px außerhalb des Bildes, nach 6 s).
- **2026-11-24 · Charaktere aus Basismodell plus sichtbaren Ausrüstungsebenen.** Basis = Grundkleidung ohne Waffe. Die Startwaffe ist eine eigene Ebene, solange keine Waffe angelegt ist. Siehe [[Charaktergrafik & Ausrüstungs-Layer]].
- **2026-11-24 · Umhänge bleiben im Basismodell.** Grund: Das Ausrüstungssystem hat keinen Umhang-Slot (Waffe, Kopf, Brust, Hände, Füße, Talisman). Der rote bzw. grüne Umhang ist Klassenidentität. Ein Umhang-Slot wäre eine Design- und Balancing-Änderung.
- **2026-11-24 · Aussehen eines Gegenstands = Stufe aus der Gegenstandsstufe (wie der Name), Seltenheit = Akzentfarbe.** Grund: Die Namen hängen schon an der Stufe; keine neuen Item-Daten, keine Wertänderung.
- **2026-11-24 · Ausrüstungsgrafik prozedural aus den Originalfiguren abgeleitet.** Grund: Claude hat keinen Bildgenerator. So sitzen alle Teile in jedem der rund 1.240 Frames pixelgenau. Für handgezeichnete Varianten kann Codex (mit Bildgenerator) die Pipeline weiterverwenden.
- **2026-11-24 · Gepackte Atlanten plus Rechtecktabelle statt Einzelframes.** Grund: rund 23.000 Ausrüstungsframes als Einzel-PNGs würden Build, IDE und Testkopien stark verlangsamen.
