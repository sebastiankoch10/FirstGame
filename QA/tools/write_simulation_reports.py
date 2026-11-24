"""Generate the two native full-run reports from completed, reviewed v2 cohorts.

This script summarizes observed production-GML runs. It never generates gameplay
observations. Run analyze_qa.py on the same cohort files first. Calibration runs
are counted separately and do not enter the primary balance comparison.
"""
from collections import Counter
from pathlib import Path
import hashlib
import json
import statistics

from analyze_qa import describe, wilson

ROOT = Path(__file__).resolve().parents[2]
QA = ROOT / "QA"
DATA = QA / "data"
COHORTS = ("baseline-v2-a", "baseline-v2-b", "after-v2-a", "after-v2-b", "holdout-v2")
PHASES = ("baseline", "after", "holdout")
CLASSES = ("Sword", "Mage", "Ranger")
PERSONAS = ("beginner", "average", "experienced")
CLASS_NAMES = {"Sword": "Schwertkämpfer", "Mage": "Zaubermeisterin", "Ranger": "Waldläufer"}
PHASE_NAMES = {"baseline": "Vorher", "after": "Nachher, gepaart", "holdout": "Nachher, Holdout"}
PERSONA_NAMES = {"beginner": "Anfänger-Bot", "average": "Durchschnitts-Bot", "experienced": "Erfahrener Bot"}


def load(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def read(paths):
    rows = []
    for path in paths:
        for line in path.read_text(encoding="utf-8-sig").splitlines():
            if line.strip():
                row = json.loads(line)
                row["_path"] = path.relative_to(ROOT).as_posix()
                rows.append(row)
    return rows


def valid(row):
    return (row.get("completed") and row.get("record_type", "full_run") == "full_run"
            and row.get("end_reason") in ("death", "survived_1800_seconds_censored"))


def fmt(value, digits=1):
    if value is None:
        return "—"
    return f"{value:,.{digits}f}".replace(",", " ").replace(".", ",")


def pct(value):
    return "—" if value is None else fmt(value * 100) + " %"


def bounds(values, scale=1):
    return "–".join(fmt(v * scale) for v in values) if values and values[0] is not None else "—"


def mean(rows, field):
    return statistics.mean(r.get(field, 0) for r in rows) if rows else 0


def group(rows, phase, klass=None, persona=None):
    return [r for r in rows if r["phase"] == phase
            and (klass is None or r["class_name"] == klass)
            and (persona is None or r["persona"] == persona)]


def table(headers, rows):
    return ("| " + " | ".join(headers) + " |\n| " + " | ".join("---" for _ in headers)
            + " |\n" + "\n".join("| " + " | ".join(str(v) for v in row) + " |" for row in rows))


def summary_lookup(analysis, field):
    return {(x["phase"], x["class_name"], x["persona"]): x for x in analysis[field]}


def source_totals(rows):
    totals = Counter()
    for row in rows:
        for source in row.get("metrics", {}).get("sources", {}).values():
            label = "Startwaffe" if source.get("sid") == 0 else "Fähigkeiten"
            for metric in ("damage", "attempted", "dot_damage", "kills", "normal_damage", "boss_damage"):
                totals[label + ":" + metric] += source.get(metric, 0)
    return totals


def build(row):
    def side(key):
        return ", ".join(f"{int(s['id'])}:{int(s['level'])}" for s in sorted(row.get(key, []), key=lambda s: s["id"])) or "leer"
    return side("active") + " / " + side("passive")


def ending_sources(rows):
    out = Counter()
    for row in rows:
        if row["end_reason"] != "death":
            continue
        source = (row.get("metrics", {}).get("last_fatal") or {}).get("source", {})
        label = source.get("kind", "nicht zugeordnet")
        if source.get("boss"):
            label += ":" + source["boss"]
        if source.get("ability"):
            label += ":" + str(source["ability"])
        out[label] += 1
    return out


def full_run_sources(rows):
    """Actual observed contributions; never an equal-exposure DPS ranking."""
    rs = group(rows, "after")
    catalog = {int(s["id"]): s["name"] for s in load(ROOT / "FirstGame_ArtPack/spell_v2/catalog.json")}
    stats = {}
    held = Counter()
    for row in rs:
        held.update({int(s["id"]) for s in row.get("active", []) + row.get("passive", [])})
        for source in row.get("metrics", {}).get("sources", {}).values():
            sid = int(source["sid"])
            target = stats.setdefault(sid, Counter())
            target.update({k: v for k, v in source.items() if k not in ("sid", "stage") and isinstance(v, (int, float))})
    held[0] = len(rs)
    damage = sum(s["damage"] for s in stats.values())
    kills = sum(s["kills"] for s in stats.values())
    ids = [0, *range(101, 119), *sorted(sid for sid, s in stats.items()
                                      if sid >= 200 and (s["damage"] > 0 or s["healing"] > 0))]
    labels = {sid: "0: Startwaffen aller Klassen" if sid == 0 else f"{sid}: {catalog.get(sid, 'unbenannt')}" for sid in ids}
    activity, contributions = [], []
    for sid in ids:
        s = stats.get(sid, Counter())
        activity.append([labels[sid], held[sid], fmt(s["casts"], 0), fmt(s["projectiles"], 0),
                         fmt(s["projectiles_hit"], 0), fmt(s["projectiles_expired_without_hit"], 0),
                         fmt(s["hits"], 0), fmt(s["healing"])])
        contributions.append([labels[sid], fmt(s["attempted"], 0), fmt(s["damage"], 0), fmt(s["overkill"], 0),
                              fmt(s["dot_damage"], 0), fmt(s["normal_damage"], 0), fmt(s["boss_damage"], 0),
                              fmt(s["kills"], 0), pct(s["damage"] / damage if damage else None),
                              pct(s["kills"] / kills if kills else None)])
    return ["## Fähigkeitenbeiträge in vollständigen Nachher-Runs", "",
            f"Diese Tabellen summieren ausschließlich die **{len(rs)} gepaarten Nachher-Runs**, ohne Holdout "
            "und ohne kontrollierte Benchmarks. Sie zeigen tatsächliche Nutzung und Wirkung im vorhandenen "
            "Spiel. Auswahlwahrscheinlichkeit, früh/spät erlernte Stufe, Klassen, Gegnerzahl und Überlebensdauer "
            "sind unterschiedlich: Die Summen sind **kein Vergleich bei gleicher Einsatzchance und keine "
            "intrinsische DPS-Rangliste**. Ein seltener gewählter Zauber kann trotz kleiner Gesamtsumme stark sein. "
            "„Runs gelernt“ zählt Runs mit der Fähigkeit im Endbuild; „0“ fasst die Startwaffen aller Klassen "
            "und Komboschritte zusammen.", "",
            table(["Quelle", "Runs gelernt", "Auslösungen", "Projektile", "Projektile mit Treffer", "Ohne Treffer abgelaufen", "Schadensereignisse", "Heilung HP"], activity), "",
            "Ein Schadensereignis kann ein einzelner Flächen-/Feld-/DoT-Tick sein. Eine Auslösung und ein "
            "Projektil sind unterschiedliche Einheiten. Noch fliegende Projektile zählen nicht als abgelaufene "
            "Fehlschüsse; mehrfach treffende Projektile zählen bei „mit Treffer“ einmal. Aus den Ereigniszahlen "
            "darf deshalb keine einheitliche Trefferwahrscheinlichkeit aller Fähigkeitentypen berechnet werden.", "",
            table(["Quelle", "Versucht", "Effektiver HP-Verlust", "Overkill", "DoT enthalten", "Normale Gegner HP", "Boss HP", "Kills", "Schadenanteil", "Killanteil"], contributions), "",
            "Effektiver Schaden ist tatsächlich abgezogenes Gegner-HP; Overkill ist versuchter Schaden "
            "oberhalb des noch verfügbaren HP. DoT ist bereits Teil des effektiven Schadens und wird nicht "
            "zusätzlich addiert. Normal-/Boss-Spalten teilen denselben effektiven Schaden auf. Die Anteile "
            "beziehen sich auf alle erfassten Schadens-/Killquellen dieser Kohorte; der letzte schädigende "
            "Treffer erhält den Kill. Heilung wird separat in tatsächlichen HP ausgewiesen, nicht als Schaden.", "",
            "Passive Verstärkungen bleiben beim ursprünglichen Angriff und erhalten keinen erfundenen "
            "zusätzlichen Schaden. Passive Fähigkeiten erscheinen hier nur mit einer eigenen tatsächlich "
            "schädigenden/heilenden Mechanik, etwa Orbit Shield (201) oder Renewal (215). Rüstung, "
            "Geschwindigkeit, Abklingzeit und andere Modifikatoren werden dadurch nicht als wirkungslos "
            "bewertet. Ihre kontrollierten Vergleichstests stehen in [ABILITY_BALANCE.md](ABILITY_BALANCE.md).", ""]


def report_classes(rows, analysis):
    pooled = summary_lookup(analysis, "class_pooled")
    strata = summary_lookup(analysis, "class_persona")
    lines = ["# Klassenbalance aus nativen vollständigen Runs", "",
             "Diese Auswertung gilt für die drei dokumentierten Bot-Regeln und die beobachteten Seeds. "
             "Sie bestimmt keine universell stärkste Klasse für Menschen. Vorher und Nachher verwenden "
             "dieselben Klasse/Seed/Bot-Kombinationen; der Holdout verwendet neue Seeds. "
             "Methodik, Stichprobenumfang und Grenzen stehen in [SIMULATION_REPORT.md](SIMULATION_REPORT.md).", "",
             "## Überleben, Streuung und Rangfolge", "",
             "Alle Zeiten sind Sekunden. Der Mittelwert ist auf 1.800 s beschränkt; Überlebende am Zeitdeckel "
             "wären rechtszensiert. Die 95-%-Intervalle des Mittelwerts sind ein deterministischer Bootstrap "
             "mit 1.000 Wiederholungen der beobachteten Runs. Min–Max und Standardabweichung zeigen die "
             "Streuung; kleine Gruppen erlauben keine präzise Rangordnung.", ""]
    values = []
    for phase in PHASES:
        for klass in CLASSES:
            s = pooled[(phase, klass, "pooled")]
            d = s["restricted_survival_seconds"]
            values.append([PHASE_NAMES[phase], CLASS_NAMES[klass], s["n"], fmt(d["mean"]), fmt(d["median"]),
                           bounds(d["mean_bootstrap95"]), fmt(d["sd"]), f"{fmt(d['minimum'])}–{fmt(d['maximum'])}"])
    lines += [table(["Kohorte", "Klasse", "n", "Mittel", "Median", "95-%-KI Mittel", "SD", "Min–Max"], values), ""]
    ranked = sorted(CLASSES, key=lambda c: pooled[("after", c, "pooled")]["restricted_survival_seconds"]["mean"], reverse=True)
    holdrank = sorted(CLASSES, key=lambda c: pooled[("holdout", c, "pooled")]["restricted_survival_seconds"]["mean"], reverse=True)
    lines += [f"Nach mittlerer beobachteter Überlebenszeit lautet die Rangfolge der gepaarten Nachher-Stichprobe: "
              f"{' → '.join(CLASS_NAMES[c] for c in ranked)}. Im unabhängigen Holdout: "
              f"{' → '.join(CLASS_NAMES[c] for c in holdrank)}. "
              "Das sind deskriptive Bot-Ergebnisse. HP, Bewegung, Waffenreichweite, Upgrade-Angebote, "
              "Sammelverhalten und die Anpassung der Bot-Regel an eine Klasse wirken gemeinsam.", "",
              "Eine konkrete statische Grenze der Klassenpolitik: Der Bot bevorzugt für die Zaubermeisterin "
              "etwa 190 Einheiten Abstand zum nächsten Gegner; der eigene Stab-Bogen reicht 155, der Kreis "
              "130 Einheiten. Beide können andere nahe Gegner treffen, aber diese Zielabstandsregel nutzt "
              "den gesamten Waffenzyklus nicht garantiert optimal. Wegwahl, Zielabstand und die Anpassung "
              "der KI sind mögliche Störfaktoren. Daraus folgt weder ein nachgewiesener Produktionsfehler "
              "noch eine belastbare Forderung nach höheren Klassen-HP.", "",
              "## Drei Bot-Strata", "",
              "Die Bezeichnungen sind technische Profile, keine empirisch gemessenen menschlichen Skillgruppen. "
              "Reaktionszeit / Gefahrgewicht: Anfänger 0,65 s / 0,65, Durchschnitt 0,30 s / 1,0, erfahren 0,12 s / 1,2. "
              "Anfänger nutzen weder Sprung noch Dodge; die beiden anderen verwenden legale, zeitlich geplante Eingaben. "
              "Alle nutzen eine lokale Bewertung von acht Bewegungsrichtungen. Die Reihenfolge der Ergebnisse muss "
              "deshalb nicht monoton mit dem Profilnamen steigen.", ""]
    values = []
    for phase in PHASES:
        for klass in CLASSES:
            for persona in PERSONAS:
                s = strata[(phase, klass, persona)]
                d = s["restricted_survival_seconds"]
                values.append([PHASE_NAMES[phase], CLASS_NAMES[klass], PERSONA_NAMES[persona], s["n"],
                               fmt(d["mean"]), fmt(d["median"]), bounds(d["mean_bootstrap95"])])
    lines += [table(["Kohorte", "Klasse", "Bot", "n", "Mittel s", "Median s", "95-%-KI Mittel s"], values), "",
              "## Erreichte Meilensteine", "",
              "Jede Zelle enthält erreichte Runs / n und das 95-%-Wilson-Intervall des Anteils. "
              "Ein gemessener Anteil von 0 % bedeutet bei diesen Stichproben keine bewiesene Unmöglichkeit.", ""]
    values = []
    for phase in PHASES:
        for klass in CLASSES:
            s = pooled[(phase, klass, "pooled")]
            cells = []
            for m in s["milestones"]:
                if m["minute"] in (5, 10, 15, 20, 25, 30):
                    cells.append(f"{m['reached']}/{m['n']} ({bounds(m['wilson95'], 100)} %)" )
            values.append([PHASE_NAMES[phase], CLASS_NAMES[klass], *cells])
    lines += [table(["Kohorte", "Klasse", "5 min", "10 min", "15 min", "20 min", "25 min", "30 min"], values), "",
              "## Gepaarter Vorher/Nachher-Vergleich", "",
              "Die Änderung betrifft den normalen Münz-Zug von 252 auf 420 Einheiten/s; die zusätzliche "
              "Boss-Draw-Frame-Begrenzung ändert keine beabsichtigte Kampfregel. Die folgende Differenz ist "
              "Nachher minus Vorher bei identischem Start-Seed, Klasse und Bot. Der zufällige Spielverlauf "
              "kann nach einer veränderten Einsammlung divergieren.", ""]
    values = []
    for klass in CLASSES:
        pairs = [p for p in analysis["paired_before_after"] if p["class_name"] == klass]
        d = describe([p["delta"] for p in pairs])
        values.append([CLASS_NAMES[klass], len(pairs), fmt(d["mean"]), fmt(d["median"]),
                       bounds(d["mean_bootstrap95"]), sum(p["delta"] > 1e-5 for p in pairs),
                       sum(p["delta"] < -1e-5 for p in pairs), sum(abs(p["delta"]) <= 1e-5 for p in pairs)])
    lines += [table(["Klasse", "Paare", "Δ Mittel s", "Δ Median s", "95-%-KI Δ Mittel s", "Länger", "Kürzer", "Gleich"], values), "",
              "Ein positiver Mittelwert belegt keinen garantierten Vorteil in jedem Run. Der unabhängige Holdout "
              "prüft neue Seeds nach der Korrektur und besitzt keinen gepaarten Vorher-Gegenpart.", "",
              "## Tatsächlicher Schadensbeitrag der Startwaffe", "",
              "Anteile sind aus summiertem tatsächlich abgezogenem Gegner-HP berechnet, nicht aus Nennschaden "
              "oder dem Mittel einzelner Prozentwerte. Der DoT-Anteil ist bereits im effektiven Schaden enthalten. "
              "Kills bezeichnen den der letzten Schadensquelle zugeordneten Kill, keinen alleinigen Verdienst.", ""]
    values = []
    for phase in PHASES:
        for klass in CLASSES:
            rs = group(rows, phase, klass)
            t = source_totals(rs)
            damage = t["Startwaffe:damage"] + t["Fähigkeiten:damage"]
            kills = t["Startwaffe:kills"] + t["Fähigkeiten:kills"]
            attempted = t["Startwaffe:attempted"] + t["Fähigkeiten:attempted"]
            dot = t["Startwaffe:dot_damage"] + t["Fähigkeiten:dot_damage"]
            values.append([PHASE_NAMES[phase], CLASS_NAMES[klass], fmt(attempted, 0), fmt(damage, 0),
                           pct(t["Startwaffe:damage"] / damage if damage else None),
                           pct(t["Startwaffe:kills"] / kills if kills else None), pct(dot / damage if damage else None)])
    lines += [table(["Kohorte", "Klasse", "Versuchter Schaden", "Effektiver Schaden", "Startwaffe Schaden", "Startwaffe Kills", "DoT Schaden"], values), "",
              "Das kontrollierte native 15-s-Fenster ohne hinzugewählte Fähigkeiten ergibt gegen ein stationäres Ziel "
              "38,00 / 34,53 / 28,40 DPS für Schwert / Magie / Waldläufer, gegen acht stationäre Ziele "
              "222,93 / 235,67 / 88,00 DPS. Diese Fixtures erklären Zielgeometrie und Mehrzielwirkung, "
              "ersetzen weder bewegte Runs noch menschliche Klassenstärke. Details: [ABILITY_BALANCE.md](ABILITY_BALANCE.md).", "",
              "## Kills, eingesammelte XP und Auswahlfortschritt", "",
              "Endwerte hängen stark von der Überlebensdauer ab. XP/Kill ist hier das Verhältnis der Summen, "
              "kein gleichzeitiger Test bei gleicher Kampfdauer. Münzen am Boden, Bossanteile, Entfernen ferner Gegner "
              "und verzögerte Einsammlung verhindern die Gleichsetzung Kills = eingesammelte XP. "
              "`coins` ist der exportierte aktuelle Rundenzähler; `xp_earned` zählt verdiente Münz-XP.", ""]
    values = []
    for phase in PHASES:
        for klass in CLASSES:
            rs = group(rows, phase, klass)
            kills = sum(r["kills"] for r in rs)
            xp = sum(r["xp_earned"] for r in rs)
            choices = [sum(c.get("chosen", -1) > 0 for c in r.get("offers_choices", [])) for r in rs]
            values.append([PHASE_NAMES[phase], CLASS_NAMES[klass], fmt(mean(rs, "level")), fmt(mean(rs, "kills")),
                           fmt(mean(rs, "xp_earned")), pct(xp / kills if kills else None), fmt(mean(rs, "coins")),
                           fmt(statistics.mean(choices)), int(max(r["level"] for r in rs))])
    lines += [table(["Kohorte", "Klasse", "Level Ø", "Kills Ø", "XP Ø", "XP/Kill", "coins Ø", "Auswahlen Ø", "Max. Level"], values), "",
              "Der Waldläufer bewegt sich bereits ohne Passivbonus mit 252 Einheiten/s. Eine normale Münze "
              "mit ebenfalls 252 Einheiten/s konnte ihn in der kontrollierten geraden Verfolgung aus 80 Einheiten "
              "Rückstand nicht einholen. Die echte Player-/Coin-Step-Fixture scheiterte vorher in beiden "
              "Waldläufer-Fällen, nach der Korrektur bestehen alle vier Fälle, einschließlich Fleet Footed 9. "
              "Das belegt den konkreten Einsammelfehler; die Run-Tabellen messen dessen mögliche Gesamtfolgen. "
              "Daten: [moving-coin-baseline.json](data/moving-coin-baseline.json), [moving-coin-after.json](data/moving-coin-after.json).", "",
              "## Zufallsangebote und Build-Vergleiche", "",
              "Angebote nutzen den separaten reproduzierbaren Produktions-`choice_rng`. Der Bot wählt jeweils "
              "den höchsten Wert aus einem Zufallsanteil 0–3; die beiden fortgeschrittenen Profile bevorzugen "
              "frühe aktive Fähigkeiten, vorhandene Upgrades und bei niedrigen HP Heilung/Schutz. Beim Waldläufer "
              "erhalten die vorhandenen IDs 204/202/206/208 zusätzlich 0,5. Diese kleine Klassenvorliebe ist ein "
              "Bestandteil des Tests und ein möglicher Störfaktor, kein Beleg für eine optimale Buildstrategie.", ""]
    values = []
    for phase in PHASES:
        for klass in CLASSES:
            rs = group(rows, phase, klass)
            chosen = Counter(int(c["chosen"]) for r in rs for c in r.get("offers_choices", []) if c.get("chosen", -1) > 0)
            offers = {tuple(int(x) for x in c.get("offered", [])) for r in rs for c in r.get("offers_choices", [])}
            values.append([PHASE_NAMES[phase], CLASS_NAMES[klass], len({build(r) for r in rs}), len(offers),
                           ", ".join(f"{sid} ({n})" for sid, n in chosen.most_common(5)) or "—"])
    lines += [table(["Kohorte", "Klasse", "Verschiedene Endbuilds", "Verschiedene Angebotsdreier", "Häufigste gewählte IDs (Anzahl Investitionen)"], values), "",
              "Die längsten beobachteten Nachher-Runs je Klasse sind Beispiele, keine als optimal bestätigten Builds. "
              "Notation: aktive IDs:Level / passive IDs:Level.", ""]
    values = []
    for klass in CLASSES:
        candidates = [r for r in rows if r["phase"] in ("after", "holdout") and r["class_name"] == klass]
        best = max(candidates, key=lambda r: r["seconds"])
        values.append([CLASS_NAMES[klass], best["run_id"], fmt(best["seconds"]), int(best["level"]), build(best)])
    lines += [table(["Klasse", "Run", "Sekunden", "Level", "Endbuild"], values), "",
              "Länger überlebende Runs erhalten mehr Angebote und können stärkere Builds erst dadurch erreichen. "
              "Eine Korrelation zwischen Auswahl und Überleben ist daher keine kausale Tier-Liste. "
              "Die Zahl möglicher Builds übersteigt diese Stichprobe erheblich. Gleiche Seeds balancieren die "
              "Startbedingungen der Klassen, aber unterschiedliche Angriffe und Effekte verbrauchen den gemeinsamen "
              "Welt-Zufallsstrom verschieden; dieselben Seeds erzwingen keine identischen Spawnfolgen. "
              "Aus diesen Daten folgt keine formale menschliche Fairnessbewertung.", ""]
    return "\n".join(lines)


def report_simulation(rows, calibration, manifests, analysis):
    counts = Counter(r["phase"] for r in rows)
    total = len(rows) + len(calibration)
    lines = ["# Bericht der nativen Monte-Carlo-Prüfung", "",
             f"Es liegen **{len(rows)} gültige vollständige Runs der Hauptstichprobe** und **{len(calibration)} "
             f"zusätzliche vollständige Kalibrierungsruns** vor, insgesamt **{total}**. "
             "Das gewünschte Ziel von 3.000 vollständigen Runs wurde nicht erreicht. Alle nachfolgend als Runs "
             "bezeichneten Beobachtungen sind echte Produktions-GML im nativen GameMaker-Runner, keine "
             "Python-Ersatzsimulation. Boss-Einzelkämpfe, Zeitfenster und Assertions sind getrennte Prüfeinheiten.", "",
             "## Stichprobe und Abschlusskriterien", ""]
    values = []
    for phase in PHASES:
        rs = group(rows, phase)
        values.append([PHASE_NAMES[phase], len(rs), ", ".join(f"{c}: {len(group(rows, phase, c))}" for c in CLASSES),
                       ", ".join(f"{p}: {sum(r['persona'] == p for r in rs)}" for p in PERSONAS),
                       sum(r["end_reason"] == "death" for r in rs),
                       sum(r["end_reason"] == "survived_1800_seconds_censored" for r in rs)])
    lines += [table(["Kohorte", "Runs", "Klassen", "Botprofile", "Echter Tod", "Bei 30 min zensiert"], values), "",
              "Ein vollständiger Run startet im normalen leeren Fähigkeitsbuild mit der eigenen Startwaffe, "
              "normalen HP, normalen Gegnern und unveränderter Spieluhr. Er endet durch tatsächlichen Tod oder "
              "nach 1.800 simulierten Sekunden als rechtszensierter Überlebender. Es gibt keinen erzwungenen Tod "
              "und kein verkürztes Run-Ende. Baseline- und Nachher-Paare besitzen identischen Seed, Klasse und "
              "Botprofil. Die Primärgruppen sind innerhalb jeder Klasse gleich über die drei Profile verteilt. "
              "Der Holdout startet mit neuen Seeds und wurde nicht als gepaarte Effektmessung behandelt.", "",
              f"Die {len(calibration)} gültigen `visible-greedy-v1`-Kalibrierungsruns waren vollständige natürliche "
              "Runs, deckten jedoch zu frühes Dodge und unpassende Sprünge gegen `all`/hohe Angriffe im Bot auf. "
              "Sie zählen zum geleisteten vollständigen Testumfang, gehen aber nicht in Klassenrangfolgen oder "
              "Vorher/Nachher-Effekte ein. Frühere ungültige FPS-10.000-Piloten und unvollständige Fixtures "
              "werden weder hier noch in der Hauptstichprobe als gültige vollständige Runs gezählt.", "",
              "## Ausführung und Reproduzierbarkeit", "",
              "Die Runtime ist GameMaker 2024.14.4.268. Jeder logische Schritt dauert exakt 1/60 s, "
              "`room_speed` bleibt 60. Beschleunigung bündelt vollständige Steps; sie verändert nicht die "
              "Spielzeit. Batch-Parität 1/60/600 sowie die zusätzlichen v2-Klassenproben sind in "
              "[SIMULATOR_FIDELITY.md](SIMULATOR_FIDELITY.md) und [native-fidelity-v2.json](data/native-fidelity-v2.json) "
              "belegt. Batch-Parität beweist Reproduzierbarkeit, keine vollständig formale Gleichheit jeder "
              "Engine-Instanzreihenfolge mit einer menschlichen Sitzung.", "",
              "Baseline-Artefakt: `output/native-mc-baseline/20261123-174801`. Nachher und Holdout: "
              "`output/native-mc-after/20261123-175857`. Diese kopierten Produktionsquellen unterscheiden sich "
              "nur durch die dokumentierte normale Münzgeschwindigkeit 252 → 420 und die Begrenzung des "
              "Boss-Trefferreaktions-Drawframes. Ressourcen, Klassen, Fähigkeiten und Gegnertypen wurden nicht erweitert. "
              "Die Änderungen und ihr konkreter Nachweis stehen in [BALANCE_CHANGES.md](BALANCE_CHANGES.md).", "",
              "Die Rohdaten enthalten unter anderem Seed, Persona, Endgrund, HP, Level, Kills, XP, aktuelle Münzen, "
              "aktive/passive Stufen, alle angebotenen und gewählten IDs, Bossbegegnungen, Zeitstichproben, "
              "Schadensquellen, versuchten/effektiven/DoT-Schaden und den Zustands-Hash. "
              "`data/analysis.json` enthält Quellprüfsummen; `data/runs.csv` ist die flache Übersicht. "
              "Das Auswerteskript liest ausschließlich abgeschlossene Rohdatensätze, prüft eindeutige Run-IDs "
              "und erzeugt keine synthetischen Spielbeobachtungen.", ""]
    values = []
    for name, manifest in manifests.items():
        rs = [r for r in rows if f"/{name}/" in r["_path"]]
        values.append([name, len(rs), manifest["seedstart"], manifest["workers"], manifest["batchsize"],
                       fmt(manifest["elapsed_wall_seconds"]), "ja" if manifest["completed"] else "nein"])
    lines += [table(["Rohdatenordner unter data/", "Runs", "Seedstart", "Worker", "Batch", "Wandzeit s", "Abgeschlossen"], values), "",
              "Jeder Ordner enthält `cohort.json` mit Artefakt-/EXE-Prüfsumme und Worker-Logs sowie "
              "`worker-0.jsonl` bis `worker-3.jsonl`. Bei einer Wiederholung sind neue Ausgabeordner zu verwenden; "
              "vorhandene Checkpoints werden nicht als neue Beobachtungen dupliziert.", "",
              "## Beobachtete Ergebnisse und Unsicherheit", "",
              "Die vollständigen Klassen-/Bot-Tabellen einschließlich Mittelwert, Median, Streuung, "
              "95-%-Bootstrap-Intervallen, Wilson-Meilensteinen, Startwaffenanteilen und XP/Kill stehen in "
              "[CLASS_BALANCE.md](CLASS_BALANCE.md). Die Konfidenzintervalle beschreiben die beobachtete "
              "Seed-Stichprobe unter festen Regeln; sie umfassen keine Modellunsicherheit über menschliches "
              "Verhalten. Ein Bootstrap-Resample ist keine zusätzliche Spielrunde. Es gibt keine Behauptung "
              "einer universellen besten Klasse oder eines universell besten Builds.", ""]
    values = []
    for phase in PHASES:
        rs = group(rows, phase)
        d = describe([r["seconds"] for r in rs])
        values.append([PHASE_NAMES[phase], len(rs), fmt(d["mean"]), fmt(d["median"]),
                       fmt(d["maximum"]),
                       sum(r["seconds"] >= 300 - 1e-5 for r in rs), sum(r["seconds"] >= 600 - 1e-5 for r in rs),
                       sum(r["seconds"] >= 900 - 1e-5 for r in rs), sum(r["seconds"] >= 1800 - 1e-5 for r in rs)])
    lines += [table(["Kohorte", "n", "Mittel s", "Median s", "Maximum s", "5 min", "10 min", "15 min", "30 min"], values), "",
              "Die Gesamtzeilen mischen drei Klassen mit teilweise gemeinsamen Start-Seeds; deshalb wird "
              "hier kein unabhängiges Konfidenzintervall über alle Zeilen behauptet. Die ausgewiesenen "
              "Überlebensintervalle stehen je Klasse und je Bot-Stratum im Klassenbericht.", "",
              "Die gewöhnlichen Gegner skalieren ihre HP mit `1 + Minute*0,07`, den Schaden mit "
              "`1 + Minute*0,06`; Population und Boss-HP skalieren zusätzlich nach dem vorhandenen Zeitplan. "
              "Das ist der implementierte Skalierungsmechanismus. Seine langfristige Fairness lässt sich nur "
              "für Zeitbereiche mit tatsächlich beobachteten Überlebenden bewerten.", "",
              "## Tatsächlich beobachteter zeitlicher Fortschritt", "",
              "Die folgenden Produktions-/Harness-Snapshots sind bedingt auf das Erreichen des Zeitpunkts. "
              "Die Mittelwerte der Überlebenden sind keine Prognose für den durchschnittlichen neuen Run. "
              "HP, Gegnerzahl und Gegnerwerte stammen aus `timecourse`, verdiente XP aus den vorhandenen "
              "`progression_samples`. Falls beide Proben um einen Tick auseinanderliegen, werden ihre jeweiligen "
              "exportierten Werte unverändert verwendet.", ""]
    values = []
    for phase in PHASES:
        rs = group(rows, phase)
        for minute in (5, 10, 15, 20, 25, 30):
            samples = [s for r in rs for s in r.get("timecourse", []) if abs(s["seconds"] - minute * 60) < .1]
            prog = [s for r in rs for s in r.get("progression_samples", []) if abs(s["seconds"] - minute * 60) < .1]
            if not samples:
                values.append([PHASE_NAMES[phase], minute, 0, *(["nicht beobachtet"] * 7)])
                continue
            av = lambda field: fmt(statistics.mean(s.get(field, 0) for s in samples))
            xp = fmt(statistics.mean(s["earned_coin_xp"] for s in prog)) if prog else "nicht exportiert"
            values.append([PHASE_NAMES[phase], minute, len(samples), av("level"), xp, av("hp"), av("ability_steps"),
                           av("enemy_count"), av("mean_enemy_remaining_hp"), av("mean_enemy_attack_damage")])
    lines += [table(["Kohorte", "Minute", "n Snapshots", "Level Ø", "XP Ø", "HP Ø", "Investitionen Ø", "Gegner Ø", "Gegner-Rest-HP Ø", "Gegner-Angriff Ø"], values), ""]
    late15 = sum(r["seconds"] >= 900 - 1e-5 for r in rows)
    late30 = sum(r["seconds"] >= 1800 - 1e-5 for r in rows)
    lines += [f"In der Hauptstichprobe erreichen {late15} Runs Minute 15 und {late30} Minute 30. "
              "Wo die Tabelle keine Beobachtungen enthält, fehlen gemessene Aussagen zu Level, XP, Slots, "
              "späten Bossen und Dauerüberleben ausdrücklich. Isolierte Boss-Tests schließen diese Lücke "
              "für vollständige Run-Progression nicht.", ""]
    lines += full_run_sources(rows)
    lines += ["## Vollausbau: statische Kosten und beobachtete Reichweite", "",
              "Vorhanden sind 18 aktive und 18 passive Fähigkeiten, je maximal Stufe 9, bei sechs aktiven "
              "und sechs passiven Slots. Ein vollständiger Build benötigt somit **108 gültige Investitionen**. "
              "Die Startwaffe belegt keinen Slot und ersetzt keine dieser Investitionen. Bei sieben erfolgreich "
              "eingesammelten Boss-Truhen würden mindestens 101 normale Levelaufstiege benötigt, also Level 102. "
              "Die Summe der implementierten XP-Kosten bis dahin beträgt **24.922 XP**. Das ist eine statische "
              "Untergrenze unter diesen Annahmen, kein gemessener Zeitpunkt für Vollausbau und keine Garantie "
              "passender Angebote. Zwischen normalen XP-Auswahlen liegen mindestens sechs Spielsekunden.", ""]
    max_steps = max(sum(int(s["level"]) for s in r.get("active", []) + r.get("passive", [])) for r in rows)
    max_level = max(int(r["level"]) for r in rows)
    complete_builds = sum(sum(int(s["level"]) for s in r.get("active", []) + r.get("passive", [])) >= 108 for r in rows)
    lines += [f"Gemessenes höchstes Endlevel: **{max_level}**. Größter beobachteter Endbuild: **{max_steps}/108 "
              f"Investitionen**. Vollständig ausgebaute Hauptstichproben-Runs: **{complete_builds}/{len(rows)}**. "
              "Die Frage, ob gewöhnliche Spieler bis Minute 15/30 sinnvoll voll ausbauen können, bleibt damit "
              "ohne hinreichenden vollständigen Langzeitnachweis offen. Es wurden keine fiktiven späten Werte ergänzt.", "",
              ]
    for r in rows:
        if sum(int(s["level"]) for s in r.get("active", []) + r.get("passive", [])) < 108:
            continue
        investments = [c for c in r.get("offers_choices", []) if c.get("chosen", -1) > 0]
        timing = (f"Die 108. gültige Auswahl erfolgte bei {fmt(investments[107]['seconds'])} s "
                  f"({fmt(investments[107]['seconds']/60, 2)} min). " if len(investments) >= 108 else "")
        lines += [f"Konkreter beobachteter Vollausbau: `{r['run_id']}`, {CLASS_NAMES[r['class_name']]}, "
                  f"{PERSONA_NAMES[r['persona']]}. {timing}Der Run endete als `{r['end_reason']}` "
                  f"bei {fmt(r['seconds'])} s mit {fmt(r['hp'])}/{fmt(r['max_hp'])} HP, "
                  f"{int(r['bosses_defeated'])} besiegten Bossen und {int(r['xp_earned'])} verdienten Münz-XP. "
                  "Das belegt Erreichbarkeit in diesem einen natürlichen Bot-Run, keine typische menschliche "
                  "Ausbauzeit und kein besiegtes 30-Minuten-Endboss-Ereignis.", ""]
    lines += ["## Tatsächliche Todesquellen", "",
              "Der letzte tödliche Treffer ist eine Attribution des Run-Endes. Frühere Schadenstypen können "
              "wesentlich beigetragen haben; diese Tabelle misst weder Unvermeidbarkeit noch alleinige Ursache.", ""]
    values = [[PHASE_NAMES[phase], source, n] for phase in PHASES for source, n in ending_sources(group(rows, phase)).most_common()]
    lines += [table(["Kohorte", "Letzte tödliche Quelle", "Runs"], values), "",
              "Boss-Einzelkämpfe und Warn-/Trefferanalysen sind in [BOSS_BALANCE.md](BOSS_BALANCE.md) getrennt "
              "ausgewertet. Geometrische Flächenexposition und Kontaktzählung bei Projektilen besitzen "
              "verschiedene Nenner. Treffer eines lokalen Bots beweisen keine technische Unvermeidbarkeit.", "",
              "## Gemessene Laufzeit und das nicht erreichte 3.000-Run-Ziel", "",
              "Die folgende Hochrechnung verwendet ausschließlich die abgeschlossenen Kohorten auf dieser "
              "Maschine. Pro Zeile wird deren beobachtete Wandzeit mit `3000 / abgeschlossene Runs` multipliziert. "
              "Die vier Worker einer Kohorte liefen teils neben anderen Kohorten; Betriebssystemlast und "
              "Konkurrenz sind in diesen Zeiten enthalten. Es handelt sich um eine bedingte lineare Projektion "
              "für denselben Run-Mix und dieselben Bedingungen, nicht um einen nachgewiesenen Hardwaredeckel "
              "oder eine Ausrede mit erfundener Maximalleistung.", ""]
    values = []
    for name, manifest in manifests.items():
        n = sum(f"/{name}/" in r["_path"] for r in rows)
        seconds = manifest["elapsed_wall_seconds"]
        values.append([name, n, fmt(seconds), fmt(n * 3600 / seconds), fmt(seconds * 3000 / n / 3600, 2)])
    lines += [table(["Gemessene Kohorte", "Runs", "Wandzeit s", "Runs/Stunde", "Bedingt 3.000 Runs: Stunden"], values), "",
              f"Die Hauptstichprobe umfasst {fmt(sum(r['seconds'] for r in rows) / 3600, 2)} simulierte "
              "Spielstunden. Länger überlebende oder bis Minute 30 laufende Builds können erheblich mehr "
              "Zeit beanspruchen, weil mehr Gegner, Projektile und Fähigkeiten gleichzeitig aktiv werden. "
              f"Von 3.000 fehlen gegenüber allen {total} gültigen vollständigen Runs noch {max(0, 3000-total)}; "
              "gegenüber der einheitlichen Hauptstichprobe fehlen "
              f"{max(0, 3000-len(rows))}. Weitere Runs wurden nicht durch Assertions, Benchmarks oder "
              "Bootstrap-Wiederholungen ersetzt. Der Auftrag ist hinsichtlich des geforderten Stichprobenziels "
              "und belastbarer später Run-Progression daher nur teilweise erfüllt.", "",
              "## Dateien und Reproduktion", "",
              "- [CLASS_BALANCE.md](CLASS_BALANCE.md): Klassen, Botprofile, Intervalle, Build-/XP-Vergleiche.\n"
              "- [SIMULATOR_FIDELITY.md](SIMULATOR_FIDELITY.md): native Mechanik, Zeit-/Kollisionsnachweise und Grenzen.\n"
              "- [PROJECT_INVENTORY.md](PROJECT_INVENTORY.md): statisch gelesene Produktionsregeln.\n"
              "- [analysis.json](data/analysis.json), [runs.csv](data/runs.csv): maschinenlesbare Auswertung.\n"
              "- [tools/run_cohort.py](tools/run_cohort.py), [tools/analyze_qa.py](tools/analyze_qa.py), "
              "[tools/write_simulation_reports.py](tools/write_simulation_reports.py): Runner und Auswertung.\n"
              "- [survival-baseline.png](charts/survival-baseline.png), [survival-after.png](charts/survival-after.png), "
              "[survival-holdout.png](charts/survival-holdout.png), [before-after.png](charts/before-after.png): "
              "aus denselben Beobachtungen erzeugte Diagramme.", "",
              "Regenerieren: `QA/.venv/Scripts/python.exe QA/tools/write_simulation_reports.py`, nachdem "
              "`analyze_qa.py` genau die fünf Hauptkohorten verarbeitet hat. Der Generator verweigert "
              "unvollständige Kohorten, veraltete Analyse-Prüfsummen und doppelte Run-IDs.", ""]
    return "\n".join(lines)


def main():
    manifests = {name: load(DATA / name / "cohort.json") for name in COHORTS}
    for name, manifest in manifests.items():
        if not manifest.get("completed"):
            raise RuntimeError(f"Cohort not complete: {name}; wait for the final checkpoint")
    files = [p for name in COHORTS for p in sorted((DATA / name).glob("worker-*.jsonl"))]
    raw = read(files)
    rows = [r for r in raw if valid(r) and r.get("policy_version") == "visible-countdown-v2"]
    if len(rows) != len(raw):
        raise RuntimeError("Primary cohort contains incomplete, invalid or wrong-policy records")
    if len({r["run_id"] for r in rows}) != len(rows):
        raise RuntimeError("Duplicate primary full-run IDs")
    if any(r.get("simulation_version") != "native-fixed60-v2" or r.get("logical_hz") != 60
           or r.get("native_room_speed") != 60 for r in rows):
        raise RuntimeError("Primary row is not a validated fixed-60 native run")
    for name, manifest in manifests.items():
        n = sum(f"/{name}/" in r["_path"] for r in rows)
        if n != manifest["requested_total"] or n != manifest["completed_runs"]:
            raise RuntimeError(f"Incomplete/mismatched cohort: {name} ({n})")
    key = lambda r: (r["seed"], r["class_name"], r["persona"])
    before = {key(r) for r in rows if r["phase"] == "baseline"}
    after = {key(r) for r in rows if r["phase"] == "after"}
    if before != after:
        raise RuntimeError("Baseline and after are not fully matched by seed/class/persona")
    if {r["seed"] for r in rows if r["phase"] == "holdout"} & {r["seed"] for r in rows if r["phase"] != "holdout"}:
        raise RuntimeError("Holdout reuses a main comparison seed")
    for phase in PHASES:
        sizes = [len(group(rows, phase, klass, persona)) for klass in CLASSES for persona in PERSONAS]
        if len(set(sizes)) != 1 or not sizes[0]:
            raise RuntimeError(f"Class/persona strata are not balanced: {phase}")
    calibration = [r for r in read(sorted(DATA.glob("native-policy-v1-calibration-*.jsonl"))) if valid(r)]
    if len({r["run_id"] for r in calibration}) != len(calibration):
        raise RuntimeError("Duplicate calibration full-run IDs")
    analysis = load(DATA / "analysis.json")
    if analysis["full_runs"] != len(rows):
        raise RuntimeError("Stale or mixed analysis.json: run the analyzer on only the five v2 cohorts")
    if len(analysis["paired_before_after"]) != len(after):
        raise RuntimeError("Analysis does not contain all matched before/after pairs")
    hashes = {str(Path(p).resolve()): h for p, h in analysis["input_files"].items()}
    for path in files:
        if hashes.get(str(path.resolve())) != hashlib.sha256(path.read_bytes()).hexdigest():
            raise RuntimeError(f"Stale/missing analysis checksum: {path}")
    (QA / "CLASS_BALANCE.md").write_text(report_classes(rows, analysis), encoding="utf-8")
    (QA / "SIMULATION_REPORT.md").write_text(report_simulation(rows, calibration, manifests, analysis), encoding="utf-8")
    print(json.dumps({"primary_runs": len(rows), "calibration_runs": len(calibration),
                      "valid_full_runs_total": len(rows) + len(calibration),
                      "reports": ["QA/CLASS_BALANCE.md", "QA/SIMULATION_REPORT.md"]}, indent=2))


if __name__ == "__main__":
    main()
