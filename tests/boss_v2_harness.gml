/// Isolated native tests: direct production states, no injected gameplay in normal builds.
function bt_check(_ok,_label) {global.bt_checks++;if(!_ok){array_push(global.bt_failures,_label);show_debug_message("BOSS2 FAIL "+_label);}else show_debug_message("BOSS2 PASS "+_label);}
function bt_clear() {
    with(ObjectMonster)instance_destroy();with(ObjectBossMonster)instance_destroy();with(ObjectCoin)instance_destroy();with(ObjectChest)instance_destroy();with(ObjectMagnetOrb)instance_destroy();with(ObjectSkeletonRemains)instance_destroy();
    with(ObjectLightningball)instance_destroy();with(ObjectFireball)instance_destroy();with(ObjectIceball)instance_destroy();with(ObjectSwordHitbox)instance_destroy();
}
function bt_pos(_x=2048,_y=2048) {var pl=ObjectPlayer;pl.x=_x;pl.y=_y;pl.pickup_prev_x=_x;pl.pickup_prev_y=_y;pl.motion_state=player_motion_state.grounded;pl.jump_height=0;pl.dodge_timer=0;pl.boss_root_time=0;pl.boss_poison_time=0;pl.boss_poison_dps=0;camera_set_view_pos(pl.camera,_x-400,_y-300);}
function bt_reset(_class="Sword") {
    boss_test_end();bt_clear();global.selected_character=_class;reset_round();bt_pos();global.bt_dt=1/60;global.bt_bench_freeze=false;ObjectSpawner.population_timer=1000000000;
    global.boss_spawned=array_create(8,true);global.bv2_hazards=[];global.hostile_bullets=[];global.boss_zones=[];global.class_effects=[];
}
function bt_spawn(_id,_minute=15) {
    bt_reset();global.round_seconds=_minute*60;global.monster_hp_multiplier=1+_minute*.07;global.monster_damage_multiplier=1+_minute*.06;
    var pl=ObjectPlayer;pl.max_hp=100000;pl.__base_max_hp=100000;pl.hp=100000;var b=boss_spawn(_id);return b;
}
function bt_tick(_b,_dt) {if(instance_exists(_b))boss_step(_b,_dt);boss_hazards_step(_dt);bv2_hazards_step(_dt);}
function bt_effect_tick() {
    class_effects_step(1/60);spell_v2_step(1/60);var hold=global.bt_hold;global.bt_hold=false;
    with(ObjectFireball)event_perform(ev_step,0);with(ObjectIceball)event_perform(ev_step,0);with(ObjectLightningball)event_perform(ev_step,0);with(ObjectSwordHitbox)event_perform(ev_step,0);global.bt_hold=hold;
}
function bt_weapon_tick() {with(ObjectPlayer)weapon_auto_step();}
function bt_sword_regression() {
    bt_reset("Sword");var pl=ObjectPlayer,e=instance_create_layer(pl.x+70,pl.y,"Instances",ObjectMonster);e.hp=10000;e.max_hp=e.hp;pl.player_power=2;var hp0=e.hp;
    repeat(4){bt_weapon_tick();with(ObjectSwordHitbox)event_perform(ev_step,0);}bt_check(e.hp==hp0,"Original sword still has harmless preparation");bt_weapon_tick();with(ObjectSwordHitbox)event_perform(ev_step,0);var first=hp0-e.hp;
    repeat(18){bt_weapon_tick();with(ObjectSwordHitbox)event_perform(ev_step,0);}var second=hp0-e.hp-first;
    repeat(20){bt_weapon_tick();with(ObjectSwordHitbox)event_perform(ev_step,0);}var third=hp0-e.hp-first-second;
    bt_check(first==11 && second==13 && third==19,"Normal sword retains its actual eleven/thirteen/nineteen damage combo");global.bt_metrics.sword_combo=[first,second,third];
}
function bt_contact(_h) {
    var g=_h.g,angle=g.angle,dist=g.radius*.5;
    if(g.shape=="ring"){angle=_h.gap_angle+180+_h.rotate_speed*max(0,_h.age-_h.warning);dist=(g.radius+g.inner)*.5;}
    if(g.shape=="circle")dist=0;
    if(_h.expand_from>=0)dist=_h.expand_from-(variable_struct_exists(_h,"ring_width") ? _h.ring_width : 40)*.5;
    if(variable_struct_exists(_h,"wave_from_x")){ObjectPlayer.x=_h.wave_from_x+lengthdir_x(_h.wave_thickness*.5,_h.wave_angle);ObjectPlayer.y=_h.wave_from_y+lengthdir_y(_h.wave_thickness*.5,_h.wave_angle)+10;return;}
    ObjectPlayer.x=g.x+lengthdir_x(dist,angle);ObjectPlayer.y=g.y+lengthdir_y(dist,angle)+10;
}
function bt_catalog_tests() {
    var catalog=boss_v2_catalog(),snapshots=[];bt_check(array_length(catalog)==3,"Exactly three implemented main boss definitions");
    for(var k=0;k<array_length(catalog);k++) {
        var def=catalog[k];bt_check(array_length(def.abilities)==9 && boss_v2_available(def),def.id+" has nine real available abilities and imported actor art");
        for(var minute_index=0;minute_index<3;minute_index++) {
            var minute=[5,10,15][minute_index],b=bt_spawn(def.id,minute);bt_check(instance_exists(b),def.id+" spawns at minute "+string(minute));if(!instance_exists(b))continue;
            var limit=(minute_index+1)*3,original_scale=json_stringify(b.v2_scaling);bt_check(b.v2_unlocked==limit && b.v2_spawn_seconds==minute*60,def.id+" captures "+string(limit)+" unlocked abilities at spawn");
            global.round_seconds=1800;b.hp=b.max_hp*.05;b.boss_phase=4;b.boss_state="recovery";b.boss_timer=0;boss_step(b,.01);
            bt_check(b.v2_unlocked==limit && json_stringify(b.v2_scaling)==original_scale,def.id+" spawn difficulty stays frozen across time and HP phase");
            var rotation=b.dragon_enabled ? boss_v2_dragon_rotation(b) : bv2_encounter_rotation(b),valid=true;
            for(var i=0;i<array_length(rotation);i++) {
                if(b.dragon_enabled){if(!boss_v2_attack_allowed(b,rotation[i]))valid=false;}else if(rotation[i]>limit)valid=false;
            }
            bt_check(valid && array_length(rotation)>0,def.id+" phase four cannot bypass minute "+string(minute)+" unlocks");
            if(limit<9)bt_check(!boss_v2_force_attack(b,limit+1),def.id+" refuses a locked forced ability");
            array_push(snapshots,{boss:def.id,minute:minute,unlocked:limit,hp:b.max_hp,scaling:b.v2_scaling});
        }
    }
    global.bt_metrics.snapshots=snapshots;
    var incomplete=variable_clone(catalog[0]);incomplete.implemented=false;bt_check(!boss_v2_available(incomplete),"Incomplete definitions cannot enter the live random pool");
    global.boss_rng=84121;var first=[],second=[];repeat(30)array_push(first,boss_v2_pick());global.boss_rng=84121;repeat(30)array_push(second,boss_v2_pick());
    bt_check(json_stringify(first)==json_stringify(second),"Seeded regular boss selection is reproducible");var seen=[];for(var i=0;i<array_length(first);i++){if(!array_contains(seen,first[i]))array_push(seen,first[i]);bt_check(boss_v2_available(boss_v2_definition(first[i])),"Random choice is an available implemented encounter "+string(i));}
    bt_check(array_length(seen)==3,"Seeded random sample can select all three main bosses");global.bt_metrics.random_selection=first;
}
function bt_dragon_abilities() {
    var outcomes=[];
    for(var ability=1;ability<=9;ability++) {
        var b=bt_spawn("storm_warden"),pl=ObjectPlayer;bt_check(boss_v2_force_attack(b,ability),"Dragon accepts unlocked ability "+string(ability));var kind=b.boss_cast,c=b.enc_cfg,g=b.enc_geometry,hp0=pl.hp;
        pl.x=g.x+lengthdir_x(kind=="vortex" ? 80 : 100,g.angle);pl.y=g.y+lengthdir_y(kind=="vortex" ? 80 : 100,g.angle)+10;
        if(kind=="meteor" || kind=="stomp"){pl.x=b.enc_zones[0].x;pl.y=b.enc_zones[0].y+10;}
        if(kind=="slam"){pl.x=g.x+30;pl.y=g.y+10;}
        // Since 24.11.2026 the fire beam is a sweeping bv2 hazard (docs/Design/Boss-Design.md): stand on its announced start edge.
        var swept=kind=="beam" && variable_instance_exists(b,"enc_sweep") && is_struct(b.enc_sweep);
        if(swept){var sg=b.enc_sweep.g;pl.x=sg.x+lengthdir_x(100,b.enc_sweep.sweep_from);pl.y=sg.y+lengthdir_y(100,b.enc_sweep.sweep_from)+10;}
        boss_step(b,c.warning-.001);if(swept)bv2_hazards_step(0);bt_check(pl.hp==hp0,"Dragon "+kind+" does not damage during preparation");boss_step(b,.0011);if(swept)bv2_hazards_step(0);
        if(array_contains(["wind","void","volley"],kind)){bt_check(array_length(global.hostile_bullets)>0,"Dragon "+kind+" releases visible actual projectiles");var bullet=global.hostile_bullets[0];pl.x=bullet.x;pl.y=bullet.y+10;boss_hazards_step(.001);}
        bt_check(pl.hp<hp0,"Dragon "+kind+" causes real active HP loss");array_push(outcomes,{ability:ability,key:kind,damage:hp0-pl.hp,warning:c.warning});
    }
    global.bt_metrics.dragon_abilities=outcomes;
}
function bt_encounter_abilities(_id) {
    var outcomes=[];
    for(var ability=1;ability<=9;ability++) {
        var b=bt_spawn(_id),pl=ObjectPlayer,hp0=pl.hp;bt_check(boss_v2_force_attack(b,ability),_id+" accepts ability "+string(ability));
        if((_id=="twins" && ability==1) || (_id=="behemoth" && ability==1)) {
            bt_check(array_length(global.bv2_hazards)==0,_id+" ordinary projectile has no floor warning");bt_tick(b,b.v2_warning+.001);
            bt_check(array_length(global.hostile_bullets)>0,_id+" ordinary attack releases a real projectile");var bullet=global.hostile_bullets[0];pl.x=bullet.x;pl.y=bullet.y+10;boss_hazards_step(.001);bv2_hazards_step(.001);
            if(_id=="behemoth")bt_check(array_length(global.bv2_hazards)>0 && global.bv2_hazards[0].activated && pl.boss_poison_time>0,"Poison spit collision immediately activates its zero-warning splash and poison status");
        } else if(_id=="behemoth" && ability==6) {
            bt_tick(b,b.v2_warning+.001);var count=0,minion=noone;with(ObjectMonster)if(variable_instance_exists(id,"boss_minion") && boss_minion){count++;minion=id;}
            bt_check(count>0 && count<=6,"Sumpfbrut releases bounded actual minions");if(instance_exists(minion)){pl.x=minion.x;pl.y=minion.y;with(minion)bv2_minion_step(id,.01);}
        } else {
            bt_check(array_length(global.bv2_hazards)>0,_id+" ability "+string(ability)+" creates a real hazard");
            if(array_length(global.bv2_hazards)>0) {
                var h=global.bv2_hazards[0];for(var j=1;j<array_length(global.bv2_hazards);j++)if(global.bv2_hazards[j].warning<h.warning)h=global.bv2_hazards[j];
                bt_contact(h);bt_tick(b,h.warning-.001);bt_check(pl.hp==hp0,_id+" ability "+string(ability)+" is harmless before countdown completion");
                boss_step(b,.0011);bt_contact(h);bv2_hazards_step(.0011);
                bt_check(h.activated,_id+" ability "+string(ability)+" activates on the completing update");
            }
        }
        bt_check(pl.hp<hp0,_id+" ability "+string(ability)+" causes actual HP loss");array_push(outcomes,{ability:ability,damage:hp0-pl.hp});
    }
    variable_struct_set(global.bt_metrics,_id+"_abilities",outcomes);
}
function bt_twins_tests() {
    var b=bt_spawn("twins"),pl=ObjectPlayer,child=b.v2_child;bt_check(instance_exists(child),"Twin encounter has two actual targetable actors");if(!instance_exists(child))return;
    var hp0=b.hp;apply_attack_damage(child,37,pl,0);boss_twin_status(b);bt_check(b.hp==hp0-37 && child.hp==b.hp,"Ice witch damage forwards to the shared boss HP");
    apply_attack_damage(b,41,pl,0);boss_twin_status(b);bt_check(child.hp==b.hp && b.hp==hp0-78,"Fire witch and ice witch display one shared life pool");
    var formations=["eight","circle","cross","dive","split","follow"],samples=[];
    for(var i=0;i<6;i++) {
        b.v2_formation=formations[i];b.boss_state="windup";b.boss_timer=100;b.v2_warning=100;b.v2_attack_age=0;b.v2_clock=0;b.v2_formation_age=0;
        var oldx=b.x,oldy=b.y,ix=child.x,iy=child.y;repeat(60)bv2_encounter_step(b,1/60);
        var distance=point_distance(oldx,oldy,b.x,b.y)+point_distance(ix,iy,child.x,child.y);bt_check(distance>1 && b.v2_hover>0 && b.v2_other_hover>0,"Coordinated airborne formation "+formations[i]+" actually moves both actors");array_push(samples,{formation:formations[i],combined_distance:distance});
    }
    boss_v2_force_attack(b,4);bt_tick(b,.2);var h=b.v2_moving_lines[0].hazard,fire=bv2_twins_origin(b,false),ice=bv2_twins_origin(b,true);
    bt_check(abs(h.g.x-fire.x)<.01 && abs(h.g.y-fire.y)<.01 && abs(h.g.radius-point_distance(fire.x,fire.y,ice.x,ice.y))<.01,"Moving pact beam geometry uses the two actual hand positions");
    var old_angle=h.g.angle;bt_tick(b,.3);fire=bv2_twins_origin(b,false);ice=bv2_twins_origin(b,true);bt_check(abs(h.g.x-fire.x)<.01 && abs(h.g.radius-point_distance(fire.x,fire.y,ice.x,ice.y))<.01,"Beam warning follows changed flight positions and true segment length");
    b.hp=10;boss_twin_status(b);var kills=global.run_boss_kills;apply_attack_damage(child,100,pl,0);boss_step(b,.01);
    bt_check(instance_number(ObjectChest)==1 && instance_number(ObjectMagnetOrb)==1 && global.run_boss_kills==kills+1,"Shared twin death produces exactly one chest and one orb");
    if(instance_exists(b))boss_v2_death_step(b,1.51);
    bt_check(!instance_exists(child) && instance_number(ObjectChest)==1 && instance_number(ObjectMagnetOrb)==1,"Shared death animation cleans the secondary witch without an independent reward");
    global.bt_metrics.formations=samples;
}
function bt_swamp_tests() {
    var b=bt_spawn("behemoth"),pl=ObjectPlayer;boss_v2_force_attack(b,2);var h=global.bv2_hazards[0];bt_contact(h);var hp0=pl.hp;bt_tick(b,h.warning+.001);var first=pl.hp;bt_tick(b,.7);bt_check(first<hp0 && pl.hp<first,"Acid puddle applies repeated actual damage over its finite lifetime");
    var age=h.age;global.game_paused=true;repeat(30)bt_tick(b,1/60);bt_check(h.age==age,"Pause stops the boss hazard clock as well as hits");global.game_paused=false;
    b=bt_spawn("behemoth");pl=ObjectPlayer;boss_v2_force_attack(b,3);h=global.bv2_hazards[1];bt_contact(h);bt_tick(b,h.warning+.001);bt_check(pl.boss_root_time>0,"Root contact creates an actual finite movement constraint");
    pl.x=1200;pl.y=1200;var x0=pl.x;movement_step(pl,1/60,true,0,4,false,false);var rooted=pl.x-x0;pl.x=x0;pl.boss_root_time=0;movement_step(pl,1/60,true,0,4,false,false);bt_check(rooted>0 && rooted<(pl.x-x0)*.4,"Root status reduces actual movement distance without permanent immobilization");
    b=bt_spawn("behemoth");pl=ObjectPlayer;repeat(12)bv2_summon(b,b.x,b.y+60);var count=0;with(ObjectMonster)if(variable_instance_exists(id,"boss_minion") && boss_minion)count++;bt_check(count==6,"Summoning cannot exceed six supporting swamp creatures");boss_cleanup(b.id);count=0;with(ObjectMonster)if(variable_instance_exists(id,"boss_minion") && boss_minion)count++;bt_check(count==0 && array_length(global.bv2_hazards)==0,"Boss cleanup removes minions and persistent hazard ownership");
    b=bt_spawn("behemoth");pl=ObjectPlayer;boss_v2_force_attack(b,5);h=global.bv2_hazards[0];bt_contact(h);pl.motion_state=player_motion_state.rising;pl.jump_height=45;hp0=pl.hp;bt_tick(b,h.warning+.001);bt_check(pl.hp==hp0,"A correctly timed jump clears the ground shockwave");
}
function bt_passive_tests() {
    bt_reset();var dependent=[206,211,212,213,217,218];
    for(var i=0;i<array_length(dependent);i++)bt_check(!spell_passive_eligible(GetSpellData(dependent[i])),"Dependent passive "+string(dependent[i])+" requires an equipped matching active");
    var definitions=spell_catalog();for(var i=0;i<array_length(definitions);i++)if(definitions[i].type==2 && !array_contains(dependent,definitions[i].id))bt_check(spell_passive_eligible(definitions[i]),"General passive "+definitions[i].name+" remains eligible");
    var candidates=[101,102,105];for(var i=0;i<3;i++){global.active_spells=[];boss_test_add_skill(candidates[i]);bt_check(spell_passive_eligible(GetSpellData(206)),"Split Runes accepts "+GetSpellData(candidates[i]).name);}
    global.active_spells=[];repeat(60){spell_choices_v2("chest");for(var i=0;i<array_length(global.spell_options);i++)bt_check(global.spell_options[i].id!=206,"Split Runes never appears without Fireball/Iceball/Barrage");global.game_paused=false;}
    var synthetic={type:2,requirements_any:[101,102],requirements_all:[103]};global.active_spells=[];boss_test_add_skill(101);bt_check(!spell_passive_eligible(synthetic),"Combined any/all requirements reject a missing mandatory active");boss_test_add_skill(103);bt_check(spell_passive_eligible(synthetic),"Combined any/all requirements accept the complete equipped set");
    bt_check(string_pos("Fireball",spell_requirement_text(GetSpellData(206)))>0 && string_pos("Iceball",spell_requirement_text(GetSpellData(206)))>0,"Dependency tooltip lists actual existing active names");
}
function bt_testmode_tests() {
    bt_reset();var first=boss_test_request("random",15,"random",775331),second=boss_test_request("random",15,"random",775331);bt_check(json_stringify(first)==json_stringify(second),"Same test seed resolves the same random boss and class");
    boss_test_apply_build(15,true,775331);var build=json_stringify({active:global.active_spells,passive:global.passive_spells});bt_reset();boss_test_apply_build(15,true,775331);bt_check(build==json_stringify({active:global.active_spells,passive:global.passive_spells}),"Random development build is valid and reproducible from its seed");
    var valid=true;for(var i=0;i<array_length(global.passive_spells);i++)if(!spell_passive_eligible(GetSpellData(global.passive_spells[i].id)))valid=false;bt_check(valid && array_length(global.active_spells)<=6 && array_length(global.passive_spells)<=6,"Test random build respects passive prerequisites and slot limits");
    bt_check(is_undefined(boss_test_request("storm_warden",5,"Sword",1337,9)),"Test mode rejects a locked minute-five attack");
    bt_check(boss_test_start("storm_warden",15,"Mage",1337,-1),"Direct Drache / minute15 / all-nine test starts through production API");var b=global.active_boss;bt_check(instance_exists(b) && b.v2_unlocked==9 && global.current_level>1 && array_length(global.active_spells)>1,"Boss test supplies an evolved player and the correct unlocked dragon pool");
    global.boss_test.invulnerable=true;var hp0=ObjectPlayer.hp;player_receive_damage(ObjectPlayer,20,"all");bt_check(ObjectPlayer.hp==hp0,"Development invulnerability is scoped to the active test");boss_test_end();reset_round();bt_check(!global.boss_test.active && global.current_level==1,"Ending boss test restores normal round progression");
    hp0=ObjectPlayer.hp;player_receive_damage(ObjectPlayer,5,"all");bt_check(ObjectPlayer.hp<hp0,"Test invulnerability cannot leak into a normal round");
    bt_reset();var mini=boss_spawn("mini_sentinel");mini.boss_timer=100;mini.boss_state="recovery";mini.mini_auto_timer=.001;boss_step(mini,.01);bt_check(array_length(global.hostile_bullets)==1 && array_length(global.boss_zones)==0,"Waldwaechter uses one ordinary automatic projectile without a floor warning");
}
function bt_warning_fps_tests() {
    var samples=[];
    for(var i=0;i<3;i++) {
        var hz=[30,60,144][i],dt=1/hz,b=bt_spawn("behemoth"),pl=ObjectPlayer,h=bv2_line(b,"swamp_test",pl.x-100,pl.y-10,pl.x+100,pl.y-10,30,1.3,.5,17,"all"),hp0=pl.hp,time=0;
        while(pl.hp==hp0 && time<1.4){b.v2_clock+=dt;bv2_hazards_step(dt);time+=dt;if(h.age<h.warning)bt_check(pl.hp==hp0,"Warning has no premature damage at "+string(hz)+" Hz");}
        bt_check(pl.hp<hp0 && time>=1.299 && time<=1.3+dt+.001,"Hazard activation and contact share the completing update at "+string(hz)+" Hz");array_push(samples,{hz:hz,warning:1.3,first_hit:time});
    }
    global.bt_metrics.countdown_fps=samples;
}
function bt_dps_window(_class,_boss,_minute,_variant=0) {
    bt_reset(_class);global.round_seconds=_minute*60;global.monster_hp_multiplier=1+_minute*.07;global.monster_damage_multiplier=1+_minute*.06;boss_test_apply_build(_minute,false,81229);
    var pl=ObjectPlayer,b=boss_spawn(_boss);b.x=pl.x+110;b.y=pl.y;b.hp=1000000;b.max_hp=1000000;if(instance_exists(b.v2_child)){b.v2_child.x=pl.x+180;b.v2_child.y=pl.y;boss_twin_status(b);}
    var configured_hp=boss_v2_definition(_boss).base_hp*b.v2_scaling.hp,start=b.hp;global.bt_bench_freeze=true;random_set_seed(93331);
    var seconds=_variant==0 ? 12 : 20;
    for(var frame=0;frame<seconds*60;frame++) {
        var attack_window=_variant==0 || (frame mod 600)<420;
        if(!attack_window)pl.weapon_cooldown=max(2,pl.weapon_cooldown);
        bt_weapon_tick();hotbar_tick_cooldowns();if(attack_window)auto_spells_step();bt_effect_tick();boss_step(b,1/60);
    }
    global.bt_bench_freeze=false;var damage=start-b.hp,dps=damage/seconds;
    return {boss:_boss,class_name:_class,minute:_minute,variant:_variant==0 ? "full_uptime" : "70_percent_new_attack_opportunities",measured_seconds:seconds,actual_damage:damage,dps:dps,configured_hp:configured_hp,analytical_ttk_seconds:configured_hp/max(.001,dps),stationary_target:true,hostile_ai_disabled:true,human_playtest:false,preset:boss_test_preset(_minute)};
}
function bt_dps_tests() {var out=[],classes=["Sword","Mage","Ranger"],ids=["storm_warden","twins","behemoth"];for(var c=0;c<3;c++)for(var b=0;b<3;b++)for(var m=0;m<3;m++)for(var v=0;v<2;v++){var sample=bt_dps_window(classes[c],ids[b],[5,10,15][m],v);array_push(out,sample);bt_check(sample.actual_damage>0,"Native production DPS "+classes[c]+" vs "+ids[b]+" minute "+string(sample.minute)+" profile "+string(v));}global.bt_metrics.dps=out;}
function bt_menu_tick() {
    if(!variable_global_exists("bt_started")){global.bt_started=true;global.bt_checks=0;global.bt_failures=[];global.bt_metrics={};global.bt_frame=0;global.bt_hold=true;global.bt_dt=1/60;global.bt_bench_freeze=false;global.bt_menu_stage=0;global.bt_stage=0;menu_mode="main";var labels=menu_labels("main");bt_check(array_length(labels)==5 && labels[3]=="Testmodus" && string_pos("Review-Center",labels[4])==1,"Main menu exposes the development entries Testmodus and Review-Center");menu_activate(3);bt_check(menu_mode=="boss_test","Boss testen opens the production development menu");return;}
    if(global.bt_menu_stage==0){global.bt_menu_stage=1;return;}
    menu_mode="main";menu_activate(0);menu_activate(0);menu_activate(0);
}
function bt_controller_tick() {
    if(global.bt_stage==0){global.bt_stage=1;if(!global.bt_capture_only){bt_catalog_tests();bt_dragon_abilities();bt_encounter_abilities("twins");bt_encounter_abilities("behemoth");bt_twins_tests();bt_swamp_tests();bt_passive_tests();bt_testmode_tests();bt_warning_fps_tests();bt_sword_regression();bt_dps_tests();}bt_reset();global.bt_frame=0;global.bt_metrics.audio=[];}
    global.bt_frame++;bt_visual_tick(global.bt_frame);if(!global.bt_capture_only)bt_audio_tick(global.bt_frame);
    if(global.bt_frame==(global.bt_capture_only ? 440 : 560)){var r={passed:array_length(global.bt_failures)==0,status:array_length(global.bt_failures)==0 ? "PASS" : "FAIL",capture_only:global.bt_capture_only,checks:global.bt_checks,failures:global.bt_failures,metrics:global.bt_metrics,scope:global.bt_capture_only ? "Native visual captures only; does not replace the full runtime assertion report." : "Native production functions in isolated deterministic states. Short damage windows use stationary targets; TTK is analytical, not human gameplay E2E."};show_debug_message("BOSS2_RESULT "+json_stringify(r));game_end();}
}
function bt_audio_tick(_f) {
    if(_f<20 || _f>139 || ((_f-20) mod 7)!=0)return;
    var index=(_f-20) div 7;if(index>=18)return;var cue=(index<9 ? "twins_" : "swamp_")+string((index mod 9)+1),asset=asset_get_index("sfx_fg_"+cue);
    bt_check(audio_exists(asset),"Actual imported Boss2 cue "+cue+" exists");fg_audio_stop_effects();variable_struct_set(global.fg_audio.last_sfx,cue,-10000);var handle=fg_sfx(cue);bt_check(handle>=0,"Native audio engine creates a real voice for "+cue);array_push(global.bt_metrics.audio,{cue:cue,created:handle>=0,frame:_f});
}
function bt_visual_tick(_f) {
    var scenes=[{at:10,id:"twins",ability:1},{at:70,id:"twins",ability:4},{at:130,id:"twins",ability:9},{at:190,id:"behemoth",ability:3},{at:250,id:"behemoth",ability:6},{at:310,id:"behemoth",ability:9},{at:370,id:"storm_warden",ability:1}];
    for(var i=0;i<array_length(scenes);i++)if(_f==scenes[i].at){var scene=scenes[i];global.bt_scene_boss=bt_spawn(scene.id);boss_v2_force_attack(global.bt_scene_boss,scene.ability);}
    if(_f>=10 && _f<430 && instance_exists(global.bt_scene_boss)) {
        var b=global.bt_scene_boss,warning=b.dragon_enabled ? b.enc_cfg.warning : b.v2_warning;bt_tick(b,warning/30);
    }
    if(_f==460){var b=bt_spawn("behemoth");boss_v2_force_attack(b,2);global.bt_perf_boss=b;for(var i=0;i<150;i++){var e=instance_create_layer(ObjectPlayer.x-330+(i mod 15)*46,ObjectPlayer.y-220+(i div 15)*44,"Instances",ObjectMonster);e.hp=100000;e.max_hp=e.hp;e.damage=0;e.base_move_speed=.8;}weather_set("heavy_rain",999);global.bt_perf=[];global.bt_perf_last=get_timer();}
    if(_f>=461 && _f<=541) {
        var now=get_timer();if(_f>481)array_push(global.bt_perf,(now-global.bt_perf_last)/1000);global.bt_perf_last=now;
        bt_tick(global.bt_perf_boss,1/60);weather_step(1/60);feedback_step(1/60);atmosphere_step(1/60);global.bt_hold=false;with(ObjectMonster)event_perform(ev_step,0);global.bt_hold=true;
        if(_f==541){var sum=0,largest=0;for(var i=0;i<array_length(global.bt_perf);i++){sum+=global.bt_perf[i];largest=max(largest,global.bt_perf[i]);}global.bt_metrics.performance={enemies:instance_number(ObjectMonster),frames:array_length(global.bt_perf),mean_frame_ms:sum/max(1,array_length(global.bt_perf)),max_frame_ms:largest,measurement:"Native get_timer frames with150 AI enemies, heavy rain and boss acid. Short sample; PNG export outside measurement."};bt_check(array_length(global.bt_perf)==60 && instance_number(ObjectMonster)==150,"Native performance sample covers60 actual frames with150 AI enemies and new boss hazards");}
    }
}
function bt_capture_menu() {
    if(!variable_global_exists("bt_menu_stage"))return;
    if(menu_mode=="boss_test" && global.bt_menu_stage==0){var s=surface_create(display_get_gui_width(),display_get_gui_height());surface_set_target(s);boss_test_menu_draw();surface_reset_target();surface_save(s,"bt2capture-test-menu.png");surface_free(s);}
}
function bt_capture_draw() {
    if(!variable_global_exists("bt_frame"))return;var f=global.bt_frame,name="";
    switch(f){case 24:name="twins-projectiles";break;case 84:name="twins-link-warning";break;case 104:name="twins-link-active";break;case 176:name="twins-nova";break;case 204:name="behemoth-roots-warning";break;case 224:name="behemoth-roots-active";break;case 294:name="behemoth-brood";break;case 343:name="behemoth-bloom-active";break;case 356:name="behemoth-bloom";break;case 404:name="dragon-fifteen-beam";break;case 542:name="crowd-boss-rain";break;}
    if(name!="" && surface_exists(application_surface))surface_save(application_surface,"bt2capture-"+name+".png");
    if(f>=430 && f<=432){var p=(f-430)*.5,s=surface_create(800,600);surface_set_target(s);draw_clear(make_color_rgb(12,18,26));var shapes=["circle","sector","line","rectangle","ring"];for(var i=0;i<5;i++){var px=140+(i mod 3)*250,py=160+(i div 3)*260,g=telegraph_make(shapes[i],px,py,90,1,20,110,32);g.elapsed=p;telegraph_draw(g,make_color_rgb(255,125,61));draw_set_color(c_white);draw_text(px-70,py+110,shapes[i]+" "+string(p*100)+"%");}surface_reset_target();surface_save(s,"bt2capture-subtle-warning-"+string(p*100)+".png");surface_free(s);}
}
