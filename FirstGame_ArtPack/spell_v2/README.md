# Zaubersystem 2.0 – editierbare Quellen

Alle 36 Fähigkeiten sind integriert; Definitionen in `catalog.json`, erzeugt aus `tests/tools/build_spell_v2_catalog.py`. Ausführliche Werte: `SPELL_CATALOG.md` im Projektstamm.

`sources/icons.png` und `sources/effects.png` sind tatsächlich generierte Rasterquellen; `prompts.json` bewahrt die Aufträge. `frames` enthält 36 zugeschnittene Icons und 24 transparente Effektframes. Bearbeiten/Zuschneiden: `tests/tools/prepare_spell_v2_art.ps1`; Ressourcenimport: `tests/tools/import_spell_v2.py`. Der Import registriert echte Dateien und benötigt keine alten Grafikfallbacks.

`character_before` bewahrt die Originale der 20 reparierten Charakterframes; `clean_characters` enthält die bereinigten Gegenstücke. Protokoll: `tests/reports/spell-v2-character-edges.json`. Die konservative Reparatur erhält zusammenhängende Konturen und echte farbige Effekte.

Audiokomposition ist separat unter `Audio/Sources/compose_spell_v2.py` editierbar. Die 18 neuen Fähigkeits-WAVs sind Synthese-Prototypen mit ausstehender Hörabnahme. Es wurde keine kostenpflichtige API verwendet.
