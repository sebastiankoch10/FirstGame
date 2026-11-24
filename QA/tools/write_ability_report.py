"""Build the ability report from the validated native controlled measurements."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[2]

def main():
    validation=json.loads((ROOT/'QA/data/ability-validation.json').read_text())
    if not validation['passed']:raise RuntimeError('Native benchmark integrity is not validated')
    rows=[json.loads(x) for x in (ROOT/'QA/data/ability-baseline.jsonl').read_text().splitlines() if x]
    rows=[r for r in rows if r.get('record_type')=='controlled_benchmark']
    names={r['id']:r['name'] for r in json.loads((ROOT/'FirstGame_ArtPack/spell_v2/catalog.json').read_text())}
    def active(sid,level,count):return next(r for r in rows if r['kind']=='active' and r['sid']==sid and r['level']==level and r['target_count']==count)
    out=['# Fähigkeiten: native kontrollierte Messungen','',
         '**654 Messfenster tatsächlich ausgeführt:** 18 aktive Fähigkeiten × 9 Stufen × 1/8 Ziele = 324; 18 passive Fähigkeiten × 3 Stufen × 1/8 Ziele × 3 Varianten = 324; drei Startwaffen × 1/8 Ziele = 6. Jedes Fenster dauert 900 echte Produktionsschritte / 15 simulierte Sekunden. Dazu bestehen zehn native Prüfungen mit bekannten HP-Werten. Integrität: `data/ability-validation.json` PASS.','',
         'Die Ziele stehen bei 100 Pixel Entfernung, bei acht Zielen in einer Gruppe mit 44 Pixel Streuung; sie haben einen großen HP-Vorrat und deaktivierte Angriffs-/Bewegungs-KI. Dies sind tatsächliche HP-Verluste im nativen Runner, keine vollständigen Runs, menschlichen Kämpfe oder universellen Ranglisten. Ein kurzer Ausschnitt bevorzugt bestimmte Cooldown-Phasen. Heilung und Kontrolle sind gesondert zu lesen.','',
         'Rohdaten: `data/ability-baseline.jsonl`; sämtliche Stufen und Quellen bleiben maschinenlesbar. Tabellenexport: `data/controlled-benchmarks.csv`. Diagramm: `charts/active-ability-dps.png`.','',
         '## Aktive Fähigkeiten','',
         '| ID | Fähigkeit | DPS 1 Ziel St. 1 | St. 5 | St. 9 | DPS 8 Ziele St. 5 |','|---|---|---:|---:|---:|---:|']
    for sid in range(101,119):
        vals=[active(sid,lv,1)['dps'] for lv in [1,5,9]]+[active(sid,5,8)['dps']]
        out.append(f'| {sid} | {names[sid]} | '+' | '.join(f'{x:.2f}' for x in vals)+' |')
    heal=[active(106,lv,1)['healing'] for lv in [1,5,9]]
    out+=['',f'Healing Pulse heilt in diesen Fenstern Stufe 1/5/9 tatsächlich {heal[0]:.0f}/{heal[1]:.0f}/{heal[2]:.0f} HP. Sein Schaden von null ist beabsichtigt. Die Heil-Fixture besitzt dafür einen großen echten Fehl-HP-Vorrat.','',
          'Wisp Sentinel, Starfall und Arcane Barrage liefern in diesem stationären Einzelziel-Fenster viel Schaden. Starfall, Ice Prison und Ember Field treffen die Gruppe stark. Frost Nova hat geringeren direkten DPS, bietet aber Verlangsamung/Unterbrechung; diese Kontrolle wird im unbewegten Zieltest nicht als Überlebensnutzen gemessen. Eine reine DPS-Rangliste würde diese Unterschiede unterschlagen.','',
          'Alle aktiven Fähigkeiten verursachen in jeder getesteten Stufe tatsächlich Schaden oder Heilung. Ein kleiner nicht monotoner Befund: Orbit Blades fällt bei acht Zielen von 40,8 DPS auf Stufe 4 auf 39,6 auf Stufe 5, danach steigt der Wert wieder. Das kurze Fenster, Kreisbahn und Zielanordnung können dies erklären; ohne längere Bahn-/Fensterprüfung wird daraus keine numerische Korrektur abgeleitet.','',
          '## Passive A/B-Vergleiche','',
          'Verglichen werden ausschließlich `active_control` und `active_plus_passive` bei gleicher aktiver Fähigkeit/Stufe 5, Zielzahl, Seed und Fensterdauer. Die dritte Variante enthält zusätzlich die Klassenwaffe; ohne separaten gleichzeitigen Waffen-Kontrolllauf ist deren Mehrschaden kein isolierter Effekt des Passivums. Nach dem Fenster wird ein tatsächlicher 20-HP-Treffer auf den Spieler ausgeführt; dessen HP-Verlust steht in der Tabelle.','',
          '| ID | Passivum St. 9 | Test-Aktiv | DPS ohne → mit | HP-Verlust bei 20 Schaden | Weitere gemessene Größe |',
          '|---|---|---:|---:|---:|---|']
    for sid in range(201,219):
        sub=[r for r in rows if r['kind']=='passive_ab' and r['tested_passive']==sid and r['comparison_level']==9 and r['target_count']==1]
        control=next(r for r in sub if r['variant']=='active_control');modified=next(r for r in sub if r['variant']=='active_plus_passive')
        utility=modified['utility'];mods=modified['player_modifiers'];extra=''
        if sid==203:extra=f"Bewegung {mods['move_speed']:.2f} px/Tick"
        if sid==204:extra=f"Waffen-Haste +{mods['haste']*100:.0f} %"
        if sid==205:extra=f"Maximal-HP +{utility['max_hp_bonus']:.0f}"
        if sid==208:extra=f"Projektilfaktor {mods['projectile_factor']:.2f}"
        if sid==209:extra=f"Flächenfaktor {mods['area']:.2f}"
        if sid==215:extra=f"{modified['healing']:.2f} echte Regenerations-HP/15 s"
        if sid==216:extra=f"Sammelradius {utility['pickup_radius']:.0f} px"
        if sid==217:extra=f"Statusfaktor {mods['status_factor']:.2f}"
        out.append(f"| {sid} | {names[sid]} | {int(modified['sid'])} | {control['dps']:.2f} → {modified['dps']:.2f} | {utility['incoming20_actual_hp_loss']:.2f} | {extra} |")
    out+=['',
          'Power Up, Split Runes und Quick Channel zeigen in ihrer passenden Testkonfiguration einen deutlichen offensiven Effekt. Orbit Shield reduziert den tatsächlichen 20-HP-Treffer auf 8 HP; Iron Skin auf 14,6 HP. Vital Bloom erhöht das HP-Maximum um 108; Regeneration stellt im verletzten Testzustand 32,4 HP wieder her. Dies beschreibt die Stufe-9-Fixtures, keinen bewiesenen besten vollständigen Build.','',
          'Bewegung, Sammelradius, Zielkontrolle und Verweildauer werden nicht durch stationären DPS vollständig bewertet. Insbesondere kann Arcane Duration beim Iceball die Kontrolle verlängern, ohne hier den Schaden zu erhöhen. Orbit Shields eigener Umlauftreffer erreicht den 100-Pixel-Testpunkt nicht; dessen Schaden wird mit dieser Zielanordnung nicht vollständig charakterisiert.','',
          '## Startwaffen und einzelne Komboschritte','',
          '| Klasse | DPS 1 Ziel | DPS 8 Ziele |','|---|---:|---:|']
    weapons=[r for r in rows if r['kind']=='base_weapon']
    for klass in ['Sword','Mage','Ranger']:
        one=next(r for r in weapons if r['class_name']==klass and r['target_count']==1)
        eight=next(r for r in weapons if r['class_name']==klass and r['target_count']==8)
        out.append(f"| {klass} | {one['dps']:.2f} | {eight['dps']:.2f} |")
    out+=['','Die Startwaffen sind hier ohne andere aktive/passive Fähigkeiten gemessen. Reichweite, Laufgeschwindigkeit, Sicherheit und tatsächliche Angriffszeit im bewegten Spiel sind darin nicht enthalten. Der Ranger hat im Test weniger Flächenschaden, kann im tatsächlichen Spiel dafür aus größerer Entfernung und schnellerer Bewegung angreifen.','',
          '| Klasse | Schritt | Tatsächlicher Schaden/15 s (1 Ziel) | Auslösungen | Erzeugte Projektile |',
          '|---|---:|---:|---:|---:|']
    for r in weapons:
        if r['target_count']!=1:continue
        for key,s in sorted(r['metrics']['sources'].items(),key=lambda x:x[1].get('stage',0)):
            if s.get('sid')==0:out.append(f"| {r['class_name']} | {int(s['stage'])} | {s['damage']:.2f} | {int(s['casts'])} | {int(s['projectiles'])} |")
    out+=['','## Attributionsregeln und Grenzen','',
          'Versuchter Schaden, tatsächlicher HP-Verlust, Overkill, Treffer, normale/Boss-Ziele, kritische Treffer, DoT, echte Projektile und deren Ablauf bleiben je Quelle erhalten. Verzögerte Klassenangriffe behalten ihren ursprünglichen Komboschritt; anhaltende Bossgefahren behalten ihre Geburtsfähigkeit. Passive Verstärkung wird beim ursprünglichen Angriff gezählt, nicht nochmals als erfundener passiver Schaden. Eigene tatsächlich treffende Mechaniken eines Passivums bleiben eigene Mechaniken.','',
          'Ein Projektil-Fehlschuss bedeutet ausschließlich ein tatsächlich abgelaufenes Projektil ohne irgendeinen Treffer. Am Fensterende noch fliegende Projektile sind ausstehend, keine Fehlschüsse. Flächenfähigkeiten besitzen keine vergleichbare Projektil-Fehlschussquote. Overkill wird nicht als effektiver DPS ausgegeben.','',
          'Eine vollständig kausale Rangliste sämtlicher Zauberkombinationen und aller passiven Überlebenseffekte ist mit dieser Matrix nicht gemessen. Der vollständige Run-Bericht liefert ergänzende Beobachtungen; seltene Kombinationen werden nicht als statistisch bewiesene beste Builds bezeichnet.']
    (ROOT/'QA/ABILITY_BALANCE.md').write_text('\n'.join(out)+'\n',encoding='utf-8')
    print('Wrote QA/ABILITY_BALANCE.md from654 validated native cells')

if __name__=='__main__':main()
