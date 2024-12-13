// Define states
enum player_state {
    idle,
    running
}

// Initialisiere den Startzustand, falls er im Create-Event nicht bereits gesetzt wurde
if (!variable_global_exists("state")) {
    state = player_state.idle;
}

var moveSpeed = 5; // Bewegungsgeschwindigkeit

// Bewegung prüfen
if (keyboard_check(vk_left)) {
    x -= moveSpeed; // Bewege nach links
    state = player_state.running; // Zustand: Laufen
    image_xscale = -1; // Spiegeln für linke Richtung
} 
if (keyboard_check(vk_right)) {
    x += moveSpeed; // Bewege nach rechts
    state = player_state.running; // Zustand: Laufen
    image_xscale = 1; // Normale Richtung
}
if (keyboard_check(vk_up)) {
    y -= moveSpeed; // Bewege nach oben
    state = player_state.running; // Zustand: Laufen
}
if (keyboard_check(vk_down)) {
    y += moveSpeed; // Bewege nach unten
    state = player_state.running; // Zustand: Laufen
}

// Prüfen, ob keine Bewegungstaste gedrückt wird
if (!keyboard_check(vk_left) && !keyboard_check(vk_right) && !keyboard_check(vk_up) && !keyboard_check(vk_down)) {
    state = player_state.idle; // Zustand: Idle
}

// Zustandslogik für Animationen
switch (state) {
    case player_state.idle:
        // Nur setzen, wenn nötig
        if (sprite_index != adventurer_idle) {
            sprite_index = adventurer_idle; // Setze Idle-Animation
           
         
        }
        break;

    case player_state.running:
        // Nur setzen, wenn nötig
        if (sprite_index != adventurer_run) {
            sprite_index = adventurer_run; // Setze Lauf-Animation
          
        }
        break;
}
