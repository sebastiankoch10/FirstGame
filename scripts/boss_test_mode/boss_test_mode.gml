/// Development-only menu; change this macro to false for a release without the test menu.
#macro BOSS_TEST_MENU_ENABLED true
function boss_test_enabled() {return BOSS_TEST_MENU_ENABLED;}
function boss_test_settings() {
    if(!variable_global_exists("boss_test_menu_config"))global.boss_test_menu_config={mode:"boss",boss:"storm_warden",minute:15,class_name:"Sword",seed:1337,random_build:false,difficulty_index:1,attack:0,message:"",
        level:0,scene_minute:5,build:1,spell:0,spell_level:9,gear:0,enemies:0};
    return global.boss_test_menu_config;
}
function boss_test_preset(_minute) {
    // Calibrated 26.11. to the measured bot cohorts (median level per minute, QA/tools/analyze_levels.py; user approved).
    // decisions = spell steps at that minute. Bots, not humans: re-check with real run samples (progression_audit).
    if(_minute<=5)return {level:17,decisions:19};
    if(_minute<=10)return {level:33,decisions:38};
    if(_minute<=15)return {level:51,decisions:53};
    if(_minute<=20)return {level:70,decisions:77};
    if(_minute<=25)return {level:87,decisions:95};
    return {level:100,decisions:108};
}
function boss_test_bosses() {
    var source=boss_v2_catalog(),out=[];
    for(var i=0;i<array_length(source);i++){var d=variable_clone(source[i]);d.implemented=boss_v2_available(d);array_push(out,d);}
    var mini=boss_definition("mini_sentinel");if(is_struct(mini))array_push(out,{id:mini.id,name:mini.name,implemented:true,abilities:[],main:false});
    array_push(out,{id:"random",name:"Zufaelliger Hauptboss",implemented:true,abilities:[],main:true});
    return out;
}
function boss_test_definition(_id) {
    var list=boss_test_bosses();for(var i=0;i<array_length(list);i++)if(list[i].id==_id)return list[i];return undefined;
}
function boss_test_rand(_limit) {global.boss_test_rng=(global.boss_test_rng*16807) mod 2147483647;return floor(global.boss_test_rng/2147483647*max(1,_limit));}
function boss_test_request(_boss,_minute,_class,_seed,_ability=-1,_random_build=false,_difficulty=1) {
    var seed=clamp(floor(abs(_seed)),1,2147483646);global.boss_test_rng=seed;
    var chosen=_boss;
    if(chosen=="random") {
        var options=[],defs=boss_v2_catalog();for(var i=0;i<array_length(defs);i++)if(boss_v2_available(defs[i]))array_push(options,defs[i].id);
        if(array_length(options)==0)return undefined;chosen=options[boss_test_rand(array_length(options))];
    }
    var definition=boss_test_definition(chosen);if(!is_struct(definition) || !definition.implemented)return undefined;
    var actor=_class;if(actor=="random"){var classes=["Sword","Mage","Ranger"];actor=classes[boss_test_rand(3)];}
    if(!array_contains(["Sword","Mage","Ranger"],actor))actor="Sword";
    var minute=clamp(floor(_minute),5,30),count=boss_v2_ability_count(minute*60);
    if(_ability!=-1 && (!is_real(_ability) || _ability<1 || _ability>min(count,array_length(definition.abilities))))return undefined;
    return {boss:chosen,minute:minute,class_name:actor,seed:seed,ability:_ability,random_build:_random_build,difficulty_multiplier:clamp(_difficulty,.5,2)};
}
function boss_test_start(_boss="storm_warden",_minute=15,_class="Sword",_seed=1337,_ability=-1,_random_build=false,_difficulty=1) {
    if(!boss_test_enabled())return false;
    var request=boss_test_request(_boss,_minute,_class,_seed,_ability,_random_build,_difficulty);if(!is_struct(request))return false;
    var existing=variable_global_exists("boss_test") && is_struct(global.boss_test) && global.boss_test.active;
    request.restore_character=existing ? global.boss_test.restore_character : (variable_global_exists("selected_character") ? global.selected_character : "Sword");
    request.restore_level=existing ? global.boss_test.restore_level : (variable_global_exists("selected_level") ? global.selected_level : 0);
    global.boss_test_pending=request;global.selected_character=request.class_name;global.selected_level=0;
    if(room==Room1 && instance_exists(ObjectPlayer)) {reset_round();return boss_test_pending_start();}
    global.menu_transition_lock=true;room_goto(Room1);return true;
}
function boss_test_add_skill(_sid) {
    var d=GetSpellData(_sid);if(!is_struct(d) || !d.implemented || !spell_passive_eligible(d))return false;
    var list=d.type==1 ? global.active_spells : global.passive_spells;
    for(var i=0;i<array_length(list);i++)if(list[i].id==_sid){if(list[i].level>=9)return false;list[i].level++;return true;}
    if(array_length(list)>=6)return false;
    array_push(list,{id:_sid,name:d.name,type:d.type==1 ? "active" : "passive",level:1,cooldown:d.type==1 ? d.cooldown : 0,cooldown_timer:0});
    if(d.type==1){global.active_spells=list;hotbar_assign_for_spell(d.name);}else global.passive_spells=list;
    return true;
}
function boss_test_apply_build(_minute,_random_build,_seed) {
    global.active_spells=[];global.passive_spells=[];global.hotbar=array_create(6,undefined);hotbar_init();global.choice_rng=_seed;
    var preset=boss_test_preset(_minute),budget=preset.decisions;
    if(_random_build) {
        for(var i=0;i<budget;i++) {
            spell_choices_v2("chest");var options=global.spell_options;
            if(array_length(options)==0)break;var option=options[spell_choice_random(array_length(options))];if(option.id<0)break;
            if(!boss_test_add_skill(option.id))break;
        }
    } else {
        var ids=[101,103,105,106,107,118,202,204,205,207,209,210];
        for(var i=0;i<budget;i++)boss_test_add_skill(ids[i mod array_length(ids)]);
    }
    global.current_level=preset.level;global.levelup_active=false;global.chest_collected=false;global.game_paused=false;global.normal_pause_active=false;global.choice_open=false;global.spell_options=[];
    global.coins=0;global.coins_needed=progression_cost(global.current_level);global.next_levelup_time=1000000000;
    apply_passives(ObjectPlayer);ObjectPlayer.hp=ObjectPlayer.max_hp;ObjectPlayer.hud_hp_trail=ObjectPlayer.hp;
}
function boss_test_pending_start() {
    if(!variable_global_exists("boss_test_pending") || !is_struct(global.boss_test_pending) || !instance_exists(ObjectPlayer))return false;
    var request=global.boss_test_pending;global.boss_test_pending=undefined;
    if(variable_struct_exists(request,"scene") && request.scene){var scene_ok=scene_test_pending_start(request);review_after_start(scene_ok);return scene_ok;}
    with(ObjectBossMonster)instance_destroy();with(ObjectMonster)instance_destroy();with(ObjectChest)instance_destroy();with(ObjectCoin)instance_destroy();with(ObjectMagnetOrb)instance_destroy();
    with(ObjectFireball)instance_destroy();with(ObjectIceball)instance_destroy();with(ObjectLightningball)instance_destroy();with(ObjectSwordHitbox)instance_destroy();
    global.boss_test={active:true,boss:request.boss,minute:request.minute,class_name:request.class_name,seed:request.seed,ability:request.ability,invulnerable:false,difficulty_multiplier:request.difficulty_multiplier,restore_character:request.restore_character,restore_level:request.restore_level,attack_log:[],debug_hitboxes:false};
    global.round_seconds=request.minute*60;global.round_active=true;global.game_over=false;global.game_paused=false;
    global.boss_rng=request.seed;global.choice_rng=request.seed;random_set_seed(request.seed);
    global.monster_hp_multiplier=global.base_monster_hp_multiplier*(1+request.minute*.07);
    global.monster_damage_multiplier=global.base_monster_damage_multiplier*(1+request.minute*.06);
    global.boss_spawned=array_create(8,true);global.hostile_bullets=[];global.boss_zones=[];global.bv2_hazards=[];global.active_boss=noone;global.boss_exists=false;
    if(instance_exists(ObjectSpawner))ObjectSpawner.population_timer=1000000000;
    boss_test_apply_build(request.minute,request.random_build,request.seed);
    var boss=boss_spawn(request.boss);if(!instance_exists(boss)){boss_test_end();return false;}
    if(request.ability!=-1)boss_v2_force_attack(boss,request.ability);
    show_debug_message("BOSS_TEST_START "+json_stringify({boss:request.boss,minute:request.minute,seed:request.seed,class_name:request.class_name,ability:request.ability,difficulty_multiplier:request.difficulty_multiplier}));
    review_after_start(true); // review scenario overrides (no-op outside the Review Center)
    return true;
}
function boss_test_end() {
    if(variable_global_exists("boss_test") && is_struct(global.boss_test) && global.boss_test.active) {
        global.selected_character=global.boss_test.restore_character;global.selected_level=global.boss_test.restore_level;global.boss_test.active=false;
    }
    global.boss_test_pending=undefined;
}
function boss_test_tick(_dt) {
    if(!variable_global_exists("boss_test") || !is_struct(global.boss_test) || !global.boss_test.active)return;
    var state=global.boss_test;
    if(keyboard_check_pressed(vk_f1))state.invulnerable=!state.invulnerable;
    if(keyboard_check_pressed(vk_f2) && instance_exists(ObjectPlayer)){
        ObjectPlayer.hp=ObjectPlayer.max_hp;ObjectPlayer.hud_hp_trail=ObjectPlayer.hp;
        if(global.game_over){global.game_over=false;global.game_paused=false;global.normal_pause_active=false;global.pause_initialized=false;instance_activate_all();fg_music_set(instance_exists(global.active_boss) ? "boss" : "level");}
    }
    var boss=global.active_boss;
    if(instance_exists(boss)) {
        if(keyboard_check_pressed(vk_f3)){var next=(boss.boss_phase mod 4)+1;boss.hp=boss.max_hp*(next==1 ? 1 : (next==2 ? .74 : (next==3 ? .49 : .24)));}
        if(keyboard_check_pressed(vk_f4))boss.hp=max(1,boss.max_hp*.25);
        if(keyboard_check_pressed(vk_f5) && state.ability!=-1)boss_v2_force_attack(boss,state.ability);
        // F6: cycle the forced ability (Rotation -> 1 .. unlocked); F7: allow the announced catch-up move at the next pause.
        if(keyboard_check_pressed(vk_f6) && variable_instance_exists(boss,"v2_unlocked")){state.ability=state.ability>=boss.v2_unlocked ? -1 : (state.ability==-1 ? 1 : state.ability+1);if(state.ability!=-1)boss_v2_force_attack(boss,state.ability);}
        if(keyboard_check_pressed(vk_f7) && variable_instance_exists(boss,"bc_far_time")){boss.bc_far_time=99;boss.bc_catch_cd=0;}
    }
    // F8: +5 talent points, F9: an epic test item next to the player (development only).
    if(keyboard_check_pressed(vk_f8))talent_grant(5,"Bosstest");
    if(keyboard_check_pressed(vk_f9) && instance_exists(ObjectPlayer))equipment_drop(ObjectPlayer.x+50,ObjectPlayer.y+20,equipment_generate(equipment_random_slot(),3,equipment_item_level()+2));
    if(keyboard_check_pressed(vk_f10))state.debug_hitboxes=!state.debug_hitboxes;
}
function boss_test_draw_gui() {
    if(!variable_global_exists("boss_test") || !is_struct(global.boss_test) || !global.boss_test.active)return;
    var state=global.boss_test;draw_set_font(-1);draw_set_halign(fa_left);draw_set_valign(fa_top);draw_set_color(make_color_rgb(167,222,220));
    var scene=variable_struct_exists(state,"scene") && state.scene;
    var lnames=level_names();
    if(review_active())draw_text_transformed(12,display_get_gui_height()-62,"REVIEW | "+global.review.title+" | Rev. "+string(global.review.revision)+" | Esc: pruefen und freigeben",.7,.7,0);
    if(review_active() && global.review.note_t>0){draw_set_color(make_color_rgb(126,224,140));draw_text_transformed(12,display_get_gui_height()-82,global.review.note,.75,.75,0);draw_set_color(make_color_rgb(167,222,220));}
    draw_text_transformed(12,display_get_gui_height()-43,scene ? "TESTSZENE | "+lnames[clamp(global.selected_level,0,array_length(lnames)-1)]+" | ab Minute "+string(state.minute)+" | Seed "+string(state.seed)
        : "BOSSTEST | "+state.boss+" | Min "+string(state.minute)+" | Seed "+string(state.seed)+" | "+(state.ability==-1 ? "Rotation" : "Attacke "+string(state.ability))
        +(instance_exists(global.active_boss) && bc_seq_label(global.active_boss)!="" ? " | Sequenz "+bc_seq_label(global.active_boss) : ""),.7,.7,0);
    draw_text_transformed(12,display_get_gui_height()-24,"F1 Schutz "+(state.invulnerable ? "EIN" : "AUS")+" | F2 Heilen | F3 Phase | F4 HP25% | F5 Attacke | F6 Attacke wechseln | F7 Aufholen | F8 Talente | F9 Gegenstand | F10 Koerperboxen",.65,.65,0);
    if(state.debug_hitboxes && instance_exists(ObjectPlayer)) {
        var camera=ObjectPlayer.camera,view_x=camera_get_view_x(camera),view_y=camera_get_view_y(camera),sx=display_get_gui_width()/camera_get_view_width(camera),sy=display_get_gui_height()/camera_get_view_height(camera);
        draw_set_color(make_color_rgb(255,111,149));
        with(ObjectBossMonster)draw_rectangle((bbox_left-view_x)*sx,(bbox_top-view_y)*sy,(bbox_right-view_x)*sx,(bbox_bottom-view_y)*sy,true);
        draw_set_color(make_color_rgb(122,227,222));
        with(ObjectPlayer)draw_rectangle((bbox_left-view_x)*sx,(bbox_top-view_y)*sy,(bbox_right-view_x)*sx,(bbox_bottom-view_y)*sy,true);
        // weapon attachment point of the current frame (eqv_attach): grip (cyan; orange = hand hidden) and direction to the tip
        var plr=ObjectPlayer;
        if(variable_instance_exists(plr,"visual_actor")) {
            var at=eqv_attach(plr.visual_actor,plr.visual_sprite_index,plr.visual_frame_index,plr.x,plr.y,plr.visual_mirror<0 ? -1 : 1,1);
            if(at.ok){var gx=(at.x-view_x)*sx,gy=(at.y-view_y)*sy;draw_set_color(make_color_rgb(255,80,220));draw_line_width(gx,gy,gx+lengthdir_x(at.length*sx,at.angle),gy+lengthdir_y(at.length*sy,at.angle),2);
                draw_set_color(at.conf>0 ? make_color_rgb(90,240,255) : make_color_rgb(255,160,40));draw_circle(gx,gy,4,false);}
        }
    }
    draw_set_color(c_white);
}
function boss_test_menu_labels() {
    var s=boss_test_settings(),actor=s.class_name=="Mage" ? "Arkanistin" : (s.class_name=="Ranger" ? "Waldlaeufer" : (s.class_name=="random" ? "Zufaellig" : "Schwertmeister"));
    if(s.mode=="scene") {
        var spells=scene_test_spells(),names=level_names(),spell="Keiner";
        if(s.spell>0){var sd=GetSpellData(spells[s.spell-1]);spell=sd.name;}
        return ["Modus: Freie Szene","Level: "+names[s.level],"Spielminute: "+string(s.scene_minute),"Klasse: "+actor,"Build: "+["Leer","Ausgewogen","Zufaellig (gueltig)"][s.build],
            "Zauber dazu: "+spell,"Zauberstufe: "+string(s.spell_level),"Ausruestung: "+["Keine","Magisch","Selten","Episch"][s.gear],"Gegner: "+["Normal","Keine"][s.enemies],"Szene starten","Zurueck"];
    }
    var d=boss_test_definition(s.boss),name=is_struct(d) ? d.name : s.boss;
    if(is_struct(d) && !d.implemented)name+=" [noch nicht verfuegbar]";
    var attack="Gesamtkampf",count=boss_v2_ability_count(s.minute*60);
    if(is_struct(d) && s.attack>0 && s.attack<=min(count,array_length(d.abilities)))attack=d.abilities[s.attack-1].name;
    return ["Modus: Bosskampf","Boss: "+name,"Spielminute: "+string(s.minute)+" / "+string(count)+" Faehigkeiten","Klasse: "+actor,"Build: "+(s.random_build ? "Zufaellig (gueltig)" : "Ausgewogen"),"Schwierigkeit: "+["Leicht","Normal","Hart"][s.difficulty_index],"Angriff: "+attack,"Seed: "+string(s.seed)+" (Ziffern tippen / R neu)","Test starten","Direkt: Drache / Minute 15 / alle neun","Zurueck"];
}
/// Active spells offered in the scene test (ids from the catalog, implemented only).
function scene_test_spells() {
    var out=[];for(var id_=101;id_<=118;id_++){var d=GetSpellData(id_);if(is_struct(d) && d.implemented)array_push(out,id_);}
    return out;
}
/// Row of the seed field (digits are typed there), -1 in the scene mode.
function boss_test_seed_row() {return boss_test_settings().mode=="scene" ? -1 : 7;}
function boss_test_menu_change(_row,_delta=1) {
    var s=boss_test_settings();s.message="";
    if(_row==0){s.mode=s.mode=="scene" ? "boss" : "scene";menu_index=0;return;}
    if(_row==3){var classes=["Sword","Mage","Ranger","random"],index=0;for(var i=0;i<4;i++)if(classes[i]==s.class_name)index=i;s.class_name=classes[(index+4+_delta) mod 4];return;}
    if(s.mode=="scene") {
        switch(_row) {
            case 1:s.level=(s.level+level_count()+_delta) mod level_count();break;
            case 2:var minutes=[0,1,3,5,10,15,20,25,30],index=0;for(var i=0;i<9;i++)if(minutes[i]==s.scene_minute)index=i;s.scene_minute=minutes[(index+9+_delta) mod 9];break;
            case 4:s.build=(s.build+3+_delta) mod 3;break;
            case 5:var n=array_length(scene_test_spells())+1;s.spell=(s.spell+n+_delta) mod n;break;
            case 6:var levels=[1,3,5,7,9],index=0;for(var i=0;i<5;i++)if(levels[i]==s.spell_level)index=i;s.spell_level=levels[(index+5+_delta) mod 5];break;
            case 7:s.gear=(s.gear+4+_delta) mod 4;break;
            case 8:s.enemies=(s.enemies+2+_delta) mod 2;break;
            case 9:if(!scene_test_start(s))s.message="Die Szene konnte nicht gestartet werden.";break;
            case 10:menu_mode="main";menu_index=3;break;
        }
        return;
    }
    switch(_row) {
        case 1:var defs=boss_test_bosses(),index=0;for(var i=0;i<array_length(defs);i++)if(defs[i].id==s.boss)index=i;s.boss=defs[(index+array_length(defs)+_delta) mod array_length(defs)].id;s.attack=0;break;
        case 2:var minutes=[5,10,15,20,25,30],index=0;for(var i=0;i<6;i++)if(minutes[i]==s.minute)index=i;s.minute=minutes[(index+6+_delta) mod 6];s.attack=0;break;
        case 4:s.random_build=!s.random_build;break;
        case 5:s.difficulty_index=(s.difficulty_index+3+_delta) mod 3;break;
        case 6:var d=boss_test_definition(s.boss),count=is_struct(d) ? min(boss_v2_ability_count(s.minute*60),array_length(d.abilities)) : 0;s.attack=(s.attack+count+1+_delta) mod (count+1);break;
        case 7:s.seed=clamp(s.seed+_delta,1,999999999);keyboard_string=string(s.seed);break;
        case 8:if(!boss_test_start(s.boss,s.minute,s.class_name,s.seed,s.attack==0 ? -1 : s.attack,s.random_build,[.8,1,1.25][s.difficulty_index]))s.message="Diese Begegnung oder Attacke ist noch nicht verfuegbar.";break;
        case 9:boss_test_start("storm_warden",15,s.class_name,s.seed,-1,s.random_build,[.8,1,1.25][s.difficulty_index]);break;
        case 10:menu_mode="main";menu_index=3;break;
    }
}
/// Free scene (development): any level, minute, class, build, one extra spell at a chosen level, a full equipment set.
function scene_test_start(_s) {
    if(!boss_test_enabled())return false;
    var actor=_s.class_name;if(actor=="random"){var classes=["Sword","Mage","Ranger"];actor=classes[irandom(2)];}
    var existing=variable_global_exists("boss_test") && is_struct(global.boss_test) && global.boss_test.active;
    var spells=scene_test_spells();
    global.boss_test_pending={scene:true,level:_s.level,minute:_s.scene_minute,class_name:actor,seed:_s.seed,build:_s.build,
        spell:_s.spell==0 ? -1 : spells[_s.spell-1],spell_level:_s.spell_level,gear:_s.gear,enemies:_s.enemies,
        restore_character:existing ? global.boss_test.restore_character : global.selected_character,restore_level:existing ? global.boss_test.restore_level : global.selected_level};
    global.selected_character=actor;global.selected_level=_s.level;global.menu_transition_lock=true;
    reset_round();room_goto(level_room(_s.level));return true;
}
function scene_test_pending_start(_r) {
    global.boss_test={active:true,scene:true,boss:"Szene",minute:_r.minute,class_name:_r.class_name,seed:_r.seed,ability:-1,invulnerable:false,difficulty_multiplier:1,
        restore_character:_r.restore_character,restore_level:_r.restore_level,attack_log:[],debug_hitboxes:false};
    random_set_seed(_r.seed);global.choice_rng=_r.seed;global.round_seconds=_r.minute*60;global.round_active=true;global.game_over=false;global.game_paused=false;
    if(_r.build==0){global.active_spells=[];global.passive_spells=[];global.hotbar=array_create(6,undefined);hotbar_init();}
    else boss_test_apply_build(max(5,_r.minute),_r.build==2,_r.seed);
    if(_r.spell>0) {
        // make room for the chosen spell, then raise it to the chosen level
        var have=false;for(var i=0;i<array_length(global.active_spells);i++)if(global.active_spells[i].id==_r.spell)have=true;
        if(!have && array_length(global.active_spells)>=6){array_delete(global.active_spells,5,1);global.hotbar=array_create(6,undefined);hotbar_init();for(var i=0;i<array_length(global.active_spells);i++)hotbar_assign_for_spell(global.active_spells[i].name);}
        for(var i=0;i<9;i++){var lv=0;for(var j=0;j<array_length(global.active_spells);j++)if(global.active_spells[j].id==_r.spell)lv=global.active_spells[j].level;if(lv>=_r.spell_level)break;boss_test_add_skill(_r.spell);}
    }
    if(_r.gear>0){var slots=equipment_slots();for(var i=0;i<array_length(slots);i++)equipment_equip(equipment_generate(slots[i],_r.gear,equipment_item_level()+_r.gear));}
    if(_r.enemies==1){with(ObjectMonster)instance_destroy();if(instance_exists(ObjectSpawner))ObjectSpawner.population_timer=1000000000;}
    apply_passives(ObjectPlayer);ObjectPlayer.hp=ObjectPlayer.max_hp;ObjectPlayer.hud_hp_trail=ObjectPlayer.hp;
    show_debug_message("SCENE_TEST_START "+json_stringify({level:_r.level,minute:_r.minute,class_name:_r.class_name,spell:_r.spell,spell_level:_r.spell_level,gear:_r.gear,enemies:_r.enemies}));
    return true;
}
function boss_test_menu_geometry() {return {x:24,y:92,w:display_get_gui_width()-48,h:38,gap:6};}
function boss_test_menu_step() {
    var s=boss_test_settings(),previous=menu_index,ui=boss_test_menu_geometry(),count=11,seed_row=boss_test_seed_row();
    if(keyboard_check_pressed(vk_escape)){fg_sfx("ui_back");menu_mode="main";menu_index=3;return;}
    if(keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W")))menu_index=(menu_index+count-1) mod count;
    if(keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S")))menu_index=(menu_index+1) mod count;
    var mx=device_mouse_x_to_gui(0),my=device_mouse_y_to_gui(0),hover=-1;
    for(var i=0;i<count;i++)if(point_in_rectangle(mx,my,ui.x,ui.y+i*(ui.h+ui.gap),ui.x+ui.w,ui.y+i*(ui.h+ui.gap)+ui.h))hover=i;
    if(hover>=0)menu_index=hover;fg_audio_hover(previous,menu_index);
    if(menu_index==seed_row) {
        if(previous!=seed_row)keyboard_string=string(s.seed);
        if(keyboard_check_pressed(ord("R"))){s.seed=irandom_range(1,999999999);keyboard_string=string(s.seed);}
        var digits="";for(var i=1;i<=string_length(keyboard_string);i++){var c=string_char_at(keyboard_string,i);if(ord(c)>=48 && ord(c)<=57)digits+=c;}
        digits=string_copy(digits,1,9);if(digits!="")s.seed=max(1,real(digits));keyboard_string=digits;
    }
    if(keyboard_check_pressed(vk_left))boss_test_menu_change(menu_index,-1);
    if(keyboard_check_pressed(vk_right)){fg_sfx("ui_click");boss_test_menu_change(menu_index,1);}
    else if(keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || (mouse_check_button_pressed(mb_left) && hover>=0)){fg_sfx("ui_click");if(menu_index!=seed_row)boss_test_menu_change(menu_index,1);}
}
function boss_test_menu_draw() {
    var s=boss_test_settings(),ui=boss_test_menu_geometry(),labels=boss_test_menu_labels();
    draw_set_alpha(1);draw_set_color(make_color_rgb(10,16,22));draw_rectangle(0,0,display_get_gui_width(),display_get_gui_height(),false);
    draw_set_font(-1);draw_set_halign(fa_center);draw_set_valign(fa_middle);draw_set_color(make_color_rgb(218,186,112));draw_text(display_get_gui_width()*.5,33,"TESTMODUS - ENTWICKLUNG");
    draw_set_color(make_color_rgb(166,192,205));draw_text_transformed(display_get_gui_width()*.5,62,"Links / Rechts aendert Werte. Enter oder Klick bestaetigt.",.8,.8,0);
    for(var i=0;i<array_length(labels);i++) {
        var yy=ui.y+i*(ui.h+ui.gap);spell_ui_panel(ui.x,yy,ui.w,ui.h,i==menu_index);
        draw_set_halign(fa_left);var go=s.mode=="scene" ? i==9 : (i==8 || i==9);draw_set_color(go ? make_color_rgb(238,207,133) : (i==0 ? make_color_rgb(167,222,220) : c_white));
        var scale=min(.9,(ui.w-24)/max(1,string_width(labels[i])));draw_text_transformed(ui.x+12,yy+ui.h*.5,labels[i],scale,scale,0);
    }
    draw_set_color(make_color_rgb(198,155,170));draw_set_halign(fa_left);draw_text_transformed(24,display_get_gui_height()-36,s.message=="" ? (s.mode=="scene" ? "Freie Szene: ohne Bosse; im Spiel F1 Schutz, F2 Heilen, F8 Talente, F9 Gegenstand, F10 Koerperboxen." : "Test-Presets ersetzen nur diese Entwicklungsrunde.")+" Escape: zurueck." : s.message,.75,.75,0);draw_set_color(c_white);
}
