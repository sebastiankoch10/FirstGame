/// Runtime for generated level worlds (Verfluchter Sumpf, Aschenfrost-Ruinen).
/// One ObjectLevelWorld owns ground chunks, prop instances, collision grid, hazards and bounded ambient effects.
/// Ground footprints are foreshortened ellipses (y * 0.64), matching the 40 degree prop renders.
#macro LEVEL_FOOT_Y 0.64
#macro LEVEL_CELL 256

function level_world_create() {
    var def=level_def(),fn=asset_get_index(def.layout);
    world_ready=false;
    if(fn<0 || def.world!="generated") return;
    data=script_execute(fn);
    world_def=def;level_id=def.id;
    ground_sprite=asset_get_index(def.id=="swamp" ? "spr_lv_sw_ground" : "spr_lv_af_ground");
    minimap_sprite=asset_get_index(def.id=="swamp" ? "spr_lv_sw_minimap" : "spr_lv_af_minimap");
    cull_x=-100000;cull_y=-100000;clock=0;
    texture_prefetch(def.id=="swamp" ? "Level_Swamp" : "Level_Ashfrost"); // avoid first-draw hitches in the crowd
    global.level_visible_props=[];global.level_occluders=[];global.level_glows=[];global.level_puffs=[];
    // Collision grid (16 x 16 cells of 256 px); blockers are inserted into every touched cell.
    var cells=(room_width div LEVEL_CELL+1)*(room_height div LEVEL_CELL+1);
    block_cols=room_width div LEVEL_CELL+1;
    global.level_block_grid=array_create(cells,0);for(var i=0;i<cells;i++)global.level_block_grid[i]=[];
    global.level_hazards=[];
    var meta=data.meta,props=data.props,n=array_length(props) div 4;
    prop_count=n;
    for(var i=0;i<n;i++) {
        var mi=props[i*4],px=props[i*4+1],py=props[i*4+2],flip=props[i*4+3],m=meta[mi];
        var inst=instance_create_layer(px,py,"Instances",ObjectLevelProp);
        inst.sprite_index=data.sprites[mi];inst.image_xscale=flip;inst.image_speed=0;inst.image_index=0;
        inst.prop_sway=m[3];inst.prop_glow_col=m[4];inst.prop_glow_r=m[5];inst.prop_glow_s=m[6];inst.prop_ground=m[7]==1;
        inst.prop_fade_w=m[8];inst.prop_fade_h=m[9];inst.prop_alpha=1;inst.prop_phase=vfx_random(10);
        inst.prop_shadow=!inst.prop_ground;inst.prop_block=m[0];inst.prop_ba=m[1];inst.prop_bb=m[2];
        inst.depth=inst.prop_ground ? 90000 : -py;inst.visible=false;
        if(m[0]==1)level_block_add(1,px,py,m[1],m[1]*LEVEL_FOOT_Y);
        else if(m[0]==2)level_block_add(2,px,py,m[1],max(6,m[2]*LEVEL_FOOT_Y));
    }
    var b=data.blockers;for(var i=0;i+2<array_length(b);i+=3)level_block_add(1,b[i],b[i+1],b[i+2],b[i+2]*LEVEL_FOOT_Y);
    var hz=data.hazards;
    for(var i=0;i+4<array_length(hz);i+=5)array_push(global.level_hazards,{kind:data.hazard_kinds[hz[i]],x:hz[i+1],y:hz[i+2],r:hz[i+3],phase:hz[i+4],x2:0,y2:0,line:false,state:"idle",hit:false,tick:0,cycle_prev:0});
    var hl=data.hazard_lines;
    for(var i=0;i+5<array_length(hl);i+=6)array_push(global.level_hazards,{kind:data.hazard_kinds[hl[i]],x:hl[i+1],y:hl[i+2],r:18,phase:hl[i+5],x2:hl[i+3],y2:hl[i+4],line:true,state:"idle",hit:false,tick:0,cycle_prev:0});
    water=data.water;water_count=array_length(water) div 2;
    // Bounded camera-relative ambient particles.
    motes=[];for(var i=0;i<(level_id=="swamp" ? 26 : 34);i++)array_push(motes,{x:vfx_random(1000),y:vfx_random(800),p:vfx_random(10),s:vfx_random_range(.6,1.4)});
    flakes=[];for(var i=0;i<(level_id=="swamp" ? 0 : 90);i++)array_push(flakes,{x:vfx_random(1000),y:vfx_random(800),s:vfx_random_range(.5,1.5),k:vfx_irandom(2)});
    pulse_timer=2;
    // One quiet ambient loop per world (own synthesized prototype), tied to the effects volume.
    ambient_handle=-1;var amb=asset_get_index(def.ambient_loop);
    if(audio_exists(amb)){ambient_handle=audio_play_sound(amb,4,true);audio_sound_gain(ambient_handle,0,0);}
    world_ready=true;
    show_debug_message("LEVEL_WORLD "+level_id+" props="+string(n)+" hazards="+string(array_length(global.level_hazards)));
}
function level_block_add(_kind,_x,_y,_a,_b) {
    var blk={k:_kind,x:_x,y:_y,a:_a,b:_b};
    var pad=28,c0=max(0,floor((_x-_a-pad)/LEVEL_CELL)),c1=min(block_cols-1,floor((_x+_a+pad)/LEVEL_CELL));
    var r0=max(0,floor((_y-_b-pad)/LEVEL_CELL)),r1=min(array_length(global.level_block_grid) div block_cols-1,floor((_y+_b+pad)/LEVEL_CELL));
    for(var r=r0;r<=r1;r++)for(var c=c0;c<=c1;c++)array_push(global.level_block_grid[r*block_cols+c],blk);
}
function level_point_blocked(_x,_y,_pad=0) {
    if(!variable_global_exists("level_block_grid") || !instance_exists(ObjectLevelWorld))return false;
    var cols=ObjectLevelWorld.block_cols,c=floor(_x/LEVEL_CELL),r=floor(_y/LEVEL_CELL);
    if(c<0 || r<0 || c>=cols || r*cols+c>=array_length(global.level_block_grid))return false;
    var list=global.level_block_grid[r*cols+c];
    for(var i=0;i<array_length(list);i++) {
        var b=list[i],dx=_x-b.x,dy=_y-b.y;
        if(b.k==1) {var ax=b.a+_pad,by=b.b+_pad*LEVEL_FOOT_Y;if((dx*dx)/(ax*ax)+(dy*dy)/(by*by)<=1)return true;}
        else if(abs(dx)<=b.a+_pad && abs(dy)<=b.b+_pad*LEVEL_FOOT_Y)return true;
    }
    return false;
}
function level_view_rect() {var r=combat_view_rect(-20);return {left:r.left-300,top:r.top-140,right:r.right+300,bottom:r.bottom+420};}
function level_world_cull() {
    var r=combat_view_rect(-20);
    if(abs(r.left-cull_x)<=48 && abs(r.top-cull_y)<=48)return;
    cull_x=r.left;cull_y=r.top;
    var vr=level_view_rect(),occ=[],glows=[];
    with(ObjectLevelProp) {
        visible=point_in_rectangle(x,y,vr.left,vr.top,vr.right,vr.bottom);
        if(visible) {
            if(prop_fade_h>0)array_push(occ,id);
            if(prop_glow_r>0)array_push(glows,id);
        }
    }
    global.level_occluders=occ;global.level_glows=glows;
}
function level_world_step(_dt) {
    if(world_ready && ambient_handle!=-1 && audio_is_playing(ambient_handle)) {
        var vol=variable_global_exists("effects_volume") ? global.effects_volume : .8;
        audio_sound_gain(ambient_handle,global.game_over ? 0 : vol*(global.game_paused ? .14 : .34),400);
    }
    if(!world_ready || global.game_paused || global.game_over)return;
    clock+=_dt;
    var pl=instance_exists(ObjectPlayer) ? ObjectPlayer : noone;
    global.level_speed_factor=1;global.level_player_hazard="";
    var minute=global.round_seconds/60,scale=global.base_monster_damage_multiplier*(1+minute*0.04);
    for(var i=0;i<array_length(global.level_hazards);i++) {
        var h=global.level_hazards[i];
        var inside=false;
        if(instance_exists(pl)) {
            if(h.line) inside=boss_point_segment_distance(pl.x,pl.y-8,h.x,h.y,h.x2,h.y2)<=h.r;
            else {var dx=(pl.x-h.x)/h.r,dy=(pl.y-6-h.y)/(h.r*0.92);inside=dx*dx+dy*dy<=0.86;}
        }
        switch(h.kind) {
            case "toxic":
                if(inside){global.level_player_hazard="toxic";h.tick-=_dt;if(h.tick<=0){h.tick=.5;player_receive_damage(pl,3*scale,"ground");}}else h.tick=0;
                break;
            case "mud":if(inside && pl.motion_state==player_motion_state.grounded){global.level_speed_factor=min(global.level_speed_factor,.76);global.level_player_hazard="mud";}break;
            case "ice":if(inside && pl.motion_state==player_motion_state.grounded){global.level_speed_factor=min(global.level_speed_factor,.84);global.level_player_hazard="ice";}break;
            case "spores":case "ember":case "fissure":
                // Readable cycle: idle -> telegraph (1.0 s) -> active (0.35 s). Damage only inside the announced shape.
                var period=h.kind=="fissure" ? 6.2 : 5.4,warn=h.kind=="fissure" ? 1.1 : 1.0,act=.35;
                var t=(clock+h.phase*1.37) mod period,start=period-warn-act;
                var st=t<start ? "idle" : (t<start+warn ? "warn" : "active");
                if(st!=h.state){if(st=="active"){h.hit=false;light_pulse(h.x,h.y,h.line ? 260 : 170,level_hazard_color(h.kind),.85,.3);}h.state=st;}
                h.warn_p=st=="warn" ? (t-start)/warn : (st=="active" ? 1 : 0);
                if(st=="active" && inside && !h.hit){if(player_receive_damage(pl,(h.kind=="fissure" ? 9 : 7)*scale,h.kind=="spores" ? "all" : "ground"))h.hit=true;}
                break;
        }
    }
    // Dynamic puffs (fungus deaths): short warning, one hit, then a fading cloud.
    for(var i=array_length(global.level_puffs)-1;i>=0;i--) {
        var p=global.level_puffs[i];p.age+=_dt;
        if(p.age>=p.warning && !p.fired){p.fired=true;light_pulse(p.x,p.y,140,make_color_rgb(150,220,90),.7,.25);
            if(instance_exists(pl) && point_distance(pl.x,pl.y-6,p.x,p.y)<=p.r)player_receive_damage(pl,p.damage,"all");}
        if(p.age>=p.warning+.7)array_delete(global.level_puffs,i,1);
    }
    // Sporadic ambient light impulses: toxic gas or magical flicker near the camera.
    pulse_timer-=_dt;
    if(pulse_timer<=0) {
        pulse_timer=vfx_random_range(2.2,4.5);
        var r=combat_view_rect(),best=noone;
        for(var i=0;i<array_length(global.level_hazards);i++){var h=global.level_hazards[i];if(point_in_rectangle(h.x,h.y,r.left-100,r.top-100,r.right+100,r.bottom+100)){best=h;break;}}
        if(is_struct(best))light_pulse(best.x,best.y,220,level_hazard_color(best.kind),.55,.6);
        else light_pulse(vfx_random_range(r.left,r.right),vfx_random_range(r.top,r.bottom),260,level_id=="swamp" ? make_color_rgb(110,190,120) : make_color_rgb(140,170,255),.35,.8);
    }
}
function level_puff_add(_x,_y,_r,_warning,_damage,_kind) {
    if(!variable_global_exists("level_puffs"))global.level_puffs=[];
    if(array_length(global.level_puffs)>=24)array_delete(global.level_puffs,0,1);
    array_push(global.level_puffs,{x:_x,y:_y,r:_r,warning:_warning,damage:_damage,kind:_kind,age:0,fired:false});
}
function level_hazard_color(_kind) {
    switch(_kind){case "toxic":return make_color_rgb(140,230,70);case "spores":return make_color_rgb(170,215,90);case "mud":return make_color_rgb(120,100,70);
        case "ember":return make_color_rgb(255,128,40);case "ice":return make_color_rgb(140,210,255);case "fissure":return make_color_rgb(150,120,255);}
    return c_white;
}
function level_speed_factor_for(_pl) {return variable_global_exists("level_speed_factor") && level_generated() ? global.level_speed_factor : 1;}

/// Ground layer: baked chunks plus living water and hazard surface details (drawn under props and actors).
function level_world_draw() {
    if(!world_ready)return;
    level_world_cull();
    var r=combat_view_rect(-24),chunk=512;
    for(var cy=max(0,floor(r.top/chunk));cy<=min(7,floor(r.bottom/chunk));cy++)
        for(var cx=max(0,floor(r.left/chunk));cx<=min(7,floor(r.right/chunk));cx++)
            draw_sprite(ground_sprite,cy*8+cx,cx*chunk,cy*chunk);
    var t=clock;
    // Water ripples and glints (swamp); frost glitter (ruins) reuse the same point list.
    for(var i=0;i<water_count;i++) {
        var wx=water[i*2],wy=water[i*2+1];
        if(wx<r.left-20 || wx>r.right+20 || wy<r.top-20 || wy>r.bottom+20)continue;
        var ph=frac(t*.28+i*.618);
        if(level_id=="swamp") {
            if(ph<.55){var p=ph/.55;draw_set_alpha((1-p)*.38);draw_set_color(make_color_rgb(120,160,150));draw_ellipse(wx-3-p*14,wy-2-p*6,wx+3+p*14,wy+2+p*6,true);}
            if(i mod 5==0){var b=frac(t*.6+i*.37);if(b<.25){draw_set_alpha(.5*(1-b*4));draw_set_color(make_color_rgb(150,190,170));draw_circle(wx+4,wy-2,1+b*6,true);}}
            if(i mod 3==0 && frac(t*.9+i*.29)<.12){draw_set_alpha(.7);draw_set_color(make_color_rgb(170,210,200));draw_point(wx-6,wy+1);draw_point(wx-5,wy+1);}
        } else if(frac(t*.7+i*.41)<.18){draw_set_alpha(.75);draw_set_color(make_color_rgb(210,240,255));draw_point(wx,wy);draw_point(wx+1,wy);draw_point(wx,wy-1);}
    }
    // Hazard surfaces.
    for(var i=0;i<array_length(global.level_hazards);i++) {
        var h=global.level_hazards[i];
        if(h.x+h.r<r.left-200 || h.x-h.r>r.right+200 || h.y+h.r<r.top-200 || h.y-h.r>r.bottom+200)if(!h.line)continue;
        var col=level_hazard_color(h.kind);
        if(h.kind=="toxic") {
            for(var k=0;k<7;k++){var bp=frac(t*.7+k*.137+h.phase),ang=k*51+h.phase*90,rr=h.r*.55*frac(k*.31+h.phase);
                var bx=h.x+lengthdir_x(rr,ang),by=h.y+lengthdir_y(rr*.6,ang);
                if(bp<.7){draw_set_alpha(.75*(1-bp/.7));draw_set_color(make_color_rgb(180,240,110));draw_circle(bx,by-bp*6,1.5+bp*3,true);}
                else {draw_set_alpha((1-bp)*2);draw_set_color(make_color_rgb(210,255,150));draw_circle(bx,by-4,4+(bp-.7)*12,true);}}
        } else if(h.kind=="mud") {
            for(var k=0;k<3;k++){var bp=frac(t*.25+k*.33+h.phase);var bx=h.x+lengthdir_x(h.r*.5*frac(k*.43+h.phase),k*120),by=h.y+lengthdir_y(h.r*.3,k*120);
                draw_set_alpha(.45*(1-bp));draw_set_color(make_color_rgb(70,62,48));draw_ellipse(bx-2-bp*10,by-1-bp*4,bx+2+bp*10,by+1+bp*4,true);}
        } else if(h.kind=="spores" || h.kind=="ember" || h.kind=="fissure") {
            if(h.state=="warn") {
                var g=h.line ? telegraph_make("line",h.x,h.y,point_distance(h.x,h.y,h.x2,h.y2),1,point_direction(h.x,h.y,h.x2,h.y2),0,h.r*2) : telegraph_make("circle",h.x,h.y,h.r,1);
                g.elapsed=h.warn_p;telegraph_draw(g,col);
            }
        }
    }
    draw_set_alpha(1);draw_set_color(c_white);
}
/// Above-lighting overlay: hazard bursts, glows, motes, falling ash/snow, fog banks.
function level_world_overlay() {
    if(!instance_exists(ObjectLevelWorld))return;
    with(ObjectLevelWorld) {
        if(!world_ready)return;
        var r=combat_view_rect(),ww=r.right-r.left,hh=r.bottom-r.top,t=clock;
        gpu_set_blendmode(bm_add);
        // Glowing props (mushrooms, lanterns, crystals, braziers) get a soft additive halo after the multiply pass.
        for(var i=0;i<array_length(global.level_glows);i++) {
            var p=global.level_glows[i];if(!instance_exists(p))continue;
            var fl=.75+.25*sin(t*3.1+p.prop_phase*2);
            draw_set_alpha(.10*fl*p.prop_glow_s);draw_set_color(p.prop_glow_col);
            draw_circle(p.x,p.y-14,p.prop_glow_r*.32,false);draw_set_alpha(.06*fl*p.prop_glow_s);draw_circle(p.x,p.y-14,p.prop_glow_r*.55,false);
            if(p.prop_glow_r>=180 && !p.prop_ground) {
                // Flickering flames: bounded rising sparks above braziers and the shrine orb.
                draw_set_color(merge_color(p.prop_glow_col,c_white,.35));
                for(var k=0;k<5;k++){var q=frac(t*(.9+k*.13)+p.prop_phase+k*.21);draw_set_alpha(.8*(1-q));draw_circle(p.x+sin(t*3+k*1.7+p.prop_phase)*5*(1+q),p.y-46-q*34,1.6*(1-q)+.6,false);}
                draw_set_alpha(.35*fl);draw_set_color(p.prop_glow_col);draw_circle(p.x,p.y-48,7+2*sin(t*9+p.prop_phase),false);
            }
        }
        for(var i=0;i<array_length(global.level_hazards);i++) {
            var h=global.level_hazards[i];
            if(!h.line && (h.x+h.r<r.left-60 || h.x-h.r>r.right+60 || h.y+h.r<r.top-60 || h.y-h.r>r.bottom+60))continue;
            var col=level_hazard_color(h.kind);
            if(h.kind=="toxic"){draw_set_alpha(.07+.03*sin(t*2+h.phase));draw_set_color(col);draw_ellipse(h.x-h.r,h.y-h.r*.6,h.x+h.r,h.y+h.r*.6,false);}
            if(h.state=="active") {
                draw_set_alpha(.42);draw_set_color(col);
                if(h.line){draw_line_width(h.x,h.y,h.x2,h.y2,h.r*1.6);draw_set_alpha(.6);draw_set_color(c_white);draw_line_width(h.x,h.y,h.x2,h.y2,3);}
                else for(var k=0;k<10;k++){var a=k*36+t*90,rr=h.r*(.3+.6*frac(t*2+k*.13));draw_circle(h.x+lengthdir_x(rr,a),h.y+lengthdir_y(rr*.6,a)-6-frac(t*2+k*.2)*20,5+k mod 3*2,false);}
            }
        }
        for(var i=0;i<array_length(global.level_puffs);i++) {
            var p=global.level_puffs[i];
            if(!p.fired){gpu_set_blendmode(bm_normal);var g=telegraph_make("circle",p.x,p.y,p.r,p.warning);g.elapsed=p.age;telegraph_draw(g,make_color_rgb(160,220,90));gpu_set_blendmode(bm_add);}
            else {var q=clamp((p.age-p.warning)/.7,0,1);draw_set_alpha(.35*(1-q));draw_set_color(make_color_rgb(150,215,90));
                for(var k=0;k<8;k++){var a=k*45;draw_circle(p.x+lengthdir_x(p.r*q*.8,a),p.y+lengthdir_y(p.r*q*.5,a)-q*14,6+q*10,false);}}
        }
        // Fireflies / magical motes.
        for(var i=0;i<array_length(motes);i++) {
            var m=motes[i],mx=r.left+((m.x+sin(t*.4*m.s+m.p)*40+t*6*m.s) mod (ww+40))-20,my=r.top+((m.y+cos(t*.33*m.s+m.p*2)*30) mod (hh+40))-20;
            var blink=.5+.5*sin(t*2.6*m.s+m.p*3);
            if(level_id=="swamp"){draw_set_color(make_color_rgb(190,235,110));draw_set_alpha(.55*blink);draw_circle(mx,my,1.2,false);draw_set_alpha(.12*blink);draw_circle(mx,my,4,false);}
            else {draw_set_color(i mod 3==0 ? make_color_rgb(255,150,60) : make_color_rgb(150,200,255));draw_set_alpha(.5*blink);draw_circle(mx,my-frac(t*.1*m.s+m.p)*hh*.3,1.1,false);}
        }
        gpu_set_blendmode(bm_normal);
        // Falling ash and snow (ruins): slow, sparse, drifting with the wind.
        var wind=variable_global_exists("weather") ? global.weather.wind : .3;
        for(var i=0;i<array_length(flakes);i++) {
            var f=flakes[i],fx=r.left+((f.x+t*(14+wind*40)*f.s+sin(t*.8+i)*8) mod (ww+20))-10,fy=r.top+((f.y+t*(26+f.k*10)*f.s) mod (hh+20))-10;
            if(f.k==0){draw_set_color(make_color_rgb(225,235,245));draw_set_alpha(.55);draw_point(fx,fy);draw_point(fx+1,fy);}
            else if(f.k==1){draw_set_color(make_color_rgb(120,116,114));draw_set_alpha(.5);draw_rectangle(fx,fy,fx+1,fy+1,false);}
            else {draw_set_color(make_color_rgb(200,205,215));draw_set_alpha(.35);draw_point(fx,fy);}
        }
        draw_set_alpha(1);draw_set_color(c_white);
    }
}
/// Light sources for atmosphere_draw (shared 72-source budget; capped here at 26).
function level_world_lights(_rect) {
    if(!instance_exists(ObjectLevelWorld) || !ObjectLevelWorld.world_ready)return;
    var used=0,t=ObjectLevelWorld.clock;
    for(var i=0;i<array_length(global.level_glows) && used<18;i++) {
        var p=global.level_glows[i];if(!instance_exists(p))continue;
        atmosphere_source(p.x,p.y-16,p.prop_glow_r,p.prop_glow_col,p.prop_glow_s*(.85+.15*sin(t*3+p.prop_phase)),_rect);used++;
    }
    for(var i=0;i<array_length(global.level_hazards) && used<26;i++) {
        var h=global.level_hazards[i];
        if(h.kind=="toxic"){atmosphere_source(h.x,h.y,h.r*2.2,make_color_rgb(110,200,60),.55+.1*sin(t*2+h.phase),_rect);used++;}
        else if(h.kind=="ember"){atmosphere_source(h.x,h.y,h.r*2.4,make_color_rgb(255,120,40),.5+.15*sin(t*5+h.phase)+(h.state=="active" ? .5 : 0),_rect);used++;}
        else if(h.state=="warn" || h.state=="active"){atmosphere_source(h.line ? (h.x+h.x2)/2 : h.x,h.line ? (h.y+h.y2)/2 : h.y,h.line ? 240 : h.r*2,level_hazard_color(h.kind),.4+.5*h.warn_p,_rect);used++;}
    }
}
/// Props: contact shadow, wind sway for plants/reeds, fade when the player stands behind tall props.
function level_prop_draw() {
    var alpha=1;
    if(prop_fade_h>0 && instance_exists(ObjectPlayer)) {
        var pl=ObjectPlayer;
        if(abs(pl.x-x)<prop_fade_w && pl.y<y-4 && pl.y>y-prop_fade_h)alpha=.42;
    }
    prop_alpha=lerp(prop_alpha,alpha,.25);
    if(prop_shadow)master_shadow_draw(x-6,y+3,max(14,sprite_get_width(sprite_index)*.18),max(5,sprite_get_width(sprite_index)*.05),.32);
    var sway=prop_sway>0 && variable_global_exists("weather") ? sin(global.weather.clock*1.6+x*.017)*(1+global.weather.wind*2.2) : 0;
    draw_sprite_ext(sprite_index,0,x,y,image_xscale,1,sway,c_white,prop_alpha);
}
function level_coin_hidden(_coin) {
    if(!variable_global_exists("level_occluders"))return false;
    for(var i=0;i<array_length(global.level_occluders);i++) {
        var p=global.level_occluders[i];if(!instance_exists(p))continue;
        if(abs(_coin.x-p.x)<p.prop_fade_w && _coin.y<p.y-4 && _coin.y>p.y-p.prop_fade_h)return true;
    }
    return false;
}
function level_minimap_draw(_x,_y,_size) {
    if(!instance_exists(ObjectLevelWorld) || !sprite_exists(ObjectLevelWorld.minimap_sprite))return;
    draw_sprite_ext(ObjectLevelWorld.minimap_sprite,0,_x,_y,_size/sprite_get_width(ObjectLevelWorld.minimap_sprite),_size/sprite_get_height(ObjectLevelWorld.minimap_sprite),0,c_white,.55);
    var sites=ObjectLevelWorld.data.sites;
    draw_set_color(make_color_rgb(232,204,133));draw_set_alpha(.8);
    for(var i=0;i<array_length(sites);i++){var sx=_x+sites[i].x/room_width*_size,sy=_y+sites[i].y/room_height*_size;draw_triangle(sx,sy-2,sx-2,sy+2,sx+2,sy+2,false);}
    draw_set_alpha(1);draw_set_color(c_white);
}
