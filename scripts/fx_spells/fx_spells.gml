/// Graphics overhaul for spells and passives (Roadmap 16, Visuelles Leitbild 7.2): the same pixel particles as the
/// showcase (Feuerball, Eisball, Kettenblitz) for every other spell and for the passives that act visibly.
///   fx_spell_burst       every spell impact and field tick (spell_fx_burst): core flash, element sparks, extras
///   fx_spells_step       while a spell lives: embers over Ember Field, motes spiralling into Gravity Well, frost mist in
///                        Ice Prison, streaks behind Orbit Blades and Glaive, a trail behind Wisp and Prismatic Seed,
///                        energy gathering for Thunder Seal and Solar Verdict, falling streaks for Starfall
///   fx_spell_link        sparks along chain links (Wisp, Prismatic Seed)
///   passives             healing motes (Renewal, Vitality, Healing Pulse), a ward shimmer when armour or Orbit Shield
///                        absorbs damage, a resonance spark, faint element motes for the element oaths, a glint behind
///                        the Orbit Shield. Pure stat passives (Power Up, Quick Hands, Wide Glyphs, ...) have no picture
///                        of their own: they show in the spell they change.
/// Visual only; counts follow "Effektqualitaet" (fxp_n), intensity follows the spell band (vfx_band) like the rest of
/// the spell effects (G17: level 1 compact, the endgame impressive). Budgets per frame keep crowds and fields cheap.
function fx_spells_init() {if(!variable_global_exists("fxs") || !is_struct(global.fxs))global.fxs={bursts:0};}

function fx_spell_burst(_x,_y,_r,_el,_band) {
    fx_spells_init();if(global.fxs.bursts>=fxp_n(10))return;global.fxs.bursts++;
    var b=clamp(_band,0,2),n=fxp_n(5+5*b+min(10,_r/14));
    fxp_add(_x,_y,0,0,.06+.02*b,_el,round(3+3*b),FXP_FLASH,FXP_EMIT);
    repeat(n){var a=vfx_random(360),sp=vfx_random_range(90,220)*(.7+.25*b)*clamp(_r/60,.6,1.6);
        fxp_add(_x,_y,lengthdir_x(sp,a),lengthdir_y(sp,a),vfx_random_range(.1,.22),_el,1,FXP_STREAK,FXP_EMIT,0,6,.05);}
    switch(_el) {
        case 1:repeat(fxp_n(3+2*b))fxp_add(_x+vfx_random_range(-_r*.3,_r*.3),_y+vfx_random_range(-_r*.2,_r*.2),vfx_random_range(-15,15),-vfx_random_range(30,70),vfx_random_range(.35,.7),1,vfx_choose(1,2),FXP_EMBER,FXP_EMIT,-50,2,.1);break;
        case 2:repeat(fxp_n(3+2*b))fxp_add(_x,_y,vfx_random_range(-60,60),-vfx_random_range(20,70),vfx_random_range(.3,.55),2,vfx_choose(1,2),FXP_SHARD,FXP_EMIT,240,1.5,.1);break;
        case 3:repeat(fxp_n(3+2*b)){var a=vfx_random(360);fxp_add(_x,_y,lengthdir_x(260,a),lengthdir_y(260,a),vfx_random_range(.05,.1),3,1,FXP_STREAK,FXP_EMIT,0,3,0);}break;
        case 5:repeat(fxp_n(3+2*b))fxp_add(_x+vfx_random_range(-_r*.3,_r*.3),_y,vfx_random_range(-25,25),-vfx_random_range(10,30),vfx_random_range(.4,.7),5,vfx_choose(3,4),FXP_PUFF,FXP_LIT,-6,2,.2,.7);break;
        default:repeat(fxp_n(3+2*b)){var a=vfx_random(360),rr=vfx_random(_r*.5);fxp_add(_x+lengthdir_x(rr,a),_y+lengthdir_y(rr,a),0,-vfx_random_range(15,40),vfx_random_range(.3,.6),_el,1,FXP_PIXEL,FXP_EMIT,-15,1,.2);}break;
    }
    if(b>=2 && _r>=70 && !(variable_global_exists("active_boss") && instance_exists(global.active_boss)))fx_shock(_x,_y,_r,1.8,.25);
}
function fx_spell_link(_ax,_ay,_bx,_by,_el) {
    var d=point_distance(_ax,_ay,_bx,_by),n=fxp_n(clamp(d/30,2,8));
    for(var i=0;i<n;i++){var q=vfx_random(1),a=vfx_random(360);fxp_add(lerp(_ax,_bx,q),lerp(_ay,_by,q),lengthdir_x(60,a),lengthdir_y(60,a),vfx_random_range(.08,.16),_el,1,FXP_PIXEL,FXP_EMIT,0,4,0);}
}
/// Continuous particles of living spells (Step, paused with the game).
function fx_spells_step(_dt) {
    fx_spells_init();global.fxs.bursts=0;
    if(_dt<=0 || !variable_global_exists("spell_fields") || !instance_exists(ObjectPlayer))return;
    var budget=fxp_n(36),r=combat_view_rect();
    for(var i=0;i<array_length(global.spell_fields) && budget>0;i++) {
        var f=global.spell_fields[i],b=vfx_band(f.level),rate=(.45+.3*b)*fxp_rate();
        if(f.x<r.left-200 || f.x>r.right+200 || f.y<r.top-200 || f.y>r.bottom+200)continue;
        switch(f.kind) {
            case "field":if(vfx_random(1)<rate){repeat(2){var a=vfx_random(360),rr=f.radius*sqrt(vfx_random(1));fxp_add(f.x+lengthdir_x(rr,a),f.y+lengthdir_y(rr,a),vfx_random_range(-6,6),-vfx_random_range(25,60),vfx_random_range(.4,.8),1,vfx_choose(1,1,2),FXP_EMBER,FXP_EMIT,-40,1.5,vfx_random_range(0,.3));budget--;}}break;
            case "gravity":if(vfx_random(1)<rate){fxp_gather(f.x,f.y,f.radius*.9,4,1);budget-=2;}break;
            case "prison":if(vfx_random(1)<rate){var a=vfx_random(360);fxp_add(f.x+lengthdir_x(f.radius*.9,a),f.y+lengthdir_y(f.radius*.9,a),vfx_random_range(-8,8),-vfx_random_range(5,20),vfx_random_range(.5,.9),2,vfx_choose(3,4),FXP_PUFF,FXP_EMIT,0,1.2,.6,.45);
                fxp_add(f.x+lengthdir_x(f.radius*.8,a+90),f.y+lengthdir_y(f.radius*.8,a+90),0,-12,vfx_random_range(.3,.5),2,1,FXP_SHARD,FXP_EMIT,0,0,.1);budget-=2;}break;
            case "orbit":for(var n=0;n<f.count;n++){var a=f.age*190+n*360/f.count,bx=f.x+lengthdir_x(f.radius,a),by=f.y+lengthdir_y(f.radius,a);
                if(vfx_random(1)<rate){fxp_add(bx,by,lengthdir_x(80,a-90),lengthdir_y(80,a-90),vfx_random_range(.06,.12),0,1,FXP_STREAK,FXP_EMIT,0,6,0,.85);budget--;}}break;
            case "summon":if(vfx_random(1)<rate){fxp_add(f.x+vfx_random_range(-3,3),f.y+vfx_random_range(-3,3),vfx_random_range(-10,10),vfx_random_range(-10,10),vfx_random_range(.3,.5),6,1,FXP_PIXEL,FXP_EMIT,-10,1.5,.15);budget--;}break;
            case "glaive":if(vfx_random(1)<.8*fxp_rate()){fxp_add(f.x,f.y,vfx_random_range(-20,20),vfx_random_range(-20,20),vfx_random_range(.08,.16),0,1,FXP_STREAK,FXP_EMIT,0,5,0,.8);budget--;}break;
            case "seed":fxp_trail(f.x,f.y,point_direction(f.x,f.y,f.ex,f.ey),4,430,.8);budget-=2;break;
            case "seal":case "verdict":if(f.ticks==0){var el=f.kind=="seal" ? 3 : 7;fxp_gather(f.x,f.y,f.radius*.8,el,.4+.6*clamp(f.age/(f.kind=="seal" ? .9 : .72),0,1));budget-=2;}break;
            case "meteor":if(f.ticks<f.count && vfx_random(1)<rate){var xx=f.x+lengthdir_x(f.ticks*32,f.angle+f.ticks*137),yy=f.y+lengthdir_y(f.ticks*32,f.angle+f.ticks*137);
                fxp_add(xx-60,yy-220,240,880,.22,1,2,FXP_STREAK,FXP_EMIT,0,0,0);budget--;}break;
            case "spikes":if(f.ticks<f.count && vfx_random(1)<rate){var xx=f.sx+lengthdir_x(65+f.ticks*70,f.angle),yy=f.sy+lengthdir_y(65+f.ticks*70,f.angle);
                fxp_add(xx+vfx_random_range(-10,10),yy+4,vfx_random_range(-15,15),-vfx_random_range(10,35),vfx_random_range(.25,.45),5,1,FXP_PIXEL,FXP_EMIT,200,2,.2);budget--;}break;
            case "lance":if(f.age<.12 && vfx_random(1)<.9){var q=vfx_random(1);fxp_add(lerp(f.sx,f.ex,q),lerp(f.sy,f.ey,q),vfx_random_range(-40,40),vfx_random_range(-40,40),vfx_random_range(.1,.2),4,1,FXP_STREAK,FXP_EMIT,0,5,0);budget--;}break;
        }
    }
    fx_passives_step(_dt);
}
/// Passives that act visibly (called from fx_spells_step).
function fx_passives_step(_dt) {
    var pl=ObjectPlayer;if(!instance_exists(pl))return;
    // element oaths: a faint mote of their element now and then at the feet
    var oaths=[[variable_instance_exists(pl,"fire_bonus") ? pl.fire_bonus : 0,1],[variable_instance_exists(pl,"storm_bonus") ? pl.storm_bonus : 0,3],[variable_instance_exists(pl,"cold_bonus") ? pl.cold_bonus : 0,2]];
    for(var i=0;i<3;i++)if(oaths[i][0]>0 && vfx_random(1)<.12*fxp_rate()){var a=vfx_random(360);fxp_add(pl.x+lengthdir_x(10,a),pl.y-2+lengthdir_y(4,a),vfx_random_range(-4,4),-vfx_random_range(15,35),vfx_random_range(.4,.7),oaths[i][1],1,oaths[i][1]==1 ? FXP_EMBER : FXP_PIXEL,FXP_EMIT,-10,1,.2,.8);}
    // Orbit Shield: a glint follows the orbiting shield (position from the shield logic in scripts/spell)
    if(variable_instance_exists(pl,"damage_reduction") && pl.damage_reduction>0 && variable_instance_exists(pl,"orbit_angle") && vfx_random(1)<.5*fxp_rate()) {
        var d=GetSpellData(SPELL.SHIELD),ox=pl.x+lengthdir_x(d.shield_radius,pl.orbit_angle),oy=pl.y+lengthdir_y(d.shield_radius,pl.orbit_angle);
        fxp_add(ox,oy,lengthdir_x(40,pl.orbit_angle-90),lengthdir_y(40,pl.orbit_angle-90),vfx_random_range(.08,.14),0,1,FXP_STREAK,FXP_EMIT,0,6,0,.8);
    }
}
/// Healing (Renewal tick, Vitality gain, Healing Pulse): green motes rise from the figure.
function fx_heal_motes(_pl,_amount) {
    if(!instance_exists(_pl) || _amount<=0)return;
    repeat(fxp_n(clamp(2+_amount*.5,3,10))){var a=vfx_random(360);fxp_add(_pl.x+lengthdir_x(vfx_random(12),a),_pl.y-6+lengthdir_y(vfx_random(6),a),vfx_random_range(-6,6),-vfx_random_range(25,55),vfx_random_range(.5,.9),6,vfx_choose(1,1,2),FXP_PIXEL,FXP_EMIT,-15,1,.1);}
}
/// Armour or Orbit Shield absorbed part of a hit: a short steel shimmer ring around the figure.
function fx_ward_flash(_pl) {
    if(!instance_exists(_pl))return;
    var n=fxp_n(8);for(var i=0;i<n;i++){var a=i*360/n+vfx_random(20);fxp_add(_pl.x+lengthdir_x(14,a),_pl.y-14+lengthdir_y(16,a),lengthdir_x(70,a),lengthdir_y(70,a),.12,0,1,FXP_STREAK,FXP_EMIT,0,8,0,.85);}
}
/// Resonant Core triggered on a target with a status: a small violet spark.
function fx_resonance_spark(_target) {
    if(!instance_exists(_target) || vfx_random(1)>.5)return;
    fxp_add(_target.x,_target.y-fx_body_mid(_target),0,0,.06,4,3,FXP_FLASH,FXP_EMIT);
    repeat(fxp_n(3)){var a=vfx_random(360);fxp_add(_target.x,_target.y-fx_body_mid(_target),lengthdir_x(120,a),lengthdir_y(120,a),.1,4,1,FXP_STREAK,FXP_EMIT,0,6,0);}
}
