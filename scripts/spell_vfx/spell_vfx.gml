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
function spell_vfx_burst(_x,_y,_radius,_element) {
    var col=spell_element_color(_element),n=clamp(round(_radius/9),5,16);
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
        var col=spell_element_color(f.element),k=clamp(min(f.age*4,(f.duration-f.age)*3),0,1),fl=.85+.15*sin(current_time/90+i*1.7);
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
