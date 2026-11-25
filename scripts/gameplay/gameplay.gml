/// Independent weapons, movement/contact rules, common menus and bounded effects.
// World camera size in world units: 16:9 like the window, so pixels stay square (was 800x600 = 4:3 stretched to 16:9).
// 960x540 scales by exactly 2 at 1080p. See docs/Design/Technische Architektur.md, R1.
#macro VIEW_W 960
#macro VIEW_H 540
function combat_mask() {
    if (!variable_global_exists("body_mask") || !sprite_exists(global.body_mask)) {
        global.body_mask=sprite_duplicate(spr_fg_swordsmanv3_idle_right);
        // Same physical offsets (-10,-29)..(10,-7) around the foot origin, whatever the art canvas is
        // (was hard-coded 38,59..58,81 for the 96 px frame; the density switch moved the origin to 80,145).
        var ox=sprite_get_xoffset(global.body_mask),oy=sprite_get_yoffset(global.body_mask);
        sprite_collision_mask(global.body_mask,false,2,ox-10,oy-29,ox+10,oy-7,2,0);
    }
    return global.body_mask;
}
function weapon_definition(_class) {
    switch(_class) {
        case "Mage": return {name:"Sternenstab",damage:25,power_scale:1,cooldown:96,range:480,kind:"wand",speed:10};
        case "Ranger": return {name:"Waldbogen",damage:6,power_scale:0.5,cooldown:18,range:580,kind:"bolt",speed:16};
        default: return {name:"Schwert",damage:18,power_scale:1.5,cooldown:44,range:116,kind:"sword",speed:0};
    }
}
function player_combat_init() {
    weapon=weapon_definition(global.selected_character);
    weapon_cooldown=0; attack_timer=0; attack_direction=0;
    class_weapon_init();
    boss_root_time=0;boss_poison_time=0;boss_poison_dps=0;boss_poison_tick=0;
    attack_duration=18;sword_combo_active=false;sword_combo_clock=0;sword_combo_event=0;
    spell_area=1;spell_cdr=1;projectile_factor=1;crit_chance=0;crit_damage=1.6;split_bonus=0;
    fire_bonus=0;cold_bonus=0;storm_bonus=0;armor_flat=0;regen_rate=0;regen_clock=0;pickup_radius=96;status_factor=1;resonance=0;
    dodge_timer=0; dodge_cooldown=0; dodge_direction=0;
    mobility_cooldown=0; motion_protected=false;
    mouse_move_armed=false; menu_input_guard=1;
    weapon_haste=0; extra_projectiles=0; passive_hp_bonus=0;
    weapon_damage_mult=1;weapon_range_mult=1;extra_hp_bonus=0;sword_charge_until=-1;sword_charge_mult=1;sword_whirl_chain=false;last_stand_until=-1;
    __base_max_hp=max_hp;
    health_visible_time=0;last_damage_taken=0;
    jump_time=0;jump_second_used=false;dive_time=0;dive_start_height=0;dodge_elapsed=0;
    hud_hp_trail=hp; hud_damage_hold=0; hud_hit_flash=0;
    player_scale=1; // art is drawn 1:1 since the density switch (was 1.65 with 96 px frames)
    mask_index=combat_mask();
    collision_half_width=11; collision_half_height=12;
    contact_radius=10;
}
function combat_nearest(_pl,_range) {
    var target=noone, best=_range+0.001;
    var types=[ObjectMonster,ObjectBossMonster];
    for(var t=0;t<2;t++) {
        for(var i=0;i<instance_number(types[t]);i++) {
            var e=instance_find(types[t],i);
            if (e.hp<=0 || !combat_target_visible(e)) continue;
            var dist=combat_body_distance(e,_pl.x,_pl.y);
            if (dist<best) {best=dist; target=e;}
        }
    }
    return target;
}
function weapon_auto_step() {
    if(global.game_paused || global.game_over || hp<=0)return;
    if (weapon_cooldown>0) weapon_cooldown--;
    if (attack_timer>0) attack_timer--;
    if(weapon.kind!="sword") {class_weapon_auto_step();return;}
    if(weapon.kind=="sword") {
        if(sword_combo_active){master_sword_step();return;}
        if(weapon_cooldown>0)return;
        var sword_target=combat_nearest(id,weapon.range);
        if(instance_exists(sword_target))master_sword_start(sword_target);
        return;
    }
}

function player_is_protected(_pl) {
    return _pl.motion_state!=player_motion_state.grounded || _pl.dodge_timer>0;
}
function player_contact(_pl,_enemy) {
    if (global.game_paused || !instance_exists(_enemy) || _enemy.hp<=0) return false;
    if (player_is_protected(_pl)) return false;
    if(variable_instance_exists(_enemy,"hit_stun") && _enemy.hit_stun>0)return false;
    var authored=variable_instance_exists(_enemy,"lvl_kind");
    var skeleton=(variable_instance_exists(_enemy,"master_skeleton") && _enemy.master_skeleton) || authored;
    if(skeleton && !_enemy.skeleton_strike)return false;
    if(_enemy.object_index==ObjectBossMonster) {
        var xx=clamp(_pl.x,_enemy.bbox_left,_enemy.bbox_right),yy=clamp(_pl.y-10,_enemy.bbox_top,_enemy.bbox_bottom);
        if(point_distance(_pl.x,_pl.y-10,xx,yy)>_pl.contact_radius) return false;
    } else if (point_distance(_pl.x,_pl.y-10,_enemy.x,_enemy.y-10)>(authored ? _enemy.lvl_cfg.reach : (skeleton ? 43 : _pl.contact_radius+_enemy.contact_radius))) return false;
    if(variable_instance_exists(_enemy,"contact_next") && global.round_seconds<_enemy.contact_next) return false;
    if(!player_receive_damage(_pl,_enemy.damage)) return false;
    _enemy.contact_next=global.round_seconds+loot_config().contact_interval;return true;
}
function player_protected_from(_pl,_height) {
    if(_pl.dodge_timer>0) return true;
    if(_height=="all") return false;
    if(_height=="high") return _pl.motion_state==player_motion_state.sliding;
    return player_is_protected(_pl);
}
function player_receive_damage(_pl,_amount,_height="ground") {
    if(variable_global_exists("boss_test") && global.boss_test.active && global.boss_test.invulnerable)return false;
    if(global.game_paused || global.game_over || !instance_exists(_pl) || _pl.hp<=0 || _amount<=0) return false;
    if(player_protected_from(_pl,_height)) return false;
    if(variable_instance_exists(_pl,"last_stand_until") && global.round_seconds<_pl.last_stand_until) return false;
    var original=_amount;_amount=max(1,_amount-_pl.armor_flat);
    run_stats_get(SPELL.ARMOR).blocked+=max(0,min(_pl.hp,original)-min(_pl.hp,_amount));
    if(!variable_instance_exists(_pl,"hud_hp_trail")) _pl.hud_hp_trail=_pl.hp;
    _pl.hud_hp_trail=max(_pl.hud_hp_trail,_pl.hp);
    var hp_before=_pl.hp;
    _pl.hp=max(0,_pl.hp-_amount*(1-_pl.damage_reduction));
    run_stats_get(SPELL.SHIELD).blocked+=max(0,min(hp_before,_amount)-(hp_before-_pl.hp));
    _pl.last_damage_taken=hp_before-_pl.hp;_pl.health_visible_time=3;
    fg_sfx("player_hit");
    _pl.hud_damage_hold=0.25; _pl.hud_hit_flash=0.2;
    // Ordinary hits do not grant global invulnerability; attackers own their cooldown.
    if(_pl.hp<=0 && talent_last_stand(_pl)) return true;
    if(_pl.hp<=0) {_pl.death_time=current_time;fg_audio_stop_effects(); fg_sfx("game_over"); fg_music_set("none"); global.game_over=true; global.game_paused=true; global._pause_index=0;}
    return true;
}
function effect_add(_x,_y,_radius,_color,_life,_style="") {
    light_pulse(_x,_y,max(90,_radius*2.8),_color,0.95,min(0.45,_life/60));
    if (!variable_global_exists("combat_effects")) global.combat_effects=[];
    if (array_length(global.combat_effects)>=96) array_delete(global.combat_effects,0,1);
    array_push(global.combat_effects,{x:_x,y:_y,radius:_radius,color:_color,life:_life,total:_life,style:_style});
}
function effects_step() {
    if (!variable_global_exists("combat_effects")) global.combat_effects=[];
    for(var i=array_length(global.combat_effects)-1;i>=0;i--) {
        global.combat_effects[i].life--;
        if (global.combat_effects[i].life<=0) array_delete(global.combat_effects,i,1);
    }
}
function effects_draw() {
    if (!variable_global_exists("combat_effects")) return;
    for(var i=0;i<array_length(global.combat_effects);i++) {
        vfx_area_effect_draw(global.combat_effects[i]);
    }
    draw_set_alpha(1); draw_set_color(c_white);
}
function enemy_pursue() {
    if (!instance_exists(ObjectPlayer)) {speed=0; return;}
    // Explicit movement avoids GameMaker integrating speed a second time.
    speed=0;
    var dir=point_direction(x,y,ObjectPlayer.x,ObjectPlayer.y);
    var start_x=x,start_y=y;
    enemy_reaction_step(min(0.05,max(0,delta_time/1000000)));
    if(object_index==ObjectMonster)scenery_resolve(id,start_x,start_y);
    start_x=x;start_y=y;
    if(hit_stun>0) {chase_vx=0;chase_vy=0;if(slow_time>0)slow_time--;if(shock_time>0)shock_time--;return;}
    var authored=variable_instance_exists(id,"lvl_kind");
    if(((variable_instance_exists(id,"master_skeleton") && self.master_skeleton) || authored) && skeleton_attacking){chase_vx=0;chase_vy=0;return;}
    var pace=base_move_speed*combat_config().monster_speed*(slow_time>0 ? slow_factor : 1)*(shock_time>0 ? 0.8 : 1);
    // Authored level enemies: crawlers zig-zag, spirits weave in wide arcs instead of a straight chase.
    if(authored && lvl_cfg.weave>0) dir+=sin(current_time/1000*(lvl_cfg.hover>0 ? 1.6 : 4.2)+lvl_weave_phase)*(lvl_cfg.hover>0 ? 38 : 24)*lvl_cfg.weave;
    var dx=lengthdir_x(pace,dir), dy=lengthdir_y(pace,dir);
    if (object_index==ObjectMonster) {
        var neighbors=ds_list_create();
        collision_circle_list(x,y,30,ObjectMonster,false,true,neighbors,false);
        var sx=0,sy=0;
        for(var i=0;i<ds_list_size(neighbors);i++) {
            var e=neighbors[| i];
            var dist=point_distance(x,y,e.x,e.y);
            if (e.id!=id && dist<24) {
                var away=dist>0.01 ? point_direction(e.x,e.y,x,y) : separation_angle;
                sx+=lengthdir_x((24-dist)/24,away); sy+=lengthdir_y((24-dist)/24,away);
            }
        }
        ds_list_destroy(neighbors);
        var push=point_distance(0,0,sx,sy);
        if (push>0) {dx+=sx/push*min(push*0.12,pace*0.3); dy+=sy/push*min(push*0.12,pace*0.3);}
    }
    // Low-pass the pursuit vector to avoid abrupt reversal/separation jitter.
    chase_vx=lerp(chase_vx,dx,0.22); chase_vy=lerp(chase_vy,dy,0.22);
    x=clamp(x+chase_vx,12,room_width-12); y=clamp(y+chase_vy,12,room_height-12);
    // Floating spirits pass over scenery; every grounded enemy respects the same footprints as the player.
    if(object_index==ObjectMonster && !(authored && lvl_cfg.hover>0))scenery_resolve(id,start_x,start_y);
    if (slow_time>0) slow_time--;
    if (shock_time>0) shock_time--;
}
function enemy_draw(_scale,_boss) {
    // Status illumination is batched by atmosphere_draw, without per-enemy blend passes.
    draw_set_alpha(1);
    var hover=variable_instance_exists(id,"lvl_hover") ? lvl_hover*(1+sin(current_time/260+lvl_weave_phase)*.25) : 0;
    if(level_world_room())master_shadow_draw(x-3,y+2,(hover>0 ? 10 : 14)*_scale,(hover>0 ? 3.5 : 5)*_scale,hover>0 ? .22 : .36);
    var art=monster_art_div(id);draw_sprite_ext(sprite_index,image_index,x,y-hover,_scale/art*image_xscale,_scale/art*image_yscale,0,hurt_flash_timer>0 ? make_color_rgb(255,200,170) : element_tint(id),1);
    var w=_boss ? 76 : 38, h=_boss ? 8 : 5;
    var yy=y-40*_scale;
    if(!_boss && hp<max_hp && (hurt_flash_timer>0 || damage_number_timer>0)) {
    draw_set_color(make_color_rgb(9,14,21)); draw_rectangle(x-w/2-2,yy-2,x+w/2+2,yy+h+2,false);
    draw_set_color(make_color_rgb(172,153,105)); draw_rectangle(x-w/2-2,yy-2,x+w/2+2,yy+h+2,true);
    draw_set_color(make_color_rgb(56,37,44)); draw_rectangle(x-w/2,yy,x+w/2,yy+h,false);
    draw_set_color(_boss ? make_color_rgb(222,103,72) : make_color_rgb(107,196,115));
    if (hp>0) draw_rectangle(x-w/2,yy,x-w/2+w*clamp(hp/max_hp,0,1),yy+h,false);
    }
    // Bounded, deterministic pixel particles: no per-enemy particle system allocations.
    var phase=(current_time div 90 + particle_phase) mod 8;
    for(var i=0;i<3;i++) {
        var px=x+lengthdir_x(11,phase*45+i*120), py=y-12-i*5;
        if (burn_time>0) {
            draw_set_color(make_color_rgb(255,133+i*25,40));
            draw_triangle(px-2,py,px+2,py,px,py-7-(phase mod 3),false);
            draw_set_color(make_color_rgb(255,209,99));draw_rectangle(px,py-10-phase,px+1,py-9-phase,false);
        }
        if (slow_time>0) {
            draw_set_color(make_color_rgb(140,226,255));
            draw_triangle(px,py-4,px-3,py,px+3,py,false); draw_triangle(px,py+4,px-3,py,px+3,py,false);
        }
        if (shock_time>0) {
            draw_set_color(make_color_rgb(151,208,255));
            draw_line(px-3,py,px+1,py-3); draw_line(px+1,py-3,px-1,py-6);
        }
    }
    draw_set_alpha(1); draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_top);
}
function menu_labels(_mode) {
    switch(_mode) {
        case "characters": return ["Schwertmeister","Arkanistin","Waldlaeufer"];
        case "levels": return level_names();
        case "settings": return ["Vollbild: Ein/Aus","Gesamtlautstaerke","Musik","Effekte","Ton im Hintergrund abspielen","Zurueck zum Titelbildschirm"];
        case "boss_test":return boss_test_menu_labels();
        default: return boss_test_enabled() ? ["Neues Spiel","Einstellungen","Beenden","Boss testen"] : ["Neues Spiel","Einstellungen","Beenden"];
    }
}
function menu_geometry(_count,_characters=false) {
    var w=display_get_gui_width(),h=display_get_gui_height();
    var bw=min(420,w*(_characters ? 0.50 : 0.75));
    return {x:_characters ? w*0.08 : (w-bw)/2,y:h*0.5-_count*62/2+20,w:bw,h:52,gap:10};
}
function menu_activate(_choice) {
    if(menu_mode=="boss_test"){boss_test_menu_change(_choice,1);return;}
    fg_sfx(menu_mode=="characters" ? "character_select" : (menu_mode=="levels" ? "game_start" : (menu_mode=="settings" && _choice==5 ? "ui_back" : "ui_click")));
    if (menu_mode=="characters") {
        var names=["Sword","Mage","Ranger"];
        global.selected_character=names[clamp(_choice,0,2)];
        menu_mode="levels"; menu_index=global.selected_level;
    } else if (menu_mode=="levels") {
        global.selected_level=clamp(_choice,0,level_count()-1);
        pending_new_game=false;
        reset_round();
        room_goto(level_room(global.selected_level));
    } else if (menu_mode=="settings") {
        if (_choice==0) window_set_fullscreen(!window_get_fullscreen());
        if (_choice>=1 && _choice<=3) {var volume_keys=["master_volume","music_volume","effects_volume"]; fg_audio_cycle_volume(volume_keys[_choice-1]);}
        if (_choice==4) fg_audio_toggle_background();
        if (_choice==5) {menu_mode="main"; menu_index=0;}
    } else {
        if (_choice==0) {menu_mode="characters"; menu_index=0; pending_new_game=true;}
        if (_choice==1) {menu_mode="settings"; menu_index=0;}
        if (_choice==2) game_end();
        if (_choice==3 && boss_test_enabled()) {menu_mode="boss_test";menu_index=0;boss_test_settings();}
    }
}
function round_menu_labels() {
    if (global.game_over) return ["Neustart","Zurueck zum Hauptmenue"];
    if (global.settings_active) return ["Vollbild: Ein/Aus","Gesamtlautstaerke","Musik","Effekte","Ton im Hintergrund abspielen","Zurueck zur Runde","Zurueck zum Titelbildschirm"];
    return ["Weiter","Talente & Ausruestung","Neues Spiel","Einstellungen","Zurueck zum Titelbildschirm","Beenden"];
}
function round_menu_activate(_choice) {
    fg_sfx("ui_click");
    if (global.settings_active && !global.game_over) {
        if (_choice==0) window_set_fullscreen(!window_get_fullscreen());
        if (_choice>=1 && _choice<=3) {var volume_keys=["master_volume","music_volume","effects_volume"]; fg_audio_cycle_volume(volume_keys[_choice-1]);}
        if (_choice==4) fg_audio_toggle_background();
        if (_choice==5) {fg_sfx("ui_back"); global.settings_active=false; global._pause_index=0;}
        if (_choice==6) round_end_to_title();
        return;
    }
    var action=round_menu_labels()[_choice];
    if (action=="Weiter") {
        instance_activate_all(); global.game_paused=false; global.normal_pause_active=false; global.pause_initialized=false;
        if (instance_exists(ObjectPlayer)) ObjectPlayer.mouse_move_armed=false; ObjectPlayer.menu_input_guard=1;
    } else if (action=="Einstellungen") {global.settings_active=true; global._pause_index=0;}
    else if (string_pos("Talente",action)==1) {global.game_paused=false; global.normal_pause_active=false; global.pause_initialized=false; talent_menu_open();}
    else if (action=="Neustart" || action=="Neues Spiel") {fg_sfx("game_start"); instance_activate_all(); reset_round(); room_restart();}
    else if(action=="Beenden") game_end();
    else round_end_to_title();
}
function round_end_to_title() {
    boss_test_end();
    fg_sfx("ui_back");
    instance_activate_all(); reset_round(); global.round_active=false; room_goto(RoomMenu);
}
function round_menu_step() {
    var previous_index=global._pause_index;
    var labels=round_menu_labels(), count=array_length(labels), ui=(!global.game_over && !global.settings_active) ? pause_geometry() : menu_geometry(count);
    if (keyboard_check_pressed(vk_up)) global._pause_index=(global._pause_index+count-1) mod count;
    if (keyboard_check_pressed(vk_down)) global._pause_index=(global._pause_index+1) mod count;
    var hover=-1, mx=device_mouse_x_to_gui(0),my=device_mouse_y_to_gui(0);
    for(var i=0;i<count;i++) if(point_in_rectangle(mx,my,ui.x,ui.y+i*62,ui.x+ui.w,ui.y+i*62+ui.h)) hover=i;
    if (hover>=0) global._pause_index=hover;
    fg_audio_hover(previous_index,global._pause_index);
    if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || (mouse_check_button_pressed(mb_left) && hover>=0)) round_menu_activate(global._pause_index);
}
function round_menu_draw() {
    var inventory=!global.game_over && !global.settings_active;
    var labels=round_menu_labels(),ui=inventory ? pause_geometry() : menu_geometry(array_length(labels));
    draw_set_alpha(0.88);draw_set_color(make_color_rgb(8,12,21));
    draw_rectangle(0,0,display_get_gui_width(),display_get_gui_height(),false);
    draw_set_alpha(1);draw_set_color(make_color_rgb(239,211,158));draw_set_halign(inventory ? fa_left : fa_center);draw_set_valign(fa_top);
    draw_text(inventory ? 18 : display_get_gui_width()/2,inventory ? 24 : ui.y-46,global.game_over ? "GAME OVER" : (global.settings_active ? "EINSTELLUNGEN" : "PAUSE"));
    for(var i=0;i<array_length(labels);i++) {
        var yy=ui.y+i*62;
        spell_ui_panel(ui.x,yy,ui.w,ui.h,i==global._pause_index);
        draw_set_halign(fa_center);draw_set_valign(fa_middle);
        var label=labels[i];
        if(global.settings_active && i>=1 && i<=3) label+=fg_audio_volume_label(i);
        if(global.settings_active && i==4) label+=global.audio_background ? ": Ein" : ": Aus";
        if(string_width(label)>ui.w-18) {
            draw_set_valign(fa_top);draw_text_ext(ui.x+ui.w/2,yy+6,label,18,ui.w-18);
        } else draw_text(ui.x+ui.w/2,yy+ui.h/2,label);
    }
    draw_set_halign(fa_left);draw_set_valign(fa_top);
    if(inventory) pause_inventory_draw();
}

function combat_area_hit(_x,_y,_radius,_damage,_owner,_burn_time,_burn_dps,_slow_time,_slow_factor,_sid=0) {
    var types=[ObjectMonster,ObjectBossMonster],count=0;
    for(var t=0;t<2;t++) for(var i=0;i<instance_number(types[t]);i++) {
        var e=instance_find(types[t],i);
        if(e.hp<=0 || combat_body_distance(e,_x,_y)>_radius) continue;
        apply_attack_damage(e,_damage,_owner,_sid); count++;
        if(_burn_time>0) {if(e.burn_time<=0 || _burn_dps>=e.burn_dps){e.burn_dps=_burn_dps;e.burn_spell_id=_sid;}e.burn_time=max(e.burn_time,_burn_time);}
        if(_slow_time>0) {e.slow_factor=min(e.slow_time>0 ? e.slow_factor : 1,_slow_factor);e.slow_time=max(e.slow_time,_slow_time);}
    }
    return count;
}
