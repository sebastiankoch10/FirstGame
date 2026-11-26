if (!instance_exists(ObjectRender)) instance_create_depth(0, 0, 0, ObjectRender); // pixel-perfect output (render_pipeline)
menu_index = 0;
menu_mode = "main";
// Returning from a review scenario opens the Review Center list again.
if (variable_global_exists("menu_return_mode") && global.menu_return_mode=="review" && review_enabled()) {menu_mode="review"; review_center_open();}
global.menu_return_mode = "";
if (!variable_global_exists("selected_character")) global.selected_character = "Sword";
if (!variable_global_exists("selected_level")) global.selected_level = 0;
if (!variable_global_exists("master_volume")) global.master_volume = 1;
submenu_index = 0;
pending_new_game = false;
global.round_active = false;
global.menu_transition_lock = false;

fg_audio_init(); fg_music_set("menu");
