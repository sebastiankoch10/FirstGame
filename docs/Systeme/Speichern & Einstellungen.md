---
tags: [system, speichern]
updated: 2026-11-26
---
# Speichern & Einstellungen

## Zweck
Es gibt **keinen Spielstand**. Jeder Run beginnt neu. Gespeichert wird nur wenig, im lokalen GameMaker-Ordner (`%LOCALAPPDATA%\FirstGame`).

## Was wird geschrieben (laut Code)
- `firstgame_audio.ini`: die Option „Ton im Hintergrund“ (`scripts/audio_manager`). Gesamt-, Musik- und Effektlautstärke wurden im Code **nicht** als gespeichert gefunden.
- `firstgame_settings.ini` (seit 25.11.): Effektqualität, Abschnitt `Grafik`, Schlüssel `effekte` (0 Niedrig, 1 Mittel, 2 Hoch). Menüeintrag „Effektqualitaet“ in beiden Einstellungsmenüs (`scripts/gameplay`, `ObjectMainMenu`).
  - Im selben Abschnitt `vollbild` (0/1), geschrieben von `render_set_fullscreen` und beim Start gelesen ([[Rendering & Pixelraster]]).
- `firstgame_talents.ini`: Talentränge und -punkte je Klasse (seit 2026-11-25 aktiv, nur im echten Spiel).
- `firstgame_progression_current.json`: Messpunkte des Runs (`scripts/progression_audit`); schreibt in jedem Run.
- `boss-dev-errors.log`: nur im Boss-Entwicklermodus.

- `review_approvals.json`, `review_approvals.log` (seit 26.11.): persönliche Freigaben aus dem [[Review-Center]], nur per Klick im Spiel geschrieben. Test- und Review-Sitzungen schreiben keine Talente und kein Fortschrittsprotokoll.

## Abhängigkeiten
[[Audio]] · [[Talente]] · [[Progression & Level-up]] · [[Rendering & Pixelraster]] · [[Licht, Wetter & Effekte]] (Effektqualität)

## Bekannte Probleme
- Lautstärken gehen beim Neustart vermutlich verloren. Siehe [[Bugs & Ideen]].
