---
tags: [handoff, status]
updated: 2026-11-27
agent: Claude
---
# Übergabe (wird nach jeder Aufgabe überschrieben, max. ~40 Zeilen)

**Zuletzt dran:** Claude, 2026-11-27. Auftrag „Mach das alles“ mit Ergänzung (1 → Liste → 2 → 3 Drache → 4 → anhalten). **Block 1, 2 und 3 fertig.** Als Nächstes laut Auftrag Punkt 4 (Zauber und Passiva, Roadmap 16), danach anhalten und berichten; über die übrigen Bosse entscheidet der Nutzer.

## Stand
- **Block 3 (Drache, Pilot „Die Attacke ist die Warnung“):** Alle 9 Attacken plus Biss und Schweif kündigen sich mit Vorzeichen an und zeigen aktiv die Attacke selbst (`scripts/hazard_looks`, [[Boss-Design]] B2, [[Kampf & Begegnungen]] 5.0). Aktive Bossgefahren liegen über allen Ankündigungen; Elemente nie auf Spielerfigur und Drachenkörper.
- **Tests 27.11. (Stand 7):** docs, anchors, static, Regression 811, Feature 219, Boss 190 (Orakel), Level 177, Klassen 151, Visual 77: PASS. visual-qa: zwei Runden, Befunde umgesetzt bzw. in [[Bugs & Ideen]].
- **Block 2:** Boss-Codepfade (Drache, Minibosse, Encounter) laufen über die gemeinsamen `bv2`-Gefahren.
- **Block 1:** Roadmap 14 (`scripts/fx_world`), Drachen-Zielkorrektur, Sequenzen.

## Offen (nur zur Information, nicht ungefragt abarbeiten)
- Zwillingshexen, Sumpfbehemoth, Minibosse und Gegner noch mit Markerwarnungen (Entscheidung des Nutzers).
- Drache: Maul-Ursprung von Strahl, Leere und Salve; Biss-Hals als Säule; Abbruch laufender Ankündigungen bei Navigation ([[Bugs & Ideen]]).
- Münz-Stresstest unter 60 FPS; neue Figurengrafik BLOCKED (Quelle beim Nutzer); Diktieren mit Win+H ungetestet.

## Bekannte Bugs / Risiken
- GML: Ein `//`-Kommentar in einer Einzeilen-Anweisung schluckt den Rest der Zeile; nach jeder Änderung `compile_check.py` vor der QA.
- `fx_*`-Funktionen nicht innerhalb von `with()` auf Controller-Variablen zugreifen lassen.
- `record_scene` nie parallel starten; der Cleaner behält nur 6 Szenen-Läufe (Aufnahmen zum Aufheben nach `overhaul/` kopieren).
