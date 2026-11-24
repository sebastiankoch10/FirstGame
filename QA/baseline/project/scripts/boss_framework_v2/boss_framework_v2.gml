/// Central immutable-at-spawn encounter definitions, scaling and seeded schedule selection.
function boss_v2_ability_count(_seconds) {return _seconds>=900 ? 9 : (_seconds>=600 ? 6 : 3);}
function boss_v2_random(_limit) {
    if(!variable_global_exists("boss_rng"))global.boss_rng=712403;
    global.boss_rng=(global.boss_rng*16807) mod 2147483647;
    return floor(global.boss_rng/2147483647*max(1,_limit));
}
function boss_v2_scaling(_seconds) {
    var minute=max(5,_seconds/60),tier=clamp(floor(minute/5)-1,0,5),hp=[1.35,1.9,2.5,3.4,4.5,5.8];
    var difficulty=variable_global_exists("boss_test") && global.boss_test.active ? global.boss_test.difficulty_multiplier : 1;
    return {minute:minute,tier:tier,hp:hp[tier]*global.base_monster_hp_multiplier*difficulty,damage:(1+minute*.06)*global.base_monster_damage_multiplier*difficulty,
        speed:1+tier*.07,projectiles:min(3,floor((minute-5)/10)),projectile_speed:1+tier*.08};
}
function boss_v2_catalog() {
    var dragon_keys=["beam","arc","stomp","meteor","slam","wind","void","vortex","volley"],dragon=[];
    for(var i=0;i<9;i++){var c=dragon_encounter_config(dragon_keys[i]);array_push(dragon,{id:i+1,key:dragon_keys[i],name:dragon_pattern_label(dragon_keys[i]),mechanic:dragon_keys[i],warning:c.warning,active:c.active,damage:c.damage,radius:c.radius,implemented:true});}
    var witches=[],swamp=[];for(var i=1;i<=9;i++){array_push(witches,bv2_attack_profile("twins",i));array_push(swamp,bv2_attack_profile("behemoth",i));}
    return [{id:"storm_warden",name:"Aschenfluegel",kind:"dragon",base_hp:9200,implemented:true,abilities:dragon,required_sprite:"spr_fg_dragonboss_idle"},
        {id:"twins",name:"Die Zwillingshexen",kind:"twins",base_hp:13000,implemented:true,abilities:witches,required_sprite:"spr_bv2_fire_idle"},
        {id:"behemoth",name:"Sumpfbehemoth",kind:"behemoth",base_hp:9200,implemented:true,abilities:swamp,required_sprite:"spr_bv2_behemoth_idle"}];
}
function boss_v2_definition(_id) {var defs=boss_v2_catalog();for(var i=0;i<array_length(defs);i++)if(defs[i].id==_id)return defs[i];return undefined;}
function boss_v2_available(_d) {
    if(!is_struct(_d) || !_d.implemented || array_length(_d.abilities)!=9 || !sprite_exists(asset_get_index(_d.required_sprite)))return false;
    for(var i=0;i<9;i++)if(!_d.abilities[i].implemented)return false;
    if(_d.kind=="twins" && !sprite_exists(asset_get_index("spr_bv2_ice_idle")))return false;
    if(_d.kind!="dragon"){
        var family=_d.kind=="twins" ? "twins" : "swamp";
        for(var i=0;i<9;i++)if(!sprite_exists(asset_get_index("spr_bv2_"+family+"_fx_"+string(i))) || !audio_exists(asset_get_index("sfx_fg_"+family+"_"+string(i+1))))return false;
        var actions=_d.kind=="twins" ? ["idle","fly","fast","turn","charge","cast","joint","hurt","phase","death"] : ["idle","walk","turn","roots","spit","stomp","summon","breath","wave","bloom","hurt","phase","death"];
        var families=_d.kind=="twins" ? ["fire","ice"] : ["behemoth"];
        for(var j=0;j<array_length(families);j++)for(var k=0;k<array_length(actions);k++)if(!sprite_exists(asset_get_index("spr_bv2_"+families[j]+"_"+actions[k])))return false;
    }
    return true;
}
function boss_v2_pick() {
    var defs=boss_v2_catalog(),pool=[];for(var i=0;i<array_length(defs);i++)if(boss_v2_available(defs[i]))array_push(pool,defs[i].id);
    return array_length(pool)>0 ? pool[boss_v2_random(array_length(pool))] : "";
}
function boss_v2_init(_b) {
    var d=boss_v2_definition(_b.boss_id);_b.v2_enabled=is_struct(d);_b.v2_child=noone;_b.v2_forced_ability=-1;_b.v2_dying=false;
    if(!_b.v2_enabled)return;
    _b.v2_kind=d.kind;_b.v2_spawn_seconds=global.round_seconds;_b.v2_unlocked=boss_v2_ability_count(global.round_seconds);_b.v2_scaling=boss_v2_scaling(global.round_seconds);
    _b.max_hp=d.base_hp*_b.v2_scaling.hp;_b.hp=_b.max_hp;_b.damage=0;_b.v2_clock=0;_b.v2_origin_x=_b.x;_b.v2_origin_y=_b.y;_b.v2_attack_log=[];
    if(d.kind!="dragon")bv2_encounter_init(_b);
}
function boss_v2_force_attack(_b,_ability) {
    if(!instance_exists(_b) || !_b.v2_enabled)return false;
    var defs=boss_v2_definition(_b.boss_id),idx=-1;
    for(var i=0;i<9;i++)if(defs.abilities[i].id==_ability || defs.abilities[i].key==_ability)idx=i+1;
    if(idx<1 || idx>_b.v2_unlocked)return false;
    bv2_clear_owner(_b);_b.enc_zones=[];_b.dragon_magma=[];
    if(_b.dragon_enabled)dragon_attack_begin(_b,defs.abilities[idx-1].key);else bv2_encounter_attack_begin(_b,idx);
    return true;
}
function boss_v2_attack_allowed(_b,_key) {
    if(!variable_instance_exists(_b,"v2_enabled") || !_b.v2_enabled)return true;
    var d=boss_v2_definition(_b.boss_id);for(var i=0;i<_b.v2_unlocked;i++)if(d.abilities[i].key==_key)return true;return false;
}
function boss_v2_dragon_rotation(_b) {
    var old=dragon_rotation(_b.boss_phase),out=[];for(var i=0;i<array_length(old);i++)if(boss_v2_attack_allowed(_b,old[i]))array_push(out,old[i]);
    var def=boss_v2_definition(_b.boss_id);for(var i=0;i<_b.v2_unlocked;i++)if(!array_contains(out,def.abilities[i].key))array_push(out,def.abilities[i].key);
    return out;
}
function boss_v2_note(_b,_index) {
    if(array_length(_b.v2_attack_log)>=64)array_delete(_b.v2_attack_log,0,1);
    array_push(_b.v2_attack_log,{ability:_index,phase:_b.boss_phase,time:global.round_seconds});
}
function boss_shared_target(_target) {
    if(instance_exists(_target) && variable_instance_exists(_target,"boss_twin") && _target.boss_twin && instance_exists(_target.boss_owner))return _target.boss_owner;
    return _target;
}
function boss_is_actor(_target) {return _target.object_index==ObjectBossMonster || (variable_instance_exists(_target,"boss_twin") && _target.boss_twin);}
function boss_twin_create(_b) {
    var e=instance_create_layer(_b.x+180,_b.y,"Instances",ObjectMonster);e.boss_twin=true;e.boss_owner=_b;e.master_skeleton=false;
    e.hp=_b.hp;e.max_hp=_b.max_hp;e.damage=0;e.body_radius=35;e.visual_height=135;e.contact_radius=25;e.mask_index=boss_body_mask(35,135);e.speed=0;e.image_speed=0;e.base_move_speed=0;
    _b.v2_child=e;return e;
}
function boss_twin_status(_b) {
    if(!instance_exists(_b.v2_child))return;
    var child=_b.v2_child;child.hp=_b.hp;child.max_hp=_b.max_hp;
    if(child.burn_time>0){if(_b.burn_time<=0 || child.burn_dps>=_b.burn_dps){_b.burn_dps=child.burn_dps;if(variable_instance_exists(child,"burn_spell_id"))_b.burn_spell_id=child.burn_spell_id;}_b.burn_time=max(_b.burn_time,child.burn_time);child.burn_time=0;}
    _b.slow_time=max(_b.slow_time,child.slow_time);if(child.slow_time>0)_b.slow_factor=min(_b.slow_factor,child.slow_factor);child.slow_time=0;
    _b.shock_time=max(_b.shock_time,child.shock_time);child.shock_time=0;
}
function bv2_clear_owner(_b) {
    if(!variable_global_exists("bv2_hazards"))return;
    for(var i=array_length(global.bv2_hazards)-1;i>=0;i--)if(global.bv2_hazards[i].owner==_b)array_delete(global.bv2_hazards,i,1);
}
function boss_v2_cleanup(_b) {
    bv2_clear_owner(_b);
    var keep_twin=instance_exists(_b) && variable_instance_exists(_b,"v2_dying") && _b.v2_dying;
    with(ObjectMonster)if((variable_instance_exists(id,"boss_twin") && boss_twin && boss_owner==_b && !keep_twin) || (variable_instance_exists(id,"boss_minion") && boss_minion && boss_owner==_b))instance_destroy();
}
function boss_v2_die(_b) {_b.v2_dying=true;_b.v2_state_age=0;_b.boss_state="dying";_b.damage=0;boss_reward_once(_b);}
function boss_v2_death_step(_b,_dt) {
    if(global.game_paused)return;_b.v2_state_age+=_dt;_b.v2_clock+=_dt;
    if(_b.v2_state_age>=1.5){if(instance_exists(_b.v2_child))with(_b.v2_child)instance_destroy();with(_b)instance_destroy();}
}
