/// Compact HUD. All ratios read live gameplay state; drawing never advances simulation.
function hud_step(_dt) {
    if(!instance_exists(ObjectPlayer)) return;
    var pl=ObjectPlayer;
    if(!variable_instance_exists(pl,"hud_hp_trail")) {
        pl.hud_hp_trail=pl.hp; pl.hud_damage_hold=0; pl.hud_hit_flash=0;
    }
    pl.health_visible_time=max(0,pl.health_visible_time-_dt);
    pl.hud_hit_flash=max(0,pl.hud_hit_flash-_dt);
    pl.hud_damage_hold=max(0,pl.hud_damage_hold-_dt);
    if(pl.hp>=pl.hud_hp_trail) pl.hud_hp_trail=pl.hp;
    else if(pl.hud_damage_hold<=0) pl.hud_hp_trail=max(pl.hp,pl.hud_hp_trail-_dt*pl.max_hp*0.65);
}
function hud_radial(_x,_y,_size,_remaining) {
    var fraction=clamp(_remaining,0,1);
    if(fraction<=0) return;
    var half=_size/2,cx=_x+half,cy=_y+half;
    var angle=(1-fraction)*360;
    draw_set_color(make_color_rgb(3,6,13)); draw_set_alpha(0.76);
    // Clip to the square icon, including every corner; reveal clockwise from twelve o'clock.
    while(angle<359.999) {
        var next_angle=min(360,angle+5,(floor((angle+0.0001)/45)+1)*45);
        var ax=dsin(angle),ay=-dcos(angle),bx=dsin(next_angle),by=-dcos(next_angle);
        var ascale=half/max(abs(ax),abs(ay)),bscale=half/max(abs(bx),abs(by));
        draw_triangle(cx,cy,cx+ax*ascale,cy+ay*ascale,cx+bx*bscale,cy+by*bscale,false);
        angle=next_angle;
    }
    draw_set_alpha(1); draw_set_color(c_white);
}
function hud_layout() {
    var w=display_get_gui_width(),h=display_get_gui_height();
    var size=min(36,floor((w-36)/12));
    return {x:12,y:12,hp_w:min(250,w*0.35),hp_h:80,size:size,gap:5,
        slots_x:12,active_y:h-size-38,passive_y:h-size*2-44};
}
function hud_draw() {
    if(global.game_paused || !instance_exists(ObjectPlayer)) return;
    var pl=ObjectPlayer,ui=hud_layout(),w=display_get_gui_width();
    draw_set_font(-1); draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_alpha(1);
    var xp_x=12,xp_y=display_get_gui_height()-12,xp_w=w-24;
    draw_set_color(make_color_rgb(65,87,94));draw_rectangle(xp_x,xp_y,xp_x+xp_w,xp_y+6,true);
    draw_set_alpha(0.45);draw_set_color(make_color_rgb(22,43,46));draw_rectangle(xp_x+1,xp_y+1,xp_x+xp_w-1,xp_y+5,false);draw_set_alpha(1);
    if(global.coins>0) {draw_set_color(make_color_rgb(105,211,217));draw_rectangle(xp_x+1,xp_y+1,xp_x+(xp_w-2)*clamp(global.coins/max(1,global.coins_needed),0,1),xp_y+5,false);}
    draw_set_color(make_color_rgb(221,233,230));draw_text(12,xp_y-19,"Lv "+string(global.current_level));
    draw_set_halign(fa_center);draw_text(w/2,10,format_round_time(global.round_seconds));draw_set_halign(fa_left);
    var hovered=undefined;
    for(var group=0;group<2;group++) for(var i=0;i<6;i++) {
        var list=group==0 ? global.active_spells : global.passive_spells;
        var xx=ui.slots_x+i*(ui.size+ui.gap),yy=group==0 ? ui.active_y : ui.passive_y;
        spell_ui_panel(xx,yy,ui.size,ui.size,false);
        if(i>=array_length(list)) continue;
        var entry=list[i],sid=name_to_spell_id(entry.name);
        spell_ui_icon(sid,xx+3,yy+3,ui.size-6);
        if(group==0) {
            var full_cooldown=variable_struct_exists(entry,"cooldown") ? entry.cooldown : spell_values(sid,entry.level).cooldown;
            hud_radial(xx+3,yy+3,ui.size-6,entry.cooldown_timer/max(1,full_cooldown));
            if(variable_struct_exists(entry,"ready_flash") && entry.ready_flash>0) {
                draw_set_color(make_color_rgb(244,234,177)); draw_rectangle(xx-1,yy-1,xx+ui.size+1,yy+ui.size+1,true);
            }
        }
        draw_set_color(c_white); draw_set_halign(fa_right); draw_set_valign(fa_bottom);
        draw_text(xx+ui.size-3,yy+ui.size-1,string(entry.level));
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        if(point_in_rectangle(device_mouse_x_to_gui(0),device_mouse_y_to_gui(0),xx,yy,xx+ui.size,yy+ui.size)) hovered=entry;
    }
    draw_set_color(make_color_rgb(163,185,195));
    draw_text(ui.slots_x+6*(ui.size+ui.gap)+4,ui.active_y+8,"AUTO");
    draw_text(ui.slots_x+6*(ui.size+ui.gap)+4,ui.passive_y+8,"PASSIV");
    boss_hud_draw(12,34,w-24);
    talent_hud_draw();
    equipment_hud_draw(ui.slots_x,ui.passive_y-28);
    hud_minimap();
    if(is_struct(hovered)) spell_tooltip(name_to_spell_id(hovered.name),hovered.level,12,94,min(420,w-24),ui.passive_y-12,false);
    draw_set_alpha(1); draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_top);
}
