/// Controlled native DPS/mechanic measurements, independent of Monte Carlo wins.
function qa_bench_skill(_sid,_level) {
    repeat(_level)boss_test_add_skill(_sid);
}
function qa_bench_clear_targets() {with(ObjectMonster)instance_destroy();with(ObjectBossMonster)instance_destroy();}
function qa_bench_target(_x,_y) {
    var e=instance_create_layer(_x,_y,"Instances",ObjectMonster);e.hp=10000000;e.max_hp=e.hp;
    e.master_skeleton=false;e.damage=0;e.base_move_speed=0;e.knock_vx=0;e.knock_vy=0;return e;
}
function qa_bench_prepare(_sid,_level,_count,_passive=0,_passive_level=0,_class="Sword",_weapons=false) {
    qa_reset(_class,global.qa_seedstart,"controlled_benchmark");global.qa_inside_tick=true;
    global.qa_bench_freeze=true;global.qa_isolated_boss=true;global.boss_spawned=array_create(8,true);
    global.qa_bench_weapons=_weapons;global.qa_bench_frames=0;
    var passive_cell=global.qa_bench_index>=324 && global.qa_bench_index<648;
    global.qa_bench_case={kind:global.qa_bench_index<324 ? "active" : (passive_cell ? "passive_ab" : "base_weapon"),sid:_sid,level:_level,target_count:_count,passive:_passive,passive_level:_passive_level,class_name:_class,
        tested_passive:passive_cell ? 201+((global.qa_bench_index-324) div 18) : 0,
        comparison_level:passive_cell ? [1,5,9][((global.qa_bench_index-324) mod 18) div 6] : 0,
        variant:passive_cell ? ["active_control","active_plus_passive","active_plus_passive_plus_base_weapon"][((global.qa_bench_index-324) mod 6) div 2] : "standalone"};
    global.active_spells=[];global.passive_spells=[];
    if(_sid>0)qa_bench_skill(_sid,_level);
    if(_passive>0)qa_bench_skill(_passive,_passive_level);
    apply_passives(ObjectPlayer);var pl=ObjectPlayer;
    // Healing throughput is measured with a large real missing-HP reserve.
    if(_sid==106){pl.max_hp=100000;pl.hp=1000;}
    if(_passive==215)pl.hp=max(1,pl.max_hp*.25);
    global.qa_bench_start_hp=pl.hp;global.qa_bench_start_maxhp=pl.max_hp;
    global.qa_bench_start_x=pl.x;global.qa_bench_start_y=pl.y;
    for(var i=0;i<_count;i++) {
        var angle=_count==1 ? 0 : i*360/_count,spread=_count==1 ? 0 : 44;
        qa_bench_target(pl.x+100+lengthdir_x(spread,angle),pl.y+lengthdir_y(spread,angle));
    }
    qa_metrics_reset(_class,global.qa_seedstart,"controlled_benchmark");global.qa_inside_tick=false;
}
function qa_bench_tick() {
    global.qa_inside_tick=true;qa_metrics_tick(1/60);global.round_seconds+=1/60;
    hotbar_tick_cooldowns();auto_spells_step();
    if(global.qa_bench_weapons)with(ObjectPlayer)weapon_auto_step();
    class_effects_step(1/60);spell_v2_step(1/60);spell_orbit_step(ObjectPlayer);spell_passive_step(1/60);
    with(ObjectFireball)event_perform(ev_step,0);with(ObjectIceball)event_perform(ev_step,0);with(ObjectLightningball)event_perform(ev_step,0);with(ObjectSwordHitbox)event_perform(ev_step,0);
    with(ObjectMonster)event_perform(ev_step,0);
    with(ObjectBossMonster)boss_step(id,1/60);
    global.qa_bench_frames++;global.qa_inside_tick=false;
}
function qa_bench_export() {
    var c=global.qa_bench_case,m=qa_metrics_export(),s=m.seconds;
    // A separate actual incoming-damage probe quantifies defensive modifiers;
    // it runs after the damage window and is not added to outgoing DPS.
    var before_probe=ObjectPlayer.hp;qa_original_player_receive_damage(ObjectPlayer,20,"all");
    var defensive_probe=before_probe-ObjectPlayer.hp;
    var row={record_type:"controlled_benchmark",run_id:global.qa_phase+"-bench-"+string(global.qa_bench_index),phase:global.qa_phase,
        seed:global.qa_seedstart,class_name:c.class_name,kind:c.kind,sid:c.sid,level:c.level,target_count:c.target_count,
        passive:c.passive,passive_level:c.passive_level,seconds:s,damage:m.damage_out,dps:m.damage_out/max(.001,s),
        tested_passive:c.tested_passive,comparison_level:c.comparison_level,variant:c.variant,
        healing:m.healing,player_hp:ObjectPlayer.hp,player_max_hp:ObjectPlayer.max_hp,metrics:m,
        utility:{incoming20_actual_hp_loss:defensive_probe,max_hp_bonus:ObjectPlayer.max_hp-ObjectPlayer.__base_max_hp,
            movement_speed:ObjectPlayer.moveSpeed,pickup_radius:ObjectPlayer.pickup_radius},
        controlled_stationary_targets:true,hostile_ai_disabled:true,gameplay_win:false,
        values:c.sid>0 ? spell_values(c.sid,c.level) : weapon_definition(c.class_name),
        player_modifiers:{power:ObjectPlayer.player_power,move_speed:ObjectPlayer.moveSpeed,haste:ObjectPlayer.weapon_haste,
            area:ObjectPlayer.spell_area,cdr:ObjectPlayer.spell_cdr,projectile_factor:ObjectPlayer.projectile_factor,
            damage_reduction:ObjectPlayer.damage_reduction,armor:ObjectPlayer.armor_flat,regen:ObjectPlayer.regen_rate,
            pickup_radius:ObjectPlayer.pickup_radius,status_factor:ObjectPlayer.status_factor,crit_chance:ObjectPlayer.crit_chance,
            fire_bonus:ObjectPlayer.fire_bonus,cold_bonus:ObjectPlayer.cold_bonus,storm_bonus:ObjectPlayer.storm_bonus,resonance:ObjectPlayer.resonance}};
    show_debug_message("QA_MC_ROW "+json_stringify(row));return row;
}
function qa_telemetry_check(_ok,_name) {array_push(global.qa_telemetry_checks,{name:_name,passed:_ok});}
function qa_telemetry_tests() {
    global.qa_telemetry_checks=[];qa_reset("Sword",111331,"telemetry_validation");global.qa_inside_tick=true;
    global.qa_bench_freeze=true;var e=qa_bench_target(ObjectPlayer.x+100,ObjectPlayer.y),pl=ObjectPlayer;
    e.hp=10;qa_metrics_reset("Sword",111331,"telemetry_validation");
    apply_attack_damage(e,40,pl,101);var m=qa_metrics_export();
    qa_telemetry_check(m.damage_out==10 && m.attempted_out==40 && m.overkill==30 && qa_stat(101).damage==10,"actual HP delta clips forty attempted damage to ten HP plus thirty overkill");
    qa_telemetry_check(m.kills==1,"overkill credits exactly one enemy kill");
    apply_attack_damage(e,40,pl,101);qa_telemetry_check(global.qa_metrics.damage_out==10 && global.qa_metrics.kills==1,"dead target cannot generate duplicate damage or kill");
    e.hp=100;e.max_hp=100;pl.crit_chance=1;pl.crit_damage=1.6;qa_metrics_reset("Sword",111331,"telemetry_validation");
    apply_attack_damage(e,10,pl,101);qa_telemetry_check(e.hp==84 && qa_stat(101).damage==16 && qa_stat(101).critical_hits==1,"critical multiplier recorded once on the originating skill");pl.crit_chance=0;
    e.burn_dps=60;e.burn_time=2;e.burn_spell_id=101;with(e)event_perform(ev_step,0);
    qa_telemetry_check(e.hp==83 && qa_stat(101).damage==17 && qa_stat(101).dot_damage==1,"production burn tick adds one HP once to its original active skill");
    qa_telemetry_check(!variable_struct_exists(global.qa_metrics.sources,"s207") || variable_struct_get(global.qa_metrics.sources,"s207").damage==0,"critical passive can count proc activations but does not duplicate its boosted attack damage");
    qa_metrics_reset("Sword",111331,"telemetry_validation");pl.hp=100;pl.max_hp=100;pl.armor_flat=2;pl.damage_reduction=.25;
    var source={boss:"behemoth",ability:"2",uid:0,kind:"boss_attack"};qa_receive_from(pl,10,"all",source);
    qa_telemetry_check(pl.hp==94 && global.qa_metrics.damage_in==6 && global.qa_metrics.last_damage.source.ability=="2","incoming damage measured after armor and reduction with explicit source");
    pl.dodge_timer=.1;qa_receive_from(pl,10,"all",source);qa_telemetry_check(pl.hp==94 && global.qa_metrics.damage_in==6,"protected contacts produce zero HP damage");pl.dodge_timer=0;
    var b=boss_spawn("behemoth");qa_boss_note(b,2,1);var snap=qa_source_snapshot(b,"acid");qa_boss_note(b,9,1);qa_receive_from(pl,8,"all",snap);
    qa_telemetry_check(global.qa_metrics.last_damage.source.ability=="2" && b.qa_attack.ability=="9","lingering hazard retains its birth ability after a new boss cast");
    qa_metrics_reset("Sword",111331,"telemetry_validation");pl.hp=3;pl.armor_flat=0;pl.damage_reduction=0;qa_receive_from(pl,100,"all",snap);
    qa_telemetry_check(global.qa_metrics.damage_in==3 && global.qa_metrics.last_fatal.actual==3 && global.qa_metrics.last_fatal.source.ability=="2","fatal incoming overkill clips to remaining HP with immutable source");
    global.game_paused=false;global.game_over=false;qa_bench_clear_targets();global.qa_inside_tick=false;
    var failed=0;for(var i=0;i<array_length(global.qa_telemetry_checks);i++)if(!global.qa_telemetry_checks[i].passed)failed++;
    show_debug_message("QA_MC_ROW "+json_stringify({record_type:"telemetry_validation",checks:global.qa_telemetry_checks,passed:failed==0,failed:failed}));
    return failed==0;
}
function qa_bench_case_at(_index) {
    //324 active cells,324 paired passive cells (1/8 target, levels1/5/9),6 base-weapon cells.
    if(_index<324){var sid=101+(_index div 18),within=_index mod 18;return {sid:sid,level:1+(within div 2),count:within mod 2==0 ? 1 : 8,passive:0,passive_level:0,class_name:"Sword",weapon:false};}
    _index-=324;
    if(_index<324){var passive=201+(_index div 18),within=_index mod 18,lv=[1,5,9][within div 6],variant=(within div 2) mod 3,count=within mod 2==0 ? 1 : 8;
        //Each passive has its prerequisite active and a paired unmodified run. Variant0 baseline,1 passive,2 passive+weapon.
        var sid=passive==212 ? 103 : (passive==213 || passive==217 ? 102 : (passive==218 ? 107 : 101));
        return {sid:sid,level:5,count:count,passive:variant==0 ? 0 : passive,passive_level:variant==0 ? 0 : lv,class_name:"Sword",weapon:variant==2};}
    _index-=324;return {sid:0,level:1,count:_index mod 2==0 ? 1 : 8,passive:0,passive_level:0,class_name:["Sword","Mage","Ranger"][_index div 2],weapon:true};
}
function qa_bench_suite_step() {
    if(!variable_global_exists("qa_bench_index")) {
        global.qa_bench_index=0;global.qa_bench_ready=false;
        if(!qa_telemetry_tests()){show_debug_message("QA_MC_DONE "+json_stringify({mode:"bench",passed:false,reason:"telemetry_validation"}));game_end();return;}
    }
    if(!global.qa_bench_ready){var c=qa_bench_case_at(global.qa_bench_index);qa_bench_prepare(c.sid,c.level,c.count,c.passive,c.passive_level,c.class_name,c.weapon);global.qa_bench_ready=true;}
    repeat(global.qa_batch) {
        qa_bench_tick();
        if(global.qa_bench_frames>=900){qa_bench_export();global.qa_bench_index++;global.qa_bench_ready=false;
            if(global.qa_bench_index>=654){global.qa_bench_freeze=false;show_debug_message("QA_MC_DONE "+json_stringify({mode:"bench",rows:global.qa_bench_index,passed:true}));game_end();}return;}
    }
}
