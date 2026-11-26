/// Data-driven level definitions shared by menu, world generation, spawning, lighting, weather, audio and bosses.
/// Index order equals global.selected_level. The forest keeps its previous room, values and spawn rules unchanged.
function level_definitions() {
    static defs=[
        {id:"forest",name:"Verzauberter Wald",room_name:"Room1",preview:"spr_lv_forest_preview",
         desc:"Daemmriger Waldruinen-Grund mit Feuerschalen, Moos und alten Mauern. Skelettkrieger, -spaeher und -wachen.",
         tagline:"Ausgewogen",palette:[make_color_rgb(42,70,72),make_color_rgb(110,92,60),make_color_rgb(170,62,48),make_color_rgb(230,160,70)],
         hp_mult:1,damage_mult:1,music:"mus_fg_level",ambient_loop:"",world:"master",layout:"",
         weather:{fog:0.045,rain:1,wind:0.45,ambient:make_color_rgb(187,202,219)},ambient_min:[152,165,183],ambient_max:[210,220,235],
         leaves:[make_color_rgb(188,128,55),make_color_rgb(172,62,48)],boss_weights:{storm_warden:1,twins:1,behemoth:1}},
        {id:"swamp",name:"Verfluchter Sumpf",room_name:"RoomSwamp",fallback_room:"RoomCrypt",preview:"spr_lv_sw_preview",
         desc:"Totbaeume, dunkles Wasser, giftige Tuempel und Nebel. Sumpfkriecher, Sumpfskelette, Pilzkreaturen und versunkene Ritter.",
         tagline:"Gift, Schlamm und dichte Horden",palette:[make_color_rgb(24,46,40),make_color_rgb(60,84,48),make_color_rgb(120,190,70),make_color_rgb(150,120,190)],
         hp_mult:0.9,damage_mult:1.1,music:"mus_fg_level_swamp",ambient_loop:"amb_fg_swamp",world:"generated",layout:"level_layout_swamp",
         weather:{fog:0.15,rain:0.55,wind:0.22,ambient:make_color_rgb(128,150,134)},ambient_min:[104,124,110],ambient_max:[150,176,156],
         leaves:[make_color_rgb(112,104,48),make_color_rgb(84,98,52)],boss_weights:{storm_warden:1,twins:1,behemoth:2}},
        {id:"ashfrost",name:"Aschenfrost-Ruinen",room_name:"RoomAshfrost",fallback_room:"RoomRuins",preview:"spr_lv_af_preview",
         desc:"Zerstoerte Magierstadt aus Eis, Asche und Glutadern. Aschenkrieger, verfluchte Ruestungen, Eisgeister und Konstrukte.",
         tagline:"Mehr Elitegegner",palette:[make_color_rgb(36,48,72),make_color_rgb(120,140,170),make_color_rgb(230,110,40),make_color_rgb(110,210,230)],
         hp_mult:1.25,damage_mult:1.15,music:"mus_fg_level_ruins",ambient_loop:"amb_fg_ruins",world:"generated",layout:"level_layout_ashfrost",
         weather:{fog:0.07,rain:0,wind:0.55,ambient:make_color_rgb(132,146,182)},ambient_min:[108,120,152],ambient_max:[160,172,205],
         leaves:[make_color_rgb(150,150,160),make_color_rgb(110,104,104)],boss_weights:{storm_warden:1,twins:2,behemoth:1}}
    ];
    return defs;
}
function level_count() {return array_length(level_definitions());}
function level_names() {var names=[];for(var i=0;i<level_count();i++)array_push(names,level_def(i).name);return names;}
function level_def(_index=-1) {
    var defs=level_definitions(),i=_index<0 ? (variable_global_exists("selected_level") ? global.selected_level : 0) : _index;
    return defs[clamp(i,0,array_length(defs)-1)];
}
/// Room of a level; a generated level whose room is missing falls back to the forest instead of a broken state.
function level_room(_index) {
    var d=level_def(_index),r=asset_get_index(d.room_name);
    if(room_exists(r))return r;
    if(variable_struct_exists(d,"fallback_room")){r=asset_get_index(d.fallback_room);if(room_exists(r))return r;}
    return Room1;
}
function level_index_for_room(_room) {
    for(var i=0;i<level_count();i++)if(level_room(i)==_room && (i==0 || _room!=Room1))return i;
    return -1;
}
/// Shared world rules (shadows, scenery collision, occlusion) apply in every authored world room.
function level_world_room() {return room==Room1 || (instance_exists(ObjectLevelWorld) && ObjectLevelWorld.world_ready);}
function level_generated() {return instance_exists(ObjectLevelWorld) && ObjectLevelWorld.world_ready;}
function level_music_asset() {
    var a=asset_get_index(level_def().music);
    return audio_exists(a) ? a : mus_fg_level;
}

/// ---------------------------------------------------------------- authored level enemies
/// Timings in seconds; reach is the true strike contact distance; trigger (< reach) starts the telegraphed attack,
/// so an enemy only commits to a swing once it can actually connect. Moving away during the windup still dodges it.
function level_enemy_kinds() {
    static kinds={
        swamp_skeleton:{name:"Sumpfskelett",prefix:"spr_lv_en_swskel_",hp:96,damage:11,speed:0.96,scale:1.4,reach:43,trigger:41,windup:.24,strike_end:.40,total:.80,hover:0,weave:0,death:"remains",frames_attack:2},
        swamp_crawler:{name:"Sumpfkriecher",prefix:"spr_lv_en_crawler_",baked:true,hp:46,damage:7,speed:1.62,scale:1.1,reach:32,trigger:30,windup:.16,strike_end:.30,total:.56,hover:0,weave:.35,death:"remains",frames_attack:4},
        swamp_mushroom:{name:"Pilzkreatur",prefix:"spr_lv_en_shroom_",baked:true,hp:70,damage:9,speed:0.92,scale:1.25,reach:36,trigger:34,windup:.30,strike_end:.46,total:.85,hover:0,weave:0,death:"spores",frames_attack:4},
        swamp_knight:{name:"Versunkener Ritter",prefix:"spr_lv_en_knight_",hp:190,damage:19,speed:0.74,scale:1.62,reach:54,trigger:51,windup:.42,strike_end:.60,total:1.08,hover:0,weave:0,death:"remains",frames_attack:2},
        ash_warrior:{name:"Aschenkrieger",prefix:"spr_lv_en_ashwar_",hp:64,damage:10,speed:1.45,scale:1.36,reach:44,trigger:42,windup:.14,strike_end:.30,total:.56,hover:0,weave:0,death:"remains",frames_attack:2},
        cursed_armor:{name:"Verfluchte Ruestung",prefix:"spr_lv_en_armor_",hp:175,damage:17,speed:0.80,scale:1.56,reach:52,trigger:49,windup:.40,strike_end:.58,total:1.02,hover:0,weave:0,death:"remains",frames_attack:2},
        ice_spirit:{name:"Eisgeist",prefix:"spr_lv_en_spirit_",baked:true,hp:52,damage:8,speed:1.25,scale:1.3,reach:38,trigger:36,windup:.22,strike_end:.36,total:.62,hover:18,weave:1,death:"remains",frames_attack:4},
        construct:{name:"Magisches Konstrukt",prefix:"spr_lv_en_construct_",baked:true,hp:230,damage:14,speed:0.62,scale:1.62,reach:46,trigger:70,windup:.62,strike_end:.78,total:1.35,hover:0,weave:0,death:"remains",frames_attack:4,slam:76}
    };
    return kinds;
}
/// Time-based composition: variety grows with the run clock; no per-level change to the population curve.
function level_enemy_pick(_level_id,_elapsed,_roll) {
    if(_level_id=="swamp") {
        if(_elapsed<60) return _roll<56 ? "swamp_crawler" : "swamp_skeleton";
        if(_elapsed<180) return _roll<46 ? "swamp_crawler" : (_roll<80 ? "swamp_skeleton" : "swamp_mushroom");
        var knight=min(18,10+_elapsed/90);
        return _roll<40 ? "swamp_crawler" : (_roll<70 ? "swamp_skeleton" : (_roll<100-knight ? "swamp_mushroom" : "swamp_knight"));
    }
    if(_elapsed<60) return _roll<55 ? "ash_warrior" : "cursed_armor";
    if(_elapsed<180) return _roll<46 ? "ash_warrior" : (_roll<78 ? "cursed_armor" : "ice_spirit");
    var construct=min(16,8+_elapsed/100);
    return _roll<40 ? "ash_warrior" : (_roll<66 ? "cursed_armor" : (_roll<100-construct ? "ice_spirit" : "construct"));
}
function level_enemy_spawn(_x,_y) {
    var lv=level_def(),elapsed=global.round_seconds,kind=level_enemy_pick(lv.id,elapsed,irandom(99));
    var e=level_enemy_create(_x,_y,kind);
    // Crawler packs: small tight groups instead of a single file; still bounded by the runtime cap.
    if(kind=="swamp_crawler" && elapsed>=25 && irandom(99)<35 && instance_exists(ObjectSpawner) && instance_number(ObjectMonster)<ObjectSpawner.runtime_cap-2) {
        repeat(2){var a=random(360),px=_x+lengthdir_x(26,a),py=_y+lengthdir_y(26,a);if(!scenery_point_blocked(px,py-6,12))level_enemy_create(px,py,kind);}
    }
    return e;
}
/// Sprite scale divisor: creatures marked baked are rendered at their cfg.scale (pixel density 1:1, see
/// tests/tools/levels/enemies.py creature_spec), so they are drawn at monster_scale/cfg.scale (1 unless elite).
/// Switch (on): an earlier suspicion that it broke the level suite was the suite's real frame time (fixed 26.11.).
#macro ENEMY_MOTION_ENABLED true
/// Movement identity per species (Phase 2B, docs/Design/Kampf & Begegnungen.md 7): whole-pixel body offsets layered on
/// the frame animation. Rhythm and weight differ (light scuttle, bouncy hop, heavy stomp, stiff jerk, floating drift);
/// the wind-up pulls back from the target and the strike lunges toward it, so the body announces the attack.
function enemy_motion_profile(_kind) {
    static p={
        swamp_crawler:{rate:15,bob:1,side:1,hop:0,heavy:0,back:1,lunge:5,jerk:0},
        swamp_mushroom:{rate:5.5,bob:0,side:0,hop:4,heavy:0,back:1,lunge:3,jerk:0},
        swamp_skeleton:{rate:7,bob:1,side:0,hop:0,heavy:0,back:2,lunge:3,jerk:1},
        swamp_knight:{rate:4.5,bob:2,side:0,hop:0,heavy:1,back:3,lunge:4,jerk:0},
        ash_warrior:{rate:6,bob:1,side:0,hop:0,heavy:0,back:2,lunge:4,jerk:0},
        cursed_armor:{rate:3.8,bob:2,side:0,hop:0,heavy:1,back:3,lunge:3,jerk:1},
        ice_spirit:{rate:2.2,bob:0,side:3,hop:0,heavy:0,back:-3,lunge:4,jerk:0},
        construct:{rate:3.2,bob:2,side:0,hop:0,heavy:1,back:2,lunge:2,jerk:0}
    };
    return variable_struct_exists(p,_kind) ? p[$ _kind] : undefined;
}
function enemy_motion_offset() {
    var o={dx:0,dy:0};
    if(!variable_instance_exists(id,"lvl_kind"))return o;
    var pr=enemy_motion_profile(lvl_kind);if(!is_struct(pr))return o;
    var t=current_time/1000+particle_phase*.37,moving=point_distance(x,y,xprevious,yprevious)>.15;
    var ph=t*pr.rate,face=instance_exists(ObjectPlayer) ? sign(ObjectPlayer.x-x) : 1;if(face==0)face=1;
    if(moving) {
        if(pr.heavy){var s=abs(sin(ph));o.dy=-round(pr.bob*power(s,3));}                 // heavy: long ground contact, short lift
        else o.dy=-round(pr.bob*abs(sin(ph)));
        if(pr.hop>0)o.dy=-round(pr.hop*abs(sin(ph)));                                  // bouncy hop
        if(pr.side>0)o.dx=round(pr.side*sin(ph*(pr.hop>0 ? 1 : 2)));                     // scuttle / drift
        if(pr.jerk && (floor(ph*2) mod 3)==0)o.dx+=face;                                // stiff, jerky gait
    }
    if(variable_instance_exists(id,"skeleton_attacking") && skeleton_attacking && is_struct(lvl_cfg)) {
        var at=skeleton_attack_time,wu=max(.01,lvl_cfg.windup),se=lvl_cfg.strike_end;
        if(at<wu){var k=at/wu;o.dx=-face*round(pr.back*k);o.dy=lvl_kind=="ice_spirit" ? -round(3*k) : (pr.heavy ? -round(k) : round(k*.6));}
        else if(at<se){var k=clamp((at-wu)/max(.01,se-wu),0,1);o.dx=face*round(pr.lunge*sin(pi*min(1,k*1.4)));o.dy=pr.heavy ? round(2*sin(pi*k)) : 0;}
    }
    return o;
}
function monster_art_div(_e) {
    return (variable_instance_exists(_e,"lvl_cfg") && is_struct(_e.lvl_cfg) && variable_struct_exists(_e.lvl_cfg,"baked")) ? _e.lvl_cfg.scale : 1;
}
function level_enemy_create(_x,_y,_kind) {
    var cfg=variable_struct_get(level_enemy_kinds(),_kind);
    var e=instance_create_layer(_x,_y,"Instances",ObjectMonster);
    with(e) {
        master_skeleton=false;lvl_kind=_kind;lvl_cfg=cfg;monster_species=_kind;
        max_hp=cfg.hp*global.monster_hp_multiplier;hp=max_hp;
        damage=cfg.damage*global.monster_damage_multiplier;base_move_speed=cfg.speed;monster_scale=cfg.scale;
        skeleton_clock=random(1);skeleton_action="walk";skeleton_direction="down";skeleton_attacking=false;skeleton_attack_time=0;skeleton_strike=false;
        lvl_hover=cfg.hover;lvl_weave_phase=random(360);lvl_slam_done=false;
        sprite_index=player_artpack_sprite(cfg.prefix+"walk_down");image_index=0;image_speed=0;image_xscale=1;
    }
    return e;
}
function level_enemy_step(_dt) {
    var cfg=lvl_cfg,pl=instance_exists(ObjectPlayer) ? ObjectPlayer : noone;
    var dist=instance_exists(pl) ? point_distance(x,y,pl.x,pl.y) : 99999;
    if(!skeleton_attacking && dist<cfg.trigger && hit_stun<=0) {skeleton_attacking=true;skeleton_attack_time=0;lvl_slam_done=false;}
    skeleton_strike=false;
    var action=dist>cfg.trigger+6 ? "walk" : "idle";
    if(skeleton_attacking) {
        skeleton_attack_time+=_dt;
        skeleton_strike=skeleton_attack_time>=cfg.windup && skeleton_attack_time<cfg.strike_end;
        action="attack";
        if(skeleton_attack_time>=cfg.total){skeleton_attacking=false;skeleton_strike=false;}
    }
    if(monster_hurt_timer>0 || hit_stun>0) {monster_hurt_timer=max(0,monster_hurt_timer-1);action="hurt";skeleton_strike=false;}
    if(skeleton_strike && instance_exists(pl)) {
        if(variable_struct_exists(cfg,"slam")) {
            // Construct slam: one area check per attack inside its announced ring.
            if(!lvl_slam_done){lvl_slam_done=true;light_pulse(x,y-10,180,make_color_rgb(120,220,255),.8,.25);
                if(point_distance(x,y,pl.x,pl.y)<=cfg.slam && player_receive_damage(pl,damage,"ground"))pl.health_visible_time=3;}
        } else if(dist<=cfg.reach) player_contact(pl,id);
    }
    var angle=instance_exists(pl) ? point_direction(x,y,pl.x,pl.y) : 270;
    if(!skeleton_attacking || skeleton_attack_time<.12)skeleton_direction=player_visual_direction("swordsmanv3",angle);
    if(action!=skeleton_action){skeleton_clock=0;skeleton_action=action;}
    skeleton_clock+=_dt;
    sprite_index=player_artpack_sprite(cfg.prefix+action+"_"+skeleton_direction);
    var count=sprite_get_number(sprite_index);
    image_xscale=1;image_yscale=1;image_speed=0;
    if(action=="attack") {
        var half=max(1,count div 2);
        image_index=skeleton_attack_time<cfg.windup ? min(half-1,floor(skeleton_attack_time/cfg.windup*half)) : min(count-1,half+floor((skeleton_attack_time-cfg.windup)/max(.01,cfg.total-cfg.windup)*(count-half)));
    } else if(action=="hurt") image_index=min(count-1,floor(skeleton_clock*20));
    else image_index=floor(skeleton_clock*(action=="walk" ? 9 : 4)) mod count;
}
function level_enemy_death(_e) {
    var cfg=_e.lvl_cfg;
    if(instance_number(ObjectSkeletonRemains)>=32)with(instance_find(ObjectSkeletonRemains,0))instance_destroy();
    var rem=instance_create_layer(_e.x,_e.y,"Instances",ObjectSkeletonRemains);
    rem.sprite_index=player_artpack_sprite(cfg.prefix+"death_"+_e.skeleton_direction);
    rem.remains_scale=_e.monster_scale;rem.remains_art=monster_art_div(_e);rem.depth=-_e.y;rem.life=0;rem.remains_hover=_e.lvl_hover;
    if(cfg.death=="spores")level_puff_add(_e.x,_e.y-6,66,.55,9*global.monster_damage_multiplier,"spore");
}

/// Level select panel: real world preview, name, short description and the level's palette.
function level_select_preview_draw(_index,_gw,_gh) {
    var d=level_def(_index),spr=asset_get_index(d.preview);
    var pw=min(_gw*0.44,560),ph=pw*9/16,px=_gw*0.52,py=_gh*0.26;
    draw_set_alpha(1);draw_set_color(make_color_rgb(8,12,16));draw_rectangle(px-6,py-6,px+pw+6,py+ph+6,false);
    draw_set_color(d.palette[3]);draw_rectangle(px-6,py-6,px+pw+6,py+ph+6,true);
    if(sprite_exists(spr)) {
        var sc=min(pw/sprite_get_width(spr),ph/sprite_get_height(spr));
        draw_sprite_ext(spr,0,px+pw/2-sprite_get_width(spr)*sc/2+sprite_get_xoffset(spr)*sc,py+ph/2-sprite_get_height(spr)*sc/2+sprite_get_yoffset(spr)*sc,sc,sc,0,c_white,1);
    } else {draw_set_color(d.palette[0]);draw_rectangle(px,py,px+pw,py+ph,false);}
    draw_set_halign(fa_left);draw_set_valign(fa_top);
    draw_set_color(make_color_rgb(236,210,150));draw_text(px,py+ph+16,d.name);
    draw_set_color(make_color_rgb(150,170,170));draw_text(px,py+ph+40,d.tagline);
    draw_set_color(make_color_rgb(210,218,210));draw_text_ext(px,py+ph+66,d.desc,20,pw);
    for(var i=0;i<array_length(d.palette);i++){var sx=px+pw-4-(array_length(d.palette)-i)*26;draw_set_color(d.palette[i]);draw_rectangle(sx,py+ph+18,sx+20,py+ph+34,false);draw_set_color(make_color_rgb(20,24,28));draw_rectangle(sx,py+ph+18,sx+20,py+ph+34,true);}
    draw_set_halign(fa_center);draw_set_valign(fa_middle);draw_set_color(c_white);
}
