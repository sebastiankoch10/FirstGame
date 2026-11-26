/// Shared real hit feedback. Simulation values live here, never in cosmetic draw code.
function combat_config() {
    static cfg={monster_speed:1.08,stun:0.12,stun_lockout:0.42,knockback:145,knockback_decay:13,
        // Faster than Ranger + Fleet Footed's normal/jump pace; pickup range stays independent.
        sword_range:116,orb_radius:18,normal_coin_speed:420,magnet_start:1000,magnet_max:2400,magnet_acceleration:1800};
    return cfg;
}
function magnet_pickup_mask() {
    if(!variable_global_exists("orb_pickup_mask") || !sprite_exists(global.orb_pickup_mask)) {
        global.orb_pickup_mask=sprite_duplicate(spr_fg_magnet_orb);sprite_set_offset(global.orb_pickup_mask,20,32);
        sprite_collision_mask(global.orb_pickup_mask,false,2,2,2,38,38,2,0);
    }
    return global.orb_pickup_mask;
}
function magnet_touching(_orb,_pl) {
    if(!instance_exists(_orb) || !instance_exists(_pl))return false;
    var radius=combat_config().orb_radius+_pl.contact_radius;
    var distance=point_distance(_orb.x,_orb.y-12,_pl.x,_pl.y-12);
    if(variable_instance_exists(_pl,"pickup_prev_x") && point_distance(_pl.x,_pl.y,_pl.pickup_prev_x,_pl.pickup_prev_y)<72) {
        distance=min(distance,boss_point_segment_distance(_orb.x,_orb.y-12,_pl.pickup_prev_x,_pl.pickup_prev_y-12,_pl.x,_pl.y-12));
    }
    return distance<=radius;
}
function magnet_collect(_orb,_pl=undefined,_collision_event=false) {
    if(is_undefined(_pl))_pl=variable_global_exists("player") ? global.player : noone;
    if(!instance_exists(_orb) || !instance_exists(_pl) || _orb.object_index!=ObjectMagnetOrb || _pl.object_index!=ObjectPlayer)return false;
    if(global.game_paused || global.game_over || _orb.collected || _orb.run_token!=global.run_token || !magnet_touching(_orb,_pl))return false;
    _orb.collected=true;global.magnet_sequence++;global.magnet_metrics.activations++;
    if(_collision_event)global.magnet_metrics.collision_activations++;else global.magnet_metrics.swept_activations++;
    // Include coins on any instance layer, including accidentally deactivated legacy instances.
    instance_activate_object(ObjectCoin);
    with(ObjectCoin) if(!coin_collected) {
        magnetized=true;magnet_generation=global.magnet_sequence;magnet_velocity=combat_config().magnet_start;
        global.magnet_metrics.marked++;
    }
    fg_sfx("spell_upgrade");light_pulse(_orb.x,_orb.y-12,140,make_color_rgb(98,239,231),0.7,0.25);
    with(_orb)instance_destroy();return true;
}
function hit_reaction(_target,_source,_sid) {
    var cfg=combat_config();
    if(!variable_instance_exists(_target,"hit_stun")) {_target.hit_stun=0;_target.stun_lockout=0;_target.knock_vx=0;_target.knock_vy=0;}
    var boss=_target.object_index==ObjectBossMonster || (variable_instance_exists(_target,"boss_twin") && _target.boss_twin),resistance=boss ? 1 : (variable_instance_exists(_target,"monster_scale") && _target.monster_scale>=1.5 ? 0.65 : 0);
    if(!boss && _target.stun_lockout<=0) {_target.hit_stun=cfg.stun;_target.stun_lockout=cfg.stun_lockout;}
    var dir=instance_exists(_source) ? point_direction(_source.x,_source.y,_target.x,_target.y) : 0;
    if(instance_exists(_source) && variable_instance_exists(_source,"projectile_speed"))dir=_source.direction;
    _target.knock_vx=clamp(_target.knock_vx+lengthdir_x(cfg.knockback*(1-resistance),dir),-190,190);
    _target.knock_vy=clamp(_target.knock_vy+lengthdir_y(cfg.knockback*(1-resistance),dir),-190,190);
    // Hitstop (Kampf & Begegnungen 9): physical base-weapon hits freeze the enemy's picture for HITSTOP_FRAMES.
    // Visual only: position, stun and knockback keep running underneath, the player is never affected.
    if(!boss && _sid<=0 && (!variable_global_exists("selected_character") || global.selected_character!="Mage") &&(!variable_instance_exists(_target,"hitstop_t") || _target.hitstop_t<=-.1)) {
        _target.hitstop_t=HITSTOP_FRAMES/60;_target.hitstop_x=_target.x;_target.hitstop_y=_target.y;_target.hitstop_img=_target.image_index;
    }
}
#macro HITSTOP_FRAMES 2
/// Draw-time swap for the hitstop picture: returns the real state to restore with enemy_hitstop_end (or undefined).
function enemy_hitstop_begin() {
    if(!variable_instance_exists(id,"hitstop_t") || hitstop_t<=0)return undefined;
    var real_state={x:x,y:y,img:image_index},shake=(current_time div 33) mod 2==0 ? 1 : -1;
    x=hitstop_x+shake;y=hitstop_y;image_index=hitstop_img;
    return real_state;
}
function enemy_hitstop_end(_s) {if(is_struct(_s)){x=_s.x;y=_s.y;image_index=_s.img;}}
function enemy_reaction_step(_dt) {
    if(!variable_instance_exists(id,"hit_stun")) {hit_stun=0;stun_lockout=0;knock_vx=0;knock_vy=0;}
    hit_stun=max(0,hit_stun-_dt);stun_lockout=max(0,stun_lockout-_dt);
    if(variable_instance_exists(id,"hitstop_t"))hitstop_t-=_dt; // visual hitstop timer (runs to -0.1: short lockout)
    x=clamp(x+knock_vx*_dt,12,room_width-12);y=clamp(y+knock_vy*_dt,12,room_height-12);
    var decay=exp(-combat_config().knockback_decay*_dt);knock_vx*=decay;knock_vy*=decay;
}
function damage_source_kind(_sid,_status=false) {
    if(_status)return "Status Damage";if(_sid<=0)return "Base Weapon";
    var data=GetSpellData(_sid);return is_struct(data) && data.type==SPELL_TYPE.PASSIVE ? "Passive Effect" : "Active Spell";
}
function damage_number_add(_target,_amount,_sid,_status=false) {
    if(!variable_global_exists("damage_labels"))global.damage_labels=[];
    var source_kind=damage_source_kind(_sid,_status),color=source_kind=="Base Weapon" ? c_white : make_color_rgb(255,225,88);
    // DoT ticks aggregate per target/source; never allocate sixty labels per second.
    if(_status) for(var i=0;i<array_length(global.damage_labels);i++) {
        var label=global.damage_labels[i];if(label.target==_target.id && label.sid==_sid && label.status && label.age<0.45) {label.amount+=_amount;return;}
    }
    if(array_length(global.damage_labels)>=96)array_delete(global.damage_labels,0,1);
    array_push(global.damage_labels,{target:_target.id,sid:_sid,source_kind:source_kind,status:_status,amount:_amount,x:_target.x+(array_length(global.damage_labels) mod 3-1)*7,y:_target.y-45,age:0,color:color});
}
function impact_add(_x,_y,_kind,_direction=0) {
    if(!variable_global_exists("impact_fx"))global.impact_fx=[];
    if(array_length(global.impact_fx)>=72)array_delete(global.impact_fx,0,1);
    array_push(global.impact_fx,{x:_x,y:_y,kind:_kind,dir:_direction,age:0});
}
function feedback_step(_dt) {
    for(var i=array_length(global.impact_fx)-1;i>=0;i--) {global.impact_fx[i].age+=_dt;if(global.impact_fx[i].age>=0.22)array_delete(global.impact_fx,i,1);}
    for(var i=array_length(global.damage_labels)-1;i>=0;i--) {global.damage_labels[i].age+=_dt;if(global.damage_labels[i].age>=0.7)array_delete(global.damage_labels,i,1);}
}
function feedback_draw() {
    for(var i=0;i<array_length(global.impact_fx);i++) {
        var e=global.impact_fx[i],f=e.age/0.22,col=make_color_rgb(167,205,255);
        if(e.kind=="bolt" || e.kind=="sword")col=make_color_rgb(255,231,179);
        if(e.kind=="fire")col=make_color_rgb(255,144,50);
        if(e.kind=="ice")col=make_color_rgb(115,228,255);
        if(e.kind=="arcane")col=make_color_rgb(217,138,255);
        draw_set_alpha(1-f);draw_set_color(col);
        for(var n=0;n<5;n++) {
            var a=e.dir+n*72,r=5+f*18;
            draw_line_width(round(e.x+lengthdir_x(r*0.4,a)),round(e.y+lengthdir_y(r*0.4,a)),round(e.x+lengthdir_x(r,a)),round(e.y+lengthdir_y(r,a)),2);
        }
        if(e.kind!="bolt")draw_circle(e.x,e.y,4+f*12,true);
    }
    draw_set_halign(fa_center);draw_set_valign(fa_bottom);draw_set_font(world_font());
    for(var i=0;i<array_length(global.damage_labels);i++) {
        var d=global.damage_labels[i];draw_set_alpha(min(1,(0.7-d.age)*4));draw_set_color(d.color);
        draw_text(round(d.x),round(d.y-d.age*27),string_format(d.amount,0,d.amount<1 ? 2 : (d.status ? 1 : 0)));
    }
    draw_set_font(-1);draw_set_halign(fa_left);draw_set_valign(fa_top);draw_set_alpha(1);draw_set_color(c_white);
}
function projectile_setup() {
    hit_targets=[];hit_done=false;damage_radius=20;visual_width=104;visual_height=104;
    if(object_index==ObjectFireball) {damage_radius=18;visual_width=84;visual_height=84;}
    if(object_index==ObjectIceball) {damage_radius=12;visual_width=56;visual_height=56;}
    speed=0;
}
function projectile_draw() {
    if(variable_instance_exists(id,"class_weapon_v2") && class_weapon_v2) {
        var radius=(projectile_kind=="bolt" ? 19 : 23)+class_tier*3;
        class_fx_sprite(projectile_kind=="bolt" ? 4 : 0,.25+.08*sin(current_time/90),x,y,radius,direction);
        if(class_tier>1){draw_set_alpha(.4);draw_set_color(projectile_kind=="bolt" ? make_color_rgb(206,212,218) : make_color_rgb(166,119,255));draw_line_width(x-lengthdir_x(22+class_tier*6,direction),y-lengthdir_y(22+class_tier*6,direction),x,y,2);draw_set_alpha(1);draw_set_color(c_white);} // arrows: silver streak with the upgrade tier, never an element colour
        return;
    }
    var kind=projectile_kind,col=make_color_rgb(150,201,255);
    if(object_index==ObjectFireball){kind="fire";col=make_color_rgb(255,157,55);}
    else if(object_index==ObjectIceball){kind="ice";col=make_color_rgb(147,229,255);}
    else if(kind=="arcane")col=make_color_rgb(221,150,255);
    if(kind=="bolt") {
        draw_set_color(make_color_rgb(218,192,139));
        draw_line_width(x-lengthdir_x(17,direction),y-lengthdir_y(17,direction),x+lengthdir_x(10,direction),y+lengthdir_y(10,direction),4);
        draw_set_color(c_white);var tipx=x+lengthdir_x(14,direction),tipy=y+lengthdir_y(14,direction);
        draw_triangle(tipx,tipy,tipx+lengthdir_x(7,direction+145),tipy+lengthdir_y(7,direction+145),tipx+lengthdir_x(7,direction-145),tipy+lengthdir_y(7,direction-145),false);
    } else {
        vfx_projectile_draw(kind,x,y,direction,damage_radius,variable_instance_exists(id,"spell_id") && spell_id>0 ? vfx_spell_band(spell_id) : 1,sprite_index,image_index,col);
    }
    draw_set_alpha(1);draw_set_color(c_white);
}
function pickup_hint_draw() {
    with(ObjectMagnetOrb) {
        draw_set_color(make_color_rgb(122,255,242));draw_circle(x,y-12,21,true);
        if(instance_exists(ObjectPlayer) && point_distance(x,y,ObjectPlayer.x,ObjectPlayer.y)<100) {draw_set_halign(fa_center);draw_set_font(world_font());draw_text(round(x),round(y-42),"MAGNET");draw_set_font(-1);draw_set_halign(fa_left);}
    }
    draw_set_color(c_white);
}
/// Pixel font for numbers in the world (tests/tools/art/build_pixel_font.py): 5x7 glyphs, white fill (tinted by the
/// draw colour) and a dark outline, so labels stay crisp on the world grid (render_pipeline).
function world_font() {
    if(!variable_global_exists("world_font_id") || !font_exists(global.world_font_id))global.world_font_id=font_add_sprite_ext(spr_font_world,"0123456789.,+-%ABCDEFGHIJKLMNOPQRSTUVWXYZ",true,1);
    return global.world_font_id;
}
