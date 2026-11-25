if (!instance_exists(ObjectRender)) instance_create_depth(0, 0, 0, ObjectRender); // pixel-perfect output (render_pipeline)
menu_index = 0;
menu_mode = "main";
if (!variable_global_exists("selected_character")) global.selected_character = "Sword";
if (!variable_global_exists("selected_level")) global.selected_level = 0;
if (!variable_global_exists("master_volume")) global.master_volume = 1;
submenu_index = 0;
pending_new_game = false;
global.round_active = false;
global.menu_transition_lock = false;

fg_audio_init(); fg_music_set("menu");
