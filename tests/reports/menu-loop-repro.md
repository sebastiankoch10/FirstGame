# FirstGame Menü-Loop Reproduktion

Stand: 2026-11-22

## AUSGEFÜHRTER FEHLSCHLAGENDER TEST

- Build: Live Windows-VM-Prozess `run_1795339809098655500`, PID 9196
- Aktionen:
  1. Hauptmenü geöffnet
  2. Enter auf „Neues Spiel“
  3. Charakterauswahl „CHARAKTER“ sichtbar
  4. Enter auf „Schwertkaempfer“
  5. Levelauswahl „LEVEL“ sichtbar
  6. Enter auf „Waldfeld“
- Beobachtung: Nach Aktion 6 kehrte die Oberfläche sofort zu „Neues Spiel“, „Levelauswahl“, „Einstellungen“, „Beenden“ zurück.
- Ergebnis: **FAIL**
- Ursache: `pending_new_game` wurde in der Charakterauswahl auf `false` gesetzt. Dadurch erkannte die anschließende Levelauswahl den Übergang nicht mehr als neuen Spielstart und lief in den Rückweg zum Hauptmenü.

## Reparatur

- `pending_new_game` bleibt nach der Charakterauswahl erhalten.
- Die Levelauswahl setzt `pending_new_game` erst unmittelbar nach dem `room_goto(Room1)`-Startpfad zurück.
- Menü- und Raumwechsel werden mit Debug-Zeilen protokolliert.

## Nachreproduktion nach Reparatur

- Neuer direkter Windows-VM-Build: erfolgreich.
- Startprozess: PID 23508.
- Echte Eingaben: Hauptmenü -> Enter -> Schwertkaempfer -> Enter -> Waldfeld -> Enter.
- Nach der Levelauswahl wurde die tatsächliche Gameplay-Oberfläche mit Level/HUD/Spieler/Gegenden angezeigt.
- Zweiter Screenshot nach weiterer Laufzeit zeigte weiterhin keine Rückkehr ins Hauptmenü.
- Ergebnis für `Schwertkaempfer / Waldfeld`: **PASS**
- Der Raumwechsel blieb in der Gameplay-Sicht; kein sichtbarer Raum- oder Menüloop wurde mehr beobachtet.

## Matrixstatus

| Klasse | Level | Ergebnis |
|---|---|---|
| Schwertkämpfer | Waldfeld | PASS |
| Schwertkämpfer | Gruft | NOT RUN / nicht 10 Sekunden verifiziert |
| Schwertkämpfer | Verlassene Ruinen | NOT RUN |
| Magier | Waldfeld | FAIL für 10-Sekunden-Stabilität: Gameplay wurde geladen, danach Game Over beobachtet |
| Magier | Gruft | NOT RUN |
| Magier | Verlassene Ruinen | NOT RUN |
| Waldläufer | alle Level | NOT RUN |

## Fehlende technische Voraussetzung

- Der isolierte Snapshot-`gm_test_run` kann wegen des Windows-PackageZip-Fehlers keine Assertionen ausführen.
- Die UI-Automation konnte einzelne reale Menüpfade ausführen, war aber für die gesamte neunfache Matrix nicht zuverlässig genug.
