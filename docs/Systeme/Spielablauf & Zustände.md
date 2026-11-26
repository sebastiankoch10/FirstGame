---
tags: [system, ablauf]
updated: 2026-11-26
---
# Spielablauf & Zustände

## Zweck
Zentrale Schleife und Spielzustände. Sie legt fest, was in welchem Frame läuft und wann pausiert wird.

## Wichtige Dateien
- `rooms/RoomMenu` ist der Startraum. Danach geht es zu `Room1`, `RoomSwamp` oder `RoomAshfrost` (Reihenfolge in `FirstGame.yyp`).
- `objects/ObjectController/Step_0.gml` steuert die Reihenfolge pro Frame:
  1. Testmodus (`boss_test_pending_start` startet Bosskampf oder „Freie Szene“, `boss_test_tick`; siehe [[Boss-Testmodus]])
  2. Charakterbildschirm (`talent_menu_step`)
  3. Pause, Level-up und Truhenwahl
  4. `boss_world_step`
  5. HUD, Effekte, Zauber, Ausrüstung
  6. `apply_passives`, Level-up-Prüfung, automatische Zauber
- `objects/ObjectController/Draw_73.gml` zeichnet nach dem Licht: Zauber, Bossgefahren, Beute. `Draw_64.gml` zeichnet die GUI-Modals.
- `objects/ObjectController/Create_0.gml` lädt seit 26.11. beim Run-Start die Texturgruppen `Default` und `Equipment` vor (`texture_prefetch`, einmal je Sitzung wirksam, Log `TEXTURE_PREFETCH ms`). Gemessen: **etwa 5,1 s** beim ersten Run-Start der Sitzung, danach 0,01 ms. Wie das gelöst wird, entscheidet der Nutzer: so lassen, im Menü verteilt laden, Kompression umstellen oder Vorladen entfernen ([[Bugs & Ideen]]). Vorher entpackte GameMaker die bz2-Seiten erst beim ersten Gebrauch mitten im Kampf, mit Einzelbildern bis etwa 350 ms. Die Levelgruppen `Level_Swamp` und `Level_Ashfrost` lädt `level_world_create`.
- `scripts/reset_round`: setzt alles für einen neuen Run zurück (Klassenwerte, Talente, Ausrüstung, Bosse, Level-Schwierigkeit). Über `talent_reset_run` auch die Waffen-Upgrades.
- `objects/ObjectRender` (persistent, vom Hauptmenü erzeugt): Raumstart setzt Ansicht und GUI-Größe, Post-Draw gibt die Welt-Surface pixelgenau aus ([[Rendering & Pixelraster]]).
- Globale Zustände: `global.game_paused`, `normal_pause_active`, `levelup_active`, `chest_collected`, `talent_menu_active`, `game_over`, `round_active`.

## Abhängigkeiten
[[Spieler & Bewegung]] · [[UI, HUD & Menüs]] · [[Bosse]] · [[Zauber & Passiva]] · [[Talente]] · [[Ausrüstung]] · [[Rendering & Pixelraster]] · [[Boss-Testmodus]]

## Bekannte Probleme
- Die Pause hängt an vielen Flags. Neue Modals müssen sie konsequent setzen und zurücksetzen (siehe `talent_menu_open/close`).
