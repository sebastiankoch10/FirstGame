/// Whole isolated boss encounters. Real production damage, HP, collisions and legal inputs.
/// These development presets are controlled encounter states, not measured full-run builds.
function qa_boss_case_at(_index) {
    var bosses=["storm_warden","twins","behemoth","mini_sentinel","mini_warden"];
    var classes=["Sword","Mage","Ranger"],policies=["average","experienced","no_response","technical_greedy"];
    return {boss:bosses[(_index div 3) mod 5],class_name:classes[_index mod 3],
        persona:policies[(_index div 15) mod 4],minute:[15,5,10][(_index div 60) mod 3],
        replicate:_index div 180,seed:global.qa_seedstart+(_index div 3),random_build:(_index div 180) mod 2==1};
}
function qa_boss_prepare(_case) {
    qa_reset(_case.class_name,_case.seed,_case.persona);global.qa_inside_tick=true;
    global.qa_isolated_boss=true;global.qa_bench_freeze=false;global.boss_spawned=array_create(8,true);
    global.round_seconds=_case.minute*60;
    global.monster_hp_multiplier=global.base_monster_hp_multiplier*(1+_case.minute*.07);
    global.monster_damage_multiplier=global.base_monster_damage_multiplier*(1+_case.minute*.06);
    boss_test_apply_build(_case.minute,_case.random_build,_case.seed);
    global.qa_boss_case=_case;global.qa_boss_instance=boss_spawn(_case.boss);
    global.qa_boss_start_hp=instance_exists(global.qa_boss_instance) ? global.qa_boss_instance.max_hp : 0;
    global.qa_boss_phases=[];global.qa_boss_max_overlap=0;
    global.qa_policy={reaction:_case.persona=="average" ? .30 : (_case.persona=="experienced" ? .12 : 1/60),
        avoid:_case.persona=="average" ? 1 : 1.2,mobility:_case.persona!="no_response",
        noresponse:_case.persona=="no_response",technical:_case.persona=="technical_greedy"};
    qa_metrics_reset(_case.class_name,_case.seed,_case.persona);global.qa_inside_tick=false;
}
function qa_boss_export(_reason) {
    var b=global.qa_boss_instance,c=global.qa_boss_case,m=qa_metrics_export();
    var hp_remaining=instance_exists(b) ? max(0,b.hp) : 0;
    var row={record_type:"boss_encounter",run_id:global.qa_phase+"-boss-"+string(global.qa_boss_index)+"-"+string(c.seed),
        phase:global.qa_phase,seed:c.seed,boss:c.boss,class_name:c.class_name,persona:c.persona,spawn_minute:c.minute,
        policy_version:variable_global_exists("qa_policy_version") ? global.qa_policy_version : "visible-greedy-v1",
        replicate:c.replicate,completed:_reason=="boss_defeated" || _reason=="player_death",end_reason:_reason,
        won:_reason=="boss_defeated",censored:_reason=="timeout_600_seconds",seconds:global.qa_ticks/60,
        boss_hp_initial:global.qa_boss_start_hp,boss_hp_remaining:hp_remaining,player_hp:ObjectPlayer.hp,
        player_max_hp:ObjectPlayer.max_hp,phases_seen:global.qa_boss_phases,max_simultaneous_hazards:global.qa_boss_max_overlap,
        active:global.active_spells,passive:global.passive_spells,level:global.current_level,metrics:m,
        initialization:"Equivalent production Boss Test initialization: current minute preset; actual boss_spawn; normal HP; no invulnerability",
        preset:boss_test_preset(c.minute),random_build:c.random_build,normal_population_disabled:true,
        technical_bot_limit:"Greedy visible-information route candidate scorer with legal inputs; not a complete reachability proof",
        batch_size:global.qa_batch,wall_seconds:(get_timer()-global.qa_run_wall)/1000000};
    show_debug_message("QA_MC_ROW "+json_stringify(row));return row;
}
function qa_boss_suite_step() {
    if(!variable_global_exists("qa_boss_index")){
        global.qa_boss_index=0;global.qa_boss_ready=false;
        // The wrapper forwards --cases through the existing probe argument.
        global.qa_boss_limit=min(global.qa_runs*180,max(1,global.qa_probe));
    }
    if(!global.qa_boss_ready){qa_boss_prepare(qa_boss_case_at(global.qa_boss_index));global.qa_boss_ready=true;}
    repeat(global.qa_batch){
        qa_world_tick();var b=global.qa_boss_instance;
        if(instance_exists(b) && !array_contains(global.qa_boss_phases,b.boss_phase))array_push(global.qa_boss_phases,b.boss_phase);
        global.qa_boss_max_overlap=max(global.qa_boss_max_overlap,array_length(global.bv2_hazards)+array_length(global.hostile_bullets)+array_length(global.boss_zones));
        var reason="";
        if(global.qa_boss_start_hp<=0)reason="initialization_failed";
        else if(global.game_over)reason="player_death";
        else if(!instance_exists(b) || b.hp<=0)reason="boss_defeated";
        else if(global.qa_ticks>=36000)reason="timeout_600_seconds";
        if(reason!=""){
            qa_boss_export(reason);global.qa_boss_ready=false;global.qa_boss_index++;
            if(global.qa_boss_index>=global.qa_boss_limit){show_debug_message("QA_MC_DONE "+json_stringify({mode:"boss",encounters:global.qa_boss_index,passed:true}));game_end();}
            return;
        }
    }
}
