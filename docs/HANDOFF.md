---
tags: [handoff, status]
updated: 2026-11-26
agent: Claude
---
# Übergabe (wird nach jeder Aufgabe überschrieben, max. ~40 Zeilen)

**Zuletzt dran:** Claude, 2026-11-26. **In Arbeit:** Aufträge Phase 1, 2A und 2B des Nutzers (siehe Chat). Reihenfolge: Review-Center → Inventar → Telegraphs, Geometrie, VFX, Licht (2A) → Bossverhalten, Schachbrett, Ringe (2B) → artikulierte Bosse und Gegner → Grundangriffe und Progression → modulare Charaktere → Assets → Doku und Bericht.

## Stand
- **Fertig und getestet (Commit 26.11.):**
  - **Review-Center:** [[Review-Center]], Ablauf in AGENTS.md „Review-Workflow“.
  - **Inventar:** Drag-and-drop, Rechtsklick, Tooltips, Shift-Vergleich.
  - QA Stufe 3 PASS, Review-E2E PASS.
- **Vorbereitet im Scratchpad, noch nicht eingespielt:** `hazard_fx` (Telegraphs v2, Flächen, Strahl, Aufladung, Schachbrett), Licht-Blitze, Aggression und Ringe.
- **Review-Registry:** 3 Einträge offen (Drache Feuerstrahl, Hexen Ring, Charakter Bewegung).

## Offen (Reihenfolge)
1. Phase 2A einspielen, prüfen, Review-Fälle registrieren.
2. Phase 2B: spielfeldweites Schachbrett, Druck nach Entfernung, kontrahierende Ringe, artikulierter Drache (Schweif, Flügel), Gegnerbewegung, Waldläufer-Grundpfeile, Fähigkeitsprogression.
3. Phase 1 Rest: modulare Charakterdarstellung (neutrale Basis, Ebenen, Waffen-Ankerpunkte).
4. **Nutzer:** F5 → Review-Center, prüfen und mit dem grünen Haken freigeben.

## Bekannte Bugs / Risiken
- GameMaker-IDE war offen und sortiert `FirstGame.yyp` beim Speichern um (inhaltlich gleich).
- `FirstGame_ArtPack/class_overhaul/CHARACTER_ART.md` hat ein fremdes „c“ in Zeile 1; nicht angefasst.
- Spielerlevel je Minute ist nicht gemessen (`boss_test_preset`), siehe [[Bugs & Ideen]].
