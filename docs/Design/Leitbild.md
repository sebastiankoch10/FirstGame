---
tags: [design, verbindlich, leitbild]
updated: 2026-11-26
status: verbindlich (global, höchster Rang unter den Designdokumenten)
---
# Leitbild: globale Designphilosophie

Dieses Dokument ist die oberste verbindliche Designquelle für FirstGame. Es gilt für alle Klassen, Gegner, Bosse, Fähigkeiten, Grafiken, Animationen, Effekte und Klänge, auch für künftige. Fachdokumente regeln die Details; sie dürfen diesem Dokument nicht widersprechen.

## 1. Vorrang und Status der Dokumente

| Rang | Dokument | Status | Bedeutung |
|---|---|---|---|
| 1 | `docs/Design/Leitbild.md` (dieses Dokument) | verbindlich, global | Gewinnt bei jedem Widerspruch zwischen Designdokumenten. |
| 2 | übrige `docs/Design/*.md` | verbindlich, je Fachgebiet | Im eigenen Fachgebiet maßgeblich. Das spezifischere Dokument gilt im Detail, solange es Rang 1 nicht widerspricht. |
| 3 | `docs/DECISIONS.md` | verbindlich als Entscheidungsprotokoll | Eine neue Entscheidung gilt sofort. Das betroffene Designdokument wird im selben Auftrag nachgezogen. |
| 4 | `docs/Systeme/*.md` | beschreibend (Ist-Zustand) | Zeigt, wo etwas im Code steht. Keine Anforderungen. |
| 5 | `docs/HANDOFF.md`, `docs/LOG.md` | Stand und Verlauf | Keine Anforderungen. |
| 6 | `docs/Bugs & Ideen.md` | unverbindlich | Gesammelte Fehler und Ideen. |
| 7 | Root-`*_REPORT.md`, `DEVELOPMENT_PROGRESS.md`, `TODO.md`, `QA/*.md`, `FirstGame_ArtPack/**/*.md`, `docs/_archive/`, `docs/_export/` | historisch oder Momentaufnahme | Werte und Aussagen können veraltet sein. |

- **`AGENTS.md`** regelt die Arbeitsweise (Werkzeuge, Tests, Git, Übergabe). Es ist kein Designdokument, ist für die Arbeitsweise aber maßgeblich.
- **Soll und Ist:** Designdokumente beschreiben das Soll. Der Code ist die Wahrheit für das Ist. Weicht der Code vom Soll ab, ist das eine Lücke. Sie wird in [[Roadmap & Vertical Slice]] oder [[Bugs & Ideen]] erfasst, nie stillschweigend durch Umschreiben des Solls beseitigt.
- **Kennzeichnung in Designdokumenten:**
  - **Soll**: Anforderung.
  - **Ist (Datum)**: gemessener oder gelesener Stand.
  - **Offen**: wartet auf eine Entscheidung des Nutzers.
  - **Vorschlag**: Empfehlung eines Agenten, noch nicht bestätigt.
- **Neue Nutzeranforderungen** (Prompts) haben bei echten Widersprüchen Vorrang vor älteren Dokumenten. Sie werden im selben Auftrag mit Datum in das passende Designdokument übernommen, dazu eine Zeile in `DECISIONS.md`. Eine wesentliche Entscheidung darf nicht nur im Chat stehen.
- **Herkunft:** Wo eine Regel aus einem früheren Auftrag stammt, steht das Datum dabei (z. B. „Auftrag 22.11.“). Quellen waren die Codex-Aufträge vom 22./23.11. und die Claude-Aufträge vom 23.–25.11.2026. Nicht zugängliche Gespräche wurden nicht rekonstruiert.

## 2. Spielidentität

FirstGame ist ein eigenständiges **Pixel-Art-Action-RPG im Run-Format**:
- Top-down, Runs von 30 Minuten.
- Wachsende Gegnerhorden bilden die Survivors-Schicht, die Klassenwaffen greifen automatisch an.
- Bauen eines Builds aus Zaubern, Passiva, Talenten und Ausrüstung.
- Als Höhepunkt jeder Runde: anspruchsvolle, lernbare Bosskämpfe.

Das langfristige Ziel (Auftrag 25.11.):
- hochwertige, lebendige und kohärente Pixel-Art;
- anspruchsvolle Bosskämpfe;
- ausgeprägte Charakterprogression;
- überzeugende audiovisuelle Kampfinszenierung.

**Nicht mehr Pixel-Art, sondern besser inszenierte Pixel-Art.**

- **Entschieden (Nutzer, 25.11.): beides.**
  - Das Run-Format bleibt (30 Minuten, automatische Angriffe).
  - **Dazu kommt Fortschritt zwischen den Runs:** Talente und Talentpunkte bleiben je Klasse erhalten, ein Zurücksetzen ist jederzeit möglich. Details: [[Progression & Builds]].
  - Manuelles Zielen ist weiterhin nicht vorgesehen.

## 3. Die drei Inspirationsquellen und wie sie zusammenwirken

| Quelle | Das übernehmen wir | Das übernehmen wir nicht |
|---|---|---|
| **Soulslike** | Erkennbare Angriffsvorbereitung durch Körperbewegung, Bedeutung von Timing, Konsequenz bei Fehlern, lernbare Gegner, das Gefühl, einen Gegner zu meistern | Bestrafung durch Unlesbarkeit, lange Eingabesperren |
| **Final Fantasy XIV** | Räumlich strukturierte, mehrphasige Mechaniken, wechselnde sichere und gefährliche Flächen, überlappende Muster, Vorausplanung, klar kommunizierte Gefahrenbereiche | Fremde Effekte oder Assets, geschlossene Arena (unsere Welt ist offen), Gruppenrollen |
| **Path of Exile** | Build-Tiefe, Synergien, skalierende Fähigkeiten, bedeutsame Talente, spürbare mechanische und visuelle Progression | Bildschirmfüllende Spielereffekte, die Gegnerinformationen verdecken |
| **Survivors** (Basis) | Horden, Kiting, Flächenschaden, automatische Angriffe, kurze Runs | Gegnermassen als einzige Schwierigkeitsquelle |

**Synthese:** Der Kern des Spiels ist **räumliche Entscheidungsfindung unter Druck**. Jede Quelle liefert dazu einen Teil:
- Die Horde (Survivors) verengt den Bewegungsraum.
- Die Bossmuster (FFXIV) bestimmen, wo es sicher ist.
- Einzelne Angriffe (Soulslike) verlangen Timing.
- Der Build (PoE) bestimmt, wie viel Schaden man aus welcher Position machen kann.

Kein Teil steht für sich; Details in [[Kampf & Begegnungen]].

## 4. Säulen (Prüfsteine für jede Entscheidung)

1. **Räumliche Entscheidungen unter Druck:** Der Spieler fragt sich ständig, wo er stehen kann, wohin er muss und ob er jetzt Schaden machen oder überleben will.
2. **Lesbarkeit vor Spektakel:** Schwierigkeit entsteht aus Verständnis, Positionierung, Reaktion und Timing, nicht aus unlesbarem Chaos.
3. **Fairness:** Es gibt immer eine realistisch ausführbare Überlebensstrategie und keinen grundsätzlich unvermeidbaren Schaden.
4. **Lebendige, zusammenhängende Körper:** Figuren wirken wie physische Körper mit Gewicht. Bewegung kommuniziert Absicht und Gefahr.
5. **Verdiente Eskalation:** Visuelle und akustische Wucht spiegelt die tatsächliche Macht wider. Stufe 1 ist kompakt, das Endgame beeindruckend.
6. **Aus einem Guss:** Alle Assets wirken wie Teile desselben Spiels (Pixelraster, Licht, Palette, Animationsqualität).
7. **Steuerung zuerst:** Keine Animation verzögert die Eingabe oder sperrt die Bewegung unnötig.
8. **Systeme statt Einzelanfertigungen:** Höhere Qualität entsteht über wiederverwendbare Bausteine, nicht über Sonderlösungen je Fähigkeit oder Gegner.

## 5. Globale Grundsätze

Diese Regeln gelten für alle Klassen, Gegner, Bosse und Fähigkeiten, auch künftige. Klassen- und Bossdokumente beschreiben nur ihre Besonderheiten.

| Nr. | Grundsatz | Detail |
|---|---|---|
| G1 | **Ankündigung = Wahrheit.** Animation, Warnfläche, Hitbox, Schadenszeitpunkt, Effekt und Ton hängen an derselben Zeitquelle (eine Uhr je Besitzer). Bei 100 % Warnung beginnt sofort die aktive Phase. Pause hält alles gemeinsam an. | [[Kampf & Begegnungen]], [[Technische Architektur]] |
| G2 | **Kein unvermeidbarer Schaden.** Keine zufälligen Kombinationen, die alle sicheren Positionen schließen. | [[Kampf & Begegnungen]] |
| G3 | **Kiting bleibt legitim**, aber keine einfache Strategie neutralisiert alle Mechaniken. | [[Boss-Design]] |
| G4 | **Trefferhöhen statt pauschaler Unverwundbarkeit:** Boden, hoch, alle; Sprung, Slide und Ausweichen wirken gezielt. | [[Kampf & Begegnungen]] |
| G5 | **Eigene Effekte verdecken nie überlebenswichtige Informationen.** Es gilt die visuelle Hierarchie. | [[Kampf & Begegnungen]] |
| G6 | **Visuelle Intensität folgt der tatsächlichen Macht.** Hitbox und sichtbare Schadensfläche stimmen überein. | [[Fähigkeiten, VFX & Audio]] |
| G7 | **Jede Figur ist in jeder Animation dieselbe Figur:** gleiche Proportionen, Farben und Größe in allen Richtungen. Kleidung, Haare und Umhänge reagieren auf Bewegung. Früher nur für Zaubermeisterin und Waldläufer gefordert, gilt jetzt für alle. | [[Klassen]], [[Visuelles Leitbild & Animation]] |
| G8 | **Ein gemeinsames Pixelraster:** keine willkürlichen Pixelgrößen, keine verzerrte Darstellung. | [[Visuelles Leitbild & Animation]] |
| G9 | **Fähigkeiten sind audiovisuelle Ereignisse** mit Phasen (Vorbereitung bis Abklingen). Ton und Bild werden gemeinsam entworfen. | [[Fähigkeiten, VFX & Audio]] |
| G10 | **Nur freigegebene Grafikquellen:** FirstGame-ArtPack und daraus abgeleitete eigene Grafik. Keine alten Projektgrafiken als Ersatz, keine kopierten fremden Assets. Referenzen wie Terranigma dienen nur der Bewegungsqualität. | [[Visuelles Leitbild & Animation]], [[Assets & Pipeline]] |
| G11 | **Ehrlicher Status:** Ein Sprite, eine abspielende Animation oder verursachter Schaden heißt nicht „fertig“. Es gilt die Statusskala des [[Qualitätsstandard]]. | [[Qualitätsstandard]] |
| G12 | **Keine Balancing-Zahlenänderungen ohne Auftrag** (HP, Schaden, XP, Klassenwerte, Skalierung, Drop-Raten). Darstellung darf sich ändern, Hitbox-Radien und Werte nicht. | `AGENTS.md` |
| G13 | **Performance-Budgets** gelten für jede neue Funktion (Partikel, Lichter, Stimmen, Instanzen). | [[Technische Architektur]] |
| G14 | **Bestehendes Drachenmodell und Originalquellen bleiben erhalten.** Erweitern statt ersetzen. | [[Assets & Pipeline]] |
| G15 | **Sichtbare Gefahr = Schadensfläche (WYSIWYG).** Warnung, aktive Fläche, Partikel und Treffertest nutzen dieselbe Geometrie. Gefahrenflächen sind zusammenhängend, ohne scheinbar sichere Lücken; die nächste Mechanik liegt immer oben (Auftrag 26.11., Phase 2A). | [[Kampf & Begegnungen]] |
| G16 | **Grundangriffe sehen aus wie das, was sie mechanisch sind.** Ein Grundpfeil ist ein physischer Pfeil. Element- oder Spezialoptik entsteht erst durch echte Element- oder Spezialmechanik. Gilt für alle Klassen (Auftrag 26.11., Phase 2B). | [[Fähigkeiten, VFX & Audio]] |
| G17 | **Progression ist qualitativ.** Grundstufe kompakt und hochwertig; höhere Stufen bekommen neue Komponenten und Phasen, nicht nur Größe oder Partikelzahl. Gegnerische Gefahren bleiben auch im Endgame lesbar (Phase 2B). | [[Fähigkeiten, VFX & Audio]] |
| G18 | **Persönliche Freigabe nur durch den Nutzer** im Review-Center. Technische QA ist keine Freigabe; freigegebene Inhalte sind Qualitätsreferenz (Phase 1). | AGENTS.md „Review-Workflow“, [[Review-Center]] |

## 6. Aufgelöste Widersprüche (Audit 25.11.2026)

| Frühere Anforderung | Neue bzw. gültige Regel | Grund |
|---|---|---|
| „Angriffe optisch viel zu klein, mehr visuelle Präsenz“ (Auftrag 22.11.); Zaubermeisterin „größer, eindrucksvoller“ | **Präsenz durch Klarheit, Kontrast, Timing und Ton statt Fläche.** Stufe 1 ist kompakt, aber sofort erkennbar. Die Größe wächst mit der Progression. | Auftrag 25.11. hat Vorrang. Die Erkennbarkeit aus dem 22.11. bleibt Pflicht. |
| „Zeitweise ein Großteil des Bildschirms von Projektilen bedeckt“ (Auftrag 22.11.) | **Kurze Dichte-Spitzen erlaubt, nie dauerhaft.** Ein erreichbarer Weg bleibt immer sichtbar. | `Boss-Design` F und Auftrag 25.11. (keine Schwierigkeit aus unlesbarem Chaos) |
| „Während Sprung und Slide unverwundbar“ (Auftrag 22.11., früh) | **Trefferhöhen** (Boden/hoch/alle). Nur die Ausweichrolle hat kurze, getrennt konfigurierbare Unverwundbarkeit. | Auftrag 22.11. (später), so umgesetzt |
| Warnfläche füllt sich vollständig radial (Auftrag 22.11., `CLASS_DRAGON_REPORT.md`) | **Dezente Warnung:** voller Umriss ab 0 %, Countdown am Rand, kontrollierte Intensivierung, Aufleuchten beim Einschlag. Normale Projektile bekommen keine Bodenwarnung. | Boss-System-2.0-Auftrag („teilweise zu präsent“), Bossphilosophie 23.11., Auftrag 25.11. |
| Drache: „sehr viele Sprites und Animationen sind ausdrücklich gewünscht“ | **Artikulierter Körper statt immer mehr Sprites.** Mehr Frames sind nur dort erwünscht, wo sie Qualität bringen. | Auftrag 25.11. |
| Anforderungen an Kleidung, Haare und „dieselbe Figur in jeder Animation“ nur für Zaubermeisterin und Waldläufer | **Global** (G7), auch für den Schwertkämpfer und künftige Klassen | Auftrag 25.11. |
| Visuelle Waffenstufen nach Spielerstufe 1/34/68, bewusst getrennt vom Waffenschaden (Auftrag 22.11.) | **Bleibt vorerst.** Soll: an die echte Waffenprogression koppeln, sobald das geplante Waffen-Upgrade-System existiert. | Auftrag 25.11. (Intensität folgt tatsächlichem Fortschritt) |
| `TALENTS_AND_EQUIPMENT.md`: „Ausrüstung am Charakter nicht sichtbar“; Systemnotiz Spieler | **Veraltet.** Seit 24.11. ist Ausrüstung als Ebenen sichtbar. Korrigiert. | Code-Stand |

## 7. Glossar

- **Klassen:** **Schwertmeister** (Code `Sword`, Figur `swordsmanv3`), **Arkanistin** (`Mage`, `magev3`), **Waldläufer** (`Ranger`, `rangerv3`).
  - Umbenannt am 25.11. (Nutzerentscheidung).
  - Frühere Namen in älteren Texten: Schwertkämpfer, Zaubermeisterin.
- **Gegnerränge:** normaler Gegner, Elite (noch nicht im Spiel), Miniboss (Minute 1 und 3), Hauptboss (ab Minute 5, alle 5 Minuten).
- **Warnung (Telegraph):** angekündigte Trefferfläche mit Countdown.
- **Aktive Phase:** Zeitraum, in dem eine Attacke Schaden verursachen kann.
- **Trefferhöhe:** `ground`, `high`, `all`.
- **Stufen:** Spielerstufe (XP), Zauberstufe 1–9, Talentrang, Gegenstandsstufe (Item-Level).
- **Welteinheit:** Koordinateneinheit des Raums.
- **Artpixel:** ein Pixel der Quellgrafik. Ihr Verhältnis regelt [[Visuelles Leitbild & Animation]].

## 8. Die Designdokumente

| Dokument | Fachgebiet |
|---|---|
| [[Kampf & Begegnungen]] | Kampfphilosophie, räumliche Entscheidungen, Warnungen, Fairness, Gegner- und Bossprinzipien, visuelle Hierarchie |
| [[Boss-Design]] | Bossregeln im Detail und Umsetzungsstand je Hauptboss |
| [[Klassen]] | Anforderungen an jede Klasse und Klassenprofile |
| [[Progression & Builds]] | Level-ups, Zauber, Talente, Ausrüstung, Waffenentwicklung |
| [[Visuelles Leitbild & Animation]] | Art Direction, Terranigma-Referenz, Pixelraster, Animationsanforderungen |
| [[Fähigkeiten, VFX & Audio]] | Fähigkeiten als Ereignisse, VFX, visuelle Progression, Ton |
| [[Technische Architektur]] | Ist-Architektur, Technikvergleich, Zielarchitektur, Budgets |
| [[Assets & Pipeline]] | Asset-Bestand, Struktur, Namen, Arbeitsablauf, Migrationsplan |
| [[Qualitätsstandard]] | Statusskala, Abnahmekriterien, Review-Prozess |
| [[Roadmap & Vertical Slice]] | Priorisierte Schritte und Vertical-Slice-Spezifikation |
