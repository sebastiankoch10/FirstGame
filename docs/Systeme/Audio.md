---
tags: [system, audio]
updated: 2026-11-26
---
# Audio

## Zweck
Musik (Menü, Level, Boss) und Soundeffekte mit zentralem Mixer.

## Wichtige Dateien
- `scripts/audio_manager`:
  - `fg_sfx`: höchstens 16 Stimmen, 2 je Cue. Wiederholte, nicht wichtige Cues variieren die Tonhöhe um ±5 % (deterministisch, ohne Zufall).
  - `fg_music_set` mit Überblendung, Lautstärken, Ton im Hintergrund
  - Musikabsenkung: in der Pause auf 45 %; solange eine Bossgefahr in der Warnphase ist, weich auf 72 % (`danger_duck`), damit Warntöne herausstechen ([[Bosse]]).
- Dateien: `sounds/` (registriert), `Audio/` (Quellen). Ambience: `amb_fg_swamp`, `amb_fg_ruins`.

## Abhängigkeiten
[[Level & Welten]] (Musik und Ambience je Level) · [[Speichern & Einstellungen]] · [[UI, HUD & Menüs]]

## Bekannte Probleme
- Die Klänge sind programmatisch synthetisierte Prototypen; kein Hörtest.
- Lautstärken werden nicht gespeichert, nur „Ton im Hintergrund“ ([[Bugs & Ideen]]).
