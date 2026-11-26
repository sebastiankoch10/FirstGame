---
tags: [handoff, status]
updated: 2026-11-26
agent: Claude
---
# Übergabe (wird nach jeder Aufgabe überschrieben, max. ~40 Zeilen)

**Zuletzt dran:** Claude, 2026-11-26 abends. Folgeauftrag „offene Punkte nach Phase 1/2A/2B und QA-Auftrag“ abgeschlossen, committet und nach `origin/entwicklung` gepusht (Nutzerfreigabe).

## Stand
- **Review-Center:** 36 Szenarien offen (11 neu: mehrphasige Zauber, Wald-Skelette, MAGNET, Ankerpunkte, Trefferstopp, Drachen-Sequenzen P1/P3, Hexen- und Behemoth-Bewegung). Keine persönliche Freigabe bisher ([[Review-Center]]).
- **Neu am 26.11. abends:**
  - **Drachen-Sequenzen** ([[Boss-Design]] H2): 11 Sequenzen in 4 Phasen, nach je 2 regulären Angriffen, mit fairer Pause und Ruhe. Daten in `bc_sequences`.
  - **Trefferstopp** als Bild (2 Bilder, physische Grundwaffe); Bewegungsidentität von Hexen und Behemoth beim Aufladen und Einschlag.
  - **Nutzerentscheidungen:** Texturen im Menü verteilt laden (Run-Start 0 statt 5,1 s, Menü ruckelt anfangs), Effekt-Zufall getrennt (`vfx_random`), `boss_test_preset` kalibriert, `.obsidian` versioniert (ohne workspace), „c“ in `CHARACTER_ART.md` entfernt.
  - **Performance:** Skelett-Sprite gecacht. Horde unbegrenzt 72–75 FPS, Bosse mit 60 Gegnern 96–102.
  - **Teil B:** Anforderungen für neue Grafik in [[Assets & Pipeline]] 7. Vorbereitet sind Skelett-Rollen-Sets (automatisch, 1:1) und die Basisfigur (Ordner, `atlas.base_neutral_path`, `check_base_neutral.py`).
  - **Werkzeuge:** `record_scene.py spellsheet`, Boss-Suite-Lauf `sequences`, Feature-Suite mit fester Bildzeit.
- **Tests (26.11. abends):**
  - QA Stufe 3 PASS: docs, anchors, static, Regression 811, Feature 195, Boss 190, Level 168, Klassen 151, Visual 86, Review-E2E 12.
  - perf PASS, keine Ausreißer.

## Offen (Reihenfolge)
1. **Nutzer:**
   - F5 → Review-Center: 36 Szenarien prüfen und freigeben, besonders die Drachen-Sequenzen und den Trefferstopp.
   - Grafikquelle entscheiden (Roadmap 9, 11, 12).
2. **Animation Controller S2:** nicht umgesetzt (großer Umbau von Spieler, Skeletten und Drachen); nächster eigener Schritt nach [[Technische Architektur]] 4.2.
3. **Sequenzen** für Hexen und Behemoth nach dem Spieltest des Drachen-Piloten (gleiche Datenstruktur).
4. **Grundstufen:** Mehrere Zauber auf Stufe 1 sind kaum sichtbar (Blitz, Lanze, Siegel, Sternenfall, Brunnen, Gefängnis, Urteil); künstlerisches Urteil des Nutzers ([[Zauber & Passiva]]).

## Bekannte Bugs / Risiken
- Bossdruck-Werte (`bc_config`) und Sequenz-Takt (`seq_every`, `seq_gap`, `seq_rest`) sind Startwerte; nach dem Spieltest feinjustieren.
- Im Hauptmenü ruckelt das Bild in den ersten etwa 3 s (Textur-Entpacken, längstes Bild etwa 0,55 s).
- Visuell nicht belegt: Öffnungen der kontrahierenden Ringe (Aufnahme verfehlt); geprüft nur über Geometrie und Orakel.
- GML: `all` ist ein Schlüsselwort (keine Variable so nennen); Array-Literale nicht direkt indizieren.
