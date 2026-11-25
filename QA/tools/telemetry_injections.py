"""Exact, fail-closed source instrumentation, applied only to an isolated project copy.

The production calls and their RNG stay in place. HP observations and immutable attack
snapshots are added at the actual hit/spawn sites; no production file is changed.
"""
from pathlib import Path


def _replace(code, old, new, *, count=1):
    found = code.count(old)
    if found != count:
        raise RuntimeError(f"Telemetry anchor changed ({found} matches, expected {count}): {old[:100]!r}")
    return code.replace(old, new)


def apply_injections(code, path):
    p = str(path).replace("\\", "/")
    if p.endswith("scripts/gameplay/gameplay.gml"):
        code = _replace(code, 'function player_receive_damage(', 'function qa_original_player_receive_damage(')
        code = _replace(code, 'player_receive_damage(_pl,_enemy.damage)', 'qa_receive_from(_pl,_enemy.damage,"ground",qa_source_snapshot(_enemy,"contact"))')
        code = _replace(code, 'function enemy_pursue() {', 'function enemy_pursue() {\n    if(variable_global_exists("qa_bench_freeze") && global.qa_bench_freeze){speed=0;hit_stun=max(0,hit_stun-1/60);stun_lockout=max(0,stun_lockout-1/60);if(slow_time>0)slow_time--;if(shock_time>0)shock_time--;return;}')
    elif p.endswith("scripts/spell/spell.gml"):
        code = _replace(code, '    run_stats_damage(_sid,hp_before-_target.hp);', '    qa_damage_out(_target,actual_damage,_source,_sid,hp_before,_target.hp,critical);\n    run_stats_damage(_sid,hp_before-_target.hp);')
        code = _replace(code, '    array_push(_projectile.hit_targets,_target.id);', '    qa_projectile_impact(_projectile);\n    array_push(_projectile.hit_targets,_target.id);')
        code = _replace(code, 'ds_list_destroy(hits);instance_destroy();return;', 'ds_list_destroy(hits);qa_projectile_expire(id);instance_destroy();return;')
        code = _replace(code, 'if(lifetime<=0)instance_destroy();depth=-y;', 'if(lifetime<=0){qa_projectile_expire(id);instance_destroy();}depth=-y;')
    elif p.endswith("scripts/cast_spell/cast_spell.gml"):
        code = _replace(code, 'p.slow_time=round(d.slow_time*pl.status_factor*spell_cold_duration_factor());}', 'p.slow_time=round(d.slow_time*pl.status_factor*spell_cold_duration_factor());}\n            qa_projectile_spawn(p,sid);')
    elif p.endswith("scripts/run_spell_stats/run_spell_stats.gml"):
        code = _replace(code, 'function run_stats_cast(_sid) {run_stats_get(_sid).casts++;}', 'function run_stats_cast(_sid) {run_stats_get(_sid).casts++;qa_cast(_sid);}')
        code = _replace(code, 'function run_stats_heal(_sid,_amount) {if(_amount>0)run_stats_get(_sid).healing+=_amount;}', 'function run_stats_heal(_sid,_amount) {if(_amount>0){run_stats_get(_sid).healing+=_amount;qa_heal(_sid,_amount);}}')
    elif p.endswith("scripts/class_weapons/class_weapons.gml"):
        code = _replace(code, 'kind:_kind,x:_x,y:_y,sx:_sx', 'kind:_kind,qa_weapon_stage:ObjectPlayer.class_combo_index,x:_x,y:_y,sx:_sx')
        code = _replace(code, 'function class_weapon_area(_x,_y,_radius,_damage)', 'function class_weapon_area(_x,_y,_radius,_damage,_stage=0)')
        code = _replace(code, 'apply_attack_damage(targets[i],_damage,ObjectPlayer,0);', 'qa_apply_weapon_damage(targets[i],_damage,ObjectPlayer,_stage);')
        code = _replace(code, 'shot.class_tier=weapon_visual_tier();return shot;', 'shot.class_tier=weapon_visual_tier();qa_projectile_spawn(shot,0,_pl.class_combo_index);return shot;')
        code = _replace(code, 'function class_weapon_release(_pl,_step) {', 'function class_weapon_release(_pl,_step) {\n    qa_cast(0,_step);')
        code = _replace(code, 'apply_attack_damage(targets[j],f.damage,ObjectPlayer,0);', 'qa_apply_weapon_damage(targets[j],f.damage,ObjectPlayer,f.qa_weapon_stage);')
        code = _replace(code, 'class_weapon_area(f.x,f.y,f.radius,f.damage)', 'class_weapon_area(f.x,f.y,f.radius,f.damage,f.qa_weapon_stage)', count=2)
        code = _replace(code, 'class_weapon_area(f.x,f.y,f.radius,f.damage*.55)', 'class_weapon_area(f.x,f.y,f.radius,f.damage*.55,f.qa_weapon_stage)')
    elif p.endswith("scripts/master_combat/master_combat.gml"):
        code = _replace(code, 'global.sword_combo_metrics.swings++;', 'qa_cast(0,stage);global.sword_combo_metrics.swings++;')
    elif p.endswith("objects/ObjectSwordHitbox/Step_0.gml"):
        code = _replace(code, 'apply_attack_damage(e,damage,owner);', 'qa_apply_weapon_damage(e,damage,owner,combo_stage);')
    elif p.endswith("objects/ObjectMonster/Step_0.gml"):
        code = _replace(code, 'var burn_actual=min(max(0,hp),burn_dps / room_speed);hp-=burn_actual;', 'var burn_before=hp,burn_actual=min(max(0,hp),burn_dps / room_speed);hp-=burn_actual;qa_damage_out(id,burn_dps/room_speed,ObjectPlayer,variable_instance_exists(id,"burn_spell_id") ? burn_spell_id : 0,burn_before,hp,false,true);')
    elif p.endswith("scripts/boss_framework_v2/boss_framework_v2.gml"):
        code = _replace(code, 'function boss_v2_note(_b,_index) {', 'function boss_v2_note(_b,_index) {\n    qa_boss_note(_b,_index);')
    elif p.endswith("scripts/boss_hazards_v2/boss_hazards_v2.gml"):
        code = _replace(code, 'var h={owner:_b,kind:_kind,g:_g,', 'var h={owner:_b,qa_source:qa_source_snapshot(_b,_kind),kind:_kind,g:_g,')
        code = _replace(code, 'var b={owner:_b,x:_x,y:_y,', 'var b={owner:_b,qa_source:qa_source_snapshot(_b,_kind),x:_x,y:_y,')
        code = _replace(code, 'h.age=max(0,h.owner.v2_clock-h.birth_clock);h.g.elapsed=h.age;', 'h.age=max(0,h.owner.v2_clock-h.birth_clock);h.g.elapsed=h.age;\n        qa_source_seen(h.qa_source,h.warning,instance_exists(ObjectPlayer) && bv2_hazard_hit(h,ObjectPlayer),h.age>=h.warning && h.age<h.warning+h.active);')
        code = _replace(code, 'player_receive_damage(ObjectPlayer,h.damage,h.height)', 'qa_receive_from(ObjectPlayer,h.damage,h.height,h.qa_source)')
        code = _replace(code, 'if(_h.poison>0){', 'if(_h.poison>0){_pl.qa_poison_source=variable_clone(_h.qa_source);_pl.qa_poison_source.delivery="poison";')
        code = _replace(code, 'player_receive_damage(_pl,_pl.boss_poison_dps*.5,"all")', 'qa_receive_from(_pl,_pl.boss_poison_dps*.5,"all",variable_instance_exists(_pl,"qa_poison_source") ? _pl.qa_poison_source : {boss:"",ability:"poison",uid:0,kind:"unattributed"})')
        code = _replace(code, 'e.boss_minion=true;e.boss_owner=_b;', 'e.boss_minion=true;e.boss_owner=_b;e.qa_source=qa_source_snapshot(_b,"brood");')
    elif p.endswith("scripts/dragon_encounter/dragon_encounter.gml"):
        code = _replace(code, 'owner:_b,x:g.x+', 'owner:_b,qa_source:qa_source_snapshot(_b,_b.boss_cast),x:g.x+')
        code = _replace(code, 'player_receive_damage(pl,c.damage,c.height)', 'qa_receive_from(pl,c.damage,c.height,qa_source_snapshot(_b,_b.boss_cast))', count=2)
        code = _replace(code, '\n    _b.enc_cfg=c;_b.enc_hits=0;', '\n    qa_source_seen(qa_source_snapshot(_b,_kind),c.warning);_b.enc_cfg=c;_b.enc_hits=0;')
        # Dragon melee (bite / tail sweep) announces its sector the same way.
        code = _replace(code, '_b.dragon_pose_locked=false;_b.enc_cfg=c;_b.enc_hits=0;', '_b.dragon_pose_locked=false;qa_source_seen(qa_source_snapshot(_b,kind),c.warning);_b.enc_cfg=c;_b.enc_hits=0;')
        code = _replace(code, '_b.enc_geometry.elapsed=_b.dragon_state_age;', '_b.enc_geometry.elapsed=_b.dragon_state_age;qa_source_seen(qa_source_snapshot(_b,_b.boss_cast),_b.enc_cfg.warning,!array_contains(["meteor","stomp","void","volley","wind"],_b.boss_cast) && telegraph_contains(_b.enc_geometry,ObjectPlayer.x,ObjectPlayer.y-10),false);')
        code = _replace(code, 'z.g.elapsed=z.age;', 'z.g.elapsed=z.age;qa_source_seen(qa_source_snapshot(_b,_b.boss_cast),z.warning,telegraph_contains(z.g,pl.x,pl.y-10),z.erupted);')
        code = _replace(code, 'var age=_b.dragon_state_age,hit=false;', 'var age=_b.dragon_state_age,hit=false;qa_source_seen(qa_source_snapshot(_b,kind),c.warning,false,true);')
        code = _replace(code, 'if(hit && age>=_b.dragon_next_hit)', 'qa_source_seen(qa_source_snapshot(_b,kind),c.warning,hit,true);if(hit && age>=_b.dragon_next_hit)')
    elif p.endswith("scripts/boss_combat/boss_combat.gml"):
        code = _replace(code, 'owner:_boss,kind:_kind,x:', 'owner:_boss,qa_source:qa_source_snapshot(_boss,_kind),kind:_kind,x:')
        code = _replace(code, 'owner:_boss,x:_boss.x,y:_boss.y-20,', 'owner:_boss,qa_source:qa_source_snapshot(_boss,"projectile"),x:_boss.x,y:_boss.y-20,')
        code = _replace(code, '_b.boss_cast=_pattern; _b.boss_state="windup";', '_b.boss_cast=_pattern; _b.boss_state="windup";qa_boss_note(_b,_pattern);')
        code = _replace(code, 'var burn_actual=min(max(0,_b.hp),_b.burn_dps*_dt);_b.hp-=burn_actual;', 'var burn_before=_b.hp,burn_actual=min(max(0,_b.hp),_b.burn_dps*_dt);_b.hp-=burn_actual;qa_damage_out(_b,_b.burn_dps*_dt,ObjectPlayer,variable_instance_exists(_b,"burn_spell_id") ? _b.burn_spell_id : 0,burn_before,_b.hp,false,true);')
        code = _replace(code, 'var b=global.hostile_bullets[i];\n        if(!instance_exists(b.owner))', 'var b=global.hostile_bullets[i];qa_source_seen(qa_struct_source(b),-1,false,true);\n        if(!instance_exists(b.owner))')
        code = _replace(code, 'player_receive_damage(pl,b.damage,"high")', 'qa_receive_from(pl,b.damage,"high",qa_struct_source(b))')
        code = _replace(code, 'splash.poison=b.poison;', 'splash.poison=b.poison;splash.qa_source=variable_clone(b.qa_source);')
        code = _replace(code, 'var old_age=z.age; z.age+=_dt;', 'var old_age=z.age; z.age+=_dt;qa_source_seen(qa_struct_source(z),z.warning,instance_exists(pl) && point_distance(pl.x,pl.y-10,z.x,z.y)<=z.radius,z.age>=z.warning);')
        code = _replace(code, 'player_receive_damage(pl,z.damage,z.kind=="lightning" ? "all" : "ground")', 'qa_receive_from(pl,z.damage,z.kind=="lightning" ? "all" : "ground",qa_struct_source(z))')
        code = _replace(code, 'if(_b.mini_auto_timer<=0 && instance_exists(ObjectPlayer)){boss_fan_pattern', 'if(_b.mini_auto_timer<=0 && instance_exists(ObjectPlayer)){var qa_old_attack=variable_instance_exists(_b,"qa_attack") ? _b.qa_attack : undefined;qa_boss_note(_b,"automatic_projectile",0);boss_fan_pattern')
        code = _replace(code, 'fg_sfx("magic_projectile");_b.mini_auto_timer=1.6;', 'fg_sfx("magic_projectile");if(!is_undefined(qa_old_attack))_b.qa_attack=qa_old_attack;_b.mini_auto_timer=1.6;')
        code = _replace(code, '    if(_b.dragon_enabled) {dragon_step(_b,_dt);return;}', '    if(variable_global_exists("qa_bench_freeze") && global.qa_bench_freeze)return;\n    if(_b.dragon_enabled) {dragon_step(_b,_dt);return;}')
    return code
