---
tags: [handoff, status]
updated: 2026-11-25
agent: Claude
---
# Übergabe (wird nach jeder Aufgabe überschrieben, max. ~40 Zeilen)

**Zuletzt dran:** Claude, 2026-11-25. Aufgaben: Design-Kanon und Audit, danach Nutzerentscheidungen und Roadmap-Schritte.

## Stand
- **Design-Kanon** `docs/Design/` (11 Dokumente). Vorrang und globale Regeln: [[Leitbild]]. Reihenfolge: [[Roadmap & Vertical Slice]].
- **Entschieden (25.11.):**
  - Kamera 960×540;
  - eigenes kostenloses Rig;
  - Namen Schwertmeister, Arkanistin, Waldläufer;
  - 30-min-Runs plus Talente zwischen Runs;
  - Legacy-Sprites und `output/` gelöscht.
- **Umgesetzt und getestet:**
  - Kamera 16:9 (keine Verzerrung mehr);
  - Klassennamen;
  - dauerhafte Talente je Klasse mit R = zurücksetzen (nur im echten Spiel, Testbuilds pro Run);
  - Kettenblitz als Pixel-Effekt in 3 Stufen;
  - Intensitäts-Bänder für alle Zauber;
  - Pixel-Partikel und Tonvariation;
  - Drachen-Körper-Rig (2D-Skinning);
  - Lebendigkeit der Spielfigur (Absprung, Landung, Lehnen);
  - IDE-Ordner nach Kategorien;
  - **Meilenstein 3:** langsamere Meta-Progression (nur Boss-Punkte dauerhaft), Elitegegner, Drachen-Nahangriffe, Waffen-Upgrade-Karten;
  - **Meilenstein 4:** Pixeldichte 1:1 für Figuren und Ausrüstung (160-px-Frames, Ursprung 80/145, `player_scale` 1).
- **Tests (25.11., Meilenstein 4):** static, regression 811, feature 159, boss 141, level 166, classes 150, visual 75 – alle PASS.

## Offen (Details und Reihenfolge in [[Roadmap & Vertical Slice]])
1. **Pixeldichte für Gegner und Bosse:** Figuren und Ausrüstung sind fertig; Gegner und Bosse stammen aus anderen Quellen.
2. **Haar und Umhang** als eigene, nachschwingende Ebenen (Pipeline-Trennung plus Federmodul).
3. **Attack Timeline (S1)** als gemeinsames System und Migration von Schwert und Klassenwaffen; Animation Controller (S2).
4. **Drachen-Rig Stufe 2:** Hitboxen an Knochen, Schweifschlag, Biss, Knochen für alle Posen; Hexen und Behemoth.
5. **Eigene zusammengesetzte Effekte** für die übrigen 17 Zauber (Vorlage: Kettenblitz).
6. **Minibosse:** Codex-Auftrag liegt beim Nutzer (neue Grafik).
7. **Quell-Asset-Migration** (Pfadtabelle, dann Verschieben).
8. **Werte** von Elitegegnern und Waffen-Upgrades sind ungetestete Designwerte; Spieltest bzw. Simulation empfohlen.

## Bekannte Bugs / Risiken
- **MCP:** `MCP_TIMEOUT` in `.claude/settings.json` wirkt nicht (gms-MCP bricht nach 30 s ab). Für die Tests egal.
- **Rig:** `sprite_get_uvs` passt bei den Drachen-Frames nicht zur Primitive-Textur; das Rig rendert deshalb über eine eigene Surface. Ursache unklar.
- **Legacy-Harnesses** (`atmosphere_`, `dragon_`, `player_smoke_harness`) verweisen auf gelöschte 0.1-Sprites. Sie laufen in keiner Suite.

## Nächste Schritte
1. **Nutzer:** F5. Kamera, Kettenblitz (Stufe 1 gegen 7+), Drache und Talente über mehrere Runs ansehen; künstlerische Abnahme.
2. **Danach** Roadmap-Punkt 1 (Pixeldichte) oder 2 (Haar und Umhang), je nach Rückmeldung.
