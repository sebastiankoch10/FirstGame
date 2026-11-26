---
tags: [handoff, status]
updated: 2026-11-26
agent: Claude
---
# Übergabe (wird nach jeder Aufgabe überschrieben, max. ~40 Zeilen)

**Zuletzt dran:** Claude, 2026-11-26 spätabends. Qualitätsaudit abgeschlossen. **Commit lokal, nicht gepusht** (im Auftrag war der Push nicht angekreuzt); für andere Geräte `git push origin entwicklung`.

## Stand
- **Review-Center:** 36 Szenarien offen, keine persönliche Freigabe bisher ([[Review-Center]]).
- **Audit 26.11. (behoben, mit Messung bzw. Test):**
  - **Münzen:** Sie verfallen nie und hatten keine Obergrenze. 2.500 liegende Münzen drückten die Horde von 72,6 auf 56,7 FPS unbegrenzt. Jetzt schlafen Münzen außerhalb des Bildausschnitts (`coin_cull_step`), Ergebnis 66,7 FPS; Wert, Position und Anzahl bleiben gleich ([[Progression & Level-up]]).
  - **Drache:** Die Ringformel von Bodenschlag und Wirbel stand doppelt im Code (Treffer und Bild). Jetzt gibt es eine Funktion `dragon_ring_geometry` ([[Bosse]]).
  - **Boss-Suite:** Das Orakel sieht jetzt auch die geometrischen Altangriffe des Drachen: 12 statt 6 von 18 Fällen, überall 0 Bilder ohne sichere Position.
- **Audit bestätigt (nicht angefasst):** zentrale Schadensberechnung (`apply_attack_damage`), Stapelwerte mit Deckeln (`talent_equipment_apply`), gedeckelte Laufzeitlisten, keine Ressourcenlecks, Kiting-Druck (4–5 Aufholbewegungen in 45 s).
- **Davor am 26.11.:** Drachen-Sequenzen, Trefferstopp, Texturen im Menü, `vfx_random`, Preset kalibriert, Anforderungen für neue Grafik (siehe [[LOG]]).
- **Tests (26.11. spätabends):**
  - QA Stufe 2 PASS: docs, anchors, Regression 811, Boss 190, Level 174.
  - perf PASS mit 4 Szenarien.
  - Feature 195, Klassen 151, Visual 86 und Review 12 zuletzt am Abend PASS; vom Audit laut `qa.py` nicht betroffen.

## Offen (Reihenfolge)
1. **Nutzer:** F5 → Review-Center (36 Szenarien); Grafikquelle entscheiden; Zusammenstellung der Drachen-Sequenzen nach dem Spieltest (zwei sind identisch, [[Bugs & Ideen]]).
2. **Größtes Wartungsrisiko:** drei Boss-Codepfade. Vorschlag: Altangriffe des Drachen einzeln auf `bv2` umziehen, abgesichert durch das Orakel ([[Bugs & Ideen]]).
3. **Animation Controller S2** ([[Technische Architektur]] 4.2) und Gegnerzustand ohne Existenzprüfungen (`ObjectMonster`).
4. **Balancing-Beobachtung:** Waldläufer räumt in Bot-Händen deutlich langsamer; nur dokumentiert.

## Bekannte Bugs / Risiken
- Sequenz-Takt und Bossdruck (`bc_config`) sind Startwerte; nach dem Spieltest feinjustieren.
- Im Hauptmenü ruckelt das Bild in den ersten etwa 3 s (Textur-Entpacken).
- Das Orakel sieht die Projektilangriffe des Drachen nicht (Wind, Leere, Salve).
- Neuer Code: `instance_number(ObjectCoin)` und `with(ObjectCoin)` sehen nur aktive Münzen.
- GML: `all` ist ein Schlüsselwort; Array-Literale nicht direkt indizieren.
