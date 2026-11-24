# FirstGame

**Drei spielbare Welten:** Verzauberter Wald, Verfluchter Sumpf und Aschenfrost-Ruinen, siehe [LEVEL_EXPANSION_PROGRESS.md](LEVEL_EXPANSION_PROGRESS.md) (native Levelsuite 166/166 PASS, Regression 811/811 PASS). Bossphilosophie: [DESIGN/BOSS_DESIGN.md](DESIGN/BOSS_DESIGN.md). Arbeitsregeln: [CLAUDE.md](CLAUDE.md).


**Aktueller Stand:** [QA-Ergebnisse und Balancing](QA/QA_SUMMARY.md), [reproduzierbare Testumgebung](QA/README.md). 192 vollständige native Runden, 360 primäre Bosskämpfe plus 15 Nachtests, 654 Fähigkeitsfenster und 811 Regressionsprüfungen. Normale Münzen erreichen schnelle Spieler im Sammelradius; Boss-Trefferframes sind korrigiert. [Aktueller Windows-Build ohne Test-Hooks](output/production-build/20261123-223542/FirstGame.zip). Das 3.000-Run-Ziel wurde nicht erreicht; Grenzen und Restarbeit stehen im QA-Bericht. Die folgenden früheren Berichte dokumentieren vorherige Stände.
 

Aktueller Grafik-/Boss-/Balance-Stand: [ATMOSPHERE_REPORT.md](ATMOSPHERE_REPORT.md). Aktuelle gezielte Tests: `python tests/tools/run_atmosphere_smoke.py`; XP-Rechnung: `python tests/tools/simulate_atmosphere_progression.py`.

Aktueller erster Hauptdrachenkampf, Boss-Orbs und Run-Statistiken: [DRAGON_REPORT.md](DRAGON_REPORT.md).

Aktueller Kampf-/Magnet-/Wetterstand: [COMBAT_REPORT.md](COMBAT_REPORT.md). Verifikation: `python tests/tools/run_combat_smoke.py`; XP-Analyse: `python tests/tools/analyze_combat_progression.py`. Ältere Smoke-Einstiege leiten auf die aktuelle Suite weiter.

Neue Schwertkämpferfigur nach Bildvorlage, acht Richtungen und erweiterte Animationen: [SWORDSMAN_REPORT.md](SWORDSMAN_REPORT.md).

