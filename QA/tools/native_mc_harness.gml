/// Isolated native fixed60Hz harness. All combat values and effects remain production.
function qa_arg(_key,_default) {
    var prefix="-qa_"+_key+"=";
    for(var i=1;i<=parameter_count();i++){var arg=parameter_string(i);if(string_pos(prefix,arg)==1)return string_delete(arg,1,string_length(prefix));}
    return _default;
}
function qa_menu_tick() {
    if(variable_global_exists("qa_started"))return;
    global.qa_started=true;global.qa_mode=qa_arg("mode","runs");global.qa_phase=qa_arg("phase","baseline");
    global.qa_runs=real(qa_arg("runs","1"));global.qa_seedstart=real(qa_arg("seed","710101"));global.qa_batch=real(qa_arg("batch","60"));global.qa_probe=real(qa_arg("probe","600"));
    global.qa_forced_persona=qa_arg("persona","cycle");global.qa_probe_class=qa_arg("class","Sword");global.qa_checkpoint_file=qa_arg("checkpoint","qa-native-checkpoints.jsonl");
    global.qa_run_index=0;global.qa_run_ready=false;global.qa_inside_tick=false;global.qa_capture_ready=false;global.qa_fixture_draws=0;
    global.qa_xaxis=0;global.qa_yaxis=0;global.qa_jump=false;global.qa_dodge=false;global.qa_mouse_x=0;global.qa_mouse_y=0;
    // room_speed is a production gameplay unit (DoT, status counters, sprite
    // clocks). Keep the native room at60Hz; accelerate only by batching ticks.
    game_set_speed(60,gamespeed_fps);
    if(global.qa_mode!="fixture")draw_enable_drawevent(false);
    menu_mode="main";menu_activate(0);menu_activate(0);menu_activate(0);
}
function qa_key(_key) {
    if(_key==vk_left || _key==ord("A"))return global.qa_xaxis<0;
    if(_key==vk_right || _key==ord("D"))return global.qa_xaxis>0;
    if(_key==vk_up || _key==ord("W"))return global.qa_yaxis<0;
    if(_key==vk_down || _key==ord("S"))return global.qa_yaxis>0;
    return false;
}
function qa_key_pressed(_key) {return (_key==vk_space && global.qa_jump) || (_key==vk_control && global.qa_dodge);}
function qa_mouse(_key){return false;}
function qa_mouse_pressed(_key){return false;}
function qa_world_collision_cache() {
    // Production master_world_ground builds this same all-room physical list in
    // Draw. Headless tests must retain that nonvisual prerequisite explicitly.
    global.master_collision_props=[];
    with(ObjectMasterScenery)if(master_prop>=8 && master_prop<=10)array_push(global.master_collision_props,id);
}
function qa_bot_observed(_entity,_reaction) {
    if(!variable_struct_exists(_entity,"qa_bot_first_seen"))_entity.qa_bot_first_seen=global.qa_ticks;
    return (global.qa_ticks-_entity.qa_bot_first_seen)/60>=_reaction;
}
function qa_mark_penalty(_g,_x,_y) {
    if(!telegraph_contains(_g,_x,_y))return 0;
    var dist=point_distance(_g.x,_g.y,_x,_y),inside=max(0,_g.radius-dist);
    if(_g.shape=="ring")inside=min(inside,max(0,dist-_g.inner));
    if(_g.shape=="sector"){
        var edge=max(0,_g.span*.5-abs(angle_difference(point_direction(_g.x,_g.y,_x,_y),_g.angle)));
        inside=min(inside,dist*sin(degtorad(min(90,edge))));
    }
    if(_g.shape=="line" || _g.shape=="rectangle"){
        var dx=_x-_g.x,dy=_y-_g.y,along=dx*lengthdir_x(1,_g.angle)+dy*lengthdir_y(1,_g.angle),across=dx*lengthdir_x(1,_g.angle+90)+dy*lengthdir_y(1,_g.angle+90);
        inside=min(max(0,_g.width*.5-abs(across)),max(0,min(along,_g.radius-along)));
    }
    return 160+inside*3;
}
function qa_bot_plan(_geometry,_remaining,_height,_policy) {
    if(!_policy.mobility)return;
    var pl=ObjectPlayer,lead=_height=="ground" ? .20 : .075;
    var kind=_height=="ground" ? "jump" : "dodge";
    if(pl.motion_state!=player_motion_state.grounded || pl.dodge_timer>0)return;
    var wait=max(0,_remaining-lead);
    if(pl.mobility_cooldown>wait || (kind=="dodge" && pl.dodge_cooldown>wait))return;
    var due=global.qa_ticks+round(wait*60);
    if(is_struct(global.qa_mobility_plan) && global.qa_mobility_plan.tick<=due)return;
    global.qa_mobility_plan={tick:due,expires:due+8,kind:kind,g:_geometry};
}
function qa_bot_apply_plan() {
    var plan=global.qa_mobility_plan;
    if(!is_struct(plan) || global.qa_ticks<plan.tick)return;
    global.qa_mobility_plan=undefined;
    var pl=ObjectPlayer;
    if(global.qa_ticks>plan.expires || (is_struct(plan.g) && !telegraph_contains(plan.g,pl.x,pl.y-10)))return;
    if(plan.kind=="jump" && pl.mobility_cooldown<=0 && pl.motion_state==player_motion_state.grounded)global.qa_jump=true;
    if(plan.kind=="dodge" && pl.mobility_cooldown<=0 && pl.dodge_cooldown<=0 && pl.motion_state==player_motion_state.grounded)global.qa_dodge=true;
}
function qa_reset(_class,_seed,_persona) {
    global.qa_inside_tick=true;
    with(ObjectChest)instance_destroy();with(ObjectMagnetOrb)instance_destroy();with(ObjectSkeletonRemains)instance_destroy();
    random_set_seed(_seed);global.selected_character=_class;global.selected_level=0;reset_round();
    var pl=ObjectPlayer;pl.x=2112;pl.y=1952;pl.pickup_prev_x=pl.x;pl.pickup_prev_y=pl.y;pl.menu_input_guard=0;pl.facing_direction=0;pl.visual_facing_angle=0;
    pl.speed=0;pl.hspeed=0;pl.vspeed=0;camera_set_view_pos(pl.camera,pl.x-400,pl.y-300);qa_world_collision_cache();
    with(ObjectSpawner){population_timer=0;runtime_cap=180;frame_ms=16.7;slow_seconds=0;recover_seconds=0;}
    global.qa_class=_class;global.qa_seed=_seed;global.qa_persona=_persona;global.qa_ticks=0;global.qa_choices=[];global.qa_bosses=[];global.qa_seen_boss=noone;
    global.qa_bot_rng=(_seed mod 1000000)+1;global.qa_bot_clock=0;global.qa_bot_direction=0;global.qa_xaxis=0;global.qa_yaxis=0;
    global.qa_jump=false;global.qa_dodge=false;global.qa_mouse_x=pl.x+100;global.qa_mouse_y=pl.y;global.qa_mobility_plan=undefined;global.qa_policy_version="visible-countdown-v2";
    global.qa_run_wall=get_timer();global.qa_min_hp=pl.hp;global.qa_run_ready=true;global.qa_timecourse=[];global.qa_sample_index=0;
    global.qa_policy={reaction:_persona=="beginner" ? .65 : (_persona=="average" ? .30 : .12),avoid:_persona=="beginner" ? .65 : (_persona=="average" ? 1 : 1.2),mobility:_persona!="beginner"};
    global.qa_isolated_boss=false;global.qa_bench_freeze=false;qa_metrics_reset(_class,_seed,_persona);global.qa_inside_tick=false;
}
function qa_bot_random() {global.qa_bot_rng=(global.qa_bot_rng*48271) mod 2147483647;return global.qa_bot_rng/2147483647;}
function qa_visible_point(_x,_y,_pad=0) {var r=combat_view_rect(-_pad);return point_in_rectangle(_x,_y,r.left,r.top,r.right,r.bottom);}
function qa_bot_step(_policy) {
    global.qa_jump=false;global.qa_dodge=false;global.qa_bot_clock-=1/60;
    if(variable_struct_exists(_policy,"noresponse") && _policy.noresponse){global.qa_xaxis=0;global.qa_yaxis=0;return;}
    qa_bot_apply_plan();
    if(global.qa_bot_clock>0)return;
    global.qa_bot_clock=_policy.reaction;
    var pl=ObjectPlayer,types=[ObjectMonster,ObjectBossMonster],enemies=[],nearest=noone,best=1000000;
    for(var t=0;t<2;t++)for(var i=0;i<instance_number(types[t]);i++){
        var e=instance_find(types[t],i);if(e.hp<=0 || !combat_target_visible(e))continue;
        array_push(enemies,e);var dist=combat_body_distance(e,pl.x,pl.y);
        if(dist<best){best=dist;nearest=e;}
    }
    var goal_x=pl.x+lengthdir_x(180,global.qa_bot_direction),goal_y=pl.y+lengthdir_y(180,global.qa_bot_direction);
    var coin=noone,coin_best=1000000;
    for(var i=0;i<instance_number(ObjectCoin);i++){var c=instance_find(ObjectCoin,i);if(!qa_visible_point(c.x,c.y))continue;var d=point_distance(pl.x,pl.y,c.x,c.y);if(d<coin_best){coin=c;coin_best=d;}}
    if(instance_exists(coin)){goal_x=coin.x;goal_y=coin.y;}
    // Visible rewards are goals just like a human-readable chest/orb marker.
    for(var t=0;t<2;t++){var obj=t==0 ? ObjectMagnetOrb : ObjectChest;for(var i=0;i<instance_number(obj);i++){var item=instance_find(obj,i);if(qa_visible_point(item.x,item.y) && point_distance(pl.x,pl.y,item.x,item.y)<350){goal_x=item.x;goal_y=item.y;}}}
    var ideal=global.qa_class=="Sword" ? 74 : (global.qa_class=="Mage" ? 190 : 250);
    if(instance_exists(nearest) && (!instance_exists(coin) || coin_best>160)) {
        var approach=point_direction(pl.x,pl.y,nearest.x,nearest.y);
        goal_x=nearest.x-lengthdir_x(ideal,approach);goal_y=nearest.y-lengthdir_y(ideal,approach);
        if(best<ideal+28 && best>ideal-35){goal_x=pl.x+lengthdir_x(130,approach+90);goal_y=pl.y+lengthdir_y(130,approach+90);}
    }
    var best_score=-1000000,best_angle=global.qa_bot_direction,danger_here=0;
    // Decisions use positions/velocity and presently visible marks only. No boss
    // hidden target, future rotation, cooldown, RNG or unreleased projectile reads.
    for(var candidate=0;candidate<8;candidate++) {
        var angle=candidate*45,reach=pl.moveSpeed*60*_policy.reaction+24;
        var px=pl.x+lengthdir_x(reach,angle),py=pl.y+lengthdir_y(reach,angle);
        var candidate_score=(point_distance(pl.x,pl.y,goal_x,goal_y)-point_distance(px,py,goal_x,goal_y))*.8;
        if(px<35 || py<35 || px>room_width-35 || py>room_height-35)candidate_score-=800;
        for(var segment=1;segment<=4;segment++)if(scenery_point_blocked(lerp(pl.x,px,segment/4),lerp(pl.y,py,segment/4)-6,12)){candidate_score-=600;break;}
        for(var i=0;i<array_length(enemies);i++){
            var e=enemies[i],dist=combat_body_distance(e,px,py),now=combat_body_distance(e,pl.x,pl.y);
            var safe=e.object_index==ObjectBossMonster ? 65 : (global.qa_class=="Sword" ? 45 : 80);
            candidate_score-=max(0,safe-dist)*_policy.avoid*2.4;
            if(now<48 && e.damage>0){
                danger_here=max(danger_here,1);
                if(candidate==0){var strike_wait=variable_instance_exists(e,"skeleton_attacking") && e.skeleton_attacking ? max(0,.20-e.skeleton_attack_time) : .20;qa_bot_plan(undefined,strike_wait,"ground",_policy);}
            }
        }
        for(var i=0;i<array_length(global.hostile_bullets);i++) {
            var bullet=global.hostile_bullets[i];if(!qa_visible_point(bullet.x,bullet.y) || !qa_bot_observed(bullet,_policy.reaction))continue;
            var tx=bullet.x+bullet.vx*min(.35,_policy.reaction),ty=bullet.y+bullet.vy*min(.35,_policy.reaction);
            var near=boss_point_segment_distance(px,py-10,bullet.x,bullet.y,tx,ty);
            candidate_score-=max(0,bullet.radius+24-near)*5*_policy.avoid;
            if(point_distance(pl.x,pl.y-10,bullet.x,bullet.y)<75){
                danger_here=max(danger_here,2);
                if(candidate==0){var velocity_squared=bullet.vx*bullet.vx+bullet.vy*bullet.vy,arrival=velocity_squared>0 ? ((pl.x-bullet.x)*bullet.vx+(pl.y-10-bullet.y)*bullet.vy)/velocity_squared : 0;
                    if(arrival>=0 && arrival<=.4 && boss_point_segment_distance(pl.x,pl.y-10,bullet.x,bullet.y,bullet.x+bullet.vx*.4,bullet.y+bullet.vy*.4)<=bullet.radius+pl.contact_radius+6)qa_bot_plan(undefined,arrival,"high",_policy);}
            }
        }
        for(var i=0;i<array_length(global.bv2_hazards);i++) {
            var h=global.bv2_hazards[i],g=h.g;
            if(!qa_visible_point(g.x,g.y,g.radius) || !qa_bot_observed(h,_policy.reaction))continue;
            if(h.age>=h.warning+h.active)continue;
            candidate_score-=qa_mark_penalty(g,px,py-10)*_policy.avoid;
            if(telegraph_contains(g,pl.x,pl.y-10)){danger_here=max(danger_here,2);if(candidate==0)qa_bot_plan(g,max(0,h.warning-h.age),h.height,_policy);}
        }
        for(var i=0;i<array_length(global.boss_zones);i++) {
            var z=global.boss_zones[i];if(!qa_visible_point(z.x,z.y,z.radius) || z.age>=z.warning+z.active || !qa_bot_observed(z,_policy.reaction))continue;
            var zg=telegraph_make("circle",z.x,z.y,z.radius,z.warning);
            candidate_score-=qa_mark_penalty(zg,px,py-10)*_policy.avoid;
            if(point_distance(pl.x,pl.y-10,z.x,z.y)<z.radius+12){danger_here=max(danger_here,2);if(candidate==0)qa_bot_plan(zg,max(0,z.warning-z.age),z.kind=="lightning" ? "all" : "ground",_policy);}
        }
        for(var i=0;i<instance_number(ObjectBossMonster);i++) {
            var dragon=instance_find(ObjectBossMonster,i);
            if(!dragon.dragon_enabled || !variable_instance_exists(dragon,"enc_geometry"))continue;
            if(dragon.boss_state!="windup" && dragon.boss_state!="active")continue;
            var kind=dragon.boss_cast,dg=dragon.enc_geometry;
            // Same visibility gates as dragon_encounter_draw: ordinary wind,
            // void and volley casts have no invisible floor mark to inspect.
            if(!array_contains(["meteor","stomp","void","volley","wind"],kind) && qa_visible_point(dg.x,dg.y,dg.radius) && qa_bot_observed(dg,_policy.reaction)) {
                candidate_score-=qa_mark_penalty(dg,px,py-10)*_policy.avoid;
                if(telegraph_contains(dg,pl.x,pl.y-10)){danger_here=max(danger_here,2);if(candidate==0)qa_bot_plan(dg,max(0,dragon.enc_cfg.warning-dragon.dragon_state_age),dragon.enc_cfg.height,_policy);}
            }
            for(var j=0;j<array_length(dragon.enc_zones);j++) {
                var dz=dragon.enc_zones[j];
                if(!qa_visible_point(dz.x,dz.y,dragon.enc_cfg.radius) || !qa_bot_observed(dz,_policy.reaction))continue;
                candidate_score-=qa_mark_penalty(dz.g,px,py-10)*_policy.avoid;
                if(telegraph_contains(dz.g,pl.x,pl.y-10)){danger_here=max(danger_here,2);if(candidate==0)qa_bot_plan(dz.g,max(0,dz.warning-dz.age),dragon.enc_cfg.height,_policy);}
            }
        }
        // Stable per-run tie jitter is bot-owned and never consumes gameplay RNG.
        candidate_score+=qa_bot_random()*5;
        if(candidate_score>best_score){best_score=candidate_score;best_angle=angle;}
    }
    global.qa_bot_direction=best_angle;global.qa_xaxis=round(lengthdir_x(1,best_angle));global.qa_yaxis=round(lengthdir_y(1,best_angle));
    global.qa_mouse_x=instance_exists(nearest) ? nearest.x : pl.x+lengthdir_x(100,best_angle);
    global.qa_mouse_y=instance_exists(nearest) ? nearest.y : pl.y+lengthdir_y(100,best_angle);
    // Execute a countdown plan due on this tick; future plans remain timed
    // inputs, never early invulnerability. ALL/high attacks never trigger jump.
    qa_bot_apply_plan();
}
function qa_resolve_choice() {
    if(global.game_over || (!global.levelup_active && !global.chest_collected))return;
    var opts=global.spell_options,index=0,best=-1000000;
    for(var i=0;i<array_length(opts);i++) {
        var d=GetSpellData(opts[i].id),candidate_score=qa_bot_random()*3;
        if(is_struct(d) && global.qa_persona!="beginner") {
            candidate_score+=d.type==SPELL_TYPE.ACTIVE && array_length(global.active_spells)<4 ? 2 : 0;
            candidate_score+=spell_level(d.id)>0 ? .75 : 0;
            if(ObjectPlayer.hp<ObjectPlayer.max_hp*.55 && array_contains([106,205,214,215,201],d.id))candidate_score+=2;
            if(global.qa_class=="Ranger" && array_contains([204,202,206,208],d.id))candidate_score+=.5;
        }
        if(candidate_score>best){best=candidate_score;index=i;}
    }
    var offered=[];for(var i=0;i<array_length(opts);i++)array_push(offered,opts[i].id);
    if(array_length(opts)>0){learn_spell(opts[index].id);array_push(global.qa_choices,{seconds:global.round_seconds,level:global.current_level,offered:offered,chosen:opts[index].id});}
    global.choice_open=false;global.choice_mouse_armed=false;global.chest_collected=false;global.levelup_active=false;global.game_paused=false;
    instance_activate_all();global.pause_initialized=false;global._ui_hover_index=-1;global.start_choice_pending=false;
    global.next_levelup_time=global.round_seconds+progression_config().min_gap;ObjectPlayer.mouse_move_armed=false;ObjectPlayer.menu_input_guard=1;apply_passives(ObjectPlayer);
}
function qa_world_tick() {
    global.qa_inside_tick=true;qa_resolve_choice();
    if(global.game_over){global.qa_inside_tick=false;return;}
    qa_bot_step(global.qa_policy);
    with(ObjectController)qa_controller_production_step();
    with(ObjectPlayer)event_perform(ev_step,0);
    if(!global.qa_isolated_boss)with(ObjectSpawner)event_perform(ev_step,0);
    with(ObjectMonster)event_perform(ev_step,0);
    with(ObjectBossMonster)event_perform(ev_step,0);
    with(ObjectFireball)event_perform(ev_step,0);with(ObjectIceball)event_perform(ev_step,0);with(ObjectLightningball)event_perform(ev_step,0);with(ObjectSwordHitbox)event_perform(ev_step,0);
    with(ObjectCoin)event_perform(ev_step,0);with(ObjectChest)event_perform(ev_step,0);with(ObjectMagnetOrb)event_perform(ev_step,0);with(ObjectSkeletonRemains)event_perform(ev_step,0);
    qa_dispatch_collisions();qa_resolve_choice();global.qa_ticks++;global.qa_min_hp=min(global.qa_min_hp,ObjectPlayer.hp);
    qa_track_boss();qa_metrics_tick(1/60);qa_sample_stage();global.qa_inside_tick=false;
}
function qa_sample_stage() {
    var points=[60,180,300,600,900,1200,1500,1800];
    if(global.qa_isolated_boss || global.qa_sample_index>=array_length(points) || global.round_seconds+.00001<points[global.qa_sample_index])return;
    var count=0,hp_sum=0,attack_sum=0;
    with(ObjectMonster)if(hp>0 && !boss_is_actor(id)){count++;hp_sum+=hp;attack_sum+=damage;}
    var m=qa_metrics_export(),steps=0;
    for(var i=0;i<array_length(global.active_spells);i++)steps+=global.active_spells[i].level;
    for(var i=0;i<array_length(global.passive_spells);i++)steps+=global.passive_spells[i].level;
    array_push(global.qa_timecourse,{seconds:points[global.qa_sample_index],level:global.current_level,hp:ObjectPlayer.hp,max_hp:ObjectPlayer.max_hp,
        kills:global.run_kills,bosses:global.run_boss_kills,ability_steps:steps,active_count:array_length(global.active_spells),passive_count:array_length(global.passive_spells),
        damage_out:m.damage_out,damage_in:m.damage_in,sources:variable_clone(m.sources),enemy_count:count,mean_enemy_remaining_hp:hp_sum/max(1,count),mean_enemy_attack_damage:attack_sum/max(1,count)});
    global.qa_sample_index++;
}
function qa_dispatch_collisions() {
    // place_meeting/instance_place_list use the exact GameMaker sprite masks.
    // Skeleton's wider43px sword window is already dispatched by its real Step.
    with(ObjectPlayer){var types=[ObjectMonster,ObjectBossMonster];for(var t=0;t<2;t++)for(var i=0;i<instance_number(types[t]);i++){var e=instance_find(types[t],i);if(place_meeting(x,y,e))player_contact(id,e);}}
    with(ObjectCoin)if(place_meeting(x,y,ObjectPlayer))event_perform(ev_collision,ObjectPlayer);
    with(ObjectMagnetOrb)if(place_meeting(x,y,ObjectPlayer))magnet_collect(id,ObjectPlayer,true);
    // Projectile monster Collision files are unregistered legacy orphans. Actual
    // production projectile Steps perform their own swept hit tests above.
}
function qa_track_boss() {
    var b=instance_exists(global.active_boss) ? global.active_boss : noone;
    if(instance_exists(b) && b!=global.qa_seen_boss){global.qa_seen_boss=b;array_push(global.qa_bosses,{boss:b.boss_data.id,started:global.round_seconds,ended:-1,defeated:false,hp_start:b.max_hp,hp_remaining:b.hp});}
    if(array_length(global.qa_bosses)>0){var entry=global.qa_bosses[array_length(global.qa_bosses)-1];if(entry.ended<0){if(instance_exists(global.qa_seen_boss)){entry.hp_remaining=global.qa_seen_boss.hp;if(entry.hp_remaining<=0){entry.ended=global.round_seconds;entry.defeated=true;}}else {entry.ended=global.round_seconds;entry.defeated=true;}}}
}
function qa_state_hash() {
    var pl=ObjectPlayer,s={ticks:global.qa_ticks,x:pl.x,y:pl.y,hp:pl.hp,level:global.current_level,xp:global.coin_xp_earned,coins:global.coins,kills:global.run_kills,bosses:global.run_boss_kills,
        motion:pl.motion_state,jump_time:pl.jump_time,dodge_timer:pl.dodge_timer,dodge_cooldown:pl.dodge_cooldown,mobility_cooldown:pl.mobility_cooldown,
        weapon_cooldown:pl.weapon_cooldown,class_pending:pl.class_pending,class_combo:pl.class_combo_index,sword_clock:pl.sword_combo_clock,bot_rng:global.qa_bot_rng,
        choice_rng:global.choice_rng,boss_rng:global.boss_rng,active:global.active_spells,passive:global.passive_spells,offers:global.qa_choices,
        class_effects:global.class_effects,spell_fields:global.spell_fields,hostile_bullets:global.hostile_bullets,boss_zones:global.boss_zones,bv2_hazards:global.bv2_hazards,enemies:[],coins_pos:[],shots:[]};
    var types=[ObjectMonster,ObjectBossMonster];for(var t=0;t<2;t++)for(var i=0;i<instance_number(types[t]);i++){var e=instance_find(types[t],i);array_push(s.enemies,{t:t,x:e.x,y:e.y,hp:e.hp,slow:e.slow_time,burn:e.burn_time});}
    for(var i=0;i<instance_number(ObjectCoin);i++){var c=instance_find(ObjectCoin,i);array_push(s.coins_pos,[c.x,c.y,c.magnetized]);}
    var kinds=[ObjectFireball,ObjectIceball,ObjectLightningball];for(var t=0;t<3;t++)for(var i=0;i<instance_number(kinds[t]);i++){var p=instance_find(kinds[t],i);array_push(s.shots,[t,p.x,p.y,p.lifetime]);}
    return md5_string_utf8(json_stringify(s));
}
function qa_export(_complete,_reason) {
    var row={run_id:global.qa_phase+"-"+global.qa_class+"-"+string(global.qa_seed)+"-"+global.qa_persona,seed:global.qa_seed,class_name:global.qa_class,persona:global.qa_persona,
        completed:_complete,end_reason:_reason,simulation_version:"native-fixed60-v2",policy_version:global.qa_policy_version,ticks:global.qa_ticks,seconds:global.round_seconds,level:global.current_level,kills:global.run_kills,bosses_defeated:global.run_boss_kills,
        hp:ObjectPlayer.hp,max_hp:ObjectPlayer.max_hp,min_hp:global.qa_min_hp,xp_earned:global.coin_xp_earned,coins:global.coins,active:global.active_spells,passive:global.passive_spells,
        offers_choices:global.qa_choices,boss_encounters:global.qa_bosses,run_stats:global.run_spell_stats,progression_samples:global.progression_samples,timecourse:global.qa_timecourse,
        metrics:qa_metrics_export(),state_hash:qa_state_hash(),batch_size:global.qa_batch,logical_hz:60,native_room_speed:room_speed,
        physical_scenery_count:array_length(global.master_collision_props),wall_seconds:(get_timer()-global.qa_run_wall)/1000000};
    show_debug_message("QA_MC_ROW "+json_stringify(row));
    var f=file_text_open_append(global.qa_checkpoint_file);file_text_write_string(f,json_stringify(row));file_text_writeln(f);file_text_close(f);
}
function qa_controller_tick() {
    if(!variable_global_exists("qa_started"))return;
    if(global.qa_mode=="boss"){qa_boss_suite_step();return;}
    if(global.qa_mode=="bench"){qa_bench_suite_step();return;}
    if(!global.qa_run_ready){var classes=["Sword","Mage","Ranger"],personas=["beginner","average","experienced"],index=global.qa_run_index;
        var chosen_class=global.qa_mode=="validation" ? global.qa_probe_class : classes[index mod 3];
        qa_reset(chosen_class,global.qa_seedstart+(index div 3),global.qa_forced_persona=="cycle" ? personas[(index div 3) mod 3] : global.qa_forced_persona);}
    if(global.qa_mode=="fixture"){qa_fixture_step();return;}
    for(var i=0;i<global.qa_batch;i++) {
        qa_world_tick();var complete=global.game_over || global.qa_ticks>=108000;
        if(complete || (global.qa_mode=="validation" && global.qa_ticks>=global.qa_probe)) {
            qa_export(complete,global.game_over ? "death" : (complete ? "survived_1800_seconds_censored" : "validation_probe"));
            global.qa_run_ready=false;global.qa_run_index++;
            var limit=global.qa_mode=="validation" ? 1 : global.qa_runs*3;
            if(global.qa_run_index>=limit){show_debug_message("QA_MC_DONE "+json_stringify({runs:global.qa_run_index,mode:global.qa_mode}));game_end();}
            return;
        }
    }
}
function qa_fixture_step() {
    if(global.qa_ticks==0){
        global.qa_inside_tick=true;var pl=ObjectPlayer;
        var dot=instance_create_layer(pl.x+300,pl.y,"Instances",ObjectMonster);dot.hp=10000;dot.max_hp=dot.hp;dot.burn_dps=60;dot.burn_time=60;dot.burn_spell_id=101;
        repeat(60)with(dot)event_perform(ev_step,0);
        var dot_loss=10000-dot.hp;with(dot)instance_destroy();
        var status_boss=boss_spawn("mini_sentinel");status_boss.hp=10000;status_boss.max_hp=10000;status_boss.burn_time=60;status_boss.burn_dps=60;status_boss.burn_spell_id=101;status_boss.slow_time=60;status_boss.shock_time=60;
        global.qa_bench_freeze=true;repeat(60)boss_step(status_boss,1/60);global.qa_bench_freeze=false;
        var boss_dot_loss=10000-status_boss.hp,status_left=status_boss.slow_time+status_boss.shock_time+status_boss.burn_time;with(status_boss)instance_destroy();boss_system_reset();
        var e=population_spawn_enemy(pl.x+27,pl.y);e.hp=10000;e.max_hp=e.hp;e.skeleton_attacking=true;e.skeleton_attack_time=.20;
        var before=pl.hp;with(e)event_perform(ev_step,0);var contact=pl.hp<before;
        var coin=instance_create_layer(pl.x,pl.y-18,"Instances",ObjectCoin),xp=global.coin_xp_earned;
        qa_dispatch_collisions();var mask_coin=global.coin_xp_earned==xp+1;
        var scenery_pass=false;
        if(array_length(global.master_collision_props)>0){var prop=global.master_collision_props[0];scenery_pass=scenery_point_blocked(prop.x+(prop.master_prop==9 ? 70*prop.image_xscale : 0),prop.y-6*prop.image_yscale,0);}
        global.qa_fixture_report={contact_hp_loss:before-pl.hp,contact_pass:contact,coin_mask_pass:mask_coin,player_mask:[pl.bbox_left-pl.x,pl.bbox_top-pl.y,pl.bbox_right-pl.x,pl.bbox_bottom-pl.y],
            native_room_speed:room_speed,logical_hz:60,monster_dot_60dps_one_second:dot_loss,boss_dot_60dps_one_second:boss_dot_loss,status_frames_remaining:status_left,
            clock_pass:room_speed==60 && abs(dot_loss-60)<.001 && abs(boss_dot_loss-60)<.001 && abs(status_left)<.001,
            physical_scenery_count:array_length(global.master_collision_props),scenery_footprint_pass:scenery_pass};
        global.qa_inside_tick=false;
    }
    qa_world_tick();
    if(global.qa_ticks==60){global.qa_capture_ready=true;show_debug_message("QA_MC_FIXTURE "+json_stringify(global.qa_fixture_report));}
    if(global.qa_ticks>=64){qa_export(false,"rendered_collision_fixture");show_debug_message("QA_MC_DONE "+json_stringify({fixture:global.qa_fixture_report}));game_end();}
}
function qa_capture_draw() {
    if(!variable_global_exists("qa_capture_ready") || !global.qa_capture_ready)return;
    if(surface_exists(application_surface)){surface_save(application_surface,"qa-mc-capture-collision-fixture.png");global.qa_capture_ready=false;}
}
