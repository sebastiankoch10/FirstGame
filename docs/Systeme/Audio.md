---
tags: [system, audio]
updated: 2026-11-24
---
# Audio

## Zweck
Musik (Menü, Level, Boss) und Soundeffekte mit zentralem Mixer.

## Wichtige Dateien
- `scripts/audio_manager`:
  - `fg_sfx`: höchstens 16 Stimmen, 2 je Cue
  - `fg_music_set` mit Überblendung, Lautstärken, Ton im Hintergrund
- Dateien: `sounds/` (registriert), `Audio/` (Quellen). Ambience: `amb_fg_swamp`, `amb_fg_ruins`.

## Abhängigkeiten
[[Level & Welten]] (Musik und Ambience je Level) · [[Speichern & Einstellungen]] · [[UI, HUD & Menüs]]

## Bekannte Probleme
- Die Klänge sind programmatisch synthetisierte Prototypen; kein Hörtest.
