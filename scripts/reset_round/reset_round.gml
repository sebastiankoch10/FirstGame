function reset_round()
{
    if(!variable_global_exists("boss_test_pending") || !is_struct(global.boss_test_pending))boss_test_end();
    if (!variable_global_exists("selected_character")) global.selected_character = "Sword";
    if (!variable_global_exists("selected_level")) global.selected_level = 0;
    global.start_choice_pending=false;
    run_stats_reset();
    global.run_token=variable_global_exists("run_token") ? global.run_token+1 : 1;
    global.magnet_sequence=0;global.magnet_metrics={activations:0,collision_activations:0,swept_activations:0,marked:0,collected:0,xp:0};
    global.run_kills=0;global.run_boss_kills=0;global.progression_samples=[];global.progression_sample_index=0;
    global.coin_xp_earned=0;global.damage_labels=[];global.impact_fx=[];
    global.sword_combo_metrics={chains:0,swings:0,finishers:0};
    spell_v2_init();global.class_effects=[];global.choice_rng=irandom(1000000000)+1;global.next_levelup_time=0;
    talent_reset_run();equipment_reset_run();spell_vfx_reset();fxp_reset();atmos_reset();fx_world_reset();global.fxs={bursts:0};fx_init();global.fx.shocks=[];global.fx.heats=[];
    with(ObjectSkeletonRemains)instance_destroy();
    global.choice_mouse_armed=false;global.choice_open=false;
    instance_activate_object(ObjectMagnetOrb);instance_activate_object(ObjectCoin);
    with(ObjectMagnetOrb)instance_destroy();with(ObjectCoin)instance_destroy();
    global.round_seconds=0;
    boss_system_reset();
    global.settings_active=false;
    global.combat_effects=[];
    if (!variable_global_exists("master_volume")) global.master_volume=1;
    global.active_spells = [];
    global.passive_spells = [];
    global.hotbar = array_create(6, undefined);
    global.coins = 0;
    global.coins_needed = progression_cost(1);
    global.minimap_visible=true;weather_init();
    global.chain_segments=[];global.light_pulses=[];
    global.population_metrics={alive:0,nearby:0,visible:0,minimum:18,cap:180,refill_ms:0};
    global.current_level = 1;
    global.start_time = current_time;
    global.monster_hp_multiplier = 1;
    global.monster_damage_multiplier = 1;
    global.boss_index = 0;
    global.boss_exists = false;
    global.levelup_active = false;
    global.chest_collected = false;
    global.game_paused = false;
    global.normal_pause_active = false;
    global.pause_initialized = false;
    global.spell_options = [];
    global.selected_spell_index = 0;
    global._ui_hover_index = -1;
    global._pause_index = 0;
    global.game_over = false;
    global.round_active = true;
    global.menu_transition_lock = false;

    if (!variable_global_exists("qa_test_mode")) global.qa_test_mode = false;
    if (!variable_global_exists("qa_test_speed")) global.qa_test_speed = 1;

    if (!variable_global_exists("selected_level")) global.selected_level = 0;
    // Unchanged per-slot difficulty values (1 / 0.9+1.1 / 1.25+1.15), now owned by the level definitions.
    var level_cfg=level_def(global.selected_level);
    global.monster_hp_multiplier = level_cfg.hp_mult;
    global.monster_damage_multiplier = level_cfg.damage_mult;
    global.level_puffs=[];global.level_speed_factor=1;global.level_player_hazard="";

    global.base_monster_hp_multiplier=global.monster_hp_multiplier;
    global.base_monster_damage_multiplier=global.monster_damage_multiplier;

    if (variable_global_exists("player") && instance_exists(global.player)) {
        switch (global.selected_character) {
            case "Mage":
                global.player.max_hp = 70;
                global.player.moveSpeed = 2.8;
                global.player.player_power = 4;
                break;
            case "Ranger":
                global.player.max_hp = 82;
                global.player.moveSpeed = 4.2;
                global.player.player_power = 1;
                break;
            default:
                global.player.max_hp = 120;
                global.player.moveSpeed = 3.2;
                global.player.player_power = 2;
                break;
        }
        global.player.hp = global.player.max_hp;
        global.player.__base_player_power = global.player.player_power;
        global.player.__base_moveSpeed = global.player.moveSpeed;
        global.player.damage_reduction = 0;
        global.player.orbit_frame = 0;
        global.player.orbit_angle = 0;
        global.player.passive_power_bonus = 0;
        global.player.passive_ms_bonus = 0;
        global.player.jump_height = 0;
        global.player.jump_velocity = 0;
        global.player.jump_elapsed = 0;
        global.player.jump_direction = 0;
        global.player.dive_direction = 0;
        global.player.motion_state = 0;
        global.player.slide_speed = 0;
        global.player.slide_remaining = 0;
        global.player.slide_timer = 0;
        global.player.slide_direction = 0;
        global.player.attack_timer = 0;
        global.player.attack_stage = 1;
        global.player.buffered_attack = false;
        global.player.attack_hitbox_created = false;
        global.player.attack_cooldown = 0;
        global.player.state = 0;
        with (global.player) player_initialize_artpack();
        global.player.image_index = 0;
        global.player.image_speed = 0;
        global.player.image_xscale = 1;
        global.player.image_yscale = 1;
        global.player.player_scale = 1; // art 1:1 (density switch 25.11.2026)
        with(global.player) player_combat_init();
        global.player.image_angle = 0;
        with (ObjectSwordHitbox) {
            if (owner == global.player) instance_destroy();
        }
    }

    with (ObjectMonster) instance_destroy();
    with (ObjectBossMonster) instance_destroy();
    with (ObjectCoin) instance_destroy();
    with (ObjectFireball) instance_destroy();
    with (ObjectIceball) instance_destroy();
    with (ObjectLightningball) instance_destroy();
    with (ObjectSwordHitbox) instance_destroy();
}
