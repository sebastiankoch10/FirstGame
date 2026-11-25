/// Distinct automatic mechanics, bounded effects and shared upgrades. Times in frames unless noted.
function spell_level(_sid) {
    var d=GetSpellData(_sid);if(!is_struct(d))return 0;
    var list=d.type==SPELL_TYPE.ACTIVE ? global.active_spells : global.passive_spells;
    for(var i=0;i<array_length(list);i++)if(list[i].id==_sid)return list[i].level;
    return 0;
}
function spell_bonus(_sid) {return spell_level(_sid)*GetSpellData(_sid).bonus_per_level;}
function spell_cold_duration_factor() {return 1+spell_level(SPELL.WINTER)*GetSpellData(SPELL.WINTER).status_duration_per_level;}
function spell_ids(_type) {
    var out=[],data=spell_catalog();
    for(var i=0;i<array_length(data);i++)if(data[i].type==_type && data[i].implemented)array_push(out,data[i].id);
    return out;
}
function spell_build_complete() {
    if(array_length(global.active_spells)!=6 || array_length(global.passive_spells)!=6)return false;
    for(var g=0;g<2;g++){var list=g==0 ? global.active_spells : global.passive_spells;for(var i=0;i<6;i++)if(list[i].level<9)return false;}
    return true;
}
function progression_try_level() {
    if(global.game_paused || global.game_over || global.round_seconds<global.next_levelup_time || spell_build_complete() || global.coins<global.coins_needed)return false;
    global.coins-=global.coins_needed;global.current_level++;global.coins_needed=progression_cost(global.current_level);
    talent_on_level(global.current_level);
    fg_sfx("level_up");handle_chest_selection("levelup");return true;
}
function spell_v2_init() {global.spell_fields=[];global.spell_bursts=[];global.spell_links=[];global.spell_trace_id=0;}
function spell_link(_ax,_ay,_bx,_by,_element) {
    if(array_length(global.spell_links)>=48)array_delete(global.spell_links,0,1);
    array_push(global.spell_links,{ax:_ax,ay:_ay,bx:_bx,by:_by,element:_element,life:.18});
}
function spell_v2_values(_sid,_level) {
    var d=GetSpellData(_sid);if(!is_struct(d))return undefined;
    var lv=clamp(floor(_level),1,9),pl=instance_exists(ObjectPlayer) ? ObjectPlayer : noone;
    if(d.type==SPELL_TYPE.PASSIVE) {
        var bonus=d.bonus_per_level*lv;
        if(_sid==SPELL.SHIELD)bonus=min(d.max_reduction,lv*d.bonus_per_level)*100;
        if(_sid==SPELL.MULTISHOT)bonus=ceil(lv/d.projectile_interval);
        return {damage:bonus,cooldown:0,level:lv,orbit_damage:d.shield_damage+lv*d.shield_damage_per_level,projectile_bonus:lv*d.bonus_per_level};
    }
    var power_value=instance_exists(pl) ? pl.player_power : 0;
    var area=instance_exists(pl) && variable_instance_exists(pl,"spell_area") ? pl.spell_area : 1;
    var cdr=instance_exists(pl) && variable_instance_exists(pl,"spell_cdr") ? pl.spell_cdr : 1;
    var extra=instance_exists(pl) ? pl.extra_projectiles : 0;
    var count=d.projectile_count;
    if(_sid==SPELL.FIREBALL || _sid==SPELL.ICEBALL || _sid==SPELL.ARC_BARRAGE)count+=extra;
    if(_sid==SPELL.ARC_BARRAGE)count+=floor((lv-1)/4);
    var damage=round(d.base_damage*(1+(lv-1)*d.scaling.level)+power_value*d.scaling.power);
    if(instance_exists(pl) && variable_instance_exists(pl,"split_bonus") && array_contains([101,102,105],_sid))damage+=pl.split_bonus;
    var conductor=instance_exists(pl) ? spell_level(SPELL.CONDUCTOR) : 0;
    return {damage:damage,cooldown:max(18,round(d.cooldown*(1-(lv-1)*d.cooldown_per_level)*cdr)),
        duration:d.duration+(lv-1)*.10,range:array_contains([101,102,105],_sid) ? d.projectile_speed*d.projectile_lifetime : d.target_range,
        radius:(d.explosion_radius+d.radius_per_level*(lv-1))*area,count:count,level:lv,
        chain_targets:_sid==SPELL.LIGHTNING ? d.chain_base+floor((lv-1)/3)+(conductor>=5 ? 1 : 0)+(conductor>=9 ? 1 : 0) : 0,
        chain_range:d.chain_range+(lv-1)*4,stages:d.base_count+floor((lv-1)/d.count_every),element:d.element};
}
/// _band: visual band 0-2 (vfx_band of the spell level). Radius stays the hit radius; band only sets intensity.
function spell_fx_burst(_x,_y,_radius,_element,_duration=.4,_band=2) {
    if(array_length(global.spell_bursts)>=64)array_delete(global.spell_bursts,0,1);
    array_push(global.spell_bursts,{x:_x,y:_y,radius:_radius,element:_element,age:0,duration:_duration,band:_band});
    light_pulse(_x,_y,min(280,_radius*1.7),spell_element_color(_element),.65*vfx_band_alpha(_band),min(.3,_duration));
    spell_vfx_burst(_x,_y,_radius,_element,_band);
}
function spell_element_color(_element) {
    var colors=[make_color_rgb(242,213,145),make_color_rgb(255,137,44),make_color_rgb(108,225,255),make_color_rgb(143,197,255),make_color_rgb(206,118,255),make_color_rgb(213,174,101),make_color_rgb(116,239,153),make_color_rgb(255,218,108)];
    return colors[clamp(_element,0,7)];
}
function spell_targets(_x,_y,_radius) {
    var out=[],types=[ObjectMonster,ObjectBossMonster];
    for(var t=0;t<2;t++)for(var i=0;i<instance_number(types[t]);i++) {
        var e=instance_find(types[t],i);
        if(e.hp>0 && combat_body_distance(e,_x,_y)<=_radius)array_push(out,e);
    }
    return out;
}
function spell_v2_hit(_target,_damage,_sid,_level=1) {
    if(!instance_exists(_target) || _target.hp<=0)return false;
    var d=GetSpellData(_sid),pl=ObjectPlayer;
    if(!apply_attack_damage(_target,_damage,pl,_sid))return false;
    var status=variable_instance_exists(pl,"status_factor") ? pl.status_factor : 1;
    if(d.element==2) {_target.slow_factor=min(_target.slow_time>0 ? _target.slow_factor : 1,d.slow_factor);_target.slow_time=max(_target.slow_time,round((d.slow_time+_level*d.slow_per_level)*status*spell_cold_duration_factor()));}
    if(d.element==3)_target.shock_time=max(_target.shock_time,round(d.shock_time*status));
    if(d.element==1) {
        var dot=(d.ignite_dps+_level*d.ignite_per_level)*(1+pl.fire_bonus);
        if(_target.burn_time<=0 || dot>=_target.burn_dps){_target.burn_dps=dot;_target.burn_spell_id=_sid;}
        _target.burn_time=max(_target.burn_time,round(d.ignite_time*status));
    }
    return true;
}
function spell_v2_area(_x,_y,_radius,_damage,_sid,_level=1) {
    var hits=spell_targets(_x,_y,_radius),count=0;
    for(var i=0;i<array_length(hits);i++)if(spell_v2_hit(hits[i],_damage,_sid,_level))count++;
    return count;
}
function spell_v2_line(_ax,_ay,_bx,_by,_width,_damage,_sid,_level=1) {
    var hits=spell_targets((_ax+_bx)*.5,(_ay+_by)*.5,point_distance(_ax,_ay,_bx,_by)*.5+_width),count=0;
    for(var i=0;i<array_length(hits);i++) {
        var e=hits[i];
        if(boss_point_segment_distance(e.x,e.y-10,_ax,_ay,_bx,_by)<=_width+e.contact_radius)if(spell_v2_hit(e,_damage,_sid,_level))count++;
    }
    return count;
}
function spell_v2_cast(_spell,_target,_v) {
    var sid=_spell.id,d=GetSpellData(sid),pl=ObjectPlayer;
    if(!instance_exists(_target) || array_length(global.spell_fields)>=48)return false;
    var aim=point_direction(pl.x,pl.y-10,_target.x,_target.y-10),tx=_target.x,ty=_target.y-10;
    var f={sid:sid,level:_spell.level,kind:d.mechanic,element:d.element,x:tx,y:ty,sx:pl.x,sy:pl.y-10,
        ex:pl.x+lengthdir_x(_v.range,aim),ey:pl.y-10+lengthdir_y(_v.range,aim),age:0,next:0,ticks:0,
        radius:_v.radius,damage:_v.damage,duration:_v.duration,count:_v.stages,angle:aim,hit_ids:[],return_done:false};
    if(sid==SPELL.LANCE) {
        spell_v2_line(f.sx,f.sy,f.ex,f.ey,f.radius,f.damage,sid,f.level);
        spell_fx_burst(tx,ty,64,4,.4,vfx_band(f.level));f.duration=.28;
    }
    if(sid==SPELL.ORBIT_BLADES || sid==SPELL.WISP){f.x=pl.x;f.y=pl.y-10;}
    if(sid==SPELL.STONE_SPIKES || sid==SPELL.STARFALL)f.duration=.4+f.count*.35;
    if(sid==SPELL.THUNDER_SEAL)f.duration=1.35;
    if(sid==SPELL.VERDICT)f.duration=1.2;
    if(sid==SPELL.PRISM){f.x=pl.x;f.y=pl.y-10;f.ex=tx;f.ey=ty;f.duration=2.5;}
    if(sid==SPELL.GLAIVE){f.x=pl.x;f.y=pl.y-10;f.ex=pl.x+lengthdir_x(min(380,point_distance(pl.x,pl.y,tx,ty)+80),aim);f.ey=pl.y-10+lengthdir_y(min(380,point_distance(pl.x,pl.y,tx,ty)+80),aim);}
    array_push(global.spell_fields,f);
    run_stats_cast(sid);fg_sfx(d.cue);_spell.cooldown=_v.cooldown;_spell.cooldown_timer=_v.cooldown;
    return true;
}
function spell_v2_step(_dt) {
    if(global.game_paused || !instance_exists(ObjectPlayer))return;
    var dt=min(.05,max(0,_dt)),pl=ObjectPlayer;
    for(var i=array_length(global.spell_links)-1;i>=0;i--){global.spell_links[i].life-=dt;if(global.spell_links[i].life<=0)array_delete(global.spell_links,i,1);}
    for(var i=array_length(global.spell_bursts)-1;i>=0;i--){global.spell_bursts[i].age+=dt;if(global.spell_bursts[i].age>=global.spell_bursts[i].duration)array_delete(global.spell_bursts,i,1);}
    for(var i=array_length(global.spell_fields)-1;i>=0;i--) {
        var f=global.spell_fields[i];f.age+=dt;
        switch(f.kind) {
            case "field":case "gravity":case "prison":
                if(f.kind=="gravity") {
                    var victims=spell_targets(f.x,f.y,f.radius);
                    for(var n=0;n<array_length(victims);n++){var e=victims[n];if(boss_is_actor(e))continue;var oldx=e.x,oldy=e.y,a=point_direction(e.x,e.y-10,f.x,f.y),pull=min(100*dt,point_distance(e.x,e.y-10,f.x,f.y));e.x+=lengthdir_x(pull,a);e.y+=lengthdir_y(pull,a);scenery_resolve(e,oldx,oldy);}
                }
                if(f.age>=f.next) {
                    spell_v2_area(f.x,f.y,f.radius,f.damage,f.sid,f.level);f.next=f.age+.5;f.ticks++;
                    if(f.kind=="prison"){var victims=spell_targets(f.x,f.y,f.radius);for(var n=0;n<array_length(victims);n++)if(!boss_is_actor(victims[n]))victims[n].hit_stun=max(victims[n].hit_stun,.18);}
                    spell_fx_burst(f.x,f.y,f.radius,f.element,.34,vfx_band(f.level));
                }break;
            case "orbit":
                f.x=pl.x;f.y=pl.y-10;
                if(f.age>=f.next){
                    for(var n=0;n<f.count;n++){var a=f.age*190+n*360/f.count;spell_v2_area(f.x+lengthdir_x(f.radius,a),f.y+lengthdir_y(f.radius,a),24,f.damage,f.sid,f.level);}
                    f.next=f.age+.42;
                }break;
            case "summon":
                f.x=pl.x+lengthdir_x(54,f.age*80);f.y=pl.y-45+lengthdir_y(20,f.age*80);
                if(f.age>=f.next){var target=combat_nearest(pl,f.radius);if(instance_exists(target)){spell_v2_hit(target,f.damage,f.sid,f.level);spell_link(f.x,f.y,target.x,target.y-12,6);spell_fx_burst(target.x,target.y-12,42,6,.4,vfx_band(f.level));f.angle=point_direction(f.x,f.y,target.x,target.y);f.ticks++;}f.next=f.age+max(.25,.65-f.level*.025);}
                break;
            case "spikes":case "meteor":
                if(f.ticks<f.count && f.age>=.28+f.ticks*.35){
                    var xx=f.kind=="spikes" ? f.sx+lengthdir_x(65+f.ticks*70,f.angle) : f.x+lengthdir_x(f.ticks*32,f.angle+f.ticks*137);
                    var yy=f.kind=="spikes" ? f.sy+lengthdir_y(65+f.ticks*70,f.angle) : f.y+lengthdir_y(f.ticks*32,f.angle+f.ticks*137);
                    spell_v2_area(xx,yy,f.radius,f.damage,f.sid,f.level);spell_fx_burst(xx,yy,f.radius,f.element,.45,vfx_band(f.level));f.ticks++;
                }break;
            case "seal":case "verdict":
                if(f.ticks==0 && f.age>=(f.kind=="seal" ? .9 : .72)) {spell_v2_area(f.x,f.y,f.radius,f.damage,f.sid,f.level);spell_fx_burst(f.x,f.y,f.radius,f.element,.45,vfx_band(f.level));f.ticks++;}
                break;
            case "glaive":
                var ox=f.x,oy=f.y,p=clamp(f.age/.55,0,1);
                if(f.age<.55){f.x=lerp(f.sx,f.ex,p);f.y=lerp(f.sy,f.ey,p);}
                else {if(!f.return_done){f.hit_ids=[];f.return_done=true;}p=clamp((f.age-.55)/.55,0,1);f.x=lerp(f.ex,pl.x,p);f.y=lerp(f.ey,pl.y-10,p);}
                var victims=spell_targets(f.x,f.y,f.radius+point_distance(ox,oy,f.x,f.y));
                for(var n=0;n<array_length(victims);n++){var e=victims[n];if(array_contains(f.hit_ids,e.id))continue;if(boss_point_segment_distance(e.x,e.y-10,ox,oy,f.x,f.y)<=f.radius+e.contact_radius){spell_v2_hit(e,f.damage,f.sid,f.level);array_push(f.hit_ids,e.id);}}
                break;
            case "seed":
                var a=point_direction(f.x,f.y,f.ex,f.ey),speed_value=430*dt*pl.projectile_factor,dist=point_distance(f.x,f.y,f.ex,f.ey);
                f.x+=lengthdir_x(min(dist,speed_value),a);f.y+=lengthdir_y(min(dist,speed_value),a);
                if(dist<=speed_value || f.age>2){
                    spell_v2_area(f.x,f.y,f.radius,f.damage,f.sid,f.level);
                    var victims=spell_targets(f.x,f.y,f.radius+130);for(var n=0;n<min(f.count,array_length(victims));n++){spell_v2_hit(victims[n],f.damage*.65,f.sid,f.level);spell_link(f.x,f.y,victims[n].x,victims[n].y-12,4);spell_fx_burst(victims[n].x,victims[n].y-12,44,4,.4,vfx_band(f.level));}
                    spell_fx_burst(f.x,f.y,f.radius,4,.4,vfx_band(f.level));f.age=f.duration;
                }break;
        }
        if(f.age>=f.duration)array_delete(global.spell_fields,i,1);
    }
    spell_passive_step(dt);
}
function spell_v2_draw() {
    for(var i=0;i<array_length(global.spell_links);i++){var link=global.spell_links[i];draw_set_alpha(link.life/.18);draw_set_color(spell_element_color(link.element));draw_line_width(link.ax,link.ay,link.bx,link.by,5);draw_set_color(c_white);draw_line_width(link.ax,link.ay,link.bx,link.by,1);}
    for(var i=0;i<array_length(global.spell_fields);i++) {
        var f=global.spell_fields[i],col=spell_element_color(f.element),fa=vfx_band_alpha(vfx_band(f.level));draw_set_color(col);draw_set_alpha(.5*fa);
        var fb=vfx_field_band(f);
        if(f.kind=="lance")vfx_lance_draw(f,fb,fa);
        else if(f.kind=="orbit")vfx_orbit_draw(f,fb,fa);
        else if(f.kind=="glaive")vfx_glaive_draw(f,fb,fa);
        else if(f.kind=="summon" || f.kind=="seed"){spell_fx_core_draw(f.x,f.y,42,f.element,(f.age mod .6)/.6,.9);}
        else if(f.kind=="gravity")vfx_gravity_draw(f,fb,fa);
        else if(f.kind=="seal" || f.kind=="verdict")vfx_pillar_draw(f,fb,fa);
        else if(f.kind=="field")vfx_ember_field_draw(f,fb,fa);
        else if(f.kind=="prison") {
            var b=vfx_band(f.level);vfx_pixel_ring(f.x,f.y,f.radius,col,.75*fa,f.age*20,0,2);
            for(var n=0;n<(b==0 ? 6 : (b==1 ? 8 : 12));n++){var a=n*360/(b==0 ? 6 : (b==1 ? 8 : 12)),xx=f.x+lengthdir_x(f.radius,a),yy=f.y+lengthdir_y(f.radius,a);vfx_pixel_shard(xx,yy,b==2 ? 22 : 16,make_color_rgb(190,236,255),fa);}
        } else if(f.kind=="spikes" || f.kind=="meteor") {
            for(var n=f.ticks;n<f.count;n++){
                var xx=f.kind=="spikes" ? f.sx+lengthdir_x(65+n*70,f.angle) : f.x+lengthdir_x(n*32,f.angle+n*137);
                var yy=f.kind=="spikes" ? f.sy+lengthdir_y(65+n*70,f.angle) : f.y+lengthdir_y(n*32,f.angle+n*137);
                vfx_pixel_ring(xx,yy,f.radius,col,.6*fa,f.age*40+n*30,3,2);if(f.kind=="meteor")vfx_pixel_streak(xx-40,yy-160,xx,yy-18,col,fa);
            }
        } else {
            var b=vfx_band(f.level),rot=f.age*(30+b*20);
            vfx_pixel_ring(f.x,f.y,f.radius,col,.7*fa,rot,b==0 ? 3 : (b==1 ? 4 : 0),b==2 ? 3 : 2);
            if(b>=1)vfx_pixel_ring(f.x,f.y,f.radius*.62,merge_color(col,c_white,.4),.45*fa,-rot*1.5,5,1);
            for(var n=0;n<(b==2 ? 8 : 6);n++){var a=n*360/(b==2 ? 8 : 6)+rot*2,px=round(f.x+lengthdir_x(f.radius*.85,a)),py=round(f.y+lengthdir_y(f.radius*.85,a));draw_set_alpha(.9*fa);draw_set_color(merge_color(col,c_white,.5));draw_rectangle(px-1,py-1,px+1,py+1,false);}
        }
    }
    for(var i=0;i<array_length(global.spell_bursts);i++){var e=global.spell_bursts[i];spell_fx_draw(e.x,e.y,e.radius,e.element,e.age/e.duration,vfx_band_alpha(variable_struct_exists(e,"band") ? e.band : 2));}
    draw_set_alpha(1);draw_set_color(c_white);
    spell_vfx_draw();
}
function spell_fx_draw(_x,_y,_radius,_element,_progress,_alpha) {
    // Pixel shock ring + core flash on the world grid; the 4-frame sprite only in the endgame band and capped in size,
    // so spells no longer show a large stretched block (Fähigkeiten, VFX & Audio 2/4).
    var col=spell_element_color(_element),k=clamp(1-_progress,0,1);
    vfx_pixel_ring(_x,_y,_radius*(.3+.7*_progress),col,.85*k*_alpha,_progress*90,0,_alpha>=1 ? 3 : 2);
    if(_progress<.25){var s=round(3+_radius*.06);draw_set_color(c_white);draw_set_alpha(_alpha);draw_rectangle(round(_x)-s,round(_y),round(_x)+s,round(_y),false);draw_rectangle(round(_x),round(_y)-s,round(_x),round(_y)+s,false);}
    // Middle band: a second, inner pixel ring instead of a sprite.
    if(_alpha<1){if(_alpha>=.8)vfx_pixel_ring(_x,_y,_radius*(.15+.5*_progress),merge_color(col,c_white,.45),.7*k,-_progress*140,4,1);return;}
    // Endgame band: the painted burst sprite as a core, capped in size (large areas are carried by the pixel rings).
    var row=_element==0 || _element==7 ? 4 : clamp(_element-1,0,5),spr=asset_get_index("spr_v2_fx_"+string(row));
    var frame=clamp(floor(_progress*4),0,3),size=min(_radius,110)*2/208;
    draw_sprite_ext(spr,frame,_x,_y,size,size,0,c_white,.85*clamp((1-_progress)*2,0,1));
}
/// Small persistent spell core (summon, seed, gravity): the painted 4-frame sprite at a fixed small radius.
function spell_fx_core_draw(_x,_y,_radius,_element,_progress,_alpha) {
    var row=_element==0 || _element==7 ? 4 : clamp(_element-1,0,5),spr=asset_get_index("spr_v2_fx_"+string(row));
    var frame=clamp(floor(_progress*4),0,3),size=_radius*2/208;
    draw_sprite_ext(spr,frame,_x,_y,size,size,0,c_white,_alpha*clamp((1-_progress)*2,0,1));
}
