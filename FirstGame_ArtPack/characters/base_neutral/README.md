# Basemodel ohne Ausrüstung (Ablage, noch leer)

Hier liegen die Atlanten der drei Basemodels (Schwertkämpfer, Arkanistin, Waldläufer), sobald sie geliefert sind:
- je Klasse 4 Atlanten (walk, combat, mobility, reaction);
- je Atlas 8 × 8 Zellen, also 256 Posen je Klasse.

**Regel:** Ein Sprite mit sichtbarer Ausrüstung ist kein Basemodel.
- Nicht enthalten: Umhang, Mantel, Robe, Schal, Rüstungs- und Schulterteile, Gürtel- und Metallteile, Taschen, Köcher, Waffe.
- Enthalten: Körper, Kopf, Haare, Gesicht, sehr einfache, eng anliegende Basiskleidung, Stoffschuhe. Die Hand ist leer, bleibt aber in Griffhaltung.

- Regel im Wortlaut: `docs/Design/Visuelles Leitbild & Animation.md`, Abschnitt 5.5a.
- Anforderungen (Maße, Posen, Dateinamen, Abnahme, Vorlage für die Quelle): `docs/Design/Assets & Pipeline.md`, Abschnitt 7.1.
- Umstieg ohne Mischbetrieb: `docs/Design/Assets & Pipeline.md`, Abschnitt 7.7.
- Technische Prüfung einer Lieferung: `python tests/tools/characters/check_base_neutral.py`.
- Herkunft (Werkzeug bzw. Künstler, Datum, Lizenz) bei der Lieferung hier ergänzen.
