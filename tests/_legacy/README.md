# Archivierte Tests (nicht mehr in Benutzung)

Am 2026-11-26 aus `tests/` hierher verschoben, nichts gelöscht. Kein Runner und keine QA-Stufe verwendet diese Dateien.

| Datei | Grund |
|---|---|
| `atmosphere_harness.gml`, `audio_harness.gml`, `dragon_harness.gml`, `gameplay_harness.gml`, `spell_harness.gml`, `survivor_harness.gml` | Von keinem Runner referenziert; verweisen zum Teil auf gelöschte ArtPack-0.1-Sprites. |
| `combat_harness.gml`, `spell_v2_harness.gml`, `run_combat_smoke.py` | Absturz 0xC0000005 seit 2026-11-24; baute in `output/`. Abgedeckt durch die Suiten `regression`, `feature` und `classes`. |
| `player_smoke_harness.gml`, `run_player_animation_legacy.py` | Figurenanimation vor den v3-Figuren. Abgedeckt durch die Suite `visual`. |
| `run_boss_v2_smoke.py` | Doppelt: `tests/boss_v2_harness.gml` läuft in der Suite `regression` mit (bleibt in `tests/`). |

Die Pfade in den Runnern sind nicht angepasst. Wer etwas wiederbeleben will, verschiebt es zurück und prüft es gegen den aktuellen Code.
