---
tags: [handoff, status]
updated: 2026-11-26
agent: Claude
---
# Übergabe (wird nach jeder Aufgabe überschrieben, max. ~40 Zeilen)

**Zuletzt dran:** Claude, 2026-11-26 mittags. Autonomer Auftrag „offene Aufgaben, QA-Optimierung, Obsidian-Integration“ abgeschlossen. **Commit lokal, nicht gepusht** (Auftrag: kein automatischer Push); für andere Geräte `git push origin entwicklung`.

## Stand
- **Review-Center:** 25 Szenarien offen, keine persönliche Freigabe bisher ([[Review-Center]]). In diesem Auftrag wurden bewusst keine neuen Review-Fälle angelegt; die betroffenen sichtbaren Änderungen stehen in [[Bugs & Ideen]].
- **Neu am 26.11. mittags:**
  - **Messungen:** Lastmessung (`run_native_harness.py perf`) und Level je Minute aus zwei Bot-Kohorten (`QA/tools/analyze_levels.py`); Kalibrierungsvorschlag für `boss_test_preset` in [[Boss-Testmodus]] (nicht umgesetzt).
  - **Spiel:** mehrphasige Steinstacheln, Sternenfall und Prismensamen; Bewegungsidentität der Wald-Skelette; `eqv_attach_draw` und Ankeranzeige mit F10; Lautstärken werden gespeichert; Pixelschrift mit Buchstaben („MAGNET“).
  - **Aufgeräumt:** verwaiste Kollisions-Events entfernt, alte Tests nach `tests/_legacy/`, Asset-Migration abgeschlossen (ArtPack-Zielstruktur), `docs/ai-activity.log` nur noch lokal.
  - **QA:** Suiten `docs` (immer), `review` (nur bei Review-Änderungen), `perf` (auf Anlass); Agenten `qa` und `visual-qa` für Claude und Codex synchron.
- **Regel:** Neue Anforderungen in die maßgebliche vorhandene Doku einarbeiten (AGENTS.md „Grundsätze“).
- **Tests (26.11.):** QA Stufe 3 PASS (docs, anchors, static, regression 811, feature 195, boss 141, level 166, classes 151, visual 84); perf gemessen; Review-E2E zuletzt PASS 12/12 (heute nicht erneut nötig, kein Review-Code geändert).

## Offen (Reihenfolge)
1. **Nutzer:** F5 → Review-Center prüfen und freigeben; über `boss_test_preset`-Vorschlag entscheiden.
2. **Performance:** Engpass ist die Gegnerzahl (148 Gegner ≈ 64–66 FPS unbegrenzt); `enemy_pursue` und `enemy_draw` profilieren ([[Bugs & Ideen]]).
3. **Grafik-Entscheidungen** ([[Roadmap & Vertical Slice]] Zeilen 11–13): neutrale Basisfigur; Drachenschweif und Flügel als Teile; danach Ankerpunkte für weitere Waffenmodelle nutzen.
4. `FirstGame_ArtPack/atmosphere_v2/` prüfen und gegebenenfalls nach `_legacy/` legen.

## Bekannte Bugs / Risiken
- Die Bossdruck-Werte (`bc_config`) sind Startwerte; nach dem Spieltest feinjustieren.
- `FirstGame_ArtPack/characters/class_overhaul/CHARACTER_ART.md` enthält ein fremdes „c“ in Zeile 1 (uncommittet, nicht angefasst).
- Beim Schreiben von Patches über die Shell werden doppelte Backslashes zu einfachen; in Skripten `chr(92)` verwenden.
