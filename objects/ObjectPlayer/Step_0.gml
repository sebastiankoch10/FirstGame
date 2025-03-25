// Angriff prüfen
if (keyboard_check_pressed(ord("E"))) {
    if (state == player_state.attacking) {
        buffered_attack = true; // Angriff wird gepuffert, wenn bereits ein Angriff läuft
    } else {
        // Neue Angriffsanimationslogik
        switch (attack_stage) {
            case 1:
                sprite_index = attack_sprite_1; // Erste Angriffsanimation
                break;
            case 2:
                sprite_index = attack_sprite_2; // Zweite Angriffsanimation
                break;
            case 3:
                sprite_index = attack_sprite_3; // Dritte Angriffsanimation
                break;
        }

        image_index = 0;                // Animation von Anfang starten
        image_speed = 1;                // Geschwindigkeit der Animation
        state = player_state.attacking; // Zustand auf "angreifend" setzen
        attack_timer = attack_delay;    // Abklingzeit zurücksetzen
    }
}

// Angriffszustand überwachen
if (state == player_state.attacking) {
    // Prüfen, ob die Animation abgeschlossen ist
    if (image_index >= sprite_get_number(sprite_index) - 1) {
        if (buffered_attack) {
            // Gepufferte Eingabe verarbeiten: zur nächsten Phase wechseln
            attack_stage += 1;
            if (attack_stage > 3) {
                attack_stage = 1; // Zurück zur ersten Animation
            }

            // Nächste Angriffsanimation starten
            buffered_attack = false; // Puffer zurücksetzen
            switch (attack_stage) {
                case 1:
                    sprite_index = attack_sprite_1;
                    break;
                case 2:
                    sprite_index = attack_sprite_2;
                    break;
                case 3:
                    sprite_index = attack_sprite_3;
                    break;
            }
            image_index = 0; // Animation von Anfang starten
            image_speed = 1;
        } else {
            // Keine gepufferte Eingabe: Zustand zurücksetzen
            state = player_state.idle;
            attack_stage = 1; // Optional: Zyklus zurücksetzen
        }
    }

    // Bewegungslogik während des Angriffszustands mit halber Geschwindigkeit
    var reducedSpeed = moveSpeed / 2;
    if (keyboard_check(vk_left)) {
        x -= reducedSpeed; // Bewege nach links
        image_xscale = -1; // Richtung links
    }
    if (keyboard_check(vk_right)) {
        x += reducedSpeed; // Bewege nach rechts
        image_xscale = 1; // Richtung rechts
    }
    if (keyboard_check(vk_up)) {
        y -= reducedSpeed; // Bewege nach oben
    }
    if (keyboard_check(vk_down)) {
        y += reducedSpeed; // Bewege nach unten
    }
}

// Bewegung prüfen, wenn nicht im Angriff
if (state != player_state.attacking) {
    var moving = false;

    if (keyboard_check(vk_left)) {
        x -= moveSpeed; // Bewege nach links
        image_xscale = -1; // Richtung links
        moving = true;
    }
    if (keyboard_check(vk_right)) {
        x += moveSpeed; // Bewege nach rechts
        image_xscale = 1; // Richtung rechts
        moving = true;
    }
    if (keyboard_check(vk_up)) {
        y -= moveSpeed; // Bewege nach oben
        moving = true;
    }
    if (keyboard_check(vk_down)) {
        y += moveSpeed; // Bewege nach unten
        moving = true;
    }

    // Zustand basierend auf Bewegung setzen
    if (moving) {
        state = player_state.running;
    } else {
        state = player_state.idle;
    }

    // Spieler innerhalb des Raums begrenzen
    if (x < 0) x = 0; // Links
    if (x > room_width - sprite_width) x = room_width - sprite_width; // Rechts
    if (y < 0) y = 0; // Oben
    if (y > room_height - sprite_height) y = room_height - sprite_height; // Unten
}

// Angriffs-Timer überwachen
if (attack_timer > 0) {
    attack_timer -= 1;
}

// Zustandslogik für Animationen
switch (state) {
    case player_state.idle:
        if (sprite_index != spr_adventurer_idle) {
            sprite_index = spr_adventurer_idle; // Setze Idle-Animation
        }
        break;

    case player_state.running:
        if (sprite_index != spr_adventurer_run) {
            sprite_index = spr_adventurer_run; // Setze Lauf-Animation
        }
        break;

    case player_state.attacking:
        // Animation wird bereits im Angriffs-Code gesetzt
        break;
}

// Kamera folgt dem Spieler
var cam_x = x - 400; // Spielerposition minus halbe Kamerabreite 
var cam_y = y - 300; // Spielerposition minus halbe Kamerahöhe
camera_set_view_pos(camera, cam_x, cam_y); // Position aktualisieren


// Hitbox für das Schwert erstellen
if (keyboard_check_pressed(ord("E")) && state != player_state.attacking) {
    // Hitbox erstellen
    var hitbox = instance_create_layer(x + (image_xscale * 20), y, "Instances", ObjectSwordHitbox);
    hitbox.image_xscale = image_xscale; // Richtung anpassen
    hitbox.lifetime = 10; // Lebensdauer der Hitbox in Frames
}

if (state == player_state.attacking) {
    // Hitbox für das Schwert erstellen
    if (!instance_exists(ObjectSwordHitbox)) {
        var hitbox = instance_create_layer(x + (image_xscale * 20), y, "Instances", ObjectSwordHitbox);
        hitbox.image_xscale = image_xscale; // Richtung anpassen


    }
} else {
    // Hitbox entfernen, wenn nicht im Angriff
    with (ObjectSwordHitbox) {
        instance_destroy();
    }
}

if (global.game_paused) {
    show_debug_message("Spiel pausiert in ObjectPlayer");
    return;
}


