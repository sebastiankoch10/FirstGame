/// Room1's complete replacement renderer and shared contact/cast shadows.
function master_shadow_draw(_x,_y,_width,_height,_strength=.3) {
    draw_set_color(make_color_rgb(5,10,20));
    for(var i=3;i>=0;i--) {
        var grow=1+i*.18;draw_set_alpha(_strength*.22);
        draw_ellipse(_x-_width*grow,_y-_height*grow,_x+_width*grow,_y+_height*grow,false);
    }
    draw_set_alpha(1);draw_set_color(c_white);
}
function master_world_ground() {
    var r=combat_view_rect(-20),tile=512;
    global.master_render_rect={left:r.left-260,top:r.top-260,right:r.right+260,bottom:r.bottom+260};
    if(abs(r.left-master_cull_x)>48 || abs(r.top-master_cull_y)>48) {
        master_cull_x=r.left;master_cull_y=r.top;
        global.master_torches=[];global.master_visible_trees=[];global.master_occluders=[];global.master_collision_props=[];
        var bounds=global.master_render_rect;
        with(ObjectMasterScenery) {
            visible=point_in_rectangle(x,y,bounds.left-50,bounds.top-50,bounds.right+50,bounds.bottom+50);
            if(master_prop==11)array_push(global.master_torches,id);
            if(master_prop<4 && visible)array_push(global.master_visible_trees,id);
            if(visible && (master_prop<4 || (master_prop>=8 && master_prop<=11)))array_push(global.master_occluders,id);
            if(master_prop>=8 && master_prop<=10)array_push(global.master_collision_props,id);
        }
        scenery_grid_build(); // cell index for scenery_point_blocked (same result, fewer props tested)
    }
    for(var yy=floor(r.top/tile)*tile;yy<r.bottom;yy+=tile)for(var xx=floor(r.left/tile)*tile;xx<r.right;xx+=tile) {
        var mx=(abs(xx div tile) mod 2)==0 ? 1 : -1,my=(abs(yy div tile) mod 2)==0 ? 1 : -1;
        draw_sprite_ext(spr_master_ground,0,xx+(mx<0 ? tile : 0),yy+(my<0 ? tile : 0),mx,my,0,c_white,1);
    }
    // Soft canopy shadows break up the floor, tied to the actual tree positions.
    for(var i=0;i<array_length(global.master_visible_trees);i++) {
        var tree=global.master_visible_trees[i];
        master_shadow_draw(tree.x-38,tree.y+15,75*tree.image_xscale,24*tree.image_yscale,.35);
    }
}
function master_scenery_draw() {
    var r=global.master_render_rect;if(!point_in_rectangle(x,y,r.left,r.top,r.right,r.bottom))return;
    var sway=master_prop<8 ? sin(global.weather.clock*1.25+x*.013)*global.weather.wind*.8 : 0;
    var alpha=1;
    if(master_prop<4 && instance_exists(ObjectPlayer) && abs(ObjectPlayer.x-x)<85 && ObjectPlayer.y<y && ObjectPlayer.y>y-180)alpha=.42;
    if(master_prop<4)fx_soft_shadow(x-12,y+4,44*image_xscale,11*image_yscale,.35);
    else if(master_prop>=8 && master_prop!=14 && master_prop!=15)fx_soft_shadow(x-8,y+3,(master_prop==9 ? 73 : (master_prop==10 ? 65 : 30))*image_xscale,9*image_yscale,.34);
    fx_sway_draw(sprite_index,0,x,y,image_xscale,image_yscale,sprite_get_yoffset(sprite_index)*image_yscale*dsin(sway),c_white,alpha); // pixel-grid sway
    if(master_prop==11) {
        draw_set_color(make_color_rgb(255,219,129));draw_set_alpha(.65+.15*sin(current_time/90+x));
        draw_circle(x,y-78*image_yscale,2,false);draw_set_color(c_white);draw_set_alpha(1);
    }
}
function master_scenery_lights(_rect) {
    for(var i=0;i<array_length(global.master_torches);i++) {
        var prop=global.master_torches[i];
        if(prop.master_prop==11)atmosphere_source(prop.x,prop.y-75*prop.image_yscale,175,make_color_rgb(255,174,75),.85+.07*sin(current_time/120+prop.x),_rect);
    }
}
