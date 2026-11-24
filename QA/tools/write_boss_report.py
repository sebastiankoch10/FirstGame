"""Rebuild the boss report from completed native v2 encounters, without extrapolation."""
from pathlib import Path
from collections import Counter, defaultdict
import hashlib
import json
import math
import statistics
from itertools import product

ROOT = Path(__file__).resolve().parents[2]
QA = ROOT / "QA"
BOSSES = ["storm_warden", "twins", "behemoth", "mini_sentinel", "mini_warden"]
MAIN = BOSSES[:3]
CLASSES = ["Sword", "Mage", "Ranger"]
POLICIES = ["no_response", "average", "experienced", "technical_greedy"]
LABEL = {"storm_warden": "Drache (storm_warden)", "twins": "Zwillinge", "behemoth": "Behemoth",
         "mini_sentinel": "Mini Sentinel", "mini_warden": "Mini Warden"}
NAMES = {
    "storm_warden": ["Feuerstrahl", "Feuerbogen", "Magmaeruption", "Meteoritenregen", "Bodeneinschlag", "Flügelsturm", "Void-Orbs", "Feuerwirbel", "Void-Salven"],
    "twins": ["Doppelte Geschosssalve", "Feuer-Eis-Ring", "Meteoriten/Eissplitterregen", "Verbindungsstrahl", "Dualer Spiralwirbel", "Kreuzschlag-Strahlen", "Brennender Froststoß", "Vereinigte Zonenflut", "Duale Nova"],
    "behemoth": ["Giftgespucke", "Säurepfützen", "Packende Wurzeln", "Pilzexplosion", "Sumpfstampfer", "Sumpfbrut", "Giftatem", "Sumpfwelle", "Verfallsblüte"],
}
BASE_WARNING = {
    "storm_warden": [1.2, 1.0, 1.05, 1.8, 1.5, .9, .8, 1.7, .65],
    "twins": [.55, 1.2, 1.4, 1.3, 1.5, 1.4, 1.5, 1.6, 1.8],
    "behemoth": [.7, 1.1, 1.1, 1.6, 1.4, 1.3, 1.5, 1.3, 1.9],
}


def wilson(k, n):
    if not n:
        return None
    z = 1.959963984540054
    p = k / n
    center = (p + z * z / (2 * n)) / (1 + z * z / n)
    half = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / (1 + z * z / n)
    return [max(0, center - half), min(1, center + half)]


def describe(xs):
    return {"n": len(xs), "mean": statistics.mean(xs) if xs else None,
            "median": statistics.median(xs) if xs else None,
            "min": min(xs) if xs else None, "max": max(xs) if xs else None}


def outcome(rs):
    wins = [r for r in rs if r["won"]]
    return {"n": len(rs), "wins": len(wins), "deaths": sum(r["end_reason"] == "player_death" for r in rs),
            "censored": sum(r["censored"] for r in rs), "win_fraction": len(wins) / len(rs) if rs else None,
            "win_wilson95": wilson(len(wins), len(rs)), "seconds_all": describe([r["seconds"] for r in rs]),
            "seconds_wins": describe([r["seconds"] for r in wins])}


def fmt(x, decimals=1):
    return "—" if x is None else f"{x:.{decimals}f}"


def rate(rs):
    s = outcome(rs)
    lo, hi = s["win_wilson95"]
    return f'{s["wins"]}/{s["n"]} = {s["win_fraction"]:.1%} [{lo:.1%}; {hi:.1%}]'


def attack_summary(aa):
    done = [a for a in aa if not a["censored"]]
    threatened_done = [a for a in done if a["threatened"]]
    hits = sum(a["hits"] for a in aa)
    return {"activations": len(aa), "threatened": sum(a["threatened"] for a in aa),
            "activations_hit": sum(a["hits"] > 0 for a in aa), "hits": hits,
            "damage": sum(a["damage"] for a in aa), "fatal_hits": sum(a["fatal_hits"] for a in aa),
            "maximum_hit": max((a["maximum_hit"] for a in aa), default=0),
            "censored": sum(a["censored"] for a in aa),
            "completed_threatened": len(threatened_done),
            "avoided_threatened": sum(a["avoided_while_threatened"] for a in aa),
            "protected_contacts": sum(a["protected_contacts"] for a in aa),
            "warning": describe([a["warning"] for a in aa if a["warning"] >= 0]),
            "first_possible": describe([a["first_possible"] for a in aa if a["first_possible"] >= 0])}


def main():
    cohorts = {}
    paths = {}
    for name in ["baseline", "holdout"]:
        p = QA / "data" / f"boss-{name}.jsonl"
        paths[str(p.relative_to(ROOT)).replace("\\", "/")] = hashlib.sha256(p.read_bytes()).hexdigest()
        cohorts[name] = [json.loads(line) for line in p.read_text(encoding="utf-8").splitlines() if line.strip()]
    rows = cohorts["baseline"] + cohorts["holdout"]
    errors = []
    cells = ["boss", "class_name", "persona", "spawn_minute"]
    expected_cells = set(product(BOSSES, CLASSES, POLICIES, [5, 10, 15]))
    for name, rs in cohorts.items():
        if len(rs) != 180 or {tuple(r[d] for d in cells) for r in rs} != expected_cells:
            errors.append(name + ": expected exactly one encounter per planned cell")
        if not all(r["record_type"] == "boss_encounter" and r["completed"] and not r["censored"] for r in rs):
            errors.append(name + ": incomplete or invalid record")
        if not all(r["policy_version"] == "visible-countdown-v2" and not r["random_build"] and r["normal_population_disabled"] for r in rs):
            errors.append(name + ": unexpected policy/build/population configuration")
        triplets = defaultdict(list)
        for r in rs:
            triplets[(r["boss"], r["persona"], r["spawn_minute"])].append(r)
            aa = r["metrics"]["boss_activations"]
            if not math.isclose(sum(a["damage"] for a in aa), r["metrics"]["damage_in"], abs_tol=1e-5):
                errors.append(r["run_id"] + ": activation incoming damage differs")
            if sum(a["fatal_hits"] for a in aa) != (1 if r["end_reason"] == "player_death" else 0):
                errors.append(r["run_id"] + ": activation fatal count differs")
        if any(len(t) != 3 or len({r["seed"] for r in t}) != 1 for t in triplets.values()):
            errors.append(name + ": class triplets are not seed matched")
    if len({r["run_id"] for r in rows}) != len(rows):
        errors.append("Duplicate encounter IDs across cohorts")
    seed_sets = {n: set(r["seed"] for r in rs) for n, rs in cohorts.items()}
    if seed_sets["baseline"] & seed_sets["holdout"]:
        errors.append("Cohort seeds overlap")
    grouped_cells = defaultdict(list)
    for r in rows:
        grouped_cells[tuple(r[d] for d in cells)].append(r)
    if any(len(rs) != 2 for rs in grouped_cells.values()):
        errors.append("Primary cells do not have exactly two observations")
    attacks = defaultdict(list)
    attacks_policy = defaultdict(list)
    for r in rows:
        for a in r["metrics"]["boss_activations"]:
            attacks[(r["boss"], a["ability"])].append(a)
            attacks_policy[(r["boss"], a["ability"], r["persona"])].append(a)
    attack_stats = {boss + ":" + ability: attack_summary(aa) for (boss, ability), aa in attacks.items()}
    total = outcome(rows)
    stats = {"passed": not errors, "errors": errors, "primary": total,
             "cohorts": {n: outcome(rs) for n, rs in cohorts.items()}, "input_sha256": paths,
             "cohort_seed_ranges": {n: [min(ss), max(ss)] for n, ss in seed_sets.items()},
             "seed_overlap": sorted(seed_sets["baseline"] & seed_sets["holdout"]),
             "cells": [{**dict(zip(cells, key)), **outcome(rs)} for key, rs in sorted(grouped_cells.items())],
             "attacks": attack_stats,
             "attack_policy": {":".join(k): attack_summary(v) for k, v in attacks_policy.items()},
             "scope": "360 primary native v2 fights; one preset observation per cell per independent-seed cohort; no human or unavoidability claim"}
    for dim in ["boss", "class_name", "persona", "spawn_minute"]:
        stats[dim] = {str(k): outcome([r for r in rows if r[dim] == k]) for k in sorted({r[dim] for r in rows}, key=str)}
    lines = []
    add = lines.append
    def table(headers, body):
        add("| " + " | ".join(headers) + " |")
        add("| " + " | ".join(["---"] * len(headers)) + " |")
        for row in body:
            add("| " + " | ".join(str(x) for x in row) + " |")
        add("")

    add("# Bossbalance – tatsächlich ausgeführte native Kämpfe")
    add("")
    add(f"Stand 23.11.2026. **{len(rows)} tatsächlich ausgespielte primäre Begegnungen**, davon {total['wins']} echte Boss-Siege und {total['deaths']} echte Spielertode; kein Fight-Timeout. Gesamt-Sieganteil: **{rate(rows)}**. Die drei Hauptbosse haben jeweils neun Fähigkeiten; alle **27** wurden tatsächlich aktiviert. Die zwei Mini-Bosse ergänzen fünf beobachtete Angriffsarten.")
    add("")
    add("Die Ergebnisse zeigen unter diesen Presets einen Vorteil für Sword und einen starken Einfluss der Ausweichsteuerung. Drache ist mit 34/72 Siegen der schwierigste Boss im gemischten Testplan. Die schnell reagierende technische Heuristik gewinnt 82/90 Begegnungen, scheitert also ebenfalls achtmal. Daraus folgt kein Beweis technisch unvermeidbarer Treffer. Boss-Kampfwerte wurden aufgrund dieser Stichprobe noch nicht geändert.")
    add("")
    add("## Datengrundlage und Aussagegrenze")
    add("")
    add("Primärdaten: [boss-baseline.jsonl](data/boss-baseline.jsonl) und [boss-holdout.jsonl](data/boss-holdout.jsonl), je 180 vollständige native Kämpfe im installierten GameMaker-Runner. Python erfasst und analysiert die Produktions-GML; keine nachgebaute Python-Kampfformel. Gleichwertige Initialisierung zum bestehenden Boss-Testmodus: tatsächliches `boss_spawn`, tatsächliche Boss-/Spieler-HP, legale Eingaben, keine Unverwundbarkeit. Logik und Engine bleiben bei 60 Hz; Batchgröße 600 beschleunigt die Verarbeitung. Details und nachgewiesene Grenzen: [SIMULATOR_FIDELITY.md](SIMULATOR_FIDELITY.md).")
    add("")
    add("Testplan pro Datei: 5 Bosse × 3 Klassen × 4 Policies × Minuten 5/10/15 = 180 Zellen; **eine Beobachtung je Zelle und Datei, zusammen nur zwei je Zelle**. Die gewünschten 100 Beobachtungen je Kombination sind nicht erreicht. Alle 360 verwenden den festen ausgewogenen Minuten-Preset, keine Zufallsbuilds und keine normale Gegnerpopulation. Boss-eigene Beschwörungen bleiben Teil des Kampfes. Minuten unterscheiden sowohl Boss-Skalierung/Freischaltungen (3/6/9 Hauptfähigkeiten) als auch Spielerausbau; dies ist kein isolierter Effekt der Zeit.")
    add("")
    add("Baseline-Seeds 810101–810160, Holdout-Seeds 910101–910160, ohne Überschneidung. Innerhalb einer Datei teilen sich die drei Klassen einer Boss/Minute/Policy-Gruppe den Seed. Verschiedene Policies haben verschiedene Seeds; Policy-Unterschiede sind deshalb ungepaarte Vergleiche. Unterschiedlicher RNG-Verbrauch der Klassen verhindert identische Ereignisfolgen trotz gleicher Seeds. Beide Exporte nennen intern `phase=baseline` und `source_phase=baseline`; die Holdout-Zuordnung folgt dem Dateipfad und dem unabhängigen Seedbereich, nicht diesen Metadaten.")
    add("")
    add("Ausgeschlossen aus N=360: 195 gültige Ausführungen mit der alten Policy v1 (180 eindeutige Konfigurationen + 15 Wiederholungen; Kalibrierung), 15 v2-Piloten derselben ersten Konfigurationen sowie 15 ungültige frühe Boss-Piloten mit `room_speed=10000`. Weder Wiederholungen noch gezielte Regressionen werden als zusätzliche unabhängige Beobachtungen gezählt.")
    add("")
    table(["Primärdatei", "Kämpfe", "Siege / N; 95%-Wilson-Intervall", "Tode", "Fight-Timeouts"],
          [[n, len(rs), rate(rs), outcome(rs)["deaths"], outcome(rs)["censored"]] for n, rs in cohorts.items()])
    add("Die Intervalle sind deskriptive binomiale 95%-Wilson-Intervalle für den festen Testmix. Gemeinsame Seeds der Klassentriplets und unterschiedliche Presets schränken die Unabhängigkeitsannahme ein; sie belegen keine menschliche Gewinnwahrscheinlichkeit und ersetzen keine gepaarte oder hierarchische Analyse. Bei n=2 reicht selbst 2/2 nur zu einem Wilson-Intervall von etwa 34–100 %. Keine Signifikanz- oder Äquivalenzbehauptung aus Einzelzellen.")
    add("")
    add("## Sieganteile nach Klasse, Boss, Steuerung und Minute")
    add("")
    table(["Dimension", "Wert", "Siege / N; 95%-Wilson-Intervall", "Siegdauer Median [Min; Max] s"],
          [[dim, LABEL.get(k, str(k)), rate(sub),
            f"{fmt(outcome(sub)['seconds_wins']['median'])} [{fmt(outcome(sub)['seconds_wins']['min'])}; {fmt(outcome(sub)['seconds_wins']['max'])}]"
            ] for dim, values in [("Klasse", CLASSES), ("Boss", BOSSES), ("Policy", POLICIES), ("Minute", [5, 10, 15])]
           for k in values for sub in [[r for r in rows if r[{"Klasse":"class_name", "Boss":"boss", "Policy":"persona", "Minute":"spawn_minute"}[dim]] == k]]])
    add("Siegdauern enthalten ausschließlich tatsächlich gewonnene Kämpfe; frühe Tode verkürzen sie nicht. Die sehr kurzen Mini-Bosse beeinflussen den gemeinsamen Median erheblich. Aggregierte Klassenquoten gelten deshalb nur für diesen identischen Boss-/Policy-/Minutenmix.")
    add("")
    add("### Klasse innerhalb jedes Bosses")
    add("")
    table(["Boss", *CLASSES], [[LABEL[b], *[rate([r for r in rows if r["boss"] == b and r["class_name"] == c]) for c in CLASSES]] for b in BOSSES])
    add("### Klasse innerhalb jeder Steuerung")
    add("")
    table(["Policy", *CLASSES], [[p, *[rate([r for r in rows if r["persona"] == p and r["class_name"] == c]) for c in CLASSES]] for p in POLICIES])
    add("### Steuerung innerhalb jedes Bosses")
    add("")
    table(["Boss", *POLICIES], [[LABEL[b], *[rate([r for r in rows if r["boss"] == b and r["persona"] == p]) for p in POLICIES]] for b in BOSSES])
    add("### Minuten-Preset innerhalb jedes Bosses")
    add("")
    table(["Boss", "Minute 5", "Minute 10", "Minute 15"], [[LABEL[b], *[rate([r for r in rows if r["boss"] == b and r["spawn_minute"] == m]) for m in [5, 10, 15]]] for b in BOSSES])
    add("Policies: `no_response` bleibt stehen und verwendet keine Mobilität, greift aber weiter automatisch an; `average` reagiert nach 0,30 s; `experienced` nach 0,12 s; `technical_greedy` nach 1/60 s. Die letzten drei benutzen denselben sichtbaren Kandidaten-/Countdown-Planer, keine getrennte optimale Wegsuche. Bewegungswahl aus acht Richtungen und legale Sprung-/Dodge-Eingaben; sichtbare aktuelle Projektile und Warnflächen, keine zukünftige Rotation oder unveröffentlichte Zufallsentscheidung. Das ist eine Botdefinition, keine Kalibrierung an menschlichem Können.")
    add("")
    add("## Alle 27 Hauptfähigkeiten – Exposition und Treffer")
    add("")
    add("`A` = gestartete Aktivierungen; `T` = jemals als bedrohend erfasst; `HA` = Aktivierungen mit mindestens einem tatsächlichen HP-Treffer; `H` = einzelne HP-Schadensereignisse, einschließlich wiederholtem Schaden/Gift. Trefferquote hier einheitlich `HA/A` über alle gestarteten Aktivierungen. `E/TD` = ohne HP-Verlust abgeschlossene bedrohte Aktivierungen / abgeschlossene bedrohte Aktivierungen. `C` = am Fight-Ende als möglicherweise offen markierte Aktivierungen: Die Telemetrie verwendet dafür die Heuristik `jetzt − last_seen < 0,5 s`, keinen exakten Lebenszyklusbeweis. Entsprechend sind auch E/TD nur nach dieser Heuristik abgeschlossen. Ein abgeschlossener Fight kann offene Angriffe enthalten; C zählt keine zusätzlichen Kämpfe.")
    add("")
    add("**Nennergrenze:** Flächen zählen bereits geometrische Exposition während sichtbarer Warnungen; Projektile zählen bislang tatsächlichen oder geschützten Kontakt. Erfolgreich ohne Kontakt gemiedene Projektile fehlen im T-Nenner. Deshalb darf `HA/T` bei Projektilen weder als faire Trefferquote noch als Unvermeidbarkeitsmaß gelesen werden. `HA/A` enthält ihrerseits räumlich irrelevante und am Fight-Ende offene Angriffe. E umfasst auch Schutz durch Sprung/Dodge/Slide; es ist keine Zahl bewiesener sicherer Laufwege. Keine scheinpräzisen unabhängigen Konfidenzintervalle für innerhalb desselben Kampfes korrelierte Attacken.")
    add("")
    main_keys = [(b, str(i)) for b in MAIN for i in range(1, 10)]
    table(["Boss:ID / Fähigkeit", "A", "T", "HA", "H", "HA/A", "E/TD", "C"],
          [[f"{b}:{aid} {NAMES[b][int(aid)-1]}", s["activations"], s["threatened"], s["activations_hit"], int(s["hits"]),
            f"{s['activations_hit']/s['activations']:.1%}", f"{s['avoided_threatened']}/{s['completed_threatened']}", s["censored"]]
           for b, aid in main_keys for s in [attack_stats[b + ":" + aid]]])
    add("## Hauptfähigkeiten – tatsächlicher Schaden, Todesursachen und Zeiten")
    add("")
    add("HP/A und HP/H sind tatsächlicher mittlerer HP-Verlust pro Aktivierung bzw. Schadensereignis, nach HP-Begrenzung; Max ist der größte einzelne HP-Verlust. Tod-% teilt die fatalen Treffer durch alle 140 Spielertode der Primärdaten, nicht durch besiegte Bosse. `Profil` ist die statisch geprüfte Basiswarnung vor Minuten-/Phasenskalierung. `Warn-Tel.` ist der erste gültig protokollierte Warnwert einer zugeordneten Teilgefahr: Bei gestaffelten Mustern kann die zuerst durchlaufene Teilgefahr eine späte Stufe sein, bei Behemoth-Gespucke der Splash mit 0 s. Das ist **keine einheitliche Messung der ersten sichtbaren Vorwarnung**. `Erstmals aktiv` ist der erste instrumentierte aktive Zeitpunkt relativ zum Start, kein Nachweis eines dort notwendigen Spielertreffers. Mittelwerte nur über gültige Werte, n in Klammern; — bedeutet nicht erfasst.")
    add("")
    table(["Boss:ID", "HP/A", "HP/H", "Max HP", "Fatal", "Tod-%", "Profil s", "Warn-Tel. Ø s (n)", "Erstmals aktiv Ø s (n)"],
          [[b + ":" + aid, fmt(s["damage"]/s["activations"]), fmt(s["damage"]/s["hits"] if s["hits"] else None),
            fmt(s["maximum_hit"]), int(s["fatal_hits"]), f"{s['fatal_hits']/total['deaths']:.1%}",
            fmt(BASE_WARNING[b][int(aid)-1], 2),
            f"{fmt(s['warning']['mean'], 3)} ({s['warning']['n']})", f"{fmt(s['first_possible']['mean'], 3)} ({s['first_possible']['n']})"]
           for b, aid in main_keys for s in [attack_stats[b + ":" + aid]]])
    add("Die Basiswarnungen werden durch den Produktions-Speedfaktor geteilt (Minute 5/10/15: 1,00/1,07/1,14). Dragon-Strahl/-Bogen verkürzen ab Phase 3 zusätzlich um 12 %; Mindestwarnung 0,55 s, für Magma 0,85 s. Twins/Behemoth mindestens 0,50 s, mit zusätzlichen Verzögerungen gestaffelter Teilflächen. Bewegte Salven besitzen keine Boden-Countdownfläche; Basis-Windup und sichtbare Projektilreaktionszeit sind unterschiedliche Größen. Diese statischen Konfigurationen ergänzen die Telemetrie, ersetzen aber keine gerenderte Messung der tatsächlich erkennbaren Warnung.")
    add("")
    add("Die Schadenstraces stimmen pro Fight mit dem tatsächlichen HP-Verlust überein; genau eine fatale Quelle pro Spielertod. Größter einzelner Todesverursacher: Drachen-Feuerstrahl mit 26/140 Toden (18,6 %); danach Zwillinge-Salve 13, beide Spiralwirbel zusammen 12, Behemoth-Giftgespucke inklusive zugeordnetem Gift 10, Säurepfützen und Wurzeln je 9. Direkter Schaden und nachlaufendes Gift bleiben der konkreten Aktivierung zugeordnet. `Sumpfbrut` ist eine Beschwörung mit nominal 0 Direktschaden; 0 eigene HP-Treffer allein beweist keine wirkungslose Beschwörung.")
    add("")
    add("### Mini-Bosse separat")
    add("")
    table(["Boss:Angriff", "A", "T", "HA", "H", "HA/A", "E/TD", "Fatal", "C"],
          [[b+":"+aid, s["activations"], s["threatened"], s["activations_hit"], int(s["hits"]),
            f"{s['activations_hit']/s['activations']:.1%}", f"{s['avoided_threatened']}/{s['completed_threatened']}", int(s["fatal_hits"]), s["censored"]]
           for b, aid in sorted(attacks) if b not in MAIN for s in [attack_stats[b+":"+aid]]])
    add("## Fähigkeiten- und Phasenabdeckung")
    add("")
    table(["Boss / Minute", "N", "verschiedene aktivierte IDs", "alle freigeschalteten IDs pro Fight", "Phase 1 / 2 / 3 / 4 erreicht"],
          [[f"{LABEL[b]} / {m}", len(sub), ", ".join(sorted({a['ability'] for r in sub for a in r['metrics']['boss_activations']}, key=int)),
            f"{sum(set(str(i) for i in range(1, unlock+1)) <= {a['ability'] for a in r['metrics']['boss_activations']} for r in sub)}/{len(sub)}",
            " / ".join(str(sum(p in r["phases_seen"] for r in sub)) for p in [1, 2, 3, 4])]
           for b in MAIN for m, unlock in [(5, 3), (10, 6), (15, 9)] for sub in [[r for r in rows if r["boss"] == b and r["spawn_minute"] == m]]])
    add("Abdeckung ist Überdeckung der Stichprobe, keine vollständige Prüfung jeder Fähigkeit in jeder Phase und jedem Überlappungszustand. Frühe Tode und die Freischaltung begrenzen spätere Fähigkeiten systematisch; Null Treffer kann geringe oder selektierte Exposition bedeuten. Vollständige Policy-Zähler und alle 180 Zellen stehen in [boss-combined-validation.json](data/boss-combined-validation.json).")
    add("")
    add("## Drache – Minute 15, neun Fähigkeiten und vier Phasen")
    add("")
    dragon = [r for r in rows if r["boss"] == "storm_warden" and r["spawn_minute"] == 15]
    dw = [r for r in dragon if r["won"]]
    stats["dragon_minute15"] = {**outcome(dragon), "all_four_phases": sum(set([1,2,3,4]) <= set(r["phases_seen"]) for r in dragon),
                                "all_nine": sum(len({a["ability"] for a in r["metrics"]["boss_activations"]}) == 9 for r in dragon),
                                "wins_in_120_180": sum(120 <= r["seconds"] <= 180 for r in dw)}
    d = stats["dragon_minute15"]
    add(f"**{rate(dragon)}**, {d['all_four_phases']}/24 erreichten alle vier Phasen, {d['all_nine']}/24 aktivierten alle neun Fähigkeiten. Alle neun Fähigkeiten und jede Phase sind insgesamt abgedeckt; nicht jede Begegnung gelangte dorthin. Echte Siege: Median {fmt(d['seconds_wins']['median'])} s, Bereich {fmt(d['seconds_wins']['min'])}–{fmt(d['seconds_wins']['max'])} s; **{d['wins_in_120_180']}/{len(dw)} Siege im Ziel 120–180 s**. Das bestätigt erreichbare Zieldauer mit diesen festen Builds; 15/24 Tode verhindern eine pauschale Aussage über repräsentative erfolgreiche Spieler oder Zufallsbuilds.")
    add("")
    table(["Policy / Klasse", "Siege / N", "alle 4 Phasen", "alle 9 Fähigkeiten", "Siegdauer(n) s"],
          [[p+" / "+c, rate(sub), sum(len(r["phases_seen"]) == 4 for r in sub),
            sum(len({a["ability"] for a in r["metrics"]["boss_activations"]}) == 9 for r in sub),
            ", ".join(fmt(r["seconds"], 2) for r in sub if r["won"]) or "—"]
           for p in POLICIES for c in CLASSES for sub in [[r for r in dragon if r["persona"] == p and r["class_name"] == c]]])
    add("Phasenwechsel erfolgen bei 75/50/25 % Rest-HP. Maximal 16 gleichzeitig gezählte Gefahrenobjekte in diesen Kämpfen; der Zähler umfasst auch räumlich entfernte Projektile und ist keine Zahl gleichzeitig den Spieler bedrohender Flächen. Rotationen und Überlappungen liefen durch die Produktionslogik; gerenderte Wahrnehmbarkeit und sämtliche kritischen Kombinationen wurden mit diesen Daten nicht vollständig vermessen.")
    add("")
    add("## Fairnessbefund und konkrete nächste Schritte")
    add("")
    add("**Tatsächlich nicht vermeidbar:** Häufigkeit nicht bestimmt. Es gibt keinen vollständigen zeitabhängigen Erreichbarkeitstest mit allen Hindernissen, sicheren Bereichen und Mobilitäts-Cooldowns. Ein Treffer von `technical_greedy` ist ein Untersuchungsfall, kein Unvermeidbarkeitsbeweis. Die Heuristik bewertet sichtbare Geometrie, aktuelle Bewegungen und legale Schutzfenster; sie exportiert keine vollständigen Distanz-/Routenbeweise für jeden Treffer.")
    add("")
    add("**Auffällig schwierig im Botmodell:** Behemoth-Sumpfstampfer trifft in 100/126 Aktivierungen (79,4 %), davon 40/49 bei `technical_greedy`; acht bedrohte technische Aktivierungen endeten dennoch ohne HP-Verlust. Verfallsblüte trifft in 34/41 Aktivierungen (82,9 %), bei der technischen Policy 18/18. Die Blüte wechselt von Außenblättern zum Kern und dann zum Sporenring. Beide brauchen gezielte Zustands-Replays mit verbleibender Warnzeit, Abstand zum sicheren Bereich, Sprung-/Dodge-Verfügbarkeit und überlagerten Gefahren. Die Stichprobe allein trennt schwierige Geometrie, unzureichende Botplanung und unmögliche Flucht nicht.")
    add("")
    add("**Gefährlich mit dokumentierten Gegenbeispielen:** Feuerstrahl verursacht 26 Tode; zugleich wurden 42/440 Aktivierungen mit HP-Schaden beobachtet und zahlreiche bedrohte Aktivierungen ohne HP-Verlust beendet. 16 der 26 Strahltode betreffen die stillstehende Kontrolle; neun `average`, einer `experienced`, keiner `technical_greedy`. Das belegt hohe Gefahr für bestimmte Steuerungen, keine unfairen Zufallsschäden. Drachen-Void-Orbs, Wind und Salven sowie Twins-Salve sind bewegte Projektile: hohe kontaktbasierte T-Quoten erlauben keine technische Fairnessklassifikation. Produktionscode nutzt für alle Angriffe die Spieler-Schutzfunktion: aktiver Dodge schützt alle Höhen, Luft-/Slide-Zustände schützen Bodenangriffe, Slide schützt hohe Angriffe; `all` hat keinen Sprung-/Slide-Schutz ohne aktiven Dodge.")
    add("")
    add("**Auffällig geringe Wirkung in erreichter Stichprobe:** Drachen-Feuerwirbel 0/65 HP-treffende Aktivierungen bei 55 bedrohten/erfolgreich ohne HP-Verlust abgeschlossenen Aktivierungen; Twins-Froststoß 0/49 bei 48 abgeschlossenen Vermeidungen; Behemoth-Pilzexplosion 0/124 bei nur 20 geometrisch bedrohten Aktivierungen. Das sind Kandidaten für zu leichtes Ausweichen oder Positionsauswahl der Bots, keine gesicherten wirkungslosen Angriffe. Die stillstehende Kontrolle stirbt vor diesen späteren Angriffen; ein sauberer Vergleich ohne gezielte Ausweichreaktion fehlt dort. Sumpfbrut separat als Beschwörung bewerten.")
    add("")
    add("**Geometrie/Warnung statisch geprüft:** Reale Kreis-, Ring-, Sektor- und Linienproben, Spieler-Kontaktradius und Produktions-Hindernisse werden verwendet. Der Drache besitzt unter anderem einen fixierten Strahl (48 px Breite, mindestens 1.200 px Länge, bei Bedarf bis über den sichtbaren Bereich verlängert), gezielte Flächen und gestaffelte Muster; Twins und Behemoth ergänzen bewegte Linien, Ringlücken und Wellen. Die aktive Gefahr kann sich nach der Startwarnung ändern. Eine berechnete nominelle Warnzeit allein beweist daher keine erreichbare sichere Position oder passende Renderanzeige. Normales Rendering und menschliche Lesbarkeit sind getrennte Prüffelder.")
    add("")
    add("Priorität: (1) **Boss-Fairnessproblem, offen:** Trefferzustände von Sumpfstampfer/Verfallsblüte reproduzieren und echte sichere Wege mit legalen Inputs prüfen; (2) **Balancingproblem, Hinweis:** Klassenunterschiede an Hauptbossen mit mehr unabhängigen Seeds und zusätzlichen Builds nachmessen; (3) **Noch nicht getestete Funktion:** späte Angriffe mit einer überlebensfähigen Vergleichssteuerung ohne gezielte Warnungsreaktion isoliert prüfen; (4) **Noch nicht getestete Funktion:** menschliche Wahrnehmung/Animation und ungünstige Überlappungen in normaler Engine-Sitzung. Keine dieser offenen Prüfungen ist als bestätigter Produktionsbug eingestuft.")
    add("")
    add("## Änderungen, Vergleich und Reproduzierbarkeit")
    add("")
    add("Produktionsänderungen dieses Auftrags betreffen die visuelle Hurt-Frame-Begrenzung und `normal_coin_speed` 252 → 420; keine Boss-HP-, Schadens-, Warnzeit-, Flächen- oder Rotationswerte wurden geändert. Diese isolierten Presetkämpfe liefern deshalb **keinen Nachweis einer Bossbalance-Verbesserung**. Der Holdout ist eine neue Seedstichprobe derselben Kampflogik, kein Nachherzustand.")
    add("")
    replay_path = QA / "data" / "boss-after-selected.jsonl"
    if replay_path.exists():
        replay = [json.loads(s) for s in replay_path.read_text(encoding="utf-8").splitlines() if s.strip()]
        match_fields = ["boss", "class_name", "persona", "spawn_minute", "seed"]
        check_fields = ["end_reason", "won", "seconds", "boss_hp_initial", "boss_hp_remaining", "player_hp", "player_max_hp",
                        "phases_seen", "max_simultaneous_hazards", "active", "passive", "metrics"]
        key = lambda r: tuple(r[d] for d in match_fields)
        base_by_key = {key(r): r for r in cohorts["baseline"][:15]}
        pairs = []
        for after in replay:
            before = base_by_key.get(key(after))
            differences = check_fields if before is None else [f for f in check_fields if before.get(f) != after.get(f)]
            pairs.append({**{f: after[f] for f in match_fields}, "baseline_run_id": before["run_id"] if before else None,
                          "after_run_id": after["run_id"], "identical": not differences, "different_fields": differences,
                          "before_seconds": before["seconds"] if before else None, "after_seconds": after["seconds"],
                          "before_damage_in": before["metrics"]["damage_in"] if before else None, "after_damage_in": after["metrics"]["damage_in"],
                          "before_damage_out": before["metrics"]["damage_out"] if before else None, "after_damage_out": after["metrics"]["damage_out"]})
        comparison = {"replay_outcomes": outcome(replay), "expected_pairs": 15, "pairs": pairs,
                      "all_pairs_exactly_identical": len(replay) == 15 and len({key(r) for r in replay}) == 15 and all(p["identical"] for p in pairs),
                      "fields_compared": check_fields, "input_sha256": hashlib.sha256(replay_path.read_bytes()).hexdigest()}
        stats["after_selected_comparison"] = comparison
        identical = sum(p["identical"] for p in pairs)
        add(f"Zusätzlich tatsächlich ausgeführt: **{len(replay)} gepaarte Nachher-Replays**, [boss-after-selected.jsonl](data/boss-after-selected.jsonl), dieselben ersten 15 Baseline-Fälle (alle fünf Bosse × drei Klassen, Minute 15, `average`, Seeds 810101–810105). {identical}/{len(replay)} stimmen nach JSON-Auswertung exakt überein bei Ergebnis, Dauer, Start-/Rest-HP, Phasen, Gefahrenmaximum, Build und vollständiger Kampftelemetrie einschließlich Quellen/Aktivierungen; Nachher {outcome(replay)['wins']} Siege, {outcome(replay)['deaths']} Tode. Damit liegen **375 ausgewertete aktuelle Fight-Ausführungen vor, weiterhin N=360 in der primären Stichprobe**. Der Replay stützt Regressionstreue für diese Konfigurationen; er belegt weder eine Balanceverbesserung noch normale Renderleistung. [Replay-Integrität](data/boss-after-selected-validation.json) und paarweise Details im kombinierten Export.")
    else:
        add("Ein späterer gepaarter Regressions-Replay ist gesondert zu zählen, nicht als zusätzliche Primärstichprobe.")
    add("")
    add("Integrität: [Baseline-Validierung](data/boss-baseline-validation.json), [Holdout-Validierung](data/boss-holdout-validation.json), [kombinierter Plan-/Statistikexport](data/boss-combined-validation.json). Beide Dateivalidierungen prüfen echte HP-Endzustände, eindeutige IDs, vollständige Ein-/Ausgangsschadenssummen, genaue fatale Quellen und die Übereinstimmung der Tick-/Telemetriezeit. Der kombinierte Export prüft zusätzlich den vollständigen Zellplan, zwei Beobachtungen pro Zelle, Policy/Build-Konfiguration und getrennte Seedbereiche. SHA-256-Eingabehashes stehen dort.")
    add("")
    add("Reproduktion aus dem Projektverzeichnis:")
    add("")
    add("```powershell")
    add("python QA/tools/validate_boss_data.py QA/data/boss-baseline.jsonl --out QA/data/boss-baseline-validation.json")
    add("python QA/tools/validate_boss_data.py QA/data/boss-holdout.jsonl --out QA/data/boss-holdout-validation.json")
    if replay_path.exists():
        add("python QA/tools/validate_boss_data.py QA/data/boss-after-selected.jsonl --out QA/data/boss-after-selected-validation.json")
    add("python QA/tools/write_boss_report.py")
    add("```")
    add("")
    add("Rohdaten behalten Seeds, Builds, Policyversion, tatsächliche HP, Aktivierungen und Schadensquellen. Projektil-Fehlschüsse anderer Schadensquellen bedeuten ausschließlich tatsächlich abgelaufene Projektile ohne Treffer; am Kampfende noch fliegende Projektile zählen nicht als Fehlschuss. Quellen: `QA/tools/boss_mc_harness.gml`, `QA/tools/native_mc_harness.gml`, `QA/tools/qa_telemetry.gml`, `scripts/boss_framework_v2/`, `scripts/boss_encounters_v2/`, `scripts/dragon_encounter/`, `scripts/gameplay/`. Technisch unvermeidbare Treffer und menschliche Fairness sind **nicht bestimmt**, keine geschätzten Nullen.")
    (QA / "data" / "boss-combined-validation.json").write_text(json.dumps(stats, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    if errors:
        raise SystemExit("; ".join(errors))
    (QA / "BOSS_BALANCE.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(json.dumps({"report": "QA/BOSS_BALANCE.md", "encounters": len(rows), "wins": total["wins"], "dragon15": stats["dragon_minute15"], "errors": errors}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
