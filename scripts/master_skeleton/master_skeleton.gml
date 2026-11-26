/// Fully articulated new skeletons. Old monster art is never resolved on the Room1 path.
function master_skeleton_init() {
    master_skeleton=true;monster_species="master_skeleton";skeleton_role="warrior";
    skeleton_clock=0;skeleton_action="idle";skeleton_direction="down";
    skeleton_attacking=false;skeleton_attack_time=0;skeleton_strike=false;
    monster_visual_sprite=player_artpack_sprite("spr_master_skeleton_idle_down");
    sprite_index=monster_visual_sprite;image_index=0;image_speed=0;image_xscale=1;
}
function master_skeleton_step(_dt) {
    var dist=instance_exists(ObjectPlayer) ? point_distance(x,y,ObjectPlayer.x,ObjectPlayer.y) : 99999;
    if(!skeleton_attacking && dist<48 && hit_stun<=0) {skeleton_attacking=true;skeleton_attack_time=0;}
    skeleton_strike=false;
    var action=dist>55 ? "walk" : "idle";
    if(skeleton_attacking) {
        skeleton_attack_time+=_dt;skeleton_strike=skeleton_attack_time>=.20 && skeleton_attack_time<.36;
        action="attack";
        if(skeleton_attack_time>=.72){skeleton_attacking=false;skeleton_strike=false;}
    }
    if(monster_hurt_timer>0 || hit_stun>0) {
        monster_hurt_timer=max(0,monster_hurt_timer-1);action="hurt";skeleton_strike=false;
    }
    if(skeleton_strike && dist<=43)player_contact(ObjectPlayer,id);
    var angle=instance_exists(ObjectPlayer) ? point_direction(x,y,ObjectPlayer.x,ObjectPlayer.y) : 270;
    // Lock the facing once the telegraphed sword strike begins.
    if(!skeleton_attacking || skeleton_attack_time<.12)skeleton_direction=player_visual_direction("swordsmanv3",angle);
    if(action!=skeleton_action){skeleton_clock=0;skeleton_action=action;}
    skeleton_clock+=_dt;
    sprite_index=player_artpack_sprite("spr_master_skeleton_"+action+"_"+skeleton_direction);
    var count=sprite_get_number(sprite_index);
    image_xscale=1;image_yscale=1;image_speed=0;
    if(action=="attack")image_index=skeleton_attack_time<.20 ? 0 : 1;
    else if(action=="hurt")image_index=min(count-1,floor(skeleton_clock*20));
    else {
        // walk cycle speed follows the role (visual only): the scout's legs move faster, the guard's slower
        var walk_rate=skeleton_role=="scout" ? 13 : (skeleton_role=="guard" ? 7.5 : 10);
        image_index=floor(skeleton_clock*(action=="walk" ? walk_rate : 3)) mod count;
    }
}
function master_skeleton_remains(_enemy) {
    if(instance_number(ObjectSkeletonRemains)>=32)with(instance_find(ObjectSkeletonRemains,0))instance_destroy();
    var rem=instance_create_layer(_enemy.x,_enemy.y,"Instances",ObjectSkeletonRemains);
    rem.sprite_index=player_artpack_sprite("spr_master_skeleton_death_"+_enemy.skeleton_direction);
    rem.remains_scale=_enemy.monster_scale;rem.depth=-_enemy.y;rem.life=0;
}
