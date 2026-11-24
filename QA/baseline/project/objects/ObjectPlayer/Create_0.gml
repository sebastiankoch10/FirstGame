// ObjectPlayer: Create
global.player = id;

enum player_state {
    idle,
    running,
    attacking
}

enum player_motion_state {
    grounded,
    rising,
    falling,
    diving,
    sliding
}

// Initiale Werte setzen
state = player_state.idle; // Startzustand
if (!variable_global_exists("selected_character")) global.selected_character = "Sword";

switch (global.selected_character) {
    case "Mage":
        max_hp = 70;
        moveSpeed = 2.8;
        player_power = 4;
        break;
    case "Ranger":
        max_hp = 82;
        moveSpeed = 4.2;
        player_power = 1;
        break;
    default:
        max_hp = 120;
        moveSpeed = 3.2;
        player_power = 2;
        break;
}
hp = max_hp;
__base_moveSpeed = moveSpeed;
__base_player_power = player_power;
invulnerable_timer = 0;
damage_reduction = 0;
image_xscale = 1;          // Richtung (rechts als Standard)
player_scale = 1.3;
image_yscale = 1;

jump_height = 0;
jump_velocity = 0;
motion_state = player_motion_state.grounded;
jump_elapsed = 0;
jump_direction = 0;
dive_direction = 0;
slide_speed = 0;
slide_remaining = 0;
slide_timer = 0;
slide_direction = 0;
facing_direction = 0;
player_initialize_artpack();

jump_takeoff_speed = 8.5;
jump_gravity = 0.5;
jump_horizontal_speed = 1.05;
jump_dive_start_speed = 3;
jump_dive_acceleration = 0.8;
jump_dive_max_speed = 12;
slide_max_distance = 148;
slide_start_speed = 8;
slide_deceleration = 0.16;
slide_max_frames = 40;
attack_image_speed = 0.18;
attack_hit_start_frame = 2; // The sword arc starts on frame 2 in all three attack sprites.
attack_damage = 20;

// Angriffslogik
attack_stage = 1;          // Aktuelle Angriffsanimation (1 = erste Animation)
attack_timer = 0;          // Timer für Angriffssequenz (Abklingzeit)
buffered_attack = false;   // Angriffspuffer: Speichert Eingaben während der Animation
attack_hitbox_created = false;
attack_cooldown = 0;


global.active_spells = [];
global.hotbar = array_create(6, undefined);
player_combat_init();

 // Kamera-Setup
camera = camera_create();
camera_set_view_size(camera, 800, 600); // Sichtgröße (800x600)
view_set_camera(0, camera); // Viewport 0 verwendet diese Kamera
