# FirstGame – Zauberkatalog 2.0

Stand: 22.11.2026. Alle 18 aktiven und 18 passiven Fähigkeiten sind implementiert. Maximal sechs aktive und sechs passive Slots; jede Fähigkeit Stufe 1–9. Die Klassenwaffe belegt keinen Slot.

## Bearbeiten und regenerieren

Zentrale Definitionen: `tests/tools/build_spell_v2_catalog.py` → `FirstGame_ArtPack/spell_v2/catalog.json` und `scripts/spell_v2_catalog/spell_v2_catalog.gml`. Danach dieses Dokument mit `python tests/tools/write_spell_v2_catalog.py` regenerieren. Ausführung: `scripts/spell_v2`, ältere sechs Zauber zusätzlich `scripts/cast_spell`; Modifikatoren: `scripts/apply_passives`. UI und Ausführung lesen denselben Katalog.

## Gemeinsame Regeln

Basiswerte unten: Power 2, keine Passiven. Schaden/Heilung je direktem Treffer beziehungsweise Puls, keine DPS-Summen. Formel: round(Basis × (1 + 0,16 × (Stufe−1)) + Power × Skalierung). Cooldown in Frames = max(18, round(Basis × (1−0,012 × (Stufe−1)) × CDR)); Anzeige bei 60 Hz. Radien steigen, soweit vorhanden, um vier Pixel pro Stufe und werden durch Wide Glyphs multipliziert. Statuszeiten werden durch Lingering Hex, Kälte zusätzlich durch Winter Heart verlängert. Flächenschaden kann mehrere Ziele treffen; tatsächliche Run-Summen werden getrennt erfasst.

Neue Mehrfacheffekte haben 3/4/5 Klingen, Spitzen, Einschläge oder Folgesplitter auf Stufe 1/5/9. Barrage hat 3/4/5 Grundprojektile. Lightning hat 3/4/5 Kettenziele ab Stufe 1/4/7; Storm Conductor ergänzt auf 5 und 9 je eines. Jeder Zauber besitzt neun echte numerische Upgrades einschließlich Stufe 1.

## Aktive Fähigkeiten

### 101: Fireball — IMPLEMENTIERT

Explodiert am Projektilkopf und entzuendet Gegner im Radius.

Mechanik `projectile`; Icon `icon_v2_101`; eigene WAV `Audio/Spells/skill_101.wav` (Synthese-Prototyp).

| Stufe | Schaden / Heilung | Cooldown (s) | Radius (px) | Projektile / Stufen / Kettenziele |
|---|---|---|---|---|
| 1 | 21 | 1.75 | 64 | — |
| 2 | 23 | 1.73 | 68 | — |
| 3 | 26 | 1.70 | 72 | — |
| 4 | 29 | 1.68 | 76 | — |
| 5 | 32 | 1.67 | 80 | — |
| 6 | 35 | 1.65 | 84 | — |
| 7 | 38 | 1.62 | 88 | — |
| 8 | 41 | 1.60 | 92 | — |
| 9 | 44 | 1.58 | 96 | — |

Explosion am Projektilkopf; Brennen 1 Schaden/s für 1 s, stärkster laufender Brand bleibt zuständig.

### 102: Iceball — IMPLEMENTIERT

Ein schneller Eissplitter verletzt und verlangsamt sein Ziel.

Mechanik `projectile`; Icon `icon_v2_102`; eigene WAV `Audio/Spells/skill_102.wav` (Synthese-Prototyp).

| Stufe | Schaden / Heilung | Cooldown (s) | Radius (px) | Projektile / Stufen / Kettenziele |
|---|---|---|---|---|
| 1 | 17 | 1.60 | — | — |
| 2 | 19 | 1.58 | — | — |
| 3 | 22 | 1.57 | — | — |
| 4 | 24 | 1.55 | — | — |
| 5 | 27 | 1.52 | — | — |
| 6 | 29 | 1.50 | — | — |
| 7 | 31 | 1.48 | — | — |
| 8 | 34 | 1.47 | — | — |
| 9 | 36 | 1.45 | — | — |

Verlangsamungsfaktor 0,5 für 1 s.

### 103: Lightning — IMPLEMENTIERT

Ein Einschlag verzweigt sich durch mehrere verschiedene Gegner.

Mechanik `chain`; Icon `icon_v2_103`; eigene WAV `Audio/Spells/skill_103.wav` (Synthese-Prototyp).

| Stufe | Schaden / Heilung | Cooldown (s) | Radius (px) | Projektile / Stufen / Kettenziele |
|---|---|---|---|---|
| 1 | 20 | 2.10 | — | 3 |
| 2 | 23 | 2.07 | — | 3 |
| 3 | 26 | 2.05 | — | 3 |
| 4 | 29 | 2.02 | — | 4 |
| 5 | 32 | 2.00 | — | 4 |
| 6 | 34 | 1.97 | — | 4 |
| 7 | 37 | 1.95 | — | 5 |
| 8 | 40 | 1.92 | — | 5 |
| 9 | 43 | 1.90 | — | 5 |

Sprungreichweite 160–192 px; Schock 24 Frames.

### 104: Frost Nova — IMPLEMENTIERT

Ein Frostkreis verletzt und verlangsamt Gegner um den Helden.

Mechanik `nova`; Icon `icon_v2_104`; eigene WAV `Audio/Spells/skill_104.wav` (Synthese-Prototyp).

| Stufe | Schaden / Heilung | Cooldown (s) | Radius (px) | Projektile / Stufen / Kettenziele |
|---|---|---|---|---|
| 1 | 13 | 4.00 | 130 | — |
| 2 | 15 | 3.95 | 134 | — |
| 3 | 17 | 3.90 | 138 | — |
| 4 | 19 | 3.85 | 142 | — |
| 5 | 21 | 3.80 | 146 | — |
| 6 | 23 | 3.77 | 150 | — |
| 7 | 25 | 3.72 | 154 | — |
| 8 | 26 | 3.67 | 158 | — |
| 9 | 28 | 3.62 | 162 | — |

Verlangsamungsfaktor 0,4 für 1,5 s.

### 105: Arcane Barrage — IMPLEMENTIERT

Ein Faecher aus arkanen Geschossen mit eigenstaendigen Treffern.

Mechanik `projectile`; Icon `icon_v2_105`; eigene WAV `Audio/Spells/skill_105.wav` (Synthese-Prototyp).

| Stufe | Schaden / Heilung | Cooldown (s) | Radius (px) | Projektile / Stufen / Kettenziele |
|---|---|---|---|---|
| 1 | 12 | 2.40 | — | 3 |
| 2 | 14 | 2.37 | — | 3 |
| 3 | 15 | 2.35 | — | 3 |
| 4 | 17 | 2.32 | — | 3 |
| 5 | 18 | 2.28 | — | 4 |
| 6 | 20 | 2.25 | — | 4 |
| 7 | 22 | 2.23 | — | 4 |
| 8 | 23 | 2.20 | — | 4 |
| 9 | 25 | 2.17 | — | 5 |

Fächer aus getrennt treffenden Projektilen; Split Runes addiert Geschosse und flachen Projektilschaden.

### 106: Healing Pulse — IMPLEMENTIERT

Ein gruener Impuls stellt tatsaechlich fehlende Lebenspunkte wieder her.

Mechanik `heal`; Icon `icon_v2_106`; eigene WAV `Audio/Spells/skill_106.wav` (Synthese-Prototyp).

| Stufe | Schaden / Heilung | Cooldown (s) | Radius (px) | Projektile / Stufen / Kettenziele |
|---|---|---|---|---|
| 1 | 19 | 8.00 | 62 | — |
| 2 | 22 | 7.90 | 66 | — |
| 3 | 25 | 7.80 | 70 | — |
| 4 | 28 | 7.72 | 74 | — |
| 5 | 31 | 7.62 | 78 | — |
| 6 | 33 | 7.52 | 82 | — |
| 7 | 36 | 7.42 | 86 | — |
| 8 | 39 | 7.33 | 90 | — |
| 9 | 42 | 7.23 | 94 | — |

Heilt ausschließlich fehlendes Leben. Die tatsächliche Heilung kann niedriger sein.

### 107: Ember Field — IMPLEMENTIERT

Eine brennende Bodenrune pulsiert drei Sekunden lang gegen Gegner in ihrem Bereich.

Mechanik `field`; Icon `icon_v2_107`; eigene WAV `Audio/Spells/skill_107.wav` (Synthese-Prototyp).

| Stufe | Schaden / Heilung | Cooldown (s) | Radius (px) | Projektile / Stufen / Kettenziele |
|---|---|---|---|---|
| 1 | 10 | 5.00 | 100 | — |
| 2 | 11 | 4.93 | 104 | — |
| 3 | 13 | 4.88 | 108 | — |
| 4 | 14 | 4.82 | 112 | — |
| 5 | 15 | 4.77 | 116 | — |
| 6 | 16 | 4.70 | 120 | — |
| 7 | 18 | 4.63 | 124 | — |
| 8 | 19 | 4.58 | 128 | — |
| 9 | 20 | 4.52 | 132 | — |

Bodenfeld 3,0–3,8 s; Schaden alle 0,5 s; Brennen 1,2–2,8/s für 1 s.

### 108: Piercing Lance — IMPLEMENTIERT

Eine gerade magische Lanze durchdringt alle Gegner entlang ihrer Flugbahn.

Mechanik `lance`; Icon `icon_v2_108`; eigene WAV `Audio/Spells/skill_108.wav` (Synthese-Prototyp).

| Stufe | Schaden / Heilung | Cooldown (s) | Radius (px) | Projektile / Stufen / Kettenziele |
|---|---|---|---|---|
| 1 | 27 | 3.50 | 22 | — |
| 2 | 31 | 3.45 | 26 | — |
| 3 | 35 | 3.42 | 30 | — |
| 4 | 39 | 3.37 | 34 | — |
| 5 | 43 | 3.33 | 38 | — |
| 6 | 47 | 3.28 | 42 | — |
| 7 | 51 | 3.25 | 46 | — |
| 8 | 55 | 3.20 | 50 | — |
| 9 | 59 | 3.17 | 54 | — |

Sofortige Linie, 650 px Reichweite; Radius in der Tabelle ist die halbe Linienbreite.

### 109: Orbit Blades — IMPLEMENTIERT

Drei Klingen kreisen drei Sekunden um den Helden. Jedes Ziel hat eine Trefferschranke.

Mechanik `orbit`; Icon `icon_v2_109`; eigene WAV `Audio/Spells/skill_109.wav` (Synthese-Prototyp).

| Stufe | Schaden / Heilung | Cooldown (s) | Radius (px) | Projektile / Stufen / Kettenziele |
|---|---|---|---|---|
| 1 | 12 | 6.00 | 95 | 3 |
| 2 | 14 | 5.93 | 99 | 3 |
| 3 | 15 | 5.85 | 103 | 3 |
| 4 | 17 | 5.78 | 107 | 3 |
| 5 | 18 | 5.72 | 111 | 4 |
| 6 | 20 | 5.63 | 115 | 4 |
| 7 | 22 | 5.57 | 119 | 4 |
| 8 | 23 | 5.50 | 123 | 4 |
| 9 | 25 | 5.42 | 127 | 5 |

Klingenorbit 3,0–3,8 s; Kontaktprüfung alle 0,42 s.

### 110: Stone Spikes — IMPLEMENTIERT

Drei angekuendigte Steinspitzen brechen nacheinander entlang der Zielrichtung hervor.

Mechanik `spikes`; Icon `icon_v2_110`; eigene WAV `Audio/Spells/skill_110.wav` (Synthese-Prototyp).

| Stufe | Schaden / Heilung | Cooldown (s) | Radius (px) | Projektile / Stufen / Kettenziele |
|---|---|---|---|---|
| 1 | 24 | 4.75 | 62 | 3 |
| 2 | 28 | 4.70 | 66 | 3 |
| 3 | 31 | 4.63 | 70 | 3 |
| 4 | 35 | 4.58 | 74 | 3 |
| 5 | 38 | 4.52 | 78 | 4 |
| 6 | 42 | 4.47 | 82 | 4 |
| 7 | 45 | 4.40 | 86 | 4 |
| 8 | 49 | 4.35 | 90 | 4 |
| 9 | 52 | 4.30 | 94 | 5 |

Erster Einschlag nach 0,28 s, weitere im Abstand 0,35 s; Linie entlang der Zielrichtung.

### 111: Wisp Sentinel — IMPLEMENTIERT

Ein beschworener Lichtgeist begleitet den Helden und beschiesst nahe Gegner.

Mechanik `summon`; Icon `icon_v2_111`; eigene WAV `Audio/Spells/skill_111.wav` (Synthese-Prototyp).

| Stufe | Schaden / Heilung | Cooldown (s) | Radius (px) | Projektile / Stufen / Kettenziele |
|---|---|---|---|---|
| 1 | 14 | 7.00 | 265 | — |
| 2 | 16 | 6.92 | 269 | — |
| 3 | 18 | 6.83 | 273 | — |
| 4 | 20 | 6.75 | 277 | — |
| 5 | 22 | 6.67 | 281 | — |
| 6 | 24 | 6.58 | 285 | — |
| 7 | 26 | 6.50 | 289 | — |
| 8 | 27 | 6.42 | 293 | — |
| 9 | 29 | 6.33 | 297 | — |

Geist 5,0–5,8 s; Zielradius 265–297 px; Angriffsintervall 0,625–0,425 s.

### 112: Thunder Seal — IMPLEMENTIERT

Eine elektrische Rune laedt sich auf und entlaedt sich nach einer Sekunde.

Mechanik `seal`; Icon `icon_v2_112`; eigene WAV `Audio/Spells/skill_112.wav` (Synthese-Prototyp).

| Stufe | Schaden / Heilung | Cooldown (s) | Radius (px) | Projektile / Stufen / Kettenziele |
|---|---|---|---|---|
| 1 | 50 | 6.50 | 125 | — |
| 2 | 58 | 6.42 | 129 | — |
| 3 | 65 | 6.35 | 133 | — |
| 4 | 73 | 6.27 | 137 | — |
| 5 | 81 | 6.18 | 141 | — |
| 6 | 88 | 6.12 | 145 | — |
| 7 | 96 | 6.03 | 149 | — |
| 8 | 104 | 5.95 | 153 | — |
| 9 | 111 | 5.88 | 157 | — |

Einmalige Entladung nach 0,9 s; Schock 35 Frames.

### 113: Starfall — IMPLEMENTIERT

Drei zeitversetzte Sternsplitter schlagen auf erfasste Gegnerpositionen ein.

Mechanik `meteor`; Icon `icon_v2_113`; eigene WAV `Audio/Spells/skill_113.wav` (Synthese-Prototyp).

| Stufe | Schaden / Heilung | Cooldown (s) | Radius (px) | Projektile / Stufen / Kettenziele |
|---|---|---|---|---|
| 1 | 34 | 7.50 | 80 | 3 |
| 2 | 39 | 7.42 | 84 | 3 |
| 3 | 44 | 7.32 | 88 | 3 |
| 4 | 49 | 7.23 | 92 | 3 |
| 5 | 54 | 7.13 | 96 | 4 |
| 6 | 60 | 7.05 | 100 | 4 |
| 7 | 65 | 6.97 | 104 | 4 |
| 8 | 70 | 6.87 | 108 | 4 |
| 9 | 75 | 6.78 | 112 | 5 |

Erster Einschlag nach 0,28 s, weitere alle 0,35 s; versetzte Positionen.

### 114: Gravity Well — IMPLEMENTIERT

Ein Wirbel zieht normale Gegner an und verursacht periodischen Schaden. Bosse widerstehen dem Zug.

Mechanik `gravity`; Icon `icon_v2_114`; eigene WAV `Audio/Spells/skill_114.wav` (Synthese-Prototyp).

| Stufe | Schaden / Heilung | Cooldown (s) | Radius (px) | Projektile / Stufen / Kettenziele |
|---|---|---|---|---|
| 1 | 7 | 7.00 | 145 | — |
| 2 | 8 | 6.92 | 149 | — |
| 3 | 9 | 6.83 | 153 | — |
| 4 | 9 | 6.75 | 157 | — |
| 5 | 10 | 6.67 | 161 | — |
| 6 | 11 | 6.58 | 165 | — |
| 7 | 12 | 6.50 | 169 | — |
| 8 | 13 | 6.42 | 173 | — |
| 9 | 13 | 6.33 | 177 | — |

Feld 3,5–4,3 s; Puls alle 0,5 s; Zug bis 100 px/s nur auf normale Gegner, respektiert Säulen.

### 115: Ice Prison — IMPLEMENTIERT

Ein Frostgefaengnis haelt normale Gegner kurz fest und verlangsamt alle Getroffenen.

Mechanik `prison`; Icon `icon_v2_115`; eigene WAV `Audio/Spells/skill_115.wav` (Synthese-Prototyp).

| Stufe | Schaden / Heilung | Cooldown (s) | Radius (px) | Projektile / Stufen / Kettenziele |
|---|---|---|---|---|
| 1 | 18 | 6.00 | 150 | — |
| 2 | 21 | 5.93 | 154 | — |
| 3 | 23 | 5.85 | 158 | — |
| 4 | 26 | 5.78 | 162 | — |
| 5 | 28 | 5.72 | 166 | — |
| 6 | 31 | 5.63 | 170 | — |
| 7 | 33 | 5.57 | 174 | — |
| 8 | 36 | 5.50 | 178 | — |
| 9 | 38 | 5.42 | 182 | — |

Feld 1,8–2,6 s; Puls alle 0,5 s; normale Gegner 0,18 s festhalten. Slowfaktor 0,45 für 65–105 Frames; Bosse werden nicht festgehalten.

### 116: Returning Glaive — IMPLEMENTIERT

Eine Klinge trifft beim Hinflug und nochmals auf dem Rueckweg zur aktuellen Heldenposition.

Mechanik `glaive`; Icon `icon_v2_116`; eigene WAV `Audio/Spells/skill_116.wav` (Synthese-Prototyp).

| Stufe | Schaden / Heilung | Cooldown (s) | Radius (px) | Projektile / Stufen / Kettenziele |
|---|---|---|---|---|
| 1 | 22 | 4.50 | 24 | — |
| 2 | 25 | 4.45 | 28 | — |
| 3 | 28 | 4.40 | 32 | — |
| 4 | 32 | 4.33 | 36 | — |
| 5 | 35 | 4.28 | 40 | — |
| 6 | 38 | 4.23 | 44 | — |
| 7 | 41 | 4.18 | 48 | — |
| 8 | 44 | 4.12 | 52 | — |
| 9 | 48 | 4.07 | 56 | — |

Hinweg 0,55 s und Rückweg 0,55 s zur aktuellen Spielerposition; pro Gegner höchstens ein Treffer je Weg.

### 117: Prismatic Seed — IMPLEMENTIERT

Ein reisender Kern zerbricht am Ziel und verteilt zielsuchende Energiesplitter.

Mechanik `seed`; Icon `icon_v2_117`; eigene WAV `Audio/Spells/skill_117.wav` (Synthese-Prototyp).

| Stufe | Schaden / Heilung | Cooldown (s) | Radius (px) | Projektile / Stufen / Kettenziele |
|---|---|---|---|---|
| 1 | 20 | 5.00 | 105 | 3 |
| 2 | 23 | 4.93 | 109 | 3 |
| 3 | 26 | 4.88 | 113 | 3 |
| 4 | 29 | 4.82 | 117 | 3 |
| 5 | 32 | 4.77 | 121 | 4 |
| 6 | 34 | 4.70 | 125 | 4 |
| 7 | 37 | 4.63 | 129 | 4 |
| 8 | 40 | 4.58 | 133 | 4 |
| 9 | 43 | 4.52 | 137 | 5 |

Reisender Kern bis 2 s; Explosion und 65%-Folgetreffer an maximal 3–5 ausgewählten Zielen.

### 118: Solar Verdict — IMPLEMENTIERT

Ein langsam aufladender Sonnenstrahl entfesselt eine besonders starke Flaechenexplosion.

Mechanik `verdict`; Icon `icon_v2_118`; eigene WAV `Audio/Spells/skill_118.wav` (Synthese-Prototyp).

| Stufe | Schaden / Heilung | Cooldown (s) | Radius (px) | Projektile / Stufen / Kettenziele |
|---|---|---|---|---|
| 1 | 86 | 13.00 | 230 | — |
| 2 | 99 | 12.85 | 234 | — |
| 3 | 113 | 12.68 | 238 | — |
| 4 | 126 | 12.53 | 242 | — |
| 5 | 140 | 12.38 | 246 | — |
| 6 | 153 | 12.22 | 250 | — |
| 7 | 167 | 12.07 | 254 | — |
| 8 | 180 | 11.90 | 258 | — |
| 9 | 194 | 11.75 | 262 | — |

Große Explosion nach 0,72 s; goldene Säule und Lichtimpuls.

## Passive Fähigkeiten

Die folgenden Werte gelten kumulativ je aktueller Stufe. Wiederholtes Anwenden stapelt den gleichen Bonus nicht erneut. Passiver Verstärkerschaden wird nicht als erfundener eigener Angriff gezählt.

### 201: Orbit Shield — IMPLEMENTIERT

Kreisschild mit eigenem Trefferschaden. Schadensreduktion bis 60%; Orbit-Schaden steigt auf jeder Stufe.

Icon `icon_v2_201`. Kein eigener Cast-Cue; Auswahl/Upgrade verwendet die zentralen UI-Ereignisse.

| Stufe | Gesamte Wirkung |
|---|---|
| 1 | 10% Reduktion; 3 Orbit-Schaden |
| 2 | 20% Reduktion; 4 Orbit-Schaden |
| 3 | 30% Reduktion; 5 Orbit-Schaden |
| 4 | 40% Reduktion; 6 Orbit-Schaden |
| 5 | 50% Reduktion; 7 Orbit-Schaden |
| 6 | 60% Reduktion; 8 Orbit-Schaden |
| 7 | 60% Reduktion; 9 Orbit-Schaden |
| 8 | 60% Reduktion; 10 Orbit-Schaden |
| 9 | 60% Reduktion; 11 Orbit-Schaden |

### 202: Power Up — IMPLEMENTIERT

Additive Power fuer Klassenwaffe, direkte Zauber und Heilung. Kein erfundener eigener Schaden.

Icon `icon_v2_202`. Kein eigener Cast-Cue; Auswahl/Upgrade verwendet die zentralen UI-Ereignisse.

| Stufe | Gesamte Wirkung |
|---|---|
| 1 | +2 Power |
| 2 | +4 Power |
| 3 | +6 Power |
| 4 | +8 Power |
| 5 | +10 Power |
| 6 | +12 Power |
| 7 | +14 Power |
| 8 | +16 Power |
| 9 | +18 Power |

### 203: Fleet Footed — IMPLEMENTIERT

Erhoeht das Bodentempo und die gerichtete Sprungbewegung additiv um 0.12 pro Stufe.

Icon `icon_v2_203`. Kein eigener Cast-Cue; Auswahl/Upgrade verwendet die zentralen UI-Ereignisse.

| Stufe | Gesamte Wirkung |
|---|---|
| 1 | +0.12 Bodentempo |
| 2 | +0.24 Bodentempo |
| 3 | +0.36 Bodentempo |
| 4 | +0.48 Bodentempo |
| 5 | +0.6 Bodentempo |
| 6 | +0.72 Bodentempo |
| 7 | +0.84 Bodentempo |
| 8 | +0.96 Bodentempo |
| 9 | +1.08 Bodentempo |

### 204: Quick Hands — IMPLEMENTIERT

Erhoeht ausschliesslich die Angriffsgeschwindigkeit der Klassenwaffe um 5% pro Stufe.

Icon `icon_v2_204`. Kein eigener Cast-Cue; Auswahl/Upgrade verwendet die zentralen UI-Ereignisse.

| Stufe | Gesamte Wirkung |
|---|---|
| 1 | 5% Waffenhaste |
| 2 | 10% Waffenhaste |
| 3 | 15% Waffenhaste |
| 4 | 20% Waffenhaste |
| 5 | 25% Waffenhaste |
| 6 | 30% Waffenhaste |
| 7 | 35% Waffenhaste |
| 8 | 40% Waffenhaste |
| 9 | 45% Waffenhaste |

### 205: Vitality — IMPLEMENTIERT

Erhoeht das Lebensmaximum um 12 pro Stufe und heilt genau den neu hinzugekommenen Betrag.

Icon `icon_v2_205`. Kein eigener Cast-Cue; Auswahl/Upgrade verwendet die zentralen UI-Ereignisse.

| Stufe | Gesamte Wirkung |
|---|---|
| 1 | +12 maximale HP |
| 2 | +24 maximale HP |
| 3 | +36 maximale HP |
| 4 | +48 maximale HP |
| 5 | +60 maximale HP |
| 6 | +72 maximale HP |
| 7 | +84 maximale HP |
| 8 | +96 maximale HP |
| 9 | +108 maximale HP |

### 206: Split Runes — IMPLEMENTIERT

Fireball, Iceball und Barrage: Zusatzgeschoss auf Stufe 1/4/7. Ein Punkt Projektilschaden je Stufe gilt auch fuer die Klassenwaffen, deren feste Kombofolge erhalten bleibt.

Icon `icon_v2_206`. Kein eigener Cast-Cue; Auswahl/Upgrade verwendet die zentralen UI-Ereignisse.

| Stufe | Gesamte Wirkung |
|---|---|
| 1 | 1 Zusatzprojektile; +1 Projektilschaden |
| 2 | 1 Zusatzprojektile; +2 Projektilschaden |
| 3 | 1 Zusatzprojektile; +3 Projektilschaden |
| 4 | 2 Zusatzprojektile; +4 Projektilschaden |
| 5 | 2 Zusatzprojektile; +5 Projektilschaden |
| 6 | 2 Zusatzprojektile; +6 Projektilschaden |
| 7 | 3 Zusatzprojektile; +7 Projektilschaden |
| 8 | 3 Zusatzprojektile; +8 Projektilschaden |
| 9 | 3 Zusatzprojektile; +9 Projektilschaden |

### 207: Keen Focus — IMPLEMENTIERT

Direkte Angriffe erhalten 2 Prozentpunkte kritische Trefferchance je Stufe. Kritische Treffer verursachen 160% Schaden.

Icon `icon_v2_207`. Kein eigener Cast-Cue; Auswahl/Upgrade verwendet die zentralen UI-Ereignisse.

| Stufe | Gesamte Wirkung |
|---|---|
| 1 | 2 Prozentpunkte kritische Chance |
| 2 | 4 Prozentpunkte kritische Chance |
| 3 | 6 Prozentpunkte kritische Chance |
| 4 | 8 Prozentpunkte kritische Chance |
| 5 | 10 Prozentpunkte kritische Chance |
| 6 | 12 Prozentpunkte kritische Chance |
| 7 | 14 Prozentpunkte kritische Chance |
| 8 | 16 Prozentpunkte kritische Chance |
| 9 | 18 Prozentpunkte kritische Chance |

### 208: Swift Sigils — IMPLEMENTIERT

Fliegende Projektile bewegen sich 5.5% schneller je Stufe; ihre vorgesehene Reichweite bleibt gleich.

Icon `icon_v2_208`. Kein eigener Cast-Cue; Auswahl/Upgrade verwendet die zentralen UI-Ereignisse.

| Stufe | Gesamte Wirkung |
|---|---|
| 1 | 5.5% Projektiltempo |
| 2 | 11% Projektiltempo |
| 3 | 16.5% Projektiltempo |
| 4 | 22% Projektiltempo |
| 5 | 27.5% Projektiltempo |
| 6 | 33% Projektiltempo |
| 7 | 38.5% Projektiltempo |
| 8 | 44% Projektiltempo |
| 9 | 49.5% Projektiltempo |

### 209: Wide Glyphs — IMPLEMENTIERT

Erweitert Flaechenradien und Schwertreichweite um 3.5% je Stufe. Sichtbare Effekte und Trefferzone skalieren gemeinsam.

Icon `icon_v2_209`. Kein eigener Cast-Cue; Auswahl/Upgrade verwendet die zentralen UI-Ereignisse.

| Stufe | Gesamte Wirkung |
|---|---|
| 1 | 3.5% Radius |
| 2 | 7% Radius |
| 3 | 10.5% Radius |
| 4 | 14% Radius |
| 5 | 17.5% Radius |
| 6 | 21% Radius |
| 7 | 24.5% Radius |
| 8 | 28% Radius |
| 9 | 31.5% Radius |

### 210: Deep Rhythm — IMPLEMENTIERT

Reduziert aktive Zauber-Cooldowns um 3.5% der Basis je Stufe. Klassenwaffe bleibt davon unabhaengig.

Icon `icon_v2_210`. Kein eigener Cast-Cue; Auswahl/Upgrade verwendet die zentralen UI-Ereignisse.

| Stufe | Gesamte Wirkung |
|---|---|
| 1 | 3.5% Cooldown-Reduktion |
| 2 | 7% Cooldown-Reduktion |
| 3 | 10.5% Cooldown-Reduktion |
| 4 | 14% Cooldown-Reduktion |
| 5 | 17.5% Cooldown-Reduktion |
| 6 | 21% Cooldown-Reduktion |
| 7 | 24.5% Cooldown-Reduktion |
| 8 | 28% Cooldown-Reduktion |
| 9 | 31.5% Cooldown-Reduktion |

### 211: Ember Oath — IMPLEMENTIERT

Verstaerkt direkten Feuerschaden und Brennen um 4.5% je Stufe.

Icon `icon_v2_211`. Kein eigener Cast-Cue; Auswahl/Upgrade verwendet die zentralen UI-Ereignisse.

| Stufe | Gesamte Wirkung |
|---|---|
| 1 | 4.5% Feuerschaden |
| 2 | 9% Feuerschaden |
| 3 | 13.5% Feuerschaden |
| 4 | 18% Feuerschaden |
| 5 | 22.5% Feuerschaden |
| 6 | 27% Feuerschaden |
| 7 | 31.5% Feuerschaden |
| 8 | 36% Feuerschaden |
| 9 | 40.5% Feuerschaden |

### 212: Storm Conductor — IMPLEMENTIERT

Verstaerkt Blitzschaden um 4.5% je Stufe; Kettenblitz erhaelt auf Stufe 5 und 9 einen weiteren Sprung.

Icon `icon_v2_212`. Kein eigener Cast-Cue; Auswahl/Upgrade verwendet die zentralen UI-Ereignisse.

| Stufe | Gesamte Wirkung |
|---|---|
| 1 | +4.5% Blitzschaden; +0 Kettensprünge |
| 2 | +9% Blitzschaden; +0 Kettensprünge |
| 3 | +13.5% Blitzschaden; +0 Kettensprünge |
| 4 | +18% Blitzschaden; +0 Kettensprünge |
| 5 | +22.5% Blitzschaden; +1 Kettensprünge |
| 6 | +27% Blitzschaden; +1 Kettensprünge |
| 7 | +31.5% Blitzschaden; +1 Kettensprünge |
| 8 | +36% Blitzschaden; +1 Kettensprünge |
| 9 | +40.5% Blitzschaden; +2 Kettensprünge |

### 213: Winter Heart — IMPLEMENTIERT

Verstaerkt Eisschaden um 4.5% je Stufe und verlaengert Kaeltewirkungen um 4% je Stufe.

Icon `icon_v2_213`. Kein eigener Cast-Cue; Auswahl/Upgrade verwendet die zentralen UI-Ereignisse.

| Stufe | Gesamte Wirkung |
|---|---|
| 1 | +4.5% Eisschaden; +4% Kältedauer |
| 2 | +9% Eisschaden; +8% Kältedauer |
| 3 | +13.5% Eisschaden; +12% Kältedauer |
| 4 | +18% Eisschaden; +16% Kältedauer |
| 5 | +22.5% Eisschaden; +20% Kältedauer |
| 6 | +27% Eisschaden; +24% Kältedauer |
| 7 | +31.5% Eisschaden; +28% Kältedauer |
| 8 | +36% Eisschaden; +32% Kältedauer |
| 9 | +40.5% Eisschaden; +36% Kältedauer |

### 214: Iron Ward — IMPLEMENTIERT

Verringert einen eingehenden Treffer vor dem Kreisschild um 0.6 Schaden je Stufe, mindestens ein Punkt bleibt.

Icon `icon_v2_214`. Kein eigener Cast-Cue; Auswahl/Upgrade verwendet die zentralen UI-Ereignisse.

| Stufe | Gesamte Wirkung |
|---|---|
| 1 | +0.6 flache Schadensminderung |
| 2 | +1.2 flache Schadensminderung |
| 3 | +1.8 flache Schadensminderung |
| 4 | +2.4 flache Schadensminderung |
| 5 | +3 flache Schadensminderung |
| 6 | +3.6 flache Schadensminderung |
| 7 | +4.2 flache Schadensminderung |
| 8 | +4.8 flache Schadensminderung |
| 9 | +5.4 flache Schadensminderung |

### 215: Renewal — IMPLEMENTIERT

Heilt pro Sekunde 0.12 Lebenspunkte je Stufe, nur tatsaechlich fehlendes Leben wird erfasst.

Icon `icon_v2_215`. Kein eigener Cast-Cue; Auswahl/Upgrade verwendet die zentralen UI-Ereignisse.

| Stufe | Gesamte Wirkung |
|---|---|
| 1 | +0.12 HP/s Regeneration |
| 2 | +0.24 HP/s Regeneration |
| 3 | +0.36 HP/s Regeneration |
| 4 | +0.48 HP/s Regeneration |
| 5 | +0.6 HP/s Regeneration |
| 6 | +0.72 HP/s Regeneration |
| 7 | +0.84 HP/s Regeneration |
| 8 | +0.96 HP/s Regeneration |
| 9 | +1.08 HP/s Regeneration |

### 216: Scavenger — IMPLEMENTIERT

Vergroessert den normalen Muenz-Sammelradius um 12 Pixel je Stufe. Aktiviert keine Magnet-Orbs aus der Ferne.

Icon `icon_v2_216`. Kein eigener Cast-Cue; Auswahl/Upgrade verwendet die zentralen UI-Ereignisse.

| Stufe | Gesamte Wirkung |
|---|---|
| 1 | 108 px Sammelradius |
| 2 | 120 px Sammelradius |
| 3 | 132 px Sammelradius |
| 4 | 144 px Sammelradius |
| 5 | 156 px Sammelradius |
| 6 | 168 px Sammelradius |
| 7 | 180 px Sammelradius |
| 8 | 192 px Sammelradius |
| 9 | 204 px Sammelradius |

### 217: Lingering Hex — IMPLEMENTIERT

Verlaengert Brennen, Schock und Verlangsamung um 8% je Stufe. Boss-Festhalten bleibt ausgeschlossen.

Icon `icon_v2_217`. Kein eigener Cast-Cue; Auswahl/Upgrade verwendet die zentralen UI-Ereignisse.

| Stufe | Gesamte Wirkung |
|---|---|
| 1 | 8% Statusdauer |
| 2 | 16% Statusdauer |
| 3 | 24% Statusdauer |
| 4 | 32% Statusdauer |
| 5 | 40% Statusdauer |
| 6 | 48% Statusdauer |
| 7 | 56% Statusdauer |
| 8 | 64% Statusdauer |
| 9 | 72% Statusdauer |

### 218: Resonant Core — IMPLEMENTIERT

Direkte Treffer verursachen 2.5% mehr Schaden je Stufe gegen bereits brennende, geschockte oder verlangsamte Ziele.

Icon `icon_v2_218`. Kein eigener Cast-Cue; Auswahl/Upgrade verwendet die zentralen UI-Ereignisse.

| Stufe | Gesamte Wirkung |
|---|---|
| 1 | 2.5% Schaden gegen beeinträchtigte Ziele |
| 2 | 5% Schaden gegen beeinträchtigte Ziele |
| 3 | 7.5% Schaden gegen beeinträchtigte Ziele |
| 4 | 10% Schaden gegen beeinträchtigte Ziele |
| 5 | 12.5% Schaden gegen beeinträchtigte Ziele |
| 6 | 15% Schaden gegen beeinträchtigte Ziele |
| 7 | 17.5% Schaden gegen beeinträchtigte Ziele |
| 8 | 20% Schaden gegen beeinträchtigte Ziele |
| 9 | 22.5% Schaden gegen beeinträchtigte Ziele |

## Nachweise und Grenzen

[Abschlussbericht](SPELL_V2_REPORT.md), native echte HP-/Heilungsprüfungen in `tests/reports/spell-v2-native.json`. Alle aktiven Mechaniken wurden auf 1/9 ausgeführt; Zwischenstufen und passive Neuberechnung zusätzlich geprüft. Diese technischen Nachweise ersetzen keine menschliche Langzeit-Balance- oder Hörabnahme.
