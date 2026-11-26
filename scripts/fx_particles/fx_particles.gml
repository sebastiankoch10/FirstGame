/// Shared pixel particle system on the world grid (Grafik-Overhaul 26.11., docs/Design/Fähigkeiten, VFX & Audio.md 2a).
/// Every particle is drawn on whole world pixels (1 art pixel = 1 surface pixel, render_pipeline), with a colour ramp
/// over its life (hot core -> body -> dark rim -> smoke). Two layers:
///   FXP_LIT  drawn before the world light (dust, ash, smoke, debris): they take the light of fire and magic.
///   FXP_EMIT drawn after the light (fire, sparks, magic, lightning): self-luminous, the source of the glow pass.
/// Visual only: own random generator (vfx_random), never the gameplay RNG; scaled by "Effektqualitaet".
#macro FXP_LIT 0
#macro FXP_EMIT 1
/// FXP_TOP: decoration of an enemy attack strictly inside its own danger area, drawn over the area fill but below
/// every warning (readability layer, not post-processed). Used where the danger surface itself is opaque (beams).
#macro FXP_TOP 2
#macro FXP_PIXEL 0
#macro FXP_STREAK 1
#macro FXP_SHARD 2
#macro FXP_EMBER 3
#macro FXP_PUFF 4
#macro FXP_FLASH 5

function fxp_reset() {global.fxp=[];global.fxp_decals=[];global.fxp_metrics={count:0,drawn:0,ms:0,peak:0};}
function fxp_init() {if(!variable_global_exists("fxp"))fxp_reset();}
/// Pool size per quality (Niedrig / Mittel / Hoch).
function fxp_cap() {static caps=[420,1000,1800];return caps[vfx_quality()];}
/// Emission rate per quality: callers multiply their particle counts with it.
function fxp_rate() {static r=[.3,.6,1];return r[vfx_quality()];}
function fxp_n(_n) {return max(1,round(_n*fxp_rate()));}
/// Colour ramps (start -> end of life). Element index as in vfx_palette.
function fxp_ramp(_el) {
    static ramps=[
        [make_color_rgb(255,252,236),make_color_rgb(240,226,190),make_color_rgb(190,176,150),make_color_rgb(110,100,90)],                              // physical
        [make_color_rgb(255,252,226),make_color_rgb(255,226,120),make_color_rgb(255,150,52),make_color_rgb(214,70,30),make_color_rgb(110,34,22)],        // fire
        [make_color_rgb(255,255,255),make_color_rgb(206,248,255),make_color_rgb(120,214,255),make_color_rgb(56,128,214)],                               // ice
        [make_color_rgb(255,255,255),make_color_rgb(214,238,255),make_color_rgb(140,190,255),make_color_rgb(92,104,240)],                               // lightning
        [make_color_rgb(255,246,255),make_color_rgb(240,196,255),make_color_rgb(190,112,255),make_color_rgb(102,52,190)],                               // arcane / void
        [make_color_rgb(250,232,190),make_color_rgb(213,174,101),make_color_rgb(140,104,62),make_color_rgb(80,60,40)],                                  // earth
        [make_color_rgb(236,255,200),make_color_rgb(150,236,110),make_color_rgb(70,168,72),make_color_rgb(34,92,44)],                                   // nature / poison
        [make_color_rgb(255,255,236),make_color_rgb(255,236,150),make_color_rgb(255,196,80),make_color_rgb(190,120,30)],                                // holy
        [make_color_rgb(96,88,82),make_color_rgb(78,72,70),make_color_rgb(60,58,60),make_color_rgb(44,44,48)]                                           // 8 smoke (lit)
    ];
    return ramps[clamp(_el,0,8)];
}
function fxp_ramp_color(_ramp,_t) {
    var n=array_length(_ramp)-1,f=clamp(_t,0,.9999)*n,i=floor(f);
    return merge_color(_ramp[i],_ramp[min(n,i+1)],f-i);
}
/// One particle. _t0 shifts the start along the ramp (0 = hottest). Returns false when the pool is full of newer ones.
function fxp_add(_x,_y,_vx,_vy,_life,_el,_size=1,_kind=FXP_PIXEL,_layer=FXP_EMIT,_grav=0,_drag=0,_t0=0,_alpha=1) {
    fxp_init();
    if(array_length(global.fxp)>=fxp_cap())array_delete(global.fxp,0,1);
    array_push(global.fxp,{x:_x,y:_y,vx:_vx,vy:_vy,life:_life,total:_life,ramp:fxp_ramp(_el),size:_size,kind:_kind,layer:_layer,
        grav:_grav,drag:_drag,t0:_t0,alpha:_alpha,seed:vfx_random(100)});
    return true;
}
function fxp_step(_dt) {
    fxp_init();var stamp=get_timer(),dt=min(.05,max(0,_dt)),p=global.fxp;
    for(var i=array_length(p)-1;i>=0;i--) {
        var q=p[i];q.life-=dt;
        if(q.life<=0){array_delete(p,i,1);continue;}
        if(q.drag>0){var d=max(0,1-q.drag*dt);q.vx*=d;q.vy*=d;}
        q.vy+=q.grav*dt;q.x+=q.vx*dt;q.y+=q.vy*dt;
    }
    var dc=global.fxp_decals;for(var i=array_length(dc)-1;i>=0;i--){dc[i].life-=dt;if(dc[i].life<=0)array_delete(dc,i,1);}
    global.fxp_metrics.count=array_length(p);global.fxp_metrics.peak=max(global.fxp_metrics.peak,array_length(p));global.fxp_metrics.ms=(get_timer()-stamp)/1000;
}
/// Draw one layer. Positions are rounded to whole world pixels; sizes are whole pixels.
function fxp_draw(_layer) {
    fxp_init();var r=combat_view_rect(),p=global.fxp,drawn=0,t=current_time/1000;
    if(_layer==FXP_LIT)fxp_decals_draw(r);
    for(var i=0;i<array_length(p);i++) {
        var q=p[i];if(q.layer!=_layer)continue;
        if(q.x<r.left-24 || q.x>r.right+24 || q.y<r.top-24 || q.y>r.bottom+24)continue;
        var life=1-q.life/q.total,col=fxp_ramp_color(q.ramp,q.t0+(1-q.t0)*life),a=q.alpha*(life<.85 ? 1 : (1-life)/.15),px=round(q.x),py=round(q.y);
        draw_set_color(col);drawn++;
        switch(q.kind) {
            case FXP_STREAK:{
                // velocity-aligned speed line, 1 px, length from speed (shrinks as it slows)
                var sp=point_distance(0,0,q.vx,q.vy),len=clamp(sp*.035,1,18)*(1-life*.6),ux=q.vx/max(1,sp),uy=q.vy/max(1,sp);
                draw_set_alpha(a);draw_line(px,py,round(q.x-ux*len),round(q.y-uy*len));
                if(q.size>1 && life<.5){draw_set_color(fxp_ramp_color(q.ramp,0));draw_point(px,py);}
            }break;
            case FXP_SHARD:{
                // crystal shard: a pixel diamond that tumbles (alternates its long axis)
                var s=max(1,round(q.size*(1-life*.5))),flip=(floor(t*14+q.seed) mod 2)==0;draw_set_alpha(a);
                if(flip){draw_rectangle(px,py-s,px,py+s,false);draw_point(px-1,py);draw_point(px+1,py);}
                else{draw_rectangle(px-s,py,px+s,py,false);draw_point(px,py-1);draw_point(px,py+1);}
                draw_set_color(fxp_ramp_color(q.ramp,0));draw_point(px,py);
            }break;
            case FXP_EMBER:{
                // flickering ember: 1-2 px, brightness jumps
                var fl=.55+.45*sin(t*31+q.seed*7),s=max(1,round(q.size*(1-life*.4)));
                draw_set_alpha(a*fl);draw_rectangle(px,py,px+s-1,py+s-1,false);
            }break;
            case FXP_PUFF:{
                // smoke / dust puff: a small irregular cloud of three pixel-edged discs that grows and thins out
                var s=max(1,round(q.size*(.5+life*1.2))),o=max(1,round(s*.6)),ph=q.seed;draw_set_alpha(a*.4*(1-life));
                draw_circle(px,py,s,false);draw_circle(px+round(o*cos(ph)),py-round(o*.6+o*.4*sin(ph)),max(1,s-1),false);draw_circle(px-round(o*sin(ph*1.7)),py-round(o*.3),max(1,round(s*.7)),false);
            }break;
            case FXP_FLASH:{
                // impact core: a white-hot disc that shrinks within a few frames
                var s=max(1,round(q.size*(1-life)));draw_set_alpha(a);draw_circle(px,py,s,false);
                draw_set_color(fxp_ramp_color(q.ramp,0));draw_circle(px,py,max(1,s-2),false);
            }break;
            default:{var s=max(1,round(q.size*(1-life*.5)));draw_set_alpha(a);draw_rectangle(px,py,px+s-1,py+s-1,false);}break;
        }
    }
    draw_set_alpha(1);draw_set_color(c_white);
    if(_layer==FXP_EMIT)global.fxp_metrics.drawn=drawn;
}

// ---------------- ground marks ----------------
/// Scorch / frost / burn mark on the ground (drawn in the lit layer, fades out). _el as vfx_palette.
function fxp_decal(_x,_y,_r,_el,_life=4) {
    fxp_init();if(array_length(global.fxp_decals)>=16)array_delete(global.fxp_decals,0,1);
    array_push(global.fxp_decals,{x:_x,y:_y,r:_r,el:_el,life:_life,total:_life,seed:vfx_irandom(999)});
}
function fxp_decals_draw(_r) {
    var dc=global.fxp_decals;
    for(var i=0;i<array_length(dc);i++) {
        var d=dc[i],k=min(1,d.life/(d.total*.5));if(d.x<_r.left-d.r || d.x>_r.right+d.r || d.y<_r.top-d.r || d.y>_r.bottom+d.r)continue;
        var col=d.el==1 ? make_color_rgb(34,22,18) : (d.el==2 ? make_color_rgb(200,236,255) : make_color_rgb(40,30,50));
        // irregular pixel blotch: a few overlapping ellipses on the grid, plus glowing cinders for fire
        draw_set_color(col);
        for(var n=0;n<3;n++){var a=vfx_hash(n,d.seed)*360,o=d.r*.35*(vfx_hash(n+7,d.seed)*.5+.5),rr=d.r*(.45+.25*(vfx_hash(n+3,d.seed)*.5+.5));
            draw_set_alpha((d.el==2 ? .22 : .32)*k);draw_ellipse(round(d.x+lengthdir_x(o,a)-rr),round(d.y+lengthdir_y(o*.6,a)-rr*.6),round(d.x+lengthdir_x(o,a)+rr),round(d.y+lengthdir_y(o*.6,a)+rr*.6),false);}
    }
    draw_set_alpha(1);
}
/// Glowing remains of fire decals (emissive, drawn with the emit layer by fxp_decals_glow).
function fxp_decals_glow() {
    fxp_init();var dc=global.fxp_decals,t=current_time/1000;
    for(var i=0;i<array_length(dc);i++) {
        var d=dc[i];if(d.el!=1)continue;var k=d.life/d.total;
        for(var n=0;n<6;n++){var a=vfx_hash(n+11,d.seed)*360,o=d.r*.55*(vfx_hash(n+17,d.seed)*.5+.5);
            draw_set_alpha(k*(.35+.35*sin(t*6+n*1.7)));draw_set_color(n mod 2==0 ? make_color_rgb(255,140,50) : make_color_rgb(255,210,110));
            draw_point(round(d.x+lengthdir_x(o,a)),round(d.y+lengthdir_y(o*.6,a)));}
    }
    draw_set_alpha(1);
}

// ---------------- composed building blocks ----------------
/// Impact (reference: white core flash, radial speed-line sparks, shock ring, smoke / shards, scorch mark, light).
/// _power 0..1 (small hit .25, spell hit .5-.8, boss impact 1). Visual only.
function fxp_impact(_x,_y,_el,_power=.6) {
    var p=clamp(_power,0,1.5),pal=vfx_palette(_el);
    fxp_add(_x,_y,0,0,.09+.05*p,_el,round(5+9*p),FXP_FLASH,FXP_EMIT);
    var n=fxp_n(8+18*p);
    for(var i=0;i<n;i++) {
        var a=vfx_random(360),sp=vfx_random_range(160,420)*(.6+.6*p);
        fxp_add(_x,_y,lengthdir_x(sp,a),lengthdir_y(sp,a),vfx_random_range(.12,.28),_el,1+(vfx_random(1)>.7),FXP_STREAK,FXP_EMIT,0,7,.05);
    }
    var m=fxp_n(6+14*p);
    for(var i=0;i<m;i++) {
        var a=vfx_random(360),sp=vfx_random_range(30,130)*(.5+.6*p);
        switch(_el) {
            case 2:fxp_add(_x,_y,lengthdir_x(sp*1.4,a),lengthdir_y(sp*1.4,a)-30,vfx_random_range(.35,.7),2,vfx_choose(1,2),FXP_SHARD,FXP_EMIT,260,1.5,.1);break;
            case 3:fxp_add(_x+vfx_random_range(-6,6),_y+vfx_random_range(-6,6),lengthdir_x(sp,a),lengthdir_y(sp,a),vfx_random_range(.08,.18),3,1,FXP_STREAK,FXP_EMIT,0,4,0);break;
            case 1:fxp_add(_x,_y,lengthdir_x(sp,a),lengthdir_y(sp,a)-vfx_random_range(20,70),vfx_random_range(.45,.9),1,vfx_choose(1,2),FXP_EMBER,FXP_EMIT,-60,2.5,.15);break;
            default:fxp_add(_x,_y,lengthdir_x(sp,a),lengthdir_y(sp,a),vfx_random_range(.25,.5),_el,1,FXP_PIXEL,FXP_EMIT,0,3,.1);break;
        }
    }
    if(_el==1 || _el==5 || _el==0)repeat(fxp_n(3+4*p))fxp_add(_x+vfx_random_range(-8,8),_y+vfx_random_range(-6,4),vfx_random_range(-15,15),-vfx_random_range(15,45),vfx_random_range(.6,1.1),8,round(3+4*p),FXP_PUFF,FXP_LIT,-10,1.2,0,.9);
    if(_el==2)repeat(fxp_n(3+3*p))fxp_add(_x+vfx_random_range(-10,10),_y+vfx_random_range(-6,6),vfx_random_range(-20,20),-vfx_random_range(5,20),vfx_random_range(.5,.9),2,round(3+4*p),FXP_PUFF,FXP_EMIT,0,1.5,.6,.5);
    if(p>=.45)fx_shock(_x,_y,30+70*p,1.5+2.5*p,.25+.15*p);
    if(_el==1 && p>=.4)fxp_decal(_x,_y+2,8+14*p,1,3+2*p);
    if(_el==2 && p>=.4)fxp_decal(_x,_y+2,8+12*p,2,2.5+2*p);
    light_pulse(_x,_y,60+110*p,pal[1],.8+.8*p,.16+.1*p);
}
/// Per-frame trail behind a moving projectile (fire: rising embers and smoke; ice: frost glitter; lightning/arcane:
/// crackling sparks). _speed in px/s.
function fxp_trail(_x,_y,_dir,_el,_speed=300,_size=1) {
    var back=_dir+180,j=4*_size;
    switch(_el) {
        case 1:
            repeat(fxp_n(3)){fxp_add(_x+vfx_random_range(-j,j),_y+vfx_random_range(-j,j),lengthdir_x(_speed*.15,back)+vfx_random_range(-20,20),lengthdir_y(_speed*.15,back)-vfx_random_range(20,60),vfx_random_range(.18,.42),1,vfx_choose(1,1,2),FXP_EMBER,FXP_EMIT,-80,2,vfx_random_range(0,.25));}
            if(vfx_random(1)<.35*fxp_rate())fxp_add(_x+lengthdir_x(6,back),_y+lengthdir_y(6,back),vfx_random_range(-8,8),-vfx_random_range(10,30),vfx_random_range(.5,.8),8,round(2+2*_size),FXP_PUFF,FXP_LIT,-8,1,0,.7);
            break;
        case 2:repeat(fxp_n(2))fxp_add(_x+vfx_random_range(-j,j),_y+vfx_random_range(-j,j),lengthdir_x(_speed*.08,back)+vfx_random_range(-14,14),lengthdir_y(_speed*.08,back)+vfx_random_range(-14,14),vfx_random_range(.25,.5),2,1,vfx_choose(FXP_PIXEL,FXP_SHARD),FXP_EMIT,40,1.5,.15);break;
        case 3:case 4:repeat(fxp_n(2))fxp_add(_x+vfx_random_range(-j,j),_y+vfx_random_range(-j,j),vfx_random_range(-60,60),vfx_random_range(-60,60),vfx_random_range(.06,.14),_el,1,FXP_STREAK,FXP_EMIT,0,3,0);break;
        default:repeat(fxp_n(2))fxp_add(_x,_y,lengthdir_x(_speed*.1,back),lengthdir_y(_speed*.1,back),vfx_random_range(.15,.3),_el,1,FXP_PIXEL,FXP_EMIT,0,2,.1);break;
    }
}
/// Rising aura around a figure or a charging origin (_k 0..1 intensity, _r radius).
function fxp_aura(_x,_y,_r,_el,_k=1) {
    if(vfx_random(1)>_k)return;
    repeat(fxp_n(2)){var a=vfx_random(360),rr=_r*vfx_random_range(.5,1);
        fxp_add(_x+lengthdir_x(rr,a),_y+lengthdir_y(rr*.55,a),vfx_random_range(-6,6),-vfx_random_range(30,80),vfx_random_range(.35,.7),_el,vfx_choose(1,1,2),_el==1 ? FXP_EMBER : FXP_PIXEL,FXP_EMIT,-20,1,vfx_random_range(.1,.4));}
}
/// Converging stream into a charging origin (energy gathers, Visuelles Leitbild 3a): particles start on a ring and fly in.
function fxp_gather(_x,_y,_r,_el,_k=1) {
    if(vfx_random(1)>_k)return;
    repeat(fxp_n(2)){var a=vfx_random(360),rr=_r*vfx_random_range(.7,1.1),life=vfx_random_range(.25,.4);
        fxp_add(_x+lengthdir_x(rr,a),_y+lengthdir_y(rr,a),-lengthdir_x(rr/life,a),-lengthdir_y(rr/life,a),life,_el,1,FXP_STREAK,FXP_EMIT,0,0,.35);}
}
/// Flames along a beam (x,y origin, angle, length, width): tongues licking forward, embers lifting off. Particles are
/// spawned inside 80 % of the hit width and travel along the beam, so the decoration never paints danger outside it.
/// _layer FXP_TOP for enemy beams (over their opaque surface), FXP_EMIT for own effects.
function fxp_flame_line(_x,_y,_ang,_len,_w,_k=1,_layer=FXP_EMIT) {
    var ux=lengthdir_x(1,_ang),uy=lengthdir_y(1,_ang),nx=-uy,ny=ux,n=fxp_n(10*_k*clamp(_len/300,.5,2));
    for(var i=0;i<n;i++) {
        var d=vfx_random(_len),o=vfx_random_range(-.4,.4)*_w*(.4+.6*clamp(d/60,0,1)),sp=vfx_random_range(140,320);
        // along the beam only (no sideways drift), so a particle never leaves the hit width
        fxp_add(_x+ux*d+nx*o,_y+uy*d+ny*o,ux*sp,uy*sp,vfx_random_range(.08,.2),1,vfx_choose(1,1,2),vfx_choose(FXP_PIXEL,FXP_EMBER,FXP_STREAK,FXP_STREAK),_layer,0,3,vfx_random_range(0,.35));
    }
}
