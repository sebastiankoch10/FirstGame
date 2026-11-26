---
tags: [handoff, status]
updated: 2026-11-26
agent: Claude
---
# Übergabe (wird nach jeder Aufgabe überschrieben, max. ~40 Zeilen)

**Zuletzt dran:** Claude, 2026-11-26: Vault-Prüfung in `docs/` (nur Doku, Code nur gelesen). **Nicht committet** (Auftrag: kein Commit). Davor Claude, 25.11. abends, Generalfreigabe siehe AGENTS.md „Regeln“ und [[DECISIONS]].

## Stand
- **Design-Kanon** `docs/Design/`, Vorrang im [[Leitbild]], Reihenfolge in [[Roadmap & Vertical Slice]].
- **Vault (26.11.):** 18 Systemnotizen auf Code-Stand, alle Notizen mit Frontmatter und im [[00_Index]] verlinkt; Details im Nachtrag von [[SETUP_REPORT]].
- **Zuletzt am Spiel (25.11.):**
  - **Pixelraster** (R2 Variante B): Welt in 960×540, Ausgabe ganzzahlig bzw. sharp-bilinear ([[Rendering & Pixelraster]]).
  - **Drache als Verbund aus Teilen** (`scripts/dragon_parts`): Kopf zielt auf den Spieler, Feuer exakt am Maul, Kopf und Hals sind Trefferformen.
  - **Behemoth und Zwillingshexen** in Spielgröße gebacken, 1:1 gezeichnet.
  - **Pixel-Effekte** für alle Boss-, Klassen- und Zaubereffekte; Schadenszahlen in Pixelschrift.
  - **Testmodus** im Hauptmenü mit „Freie Szene“ ([[Boss-Testmodus]]).
  - **Werkzeuge:** `tests/tools/record_scene.py`, `clean_test_artifacts.py`, `tests/tools/art/pixelize.py`.
- **Git:** `entwicklung` auf GitHub (`origin`), letzter Commit `6124c0d7`. Die Doku-Änderungen vom 26.11. liegen uncommittet im Arbeitsbaum.
- **Tests:** zuletzt QA Stufe 3 PASS (25.11.: anchors, static, regression 811, feature 162, boss 141, level 166, classes 151). Heute keine Tests, weil kein Code geändert wurde (NOT RUN).

## Offen (Reihenfolge)
1. **Nutzer:** Doku-Änderungen durchsehen und committen (z. B. `git add docs AGENTS.md`). `docs/.obsidian/` bewusst entscheiden ([[Bugs & Ideen]]).
2. **Spieltest durch den Nutzer** (F5): Testmodus → Bosskampf Drache; Freie Szene mit Zauber Stufe 9; Vollbild (1080p = exakt 2×).
3. **Drache Stufe 2:** Schweif als Gliederkette mit Hitbox an der Spitze, Flügel als eigene Teile, Draufsicht-Variante des Kopfes.
4. S2 Animation Controller, Trefferstopp; Skelett-Gegner in Pixeldichte 1:1 (neue Grafik); Minibosse (Codex-Auftrag beim Nutzer).

## Bekannte Bugs / Risiken
- Vektorlinien (Warnflächen) liegen im Weltraster: dünne Linien wirken gröber. Beim Spieltest prüfen.
- Rig der Spielfigur und der Hexen rendert weiter über eine Surface (Verformung resampelt leicht).
- Export-Generator schreibt kein Frontmatter; MCP-Zeitlimit und Legacy-Werkzeuge: siehe [[Bugs & Ideen]].

## Nächste Schritte
1. **Nutzer:** Commit der Doku, dann F5 und Rückmeldung zu Drache, Effekten und Schärfe.
2. **Danach:** Drache Stufe 2 (Schweif, Flügel).
