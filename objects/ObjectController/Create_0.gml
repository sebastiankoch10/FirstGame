reset_round();
hotbar_init();
// Shared texture pages are unpacked in the main menu (texture_warmup_step); this completes whatever is still missing,
// so no page is unpacked mid-fight (up to ~350 ms per frame, perf suite 26.11.).
texture_warmup_finish();

global._ui_hover_index = -1;

show_debug_message("ObjectController: Initialisierung abgeschlossen.");
show_debug_message("RUNTIME room=" + room_get_name(room) + " player_instances=" + string(instance_number(ObjectPlayer)) + " spawner_instances=" + string(instance_number(ObjectSpawner)));

// Hazard drawings stay visible above world sprites; GUI is drawn separately.
depth=-10000;


atmosphere_init();
