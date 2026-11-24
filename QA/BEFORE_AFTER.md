# Vorher / Nachher

**72 gepaarte Bedingungen**: gleiche Klasse, gleicher Seed, gleiche sichtbare Bot-Strategie und gleiche Zeitbasis. Dazu 36 unabhängige Nachher-Runs. Die einzige geänderte Gameplay-Zahl ist die normale Münzgeschwindigkeit 252 → 420 Pixel/Sekunde. Der Hurt-Frame-Fix ist Darstellung. Die gesicherte Baseline wurde nicht verändert.

| Klasse | Paare | Überleben vorher → nachher (s, Mittel) | Gepaarte Differenz, 95%-Bootstrapintervall | XP/Kill vorher → nachher | Mittleres Endlevel vorher → nachher |
|---|---:|---:|---|---:|---:|
| Sword | 24 | 157.2 → 285.5 | +128.4 s [+37.0; +245.8] | 97.4% → 96.8% | 10.5 → 17.0 |
| Mage | 24 | 177.1 → 191.7 | +14.6 s [-15.6; +45.1] | 84.3% → 85.7% | 10.8 → 11.8 |
| Ranger | 24 | 199.8 → 277.1 | +77.3 s [+5.3; +174.8] | 67.4% → 72.8% | 7.5 → 9.5 |

XP/Kill ist die Summe tatsächlich eingesammelter Münz-XP geteilt durch normale Kills, keine frei angenommene Dropquote. Nicht eingesammelte Münzen können am Todeszeitpunkt noch existieren. Die Änderung kann auch Auswahl, Kampffolge und spätere Zufallsverbräuche verändern. Gleiche Anfangs-Seeds erzwingen daher keine identische spätere Welt.

Die Intervalle stammen aus 1.000 deterministisch gesäten Bootstrap-Stichproben der tatsächlichen gepaarten Differenzen. Überlappt ein Intervall null, liefert diese Stichprobe keinen gesicherten mittleren Überlebensgewinn. Das ist kein Beweis gleicher Klassenstärke oder einer Wirkung beim Menschen.

## Direkte native Fehlerreproduktion

| Bewegung, Münze 80 Pixel dahinter | Vorher: Sammeltick | Nachher: Sammeltick |
|---|---:|---:|
| Sword | 64 | 17 |
| Mage | 46 | 16 |
| Ranger | nicht in 180 Ticks | 23 |
| Ranger + Fleet Footed 9 | nicht in 180 Ticks | 38 |

Alle vier tatsächlichen freien Bewegungsstrecken bleiben gleich. Die zwei Ranger-Sammeltests reproduzieren vorher den Fehler und bestehen nachher. Quellen: `data/moving-coin-baseline.json`, `data/moving-coin-after.json`.

## Unabhängige Seeds

| Klasse | Runs | Mittleres Überleben (s) | Median (s) | XP/Kill | Minute 30 erreicht |
|---|---:|---:|---:|---:|---:|
| Sword | 12 | 322.5 | 161.2 | 97.9% | 1 |
| Mage | 12 | 189.6 | 198.0 | 78.8% | 0 |
| Ranger | 12 | 180.1 | 117.9 | 81.9% | 0 |

Die unabhängigen Seeds wurden nach Festlegung der 420 gewählt. Sie besitzen keine gepaarten unveränderten Gegenläufe; Unterschiede zur Baseline werden daher nicht kausal allein dem Münzwert zugeschrieben.

## Regression und Grenzen

Die 15 ausgewählten isolierten Nachher-Bosskämpfe stimmen mit ihren Baseline-Gegenstücken einschließlich vollständiger Telemetrie exakt überein. Es wurde kein Boss-Kampfwert verändert. Die 654 kontrollierten Fähigkeitsfenster werden nicht als 654 vollständige Runs oder als nachträglich erneut ausgeführte Fenster gezählt. Die allgemeine aktuelle Runner-Regression besteht 811 Prüfungen; der normale Build ist separat unter `data/production-build.json` dokumentiert.

Kleine Stichprobe, Bot-Strategien, unterschiedliche Build-Entwicklung und mögliche Ein-Tick-Unterschiede zur dynamischen Engine-Reihenfolge begrenzen die Aussagen. Survival-Kurven, Klassen-/Skill-Strata und fehlende späte Beobachtungen stehen in `SIMULATION_REPORT.md` und `CLASS_BALANCE.md`.
