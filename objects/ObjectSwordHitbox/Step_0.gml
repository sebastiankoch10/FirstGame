if(global.game_paused) exit;
if(!instance_exists(owner) || lifetime<=0) {instance_destroy(); exit;}
lifetime--;
x=owner.x; y=owner.y-10; depth=-owner.y-1;
var types=[ObjectMonster,ObjectBossMonster];
for(var t=0;t<2;t++) for(var j=0;j<instance_number(types[t]);j++) {
    var e=instance_find(types[t],j);
    var dist=combat_body_distance(e,x,y);
    var dir=point_direction(x,y,e.x,e.y-10);
    if(e.hp>0 && dist<=hit_radius && abs(angle_difference(dir,direction))<=hit_half_angle && !array_contains(hit_targets,e.id)) {
        array_push(hit_targets,e.id); apply_attack_damage(e,damage,owner);impact_add(e.x,e.y-12,"sword",direction); fg_sfx("sword_hit");
    }
}
