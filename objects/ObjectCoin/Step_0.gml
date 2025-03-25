/// @description Hier Beschreibung einfügen
// Sie können Ihren Code in diesem Editor schreiben
// Prüfen, ob der Spieler die Münze berührt
// Prüfen, ob der Spieler die Münze berührt
if (place_meeting(x, y, ObjectPlayer)) {
    // Münze einsammeln
    global.coins += 1;

    // Münze zerstören
    instance_destroy();
}
