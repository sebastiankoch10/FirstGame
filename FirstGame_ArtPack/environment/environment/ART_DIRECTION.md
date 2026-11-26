# Landschaftserweiterung 2026-11-22

Quelle: eingebautes Imagegen-Werkzeug, ohne CLI/API-Aufruf. Originale für FirstGame; keine übernommenen Nintendo-Grafiken.

- `landscape_source.png`: Originalatlas, 4×4 Zellen; `detail_00.png` bis `detail_15.png`: daraus mit Nearest Neighbor gewonnene 64×64-Einzelbilder.
- Reihen: vier Bäume; Busch, Blütenbusch, zwei Blumen; Fels, Kiesel, Stumpf, Stamm; Ruinensäule, Truhe, Feuerprojektil, Eisprojektil.
- `ground_source.png`: Originalatlas, 4×4 Bodentexturen.
- `ground_tiles_v2.png`: 256×256-Atlas, 32er Raster. Index 0 transparent; 1–8 farblich angeglichene Gräser, 9–12 freigestellte Blumen, 13–16 Erde, 17–32 transparente Wegverbindungen nach N/O/S/W-Bitmaske.
- Verarbeitung: `tests/tools/prepare_artpack.ps1`; Importe und Layouts: `tests/tools/finish_art_migration.py`.
- Die älteren `spr_fg_environment_*.png` sind unbenutzte Copilot-Prototypquellen. Keine aktive Ressource verweist darauf.

Generierungsauftrag für den Objektatlas: originales farbenfrohes GBA-Action-RPG-Pixelart, transparente 4×4-Anordnung, drei Viertel von oben, klar getrennte Bäume, Pflanzen, Felsen, Ruine, Truhe, Feuer- und Eisprojektil, ohne Text oder Bodenflächen.

Generierungsauftrag für Boden: 4×4-Anordnung, acht dezente frische Gras-/Kleevarianten, vier Wildblumenvarianten und vier warme Erdvarianten, flach von oben, ohne Objekte oder Schrift. Die Rohgrafiken wurden anschließend für feste Raster, transparente Details und Wegverbindungen technisch aufbereitet.

Noch nicht separat vorhanden: Blitzanimation, zusätzliche Waffen-/Combo-Effektstreifen. Blitz nutzt den vorhandenen neuen Eisblitz; das Schwert ist Bestandteil der vorhandenen ArtPack-Angriffspose. Kein alter Grafik-Fallback.
