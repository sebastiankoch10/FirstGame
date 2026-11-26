---
tags: [system, ui]
updated: 2026-11-26
---
# UI, HUD & Menüs

## Zweck
Hauptmenü, Charakter- und Levelauswahl, Pause, Level-up-Wahl, HUD, Charakterbildschirm.

## Wichtige Dateien
- `objects/ObjectMainMenu`: Ablauf Neues Spiel → Charakter → Level, dazu Einstellungen und „Testmodus“ (bis 25.11. „Boss testen“, siehe [[Boss-Testmodus]]). Einstellungen seit 25.11. mit „Effektqualitaet“ (Index 5, „Zurueck“ jetzt 6 bzw. im Pausenmenü 6/7).
- `scripts/gameplay`:
  - Hauptmenü: `menu_labels`, `menu_activate`
  - Pausenmenü: `round_menu_labels`, `round_menu_activate`, `round_menu_draw`
- `scripts/gameplay_polish`: `ui_modal_draw`, Pause-Geometrie, Minimap.
- `scripts/hud`: Zauberslots mit Abklingzeit, XP-Leiste, Timer, Bossleiste, Talenthinweis, Ausrüstungsleiste.
- `scripts/spell_ui_v2`: Level-up-Karten, Tooltips, Pausen-Inventar mit Run-Statistiken.
- Weitere Bildschirme: der Charakterbildschirm in `scripts/talents` und `scripts/equipment`, die Levelvorschau in `scripts/level_worlds`. Objekte: `ObjectOverlay`, `ObjectSpellHUD`.

- **Review-Center** (seit 26.11.): Hauptmenüpunkt „Review-Center (N offen)“, Listenbildschirm mit Reitern und Detailfeld; im Szenario erweitert sich das Pausenmenü um Review-Aktionen und den grünen Freigabeknopf. Siehe [[Review-Center]].

- Einstellungen seit 26.11. mit „Lichtblitze“ (Index 6). „Zurueck“ liegt jetzt auf 7, im Pausenmenü auf 7 bzw. 8.

## Abhängigkeiten
[[Spielablauf & Zustände]] · [[Talente]] · [[Ausrüstung]] · [[Zauber & Passiva]] · [[Boss-Testmodus]]
