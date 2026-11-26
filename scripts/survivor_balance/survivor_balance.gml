/// Population goals, visible targeting and XP are shared by runtime and local fixtures.
function combat_view_rect(_inset=0) {
    var cam=view_camera[0],xx=camera_get_view_x(cam),yy=camera_get_view_y(cam);
    return {left:xx+_inset,top:yy+_inset,right:xx+camera_get_view_width(cam)-_inset,bottom:yy+camera_get_view_height(cam)-_inset};
}
function combat_target_visible(_target) {
    if(!instance_exists(_target)) return false;
    var r=combat_view_rect(22);
    if(_target.object_index==ObjectBossMonster) return _target.bbox_right>=r.left && _target.bbox_left<=r.right && _target.bbox_bottom>=r.top && _target.bbox_top<=r.bottom;
    return point_in_rectangle(_target.x,_target.y-10,r.left,r.top,r.right,r.bottom);
}
function progression_cost(_level) {
    var lv=max(1,floor(_level));
    var cfg=progression_config();
    if(lv<=3)return cfg.first[lv-1];
    if(lv<=cfg.early_end)return ceil(cfg.early_base+cfg.early_step*(lv-4));
    var n=lv-cfg.early_end-1;return ceil(cfg.late_base+cfg.late_step*n+cfg.late_curve*n*n);
}
function population_profile(_seconds) {
    var times=[0,60,180,300,600,1200,1800],counts=[18,24,40,60,80,110,150];
    var wanted=150;
    for(var i=0;i<6;i++) if(_seconds<times[i+1]) {
        wanted=lerp(counts[i],counts[i+1],clamp((_seconds-times[i])/(times[i+1]-times[i]),0,1));break;
    }
    return {minimum:round(wanted),visible_floor:floor(wanted*0.6),technical_max:180};
}
function population_counts() {
    var near_rect=combat_view_rect(-150),visible_rect=combat_view_rect(0),nearby=0,visible_count=0,alive=0;
    for(var i=0;i<instance_number(ObjectMonster);i++) {
        var e=instance_find(ObjectMonster,i);if(e.hp<=0) continue;alive++;
        if(point_in_rectangle(e.x,e.y,near_rect.left,near_rect.top,near_rect.right,near_rect.bottom)) nearby++;
        if(point_in_rectangle(e.x,e.y-10,visible_rect.left,visible_rect.top,visible_rect.right,visible_rect.bottom)) visible_count++;
    }
    return {alive:alive,nearby:nearby,visible:visible_count};
}
function population_spawn_point(_side,_offset) {
    var r=combat_view_rect(),margin=random_range(24,42),xx=0,yy=0;
    switch(_side) {
        case 0:xx=lerp(r.left,r.right,_offset);yy=r.top-margin;break;
        case 1:xx=r.right+margin;yy=lerp(r.top,r.bottom,_offset);break;
        case 2:xx=lerp(r.left,r.right,_offset);yy=r.bottom+margin;break;
        case 3:xx=r.left-margin;yy=lerp(r.top,r.bottom,_offset);break;
    }
    if(xx<18 || yy<18 || xx>room_width-18 || yy>room_height-18) return undefined;
    if(!instance_exists(ObjectPlayer) || point_distance(xx,yy,ObjectPlayer.x,ObjectPlayer.y)<190) return undefined;
    if(scenery_point_blocked(xx,yy-6,12))return undefined;
    var blocker=instance_position(xx,yy,ObjectEnvironmentDecoration);
    if(instance_exists(blocker) && blocker.blocks_movement) return undefined;
    return {x:xx,y:yy};
}
function population_spawn_enemy(_x,_y) {
    var e=population_spawn_enemy_base(_x,_y);
    elite_try_make(e);
    return e;
}
function population_spawn_enemy_base(_x,_y) {
    // Generated worlds use their own authored enemy pools on the unchanged population curve.
    if(room!=Room1 && level_generated())return level_enemy_spawn(_x,_y);
    var e=instance_create_layer(_x,_y,"Instances",ObjectMonster),elapsed=global.round_seconds;
    var roll=irandom(99),runner=elapsed>=20 && roll<min(30,12+elapsed/15),tank=elapsed>=90 && roll>=88;
    if(room==Room1) {
        // The first world's active pool is exclusively the new authored skeleton set.
        e.monster_species="master_skeleton";e.master_skeleton=true;
        e.max_hp=(tank ? 165 : (runner ? 50 : 78))*global.monster_hp_multiplier;
        e.damage=(tank ? 15 : (runner ? 8 : 11))*global.monster_damage_multiplier;
        e.base_move_speed=tank ? 0.82 : (runner ? 1.55 : 1.12);
        e.monster_scale=tank ? 1.65 : (runner ? 1.25 : 1.4);
        e.skeleton_role=tank ? "guard" : (runner ? "scout" : "warrior");
        e.hp=e.max_hp;return e;
    }
    if(tank) {
        e.max_hp=165*global.monster_hp_multiplier;e.damage=15*global.monster_damage_multiplier;e.base_move_speed=0.82;
        e.monster_species=choose("boar","golem","blob");e.monster_scale=1.5;
    } else if(runner) {
        e.max_hp=50*global.monster_hp_multiplier;e.damage=8*global.monster_damage_multiplier;e.base_move_speed=1.55;
        e.monster_species=choose("bat","goblin","imp","bandit");e.monster_scale=1.15;
    } else {
        e.max_hp=78*global.monster_hp_multiplier;e.damage=11*global.monster_damage_multiplier;e.base_move_speed=1.12;
        e.monster_species=choose("slime","mushroom","wisp","lizard","spider","skeleton","plant","beetle");
    }
    e.hp=e.max_hp;
    return e;
}
function population_step(_spawner,_dt) {
    if(global.game_paused || global.game_over || !instance_exists(ObjectPlayer)) return;
    // The spawner owns elite hazards (bv2 needs an owner clock that outlives the elite).
    if(!variable_instance_exists(_spawner,"v2_clock"))_spawner.v2_clock=0;
    _spawner.v2_clock+=_dt;
    _spawner.population_timer-=_dt;
    // Track actual frame cadence; sustained slow frames lower the ceiling, not HP/XP.
    _spawner.frame_ms=lerp(_spawner.frame_ms,min(100,_dt*1000),0.04);
    if(_spawner.frame_ms>25) _spawner.slow_seconds+=_dt;else _spawner.slow_seconds=max(0,_spawner.slow_seconds-_dt);
    if(_spawner.slow_seconds>2) {_spawner.runtime_cap=max(80,_spawner.runtime_cap-10);_spawner.slow_seconds=0;}
    if(_spawner.frame_ms<19) _spawner.recover_seconds+=_dt;else _spawner.recover_seconds=0;
    if(_spawner.recover_seconds>8) {_spawner.runtime_cap=min(180,_spawner.runtime_cap+10);_spawner.recover_seconds=0;}
    if(_spawner.population_timer>0) return;
    _spawner.population_timer=0.20;
    var started=get_timer(),profile=population_profile(global.round_seconds),r=combat_view_rect(-650);
    // Far-away stragglers are despawned without drops, never teleported into the visible field.
    var recycled=0;
    for(var i=instance_number(ObjectMonster)-1;i>=0 && recycled<8;i--) {
        var e=instance_find(ObjectMonster,i);
        if(!point_in_rectangle(e.x,e.y,r.left,r.top,r.right,r.bottom)) {with(e) instance_destroy();recycled++;}
    }
    var c=population_counts(),extra=min(ceil(profile.minimum*0.25),max(0,profile.visible_floor-c.visible));
    var wanted=min(_spawner.runtime_cap,profile.minimum+extra);
    var budget=min(6,max(0,wanted-c.nearby),max(0,_spawner.runtime_cap-c.alive));
    var side=irandom(3),anchor=random_range(0.12,0.88);
    repeat(budget) {
        var point=undefined;
        repeat(12) {
            point=population_spawn_point(side,clamp(anchor+random_range(-0.10,0.10),0.03,0.97));
            if(is_struct(point)) break;
            side=(side+1) mod 4;
        }
        if(is_struct(point)) population_spawn_enemy(point.x,point.y);
        if(irandom(2)==0) {side=(side+1+irandom(1)) mod 4;anchor=random_range(0.1,0.9);}
    }
    var minute=global.round_seconds/60;
    global.monster_hp_multiplier=global.base_monster_hp_multiplier*(1+minute*0.07);
    global.monster_damage_multiplier=global.base_monster_damage_multiplier*(1+minute*0.06);
    global.population_metrics=population_counts();
    global.population_metrics.minimum=profile.minimum;global.population_metrics.cap=_spawner.runtime_cap;
    global.population_metrics.refill_ms=(get_timer()-started)/1000;
}

function progression_config() {static cfg={first:[1,16,24],early_end:14,early_base:36,early_step:10,late_base:146,late_step:2.3,late_curve:0.012,min_gap:6};return cfg;}
function population_spawn_safe(_x,_y) {
 if(scenery_point_blocked(_x,_y-6,12))return false;
 var blocker=instance_position(_x,_y,ObjectEnvironmentDecoration);
 return !instance_exists(blocker) || !blocker.blocks_movement;
}

// ---------------- Elite enemies (user decision 25.11.2026) ----------------
/// From minute 3 every 60th spawned enemy becomes an elite (deterministic counter, no RNG: seeded runs stay comparable).
/// All numbers are new, untested design values (docs/Design/Kampf & Begegnungen.md 7). Abilities use the shared
/// bv2 hazards, so warning, countdown, hit and pause follow the same rules as boss attacks (G1).
function elite_config() {
    static c={from_seconds:180,every:60,hp_mult:3,damage_mult:1.25,scale_mult:1.2,drop_chance:.1,
        leap_cooldown:5,leap_min:120,leap_max:360,leap_radius:70,leap_warning:.9,leap_damage_mult:1.6,
        toxic_radius:85,toxic_warning:.6,toxic_active:3,toxic_damage_mult:.35};
    return c;
}
function elite_try_make(_e) {
    if(!instance_exists(_e) || !variable_global_exists("round_seconds") || global.round_seconds<elite_config().from_seconds)return;
    if(!variable_global_exists("elite_counter"))global.elite_counter=0;
    global.elite_counter++;
    var c=elite_config();if(global.elite_counter mod c.every!=0)return;
    _e.elite=true;_e.max_hp*=c.hp_mult;_e.hp=_e.max_hp;_e.damage*=c.damage_mult;_e.monster_scale*=c.scale_mult;
    _e.elite_ability=(global.elite_counter div c.every) mod 2==0 ? "leap" : "toxic";
    _e.elite_timer=c.leap_cooldown*.5;_e.elite_leap=undefined;
}
function elite_is(_e) {return variable_instance_exists(_e,"elite") && _e.elite;}
function elite_owner() {return instance_exists(ObjectSpawner) ? instance_find(ObjectSpawner,0) : noone;}
/// Returns true while the elite performs its leap (normal movement is suspended).
function elite_step(_e,_dt) {
    var c=elite_config(),own=elite_owner();if(!instance_exists(own) || !instance_exists(ObjectPlayer))return false;
    if(is_struct(_e.elite_leap)) {
        var L=_e.elite_leap;L.t+=_dt;var p=clamp(L.t/c.leap_warning,0,1);
        _e.x=lerp(L.sx,L.tx,p);_e.y=lerp(L.sy,L.ty,p);
        if(p>=1){_e.elite_leap=undefined;_e.elite_timer=c.leap_cooldown;spell_vfx_burst(_e.x,_e.y,40,5,1);}
        return true;
    }
    if(_e.elite_ability!="leap")return false;
    _e.elite_timer-=_dt;
    var pl=ObjectPlayer,d=point_distance(_e.x,_e.y,pl.x,pl.y);
    if(_e.elite_timer<=0 && d>=c.leap_min && d<=c.leap_max && combat_target_visible(_e)) {
        // Target is fixed when the warning appears (Kampf & Begegnungen 5.5); a jump clears the ground wave.
        bv2_zone(own,"elite_slam",pl.x,pl.y,c.leap_radius,c.leap_warning,.2,_e.damage*c.leap_damage_mult,"ground");
        _e.elite_leap={sx:_e.x,sy:_e.y,tx:pl.x,ty:pl.y,t:0};fg_sfx("dodge");
        return true;
    }
    return false;
}
/// Visual lift of a leaping elite (arc), used by the Draw event.
function elite_lift(_e) {
    if(!elite_is(_e) || !is_struct(_e.elite_leap))return 0;
    return sin(pi*clamp(_e.elite_leap.t/elite_config().leap_warning,0,1))*56;
}
function elite_on_death(_e) {
    var c=elite_config(),own=elite_owner();
    if(_e.elite_ability=="toxic" && instance_exists(own)) {
        var h=bv2_zone(own,"swamp_elite_acid",_e.x,_e.y,c.toxic_radius,c.toxic_warning,c.toxic_active,_e.damage*c.toxic_damage_mult,"all");
        if(is_struct(h) && !h.expired){h.hit_once=false;h.interval=.5;}
    }
    // Better loot than a normal enemy: 10 % chance on gear, at least magic rarity.
    if(variable_global_exists("equipment_drops") && !global.game_over && equipment_rng()<c.drop_chance)
        equipment_drop(_e.x,_e.y,equipment_generate(equipment_random_slot(),equipment_rng()<.75 ? 1 : 2,equipment_item_level()));
}
/// Gold outline (flat-colour silhouette via fog) drawn under an elite, pulsing slightly.
function elite_outline_draw(_e,_scale) {
    if(!elite_is(_e))return;
    var a=.55+.25*sin(current_time/180),col=make_color_rgb(255,206,96),sp=_e.sprite_index,fr=_e.image_index;
    var hover=variable_instance_exists(_e,"lvl_hover") ? _e.lvl_hover*(1+sin(current_time/260+_e.lvl_weave_phase)*.25) : 0;   // same as enemy_draw
    gpu_set_fog(true,col,0,1);
    var mdx=variable_instance_exists(_e,"motion_dx") ? _e.motion_dx : 0,mdy=variable_instance_exists(_e,"motion_dy") ? _e.motion_dy : 0;
    for(var i=0;i<4;i++)draw_sprite_ext(sp,fr,_e.x+mdx+lengthdir_x(2,i*90),_e.y-hover+mdy+lengthdir_y(2,i*90),_scale/monster_art_div(_e)*_e.image_xscale,_scale/monster_art_div(_e)*_e.image_yscale,0,c_white,a);
    gpu_set_fog(false,c_black,0,0);
}
