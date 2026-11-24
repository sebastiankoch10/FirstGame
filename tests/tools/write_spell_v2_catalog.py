"""Regenerate the review catalog from the same definitions used by GameMaker."""
from pathlib import Path
import math
from build_spell_v2_catalog import catalog
ROOT=Path(__file__).resolve().parents[2]
def rnd(v): return math.floor(v+.5)
def main():
 lines=['# FirstGame – Zauberkatalog 2.0','','Stand: 22.11.2026. Alle 18 aktiven und 18 passiven Fähigkeiten sind implementiert. Maximal sechs aktive und sechs passive Slots; jede Fähigkeit Stufe 1–9. Die Klassenwaffe belegt keinen Slot.','','## Bearbeiten und regenerieren','','Zentrale Definitionen: `tests/tools/build_spell_v2_catalog.py` → `FirstGame_ArtPack/spell_v2/catalog.json` und `scripts/spell_v2_catalog/spell_v2_catalog.gml`. Danach dieses Dokument mit `python tests/tools/write_spell_v2_catalog.py` regenerieren. Ausführung: `scripts/spell_v2`, ältere sechs Zauber zusätzlich `scripts/cast_spell`; Modifikatoren: `scripts/apply_passives`. UI und Ausführung lesen denselben Katalog.','','## Gemeinsame Regeln','','Basiswerte unten: Power 2, keine Passiven. Schaden/Heilung je direktem Treffer beziehungsweise Puls, keine DPS-Summen. Formel: round(Basis × (1 + 0,16 × (Stufe−1)) + Power × Skalierung). Cooldown in Frames = max(18, round(Basis × (1−0,012 × (Stufe−1)) × CDR)); Anzeige bei 60 Hz. Radien steigen, soweit vorhanden, um vier Pixel pro Stufe und werden durch Wide Glyphs multipliziert. Statuszeiten werden durch Lingering Hex, Kälte zusätzlich durch Winter Heart verlängert. Flächenschaden kann mehrere Ziele treffen; tatsächliche Run-Summen werden getrennt erfasst.','','Neue Mehrfacheffekte haben 3/4/5 Klingen, Spitzen, Einschläge oder Folgesplitter auf Stufe 1/5/9. Barrage hat 3/4/5 Grundprojektile. Lightning hat 3/4/5 Kettenziele ab Stufe 1/4/7; Storm Conductor ergänzt auf 5 und 9 je eines. Jeder Zauber besitzt neun echte numerische Upgrades einschließlich Stufe 1.','','## Aktive Fähigkeiten']
 for d in catalog():
  if d['type']!=1:continue
  sid=d['id'];lines += ['',f"### {sid}: {d['name']} — IMPLEMENTIERT",'',d['desc'],'',f"Mechanik `{d['mechanic']}`; Icon `{d['icon_sprite_name']}`; eigene WAV `Audio/Spells/{d['cue']}.wav` (Synthese-Prototyp).",'', '| Stufe | Schaden / Heilung | Cooldown (s) | Radius (px) | Projektile / Stufen / Kettenziele |','|---|---|---|---|---|']
  for lv in range(1,10):
   damage=rnd(d['base_damage']*(1+.16*(lv-1))+2*d['scaling']['power'])
   count=3+(lv-1)//3 if sid==103 else d['projectile_count']+(lv-1)//4 if sid==105 else 3+(lv-1)//4 if sid in (109,110,113,117) else '—'
   lines.append(f"| {lv} | {damage} | {max(18,rnd(d['cooldown']*(1-.012*(lv-1))))/60:.2f} | {d['explosion_radius']+d['radius_per_level']*(lv-1) if d['explosion_radius'] else '—'} | {count} |")
  extra={101:'Explosion am Projektilkopf; Brennen 1 Schaden/s für 1 s, stärkster laufender Brand bleibt zuständig.',102:'Verlangsamungsfaktor 0,5 für 1 s.',103:'Sprungreichweite 160–192 px; Schock 24 Frames.',104:'Verlangsamungsfaktor 0,4 für 1,5 s.',106:'Heilt ausschließlich fehlendes Leben. Die tatsächliche Heilung kann niedriger sein.',107:'Bodenfeld 3,0–3,8 s; Schaden alle 0,5 s; Brennen 1,2–2,8/s für 1 s.',108:'Sofortige Linie, 650 px Reichweite; Radius in der Tabelle ist die halbe Linienbreite.',109:'Klingenorbit 3,0–3,8 s; Kontaktprüfung alle 0,42 s.',110:'Erster Einschlag nach 0,28 s, weitere im Abstand 0,35 s; Linie entlang der Zielrichtung.',111:'Geist 5,0–5,8 s; Zielradius 265–297 px; Angriffsintervall 0,625–0,425 s.',112:'Einmalige Entladung nach 0,9 s; Schock 35 Frames.',113:'Erster Einschlag nach 0,28 s, weitere alle 0,35 s; versetzte Positionen.',114:'Feld 3,5–4,3 s; Puls alle 0,5 s; Zug bis 100 px/s nur auf normale Gegner, respektiert Säulen.',115:'Feld 1,8–2,6 s; Puls alle 0,5 s; normale Gegner 0,18 s festhalten. Slowfaktor 0,45 für 65–105 Frames; Bosse werden nicht festgehalten.',116:'Hinweg 0,55 s und Rückweg 0,55 s zur aktuellen Spielerposition; pro Gegner höchstens ein Treffer je Weg.',117:'Reisender Kern bis 2 s; Explosion und 65%-Folgetreffer an maximal 3–5 ausgewählten Zielen.',118:'Große Explosion nach 0,72 s; goldene Säule und Lichtimpuls.'}.get(sid,'Fächer aus getrennt treffenden Projektilen; Split Runes addiert Geschosse und flachen Projektilschaden.')
  lines += ['',extra]
 lines += ['','## Passive Fähigkeiten','','Die folgenden Werte gelten kumulativ je aktueller Stufe. Wiederholtes Anwenden stapelt den gleichen Bonus nicht erneut. Passiver Verstärkerschaden wird nicht als erfundener eigener Angriff gezählt.']
 for d in catalog():
  if d['type']!=2:continue
  sid=d['id'];lines += ['',f"### {sid}: {d['name']} — IMPLEMENTIERT",'',d['desc'],'',f"Icon `{d['icon_sprite_name']}`. Kein eigener Cast-Cue; Auswahl/Upgrade verwendet die zentralen UI-Ereignisse.",'','| Stufe | Gesamte Wirkung |','|---|---|']
  for lv in range(1,10):
   b=lv*d['bonus_per_level']
   if sid==201:v=f'{min(.6,b)*100:.0f}% Reduktion; {2+lv} Orbit-Schaden'
   elif sid==206:v=f'{math.ceil(lv/3)} Zusatzprojektile; +{lv} Projektilschaden'
   elif sid==213:v=f'+{b*100:g}% Eisschaden; +{lv*4}% Kältedauer'
   elif sid==212:v=f'+{b*100:g}% Blitzschaden; +{int(lv>=5)+int(lv>=9)} Kettensprünge'
   elif sid==216:v=f'{96+b:g} px Sammelradius'
   elif sid in (202,203,205,214,215):v=f'+{b:g} '+{202:'Power',203:'Bodentempo',205:'maximale HP',214:'flache Schadensminderung',215:'HP/s Regeneration'}[sid]
   else:v=f'{b*100:g}'+{204:'% Waffenhaste',207:' Prozentpunkte kritische Chance',208:'% Projektiltempo',209:'% Radius',210:'% Cooldown-Reduktion',211:'% Feuerschaden',217:'% Statusdauer',218:'% Schaden gegen beeinträchtigte Ziele'}[sid]
   lines.append(f'| {lv} | {v} |')
 lines += ['','## Nachweise und Grenzen','','[Abschlussbericht](SPELL_V2_REPORT.md), native echte HP-/Heilungsprüfungen in `tests/reports/spell-v2-native.json`. Alle aktiven Mechaniken wurden auf 1/9 ausgeführt; Zwischenstufen und passive Neuberechnung zusätzlich geprüft. Diese technischen Nachweise ersetzen keine menschliche Langzeit-Balance- oder Hörabnahme.']
 (ROOT/'SPELL_CATALOG.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
 print('Wrote SPELL_CATALOG.md: 36 implemented abilities, nine levels each')
if __name__=='__main__':main()
