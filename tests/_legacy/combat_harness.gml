function gp_check(_ok,_message) {global.sv_checks++;if(!_ok){global.sv_failed=true;show_debug_message("COMBAT FAIL "+_message);}else show_debug_message("COMBAT PASS "+_message);}
function gp_key_down(_key) {return global.cf_move && _key==ord("D");}
function gp_key_pressed(_key) {return global.cf_key==_key;}
function gp_mouse_down(_button) {return global.cf_down;}
function gp_mouse_pressed(_button) {return global.cf_press;}
function gp_mouse_x() {return 2300;}
function gp_mouse_y() {return 2048;}
function gp_gui_x(_device) {return global.cf_mx;}
function gp_gui_y(_device) {return global.cf_my;}
function sv_clear() {
    with(ObjectMonster)instance_destroy();with(ObjectBossMonster)instance_destroy();with(ObjectCoin)instance_destroy();with(ObjectChest)instance_destroy();with(ObjectMagnetOrb)instance_destroy();
    with(ObjectLightningball)instance_destroy();with(ObjectFireball)instance_destroy();with(ObjectIceball)instance_destroy();with(ObjectSwordHitbox)instance_destroy();
}
function cf_pos(_x=2048,_y=2048) {
    ObjectPlayer.x=_x;ObjectPlayer.y=_y;ObjectPlayer.pickup_prev_x=_x;ObjectPlayer.pickup_prev_y=_y;ObjectPlayer.motion_state=0;ObjectPlayer.dodge_timer=0;
    camera_set_view_pos(ObjectPlayer.camera,clamp(_x-400,0,room_width-800),clamp(_y-300,0,room_height-600));
}
function gp_capture(_surface,_name) {
    // Native PNG export avoids megabytes of synchronous console output per detailed world image.
    surface_save(_surface,"fgcapture-"+_name+".png");
    show_debug_message("GAMEPLAY_CAPTURE "+_name);
}
function sv_menu_tick() {
    if(!variable_global_exists("cf_case")) {global.cf_case=0;global.cf_phase=0;global.cf_key=-1;global.cf_move=false;global.cf_down=false;global.cf_press=false;global.cf_mx=-100;global.cf_my=-100;global.sv_checks=0;global.sv_failed=false;global.sv_metrics={};global.sv_native_modal_frames=0;}
    if(global.cf_case>=9) {
        if(variable_global_exists("cf_done")) {show_debug_message("GAMEPLAY_RESULT "+json_stringify({passed:!global.sv_failed,checks:global.sv_checks,classes:["Sword","Mage","Ranger"],combinations:9,metrics:global.sv_metrics,native_modal_frames:global.sv_native_modal_frames}));game_end();return;}
        menu_mode="main";menu_activate(0);menu_activate(0);menu_activate(0);global.cf_phase=8;global.cf_frame=0;return;
    }
    menu_mode="main";menu_activate(0);menu_activate(global.cf_case div 3);menu_activate(global.cf_case mod 3);global.cf_phase=0;global.cf_wait=0;
}
function cf_auto_choice() {
    if(!global.levelup_active && !global.chest_collected)return;
    var ui=spell_ui_layout();global.cf_mx=ui.x+ui.w*0.5;global.cf_my=ui.y+ui.row*0.5;
    if(global.choice_mouse_armed){global.cf_down=true;global.cf_press=true;}
}
function sv_controller_tick() {
    global.cf_key=-1;global.cf_press=false;global.cf_down=false;global.cf_move=false;
    if(global.cf_phase==8){cf_native_tick();return;}
    if(global.cf_phase==0) {
        gp_check(instance_exists(ObjectPlayer) && instance_exists(ObjectSpawner) && global.coins_needed==1,"real class/level start "+string(global.cf_case));
        ObjectSpawner.population_timer=999;instance_create_layer(ObjectPlayer.x,ObjectPlayer.y,"Instances",ObjectCoin);global.cf_phase=1;return;
    }
    if(global.cf_phase==1) {
        if(!global.levelup_active){global.cf_wait++;if(global.cf_wait<20)return;gp_check(false,"coin opens level-up");}
        gp_check(global.current_level==2 && global.game_paused,"actual coin collision opens first choice");global.cf_key=vk_space;global.cf_phase=2;return;
    }
    if(global.cf_phase==2) {gp_check(global.levelup_active && array_length(global.active_spells)+array_length(global.passive_spells)==0,"Space does not select a skill");global.cf_key=ord("W");global.cf_phase=3;return;}
    if(global.cf_phase==3) {gp_check(global.levelup_active,"WASD does not select a skill");global.cf_down=true;global.cf_phase=4;return;}
    if(global.cf_phase==4) {gp_check(global.levelup_active,"held mouse without new press does not select");var ui=spell_ui_layout();global.cf_mx=ui.x+80;global.cf_my=ui.y+25;global.cf_phase=5;return;}
    if(global.cf_phase==5) {global.cf_down=true;global.cf_press=true;global.cf_phase=6;return;}
    if(global.cf_phase==6) {
        gp_check(!global.game_paused && array_length(global.active_spells)+array_length(global.passive_spells)==1,"fresh mouse press selects exactly one skill and resumes");
        if(global.cf_case==0)cf_fixtures();global.cf_case++;round_end_to_title();return;
    }
}
function cf_enemy(_x,_y,_hp=1000) {var e=instance_create_layer(_x,_y,"Instances",ObjectMonster);e.hp=_hp;e.max_hp=_hp;return e;}
function cf_fixtures() {
    sv_clear();reset_round();cf_pos();var pl=ObjectPlayer;ObjectSpawner.population_timer=999;
    cf_swordsman_checks(pl);
    cf_master_checks(pl);sv_clear();reset_round();cf_pos();
    v2_fixtures();sv_clear();reset_round();cf_pos();
    var orb=magnet_drop(pl.x+200,pl.y,true),coin=instance_create_layer(3900,3900,"Instances",ObjectCoin);
    gp_check(!magnet_collect(orb,pl) && global.magnet_metrics.activations==0 && !coin.magnetized,"remote function cannot trigger magnet without actual touch");
    var fake=cf_enemy(orb.x,orb.y);gp_check(!magnet_collect(orb,fake),"other objects cannot activate orb");
    cf_pos(orb.x,orb.y);magnet_collect(orb,pl,true);
    gp_check(!instance_exists(orb) && global.magnet_metrics.activations==1 && coin.magnetized,"orb collision handler contract activates once");
    gp_check(!magnet_collect(orb,pl) && global.magnet_metrics.activations==1,"destroyed orb cannot activate twice");
    var newer=instance_create_layer(3800,3800,"Instances",ObjectCoin);gp_check(!newer.magnetized,"new coins do not inherit stale global magnet effect");
    sv_clear();cf_pos();global.selected_character="Mage";pl.player_power=4;with(pl)player_combat_init();var e=cf_enemy(pl.x+150,pl.y);
    with(pl)weapon_auto_step();gp_check(instance_number(ObjectLightningball)==3 && pl.weapon_cooldown==64,"mage base attack launches three projectiles with shared cooldown");
    gp_check(instance_find(ObjectLightningball,0).visual_width==104 && instance_find(ObjectLightningball,0).damage_radius==20,"mage projectile art and head collider are enlarged together");
    var shots=[];for(var i=0;i<3;i++)array_push(shots,instance_find(ObjectLightningball,i));
    gp_check(abs(angle_difference(shots[0].direction,shots[2].direction))==14,"mage fan is narrow and visible");
    with(e)instance_destroy();var targets=[];
    for(var i=0;i<3;i++){var t=cf_enemy(pl.x+110,pl.y+(i-1)*70);array_push(targets,t);shots[i].x=pl.x+40;shots[i].y=t.y-12;shots[i].direction=0;}
    repeat(20)with(ObjectLightningball)event_perform(ev_step,0);
    var all_hit=true;for(var i=0;i<3;i++)if(targets[i].hp>=1000)all_hit=false;
    gp_check(all_hit && instance_number(ObjectLightningball)==0,"all three mage projectiles deal actual collision damage");
    sv_clear();cf_pos();global.selected_character="Ranger";pl.player_power=1;with(pl)player_combat_init();var line=[];
    for(var i=0;i<5;i++)array_push(line,cf_enemy(pl.x+85+i*60,pl.y));with(pl)weapon_auto_step();var bolt=instance_find(ObjectLightningball,0);
    repeat(30)with(bolt)event_perform(ev_step,0);
    var exact=true;for(var i=0;i<5;i++)if(line[i].hp!=983)exact=false;
    gp_check(exact && instance_exists(bolt) && array_length(bolt.hit_targets)==5,"one ranger bolt pierces five real enemies with exact damage");
    bolt.direction=180;bolt.lifetime=60;repeat(30)with(bolt)event_perform(ev_step,0);
    exact=true;for(var i=0;i<5;i++)if(line[i].hp!=983)exact=false;
    gp_check(exact,"same bolt cannot damage the same enemies on a second crossing");
    sv_clear();cf_pos();global.selected_character="Sword";pl.player_power=2;with(pl)player_combat_init();e=cf_enemy(pl.x+70,pl.y);repeat(5)with(pl)weapon_auto_step();
    gp_check(e.hp<1000 && e.hit_stun>0 && e.knock_vx>0,"sword deals real damage, short stun and directional knockback");
    var before_x=e.x;with(e)enemy_reaction_step(0.05);gp_check(e.x>before_x,"knockback actually moves target");
    with(e)enemy_reaction_step(0.13);apply_attack_damage(e,2,pl);gp_check(e.hit_stun==0,"rapid hits cannot refresh stun during lockout");
    with(e)enemy_reaction_step(0.5);gp_check(e.stun_lockout==0,"enemy recovers and can react to later distinct attacks");
    global.damage_labels=[];apply_attack_damage(e,7,pl,0);gp_check(global.damage_labels[0].color==c_white,"base weapon damage number is white");
    apply_attack_damage(e,8,pl,SPELL.ICEBALL);gp_check(global.damage_labels[1].color==make_color_rgb(255,225,88),"active spell number is yellow");
    apply_attack_damage(e,2,pl,SPELL.SHIELD);gp_check(global.damage_labels[2].color!=c_white,"separate passive hit is yellow");
    gp_check(array_length(global.damage_labels)==3 && array_length(global.impact_fx)>0,"single source label per hit and visible impact pool");
    var b=boss_spawn("storm_warden");apply_attack_damage(b,1,pl);gp_check(b.knock_vx==0 && b.knock_vy==0 && b.hit_stun==0,"giant dragon resists ordinary knockback and stun");
    var positions=[[1900,2100],[2600,2100],[2300,1800],[2300,2340]];
    for(var i=0;i<4;i++) {
        b.x=2300;b.y=2200;cf_pos(positions[i][0],positions[i][1]);pl.max_hp=10000;pl.hp=10000;pl.damage_reduction=0;
        dragon_attack_begin(b,"beam");var g=dragon_attack_geometry(b),angle=b.dragon_base_angle;
        gp_check(boss_point_segment_distance(pl.x,pl.y-10,g.x,g.y,g.ex,g.ey)<0.1,"beam locks real player position in direction "+string(i));
        var edges=dragon_warning_edges(g);gp_check(abs(point_distance(edges.ax,edges.ay,edges.cx,edges.cy)-g.width)<0.01,"warning corridor has true width in direction "+string(i));
        var hp0=pl.hp;boss_step(b,dragon_config().warning-0.01);gp_check(pl.hp==hp0 && b.boss_state=="windup","warning phase is harmless "+string(i));
        boss_step(b,0.02);gp_check(b.boss_state=="active" && pl.hp==hp0-36,"first active visible frame deals immediate contact damage "+string(i));
        pl.x+=80;boss_step(b,0.01);gp_check(b.dragon_base_angle==angle,"locked beam does not chase after warning "+string(i));
        var hp_end=pl.hp;b.boss_timer=0.001;boss_step(b,0.01);gp_check(b.boss_state=="recovery" && pl.hp==hp_end,"ended attack cannot deal late damage "+string(i));
    }
    gp_check(dragon_config().warning<1.25 && dragon_config().beam_damage>22,"dragon tells are faster and strong hits more dangerous");
    sv_clear();cf_pos();run_stats_reset();e=cf_enemy(pl.x+80,pl.y,10);apply_attack_damage(e,40,pl,SPELL.ICEBALL);
    gp_check(run_stats_get(SPELL.ICEBALL).damage==10 && run_stats_get(SPELL.ICEBALL).hits==1,"stats clip overkill and retain source");
    with(e)instance_destroy();e=cf_enemy(pl.x+80,pl.y);combat_area_hit(e.x,e.y-10,30,17,pl,60,1,0,1,SPELL.FIREBALL);with(e)event_perform(ev_step,0);
    gp_check(run_stats_get(SPELL.FIREBALL).dot_damage>0 && run_stats_get(SPELL.FIREBALL).hits==1,"burn contribution separated without multiplying direct hits");
    pl.hp=98;pl.max_hp=100;var heal={id:SPELL.HEAL,name:"Healing Pulse",level:1,cooldown_timer:0};cast_spell(heal);
    gp_check(run_stats_get(SPELL.HEAL).healing==2 && run_stats_get(SPELL.HEAL).casts==1,"healing stats count actual restored HP and successful cast");
    var casts_before=run_stats_get(SPELL.VITALITY).casts;global.passive_spells=[{id:SPELL.VITALITY,name:"Vitality",level:1,type:"passive"}];pl.__base_max_hp=100;pl.passive_hp_bonus=0;pl.hp=100;apply_passives(pl);
    gp_check(run_stats_get(SPELL.VITALITY).casts==casts_before+1 && run_stats_get(SPELL.VITALITY).healing==12,"passive Vitality records its actual heal proc");
    global.passive_spells=[];apply_passives(pl);
    var bank=fg_audio_bank(),events=["sword_swing","sword_hit","crossbow","arrow_hit","magic_projectile","magic_hit","fireball","explosion","ice","ice_hit","lightning","shock_hit","nova_cast","heal_cast","arcane_hit"];
    var sounds_valid=true;for(var i=0;i<array_length(events);i++)if(!audio_exists(variable_struct_get(bank,events[i])))sounds_valid=false;
    gp_check(sounds_valid,"launch, impact and all active spell audio resources exist");
    gp_check(variable_struct_exists(global.fg_audio.requests,"magic_hit") && variable_struct_exists(global.fg_audio.requests,"arrow_hit") && variable_struct_exists(global.fg_audio.requests,"skill_106"),"actual collisions and cast paths requested their distinct cues");
    for(var lv=0;lv<3;lv++) {
        global.selected_level=lv;weather_init();weather_set("heavy_rain",999);weather_step(0.016);
        gp_check(global.weather.rain<0.02,"rain blends in instead of jumping for level "+string(lv));
        weather_step(12);gp_check(global.weather.rain>0.2 && array_length(global.weather.rain_particles)<=160,"rain profile works within particle cap "+string(lv));
        weather_set("gust",999);repeat(30)weather_step(0.05);gp_check(array_length(global.weather.leaves)>0 && array_length(global.weather.leaves)<=24,"occasional gust generates bounded leaves "+string(lv));
        weather_set("clear",999);weather_step(30);gp_check(global.weather.rain<0.001 && global.weather.sun>0.7,"rain fades out and sun returns "+string(lv));
    }
    global.selected_level=0;weather_init();weather_set("heavy_rain",45);global.weather.index=5;weather_step(46);gp_check(global.weather.type=="light_rain","rain episode naturally decays to light rain");weather_step(16);gp_check(global.weather.type=="clearing","rain cycle transitions into clearing");
    gp_check(color_get_red(weather_ambient())>=112 && combat_config().monster_speed==1.08,"brighter minimum ambience and centrally configured eight percent monster pace");
    global.round_seconds=61;progression_audit_step();gp_check(array_length(global.progression_samples)==1 && global.progression_samples[0].seconds==60,"actual future run logger records configured minute checkpoints");
    run_stats_reset();gp_check(run_stats_get(SPELL.FIREBALL).damage==0 && run_stats_get(SPELL.HEAL).healing==0,"round stat reset clears previous contributions");
    sv_clear();var stale_orb=magnet_drop(3000,3000,true),stale_coin=instance_create_layer(3900,3900,"Instances",ObjectCoin);instance_deactivate_object(stale_orb);instance_deactivate_object(stale_coin);
    global.selected_character="Sword";global.selected_level=0;reset_round();instance_activate_object(ObjectMagnetOrb);instance_activate_object(ObjectCoin);gp_check(instance_number(ObjectMagnetOrb)==0 && instance_number(ObjectCoin)==0,"new run also clears inactive stale orbs and magnet coins");cf_pos();
}
function cf_native_tick() {
    global.cf_frame++;var f=global.cf_frame;cf_auto_choice();
    if(f==1) {
        sv_clear();reset_round();cf_pos();ObjectSpawner.population_timer=999;
        var audit_layer=layer_create(100,"CoinAudit");
        for(var i=0;i<30;i++){var c=instance_create_layer(80+(i mod 6)*780,80+(i div 6)*950,i mod 2 ? "Instances" : audit_layer,ObjectCoin);if(i==0)instance_deactivate_object(c);}
    }
    if(f==90)gp_check(global.magnet_metrics.activations==0 && global.coin_xp_earned==0,"native map coins remain untouched without orb pickup");
    if(f==92)global.cf_orb=magnet_drop(ObjectPlayer.x+140,ObjectPlayer.y,true);
    if(f>=100 && f<160 && instance_exists(global.cf_orb))global.cf_move=true;
    if(f==160)gp_check(!instance_exists(global.cf_orb) && global.magnet_metrics.activations==1 && global.magnet_metrics.collision_activations==1 && global.magnet_metrics.marked==30,"real engine collision from walking collects orb once and includes thirty coins on multiple layers plus inactive coin");
    if(f==360) {
        gp_check(instance_number(ObjectCoin)==0 && global.coin_xp_earned==30 && global.magnet_metrics.xp==30 && global.magnet_metrics.collected==30,"native magnet delivers all thirty coins and exactly thirty XP with no leftovers");
        global.sv_metrics.magnet30=global.magnet_metrics;weather_set("heavy_rain",999);
    }
    if(f==430)weather_set("gust",999);if(f==480)weather_set("heavy_rain",999);
    if(f==560)weather_set("clearing",999);
    if(f==700) {sv_clear();reset_round();cf_pos();ObjectSpawner.population_timer=999;var b=boss_spawn("storm_warden");b.x=ObjectPlayer.x+245;b.y=ObjectPlayer.y+200;dragon_attack_begin(b,"beam");}
    if(f==820) {gp_check(global.game_over,"native stationary unprotected player is killed by correctly aimed heavy breath");global.sv_metrics.stationary_dragon_lethal=global.game_over;}
    if(f==830) {
        sv_clear();reset_round();cf_pos();ObjectSpawner.population_timer=999;ObjectPlayer.__base_max_hp=100000;ObjectPlayer.max_hp=100000;ObjectPlayer.hp=100000;
        var ids=[101,102,103,104,105,106,201,202,203,204,205,206];for(var i=0;i<12;i++)learn_spell(ids[i]);apply_passives(ObjectPlayer);
        var b=boss_spawn("storm_warden");b.x=2290;b.y=2248;b.boss_timer=99;global.cf_boss=b;weather_set("light_rain",999);
    }
    if(f>=830 && instance_exists(global.cf_boss)) {
        var b=global.cf_boss;if(f==940){cf_pos(b.x,b.y-400);dragon_attack_begin(b,"beam");}if(f==1000)cf_pos();if(f==850)dragon_attack_begin(b,"beam");if(f==1000)dragon_attack_begin(b,"sweep");if(f==1200)dragon_attack_begin(b,"arc");if(f==1350)dragon_attack_begin(b,"stomp");if(f==1550)b.hp=b.max_hp*0.49;if(f==1700)b.hp=0;
    }
    if(f==1800)gp_check(instance_number(ObjectMagnetOrb)==1 && instance_number(ObjectChest)==1,"native boss death leaves exactly one visible orb next to chest");
    if(f==1850) {global.game_paused=true;global.normal_pause_active=true;global.cf_mx=-100;global.cf_my=-100;}
    if(f==1854) {
        var surface=surface_create(800,600);surface_set_target(surface);draw_clear(make_color_rgb(18,29,35));display_set_gui_size(800,600);ui_modal_draw();surface_reset_target();gp_capture(surface,"inlinepause");surface_free(surface);
        gp_check(run_stats_get(SPELL.FIREBALL).damage>0,"inline pause values reflect actual native run spell damage");
    }
    if(f==1860)cf_swordsman_gallery();
    if(f==1880) {
        global.game_paused=false;global.normal_pause_active=false;sv_clear();reset_round();cf_pos();ObjectSpawner.population_timer=999;
        ObjectPlayer.__base_max_hp=100000;ObjectPlayer.max_hp=100000;ObjectPlayer.hp=100000;
        var r=combat_view_rect();for(var i=0;i<150;i++){var e=cf_enemy(r.left+45+(i mod 15)*45,r.top+90+(i div 15)*40,10000);e.damage=0;}
        weather_set("gust",999);repeat(24)weather_step(1/60);weather_set("heavy_rain",999);global.weather.rain=1;
    }
    if(f==1900){global.cf_perf_ms=0;global.cf_perf_frames=0;global.cf_perf_max=0;}
    if(f>1900 && f<=1960){global.cf_perf_ms+=delta_time/1000;global.cf_perf_frames++;global.cf_perf_max=max(global.cf_perf_max,delta_time/1000);}
    if(f==1962){var frame_mean=global.cf_perf_ms/global.cf_perf_frames;gp_check(frame_mean<40 && instance_number(ObjectMonster)==150 && array_length(global.weather.rain_particles)==160,"native 150-monster weather scene renders within bounded frame budget");global.sv_metrics.weather_crowd={enemies:150,rain:array_length(global.weather.rain_particles),leaves:array_length(global.weather.leaves),mean_frame_ms:frame_mean,max_frame_ms:global.cf_perf_max,frames:global.cf_perf_frames};}
    if(f==1985) {
        sv_clear();reset_round();cf_pos(2048,1952);ObjectSpawner.population_timer=999;
        ObjectPlayer.__base_max_hp=100000;ObjectPlayer.max_hp=100000;ObjectPlayer.hp=100000;
        global.cf_combo_captured=[false,false,false];
        for(var i=0;i<7;i++){var e=population_spawn_enemy(ObjectPlayer.x+65+(i div 3)*54,ObjectPlayer.y-45+(i mod 3)*35);e.hp=1000;e.max_hp=1000;e.damage=0;}
    }
    if(f==2090)gp_check(global.cf_combo_captured[0] && global.cf_combo_captured[1] && global.cf_combo_captured[2],"native combat draw captures all three actual combo strike effects");
    if(f==2100){var e=instance_find(ObjectMonster,0);if(instance_exists(e))e.hp=0;}
    if(f==2200){cf_pos(1810,880);weather_set("gust",999);}
    v2_native_tick(f);
    if(f>=2980){global.cf_done=true;global.cf_case=9;global.game_paused=false;round_end_to_title();}
}
function cf_swordsman_checks(_pl) {
    var dirs=["right","up_right","up","up_left","left","down_left","down","down_right"];
    var actions=["idle","turn","walk","run","attack1","attack2","attack3","jump","fall","dive","landing","slide","dodge","hurt","death"];
    var counts=[1,1,8,8,2,2,3,3,2,1,1,4,4,3,5],valid=true;
    for(var a=0;a<array_length(actions);a++)for(var d=0;d<8;d++) {
        var spr=player_artpack_sprite("spr_fg_swordsmanv3_"+actions[a]+"_"+dirs[d]);
        if(sprite_get_number(spr)!=counts[a] || sprite_get_width(spr)!=96 || sprite_get_xoffset(spr)!=48 || sprite_get_yoffset(spr)!=88)valid=false;
    }
    gp_check(valid,"all 120 swordsman resources expose correct native frames and foot origins");
    for(var d=0;d<8;d++) {
        _pl.facing_direction=d*45;_pl.attack_timer=0;_pl.hud_hit_flash=0;_pl.menu_input_guard=0;_pl.weapon_cooldown=999;
        with(_pl)event_perform(ev_step,0);
        gp_check(_pl.visual_sprite_index==player_artpack_sprite("spr_fg_swordsmanv3_idle_"+dirs[d]) && _pl.visual_mirror==1 && _pl.mask_index==combat_mask(),"actual player step selects authored octant without changing mask "+dirs[d]);
    }
    var first=player_visual_asset("swordsmanv3","attack","right",1).sprite,second=player_visual_asset("swordsmanv3","attack","right",2).sprite,third=player_visual_asset("swordsmanv3","attack","right",3).sprite;
    gp_check(first!=second && second!=third && first!=third,"three combo stages select distinct authored pose sequences");
    gp_check(player_visual_direction("swordsmanv3",22.49)=="right" && player_visual_direction("swordsmanv3",22.5)=="up_right" && player_visual_direction("swordsmanv3",359)=="right","octant boundaries and angle wrapping are deterministic");
    _pl.weapon_cooldown=0;_pl.facing_direction=0;
}
function cf_swordsman_gallery() {
    var surface=surface_create(800,600);surface_set_target(surface);draw_clear(make_color_rgb(16,22,33));
    draw_set_halign(fa_left);draw_set_color(make_color_rgb(235,212,163));draw_text(15,10,"SCHWERTKAEMPFER - 8 RICHTUNGEN / NATIVE SPRITES");
    var dirs=["right","up_right","up","up_left","left","down_left","down","down_right"];
    var actions=["idle","walk","attack3","dodge","death"];
    for(var row=0;row<5;row++) {
        draw_set_color(make_color_rgb(162,190,201));draw_text(12,44+row*110,string_upper(actions[row]));
        for(var d=0;d<8;d++) {
            var spr=player_artpack_sprite("spr_fg_swordsmanv3_"+actions[row]+"_"+dirs[d]);
            var frame=row==0 ? 0 : (row==1 ? 3 : (row==2 || row==3 ? 1 : sprite_get_number(spr)-1));
            draw_sprite_ext(spr,frame,50+d*100,139+row*110,1.35,1.35,0,c_white,1);
        }
    }
    draw_set_color(c_white);surface_reset_target();gp_capture(surface,"swordsman-gallery");surface_free(surface);
}
function ap_render_capture() {
    if(global.cf_phase!=8)return;var f=global.cf_frame,name="";
    switch(f){case 60:name="field";break;case 135:name="magnetflight";break;case 460:name="gust";break;case 540:name="rain";break;case 660:name="clearing";break;case 915:name="aimedbeam";break;case 970:name="verticalwarning";break;case 999:name="verticalbeam";break;case 1100:name="sweep";break;case 1280:name="firearc";break;case 1470:name="magma";break;case 1570:name="phase";break;case 1730:name="loot";break;case 1970:name="raincrowd";break;}
    if(f==2130)name="master-corpse";if(f==2230)name="master-north-ruins";
    var v2_name=v2_capture_name(f);if(v2_name!="")name=v2_name;
    if(f>1985 && f<2080 && name=="") {
        var hit=instance_find(ObjectSwordHitbox,0);
        if(instance_exists(hit) && hit.lifetime<=7 && !global.cf_combo_captured[hit.combo_stage-1]) {
            global.cf_combo_captured[hit.combo_stage-1]=true;
            var combo_names=["first","second","finisher"];name="master-combo-"+combo_names[hit.combo_stage-1];
        }
    }
    if(name=="")return;var surface=surface_create(800,600);surface_set_target(surface);draw_clear_alpha(c_black,0);
    if(name=="v2-pause-details" || name=="v2-offers")ui_modal_draw();else draw_surface_stretched(application_surface,0,0,800,600);
    surface_reset_target();gp_capture(surface,name);surface_free(surface);
}
function cf_master_weapon_tick(_pl) {with(_pl)weapon_auto_step();with(ObjectSwordHitbox)event_perform(ev_step,0);}
function cf_master_checks(_pl) {
    gp_check(room==Room1 && instance_number(ObjectMasterWorld)==1 && instance_number(ObjectEnvironmentDecoration)==0 && !layer_exists("Ground") && !layer_exists("Paths") && !layer_exists("Ground_Details"),"Room1 contains replacement world only and no old scenery or tile layers");
    var types=array_create(16,false);with(ObjectMasterScenery)types[master_prop]=true;
    var all_props=true;for(var i=0;i<16;i++)if(!types[i])all_props=false;
    gp_check(all_props && instance_number(ObjectMasterScenery)>600,"new room actually instantiates trees plants ruins fire bowls and floor details");
    var valid=true,dirs=["right","up_right","up","up_left","left","down_left","down","down_right"],actions=["idle","walk","attack","hurt","death"],counts=[2,4,2,3,5];
    for(var d=0;d<8;d++)for(var a=0;a<5;a++)if(sprite_get_number(player_artpack_sprite("spr_master_skeleton_"+actions[a]+"_"+dirs[d]))!=counts[a])valid=false;
    gp_check(valid,"new skeleton has native idle walk attack hurt death frames in all eight directions");
    valid=true;for(var t=0;t<3;t++){global.round_seconds=t*120;repeat(12){var e=population_spawn_enemy(_pl.x+160,_pl.y+100);if(!e.master_skeleton || e.monster_species!="master_skeleton")valid=false;}}
    gp_check(valid && instance_number(ObjectMonster)==36,"all normal spawns at early middle and late times are exclusively new skeletons");
    global.sv_metrics.master_world={old_scenery:instance_number(ObjectEnvironmentDecoration),new_scenery:instance_number(ObjectMasterScenery),normal_spawn_samples:instance_number(ObjectMonster),skeleton_pool_only:valid,types_instantiated:types};
    sv_clear();global.round_seconds=0;var e=population_spawn_enemy(_pl.x+20,_pl.y);e.damage=8;_pl.hp=120;_pl.damage_reduction=0;_pl.invulnerable_timer=0;
    master_skeleton_step_probe(e,.10);var hp_before=_pl.hp;
    gp_check(hp_before==120,"skeleton attack windup is harmless");
    master_skeleton_step_probe(e,.11);gp_check(_pl.hp<hp_before,"skeleton active sword frame applies real damage");
    sv_clear();global.selected_character="Sword";_pl.player_power=2;with(_pl)player_combat_init();global.sword_combo_metrics={chains:0,swings:0,finishers:0};
    e=cf_enemy(_pl.x+70,_pl.y);repeat(4)cf_master_weapon_tick(_pl);gp_check(e.hp==1000,"three-hit combo begins with a real harmless windup");
    cf_master_weapon_tick(_pl);var first_loss=1000-e.hp;gp_check(e.hp==989,"first combo strike deals eleven actual HP once");
    repeat(18)cf_master_weapon_tick(_pl);var second_loss=1000-e.hp-first_loss;gp_check(e.hp==976 && _pl.attack_stage==2,"second strike has its own animation and thirteen actual HP");
    repeat(20)cf_master_weapon_tick(_pl);var third_loss=1000-e.hp-first_loss-second_loss;gp_check(e.hp==957 && _pl.attack_stage==3,"finisher is a distinct third hit for nineteen actual HP");
    global.sv_metrics.master_world.combo_hp_loss=[first_loss,second_loss,third_loss];
    repeat(17)cf_master_weapon_tick(_pl);gp_check(e.hp==957 && ! _pl.sword_combo_active && global.sword_combo_metrics.swings==3 && global.sword_combo_metrics.finishers==1,"one chain ends after exactly three contacts without duplicated hitbox damage");
    gp_check(sprite_get_number(spr_master_slash_1)==4 && sprite_get_number(spr_master_slash_2)==4 && sprite_get_number(spr_master_slash_3)==4,"all three new raster slash effects contain four actual frames");
    gp_check(master_sword_frame(1,3)==0 && master_sword_frame(1,4)==1 && master_sword_frame(2,21)==0 && master_sword_frame(2,22)==1 && master_sword_frame(3,41)==0 && master_sword_frame(3,42)==1 && master_sword_frame(3,50)==2,"body contact poses and recovery use the exact three actual strike times");
    with(ObjectSwordHitbox)instance_destroy();e.hp=0;with(e)event_perform(ev_step,0);
    gp_check(!instance_exists(e) && instance_number(ObjectSkeletonRemains)==1 && instance_number(ObjectCoin)==1,"skeleton death creates one corpse animation and one coin only");
    var rem=instance_find(ObjectSkeletonRemains,0);rem.life=.42;with(rem)event_perform(ev_step,0);
    gp_check(rem.image_index==4 && rem.life<1.25,"death animation reaches its fifth frame before fading");
    with(ObjectSkeletonRemains)instance_destroy();
}
function master_skeleton_step_probe(_enemy,_dt){with(_enemy)master_skeleton_step(_dt);}
