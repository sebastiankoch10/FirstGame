/// Injected only into the isolated VM copy. Tests call actual production cast/damage/upgrade functions.
function v2_clear() {sv_clear();with(ObjectSkeletonRemains)instance_destroy();spell_v2_init();global.damage_labels=[];global.impact_fx=[];global.chain_segments=[];global.light_pulses=[];global.active_spells=[];global.passive_spells=[];global.game_paused=false;global.levelup_active=false;global.chest_collected=false;}
function v2_spell_entry(_sid,_level) {var d=GetSpellData(_sid);return {id:_sid,name:d.name,type:d.type==1 ? "active" : "passive",level:_level,cooldown:d.type==1 ? d.cooldown : 0,cooldown_timer:0};}
function v2_tick_effects(_steps) {
    repeat(_steps){spell_v2_step(.05);with(ObjectFireball)event_perform(ev_step,0);with(ObjectIceball)event_perform(ev_step,0);with(ObjectLightningball)event_perform(ev_step,0);}
}
function v2_fixtures() {
    var pl=ObjectPlayer,defs=spell_catalog();gp_check(array_length(spell_ids(1))==18 && array_length(spell_ids(2))==18,"v2 exactly eighteen implemented active and eighteen passive abilities");
    var outcomes=[];
    for(var sid=101;sid<=118;sid++) {
        for(var version=0;version<2;version++) {
            v2_clear();reset_round();cf_pos();pl.__base_max_hp=1000;pl.max_hp=1000;pl.hp=400;pl.player_power=2;pl.__base_player_power=2;apply_passives(pl);run_stats_reset();
            var d=GetSpellData(sid),entry=v2_spell_entry(sid,version==0 ? 1 : 9);
            var a=cf_enemy(pl.x+70,pl.y,10000),b=cf_enemy(pl.x+140,pl.y,10000),c=cf_enemy(pl.x+210,pl.y,10000);
            a.damage=0;b.damage=0;c.damage=0;fg_audio_stop_effects();
            var before_request=variable_struct_exists(global.fg_audio.requests,d.cue) ? variable_struct_get(global.fg_audio.requests,d.cue) : 0;
            var ok=cast_spell(entry,a),blocked=!cast_spell(entry,a);v2_tick_effects(90);
            var stats=run_stats_get(sid),effective=sid==106 ? stats.healing>0 : stats.damage>0;
            gp_check(ok && blocked && effective && stats.casts==1 && entry.cooldown_timer>0,"v2 actual cast cooldown and effective contribution "+string(sid)+" level "+string(entry.level));
            gp_check(sprite_exists(asset_get_index(d.icon_sprite_name)) && audio_exists(variable_struct_get(fg_audio_bank(),d.cue)) && variable_struct_get(global.fg_audio.requests,d.cue)==before_request+1,"v2 real icon and exactly one cue request per cast "+string(sid)+" level "+string(entry.level));
            global.active_spells=[entry];repeat(entry.cooldown_timer)hotbar_tick_cooldowns();
            gp_check(entry.cooldown_timer==0 && cast_spell(entry,a),"v2 production cooldown tick rearms the actual ability "+string(sid)+" level "+string(entry.level));
            array_push(outcomes,{id:sid,level:entry.level,damage:stats.damage,healing:stats.healing,hits:stats.hits});
        }
    }
    global.sv_metrics.spell_v2={active_outcomes:outcomes};
    var all_played=true;for(var sid=101;sid<=118;sid++)if(!variable_struct_exists(global.fg_audio.played,"skill_"+string(sid)))all_played=false;
    gp_check(all_played,"v2 audio engine actually created voices for all eighteen distinct active cues");
    var unique_levels=true;
    for(var sid=101;sid<=118;sid++){var previous=json_stringify(spell_values(sid,1));for(var lv=2;lv<=9;lv++){var current=json_stringify(spell_values(sid,lv));if(current==previous)unique_levels=false;previous=current;}}
    gp_check(unique_levels,"v2 every intermediate active upgrade changes the shared computed runtime values");
    var modifiers=["damage_reduction","player_power","moveSpeed","weapon_haste","max_hp","extra_projectiles","crit_chance","projectile_factor","spell_area","spell_cdr","fire_bonus","storm_bonus","cold_bonus","armor_flat","regen_rate","pickup_radius","status_factor","resonance"];
    for(var sid=201;sid<=218;sid++) {
        v2_clear();reset_round();pl.__base_max_hp=1000;pl.max_hp=1000;pl.hp=500;
        global.passive_spells=[v2_spell_entry(sid,1)];apply_passives(pl);var value1=variable_instance_get(pl,modifiers[sid-201]),hp1=pl.hp;
        apply_passives(pl);var stable=value1==variable_instance_get(pl,modifiers[sid-201]) && hp1==pl.hp;
        global.passive_spells[0].level=9;apply_passives(pl);var value9=variable_instance_get(pl,modifiers[sid-201]);
        gp_check(stable && value1!=value9,"v2 passive applies without stacking and really scales "+string(sid));
    }
    v2_passive_behaviour();v2_choice_checks();v2_progression_checks();v2_dragon_jump_checks();v2_combat_benchmarks();
    v2_clear();reset_round();cf_pos();fg_audio_stop_effects();
}
function v2_passive_behaviour() {
    var pl=ObjectPlayer;
    v2_clear();reset_round();cf_pos();global.passive_spells=[v2_spell_entry(207,9)];apply_passives(pl);var e=cf_enemy(pl.x+70,pl.y,100000);random_set_seed(17319);repeat(200)apply_attack_damage(e,10,pl,0);
    gp_check(run_stats_get(207).hits>0 && e.hp<98000,"v2 critical passive produces real additional HP loss under seeded RNG");
    v2_clear();reset_round();global.passive_spells=[v2_spell_entry(208,9)];global.selected_character="Mage";with(pl)player_combat_init();apply_passives(pl);e=cf_enemy(pl.x+120,pl.y);with(pl)weapon_auto_step();var p=instance_find(ObjectLightningball,0);
    gp_check(p.projectile_speed>9 && p.lifetime*p.projectile_speed>=430,"v2 projectile speed modifier affects actual staff travel without losing intended range");
    v2_clear();reset_round();global.selected_character="Sword";pl.hp=50;pl.__base_max_hp=120;pl.max_hp=120;global.passive_spells=[v2_spell_entry(215,9)];apply_passives(pl);spell_passive_step(1);
    gp_check(pl.hp>50 && run_stats_get(215).healing>0,"v2 regeneration records actual restored health");
    global.passive_spells=[v2_spell_entry(214,9)];apply_passives(pl);pl.hp=100;var before=pl.hp;player_receive_damage(pl,20);
    gp_check(abs(before-pl.hp-14.6)<.01 && run_stats_get(214).blocked>5,"v2 iron ward reduces a real incoming hit before percentage mitigation");
    v2_clear();reset_round();cf_pos();global.passive_spells=[v2_spell_entry(209,9),v2_spell_entry(210,9)];apply_passives(pl);e=cf_enemy(pl.x+165,pl.y,10000);var s=v2_spell_entry(104,1);cast_spell(s,e);
    gp_check(e.hp<10000 && s.cooldown_timer<GetSpellData(104).cooldown,"v2 area and cooldown passives alter actual nova reach and cooldown");
    v2_clear();reset_round();cf_pos();global.passive_spells=[v2_spell_entry(211,9),v2_spell_entry(212,9),v2_spell_entry(213,9)];apply_passives(pl);var valid=true;
    for(var sid=101;sid<=103;sid++){e=cf_enemy(pl.x+70,pl.y,10000);apply_attack_damage(e,100,pl,sid);if(10000-e.hp<=100)valid=false;with(e)instance_destroy();}
    gp_check(valid && spell_values(103,1).chain_targets==5,"v2 elemental passives amplify their real elements and conductor adds chain jumps");
    v2_clear();reset_round();cf_pos();global.passive_spells=[v2_spell_entry(217,9),v2_spell_entry(218,9)];apply_passives(pl);e=cf_enemy(pl.x+70,pl.y,10000);spell_v2_hit(e,10,115,1);var before=e.hp;apply_attack_damage(e,100,pl,0);
    gp_check(e.slow_time>65 && before-e.hp>100,"v2 lingering status and resonance work on an actual debuffed target");
    global.passive_spells=[v2_spell_entry(216,9)];apply_passives(pl);var coin=instance_create_layer(pl.x+160,pl.y,"Instances",ObjectCoin);var xbefore=coin.x;with(coin)event_perform(ev_step,0);
    gp_check(coin.collect_radius==204 && coin.x<xbefore,"v2 scavenger extends actual normal coin attraction without a magnet");
    v2_clear();reset_round();cf_pos();var a=cf_enemy(pl.x+80,pl.y,10000),b=cf_enemy(pl.x+150,pl.y,10000),boss=boss_spawn("storm_warden");boss.x=pl.x+150;boss.y=pl.y;
    var bx=b.x,bossx=boss.x;s=v2_spell_entry(114,1);cast_spell(s,a);spell_v2_step(.05);
    gp_check(b.x<bx && boss.x==bossx,"v2 gravity really pulls normal targets while bosses resist displacement");
    v2_clear();reset_round();cf_pos();e=cf_enemy(pl.x+80,pl.y,10000);s=v2_spell_entry(116,1);cast_spell(s,e);v2_tick_effects(40);
    gp_check(run_stats_get(116).hits==2,"v2 returning glaive hits a stationary target once on each actual leg");
    v2_clear();reset_round();cf_pos();var increasing=true,last=0;global.passive_spells=[v2_spell_entry(201,1)];e=cf_enemy(pl.x+lengthdir_x(50,4),pl.y+lengthdir_y(50,4)+18,10000);
    for(var lv=1;lv<=9;lv++){global.passive_spells[0].level=lv;apply_passives(pl);pl.orbit_angle=0;pl.orbit_frame=0;e.orbit_last_hit=-999;e.hp=10000;spell_orbit_step(pl);var loss=10000-e.hp;if(loss<=last)increasing=false;last=loss;}
    gp_check(increasing,"v2 orbit shield levels seven through nine still add real hit damage after mitigation caps");
    e.burn_time=10;e.burn_dps=9;e.burn_spell_id=107;combat_area_hit(e.x,e.y-10,30,1,pl,60,1,0,1,101);
    var kept=e.burn_spell_id==107 && e.burn_dps==9;e.burn_time=0;combat_area_hit(e.x,e.y-10,30,1,pl,60,1,0,1,101);
    gp_check(kept && e.burn_spell_id==101 && e.burn_dps==1,"v2 burn attribution keeps the strongest live source but never inherits an expired stronger burn");
}
function v2_choice_checks() {
    v2_clear();reset_round();global.active_spells=[];global.passive_spells=[];
    for(var i=0;i<3;i++){array_push(global.active_spells,v2_spell_entry(101+i,4));array_push(global.passive_spells,v2_spell_entry(201+i,4));}
    var good=true,upgrade_extras=0;
    global.choice_rng=91827;
    for(var t=0;t<200;t++) {
        spell_choices_v2("levelup");var opts=global.spell_options,owned=0,fresh=0;
        for(var i=0;i<array_length(opts);i++){if(opts[i].level>0)owned++;else fresh++;for(var j=i+1;j<array_length(opts);j++)if(opts[i].id==opts[j].id)good=false;}
        if(owned<1||fresh<1||array_length(opts)!=3)good=false;upgrade_extras+=owned-1;
    }
    gp_check(good && upgrade_extras>90 && upgrade_extras<170,"v2 reproducible weighted offers contain investment and new options without duplicate IDs");
    global.choice_rng=1337;spell_choices_v2("levelup");var first=json_stringify(global.spell_options);global.choice_rng=1337;spell_choices_v2("levelup");
    gp_check(first==json_stringify(global.spell_options),"v2 same independent offer seed yields identical cards");
    global.active_spells=[];global.passive_spells=[];for(var i=0;i<6;i++){array_push(global.active_spells,v2_spell_entry(101+i,1));array_push(global.passive_spells,v2_spell_entry(201+i,1));}
    spell_choices_v2("levelup");good=true;for(var i=0;i<array_length(global.spell_options);i++)if(global.spell_options[i].level==0)good=false;
    gp_check(good && !learn_spell(107) && !learn_spell(207),"v2 full six plus six slots offer owned upgrades only and reject new abilities");
    for(var i=0;i<6;i++){global.active_spells[i].level=9;global.passive_spells[i].level=9;}
    spell_choices_v2("levelup");gp_check(global.spell_options[0].id==-1 && spell_build_complete(),"v2 maxed build has no impossible upgrade choices");
}
function v2_progression_checks() {
    v2_clear();reset_round();global.coins=10000;global.round_seconds=0;
    gp_check(progression_try_level() && global.current_level==2,"v2 first upgrade still costs one actual coin XP");
    learn_spell(global.spell_options[0].id);global.game_paused=false;global.levelup_active=false;global.next_levelup_time=6;
    gp_check(!progression_try_level() && global.current_level==2,"v2 banked XP cannot interrupt the first skill immediately again");
    global.round_seconds=6;gp_check(progression_try_level() && global.current_level==3,"v2 next XP choice unlocks after six actual gameplay seconds");
    v2_clear();reset_round();var boss=boss_spawn("mini_sentinel");global.coins_needed=100;global.coins=0;boss_reward_once(boss);var reward=global.coins;
    gp_check(reward==2 && !boss_reward_once(boss) && global.coins==reward,"v2 miniboss XP is capped and awarded exactly once alongside real loot");
    var models=[[45,18],[80,30],[70,55]],replays=[];
    for(var m=0;m<3;m++) {
        v2_clear();reset_round();global.choice_rng=18391;var samples=[],full_min=-1,decisions=0,chests=0;
        for(var sec=1;sec<=1740;sec++) {
            global.round_seconds=sec;global.coins+=(models[m][0]+models[m][1]*sec/60)/60;
            if(array_contains([60,180,300,600,900,1200,1500],sec)) {
                global.coins+=min(sec<300 ? 2 : 5,floor(global.coins_needed*.12));
                handle_chest_selection("chest");v2_accept_first();chests++;decisions++;
            }
            if(progression_try_level()){v2_accept_first();decisions++;}
            if(spell_build_complete() && full_min<0)full_min=sec/60;
            if(array_contains([60,180,300,600,900,1200,1500,1740],sec))array_push(samples,{minute:sec/60,level:global.current_level,decisions:decisions});
        }
        array_push(replays,{base:models[m][0],slope:models[m][1],samples:samples,full_build_minute:full_min});
        gp_check(m!=2 || (full_min>=28 && full_min<=29.2),"v2 actual progression and offer code handles injected budget profile "+string(m));
    }
    global.sv_metrics.spell_v2.native_budget_replays=replays;
}
function v2_accept_first() {
    if(array_length(global.spell_options)>0 && global.spell_options[0].id>0)learn_spell(global.spell_options[0].id);
    global.game_paused=false;global.levelup_active=false;global.chest_collected=false;global.choice_open=false;global.next_levelup_time=global.round_seconds+6;
}
function v2_combat_benchmarks() {
    var pl=ObjectPlayer,samples=[];global.bench_dt=1/60;
    for(var phase=0;phase<2;phase++) {
        v2_clear();global.selected_character="Sword";reset_round();cf_pos();random_set_seed(20260222);
        pl.__base_max_hp=100000;pl.max_hp=100000;pl.hp=100000;
        global.monster_hp_multiplier=phase==0 ? 1 : 2.75;global.monster_damage_multiplier=phase==0 ? 1 : 2.5;
        ObjectSpawner.population_timer=0;ObjectSpawner.runtime_cap=180;
        if(phase==1) {
            var active=[101,103,107,109,114,118],passive=[202,204,206,209,210,218];
            for(var n=0;n<6;n++){array_push(global.active_spells,v2_spell_entry(active[n],9));array_push(global.passive_spells,v2_spell_entry(passive[n],9));}
        }
        apply_passives(pl);var start_kills=0;
        for(var frame=0;frame<840;frame++) {
            global.round_seconds=(phase==0 ? 0 : 1500)+frame/60;
            with(ObjectSpawner)event_perform(ev_step,0);
            with(pl)weapon_auto_step();hotbar_tick_cooldowns();auto_spells_step();spell_v2_step(1/60);
            with(ObjectSwordHitbox)event_perform(ev_step,0);
            with(ObjectFireball)event_perform(ev_step,0);with(ObjectIceball)event_perform(ev_step,0);with(ObjectLightningball)event_perform(ev_step,0);
            with(ObjectMonster)event_perform(ev_step,0);with(ObjectSkeletonRemains)event_perform(ev_step,0);
            if(frame==239)start_kills=global.run_kills;
        }
        var kills=global.run_kills-start_kills;
        array_push(samples,{phase:phase==0 ? "start_weapon_only" : "six_plus_six_level9_at_minute25",sample_seconds:10,warmup_seconds:4,kills:kills,kills_per_minute:kills*6,seed:20260222,fixed_hz:60,stationary_invulnerable_fixture:true});
        gp_check(kills>0,"v2 short production combat benchmark records actual kills "+string(phase));
    }
    global.bench_dt=0;global.sv_metrics.spell_v2.combat_benchmarks=samples;
}
function v2_dragon_jump_checks() {
    v2_clear();reset_round();cf_pos();var pl=ObjectPlayer,b=boss_spawn("storm_warden");b.x=pl.x+250;b.y=pl.y+200;dragon_attack_begin(b,"beam");var g=dragon_attack_geometry(b),r=combat_view_rect();
    gp_check(g.length>=1200 && dragon_config().warning>=.6 && dragon_config().warning<.95,"v2 dragon covers the viewport with a shorter fair locked warning");
    gp_check(dragon_config().magma_radius>=104 && dragon_config().magma_radius<=156,"v2 magma diameter is between two and three times its previous size");
    dragon_attack_begin(b,"stomp");var separated=true;
    for(var i=0;i<array_length(b.dragon_magma);i++)for(var j=i+1;j<array_length(b.dragon_magma);j++)if(point_distance(b.dragon_magma[i].x,b.dragon_magma[i].y,b.dragon_magma[j].x,b.dragon_magma[j].y)<250)separated=false;
    gp_check(separated && array_length(b.dragon_magma)>0,"v2 magma warning circles retain gaps instead of unavoidable overlapping zones");
    with(b)instance_destroy();pl.motion_state=0;pl.mobility_cooldown=0;pl.jump_time=0;pl.jump_second_used=false;var startx=pl.x,peak=0;
    for(var i=0;i<45;i++){movement_step(pl,1/60,true,0,pl.moveSpeed,i==0,false);peak=max(peak,pl.jump_height);}
    gp_check(peak>65 && pl.x-startx>135 && pl.motion_state!=player_motion_state.sliding,"v2 single jump is higher and farther without producing an automatic slide");
    pl.motion_state=0;pl.mobility_cooldown=0;pl.jump_time=0;pl.jump_second_used=false;
    for(var i=0;i<30;i++)movement_step(pl,1/60,true,0,pl.moveSpeed,i==0 || i==20,false);
    gp_check(pl.motion_state==player_motion_state.sliding || pl.slide_timer>0,"v2 precise second apex press still triggers the actual dive and slide");
    gp_check(sword_visual_tier(1)==1 && sword_visual_tier(34)==2 && sword_visual_tier(68)==3,"v2 sword presentation has three progression tiers without changing damage multipliers");
    var pillar=noone,arch=noone;with(ObjectMasterScenery){if(master_prop==8)pillar=id;if(master_prop==9)arch=id;}
    gp_check(instance_exists(pillar) && scenery_point_blocked(pillar.x,pillar.y-6,10) && !scenery_point_blocked(arch.x,arch.y-6,10),"v2 enlarged masonry has solid base footprints but an open arch passage");
    pl.motion_state=0;pl.mobility_cooldown=0;pl.dodge_timer=0;pl.x=pillar.x-28*pillar.image_xscale-15;pl.y=pillar.y-6;var oldx=pl.x;
    movement_step(pl,.05,true,0,pl.moveSpeed,false,false);
    gp_check(pl.x==oldx,"v2 actual player movement cannot walk through an enlarged column base");
    gp_check(dragon_config().magma_warning*2.8*60>dragon_config().magma_radius+20,"v2 giant magma retains enough warning travel distance for the slowest base class");
}
function v2_native_scene(_ids) {
    v2_clear();cf_pos(2112,1952);ObjectSpawner.population_timer=999;global.normal_pause_active=false;
    var pl=ObjectPlayer;pl.hp=100000;pl.max_hp=100000;pl.__base_max_hp=100000;pl.weapon_cooldown=999;pl.sword_combo_active=false;pl.attack_timer=0;
    for(var i=0;i<array_length(_ids);i++){learn_spell(_ids[i]);global.active_spells[i].level=5;}
    apply_passives(pl);
    for(var i=0;i<14;i++){var e=cf_enemy(pl.x+85+(i div 4)*48,pl.y-65+(i mod 4)*43,10000);e.damage=0;e.base_move_speed=.18;}
}
function v2_native_tick(_f) {
    // Real frames let the audio mixer process its bounded voices after fast-forward fixtures.
    if(_f==2260){v2_clear();global.selected_character="Mage";reset_round();cf_pos();ObjectSpawner.population_timer=999;ObjectPlayer.hp=40;learn_spell(106);var e=cf_enemy(ObjectPlayer.x+80,ObjectPlayer.y,10000);e.damage=0;e.base_move_speed=0;}
    if(_f==2280)gp_check(variable_struct_exists(global.fg_audio.played,"magic_hit") && variable_struct_exists(global.fg_audio.played,"skill_106") && run_stats_get(106).healing>0,"native real-frame staff impact and healing create actual audio engine voices after mixer advance");
    if(_f==2310){global.selected_character="Sword";reset_round();v2_native_scene([103]);}
    if(_f==2340)v2_native_scene([101]);
    if(_f==2370)v2_native_scene([105]);
    if(_f==2400)v2_native_scene([107,110,114,115]);
    if(_f==2480)v2_native_scene([109,111,116,117]);
    if(_f==2550)v2_native_scene([112,113,118]);
    if(_f==2630) {
        v2_clear();global.active_spells=[];global.passive_spells=[];
        for(var i=0;i<6;i++){array_push(global.active_spells,v2_spell_entry(101+i,5));array_push(global.passive_spells,v2_spell_entry(201+i,4));}
        global.game_paused=true;global.normal_pause_active=true;
        var ui=pause_geometry();global.cf_mx=ui.w+36+55;global.cf_my=90+2*34+5;
    }
    if(_f==2645) {
        global.normal_pause_active=false;global.active_spells=[];global.passive_spells=[];
        for(var i=0;i<3;i++){array_push(global.active_spells,v2_spell_entry(101+i,3));array_push(global.passive_spells,v2_spell_entry(201+i,2));}
        global.choice_rng=91827;handle_chest_selection("levelup");global.cf_mx=-100;global.cf_my=-100;
    }
    if(_f==2660) {
        global.game_paused=false;global.normal_pause_active=false;v2_clear();cf_pos(2112,1952);apply_passives(ObjectPlayer);
        var tree=instance_create_layer(ObjectPlayer.x+250,ObjectPlayer.y+75,"Instances",ObjectMasterScenery);tree.master_prop=0;tree.sprite_index=spr_master_oak;tree.depth=-tree.y;
        var coin=instance_create_layer(tree.x,tree.y-45,"Instances",ObjectCoin);ObjectMasterWorld.master_cull_x=-100000;
        global.cf_hidden_coin=coin;
    }
    if(_f==2670)gp_check(instance_exists(global.cf_hidden_coin) && coin_hidden_by_scenery(global.cf_hidden_coin),"v2 actual coin behind a large tree qualifies for the subtle overlay marker");
    if(_f==2710){sv_clear();var b=boss_spawn("mini_sentinel");b.x=ObjectPlayer.x+195;b.y=ObjectPlayer.y+125;b.boss_timer=999;}
    if(_f==2760){sv_clear();var b=boss_spawn("storm_warden");b.x=ObjectPlayer.x+245;b.y=ObjectPlayer.y+210;dragon_attack_begin(b,"beam");global.cf_boss=b;}
    if(_f==2840 && instance_exists(global.cf_boss))dragon_attack_begin(global.cf_boss,"stomp");
    if(_f==2920){sv_clear();ObjectPlayer.motion_state=0;ObjectPlayer.mobility_cooldown=0;global.cf_key=vk_space;global.cf_move=true;}
}
function v2_capture_name(_f) {
    switch(_f) {
        case 2315:return "v2-chain";case 2346:return "v2-fire-flight";case 2354:return "v2-fire-impact";
        case 2377:return "v2-barrage";case 2430:return "v2-fields";case 2505:return "v2-orbits-summon";
        case 2594:return "v2-verdict";case 2634:return "v2-pause-details";case 2645:return "v2-offers";case 2680:return "v2-hidden-coin";
        case 2720:return "v2-miniboss-arrow";case 2764:return "v2-warning";case 2806:return "v2-screen-beam";
        case 2845:return "v2-magma-warning";case 2900:return "v2-magma-impact";case 2938:return "v2-jump";
    }
    return "";
}
