---
tags: [handoff, status]
updated: 2026-11-27
agent: Claude
---
# Übergabe (wird nach jeder Aufgabe überschrieben, max. ~40 Zeilen)

**Zuletzt dran:** Claude, 2026-11-27. Auftrag „Mach das alles“ mit Ergänzung (Reihenfolge 1 → Liste bremsender Regeln → 2 → 3 Drache → 4 → anhalten). **Block 1 fertig** (Roadmap 14, Drachen-Befunde, Leistung). Als Nächstes laut Auftrag: Boss-Codepfade auf bv2 zusammenführen, dann „Die Attacke ist die Warnung“ am Drachen.

## Stand
- **Roadmap 14 umgesetzt:** `scripts/fx_world` (Treffer, Tode, Münzen, Pickups, Level-up, pixelgenaues Pflanzenwiegen, Startwaffen), Sternenorb neu, Trefferaufblitzen auf der Spieluhr. Offen: neue Figurengrafik (BLOCKED, Quelle beim Nutzer).
- **Drache:** gezielte Fächer treffen die Zielposition; Sequenzen neu zusammengestellt ([[DECISIONS]] 27.11.).
- **Regeln neu:** Offenes melden statt abarbeiten; bei Widersprüchen und Strukturproblemen vor großem Aufwand erst fragen (AGENTS.md „Regeln“). Review-Center nur auf Wunsch des Nutzers.
- **Tests 27.11.:** Boss 190, Regression 811, Feature 219, Level 177 (neu: 960×540-Raster in allen Leveln), Klassen 151, Visual 77, docs, anchors: PASS. perf: Horde 16,9 ms, Drache 17,1–17,2, Hexen 16,7–16,8; Münz-Stresstest 18,2–18,4 ms (FAIL gegen 60 FPS, schon vor dem Overhaul knapp).

## Offen (nur zur Information, nicht ungefragt abarbeiten)
- Roadmap 15 (nach dem Drachen anhalten), Roadmap 16, Münz-Stresstest ([[Bugs & Ideen]]).
- Befunde der visual-qa vom 27.11. in [[Bugs & Ideen]] (Schadenszahlen, Arkanistin-Bogen, Wiegen bei schwachem Wind, Recorder 1280×720).
- Diktieren mit Win+H ungetestet.

## Bekannte Bugs / Risiken
- GML: Ein `//`-Kommentar in einer Einzeilen-Anweisung schluckt den Rest der Zeile (zweimal passiert); nach jeder Änderung `compile_check.py` vor der QA.
- `fx_*`-Funktionen nicht innerhalb von `with()` auf Controller-Variablen zugreifen lassen (Absturz `light_sprite` am 27.11., von der Level-Suite gefunden).
- `record_scene` nie parallel starten; Aufnahmen sind 1280×720 hochskaliert (Recorder-Fehler).
- Ohne Shader-Unterstützung entfällt die Nachbearbeitung (Meldung `FX_POST disabled`).
