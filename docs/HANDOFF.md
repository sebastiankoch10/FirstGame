---
tags: [handoff, status]
updated: 2026-11-25
agent: Claude
---
# Übergabe (wird nach jeder Aufgabe überschrieben, max. ~40 Zeilen)

**Zuletzt dran:** Claude, 2026-11-25 abends. Nutzer hat Generalfreigabe gegeben (höchster Standard, Push erlaubt), siehe AGENTS.md „Regeln“ und [[DECISIONS]].

## Stand
- **Design-Kanon** `docs/Design/`, Vorrang im [[Leitbild]], Reihenfolge in [[Roadmap & Vertical Slice]].
- **Heute abend umgesetzt:**
  - **Pixelraster** (R2 Variante B): Welt in 960×540, Ausgabe ganzzahlig bzw. sharp-bilinear (`scripts/render_pipeline`, `ObjectRender`). Siehe [[Rendering & Pixelraster]].
  - **Drache als Verbund aus Teilen** (`scripts/dragon_parts`): Kopf zielt auf den Spieler, Hals streckt sich, Feuer exakt am Maul, Kopf und Hals sind Trefferformen. Teile in Spielgröße gebacken (`tests/tools/bosses/build_dragon_parts.py`).
  - **Behemoth** in Spielgröße gebacken (`build_boss_baked.py`).
  - **Pixel-Effekte:** Feueratem, Feuerkegel, Schwerthiebe, alle Klasseneffekte; Schadenszahlen in Pixelschrift.
  - **Testmodus** im Hauptmenü mit „Freie Szene“ ([[Boss-Testmodus]]).
  - **Werkzeuge:** Szenen-Aufnahme `tests/tools/record_scene.py`, Aufräumen `clean_test_artifacts.py`, Pixel-Helfer `tests/tools/art/pixelize.py`.
- **Git:** `entwicklung` liegt seit heute auf GitHub (`origin`); nach jedem Commit pushen.
- **Tests:** Render-Umbau QA Stufe 3 PASS (`77f68e40`). Stand danach: siehe letzter Commit.

## Offen (Reihenfolge)
1. **Spieltest durch den Nutzer** (F5): Testmodus → Bosskampf Drache; Freie Szene mit Zauber Stufe 9; Vollbild (1080p = exakt 2×).
2. **Zwillingshexen** werden noch 1,5-fach skaliert; Neubacken aus den Quellen braucht die Frame-Ausrichtung ([[Bugs & Ideen]]).
3. **Restliche gemalte Effekte** der Bosse (Meteor, Wirbel, Bodeneinschlag, Flügelsturm, Hexen- und Sumpf-Effekte) als Pixel-Komposite.
4. **Drache Stufe 2:** Schweif als Gliederkette mit Hitbox an der Spitze, Flügel als eigene Teile, Draufsicht-Variante des Kopfes.
5. S2 Animation Controller, Trefferstopp; Skelett-Gegner in Pixeldichte 1:1 (neue Grafik); Minibosse (Codex-Auftrag beim Nutzer).

## Bekannte Bugs / Risiken
- Vektorlinien (Warnflächen) liegen jetzt im Weltraster: dünne Linien wirken gröber. Beim Spieltest prüfen.
- Rig der Spielfigur und der Hexen rendert weiter über eine Surface (Verformung resampelt leicht).
- MCP-Zeitlimit und Legacy-Werkzeuge: siehe [[Bugs & Ideen]].

## Nächste Schritte
1. **Nutzer:** F5, Testmodus ausprobieren, Rückmeldung zu Drache, Effekten und Schärfe.
2. **Danach:** Punkt 2 und 3, dann Drache Stufe 2.
