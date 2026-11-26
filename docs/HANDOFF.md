---
tags: [handoff, status]
updated: 2026-11-26
agent: Claude
---
# Übergabe (wird nach jeder Aufgabe überschrieben, max. ~40 Zeilen)

**Zuletzt dran:** Claude, 2026-11-26 abends. Nutzerentscheidung: keine Basemodels, die heutigen Figuren bleiben, Rüstung unsichtbar. Das Review-Center hat jetzt ein Urteil „Gut“ / „Nicht gut“ mit Kommentar. Der frühere Auftrag „Basemodels“ an Codex ist **zurückgezogen**.

## Zuletzt erledigt
- **Rüstung unsichtbar:** `#macro EQUIPMENT_ARMOR_VISIBLE false` in `scripts/equipment_visual` (`player_layers_draw` zeichnet nur `wpn*`).
  - Helm, Brust, Hände und Füße bleiben als Gegenstände, Werte, Inventar und Ebenengrafik erhalten; `true` zeigt sie wieder.
  - Die Waffen bleiben sichtbar. Regel: [[Visuelles Leitbild & Animation]] 5.5a, Begründung in [[DECISIONS]].
- **Review-Urteil mit Kommentar:** Das Escape-Menü hat „Gut – freigeben“ und „Nicht gut“, beide mit Textfeld (600 Zeichen).
  - Bei „Nicht gut“ wählt der Nutzer „Komplett weg“ oder „Anders umsetzen“. Diktieren geht über Windows Win+H.
  - `review.py sync`: „Gut“ wird `processed`, „Nicht gut“ wird `rejected` mit `feedback`. `status` zeigt „NICHT GUT“ und „GUT MIT WUNSCH“.
  - Kommentare sind Arbeitsaufträge: AGENTS.md „Review-Workflow“, [[Review-Center]].
- **Erste persönliche Freigaben verarbeitet:** `boss.dragon.beam` Rev. 2 und `boss.twins.checker` Rev. 1. Sie sind jetzt verbindliche Qualitätsreferenz.
- **Review:** neuer Eintrag `char.armor.hidden`; Texte von `char.motion.sword` und `ui.inventory` angepasst. Pausenliste rückt bei beiden Urteilszeilen zusammen (`pause_row_pitch`).

## Stand
- Review-Center: 37 Einträge, 33 offen, 2 verarbeitet, 2 ersetzt.
- Tests: QA Stufe 3 PASS (Regression 811, Feature 195, Boss 190, Level 174, Klassen 151, Visual 77, Review 18, docs, static).
- Basemodel-Vorbereitung (`characters/base_neutral/`, `check_base_neutral.py`, [[Assets & Pipeline]] 7.1/7.7) bleibt liegen, ohne Auftrag.

## Offen / nächste Schritte
1. Diktieren mit Win+H im Urteilsdialog ist nicht automatisch prüfbar. Beim ersten echten Urteil ausprobieren.
2. Nach dem nächsten `sync`: Kommentare aus `review.py status` als Aufträge abarbeiten.
3. Zusammenstellung der Drachen-Sequenzen nach dem Spieltest; Sequenzen für Hexen und Behemoth.
4. Drei Boss-Codepfade zusammenführen; Animation Controller S2 ([[Bugs & Ideen]]).
5. Neue Grafik (Drachenschwanz und -flügel, Skelette, Minibosse) muss geliefert werden; hier gibt es kein Bildwerkzeug.

## Bekannte Bugs / Risiken
- Prüffrage: Verfehlen Leere und Wind (P3) eine ruhende Figur? ([[Bugs & Ideen]])
- Im Hauptmenü ruckelt das Bild in den ersten etwa 3 s (Textur-Entpacken).
- GML: reservierte Namen siehe AGENTS.md (`all`, `real`); Array-Literale nicht direkt indizieren; `@'…'` darf keinen Apostroph enthalten.
