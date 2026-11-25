/// Bounded spell particles and persistent spell lights. Purely visual: no gameplay value is read back from here.
/// Elements (spell_element_color): 0 neutral, 1 fire, 2 ice, 3 storm, 4 arcane, 5 earth, 6 nature/wisp, 7 holy.
function spell_vfx_reset() {global.spell_particles=[];global.spell_vfx_clock=0;}
function spell_vfx_cap() {return 420;}
/// kind: 0 soft dot (pixel star), 1 streak (velocity aligned), 2 diamond spark, 3 rising rune square, 4 pixel spark
function spell_particle(_x,_y,_vx,_vy,_life,_size,_color,_kind=0,_grav=0) {
    if(!variable_global_exists("spell_particles"))spell_vfx_reset();
    if(array_length(global.spell_particles)>=spell_vfx_cap())array_delete(global.spell_particles,0,1);
    array_push(global.spell_particles,{x:_x,y:_y,vx:_vx,vy:_vy,life:_life,total:_life,size:_size,color:_color,kind:_kind,grav:_grav});
}
function spell_vfx_burst(_x,_y,_radius,_element,_band=2) {
    var col=spell_element_color(_element),n=max(3,round(clamp(round(_radius/9),5,16)*(_band==0 ? .5 : (_band==1 ? .75 : 1))));
    for(var i=0;i<n;i++) {
        var a=random(360),sp=random_range(40,120)*(.6+_radius/160);
        switch(_element) {
            case 1:spell_particle(_x+lengthdir_x(_radius*.3,a),_y+lengthdir_y(_radius*.3,a),lengthdir_x(sp*.5,a),lengthdir_y(sp*.5,a)-50,random_range(.35,.7),random_range(2,3.5),choose(col,make_color_rgb(255,214,120)),0,-40);break;
            case 2:spell_particle(_x,_y,lengthdir_x(sp,a),lengthdir_y(sp,a),random_range(.3,.55),random_range(2,3),choose(col,c_white),2,30);break;
            case 3:spell_particle(_x,_y,lengthdir_x(sp*1.4,a),lengthdir_y(sp*1.4,a),random_range(.12,.25),2,choose(col,c_white),1,0);break;
            case 5:spell_particle(_x+lengthdir_x(_radius*.4,a),_y+lengthdir_y(_radius*.25,a),lengthdir_x(sp*.4,a),-random_range(60,140),random_range(.35,.6),random_range(2,3),make_color_rgb(150,122,84),0,320);break;
            default:spell_particle(_x,_y,lengthdir_x(sp,a),lengthdir_y(sp,a),random_range(.3,.55),random_range(1.5,3),choose(col,merge_color(col,c_white,.5)),2,0);break;
        }
    }
}
/// Short trail for a moving projectile (called every step by spell_projectile_step).
function spell_vfx_trail(_x,_y,_dir,_kind) {
    if(!variable_global_exists("spell_vfx_clock"))spell_vfx_reset();
    var back=_dir+180;
    switch(_kind) {
        case "fire":spell_particle(_x+lengthdir_x(6,back),_y+lengthdir_y(6,back),lengthdir_x(30,back)+random_range(-15,15),lengthdir_y(30,back)-random_range(10,40),random_range(.2,.38),random_range(2,3.4),choose(make_color_rgb(255,140,50),make_color_rgb(255,214,120)),0,-30);break;
        case "ice":if(irandom(1)==0)spell_particle(_x+lengthdir_x(6,back),_y+lengthdir_y(6,back),random_range(-20,20),random_range(-20,20),random_range(.25,.4),random_range(1.5,2.5),choose(make_color_rgb(140,226,255),c_white),2,15);break;
        case "arcane":if(irandom(1)==0)spell_particle(_x,_y,random_range(-25,25),random_range(-25,25),random_range(.2,.32),2,choose(make_color_rgb(206,118,255),make_color_rgb(240,200,255)),2,0);break;
        case "wand":case "bolt":
            // An equipped weapon item tints the class-weapon trail in its rarity colour (visual only).
            var gear=variable_global_exists("equipment") && is_struct(global.equipment[$ "weapon"]);
            var tint=gear ? equipment_rarity_color(global.equipment[$ "weapon"].rarity) : (_kind=="wand" ? make_color_rgb(176,140,255) : make_color_rgb(190,255,160));
            if(_kind=="wand"){if(irandom(gear ? 1 : 2)==0)spell_particle(_x,_y,random_range(-18,18),random_range(-18,18),.22,2,tint,0,0);}
            else if(irandom(gear ? 2 : 3)==0)spell_particle(_x+lengthdir_x(8,back),_y+lengthdir_y(8,back),lengthdir_x(20,back),lengthdir_y(20,back),.14,1.5,tint,1,0);
            break;
        default:if(irandom(2)==0)spell_particle(_x,_y,random_range(-20,20),random_range(-20,20),.25,2,make_color_rgb(160,200,255),0,0);break;
    }
}
/// Continuous emitters for active spell fields and class effects.
function spell_vfx_step(_dt) {
    if(!variable_global_exists("spell_particles"))spell_vfx_reset();
    var dt=min(.05,max(0,_dt));global.spell_vfx_clock+=dt;
    var emit=global.spell_vfx_clock>=1/30;if(emit)global.spell_vfx_clock-=1/30;
    if(emit && variable_global_exists("spell_fields")) for(var i=0;i<array_length(global.spell_fields);i++) {
        var f=global.spell_fields[i],col=spell_element_color(f.element);
        // Basis band emits every second tick (half the particles); middle and endgame emit every tick.
        if(vfx_band(f.level)==0){f.vfx_skip=!(variable_struct_exists(f,"vfx_skip") && f.vfx_skip);if(f.vfx_skip)continue;}
        switch(f.kind) {
            case "field":
                repeat(2){var a=random(360),r=random(f.radius);spell_particle(f.x+lengthdir_x(r,a),f.y+lengthdir_y(r*.7,a),random_range(-8,8),-random_range(30,70),random_range(.4,.8),random_range(1.8,3),choose(col,make_color_rgb(255,214,120),make_color_rgb(255,96,40)),0,-20);}break;
            case "gravity":
                repeat(2){var a=random(360),r=f.radius*random_range(.7,1);var px=f.x+lengthdir_x(r,a),py=f.y+lengthdir_y(r,a),toward=point_direction(px,py,f.x,f.y)+35;spell_particle(px,py,lengthdir_x(r*1.6,toward),lengthdir_y(r*1.6,toward),.5,2,choose(col,make_color_rgb(240,200,255)),2,0);}break;
            case "prison":
                {var a=random(360),r=random(f.radius);spell_particle(f.x+lengthdir_x(r,a),f.y+lengthdir_y(r*.7,a)-30,random_range(-10,10),random_range(20,45),random_range(.5,.9),random_range(1.5,2.5),choose(col,c_white),2,0);}break;
            case "orbit":
                for(var n=0;n<f.count;n++){var a=f.age*190+n*360/f.count;spell_particle(f.x+lengthdir_x(f.radius,a),f.y+lengthdir_y(f.radius,a),lengthdir_x(40,a+90),lengthdir_y(40,a+90),.2,1.8,merge_color(col,c_white,.4),1,0);}break;
            case "summon":
                spell_particle(f.x+random_range(-5,5),f.y+random_range(-5,5),random_range(-12,12),random_range(5,25),random_range(.4,.7),random_range(1.8,3),choose(col,make_color_rgb(220,255,230)),0,-10);break;
            case "seal":case "verdict":
                {var a=random(360),r=random(f.radius);spell_particle(f.x+lengthdir_x(r,a),f.y+lengthdir_y(r*.7,a),0,-random_range(60,140),random_range(.3,.6),random_range(1.5,2.5),merge_color(col,c_white,.3),3,0);}break;
            case "glaive":
                spell_particle(f.x,f.y,random_range(-15,15),random_range(-15,15),.22,2.2,merge_color(col,c_white,.3),2,0);break;
            case "seed":
                repeat(2)spell_particle(f.x,f.y,random_range(-30,30),random_range(-30,30),.3,2,make_color_hsv(irandom(255),140,255),2,0);break;
            case "spikes":case "meteor":
                if(f.kind=="meteor" && f.ticks<f.count){var n=f.ticks,mx=f.x+lengthdir_x(n*32,f.angle+n*137),my=f.y+lengthdir_y(n*32,f.angle+n*137);spell_particle(mx-30+random_range(-6,6),my-130+random_range(-10,10),40,140,.25,2.5,choose(make_color_rgb(255,214,120),make_color_rgb(255,140,60)),1,0);}break;
        }
    }
    if(emit && variable_global_exists("class_effects")) for(var i=0;i<array_length(global.class_effects);i++) {
        var f=global.class_effects[i];
        if(f.kind=="mage_circle"){var a=random(360);spell_particle(f.x+lengthdir_x(f.radius*.85,a),f.y+lengthdir_y(f.radius*.85,a),0,-random_range(30,70),.5,2,make_color_rgb(190,150,255),3,0);}
        if((f.kind=="mage_star" || f.kind=="mage_star_nova") && f.age<1){var fl=clamp(f.age/.85,0,1),xx=lerp(f.sx,f.x,fl),yy=lerp(f.sy,f.y,fl)-sin(pi*fl)*180;repeat(2)spell_particle(xx+random_range(-6,6),yy+random_range(-6,6),random_range(-20,20),random_range(-20,20),.4,random_range(2,3),choose(make_color_rgb(200,160,255),make_color_rgb(255,240,200)),2,0);}
        if(f.kind=="ranger_rain" && f.age>.35){var a=random(360),r=f.radius*sqrt(random(1));spell_particle(f.x+lengthdir_x(r,a),f.y+lengthdir_y(r,a),random_range(-20,20),-random_range(20,50),.3,2,make_color_rgb(170,240,130),0,60);}
    }
    for(var i=array_length(global.spell_particles)-1;i>=0;i--) {
        var p=global.spell_particles[i];p.life-=dt;
        if(p.life<=0){array_delete(global.spell_particles,i,1);continue;}
        p.vy+=p.grav*dt;p.x+=p.vx*dt;p.y+=p.vy*dt;
    }
}
function spell_vfx_draw() {
    if(!variable_global_exists("spell_particles"))return;
    var r=combat_view_rect();gpu_set_blendmode(bm_add);
    // Soft additive ground glow under persistent fields (drawn under the particles).
    if(variable_global_exists("spell_fields")) for(var i=0;i<array_length(global.spell_fields);i++) {
        var f=global.spell_fields[i];
        if(!array_contains(["field","gravity","prison","seal","verdict"],f.kind))continue;
        var col=spell_element_color(f.element),k=clamp(min(f.age*4,(f.duration-f.age)*3),0,1)*vfx_band_alpha(vfx_band(f.level)),fl=.85+.15*sin(current_time/90+i*1.7);
        draw_set_color(col);
        for(var n=0;n<4;n++){draw_set_alpha(.05*k*fl);draw_ellipse(f.x-f.radius*(1-n*.2),f.y-f.radius*(1-n*.2)*.72,f.x+f.radius*(1-n*.2),f.y+f.radius*(1-n*.2)*.72,false);}
        if(f.kind=="field"){draw_set_color(make_color_rgb(255,214,120));for(var n=0;n<7;n++){var a=n*51.4+current_time/14,rr=f.radius*(.35+.5*frac(n*.37+current_time/1700));var fx=f.x+lengthdir_x(rr,a),fy=f.y+lengthdir_y(rr*.72,a),h=6+5*sin(current_time/70+n);draw_set_alpha(.35*k);draw_triangle(fx-3,fy,fx+3,fy,fx,fy-h,false);}}
    }
    if(array_length(global.spell_particles)==0){gpu_set_blendmode(bm_normal);draw_set_alpha(1);return;}
    for(var i=0;i<array_length(global.spell_particles);i++) {
        var p=global.spell_particles[i];
        if(p.x<r.left-20 || p.x>r.right+20 || p.y<r.top-20 || p.y>r.bottom+20)continue;
        var k=p.life/p.total,s=max(.6,p.size*(.45+.55*k));draw_set_color(p.color);
        switch(p.kind) {
            case 1:draw_set_alpha(.85*k);draw_line_width(p.x,p.y,p.x-p.vx*.05,p.y-p.vy*.05,max(1,s*.7));break;
            case 2:draw_set_alpha(.9*k);draw_triangle(p.x,p.y-s*1.4,p.x+s,p.y,p.x-s,p.y,false);draw_triangle(p.x,p.y+s*1.4,p.x+s,p.y,p.x-s,p.y,false);break;
            case 3:draw_set_alpha(.8*k);draw_rectangle(round(p.x-s*.7),round(p.y-s*.7),round(p.x+s*.7),round(p.y+s*.7),true);break;
            // Pixel spark: a square on the world pixel grid (docs/Design/Fähigkeiten, VFX & Audio.md 2.4).
            case 4:{draw_set_alpha(k);var px=round(p.x),py=round(p.y),ps=max(1,round(p.size));draw_rectangle(px,py,px+ps-1,py+ps-1,false);}break;
            // Soft dot as pixel star: core square plus a faint cross glow, both on the grid (was two vector circles).
            default:{var px=round(p.x),py=round(p.y),c=max(0,round(s*.6)),o=max(1,round(s*1.8));
                draw_set_alpha(.25*k);draw_rectangle(px-o,py,px+o,py,false);draw_rectangle(px,py-o,px,py+o,false);
                draw_set_alpha(.9*k);draw_rectangle(px-c,py-c,px+c,py+c,false);}break;
        }
    }
    gpu_set_blendmode(bm_normal);draw_set_alpha(1);draw_set_color(c_white);
}
/// Persistent light sources for active spell fields and class effects (multiplicative world light).
function spell_vfx_lights(_rect) {
    if(variable_global_exists("spell_fields")) for(var i=0;i<array_length(global.spell_fields);i++) {
        var f=global.spell_fields[i],col=spell_element_color(f.element),k=clamp(1-f.age/max(.01,f.duration),0,1);
        switch(f.kind) {
            case "field":case "gravity":case "prison":atmosphere_source(f.x,f.y,f.radius*1.5,col,.55+.15*sin(current_time/120+i),_rect);break;
            case "orbit":atmosphere_source(f.x,f.y,f.radius*1.8,col,.45,_rect);break;
            case "summon":case "glaive":case "seed":atmosphere_source(f.x,f.y,110,col,.75,_rect);break;
            case "seal":case "verdict":atmosphere_source(f.x,f.y,f.radius*1.6,col,.35+.5*(1-k),_rect);break;
            case "lance":atmosphere_source((f.sx+f.ex)/2,(f.sy+f.ey)/2,200,col,.7*k,_rect);break;
        }
    }
    if(variable_global_exists("class_effects")) for(var i=0;i<array_length(global.class_effects);i++) {
        var f=global.class_effects[i];
        if(f.kind=="mage_circle")atmosphere_source(f.x,f.y,f.radius*1.5,make_color_rgb(166,116,255),.55,_rect);
        else if((f.kind=="mage_star" || f.kind=="mage_star_nova") && f.age<1){var fl=clamp(f.age/.85,0,1);atmosphere_source(lerp(f.sx,f.x,fl),lerp(f.sy,f.y,fl)-sin(pi*fl)*180,150,make_color_rgb(200,160,255),.9,_rect);}
        else if(f.kind=="ranger_rain")atmosphere_source(f.x,f.y,f.radius*1.3,make_color_rgb(150,232,113),.35,_rect);
    }
}

// ---------------- Pixel effect building blocks (25.11.2026) ----------------
/// Ring of square dots on the world grid, rotating; _dash > 0 leaves out every _dash-th dot; _w = dot size.
function vfx_pixel_ring(_x,_y,_r,_col,_alpha,_rot=0,_dash=0,_w=2) {
    if(_alpha<=0 || _r<=1)return;
    var n=clamp(round(_r*2*pi/7),10,96);draw_set_color(_col);draw_set_alpha(clamp(_alpha,0,1));
    for(var i=0;i<n;i++) {
        if(_dash>0 && (i mod _dash)==0)continue;
        var a=_rot+i*360/n,px=round(_x+lengthdir_x(_r,a)),py=round(_y+lengthdir_y(_r,a));
        draw_rectangle(px,py,px+_w-1,py+_w-1,false);
    }
}
/// Upright ice shard as a pixel diamond (bright edge, cold core).
function vfx_pixel_shard(_x,_y,_h,_col,_alpha) {
    var x0=round(_x),y0=round(_y);draw_set_alpha(clamp(_alpha,0,1));
    for(var r=0;r<_h;r++){var w=max(0,round((1-abs(r-_h*.35)/(_h*.65))*4));draw_set_color(r<_h*.35 ? c_white : _col);draw_rectangle(x0-w,y0-r,x0+w,y0-r,false);}
}
/// Falling streak: a 2 px trail that brightens towards its head.
function vfx_pixel_streak(_ax,_ay,_bx,_by,_col,_alpha) {
    var n=12;
    for(var i=0;i<n;i++){var t=i/(n-1),px=round(lerp(_ax,_bx,t)),py=round(lerp(_ay,_by,t));draw_set_alpha(clamp(_alpha*(.2+.8*t),0,1));draw_set_color(t>.8 ? c_white : _col);draw_rectangle(px,py,px+1,py+1,false);}
}

/// ---- S4: composed pixel effects per spell (Fähigkeiten, VFX & Audio 2 and 4) ----
/// Every block sits on whole world pixels, uses the element palette (dark rim, body, light core) and grows with the
/// band (0 basis, 1 middle, 2 endgame) in parts and detail, not in area: the visible area stays the hitbox (G6).
/// No global RNG (vfx_hash), so seeded runs stay comparable.
function vfx_palette(_element) {
    static p=[
        [make_color_rgb(118,98,66),make_color_rgb(242,213,145),make_color_rgb(255,248,228)],   // physical
        [make_color_rgb(150,38,20),make_color_rgb(255,137,44),make_color_rgb(255,232,140)],    // fire
        [make_color_rgb(44,112,170),make_color_rgb(108,225,255),make_color_rgb(236,252,255)],  // ice
        [make_color_rgb(78,88,206),make_color_rgb(143,197,255),make_color_rgb(242,247,255)],   // lightning
        [make_color_rgb(74,32,124),make_color_rgb(206,118,255),make_color_rgb(246,228,255)],   // arcane / void
        [make_color_rgb(98,72,42),make_color_rgb(213,174,101),make_color_rgb(250,232,190)],    // earth
        [make_color_rgb(32,112,62),make_color_rgb(116,239,153),make_color_rgb(228,255,234)],   // nature
        [make_color_rgb(156,94,22),make_color_rgb(255,218,108),make_color_rgb(255,252,228)]    // holy
    ];
    return p[clamp(_element,0,7)];
}
/// Band of a spell field; honours the capture override like vfx_spell_band.
function vfx_field_band(_f) {return variable_global_exists("vfx_band_override") ? global.vfx_band_override : vfx_band(_f.level);}
/// One square art pixel block of size _s on the world grid.
function vfx_px(_x,_y,_s,_col,_alpha) {
    if(_alpha<=0)return;
    var px=round(_x),py=round(_y);draw_set_color(_col);draw_set_alpha(min(1,_alpha));draw_rectangle(px,py,px+_s-1,py+_s-1,false);
}
/// Solid pixel line on the world grid (one _w x _w block per pixel step, Bresenham-like).
function vfx_pixel_line(_ax,_ay,_bx,_by,_w,_col,_alpha) {
    if(_alpha<=0)return;
    var n=max(1,ceil(max(abs(_bx-_ax),abs(_by-_ay))));draw_set_color(_col);draw_set_alpha(min(1,_alpha));
    var h=floor(_w/2);
    for(var i=0;i<=n;i++){var px=round(lerp(_ax,_bx,i/n))-h,py=round(lerp(_ay,_by,i/n))-h;draw_rectangle(px,py,px+_w-1,py+_w-1,false);}
}
/// Soft additive glow (light layer of a composed effect); never darkens the ground.
function vfx_glow_line(_ax,_ay,_bx,_by,_w,_col,_alpha) {
    if(_alpha<=0)return;
    gpu_set_blendmode(bm_add);draw_set_color(_col);draw_set_alpha(min(1,_alpha));draw_line_width(_ax,_ay,_bx,_by,_w);gpu_set_blendmode(bm_normal);
}
function vfx_glow_disc(_x,_y,_r,_col,_alpha) {
    if(_alpha<=0)return;
    gpu_set_blendmode(bm_add);draw_set_color(_col);draw_set_alpha(min(1,_alpha));draw_circle(_x,_y,_r,false);gpu_set_blendmode(bm_normal);
}
/// Piercing Lance: additive glow over the hitbox width, solid 1 px edges, a 3 px light core with a body-coloured
/// rim, runes running to the tip (more with the band), sparks off the edges in the endgame band.
function vfx_lance_draw(_f,_b,_fa) {
    var pal=vfx_palette(_f.element),k=clamp(1-_f.age/max(.01,_f.duration),0,1),len=point_distance(_f.sx,_f.sy,_f.ex,_f.ey);
    if(len<2)return;
    var dir=point_direction(_f.sx,_f.sy,_f.ex,_f.ey),nx=lengthdir_x(1,dir+90),ny=lengthdir_y(1,dir+90),tick=floor(_f.age*40);
    var edge=_f.radius*.92,ax=_f.sx,ay=_f.sy,bx=_f.ex,by=_f.ey;
    vfx_glow_line(ax,ay,bx,by,_f.radius*2,pal[1],(.10+.06*_b)*k);
    vfx_pixel_line(ax+nx*edge,ay+ny*edge,bx+nx*edge,by+ny*edge,1,pal[1],.75*k*_fa);
    vfx_pixel_line(ax-nx*edge,ay-ny*edge,bx-nx*edge,by-ny*edge,1,pal[1],.75*k*_fa);
    vfx_pixel_line(ax,ay,bx,by,_b==0 ? 3 : 4,pal[1],k);
    vfx_pixel_line(ax,ay,bx,by,_b==0 ? 1 : 2,pal[2],k);
    var runes=_b==0 ? 2 : (_b==1 ? 3 : 5);
    for(var r=0;r<runes;r++) {
        var q=frac(_f.age*3.2+r/runes),cx=lerp(ax,bx,q),cy=lerp(ay,by,q),s=_b==2 ? 5 : 4;
        vfx_pixel_line(cx-s,cy,cx+s,cy,1,pal[2],k);vfx_pixel_line(cx,cy-s,cx,cy+s,1,pal[2],k);
    }
    if(_b==2)for(var s=0;s<8;s++){var q=(s+.5)/8,o=edge+3+3*vfx_hash(s,tick),sd=(s mod 2) ? 1 : -1,cx=lerp(ax,bx,q),cy=lerp(ay,by,q);vfx_pixel_line(cx+nx*edge*sd,cy+ny*edge*sd,cx+nx*o*sd,cy+ny*o*sd,1,pal[2],.8*k);}
}
/// Orbit Blades: solid pixel crescents facing their motion (2 px body, 1 px light inner edge), afterimages per band.
function vfx_orbit_draw(_f,_b,_fa) {
    var pal=vfx_palette(_f.element),ghosts=_b+1;
    for(var n=0;n<_f.count;n++)for(var g=ghosts;g>=0;g--) {
        var a=_f.age*190+n*360/_f.count-g*11,bx=_f.x+lengthdir_x(_f.radius,a),by=_f.y+lengthdir_y(_f.radius,a);
        var mv=a+90,cx=bx-lengthdir_x(6,mv),cy=by-lengthdir_y(6,mv),al=g==0 ? 1 : .55/g;
        for(var s=-60;s<=60;s+=6) {
            var sa=mv+s,tip=abs(s)>=48;
            if(g>0){vfx_px(cx+lengthdir_x(14,sa),cy+lengthdir_y(14,sa),1,pal[1],al*_fa);continue;}
            vfx_px(cx+lengthdir_x(14,sa),cy+lengthdir_y(14,sa),tip ? 1 : 2,pal[1],1);
            if(!tip)vfx_px(cx+lengthdir_x(12,sa),cy+lengthdir_y(12,sa),1,pal[2],1);
        }
        if(g==0)vfx_glow_disc(bx,by,10,pal[1],.10+.05*_b);
    }
}
/// Returning Glaive: a spinning four-armed pixel blade (solid arms, light tips), a hub and a motion trail.
function vfx_glaive_draw(_f,_b,_fa) {
    var pal=vfx_palette(_f.element),spin=_f.age*900;
    var dir=(_f.age<.55 || !instance_exists(ObjectPlayer)) ? point_direction(_f.sx,_f.sy,_f.ex,_f.ey) : point_direction(_f.x,_f.y,ObjectPlayer.x,ObjectPlayer.y-10);
    var tl=_b==0 ? 22 : (_b==1 ? 34 : 48);
    for(var g=0;g<3;g++)vfx_glow_disc(_f.x-lengthdir_x(tl*g/3,dir),_f.y-lengthdir_y(tl*g/3,dir),8-2*g,pal[1],(.12+.05*_b)*(1-.3*g));
    vfx_pixel_streak(_f.x-lengthdir_x(tl,dir),_f.y-lengthdir_y(tl,dir),_f.x,_f.y,pal[1],.6*_fa);
    for(var arm=0;arm<4;arm++) {
        var a=spin+arm*90,b2=a+28,mx=_f.x+lengthdir_x(9,a),my=_f.y+lengthdir_y(9,a),ex=mx+lengthdir_x(8,b2),ey=my+lengthdir_y(8,b2);
        vfx_pixel_line(_f.x,_f.y,mx,my,2,pal[1],1);vfx_pixel_line(mx,my,ex,ey,2,pal[1],1);vfx_px(ex,ey,1,pal[2],1);
        vfx_pixel_line(_f.x,_f.y,mx,my,1,pal[2],.8);
    }
    vfx_px(_f.x-1,_f.y-1,3,pal[0],1);vfx_px(_f.x,_f.y,1,pal[2],1);
    if(_b==2)vfx_pixel_ring(_f.x,_f.y,20,pal[1],.4,spin*.5,3,1);
}
/// Gravity Well: dashed rim on the hitbox, pixel motes spiralling inwards (void moves inwards), small core sprite.
function vfx_gravity_draw(_f,_b,_fa) {
    var pal=vfx_palette(_f.element),arms=_b==0 ? 4 : (_b==1 ? 5 : 7),parts=_b==2 ? 10 : 8;
    vfx_glow_disc(_f.x,_f.y,_f.radius*.55,pal[0],(.10+.04*_b)*_fa);
    vfx_pixel_ring(_f.x,_f.y,_f.radius,pal[1],.6*_fa,-_f.age*25,4,2);
    for(var arm=0;arm<arms;arm++)for(var p=0;p<parts;p++) {
        var rf=frac(p/parts-_f.age*.7+arm*.13),a=arm*360/arms+_f.age*60+(1-rf)*210,rr=_f.radius*rf;
        vfx_px(_f.x+lengthdir_x(rr,a),_f.y+lengthdir_y(rr,a),rf>.45 ? 2 : 1,rf<.3 ? pal[2] : (rf<.7 ? pal[1] : pal[0]),(.35+.65*(1-rf))*_fa);
    }
    spell_fx_core_draw(_f.x,_f.y,_b==2 ? 45 : 36,_f.element,(_f.age mod .6)/.6,.8);
}
/// Thunder Seal / Solar Verdict: rune circle on the ground while charging, energy falling into the centre, then a
/// stepped pixel pillar at the hit time (zigzag for lightning, straight with side rays for holy light).
function vfx_pillar_draw(_f,_b,_fa) {
    var pal=vfx_palette(_f.element),th=_f.kind=="seal" ? .9 : .72,p=clamp(_f.age/th,0,1),rot=_f.age*(40+_b*25);
    vfx_pixel_ring(_f.x,_f.y,_f.radius,pal[1],(.45+.4*p)*_fa,rot,_b==0 ? 3 : 4,2);
    if(_b>=1)vfx_pixel_ring(_f.x,_f.y,_f.radius*.6,pal[2],.5*_fa,-rot*1.4,5,1);
    var marks=_b==2 ? 8 : 6;
    for(var m=0;m<marks;m++){var a=m*360/marks+rot*1.5,mx=_f.x+lengthdir_x(_f.radius*.82,a),my=_f.y+lengthdir_y(_f.radius*.82,a);vfx_px(mx-1,my-1,3,pal[2],(.5+.5*p)*_fa);}
    if(_f.age<th) {
        // charge: a thin column of light falling into the centre
        var top=_f.y-230*(1-p),drops=_b+2;
        vfx_pixel_line(_f.x,top,_f.x,_f.y,1,pal[1],.7*_fa);vfx_glow_line(_f.x,top,_f.x,_f.y,6,pal[1],.12+.05*_b);
        for(var d=0;d<drops;d++){var dy=lerp(_f.y-230,_f.y,frac(_f.age*2.4+d/drops));vfx_px(_f.x-1,dy,2,pal[2],_fa);}
        return;
    }
    var k=clamp(1-(_f.age-th)/.3,0,1);if(k<=0)return;
    var w=(_b==0 ? 4 : (_b==1 ? 6 : 9))*(.5+.5*k),tick=floor(_f.age*30),seg=10;
    for(var yy=round(_f.y-260);yy<_f.y;yy+=seg) {
        var ox=_f.kind=="seal" ? round(vfx_hash(yy,tick)*(3+_b*2)) : 0;
        draw_set_alpha(.55*k);draw_set_color(pal[0]);draw_rectangle(round(_f.x+ox-w-2),yy,round(_f.x+ox+w+1),yy+seg-1,false);
        draw_set_alpha(.9*k);draw_set_color(pal[1]);draw_rectangle(round(_f.x+ox-w),yy,round(_f.x+ox+w-1),yy+seg-1,false);
        draw_set_alpha(k);draw_set_color(pal[2]);draw_rectangle(round(_f.x+ox-max(1,w*.35)),yy,round(_f.x+ox+max(1,w*.35)),yy+seg-1,false);
    }
    if(_f.kind=="verdict" && _b>=1)for(var r=0;r<(_b==2 ? 8 : 4);r++){var a=r*360/(_b==2 ? 8 : 4)+22.5,l=_f.radius*(.5+.5*(1-k));vfx_pixel_streak(_f.x,_f.y,_f.x+lengthdir_x(l,a),_f.y+lengthdir_y(l,a)*.6,pal[1],.8*k);}
    if(_f.kind=="seal" && _b>=1)for(var r=0;r<_b*2;r++){var a=vfx_hash(r,tick)*180+180,l=_f.radius*.7;var mx=_f.x+lengthdir_x(l*.5,a)+vfx_hash(r+7,tick)*8,my=_f.y+lengthdir_y(l*.5,a)*.6;vfx_px(mx,my,1,pal[2],k);vfx_pixel_streak(_f.x,_f.y-4,mx,my,pal[1],.7*k);}
}
/// Ember Field: faint ground glow inside the hitbox, flickering rim, embers rising from hashed spots.
function vfx_ember_field_draw(_f,_b,_fa) {
    var pal=vfx_palette(_f.element),tick=floor(_f.age*12);
    vfx_glow_disc(_f.x,_f.y,_f.radius,pal[0],(.10+.04*_b)*_fa);
    vfx_pixel_ring(_f.x,_f.y,_f.radius,pal[0],.7*_fa,_f.age*12,0,2);
    for(var i=0;i<(_b==0 ? 10 : (_b==1 ? 16 : 24));i++)if(vfx_hash(i,tick)>.2)vfx_px(_f.x+lengthdir_x(_f.radius,i*29+_f.age*12),_f.y+lengthdir_y(_f.radius,i*29+_f.age*12)-2,1,pal[1],.8*_fa);
    var embers=_b==0 ? 10 : (_b==1 ? 18 : 28);
    for(var i=0;i<embers;i++) {
        var a=vfx_hash(i,1)*180+180,rr=sqrt(abs(vfx_hash(i,2)))*_f.radius*.85,ph=frac(_f.age*(.8+.3*abs(vfx_hash(i,4)))+(vfx_hash(i,3)+1)*.5);
        var ex=_f.x+lengthdir_x(rr,a)+sin(_f.age*6+i)*2,ey=_f.y+lengthdir_y(rr,a)-ph*(18+_b*8);
        vfx_px(ex,ey,ph<.5 ? 2 : 1,ph<.3 ? pal[2] : (ph<.7 ? pal[1] : pal[0]),sin(ph*pi)*_fa);
    }
    if(_b==2)for(var t=0;t<5;t++){var a=t*72+_f.age*20,tx=_f.x+lengthdir_x(_f.radius*.45,a),ty=_f.y+lengthdir_y(_f.radius*.45,a),h=3+round(2*abs(vfx_hash(t,tick)));for(var s=0;s<h;s++)vfx_px(tx,ty-s*2,s==h-1 ? 1 : 2,s<1 ? pal[1] : pal[2],.85);}
}

/// Spell projectiles (Feuerball, Eiskugel, Arkansalve): soft additive trail and halo, the painted core sprite at
/// whole-pixel scale 1 (no stretching), element details on the pixel grid; more detail per band.
function vfx_projectile_draw(_kind,_x,_y,_dir,_radius,_band,_spr,_img,_tint=c_white) {
    var el=_kind=="fire" ? 1 : (_kind=="ice" ? 2 : 4),pal=vfx_palette(el),tl=18+_band*10,t=current_time/1000;
    for(var g=0;g<3;g++)vfx_glow_disc(_x-lengthdir_x(tl*g/3,_dir),_y-lengthdir_y(tl*g/3,_dir),_radius*(1-.28*g),pal[1],(.13+.05*_band)*(1-.3*g));
    if(_kind=="arcane") {
        // rune core: a pixel diamond with a light centre and motes circling it
        var s=5+_band*2;
        for(var r=s;r>=0;r--)vfx_pixel_line(_x-r,_y-(s-r),_x+r,_y-(s-r),1,r>s-2 ? pal[0] : pal[1],1);
        for(var r=s-1;r>=0;r--)vfx_pixel_line(_x-r,_y+(s-r),_x+r,_y+(s-r),1,r>s-2 ? pal[0] : pal[1],1);
        vfx_px(_x-1,_y-1,2,pal[2],1);
        for(var m=0;m<2+_band;m++){var a=t*360+m*360/(2+_band);vfx_px(_x+lengthdir_x(s+5,a),_y+lengthdir_y(s+5,a)*.7,_band==2 ? 2 : 1,pal[2],.9);}
        vfx_pixel_streak(_x-lengthdir_x(tl,_dir),_y-lengthdir_y(tl,_dir),_x,_y,pal[1],.7);
    } else {
        draw_sprite_ext(_spr,_img,round(_x),round(_y),1,1,_dir,_tint,1);
        if(_kind=="fire")for(var f=0;f<2+_band;f++){var bk=8+f*6+3*vfx_hash(f,floor(t*20)),sd=vfx_hash(f+5,floor(t*20))*5;vfx_px(_x-lengthdir_x(bk,_dir)+lengthdir_x(sd,_dir+90),_y-lengthdir_y(bk,_dir)+lengthdir_y(sd,_dir+90)-f,f==0 ? 2 : 1,f==0 ? pal[2] : pal[1],.9);}
        else for(var f=0;f<1+_band;f++){var bk=10+f*9,sx=_x-lengthdir_x(bk,_dir),sy=_y-lengthdir_y(bk,_dir);vfx_pixel_line(sx-lengthdir_x(3,_dir),sy-lengthdir_y(3,_dir),sx+lengthdir_x(3,_dir),sy+lengthdir_y(3,_dir),1,pal[2],.85);}
    }
}
/// Legacy area effects from effect_add (frost nova, heal, fire explosion, boss pulse) as pixel effects:
/// additive glow (never a dark or opaque disc), an expanding pixel ring and element details.
function vfx_area_effect_draw(_e) {
    var f=1-_e.life/_e.total,k=1-f,r=_e.radius,st=variable_struct_exists(_e,"style") ? _e.style : "";
    vfx_glow_disc(_e.x,_e.y,r*(.35+.65*f),_e.color,.22*k);
    vfx_pixel_ring(_e.x,_e.y,r*(.35+.65*f),_e.color,.9*k,f*60,0,2);
    vfx_pixel_ring(_e.x,_e.y,r,merge_color(_e.color,c_black,.35),.55*k,-f*40,4,1);
    if(st=="nova") {
        // ice shards fly out with the ring and stay upright (crystal language)
        var n=max(8,round(r/10));
        for(var i=0;i<n;i++){var a=i*360/n+7*vfx_hash(i,3),rr=r*(.3+.7*f)*(0.92+.08*vfx_hash(i,4));vfx_pixel_shard(_e.x+lengthdir_x(rr,a),_e.y+lengthdir_y(rr,a)*.9,round(8+6*k),_e.color,k);}
    } else if(st=="heal") {
        // green plus signs rise around the player
        for(var i=0;i<8;i++){var a=i*45+15*vfx_hash(i,9),rr=r*.55*(.6+.4*abs(vfx_hash(i,2))),px=_e.x+lengthdir_x(rr,a),py=_e.y+lengthdir_y(rr,a)*.6-f*26-6*abs(vfx_hash(i,5));
            vfx_pixel_line(px-2,py,px+2,py,1,merge_color(_e.color,c_white,.5),k);vfx_pixel_line(px,py-2,px,py+2,1,merge_color(_e.color,c_white,.5),k);}
    } else if(st=="fire") {
        // embers rise from the blast edge
        for(var i=0;i<10;i++){var a=i*36+20*vfx_hash(i,1),rr=r*(.5+.5*f),px=_e.x+lengthdir_x(rr,a),py=_e.y+lengthdir_y(rr,a)-f*14*abs(vfx_hash(i,2));vfx_px(px,py,f<.5 ? 2 : 1,f<.4 ? make_color_rgb(255,232,140) : _e.color,k);}
    }
}
