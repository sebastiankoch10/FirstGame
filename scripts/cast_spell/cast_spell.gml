function cast_spell(_spell,_target=undefined) {
    if(global.game_paused || global.game_over || !global.round_active) return false;
    if(!is_struct(_spell)) return false;
    if(variable_struct_exists(_spell,"cooldown_timer") && _spell.cooldown_timer>0) return false;
    var sid=variable_struct_exists(_spell,"id") ? _spell.id : name_to_spell_id(_spell.name);
    var d=GetSpellData(sid);
    if(!is_struct(d) || d.type!=SPELL_TYPE.ACTIVE || !instance_exists(ObjectPlayer)) return false;
    var pl=ObjectPlayer;
    var v=spell_values(sid,_spell.level);
    if(is_undefined(_target)) _target=auto_spell_target(sid,v,pl);
    if(sid==SPELL.HEAL && pl.hp>=pl.max_hp) return false;
    if(sid!=SPELL.HEAL && !instance_exists(_target)) return false;
    if(sid>=107)return spell_v2_cast(_spell,_target,v);
    if(sid==SPELL.HEAL) {
        var before_heal=pl.hp;pl.hp=min(pl.max_hp,pl.hp+v.damage);
        run_stats_heal(sid,pl.hp-before_heal);
        effect_add(pl.x,pl.y-10,62,make_color_rgb(111,239,151),24);
        spell_fx_burst(pl.x,pl.y-10,76,6);
    } else if(sid==SPELL.LIGHTNING) {
        cast_chain_lightning(_target,v.damage,v.chain_targets,v.chain_range,pl);
    } else if(sid==SPELL.FROST_NOVA) {
        combat_area_hit(pl.x,pl.y-10,v.radius,v.damage,pl,0,0,round(d.slow_time*pl.status_factor*spell_cold_duration_factor()),d.slow_factor,sid);
        effect_add(pl.x,pl.y-10,v.radius,make_color_rgb(138,218,255),22);
        spell_fx_burst(pl.x,pl.y-10,v.radius,2);
    } else {
        var aim=point_direction(pl.x,pl.y-10,_target.x,_target.y-10);
        for(var i=0;i<v.count;i++) {
            var dir=aim+(i-(v.count-1)*0.5)*9;
            var obj=sid==SPELL.FIREBALL ? ObjectFireball : (sid==SPELL.ICEBALL ? ObjectIceball : ObjectLightningball);
            var p=instance_create_layer(pl.x+lengthdir_x(18,dir),pl.y-10+lengthdir_y(18,dir),"Instances",obj);
            p.owner=pl; p.direction=dir; p.image_angle=dir; p.damage=v.damage; p.spell_id=sid;
            p.projectile_speed=d.projectile_speed*pl.projectile_factor; p.lifetime=ceil(v.range/p.projectile_speed);
            p.explosion_radius=v.radius;
            p.projectile_kind=sid==SPELL.ARC_BARRAGE ? "arcane" : "lightning";
            if(sid==SPELL.FIREBALL) {p.burn_time=round(d.ignite_time*pl.status_factor); p.burn_dps=d.ignite_dps*(1+pl.fire_bonus);}
            if(sid==SPELL.ICEBALL) {p.slow_on_hit=true; p.slow_factor=d.slow_factor; p.slow_time=round(d.slow_time*pl.status_factor*spell_cold_duration_factor());}
        }
    }
    var cue=sid==SPELL.HEAL ? "heal_cast" : (sid==SPELL.FROST_NOVA ? "nova_cast" : (sid==SPELL.LIGHTNING ? "lightning" : (sid==SPELL.FIREBALL ? "fireball" : (sid==SPELL.ICEBALL ? "ice" : "magic_projectile"))));
    fg_sfx(d.cue);
    run_stats_cast(sid);
    var extra=max(0,v.count-(sid==SPELL.ARC_BARRAGE ? 3 : 1));
    if(extra>0){run_stats_get(SPELL.MULTISHOT).extra_projectiles+=extra;run_stats_cast(SPELL.MULTISHOT);}
    _spell.cooldown=v.cooldown;
    _spell.cooldown_timer=v.cooldown;
    return true;
}
