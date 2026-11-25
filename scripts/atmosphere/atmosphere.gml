/// Bounded, half-resolution multiplicative world lighting. HUD/telegraphs stay above it.
function atmosphere_init() {
    light_surface=-1; light_sprite=-1; light_width=0; light_height=0;
    light_camera=camera_create_view(0,0,128,128,0,noone,-1,-1,-1,-1);
    global.light_pulses=[]; global.light_metrics={sources:0,draw_ms:0};
}
function light_pulse(_x,_y,_radius,_color,_strength=1,_duration=0.22) {
    if(!variable_global_exists("light_pulses")) global.light_pulses=[];
    if(array_length(global.light_pulses)>=40) array_delete(global.light_pulses,0,1);
    array_push(global.light_pulses,{x:_x,y:_y,radius:_radius,color:_color,strength:_strength,life:_duration,total:_duration});
}
function atmosphere_step(_dt) {
    if(!variable_global_exists("light_pulses")) global.light_pulses=[];
    for(var i=array_length(global.light_pulses)-1;i>=0;i--) {
        global.light_pulses[i].life-=_dt;
        if(global.light_pulses[i].life<=0) array_delete(global.light_pulses,i,1);
    }
}
function atmosphere_source(_x,_y,_radius,_color,_strength,_rect) {
    if(global.light_metrics.sources>=72 || _radius<=0) return;
    if(_x+_radius<_rect.left || _x-_radius>_rect.right || _y+_radius<_rect.top || _y-_radius>_rect.bottom) return;
    draw_sprite_ext(light_sprite,0,(_x-_rect.left)*0.5,(_y-_rect.top)*0.5,_radius/128,_radius/128,0,_color,_strength);
    global.light_metrics.sources++;
}
function atmosphere_draw() {
    if(!instance_exists(ObjectPlayer) || !global.round_active) return;
    var stamp=get_timer(),r=combat_view_rect(),ww=ceil((r.right-r.left)*0.5),hh=ceil((r.bottom-r.top)*0.5);
    var old_view=matrix_get(matrix_view),old_projection=matrix_get(matrix_projection);
    if(!sprite_exists(light_sprite)) {
        var temp=surface_create(128,128); if(!surface_exists(temp)) return;
        surface_set_target(temp);camera_set_view_size(light_camera,128,128);camera_apply(light_camera);draw_clear(c_black);draw_set_alpha(1);
        draw_circle_color(64,64,64,c_white,c_black,false);surface_reset_target();
        light_sprite=sprite_create_from_surface(temp,0,0,128,128,false,false,64,64);surface_free(temp);
        matrix_set(matrix_view,old_view);matrix_set(matrix_projection,old_projection);
    }
    if(!surface_exists(light_surface) || light_width!=ww || light_height!=hh) {
        if(surface_exists(light_surface)) surface_free(light_surface);
        light_surface=surface_create(ww,hh);light_width=ww;light_height=hh;
    }
    if(!surface_exists(light_surface)) return;
    var old_world=matrix_get(matrix_world);matrix_set(matrix_world,matrix_build_identity());
    surface_set_target(light_surface);camera_set_view_size(light_camera,ww,hh);camera_apply(light_camera);
    draw_clear(weather_ambient());
    global.light_metrics.sources=0;gpu_set_blendmode(bm_add);
    atmosphere_source(ObjectPlayer.x,ObjectPlayer.y-18,180,make_color_rgb(167,181,183),0.60,r);
    if(room==Room1)master_scenery_lights(r);
    else level_world_lights(r);
    equipment_lights(r);spell_vfx_lights(r);
    for(var i=0;i<array_length(global.light_pulses);i++) {
        var p=global.light_pulses[i];atmosphere_source(p.x,p.y,p.radius,p.color,p.strength*p.life/p.total,r);
    }
    if(instance_exists(global.active_boss) && global.active_boss.dragon_enabled && global.active_boss.boss_state=="active") {
        var g=dragon_attack_geometry(global.active_boss);
        atmosphere_source(g.x,g.y,230,make_color_rgb(255,142,47),1.1,r);
        atmosphere_source((g.x+g.ex)/2,(g.y+g.ey)/2,240,make_color_rgb(255,132,40),0.8,r);
        atmosphere_source(g.ex,g.ey,190,make_color_rgb(255,105,35),0.7,r);
    }
    var types=[ObjectFireball,ObjectIceball,ObjectLightningball];
    for(var t=0;t<3;t++) for(var i=0;i<instance_number(types[t]);i++) {
        var p=instance_find(types[t],i),col=t==0 ? make_color_rgb(255,135,48) : (t==1 ? make_color_rgb(110,190,255) : make_color_rgb(151,148,255));
        atmosphere_source(p.x,p.y,t==0 ? 125 : 82,col,0.85,r);
    }
    // Budget guarantees projectiles/player/impacts priority over crowded status lights.
    for(var i=0;i<array_length(global.chain_segments);i++) {
        var e=global.chain_segments[i];atmosphere_source(e.bx,e.by,155,make_color_rgb(169,211,255),e.life/0.16,r);
    }
    var enemies=[ObjectBossMonster,ObjectMonster];
    for(var t=0;t<2;t++) for(var i=0;i<instance_number(enemies[t]);i++) {
        if(global.light_metrics.sources>=72) break;
        var e=instance_find(enemies[t],i);
        if(e.burn_time>0) atmosphere_source(e.x,e.y-18,100,make_color_rgb(255,133,41),0.7+0.10*sin(current_time/83+e.particle_phase),r);
        else if(e.shock_time>0) atmosphere_source(e.x,e.y-18,105,make_color_rgb(150,208,255),0.8,r);
        else if(e.slow_time>0) atmosphere_source(e.x,e.y-18,72,make_color_rgb(107,189,255),0.5,r);
    }
    gpu_set_blendmode(bm_normal);surface_reset_target();matrix_set(matrix_world,old_world);
    matrix_set(matrix_view,old_view);matrix_set(matrix_projection,old_projection);
    gpu_set_texfilter(true);gpu_set_blendmode_ext(bm_dest_colour,bm_zero);draw_set_alpha(1);draw_set_color(c_white);
    draw_surface_stretched(light_surface,r.left,r.top,r.right-r.left,r.bottom-r.top);
    gpu_set_blendmode(bm_normal);gpu_set_texfilter(false);
    global.light_metrics.draw_ms=(get_timer()-stamp)/1000;
}
function atmosphere_cleanup() {
    if(surface_exists(light_surface)) surface_free(light_surface);
    if(sprite_exists(light_sprite)) sprite_delete(light_sprite);
    camera_destroy(light_camera);
}
function boss_navigation_step(_b,_dt) {
    var cfg=boss_navigation_config(),r=combat_view_rect();
    _b.teleport_cooldown=max(0,_b.teleport_cooldown-_dt);
    var off=_b.x+_b.body_radius<r.left || _b.x-_b.body_radius>r.right || _b.y<r.top || _b.y-_b.visual_height>r.bottom;
    var distance=point_distance(_b.x,_b.y,ObjectPlayer.x,ObjectPlayer.y);
    _b.offscreen_time=off && distance>cfg.distance ? _b.offscreen_time+_dt : 0;
    if(_b.teleport_warning>0) {
        _b.teleport_warning-=_dt;
        if(_b.teleport_warning<=0) {
            light_pulse(_b.x,_b.y,180,make_color_rgb(150,120,255),0.9);
            _b.x=_b.teleport_x;_b.y=_b.teleport_y;
            _b.teleport_cooldown=cfg.cooldown;_b.offscreen_time=0;
            _b.boss_state="intro";_b.boss_timer=1.1;
            light_pulse(_b.x,_b.y,260,make_color_rgb(150,120,255),1,0.45);
        }
        return true;
    }
    if(_b.offscreen_time>=cfg.delay && _b.teleport_cooldown<=0) {
        for(var i=0;i<12;i++) {
            var angle=point_direction(ObjectPlayer.x,ObjectPlayer.y,_b.x,_b.y)+i*30;
            var safe=cfg.arrival+_b.body_radius;
            var xx=clamp(ObjectPlayer.x+lengthdir_x(safe,angle),_b.body_radius,room_width-_b.body_radius);
            var yy=clamp(ObjectPlayer.y+lengthdir_y(safe,angle),_b.visual_height,room_height-32);
            if(point_distance(xx,yy,ObjectPlayer.x,ObjectPlayer.y)<safe-8) continue;
            if(!population_spawn_safe(xx,yy)) continue;
            boss_cleanup(_b.id,true);global.active_boss=_b;global.boss_exists=true;
            _b.teleport_x=xx;_b.teleport_y=yy;_b.teleport_warning=0.8;return true;
        }
    }
    return false;
}
// Technical fallback only: ordinary distances are handled by the bosses' own announced catch-up moves (boss_choreo).
function boss_navigation_config() {static cfg={distance:850,delay:6,cooldown:12,arrival:210};return cfg;}
function boss_direction_draw() {
    if(!instance_exists(global.active_boss) || !instance_exists(ObjectPlayer)) return;
    var b=global.active_boss,p=ObjectPlayer,desired=point_direction(p.x,p.y,b.x,b.y);
    boss_direction_update(p,b,0.18);
    var a=p.boss_arrow_angle,xx=p.x+lengthdir_x(64,a),yy=p.y-12+lengthdir_y(64,a);
    draw_set_alpha(combat_target_visible(b) ? 0.55 : 0.95);draw_set_color(make_color_rgb(255,210,116));
    draw_triangle(xx+lengthdir_x(8,a),yy+lengthdir_y(8,a),xx+lengthdir_x(6,a+135),yy+lengthdir_y(6,a+135),xx+lengthdir_x(6,a-135),yy+lengthdir_y(6,a-135),false);
    draw_set_alpha(1);draw_set_color(c_white);
    if(b.teleport_warning>0) {
        draw_set_color(make_color_rgb(190,153,255));draw_circle(b.teleport_x,b.teleport_y,b.body_radius+20,true);
        draw_set_color(c_white);
    }
}
function boss_direction_update(_pl,_boss,_blend) {
    var desired=point_direction(_pl.x,_pl.y,_boss.x,_boss.y);
    if(!variable_instance_exists(_pl,"boss_arrow_angle")) _pl.boss_arrow_angle=desired;
    _pl.boss_arrow_angle+=angle_difference(desired,_pl.boss_arrow_angle)*clamp(_blend,0,1);
}
function loot_config() {static cfg={magnet_chance:0,magnet_speed:960,contact_interval:0.65};return cfg;}
function boss_body_mask(_radius,_height) {
    if(!variable_global_exists("boss_masks")) global.boss_masks={};
    var key="r"+string(_radius)+"h"+string(_height);
    if(variable_struct_exists(global.boss_masks,key)) return variable_struct_get(global.boss_masks,key);
    var mask=sprite_duplicate(spr_fg_boss_golem);
    sprite_set_offset(mask,192,360);
    sprite_collision_mask(mask,false,2,192-_radius,360-min(310,_height*0.80),192+_radius,360,2,0);
    variable_struct_set(global.boss_masks,key,mask);return mask;
}
function combat_body_distance(_target,_x,_y) {
    if(_target.object_index==ObjectBossMonster) {
        var d=point_distance(_x,_y,clamp(_x,_target.bbox_left,_target.bbox_right),clamp(_y,_target.bbox_top,_target.bbox_bottom));
        // Composite bosses: head and neck are hit shapes of the same unit (dragon_parts).
        if(variable_instance_exists(_target,"dp") && _target.dp.active)d=min(d,dragon_parts_distance(_target,_x,_y));
        return d;
    }
    return max(0,point_distance(_x,_y,_target.x,_target.y-10)-_target.contact_radius);
}
function boss_large_draw() {
    if(dragon_enabled) {dragon_draw(id);return;}
    if(variable_instance_exists(id,"v2_enabled") && v2_enabled){bv2_actor_draw(id,false);return;}
    var spr=boss_data.species=="dragon" ? spr_fg_boss_dragon : spr_fg_boss_golem;
    var frame=boss_state=="windup" ? 2 : (boss_state=="recovery" ? 1 : 0);
    var size=visual_height/330;
    draw_sprite_ext(spr,frame,x,y,size*image_xscale,size,0,hurt_flash_timer>0 ? make_color_rgb(255,200,180) : element_tint(id),1);
    for(var i=0;i<3;i++) {
        var xx=x+(i-1)*18,yy=y-visual_height*0.4-((current_time div 90+i*3) mod 8);
        if(burn_time>0) {draw_set_color(make_color_rgb(255,161,57));draw_triangle(xx-3,yy+4,xx+3,yy+4,xx,yy-6,false);}
        if(slow_time>0) {draw_set_color(make_color_rgb(135,220,255));draw_triangle(xx,yy-5,xx-3,yy,xx+3,yy,false);}
        if(shock_time>0) {draw_set_color(make_color_rgb(204,230,255));draw_line_width(xx-4,yy,xx+3,yy-5,2);draw_line(xx+3,yy-5,xx,yy-9);}
    }
    draw_set_color(c_white);
}
function magnet_drop(_x,_y,_guaranteed=false) {
    if(_guaranteed) return instance_create_layer(_x,_y,"Instances",ObjectMagnetOrb);
    return noone;
}
