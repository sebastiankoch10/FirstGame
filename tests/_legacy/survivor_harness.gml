function gp_check(_ok,_message) {
    global.sv_checks++;if(!_ok) {global.sv_failed=true;show_debug_message("SURVIVOR FAIL "+_message);}else show_debug_message("SURVIVOR PASS "+_message);
}
function gp_key_down(_key) {
    if(global.sv_live && !global.game_paused) {
        var keys=[ord("D"),ord("S"),ord("A"),ord("W")];return _key==keys[(global.sv_live_frame div 90) mod 4];
    }
    return false;
}
function gp_key_pressed(_key) {return _key==global.sv_key;}
function gp_mouse_down(_button) {return false;}
function gp_mouse_pressed(_button) {return false;}
function gp_mouse_x() {return 2300;}
function gp_mouse_y() {return 2048;}
function gp_gui_x(_device) {return global.sv_mouse_x;}
function gp_gui_y(_device) {return global.sv_mouse_y;}
function sv_clear() {
    with(ObjectMonster) instance_destroy();with(ObjectBossMonster) instance_destroy();with(ObjectCoin) instance_destroy();
    with(ObjectLightningball) instance_destroy();with(ObjectFireball) instance_destroy();with(ObjectIceball) instance_destroy();with(ObjectSwordHitbox) instance_destroy();
}
function sv_center() {
    ObjectPlayer.x=2048;ObjectPlayer.y=2048;ObjectPlayer.motion_state=0;ObjectPlayer.dodge_timer=0;
    camera_set_view_pos(ObjectPlayer.camera,1648,1748);
}
function gp_capture(_surface,_name) {
    var buffer=buffer_create(800*600*4,buffer_fixed,1);buffer_get_surface(buffer,_surface,0);
    var packed=buffer_compress(buffer,0,800*600*4);
    show_debug_message("GAMEPLAY_IMAGE "+_name+" "+buffer_base64_encode(packed,0,buffer_get_size(packed)));
    buffer_delete(packed);buffer_delete(buffer);
}
function sv_capture(_name,_modal) {
    var surface=surface_create(800,600);surface_set_target(surface);draw_clear(make_color_rgb(27,43,37));display_set_gui_size(800,600);
    var original_world=matrix_get(matrix_world),r=combat_view_rect();
    matrix_set(matrix_world,matrix_build(-r.left,-r.top,0,0,0,0,1,1,1));
    with(ObjectPlayer) event_perform(ev_draw,0);with(ObjectMonster) event_perform(ev_draw,0);with(ObjectBossMonster) event_perform(ev_draw,0);
    chain_visual_draw();matrix_set(matrix_world,original_world);if(_modal) ui_modal_draw();else hud_draw();surface_reset_target();gp_capture(surface,_name);surface_free(surface);
}
function sv_menu_tick() {
    if(!variable_global_exists("sv_case")) {
        global.sv_case=0;global.sv_phase=0;global.sv_checks=0;global.sv_failed=false;global.sv_live=false;global.sv_live_frame=0;
        global.sv_key=-1;global.sv_mouse_x=-100;global.sv_mouse_y=-100;global.sv_native_modal_frames=0;global.sv_metrics={};
    }
    global.sv_key=-1;
    if(global.sv_case>=9 && global.sv_preview) {
        menu_mode="main";menu_activate(0);menu_activate(2);menu_activate(0);global.sv_phase=6;return;
    }
    if(global.sv_case>=9) {
        show_debug_message("GAMEPLAY_RESULT "+json_stringify({passed:!global.sv_failed,checks:global.sv_checks,classes:["Sword","Mage","Ranger"],combinations:9,metrics:global.sv_metrics,native_modal_frames:global.sv_native_modal_frames}));game_end();return;
    }
    menu_mode="main";menu_activate(0);menu_activate(global.sv_case div 3);menu_activate(global.sv_case mod 3);global.sv_phase=0;
}
function sv_fixtures() {
    sv_clear();sv_center();var pl=ObjectPlayer,spawner=ObjectSpawner;
    gp_check(progression_cost(1)==1 && progression_cost(2)==2 && progression_cost(3)==3,"central first costs 1/2/3");
    var last=0;for(var lv=1;lv<60;lv++) {gp_check(progression_cost(lv)>last,"monotonic XP "+string(lv));last=progression_cost(lv);}
    var predictions=[];var rates=[60,120,240];
    for(var i=0;i<3;i++) {
        var levels=[];var horizons=[1,30];
        for(var h=0;h<2;h++) {var pool=rates[i]*horizons[h],level=1;while(pool>=progression_cost(level)) {pool-=progression_cost(level);level++;}array_push(levels,level);}
        gp_check(levels[0]<20,"first minute does not grant thirty levels at "+string(rates[i])+" kills/min");array_push(predictions,{kills_per_minute:rates[i],minute_one:levels[0],minute_thirty:levels[1]});
    }
    global.sv_metrics.progression=predictions;
    spawner.population_timer=0;population_step(spawner,1/60);
    var bounds=true,r=combat_view_rect();
    for(var i=0;i<instance_number(ObjectMonster);i++) {var e=instance_find(ObjectMonster,i);if(point_in_rectangle(e.x,e.y,r.left,r.top,r.right,r.bottom) || point_distance(e.x,e.y,pl.x,pl.y)<190) bounds=false;}
    gp_check(bounds && instance_number(ObjectMonster)>1,"groups spawn safely outside actual view");
    for(var frame=0;frame<150;frame++) {population_step(spawner,1/60);with(ObjectMonster) event_perform(ev_step,0);}
    var counts=population_counts();gp_check(counts.nearby>=18 && counts.visible>=10,"early population is present and visible");
    global.sv_metrics.early=counts;
    var before=counts.alive;
    repeat(6) {var e=instance_find(ObjectMonster,0);e.hp=0;with(e) event_perform(ev_step,0);}
    spawner.population_timer=0;population_step(spawner,1/60);
    gp_check(population_counts().alive>=population_profile(global.round_seconds).minimum && population_counts().alive>before-6,"deaths are refilled promptly instead of fixed single spawns");
    sv_clear();
    var inside=instance_create_layer(2120,2048,"Instances",ObjectMonster);inside.hp=1000;
    var outside=instance_create_layer(r.right+15,2048,"Instances",ObjectMonster);outside.hp=1000;
    gp_check(combat_nearest(pl,1000)==inside,"auto targeting ignores offscreen enemy");
    with(inside) instance_destroy();gp_check(!instance_exists(combat_nearest(pl,1000)),"offscreen-only scene gives no automatic target");
    sv_clear();
    global.active_spells=[];global.passive_spells=[];global.hotbar=array_create(6,undefined);
    var ids=[101,102,103,104,105,106,201,202,203,204,205,206];
    for(var i=0;i<12;i++) {learn_spell(ids[i]);repeat(i mod 9) learn_spell(ids[i]);}
    apply_passives(pl);
    for(var i=0;i<6;i++) gp_check(global.active_spells[i].level==i+1,"orb level equals actual upgrade count");
    var nodes=[];
    for(var i=0;i<5;i++) {var e=instance_create_layer(2100+i*60,2048,"Instances",ObjectMonster);e.hp=1000;array_push(nodes,e);}
    var far=instance_create_layer(2300,2280,"Instances",ObjectMonster);far.hp=1000;
    var hits=cast_chain_lightning(nodes[0],17,5,140,pl);
    gp_check(hits==5 && array_length(global.chain_segments)==5,"chain creates five distinct visible hit links");
    var exact=true;for(var i=0;i<5;i++) if(nodes[i].hp!=983 || nodes[i].shock_time<=0) exact=false;
    gp_check(exact && far.hp==1000,"each chained target loses exact HP once; out-of-hop target is untouched");
    nodes[0].burn_time=60;nodes[0].slow_time=60;nodes[0].shock_time=24;
    gp_check(element_tint(nodes[0])!=c_white,"real element status tints body");
    nodes[0].burn_time=0;nodes[0].slow_time=0;nodes[0].shock_time=0;
    gp_check(element_tint(nodes[0])==c_white,"expired element status leaves no tint/glow");
    sv_capture("chain",false);
    global.game_paused=true;global.normal_pause_active=true;global.settings_active=false;global.game_over=false;
    sv_capture("pause",true);
    var ui=pause_geometry();global.sv_mouse_x=ui.ability_x+50;global.sv_mouse_y=ui.ability_y+12;sv_capture("tooltip",true);global.sv_mouse_x=-100;global.sv_mouse_y=-100;
    gp_check(global.minimap_visible && pl.x/room_width>=0 && pl.x/room_width<=1,"minimap enabled with valid world mapping");
    global.game_paused=false;global.normal_pause_active=false;
    var boss=boss_spawn("storm_warden");boss.hp=boss.max_hp*0.6;
    sv_capture("boss",false);boss_cleanup(boss);with(boss) instance_destroy();
    // Damage bar is driven by accepted damage and uses a three-second timer.
    pl.motion_state=0;pl.dodge_timer=0;pl.invulnerable_timer=0;pl.hp=pl.max_hp;
    player_receive_damage(pl,10);gp_check(pl.health_visible_time==3 && pl.hud_hit_flash>0,"hit displays player bar and red flash");
    hud_step(2.9);gp_check(pl.health_visible_time>0,"player health bar lasts nearly three seconds");hud_step(0.11);gp_check(pl.health_visible_time==0,"player health bar hides after three seconds");
    // New timing survives direct 30/60/120 Hz updates, with no auto-slide.
    var fps_values=[30,60,120];
    for(var fi=0;fi<3;fi++) for(var attempt=0;attempt<3;attempt++) {
        var hz=fps_values[fi],did_slide=false;pl.motion_state=0;pl.dodge_timer=0;pl.mobility_cooldown=0;pl.x=2048;pl.y=2048;
        for(var frame=0;frame<hz*2;frame++) {
            var second=attempt==1 ? round(hz*0.10) : round(hz*0.29);
            movement_step(pl,1/hz,true,0,pl.moveSpeed,frame==0 || (attempt>0 && frame==second),false);
            if(pl.motion_state==4) did_slide=true;
        }
        gp_check(did_slide==(attempt==2),"jump timing normal/early/apex at "+string(hz)+" Hz attempt "+string(attempt));
    }
    pl.motion_state=0;pl.dodge_timer=0;
    // Focus updates mute only the effective master, never restart music or overwrite bus volumes.
    var master=global.master_volume,bg=global.audio_background;global.master_volume=0.7;global.audio_background=false;
    fg_music_set("level");var music_handle=global.fg_audio.current,starts=global.fg_audio.music_starts;
    fg_audio_apply_focus(false);gp_check(global.fg_audio.effective_master==0,"background audio disabled mutes on focus loss");
    fg_audio_apply_focus(true);gp_check(abs(global.fg_audio.effective_master-0.7)<0.001 && global.fg_audio.current==music_handle && global.fg_audio.music_starts==starts,"focus return restores gain without duplicate music");
    global.audio_background=true;fg_audio_apply_focus(false);gp_check(abs(global.fg_audio.effective_master-0.7)<0.001,"background audio opt-in keeps prior master gain");
    global.audio_background=bg;global.master_volume=master;fg_audio_apply_focus(true);
    // Measured CPU update cost at a bounded larger crowd; not a claim of full-frame GPU FPS.
    sv_clear();sv_center();global.round_seconds=1500;
    for(var i=0;i<25;i++) {spawner.population_timer=0;population_step(spawner,1/60);}
    var started=get_timer();repeat(30) with(ObjectMonster) event_perform(ev_step,0);
    global.sv_metrics.crowd={counts:population_counts(),monster_update_ms:(get_timer()-started)/1000/30};
    gp_check(instance_number(ObjectMonster)<=180 && instance_number(ObjectMonster)>=100,"later population fills beyond one hundred within technical ceiling");
    reset_round();sv_center();spawner.population_timer=0;spawner.runtime_cap=180;
}
function sv_controller_tick() {
    global.sv_key=-1;
    if(global.sv_phase==6) {
        var ids=[101,102,103,104,105,106,201,202,203,204,205,206];
        for(var i=0;i<12;i++) {learn_spell(ids[i]);repeat(i mod 9) learn_spell(ids[i]);}
        apply_passives(ObjectPlayer);global.game_paused=true;global.normal_pause_active=true;
        global.sv_hold=0;global.sv_phase=7;return;
    }
    if(global.sv_phase==7) {
        global.sv_hold+=delta_time/1000000;
        if(global.sv_hold>45) {
            show_debug_message("GAMEPLAY_RESULT "+json_stringify({passed:!global.sv_failed,checks:global.sv_checks,classes:["Sword","Mage","Ranger"],combinations:9,metrics:global.sv_metrics,native_modal_frames:global.sv_native_modal_frames}));game_end();
        }
        return;
    }
    if(global.sv_phase==0) {
        gp_check(global.minimap_visible && ObjectPlayer.x>=0 && ObjectPlayer.x<=room_width && ObjectPlayer.y>=0 && ObjectPlayer.y<=room_height,"minimap uses valid coordinates for "+room_get_name(room));
        gp_check(global.current_level==1 && global.coins_needed==1 && array_length(global.active_spells)==0,"real start uses one-coin first level-up and empty spells");
        global.sv_clock=global.round_seconds;global.sv_key=vk_escape;global.sv_phase=1;global.sv_wait=0;return;
    }
    if(global.sv_phase==1) {
        gp_check(global.game_paused && global.normal_pause_active && instance_exists(ObjectPlayer),"pause keeps camera owner and GUI active");
        global.sv_wait++;if(global.sv_wait<4) return;
        gp_check(global.round_seconds==global.sv_clock,"pause stops actual boss clock");
        if(global.sv_case==0) sv_capture("emptypause",true);
        global.sv_key=vk_escape;global.sv_phase=2;return;
    }
    if(global.sv_phase==2) {
        gp_check(!global.game_paused,"resume returns to native simulation");
        var coin=instance_create_layer(ObjectPlayer.x,ObjectPlayer.y,"Instances",ObjectCoin);
        global.sv_phase=3;global.sv_wait=0;return;
    }
    if(global.sv_phase==3) {
        if(!global.levelup_active) {global.sv_wait++;if(global.sv_wait<10)return;gp_check(false,"one coin must trigger level-up");}
        gp_check(global.current_level==2 && global.coins_needed==2 && global.game_paused,"real coin collision triggers first level-up selection");
        if(global.sv_case==0) sv_capture("levelup",true);
        global.sv_key=vk_space;global.sv_phase=4;return;
    }
    if(global.sv_phase==4) {
        gp_check(!global.game_paused,"ability choice resumes gameplay");
        if(global.sv_case==0) sv_fixtures();
        if(global.sv_case==6) {reset_round();global.sv_live=true;global.sv_live_frame=0;global.sv_peak_alive=0;global.sv_peak_visible=0;global.sv_min_fps=1000;global.sv_frame_ms=0;global.sv_measured_frames=0;global.sv_phase=5;return;}
        global.sv_case++;round_end_to_title();return;
    }
    if(global.sv_phase==5) {
        global.sv_live_frame++;
        if(global.levelup_active) global.sv_key=vk_space;
        if(global.game_over) {gp_check(false,"native early ranger run survives eight seconds of kiting");global.sv_live_frame=480;}
        var c=population_counts();global.sv_peak_alive=max(global.sv_peak_alive,c.alive);global.sv_peak_visible=max(global.sv_peak_visible,c.visible);
        if(global.sv_live_frame>120) {global.sv_min_fps=min(global.sv_min_fps,fps_real);global.sv_frame_ms+=delta_time/1000;global.sv_measured_frames++;}
        if(global.sv_live_frame<480)return;
        gp_check(global.sv_peak_visible>=10,"native running ranger sees many enemies at once");
        global.sv_metrics.native_ranger={frames:global.sv_live_frame,peak_alive:global.sv_peak_alive,peak_visible:global.sv_peak_visible,min_reported_fps:global.sv_min_fps,mean_delivered_frame_ms:global.sv_frame_ms/max(1,global.sv_measured_frames)};
        sv_capture("native",false);global.sv_live=false;global.sv_case++;round_end_to_title();
    }
}
