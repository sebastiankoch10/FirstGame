---
tags: [handoff, status]
updated: 2026-11-27
agent: Claude
---
# Übergabe (wird nach jeder Aufgabe überschrieben, max. ~40 Zeilen)

**Zuletzt dran:** Claude, 2026-11-27. Auftrag „Mach das alles“ mit Ergänzung **abgeschlossen** (1 → Liste → 2 → 3 Drache → 4). Laut Auftrag angehalten: Über die Umstellung der übrigen Bosse (Zwillingshexen, Sumpfbehemoth, Minibosse, Gegner) entscheidet der Nutzer.

## Stand
- **Punkt 4 (Roadmap 16):** `scripts/fx_spells` gibt allen Zaubern und den sichtbar wirkenden Passiva Pixelpartikel (Einschlag, lebende Zauber, Heilung, Schutz, Resonanz, Schwüre, Orbit Shield). Eigene Lichtblitze und -pulse gedämpft; der Endgame-Kettenblitz überstrahlt den Drachen nicht mehr. Keine neuen Sprites.
- **Block 3 (Drache, Pilot „Die Attacke ist die Warnung“):** Vorzeichen und aktive Darstellung aller 9 Attacken plus Biss und Schweif (`scripts/hazard_looks`); aktive Bossgefahren über allen Ankündigungen; Spielerfigur bleibt frei.
- **Block 2:** Boss-Codepfade über die gemeinsamen `bv2`-Gefahren. **Block 1:** Roadmap 14 (`scripts/fx_world`).
- **Tests 27.11.:** Punkt 4 alle 9 Suiten PASS, danach nach der Lichtkorrektur docs, anchors, Regression 811, Feature 219, Klassen 151, Visual 77 PASS. Block 3: alle 9 Suiten PASS (Boss 190 mit Orakel), Lastmessung 4/4 PASS.

## Offen (nur zur Information, nicht ungefragt abarbeiten)
- Übrige Bosse und Gegner noch mit Markerwarnungen (Entscheidung des Nutzers).
- Drache: Maul-Ursprung von Strahl, Leere und Salve; Biss-Hals als Säule; Abbruch laufender Ankündigungen bei Navigation ([[Bugs & Ideen]]).
- Zauber: Sprites verdecken teils die Spielerfigur, Ember Field ähnelt dem Drachen-Feuerboden, alte Partikel ohne Pixelraster, Passiv-Partikel ohne Aufnahme (NOT RUN) ([[Bugs & Ideen]]).
- Münz-Stresstest unter 60 FPS; neue Figurengrafik BLOCKED (Quelle beim Nutzer); Diktieren mit Win+H ungetestet.

## Bekannte Bugs / Risiken
- GML: Ein `//`-Kommentar in einer Einzeilen-Anweisung schluckt den Rest der Zeile; nach jeder Änderung `compile_check.py` vor der QA.
- `fx_*`-Funktionen nicht innerhalb von `with()` auf Controller-Variablen zugreifen lassen.
- `record_scene` nie parallel starten; der Cleaner behält nur 6 Szenen-Läufe (Aufnahmen zum Aufheben nach `overhaul/` kopieren).
