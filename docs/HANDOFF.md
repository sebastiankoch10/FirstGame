---
tags: [handoff, status]
updated: 2026-11-26
agent: Claude
---
# Übergabe (wird nach jeder Aufgabe überschrieben, max. ~40 Zeilen)

**Zuletzt dran:** Claude, 2026-11-26 nachts. Kurskorrektur „Basemodel ohne Ausrüstung“ (Priorität 1), danach Orakel für Drachen-Projektile und Prüfung der Codex-Übergabe. Alles committet und nach `origin/entwicklung` gepusht. **Nächster Agent: Codex (Basemodels).**

## PRIORITÄT 1: Basemodels ohne Ausrüstung – BLOCKIERT an fehlender Quellgrafik
- **Regel (verbindlich):** Ein Sprite mit sichtbarer Ausrüstung ist kein Basemodel ([[Visuelles Leitbild & Animation]] 5.5a).
- **Ist:** Die Spielfiguren `spr_fg_<klasse>v3_*` sind ausgerüstete Startfiguren.
  - Schwertkämpfer: Umhang, Kettenhemd, Schal, Stiefel-Rüstung.
  - Arkanistin: Robe.
  - Waldläufer: Kapuzenmantel, Lederrüstung, Köcher.
  - Sie bleiben nur als spielbare Übergangsfigur und werden nicht weiter ausgebaut.
- **Blocker:** Die Basemodels brauchen neue gemalte Atlanten. Claude Code hat kein Bildwerkzeug, lokal ist keins installiert. Herausrechnen geht nicht, weil unter Umhang und Robe keine Bildinformation liegt.
- **Auftrag für den Agenten mit Bildwerkzeug (oder Pixel-Artist):**
  1. Brief und Maße lesen: [[Assets & Pipeline]] 7.1, je Atlas die Originalzelle als Posen-Vorlage.
     - Die Atlasgrößen sind verschieden (5 von 12 weichen von 1254 × 1254 ab; Waldläufer combat hat 9 Reihen).
     - Jede Figur steht an der Stelle des Originals. Hintergrund transparent, Figur voll deckend.
  2. 12 Atlanten erzeugen (3 Klassen × `walk`, `combat`, `mobility`, `reaction`) nach `FirstGame_ArtPack/characters/base_neutral/<klasse>_<atlas>_base.png`.
  3. `python tests/tools/characters/check_base_neutral.py` muss PASS melden (Entwürfe vorab mit `--dir PFAD`); danach Sichtprüfung gegen die Verbotsliste.
  4. Erst dann Ebenen und Umschalten nach [[Assets & Pipeline]] 7.7, ohne Mischbetrieb.
- **Vorbereitet:** Regel und Ebenen-Stapel (10 Ebenen), Ablage, `atlas.base_neutral_path`, Abnahmeprüfung, Quellformat der Ebenen, Umstiegsplan.
- **Offene Designentscheidung (Nutzer):** Werden Rücken, Schultern, Beine und Nebenhand eigene Spielplätze (mehr Werte, also Balancing) oder Teil vorhandener Gegenstände?

## Stand sonst
- **Review-Center:** 34 offen, 2 ersetzt (`char.equipment.mage` und `.ranger`, weil sie Ausrüstung auf der falschen Basis zeigen).
- **Tagesstand 26.11.:** Drachen-Sequenzen, Trefferstopp, Münz-Culling, Texturen im Menü, `vfx_random`, Preset kalibriert (siehe [[LOG]]).
- **Boss-Orakel:** Es sieht jetzt auch die Projektile des Drachen; in allen Fällen gibt es 0 unsichere Bilder. Offene Prüffrage, ob Leere und Wind (P3) eine ruhende Figur verfehlen ([[Bugs & Ideen]]).
- **Tests:** QA PASS (docs, anchors, Boss 190); davor Regression 811, Review 12, Level 174 PASS.

## Offen danach
1. Zusammenstellung der Drachen-Sequenzen nach dem Spieltest; Sequenzen für Hexen und Behemoth.
2. Drei Boss-Codepfade zusammenführen; Animation Controller S2 ([[Bugs & Ideen]]).

## Bekannte Bugs / Risiken
- Weitere Ausrüstungs- und Optikarbeit an Figuren erst nach den Basemodels (Roadmap 11 vor 13).
- Im Hauptmenü ruckelt das Bild in den ersten etwa 3 s (Textur-Entpacken).
- GML: `all` ist ein Schlüsselwort; Array-Literale nicht direkt indizieren.
