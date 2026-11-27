/// Shared bounded hazards. One clock drives telegraph, activation, contact and expiry. Since 27.11. every boss and
/// miniboss attack runs here (dragon encounter and miniboss zones merged); looks and ignition: scripts/hazard_looks.
function bv2_hazard(_b,_kind,_g,_active,_damage,_height,_once,_extra) {
    _g.height=_height; // the renderer shows how the hazard is solved (ground: jump or dodge, high: slide or dodge, all: dodge only)
    if(!variable_global_exists("bv2_hazards"))global.bv2_hazards=[];
    if(array_length(global.bv2_hazards)>=128)return {owner:_b,kind:_kind,g:_g,expired:true};
    var h={owner:_b,kind:_kind,g:_g,age:0,warning:_g.duration,active:_active,damage:_damage,height:_height,hit_once:_once,hit:false,next_hit:0,interval:.45,
        activated:false,expired:false,root_time:0,poison:0,push:0,expand_from:-1,expand_to:-1,gap_width:0,gap_angle:0,rotate_speed:0,extra:_extra,birth_clock:_b.v2_clock};
    array_push(global.bv2_hazards,h);return h;
}
function bv2_zone(_b,_kind,_x,_y,_radius,_warning,_active,_damage,_height="all",_extra=undefined) {var h=bv2_hazard(_b,_kind,telegraph_make("circle",_x,_y,_radius,_warning),_active,_damage,_height,true,_extra);h.warning=max(0,_warning);return h;}
function bv2_line(_b,_kind,_x,_y,_ex,_ey,_width,_warning,_active,_damage,_height="high",_extra=undefined) {return bv2_hazard(_b,_kind,telegraph_make("line",_x,_y,point_distance(_x,_y,_ex,_ey),_warning,point_direction(_x,_y,_ex,_ey),0,_width),_active,_damage,_height,false,_extra);}
function bv2_sector(_b,_kind,_x,_y,_radius,_angle,_span,_warning,_active,_damage,_height="all",_extra=undefined) {return bv2_hazard(_b,_kind,telegraph_make("sector",_x,_y,_radius,_warning,_angle,_span),_active,_damage,_height,false,_extra);}
function bv2_ring(_b,_kind,_x,_y,_outer,_inner,_warning,_active,_damage,_height="ground",_extra=undefined) {var h=bv2_hazard(_b,_kind,telegraph_make("ring",_x,_y,_outer,_warning,0,360,_outer-_inner),_active,_damage,_height,false,_extra);return h;}
function bv2_bullet(_b,_kind,_x,_y,_angle,_speed,_damage,_radius=10,_life=5) {
    if(array_length(global.hostile_bullets)>=256)return false;
    var b={owner:_b,x:_x,y:_y,vx:lengthdir_x(_speed,_angle),vy:lengthdir_y(_speed,_angle),radius:_radius,age:0,life:_life,damage:_damage,bv2_kind:_kind,poison:0,splash_radius:0,travelled:0,range:point_distance(_x,_y,_b.v2_target_x,_b.v2_target_y)};
    array_push(global.hostile_bullets,b);return b;
}
function bv2_hazard_hit(_h,_pl) {
    // impact core: the first core_t seconds also hit inside core_r around the centre (dragon slam)
    if(variable_struct_exists(_h,"core_r") && _h.age-_h.warning<_h.core_t && point_distance(_h.g.x,_h.g.y,_pl.x,_pl.y-10)<_h.core_r)return true;
    var inside=telegraph_contains(_h.g,_pl.x,_pl.y-10);
    // moving rings: also count the band swept since the last step (no tunnelling at low frame rates)
    if(!inside && variable_struct_exists(_h,"sweep_prev") && _h.g.shape=="ring"){var d=point_distance(_h.g.x,_h.g.y,_pl.x,_pl.y-10),lo=min(_h.sweep_prev,_h.g.radius)-(_h.g.radius-_h.g.inner),hi=max(_h.sweep_prev,_h.g.radius);inside=d>=lo && d<=hi;}
    if(!inside)return false;
    if(_h.gap_width>0 && abs(angle_difference(point_direction(_h.g.x,_h.g.y,_pl.x,_pl.y-10),_h.gap_angle+_h.rotate_speed*max(0,_h.age-_h.warning)))<_h.gap_width*.5)return false;
    return true;
}
function bv2_player_status(_pl,_h) {
    if(_h.root_time>0)_pl.boss_root_time=max(_pl.boss_root_time,_h.root_time);
    if(_h.poison>0){_pl.boss_poison_time=max(_pl.boss_poison_time,_h.poison);_pl.boss_poison_dps=max(_pl.boss_poison_dps,_h.damage*.15);}
    if(_h.push>0){var px=_pl.x,py=_pl.y,a=point_direction(_h.g.x,_h.g.y,_pl.x,_pl.y);_pl.x=clamp(_pl.x+lengthdir_x(_h.push,a),16,room_width-16);_pl.y=clamp(_pl.y+lengthdir_y(_h.push,a),16,room_height-16);scenery_resolve(_pl,px,py);}
}
function bv2_hazards_step(_dt) {
    if(global.game_paused || global.game_over)return;
    if(!variable_global_exists("bv2_hazards"))global.bv2_hazards=[];
    for(var i=array_length(global.bv2_hazards)-1;i>=0;i--) {
        var h=global.bv2_hazards[i];if(!instance_exists(h.owner)){array_delete(global.bv2_hazards,i,1);continue;}
        h.age=max(0,h.owner.v2_clock-h.birth_clock);h.g.elapsed=h.age;
        if(h.gap_width>0){h.g.gap_width=h.gap_width;h.g.gap_angle=h.gap_angle+h.rotate_speed*max(0,h.age-h.warning);}
        if(h.age>=h.warning && h.age<h.warning+h.active) {
            var p=clamp((h.age-h.warning)/max(.001,h.active),0,1);
            if(h.expand_from>=0 && h.expand_to>=0){var width=variable_struct_exists(h,"ring_width") ? h.ring_width : 40,prev=h.g.radius;h.g.radius=lerp(h.expand_from,h.expand_to,p);h.g.inner=max(0,h.g.radius-width);h.sweep_prev=prev;}
            if(variable_struct_exists(h,"ring_fn")){var ring=hz_ring_at(h,h.age-h.warning);h.g.radius=ring.radius;h.g.inner=ring.inner;} // expanding ring with its own formula
            bc_hazard_update(h,p);
            if(variable_struct_exists(h,"wave_from_x")){var dist=p*h.wave_length;h.g.x=h.wave_from_x+lengthdir_x(dist,h.wave_angle);h.g.y=h.wave_from_y+lengthdir_y(dist,h.wave_angle);h.g.radius=h.wave_thickness;h.g.width=h.wave_width;h.g.angle=h.wave_angle;}
            if(!h.activated){
                h.activated=true;var el=hz_element_of(h.kind),big=geo_area(h.g)>40000;
                // impact light on the damage event: lightning lifts the whole scene briefly, big areas flash, small ones pulse;
                // attacks with their own ignition (sound, light) handle it in hz_look_activate
                if(!hz_look_activate(h)) {
                    if(el==3)light_flash(h.g.x,h.g.y,min(420,h.g.radius*2+80),make_color_rgb(190,215,255),1.6,.3,.45);
                    else if(big)light_flash(h.g.x,h.g.y,min(420,h.g.radius*1.6),bv2_element_color(h.kind),1.2,.32,.12);
                    else light_pulse(h.g.x,h.g.y,min(360,h.g.radius*2),bv2_element_color(h.kind),.9,.22);
                }
                bc_hazard_activated(h);
            }
            if(instance_exists(ObjectPlayer) && (!h.hit_once || !h.hit) && h.age>=h.next_hit && bv2_hazard_hit(h,ObjectPlayer)) {
                if(player_receive_damage(ObjectPlayer,h.damage,h.height)){h.hit=true;h.next_hit=h.age+h.interval;bv2_player_status(ObjectPlayer,h);}
            }
        }
        if(h.age>=h.warning+h.active+.35)array_delete(global.bv2_hazards,i,1);
    }
}
function bv2_status_step(_pl,_dt) {
    if(!variable_instance_exists(_pl,"boss_root_time")){_pl.boss_root_time=0;_pl.boss_poison_time=0;_pl.boss_poison_dps=0;_pl.boss_poison_tick=0;}
    if(global.game_paused || global.game_over)return;
    _pl.boss_root_time=max(0,_pl.boss_root_time-_dt);
    if(_pl.boss_poison_time>0){_pl.boss_poison_time=max(0,_pl.boss_poison_time-_dt);_pl.boss_poison_tick-=_dt;if(_pl.boss_poison_tick<=0){player_receive_damage(_pl,_pl.boss_poison_dps*.5,"all");_pl.boss_poison_tick=.5;}}
    else {_pl.boss_poison_dps=0;_pl.boss_poison_tick=0;}
}
function bv2_element_color(_kind) {
    if(string_pos("ice",_kind)>0)return make_color_rgb(126,218,255);
    if(string_pos("swamp",_kind)>0)return make_color_rgb(168,220,65);
    if(string_pos("link",_kind)>0 || string_pos("nova",_kind)>0 || string_pos("void",_kind)>0)return make_color_rgb(213,146,249);
    return make_color_rgb(255,141,76);
}
/// Twins and swamp effects as pixel composites on the world grid (render_pipeline) instead of the scaled painted sheets.
/// The element follows the hazard kind: fire or ice for the twins; acid/nature or earth for the swamp. Small radii are
/// bullets or beads (an orb), larger ones a burst over the hazard area. _p keeps its old meaning (0..1 over the sheet).
function bv2_fx(_kind,_p,_x,_y,_radius,_angle=0) {
    var swamp=string_pos("swamp",_kind)>0,ice=string_pos("ice",_kind)>0 || string_pos("frost",_kind)>0;
    var earth=swamp && (string_pos("roots",_kind)>0 || string_pos("stomp",_kind)>0 || string_pos("emerge",_kind)>0 || string_pos("wave",_kind)>0);
    var el=swamp ? (earth ? 5 : 6) : (ice ? 2 : 1);
    if(_radius<=40)vfx_element_orb(_x,_y,_radius,_angle,el);else vfx_element_burst(_x,_y,_radius,clamp(_p,0,1),el);
    draw_set_alpha(1);draw_set_color(c_white);
}
/// Small element orb with a short trail (bullets, beads on rings).
function vfx_element_orb(_x,_y,_r,_dir,_el) {
    var pal=vfx_palette(_el),x0=round(_x),y0=round(_y),r=max(3,round(_r*.4));
    if(vfx_quality()>0)vfx_glow_disc(x0,y0,r*1.8,pal[1],.2);
    for(var g=1;g<=3;g++)vfx_px(x0-lengthdir_x(r+g*3,_dir)-1,y0-lengthdir_y(r+g*3,_dir)-1,g<2 ? 3 : 2,g<2 ? pal[1] : pal[0],1-g*.22);
    draw_set_alpha(1);draw_set_color(pal[0]);draw_circle(x0,y0,r,false);draw_set_color(pal[1]);draw_circle(x0,y0,max(1,r-1),false);
    draw_set_color(pal[2]);draw_circle(x0-1,y0-1,max(1,r*.4),false);
}
/// Burst over a hazard area: core flash, pixel shock rings, element debris (fire embers, ice shards, acid bubbles,
/// earth chips) flying out and fading; q runs 0..1.
function vfx_element_burst(_x,_y,_r,_q,_el) {
    var pal=vfx_palette(_el),k=1-_q,x0=round(_x),y0=round(_y);
    if(vfx_quality()>0)vfx_glow_disc(x0,y0,_r*(.3+.6*_q),pal[1],.2*k);
    if(_q<.4){var c=1-_q/.4;draw_set_alpha(c*.9);draw_set_color(pal[2]);draw_circle(x0,y0,max(2,_r*.3*(1-c*.3)),false);}
    vfx_pixel_ring(x0,y0,_r*(.3+.7*_q),pal[1],k,0,0,2);
    vfx_pixel_ring(x0,y0,_r*(.2+.6*_q),pal[0],.8*k,_q*40,3,1);
    var n=vfx_quality()==0 ? 8 : 16;
    for(var i=0;i<n;i++) {
        var a=i*360/n+20*vfx_hash(i,_el),d=_r*(.2+.8*_q)*(.7+.3*abs(vfx_hash(i,_el+3))),px=x0+lengthdir_x(d,a),py=y0+lengthdir_y(d,a);
        if(_el==2){vfx_pixel_line(px,py-2,px,py+2,1,pal[2],k);vfx_pixel_line(px-2,py,px+2,py,1,pal[1],k);}
        else if(_el==6){draw_set_alpha(k);draw_set_color(i mod 2 ? pal[1] : pal[2]);draw_circle(round(px),round(py-_q*8),1+(i mod 3),true);}
        else vfx_px(px,py,i mod 3==0 ? 3 : 2,i mod 2 ? pal[0] : pal[1],k);
    }
}
/// _pass: 0 everything, 1 warnings only (queued for telegraph_flush), 2 active surfaces only (drawn after the flush,
/// so a hitting attack lies above every later warning, Kampf & Begegnungen 8).
function bv2_hazards_draw(_pass=0) {
    if(!variable_global_exists("bv2_hazards"))return;
    for(var i=0;i<array_length(global.bv2_hazards);i++) {
        var h=global.bv2_hazards[i],g=h.g,col=variable_struct_exists(h,"col") ? h.col : bv2_element_color(h.kind);
        var el=hz_element_of(h.kind);
        if(h.age<h.warning) {if(_pass!=2 && !hz_look_warning(h,col))telegraph_draw(g,col,el);continue;}
        if(_pass==1)continue;
        var age=h.age-h.warning;if(age>h.active+.3)continue;
        if(h.active<=0)continue; // announcement only (marker)
        if(hz_look_active(h,age,col)){draw_set_alpha(1);continue;}
        // Phase 2A: the whole active area as one coherent element surface over the exact hit geometry (WYSIWYG).
        if(g.shape=="line" && h.active>=.35)vfx_beam_stream(g,el,age,h.active,i);else hz_area_draw(g,el,col,age,h.active,i);
        draw_set_alpha(1);continue;
        draw_set_alpha(clamp((h.active+.3-age)*3,0,1));
        if(g.shape=="line" || g.shape=="rectangle") {
            var xx=g.x+lengthdir_x(g.radius*.5,g.angle),yy=g.y+lengthdir_y(g.radius*.5,g.angle);
            draw_set_color(col);draw_line_width(g.x,g.y,g.x+lengthdir_x(g.radius,g.angle),g.y+lengthdir_y(g.radius,g.angle),g.width);draw_set_color(c_white);draw_line_width(g.x,g.y,g.x+lengthdir_x(g.radius,g.angle),g.y+lengthdir_y(g.radius,g.angle),max(1,g.width*.15));
            bv2_fx(h.kind,frac(age*2),xx,yy,min(75,g.radius*.25),g.angle);
        } else if(g.shape=="ring") {
            for(var n=0;n<36;n++){var a=n*10+h.rotate_speed*age;if(h.gap_width>0 && abs(angle_difference(a,h.gap_angle+h.rotate_speed*age))<h.gap_width*.5)continue;bv2_fx(h.kind,.25+frac(age)*.4,g.x+lengthdir_x((g.radius+g.inner)*.5,a),g.y+lengthdir_y((g.radius+g.inner)*.5,a),max(16,(g.radius-g.inner)*.7),a);}
        } else if(g.shape=="sector") {
            for(var n=0;n<7;n++){var a=g.angle-g.span*.5+g.span*n/6;bv2_fx(h.kind,.2+frac(age)*.4,g.x+lengthdir_x(g.radius*.55,a),g.y+lengthdir_y(g.radius*.55,a),g.radius*.45,a);}
        } else bv2_fx(h.kind,clamp(age/max(.35,h.active),0,1),g.x,g.y,g.radius);
        draw_set_alpha(1);
    }
    draw_set_alpha(1);draw_set_color(c_white);
}
function bv2_summon(_b,_x,_y) {
    var count=0;with(ObjectMonster)if(variable_instance_exists(id,"boss_minion") && boss_minion && boss_owner==_b)count++;
    if(count>=6)return noone;
    var e=instance_create_layer(_x,_y,"Instances",ObjectMonster);e.boss_minion=true;e.boss_owner=_b;e.master_skeleton=false;e.hp=40*_b.v2_scaling.hp;e.max_hp=e.hp;e.damage=7*_b.v2_scaling.damage;e.base_move_speed=.9;e.sprite_index=asset_get_index("spr_bv2_brood");e.mask_index=combat_mask();e.contact_radius=12;e.minion_clock=0;return e;
}
function bv2_minion_step(_e,_dt) {
    if(!instance_exists(_e.boss_owner) || _e.hp<=0){with(_e)instance_destroy();return;}
    _e.minion_clock+=_dt;enemy_pursue();player_contact(ObjectPlayer,_e);_e.depth=-_e.y;
    if(_e.minion_clock>=18)with(_e)instance_destroy();
}
