---
tags: [design, verbindlich, assets, pipeline, struktur]
updated: 2026-11-25
status: verbindlich (Fachgebiet Asset-Organisation, Namen, Arbeitsablauf)
---
# Assets & Pipeline

Rang 2 unter [[Leitbild]].

## 1. Begriffe

| Begriff | Bedeutung | Beispiel |
|---|---|---|
| **Quelle** | Original, aus dem etwas erzeugt wird. Wird nie verändert. | `FirstGame_ArtPack/class_overhaul/sources/*.png`, Drachen-PNGs |
| **Referenz** | Vorbild oder Konzepttafel, wird nicht ins Spiel importiert | `FirstGame_ArtPack/references/*` |
| **Generiert** | Von einem Werkzeug erzeugtes Zwischen- oder Endprodukt, jederzeit neu erzeugbar | `FirstGame_ArtPack/character_layers/preview_*.png`, `scripts/equipment_visual_data` |
| **GameMaker-Ressource** | registriert in `FirstGame.yyp`, liegt in `sprites/`, `sounds/`, `scripts/` usw. | `sprites/spr_fg_magev3_walk_down/` |
| **Legacy** | Früherer Stand, im Spiel nicht mehr erreichbar, als Nachweis aufbewahrt | ArtPack-0.1-Helden |
| **Temporär** | Testkopien, Builds, Logs. Gehört nicht ins Repo. | `%LOCALAPPDATA%\FirstGame-Tests\`, `output/` |

## 2. Bestand (Audit 25.11.2026)

### 2.1 Projektordner

| Ordner | Größe / Dateien | Rolle | Bemerkung |
|---|---|---|---|
| `sprites/` | 147 MB / 9.630 | GameMaker-Ressourcen (1.337 Sprites) | Struktur von GameMaker vorgegeben (`sprites/<name>/`) |
| `FirstGame_ArtPack/` | 188 MB / 2.527 | **Quell-, Referenz- und generierte Grafik** | ursprünglich ein importiertes ZIP (Prototyp 0.1), seitdem wild gewachsen (2.2) |
| `sounds/` | 26 MB / 180 | GameMaker-Ressourcen (90 Klänge) | in der IDE schon nach Audio-Unterordnern sortiert |
| `Audio/` | 26 MB / 105 | Tonquellen und Synthese-Skripte (`Audio/Sources/compose_*.py`) | Quelle |
| `Assets/` | 2 MB / 522 | Kataloge und Altbestand aus der Codex-Zeit | nicht geprüft; ändern nur nach eigenem Audit |
| `tests/` | 76 MB / 288 | Harnesses, Werkzeuge, Berichte | `tests/reports/` enthält Testbilder |
| `QA/` | 240 MB / 6.123 (436 versioniert) | Simulationen, Daten, Berichte | `QA/logs/` ist überwiegend unversioniert |
| `output/` | — | alte Codex-Builds | **am 25.11. gelöscht** (Nutzerfreigabe, 820 MB, war gitignored) |
| `scripts/`, `objects/`, `rooms/`, `tilesets/`, `options/` | klein | GameMaker-Ressourcen | — |

### 2.2 `FirstGame_ArtPack/` je Unterordner

- „im Projekt“ = Anzahl PNGs, die bytegleich als GameMaker-Frame vorkommen.
- „Werkzeuge“ = Skripte, die den Ordner lesen.

| Unterordner | PNGs | im Projekt | Werkzeuge | Einordnung |
|---|---|---|---|---|
| `swordsman_v3` | 388 | 0 | `atlas.py`, `import_swordsman_art.py`, `prepare_swordsman_art.ps1` | **Quelle** des Schwertkämpfers (Originalframes; die Spielframes sind seit 24.11. Basismodelle) |
| `class_overhaul` | 1.021 | 152 | `atlas.py`, `import_class_*`, `prepare_class_*` | **Quelle** Zaubermeisterin, Waldläufer, Klasseneffekte |
| `character_layers` | 3 | 0 | `build_characters.py` | **Generiert** (Vorschauen) |
| `dragon_boss` | 35 | 32 | `import_dragon_art.py`, `prepare_dragon_art.ps1` | **Quelle**, Drache, **nicht verändern** |
| `boss_v2` | 204 | 196 | `import_boss_v2_art.py`, Audits | Quelle Hexen und Behemoth |
| `master_world` | 162 | 157 | `rebuild_master_world.py` u. a. | Quelle Wald und Skelette |
| `level_swamp`, `level_ashfrost`, `level_forest` | 105 / 96 / 2 | 101 / 92 / 0 | `build_level.py`, `update_previews.py` | Quelle bzw. generiert (Level) |
| `level_enemies` | 40 | 0 | `build_enemies.py` | Quelle der Sumpf- und Ruinengegner |
| `spell_v2` | 102 | 96 | `import_spell_v2.py`, `build_spell_v2_catalog.py` | Quelle Zaubericons und Effekte, Katalog `catalog.json` |
| `atmosphere_v2` | 56 | 52 | `import_atmosphere_art.py` | Quelle (Krieger v2, Boss, Magnet) |
| `environment` | 21 | 17 | `finish_art_migration.py` | Quelle Umgebung (frühe Migration) |
| `references` | 9 | 0 | — | **Referenz** (Konzepttafeln, u. a. Zaubermeisterin, Waldläufer, Drachenangriffe) |
| `heroes` | 120 | 0 | — | **Legacy** (ArtPack 0.1, Helden in 4 Richtungen) |
| `monsters`, `monster_originals` | 80 / 16 | 0 / 0 | — | **Legacy bzw. Referenz** (0.1-Gegner; die Projekt-Sprites `spr_fg_<art>_*` stammen daraus und werden von Minibossen noch genutzt) |
| `icons`, `portraits`, `previews`, `effects` | 8 / 5 / 4 / 1 | 0 | — | **Legacy** bzw. Menü-Altbestand |
| lose Dateien im Wurzelordner | 5 PNG | — | `audit_class_dragon.py` | **Referenz**: zwei sind Duplikate der Referenzen unter anderem Namen (`CLASS_DRAGON_REPORT.md`), zwei sind unbekannter Zweck |

### 2.3 GameMaker-Ressourcen
- **Bestand:** 1.337 Sprites, 44 Skripte, 21 Objekte, 90 Klänge.
- **Texturgruppen:** `Default`, `Level_Swamp`, `Level_Ashfrost`, `Equipment`.
- **Legacy im Projekt:** Die 164 Sprites der ArtPack-0.1-Helden (`spr_fg_warrior_*`, `spr_fg_mage_*`, `spr_fg_ranger_*`, `spr_fg_knightv2_*`) wurden am 25.11. gelöscht (Nutzerfreigabe; kein Codepfad nutzte sie). Ihre Quellen liegen weiter unter `FirstGame_ArtPack/heroes/`.
- **Bestand danach:** 1.173 Sprites.
- **Stilbruch im Spiel:** 80 Sprites der 0.1-Gegnerstreifen (`spr_fg_<art>_*`, 64×64, ohne Blickrichtungen) werden von den Minibossen (Eber, Golem) und von Ersatz-Spawns genutzt.

## 3. Umgesetzt am 25.11.2026: IDE-Ressourcenbaum nach Kategorien

**Vorher:** 1.108 Sprites lagen flach im IDE-Ordner „FirstGame_ArtPack“, 54 in „Boss_System_2“, dazu leere Altordner (Adventurer, Monster, Coin …). Alle 44 Skripte lagen flach in „Skripte“.

**Jetzt** (nur die virtuelle Ansicht; **keine Datei wurde verschoben**, Code und Build sind unberührt):

```
Sprites/
  Charaktere/   Schwertkaempfer · Zaubermeisterin · Waldlaeufer
  Ausruestung/  Schwertkaempfer · Zaubermeisterin · Waldlaeufer · Icons
  Gegner/       Wald_Skelette · Sumpf_und_Ruinen · ArtPack_0_1_Streifen
  Bosse/        Drache · Zwillingshexen · Sumpfbehemoth · Minibosse
  Effekte/
  Welt/         Wald · Sumpf · Aschenfrost · Allgemein
  UI/           Zauber_Icons · Menue
  Beute/
Skripte/
  Kern_und_Spieler · Kampf_und_Klassen · Zauber · Bosse · Gegner
  Welt_und_Atmosphaere · Fortschritt_und_Ausruestung · Audio
```

- **Werkzeug:** `tests/tools/assets/ide_folders.py`.
  - `--check` zeigt falsch einsortierte Ressourcen.
  - `--apply` sortiert und entfernt leere Sprite- und Skriptordner.
- **Neue Ressourcen** aus `tests/tools/levels/gm_project.py` landen automatisch im passenden Ordner.
- **Ältere Importer** nutzen eigene Vorlagen. Nach einem Lauf `ide_folders.py --apply` ausführen.
- **Neue Namensfamilien** brauchen eine Regel in `ide_folders.py`.

## 4. Zielstruktur für Quell-Assets und Migrationsplan

**Warum noch nicht verschoben:**
- 30+ Werkzeuge (`tests/tools`, `QA/tools`, `Audio/Sources`) lesen feste Pfade unter `FirstGame_ArtPack/`.
- Mehrere Berichte und Notizen verlinken dorthin.
- Ein Verschieben ohne zentrale Pfadtabelle würde Importer still brechen.

**Zielstruktur (Soll):**
```
FirstGame_ArtPack/                 Name bleibt (bekannt bei Nutzer und Agenten)
  README.md                        Index: Ordner, Rolle, Werkzeug, Status
  references/                      Konzepttafeln, Stil- und Bewegungsreferenzen (inkl. der losen Wurzel-PNGs)
  characters/  swordsman_v3/ · class_overhaul/ · character_layers/(generiert)
  enemies/     level_enemies/ · master_world_enemies/
  bosses/      dragon_boss/(unveränderlich) · boss_v2/ · <neue Rigs>/
  vfx/         spell_v2/ · effects/ · <neue Partikel-Atlanten>/
  environment/ environment/ · master_world/ · level_swamp/ · level_ashfrost/ · level_forest/
  ui/          icons/ · portraits/
  _legacy/     heroes/ · monsters/ · monster_originals/ · previews/ · atmosphere_v2/(nach Prüfung)
```

**Migrationsplan (schrittweise, jeder Schritt mit Tests):**
1. **Pfadtabelle:** `tests/tools/assets/art_paths.py` mit einer Konstante je Quellordner. Alle Werkzeuge lesen nur noch diese Tabelle. Prüfung: Suche nach `FirstGame_ArtPack/` außerhalb der Tabelle ergibt null Treffer.
2. **Probelauf:** Importer und Generatoren im Trockenmodus (bzw. in eine Testkopie) gegen die Tabelle laufen lassen. `QA/tools/audit_visual_preservation.py` muss unverändert bleiben.
3. **Verschieben** mit `git mv` in einem eigenen Commit. Nur die Tabelle wird angepasst.
4. **Prüfen:** Static-Suite, ein Importer-Testlauf je Quelle, Visual-Suite. Links in den Notizen werden nachgezogen; historische Berichte bleiben unverändert (historisch).
5. **Legacy:** `_legacy/` bleibt im Repo. Löschen nur auf ausdrücklichen Wunsch.

**Sofort zulässig, ohne Migration:**
- neue Quellen gleich in die Zielstruktur legen und in der Pfadtabelle eintragen;
- das README des ArtPacks aktuell halten.

## 5. Namenskonventionen

| Art | Muster | Beispiel |
|---|---|---|
| Spielerfigur | `spr_fg_<figur>_<aktion>_<richtung>` | `spr_fg_rangerv3_walk_up_left` |
| Ausrüstungsebene | `spr_eqv_<figur>_<teil>[_acc]` | `spr_eqv_magev3_head2_acc` |
| Gegner | `spr_master_skeleton_*` (Wald), `spr_lv_en_<art>_<aktion>_<richtung>` | `spr_lv_en_crawler_walk_down` |
| Bossteile (neu, Rig) | `spr_rig_<boss>_<teil>` | `spr_rig_dragon_tail3` |
| Bosseffekte | `spr_<boss>_fx_<n>` bzw. `spr_bv2_<familie>_fx_<n>` | `spr_bv2_fire_fx_2` |
| VFX-Bausteine (neu) | `spr_vfx_<element>_<baustein>` | `spr_vfx_lightning_spark` |
| UI und Icons | `icon_v2_<zauber-id>`, `spr_ui_<name>` (neu) | `icon_v2_204` |
| Klänge | `sfx_fg_<besitzer>_<ereignis>`, `mus_fg_*`, `amb_fg_*` | `sfx_fg_dragon_tail_swing` |
| Skripte | Präfix je System (`talent_`, `bv2_`, `spell_vfx_` …), siehe `AGENTS.md` | — |

- **Richtungen:** `down`, `down_left`, `down_right`, `left`, `right`, `up`, `up_left`, `up_right`.
- **Aktionen** (Ist bei Spielerfiguren): `idle`, `walk`, `run`, `attack1–4`, `jump`, `fall`, `dive`, `slide`, `dodge`, `hurt`, `death`, `turn`.
- **Neue Übergangsposen** (Soll): `land`, `turn_quick`, `windup_<n>`.

## 6. Arbeitsablauf für neue Grafik, Animationen, Icons und Klänge

1. **Quelle ablegen:** in der Zielstruktur von `FirstGame_ArtPack/` (bzw. `Audio/`), mit kurzer Herkunftsnotiz im README des Ordners: Werkzeug, Prompt oder Vorlage, Datum, Lizenz bzw. eigene Erstellung.
2. **Erzeugen bzw. importieren** nur per Skript (reproduzierbar). Registrierung über `gm_project.py`, Texturgruppe passend wählen, IDE-Ordner kommt automatisch.
3. **Pixeldichte** nach [[Visuelles Leitbild & Animation]] Abschnitt 4: kein nachträgliches Strecken im Code.
4. **Prüfen:**
   - die passende Suite über `python tests/tools/qa.py`;
   - für Grafik zusätzlich Kontaktbögen der Suite `visual` ansehen;
   - Abnahme nach [[Qualitätsstandard]].
5. **Dokumentieren:** Systemnotiz bzw. Designdokument, falls sich Regeln oder Dateien ändern.

**Verboten:**
- Originale (Drachen-PNGs, ArtPack-Quellen) verändern;
- generierte GameMaker-Frames von Hand nachbearbeiten (stattdessen die Quelle bzw. das Werkzeug ändern);
- Grafik ohne Quelle einchecken;
- alte Projektgrafiken als Ersatz verwenden.
