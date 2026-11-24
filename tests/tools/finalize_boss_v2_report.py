"""Preserve successful native/build evidence, exact balance numbers, and verified screenshots."""
from pathlib import Path
import json,shutil,zipfile,re
ROOT=Path(__file__).resolve().parents[2]
def main():
 reports=ROOT/'tests/reports';r=json.loads((reports/'boss-v2-native.json').read_text());b=json.loads((reports/'production-build.json').read_text());captures=json.loads((reports/'boss-v2-captures.json').read_text());assets=json.loads((reports/'boss-v2-assets.json').read_text())
 assert r['passed'] and not r['failures'] and b['passed'] and b['package_success'] and not b['test_hooks'] and captures['passed'] and assets['passed']
 with zipfile.ZipFile(ROOT/b['archive']) as z:assert z.testzip() is None
 shutil.copyfile(reports/'production-build.json',reports/'boss-v2-build.json')
 for png in (ROOT/r['logs']).glob('*.png'):shutil.copyfile(png,reports/('boss-v2-'+png.name))
 # The capture-only pass fixes a GUI-size mismatch in evidence extraction; no production change.
 for name in ['test-menu.png','behemoth-bloom-active.png']:shutil.copyfile(ROOT/captures['logs']/name,reports/('boss-v2-'+name))
 lines=['| Boss / Minute | Schwertkämpfer | Zaubermeisterin | Waldläufer |','|---|---|---|---|']
 for bid,label in [('storm_warden','Drache'),('twins','Zwillingshexen'),('behemoth','Sumpfbehemoth')]:
  for minute in [5,10,15]:
   cells=[]
   for actor in ['Sword','Mage','Ranger']:
    d=next(x for x in r['metrics']['dps'] if x['boss']==bid and x['class_name']==actor and x['minute']==minute and x['variant']=='70_percent_new_attack_opportunities')
    cells.append(f'{d["analytical_ttk_seconds"]:.1f} s')
   lines.append(f'| {label} / {minute} | '+' | '.join(cells)+' |')
 lines += ['','Die Tabelle nutzt das Fenster mit 70% neuen Angriffsmöglichkeiten. Die vollständigen gemessenen DPS, HP und beide Profile stehen im nativen JSON. Zwei Trefferkörper erhöhen insbesondere bei stationären Hexen die Flächeneffizienz. Ihre tatsächlichen Flugformationen verringern die Trefferquote; das ist hier nicht als vollständiger Kampf simuliert. Starke Builds dürfen die Zielzeit unterschreiten.']
 archive=b['archive'].replace('\\','/');image_links='[Boss-Testmenü](tests/reports/boss-v2-test-menu.png) · [Bewegter Hexenstrahl](tests/reports/boss-v2-twins-link-active.png) · [Verfallsblüte](tests/reports/boss-v2-behemoth-bloom-active.png) · [Dezenter Countdown](tests/reports/boss-v2-subtle-warning-50.png)'
 doc=ROOT/'BOSS_V2_REPORT.md';s=doc.read_text(encoding='utf-8');s=s.replace('<!-- BALANCE_RESULTS -->','\n'.join(lines));s=s.replace('<!-- BUILD_AND_IMAGES -->',f'**PASS: normaler Windows-Build, Compile und Paket erfolgreich, ohne injizierten Testharness.** [Aktuelles Spielpaket]({archive}). [Buildnachweis](tests/reports/boss-v2-build.json). Das gewünschte Entwicklungsmenü ist enthalten. ZIP-CRC vollständig geprüft.\n\n'+image_links)
 doc.write_text(s,encoding='utf-8')
 p=ROOT/'README.md';rows=p.read_text(encoding='utf-8').splitlines();rows[2]=f'**Aktueller Stand:** [Boss-System 2.0](BOSS_V2_REPORT.md), [Boss-Katalog](BOSS_CATALOG.md). Drei Hauptbosse mit jeweils neun Fähigkeiten und direktem Menü **Boss testen**. {int(r["checks"])} native Prüfungen bestanden. [Aktueller Windows-Build]({archive}). Frühere Berichte dokumentieren vorherige Stände.';p.write_text('\n'.join(rows)+'\n',encoding='utf-8')
 p=ROOT/'CLASS_DRAGON_REPORT.md';s=p.read_text(encoding='utf-8');pointer='Neuere Hauptboss-/Freischaltungs-/Testmenü-Änderungen: [BOSS_V2_REPORT.md](BOSS_V2_REPORT.md). Dieser Bericht bewahrt den zuvor geprüften Klassenstand.\n\n'
 if pointer not in s:s=s.replace('\n\n','\n\n'+pointer,1);p.write_text(s,encoding='utf-8')
 p=ROOT/'Audio/README.md';s=p.read_text(encoding='utf-8');s=s.replace('**Aktuell vorhanden: 3 Musik-WAVs und 67 Effekt-WAVs**, vollständig als 70 GameMaker-Soundressourcen registriert.','**Aktuell vorhanden: 3 Musik-WAVs und 85 Effekt-WAVs**, vollständig als 88 GameMaker-Soundressourcen registriert. Boss-System 2.0 ergänzt 18 tatsächliche Synthese-Prototypen unter `Audio/Bosses/twins_1.wav` bis `twins_9.wav` und `swamp_1.wav` bis `swamp_9.wav`; Quelle `Audio/Sources/compose_boss_v2.py`.');p.write_text(s,encoding='utf-8')
 missing=[link for link in re.findall(r'\]\(([^)]+)\)',doc.read_text(encoding='utf-8')) if not (ROOT/link).exists()]
 assert not missing,missing
 print('PASS: local report, balance table, evidence and ZIP CRC:',archive)
if __name__=='__main__':main()
