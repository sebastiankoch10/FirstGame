reset_round();
hotbar_init();
// Unpack the shared texture groups at run start (no-op once resident): bz2 pages unpacked on first use mid-fight
// cost up to ~350 ms in one frame (perf suite, 26.11.). Level groups are prefetched by level_world_create.
var _tp=get_timer();texture_prefetch("Default");texture_prefetch("Equipment");
show_debug_message("TEXTURE_PREFETCH ms "+string((get_timer()-_tp)/1000));

global._ui_hover_index = -1;

show_debug_message("ObjectController: Initialisierung abgeschlossen.");
show_debug_message("RUNTIME room=" + room_get_name(room) + " player_instances=" + string(instance_number(ObjectPlayer)) + " spawner_instances=" + string(instance_number(ObjectSpawner)));

// Hazard drawings stay visible above world sprites; GUI is drawn separately.
depth=-10000;


atmosphere_init();
