function gp_check(_ok,_message) {
    global.sv_checks++;if(!_ok) {global.sv_failed=true;show_debug_message("SURVIVOR FAIL "+_message);}else show_debug_message("SURVIVOR PASS "+_message);
}
function gp_key_down(_key) {
    if(global.sv_live && !global.game_paused) {
        var keys=[ord("D"),ord("S"),ord("A"),ord("W")];return _key==keys[(global.sv_live_frame div 90) mod 4];
    }
    return false;
}
function gp_key_pressed(_key) {
 if(global.sv_live && !global.game_paused) {
  if(_key==vk_space && global.sv_live_frame mod 60==1)return true;
  if(_key==vk_control && global.sv_live_frame mod 100==40)return true;
 }
 return _key==global.sv_key;
}
function gp_mouse_down(_button) {return false;}
function gp_mouse_pressed(_button) {return false;}
function gp_mouse_x() {return 2300;}
function gp_mouse_y() {return 2048;}
function gp_gui_x(_device) {return global.sv_mouse_x;}
function gp_gui_y(_device) {return global.sv_mouse_y;}
function sv_clear() {
    with(ObjectMonster) instance_destroy();with(ObjectBossMonster) instance_destroy();with(ObjectCoin) instance_destroy();with(ObjectMagnetOrb) instance_destroy();
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
    if(global.sv_case>=9 && !variable_global_exists("ap_render_done")) {
 menu_mode="main";menu_activate(0);menu_activate(0);menu_activate(0);global.sv_phase=8;global.ap_render_frame=0;return;
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
    if(global.sv_phase==8) {ap_render_step();return;}
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
        ObjectPlayer.hp=30;
        var coin=instance_create_layer(ObjectPlayer.x,ObjectPlayer.y,"Instances",ObjectCoin);
        global.sv_phase=3;global.sv_wait=0;return;
    }
    if(global.sv_phase==3) {
        if(!global.levelup_active) {global.sv_wait++;if(global.sv_wait<10)return;gp_check(false,"one coin must trigger level-up");}
        gp_check(ObjectPlayer.hp==30,"level-up does not heal wounded player");
        gp_check(global.current_level==2 && global.coins_needed==2 && global.game_paused,"real coin collision triggers first level-up selection");
        if(global.sv_case==0) sv_capture("levelup",true);
        global.sv_key=vk_space;global.sv_phase=4;return;
    }
    if(global.sv_phase==4) {
        gp_check(!global.game_paused,"ability choice resumes gameplay");
        if(global.sv_case==0) {sv_fixtures();ap_fixtures();dr_fixtures();}
        if(global.sv_case==6) {reset_round();global.sv_live=true;global.sv_live_frame=0;global.sv_peak_alive=0;global.sv_peak_visible=0;global.sv_min_fps=1000;global.sv_frame_ms=0;global.sv_measured_frames=0;global.sv_phase=5;return;}
        global.sv_case++;round_end_to_title();return;
    }
    if(global.sv_phase==5) {
        global.sv_live_frame++;
        if(global.levelup_active) global.sv_key=vk_space;
        if(global.game_over) {gp_check(false,"native early ranger run survives eight seconds with timed jumping and dodge");global.sv_live_frame=480;}
        var c=population_counts();global.sv_peak_alive=max(global.sv_peak_alive,c.alive);global.sv_peak_visible=max(global.sv_peak_visible,c.visible);
        if(global.sv_live_frame>120) {global.sv_min_fps=min(global.sv_min_fps,fps_real);global.sv_frame_ms+=delta_time/1000;global.sv_measured_frames++;}
        if(global.sv_live_frame<480)return;
        gp_check(global.sv_peak_visible>=10,"native running ranger sees many enemies at once");
        global.sv_metrics.native_ranger={frames:global.sv_live_frame,peak_alive:global.sv_peak_alive,peak_visible:global.sv_peak_visible,min_reported_fps:global.sv_min_fps,mean_delivered_frame_ms:global.sv_frame_ms/max(1,global.sv_measured_frames)};
        sv_capture("native",false);global.sv_live=false;global.sv_case++;round_end_to_title();
    }
}

function ap_fixtures() {
    sv_clear();sv_center();var pl=ObjectPlayer;
    global.game_paused=false;global.game_over=false;pl.hp=1000;pl.max_hp=1000;pl.damage_reduction=0;pl.invulnerable_timer=30;
    var attackers=[];repeat(30) {var e=instance_create_layer(pl.x,pl.y,"Instances",ObjectMonster);e.damage=2;array_push(attackers,e);}
    var hits=0;for(var i=0;i<30;i++) if(player_contact(pl,attackers[i])) hits++;
    gp_check(hits==30 && pl.hp==940,"thirty distinct attackers deal all thirty simultaneous hits despite legacy timer");
    hits=0;for(var i=0;i<30;i++) if(player_contact(pl,attackers[i])) hits++;
    gp_check(hits==0 && pl.hp==940,"same attackers cannot hit again each frame");
    global.round_seconds+=loot_config().contact_interval+0.01;
    gp_check(player_contact(pl,attackers[0]) && pl.hp==938,"individual contact clock permits next attack");
    pl.motion_state=player_motion_state.rising;gp_check(!player_contact(pl,attackers[1]),"jump contact protection remains");
    pl.motion_state=player_motion_state.sliding;gp_check(!player_contact(pl,attackers[1]),"slide contact protection remains");pl.motion_state=0;
    pl.dodge_timer=0.1;gp_check(!player_contact(pl,attackers[1]),"dodge contact protection remains");pl.dodge_timer=0;
    pl.hp=1000;pl.motion_state=player_motion_state.rising;
    gp_check(player_receive_damage(pl,3,"high") && pl.hp==997,"airborne player can be hit by high attacks");
    pl.motion_state=player_motion_state.sliding;gp_check(!player_receive_damage(pl,3,"high"),"slide avoids high projectiles");
    gp_check(player_receive_damage(pl,3,"all") && pl.hp==994,"vertical lightning can hit through slide");pl.motion_state=0;
    sv_clear();var boss=boss_spawn("storm_warden");
    gp_check(boss.body_radius==108 && boss.bbox_right-boss.bbox_left>=210 && boss.bbox_bottom-boss.bbox_top>=230,"giant boss has actual enlarged physical mask");
    var old_hp=boss.hp;
    var fire=instance_create_layer(boss.bbox_left-6,boss.y-120,"Instances",ObjectFireball);fire.owner=pl;fire.damage=17;fire.direction=0;fire.projectile_speed=11;
    with(fire) event_perform(ev_step,0);
    gp_check(boss.hp==old_hp-17 && boss.burn_time>0,"fireball really damages enlarged boss at mask edge, not only near origin");
    pl.x=boss.x;pl.y=boss.bbox_top+12;boss.contact_next=0;
    gp_check(player_contact(pl,boss),"upper boss body collision deals actual contact damage");sv_center();
    pl.boss_arrow_angle=0;repeat(50) boss_direction_update(pl,boss,0.18);
    gp_check(abs(angle_difference(pl.boss_arrow_angle,point_direction(pl.x,pl.y,boss.x,boss.y)))<0.1,"boss arrow converges to actual boss direction");
    boss.x=100;boss.y=300;var ox=boss.x,oy=boss.y;
    repeat(26) boss_navigation_step(boss,0.1);
    gp_check(boss.teleport_warning>0 && boss.x==ox && boss.y==oy,"offscreen distant boss warns before reposition");
    boss_navigation_step(boss,0.9);
    gp_check(point_distance(boss.x,boss.y,pl.x,pl.y)>=boss.body_radius+200 && boss.teleport_cooldown>11,"boss arrives safely away from player and starts cooldown");
    boss.x=100;boss.y=300;repeat(30) boss_navigation_step(boss,0.1);
    gp_check(boss.teleport_warning<=0,"boss cooldown prevents repeated teleports");
    boss.hp=0;var before=instance_number(ObjectMagnetOrb);boss_complete(boss);
    gp_check(instance_number(ObjectMagnetOrb)==before+1,"main boss guarantees one magnet orb");
    with(ObjectChest) instance_destroy();var mini=boss_spawn("mini_sentinel");mini.hp=0;before=instance_number(ObjectMagnetOrb);boss_complete(mini);
    gp_check(instance_number(ObjectMagnetOrb)==before+1,"miniboss guarantees one magnet orb");
    sv_clear();var budget=global.coins;
    for(var i=0;i<500;i++) instance_create_layer(32+(i mod 25)*160,32+(i div 25)*190,"Instances",ObjectCoin);
    var orb=magnet_drop(pl.x,pl.y,true);magnet_collect(orb);
    var all_marked=true;with(ObjectCoin) if(!magnetized) all_marked=false;gp_check(all_marked && instance_number(ObjectCoin)==500,"magnet marks all five hundred coins across room");
    var timestamp=get_timer();repeat(440) with(ObjectCoin) event_perform(ev_step,0);
    gp_check(instance_number(ObjectCoin)==0 && global.coins==budget+500,"five hundred attracted coins arrive once and award exact XP");
    global.sv_metrics.magnet={coins:500,simulation_ms:(get_timer()-timestamp)/1000};
    gp_check(sprite_get_number(spr_fg_knightv2_attack_right)==2 && sprite_get_number(spr_fg_knightv2_death_down)==2,"new knight attack and death frames imported");
    var bounds=true;var dirs=["right","down","up"];
    for(var i=0;i<3;i++) {var asset=player_visual_asset("knightv2","idle",dirs[i]);if(asset.size!=1.10 || sprite_get_height(asset.sprite)!=64) bounds=false;}
    gp_check(bounds,"all knight directions use same canvas and uniform render scale");
    reset_round();sv_center();with(ObjectChest) instance_destroy();
}
function ap_render_step() {dr_render_step();}
function ap_render_capture() {dr_render_capture();}

function dr_fixtures() {
    sv_clear();sv_center();reset_round();sv_center();var pl=ObjectPlayer;
    pl.hp=10000;pl.max_hp=10000;pl.damage_reduction=0;
    global.boss_spawned[0]=true;global.boss_spawned[1]=true;global.round_seconds=300;boss_schedule_step();
    var b=global.active_boss;
    gp_check(instance_exists(b) && b.boss_id=="storm_warden" && b.dragon_enabled && b.visual_height==300,"first main boss schedule spawns dedicated large fire dragon");
    var a0=dragon_animation(b);dragon_step(b,0.3);var a1=dragon_animation(b);
    gp_check(a0.frame!=a1.frame && b.dragon_clock>0,"breathing animation advances without movement");
    dragon_state(b,"recovery",2);b.chase_vx=0;b.chase_vy=0;var old_x=b.x,old_y=b.y;pl.x-=120;boss_step(b,0.1);
    gp_check(point_distance(old_x,old_y,b.x,b.y)>0 && point_distance(old_x,old_y,b.x,b.y)<7,"dragon follows with bounded smooth weighted movement");sv_center();
    dragon_attack_begin(b,"beam");var g=dragon_attack_geometry(b);pl.x=(g.x+g.ex)*0.5;pl.y=(g.y+g.ey)*0.5+10;var hp0=pl.hp;
    boss_step(b,1.0);gp_check(pl.hp==hp0 && b.boss_state=="windup","beam warning cannot damage player");
    boss_step(b,0.26);gp_check(b.boss_state=="active" && pl.hp==hp0,"horizontal beam activates only after full tell");
    boss_step(b,0.02);gp_check(pl.hp==hp0-dragon_config().beam_damage,"real beam geometry deals correct high damage");
    boss_step(b,0.02);gp_check(pl.hp==hp0-dragon_config().beam_damage,"beam has per-attack tick gate instead of frame damage");
    gp_check(abs(g.length-420)<0.01 && abs(sin(degtorad(g.angle)))<0.001,"horizontal beam covers 420 world pixels");
    pl.y=g.y+100;boss_step(b,0.45);gp_check(pl.hp==hp0-dragon_config().beam_damage,"outside marked beam width remains safe");
    pl.x=g.x-100*sign(g.ex-g.x);pl.y=g.y+10;gp_check(!dragon_player_in_fire(b,pl),"behind dragon mouth is safe from straight beam");
    sv_center();dragon_attack_begin(b,"sweep");boss_step(b,1.26);var angle0=b.dragon_angle;boss_step(b,0.4);
    gp_check(abs(angle_difference(b.dragon_angle,angle0))>5 && abs(angle_difference(b.dragon_angle,angle0))<25,"sweeping breath rotates gradually, not instantly");
    var pose=dragon_animation(b);gp_check(pose.action=="breath_up" || pose.action=="breath_down" || pose.action=="breath","head pose matches current breath direction");
    boss_step(b,2.4);gp_check(abs(angle_difference(b.dragon_angle,angle0))>100,"sweep completes large 110 degree sector");
    sv_center();dragon_attack_begin(b,"arc");boss_step(b,1.26);boss_step(b,1.25);g=dragon_attack_geometry(b);
    pl.x=g.x+lengthdir_x(200,g.angle+10);pl.y=g.y+lengthdir_y(200,g.angle+10)+10;gp_check(dragon_player_in_fire(b,pl),"wide fire arc includes actual cone interior");
    pl.x=g.x+lengthdir_x(200,g.angle+45);pl.y=g.y+lengthdir_y(200,g.angle+45)+10;gp_check(!dragon_player_in_fire(b,pl),"arc does not hit outside current fire sector");
    sv_center();dragon_attack_begin(b,"stomp");boss_step(b,1.26);
    gp_check(b.boss_state=="stomp" && array_length(b.dragon_magma)==3,"heavy stomp creates exactly three magma warning fields");
    var z=b.dragon_magma[0];pl.x=z.x;pl.y=z.y+10;hp0=pl.hp;boss_step(b,0.5);gp_check(pl.hp==hp0,"magma warning gives reaction time without damage");
    boss_step(b,0.56);gp_check(pl.hp==hp0-dragon_config().magma_damage && b.dragon_magma[0].erupted,"magma erupts after warning and damages once");
    boss_step(b,0.1);gp_check(pl.hp==hp0-dragon_config().magma_damage,"one magma eruption never damages repeatedly each frame");
    pl.x=20;pl.y=20;dragon_magma_spawn(b);var separated=true;
    for(var i=0;i<3;i++)for(var j=i+1;j<3;j++)if(point_distance(b.dragon_magma[i].x,b.dragon_magma[i].y,b.dragon_magma[j].x,b.dragon_magma[j].y)<120)separated=false;
    gp_check(separated,"three magma zones remain separate at room corner");sv_center();
    b.dragon_magma=[];b.hp=b.max_hp*0.49;boss_step(b,0.01);
    gp_check(b.boss_phase==2 && b.boss_state=="transition" && dragon_animation(b).action=="phase","half HP triggers own phase animation and cancels hazards");
    with(ObjectChest)instance_destroy();with(ObjectMagnetOrb)instance_destroy();var coins_before=global.coins;
    b.hp=0;boss_step(b,0.01);
    gp_check(instance_exists(b) && b.dragon_dying && instance_number(ObjectChest)==1 && instance_number(ObjectMagnetOrb)==1,"exact HP death starts corpse animation and immediately drops chest plus one orb");
    gp_check(abs(b.reward_orb.x-b.reward_chest.x-42)<0.01 && b.reward_orb.y==b.reward_chest.y,"orb appears adjacent to chest at death location");
    boss_reward_once(b);boss_step(b,0.1);gp_check(instance_number(ObjectMagnetOrb)==1 && global.coins==coins_before+30,"repeated death processing never duplicates loot or XP");
    dragon_death_step(b,1.5);gp_check(!instance_exists(b),"death sequence finishes and releases encounter instance");
    with(ObjectChest)instance_destroy();with(ObjectMagnetOrb)instance_destroy();
    var mini=boss_spawn("mini_sentinel");mini.hp=0;boss_step(mini,0.01);
    gp_check(instance_number(ObjectChest)==1 && instance_number(ObjectMagnetOrb)==1,"miniboss also drops exactly one orb and one chest");
    with(ObjectChest)instance_destroy();with(ObjectMagnetOrb)instance_destroy();
    repeat(20) {var e=instance_create_layer(120,120,"Instances",ObjectMonster);e.hp=0;with(e)event_perform(ev_step,0);}
    gp_check(instance_number(ObjectMagnetOrb)==0 && !instance_exists(magnet_drop(120,120,false)),"ordinary deaths and random-drop path create no magnet orbs");
    sv_clear();var orb=magnet_drop(pl.x+34,pl.y,true);var c=instance_create_layer(3900,3900,"Instances",ObjectCoin);
    with(orb)event_perform(ev_step,0);gp_check(!instance_exists(orb) && c.magnetized,"visible edge contact really collects orb and magnetizes far coin");
    var cx=c.x,cy=c.y;with(c)event_perform(ev_step,0);
    gp_check(point_distance(cx,cy,c.x,c.y)>11 && loot_config().magnet_speed==960 && c.collect_speed==3.5 && c.collect_radius==96,"magnet and ordinary attraction speeds increased while radius remains 96");
    sv_clear();run_stats_reset();global.active_spells=[];global.passive_spells=[];global.hotbar=array_create(6,undefined);
    var e=instance_create_layer(pl.x+80,pl.y,"Instances",ObjectMonster);e.hp=10;e.max_hp=10;
    apply_attack_damage(e,40,pl,SPELL.ICEBALL);
    gp_check(run_stats_get(SPELL.ICEBALL).damage==10 && run_stats_get(SPELL.ICEBALL).hits==1,"run damage records actual HP loss instead of overkill");
    gp_check(!apply_attack_damage(e,40,pl,SPELL.ICEBALL) && run_stats_get(SPELL.ICEBALL).hits==1,"dead target cannot inflate run hits or damage");
    with(e)instance_destroy();e=instance_create_layer(pl.x+80,pl.y,"Instances",ObjectMonster);e.hp=100;e.max_hp=100;
    combat_area_hit(e.x,e.y-10,20,17,pl,60,1,0,1,SPELL.FIREBALL);
    var immediate=run_stats_get(SPELL.FIREBALL).damage;with(e)event_perform(ev_step,0);
    gp_check(abs(immediate-17)<0.001 && run_stats_get(SPELL.FIREBALL).damage>17 && run_stats_get(SPELL.FIREBALL).hits==1,"fire explosion and burn share correct attribution without per-tick hit inflation");
    pl.hp=98;pl.max_hp=100;var heal={id:SPELL.HEAL,name:"Healing Pulse",level:1,cooldown_timer:0};cast_spell(heal);
    gp_check(run_stats_get(SPELL.HEAL).healing==2 && run_stats_get(SPELL.HEAL).casts==1,"healing run stat excludes overheal and counts successful cast");
    pl.hp=100;pl.damage_reduction=0.5;player_receive_damage(pl,20);gp_check(run_stats_get(SPELL.SHIELD).blocked==10,"shield records actual prevented incoming damage");pl.damage_reduction=0;
    var text=run_stats_text(SPELL.FIREBALL);gp_check(string_pos("17",text)>0 && string_pos("Treffer: 1",text)>0,"pause stats text exposes measured current run contribution");
    run_stats_reset();gp_check(run_stats_get(SPELL.FIREBALL).damage==0 && run_stats_get(SPELL.HEAL).healing==0,"new run stats reset damage and healing");
    sv_clear();reset_round();sv_center();
}
function dr_render_step() {
    global.ap_render_frame++;var frame=global.ap_render_frame;
    if(global.chest_collected || global.levelup_active)global.sv_key=vk_space;
    if(frame==1) {
        sv_clear();sv_center();ObjectSpawner.population_timer=999;ObjectPlayer.__base_max_hp=100000;ObjectPlayer.max_hp=100000;ObjectPlayer.hp=100000;
        var ids=[101,102,103,104,105,106,201,202,203,204,205,206];for(var i=0;i<12;i++)learn_spell(ids[i]);apply_passives(ObjectPlayer);
        var b=boss_spawn("storm_warden");b.x=2290;b.y=2248;b.boss_timer=99;global.dr_boss=b;
    }
    var b=global.dr_boss;
    if(array_contains([1,25,180,450,700,920,1050,1052,1138],frame))show_debug_message("DRAGON_NATIVE "+json_stringify({frame:frame,boss:b,active:global.active_boss,exists:instance_exists(b),hp:instance_exists(b) ? b.hp : -1,state:instance_exists(b) ? b.boss_state : "gone",paused:global.game_paused,player_x:ObjectPlayer.x,player_y:ObjectPlayer.y,chests:instance_number(ObjectChest),orbs:instance_number(ObjectMagnetOrb)}));
    if(instance_exists(b)) {
        if(frame==25)dragon_attack_begin(b,"beam");
        if(frame==180)dragon_attack_begin(b,"sweep");
        if(frame==450)dragon_attack_begin(b,"arc");
        if(frame==700)dragon_attack_begin(b,"stomp");
        if(frame==920)b.hp=b.max_hp*0.49;
        if(frame==1050)b.hp=0;
    }
    if(frame==1138) {
        gp_check(instance_number(ObjectMagnetOrb)==1 && instance_number(ObjectChest)==1,"native boss death has one orb adjacent to one chest");
        var chest=instance_find(ObjectChest,0);if(instance_exists(chest)){ObjectPlayer.x=chest.x;ObjectPlayer.y=chest.y;}
        for(var i=0;i<60;i++)instance_create_layer(80+i*50,3800,"Instances",ObjectCoin);
    }
    if(frame==1139)gp_check(global.chest_collected,"native touching chest opens selection before orb collection");
    if(frame==1145) {
        gp_check(!global.game_paused,"native chest confirmation resumes before orb pickup");
        var orb=instance_find(ObjectMagnetOrb,0);if(instance_exists(orb)){ObjectPlayer.x=orb.x-34;ObjectPlayer.y=orb.y;}
    }
    if(frame==1146) {var marked=true;with(ObjectCoin)if(!magnetized)marked=false;gp_check(instance_number(ObjectMagnetOrb)==0 && marked,"native pickup after chest selection really attracts every map coin");}
    if(frame==1338)gp_check(instance_number(ObjectCoin)==0,"native magnet flight actually delivers all sixty distant coins before pause");
    if(frame==1340) {
        global.game_paused=true;global.normal_pause_active=true;global.sv_mouse_x=pause_geometry().ability_x+50;global.sv_mouse_y=pause_geometry().ability_y+12;
    }
    if(frame==1344) {sv_capture("dragonstats",true);gp_check(run_stats_get(SPELL.FIREBALL).damage>0 && run_stats_get(SPELL.FIREBALL).casts>0,"pause shows real fireball run damage and cast statistics after native fight");}
    if(frame>=1350){global.ap_render_done=true;global.sv_case=9;global.game_paused=false;round_end_to_title();}
}
function dr_render_capture() {
    if(!variable_global_exists("ap_render_frame") || global.sv_phase!=8)return;
    var frame=global.ap_render_frame,name="";
    switch(frame){case 20:name="dragonidle";break;case 70:name="dragonwarning";break;case 125:name="dragonbeam";break;case 300:name="dragonsweep";break;case 600:name="dragonarc";break;case 805:name="magmazones";break;case 850:name="magmaeruption";break;case 940:name="dragonphase";break;case 1100:name="dragondeath";break;}
    if(name=="")return;
    var s=surface_create(800,600);surface_set_target(s);draw_clear_alpha(c_black,0);draw_surface_stretched(application_surface,0,0,800,600);surface_reset_target();gp_capture(s,name);surface_free(s);
}
