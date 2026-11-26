/// Character effects (Grafik-Overhaul, Ergänzung 26.11. abends; docs/Design/Visuelles Leitbild & Animation.md 7.5).
/// The sprites stay as they are (armour invisible); everything here is light and effect on top of them:
/// - rim light in the colour of the strongest nearby light (sh_fx_char), white hit flash;
/// - soft ground shadow that leans away from a strong light;
/// - dust on running, jumping, landing and the dodge roll, sparks on the roll;
/// - aura while a heavy attack charges; glow on the weapon tip and a glint along the blade.
/// Visual only (vfx_random), scaled by "Effektqualitaet" and "Lichtblitze".

// ---------------- light probe at the player (filled by atmosphere_source) ----------------
function fx_probe_reset() {
    global.fx_probe_last=variable_global_exists("fx_probe") ? global.fx_probe : {r:0,g:0,b:0,dx:0,dy:0,w:0};
    global.fx_probe={r:0,g:0,b:0,dx:0,dy:0,w:0};
}
/// One light source seen from the player (chest height). The player's own light (distance 0) has no direction.
function fx_probe_add(_x,_y,_radius,_color,_strength) {
    if(!variable_global_exists("fx_probe") || !instance_exists(ObjectPlayer))return;
    var px=ObjectPlayer.x,py=ObjectPlayer.y-18,d=point_distance(px,py,_x,_y);if(d<12 || d>_radius)return;
    var f=1-d/_radius,w=_strength*f*f,p=global.fx_probe;
    p.r+=color_get_red(_color)*w;p.g+=color_get_green(_color)*w;p.b+=color_get_blue(_color)*w;
    p.dx+=(_x-px)/d*w;p.dy+=(_y-py)/d*w;p.w+=w;
}
/// Key light for the figure: the probe, or a faint sky rim from the upper left (art direction) when nothing is near.
function fx_char_key() {
    var p=variable_global_exists("fx_probe_last") ? global.fx_probe_last : {w:0},sky=atmos_profile().shafts.col;
    var k=is_struct(p) && p.w>.02 ? clamp(p.w*1.6,0,1) : 0;
    var col=k>0 ? make_color_rgb(clamp(p.r/p.w,0,255),clamp(p.g/p.w,0,255),clamp(p.b/p.w,0,255)) : sky;
    var dx=-.7,dy=-.7;
    if(k>0){var l=point_distance(0,0,p.dx,p.dy);if(l>.001){dx=lerp(-.7,p.dx/l,k);dy=lerp(-.7,p.dy/l,k);}}
    var l2=max(.001,point_distance(0,0,dx,dy));
    return {col:col,k:max(.28,k),dx:dx/l2,dy:dy/l2};
}
/// Shader around the figure's draw (ObjectPlayer Draw). Returns true if set; pair with fx_char_end.
function fx_char_begin(_pl,_spr,_xs) {
    if(vfx_quality()==0 || !shader_is_compiled(sh_fx_char) || !sprite_exists(_spr))return false;
    static u_step=shader_get_uniform(sh_fx_char,"u_step");
    static u_rim=shader_get_uniform(sh_fx_char,"u_rim");
    static u_flash=shader_get_uniform(sh_fx_char,"u_flash");
    var key=fx_char_key(),tex=sprite_get_texture(_spr,0),tw=texture_get_texel_width(tex),th=texture_get_texel_height(tex);
    var ox=clamp(round(key.dx*1.3),-1,1)*sign(_xs==0 ? 1 : _xs),oy=clamp(round(key.dy*1.3),-1,1);
    if(ox==0 && oy==0)oy=-1;
    var flash=variable_instance_exists(_pl,"hud_hit_flash") ? clamp(_pl.hud_hit_flash/.2,0,1)*.7*fx_flash_k() : 0;
    shader_set(sh_fx_char);
    shader_set_uniform_f(u_step,ox*tw,oy*th);
    shader_set_uniform_f(u_rim,color_get_red(key.col)/255,color_get_green(key.col)/255,color_get_blue(key.col)/255,.55*key.k);
    shader_set_uniform_f(u_flash,1,.96,.9,flash);
    return true;
}
function fx_char_end(_on) {if(_on)shader_reset();}

// ---------------- shadow ----------------
/// Soft ground shadow as one gradient sprite (enemies and the figure; replaces four stacked ellipses: softer and
/// cheaper with big hordes). Niedrig keeps the old ellipses.
function fx_soft_shadow(_x,_y,_w,_h,_strength) {
    var spr=fx_soft_sprite();
    if(vfx_quality()==0 || !sprite_exists(spr)){master_shadow_draw(_x,_y,_w,_h,_strength);return false;}
    draw_sprite_ext(spr,0,round(_x),round(_y),_w*2.4/64,_h*2.4/64,0,make_color_rgb(5,10,20),min(1,_strength*1.3)); // centre about as dark as the old four ellipses
    return true;
}
/// Figure shadow: the soft shadow plus, under a strong light, a second, longer shadow away from it.
function fx_char_shadow(_x,_y,_w,_h,_strength) {
    if(!fx_soft_shadow(_x,_y,_w,_h,_strength))return;
    var spr=fx_soft_sprite(),c=make_color_rgb(5,10,20);
    var p=variable_global_exists("fx_probe_last") ? global.fx_probe_last : {w:0};
    if(is_struct(p) && p.w>.08) {
        var l=max(.001,point_distance(0,0,p.dx,p.dy)),k=clamp(p.w,0,1),ang=point_direction(0,0,-p.dx/l,-p.dy/l),len=_w*(1.2+1.6*k);
        draw_sprite_ext(spr,0,round(_x+lengthdir_x(len*.45,ang)),round(_y+lengthdir_y(len*.45,ang)*.5),len*2/64,_h*2/64,ang,c,min(.9,_strength*1.6*k));
    }
}

// ---------------- motion dust, roll sparks, aura (Step, paused with the game) ----------------
function fx_char_dust_el() {
    if(room==Room1 || !variable_global_exists("selected_level"))return 5;
    var id_=level_def().id;return id_=="swamp" ? 6 : (id_=="ashfrost" ? 8 : 5);
}
function fx_char_step(_dt) {
    if(_dt<=0 || !instance_exists(ObjectPlayer))return;
    var pl=ObjectPlayer.id,el=fx_char_dust_el();
    with(pl) {
        if(!variable_instance_exists(id,"fx_prev")){fx_prev={x:x,y:y,ms:motion_state,dodge:0,acc:0};}
        var mv=point_distance(x,y,fx_prev.x,fx_prev.y),grounded=motion_state==player_motion_state.grounded,dodge=variable_instance_exists(id,"dodge_timer") ? dodge_timer : 0;
        // running dust: a small puff every ~26 px on the ground
        if(grounded && dodge<=0 && hp>0){fx_prev.acc+=mv;if(fx_prev.acc>26){fx_prev.acc=0;if(vfx_random(1)<fxp_rate()+.2)fxp_add(x+vfx_random_range(-4,4),y+2,vfx_random_range(-10,10),-vfx_random_range(6,16),vfx_random_range(.35,.55),el,2,FXP_PUFF,FXP_LIT,-4,2,.45,.8);}}
        // take-off and landing
        if(fx_prev.ms==player_motion_state.grounded && !grounded)repeat(fxp_n(4))fxp_add(x+vfx_random_range(-6,6),y+2,vfx_random_range(-30,30),-vfx_random_range(5,20),vfx_random_range(.3,.5),el,2,FXP_PUFF,FXP_LIT,0,3,.45,.8);
        if(fx_prev.ms!=player_motion_state.grounded && grounded) {
            var n=fxp_n(10);for(var i=0;i<n;i++){var a=i*360/n+vfx_random(20);fxp_add(x+lengthdir_x(5,a),y+2+lengthdir_y(2,a),lengthdir_x(70,a),lengthdir_y(26,a)-6,vfx_random_range(.3,.5),el,vfx_choose(2,3),FXP_PUFF,FXP_LIT,0,4,.4,.85);}
        }
        // dodge roll: a burst at the start, then a dust trail and a few steel sparks off the ground
        if(dodge>0 && fx_prev.dodge<=0){repeat(fxp_n(6))fxp_add(x+vfx_random_range(-6,6),y+1,vfx_random_range(-40,40),-vfx_random_range(5,25),vfx_random_range(.3,.5),el,vfx_choose(2,3),FXP_PUFF,FXP_LIT,0,3,.4,.85);}
        if(dodge>0){var back=(variable_instance_exists(id,"dodge_direction") ? dodge_direction : 0)+180;
            if(vfx_random(1)<.8*fxp_rate())fxp_add(x+lengthdir_x(8,back),y+2,lengthdir_x(30,back)+vfx_random_range(-10,10),-vfx_random_range(4,14),vfx_random_range(.3,.5),el,2,FXP_PUFF,FXP_LIT,0,2,.45,.75);
            if(vfx_random(1)<.35*fxp_rate())fxp_add(x+lengthdir_x(6,back),y+2,lengthdir_x(vfx_random_range(60,140),back+vfx_random_range(-30,30)),-vfx_random_range(20,60),vfx_random_range(.12,.22),0,1,FXP_STREAK,FXP_EMIT,240,1,.1);}
        // aura while a heavy attack charges (Mage step 4, Ranger 3/9/12, sword whirl chain)
        var heavy=false,el2=0;
        if(variable_instance_exists(id,"class_pending") && class_pending>0){heavy=(global.selected_character=="Mage" && class_pending==4) || (global.selected_character=="Ranger" && (class_pending==3 || class_pending==9 || class_pending==12));el2=global.selected_character=="Mage" ? 4 : 6;}
        if(variable_instance_exists(id,"sword_combo_active") && sword_combo_active && variable_instance_exists(id,"sword_whirl_chain") && sword_whirl_chain){heavy=true;el2=0;}
        if(heavy)fxp_aura(x,y-6,16,el2,.9);
        fx_prev.x=x;fx_prev.y=y;fx_prev.ms=motion_state;fx_prev.dodge=dodge;
    }
}

// ---------------- weapon glow (emissive, world layer after the light) ----------------
/// Glow on the weapon: a glint that runs along the blade (sword), a pulsing orb (staff) or tip lights (bow); brighter
/// while attacking. Uses the hand anchor of the current frame (eqv_attach); nothing is drawn when the hand is hidden.
function fx_char_glow_draw() {
    if(vfx_quality()==0 || !instance_exists(ObjectPlayer))return;
    with(ObjectPlayer) {
        if(!variable_instance_exists(id,"fx_draw") || hp<=0)return;
        var d=fx_draw,at=eqv_attach(d.actor,d.spr,d.frame,d.x,d.y,d.xs,d.ys);if(!at.ok || at.conf<1)return;
        var t=current_time/1000,atk=attack_timer>0 || (variable_instance_exists(id,"sword_combo_active") && sword_combo_active),k=atk ? 1 : .45;
        var cls=global.selected_character,col=cls=="Mage" ? make_color_rgb(206,150,255) : (cls=="Ranger" ? make_color_rgb(190,244,160) : make_color_rgb(226,238,255));
        var ux=lengthdir_x(1,at.angle),uy=lengthdir_y(1,at.angle),len=max(6,at.length),tx=at.x+ux*len,ty=at.y+uy*len;
        if(cls=="Mage") {
            var r=1+k+.6*sin(t*7);draw_set_alpha(.5*k);draw_set_color(col);draw_circle(round(tx),round(ty),round(r+1),false);
            draw_set_alpha(.9*k);draw_set_color(c_white);draw_point(round(tx),round(ty));
            if(vfx_random(1)<.25*k*fxp_rate())fxp_add(tx,ty,vfx_random_range(-10,10),-vfx_random_range(10,30),.4,4,1,FXP_PIXEL,FXP_EMIT,-10,1,.2);
        } else {
            // a glint travels from the grip to the tip once per second (faster while attacking)
            var g=frac(t*(atk ? 2.4 : .8)),gx=lerp(at.x+ux*len*.3,tx,g),gy=lerp(at.y+uy*len*.3,ty,g);
            draw_set_alpha(.75*k);draw_set_color(col);draw_point(round(gx),round(gy));draw_point(round(gx-ux),round(gy-uy));
            draw_set_alpha(.6*k);draw_set_color(c_white);draw_point(round(tx),round(ty));
            if(atk && cls=="Sword" && vfx_random(1)<.3*fxp_rate())fxp_add(tx,ty,vfx_random_range(-40,40),vfx_random_range(-50,10),.18,0,1,FXP_STREAK,FXP_EMIT,120,2,.1);
        }
    }
    draw_set_alpha(1);draw_set_color(c_white);
}
