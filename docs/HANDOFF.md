---
tags: [handoff, status]
updated: 2026-11-26
agent: Claude
---
# Übergabe (wird nach jeder Aufgabe überschrieben, max. ~40 Zeilen)

**Zuletzt dran:** Claude, 2026-11-26. Aufträge Phase 1, 2A und 2B des Nutzers umgesetzt, soweit ohne neue Grafik möglich. Regeln: AGENTS.md „Review-Workflow“.

## Stand
- **Review-Center:** [[Review-Center]]. 25 Szenarien offen in `review/registry.json`, keine persönliche Freigabe bisher. **Start jeder Sitzung:** `python tests/tools/review/review.py sync` (Claude per Hook).
- **Phase 1:**
  - Review-Center, Freigabe, End-to-End-Test.
  - Inventar (Drag-and-drop, Rechtsklick, Tooltips, Shift-Vergleich).
  - Waffen-Ankerpunkte (`eqv_attach`, vorbereitet).
  - Sprungreaktion von Haar und Umhang.
- **Phase 2A:**
  - Gemeinsamer Gefahren-Renderer [[Telegraphs & Gefahrenflächen]] mit WYSIWYG, Füll-Countdown, Fokus-Umriss, Priorität nach Zeit und zusammenhängenden Flächen.
  - Feuerstrom, Aufladung und Ausholbewegung des Drachen.
  - `light_flash` mit Option „Lichtblitze“; Spieler-Zielmarken.
- **Phase 2B:**
  - Spielfeldweites Schachbrett, Druck nach Entfernung, kontrahierende Feuerringe, Eisflut-Regel.
  - Neutrale Grundpfeile; mehrphasiges Siegel mit Stufen 1/5/9.
- **Tests (26.11.):** QA Stufe 3 PASS (811/195/141/166/151/81), Review-E2E PASS 12/12.

## Offen (Reihenfolge)
1. **Nutzer:** F5 → Review-Center, Szenarien prüfen, gefallene mit dem grünen Haken freigeben.
2. **Grafik-Entscheidungen** ([[Roadmap & Vertical Slice]] Zeilen 11–13):
   - neutrale schlanke Basisfigur (3 Klassen × 256 Posen);
   - Drachenschweif als Kette und Flügel als Teile (neue Quellsegmente);
   - danach die Ankerpunkte nutzen.
3. **Level-Suite** läuft seit 26.11. mit fester Bildzeit; feature und classes bei Auffälligkeiten ebenso umstellen ([[Bugs & Ideen]]).
4. **Spielerlevel je Minute** per Bot-Kohorte messen (Testmodus-Presets sind Entwicklungswerte).

## Bekannte Bugs / Risiken
- Die Bossdruck-Werte (`bc_config`) sind Startwerte; nach dem Spieltest feinjustieren.
- Die GameMaker-IDE war offen; sie sortiert `FirstGame.yyp` beim Speichern um (inhaltlich gleich).
- `FirstGame_ArtPack/class_overhaul/CHARACTER_ART.md` enthält ein fremdes „c“ in Zeile 1; nicht angefasst.
