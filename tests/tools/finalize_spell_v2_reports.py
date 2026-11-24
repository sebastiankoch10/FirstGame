"""Preserve final runtime evidence and update current documentation pointers."""
from pathlib import Path
import json,shutil,zipfile
ROOT=Path(__file__).resolve().parents[2]
def main():
 report=ROOT/'tests/reports';data=json.loads((report/'combat-smoke-result.json').read_text())
 assert data['passed'] and data['checks']==322
 data['test_type']='Native Windows VM: 36 abilities, real HP/healing at active levels 1/9, all passives and intermediate values, bounded effects/audio voices, weighted choices, three injected XP budget replays, short fixed-step combat benchmarks, nine class/room starts, dragon/jump/scenery/coin checks. Not human gameplay E2E.'
 (report/'spell-v2-native.json').write_text(json.dumps(data,indent=2)+'\n',encoding='utf-8')
 work=ROOT/data['logs']
 for p in work.glob('v2-*-800.png'):shutil.copyfile(p,report/('spell-'+p.name.removesuffix('-800.png')+'.png'))
 for name in ['README.md']:
  p=ROOT/name;s=p.read_text(encoding='utf-8');lines=s.splitlines()
  lines[2]='**Aktueller Stand:** [Zaubersystem 2.0 und Abschlussbericht](SPELL_V2_REPORT.md), [vollständiger Zauberkatalog](SPELL_CATALOG.md). 18 aktive und 18 passive Fähigkeiten; 322 native Prüfungen bestanden. [Geprüftes Windows-Paket](output/production-build/20261122-215808/FirstGame.zip). Frühere Berichte unten dokumentieren historische Zwischenstände.'
  lines=[l for l in lines if not l.startswith('Aktuelles geprüftes Windows-Paket:')]
  p.write_text('\n'.join(lines)+'\n',encoding='utf-8')
 p=ROOT/'Audio/README.md';s=p.read_text(encoding='utf-8');s=s.replace('**Tatsächlich neu erzeugt: 3 Musik-WAVs und 33 Effekt-WAVs**, vollständig als 36 GameMaker-Soundressourcen registriert.','**Aktuell vorhanden: 3 Musik-WAVs und 51 Effekt-WAVs**, vollständig als 54 GameMaker-Soundressourcen registriert. Zaubersystem 2.0 ergänzt 18 tatsächlich erzeugte Synthese-Prototypen: `Audio/Spells/skill_101.wav` bis `skill_118.wav`. Quelle: `Audio/Sources/compose_spell_v2.py`. Technische Validierung bestanden; Hörabnahme ausstehend. Die folgenden Abschnitte beschreiben außerdem die ursprünglichen 36 Audiodateien.')
 p.write_text(s,encoding='utf-8')
 build=json.loads((report/'production-build.json').read_text());assert build['passed'] and not build['test_hooks']
 with zipfile.ZipFile(ROOT/build['archive']) as z:assert z.testzip() is None
 # Explicitly named one-off installers only; durable generators remain under tests/tools.
 for name in ['install_spell_v2_core.py','install_spell_v2_ui.py','install_v2_world.py','centralize_v2_modifiers.py']:
  p=ROOT/'output'/name
  if p.exists():p.unlink()
 print('PASS: 322 native checks preserved, evidence copied, ZIP CRC valid, current documentation updated')
if __name__=='__main__':main()
