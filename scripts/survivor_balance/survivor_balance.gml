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
