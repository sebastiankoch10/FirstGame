/// hotbar_assign.gml
/// Six automatic spell slots; no keyboard casting.

function hotbar_init()
{
    if (!variable_global_exists("hotbar")) {
        global.hotbar = array_create(6, undefined);
    }

}

function hotbar_assign_for_spell(_name)
{
    hotbar_init();
    var nm = string(_name);

    // Schon irgendwo belegt?
    for (var i = 0; i < 6; i++) {
        if (!is_undefined(global.hotbar[i]) && string(global.hotbar[i]) == nm) return;
    }
    // Freien Slot suchen
    for (var j = 0; j < 6; j++) {
        if (is_undefined(global.hotbar[j])) {
            global.hotbar[j] = nm;
            return;
        }
    }
}

/// @return Spell-Struct aus global.active_spells oder undefined
function hotbar_find_active_by_name(_name)
{
    if (is_undefined(global.active_spells)) return undefined;
    var nm = string(_name);
    for (var i = 0; i < array_length(global.active_spells); i++) {
        var s = global.active_spells[i];
        if (is_struct(s) && variable_struct_exists(s, "name")) {
            if (string(s.name) == nm) return s;
        }
    }
    return undefined;
}

/// Jede Step: cooldown_timer runterzählen
function hotbar_tick_cooldowns()
{
    if (is_undefined(global.active_spells)) return;
    for (var i = 0; i < array_length(global.active_spells); i++) {
        var s = global.active_spells[i];
        if (!is_struct(s)) continue;
        if(!variable_struct_exists(s,"ready_flash")) s.ready_flash=0;
        s.ready_flash=max(0,s.ready_flash-1);
        if (variable_struct_exists(s, "cooldown_timer") && s.cooldown_timer > 0) {
            s.cooldown_timer = max(0, s.cooldown_timer - 1);
            if(s.cooldown_timer==0) s.ready_flash=12;
        }
    }
}


function auto_spell_target(_sid,_values,_pl) {
    if(_sid==SPELL.HEAL) return noone;
    var range_value=(_sid==SPELL.FROST_NOVA || _sid==SPELL.ORBIT_BLADES) ? _values.radius+20 : (_sid==SPELL.WISP ? _values.radius : (_sid==SPELL.STONE_SPIKES ? 265 : _values.range));
    var nearest=combat_nearest(_pl,range_value);
    if(_sid!=SPELL.FIREBALL || !instance_exists(nearest)) return nearest;
    // Rank at most twelve nearby candidates, then candidate_score their explosion neighborhoods.
    var candidates=[],types=[ObjectMonster,ObjectBossMonster];
    for(var t=0;t<2;t++) for(var i=0;i<instance_number(types[t]);i++) {
        var e=instance_find(types[t],i),dist=point_distance(_pl.x,_pl.y,e.x,e.y);
        if(e.hp<=0 || dist>range_value || !combat_target_visible(e)) continue;
        var insert_at=array_length(candidates);
        for(var j=0;j<array_length(candidates);j++) if(dist<candidates[j].distance) {insert_at=j; break;}
        array_insert(candidates,insert_at,{target:e,distance:dist});
        if(array_length(candidates)>12) array_delete(candidates,12,1);
    }
    var best=nearest,best_score=0;
    for(var c=0;c<array_length(candidates);c++) {
        var candidate=candidates[c].target,candidate_score=0;
        for(var t=0;t<2;t++) for(var i=0;i<instance_number(types[t]);i++) {
            var e=instance_find(types[t],i);
            if(e.hp>0 && combat_target_visible(e) && point_distance(candidate.x,candidate.y,e.x,e.y)<=_values.radius) candidate_score++;
        }
        if(candidate_score>best_score) {best_score=candidate_score; best=candidate;}
    }
    return best;
}
function auto_spells_step() {
    if(global.game_paused || global.game_over || !global.round_active || !instance_exists(ObjectPlayer)) return;
    var pl=ObjectPlayer;
    for(var i=0;i<array_length(global.active_spells);i++) {
        var s=global.active_spells[i];
        if(!is_struct(s) || s.cooldown_timer>0) continue;
        var sid=name_to_spell_id(s.name),v=spell_values(sid,s.level);
        if(!is_struct(v)) continue;
        if(sid==SPELL.HEAL) {
            var missing=pl.max_hp-pl.hp;
            if(missing<=0 || (missing<v.damage*0.5 && pl.hp/pl.max_hp>0.45)) continue;
            cast_spell(s,noone);
        } else {
            var target=auto_spell_target(sid,v,pl);
            if(instance_exists(target)) cast_spell(s,target);
        }
    }
}
