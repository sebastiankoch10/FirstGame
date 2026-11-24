---
tags: [decisions, architektur, design]
updated: 2026-11-24
---
# Entscheidungen (kurz: Datum · Entscheidung · Grund)

## Arbeitsweise und Werkzeuge
- **2026-11-24 · `AGENTS.md` ist die einzige Hauptquelle, `CLAUDE.md` importiert sie.** Grund: Claude und Codex sollen dieselben Regeln lesen, damit nichts auseinanderläuft.
- **2026-11-24 · `docs/` ist der Obsidian-Vault, nicht das ganze Repo.** Grund: übersichtlich, keine Code- oder Assetflut im Vault. Die älteren Berichte bleiben an ihrem Ort und werden verlinkt.
- **2026-11-24 · Übergabe nur am Aufgabenende** über HANDOFF, LOG und DECISIONS. Grund: spart Tokens.
- **2026-11-24 · Hooks kosten keine Tokens.** SessionStart zeigt nur HANDOFF an, Stop schreibt nur eine Logzeile (kein KI-Aufruf).
- **2026-11-24 · Git nur lokal (`entwicklung`), nie pushen.** Grund: Der Nutzer nutzt GitHub nicht.
- **2026-11-24 · Token-Regeln:** Lesereihenfolge HANDOFF → eine Systemnotiz → gezielter Code. Jede Info an genau einer Stelle. Am Aufgabenende ein Commit mit `[Claude]` oder `[Codex]`. Grund: Beide Agenten bleiben synchron, ohne jedes Mal Doku oder Code komplett zu lesen. `git log` ist die billigste Synchronquelle.
- **2026-11-24 · `DEVELOPMENT_PROGRESS.md`, `TODO.md` und `QA/CURRENT_STATUS.md` werden nicht mehr laufend gepflegt.** Grund: Sie würden HANDOFF und Bugs & Ideen doppeln.
- **2026-11-24 · Test-Builds unter `%LOCALAPPDATA%\FirstGame-Tests\`, nie im Projektordner.** Grund: Der Nutzer will keine EXE oder ZIP im Projekt; er testet mit F5.

## Spieldesign
- **2026-11-23 · Bossphilosophie** in `DESIGN/BOSS_DESIGN.md`, höchste Priorität für Bosse. Positionierung statt mehr HP oder Schaden. Keine Zahlenänderungen am Balancing ohne Auftrag.
- **2026-11-24 · Talente gelten pro Run**, persistent ist umschaltbar über `talent_config().persistent`. Punkte ab Stufe 4 alle 4 Stufen und je Hauptboss. Grund: Es gab keine Vorgabe; die Architektur bleibt konfigurierbar. Siehe [[Talente]].
- **2026-11-24 · Ausrüstung:** Start ohne, 6 Slots, 4 Seltenheiten. Bosse droppen garantiert, Gegner zu 0,3 %. Klar bessere Funde werden automatisch angelegt. Siehe [[Ausrüstung]].
- **2026-11-24 · Bossmuster sind normale bv2-Gefahren auf einer Uhr je Boss.** Grund: Warnung und Treffer können nicht auseinanderlaufen. Siehe [[Bosse]].
- **2026-11-24 · Schwenkstrahlen treffen pro Überstreichen nur einmal.** Grund: Die Simulationen zeigten Mehrfachtreffer.
- **2026-11-24 · Komplexe Varianten der Fähigkeiten 1–3 erst bei Bossen ab Minute 10.** Grund: Der erste Boss in Minute 5 soll zugänglich bleiben (laut `BOSS_DESIGN.md` Abschnitt H: „später komplexere Varianten“).
- **2026-11-24 · Aufholattacken ersetzen den Teleport.** Der Teleport bleibt nur als Notfall (über 850 px außerhalb des Bildes, nach 6 s).
- **2026-11-24 · Charaktere aus Basismodell plus sichtbaren Ausrüstungsebenen.** Basis = Grundkleidung ohne Waffe. Die Startwaffe ist eine eigene Ebene, solange keine Waffe angelegt ist. Siehe [[Charaktergrafik & Ausrüstungs-Layer]].
- **2026-11-24 · Umhänge bleiben im Basismodell.** Grund: Das Ausrüstungssystem hat keinen Umhang-Slot (Waffe, Kopf, Brust, Hände, Füße, Talisman). Der rote bzw. grüne Umhang ist Klassenidentität. Ein Umhang-Slot wäre eine Design- und Balancing-Änderung.
- **2026-11-24 · Aussehen eines Gegenstands = Stufe aus der Gegenstandsstufe (wie der Name), Seltenheit = Akzentfarbe.** Grund: Die Namen hängen schon an der Stufe; keine neuen Item-Daten, keine Wertänderung.
- **2026-11-24 · Ausrüstungsgrafik prozedural aus den Originalfiguren abgeleitet.** Grund: Claude hat keinen Bildgenerator. So sitzen alle Teile in jedem der rund 1.240 Frames pixelgenau. Für handgezeichnete Varianten kann Codex (mit Bildgenerator) die Pipeline weiterverwenden.
- **2026-11-24 · Gepackte Atlanten plus Rechtecktabelle statt Einzelframes.** Grund: rund 23.000 Ausrüstungsframes als Einzel-PNGs würden Build, IDE und Testkopien stark verlangsamen.
