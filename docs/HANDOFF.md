---
tags: [handoff, status]
updated: 2026-11-27
agent: Claude
---
# Übergabe (wird nach jeder Aufgabe überschrieben, max. ~40 Zeilen)

**Zuletzt dran:** Claude, 2026-11-27. **Arbeitsweise und Review-Center neu gefasst, Grafik-Overhaul abgeschlossen, Designentscheidung „Die Attacke ist die Warnung“ festgehalten.** Kein laufender Auftrag; was als Nächstes kommt, entscheidet der Nutzer.

## Neue Regeln (verbindlich seit 27.11.)
- **Offenes melden statt abarbeiten:** am Auftragsende auflisten, in Roadmap bzw. [[Bugs & Ideen]] eintragen, nicht ungefragt fortsetzen (AGENTS.md „Regeln“).
- **Review-Center nur auf Wunsch des Nutzers:**
  - Neue Einträge brauchen `requested`; sonst entscheidet der Agent nach dem Kanon (Status „nach Kanon entschieden“ in [[Qualitätsstandard]]).
  - Alle 43 früher offenen Einträge sind `withdrawn` (zurückgezogen, keine Freigabe) und im Archiv startbar.
  - `bump` ohne `--request` landet ebenfalls in `withdrawn` (AGENTS.md „Review-Workflow“, [[Review-Center]]).

## Stand
- **Grafik-Overhaul HD-2D:** Richtung vom Nutzer bestätigt (keine künstlerische Abnahme einzelner Inhalte), Ausrollen beendet ([[Visuelles Leitbild & Animation]] 7.4).
- **Herausgelöst als eigene Aufträge:** Gegner-, Miniboss- und Bossangriffe samt Gefahrenflächen (Roadmap 15), Zauber und Passiva (Roadmap 16).
- **Die Attacke ist die Warnung:** nur festgehalten (Leitbild G19, [[Kampf & Begegnungen]] 5.0, [[Boss-Design]] B2). Der Code zeigt weiter die Markerwarnungen.
- **Tests 27.11.:** QA Stufe 2 PASS (docs, anchors, Regression 811, Review 23). Archiv-Bildschirm angesehen: `[-]`-Einträge, Statustext, lange Titel gekürzt.

## Offen (nur zur Information, nicht ungefragt abarbeiten)
- **Roadmap 14 (Rest Overhaul):**
  - Startwaffen;
  - Gegnertreffer und -tode, Münzen, Pickups, Level-up, Vegetation;
  - Figuren-Effekte von Arkanistin und Waldläufer;
  - neue Figurengrafik nach [[Assets & Pipeline]] 7.8.
- **Roadmap 15 und 16:** Aufträge des Nutzers.
- **[[Bugs & Ideen]]:**
  - Münz-Belastungstest 1,2 ms langsamer;
  - visual-qa-Restpunkte;
  - Diktieren mit Win+H ungetestet;
  - Drachen-Sequenzen;
  - Prüffrage Leere/Wind.

## Bekannte Bugs / Risiken
- Ohne Shader-Unterstützung entfällt die Nachbearbeitung (Meldung `FX_POST disabled`), das Spiel läuft weiter.
- `record_scene` nie parallel starten (gemeinsamer Speicherordner für Einzelbilder).
- Das Hauptmenü ruckelt in den ersten etwa 3 s.
- GML: reservierte Namen siehe AGENTS.md (`all`, `real`); Array-Literale nicht direkt indizieren.
