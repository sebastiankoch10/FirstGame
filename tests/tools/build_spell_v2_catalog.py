"""Single editable ability design source; emits the runtime catalog and reviewable JSON."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[2]
ACTIVE=[
 (101,'Fireball','projectile',1,18,105,64,'Explodiert am Projektilkopf und entzuendet Gegner im Radius.'),
 (102,'Iceball','projectile',2,15,96,0,'Ein schneller Eissplitter verletzt und verlangsamt sein Ziel.'),
 (103,'Lightning','chain',3,18,126,0,'Ein Einschlag verzweigt sich durch mehrere verschiedene Gegner.'),
 (104,'Frost Nova','nova',2,12,240,130,'Ein Frostkreis verletzt und verlangsamt Gegner um den Helden.'),
 (105,'Arcane Barrage','projectile',4,10,144,0,'Ein Faecher aus arkanen Geschossen mit eigenstaendigen Treffern.'),
 (106,'Healing Pulse','heal',6,18,480,62,'Ein gruener Impuls stellt tatsaechlich fehlende Lebenspunkte wieder her.'),
 (107,'Ember Field','field',1,8,300,100,'Eine brennende Bodenrune pulsiert drei Sekunden lang gegen Gegner in ihrem Bereich.'),
 (108,'Piercing Lance','lance',4,25,210,22,'Eine gerade magische Lanze durchdringt alle Gegner entlang ihrer Flugbahn.'),
 (109,'Orbit Blades','orbit',0,10,360,95,'Drei Klingen kreisen drei Sekunden um den Helden. Jedes Ziel hat eine Trefferschranke.'),
 (110,'Stone Spikes','spikes',5,22,285,62,'Drei angekuendigte Steinspitzen brechen nacheinander entlang der Zielrichtung hervor.'),
 (111,'Wisp Sentinel','summon',6,12,420,265,'Ein beschworener Lichtgeist begleitet den Helden und beschiesst nahe Gegner.'),
 (112,'Thunder Seal','seal',3,48,390,125,'Eine elektrische Rune laedt sich auf und entlaedt sich nach einer Sekunde.'),
 (113,'Starfall','meteor',1,32,450,80,'Drei zeitversetzte Sternsplitter schlagen auf erfasste Gegnerpositionen ein.'),
 (114,'Gravity Well','gravity',4,5,420,145,'Ein Wirbel zieht normale Gegner an und verursacht periodischen Schaden. Bosse widerstehen dem Zug.'),
 (115,'Ice Prison','prison',2,16,360,150,'Ein Frostgefaengnis haelt normale Gegner kurz fest und verlangsamt alle Getroffenen.'),
 (116,'Returning Glaive','glaive',0,20,270,24,'Eine Klinge trifft beim Hinflug und nochmals auf dem Rueckweg zur aktuellen Heldenposition.'),
 (117,'Prismatic Seed','seed',4,18,300,105,'Ein reisender Kern zerbricht am Ziel und verteilt zielsuchende Energiesplitter.'),
 (118,'Solar Verdict','verdict',7,84,780,230,'Ein langsam aufladender Sonnenstrahl entfesselt eine besonders starke Flaechenexplosion.'),
]
PASSIVE=[
 (201,'Orbit Shield',.1,'Kreisschild mit eigenem Trefferschaden. Schadensreduktion bis 60%; Orbit-Schaden steigt auf jeder Stufe.'),
 (202,'Power Up',2,'Additive Power fuer Klassenwaffe, direkte Zauber und Heilung. Kein erfundener eigener Schaden.'),
 (203,'Fleet Footed',.12,'Erhoeht das Bodentempo und die gerichtete Sprungbewegung additiv um 0.12 pro Stufe.'),
 (204,'Quick Hands',.05,'Erhoeht ausschliesslich die Angriffsgeschwindigkeit der Klassenwaffe um 5% pro Stufe.'),
 (205,'Vitality',12,'Erhoeht das Lebensmaximum um 12 pro Stufe und heilt genau den neu hinzugekommenen Betrag.'),
 (206,'Split Runes',1,'Fireball, Iceball und Barrage: Zusatzgeschoss auf Stufe 1/4/7. Ein Punkt Projektilschaden je Stufe gilt auch fuer die Klassenwaffen, deren feste Kombofolge erhalten bleibt.'),
 (207,'Keen Focus',.02,'Direkte Angriffe erhalten 2 Prozentpunkte kritische Trefferchance je Stufe. Kritische Treffer verursachen 160% Schaden.'),
 (208,'Swift Sigils',.055,'Fliegende Projektile bewegen sich 5.5% schneller je Stufe; ihre vorgesehene Reichweite bleibt gleich.'),
 (209,'Wide Glyphs',.035,'Erweitert Flaechenradien und Schwertreichweite um 3.5% je Stufe. Sichtbare Effekte und Trefferzone skalieren gemeinsam.'),
 (210,'Deep Rhythm',.035,'Reduziert aktive Zauber-Cooldowns um 3.5% der Basis je Stufe. Klassenwaffe bleibt davon unabhaengig.'),
 (211,'Ember Oath',.045,'Verstaerkt direkten Feuerschaden und Brennen um 4.5% je Stufe.'),
 (212,'Storm Conductor',.045,'Verstaerkt Blitzschaden um 4.5% je Stufe; Kettenblitz erhaelt auf Stufe 5 und 9 einen weiteren Sprung.'),
 (213,'Winter Heart',.045,'Verstaerkt Eisschaden um 4.5% je Stufe und verlaengert Kaeltewirkungen um 4% je Stufe.'),
 (214,'Iron Ward',.6,'Verringert einen eingehenden Treffer vor dem Kreisschild um 0.6 Schaden je Stufe, mindestens ein Punkt bleibt.'),
 (215,'Renewal',.12,'Heilt pro Sekunde 0.12 Lebenspunkte je Stufe, nur tatsaechlich fehlendes Leben wird erfasst.'),
 (216,'Scavenger',12,'Vergroessert den normalen Muenz-Sammelradius um 12 Pixel je Stufe. Aktiviert keine Magnet-Orbs aus der Ferne.'),
 (217,'Lingering Hex',.08,'Verlaengert Brennen, Schock und Verlangsamung um 8% je Stufe. Boss-Festhalten bleibt ausgeschlossen.'),
 (218,'Resonant Core',.025,'Direkte Treffer verursachen 2.5% mehr Schaden je Stufe gegen bereits brennende, geschockte oder verlangsamte Ziele.'),
]

# Alternatives mean at least one equipped active; all can express combined prerequisites later.
PASSIVE_REQUIREMENTS={
 206:dict(any=[101,102,105],all=[]),
 211:dict(any=[101,107,113],all=[]),
 212:dict(any=[103,112],all=[]),
 213:dict(any=[102,104,115],all=[]),
 217:dict(any=[101,102,103,104,107,112,113,115],all=[]),
 218:dict(any=[101,102,103,104,107,112,113,115],all=[]),
}

def catalog():
 out=[]
 for sid,name,mechanic,element,damage,cooldown,radius,desc in ACTIVE:
  d=dict(id=sid,name=name,type=1,max_level=9,implemented=True,mechanic=mechanic,element=element,desc=desc,
   base_damage=damage,scaling=dict(power=.5 if sid in (104,106) else (1.25 if sid==101 else 1),level=.16),
   cooldown=cooldown,cooldown_per_level=.012,projectile_speed=11,projectile_lifetime=60,projectile_count=3 if sid==105 else 1,
   explosion_radius=radius,radius_per_level=4 if radius else 0,target_range=650 if sid==108 else (380 if sid==116 else 480),
   duration=3,base_count=3,count_every=4,icon_sprite_name=f'icon_v2_{sid}',cue=f'skill_{sid}')
  d.update(ignite_dps=1,ignite_per_level=.2 if sid>=107 else 0,ignite_time=60,slow_factor=.4 if sid==104 else (.45 if sid==115 else .5),slow_time=90 if sid==104 else 60,slow_per_level=5 if sid>=107 else 0,shock_time=35 if sid>=107 else 24,chain_base=3,chain_range=160,
           shield_damage=2,shield_radius=50,shield_speed=4,shield_hit_interval=30)
  if sid==103:d['target_range']=450
  if sid==111:d['duration']=5
  if sid==114:d['duration']=3.5
  if sid==115:d['duration']=1.8
  if sid==116:d['duration']=1.1
  if sid==102:d.update(projectile_speed=10,projectile_lifetime=65)
  if sid==105:d.update(projectile_speed=13,projectile_lifetime=45)
  out.append(d)
 for sid,name,bonus,desc in PASSIVE:
  out.append(dict(id=sid,name=name,type=2,max_level=9,implemented=True,bonus_per_level=bonus,desc=desc,mechanic='passive',element=0,
    icon_sprite_name=f'icon_v2_{sid}',add_power=bonus if sid==202 else 0,add_move_speed=bonus if sid==203 else 0,
    shield_radius=50,shield_damage=2,shield_damage_per_level=1,shield_speed=4,shield_hit_interval=30,max_reduction=.6,
    projectile_interval=3,crit_multiplier=1.6,min_cooldown_factor=.6,base_radius=96,status_duration_per_level=.04,
    requirements_any=PASSIVE_REQUIREMENTS.get(sid,{}).get('any',[]),requirements_all=PASSIVE_REQUIREMENTS.get(sid,{}).get('all',[])))
 return out

def main():
 data=catalog();folder=ROOT/'FirstGame_ArtPack/spell_v2';folder.mkdir(exist_ok=True)
 (folder/'catalog.json').write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
 code='/// Generated from tests/tools/build_spell_v2_catalog.py. Execution and UI share this data.\nfunction spell_catalog() {\n static data='+json.dumps(data,ensure_ascii=False,separators=(',',':'))+';\n return data;\n}\n'
 target=ROOT/'scripts/spell_v2_catalog';target.mkdir(exist_ok=True);(target/'spell_v2_catalog.gml').write_text(code,encoding='utf-8')
 print('Emitted 18 active and 18 passive fully specified definitions')

if __name__=='__main__':main()
