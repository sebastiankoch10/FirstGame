/// Graphics overhaul (Visuelles Leitbild 7): world feedback built from the shared pixel particles (fx_particles).
///   fx_hit            enemy hit: tiny core flash and sparks sprayed along the hit direction (crit: shock ring, light)
///   fx_enemy_death    dust ring at the feet, body pixels, rising motes; burning enemies die in embers, chilled ones
///                     shatter, shocked ones crackle
///   coins             glints on lying coins, a short sparkle on pickup, a thin trail while the magnet pulls them
///   pickups           chest (gold motes and light), magnet orb (cyan motes and light), loot (motes in rarity colour)
///   fx_levelup        light ring, rising column, shock ring, short golden scene tint and an afterglow aura
///   fx_sway_draw      wind sway of plants on the pixel grid (horizontal strips shifted by whole pixels; base fixed)
/// Visual only: no gameplay value is read for decisions or changed. Per-frame budgets keep hordes cheap, all particle
/// counts follow "Effektqualitaet" (fxp_n), flashes and tints follow "Lichtblitze" (fx_flash_k).
function fx_world_init() {if(!variable_global_exists("fxw") || !is_struct(global.fxw))global.fxw={hits:0,deaths:0,coins:0,levelup:0,crowd:1};}
function fx_world_reset() {global.fxw={hits:0,deaths:0,coins:0,levelup:0,crowd:1};}
/// Crowd relief (perf 27.11.): from about 60 enemies on, hits and deaths spawn fewer particles (35 % at 140+).
function fx_crowd_k() {return clamp(1.45-instance_number(ObjectMonster)/130,.35,1);}

/// Element of a damage source: spells carry their own, base weapons are physical (staff of the Arkanistin: arcane).
function fx_hit_element(_sid) {
    if(_sid>0){var d=GetSpellData(_sid);return is_struct(d) ? clamp(d.element,0,7) : 0;}
    return (variable_global_exists("selected_character") && global.selected_character=="Mage") ? 4 : 0;
}
/// Height of the visual centre above the feet.
function fx_body_mid(_e) {
    if(variable_instance_exists(_e,"visual_height"))return _e.visual_height*.45;
    return 15*(variable_instance_exists(_e,"monster_scale") ? _e.monster_scale : 1);
}
function fx_hit(_target,_source,_sid,_crit) {
    fx_world_init();var f=global.fxw;if(f.hits>=fxp_n(16*f.crowd) || !instance_exists(_target))return;f.hits++;
    var el=fx_hit_element(_sid),cx=_target.x,cy=_target.y-fx_body_mid(_target);
    var dir=instance_exists(_source) ? point_direction(_source.x,_source.y,_target.x,_target.y) : vfx_random(360);
    if(instance_exists(_source) && variable_instance_exists(_source,"projectile_speed"))dir=_source.direction;
    var big=_target.object_index==ObjectBossMonster,hx=cx-lengthdir_x(big ? 16 : 5,dir),hy=cy-lengthdir_y(big ? 16 : 5,dir);
    fxp_add(hx,hy,0,0,.06,el,_crit ? 7 : 3,FXP_FLASH,FXP_EMIT);
    // sparks leave the target on the far side (direction of the blow), falling slightly
    repeat(fxp_n((_crit ? 11 : 5)*f.crowd)){var a=dir+vfx_random_range(-55,55),sp=vfx_random_range(140,330);
        fxp_add(hx,hy,lengthdir_x(sp,a),lengthdir_y(sp,a)-25,vfx_random_range(.07,.17),el,1,FXP_STREAK,FXP_EMIT,260,6,.05);}
    if(el==2)repeat(fxp_n(2))fxp_add(hx,hy,vfx_random_range(-40,40),-vfx_random_range(20,60),vfx_random_range(.25,.45),2,1,FXP_SHARD,FXP_EMIT,240,1.5,.1);
    if(el==1)repeat(fxp_n(2))fxp_add(hx,hy,vfx_random_range(-25,25),-vfx_random_range(30,70),vfx_random_range(.3,.55),1,1,FXP_EMBER,FXP_EMIT,-60,2,.15);
    if(_crit){fx_shock(hx,hy,36,1.6,.22);light_pulse(hx,hy,80,vfx_palette(el)[1],.7*fx_flash_k(),.12);}
}
/// Element look of a dying enemy from its status (burning, chilled, shocked), otherwise dust and pale motes.
function fx_death_element(_e) {
    if(variable_instance_exists(_e,"burn_time") && _e.burn_time>0)return 1;
    if(variable_instance_exists(_e,"slow_time") && _e.slow_time>0)return 2;
    if(variable_instance_exists(_e,"shock_time") && _e.shock_time>0)return 3;
    return 0;
}
function fx_enemy_death(_e) {
    fx_world_init();var f=global.fxw;if(f.deaths>=fxp_n(9*f.crowd))return;f.deaths++;
    var ck=f.crowd,el=fx_death_element(_e),s=variable_instance_exists(_e,"monster_scale") ? _e.monster_scale : 1,fx=_e.x,fy=_e.y,cy=fy-fx_body_mid(_e);
    // dust ring kicked up at the feet (lit, so it takes the colour of the scene light)
    repeat(fxp_n(5*ck)){var a=vfx_random(360),sp=vfx_random_range(25,60)*s;
        fxp_add(fx+lengthdir_x(5*s,a),fy+lengthdir_y(2*s,a),lengthdir_x(sp,a),lengthdir_y(sp*.35,a)-6,vfx_random_range(.45,.75),el==1 ? 8 : 5,round(vfx_random_range(3,5)*s),FXP_PUFF,FXP_LIT,-8,2.2,.2,.75);}
    // the body breaks into pixels that fly out and fall
    repeat(fxp_n(9*s*ck)){var a=vfx_random_range(20,160),sp=vfx_random_range(60,170);
        fxp_add(fx+vfx_random_range(-7,7)*s,cy+vfx_random_range(-8,8)*s,lengthdir_x(sp,a),lengthdir_y(sp,a)-40,vfx_random_range(.3,.55),el==0 ? 5 : el,1,el==2 ? FXP_SHARD : FXP_PIXEL,FXP_EMIT,420,1.2,.15);}
    // rising motes (the "soul" of the kill, readable even in a crowd because they move against the flow)
    repeat(fxp_n(3)){fxp_add(fx+vfx_random_range(-6,6)*s,cy+vfx_random_range(-4,4),vfx_random_range(-8,8),-vfx_random_range(30,55),vfx_random_range(.6,1),el==0 ? 7 : el,1,FXP_EMBER,FXP_EMIT,-12,.6,.35,.9);}
    if(el==1){repeat(fxp_n(4))fxp_add(fx+vfx_random_range(-6,6),cy,vfx_random_range(-30,30),-vfx_random_range(40,90),vfx_random_range(.4,.8),1,vfx_choose(1,2),FXP_EMBER,FXP_EMIT,-70,2,0);if(f.deaths<=2)fxp_decal(fx,fy+2,8*s,1,2.5);}
    if(el==3)repeat(fxp_n(4)){var a=vfx_random(360);fxp_add(fx,cy,lengthdir_x(220,a),lengthdir_y(220,a),vfx_random_range(.06,.12),3,1,FXP_STREAK,FXP_EMIT,0,4,0);}
    fxp_add(fx,cy,0,0,.07,el==0 ? 0 : el,round(5*s),FXP_FLASH,FXP_EMIT);
    if(f.deaths<=3)light_pulse(fx,cy,70*s,vfx_palette(el==0 ? 7 : el)[1],.55*fx_flash_k(),.18);
}
/// Lying coins glint now and then (called from the coin's step, on screen only).
function fx_coin_glint(_c) {
    var r=combat_view_rect();if(_c.x<r.left || _c.x>r.right || _c.y<r.top || _c.y>r.bottom)return;
    fxp_add(_c.x+vfx_random_range(-3,3),_c.y-6+vfx_random_range(-3,2),0,-6,vfx_random_range(.25,.4),7,1,FXP_SHARD,FXP_EMIT,0,0,0);
}
/// Thin gold trail behind a coin the magnet pulls.
function fx_coin_trail(_c) {if(vfx_random(1)<.35*fxp_rate())fxp_add(_c.x,_c.y-5,vfx_random_range(-10,10),vfx_random_range(-10,10),vfx_random_range(.12,.22),7,1,FXP_PIXEL,FXP_EMIT,0,4,.2);}
function fx_coin_pickup(_x,_y) {
    fx_world_init();var f=global.fxw;if(f.coins>=fxp_n(8))return;f.coins++;
    repeat(fxp_n(4)){var a=vfx_random_range(40,140),sp=vfx_random_range(40,90);fxp_add(_x,_y-8,lengthdir_x(sp,a),lengthdir_y(sp,a),vfx_random_range(.18,.3),7,1,FXP_PIXEL,FXP_EMIT,120,3,0);}
    fxp_add(_x,_y-8,0,0,.05,7,2,FXP_FLASH,FXP_EMIT);
}
/// Level-up (plays when the choice closes: particles follow the simulation clock, which stands while paused).
function fx_levelup() {
    if(!instance_exists(ObjectPlayer))return;
    fx_world_init();var pl=ObjectPlayer,px=pl.x,py=pl.y,cy=py-20;global.fxw.levelup=1.4;
    repeat(fxp_n(28)){var a=vfx_random(360),sp=vfx_random_range(160,300);fxp_add(px+lengthdir_x(10,a),py+lengthdir_y(5,a),lengthdir_x(sp,a),lengthdir_y(sp*.45,a),vfx_random_range(.25,.4),7,1,FXP_STREAK,FXP_EMIT,0,5,.05);}
    repeat(fxp_n(36)){var a=vfx_random(360),rr=vfx_random_range(4,18);fxp_add(px+lengthdir_x(rr,a),py+lengthdir_y(rr*.5,a),vfx_random_range(-6,6),-vfx_random_range(90,220),vfx_random_range(.5,.9),7,vfx_choose(1,1,2),FXP_EMBER,FXP_EMIT,-30,1.2,vfx_random_range(0,.3));}
    fxp_add(px,cy,0,0,.12,7,14,FXP_FLASH,FXP_EMIT);
    fx_shock(px,py-6,110,2.4,.45);fx_scene_tint(make_color_rgb(255,214,120),.22*fx_flash_k(),.5);
    light_pulse(px,cy,240,make_color_rgb(255,214,120),1.4*fx_flash_k(),.6);
}
/// Per frame: budgets, level-up afterglow, auras of pickups.
function fx_world_step(_dt) {
    fx_world_init();var f=global.fxw;f.hits=0;f.deaths=0;f.coins=0;
    if(_dt<=0)return;
    f.crowd=fx_crowd_k();
    // dragon projectiles leave element trails (void, wind, fire volley)
    if(variable_global_exists("hostile_bullets"))for(var i=0;i<min(48,array_length(global.hostile_bullets));i++){var b=global.hostile_bullets[i];if(variable_struct_exists(b,"dragon_void"))fxp_trail(b.x,b.y,point_direction(0,0,b.vx,b.vy),b.wind ? 2 : (b.volley ? 1 : 4),point_distance(0,0,b.vx,b.vy),(b.wind || b.volley) ? .8 : 1.3);}
    // coin glints: a few random active coins per frame instead of a call in every coin's step (perf 27.11.)
    var nc=instance_number(ObjectCoin);if(nc>0)repeat(min(4,floor(nc*.005*fxp_rate()+vfx_random(1)))){var c=instance_find(ObjectCoin,vfx_irandom(nc-1));if(instance_exists(c) && !c.coin_collected && !c.magnetized)fx_coin_glint(c);}
    if(f.levelup>0 && instance_exists(ObjectPlayer)){f.levelup-=_dt;fxp_aura(ObjectPlayer.x,ObjectPlayer.y-4,16,7,clamp(f.levelup,0,1));}
    var r=combat_view_rect();
    with(ObjectChest)if(point_in_rectangle(x,y,r.left,r.top,r.right,r.bottom) && vfx_random(1)<.5){var a=vfx_random(360);
        fxp_add(x+lengthdir_x(vfx_random(18),a),y-4+lengthdir_y(vfx_random(6),a),vfx_random_range(-4,4),-vfx_random_range(30,70),vfx_random_range(.6,1),7,1,FXP_EMBER,FXP_EMIT,-10,.5,.2);}
    with(ObjectMagnetOrb)if(point_in_rectangle(x,y,r.left,r.top,r.right,r.bottom) && vfx_random(1)<.5){var a=vfx_random(360),rr=vfx_random_range(10,16);
        fxp_add(x+lengthdir_x(rr,a),y-12+lengthdir_y(rr,a),lengthdir_x(30,a+90),lengthdir_y(30,a+90),vfx_random_range(.25,.45),2,1,FXP_PIXEL,FXP_EMIT,0,1,.1);}
    if(variable_global_exists("equipment_drops"))for(var i=0;i<array_length(global.equipment_drops);i++){var d=global.equipment_drops[i];
        if(point_in_rectangle(d.x,d.y,r.left,r.top,r.right,r.bottom) && vfx_random(1)<.25*fxp_rate()){var el=fx_rarity_element(d.item.rarity);
            fxp_add(d.x+vfx_random_range(-5,5),d.y-10,vfx_random_range(-3,3),-vfx_random_range(40,80),vfx_random_range(.5,.9),el,1,FXP_EMBER,FXP_EMIT,-8,.5,.15);}}
}
/// Particle element of a loot rarity (common, rare, epic, legendary).
function fx_rarity_element(_r) {static e=[0,2,4,7];return e[clamp(_r,0,3)];}
/// Light pools of pickups (called from atmosphere_draw).
function fx_world_lights(_rect) {
    // not inside with(): atmosphere_source reads the controller's light_sprite (level suite 27.11.: crash when a chest existed)
    for(var i=0;i<instance_number(ObjectChest);i++){var c=instance_find(ObjectChest,i);atmosphere_source(c.x,c.y-10,120,make_color_rgb(255,206,110),.7+.15*sin(current_time/300),_rect);}
    for(var i=0;i<instance_number(ObjectMagnetOrb);i++){var o=instance_find(ObjectMagnetOrb,i);atmosphere_source(o.x,o.y-12,110,make_color_rgb(98,239,231),.65,_rect);}
}
/// Wind sway of a plant on the pixel grid: the sprite is drawn in horizontal strips shifted by whole pixels, rows above
/// the origin bend more the higher they are (base fixed), so no pixel is rotated or resampled. _sway_px is the shift at
/// the top (signed). Strips are merged per offset, so a plant costs at most |_sway_px|+1 draws. Quality 0: no sway.
function fx_sway_draw(_spr,_img,_x,_y,_xs,_ys,_sway_px,_col,_alpha) {
    var amp=round(_sway_px);
    if(amp==0 || vfx_quality()==0){draw_sprite_ext(_spr,_img,_x,_y,_xs,_ys,0,_col,_alpha);return;}
    var w=sprite_get_width(_spr),h=sprite_get_height(_spr),ox=sprite_get_xoffset(_spr),oy=sprite_get_yoffset(_spr),n=abs(amp),top=0;
    var x0=_x-ox*_xs,y0=_y-oy*_ys;
    // offset(row) = round(amp * rel^1.6), rel = 1 at the top, 0 at the origin row; the row where the offset reaches k
    for(var k=n;k>=0;k--) {
        var bottom=k==0 ? h : clamp(round(oy*(1-power((k-.5)/n,1/1.6))),top,h);
        if(bottom>top)draw_sprite_part_ext(_spr,_img,0,top,w,bottom-top,x0+sign(amp)*k,y0+top*_ys,_xs,_ys,_col,_alpha);
        top=bottom;
    }
}

// ---------------- start weapons and projectiles ----------------
/// Per-frame trail of a projectile: fire and ice balls (fxp_trail), the staff bolt of the Arkanistin (arcane sparks),
/// the arrow of the Waldlaeufer (a faint air streak only: base arrows stay physical, G16), other spell projectiles in
/// their element.
function fx_projectile_trail(_p) {
    if(!instance_exists(_p))return; // the projectile may have been destroyed earlier in its own step (end of life)
    var sid=_p.spell_id,sp=_p.projectile_speed*60;
    if(sid==SPELL.FIREBALL || sid==SPELL.ICEBALL){fxp_trail(_p.x,_p.y,_p.direction,sid==SPELL.FIREBALL ? 1 : 2,sp,1+.25*vfx_spell_band(sid));return;}
    if(sid<=0) {
        if(_p.projectile_kind=="bolt"){if(vfx_random(1)<.45*fxp_rate())fxp_add(_p.x-lengthdir_x(12,_p.direction),_p.y-lengthdir_y(12,_p.direction),lengthdir_x(sp*.06,_p.direction+180),lengthdir_y(sp*.06,_p.direction+180),.09,0,1,FXP_STREAK,FXP_EMIT,0,4,.35,.55);return;}
        fxp_trail(_p.x,_p.y,_p.direction,4,sp,.7);return;
    }
    var d=GetSpellData(sid);if(is_struct(d))fxp_trail(_p.x,_p.y,_p.direction,clamp(d.element,0,7),sp,1);
}
/// Sword swing: speed lines torn along the arc (tangent to the swing), the finisher adds a shock ring.
function fx_sword_swing(_x,_y,_dir,_half,_r,_sweep,_finisher) {
    var n=fxp_n(_finisher ? 16 : 8),turn=_sweep>=0 ? 90 : -90;
    for(var i=0;i<n;i++){var a=_dir-_half+2*_half*(i+.5)/n,rr=_r*vfx_random_range(.6,.95),sp=vfx_random_range(220,380);
        fxp_add(_x+lengthdir_x(rr,a),_y+lengthdir_y(rr,a),lengthdir_x(sp,a+turn),lengthdir_y(sp,a+turn),vfx_random_range(.06,.12),0,1,FXP_STREAK,FXP_EMIT,0,8,0,.85);}
    if(_finisher)fx_shock(_x+lengthdir_x(_r*.5,_dir),_y+lengthdir_y(_r*.5,_dir),_r*.8,1.8,.25);
}
/// Particles of the class effects (called from class_effects_step after the age update; visual only).
function fx_class_effect_particles(_f,_dt) {
    var f=_f;
    switch(f.kind) {
        case "mage_star":case "mage_star_nova":{
            var flight=clamp(f.age/.85,0,1);
            if(f.age<.85){var xx=lerp(f.sx,f.x,flight),yy=lerp(f.sy,f.y,flight)-sin(pi*flight)*180,dir=point_direction(0,0,f.x-f.sx,(f.y-f.sy)-180*pi*cos(pi*flight));
                fxp_trail(xx,yy,dir,4,420,1.2);if(vfx_random(1)<.5)fxp_add(xx+vfx_random_range(-8,8),yy+vfx_random_range(-8,8),0,vfx_random_range(10,40),vfx_random_range(.3,.5),4,1,FXP_SHARD,FXP_EMIT,60,1,.1);}
            // the ground answers before the star lands: arcane motes gather on the target spot
            if(f.age>.55 && f.age<1)fxp_gather(f.x,f.y-4,f.radius*.6,4,.7);
            if(f.age>=1 && !variable_struct_exists(f,"fx_boom")){f.fx_boom=1;fxp_impact(f.x,f.y-4,4,.5);}
            if(f.kind=="mage_star_nova" && f.age>=1.32 && variable_struct_exists(f,"fx_boom") && f.fx_boom==1){f.fx_boom=2;fxp_impact(f.x,f.y-4,4,.4);}
        }break;
        case "mage_circle":{
            if(f.age<.3)repeat(fxp_n(2)){var a=vfx_random(360),rr=f.radius*sqrt(vfx_random(1));fxp_add(f.x+lengthdir_x(rr,a),f.y+lengthdir_y(rr,a),0,-vfx_random_range(30,70),vfx_random_range(.3,.5),4,1,FXP_PIXEL,FXP_EMIT,-20,1,.2);}
            if(f.age>=.3 && !variable_struct_exists(f,"fx_boom")){f.fx_boom=1;
                repeat(fxp_n(22)){var a=vfx_random(360),sp=vfx_random_range(160,280);fxp_add(f.x+lengthdir_x(f.radius*.3,a),f.y+lengthdir_y(f.radius*.3,a),lengthdir_x(sp,a),lengthdir_y(sp,a),vfx_random_range(.12,.22),4,1,FXP_STREAK,FXP_EMIT,0,6,.05);}
                fx_shock(f.x,f.y,f.radius*1.1,2,.3);}
        }break;
        case "mage_arc":{
            if(f.age<.12)repeat(fxp_n(3)){var a=f.angle+vfx_random_range(-60,60),rr=f.radius*vfx_random_range(.45,.6),sp=vfx_random_range(160,300);fxp_add(f.x+lengthdir_x(rr,a),f.y-6+lengthdir_y(rr,a),lengthdir_x(sp,a),lengthdir_y(sp,a),vfx_random_range(.08,.15),4,1,FXP_STREAK,FXP_EMIT,0,6,.1);}
        }break;
        case "sword_wave":{
            if(!variable_struct_exists(f,"fx_boom")){f.fx_boom=1;repeat(fxp_n(10)){var a=vfx_random(360);fxp_add(f.x+lengthdir_x(f.radius*.4,a),f.y+10+lengthdir_y(f.radius*.2,a),lengthdir_x(70,a),lengthdir_y(25,a)-8,vfx_random_range(.4,.7),5,4,FXP_PUFF,FXP_LIT,-6,2,.2,.7);}}
        }break;
        case "ranger_rain":{
            if(f.age>.45 && f.age<1.2 && vfx_random(1)<.6){var a=vfx_random(360),rr=f.radius*sqrt(vfx_random(1)),xx=f.x+lengthdir_x(rr,a),yy=f.y+lengthdir_y(rr,a);
                fxp_add(xx,yy,vfx_random_range(-15,15),-vfx_random_range(5,15),vfx_random_range(.35,.55),5,3,FXP_PUFF,FXP_LIT,-4,2,.2,.7);
                repeat(fxp_n(2))fxp_add(xx,yy,vfx_random_range(-60,60),-vfx_random_range(30,80),vfx_random_range(.15,.25),0,1,FXP_PIXEL,FXP_EMIT,300,2,.2);}
        }break;
    }
}
