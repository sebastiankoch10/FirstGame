# Basemodel ohne Ausrüstung (Ablage, noch leer)

Hier liegen die Atlanten der drei Basemodels (Schwertkämpfer, Arkanistin, Waldläufer), sobald sie geliefert sind:
- je Klasse 4 Atlanten (walk, combat, mobility, reaction);
- je Atlas 8 × 8 Zellen, also 256 Posen je Klasse. Ausnahme: Waldläufer combat hat wie das Original 9 Reihen, die 9. bleibt ungenutzt.
- Jeder Atlas hat exakt die Pixelgröße seines Originals; die Größen weichen teils von 1254 × 1254 ab (Tabelle in Abschnitt 7.1). Jede Figur steht an derselben Stelle wie im Original.

**Regel:** Ein Sprite mit sichtbarer Ausrüstung ist kein Basemodel.
- Nicht enthalten: Umhang, Mantel, Robe, Schal, Rüstungs- und Schulterteile, Gürtel- und Metallteile, Taschen, Köcher, Waffe.
- Enthalten: Körper, Kopf, Haare, Gesicht, sehr einfache, eng anliegende Basiskleidung, Stoffschuhe. Die Hand ist leer, bleibt aber in Griffhaltung.

- Regel im Wortlaut: `docs/Design/Visuelles Leitbild & Animation.md`, Abschnitt 5.5a.
- Anforderungen (Maße, Posen, Dateinamen, Abnahme, Vorlage für die Quelle): `docs/Design/Assets & Pipeline.md`, Abschnitt 7.1.
- Umstieg ohne Mischbetrieb: `docs/Design/Assets & Pipeline.md`, Abschnitt 7.7.
- Technische Prüfung einer Lieferung: `python tests/tools/characters/check_base_neutral.py` (mit `--dir PFAD` auch für Entwürfe außerhalb dieses Ordners).
- Posen-Vorlagen (Originale): `FirstGame_ArtPack/characters/swordsman_v3/sources/<atlas>.png` und `FirstGame_ArtPack/characters/class_overhaul/sources/<mage|ranger>_<atlas>.png`.
- Herkunft (Werkzeug bzw. Künstler, Datum, Lizenz) bei der Lieferung hier ergänzen.
