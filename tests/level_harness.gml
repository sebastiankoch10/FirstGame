/// Native level-expansion checks. Injected only into the isolated test copy by tests/tools/run_level_smoke.py.
function gp_key_down(_key) {return global.lv_hold_key==_key;}
function gp_key_pressed(_key) {return global.lv_press_key==_key;}
function gp_mouse_down(_button) {return false;}
function gp_mouse_pressed(_button) {return false;}
function gp_mouse_x() {return instance_exists(ObjectPlayer) ? ObjectPlayer.x+200 : 0;}
function gp_mouse_y() {return instance_exists(ObjectPlayer) ? ObjectPlayer.y : 0;}
function gp_gui_x(_device) {return -100;}
function gp_gui_y(_device) {return -100;}
function lv_check(_ok,_msg) {
    global.lv_checks++;
    if(!_ok){global.lv_failed=true;array_push(global.lv_failures,"L"+string(global.lv_level)+" "+_msg);show_debug_message("LEVEL FAIL L"+string(global.lv_level)+" "+_msg);}
    else show_debug_message("LEVEL PASS L"+string(global.lv_level)+" "+_msg);
}
function lv_metric(_key,_value) {variable_struct_set(global.lv_metrics,"L"+string(global.lv_level)+"_"+_key,_value);}
function lv_capture(_name) {global.lv_capture_name=_name;}
function lv_render_capture() {
    if(!variable_global_exists("lv_capture_name") || global.lv_capture_name=="")return;
    if(surface_exists(application_surface))surface_save(application_surface,"lvcapture-"+global.lv_capture_name+".png");
    show_debug_message("LEVEL_CAPTURE "+global.lv_capture_name);global.lv_capture_name="";
}
function lv_init() {
    if(variable_global_exists("lv_ready"))return;
    global.lv_ready=true;global.lv_checks=0;global.lv_failed=false;global.lv_failures=[];global.lv_metrics={};
    global.lv_level=0;global.lv_classes=["Sword","Ranger","Mage"];global.lv_stage=0;global.lv_frame=0;
    global.lv_hold_key=-1;global.lv_press_key=-1;global.lv_capture_name="";global.lv_done=false;global.lv_restart_count=0;
    global.lv_dt_sum=0;global.lv_dt_n=0;global.lv_dt_max=0;
}
/// Main menu: drive the real menu functions (Neues Spiel -> Klasse -> Level).
function lv_menu_tick() {
    lv_init();
    global.lv_press_key=-1;global.lv_hold_key=-1;
    if(global.lv_done) {
        show_debug_message("LEVEL_RESULT "+json_stringify({passed:!global.lv_failed,checks:global.lv_checks,failures:global.lv_failures,metrics:global.lv_metrics}));
        game_end();return;
    }
    if(global.lv_stage==99) {
        // Returned to title: nothing from the previous world may survive the room change.
        lv_check(instance_number(ObjectLevelProp)==0 && instance_number(ObjectLevelWorld)==0 && instance_number(ObjectMonster)==0,"title screen holds no world props, world objects or enemies");
        if(variable_global_exists("lv_amb") && global.lv_amb!=-1){lv_check(!audio_is_playing(global.lv_amb),"ambient loop stops when leaving the world");global.lv_amb=-1;}
        global.lv_level++;global.lv_stage=0;
        if(global.lv_level>=level_count()){global.lv_done=true;return;}
    }
    if(global.lv_stage==10) {global.lv_menu_wait--;if(global.lv_menu_wait>0)return;global.lv_stage=0;global.lv_menu_done=true;}
    if(global.lv_stage!=0)return;
    if(!variable_global_exists("lv_menu_done") || !global.lv_menu_done) {
        // Show the real level select for this entry for a few frames and capture the GUI.
        menu_mode="levels";menu_index=global.lv_level;global.lv_menu_shot="menu-levels-"+string(global.lv_level);global.lv_menu_wait=4;global.lv_stage=10;return;
    }
    global.lv_menu_done=false;
    lv_check(array_length(menu_labels("levels"))==3,"level select lists three levels");
    menu_mode="main";menu_activate(0);
    lv_check(menu_mode=="characters","new game opens character select");
    menu_activate(global.lv_level mod 3);
    lv_check(menu_mode=="levels","character choice opens level select");
    var labels=menu_labels("levels");
    lv_check(labels[global.lv_level]==level_def(global.lv_level).name,"level label "+labels[global.lv_level]);
    global.lv_stage=1;global.lv_frame=0;
    menu_activate(global.lv_level);
}
function lv_kill(_e) {if(instance_exists(_e)){_e.hp=0;}}
function lv_resolve_choice() {
    if(!(global.levelup_active || global.chest_collected))return false;
    if(array_length(global.spell_options)>0 && is_struct(global.spell_options[0]) && variable_struct_exists(global.spell_options[0],"id"))learn_spell(global.spell_options[0].id);
    global.choice_open=false;global.choice_mouse_armed=false;global.chest_collected=false;global.levelup_active=false;global.game_paused=false;
    instance_activate_all();global.pause_initialized=false;global.next_levelup_time=global.round_seconds+progression_config().min_gap;
    if(instance_exists(ObjectPlayer)){ObjectPlayer.menu_input_guard=1;apply_passives(ObjectPlayer);}
    return true;
}
function lv_place(_x,_y) {
    var pl=ObjectPlayer;pl.x=_x;pl.y=_y;pl.pickup_prev_x=_x;pl.pickup_prev_y=_y;pl.motion_state=player_motion_state.grounded;pl.dodge_timer=0;pl.jump_height=0;
    camera_set_view_pos(pl.camera,clamp(_x-VIEW_W/2,0,room_width-VIEW_W),clamp(_y-VIEW_H/2,0,room_height-VIEW_H));
}
function lv_clear_enemies() {with(ObjectMonster)instance_destroy();with(ObjectBossMonster)instance_destroy();with(ObjectCoin)instance_destroy();with(ObjectChest)instance_destroy();with(ObjectMagnetOrb)instance_destroy();global.active_boss=noone;global.boss_exists=false;}
function lv_find_hazard(_kind) {
    if(!variable_global_exists("level_hazards"))return undefined;
    for(var i=0;i<array_length(global.level_hazards);i++)if(global.level_hazards[i].kind==_kind)return global.level_hazards[i];
    return undefined;
}
function lv_level_kinds() {return level_def().id=="swamp" ? ["swamp_crawler","swamp_skeleton","swamp_mushroom","swamp_knight"] : ["ash_warrior","cursed_armor","ice_spirit","construct"];}
/// Controller tick: a frame-driven script per level. Real Step/Draw code runs after this prefix every frame.
function lv_controller_tick() {
    lv_init();
    global.lv_press_key=-1;global.lv_hold_key=-1;
    if(global.lv_stage==0 || global.lv_stage==99)return;
    var f=global.lv_frame;global.lv_frame++;
    var pl=instance_exists(ObjectPlayer) ? ObjectPlayer : noone,gen=level_generated(),lv=level_def();
    var dt=max(0,delta_time/1000000);
    if(global.lv_stage!=6 && (global.levelup_active || global.chest_collected))lv_resolve_choice();
    var built=level_def().world!="generated" || room_exists(asset_get_index(level_def().room_name));
    if(global.lv_stage==1) {
        if(f==0) {
            lv_check(room==level_room(global.lv_level),"selected level opens its own room ("+room_get_name(room)+")");
            lv_check(instance_exists(pl) && instance_number(ObjectPlayer)==1,"exactly one player");
            lv_check(global.round_seconds<1 && global.current_level==1 && global.coins==0,"fresh run state (time, level, coins)");
            if(global.lv_level>0 && !built){lv_metric("status","NOT RUN: room not built yet");}
            if(global.lv_level>0 && built) {
                lv_check(gen,"generated world is ready");
                lv_check(instance_number(ObjectLevelWorld)==1,"exactly one world object");
                lv_check(instance_number(ObjectLevelProp)>600,"world props created ("+string(instance_number(ObjectLevelProp))+")");
                lv_check(array_length(global.level_hazards)>=20,"environment hazards present");
                lv_check(gen && sprite_exists(ObjectLevelWorld.ground_sprite) && sprite_get_number(ObjectLevelWorld.ground_sprite)==64,"64 ground chunks");
                lv_check(!scenery_point_blocked(pl.x,pl.y-6,10),"player start is free");
                lv_metric("props",instance_number(ObjectLevelProp));
                lv_check(ObjectLevelWorld.ambient_handle!=-1 && audio_is_playing(ObjectLevelWorld.ambient_handle),"ambient loop plays (own synthesized prototype)");
            }
            lv_check(audio_exists(level_music_asset()),"level music resolves");
            ObjectSpawner.population_timer=999;
        }
        if(f==40)lv_capture("start-"+lv.id);
        if(f==44 && gen && array_length(ObjectLevelWorld.data.sites)>0) {
            // Scenic preview at the first landmark: the level-select image is a real native frame.
            var site=ObjectLevelWorld.data.sites[0];lv_place(site.x,site.y+190);
        }
        if(f==70 && gen)lv_capture("preview-"+lv.id);
        if(f==74) {lv_place(2112,1952);global.lv_stage=2;global.lv_frame=0;}
        return;
    }
    if(global.lv_stage==2) { // movement + collision
        if(f==0){global.lv_x0=pl.x;}
        if(f<30)global.lv_hold_key=ord("D");
        if(f==31)lv_check(pl.x>global.lv_x0+40 || scenery_point_blocked(pl.x+14,pl.y-6,10),"WASD moves the player ("+string(pl.x-global.lv_x0)+" px)");
        if(f==32 && gen) {
            // Walk into a blocking prop: the player must stop outside its footprint.
            var target=noone;
            with(ObjectLevelProp)if(prop_block==1 && prop_ba>=14 && target==noone)target=id;
            lv_check(instance_exists(target),"blocking prop exists");
            if(instance_exists(target)){lv_place(target.x-90,target.y);global.lv_target=target;}
        }
        if(f>32 && f<80 && gen)global.lv_hold_key=ord("D");
        if(f==80 && gen && instance_exists(global.lv_target)) {
            var t=global.lv_target,inside=((pl.x-t.x)*(pl.x-t.x))/(t.prop_ba*t.prop_ba)+((pl.y-6-t.y)*(pl.y-6-t.y))/(t.prop_ba*0.64*t.prop_ba*0.64)<0.7;
            lv_check(!inside,"player does not walk through a blocking prop");
            lv_check(pl.x<t.x+t.prop_ba+20,"blocking prop stops or deflects the player");
        }
        if(f==82){global.lv_stage=3;global.lv_frame=0;lv_place(2112,1952);}
        return;
    }
    if(global.lv_stage==3) { // natural spawns
        if(f==0){lv_clear_enemies();ObjectSpawner.population_timer=0;}
        if(f==120) {
            var n=instance_number(ObjectMonster);lv_check(n>=8,"population spawns enemies ("+string(n)+")");
            var ok=true,kinds=lv_level_kinds();
            with(ObjectMonster){if(gen){if(!variable_instance_exists(id,"lvl_kind") || !array_contains(kinds,lvl_kind))ok=false;}else if(!master_skeleton)ok=false;}
            lv_check(ok,"every spawned enemy belongs to this level's pool");
            global.lv_stage=4;global.lv_frame=0;
        }
        return;
    }
    if(global.lv_stage==4) { // each authored kind: chase, strike, take damage, die, drop XP, leave remains
        if(!gen){global.lv_stage=6;global.lv_frame=0;return;}
        var kinds=lv_level_kinds();
        if(f==0){lv_clear_enemies();ObjectSpawner.population_timer=999;lv_place(2112,1952);pl.hp=pl.max_hp;global.lv_hp0=pl.hp;global.lv_kind_i=0;global.lv_kf=0;global.lv_spell_backup=global.active_spells;global.active_spells=[];}
        // Enemy AI is checked in isolation: the player's weapon and spells pause, otherwise stun/knockback hides the AI.
        pl.weapon_cooldown=max(pl.weapon_cooldown,30);pl.class_pending=0;with(ObjectFireball)instance_destroy();with(ObjectIceball)instance_destroy();with(ObjectLightningball)instance_destroy();
        var k=global.lv_kind_i;
        if(k>=array_length(kinds)){global.active_spells=global.lv_spell_backup;global.lv_stage=5;global.lv_frame=0;return;}
        var kf=global.lv_kf;global.lv_kf++;
        if(kf==0){lv_clear_enemies();pl.hp=pl.max_hp;global.lv_e=level_enemy_create(pl.x+150,pl.y+10,kinds[k]);global.lv_e.max_hp=99999;global.lv_e.hp=99999;global.lv_d0=150;global.lv_hp0=pl.hp;global.lv_coins0=0;global.lv_kills0=-1;}
        var e=global.lv_e;
        if(kf==90 && instance_exists(e)) {
            lv_check(point_distance(e.x,e.y,pl.x,pl.y)<global.lv_d0-20,kinds[k]+" chases the player ("+string(point_distance(e.x,e.y,pl.x,pl.y))+")");
            lv_check(sprite_exists(e.sprite_index) && string_pos(e.lvl_cfg.prefix,sprite_get_name(e.sprite_index))==1,kinds[k]+" uses its own sprite set ("+sprite_get_name(e.sprite_index)+")");
        }
        if(kf==200) {
            lv_check(pl.hp<global.lv_hp0,kinds[k]+" lands a telegraphed hit ("+string(global.lv_hp0-pl.hp)+")");
            if(instance_exists(e)) {
                e.max_hp=e.lvl_cfg.hp;e.hp=e.max_hp;var before=e.hp;apply_attack_damage(e,5,pl,0);lv_check(e.hp<before,kinds[k]+" takes damage");
                global.lv_coins0=instance_number(ObjectCoin);global.lv_xp0=global.coin_xp_earned;global.lv_lvl0=global.current_level;global.lv_kills0=global.run_kills;e.hp=0;
            }
        }
        if(kf==203) {
            lv_check(!instance_exists(e),kinds[k]+" dies");
            lv_check(global.run_kills==global.lv_kills0+1 && (instance_number(ObjectCoin)>global.lv_coins0 || global.coin_xp_earned>global.lv_xp0 || global.current_level>global.lv_lvl0),kinds[k]+" counts as kill and drops XP");
            with(ObjectCoin)instance_destroy();
            lv_check(instance_number(ObjectSkeletonRemains)>0,kinds[k]+" plays a death animation");
            if(kinds[k]=="swamp_mushroom")lv_check(array_length(global.level_puffs)>0,"fungus creature releases a visible spore puff");
            if(k==1)lv_capture("enemy-"+kinds[k]);
            global.lv_kind_i++;global.lv_kf=0;
        }
        if(kf>30 && kf<200)pl.hp=max(pl.hp,1);
        return;
    }
    if(global.lv_stage==5) { // environment hazards
        if(f==0){lv_clear_enemies();pl.hp=pl.max_hp;var h=lv_find_hazard(lv.id=="swamp" ? "toxic" : "ember");global.lv_h=h;if(is_struct(h))lv_place(h.x,h.y+6);global.lv_hp0=pl.hp;}
        if(f==20)lv_capture("hazard-"+lv.id);
        if(lv.id=="swamp" && f==90)lv_check(pl.hp<global.lv_hp0 && global.level_player_hazard=="toxic","toxic pool damages a standing player");
        if(lv.id!="swamp" && f==420)lv_check(pl.hp<global.lv_hp0,"ember vent erupts after its warning");
        if(f==(lv.id=="swamp" ? 100 : 430)) {
            var slow=lv_find_hazard(lv.id=="swamp" ? "mud" : "ice");
            lv_check(is_struct(slow),"slowing ground exists");
            if(is_struct(slow)){lv_place(slow.x,slow.y+6);}
        }
        if(f==(lv.id=="swamp" ? 104 : 434)) {global.lv_x0=pl.x;lv_check(global.level_speed_factor<1,"slowing ground reduces ground speed ("+string(global.level_speed_factor)+")");}
        if(f>(lv.id=="swamp" ? 104 : 434) && f<(lv.id=="swamp" ? 124 : 454))global.lv_hold_key=ord("D");
        if(f==(lv.id=="swamp" ? 125 : 455)) {
            lv_metric("slow_move_px",pl.x-global.lv_x0);
            var cyc=lv_find_hazard(lv.id=="swamp" ? "spores" : "fissure");lv_check(is_struct(cyc),"cyclic hazard exists");
            global.lv_cyc=cyc;global.lv_seen_warn=false;global.lv_seen_active=false;pl.hp=pl.max_hp;
            if(is_struct(cyc))lv_place(cyc.line ? (cyc.x+cyc.x2)/2 : cyc.x,(cyc.line ? (cyc.y+cyc.y2)/2 : cyc.y)+6);
            global.lv_hp0=pl.hp;
        }
        if(f>(lv.id=="swamp" ? 125 : 455) && is_struct(global.lv_cyc)) {
            if(global.lv_cyc.state=="warn" && !global.lv_seen_active)global.lv_seen_warn=true;
            if(global.lv_cyc.state=="active" && global.lv_seen_warn)global.lv_seen_active=true;
            if(global.lv_cyc.state=="warn" && global.lv_seen_warn && !global.lv_seen_active && global.lv_capture_name=="" && random(1)<.05)lv_capture("telegraph-"+lv.id);
        }
        if(f==(lv.id=="swamp" ? 560 : 890)) {
            lv_check(global.lv_seen_warn && global.lv_seen_active,"cyclic hazard shows a warning before it becomes active");
            lv_check(pl.hp<global.lv_hp0,"cyclic hazard damages inside its announced shape");
            global.lv_stage=6;global.lv_frame=0;
        }
        return;
    }
    if(global.lv_stage==6) { // XP, level-up, pause
        if(f==0){lv_clear_enemies();lv_place(2112,1952);pl.hp=pl.max_hp;global.lv_skills0=lv_skill_points();global.lv_lv0=global.current_level;global.next_levelup_time=0;global.coins=global.coins_needed-1;instance_create_layer(pl.x,pl.y,"Instances",ObjectCoin);global.lv_coins0=global.coins;}
        if(f==25)lv_check(global.levelup_active && global.current_level>global.lv_lv0,"collected XP opens a level-up choice");
        if(f==26)lv_check(lv_resolve_choice() && lv_skill_points()==global.lv_skills0+1 && !global.game_paused,"level-up choice adds exactly one skill level and resumes");
        if(f==30)global.lv_press_key=vk_escape;
        if(f==32)lv_check(global.game_paused && global.normal_pause_active,"escape pauses the round");
        if(f==34)global.lv_press_key=vk_escape;
        if(f==36){lv_check(!global.game_paused,"escape resumes the round");global.lv_stage=7;global.lv_frame=0;}
        return;
    }
    if(global.lv_stage==7) { // minute 5 / 10 / 15 states with real boss spawns and unlocks
        if(f==0){lv_clear_enemies();global.boss_spawned[0]=true;global.boss_spawned[1]=true;global.round_seconds=300;ObjectSpawner.population_timer=0;}
        if(f==20) {
            var b=global.active_boss;lv_check(instance_exists(b) && b.boss_data.main,"minute 5 spawns a main boss ("+(instance_exists(b) ? b.boss_id : "none")+")");
            if(instance_exists(b)){lv_check(b.v2_unlocked==3,"minute 5 unlocks abilities 1-3");lv_metric("boss5",b.boss_id);}
            lv_capture("boss5-"+lv.id);
        }
        if(f==24 && instance_exists(global.active_boss))global.active_boss.hp=0;
        if(f==130){lv_check(!instance_exists(global.active_boss),"defeated boss is removed");lv_clear_enemies();with(ObjectSkeletonRemains)instance_destroy();global.boss_spawned[2]=true;global.round_seconds=600;}
        if(f==150){var b=global.active_boss;lv_check(instance_exists(b) && b.v2_unlocked==6,"minute 10 unlocks abilities 1-6");if(instance_exists(b)){lv_metric("boss10",b.boss_id);b.hp=0;}}
        if(f==260){lv_clear_enemies();global.boss_spawned[3]=true;global.round_seconds=900;}
        if(f==280){var b=global.active_boss;lv_check(instance_exists(b) && b.v2_unlocked==9,"minute 15 unlocks abilities 1-9");if(instance_exists(b)){lv_metric("boss15",b.boss_id);}}
        if(f>=280 && f<520)pl.hp=pl.max_hp;
        if(f==300)lv_capture("boss15-"+lv.id);
        if(f==320){if(instance_exists(global.active_boss))global.active_boss.hp=0;}
        if(f==430){lv_clear_enemies();global.round_seconds=600;ObjectSpawner.population_timer=0;global.lv_dt_sum=0;global.lv_dt_n=0;global.lv_dt_max=0;for(var i=0;i<8;i++)global.boss_spawned[i]=true;}
        if(f>430 && f<760){global.lv_dt_sum+=dt;global.lv_dt_n++;global.lv_dt_max=max(global.lv_dt_max,dt);pl.hp=pl.max_hp;}
        if(f==700)lv_capture("crowd10-"+lv.id);
        if(f==760) {
            var n=instance_number(ObjectMonster);lv_metric("crowd_minute10",n);lv_metric("frame_ms_avg",global.lv_dt_sum/max(1,global.lv_dt_n)*1000);lv_metric("frame_ms_max",global.lv_dt_max*1000);
            lv_check(n>=40,"minute-10 population builds a large crowd ("+string(n)+")");
            global.lv_stage=8;global.lv_frame=0;
        }
        return;
    }
    if(global.lv_stage==8) { // death -> restart -> clean state
        if(f==0){player_receive_damage(pl,99999,"all");}
        if(f==3)lv_check(global.game_over,"lethal damage ends the run");
        if(f==5){global.lv_props=instance_number(ObjectLevelProp);round_menu_activate(0);}
        if(f==8) {
            lv_check(!global.game_over && global.round_seconds<1 && global.coins==0 && global.current_level==1 && instance_number(ObjectBossMonster)==0 && array_length(global.active_spells)+array_length(global.passive_spells)==0,"restart begins a clean run");
            lv_check(instance_number(ObjectLevelWorld)==(gen ? 1 : 0) && instance_number(ObjectLevelProp)==(gen ? global.lv_props : 0),"restart rebuilds the same world without duplicates");
        }
        if(f==11 && gen)global.lv_amb=ObjectLevelWorld.ambient_handle;
        if(f==12){global.lv_stage=99;round_end_to_title();}
        return;
    }
}
function lv_show_error(_msg,_abort=false) {show_debug_message("LEVEL_EXCEPTION show_error "+string(_msg));throw string(_msg);}
function lv_skill_points() {
    var n=0;
    for(var i=0;i<array_length(global.active_spells);i++)n+=global.active_spells[i].level;
    for(var i=0;i<array_length(global.passive_spells);i++)n+=global.passive_spells[i].level;
    return n+weapon_upgrade_level();   // weapon upgrade cards (25.11.2026) are build levels too
}
function lv_menu_capture_begin() {
    if(!variable_global_exists("lv_menu_shot") || global.lv_menu_shot=="")return;
    global.lv_menu_surface=surface_create(display_get_gui_width(),display_get_gui_height());
    surface_set_target(global.lv_menu_surface);draw_clear_alpha(c_black,1);
}
function lv_menu_capture_end() {
    if(!variable_global_exists("lv_menu_shot") || global.lv_menu_shot=="" || !surface_exists(global.lv_menu_surface))return;
    surface_reset_target();surface_save(global.lv_menu_surface,"lvcapture-"+global.lv_menu_shot+".png");
    draw_surface(global.lv_menu_surface,0,0);surface_free(global.lv_menu_surface);
    show_debug_message("LEVEL_CAPTURE "+global.lv_menu_shot);global.lv_menu_shot="";
}
