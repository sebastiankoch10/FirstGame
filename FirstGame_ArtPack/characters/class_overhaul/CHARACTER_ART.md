# Mage and Ranger character integration

Source images remain unchanged under `sources`: four generated atlases per character, based on the supplied local reference. Preparation is mechanical alpha cleanup, connected-figure isolation, nearest-neighbour scaling and extraction of the newly authored poses. It is not a crop of the labelled concept board.

Run `powershell -NoProfile -ExecutionPolicy Bypass -File tests/tools/prepare_class_characters.ps1`, then run `python tests/tools/import_class_characters.py` sequentially with other resource importers. The importer reads the current project registry and retains existing resources; the new actors are `magev3` and `rangerv3`.

Each actor has eight authored view directions. Output canvas is 96×96, origin (48,88), with a separate stable gameplay mask. Walking has eight authored frames. Attacks, jump/fall, landing, dive, dodge/slide, hurt and death select the relevant authored poses. Run uses the walk cycle at a faster playback rate; dodge and slide share mobility poses; turn uses the authored octants with gradual runtime facing. Idle has one authored image plus a subtle breathing transform. These shared poses are not presented as additional independently drawn animation frames.

The Ranger combat atlas contains nine generated rows despite the requested eight. The first eight directional rows are selected using image-derived gutter cuts; the ninth extra row is unused. Earlier trial crops were replaced before import. The alpha cutoff removes generated translucent background noise without a global grey-colour filter. Original hair, armour and staff colours remain.

`character-preview.png` shows both actors and several actions in all directions on a dark background. `character-audit.json` records actual output/unique-frame counts and limitations. No old actor sprite is used as a fallback. The existing Sword gameplay and animation selection are preserved. Human art review of all generated octants remains recommended; source reaction views and cloth details are not guaranteed to be perfectly hand-authored-consistent.
