reset_round();
hotbar_init();

global._ui_hover_index = -1;

show_debug_message("ObjectController: Initialisierung abgeschlossen.");
show_debug_message("RUNTIME room=" + room_get_name(room) + " player_instances=" + string(instance_number(ObjectPlayer)) + " spawner_instances=" + string(instance_number(ObjectSpawner)));

// Hazard drawings stay visible above world sprites; GUI is drawn separately.
depth=-10000;


atmosphere_init();
