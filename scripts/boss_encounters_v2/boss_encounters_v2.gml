/// Coordinated encounters. Geometry/clock/hits live in the shared Boss System 2.0 hazard component.
function bv2_attack_profile(_kind,_index) {
    static twins=[
        {id:1,name:"Doppelte Geschosssalve",mechanic:"dual_salvo",warning:.55,active:1.1,damage:14,radius:0,height:"high",formation:"eight",animation:"cast"},
        {id:2,name:"Rotierender Feuer-Eis-Ring",mechanic:"element_ring",warning:1.2,active:2.4,damage:22,radius:255,height:"ground",formation:"circle",animation:"joint"},
        {id:3,name:"Meteoriten und Eissplitterregen",mechanic:"paired_rain",warning:1.4,active:1.8,damage:25,radius:70,height:"all",formation:"cross",animation:"cast"},
        {id:4,name:"Verbindungsstrahl",mechanic:"moving_link",warning:1.3,active:2.7,damage:22,radius:32,height:"high",formation:"split",animation:"joint"},
        {id:5,name:"Dualer Spiralwirbel",mechanic:"counter_spirals",warning:1.5,active:2.7,damage:24,radius:155,height:"ground",formation:"circle",animation:"joint"},
        {id:6,name:"Kreuzschlag-Strahlen",mechanic:"cross_beams",warning:1.4,active:2,damage:28,radius:28,height:"high",formation:"cross",animation:"cast"},
        {id:7,name:"Brennender Froststoss",mechanic:"burning_frost",warning:1.5,active:2.5,damage:36,radius:155,height:"all",formation:"dive",animation:"joint"},
        {id:8,name:"Vereinigte Zonenflut",mechanic:"paired_flood",warning:1.6,active:3,damage:22,radius:95,height:"ground",formation:"split",animation:"joint"},
        {id:9,name:"Duale Nova",mechanic:"three_stage_nova",warning:1.8,active:3.1,damage:40,radius:310,height:"all",formation:"eight",animation:"joint"}
    ];
    static swamp=[
        {id:1,name:"Giftgespucke",mechanic:"poison_spit",warning:.7,active:1,damage:18,radius:55,height:"high",formation:"heavy",animation:"spit"},
        {id:2,name:"Saeurepfuetzen",mechanic:"acid_pools",warning:1.1,active:1.5,damage:8,radius:78,height:"ground",formation:"heavy",animation:"spit"},
        {id:3,name:"Packende Wurzeln",mechanic:"grasping_roots",warning:1.1,active:.55,damage:17,radius:65,height:"ground",formation:"heavy",animation:"roots"},
        {id:4,name:"Pilzexplosion",mechanic:"growing_mushrooms",warning:1.6,active:3,damage:27,radius:92,height:"all",formation:"heavy",animation:"summon"},
        {id:5,name:"Sumpfstampfer",mechanic:"ground_shockwave",warning:1.4,active:1.5,damage:34,radius:350,height:"ground",formation:"heavy",animation:"stomp"},
        {id:6,name:"Sumpfbrut",mechanic:"bounded_brood",warning:1.3,active:1.1,damage:0,radius:0,height:"ground",formation:"heavy",animation:"summon"},
        {id:7,name:"Giftatem",mechanic:"poison_breath",warning:1.5,active:1.9,damage:18,radius:365,height:"all",formation:"heavy",animation:"breath"},
        {id:8,name:"Sumpfwelle",mechanic:"travelling_mud_wave",warning:1.3,active:2,damage:28,radius:650,height:"ground",formation:"heavy",animation:"wave"},
        {id:9,name:"Verfallsbluete",mechanic:"decay_bloom",warning:1.9,active:4.1,damage:30,radius:305,height:"all",formation:"heavy",animation:"bloom"}
    ];
    static metadata_ready=false;
    if(!metadata_ready) {
        for(var i=0;i<9;i++){twins[i].key=twins[i].mechanic;twins[i].implemented=true;swamp[i].key=swamp[i].mechanic;swamp[i].implemented=true;}
        metadata_ready=true;
    }
    var data=_kind=="twins" ? twins : swamp;
    return data[clamp(floor(_index),1,9)-1];
}
function bv2_encounter_phase(_b) {
    var fraction=_b.hp/max(1,_b.max_hp);
    if(_b.v2_kind=="behemoth")return fraction<=.10 ? 4 : (fraction<=.40 ? 3 : (fraction<=.70 ? 2 : 1));
    return fraction<=.25 ? 4 : (fraction<=.50 ? 3 : (fraction<=.75 ? 2 : 1));
}
function bv2_encounter_rotation(_b) {
    var sequence;
    if(_b.v2_kind=="twins") {
        switch(_b.boss_phase) {
            case 1:sequence=[1,2,3,4,1,5,6,7,8,9];break;
            case 2:sequence=[3,1,4,2,6,5,7,8,9];break;
            case 3:sequence=[4,3,5,6,2,8,7,9,1];break;
            default:sequence=[1,4,3,6,8,5,7,9,2];break;
        }
    } else {
        switch(_b.boss_phase) {
            case 1:sequence=[1,2,3,1,4,5,6,7,8,9];break;
            case 2:sequence=[2,3,1,6,4,5,7,8,9];break;
            case 3:sequence=[3,2,5,4,6,7,8,9,1];break;
            default:sequence=[2,3,6,4,7,8,9,5,1];break;
        }
    }
    var out=[];for(var i=0;i<array_length(sequence);i++)if(sequence[i]<=_b.v2_unlocked)array_push(out,sequence[i]);
    return out;
}
function bv2_encounter_init(_b) {
    var pl=ObjectPlayer;
    _b.visual_height=_b.v2_kind=="twins" ? 135 : 340;
    _b.body_radius=_b.v2_kind=="twins" ? 35 : 130;_b.contact_radius=_b.v2_kind=="twins" ? 25 : 100;
    _b.mask_index=boss_body_mask(_b.body_radius,_b.visual_height);
    if(_b.v2_kind=="twins" && !instance_exists(_b.v2_child))boss_twin_create(_b);
    _b.v2_clock=0;_b.v2_attack_age=0;_b.v2_cycle=0;_b.v2_attack=0;_b.v2_launched=false;
    _b.v2_center_x=pl.x;_b.v2_center_y=pl.y-10;_b.v2_origin_x=_b.x;_b.v2_origin_y=_b.y;
    _b.v2_formation="eight";_b.v2_formation_age=0;_b.v2_hover=60;_b.v2_other_hover=80;_b.v2_spin_a0=0;_b.v2_spin_speed=40;bc_catchup_init(_b);
    _b.v2_facing=pl.x<_b.x ? -1 : 1;_b.v2_other_facing=1;_b.v2_turn_time=0;_b.v2_other_turn_time=0;_b.v2_moving_lines=[];_b.v2_spiral_fields=[];
    _b.v2_chase_x=pl.x;_b.v2_chase_y=pl.y;_b.v2_last_x=_b.x;_b.v2_last_y=_b.y;_b.v2_move_speed=0;
    _b.boss_state="intro";_b.boss_timer=1.7;_b.v2_state_age=0;_b.v2_profile=bv2_attack_profile(_b.v2_kind,1);
}
function bv2_encounter_state(_b,_state,_time) {_b.boss_state=_state;_b.boss_timer=_time;_b.v2_state_age=0;}
function bv2_encounter_twins_positions(_b,_dt) {
    if(!instance_exists(_b.v2_child))return;
    var pl=ObjectPlayer,ice=_b.v2_child,cx=_b.v2_center_x,cy=_b.v2_center_y,t=_b.v2_clock*.65,fx=cx-200,fy=cy,ix=cx+200,iy=cy;
    switch(_b.v2_formation) {
        case "eight":fx=cx+cos(t)*215;fy=cy+sin(t*2)*105;ix=cx-cos(t)*215;iy=cy+sin(t*2)*105+22;break;
        case "circle":fx=cx+cos(t)*210;fy=cy+sin(t)*145;ix=cx-cos(t)*210;iy=cy-sin(t)*145;break;
        case "cross":var cross=sin(t*.8);fx=cx+cross*220;fy=cy+cross*115;ix=cx-cross*220;iy=cy+cross*115;break;
        case "dive":
            var p=clamp(_b.v2_attack_age/max(.1,_b.v2_warning),0,1);
            fx=cx-lerp(215,105,p);ix=cx+lerp(215,105,p);fy=cy-100+140*p;iy=fy;
            _b.v2_hover=60+sin(p*pi)*140;_b.v2_other_hover=80+sin(p*pi)*140;break;
        case "split":
            var angle=sin(_b.v2_formation_age*.55)*24;
            fx=cx+lengthdir_x(225,180+angle);fy=cy+lengthdir_y(150,180+angle);ix=cx+lengthdir_x(225,angle);iy=cy+lengthdir_y(150,angle);break;
        case "spin":
            // Both witches circle the announced centre on opposite sides: the connection beam sweeps across it.
            // Centred on the announced player position: the beam keeps sweeping across it.
            var sa=_b.v2_spin_a0+_b.v2_formation_age*_b.v2_spin_speed,scx=_b.v2_target_x,scy=_b.v2_target_y+10;
            fx=scx+lengthdir_x(235,sa);fy=scy+lengthdir_y(160,sa);ix=scx+lengthdir_x(235,sa+180);iy=scy+lengthdir_y(160,sa+180);break;
        case "follow":
            fx=pl.x-180;fy=pl.y-65;ix=_b.v2_chase_x+180;iy=_b.v2_chase_y+65;
            _b.v2_chase_x=lerp(_b.v2_chase_x,pl.x,1-exp(-1.6*_dt));_b.v2_chase_y=lerp(_b.v2_chase_y,pl.y,1-exp(-1.6*_dt));break;
    }
    if(_b.v2_formation!="dive") {_b.v2_hover=60+sin(_b.v2_clock*2.8)*7;_b.v2_other_hover=80+sin(_b.v2_clock*2.8+pi)*7;}
    var blend=1-exp(-3.2*_dt);
    _b.x=clamp(lerp(_b.x,fx,blend),80,room_width-80);_b.y=clamp(lerp(_b.y,fy,blend),225,room_height-48);
    ice.x=clamp(lerp(ice.x,ix,blend),80,room_width-80);ice.y=clamp(lerp(ice.y,iy,blend),225,room_height-48);
    var face=pl.x<_b.x ? -1 : 1,other_face=pl.x<ice.x ? -1 : 1;
    if(face!=_b.v2_facing)_b.v2_turn_time=.24;if(other_face!=_b.v2_other_facing)_b.v2_other_turn_time=.24;
    _b.v2_facing=face;_b.v2_other_facing=other_face;_b.depth=-_b.y;ice.depth=-ice.y;
}
function bv2_encounter_add_line(_b,_kind,_x,_y,_ex,_ey,_width,_warning,_active,_damage,_mode) {
    var h=bv2_line(_b,_kind,_x,_y,_ex,_ey,_width,_warning,_active,_damage,"high");
    if(is_struct(h))array_push(_b.v2_moving_lines,{hazard:h,mode:_mode});return h;
}
function bv2_twins_origin(_b,_ice=false) {
    var actor=_ice && instance_exists(_b.v2_child) ? _b.v2_child : _b,hover=_ice ? _b.v2_other_hover : _b.v2_hover,face=_ice ? _b.v2_other_facing : _b.v2_facing;
    return {x:actor.x+face*22,y:actor.y-hover-65};
}
function bv2_encounter_attack_begin(_b,_index) {
    if(!instance_exists(ObjectPlayer) || _b.hp<=0 || _index<1 || _index>_b.v2_unlocked || _index>9)return false;
    var pl=ObjectPlayer,p=bv2_attack_profile(_b.v2_kind,_index),speed_factor=max(1,_b.v2_scaling.speed),warning=max(.5,p.warning/speed_factor);
    _b.v2_attack=_index;_b.v2_profile=p;_b.v2_warning=warning;_b.v2_attack_age=0;_b.v2_launched=false;_b.v2_moving_lines=[];_b.v2_spiral_fields=[];_b.v2_formation_age=0;
    _b.v2_target_x=pl.x;_b.v2_target_y=pl.y-10;_b.v2_angle=point_direction(_b.x,_b.y-120,pl.x,pl.y-10);_b.v2_formation=p.formation;
    bv2_encounter_state(_b,"windup",warning);
    boss_v2_note(_b,_index);
    var damage=p.damage*_b.v2_scaling.damage,phase=_b.boss_phase,cx=_b.v2_center_x,cy=_b.v2_center_y,h;
    if(_b.v2_kind=="twins") {
        var ice=instance_exists(_b.v2_child) ? _b.v2_child : _b;
        var fire_hand=bv2_twins_origin(_b,false),ice_hand=bv2_twins_origin(_b,true);
        switch(_index) {
            case 1:
                // Visible moving ordinary projectiles have no floor countdown. From phase 3 the figure-eight flight
                // drags a connection beam between the witches across the area.
                if(phase>=3)bv2_encounter_add_line(_b,"twins_link",fire_hand.x,fire_hand.y,ice_hand.x,ice_hand.y,26,warning,p.active+1.2,damage,"link");
                break;
            case 2:
                h=bv2_ring(_b,"twins_ring",cx,cy,255,205,warning,2.4,damage,"ground");
                if(is_struct(h)){h.gap_angle=90;h.gap_width=75;h.rotate_speed=35+phase*5;h.interval=.55;}
                break;
            case 3:
                if(phase>=2) {
                    // Fire on one colour of the board, then ice on the cells that were safe a moment ago.
                    var cfgc=bc_config();
                    bc_checker(_b,"twins_meteor_cell",_b.v2_target_x,_b.v2_target_y,cfgc.cell,cfgc.grid,0,warning+.45,.45,damage,"all");
                    bc_checker(_b,"twins_ice_cell",_b.v2_target_x,_b.v2_target_y,cfgc.cell,cfgc.grid,1,warning+1.75,.45,damage,"all");
                    break;
                }
                for(var i=0;i<4+(phase>=3 ? 2 : 0);i++) {
                    var side=(i mod 2)==0 ? -1 : 1,xx=_b.v2_target_x+side*(i<2 ? 0 : 150),yy=_b.v2_target_y+(i div 2)*125-80;
                    bv2_zone(_b,(i mod 2)==0 ? "twins_meteor" : "twins_ice_rain",clamp(xx,85,room_width-85),clamp(yy,85,room_height-85),70,warning+i*.19,.35,damage,"all");
                }
                break;
            case 4:
                _b.v2_formation="spin";_b.v2_spin_a0=point_direction(_b.v2_target_x,_b.v2_target_y,_b.x,_b.y);_b.v2_spin_speed=(_b.v2_cycle mod 2==0 ? 1 : -1)*(phase>=3 ? 46 : 38);
                bv2_encounter_add_line(_b,"twins_link",fire_hand.x,fire_hand.y,ice_hand.x,ice_hand.y,32,warning,2.7,damage,"link");break;
            case 5:
                for(var side=-1;side<=1;side+=2) {
                    h=bv2_ring(_b,side<0 ? "twins_fire_spiral" : "twins_ice_spiral",cx+side*155,cy,155,95,warning,2.7,damage,"ground");
                    if(is_struct(h)){h.gap_angle=side<0 ? 180 : 0;h.gap_width=110;h.rotate_speed=side*55;h.interval=.55;array_push(_b.v2_spiral_fields,{hazard:h,side:side});}
                }
                break;
            case 6:
                bv2_encounter_add_line(_b,"twins_fire_cross",fire_hand.x,fire_hand.y,_b.v2_target_x+250,_b.v2_target_y+180,28,warning,2,damage,"fire_cross");
                bv2_encounter_add_line(_b,"twins_ice_cross",ice_hand.x,ice_hand.y,_b.v2_target_x-250,_b.v2_target_y+180,28,warning,2,damage,"ice_cross");
                // Later phases: the long fire/ice beams cross while the floor freezes in alternating stripes.
                if(phase>=3)bc_stripes(_b,"twins_ice_flood",_b.v2_target_x,_b.v2_target_y,(_b.v2_cycle mod 2)*90,105,7,1100,0,warning+.3,1.2,damage,"ground");
                break;
            case 7:
                bv2_zone(_b,"twins_blast",_b.v2_target_x,_b.v2_target_y,155,warning,.3,damage,"all");
                h=bv2_zone(_b,"twins_burning_frost",_b.v2_target_x,_b.v2_target_y,125,warning+.3,2.1,8*_b.v2_scaling.damage,"ground");
                if(is_struct(h)){h.hit_once=false;h.interval=.65;}break;
            case 8:
                if(phase>=2) {
                    // Opposite quadrants burn, then the other pair freezes: diagonal position changes.
                    var q=(_b.v2_cycle mod 2)*90+45;
                    bc_quadrants(_b,"twins_fire_flood",_b.v2_target_x,_b.v2_target_y,340,q,warning,.8,damage,"ground");
                    bc_quadrants(_b,"twins_ice_flood",_b.v2_target_x,_b.v2_target_y,340,q+90,warning+1.25,.8,damage,"ground");
                    break;
                }
                for(var row=-1;row<=1;row++)for(var side=-1;side<=1;side+=2) {
                    h=bv2_zone(_b,side<0 ? "twins_fire_flood" : "twins_ice_flood",clamp(cx+side*205,110,room_width-110),clamp(cy+row*225,110,room_height-110),95,warning+(row+1)*.18,2.5,damage,"ground");
                    if(is_struct(h)){h.hit_once=false;h.interval=.8;}
                }break;
            case 9:
                h=bv2_ring(_b,"twins_fire_nova",cx,cy,310,160,warning,.35,damage,"all");if(is_struct(h)){h.hit_once=true;h.gap_angle=270;h.gap_width=35;}
                bv2_zone(_b,"twins_ice_nova",cx,cy,150,warning+1,.35,damage,"all");
                h=bv2_ring(_b,"twins_dual_nova",cx,cy,280,150,warning+2.1,.4,damage*1.15,"all");if(is_struct(h))h.hit_once=true;
                break;
        }
    } else {
        var mouth=bv2_behemoth_mouth(_b);
        switch(_index) {
            case 1:break; // The spit is a readable ordinary projectile.
            case 2:
                if(phase>=2) {
                    // Acid stripes with alternating gaps: the safe lanes become dangerous and vice versa.
                    var sa=(_b.v2_cycle mod 4)*45,first=bc_stripes(_b,"swamp_acid",_b.v2_target_x,_b.v2_target_y,sa,105,7,1050,0,warning,1.6,damage,"ground");
                    var second=bc_stripes(_b,"swamp_acid",_b.v2_target_x,_b.v2_target_y,sa,105,7,1050,1,warning+2.3,1.6,damage,"ground"); // 0.7 s gap: switching lanes is always possible
                    for(var k=0;k<array_length(first);k++){first[k].hit_once=false;first[k].interval=.65;first[k].poison=1.2;}
                    for(var k=0;k<array_length(second);k++){second[k].hit_once=false;second[k].interval=.65;second[k].poison=1.2;}
                    break;
                }
                for(var i=0;i<3;i++) {
                    var xx=_b.v2_target_x+lengthdir_x(i==0 ? 0 : 180,35+i*145),yy=_b.v2_target_y+lengthdir_y(i==0 ? 0 : 180,35+i*145);
                    h=bv2_zone(_b,"swamp_acid",clamp(xx,100,room_width-100),clamp(yy,100,room_height-100),78,warning+i*.12,4.5,damage,"ground");
                    if(is_struct(h)){h.hit_once=false;h.interval=.65;h.poison=1.2;}
                }break;
            case 3:
                if(phase>=2) {
                    // Roots erupt one after another from the behemoth through and past the player (also reaches far kiters).
                    var base=point_direction(_b.x,_b.y-10,_b.v2_target_x,_b.v2_target_y),lines=phase>=3 ? [-18,18] : [0];
                    for(var l=0;l<array_length(lines);l++) {
                        var roots=bc_line_burst(_b,"swamp_roots",_b.x+lengthdir_x(150,base+lines[l]),_b.y-10+lengthdir_y(150,base+lines[l]),base+lines[l],95,10,62,warning,.1,.55,damage,"ground");
                        for(var k=0;k<array_length(roots);k++)roots[k].root_time=.55;
                    }
                    break;
                }
                for(var i=-1;i<=1;i++) {
                    h=bv2_zone(_b,"swamp_roots",clamp(_b.v2_target_x+i*155,80,room_width-80),clamp(_b.v2_target_y+abs(i)*75,80,room_height-80),65,warning+abs(i)*.15,.55,damage,"ground");
                    if(is_struct(h))h.root_time=.55;
                }break;
            case 4:
                for(var i=0;i<3;i++) {
                    var angle=i*120+30,xx=clamp(_b.v2_target_x+lengthdir_x(170,angle),105,room_width-105),yy=clamp(_b.v2_target_y+lengthdir_y(170,angle),105,room_height-105);
                    bv2_zone(_b,"swamp_mushroom",xx,yy,92,warning+i*.22,.25,damage,"all");
                    h=bv2_zone(_b,"swamp_spores",xx,yy,82,warning+i*.22+.25,2.1,6*_b.v2_scaling.damage,"ground");
                    if(is_struct(h)){h.hit_once=false;h.interval=.7;h.poison=2;}
                }break;
            case 5:
                h=bv2_ring(_b,"swamp_stomp",_b.x,_b.y-10,350,0,warning,1.5,damage,"ground");
                if(is_struct(h)){h.expand_from=80;h.expand_to=350;h.ring_width=36;h.push=55;h.interval=.7;}
                if(phase>=2) {
                    // Two shockwaves with limited safe gaps: first towards the player, then rotated by 120 degrees.
                    var toward=point_direction(_b.x,_b.y-10,_b.v2_target_x,_b.v2_target_y);
                    if(is_struct(h)){h.gap_angle=toward;h.gap_width=62;}
                    var h2=bv2_ring(_b,"swamp_stomp",_b.x,_b.y-10,350,0,warning+.95,1.5,damage,"ground");
                    if(is_struct(h2)){h2.expand_from=80;h2.expand_to=350;h2.ring_width=36;h2.push=55;h2.interval=.7;h2.gap_angle=toward+((_b.v2_cycle mod 2)==0 ? 120 : -120);h2.gap_width=62;}
                }
                break;
            case 6:
                // Later phases: while the brood hunts, poison closes in around the behemoth and shrinks the open area.
                if(phase>=3)bc_closing_ring(_b,"swamp_closing",_b.x,_b.y-10,640,320,900,warning,4.2,bv2_attack_profile("behemoth",2).damage*_b.v2_scaling.damage);
                break;
            case 7:
                var breath_angle=point_direction(mouth.x,mouth.y,_b.v2_target_x,_b.v2_target_y);
                h=bv2_sector(_b,"swamp_breath",mouth.x,mouth.y,365,breath_angle,80,warning,1.9,damage,"all");
                if(is_struct(h)){h.poison=2.4;h.interval=.55;if(phase>=2){var sd=(_b.v2_cycle mod 2==0) ? 1 : -1;bc_sweep_sector(h,breath_angle-sd*32,breath_angle+sd*32);}}break;
            case 8:
                // The mud wave now rolls 1500 px: far kiters must jump it or step out of its announced lane.
                var angle=point_direction(_b.x,_b.y-10,_b.v2_target_x,_b.v2_target_y),wave_len=1500;
                h=bv2_line(_b,"swamp_wave",_b.x,_b.y-10,_b.x+lengthdir_x(wave_len,angle),_b.y-10+lengthdir_y(wave_len,angle),190,warning,3.6,damage,"ground");
                if(is_struct(h)){h.wave_from_x=_b.x;h.wave_from_y=_b.y-10;h.wave_angle=angle;h.wave_length=wave_len;h.wave_thickness=75;h.wave_width=190;h.push=100;h.hit_once=true;}
                break;
            case 9:
                // Outer petals first; then the center, with a final patterned spore belt. Safe regions change deliberately.
                for(var i=0;i<5;i++) {
                    var angle=18+i*72,xx=clamp(_b.v2_target_x+lengthdir_x(225,angle),100,room_width-100),yy=clamp(_b.v2_target_y+lengthdir_y(225,angle),100,room_height-100);
                    h=bv2_zone(_b,"swamp_bloom",xx,yy,82,warning,.45,damage,"all");if(is_struct(h))h.poison=1.5;
                }
                bv2_zone(_b,"swamp_bloom_core",_b.v2_target_x,_b.v2_target_y,135,warning+1.2,.4,damage*1.2,"all");
                h=bv2_ring(_b,"swamp_bloom_spores",_b.v2_target_x,_b.v2_target_y,305,80,warning+2.4,.65,damage,"ground");
                if(is_struct(h)){h.hit_once=true;h.gap_angle=270;h.gap_width=65;h.poison=2;}
                break;
        }
    }
    return true;
}
function bv2_behemoth_mouth(_b) {return {x:_b.x+_b.v2_facing*55,y:_b.y-180};}
function bv2_encounter_release(_b) {
    var p=_b.v2_profile,damage=p.damage*_b.v2_scaling.damage,extra=max(0,floor(_b.v2_scaling.projectiles)),pl=ObjectPlayer;
    if(_b.v2_kind=="twins") {
        if(_b.v2_attack==1 && instance_exists(_b.v2_child)) {
            var actors=[_b,_b.v2_child];
            for(var side=0;side<2;side++) {
                var actor=actors[side],origin=bv2_twins_origin(_b,side==1),angle=point_direction(origin.x,origin.y,pl.x,pl.y-10),count=3+min(2,extra);
                for(var i=0;i<count;i++)bv2_bullet(_b,side==0 ? "twins_fire" : "twins_ice",origin.x,origin.y,angle+(i-(count-1)*.5)*14,(side==0 ? 175 : 225)*_b.v2_scaling.projectile_speed,damage,side==0 ? 12 : 9,4.5);
            }
        }
        fg_sfx("twins_"+string(_b.v2_attack));
    } else {
        if(_b.v2_attack==1) {
            var mouth=bv2_behemoth_mouth(_b),angle=point_direction(mouth.x,mouth.y,pl.x,pl.y-10),count=1+min(2,extra);
            for(var i=0;i<count;i++) {
                var h=bv2_bullet(_b,"swamp_spit",mouth.x,mouth.y,angle+(i-(count-1)*.5)*17,190*_b.v2_scaling.projectile_speed,damage,16,4.5);
                if(is_struct(h)){h.poison=2;h.splash_radius=55;}
            }
        }
        if(_b.v2_attack==6)for(var i=0;i<3+(_b.boss_phase>=3 ? 1 : 0);i++)bv2_summon(_b,clamp(_b.x+(i-1)*80,40,room_width-40),clamp(_b.y+60+(i mod 2)*45,40,room_height-40));
        fg_sfx("swamp_"+string(_b.v2_attack));
    }
    var col=_b.v2_kind=="twins" ? make_color_rgb(187,135,255) : make_color_rgb(149,227,60);
    light_pulse(_b.x,_b.y-90,260,col,.7,.3);
}
function bv2_encounter_update_links(_b) {
    if(_b.v2_kind!="twins" || !instance_exists(_b.v2_child))return;
    var ice=_b.v2_child;
    for(var i=0;i<array_length(_b.v2_moving_lines);i++) {
        var rec=_b.v2_moving_lines[i],h=rec.hazard,origin=bv2_twins_origin(_b,rec.mode=="ice_cross"),target=bv2_twins_origin(_b,true),ax=origin.x,ay=origin.y;
        var ex=target.x,ey=target.y;
        if(rec.mode=="fire_cross" || rec.mode=="ice_cross") {
            // Very long beams: aimed through the announced point and continuing far beyond it.
            var aim=point_direction(ax,ay,_b.v2_target_x+(rec.mode=="fire_cross" ? 250 : -250),_b.v2_target_y+180);
            // Phase 3+: the fire beam sweeps 28 degrees during its active time (beam sweep over the ice stripe pattern).
            if(rec.mode=="fire_cross" && _b.boss_phase>=3)aim+=28*clamp((h.age-h.warning)/max(.1,h.active),0,1)*((_b.v2_cycle mod 2)==0 ? 1 : -1);
            ex=ax+lengthdir_x(bc_config().beam_length,aim);ey=ay+lengthdir_y(bc_config().beam_length,aim);
        }
        h.g.x=ax;h.g.y=ay;h.g.radius=point_distance(ax,ay,ex,ey);h.g.angle=point_direction(ax,ay,ex,ey);
    }
    for(var i=0;i<array_length(_b.v2_spiral_fields);i++) {
        var rec=_b.v2_spiral_fields[i],a=_b.v2_clock*22+(rec.side<0 ? 180 : 0);
        rec.hazard.g.x=_b.v2_center_x+lengthdir_x(135,a);rec.hazard.g.y=_b.v2_center_y+lengthdir_y(65,a);
    }
}
function bv2_encounter_step(_b,_dt) {
    if(global.game_paused || global.game_over || !instance_exists(ObjectPlayer) || _b.hp<=0)return;
    _b.v2_clock+=_dt;_b.v2_state_age+=_dt;_b.v2_formation_age+=_dt;_b.v2_turn_time=max(0,_b.v2_turn_time-_dt);_b.v2_other_turn_time=max(0,_b.v2_other_turn_time-_dt);
    var was_teleport=_b.teleport_warning>0;
    if(boss_navigation_step(_b,_dt)) {
        bv2_clear_owner(_b);_b.v2_moving_lines=[];_b.v2_spiral_fields=[];
        if(was_teleport && _b.teleport_warning<=0){_b.v2_center_x=ObjectPlayer.x;_b.v2_center_y=ObjectPlayer.y-10;_b.v2_origin_x=_b.x;_b.v2_origin_y=_b.y;_b.v2_formation="split";if(instance_exists(_b.v2_child)){_b.v2_child.x=clamp(_b.x+180,90,room_width-90);_b.v2_child.y=_b.y;}}
        return;
    }
    if(bc_catchup_step(_b,_b.v2_kind=="twins" ? "twins" : "behemoth",_dt)){_b.v2_move_speed=0;return;} // rare announced repositioning
    _b.boss_timer=max(0,_b.boss_timer-_dt);
    if(_b.boss_state=="windup" || _b.boss_state=="active")_b.v2_attack_age+=_dt;
    if(_b.boss_state=="windup" && _b.v2_attack_age>=_b.v2_warning) {
        var overflow=max(0,_b.v2_attack_age-_b.v2_warning);
        bv2_encounter_state(_b,"active",max(0,_b.v2_profile.active-overflow));
        if(!_b.v2_launched){_b.v2_launched=true;bv2_encounter_release(_b);}
    } else if(_b.boss_timer<=0) {
        if(_b.boss_state=="active")bv2_encounter_state(_b,"recovery",max(.65,1.25/max(1,_b.v2_scaling.speed)));
        else if(_b.boss_state=="intro" || _b.boss_state=="transition")bv2_encounter_state(_b,"recovery",.65);
        else {
            var phase=bv2_encounter_phase(_b);
            if(phase!=_b.boss_phase){_b.boss_phase=phase;bv2_encounter_state(_b,"transition",1.1);fg_sfx("boss_phase");}
            else {
                var forced=false;
                if(variable_global_exists("boss_test") && is_struct(global.boss_test) && global.boss_test.active && global.boss_test.ability!=-1)forced=boss_v2_force_attack(_b,global.boss_test.ability);
                if(!forced){var rotation=bv2_encounter_rotation(_b);bv2_encounter_attack_begin(_b,rotation[_b.v2_cycle mod array_length(rotation)]);_b.v2_cycle++;}
            }
        }
    }
    if(_b.v2_kind=="twins") {
        if(_b.boss_state=="recovery" || _b.boss_state=="intro") {
            var blend=1-exp(-.7*_dt);_b.v2_center_x=lerp(_b.v2_center_x,ObjectPlayer.x,blend);_b.v2_center_y=lerp(_b.v2_center_y,ObjectPlayer.y-10,blend);
            if(_b.boss_state=="recovery")_b.v2_formation=(_b.v2_cycle mod 3)==0 ? "follow" : ((_b.v2_cycle mod 3)==1 ? "eight" : "circle");
        }
        bv2_encounter_twins_positions(_b,_dt);bv2_encounter_update_links(_b);
    } else if(_b.boss_state=="recovery" || _b.boss_state=="intro") {
        var pl=ObjectPlayer,goal_x=pl.x+(pl.x<_b.x ? 220 : -220),goal_y=pl.y+190,dir=point_direction(_b.x,_b.y,goal_x,goal_y),distance=point_distance(_b.x,_b.y,pl.x,pl.y),goal_distance=point_distance(_b.x,_b.y,goal_x,goal_y),move_amount=distance>210 ? min(32*_dt,goal_distance) : 0;
        _b.x=clamp(_b.x+lengthdir_x(move_amount,dir),150,room_width-150);_b.y=clamp(_b.y+lengthdir_y(move_amount,dir),350,room_height-30);
        var face=pl.x<_b.x ? -1 : 1;if(face!=_b.v2_facing)_b.v2_turn_time=.24;_b.v2_facing=face;
    }
    _b.v2_move_speed=point_distance(_b.x,_b.y,_b.v2_last_x,_b.v2_last_y)/max(.001,_dt);_b.depth=-_b.y;_b.v2_last_x=_b.x;_b.v2_last_y=_b.y;
}
function bv2_actor_animation(_b,_ice=false) {
    var action=_b.v2_kind=="twins" ? "idle" : "idle",frame=floor(_b.v2_clock*5) mod 4;
    if(_b.hp<=0){action="death";frame=min(3,floor(_b.v2_state_age*4));}
    else if(_b.boss_state=="transition"){action="phase";frame=floor(_b.v2_state_age*7) mod 4;}
    else if(_b.boss_state=="windup"){action=_b.v2_kind=="twins" ? "charge" : _b.v2_profile.animation;frame=clamp(floor(_b.v2_attack_age/max(.1,_b.v2_warning)*4),0,3);}
    else if(_b.boss_state=="active"){action=_b.v2_profile.animation;frame=floor(_b.v2_state_age*9) mod 4;}
    else if(_b.hurt_flash_timer>0){action="hurt";frame=min(3,floor((6-_b.hurt_flash_timer)*.5));}
    else if((_ice ? _b.v2_other_turn_time : _b.v2_turn_time)>0){action="turn";frame=clamp(floor((1-(_ice ? _b.v2_other_turn_time : _b.v2_turn_time)/.24)*4),0,3);}
    else if(_b.v2_kind=="twins"){action=_b.v2_formation=="cross" || _b.v2_formation=="dive" ? "fast" : "fly";frame=floor(_b.v2_clock*7) mod 4;}
    else if(_b.v2_move_speed>1){action="walk";frame=floor(_b.v2_clock*5) mod 4;}
    return {action:action,frame:frame};
}
function bv2_actor_draw(_b,_ice=false) {
    if(!instance_exists(_b))return;
    var twin=_b.v2_kind=="twins",actor=_ice && instance_exists(_b.v2_child) ? _b.v2_child : _b,a=bv2_actor_animation(_b,_ice);
    var prefix=twin ? (_ice ? "spr_bv2_ice_" : "spr_bv2_fire_") : "spr_bv2_behemoth_",spr=asset_get_index(prefix+a.action);
    if(!sprite_exists(spr))return;
    // Hurt/death are one-shot reactions: short resources must hold their final pose.
    // draw_sprite_ext wraps excess indices, which replayed hurt frame 0 at the end.
    var draw_frame=(a.action=="hurt" || a.action=="death") ? clamp(a.frame,0,sprite_get_number(spr)-1) : a.frame;
    var hover=twin ? (_ice ? _b.v2_other_hover : _b.v2_hover) : 0,scale=twin ? 135/90 : 340/430;
    var face=_ice ? _b.v2_other_facing : _b.v2_facing,alpha=_b.hp<=0 ? clamp(1-_b.v2_state_age/1.5,0,1) : 1;
    if(variable_instance_exists(_b,"bc_alpha"))alpha*=_b.bc_alpha;
    if(alpha<=.01)return;
    if(level_world_room())master_shadow_draw(actor.x,actor.y,twin ? 30 : 120,twin ? 9 : 28,twin ? .22 : .38);
    draw_sprite_ext(spr,draw_frame,actor.x,actor.y-hover,scale*face,scale*(1+sin(_b.v2_clock*2.1)*.006),0,_b.hurt_flash_timer>0 ? make_color_rgb(255,205,196) : c_white,alpha);
    if(twin && _b.hp>0){var col=_ice ? make_color_rgb(118,210,255) : make_color_rgb(255,134,70);draw_set_color(col);draw_set_alpha(.55);for(var i=0;i<3;i++){var phase=frac(_b.v2_clock*.6+i*.33);draw_circle(actor.x+sin(_b.v2_clock*2+i)*15,actor.y-hover+10+phase*28,2*(1-phase),false);}}
    draw_set_alpha(1);draw_set_color(c_white);
}
function bv2_encounter_draw(_b) {
    // Gameplay hazards, their warnings and active effects are drawn centrally by bv2_hazards_draw.
    // This layer adds non-damaging pact/roots ambience only; it never advertises another hitbox.
    if(_b.v2_kind=="twins" && instance_exists(_b.v2_child) && _b.boss_state=="transition") {
        var a=bv2_twins_origin(_b,false),b=bv2_twins_origin(_b,true);draw_set_color(make_color_rgb(193,140,238));draw_set_alpha(.35);draw_line_width(a.x,a.y,b.x,b.y,2);
    }
    draw_set_alpha(1);draw_set_color(c_white);
}
