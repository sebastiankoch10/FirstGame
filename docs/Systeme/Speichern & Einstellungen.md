---
tags: [system, speichern]
updated: 2026-11-24
---
# Speichern & Einstellungen

## Zweck
Es gibt **keinen Spielstand**. Jeder Run beginnt neu. Gespeichert wird nur wenig, im lokalen GameMaker-Ordner (`%LOCALAPPDATA%\FirstGame`).

## Was wird geschrieben (laut Code)
- `firstgame_audio.ini`: die Option „Ton im Hintergrund“ (`scripts/audio_manager`). Gesamt-, Musik- und Effektlautstärke wurden im Code **nicht** als gespeichert gefunden.
- `firstgame_talents.ini`: nur wenn `talent_config().persistent = true` (derzeit aus).
- `firstgame_progression_current.json`: Messpunkte des Runs (`scripts/progression_audit`); schreibt in jedem Run.
- `boss-dev-errors.log`: nur im Boss-Entwicklermodus.

## Abhängigkeiten
[[Audio]] · [[Talente]] · [[Progression & Level-up]]

## Bekannte Probleme
- Lautstärken gehen beim Neustart vermutlich verloren. Siehe [[Bugs & Ideen]].
