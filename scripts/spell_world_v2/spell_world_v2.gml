function sword_visual_tier(_level) {return _level>=68 ? 3 : (_level>=34 ? 2 : 1);}
/// Physical footprints stay at masonry bases; transparent facade pixels never form giant walls.
function scenery_point_blocked(_x,_y,_pad=0) {
    if(room!=Room1)return level_generated() ? level_point_blocked(_x,_y,_pad) : false;
    if(!variable_global_exists("master_collision_props"))return false;
    for(var i=0;i<array_length(global.master_collision_props);i++) {
        var p=global.master_collision_props[i],sy=p.image_yscale,sx=p.image_xscale;
        if(abs(_y-(p.y-6*sy))>12*sy+_pad)continue;
        if(p.master_prop==9) {
            if(abs(_x-(p.x-70*sx))<=20*sx+_pad || abs(_x-(p.x+70*sx))<=20*sx+_pad)return true;
        } else if(abs(_x-p.x)<=(p.master_prop==8 ? 28 : 65)*sx+_pad)return true;
    }
    return false;
}
function scenery_resolve(_actor,_old_x,_old_y) {
    if(!level_world_room() || scenery_point_blocked(_old_x,_old_y-6,10))return;
    if(!scenery_point_blocked(_actor.x,_actor.y-6,10))return;
    var next_x=_actor.x,next_y=_actor.y;_actor.x=_old_x;
    if(scenery_point_blocked(_actor.x,next_y-6,10)) {
        _actor.x=next_x;_actor.y=_old_y;
        if(scenery_point_blocked(next_x,_actor.y-6,10)){_actor.x=_old_x;_actor.y=_old_y;}
    }
}
function coin_hidden_by_scenery(_coin) {
    if(room!=Room1)return level_generated() ? level_coin_hidden(_coin) : false;
    if(!variable_global_exists("master_occluders"))return false;
    for(var i=0;i<array_length(global.master_occluders);i++) {
        var prop=global.master_occluders[i],half=prop.master_prop<4 ? 88 : (prop.master_prop==9 ? 95 : 40);
        var height=prop.master_prop<4 ? 220 : 175;
        if(abs(_coin.x-prop.x)<half*prop.image_xscale && _coin.y<prop.y-6 && _coin.y>prop.y-height*prop.image_yscale)return true;
    }
    return false;
}
function coin_occlusion_draw() {
    if(!level_world_room())return;
    var r=combat_view_rect();
    with(ObjectCoin)if(point_in_rectangle(x,y,r.left,r.top,r.right,r.bottom) && coin_hidden_by_scenery(id)) {
        draw_set_alpha(.55);draw_set_color(make_color_rgb(247,209,117));draw_circle(x,y-5,9,true);
        draw_sprite_ext(sprite_index,image_index,x,y,1,1,0,make_color_rgb(255,224,143),.48);
    }
    draw_set_alpha(1);draw_set_color(c_white);
}
function miniboss_marker_draw() {
    with(ObjectBossMonster)if(hp>0 && !boss_completed && !boss_data.main) {
        var yy=y-visual_height-20+sin(current_time/200)*4;
        draw_set_color(make_color_rgb(182,131,245));draw_triangle(x-7,yy-7,x+7,yy-7,x,yy+2,false);
        draw_set_color(make_color_rgb(250,227,170));draw_triangle(x-4,yy-6,x+4,yy-6,x,yy-1,false);
    }
    draw_set_color(c_white);
}
