---
tags: [handoff, status]
updated: 2026-11-24
agent: Claude
---
# Übergabe (wird nach jeder Aufgabe überschrieben, max. ~40 Zeilen)

**Zuletzt dran:** Claude, 2026-11-24. Aufgabe: QA-Agent modernisieren + Charaktermodelle mit sichtbarer Ausrüstung.

## Stand
- Spielbar per F5. Jede Klasse = Basismodell (Grundkleidung, ohne Rüstung/Waffe) + sichtbare Ausrüstung in 4 Stufen je Slot (Kopf, Brust, Hände, Füße, Waffe). Startwaffe als eigene Ebene. Details: [[Charaktergrafik & Ausrüstungs-Layer]].
- QA: `python tests/tools/qa.py --plan` wählt Stufe 1–4 und Suiten aus dem Diff, PASS-Cache. QA-Prüfer `.codex/agents/qa.toml` = `.claude/agents/qa.md`. Siehe [[Tests & QA]].
- Tests auf `9c3f3937`: regression 811, feature 129, boss 141, level 166, classes 150, visual 75 – alle PASS.

## Zuletzt gearbeitet an
- Pipeline `tests/tools/characters/` (Atlas-Port, Zerlegung, Malen, Build). Neu bauen: `python tests/tools/characters/build_characters.py --previews` (~10 min, 18 Prozesse).
- Laufzeit `scripts/equipment_visual` (`player_layers_draw`), Daten `scripts/equipment_visual_data` (generiert), Item-Icons `spr_eqv_icons_<actor>`.
- Zeichenstellen umgestellt: `ObjectPlayer/Draw_0`, Menüporträt `ObjectMainMenu/Draw_64`, Inventar/HUD/Bodenfunde (`equipment_item_icon`).

## Halb fertig / offen
- Grafik ist prozedural abgeleitet (nicht handgezeichnet). Künstlerische Feinabnahme durch den Nutzer fehlt.
- Waffe nicht in jedem Frame getrennt: Schwert 223/256, Stab 212/256, Bogen 230/256 Zellen (`tests/reports/character-layers.json`). Dort zeigt der Frame mit Item-Waffe die Originalwaffe.
- Talisman nicht sichtbar (bewusst). Umhänge bleiben Basis (kein Slot) – Entscheidung in [[DECISIONS]].

## Bekannte Bugs / Risiken
- Vereinzelte Fehlpixel der Zerlegung (z. B. Bogen-Fehltreffer an Umhangspitzen, Stabkopf-Reste) – nur bei angelegter Item-Waffe sichtbar.
- Spielerskalierung 1,65 (nicht ganzzahlig) verzerrt Pixel leicht – bestand vorher schon.
- Drache ab Minute 10 sehr schwer für Bots (siehe [[Bosse]]); `run_combat_smoke.py` veraltet.

## Nächste Schritte
1. Nutzer: F5, Klasse wählen, Ausrüstung sammeln (Boss-Test F9 gibt Testgegenstände) und Aussehen beurteilen.
2. Bei Bedarf Grafik verfeinern: Parameter in `render.py`, dann Build + `qa.py` (Suite visual).
3. Optional: Codex mit Bildgenerator für handgezeichnete Varianten einzelner Teile (Pipeline übernimmt Platzierung).
