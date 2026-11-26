---
tags: [design, verbindlich, assets, pipeline, struktur]
updated: 2026-11-26
status: verbindlich (Fachgebiet Asset-Organisation, Namen, Arbeitsablauf)
---
# Assets & Pipeline

Rang 2 unter [[Leitbild]].

## 1. Begriffe

| Begriff | Bedeutung | Beispiel |
|---|---|---|
| **Quelle** | Original, aus dem etwas erzeugt wird. Wird nie verändert. | `FirstGame_ArtPack/characters/class_overhaul/sources/*.png`, Drachen-PNGs |
| **Referenz** | Vorbild oder Konzepttafel, wird nicht ins Spiel importiert | `FirstGame_ArtPack/references/*` |
| **Generiert** | Von einem Werkzeug erzeugtes Zwischen- oder Endprodukt, jederzeit neu erzeugbar | `FirstGame_ArtPack/characters/character_layers/preview_*.png`, `scripts/equipment_visual_data` |
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
| `swordsman_v3` | 388 | 0 | `atlas.py`, `import_swordsman_art.py`, `prepare_swordsman_art.ps1` | **Quelle** des Schwertkämpfers (Originalframes). Die Spielframes daraus sind die Spielfigur ([[Visuelles Leitbild & Animation]] 5.5a) |
| `class_overhaul` | 1.021 | 152 | `atlas.py`, `import_class_*`, `prepare_class_*` | **Quelle** Zaubermeisterin, Waldläufer, Klasseneffekte |
| `character_layers` | 3 | 0 | `build_characters.py` | **Generiert** (Vorschauen) |
| `dragon_boss` | 35 | 32 | `import_dragon_art.py`, `prepare_dragon_art.ps1` | **Quelle**, Drache, **nicht verändern** |
| `boss_v2` | 204 | 196 | `import_boss_v2_art.py`, Audits | Quelle Hexen und Behemoth |
| `master_world` | 162 | 157 | `rebuild_master_world.py` u. a. | Quelle Wald und Skelette |
| `level_swamp`, `level_ashfrost`, `level_forest` | 105 / 96 / 2 | 101 / 92 / 0 | `build_level.py`, `update_previews.py` | Quelle bzw. generiert (Level) |
| `level_enemies` | 40 | 0 | `build_enemies.py` | Quelle der Sumpf- und Ruinengegner |
| `spell_v2` | 102 | 96 | `import_spell_v2.py`, `build_spell_v2_catalog.py` | Quelle Zaubericons und Effekte, Katalog `catalog.json` |
| `atmosphere_v2` (seit 26.11. unter `bosses/`) | 56 | 52 | `import_atmosphere_art.py`, `prepare_atmosphere_art.ps1` | **Quelle** der Miniboss-Modelle (`spr_fg_boss_golem`, `spr_fg_boss_dragon`), der Magnetkugel und der Münze; die Krieger-v2-Bögen darin sind ungenutzt |
| `environment` | 21 | 17 | `finish_art_migration.py` | Quelle Umgebung (frühe Migration) |
| `references` | 9 | 0 | — | **Referenz** (Konzepttafeln, u. a. Zaubermeisterin, Waldläufer, Drachenangriffe) |
| `reference/octopath` (seit 26.11. abends, **nur lokal**, `.gitignore`) | 24 | 0 | — | **Fremdreferenz**: Bildschirmfotos aus Octopath Traveler als Qualitätsmaßstab für Licht und Effekte ([[Visuelles Leitbild & Animation]] 7). Nie committen, nie pushen, nie ins Spiel einbinden. |
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

## 3a. Stand 26.11.2026 (Phasen 1, 2A, 2B)
- **Keine neuen Bild- oder Tondateien:** Telegraphs, Gefahrenflächen, Feuerstrom, Aufladungen, Lichtblitze, Pfeile und Zielmarken sind prozedurale Pixel-Komposite im Weltraster. Kein Original-Asset wurde verändert, verschoben oder gelöscht.
- **Neue generierte Datenbausteine** (nicht von Hand ändern):
  - `scripts/review_registry_data` aus `review/registry.json` (`tests/tools/review/review.py build`).
  - `scripts/equipment_attach_data` aus den Ausrüstungsatlanten (`tests/tools/characters/build_attach_points.py`).
- **Neue Werkzeuge:**
  - `tests/tools/review/` (Registry, Abgleich der Freigaben, End-to-End-Test).
  - `tests/tools/characters/build_attach_points.py`.
- **IDE-Baum:** neue Skripte über `tests/tools/assets/ide_folders.py --apply` einsortiert. Das ändert nur die virtuelle Ansicht, keine Datei wird verschoben.

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
  reference/octopath/              nur lokal (gitignored): fremde Bildschirmfotos als Maßstab, nie im Spiel
  characters/  swordsman_v3/ · class_overhaul/ · character_layers/(generiert)
  enemies/     level_enemies/ · master_world_enemies/
  bosses/      dragon_boss/(unveränderlich) · boss_v2/ · atmosphere_v2/ · <neue Rigs>/
  vfx/         spell_v2/ · effects/ · <neue Partikel-Atlanten>/
  environment/ environment/ · master_world/ · level_swamp/ · level_ashfrost/ · level_forest/
  ui/          icons/ · portraits/
  _legacy/     heroes/ · monsters/ · monster_originals/ · previews/
```

**Migrationsplan (schrittweise, jeder Schritt mit Tests):**
1. **Pfadtabelle:** `tests/tools/assets/art_paths.py` mit einer Konstante je Quellordner. Alle Werkzeuge lesen nur noch diese Tabelle. Prüfung: Suche nach `FirstGame_ArtPack/` außerhalb der Tabelle ergibt null Treffer.
2. **Probelauf:** Importer und Generatoren im Trockenmodus (bzw. in eine Testkopie) gegen die Tabelle laufen lassen. `QA/tools/audit_visual_preservation.py` muss unverändert bleiben.
3. **Verschieben** mit `git mv` in einem eigenen Commit. Nur die Tabelle wird angepasst.
4. **Prüfen:** Static-Suite, ein Importer-Testlauf je Quelle, Visual-Suite. Links in den Notizen werden nachgezogen; historische Berichte bleiben unverändert (historisch).
5. **Legacy:** `_legacy/` bleibt im Repo. Löschen nur auf ausdrücklichen Wunsch.

**Erledigt am 25.11. (sicherer Teil, kein Werkzeug liest diese Ordner):**
- `heroes/`, `monsters/`, `icons/`, `portraits/`, `previews/` und `effects/` liegen in `FirstGame_ArtPack/_legacy/`.
- `monster_originals/` und die fünf losen Konzeptbilder liegen in `references/`; die zwei Audit-Werkzeuge sind nachgezogen.
- Das ArtPack-README ist jetzt ein Index.

**Schritt 1 erledigt am 25.11.:** Pfadtabelle `tests/tools/assets/art_paths.py` (eine Konstante je Quellordner, `level_dir()` für Levelgrafik). 24 Werkzeuge lesen nur noch daraus; `python tests/tools/assets/art_paths.py --check` meldet 0 Code-Verweise außerhalb der Tabelle. Jeder umgestellte Ausdruck wurde vorher auf denselben Zielpfad geprüft.

**Schritte 2–4 erledigt am 26.11.:**
- Probelauf: `art_paths.py --check` vor und nach dem Verschieben mit 0 Verweisen außerhalb der Tabelle.
- Verschoben mit `git mv`: `swordsman_v3`, `class_overhaul`, `character_layers` → `characters/`; `level_enemies` → `enemies/`; `dragon_boss`, `boss_v2` → `bosses/`; `spell_v2` → `vfx/`; `environment`, `master_world`, `level_forest`, `level_swamp`, `level_ashfrost` → `environment/`. Nur die Pfadtabelle wurde angepasst.
- Geprüft: alle Tabelleneinträge vorhanden; Probeläufe `build_dragon_parts.py --preview`, `build_boss_baked.py twins --preview`, `audit_boss_v2_assets.py` PASS; QA-Suiten siehe LOG.
- Abweichung vom Zielbild: Die Skelett-Frames des Walds bleiben in `environment/master_world/` (kein Aufteilen eines Ordners, den der Welt-Importer als Ganzes liest).

**Nachtrag 26.11. nachmittags:**
- `atmosphere_v2/` geprüft: Der Ordner ist keine Altlast, denn vier Spielgrafiken stammen daraus (Minibosse Waldgolem und Drache, Magnetkugel, Münze). Deshalb liegt er als Ganzes unter `bosses/`, nach dem Vorbild von `master_world`, weil der Importer ihn als Ganzes liest. Der relative Verweis der Drachen-Quellen (`../atmosphere_v2/frames/boss-dragon-0.png`) stimmt dadurch wieder.
- Lücke der Migration vom Vormittag geschlossen: Die PowerShell-Vorbereitungsskripte (`prepare_*.ps1`, `audit_boss_v2_art.ps1`, `clean_character_edges.ps1`, `preview_art_rooms.ps1`) zeigten noch auf die alten Ordner. Die Python-Tabelle können sie nicht einbinden, daher behalten sie ihre Pfade. `art_paths.py --check` prüft jetzt aber, dass jeder ArtPack-Pfad in einer `.ps1` existiert (16 Pfade, 0 fehlen).

**Offen:** `ui/` entsteht erst mit neuen UI-Quellen.

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

## 7. Anforderungen für neue Grafik (Stand 26.11.2026, Quelle noch offen)

Die Quelle (KI-Atlanten oder Pixel-Artist) entscheidet der Nutzer (Roadmap Zeilen 9, 11, 12). Die Anforderungen unten gelten für beide Wege.
- **KI-Atlanten:** Jede Zelle wird gegen die Originalzelle als Vorlage erzeugt und mit dem jeweiligen Prüfwerkzeug abgenommen.
- **Pixel-Artist:** Dieser Abschnitt und die Originalatlanten als Unterlage sind das Briefing.

Nichts wird prozedural zurechtgeschnitten, wenn das die Qualität senkt. Fehlt eine Quelle, bleibt der heutige Stand.

### 7.1 ~~Basemodel ohne Ausrüstung~~ (verworfen 26.11. abends)
Nutzerentscheidung: Die heutigen Figuren bleiben, Rüstung ist unsichtbar ([[Visuelles Leitbild & Animation]] 5.5a, [[DECISIONS]]). Anforderungen, Ablageordner `characters/base_neutral/` und `check_base_neutral.py` sind ohne Auftrag; Verlauf in Git.

### 7.2 Drachenschweif als Gliederkette (Roadmap 12)
- **Umfang:**
  - 4–6 Schweifglieder mit abnehmender Größe und eine Schweifspitze. Die Spitze bekommt eine eigene Trefferfläche.
  - Dazu Körperposen ohne Schweif für alle heutigen Körperposen (`spr_drg_body_*`, idle und walk, 8 Bilder).
- **Maße:** im Maßstab und in der Ansicht der Drachen-Originale (`bosses/dragon_boss/frames`). `build_dragon_parts.py` backt sie wie Körper und Kopf auf Spielgröße (Körperbild 357 × 357, Ursprung 179,335) mit der gemeinsamen 48-Farben-Palette.
- **Drehung:** Jedes Glied wird in Seitenansicht und ungedreht geliefert, nach rechts zeigend. Die 32 Drehstufen erzeugt das Werkzeug (RotSprite wie bei Hals und Kopf); gedreht wird nie zur Laufzeit.
- **Gelenke:** Vorder- und Hintergelenk je Glied als Pixelkoordinaten in `parts.json`.
- **Dateien:** `FirstGame_ArtPack/bosses/dragon_parts_v2/tail_1.png … tail_n.png`, `tail_tip.png`, `body_notail_<pose>_<n>.png`, `parts.json`. Der Ordner `dragon_boss` bleibt unverändert.
- **Noch zu tun bei Lieferung:** Kettenphysik und Treffer-Anbindung in `dragon_parts` (Gliederfolge wie beim Hals).

### 7.3 Drachenflügel als eigene Teile (Roadmap 12)
- **Umfang:** naher und ferner Flügel mit mindestens 4 Schlüsselposen (angelegt, halb, gespreizt, Abschlag). Dazu Körperposen ohne Flügel.
- **Maße und Dateien:** wie 7.2, mit Gelenk an der Schulter in `parts.json`. Dateien `wing_near_<pose>.png` und `wing_far_<pose>.png`.
- **Animation:** Flügel schlagen über Bildfolgen. Nachschwingen und Verzögerung gegenüber dem Körper laufen nach [[Visuelles Leitbild & Animation]] 5.1.

### 7.4 Draufsicht des Drachenkopfs
- **Heute:** Der Kopf entsteht aus 32 gedrehten Stufen der Seitenansicht und wirkt nach unten flach.
- **Umfang:** drei Kopfansichten (Seite, 45° von oben, von oben), jeweils geschlossen und offen.
- **Maße und Dateien:** Maßstab wie die heutigen Kopfbilder (206–216 px, Ursprung Mitte). Das Gelenk zum Hals steht in `parts.json`. Dateien `head_<side|down45|top>_<closed|open>.png` in `dragon_parts_v2/`.
- **Anbindung:** Das Werkzeug wählt je Drehstufe die nächste Ansicht. Das Maul bleibt Ursprung des Feueratems.

### 7.5 Wald-Skelette in Pixeldichte 1:1
- **Umfang:** 3 Rollen (`warrior`, `scout`, `guard`) × 5 Aktionen × 8 Richtungen.
- **Bilder je Aktion:** wie heute (idle 2, walk 4, attack 2, hurt 3, death 5) oder mehr. Attack braucht eine klare Ausholpose.
- **Maße:** in der Bildschirmgröße der Rolle statt gestreckter 96er-Bilder.

  | Rolle | Bildgröße | Ursprung (Füße) |
  |---|---|---|
  | warrior | 134 × 134 | 67, 123 |
  | scout | 120 × 120 | 60, 110 |
  | guard | 158 × 158 | 79, 145 |

- **Namen:** GameMaker-Sprites `spr_master_skeleton_<rolle>_<aktion>_<richtung>`. Die Quellen liegen in `FirstGame_ArtPack/enemies/forest_skeletons/`.
- **Einlesen ohne Umbau:** `master_skeleton_prefix` nutzt diese Sprites automatisch, sobald `spr_master_skeleton_<rolle>_idle_down` existiert, und zeichnet sie unskaliert (`skeleton_baked` → `monster_art_div`). Überreste werden gleich behandelt. Ohne Lieferung bleibt alles wie heute.

### 7.6 Minibosse (Roadmap 9)
- **Heute:**
  - Waldwächter (Art `golem`, Minute 1) und Runenwächter (Art `boar`, Minute 3) nutzen die 0.1-Streifen `spr_fg_<art>_<aktion>`: 64 × 64, 5 Aktionen, ohne Richtungen.
  - Die Bossbilder `spr_fg_boss_golem` und `spr_fg_boss_dragon` (384 × 384, 3 Posen) stammen aus `bosses/atmosphere_v2`.
- **Umfang:**
  - je Miniboss 5 Aktionen in 8 Richtungen (oder 5 Richtungen plus Spiegelung);
  - Ausholpose für jeden Spezialangriff (Blitz, Wurf);
  - Pixeldichte 1:1 in Bildschirmgröße.
- **Dateien:** Quellen unter `FirstGame_ArtPack/bosses/minibosses/<name>/`, Sprites `spr_mb_<name>_<aktion>_<richtung>`.
- **Noch zu tun bei Lieferung:** Anbindung im Code (klein, analog zum Präfix der Levelgegner).

### 7.7 ~~Umstieg auf Basemodel plus modulare Ausrüstung~~ (verworfen 26.11. abends, siehe 7.1)

### 7.8 Figuren auf HD-2D-Niveau: was nur neue Grafik leisten kann (Grafik-Overhaul, 26.11. abends)
Shader und Effekte decken Randlicht, Lichtfarbe, Schatten, Auren, Aufblitzen, Waffenglühen, Staub und Funken ab ([[Visuelles Leitbild & Animation]] 7.5). Folgendes lässt sich damit **nicht** ehrlich erreichen und braucht gezeichnete Quellen (Format jeweils wie die heutigen Atlanten, 1:1-Pixeldichte, gleiche Zellen):
1. **Licht-Normalen je Frame** (Normal Map im Pixelstil, 8 Richtungen aus ganzen Werten) für alle drei Klassen und alle Atlanten.
   - Ohne sie bleibt die Schattierung im Sprite fest von oben links gemalt. Licht von unten oder hinten kann die Figur nur am Rand färben, nicht die Flächen modellieren.
   - Alternative mit weniger Aufwand: je Frame eine Höhen- oder Wölbungsmaske (Graustufen).
2. **Emissionsmasken der Waffen** (welche Pixel einer Klinge, Stabkugel oder Sehne leuchten dürfen).
   - Heute glüht nur ein Punkt bzw. ein wandernder Lichtfunke.
3. **Schmier- und Ausholbilder für Angriffe** (2–3 zusätzliche Frames je Schlag, Smear-Frames wie in den Referenzbildern), Treffer-Reaktion und eine echte Ausweichrolle.
   - Heute wird die Rolle nur über Stauchen und Staub gezeigt.
4. **Gemalte Schlagbögen** (Sichel-Slashes in 3 Größen × 8 Richtungen, je Klasse in ihrer Farbe) als Pixel-Sprites. Prozedurale Bögen sind möglich, erreichen aber nicht die Form der Referenz.

Abnahme: technische Prüfung wie bei 7.1 (Zellen, Alpha), danach Review-Eintrag; die Quelle (Bildwerkzeug oder Pixel-Artist) entscheidet der Nutzer.
