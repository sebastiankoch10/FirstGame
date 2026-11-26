---
tags: [handoff, status]
updated: 2026-11-26
agent: Claude
---
# Übergabe (wird nach jeder Aufgabe überschrieben, max. ~40 Zeilen)

**Zuletzt dran:** Claude, 2026-11-26 nachmittags. Performance bei vielen Gegnern, Ruckler durch Textur-Entpacken und ArtPack-Pfade erledigt. **Zwei Commits lokal, nicht gepusht**; für andere Geräte `git push origin entwicklung`.

## Stand
- **Review-Center:** 25 Szenarien offen, keine persönliche Freigabe bisher ([[Review-Center]]). Die heutigen Änderungen sind entweder unsichtbar (Performance) oder ohne Review-Eintrag ([[Bugs & Ideen]]).
- **Neu am 26.11. nachmittags:**
  - **Performance:** Die Wald-Kollision nutzt einen Zellindex (Ergebnis identisch, geprüft an 16.200 Punkten), die Gegner-Trennung eine gemeinsame Nachbarliste. 148 Gegner: unbegrenzt 73–75 statt 64–66 FPS. Werkzeug `tests/tools/profile_perf.py` ([[Tests & QA]]).
  - **Ruckler:** Texturgruppen `Default` und `Equipment` werden beim Run-Start vorgeladen. Vorher gab es Einzelbilder bis etwa 350 ms beim ersten Auftauchen. **Vorläufig**, weil es etwa 5,1 s beim ersten Run der Sitzung kostet ([[Spielablauf & Zustände]]).
  - **ArtPack:** `atmosphere_v2` ist eine aktive Quelle (Minibosse, Magnet, Münze) und liegt jetzt unter `bosses/`. 12 PowerShell-Skripte zeigten noch auf die alten Ordner und sind korrigiert; `art_paths.py --check` prüft jetzt auch `.ps1` ([[Assets & Pipeline]]).
  - **Geprüft, ohne Änderung:** `progression_audit` (gewollte Messdaten) und `RoomCrypt`/`RoomRuins` (nur Rückfallebene).
- **Vormittags/mittags:** Messungen (Last, Level je Minute), mehrphasige Zauber, Wald-Skelette, Ankerpunkte, Aufräumen, QA-Suiten `docs`/`review`/`perf` (siehe [[LOG]]).
- **Tests (26.11. nachmittags):** QA Stufe 3 PASS (docs, anchors, static, regression 811, feature 195, boss 141, level 168, classes 151); perf dreimal ohne Ausreißer über 50 ms. Visual (84) zuletzt mittags PASS; heute Nachmittag nicht betroffen.

## Offen (Reihenfolge)
1. **Nutzer:**
   - Ladezeit des Textur-Vorladens entscheiden: so lassen, im Menü verteilt laden (Empfehlung), Kompression umstellen oder entfernen ([[Bugs & Ideen]]).
   - F5 → Review-Center prüfen und freigeben.
   - Über den `boss_test_preset`-Vorschlag entscheiden.
2. **Vorschläge, noch nicht freigegeben:**
   - A: den Effekt-Zufall vom Spielzufall trennen (`spell_vfx`, Wetter, Ambiente, Trefferfunken auf eigenen Generator).
   - B: Sichtprüfung der mehrphasigen Zauber, Wald-Skelette und „MAGNET“ per `record_scene.py`.
3. **Grafik-Entscheidungen** ([[Roadmap & Vertical Slice]] Zeilen 11–13): neutrale Basisfigur; Drachenschweif und Flügel als Teile.
4. **Performance** nur bei Bedarf: restliche Posten in [[Bugs & Ideen]].

## Bekannte Bugs / Risiken
- Die Bossdruck-Werte (`bc_config`) sind Startwerte; nach dem Spieltest feinjustieren.
- `FirstGame_ArtPack/characters/class_overhaul/CHARACTER_ART.md` enthält ein fremdes „c“ in Zeile 1 (uncommittet, nicht angefasst).
- Beim Schreiben von Patches über die Shell werden doppelte Backslashes zu einfachen; in Skripten `chr(92)` verwenden.
- Arbeitsweise: Auf eine offene Frage („Was kann man machen?“) erst einen Plan vorschlagen und auf das Go des Nutzers warten.
