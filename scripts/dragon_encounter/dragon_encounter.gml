/// Four deterministic HP phases; all warnings and hits share the owner's elapsed time.
function dragon_encounter_config(_kind,_phase=1) {
    var fast=_phase>=3 ? .88 : 1;
    switch(_kind) {
        case "beam":return {warning:1.2*fast,active:1,damage:36,height:"high",radius:1200,shape:"line",span:0,width:48};
        case "arc":return {warning:1.0*fast,active:.7,damage:32,height:"ground",radius:360,shape:"sector",span:150,width:48};
        case "sweep":return {warning:1.2*fast,active:1.45,damage:30,height:"high",radius:650,shape:"sector",span:110,width:48};
        case "meteor":return {warning:1.8,active:1.8,damage:38,height:"all",radius:75,shape:"circle",span:360,width:0};
        case "slam":return {warning:1.5,active:1.1,damage:42,height:"ground",radius:320,shape:"circle",span:360,width:40};
        case "wind":return {warning:.9,active:1.7,damage:14,height:"high",radius:720,shape:"sector",span:100,width:48};
        case "void":return {warning:.8,active:1.6,damage:24,height:"high",radius:900,shape:"sector",span:60,width:48};
        case "stomp":return {warning:1.05,active:.55,damage:64,height:"all",radius:125+(_phase>=3 ? 10 : 0),shape:"circle",span:360,width:0};
        case "vortex":return {warning:1.7,active:1.6,damage:32,height:"ground",radius:310,shape:"ring",span:360,width:250};
        case "volley":return {warning:.65,active:1.7,damage:20,height:"high",radius:900,shape:"sector",span:70,width:48};
    }
    return dragon_encounter_config("beam",_phase);
}
function dragon_phase_for_hp(_b) {return _b.hp<=_b.max_hp*.25 ? 4 : (_b.hp<=_b.max_hp*.5 ? 3 : (_b.hp<=_b.max_hp*.75 ? 2 : 1));}
function dragon_rotation(_phase) {
    switch(_phase) {
        case 1:return ["beam","arc","stomp","beam"];
        case 2:return ["meteor","void","slam","wind","arc"];
        case 3:return ["vortex","volley","meteor","stomp","beam"];
        default:return ["void","beam","meteor","slam","stomp","volley","vortex","wind"];
    }
}
function dragon_encounter_begin(_b,_kind) {
    if(!instance_exists(ObjectPlayer) || _b.dragon_dying)return;
    if(!boss_v2_attack_allowed(_b,_kind))return;
    var pl=ObjectPlayer,c=dragon_encounter_config(_kind,_b.boss_phase);
    if(_b.v2_enabled){c=variable_clone(c);c.warning=max(_kind=="stomp" ? .85 : .55,c.warning/_b.v2_scaling.speed);c.damage*=_b.v2_scaling.damage;var def=boss_v2_definition(_b.boss_id);for(var ai=0;ai<9;ai++)if(def.abilities[ai].key==_kind)boss_v2_note(_b,ai+1);}
    _b.dragon_facing=pl.x<_b.x ? -1 : 1;_b.image_xscale=_b.dragon_facing;_b.dragon_pose_locked=false;_b.boss_cast=_kind;
    _b.dragon_angle=point_direction(_b.x,_b.y-180,pl.x,pl.y-10);_b.dragon_locked_pose=dragon_fire_pose(_b);_b.dragon_pose_locked=_kind=="beam";
    var mouth=dragon_mouth(_b,true);_b.dragon_angle=point_direction(mouth.x,mouth.y,pl.x,pl.y-10);_b.dragon_base_angle=_b.dragon_angle;
    _b.dragon_origin_x=mouth.x;_b.dragon_origin_y=mouth.y;_b.dragon_beam_length=1200;
    var r=combat_view_rect(),corners=[[r.left,r.top],[r.right,r.top],[r.left,r.bottom],[r.right,r.bottom]];
    for(var i=0;i<4;i++)_b.dragon_beam_length=max(_b.dragon_beam_length,(corners[i][0]-mouth.x)*lengthdir_x(1,_b.dragon_angle)+(corners[i][1]-mouth.y)*lengthdir_y(1,_b.dragon_angle)+100);
    var origin=(_kind=="slam" || _kind=="vortex") ? {x:_b.x,y:_b.y-10} : mouth;
    _b.enc_geometry=telegraph_make(c.shape,origin.x,origin.y,_kind=="beam" ? _b.dragon_beam_length : c.radius,c.warning,_b.dragon_angle,c.span,c.width);
    _b.enc_cfg=c;_b.enc_hits=0;_b.enc_waves=0;_b.dragon_next_hit=0;_b.enc_zones=[];_b.dragon_magma=[];_b.enc_lanes=[];_b.enc_combo=undefined;_b.enc_combo_fired=false;
    if(_kind=="volley")for(var lane=-1;lane<=1;lane++)array_push(_b.enc_lanes,telegraph_make("line",origin.x+lengthdir_x(lane*46,_b.dragon_angle+90),origin.y+lengthdir_y(lane*46,_b.dragon_angle+90),880,c.warning,_b.dragon_angle,0,26));
    if(_kind=="vortex" && _b.boss_phase==4)_b.enc_combo=telegraph_make("sector",mouth.x,mouth.y,780,c.warning,_b.dragon_angle,65);
    _b.dragon_target_x=pl.x;_b.dragon_target_y=pl.y-10;
    if(_kind=="meteor" || _kind=="stomp") {
        var count=_kind=="meteor" ? (_b.boss_phase>=3 ? 6 : 4) : 3;
        for(var i=0;i<count;i++) {
            var angle=30+i*137.5,dist=i==0 ? 0 : (_kind=="stomp" ? 350 : 180+40*(i mod 2));
            var xx=clamp(pl.x+lengthdir_x(dist,angle),c.radius+20,room_width-c.radius-20),yy=clamp(pl.y-10+lengthdir_y(dist,angle),c.radius+20,room_height-c.radius-20),valid=true;
            if(_kind=="stomp")for(var j=0;j<array_length(_b.enc_zones);j++)if(point_distance(xx,yy,_b.enc_zones[j].x,_b.enc_zones[j].y)<c.radius*2+24)valid=false;
            if(!valid)continue;
            var delay=_kind=="meteor" ? i*.22 : 0,g=telegraph_make("circle",xx,yy,c.radius,c.warning+delay);
            var z={x:xx,y:yy,age:0,warning:g.duration,g:g,hit:false,erupted:false};array_push(_b.enc_zones,z);
        }
        if(_kind=="stomp")_b.dragon_magma=_b.enc_zones;
    }
    _b.enc_sweep=undefined;
    // Boss design philosophy (docs/Design/Boss-Design.md): same nine abilities, more complex choreography in later phases.
    if(_b.v2_enabled) {
        var phase=_b.boss_phase,cfgc=bc_config();
        if(_kind=="beam") {
            // Very long sweeping fire beam: the swept fan is announced, the hit line turns at a readable speed.
            var span=phase>=2 ? 84 : 64,dir=(_b.dragon_cycle mod 2==0) ? 1 : -1,from=_b.dragon_angle-dir*span*.5,to=_b.dragon_angle+dir*span*.5;
            c.active+=.7;_b.enc_sweep=bc_sweep(_b,"dragon_beam",mouth.x,mouth.y,from,to,48,c.warning,c.active,c.damage,"high");
            _b.dragon_angle=from; // dragon_beam_length stays the visible length (lights/art); the hitbox is the 2600 px hazard
            if(bc_complex(_b,3))for(var k=0;k<4;k++){var a=k*90+45;bv2_zone(_b,"dragon_meteor",bc_clamp_x(pl.x+lengthdir_x(150,a)),bc_clamp_y(pl.y-10+lengthdir_y(110,a)),75,c.warning+c.active*.6,.35,c.damage,"all");}
        }
        if(_kind=="arc" && bc_complex(_b,3)) {
            // Alternating long fire cones: three cones first, then the gaps between them (reaches far kiters, 900 px).
            var base=_b.dragon_angle;
            for(var k=-1;k<=1;k++)bv2_sector(_b,"dragon_cone",mouth.x,mouth.y,900,base+k*70,34,c.warning+.5,.45,c.damage,"ground");
            for(var k=-1;k<=1;k+=2)bv2_sector(_b,"dragon_cone",mouth.x,mouth.y,900,base+k*35,34,c.warning+1.6,.45,c.damage,"ground"); // ground: also jumpable
        }
        if(_kind=="stomp" && bc_complex(_b,2)) {
            // Magma checkerboard, then the inverted board: stand on the dark cells, then switch.
            _b.enc_zones=[];_b.dragon_magma=[];
            var pp=bc_field_parity(cfgc.cell);
            bc_field_checker(_b,"dragon_magma_cell",cfgc.cell,pp,c.warning+.6,.5,c.damage,"ground"); // whole arena, jumpable
            bc_field_checker(_b,"dragon_magma_cell",cfgc.cell,1-pp,c.warning+1.9,.5,c.damage,"ground");
        }
        if(_kind=="vortex" && bc_complex(_b,2)) {
            // Fire rings contract from outside toward the dragon (they drive kiters inward): walk through the opening,
            // jump over a band (ground) or dodge through it. Three waves 0.6 s apart, openings at different angles.
            bc_closing_waves(_b,"dragon_fire_ring",_b.x,_b.y-10,3,820,150,40,.6,c.warning,2.6,c.damage*.8,50,point_direction(_b.x,_b.y,pl.x,pl.y)+180);
        }
        if(_kind=="meteor" && phase>=2) {
            // Consecutive explosions marching from the dragon through the player's position (reaches far kiters).
            _b.enc_zones=[];
            var a=point_direction(_b.x,_b.y-10,pl.x,pl.y-10);
            bc_line_burst(_b,"dragon_meteor",_b.x+lengthdir_x(140,a),_b.y-10+lengthdir_y(140,a),a,92,12,72,c.warning,.13,.35,c.damage,"all");
            if(phase>=3)bc_in_out(_b,"dragon_meteor_ring",pl.x,pl.y-10,125,300,c.warning+1.2,1.15,.35,c.damage,false,"all");
        }
    }
    dragon_state(_b,"windup",c.warning);
}
function dragon_encounter_bullets(_b,_count,_spacing,_speed,_damage,_parallel=false) {
    _speed*=_b.v2_scaling.projectile_speed;
    var g=_b.enc_geometry;
    for(var i=0;i<_count;i++) {
        if(array_length(global.hostile_bullets)>=256)break;
        var dir=g.angle+(_parallel ? 0 : (i-(_count-1)*.5)*_spacing),off=_parallel ? (i-(_count-1)*.5)*46 : 0;
        array_push(global.hostile_bullets,{owner:_b,x:g.x+lengthdir_x(off,g.angle+90),y:g.y+lengthdir_y(off,g.angle+90),vx:lengthdir_x(_speed,dir),vy:lengthdir_y(_speed,dir),radius:13,age:0,life:4,damage:_damage,dragon_void:true,wind:_b.boss_cast=="wind",volley:_b.boss_cast=="volley"});
    }
    fg_sfx(_b.boss_cast=="wind" ? "dragon_wind" : "dragon_void");
}
function dragon_encounter_zones(_b,_dt) {
    var pl=ObjectPlayer,c=_b.enc_cfg,played=false;
    for(var i=0;i<array_length(_b.enc_zones);i++) {
        var z=_b.enc_zones[i];z.age=_b.dragon_state_age+( _b.boss_state=="active" ? c.warning : 0);z.g.elapsed=z.age;
        if(telegraph_ready(z.g) && !z.erupted) {z.erupted=true;if(!played){fg_sfx(_b.boss_cast=="meteor" ? "dragon_meteor" : "dragon_magma");played=true;}light_flash(z.x,z.y,300,make_color_rgb(255,121,44),1.3,.32,.06);}
        if(z.erupted && z.age<z.warning+.55 && !z.hit && telegraph_contains(z.g,pl.x,pl.y-10))if(player_receive_damage(pl,c.damage,c.height))z.hit=true;
    }
}
function dragon_encounter_step(_b,_dt) {
    if(global.game_paused || global.game_over || _b.dragon_dying)return;
    if(_b.hp<=0){dragon_die(_b);return;}
    if(_b.v2_enabled)_b.v2_clock+=_dt; // drives the shared bv2 pattern hazards of this encounter
    _b.dragon_clock+=_dt;_b.dragon_state_age+=_dt;_b.dragon_hit_age+=_dt;
    if(!variable_instance_exists(_b,"dragon_melee_cd")){_b.dragon_melee_cd=0;_b.dragon_close_t=0;}
    _b.dragon_melee_cd=max(0,_b.dragon_melee_cd-_dt);
    _b.dragon_close_t=(instance_exists(ObjectPlayer) && point_distance(_b.x,_b.y,ObjectPlayer.x,ObjectPlayer.y)<dragon_melee_config().range) ? _b.dragon_close_t+_dt : 0;
    if(_b.hp<_b.dragon_last_hp)_b.dragon_hit_age=0;_b.dragon_last_hp=_b.hp;
    if(boss_navigation_step(_b,_dt)){_b.enc_zones=[];_b.dragon_magma=[];return;}
    if(_b.v2_enabled && bc_catchup_step(_b,"dragon",_dt))return; // rare announced dive towards a far-away player
    _b.boss_timer=max(0,_b.boss_timer-_dt);
    if(_b.boss_state=="windup") {
        _b.enc_geometry.elapsed=_b.dragon_state_age;
        if(telegraph_ready(_b.enc_geometry)) {
            var overflow=max(0,_b.dragon_state_age-_b.enc_cfg.warning);
            dragon_state(_b,"active",max(0,_b.enc_cfg.active-overflow));_b.dragon_state_age=overflow;
            fg_sfx(_b.boss_cast=="beam" || _b.boss_cast=="arc" ? "dragon_fire" : "dragon_charge");
            if(_b.boss_cast=="beam" || _b.boss_cast=="arc"){var fm=dragon_mouth(_b,true);light_flash(fm.x,fm.y,340,make_color_rgb(255,146,66),1.5,.35,.1);} // breath ignites
            else light_pulse(_b.enc_geometry.x,_b.enc_geometry.y,280,make_color_rgb(255,146,66),1,.3);
        }
    } else if(_b.boss_timer<=0) {
        if(_b.boss_state=="active") { _b.enc_zones=[];_b.dragon_magma=[];dragon_state(_b,"recovery",bc_seq_recovery(_b,bc_recovery(_b,_b.boss_phase>=3 ? .85 : 1.2))); }
        else if(_b.boss_state=="intro" || _b.boss_state=="transition")dragon_state(_b,"recovery",.8);
        else {
            var phase=dragon_phase_for_hp(_b);
            if(phase!=_b.boss_phase){_b.boss_phase=phase;_b.dragon_cycle=0;dragon_state(_b,"transition",1.2);fg_sfx("boss_phase");}
            else {
                if(variable_global_exists("boss_test") && global.boss_test.active && global.boss_test.ability!=-1)boss_v2_force_attack(_b,global.boss_test.ability);
                else if(!bc_seq_decide(_b,"dragon",dragon_encounter_begin,_dt)) { // learnable sequences (boss_choreo) between regular attacks
                    if(!dragon_melee_try(_b)){var rotation=boss_v2_dragon_rotation(_b);dragon_encounter_begin(_b,bc_dragon_far_pick(_b,rotation[_b.dragon_cycle mod array_length(rotation)]));_b.dragon_cycle++;}
                    bc_seq_regular(_b);
                }
            }
        }
    }
    if(_b.boss_state=="windup" || _b.boss_state=="active") {
        var kind=_b.boss_cast,c=_b.enc_cfg,g=_b.enc_geometry,pl=ObjectPlayer;
        if(kind=="meteor" || kind=="stomp")dragon_encounter_zones(_b,_dt);
        if(_b.boss_state=="active") {
            var age=_b.dragon_state_age,hit=false;
            if(is_struct(_b.enc_combo) && !_b.enc_combo_fired) {
                var original=_b.enc_geometry;_b.enc_geometry=_b.enc_combo;dragon_encounter_bullets(_b,3,24,190,18*_b.v2_scaling.damage);_b.enc_geometry=original;_b.enc_combo_fired=true;
            }
            var swept=variable_instance_exists(_b,"enc_sweep") && is_struct(_b.enc_sweep);
            if(kind=="beam" && swept)_b.dragon_angle=_b.enc_sweep.g.angle; // the bv2 hazard owns the hitbox
            else if(kind=="beam" || kind=="arc" || kind=="tail" || kind=="bite")hit=telegraph_contains(g,pl.x,pl.y-10);
            if(kind=="sweep") {_b.dragon_angle=_b.dragon_base_angle-55+110*clamp(age/c.active,0,1);hit=dragon_player_in_fire(_b,pl);}
            if(kind=="slam" || kind=="vortex") {
                var ring=dragon_ring_geometry(kind,g,age,c.active);hit=telegraph_contains(ring,pl.x,pl.y-10);
                if(kind=="slam" && age<.12 && point_distance(g.x,g.y,pl.x,pl.y-10)<80)hit=true;
                if(_b.enc_hits==0){fg_sfx(kind=="slam" ? "dragon_slam" : "dragon_vortex");_b.enc_hits++;}
            }
            if((kind=="void" || kind=="volley" || kind=="wind") && age>=_b.enc_waves*.48 && _b.enc_waves<(_b.boss_phase>=4 ? 3 : 2)) {
                var count=(kind=="volley" ? (_b.enc_waves==0 ? 3 : 5) : 3)+_b.v2_scaling.projectiles;
                dragon_encounter_bullets(_b,count,kind=="void" ? 18 : 13,kind=="wind" ? 170 : 220,c.damage,kind=="volley" && _b.enc_waves==0);_b.enc_waves++;
            }
            if(hit && age>=_b.dragon_next_hit)if(player_receive_damage(pl,c.damage,c.height))_b.dragon_next_hit=age+.35;
        }
    }
    if(_b.boss_state=="recovery") {
        var pl=ObjectPlayer,dir=point_direction(_b.x,_b.y,pl.x+(pl.x<_b.x ? 245 : -245),pl.y+200),v=65+bc_config().far_speed_dragon*bc_pressure(_b); // faster when the player keeps away
        _b.chase_vx=lengthdir_x(v,dir);_b.chase_vy=lengthdir_y(v,dir);_b.x=clamp(_b.x+_b.chase_vx*_dt,140,room_width-140);_b.y=clamp(_b.y+_b.chase_vy*_dt,310,room_height-24);
        if(abs(pl.x-_b.x)>40)_b.dragon_facing=pl.x<_b.x ? -1 : 1;
    }
    _b.depth=-_b.y;
}
/// Expanding ring of the slam and the vortex at state age _age: the ONE geometry for the hit test (step), the picture
/// (draw) and the boss suite's oracle. Before the audit of 26.11. the formula existed twice, linked only by a comment.
function dragon_ring_geometry(_kind,_g,_age,_active) {
    var r=_kind=="slam" ? max(45,320*_age/_active) : 100+210*_age/_active,ring=telegraph_make("ring",_g.x,_g.y,r,1,0,360,40);
    ring.inner=max(0,r-40);return ring;
}
function dragon_encounter_draw(_b) {
    if(_b.dragon_dying || !variable_instance_exists(_b,"enc_geometry"))return;
    var kind=_b.boss_cast,g=_b.enc_geometry,c=_b.enc_cfg,age=_b.dragon_state_age,col=(kind=="void" || kind=="volley") ? make_color_rgb(181,104,251) : (kind=="wind" ? make_color_rgb(130,225,211) : ((kind=="tail" || kind=="bite") ? make_color_rgb(236,214,170) : make_color_rgb(255,115,58)));
    var swept=variable_instance_exists(_b,"enc_sweep") && is_struct(_b.enc_sweep);
    if(_b.boss_state=="windup" && !array_contains(["meteor","stomp","void","volley","wind"],kind) && !(kind=="beam" && swept)) {
        g.elapsed=age;telegraph_draw(g,col,(kind=="tail" || kind=="bite") ? 0 : 1);
    }
    // Energy gathering at the mouth for fire attacks: embers converge, the mouth glows (light in atmosphere_draw).
    if(_b.boss_state=="windup" && (kind=="beam" || kind=="arc" || kind=="sweep")){var m=dragon_mouth(_b,false);vfx_charge(m.x,m.y,clamp(age/max(.1,c.warning),0,1),1,70,11);}
    if(_b.boss_state=="active") {
        if(age<.08 && (kind=="tail" || kind=="bite"))telegraph_flash(g,col);
        if((kind=="beam" && !swept) || kind=="sweep") {var fire=dragon_attack_geometry(_b);vfx_beam_stream({shape:"line",x:fire.x,y:fire.y,angle:_b.dragon_angle,radius:fire.length,width:fire.width,inner:0,span:0},1,age,c.active,5);}
        if(kind=="arc")vfx_fire_cone(g.x,g.y,g.angle,g.span,g.radius,age,c.active); // fills exactly the telegraphed sector
        if(kind=="vortex" || kind=="slam") {
            var ring=dragon_ring_geometry(kind,g,age,c.active),r=ring.radius; // the hit test uses the same function
            if(kind=="vortex")dragon_fx_sprite(6,.25+frac(age)*.35,g.x,g.y,r,_b.dragon_clock*100);
            else {for(var dust=0;dust<12;dust++){var angle=dust*30;class_fx_sprite(7,clamp(age/c.active,0,1),g.x+lengthdir_x(r-20,angle),g.y+lengthdir_y(r-20,angle),28,angle);}if(age<.4)class_fx_sprite(7,age/.4,g.x,g.y,90);}
            hz_area_draw(ring,kind=="slam" ? 5 : 1,col,age,c.active,kind=="slam" ? 2 : 8);
        }
        if(kind=="wind")dragon_fx_sprite(3,.25+frac(age)*.4,g.x+lengthdir_x(160,g.angle),g.y+lengthdir_y(160,g.angle),150,g.angle);
    }
    if(_b.boss_state=="windup" || _b.boss_state=="active")for(var i=0;i<array_length(_b.enc_zones);i++) {
        var z=_b.enc_zones[i];
        if(!z.erupted) {telegraph_draw(z.g,col,kind=="void" ? 4 : 1);if(kind=="meteor"){var p=telegraph_progress(z.g);dragon_fx_sprite(2,.2,z.x-50*(1-p),z.y-300*(1-p),36,285);}}
        else if(z.age<z.warning+.8){hz_area_draw(z.g,1,col,z.age-z.warning,.45,i);dragon_fx_sprite(kind=="meteor" ? 2 : 5,.375+clamp((z.age-z.warning)/.65,0,.624),z.x,z.y,c.radius);}
    }
    draw_set_alpha(1);draw_set_color(c_white);
}
/// Dragon effects as pixel composites on the world grid (render_pipeline) instead of the scaled painted sheet.
/// _progress keeps its old meaning (0..1 over the 8-frame sheet: bullets loop in .125-.375, impacts run .375-1).
function dragon_fx_sprite(_row,_progress,_x,_y,_radius,_angle=0,_alpha=1) {
    switch(_row) {
        case 2:if(_progress<.35)vfx_meteor(_x,_y,_radius,_angle,_alpha);else vfx_eruption(_x,_y,_radius,clamp((_progress-.375)/.625,0,1),false,_alpha);break;
        case 5:vfx_eruption(_x,_y,_radius,clamp((_progress-.375)/.625,0,1),true,_alpha);break;
        case 3:vfx_wind_blade(_x,_y,_radius,_angle,_alpha);break;
        case 4:vfx_void_orb(_x,_y,_radius,_alpha);break;
        case 7:vfx_fire_bolt(_x,_y,_radius,_angle,_alpha);break;
        case 6:vfx_vortex(_x,_y,_radius,_angle,_alpha);break;
        default:var spr=asset_get_index("spr_dragon_fx_"+string(_row));if(sprite_exists(spr))draw_sprite_ext(spr,min(7,floor(clamp(_progress,0,.999)*8)),_x,_y,_radius*2/256,_radius*2/256,_angle,c_white,_alpha);
    }
    draw_set_alpha(1);draw_set_color(c_white);
}
/// Falling meteor: a rock (dark, mid, lit side) with a fire tail against the flight direction.
function vfx_meteor(_x,_y,_r,_dir,_alpha) {
    var t=current_time/1000,r=max(5,_r*.58);
    vfx_fire_tongue(_x,_y,_dir+180,_r*1.5,_r*1.05,t,_alpha*.95);
    draw_set_alpha(_alpha);draw_set_color(make_color_rgb(70,44,40));draw_circle(round(_x),round(_y),r,false);
    draw_set_color(make_color_rgb(140,82,56));draw_circle(round(_x-1),round(_y-1),max(1,r-2),false);
    draw_set_color(make_color_rgb(255,186,104));draw_circle(round(_x+lengthdir_x(r*.4,_dir)),round(_y+lengthdir_y(r*.4,_dir)),max(1,r*.35),false);
}
/// Impact (meteor) or magma eruption: bright core, pixel shock ring, debris arcing out, embers; magma adds lava blobs
/// that linger. q runs 0..1 over the effect.
function vfx_eruption(_x,_y,_r,_q,_magma,_alpha) {
    var pal=vfx_palette(1),k=(1-_q)*_alpha,core=make_color_rgb(255,232,140),x0=round(_x),y0=round(_y);
    if(vfx_quality()>0)vfx_glow_disc(x0,y0,_r*(.4+.6*_q),pal[1],.25*k);
    if(_q<.45){var c=1-_q/.45;draw_set_alpha(c*_alpha);draw_set_color(core);draw_circle(x0,y0,max(2,_r*.45*(1-c*.3)),false);draw_set_color(make_color_rgb(255,250,226));draw_circle(x0,y0,max(1,_r*.22*c),false);}
    vfx_pixel_ring(x0,y0,_r*(.35+.65*_q),pal[1],k,0,0,2);
    vfx_pixel_ring(x0,y0,_r*(.25+.6*_q),pal[0],.8*k,_q*40,3,1);
    var n=vfx_quality()==0 ? 8 : 16;
    for(var i=0;i<n;i++) {
        var a=i*360/n+20*vfx_hash(i,7),d=_r*(.2+.9*_q)*(.7+.3*abs(vfx_hash(i,3))),lift=sin(pi*_q)*_r*.25*abs(vfx_hash(i,5));
        vfx_px(x0+lengthdir_x(d,a),y0+lengthdir_y(d,a)-lift,i mod 3==0 ? 3 : 2,i mod 2 ? make_color_rgb(90,62,48) : pal[1],k);
    }
    if(_magma)for(var b=0;b<6;b++){var a=b*60+15,d=_r*(.35+.25*abs(vfx_hash(b,11)));draw_set_alpha(min(1,(1.3-_q))*_alpha);draw_set_color(b mod 2 ? pal[1] : pal[0]);draw_circle(round(x0+lengthdir_x(d,a)),round(y0+lengthdir_y(d*.6,a)),2+(b mod 3),false);}
}
/// Wind blade bullet: a cyan crescent facing its flight with two streak lines behind it.
function vfx_wind_blade(_x,_y,_r,_dir,_alpha) {
    var dark=make_color_rgb(52,132,124),mid=make_color_rgb(130,225,211),light=make_color_rgb(232,255,250),ro=_r*.55,n=12;
    vfx_crescent(_x,_y,_dir-70,_dir+70,0,1,ro,ro*.45,n,0,dark,.9*_alpha);
    vfx_crescent(_x,_y,_dir-70,_dir+70,0,1,ro,ro*.45,n,1,mid,_alpha);
    vfx_crescent(_x,_y,_dir-70,_dir+70,0,1,ro,ro*.45,n,2,light,_alpha);
    for(var s=-1;s<=1;s+=2){var ox=lengthdir_x(ro*.4*s,_dir+90),oy=lengthdir_y(ro*.4*s,_dir+90);vfx_pixel_line(_x+ox,_y+oy,_x+ox-lengthdir_x(_r*.9,_dir),_y+oy-lengthdir_y(_r*.9,_dir),1,mid,.6*_alpha);}
}
/// Void bullet: a dark violet pixel orb with a bright rim and two pixels circling it.
function vfx_void_orb(_x,_y,_r,_alpha) {
    var pal=vfx_palette(4),x0=round(_x),y0=round(_y),r=max(3,round(_r*.55)),a=current_time*.4;
    if(vfx_quality()>0)vfx_glow_disc(x0,y0,r*1.7,pal[1],.2*_alpha);
    draw_set_alpha(_alpha);draw_set_color(pal[1]);draw_circle(x0,y0,r,false);draw_set_color(make_color_rgb(28,10,46));draw_circle(x0,y0,max(1,r-2),false);
    for(var i=0;i<2;i++)vfx_px(x0+lengthdir_x(r+3,a+i*180)-1,y0+lengthdir_y(r+3,a+i*180)-1,2,pal[2],_alpha);
}
/// Fire volley bullet: a bright head with a short flame trail.
function vfx_fire_bolt(_x,_y,_r,_dir,_alpha) {
    vfx_fire_tongue(_x,_y,_dir+180,_r*2.2,_r*.8,current_time/1000,_alpha);
    draw_set_alpha(_alpha);draw_set_color(make_color_rgb(255,232,140));draw_circle(round(_x),round(_y),max(2,_r*.32),false);
}
/// Vortex: three pixel spiral arms turning around a dark core, a dashed outer ring.
function vfx_vortex(_x,_y,_r,_rot,_alpha) {
    var pal=vfx_palette(4),x0=round(_x),y0=round(_y);
    if(vfx_quality()>0)vfx_glow_disc(x0,y0,_r*.6,pal[0],.25*_alpha);
    for(var arm=0;arm<3;arm++)for(var s=0;s<18;s++){var q=s/18,a=_rot+arm*120+q*220,d=_r*(.15+.85*q);vfx_px(x0+lengthdir_x(d,a),y0+lengthdir_y(d,a),q<.5 ? 3 : 2,q<.3 ? pal[2] : (q<.7 ? pal[1] : pal[0]),_alpha*(1-q*.5));}
    vfx_pixel_ring(x0,y0,_r,pal[1],.7*_alpha,_rot*.5,3,1);
    draw_set_alpha(_alpha);draw_set_color(make_color_rgb(20,8,34));draw_circle(x0,y0,max(2,_r*.12),false);
}

// ---------------- Close-range attacks (user decision 25.11.2026) ----------------
/// Bite and tail sweep (alternating) are extra basic attacks: the nine abilities and the
/// rotation stay unchanged. Damage reuses the existing "arc" ability (no new damage numbers). The warning is short but
/// announced (sector + body windup in the rig); the tail sweep is a ground attack (a jump clears it), the bite hits all heights.
function dragon_melee_config() {
    static c={range:230,close_time:.6,cooldown:8,tail:{warning:.75,active:.3,radius:250,span:150,height:"ground"},bite:{warning:.6,active:.22,radius:205,span:70,height:"all"}};
    return c;
}
function dragon_melee_try(_b) {
    var m=dragon_melee_config();
    if(!_b.v2_enabled || _b.dragon_melee_cd>0 || _b.dragon_close_t<m.close_time || !instance_exists(ObjectPlayer))return false;
    var pl=ObjectPlayer,size=_b.visual_height/430;
    // The dragon turns towards the player while recovering, so bite and tail sweep alternate (bite first).
    // The tail sweep comes from the hip on the tail side and fans 150 degrees towards the player.
    if(!variable_instance_exists(_b,"dragon_melee_n"))_b.dragon_melee_n=0;
    var behind=_b.dragon_melee_n mod 2==1,kind=behind ? "tail" : "bite",k=behind ? m.tail : m.bite;_b.dragon_melee_n++;
    var ox=behind ? _b.x-_b.dragon_facing*95*size : _b.x+_b.dragon_facing*85*size,oy=_b.y-(behind ? 70 : 40)*size;
    var c=variable_clone(dragon_encounter_config("arc",_b.boss_phase));
    c.warning=k.warning;c.active=k.active;c.height=k.height;c.radius=k.radius;c.span=k.span;c.shape="sector";
    if(_b.v2_enabled)c.damage*=_b.v2_scaling.damage;
    _b.boss_cast=kind;_b.dragon_pose_locked=false;_b.enc_cfg=c;_b.enc_hits=0;_b.enc_waves=0;_b.dragon_next_hit=0;
    _b.enc_zones=[];_b.dragon_magma=[];_b.enc_lanes=[];_b.enc_combo=undefined;_b.enc_combo_fired=false;_b.enc_sweep=undefined;
    _b.enc_geometry=telegraph_make("sector",ox,oy,k.radius,k.warning,point_direction(ox,oy,pl.x,pl.y-10),k.span);
    _b.dragon_melee_cd=m.cooldown;_b.dragon_close_t=0;
    fg_sfx("dragon_charge");
    dragon_state(_b,"windup",k.warning);
    return true;
}
