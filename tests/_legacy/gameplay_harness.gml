// Only appended to the isolated runtime project by run_gameplay_smoke.py.
function gp_check(_ok,_message) {
    global.gp_checks++;
    if(!_ok) {global.gp_failed=true; show_debug_message("GAMEPLAY FAIL "+_message);}
    else show_debug_message("GAMEPLAY PASS "+_message);
}
function gp_key_down(_key) {return array_contains(global.gp_down,_key);}
function gp_key_pressed(_key) {return global.gp_pressed==_key;}
function gp_mouse_down(_button) {return _button==mb_left && global.gp_mouse_held;}
function gp_mouse_pressed(_button) {return _button==mb_left && global.gp_mouse_click;}
function gp_mouse_x() {return global.gp_mx;}
function gp_mouse_y() {return global.gp_my;}
function gp_gui_x(_device) {return global.gp_gui_mx;}
function gp_gui_y(_device) {return global.gp_gui_my;}
function gp_inputs_clear() {
    global.gp_down=[]; global.gp_pressed=-1; global.gp_mouse_held=false; global.gp_mouse_click=false;
    global.gp_mx=700; global.gp_my=300; global.gp_gui_mx=-100; global.gp_gui_my=-100;
}
function gp_menu_tick() {
    gp_inputs_clear();
    if(!variable_global_exists("gp_combo")) {
        global.gp_combo=0; global.gp_stage=0; global.gp_checks=0; global.gp_failed=false; global.gp_did_restart=false;
    }
    if(global.gp_combo>=9) {
        var result={passed:!global.gp_failed,checks:global.gp_checks,classes:["Sword","Mage","Ranger"],combinations:9};
        show_debug_message("GAMEPLAY_RESULT "+json_stringify(result)); game_end(); return;
    }
    gp_check(array_length(menu_labels("main"))==3,"main menu has no direct level entry");
    menu_mode="main"; menu_activate(1);
    gp_check(menu_mode=="settings" && array_length(menu_labels(menu_mode))==5,"settings includes title button");
    menu_activate(4); gp_check(menu_mode=="main","settings title button");
    menu_activate(0); gp_check(menu_mode=="characters","new game opens characters");
    if(global.gp_combo==0 && !global.gp_did_restart) {
        var surface=surface_create(800,600); surface_set_target(surface); draw_clear(c_black); display_set_gui_size(800,600);
        event_perform(ev_draw,64); surface_reset_target(); gp_capture(surface,"characters"); surface_free(surface);
    }
    menu_activate(global.gp_combo div 3); gp_check(menu_mode=="levels","character opens levels");
    menu_activate(global.gp_combo mod 3);
    global.gp_stage=0;
}
function gp_clear_enemies() {
    with(ObjectMonster) instance_destroy(); with(ObjectBossMonster) instance_destroy();
    with(ObjectFireball) instance_destroy(); with(ObjectIceball) instance_destroy(); with(ObjectLightningball) instance_destroy();
    with(ObjectSwordHitbox) instance_destroy();
}
function gp_player_step(_pl) {with(_pl) event_perform(ev_step,0);}
function gp_fixture() {
    gp_clear_enemies();
    with(ObjectSpawner) instance_destroy();
    var pl=global.player;
    var label=global.selected_character; pl.menu_input_guard=0;
    global.normal_pause_active=true; global.game_paused=true;
    round_menu_activate(1); gp_check(global.settings_active,"pause opens in-round settings");
    var volume_before=global.master_volume; round_menu_activate(1);
    gp_check(global.master_volume!=volume_before,"volume changes through settings action");
    round_menu_activate(4); gp_check(!global.settings_active && global.game_paused,"settings returns to paused round");
    round_menu_activate(0); gp_check(!global.game_paused,"pause resumes round");
    pl.menu_input_guard=0;
    pl.x=300; pl.y=300; pl.hp=pl.max_hp; pl.invulnerable_timer=0;
    gp_check(pl.mask_index==global.body_mask && sprite_get_bbox_left(pl.mask_index)==22,"stable narrow body mask");
    // All motion states must allow actual weapon damage without a click or learned spell.
    global.active_spells=[]; global.hotbar=array_create(6,undefined);
    for(var motion=0;motion<6;motion++) {
        gp_clear_enemies();
        pl.motion_state=motion<5 ? motion : 0; pl.dodge_timer=motion==5 ? 5 : 0;
        pl.weapon_cooldown=0;
        var mob=instance_create_layer(pl.x+(label=="Sword" ? 65 : 180),pl.y,"Instances",ObjectMonster);
        mob.hp=1000;
        with(pl) weapon_auto_step();
        if(label!="Sword") {
            for(var frame=0;frame<50;frame++) with(ObjectLightningball) spell_projectile_step();
        }
        gp_check(mob.hp<1000,label+" auto damage during state "+string(motion));
        gp_check(array_length(global.active_spells)==0,"weapon independent of spell slots");
        var before=mob.hp;
        with(pl) weapon_auto_step();
        gp_check(mob.hp==before,"weapon cooldown prevents second immediate attack");
    }
    gp_clear_enemies();
    pl.motion_state=0; pl.dodge_timer=0; pl.x=300; pl.y=300;
    pl.mobility_cooldown=0; pl.dodge_cooldown=0;
    gp_inputs_clear(); global.gp_down=[ord("D")]; gp_player_step(pl);
    gp_check(abs(pl.x-(300+pl.moveSpeed))<0.001,"keyboard full-speed movement");
    gp_inputs_clear(); pl.mouse_move_armed=true;
    global.gp_mouse_held=true; global.gp_mx=pl.x+100; global.gp_my=pl.y;
    var before_x=pl.x; gp_player_step(pl);
    gp_check(abs(pl.x-before_x-pl.moveSpeed)<0.001,"held mouse follows target");
    global.gp_mx=pl.x+5; before_x=pl.x; gp_player_step(pl);
    gp_check(pl.x==before_x,"mouse dead zone stops jitter");
    global.gp_mx=pl.x+100; global.gp_down=[ord("W")]; var before_y=pl.y; before_x=pl.x;
    gp_player_step(pl); gp_check(pl.x==before_x && pl.y<before_y,"keyboard wins over held mouse without speed stacking");
    gp_inputs_clear(); before_x=pl.x; before_y=pl.y; gp_player_step(pl);
    gp_check(pl.x==before_x && pl.y==before_y,"released mouse stops movement");
    pl.mouse_move_armed=false; global.gp_mouse_held=true; global.gp_mx=pl.x+100;
    gp_player_step(pl); gp_check(pl.x==before_x,"menu-held mouse requires release");
    gp_inputs_clear(); pl.x=500; pl.y=500; pl.motion_state=0; pl.dodge_timer=0; pl.mobility_cooldown=0;
    global.gp_pressed=vk_space; gp_player_step(pl);
    gp_check(pl.motion_state==1 && player_is_protected(pl),"jump begins protected");
    var mob=instance_create_layer(pl.x,pl.y,"Instances",ObjectMonster); mob.damage=10; mob.hp=10000;
    var hp_before=pl.hp; pl.invulnerable_timer=0;
    gp_check(!player_contact(pl,mob) && pl.hp==hp_before,"jump blocks actual contact damage");
    gp_inputs_clear();
    var saw_slide=false;
    for(var frame=0;frame<100;frame++) {
        gp_player_step(pl);
        if(pl.motion_state==4) saw_slide=true;
    }
    gp_check(saw_slide && pl.motion_state==0 && !player_is_protected(pl),"jump lands, slides and protection ends");
    pl.x=500; pl.y=500; mob.x=500; mob.y=500; pl.invulnerable_timer=0;
    gp_check(player_contact(pl,mob),"ground contact damages after protection ends");
    hp_before=pl.hp; gp_check(!player_contact(pl,mob) && pl.hp==hp_before,"same-frame contact cannot hit twice");
    pl.invulnerable_timer=0; mob.x=pl.x+45;
    gp_check(!player_contact(pl,mob),"no oversized contact damage at 45 pixels");
    pl.mobility_cooldown=0; pl.dodge_cooldown=0; global.gp_pressed=vk_control;
    before_x=pl.x; gp_player_step(pl);
    gp_check(pl.dodge_timer>0 && point_distance(before_x,500,pl.x,pl.y)>0,"control starts short dodge");
    mob.x=pl.x; mob.y=pl.y; pl.invulnerable_timer=0; hp_before=pl.hp;
    gp_check(!player_contact(pl,mob) && pl.hp==hp_before,"dodge blocks contact damage");
    gp_inputs_clear(); repeat(10) gp_player_step(pl);
    gp_check(pl.dodge_timer==0 && !player_is_protected(pl),"dodge protection ends with movement");
    global.gp_pressed=vk_control; gp_player_step(pl);
    gp_check(pl.dodge_timer==0,"dodge cannot chain during cooldown");
    gp_inputs_clear(); gp_clear_enemies();
    pl.motion_state=0; pl.dodge_timer=0;
    // Register all 12 abilities and upgrade to the definition's maximum.
    global.active_spells=[]; global.passive_spells=[]; global.hotbar=array_create(6,undefined);
    var ids=[101,102,103,104,105,106,201,202,203,204,205,206];
    var initial_max=pl.__base_max_hp;
    for(var si=0;si<12;si++) {
        var sid=ids[si], d=GetSpellData(sid);
        gp_check(is_struct(d) && sprite_exists(asset_get_index(d.icon_sprite_name)),"definition and icon "+string(sid));
        for(var lv=1;lv<=9;lv++) {
            gp_check(learn_spell(sid),"learn/upgrade "+string(sid)+" level "+string(lv));
            apply_passives(pl); apply_passives(pl);
            gp_check(string_length(spell_stats_text(sid,lv))>0,"computed tooltip "+string(sid));
        }
        gp_check(!learn_spell(sid),"max-level cap "+string(sid));
    }
    gp_check(array_length(global.active_spells)==6 && array_length(global.passive_spells)==6,"six active and six passive slots");
    gp_check(pl.player_power==pl.__base_player_power+18 && pl.moveSpeed==pl.__base_moveSpeed+4.5,"combined stable passives");
    gp_check(pl.max_hp==initial_max+108 && abs(pl.weapon_haste-0.72)<0.001 && pl.extra_projectiles==3,"vitality haste multishot values");
    var held_hp=pl.hp; apply_passives(pl); gp_check(pl.hp==held_hp,"vitality cannot repeatedly heal");
    for(var si=0;si<6;si++) gp_check(global.hotbar[si]==GetSpellData(ids[si]).name,"hotbar filled consistently");
    gp_check(!learn_spell(-99),"invalid definition rejected");
    if(global.gp_combo mod 3==0) bh_class_auto_check();
    gp_clear_enemies();
    var haste_target=instance_create_layer(pl.x+60,pl.y,"Instances",ObjectMonster); haste_target.hp=10000;
    pl.weapon_cooldown=0; with(pl) weapon_auto_step();
    gp_check(pl.weapon_cooldown==max(8,ceil(pl.weapon.cooldown/1.72)),"haste changes actual weapon interval");
    if(label!="Sword") gp_check(instance_number(ObjectLightningball)==4,"multishot changes actual class weapon projectile count");
    gp_clear_enemies();
    // AOE measures three targets, including a boss, and excludes a distant target.
    gp_clear_enemies(); pl.x=300; pl.y=300;
    var a=instance_create_layer(450,300,"Instances",ObjectMonster); a.hp=1000;
    var b=instance_create_layer(480,310,"Instances",ObjectMonster); b.hp=1000;
    var boss=instance_create_layer(450,340,"Instances",ObjectBossMonster); boss.hp=1000;
    var far=instance_create_layer(750,300,"Instances",ObjectMonster); far.hp=1000;
    var fire=hotbar_find_active_by_name("Fireball"); fire.cooldown_timer=0;
    gp_check(cast_spell(fire),"fireball casts");
    var expected=spell_values(101,9).damage;
    var shot=instance_find(ObjectFireball,0); shot.x=450; shot.y=290;
    spell_projectile_hit(shot,a);
    gp_check(a.hp==1000-expected && b.hp==1000-expected && boss.hp==1000-expected && far.hp==1000,"fire explosion hits group and boss exactly once");
    gp_check(a.burn_time>0 && b.burn_time>0 && boss.burn_time>0,"AOE ignites every affected target");
    gp_check(!cast_spell(fire),"spell cooldown blocks duplicate cast");
    gp_clear_enemies();
    var ice_target=instance_create_layer(pl.x+55,pl.y,"Instances",ObjectMonster); ice_target.hp=1000;
    var frost=hotbar_find_active_by_name("Frost Nova"); frost.cooldown_timer=0;
    gp_check(cast_spell(frost) && ice_target.hp<1000 && ice_target.slow_time==90,"nova damages and applies slow");
    var heal=hotbar_find_active_by_name("Healing Pulse"); heal.cooldown_timer=0;
    pl.hp=1; var heal_value=spell_values(106,9).damage; cast_spell(heal);
    gp_check(pl.hp==min(pl.max_hp,1+heal_value),"healing restores exact HP");
    heal.cooldown_timer=0; pl.hp=pl.max_hp-1; cast_spell(heal); gp_check(pl.hp==pl.max_hp,"healing respects max HP");
    gp_clear_enemies();
    var chilled=instance_create_layer(500,300,"Instances",ObjectMonster); chilled.hp=1000;
    var ice=hotbar_find_active_by_name("Iceball"); ice.cooldown_timer=0; cast_spell(ice);
    var icy=instance_find(ObjectIceball,0); var ice_damage=icy.damage;
    spell_projectile_hit(icy,chilled);
    gp_check(chilled.hp==1000-ice_damage && chilled.slow_time==60 && chilled.slow_factor==0.5,"iceball deals exact damage and applies slow");
    chilled.chase_vx=0; chilled.chase_vy=0;
    with(chilled) repeat(61) enemy_pursue();
    gp_check(chilled.slow_time==0,"slow expires through actual pursuit updates");
    chilled.shock_time=24; with(chilled) repeat(24) enemy_pursue();
    gp_check(chilled.shock_time==0,"shock expires through actual pursuit updates");
    chilled.burn_time=60; chilled.burn_dps=1; chilled.hp=1000;
    with(chilled) repeat(60) event_perform(ev_step,0);
    gp_check(abs(chilled.hp-999)<0.001 && chilled.burn_time==0,"burn deals exact total and expires");
    gp_clear_enemies();
    var barrage_target=instance_create_layer(550,300,"Instances",ObjectMonster); barrage_target.hp=1000;
    var barrage=hotbar_find_active_by_name("Arcane Barrage"); barrage.cooldown_timer=0; cast_spell(barrage);
    gp_check(instance_number(ObjectLightningball)==6,"barrage plus multishot generates six real projectiles");
    var victim=instance_create_layer(500,300,"Instances",ObjectMonster); victim.hp=1000;
    var pr=instance_find(ObjectLightningball,0); var dmg=pr.damage;
    spell_projectile_hit(pr,victim); gp_check(victim.hp==1000-dmg,"arcane projectile deals real damage");
    gp_clear_enemies();
    victim=instance_create_layer(500,300,"Instances",ObjectMonster); victim.hp=1000;
    var lightning=hotbar_find_active_by_name("Lightning"); lightning.cooldown_timer=0; cast_spell(lightning);
    pr=instance_find(ObjectLightningball,0); spell_projectile_hit(pr,victim);
    gp_check(victim.shock_time==24,"lightning applies actual shock status");
    // Draw the real GUI into an offscreen target; export pixels via log, no OS input.
    if(global.gp_combo==0) {
        global.game_over=true;
        var surf=surface_create(800,600); surface_set_target(surf); draw_clear(c_black); display_set_gui_size(800,600);
        round_menu_draw(); surface_reset_target();
        var pixels=buffer_create(800*600*4,buffer_fixed,1); buffer_get_surface(pixels,surf,0);
        var zipped=buffer_compress(pixels,0,800*600*4); show_debug_message("GAMEPLAY_RGBA "+buffer_base64_encode(zipped,0,buffer_get_size(zipped))); buffer_delete(zipped);
        buffer_delete(pixels); surface_free(surf); global.game_over=false;
    }
    gp_clear_enemies();
    if(global.gp_combo==0 && !global.gp_did_restart) {
        pl.x=300; pl.y=330;
        var e=instance_create_layer(375,330,"Instances",ObjectMonster);
        e.burn_time=60; e.slow_time=60; e.shock_time=24; e.hp=40;
        var slash=instance_create_layer(pl.x,pl.y,"Instances",ObjectSwordHitbox);
        slash.owner=pl; slash.direction=0; slash.x=pl.x; slash.y=pl.y-10;
        var surface=surface_create(800,600); surface_set_target(surface); draw_clear(make_color_rgb(28,42,38));
        with(pl) event_perform(ev_draw,0);
        with(e) event_perform(ev_draw,0);
        with(slash) event_perform(ev_draw,0);
        with(ObjectOverlay) event_perform(ev_draw,64);
        surface_reset_target(); gp_capture(surface,"combat"); surface_free(surface);
        with(e) instance_destroy(); with(slash) instance_destroy();
    }
}
function gp_capture(_surface,_name) {
    var pixels=buffer_create(800*600*4,buffer_fixed,1); buffer_get_surface(pixels,_surface,0);
    var zipped=buffer_compress(pixels,0,800*600*4);
    show_debug_message("GAMEPLAY_IMAGE "+_name+" "+buffer_base64_encode(zipped,0,buffer_get_size(zipped)));
    buffer_delete(zipped); buffer_delete(pixels);
}
function gp_controller_tick() {
    gp_inputs_clear();
    if(global.gp_stage==0) {
        var levels=[Room1,RoomCrypt,RoomRuins];
        gp_check(room==levels[global.gp_combo mod 3],"correct room combo "+string(global.gp_combo));
        gp_check(instance_exists(ObjectPlayer),"player exists combo "+string(global.gp_combo));
        gp_check(!instance_exists(ObjectBossMonster) && instance_number(ObjectFireball)==0,"no authored boss or spell before scheduled progression");
        gp_check(array_length(global.active_spells)==0,"all six slots initially empty");
        gp_check(ObjectPlayer.weapon.kind==weapon_definition(global.selected_character).kind,"independent class weapon initialized");
        global.gp_stage=1; return;
    }
    if(global.gp_stage==1) {
        gp_check(!global.game_paused && !global.start_choice_pending && array_length(global.spell_options)==0,"no selection before first level-up");
        gp_check(array_length(global.active_spells)==0 && array_length(global.passive_spells)==0,"both slot groups empty at start");
        global.coins=global.coins_needed;
        global.gp_stage=2; return;
    }
    if(global.gp_stage==2) {
        gp_check(global.current_level==2 && global.levelup_active && global.game_paused,"regular coins trigger first level-up selection");
        gp_check(array_length(global.spell_options)==3,"first level-up has three valid offers");
        global.gp_pressed=vk_space; global.gp_stage=3; return;
    }
    if(global.gp_stage==3) {
        gp_check(!global.game_paused && array_length(global.active_spells)+array_length(global.passive_spells)==1,"level-up selection registers one ability");
        gp_fixture();
        if(global.gp_combo==0 && !global.gp_did_restart) {bh_fixture(); af_fixture();}
        if(global.gp_combo==0 && !global.gp_did_restart) {
            global.gp_did_restart=true; global.game_over=true; global.game_paused=true;
            // Click the actual restart button using the shared input/layout path.
            var ui=menu_geometry(2); global.gp_gui_mx=ui.x+20; global.gp_gui_my=ui.y+20; global.gp_mouse_click=true;
            round_menu_step(); global.gp_stage=0; return;
        }
        global.game_over=true; global.game_paused=true;
        var ui=menu_geometry(2); global.gp_gui_mx=ui.x+20; global.gp_gui_my=ui.y+62+20; global.gp_mouse_click=true;
        round_menu_step();
        global.gp_combo++; global.gp_stage=0;
    }
}
