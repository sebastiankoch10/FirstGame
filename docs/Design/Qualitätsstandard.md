---
tags: [design, verbindlich, qualitaet, abnahme, qa]
updated: 2026-11-25
status: verbindlich (Abnahme aller neuen und überarbeiteten Inhalte)
---
# Qualitätsstandard und Abnahme

Rang 2 unter [[Leitbild]]. Gilt für Entwickler-Agenten (Claude, Codex) und die QA-Prüfer (`.claude/agents/qa.md`, `.codex/agents/qa.toml`). Testwerkzeuge: [[Tests & QA]].

## 1. Statusskala (Pflicht in jedem Bericht)

| Status | Bedeutung | Wer darf ihn setzen |
|---|---|---|
| **nicht begonnen** | — | — |
| **technisch implementiert** | Code und Ressourcen existieren, der Build läuft | Entwickler-Agent |
| **funktional geprüft** | Native Tests bestehen (PASS), Gameplay-Werte stimmen (Treffer, Schaden, Timing) | Entwickler- oder QA-Agent mit Testnachweis |
| **visuell geprüft** | Laufzeitaufnahmen bzw. Kontaktbögen angesehen, die messbaren Kriterien unten erfüllt | Agent mit Bildnachweis |
| **künstlerisch abgenommen** | Der Nutzer hat Aussehen, Bewegung und Ton im Spiel (F5) beurteilt und freigegeben | **nur der Nutzer** |
| **vollständig** | alle Punkte der Checkliste, inklusive künstlerischer Abnahme und Doku | **nur der Nutzer** |

- Testergebnisse immer als **PASS / FAIL / BLOCKED / NOT RUN**.
- Ein Build ist kein Gameplay-Test, ein Sprite ist keine Animation, Schaden ist keine Inszenierung.
- **Nicht als fertig gelten:** Platzhalter, eingefärbte Kopien, Strichfiguren, nur skalierte oder gedrehte Standbilder statt nötiger Einzelbilder, unscharf hochskalierte Sprites (Auftrag 24.11.).

## 2. Gemeinsame Kriterien (alle Inhalte)

| Nr. | Kriterium | Messbar über |
|---|---|---|
| Q1 | **Pixelraster:** Pixeldichte nach Standard ([[Visuelles Leitbild & Animation]] 4.2). Keine Streckung im Code außer ganzzahlig; quadratische Pixel. | Skalierungsfaktoren im Code bzw. in der Pipeline; Pixellauf-Analyse einer Aufnahme (Verhältnis x/y = 1,00 ± 0,05) |
| Q2 | **Konsistenz der Figur:** Kopf- und Fußhöhe je Richtung und Zustand ±1 Artpixel; gleiche Palette (Farbanteile je Material ±10 %) | Kontaktbogen 8 Richtungen × Zustände; Bounding-Box-Auswertung |
| Q3 | **Stabiler Ursprung:** Fußpunkt springt nicht (≤ 1 Artpixel zwischen Frames, außer gewollt) | Ursprung bzw. Bodenlinie je Frame auswerten |
| Q4 | **Saubere Kanten:** keine halbtransparenten Säume, keine Farbränder, keine Weichzeichnung | Alpha-Histogramm (nur 0 bzw. 255 an Sprite-Kanten, außer Effekten) |
| Q5 | **Synchronität (G1):** Warnung, Hitbox, Schaden, Effekt und Ton auf einer Uhr; Schaden erst ab 100 %, sofort aktiv | native Tests (Muster in `tests/boss_harness.gml`, `class_dragon_harness.gml`) |
| Q6 | **Hitbox = Sichtbares:** sichtbare Schadensfläche und Hitbox weichen ≤ 10 % ab (Radius bzw. Länge) | Debug-Overlay (F10 im Boss-Test) plus Aufnahme |
| Q7 | **Lesbarkeit:** Hierarchie aus [[Kampf & Begegnungen]] 8; Gegnergefahren über eigenen Effekten; eigene Bodeneffekte mit Deckkraft ≤ 0,35 | Aufnahme mit Horde, Bossgefahr und Endgame-Build |
| Q8 | **Leistung:** innerhalb der Budgets ([[Technische Architektur]] 6); Partikel, Lichter und Stimmen gezählt | Messung im Harness (Bildzeit, Zähler) |
| Q9 | **Ton:** Cue je Phase nach Phasentabelle; Drosselung bei hoher Frequenz; keine Lautstärkespitzen | Harness zählt Stimmen; Hörabnahme durch den Nutzer |
| Q10 | **Dokumentation:** Designdokument bzw. Systemnotiz aktualisiert, Entscheidung in `DECISIONS.md` | Diff |
| Q11 | **Regression:** passende Suiten über `tests/tools/qa.py` PASS | `tests/reports/qa-last.json` |

## 3. Zusätzliche Kriterien je Inhaltstyp

**Spielerfigur bzw. neue Klasse**
- 8 Richtungen, alle Zustände aus [[Klassen]] 2.
- Lauf mindestens 8 Frames je Richtung.
- Jeder Angriff hat mindestens 1 Vorbereitungs-, 1 Kontakt- und 2 Nachschwung-Frames, **ohne zusätzlichen Eingabeverzug**.
- Sekundärbewegung von Haar und Umhang sichtbar bei Richtungswechsel, Sprung und Landung (Kontaktbogen der Sequenz).
- Ausrüstungsebenen in allen Zuständen deckungsgleich (Suite `visual`).
- Steuerung:
  - Laufen beginnt im selben Frame wie die Eingabe;
  - Ausweichen und Sprung werden nicht durch Animationen blockiert.

**Normaler Gegner**
- Bewegung passt zur Anatomie (Beschreibung im Designdokument plus Aufnahme).
- Lauf mindestens 6 Frames je Richtung (bzw. begründet weniger bei kleinen Kreaturen).
- Trefferreaktion und Tod vorhanden.
- Eigener Angriff wird über den Körper angekündigt.
- Statuseffekte bleiben in der Silhouette.

**Hauptboss bzw. Bossangriff**
- Neun Fähigkeiten, lernbare Rotation, Fairness-Test (Erreichbarkeit nach [[Kampf & Begegnungen]] 6), Max-Range- und Kiting-Test ([[Boss-Design]] I).
- Angriff im Körper sichtbar; Hitbox folgt dem Körperteil.
- Lebendig zwischen den Angriffen.
- Hurtbox und Hitbox im Debug-Overlay prüfbar.

**Fähigkeit bzw. Zauber**
- Pflichtphasen nach [[Fähigkeiten, VFX & Audio]] 1.
- VFX-Profil je Band (Basis, Mittel, Endgame) mit erkennbarem Unterschied **ohne Wertänderung**.
- Sofort als diese Fähigkeit erkennbar (Form, Farbe, Ton).
- Aufnahme aller drei Bänder nebeneinander.

**Effekt-Baustein**
- Auf dem Raster (Sprite- oder Feinraster).
- Element-Sprache eingehalten.
- Kein Strecken auf beliebige Größen.

**Icon bzw. UI**
- Lesbar bei Zielgröße.
- Gleicher Rahmen- und Lichtstil wie das vorhandene Set.
- UI-Texte auf Deutsch ohne Umlaute (ae/oe/ue).

## 4. Review- und Abnahmeprozess

1. **Entwickler-Agent:**
   - liest [[Leitbild]], das passende Designdokument und diesen Standard;
   - setzt um;
   - erzeugt die nötigen Aufnahmen (Kontaktbögen bzw. Laufzeitbilder) und sieht sie selbst an;
   - führt `python tests/tools/qa.py --plan` und dann `python tests/tools/qa.py` aus;
   - berichtet je Inhalt den **Status** (Abschnitt 1) und die erfüllten bzw. offenen Kriterien.
2. **QA-Agent** (nur lesend; bei Inhalts- und Grafikänderungen Pflicht ab Stufe 2):
   - prüft die Kriterien Q1–Q11 und die typspezifischen Punkte gegen die Nachweise;
   - meldet Befunde mit Datei, Zeile bzw. Bild und Reproduktion.
   - Er setzt höchstens „visuell geprüft“.
3. **Nutzer:** spielt mit F5 und gibt „künstlerisch abgenommen“ bzw. „vollständig“ frei oder schickt Korrekturen.
   - Korrekturen fließen als Entscheidung in das Designdokument ein.
4. **Abweichungen vom Standard** sind erlaubt, wenn sie begründet und im Designdokument als Ausnahme vermerkt sind.

## 5. Werkzeuge für messbare Prüfungen

| Werkzeug | Stand |
|---|---|
| Kontaktbögen der Figuren (8 Richtungen × 11 Zustände × 5 Sets) und Weltaufnahme | Ist: Suite `visual` |
| Warnflächen-Rendering bei 0/25/50/75/100 %, Synchronität bei 30/60/144 Hz | Ist: Suiten `classes`, `boss` |
| Max-Range-, Kiting- und Erreichbarkeits-Orakel | Ist: Suite `boss` |
| **Vorschlag (Roadmap):** `tests/tools/assets/art_lint.py` | prüft Pixeldichte, Kantenalpha, Ursprungsstabilität und Proportionen je Richtung direkt an den Sprite-Ressourcen |
| **Vorschlag:** Aufnahme der App-Surface im Harness | Pixellauf-Analyse Q1 (Verfahren vom 25.11., siehe [[Visuelles Leitbild & Animation]] 4.1) |
