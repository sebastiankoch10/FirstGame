---
tags: [handoff, status]
updated: 2026-11-26
agent: Claude
---
# Übergabe (wird nach jeder Aufgabe überschrieben, max. ~40 Zeilen)

**Zuletzt dran:** Claude, 2026-11-26 nachts. **Grafik-Overhaul HD-2D** (Maßstab Octopath Traveler), Schritte 0–3 und die Ergänzung „Figuren und Gefahrenflächen“. **Status: ANGEHALTEN, wartet auf das Urteil des Nutzers zum Schaustück im Review-Center.** Erst nach „Gut“ ausrollen (Roadmap 14).

## Stand des Overhauls
- **Regeln:** [[Visuelles Leitbild & Animation]] 7 (Angriffsaufbau, zwei Ebenen, Licht, Pixel, Figuren 7.5), Leitbild G10, [[DECISIONS]] 26.11. abends.
- **Referenzen:** `FirstGame_ArtPack/reference/octopath/` (24 Bilder, nur lokal, gitignored, nie committen).
- **Umgesetzt:**
  - `render_fx`: Nachbearbeitung nur der Weltebene; eine Schutzmaske hält Gegner scharf.
  - Verstärkbares Licht in `atmosphere`; dazu `fx_particles`, `atmos_fx`, `fx_attacks` sowie `fx_character` mit `sh_fx_char`.
  - Neue Gefahrenfläche bisher nur für Feuerstrahlen (`vfx_beam_fire_hd`, Schalter `FX_HD_HAZARDS`).
- **Schaustück (Review, offen):**
  - neu: `vfx.overhaul.dragon_breath`, `.sword_fireball`, `.mage_lightning`, `.ranger_ice`, `char.overhaul.sword`, `light.overhaul.forest|swamp|ashfrost`;
  - per bump: `boss.dragon.beam` Rev. 3, `boss.twins.checker` Rev. 2.
- **Vorher/Nachher-Aufnahmen:** `%LOCALAPPDATA%\FirstGame-Tests\overhaul\1-vorher|2-nachher` (je 8 Szenen).
- **Tests:** QA Stufe 3 PASS (Regression 811, Feature 219, Boss 190, Level 174, Klassen 151, Visual 77, Review 18). perf: Boss und Horde wie vorher; **Münz-Belastungstest 1,2 ms langsamer (FAIL, [[Bugs & Ideen]])**. visual-qa zum Feueratem: Rand PASS.

## Nach dem Urteil (je Sitzung Stand hier)
1. Kommentare aus `review.py status` umsetzen.
2. Ausrollen:
   - übrige 15 Zauber und Passiva;
   - Startwaffen;
   - alle Boss-, Miniboss- und Gegnerangriffe samt Gefahrenflächen (je Gefahr eine visual-qa-Zweitmeinung);
   - Treffer und Tode, Münzen, Pickups, Level-up, Vegetation.
3. Neue Figurengrafik nur mit Quelle: [[Assets & Pipeline]] 7.8.

## Sonst offen
- Diktieren mit Win+H im Urteilsdialog beim ersten echten Urteil ausprobieren (nicht automatisch prüfbar).
- Zusammenstellung der Drachen-Sequenzen nach dem Spieltest; drei Boss-Codepfade zusammenführen ([[Bugs & Ideen]]).

## Bekannte Bugs / Risiken
- Ohne Shader-Unterstützung entfällt die Nachbearbeitung (Meldung `FX_POST disabled`), das Spiel läuft weiter.
- `record_scene` nie parallel starten: Alle Aufnahmen nutzen denselben Speicherordner für Einzelbilder.
- Prüffrage: Verfehlen Leere und Wind (P3) eine ruhende Figur? Hauptmenü ruckelt in den ersten etwa 3 s.
- GML: reservierte Namen siehe AGENTS.md (`all`, `real`); Array-Literale nicht direkt indizieren.
