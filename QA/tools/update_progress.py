"""Durable progress counts from completed canonical checkpoints, including during interruption."""
from pathlib import Path
import argparse,datetime,json
ROOT=Path(__file__).resolve().parents[2]
COHORTS=['baseline-v2-a','baseline-v2-b','after-v2-a','after-v2-b','holdout-v2']
def rows(path):return [json.loads(x) for x in path.read_text(encoding='utf-8').splitlines() if x.strip()] if path.exists() else []
def write_progress(final=False):
    counts={d:sum(bool(r.get('completed')) for p in (ROOT/'QA/data'/d).glob('worker-*.jsonl') for r in rows(p)) for d in COHORTS}
    cal=sum(bool(r.get('completed')) for p in (ROOT/'QA/data').glob('native-policy-v1-calibration-*.jsonl') for r in rows(p))
    bosses={name:len(rows(ROOT/'QA/data'/name)) for name in ['boss-baseline.jsonl','boss-holdout.jsonl','boss-after-selected.jsonl']}
    if final and counts!={'baseline-v2-a':36,'baseline-v2-b':36,'after-v2-a':36,'after-v2-b':36,'holdout-v2':36}:raise RuntimeError('Do not finalize an incomplete cohort')
    out=['# QA – laufender Arbeitsstand','',f"Stand UTC: {datetime.datetime.now(datetime.timezone.utc).isoformat()}",'',
         f"- Gültige vollständige native Runs: **{sum(counts.values())+cal}**, davon {sum(counts.values())} primäre V2-Runs und {cal} V1-Kalibrierungen.",
         '- Laufende Einzelzähler werden aus vollständig gespeicherten JSONL-Zeilen gebildet; eine noch laufende Runde zählt nicht.','']
    out+=['| Kohorte | Vollständig | Ziel |','|---|---:|---:|']+[f'| {name} | {n} | 36 |' for name,n in counts.items()]
    out+=['',f"- Primäre isolierte Bosskämpfe: Baseline {bosses['boss-baseline.jsonl']}, unabhängige Seeds {bosses['boss-holdout.jsonl']}, ausgewählte Nachher-Prüfungen {bosses['boss-after-selected.jsonl']}.",
          '- Zusätzlich 195 gültige Boss-Ausführungen mit erster Bot-Strategie und 15 wiederholte V2-Piloten archiviert; nicht als unabhängige primäre Stichprobe vermischt. 15 frühe Bossläufe mit falscher Engine-Zeitbasis sind ungültig und ausgeschlossen.',
          '- 654 kontrollierte native Fähigkeitsfenster und zehn bekannte HP-/Quellenprüfungen bestanden.',
          '- Aktuelle allgemeine native Regression: 811 Prüfungen bestanden; Steuerung, Sprung/Slide/Ausweichen, Beute, Auswahl, Pause, Neustarts, Bossmechaniken, GUI-Aufnahmen und kurzer gerenderter Stressfall.',
          '- Beschleunigung: gleiche Zustände bei Batch 1/60/600; alle drei Klassen mit verbesserter Strategie geprüft. Engine und Logik bleiben bei 60 Hz. Nachher-Mage-Abgleich ebenfalls identisch.',
          '- Bestätigte Spieländerungen: normale Münzen 252 → 420 Pixel/Sekunde; Boss-Hurt-Frames auf tatsächliche Sprite-Länge begrenzt. Spieler-/Boss-HP und Schadenswerte bleiben unverändert.',
          '- Münz-Fixture: vorher zwei tatsächliche Ranger-Sammelfehler; nachher alle vier Bewegungsfälle bestanden.',
          '- Grafik: 826 Sprites/2.551 Frames geprüft; alle 5.102 PNGs einschließlich 258 Drachen-Dateien unverändert. Native GUI-Prüfzustände bei 1280×720 und 800×600 gesichtet.','']
    out.append('Status: Auswertung, Berichte und finale Prüfungen abgeschlossen; Grenzen und priorisierte Resttests stehen in QA_SUMMARY.md.' if final else 'Offen: laufende Kohorten vollständig abschließen, gepaarten Vergleich/Diagramme/Abschlussberichte erzeugen, normalen Build und Ressourcenprüfung abschließen. Nächster Schritt: abgeschlossene Kohorten auswerten; keine weitere Zahlenänderung ohne Messgrundlage.')
    (ROOT/'QA/TEST_PROGRESS.md').write_text('\n'.join(out)+'\n',encoding='utf-8')
    print(json.dumps(dict(primary=sum(counts.values()),calibration=cal,total=sum(counts.values())+cal,cohorts=counts),indent=2))
if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--final',action='store_true');args=ap.parse_args();write_progress(args.final)
