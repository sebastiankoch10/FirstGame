/// Test-copy-only instrumentation. Never registered in the production project.
/// All damage is measured from actual HP deltas; modifiers keep the attack's source ID.
function qa_metrics_reset(_class,_seed,_persona) {
    global.qa_metrics={class_name:_class,seed:_seed,persona:_persona,seconds:0,damage_out:0,damage_in:0,
        attempted_out:0,overkill:0,hits_out:0,hits_in:0,healing:0,critical_hits:0,kills:0,
        sources:{},incoming:{},boss_activations:[],last_damage:undefined,last_fatal:undefined,
        events:[],telemetry_version:1};
    global.qa_attack_serial=0;global.qa_out_stage=0;
}
function qa_metrics_enabled() {return variable_global_exists("qa_metrics") && is_struct(global.qa_metrics);}
function qa_metrics_tick(_dt) {if(qa_metrics_enabled())global.qa_metrics.seconds+=_dt;}
function qa_stat(_sid,_stage=0) {
    var key=_sid==0 ? "weapon_"+string(_stage) : "s"+string(_sid),source_stats=global.qa_metrics.sources;
    if(!variable_struct_exists(source_stats,key))variable_struct_set(source_stats,key,{sid:_sid,stage:_stage,damage:0,attempted:0,overkill:0,
        normal_damage:0,boss_damage:0,dot_damage:0,hits:0,critical_hits:0,kills:0,casts:0,
        projectiles:0,projectiles_hit:0,projectiles_expired_without_hit:0,healing:0});
    return variable_struct_get(source_stats,key);
}
function qa_event(_kind,_data) {
    if(!qa_metrics_enabled())return;
    var events=global.qa_metrics.events;
    if(array_length(events)>=24)array_delete(events,0,1);
    array_push(events,{time:global.qa_metrics.seconds,kind:_kind,data:_data});global.qa_metrics.events=events;
}
function qa_damage_out(_target,_amount,_source,_sid,_before,_after,_critical=false,_dot=false,_stage=-1) {
    if(!qa_metrics_enabled() || _before<=0)return;
    if(_stage<0)_stage=global.qa_out_stage;
    if(_sid==0 && instance_exists(_source) && variable_instance_exists(_source,"qa_weapon_stage"))_stage=_source.qa_weapon_stage;
    var actual=max(0,_before-_after),s=qa_stat(_sid,_stage),m=global.qa_metrics;
    m.damage_out+=actual;m.attempted_out+=_amount;m.overkill+=max(0,_amount-actual);m.hits_out++;
    s.damage+=actual;s.attempted+=_amount;s.overkill+=max(0,_amount-actual);s.hits++;
    if(boss_is_actor(_target))s.boss_damage+=actual;else s.normal_damage+=actual;
    if(_dot)s.dot_damage+=actual;
    if(_critical){s.critical_hits++;m.critical_hits++;}
    if(_before>0 && _after<=0){s.kills++;m.kills++;}
}
function qa_apply_weapon_damage(_target,_amount,_source,_stage) {
    var previous=variable_global_exists("qa_out_stage") ? global.qa_out_stage : 0;global.qa_out_stage=_stage;
    var result=apply_attack_damage(_target,_amount,_source,0);global.qa_out_stage=previous;return result;
}
function qa_cast(_sid,_stage=0) {if(qa_metrics_enabled())qa_stat(_sid,_stage).casts++;}
function qa_heal(_sid,_amount) {if(qa_metrics_enabled() && _amount>0){qa_stat(_sid).healing+=_amount;global.qa_metrics.healing+=_amount;}}
function qa_projectile_spawn(_p,_sid,_stage=0) {
    _p.qa_weapon_stage=_stage;_p.qa_counted_hit=false;_p.qa_registered=true;
    if(qa_metrics_enabled())qa_stat(_sid,_stage).projectiles++;
}
function qa_projectile_impact(_p) {
    if(!variable_instance_exists(_p,"qa_registered") || !qa_metrics_enabled())return;
    if(!_p.qa_counted_hit){_p.qa_counted_hit=true;qa_stat(_p.spell_id,_p.qa_weapon_stage).projectiles_hit++;}
}
function qa_projectile_expire(_p) {
    if(!variable_instance_exists(_p,"qa_registered") || !qa_metrics_enabled())return;
    if(!_p.qa_counted_hit)qa_stat(_p.spell_id,_p.qa_weapon_stage).projectiles_expired_without_hit++;
}
function qa_boss_note(_b,_ability,_warning=-1) {
    if(!qa_metrics_enabled())return;
    global.qa_attack_serial++;
    var source={boss:_b.boss_id,ability:string(_ability),uid:global.qa_attack_serial,kind:"boss_attack"};
    _b.qa_attack=source;
    var record={uid:source.uid,boss:source.boss,ability:source.ability,phase:_b.boss_phase,start:global.qa_metrics.seconds,
        warning:_warning,first_possible:-1,first_hit:-1,threatened:false,hits:0,damage:0,maximum_hit:0,fatal_hits:0,
        last_seen:global.qa_metrics.seconds,first_exposure:-1,protected_contacts:0,unprotected_contacts:0};
    array_push(global.qa_metrics.boss_activations,record);
}
function qa_source_snapshot(_owner,_kind="contact") {
    if(instance_exists(_owner)) {
        if(variable_instance_exists(_owner,"qa_source")){var s=variable_clone(_owner.qa_source);if(!variable_struct_exists(s,"delivery"))s.delivery=_kind;return s;}
        if(variable_instance_exists(_owner,"qa_attack")){var s=variable_clone(_owner.qa_attack);s.delivery=_kind;return s;}
        if(variable_instance_exists(_owner,"boss_id"))return {boss:_owner.boss_id,ability:_kind,uid:0,kind:"boss_attack",delivery:_kind};
        return {boss:"",ability:object_get_name(_owner.object_index),uid:0,kind:"enemy_contact",delivery:"contact"};
    }
    return {boss:"",ability:_kind,uid:0,kind:"unattributed"};
}
function qa_struct_source(_s) {
    return is_struct(_s) && variable_struct_exists(_s,"qa_source") ? _s.qa_source : {boss:"",ability:"unknown",uid:0,kind:"unattributed"};
}
function qa_activation(_source) {
    if(!qa_metrics_enabled() || !is_struct(_source) || _source.uid<=0)return undefined;
    var records=global.qa_metrics.boss_activations;
    for(var i=array_length(records)-1;i>=0;i--)if(records[i].uid==_source.uid)return records[i];
    return undefined;
}
function qa_source_seen(_source,_warning=-1,_threatened=false,_active=false) {
    var a=qa_activation(_source);if(!is_struct(a))return;
    var now=global.qa_metrics.seconds;a.last_seen=now;
    if(_warning>=0 && a.warning<0)a.warning=_warning;
    if(_active && a.first_possible<0)a.first_possible=now-a.start;
    if(_threatened){a.threatened=true;if(a.first_exposure<0)a.first_exposure=now-a.start;}
}
function qa_receive_from(_pl,_amount,_height,_source) {
    var hp0=instance_exists(_pl) ? _pl.hp : 0,result=qa_original_player_receive_damage(_pl,_amount,_height);
    if(!qa_metrics_enabled() || hp0<=0)return result;
    var actual=hp0-_pl.hp,a=qa_activation(_source);
    qa_source_seen(_source,-1,true,true);
    if(is_struct(a)){if(result)a.unprotected_contacts++;else if(player_protected_from(_pl,_height))a.protected_contacts++;}
    if(actual<=0)return result;
    var delivery=variable_struct_exists(_source,"delivery") ? _source.delivery : "unspecified";
    var m=global.qa_metrics,key=_source.kind+":"+_source.boss+":"+_source.ability+":"+delivery;
    if(!variable_struct_exists(m.incoming,key))variable_struct_set(m.incoming,key,{kind:_source.kind,boss:_source.boss,ability:_source.ability,delivery:delivery,damage:0,hits:0,fatal_hits:0,maximum_hit:0});
    var s=variable_struct_get(m.incoming,key);s.damage+=actual;s.hits++;s.maximum_hit=max(s.maximum_hit,actual);
    m.damage_in+=actual;m.hits_in++;
    var event={source:variable_clone(_source),attempted:_amount,actual:actual,hp_before:hp0,hp_after:_pl.hp,height:_height,time:m.seconds};
    m.last_damage=event;if(_pl.hp<=0){m.last_fatal=event;s.fatal_hits++;}
    if(is_struct(a)){a.hits++;a.damage+=actual;a.maximum_hit=max(a.maximum_hit,actual);if(a.first_hit<0)a.first_hit=m.seconds-a.start;if(_pl.hp<=0)a.fatal_hits++;}
    qa_event("damage_in",event);return result;
}
function player_receive_damage(_pl,_amount,_height="ground") {return qa_receive_from(_pl,_amount,_height,{boss:"",ability:"unspecified",uid:0,kind:"unattributed"});}
function qa_metrics_export() {
    if(!qa_metrics_enabled())return {};
    var result=variable_clone(global.qa_metrics),now=result.seconds;
    for(var i=0;i<array_length(result.boss_activations);i++) {
        var a=result.boss_activations[i];a.censored=now-a.last_seen<.5;
        a.avoided_while_threatened=a.threatened && a.hits==0 && !a.censored;
    }
    result.damage_unit="actual_clipped_HP_loss";result.miss_unit="expired_real_projectiles_without_any_impact";
    result.avoidance_unit="attack_was_geometrically_threatening_and_finished_without_HP_loss; not_proof_of_technical_unavoidability";
    return result;
}
