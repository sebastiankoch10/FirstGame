---
tags: [system, effekte]
updated: 2026-11-24
---
# Licht, Wetter & Effekte

## Zweck
Multiplikatives Weltlicht, Wetter, Kampf-Feedback, Zauberpartikel.

## Wichtige Dateien
- `scripts/atmosphere`:
  - Lichtoberfläche in halber Auflösung, `light_pulse`, `atmosphere_source` (Budget 72 Quellen)
  - Boss-Navigation und Notfall-Teleport
- `scripts/weather`: Nebel, Regen und Wind je Level.
- `scripts/spell_vfx`: begrenzter Partikelpool (420), Spuren, Feld-Emitter, dauerhafte Zauberlichter.
- `scripts/combat_feedback`: Schadenszahlen, Einschläge, Trefferreaktion.
- `scripts/attack_telegraph`: Warnflächen mit Countdown (zusammen mit [[Bosse]]).

## Abhängigkeiten
[[Zauber & Passiva]] · [[Bosse]] · [[Level & Welten]] · [[Klassen & Startwaffen]]

## Bekannte Probleme
- Partikel nutzen das globale `random()`. Das ändert die Zufallsfolge geseedeter Runs gegenüber älteren Ständen (siehe [[Bugs & Ideen]]).
