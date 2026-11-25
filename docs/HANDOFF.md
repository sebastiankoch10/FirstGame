---
tags: [handoff, status]
updated: 2026-11-25
agent: Claude
---
# Übergabe (wird nach jeder Aufgabe überschrieben, max. ~40 Zeilen)

**Zuletzt dran:** Claude, 2026-11-25. Nutzer war unterwegs; autonom an testbaren Roadmap-Punkten gearbeitet, Bilder per Handy geschickt.

## Stand
- **Design-Kanon** `docs/Design/`, Vorrang im [[Leitbild]], Reihenfolge in [[Roadmap & Vertical Slice]].
- **Heute umgesetzt und getestet:**
  - Kamera 960×540, Klassennamen, dauerhafte Talente (R = zurücksetzen), langsamere Meta-Progression.
  - Elitegegner, Drachen-Nahangriffe, Waffen-Upgrade-Karten.
  - Pixeldichte 1:1 für Figuren, Ausrüstung und die 4 prozeduralen Kreaturen; Skelett-Gegner bleiben bis zu neuer Grafik.
  - Rig (2D-Skinning) für Drache, Zwillingshexen, Sumpfbehemoth; Haar und Umhang der Spielfigur federn nach.
  - **S1 Attack Timeline** (`scripts/attack_timeline`): Schwertkette und Klassen-Kombos, Werte unverändert.
  - **Alle 18 Zauber** als zusammengesetzte Pixel-Effekte in 3 Bändern; Grafikoption **Effektqualität** Niedrig/Mittel/Hoch.
  - QA-Suite `anchors` (Telemetrie-Anker); Pfadtabelle `tests/tools/assets/art_paths.py` (Asset-Migration Schritt 1).
- **Tests:** zuletzt QA Stufe 3 PASS (anchors, static, regression 811, feature 162, boss 141, level 166, classes 151, visual 75).

## Offen (Reihenfolge in [[Roadmap & Vertical Slice]])
1. **Spieltest durch den Nutzer** (F5): Elitegegner, Waffen-Upgrades, Drachen-Nahangriffe, Haar/Umhang, Zauber in Stufe 1/5/9, Effektqualität im Einstellungsmenü. Werte von Elite und Waffen-Upgrades sind ungetestete Designwerte.
2. **S2 Animation Controller** (Übergangsposen, Clip-Ereignisse) und für den Vertical Slice Trefferstopp und Körperrotation beim Schwerthieb (Gefühl, braucht Spieltest).
3. **Drachen-Rig Stufe 2:** Kopf, Hals und rechter Flügel für alle Posen vermessen (über 15 Posen), Hitboxen an Knochen.
4. **Asset-Migration** Schritte 2–4 (Probelauf, `git mv`, Prüfen). **Minibosse:** Codex-Auftrag liegt beim Nutzer.
5. Skelett-Gegner und Bosse in Pixeldichte 1:1: braucht neue Grafik.

## Bekannte Bugs / Risiken
- **MCP:** `MCP_TIMEOUT` wirkt nicht (gms-MCP bricht nach 30 s ab); für die Tests egal.
- **Rig:** `sprite_get_uvs` passt nicht zur Primitive-Textur; das Rig rendert über eine Surface.
- **Legacy-Werkzeuge:** `audit_boss_v2_assets.py` und mehrere alte Harnesses verweisen auf gelöschte Stände; sie laufen in keiner Suite. Siehe [[Bugs & Ideen]].

## Nächste Schritte
1. **Nutzer:** F5 und die geschickten Bilder ansehen; künstlerische Abnahme bzw. Rückmeldung.
2. **Danach:** Punkt 2 oder 3, je nach Rückmeldung.
