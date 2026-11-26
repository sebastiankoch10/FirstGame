/// World post-processing (Grafik-Overhaul 26.11., docs/Design/Visuelles Leitbild & Animation.md 4.3 and 7).
/// Two layers per frame:
///   1. World layer: terrain, figures, lit by the overbright world light (atmosphere_draw), own effects, attack decor.
///      fx_post_world() then adds glow (bloom), heat shimmer, shock rings, chromatic offset, depth of field at the top
///      and bottom edges, level colour grading and a vignette, and writes the result back to the world surface.
///   2. Readability layer: enemy warnings, danger areas, boss bullets, markers, damage numbers. Drawn afterwards,
///      untouched by every post effect (Leitbild G5, G15: light, particles and blur never hide a danger).
/// Scaled by "Effektqualitaet" (fx_quality_flags) and "Lichtblitze: Reduziert" (fx_flash_k) like everything new.
#macro FX_MAX_SHOCKS 4

function fx_init() {
    if(variable_global_exists("fx") && is_struct(global.fx))return;
    global.fx={world:-1,half:-1,soft:-1,soft2:-1,q1:-1,q2:-1,e1:-1,e2:-1,heat:-1,black:-1,keep:-1,soft_sprite:-1,
        shocks:[],heats:[],tint:{col:c_white,k:0,life:0,total:1},ca:{k:0,life:0,total:1},
        metrics:{ms:0,active:false,shocks:0,heat:0},off:false,time:0};
}
/// What the current "Effektqualitaet" allows: Niedrig = grading and vignette only, Mittel = plus glow (near) and heat
/// shimmer, Hoch = everything (wide glow, depth of field, chromatic offset).
function fx_quality_flags() {
    var q=vfx_quality();
    // horde relief: with more than 110 enemies the edge blur and the wide glow pause (six fewer passes per frame;
    // a crowded screen also reads better without blur). Measured with the perf suite (horde, horde_coins).
    var crowd=instance_number(ObjectMonster)>110;
    return {bloom:q>=1,wide:q>=2 && !crowd,dof:q>=2 && !crowd,heat:q>=1,ca:q>=2};
}
/// Strength factor for flashing effects (scene colour shift, chromatic offset, glare); "Lichtblitze: Reduziert" = 35 %.
function fx_flash_k() {return light_flash_reduced() ? .35 : 1;}
/// Colour grading and lens per level. lift/gain are colour tints of shadows and highlights; ambient_k scales the
/// ambient light (the overbright light model needs a darker base so light sources can stand out).
function fx_level_profile() {
    static forest={lift:[.008,.014,.026],gamma:[1,1,1],gain:[1.06,1.01,.90],sat:1.12,contrast:1.06,vig:.26,vig_r:.55,
        bloom:{thr:.7,knee:.2,gain:1.1,near:.85,wide:.35},dof:{band:.33,ramp:.14,k:.55},ambient_k:.94,tint_shadow:make_color_rgb(40,62,84)};
    static swamp={lift:[.008,.022,.018],gamma:[1,1.02,1],gain:[.96,1.04,.95],sat:.98,contrast:1.06,vig:.28,vig_r:.55,
        bloom:{thr:.68,knee:.2,gain:1.1,near:.85,wide:.4},dof:{band:.33,ramp:.14,k:.55},ambient_k:.92,tint_shadow:make_color_rgb(30,70,60)};
    static ashfrost={lift:[.012,.018,.032],gamma:[1,1,1.02],gain:[1.03,1.0,1.04],sat:.92,contrast:1.06,vig:.27,vig_r:.55,
        bloom:{thr:.7,knee:.2,gain:1.1,near:.85,wide:.4},dof:{band:.33,ramp:.14,k:.55},ambient_k:.92,tint_shadow:make_color_rgb(50,60,90)};
    static neutral={lift:[0,0,0],gamma:[1,1,1],gain:[1,1,1],sat:1,contrast:1,vig:.3,vig_r:.5,
        bloom:{thr:.7,knee:.2,gain:1,near:.8,wide:.4},dof:{band:.3,ramp:.2,k:0},ambient_k:1,tint_shadow:c_black};
    if(room==Room1)return forest;
    if(!variable_global_exists("selected_level"))return neutral;
    var id_=level_def().id;
    return id_=="swamp" ? swamp : (id_=="ashfrost" ? ashfrost : forest);
}
/// Soft round sprite (radial gradient) for heat masks and haze; created once.
function fx_soft_sprite() {
    fx_init();
    if(sprite_exists(global.fx.soft_sprite))return global.fx.soft_sprite;
    var s=surface_create(64,64);if(!surface_exists(s))return -1;
    var mv=matrix_get(matrix_view),mp=matrix_get(matrix_projection);
    surface_set_target(s);draw_clear_alpha(c_black,0);
    for(var i=32;i>=1;i--){var k=1-i/32;draw_set_alpha(k*k*.14);draw_set_color(c_white);draw_circle(32,32,i,false);}
    draw_set_alpha(1);surface_reset_target();matrix_set(matrix_view,mv);matrix_set(matrix_projection,mp);
    global.fx.soft_sprite=sprite_create_from_surface(s,0,0,64,64,false,false,32,32);surface_free(s);
    return global.fx.soft_sprite;
}

// ---------------- events from gameplay effects (visual only) ----------------
/// Expanding shock ring that pushes pixels outward (impacts, stomps). _strength in pixels of displacement.
function fx_shock(_x,_y,_radius,_strength=3,_duration=.35) {
    fx_init();if(!fx_quality_flags().heat)return;
    if(array_length(global.fx.shocks)>=FX_MAX_SHOCKS)array_delete(global.fx.shocks,0,1);
    array_push(global.fx.shocks,{x:_x,y:_y,radius:_radius,strength:_strength,life:_duration,total:_duration});
}
/// Heat shimmer along a line for this frame (fire breath, fire fields). _k 0..1.
function fx_heat_line(_x1,_y1,_x2,_y2,_width,_k=1) {fx_init();array_push(global.fx.heats,{x1:_x1,y1:_y1,x2:_x2,y2:_y2,w:_width,k:_k});}
function fx_heat_disc(_x,_y,_r,_k=1) {fx_heat_line(_x,_y,_x,_y,_r*2,_k);}
/// Whole-scene colour shift for very strong attacks (reference: the scene briefly takes the attack colour).
function fx_scene_tint(_col,_k,_duration=.3) {
    fx_init();var k=_k*fx_flash_k();
    if(k>=global.fx.tint.k*(global.fx.tint.life/max(.001,global.fx.tint.total))){global.fx.tint={col:_col,k:k,life:_duration,total:_duration};}
}
/// Short chromatic offset of the world (heavy impacts). _px offset at the screen corner.
function fx_aberration(_px,_duration=.18) {
    fx_init();var k=_px*fx_flash_k();
    if(k>=global.fx.ca.k*(global.fx.ca.life/max(.001,global.fx.ca.total)))global.fx.ca={k:k,life:_duration,total:_duration};
}
function fx_step(_dt) {
    fx_init();var f=global.fx;f.time+=_dt;
    for(var i=array_length(f.shocks)-1;i>=0;i--){f.shocks[i].life-=_dt;if(f.shocks[i].life<=0)array_delete(f.shocks,i,1);}
    f.tint.life=max(0,f.tint.life-_dt);f.ca.life=max(0,f.ca.life-_dt);
}

// ---------------- post pass ----------------
function fx_surface(_name,_w,_h) {
    var s=global.fx[$ _name];
    if(!surface_exists(s) || surface_get_width(s)!=_w || surface_get_height(s)!=_h){if(surface_exists(s))surface_free(s);s=surface_create(_w,_h);global.fx[$ _name]=s;}
    return s;
}
/// Full-surface pass: draws _src into _dst (size of _dst) with the current shader.
function fx_pass(_dst,_src) {
    surface_set_target(_dst);draw_surface_stretched(_src,0,0,surface_get_width(_dst),surface_get_height(_dst));surface_reset_target();
}
function fx_blur(_a,_b,_spread) {
    static u=shader_get_uniform(sh_fx_blur,"u_dir");
    var w=surface_get_width(_a),h=surface_get_height(_a);
    shader_set(sh_fx_blur);
    shader_set_uniform_f(u,_spread/w,0);fx_pass(_b,_a);
    shader_set_uniform_f(u,0,_spread/h);fx_pass(_a,_b);
    shader_reset();
}
/// Post-process the world layer. Called from ObjectController Draw End after every world effect and before the
/// readability layer. The world surface is the current target; it is copied, processed and drawn back in place.
function fx_post_world() {
    static ub=shader_get_uniform(sh_fx_bright,"u_src_texel");
    static ut=shader_get_uniform(sh_fx_bright,"u_thresh");
    static u={res:shader_get_uniform(sh_fx_composite,"u_res"),time:shader_get_uniform(sh_fx_composite,"u_time"),bk:shader_get_uniform(sh_fx_composite,"u_bloom_k"),
        lift:shader_get_uniform(sh_fx_composite,"u_lift"),gamma:shader_get_uniform(sh_fx_composite,"u_gamma"),gain:shader_get_uniform(sh_fx_composite,"u_gain"),
        grade:shader_get_uniform(sh_fx_composite,"u_grade"),tint:shader_get_uniform(sh_fx_composite,"u_tint"),dof:shader_get_uniform(sh_fx_composite,"u_dof"),
        fx:shader_get_uniform(sh_fx_composite,"u_fx"),shock:shader_get_uniform(sh_fx_composite,"u_shock"),shock_w:shader_get_uniform(sh_fx_composite,"u_shock_w"),
        s_bloom:shader_get_sampler_index(sh_fx_composite,"u_bloom"),s_bloom2:shader_get_sampler_index(sh_fx_composite,"u_bloom2"),
        s_soft:shader_get_sampler_index(sh_fx_composite,"u_soft"),s_heat:shader_get_sampler_index(sh_fx_composite,"u_heat"),s_keep:shader_get_sampler_index(sh_fx_composite,"u_keep")};
    fx_init();var f=global.fx;f.metrics.active=false;
    if(f.off || !surface_exists(application_surface) || !instance_exists(ObjectPlayer))return;
    // fallback: without compiled shaders the world stays as lit (logged once)
    if(!shader_is_compiled(sh_fx_composite) || !shader_is_compiled(sh_fx_blur) || !shader_is_compiled(sh_fx_bright)){if(!variable_struct_exists(f,"warned")){f.warned=true;show_debug_message("FX_POST disabled: shaders not compiled");}return;}
    var stamp=get_timer(),W=VIEW_W,H=VIEW_H,r=combat_view_rect(),prof=fx_level_profile(),qf=fx_quality_flags();
    var mv=matrix_get(matrix_view),mp=matrix_get(matrix_projection),mw=matrix_get(matrix_world);
    matrix_set(matrix_world,matrix_build_identity());
    gpu_set_blendenable(false);gpu_set_texfilter(false);draw_set_alpha(1);draw_set_color(c_white);
    var world=fx_surface("world",W,H);fx_pass(world,application_surface);
    var black=fx_surface("black",4,4);surface_set_target(black);draw_clear(c_black);surface_reset_target();
    var bloom1=black,bloom2=black,soft=black,heat=black;
    gpu_set_texfilter(true);
    if(qf.bloom) {
        var q1=fx_surface("q1",W div 4,H div 4),q2=fx_surface("q2",W div 4,H div 4);
        shader_set(sh_fx_bright);shader_set_uniform_f(ub,1/W,1/H);shader_set_uniform_f(ut,prof.bloom.thr,prof.bloom.knee,prof.bloom.gain);
        fx_pass(q1,world);shader_reset();
        fx_blur(q1,q2,2);bloom1=q1; // one separable pass (perf: every target switch costs)
        if(qf.wide){var e1=fx_surface("e1",W div 8,H div 8),e2=fx_surface("e2",W div 8,H div 8);fx_pass(e1,q1);fx_blur(e1,e2,2.4);bloom2=e1;}
    }
    if(qf.dof && prof.dof.k>0){var s1=fx_surface("soft",W div 2,H div 2),s2=fx_surface("soft2",W div 2,H div 2);fx_pass(s1,world);fx_blur(s1,s2,2.2);soft=s1;}
    if(qf.heat && array_length(f.heats)>0) {
        heat=fx_surface("heat",W div 2,H div 2);var spr=fx_soft_sprite();
        surface_set_target(heat);draw_clear(c_black);gpu_set_blendenable(true);gpu_set_blendmode(bm_add);
        for(var i=0;i<array_length(f.heats);i++) {
            var h=f.heats[i],len=point_distance(h.x1,h.y1,h.x2,h.y2),cx=((h.x1+h.x2)*.5-r.left)*.5,cy=((h.y1+h.y2)*.5-r.top)*.5;
            if(sprite_exists(spr))draw_sprite_ext(spr,0,cx,cy,(len+h.w)*.5/64,h.w*.5/64,point_direction(h.x1,h.y1,h.x2,h.y2),c_red,clamp(h.k,0,1));
        }
        gpu_set_blendmode(bm_normal);gpu_set_blendenable(false);surface_reset_target();
    }
    f.metrics.heat=array_length(f.heats);f.heats=[];
    // keep-sharp mask: every enemy and boss stays sharp and is not darkened by the vignette (readability, G5)
    var keep=black;
    if(qf.dof || prof.vig>0) {
        keep=fx_surface("keep",W div 2,H div 2);var spr2=fx_soft_sprite();
        surface_set_target(keep);draw_clear(c_black);gpu_set_blendenable(true);gpu_set_blendmode(bm_max);
        if(sprite_exists(spr2)) {
            // a solid body shape (full keep over the whole figure incl. legs and shield, 3-4 px margin); primitives only,
            // so all enemies go into one batch; the bilinear lookup of the half-size mask softens its edge
            draw_set_color(c_white);draw_set_alpha(1);var l0=r.left-60,r0=r.right+60,t0=r.top-60,b0=r.bottom+90;
            with(ObjectMonster){if(x>l0 && x<r0 && y>t0 && y<b0){var cx=(x-r.left)*.5,cy=(y-30-r.top)*.5;draw_ellipse(cx-17,cy-24,cx+17,cy+22,false);}}
            with(ObjectBossMonster){var vh=variable_instance_exists(id,"visual_height") ? visual_height : 120,cx=(x-r.left)*.5,cy=(y-vh*.45-r.top)*.5;draw_ellipse(cx-vh*.32,cy-vh*.38,cx+vh*.32,cy+vh*.32,false);}
        }
        gpu_set_blendmode(bm_normal);gpu_set_blendenable(false);surface_reset_target();
    }
    // composite back onto the world surface (nearest for the world texture: distortion moves whole art pixels)
    matrix_set(matrix_view,mv);matrix_set(matrix_projection,mp);
    shader_set(sh_fx_composite);
    texture_set_stage(u.s_bloom,surface_get_texture(bloom1));texture_set_stage(u.s_bloom2,surface_get_texture(bloom2));
    texture_set_stage(u.s_soft,surface_get_texture(soft));texture_set_stage(u.s_heat,surface_get_texture(heat));texture_set_stage(u.s_keep,surface_get_texture(keep));gpu_set_tex_filter_ext(u.s_keep,true);
    gpu_set_tex_filter_ext(u.s_bloom,true);gpu_set_tex_filter_ext(u.s_bloom2,true);gpu_set_tex_filter_ext(u.s_soft,true);gpu_set_tex_filter_ext(u.s_heat,true);
    shader_set_uniform_f(u.res,W,H);shader_set_uniform_f(u.time,f.time);
    shader_set_uniform_f(u.bk,qf.bloom ? prof.bloom.near : 0,qf.wide ? prof.bloom.wide : 0,1);
    shader_set_uniform_f(u.lift,prof.lift[0],prof.lift[1],prof.lift[2]);shader_set_uniform_f(u.gamma,prof.gamma[0],prof.gamma[1],prof.gamma[2]);shader_set_uniform_f(u.gain,prof.gain[0],prof.gain[1],prof.gain[2]);
    shader_set_uniform_f(u.grade,prof.sat,prof.contrast,prof.vig,prof.vig_r);
    var tk=f.tint.k*power(f.tint.life/max(.001,f.tint.total),1.6);
    shader_set_uniform_f(u.tint,color_get_red(f.tint.col)/255,color_get_green(f.tint.col)/255,color_get_blue(f.tint.col)/255,clamp(tk,0,.6));
    var fy=clamp((ObjectPlayer.y-18-r.top)/H,.3,.7);
    shader_set_uniform_f(u.dof,fy,prof.dof.band,prof.dof.ramp,qf.dof ? prof.dof.k : 0);
    shader_set_uniform_f(u.fx,qf.heat ? 2.2 : 0,qf.ca ? f.ca.k*(f.ca.life/max(.001,f.ca.total)) : 0);
    var sh=array_create(FX_MAX_SHOCKS*4,0);
    for(var i=0;i<min(FX_MAX_SHOCKS,array_length(f.shocks));i++) {
        var s=f.shocks[i],p=1-s.life/s.total,e=1-power(1-p,2.2);
        sh[i*4]=(s.x-r.left)/W;sh[i*4+1]=(s.y-r.top)/H;sh[i*4+2]=max(1,s.radius*e);sh[i*4+3]=s.strength*(1-p);
    }
    shader_set_uniform_f_array(u.shock,sh);shader_set_uniform_f(u.shock_w,7);
    gpu_set_texfilter(false);
    draw_surface_stretched(world,r.left,r.top,W,H);
    shader_reset();gpu_set_blendenable(true);gpu_set_texfilter(false);
    matrix_set(matrix_world,mw);
    f.metrics.shocks=array_length(f.shocks);f.metrics.ms=(get_timer()-stamp)/1000;f.metrics.active=true;
}
function fx_cleanup() {
    if(!variable_global_exists("fx") || !is_struct(global.fx))return;
    var names=["world","half","soft","soft2","q1","q2","e1","e2","heat","black","keep"];
    for(var i=0;i<array_length(names);i++){var s=global.fx[$ names[i]];if(surface_exists(s))surface_free(s);global.fx[$ names[i]]=-1;}
}
