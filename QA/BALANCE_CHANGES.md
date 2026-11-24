# Gezielte Änderungen und Messgrundlage

## Normale Münzen erreichen schnelle Spieler

| Wert | Baseline | Neuer Wert | Einheit |
|---|---:|---:|---|
| `combat_config().normal_coin_speed` | 252 | 420 | Pixel/Sekunde |

Quelle: `scripts/combat_feedback/combat_feedback.gml`. Sammelradius, Münzwert, Magnetorb, Gegner-HP, Spieler-HP und Fähigkeitenschaden werden durch diese Korrektur nicht geändert.

**Grundlage vor der Änderung:** Im kontrollierten nativen Test läuft der tatsächliche Player-Step drei Sekunden geradeaus. Eine normale Münze startet 80 Pixel hinter ihm im Sammelradius. Alle vier Bewegungsstrecken entsprechen nach Berücksichtigung der nativen Positionsgenauigkeit der erwarteten freien Strecke. Sword sammelt bei Tick 64, Mage bei Tick 46. Ranger sammelt nicht: Abstand nach drei Sekunden etwa 80 Pixel. Mit Fleet Footed Stufe 9 sammelt Ranger ebenfalls nicht; der Abstand wächst auf etwa 988 Pixel. Daten: `data/moving-coin-baseline.json`, ursprüngliches Runner-Log im dort angegebenen Verzeichnis. Die zwei fehlgeschlagenen Sammel-Assertions reproduzieren den bestätigten Fehler; sie sind kein unbemerkter Abschlussfehler.

Die Ursache ist direkt: Ranger bewegt sich am Boden mit 252 Pixel/Sekunde, eine normale Münze ebenfalls. Bei konstantem Abstand kann sie den Spieler nicht erreichen. Fleet Footed erhöht sein Tempo auf 316,8 Pixel/Sekunde. Mit Sprungfaktor 1,25 ergeben sich analytisch bis zu 396 Pixel/Sekunde; 420 bietet dafür einen kleinen Abstand. Dies ist eine aus den tatsächlichen Bewegungswerten abgeleitete Wahl, keine Behauptung eines gemessenen 30-Minuten-Ergebnisses.

Die vorhandenen zwölf Kalibrierungsruns und die laufende unveränderte Baseline liefern zusätzlich Hinweise auf geringe Ranger-Sammelquoten. Beispiel der ersten Strategie: 814 Kills, 220 eingesammelte XP. Diese Beobachtung allein beweist keinen Klassenfehler, weil Routen und Bots mitwirken. Der kontrollierte gleiche Bewegungsfall belegt die konkrete mechanische Ursache unabhängig davon.

**Erwartung:** Münzen im normalen Sammelradius können dem bewegten Ranger folgen und werden gesammelt. Dadurch können dessen tatsächliche XP, Upgrades und Überleben steigen. Auch andere Klassen sammeln etwas schneller; deshalb werden komplette Runden mit denselben Seeds verglichen und unabhängige Seeds geprüft. Eine Verbesserung der Überlebenszeit ist vor deren Abschluss nicht behauptet.

**Nachher-Messung:** `data/moving-coin-after.json` besteht alle zehn Assertions. Sword sammelt bei Tick 17 statt 64, Mage bei Tick 16 statt 46; Ranger sammelt bei Tick 23 statt gar nicht, Ranger mit Fleet Footed 9 bei Tick 38 statt gar nicht. Die gemessenen freien Bewegungsstrecken bleiben gleich. Die gepaarten vollständigen Runs und unabhängigen Seeds werden in `BEFORE_AFTER.md` ausgewertet. Die Baseline-Projektkopie bleibt unverändert.

## Boss-Trefferanimation

`bv2_actor_draw` begrenzt die Darstellung der Treffer-/Todesframes auf die tatsächliche Sprite-Länge. Zwei vorhandene Hurt-Frames erhielten zuvor zeitweise Index 2 und sprangen beim Zeichnen zurück zu Frame 0. Jetzt bleibt der letzte gültige Hurt-Frame stehen. Die vier Todesframes behalten ihre Abfolge. Diese Darstellungsänderung verändert keine Bossmechanik oder Grafikdatei. Native Vorhalte-Aufnahmen und Ressourcenprüfung: `VISUAL_AUDIT.md`.

## Bewusst keine weiteren Zahlenänderungen

Keine Anpassung an Klassen-HP, Startwaffenschaden, Zauberschaden oder Boss-HP aus frühen Bot-Ergebnissen. Die erste Strategie verwendete Bewegungsfähigkeiten teilweise unpassend gegen Höhenkategorien; ihre Zahlen dienen der Kalibrierung. Der Vergleich von Produktionsänderungen erfolgt nur mit derselben verbesserten Strategie. Weitere Änderungen benötigen eine eigene ausreichende Messgrundlage.
