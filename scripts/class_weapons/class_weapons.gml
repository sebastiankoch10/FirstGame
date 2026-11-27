/// Automatic base weapons, separate from the six active spell slots.
function class_weapon_init() {class_combo_index=0;class_pending=0;class_release=0;class_target=noone;class_target_x=x;class_target_y=y;}
function class_fx_add(_kind,_x,_y,_damage,_radius,_duration,_sx=0,_sy=0,_angle=0) {
    if(!variable_global_exists("class_effects"))global.class_effects=[];
    if(array_length(global.class_effects)>=48)return;
    array_push(global.class_effects,{kind:_kind,x:_x,y:_y,sx:_sx,sy:_sy,damage:_damage,radius:_radius,duration:_duration,age:0,ticks:0,angle:_angle});
}
function class_weapon_area(_x,_y,_radius,_damage) {
    var targets=spell_targets(_x,_y,_radius);for(var i=0;i<array_length(targets);i++)apply_attack_damage(targets[i],_damage,ObjectPlayer,0);
}
function class_weapon_projectile(_pl,_dir,_damage,_ranger) {
    var shot=instance_create_layer(_pl.x+lengthdir_x(23,_dir),_pl.y-20+lengthdir_y(23,_dir),"Instances",ObjectLightningball);
    shot.owner=_pl;shot.direction=_dir;shot.image_angle=_dir;shot.damage=_damage+_pl.split_bonus;shot.spell_id=0;
    shot.projectile_kind=_ranger ? "bolt" : "wand";shot.projectile_speed=(_ranger ? 16 : 10)*_pl.projectile_factor;shot.lifetime=ceil(_pl.weapon.range*(variable_instance_exists(_pl,"weapon_range_mult") ? _pl.weapon_range_mult : 1)/shot.projectile_speed);shot.damage_radius=_ranger ? 5 : 10;
    shot.class_weapon_v2=true;shot.class_tier=weapon_visual_tier();return shot;
}
function class_weapon_auto_step() {
    if(global.game_paused || hp<=0)return;
    if(class_pending>0) {
        class_release--;
        if(class_release<=0) {class_weapon_release(id,class_pending);class_pending=0;}
        return;
    }
    if(weapon_cooldown>0)return;
    var target=combat_nearest(id,weapon.range*(variable_instance_exists(id,"weapon_range_mult") ? weapon_range_mult : 1));if(!instance_exists(target))return;
    class_combo_index=(class_combo_index mod (global.selected_character=="Mage" ? 4 : 12))+1;
    class_target=target;class_target_x=target.x;class_target_y=target.y-10;
    attack_direction=point_direction(x,y-10,class_target_x,class_target_y);
    var tl=class_weapon_timeline(class_combo_index),wind=tl.events[0];
    attack_stage=wind.stage;attack_duration=wind.dur;
    attack_timer=attack_duration;class_pending=class_combo_index;class_release=atl_time(tl,"release");
    weapon_cooldown=max(12,ceil(weapon.cooldown/(1+weapon_haste)));
}
/// Attack timeline of a combo step (attack_timeline.gml): Mage 1-4; Ranger 12 = finisher, 3 and 9 = heavy, else light.
function class_weapon_timeline(_step) {
    if(global.selected_character=="Mage")return atl_get("mage_"+string(_step));
    return atl_get(_step==12 ? "ranger_finisher" : (_step==3 || _step==9 ? "ranger_heavy" : "ranger_light"));
}
function class_weapon_release(_pl,_step) {
    var mage=global.selected_character=="Mage",amount=round(_pl.weapon.damage+_pl.player_power*_pl.weapon.power_scale),tier=sword_visual_tier(global.current_level),radius;
    // Equipment weapon damage and class talents (neutral without gear / at rank 0).
    amount=round(amount*(variable_instance_exists(_pl,"weapon_damage_mult") ? _pl.weapon_damage_mult : 1)*(mage ? 1+talent_stat("mage_dmg_pct") : 1+talent_stat("ranger_dmg_pct")));
    if(mage) {
        switch(_step) {
            case 1:class_weapon_projectile(_pl,_pl.attack_direction,amount,false);fg_sfx("mage_bolt");break;
            case 2:
                radius=155*_pl.spell_area;
                class_fx_add("mage_arc",_pl.x,_pl.y-10,amount*1.4,radius,.42,0,0,_pl.attack_direction);fg_sfx("mage_arc");break;
            case 3:
                class_fx_add("mage_circle",_pl.class_target_x,_pl.class_target_y,amount*1.8,130*_pl.spell_area,.65);fg_sfx("mage_circle");break;
            case 4:
                var star=1+talent_stat("mage_star");
                class_fx_add(talent_stat("mage_nova")>0 ? "mage_star_nova" : "mage_star",_pl.class_target_x,_pl.class_target_y,amount*3.5*star,170*_pl.spell_area*star,talent_stat("mage_nova")>0 ? 1.55 : 1.25,_pl.x,_pl.y-28);fg_sfx("mage_star");break;
        }
    } else {
        if(_step==12) {
            var waves=talent_stat("ranger_rain");
            class_fx_add("ranger_rain",_pl.class_target_x,_pl.class_target_y,amount,125*_pl.spell_area,1.25+waves*.16);var rain=array_length(global.class_effects)>0 ? global.class_effects[array_length(global.class_effects)-1] : undefined;if(is_struct(rain) && rain.kind=="ranger_rain" && rain.age==0)rain.waves=5+waves;fg_sfx("ranger_rain");
            if(talent_stat("ranger_quiver")>0)for(var q=0;q<7;q++)class_weapon_projectile(_pl,_pl.attack_direction+(q-3)*9,amount,true);
        }
        else {
            var count=_step==3 ? 3 : (_step==9 ? 5 : 1);
            if(count>1)count+=talent_stat("ranger_volley");
            // The authored 3/5 shot steps stay exact; Split Runes adds damage here, never changes the cycle.
            for(var i=0;i<count;i++)class_weapon_projectile(_pl,_pl.attack_direction+(i-(count-1)*.5)*8,amount,true);
            fg_sfx(count>1 ? "ranger_volley" : "ranger_arrow");
        }
    }
    light_pulse(_pl.x,_pl.y-25,100+tier*20,mage ? make_color_rgb(155,115,255) : make_color_rgb(145,240,112),.5,.12);
}
function class_effects_step(_dt) {
    if(global.game_paused || !instance_exists(ObjectPlayer) || !variable_global_exists("class_effects"))return;
    for(var i=array_length(global.class_effects)-1;i>=0;i--) {
        var f=global.class_effects[i];f.age+=_dt;
        fx_class_effect_particles(f,_dt); // graphics overhaul (visual only)
        if(f.kind=="mage_arc" && f.age>=.09 && f.ticks==0) {
            var zone=telegraph_make("sector",f.x,f.y,f.radius,1,f.angle,120),targets=spell_targets(f.x,f.y,f.radius);
            for(var j=0;j<array_length(targets);j++)if(telegraph_contains(zone,targets[j].x,targets[j].y-10))apply_attack_damage(targets[j],f.damage,ObjectPlayer,0);
            f.ticks++;
        }
        if(f.kind=="mage_circle" && f.age>=.3 && f.ticks==0) {
            class_weapon_area(f.x,f.y,f.radius,f.damage);f.ticks++;class_fx_burst(f.x,f.y,f.radius,2);
            if(talent_stat("mage_slow")>0){var slowed=spell_targets(f.x,f.y,f.radius);for(var j=0;j<array_length(slowed);j++){var e=slowed[j];e.slow_factor=min(e.slow_time>0 ? e.slow_factor : 1,.7);e.slow_time=max(e.slow_time,round(60*talent_stat("mage_slow")));}}
        }
        if(f.kind=="sword_wave" && f.age>=.06 && f.ticks==0) {class_weapon_area(f.x,f.y,f.radius,f.damage+0);f.ticks++;light_pulse(f.x,f.y,f.radius*2,make_color_rgb(255,196,120),.7,.25);}
        if(f.kind=="mage_star_nova") {
            if(f.age>=1 && f.ticks==0){class_weapon_area(f.x,f.y,f.radius,f.damage+0);f.ticks++;class_fx_burst(f.x,f.y,f.radius,3);fg_sfx("mage_implosion");}
            if(f.ticks==1 && f.age<1.32){var pulled=spell_targets(f.x,f.y,f.radius*1.4);for(var j=0;j<array_length(pulled);j++){var e=pulled[j];if(boss_is_actor(e))continue;var ox=e.x,oy=e.y,a=point_direction(e.x,e.y-10,f.x,f.y),pull=min(240*_dt,point_distance(e.x,e.y-10,f.x,f.y));e.x+=lengthdir_x(pull,a);e.y+=lengthdir_y(pull,a);scenery_resolve(e,ox,oy);}}
            if(f.age>=1.32 && f.ticks==1){class_weapon_area(f.x,f.y,f.radius*.85,f.damage*.5);f.ticks++;class_fx_burst(f.x,f.y,f.radius*.85,3);fg_sfx("mage_implosion");}
        }
        if(f.kind=="mage_star" && f.age>=1 && f.ticks==0) {class_weapon_area(f.x,f.y,f.radius,f.damage);f.ticks++;class_fx_burst(f.x,f.y,f.radius,3);fg_sfx("mage_implosion");}
        if(f.kind=="ranger_rain" && f.age>=.4+f.ticks*.16 && f.ticks<(variable_struct_exists(f,"waves") ? f.waves : 5)) {class_weapon_area(f.x,f.y,f.radius,f.damage*.55);f.ticks++;class_fx_burst(f.x,f.y,f.radius*.45,5);}
        if(f.age>=f.duration)array_delete(global.class_effects,i,1);
    }
}
// light .55 instead of 1: with the overbright world light (graphics overhaul) the full pulse washed the fight out (visual-qa 27.11.)
function class_fx_burst(_x,_y,_radius,_row) {class_fx_add("burst"+string(_row),_x,_y,0,_radius,.4);light_pulse(_x,_y,min(360,_radius*2),_row<4 ? make_color_rgb(166,116,255) : make_color_rgb(166,235,119),.55,.3);}
/// Class effect sheet rows as pixel composites (render_pipeline): 0 arcane bolt, 4 arrow, 7 dust; others keep the
/// old sprite (no class uses them any more).
function class_fx_sprite(_row,_progress,_x,_y,_radius,_angle=0,_alpha=1) {
    switch(_row) {
        case 0:vfx_arcane_bolt(_x,_y,_radius,_angle,_alpha);break;
        case 4:vfx_arrow_shot(_x,_y,_radius,_angle,_alpha);break;
        case 7:vfx_dust_puff(_x,_y,_radius,_progress,_alpha);break;
        default:var spr=asset_get_index("spr_class_fx_"+string(_row));if(sprite_exists(spr))draw_sprite_ext(spr,min(7,floor(clamp(_progress,0,.999)*8)),_x,_y,_radius*2/256,_radius*2/256,_angle,c_white,_alpha);
    }
    draw_set_alpha(1);draw_set_color(c_white);
}
/// Arkanistin bolt: violet pixel orb with a light core and a short tapering trail.
function vfx_arcane_bolt(_x,_y,_r,_dir,_alpha) {
    var pal=vfx_palette(4),x0=round(_x),y0=round(_y),r=max(3,round(_r*.3));
    if(vfx_quality()>0)vfx_glow_disc(x0,y0,r*2,pal[1],.22*_alpha);
    for(var g=1;g<=4;g++)vfx_px(x0-lengthdir_x(r+g*4,_dir)-1,y0-lengthdir_y(r+g*4,_dir)-1,g<3 ? 3 : 2,g<3 ? pal[1] : pal[0],_alpha*(1-g*.18));
    draw_set_alpha(_alpha);draw_set_color(pal[0]);draw_circle(x0,y0,r,false);draw_set_color(pal[1]);draw_circle(x0,y0,max(1,r-1),false);
    draw_set_color(pal[2]);draw_circle(x0-1,y0-1,max(1,r*.45),false);
}
/// Waldlaeufer arrow in flight: shaft, steel head, green fletching, a faint streak.
/// Baseline arrow (Phase 2B): a plain physical arrow - slim wooden shaft, small steel head, natural fletching, only a
/// faint motion streak. No element colour: poison, fire or lightning looks come only from real element mechanics.
function vfx_arrow_shot(_x,_y,_r,_dir,_alpha) {
    var len=clamp(_r*.75,12,17),tx=_x-lengthdir_x(len,_dir),ty=_y-lengthdir_y(len,_dir),wood=make_color_rgb(150,112,70),light=make_color_rgb(204,170,118);
    if(vfx_quality()>0)vfx_pixel_line(tx-lengthdir_x(10,_dir),ty-lengthdir_y(10,_dir),tx,ty,1,make_color_rgb(214,214,206),.16*_alpha); // motion streak
    vfx_pixel_line(tx,ty,_x,_y,1,wood,_alpha);
    vfx_pixel_line(tx+lengthdir_x(2,_dir),ty+lengthdir_y(2,_dir),_x-lengthdir_x(2,_dir),_y-lengthdir_y(2,_dir),1,light,.55*_alpha);
    // steel head: 3 px point with a bright tip pixel
    vfx_pixel_line(_x,_y,_x+lengthdir_x(3,_dir),_y+lengthdir_y(3,_dir),2,make_color_rgb(150,158,166),_alpha);
    vfx_px(_x+lengthdir_x(3,_dir),_y+lengthdir_y(3,_dir),1,make_color_rgb(232,236,238),_alpha);
    // fletching: two short off-white/brown vanes
    for(var s=-1;s<=1;s+=2)vfx_pixel_line(tx+lengthdir_x(3,_dir),ty+lengthdir_y(3,_dir),tx+lengthdir_x(2*s,_dir+90),ty+lengthdir_y(2*s,_dir+90),1,s<0 ? make_color_rgb(222,214,196) : make_color_rgb(176,148,112),_alpha);
}
/// Dust puff (slam, stomp): three grey-brown pixel clouds that swell and fade.
function vfx_dust_puff(_x,_y,_r,_p,_alpha) {
    var k=(1-_p)*_alpha;
    for(var i=0;i<3;i++){var a=i*120+30,d=_r*.35*_p;draw_set_alpha(k*.8);draw_set_color(i==1 ? make_color_rgb(150,128,96) : make_color_rgb(112,94,72));draw_circle(round(_x+lengthdir_x(d,a)),round(_y+lengthdir_y(d*.6,a)),max(2,_r*(.25+.35*_p)),false);}
}
function class_effects_draw() {
    if(!variable_global_exists("class_effects"))return;
    var tier=weapon_visual_tier();
    for(var i=0;i<array_length(global.class_effects);i++) {
        var f=global.class_effects[i],p=f.age/f.duration;
        if(string_pos("burst",f.kind)==1){vfx_class_burst(f.x,f.y,f.radius,p,real(string_delete(f.kind,1,5)),tier);continue;}
        if(f.kind=="mage_arc") {
            vfx_arc_sweep(f.x,f.y,f.angle,60,f.radius,p,4,tier);
        }
        if(f.kind=="mage_circle") {
            vfx_magic_circle(f.x,f.y,f.radius,p,f.age,tier);
        }
        if(f.kind=="sword_wave") {
            var p2=clamp(f.age/f.duration,0,1);gpu_set_blendmode(bm_add);
            draw_set_color(make_color_rgb(255,190,110));draw_set_alpha(.55*(1-p2));draw_circle(f.x,f.y,f.radius*(.25+.75*p2),true);
            draw_set_alpha(.25*(1-p2));draw_circle(f.x,f.y,f.radius*(.2+.8*p2)-3,true);gpu_set_blendmode(bm_normal);draw_set_alpha(1);
        }
        if(f.kind=="mage_star" || f.kind=="mage_star_nova") {
            var flight=clamp(f.age/.85,0,1),xx=lerp(f.sx,f.x,flight),ground_y=lerp(f.sy,f.y,flight),height=sin(pi*flight)*180;
            // the orb grows out of the staff instead of covering the figure at launch (visual-qa 27.11.)
            if(f.age<1){var shrink=(f.age>.85 ? 1-(f.age-.85)/.15*.7 : 1)*clamp(flight*6,.3,1);vfx_star_orb(xx,ground_y-height,(20+tier*4)*shrink,f.age);var pal=vfx_palette(4);for(var trail=1;trail<=5;trail++){var prev=max(0,flight-trail*.018),tx=lerp(f.sx,f.x,prev),ty=lerp(f.sy,f.y,prev)-sin(pi*prev)*180;vfx_px(tx-1,ty-1,trail<3 ? 3 : 2,trail<3 ? pal[1] : pal[0],1-trail*.15);}}
            if(f.age<.85)vfx_player_target_mark(f.x,f.y,f.radius,f.age/.85,make_color_rgb(186,150,255));
        }
        if(f.kind=="ranger_rain") {
            if(f.age<.4)vfx_player_target_mark(f.x,f.y,f.radius,f.age/.4,make_color_rgb(170,236,140));
            if(f.age>=.25)for(var n=0;n<20+tier*4;n++) {
                var a=n*137.5,r=f.radius*sqrt((n+.5)/(20+tier*4)),xx=f.x+lengthdir_x(r,a),yy=f.y+lengthdir_y(r,a),fall=frac(f.age*3+n*.137);
                if(f.age>.4 && f.age<1.17)vfx_arrow_fall(xx-40*(1-fall),yy-170*(1-fall),285);
                if(fall>.8)vfx_arrow_hit(xx,yy,(fall-.8)/.2,n);
            }
        }
    }
    draw_set_alpha(1);draw_set_color(c_white);
}

// ---------------- Weapon upgrades (user decision 25.11.2026) ----------------
/// Cards in the level-up/chest offer, five levels per class weapon, independent of the six spell slots.
/// Each level adds a bundle on the existing weapon hooks (read through talent_stat). New, untested design values;
/// see docs/Design/Progression & Builds.md. The weapon look (slash/projectile tiers) follows the upgrade level.
function weapon_upgrade_levels(_cls) {
    static data={
        Sword:[{sword_dmg_pct:.08},{sword_dmg_pct:.08,sword_reach_pct:.05},{sword_dmg_pct:.08,haste:.04},{sword_dmg_pct:.08,sword_reach_pct:.05},{sword_dmg_pct:.08,haste:.04}],
        Mage:[{mage_dmg_pct:.08},{mage_dmg_pct:.08,mage_star:.08},{mage_dmg_pct:.08,haste:.04},{mage_dmg_pct:.08,mage_star:.08},{mage_dmg_pct:.08,haste:.04}],
        Ranger:[{ranger_dmg_pct:.07},{ranger_dmg_pct:.07,range_pct:.08},{ranger_dmg_pct:.07,haste:.04},{ranger_dmg_pct:.07,ranger_volley:1},{ranger_dmg_pct:.07,haste:.04}]
    };
    return variable_struct_exists(data,_cls) ? data[$ _cls] : data.Sword;
}
function weapon_upgrade_max() {return 5;}
function weapon_upgrade_level() {return variable_global_exists("weapon_upgrade_level") ? global.weapon_upgrade_level : 0;}
function weapon_upgrade_name() {var c=talent_class_key();return c=="Mage" ? "Sternenstab" : (c=="Ranger" ? "Jagdbogen" : "Klinge");}
function weapon_upgrade_reset() {global.weapon_upgrade_level=0;global.weapon_upgrade_cache={};}
function weapon_upgrade_stat(_key) {
    if(!variable_global_exists("weapon_upgrade_cache"))return 0;
    return variable_struct_exists(global.weapon_upgrade_cache,_key) ? global.weapon_upgrade_cache[$ _key] : 0;
}
function weapon_upgrade_rebuild() {
    var c={},lv=weapon_upgrade_levels(talent_class_key());
    for(var i=0;i<min(weapon_upgrade_level(),array_length(lv));i++){var k=variable_struct_get_names(lv[i]);for(var j=0;j<array_length(k);j++)c[$ k[j]]=(variable_struct_exists(c,k[j]) ? c[$ k[j]] : 0)+lv[i][$ k[j]];}
    global.weapon_upgrade_cache=c;
}
function weapon_upgrade_take() {
    if(weapon_upgrade_level()>=weapon_upgrade_max())return false;
    global.weapon_upgrade_level=weapon_upgrade_level()+1;weapon_upgrade_rebuild();
    if(instance_exists(ObjectPlayer))apply_passives(ObjectPlayer);
    feedback_toast_add(weapon_upgrade_name()+" Stufe "+string(global.weapon_upgrade_level),make_color_rgb(242,206,120));
    return true;
}
/// Visual tier 1-3 of the class weapon: follows the weapon's real progress (was the player level 1/34/68).
function weapon_visual_tier() {var l=weapon_upgrade_level();return l>=4 ? 3 : (l>=2 ? 2 : 1);}
/// Readable effect of level _level (1-5) for the card detail.
function weapon_upgrade_text(_level) {
    var lv=weapon_upgrade_levels(talent_class_key());if(_level<1 || _level>array_length(lv))return "";
    var e=lv[_level-1],k=variable_struct_get_names(e),s="";
    var names={sword_dmg_pct:"Schwertschaden",mage_dmg_pct:"Stabschaden",ranger_dmg_pct:"Pfeilschaden",sword_reach_pct:"Hiebreichweite",haste:"Angriffstempo",mage_star:"Sternenorb Radius und Schaden",range_pct:"Waffenreichweite",ranger_volley:"Pfeile je Salve"};
    for(var i=0;i<array_length(k);i++){var v=e[$ k[i]];s+=(s=="" ? "" : "\n")+"+"+(k[i]=="ranger_volley" ? string(v) : string(round(v*100))+"%")+" "+(variable_struct_exists(names,k[i]) ? names[$ k[i]] : k[i]);}
    return s;
}
// ---------------- Class weapon effects as pixel composites (render_pipeline: everything on the world grid) ----------------
/// Arkanistin sweep: a violet crescent over the hit sector (same crescent as the sword swing, arcane palette).
function vfx_arc_sweep(_x,_y,_dir,_half,_r,_p,_element,_tier) {
    var pal=vfx_palette(_element),head=clamp(_p*1.6,0,1),tail=clamp(_p*1.6-.7,0,1),fade=_p<.6 ? 1 : (_p<.8 ? .7 : .4);
    if(head-tail<.02)return;
    var a0=_dir-_half,a1=_dir+_half,cy=_y-6,ro=_r*.55,band=ro*(.26+.03*_tier),n=max(10,ceil(_half*2*(head-tail)*ro/120)),k=.7+.1*_tier;
    if(vfx_quality()>0){gpu_set_blendmode(bm_add);vfx_crescent(_x,cy,a0,a1,tail,head,ro,band,n,3,pal[1],.25*k*fade);gpu_set_blendmode(bm_normal);}
    vfx_crescent(_x,cy,a0,a1,tail,head,ro,band,n,0,pal[0],.9*fade);
    vfx_crescent(_x,cy,a0,a1,tail,head,ro,band,n,1,pal[1],.8*fade);
    vfx_crescent(_x,cy,a0,a1,tail,head,ro,band,n,2,pal[2],fade);
    var tick=floor(_p*30),sp=4+_tier*2;
    for(var s=0;s<sp;s++){var q=lerp(tail,head,(s+.5)/sp),a=lerp(a0,a1,q),rr=ro+3+5*abs(vfx_hash(s,tick));vfx_px(_x+lengthdir_x(rr,a),cy+lengthdir_y(rr,a),s mod 2 ? 1 : 2,pal[2],fade);}
    draw_set_alpha(1);draw_set_color(c_white);
}
/// Arkanistin circle: two pixel rings turning in opposite directions, runes (pixel diamonds) on the outer ring,
/// a soft fill; it charges up and flashes at the end of its life.
function vfx_magic_circle(_x,_y,_r,_p,_age,_tier) {
    var pal=vfx_palette(4),k=_p<.85 ? 1 : 1-(_p-.85)/.15,grow=min(1,_p*4);
    if(vfx_quality()>0)vfx_glow_disc(_x,_y,_r*grow,pal[1],.10*k);
    vfx_pixel_ring(_x,_y,_r*grow,pal[1],.9*k,_age*40,0,2);
    vfx_pixel_ring(_x,_y,_r*grow*.72,pal[0],.8*k,-_age*70,3,1);
    var runes=6+_tier*2;
    for(var i=0;i<runes;i++) {
        var a=i*360/runes+_age*50,rx=round(_x+lengthdir_x(_r*grow*.86,a)),ry=round(_y+lengthdir_y(_r*grow*.86,a));
        vfx_px(rx-1,ry-2,2,pal[2],k);vfx_px(rx-2,ry-1,1,pal[1],k);vfx_px(rx+1,ry-1,1,pal[1],k);vfx_px(rx-1,ry,2,pal[1],k);
    }
    if(_p>.8){var fl=(_p-.8)/.2;vfx_pixel_ring(_x,_y,_r*(.3+.7*fl),pal[2],1-fl,0,0,2);}
    draw_set_alpha(1);draw_set_color(c_white);
}
/// Falling star of the Arkanistin: layered pixel orb with a turning sparkle cross.
function vfx_star_orb(_x,_y,_r,_age) {
    // Graphics overhaul (27.11.): a translucent body with structure instead of a flat opaque disc (it read as a pink
    // blob under the brighter light): dark shell, counter-rotating pixel rims, three spiral arms into a hot core, and a
    // pulsing star glint. Trail and sparks come from fx_class_effect_particles.
    var pal=vfx_palette(4),x0=round(_x),y0=round(_y),r=max(2,round(_r)),t=_age;
    if(vfx_quality()>0)vfx_glow_disc(x0,y0,r*1.7,pal[1],.07);
    draw_set_alpha(.5);draw_set_color(pal[0]);draw_circle(x0,y0,r,false);
    draw_set_alpha(.3);draw_set_color(pal[1]);draw_circle(x0,y0,max(1,round(r*.7)),false);
    vfx_pixel_ring(x0,y0,r,pal[1],.95,t*140,3,1);
    vfx_pixel_ring(x0,y0,max(2,r-3),pal[2],.65,-t*210,5,1);
    for(var arm=0;arm<3;arm++)for(var k=0;k<6;k++){var q=k/6,a=arm*120+t*260+q*150,d=r*(.86-.7*q);vfx_px(x0+lengthdir_x(d,a),y0+lengthdir_y(d,a),k<3 ? 2 : 1,pal[2],1);}
    draw_set_alpha(.85);draw_set_color(pal[1]);draw_circle(x0,y0,max(1,round(r*.22)),false); // core not burnt out: light violet, white only in the centre
    draw_set_color(c_white);draw_rectangle(x0-1,y0-1,x0,y0,false);
    var s=round(r*.8)+round(1.5*sin(t*20)); // glint inside the body (a cross beyond it read like a crosshair)
    vfx_pixel_line(x0-s,y0,x0+s,y0,1,pal[2],.6);vfx_pixel_line(x0,y0-s,x0,y0+s,1,pal[2],.6);
    draw_set_alpha(1);draw_set_color(c_white);
}
/// Class detonation (row 2: circle, row 3: star implosion): rings collapse, then a shock ring and sparks run out.
function vfx_class_burst(_x,_y,_r,_p,_row,_tier) {
    var pal=vfx_palette(4),k=1-_p,tick=floor(_p*30);
    if(_row==3 && _p<.35){var q=_p/.35;vfx_pixel_ring(_x,_y,_r*(1-q),pal[1],1,q*90,0,2);vfx_pixel_ring(_x,_y,_r*(1-q)*.6,pal[2],1,-q*90,2,1);if(vfx_quality()>0)vfx_glow_disc(_x,_y,_r*.4*q,pal[2],.25);return;}
    var q=_row==3 ? (_p-.35)/.65 : _p;
    if(vfx_quality()>0)vfx_glow_disc(_x,_y,_r*(.3+.7*q),pal[1],.2*(1-q));
    vfx_pixel_ring(_x,_y,_r*(.3+.7*q),pal[2],1-q,0,0,2);
    vfx_pixel_ring(_x,_y,_r*(.2+.6*q),pal[1],.8*(1-q),q*40,4,1);
    var sp=8+_tier*3;
    for(var i=0;i<sp;i++){var a=i*360/sp+11*vfx_hash(i,_row),d=_r*(.25+.85*q)*(.8+.2*abs(vfx_hash(i,tick)));vfx_px(_x+lengthdir_x(d,a),_y+lengthdir_y(d,a),i mod 3 ? 1 : 2,i mod 2 ? pal[2] : pal[1],1-q);}
    draw_set_alpha(1);draw_set_color(c_white);
}
/// Waldlaeufer arrow rain: one falling arrow as pixels (shaft, head, fletching) along its flight direction.
function vfx_arrow_fall(_x,_y,_dir) {
    var tx=_x-lengthdir_x(16,_dir),ty=_y-lengthdir_y(16,_dir);
    vfx_pixel_line(tx,ty,_x,_y,1,make_color_rgb(214,178,120),1);
    vfx_px(_x+lengthdir_x(1,_dir)-1,_y+lengthdir_y(1,_dir)-1,2,make_color_rgb(236,240,232),1);
    vfx_px(tx-1,ty-1,2,make_color_rgb(222,214,196),1); // natural fletching, no element colour
    if(vfx_quality()>0)vfx_pixel_line(tx-lengthdir_x(10,_dir),ty-lengthdir_y(10,_dir),tx,ty,1,make_color_rgb(214,214,206),.18);
}
/// Arrow impact: a short cross and dust pixels.
function vfx_arrow_hit(_x,_y,_q,_seed) {
    var pal=vfx_palette(0),k=1-_q,s=2+round(_q*3); // physical: splinters and dust
    vfx_pixel_line(_x-s,_y,_x+s,_y,1,pal[2],k);vfx_pixel_line(_x,_y-s,_x,_y+s,1,pal[1],k);
    for(var i=0;i<3;i++){var a=i*120+40*vfx_hash(_seed,i);vfx_px(_x+lengthdir_x(3+_q*8,a),_y+lengthdir_y(2+_q*5,a),1,make_color_rgb(150,128,96),k);}
}
/// Player target aid (not an enemy telegraph: no fill, no countdown surface): thin rotating rune dashes and a centre dot
/// in the player's colour, tightening slightly toward the impact (docs/Design/Kampf & Begegnungen.md, Telegraphs).
function vfx_player_target_mark(_x,_y,_r,_p,_col) {
    var t=current_time/1000,r=_r*(1-.12*_p),a0=t*90,x0=round(_x),y0=round(_y),al=.55*(1-.4*_p);
    for(var k=0;k<8;k++){var a=a0+k*45;vfx_pixel_line(x0+lengthdir_x(r,a),y0+lengthdir_y(r,a),x0+lengthdir_x(r,a+14),y0+lengthdir_y(r,a+14),1,_col,al);}
    draw_set_alpha(al);draw_set_color(_col);draw_rectangle(x0-1,y0-1,x0+1,y0+1,false);draw_set_alpha(1);draw_set_color(c_white);
}
