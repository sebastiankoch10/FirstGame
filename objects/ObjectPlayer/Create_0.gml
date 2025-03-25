// Zustände definieren
enum player_state {
    idle,
    running,
    attacking
}

// Initiale Werte setzen
state = player_state.idle; // Startzustand
max_hp = 100;
hp = 100; // Setze die Start-HP des Spielers auf 100 (oder einen anderen Wert)
moveSpeed = 3;             // Bewegungsgeschwindigkeit
image_xscale = 1;          // Richtung (rechts als Standard)

// Angriffslogik
attack_stage = 1;          // Aktuelle Angriffsanimation (1 = erste Animation)
attack_timer = 0;          // Timer für Angriffssequenz (Abklingzeit)
attack_delay = 30;         // Dauer der Abklingzeit (in Frames, 30 Frames = 0.5 Sek. bei 60 FPS)
buffered_attack = false;   // Angriffspuffer: Speichert Eingaben während der Animation

attack_sprite_1 = spr_adventurer_attack1;
attack_sprite_2 = spr_adventurer_attack2;
attack_sprite_3 = spr_adventurer_attack3;
 
 // Kamera-Setup
camera = camera_create();
camera_set_view_size(camera, 800, 600); // Sichtgröße (800x600)
camera_set_view_target(camera, ObjectPlayer); // Fokussiere auf Spieler
camera_set_view_speed(camera, 5, 5); // Geschwindigkeit des Kamera-Fokus
view_set_camera(0, camera); // Viewport 0 verwendet diese Kamera
