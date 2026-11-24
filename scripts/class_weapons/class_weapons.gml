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
    shot.class_weapon_v2=true;shot.class_tier=sword_visual_tier(global.current_level);return shot;
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
    attack_stage=global.selected_character=="Mage" ? class_combo_index : (class_combo_index==12 ? 3 : (class_combo_index==3 || class_combo_index==9 ? 2 : 1));
    attack_duration=global.selected_character=="Mage" ? (class_combo_index==4 ? 44 : 30) : (class_combo_index==12 ? 28 : 14);
    attack_timer=attack_duration;class_pending=class_combo_index;class_release=global.selected_character=="Mage" ? (class_combo_index==4 ? 22 : 12) : (class_combo_index==12 ? 10 : (class_combo_index==3 || class_combo_index==9 ? 6 : 4));
    weapon_cooldown=max(12,ceil(weapon.cooldown/(1+weapon_haste)));
}
function class_weapon_release(_pl,_step) {
    var mage=global.selected_character=="Mage",amount=round(_pl.weapon.damage+_pl.player_power*_pl.weapon.power_scale),tier=sword_visual_tier(global.current_level),radius;
    // Equipment weapon damage and class talents (neutral without gear / at rank 0).
    amount=round(amount*(variable_instance_exists(_pl,"weapon_damage_mult") ? _pl.weapon_damage_mult : 1)*(mage ? 1 : 1+talent_stat("ranger_dmg_pct")));
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
            class_fx_add("ranger_rain",_pl.class_target_x,_pl.class_target_y,amount,125*_pl.spell_area,1.25+waves*.16);global.class_effects[array_length(global.class_effects)-1].waves=5+waves;fg_sfx("ranger_rain");
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
function class_fx_burst(_x,_y,_radius,_row) {class_fx_add("burst"+string(_row),_x,_y,0,_radius,.4);light_pulse(_x,_y,min(360,_radius*2),_row<4 ? make_color_rgb(166,116,255) : make_color_rgb(166,235,119),1,.3);}
function class_fx_sprite(_row,_progress,_x,_y,_radius,_angle=0,_alpha=1) {
    var spr=asset_get_index("spr_class_fx_"+string(_row));if(!sprite_exists(spr))return;
    draw_sprite_ext(spr,min(7,floor(clamp(_progress,0,.999)*8)),_x,_y,_radius*2/256,_radius*2/256,_angle,c_white,_alpha);
}
function class_effects_draw() {
    if(!variable_global_exists("class_effects"))return;
    var tier=sword_visual_tier(global.current_level);
    for(var i=0;i<array_length(global.class_effects);i++) {
        var f=global.class_effects[i],p=f.age/f.duration;
        if(string_pos("burst",f.kind)==1) {if(f.kind=="burst3")draw_sprite_ext(spr_mage_star_implosion,min(3,2+floor(p*2)),f.x,f.y,f.radius*2/256,f.radius*2/256,0,c_white,1);else class_fx_sprite(real(string_delete(f.kind,1,5)),p,f.x,f.y,f.radius);continue;}
        if(f.kind=="mage_arc") {
            class_fx_sprite(1,p,f.x+lengthdir_x(f.radius*.45,f.angle),f.y+lengthdir_y(f.radius*.45,f.angle),f.radius*.65,f.angle);
            if(f.age>=.09 && f.age<.25){var arc=telegraph_make("sector",f.x,f.y,f.radius,1,f.angle,120);arc.elapsed=1;telegraph_draw(arc,make_color_rgb(147,117,255));}
        }
        if(f.kind=="mage_circle") {
            class_fx_sprite(2,p,f.x,f.y,f.radius);draw_set_alpha(.5);draw_set_color(make_color_rgb(155,115,255));draw_circle(f.x,f.y,f.radius,true);
            if(tier>1)for(var rune=0;rune<6+tier*2;rune++){var a=rune*360/(6+tier*2)+f.age*50;draw_sprite_ext(icon_v2_105,0,f.x+lengthdir_x(f.radius*.8,a),f.y+lengthdir_y(f.radius*.8,a),.13,.13,a,c_white,.6);}
        }
        if(f.kind=="sword_wave") {
            var p2=clamp(f.age/f.duration,0,1);gpu_set_blendmode(bm_add);
            draw_set_color(make_color_rgb(255,190,110));draw_set_alpha(.55*(1-p2));draw_circle(f.x,f.y,f.radius*(.25+.75*p2),true);
            draw_set_alpha(.25*(1-p2));draw_circle(f.x,f.y,f.radius*(.2+.8*p2)-3,true);gpu_set_blendmode(bm_normal);draw_set_alpha(1);
        }
        if(f.kind=="mage_star" || f.kind=="mage_star_nova") {
            var flight=clamp(f.age/.85,0,1),xx=lerp(f.sx,f.x,flight),ground_y=lerp(f.sy,f.y,flight),height=sin(pi*flight)*180;
            if(f.age<1){var shrink=f.age>.85 ? 1-(f.age-.85)/.15*.7 : 1,orb_scale=(45+tier*7)*shrink*2/256;draw_sprite_ext(spr_mage_star_orb,floor(f.age*10) mod 4,xx,ground_y-height,orb_scale,orb_scale,0,c_white,1);draw_set_color(make_color_rgb(164,116,255));draw_set_alpha(.6);for(var trail=1;trail<=5;trail++){var prev=max(0,flight-trail*.018),tx=lerp(f.sx,f.x,prev),ty=lerp(f.sy,f.y,prev)-sin(pi*prev)*180;draw_circle(tx,ty,4-trail*.5,false);}}
            var mark=telegraph_make("circle",f.x,f.y,f.radius,.85);mark.elapsed=f.age;telegraph_draw(mark,make_color_rgb(156,118,255));
        }
        if(f.kind=="ranger_rain") {
            var mark=telegraph_make("circle",f.x,f.y,f.radius,.4);mark.elapsed=f.age;telegraph_draw(mark,make_color_rgb(150,232,113));
            if(f.age>=.25)for(var n=0;n<20+tier*4;n++) {
                var a=n*137.5,r=f.radius*sqrt((n+.5)/(20+tier*4)),xx=f.x+lengthdir_x(r,a),yy=f.y+lengthdir_y(r,a),fall=frac(f.age*3+n*.137);
                if(f.age>.4 && f.age<1.17)class_fx_sprite(4,.2,xx-40*(1-fall),yy-170*(1-fall),19,285);
                if(fall>.8)class_fx_sprite(5,fall,xx,yy,16);
            }
        }
    }
    draw_set_alpha(1);draw_set_color(c_white);
}
