/// Attack decoration on the world layer (Grafik-Overhaul 26.11., Fähigkeiten, VFX & Audio 2a).
/// The readable danger itself (warning, beam stream with its 1-px edges, area fills) stays in the readability layer
/// (hazard_fx, drawn after the post pass) and is unchanged. This file only adds what lies UNDER it on the world layer:
/// light, glow sources, heat shimmer, particles and ground marks. Decoration particles start inside the hit width, so
/// nothing hard-edged suggests danger outside the real area (G15); soft light may reach beyond it. Where the danger
/// surface is opaque (beams), the particles inside it use FXP_TOP: over the surface, under every warning.
/// Showcase (Schritt 3 of the overhaul): the dragon's fire breath, straight and swept.

/// Active fire beams this frame: {x,y,angle,len,width,age,active,swept}. Straight dragon beam (dragon_encounter) and
/// swept beams (bv2 line hazards of a fire kind).
function fx_fire_beams() {
    var out=[];
    var b=variable_global_exists("active_boss") ? global.active_boss : noone;
    if(instance_exists(b) && b.dragon_enabled && !b.dragon_dying && b.boss_state=="active" && variable_instance_exists(b,"enc_sweep")) {
        var swept=is_struct(b.enc_sweep);
        if((b.boss_cast=="beam" && !swept) || b.boss_cast=="sweep"){var g=dragon_attack_geometry(b);array_push(out,{x:g.x,y:g.y,angle:b.dragon_angle,len:g.length,width:g.width,age:b.dragon_state_age,active:b.enc_cfg.active,swept:false});}
    }
    if(variable_global_exists("bv2_hazards"))for(var i=0;i<array_length(global.bv2_hazards);i++) {
        var h=global.bv2_hazards[i],g=h.g;
        if(g.shape!="line" || h.age<h.warning || hz_element_of(h.kind)!=1 || h.active<.35)continue;
        var age=h.age-h.warning;if(age>h.active)continue;
        array_push(out,{x:g.x,y:g.y,angle:g.angle,len:g.radius,width:g.width,age:age,active:h.active,swept:variable_struct_exists(h,"sweep_from")});
    }
    return out;
}
/// Visible part of a beam (it may continue off screen; decoration only where it can be seen).
function fx_beam_visible_len(_x,_y,_ang,_len) {
    var r=combat_view_rect(),vis=120,c=[[r.left,r.top],[r.right,r.top],[r.left,r.bottom],[r.right,r.bottom]];
    for(var i=0;i<4;i++)vis=max(vis,(c[i][0]-_x)*lengthdir_x(1,_ang)+(c[i][1]-_y)*lengthdir_y(1,_ang)+40);
    return min(_len,vis);
}
/// Charging dragon: energy gathers at the mouth, an aura of embers rises from the body (same clock as vfx_charge).
function fx_dragon_charge() {
    var b=variable_global_exists("active_boss") ? global.active_boss : noone;
    if(!instance_exists(b) || !b.dragon_enabled || b.dragon_dying || b.boss_state!="windup")return undefined;
    if(!array_contains(["beam","arc","sweep","void","wind","volley"],b.boss_cast))return undefined;
    // projectile attacks announce themselves the same way (Die Attacke ist die Warnung): energy of their element gathers
    var el=b.boss_cast=="void" ? 4 : (b.boss_cast=="wind" ? 2 : 1);
    var m=dragon_mouth(b,false);return {x:m.x,y:m.y,p:clamp(b.dragon_state_age/max(.1,b.enc_cfg.warning),0,1),bx:b.x,by:b.y,size:b.visual_height,el:el};
}
/// Active fire surfaces of the dragon (fan, long cones, magma, meteors, fire rings): flames lick up all over the hit
/// area while it burns (FXP_TOP: over the opaque surface, under every warning). Slow and short-lived, so they stay close
/// to the area (at most about 20 px above it). Visual only, bounded per frame.
function fx_hazard_flames_step(_dt) {
    if(!variable_global_exists("bv2_hazards"))return;
    var budget=fxp_n(40);
    for(var i=0;i<array_length(global.bv2_hazards) && budget>0;i++) {
        var h=global.bv2_hazards[i];if(h.age<h.warning || h.age>=h.warning+h.active)continue;
        // the slam's dust wave leaves lit dust behind its front (the band itself is drawn by hz_act_shock)
        if(h.kind=="dragon_slam" && variable_struct_exists(h,"ring_fn")){var ring=hz_ring_at(h,h.age-h.warning);repeat(min(budget,fxp_n(5))){var a=vfx_random(360),rr=ring.radius-vfx_random(12);fxp_add(ring.x+lengthdir_x(rr,a),ring.y+lengthdir_y(rr,a),lengthdir_x(50,a),lengthdir_y(30,a)-8,vfx_random_range(.5,.9),5,vfx_choose(4,5,6),FXP_PUFF,FXP_LIT,-6,1.5,.1,.75);budget--;}continue;}
        var k=h.kind;if(!(k=="dragon_arc" || k=="dragon_cone" || k=="dragon_magma" || k=="dragon_meteor" || k=="dragon_fire_ring" || k=="dragon_magma_cell"))continue;
        var n=min(budget,max(2,round(geo_area(h.g)/9000)));budget-=n;
        repeat(n){var pt=geo_sample(h.g,vfx_random(1),vfx_random(1));if(!telegraph_contains(h.g,pt.x,pt.y))continue;
            fxp_add(pt.x,pt.y,vfx_random_range(-8,8),-vfx_random_range(30,60),vfx_random_range(.2,.35),1,vfx_choose(1,2,2),vfx_choose(FXP_EMBER,FXP_PIXEL,FXP_STREAK),FXP_TOP,-30,2,vfx_random_range(0,.3));}
    }
}
/// Emission (Step, paused with the game): particles for charges and active beams.
function fx_attacks_step(_dt) {
    if(_dt<=0)return;
    fx_hazard_flames_step(_dt);
    var c=fx_dragon_charge();
    if(is_struct(c)) {
        fxp_gather(c.x,c.y,70+60*c.p,c.el,.35+.65*c.p);
        if(c.p>.3 && c.el==1)fxp_aura(c.bx,c.by-c.size*.35,c.size*.32,1,.5*c.p);
    }
    var beams=fx_fire_beams();
    for(var i=0;i<array_length(beams);i++) {
        var q=beams[i],len=fx_beam_visible_len(q.x,q.y,q.angle,q.len),fade=clamp((q.active-q.age)/.25,0,1);
        fxp_flame_line(q.x,q.y,q.angle,len,q.width*.8,fade,FXP_TOP);
        // ignition: shock ring at the mouth, short warm scene shift, a burst of sparks
        if(q.age<_dt*1.5){fx_shock(q.x,q.y,90,3,.3);fx_scene_tint(make_color_rgb(255,150,70),.1,.4);fx_aberration(1.5,.16);fxp_impact(q.x,q.y,1,.6);}
        // smoke lifting off the burnt path, lit by the fire (world light)
        if(vfx_random(1)<.5*fxp_rate()){var d=vfx_random(len),o=vfx_random_range(-.35,.35)*q.width;
            fxp_add(q.x+lengthdir_x(d,q.angle)+lengthdir_x(o,q.angle+90),q.y+lengthdir_y(d,q.angle)+lengthdir_y(o,q.angle+90),vfx_random_range(-10,10),-vfx_random_range(20,45),vfx_random_range(.7,1.2),8,vfx_choose(3,4,5),FXP_PUFF,FXP_LIT,-6,.8,0,.85);}
        // scorch marks along the path (dark, never glowing: lingering danger has its own look)
        if(vfx_random(1)<.12){var d=vfx_random(len);fxp_decal(q.x+lengthdir_x(d,q.angle),q.y+lengthdir_y(d,q.angle),q.width*.35,1,2.5);}
        // the end of a beam that lands inside the view splashes on the ground
        if(len>=q.len-1 && vfx_random(1)<.5)fxp_impact(q.x+lengthdir_x(len,q.angle),q.y+lengthdir_y(len,q.angle),1,.25);
    }
}
/// World-layer drawing (Draw End, before fx_post_world): glow sources and heat for charges and beams.
function fx_attacks_draw() {
    var t=current_time/1000,c=fx_dragon_charge();
    if(is_struct(c)) {
        var r=3+9*c.p+sin(t*26)*c.p,pal=vfx_palette(c.el);
        draw_set_alpha(.5*c.p);draw_set_color(pal[1]);draw_circle(round(c.x),round(c.y),round(r*1.8),false);
        draw_set_alpha(c.p);draw_set_color(pal[2]);draw_circle(round(c.x),round(c.y),round(r),false);
        draw_set_color(c_white);draw_circle(round(c.x),round(c.y),max(1,round(r*.45)),false);
        fx_heat_disc(c.x,c.y,26+40*c.p,.35+.5*c.p);
    }
    var beams=fx_fire_beams();
    for(var i=0;i<array_length(beams);i++) {
        var q=beams[i],len=fx_beam_visible_len(q.x,q.y,q.angle,q.len),fade=clamp((q.active-q.age)/.25,0,1),ux=lengthdir_x(1,q.angle),uy=lengthdir_y(1,q.angle);
        var ex=q.x+ux*len,ey=q.y+uy*len,pal=vfx_palette(1),fl=.85+.15*sin(t*31+i);
        // bright core inside the beam: the glow pass (bloom) turns it into the halo of the fire
        draw_set_alpha(.9*fade);draw_set_color(pal[1]);draw_line_width(round(q.x),round(q.y),round(ex),round(ey),max(2,round(q.width*.42*fl)));
        draw_set_alpha(fade);draw_set_color(pal[2]);draw_line_width(round(q.x),round(q.y),round(ex),round(ey),max(1,round(q.width*.18*fl)));
        draw_set_color(c_white);draw_line_width(round(q.x),round(q.y),round(q.x+ux*len*.45),round(q.y+uy*len*.45),max(1,round(q.width*.07)));
        fx_heat_line(q.x,q.y,ex,ey,q.width*1.5,.9*fade);
    }
    draw_set_alpha(1);draw_set_color(c_white);
}
/// Extra ground light of active fire beams (inside atmosphere_draw): a continuous pool along the whole beam.
function fx_attacks_lights(_rect) {
    var beams=fx_fire_beams();
    for(var i=0;i<array_length(beams);i++) {
        var q=beams[i],len=fx_beam_visible_len(q.x,q.y,q.angle,q.len),fade=clamp((q.active-q.age)/.25,0,1),n=clamp(ceil(len/110),2,7);
        // the mouth already has its own light (atmosphere_draw); the pool continues along the beam
        for(var k=1;k<=n;k++){var d=len*k/n;atmosphere_source(q.x+lengthdir_x(d,q.angle),q.y+lengthdir_y(d,q.angle),140+q.width,make_color_rgb(255,128+k*6,44),(.6-.03*k)*fade*(.9+.1*sin(current_time/45+k)),_rect);}
    }
    var c=fx_dragon_charge();
    if(is_struct(c))atmosphere_source(c.bx,c.by-c.size*.3,c.size*.9,c.el==4 ? make_color_rgb(190,110,255) : (c.el==2 ? make_color_rgb(120,230,220) : make_color_rgb(255,120,50)),.15*c.p,_rect);
}
