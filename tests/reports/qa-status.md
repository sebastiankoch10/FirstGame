# FirstGame QA Status

Stand: 2026-11-22

## Kritische Menüprüfung

- Menü-transition lock wurde hinzugefügt.
- Levelauswahl setzt `pending_new_game = false`, `round_active = true` und ruft `room_goto(Room1)` höchstens einmal auf.
- Alle drei Level verwenden weiterhin `Room1` und werden über `global.selected_level` unterschieden.
- Die aktiven Level-Multiplikatoren werden in `reset_round()` gesetzt.

## Status

- PASS: Project-Check, Quick-Diagnostik, Windows-VM-Kommandobuild.
- PASS: Die direkte Windows-VM-Run-Funktion hat einen Prozess gestartet (PID 15076).
- PASS: Der Startprozess wurde danach per `gm_run_status` als laufend erkannt und per PID beendet; der Abschlussstatus meldet nicht mehr laufend.
- BLOCKED: Neun tatsächliche Menü-/Runtime-Kombinationen konnten nicht mit `gm_test_run` ausgeführt werden, weil isolierte Snapshot-Verpackung weiterhin mit `PackageZip()` fehlschlägt.
- BLOCKED: Langläufer in echter macOS-Runtime-Testumgebung sind unter Windows nicht verfügbar.
- NOT RUN: Gameplay-Assertions für echte 60-Sekunden-Läufe, Treffer, Projektile und vier Richtungen.

## QA-Infrastruktur

- MCP-Tools sind erreichbar.
- Direkter Windows-VM-Build: erfolgreich.
- Direkter Windows-VM-Start: erfolgreich.
- Isolierter Snapshot-Test: weiterhin blockiert durch leeren `destFileName`.
- Independent FirstGame-QA-Agent: gestartet; Ergebnis wird als statische und laufzeitbegrenzte Prüfung dokumentiert.

## Testgeschwindigkeit

- Normalmodus bleibt bei Raumgeschwindigkeit 60 FPS.
- `global.qa_test_mode` und `global.qa_test_speed` werden in `reset_round()` geschützt initialisiert.
- Noch keine automatische Beschleunigung; Timer, Animationen und Gegner-KI wurden nicht blind verändert.
