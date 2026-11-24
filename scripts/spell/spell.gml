/// spell.gml
// IDs & Helper zentral

enum SPELL_TYPE {
    ACTIVE = 1,
    PASSIVE = 2
}

enum SPELL {
    // Aktive
    FIREBALL   = 101,
    ICEBALL    = 102,
    LIGHTNING  = 103,

    FROST_NOVA=104, ARC_BARRAGE=105, HEAL=106,
    EMBER_FIELD=107,LANCE=108,ORBIT_BLADES=109,STONE_SPIKES=110,WISP=111,THUNDER_SEAL=112,
    STARFALL=113,GRAVITY=114,ICE_PRISON=115,GLAIVE=116,PRISM=117,VERDICT=118,

    // Passive
    SHIELD     = 201,
    POWER_UP   = 202,
    MOVE_SPEED = 203,
    HASTE=204, VITALITY=205, MULTISHOT=206,
    CRIT=207,PROJECTILE_SPEED=208,AREA=209,COOLDOWN=210,EMBER=211,CONDUCTOR=212,WINTER=213,
    ARMOR=214,REGEN=215,PICKUP=216,LINGER=217,RESONANCE=218
}

/// @func name_to_spell_id(name)
/// @desc Mappt UI-Namen auf SPELL-ID
function name_to_spell_id(_name) {
 var nm=string(_name);if(nm=="IceBall")nm="Iceball";
 var data=spell_catalog();for(var i=0;i<array_length(data);i++)if(data[i].name==nm)return data[i].id;
 return undefined;
}

function apply_attack_damage(_target, _amount, _source, _sid=0) {
    if (!instance_exists(_target) || _amount <= 0) return false;
    if (!variable_instance_exists(_target, "hp") || _target.hp<=0) return false;

    var pl=instance_exists(ObjectPlayer) ? ObjectPlayer : noone;
    var factor=1,critical=false;
    if(instance_exists(pl)) {
        var d=GetSpellData(_sid),element=is_struct(d) ? d.element : 0;
        if(element==1)factor+=pl.fire_bonus;if(element==2)factor+=pl.cold_bonus;if(element==3)factor+=pl.storm_bonus;
        if(_target.burn_time>0 || _target.slow_time>0 || _target.shock_time>0){factor*=1+pl.resonance;if(pl.resonance>0)run_stats_cast(SPELL.RESONANCE);}
        critical=pl.crit_chance>0 && random(1)<pl.crit_chance;if(critical){factor*=pl.crit_damage;run_stats_get(SPELL.CRIT).hits++;run_stats_cast(SPELL.CRIT);}
    }
    var actual_damage = round(max(1, _amount*factor));
    var shared=boss_shared_target(_target),hp_before=shared.hp;
    shared.hp=max(0,shared.hp-actual_damage);_target.hp=shared.hp;
    run_stats_damage(_sid,hp_before-_target.hp);
    global.last_damage_event = {
        target: object_get_name(_target.object_index),
        hp_before: hp_before,
        hp_after: _target.hp,
        damage: actual_damage,source_kind:damage_source_kind(_sid)
    };

    if (variable_instance_exists(_target, "monster_hurt_timer")) {
        _target.monster_hurt_timer = max(_target.monster_hurt_timer, ceil(room_speed * 0.25));
    }
    _target.hurt_flash_timer = 6;
    _target.damage_number = actual_damage;
    _target.damage_number_timer = 30;
    _target.damage_number_y = -20;

    hit_reaction(_target,_source,_sid);
    damage_number_add(_target,hp_before-_target.hp,_sid);
    return true;
}

// Shared computed values: execution, preview and catalog use these formulas.
function spell_values(_sid,_level){return spell_v2_values(_sid,_level);}

function learn_spell(_sid) {
    var d = GetSpellData(_sid);
    if (!is_struct(d)) return false;
    var active = d.type == SPELL_TYPE.ACTIVE;
    var entries = active ? global.active_spells : global.passive_spells;
    for (var i=0; i<array_length(entries); i++) {
        if (name_to_spell_id(entries[i].name) == _sid) {
            if (entries[i].level >= d.max_level) return false;
            entries[i].level += 1;
            fg_sfx("spell_upgrade");
            return true;
        }
    }
    if (array_length(entries) >= 6) return false;
    array_push(entries, {id:_sid, name:d.name, type:active ? "active" : "passive", level:1,
        cooldown:active ? d.cooldown : 0, cooldown_timer:0});
    fg_sfx("spell_select");
    if (active) {global.active_spells=entries; hotbar_assign_for_spell(d.name);}
    else global.passive_spells=entries;
    return true;
}

function spell_projectile_hit(_projectile,_target) {
    if(!instance_exists(_target) || _target.hp<=0 || array_contains(_projectile.hit_targets,_target.id))return false;
    var sid=_projectile.spell_id,piercing=sid==0 && _projectile.projectile_kind=="bolt";
    if(_projectile.hit_done && !piercing)return false;
    array_push(_projectile.hit_targets,_target.id);
    if(!piercing)_projectile.hit_done=true;
    var kind=sid==SPELL.FIREBALL ? "fire" : (sid==SPELL.ICEBALL ? "ice" : _projectile.projectile_kind);
    var impact_x=variable_instance_exists(_projectile,"hit_x") ? _projectile.hit_x : _projectile.x,impact_y=variable_instance_exists(_projectile,"hit_y") ? _projectile.hit_y : _projectile.y;
    impact_add(impact_x,impact_y,kind,_projectile.direction);
    fg_sfx(kind=="bolt" ? "arrow_hit" : (kind=="fire" ? "explosion" : (kind=="ice" ? "ice_hit" : (kind=="arcane" ? "arcane_hit" : "magic_hit"))));
    if(sid==SPELL.FIREBALL) {
        var d=GetSpellData(sid);
        combat_area_hit(impact_x,impact_y,_projectile.explosion_radius,_projectile.damage,_projectile.owner,_projectile.burn_time,_projectile.burn_dps,0,1,sid);
        effect_add(impact_x,impact_y,_projectile.explosion_radius,make_color_rgb(255,132,45),18);
        spell_fx_burst(impact_x,impact_y,_projectile.explosion_radius*1.12,1);
    } else {
        apply_attack_damage(_target,_projectile.damage,_projectile,sid);
        if(sid==SPELL.ICEBALL) {_target.slow_factor=min(_target.slow_time>0 ? _target.slow_factor : 1,_projectile.slow_factor);_target.slow_time=max(_target.slow_time,_projectile.slow_time);}
        if(sid>0)spell_fx_burst(impact_x,impact_y,sid==102 ? 52 : 48,sid==102 ? 2 : 4);
    }
    if(!piercing)with(_projectile)instance_destroy();return true;
}
function spell_projectile_step() {
    if(global.game_paused)return;
    var steps=max(1,ceil(projectile_speed/2)),piercing=spell_id==0 && projectile_kind=="bolt";
    var hits=ds_list_create();
    repeat(steps) {
        x+=lengthdir_x(projectile_speed/steps,direction);y+=lengthdir_y(projectile_speed/steps,direction);
        var nose=piercing ? 10 : visual_width*0.25,probe_x=x+lengthdir_x(nose,direction),probe_y=y+lengthdir_y(nose,direction);
        ds_list_clear(hits);collision_circle_list(probe_x,probe_y,damage_radius,ObjectMonster,true,true,hits,false);collision_circle_list(probe_x,probe_y,damage_radius,ObjectBossMonster,true,true,hits,false);
        for(var i=0;i<ds_list_size(hits);i++) {
            var target=hits[| i];
            if(target.hp<=0 || array_contains(hit_targets,target.id))continue;
            hit_x=probe_x;hit_y=probe_y;spell_projectile_hit(id,target);
            if(!piercing){ds_list_destroy(hits);return;}
        }
        if(x<0 || y<0 || x>room_width || y>room_height){ds_list_destroy(hits);instance_destroy();return;}
    }
    ds_list_destroy(hits);lifetime--;if(lifetime<=0)instance_destroy();depth=-y;
}

function spell_ui_layout() {
    var w=display_get_gui_width(), h=display_get_gui_height();
    var compact=w<640;
    var cw=compact ? w-32 : min(360, w*0.38);
    return {x:16, y:96, w:cw, row:72, gap:12, compact:compact,
        tx:compact ? 16 : cw+32, ty:compact ? 360 : 96,
        tw:compact ? w-32 : w-cw-48, bottom:h-24};
}
function spell_ui_icon(_sid,_x,_y,_size) {
    var d=GetSpellData(_sid);
    if (!is_struct(d)) return;
    var spr=asset_get_index(d.icon_sprite_name);
    if (sprite_exists(spr)) draw_sprite_stretched(spr,0,_x,_y,_size,_size);
}
function spell_ui_panel(_x,_y,_w,_h,_selected) {
    draw_set_alpha(1);
    draw_set_color(make_color_rgb(16,24,34));
    draw_rectangle(_x,_y,_x+_w,_y+_h,false);
    draw_set_color(_selected ? make_color_rgb(239,197,112) : make_color_rgb(89,111,134));
    draw_rectangle(_x,_y,_x+_w,_y+_h,true);
    draw_set_color(make_color_rgb(41,53,67));
    draw_rectangle(_x+3,_y+3,_x+_w-3,_y+_h-3,true);
    draw_set_color(c_white);
}
function spell_stats_text(_sid,_level){return spell_values_text(_sid,_level);}
function spell_tooltip(_sid,_level,_x,_y,_width,_bottom,_offer){spell_detail_draw(_sid,_level,_x,_y,_width,_bottom,_offer);}

function spell_orbit_step(_pl) {
    if (!instance_exists(_pl)) return;
    if (!variable_instance_exists(_pl,"orbit_frame")) {_pl.orbit_frame=0; _pl.orbit_angle=0;}
    _pl.orbit_frame++;
    if (_pl.damage_reduction<=0) return;
    var d=GetSpellData(SPELL.SHIELD);
    _pl.orbit_angle=(_pl.orbit_angle+d.shield_speed) mod 360;
    var ox=_pl.x+lengthdir_x(d.shield_radius,_pl.orbit_angle);
    var oy=_pl.y+lengthdir_y(d.shield_radius,_pl.orbit_angle);
    var hits=ds_list_create();
    collision_circle_list(ox,oy,10,ObjectMonster,false,true,hits,false);
    collision_circle_list(ox,oy,10,ObjectBossMonster,false,true,hits,false);
    for(var i=0;i<ds_list_size(hits);i++) {
        var target=hits[| i];
        if (!variable_instance_exists(target,"orbit_last_hit")) target.orbit_last_hit=-d.shield_hit_interval;
        if (_pl.orbit_frame-target.orbit_last_hit>=d.shield_hit_interval) {
            if(apply_attack_damage(target,spell_values(SPELL.SHIELD,spell_level(SPELL.SHIELD)).orbit_damage,_pl,SPELL.SHIELD))run_stats_cast(SPELL.SHIELD);
            target.orbit_last_hit=_pl.orbit_frame;
        }
    }
    ds_list_destroy(hits);
}
