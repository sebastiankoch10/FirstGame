---
tags: [handoff, status]
updated: 2026-11-25
agent: Claude
---
# Übergabe (wird nach jeder Aufgabe überschrieben, max. ~40 Zeilen)

**Zuletzt dran:** Claude, 2026-11-25. Nutzer war unterwegs; autonom an testbaren Roadmap-Punkten gearbeitet.

## Stand
- **Design-Kanon** `docs/Design/`, Vorrang im [[Leitbild]], Reihenfolge in [[Roadmap & Vertical Slice]].
- **Heute umgesetzt und getestet (Auswahl):**
  - Kamera 960×540, neue Klassennamen, dauerhafte Talente (R = zurücksetzen).
  - Meta-Progression langsamer, Elitegegner, Drachen-Nahangriffe, Waffen-Upgrade-Karten.
  - Pixeldichte 1:1 für Figuren und Ausrüstung.
  - Rig (2D-Skinning) für Drache, Zwillingshexen, Sumpfbehemoth; Haar und Umhang der Spielfigur federn nach.
  - **S1 Attack Timeline:** Schwertkette und Klassen-Kombos als Zeitachsen (`scripts/attack_timeline`), Werte unverändert.
  - **Zauber-Effekte:** 16 von 18 Zaubern als zusammengesetzte Pixel-Effekte in 3 Bändern (`spell_vfx`).
  - **QA-Suite `anchors`:** prüft die Telemetrie-Anker der Simulationen in Sekunden; zwei kaputte Anker repariert.
- **Tests:** Stand `3a701c4e` QA Stufe 3 PASS (anchors, static, regression 811, feature 159, boss 141, level 166, classes 151). Letzter Effekt-Schritt: siehe LOG bzw. Commit.

## Offen (Reihenfolge in [[Roadmap & Vertical Slice]])
1. **Spieltest durch den Nutzer** (F5): Elitegegner, Waffen-Upgrades, Drachen-Nahangriffe, Haar/Umhang, alle Zauber in Stufe 1/5/9. Werte von Elite und Waffen-Upgrades sind ungetestete Designwerte.
2. **Pixeldichte für Gegner und Bosse:** Gegner werden mit 1,1–1,65 gestreckt (`monster_scale`). Vorschlag: zuerst ein A/B-Bild, dann Entscheidung.
3. **S2 Animation Controller** (Übergangsposen, Clip-Ereignisse); Trefferstopp und Körperrotation beim Schwerthieb (Vertical Slice).
4. **Drachen-Rig Stufe 2:** Knochen für alle Posen, Hitboxen an Knochen.
5. Irrlicht und Prismensamen als eigene Effekte; Qualitätsstufen (S4).
6. **Minibosse:** Codex-Auftrag liegt beim Nutzer. **Quell-Asset-Migration** (Pfadtabelle zuerst).

## Bekannte Bugs / Risiken
- **MCP:** `MCP_TIMEOUT` wirkt nicht (gms-MCP bricht nach 30 s ab); für die Tests egal.
- **Rig:** `sprite_get_uvs` passt nicht zur Primitive-Textur; das Rig rendert über eine Surface.
- **Legacy-Harnesses** (`atmosphere_`, `dragon_`, `player_smoke_`, `combat_harness`) verweisen auf Altstände und laufen in keiner Suite.

## Nächste Schritte
1. **Nutzer:** F5 und die geschickten Bilder ansehen; künstlerische Abnahme bzw. Rückmeldung.
2. **Danach:** Punkt 2 (A/B-Bild Gegner-Pixeldichte) oder Punkt 3, je nach Rückmeldung.
