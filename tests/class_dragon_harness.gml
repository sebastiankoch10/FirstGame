/// Isolated native VM checks. No test code is installed in the normal game.
function cd_check(_ok,_label) {global.cd_checks++;if(!_ok){array_push(global.cd_failures,_label);show_debug_message("CD FAIL "+_label);}else show_debug_message("CD PASS "+_label);}
function cd_clear() {
    with(ObjectMonster)instance_destroy();with(ObjectBossMonster)instance_destroy();with(ObjectCoin)instance_destroy();with(ObjectChest)instance_destroy();with(ObjectMagnetOrb)instance_destroy();
    with(ObjectLightningball)instance_destroy();with(ObjectFireball)instance_destroy();with(ObjectIceball)instance_destroy();with(ObjectSwordHitbox)instance_destroy();with(ObjectSkeletonRemains)instance_destroy();
}
function cd_pos(_x=2048,_y=2048) {var pl=ObjectPlayer;pl.x=_x;pl.y=_y;pl.pickup_prev_x=_x;pl.pickup_prev_y=_y;pl.motion_state=0;pl.dodge_timer=0;pl.jump_height=0;camera_set_view_pos(pl.camera,_x-400,_y-300);}
function cd_reset(_class="Sword") {cd_clear();global.selected_character=_class;reset_round();cd_pos();ObjectSpawner.population_timer=999;global.cd_dt=1/60;global.class_effects=[];global.hostile_bullets=[];global.boss_zones=[];}
function cd_enemy(_x,_y,_hp=100000) {var e=instance_create_layer(_x,_y,"Instances",ObjectMonster);e.hp=_hp;e.max_hp=_hp;e.damage=0;e.base_move_speed=0;return e;}
function cd_entry(_sid,_level) {var d=GetSpellData(_sid);return {id:_sid,name:d.name,type:d.type==1 ? "active" : "passive",level:_level,cooldown:d.type==1 ? d.cooldown : 0,cooldown_timer:0};}
function cd_effect_tick(_dt=1/60) {class_effects_step(_dt);spell_v2_step(_dt);var hold=global.cd_hold;global.cd_hold=false;with(ObjectFireball)event_perform(ev_step,0);with(ObjectIceball)event_perform(ev_step,0);with(ObjectLightningball)event_perform(ev_step,0);with(ObjectSwordHitbox)event_perform(ev_step,0);global.cd_hold=hold;}
function cd_weapon_tick() {with(ObjectPlayer)weapon_auto_step();}
function cd_projectiles() {return instance_number(ObjectLightningball);}
function cd_sword_regression() {
    cd_reset("Sword");var pl=ObjectPlayer,e=cd_enemy(pl.x+70,pl.y);pl.player_power=2;var start=e.hp;
    repeat(4){cd_weapon_tick();with(ObjectSwordHitbox)event_perform(ev_step,0);}cd_check(e.hp==start,"Unchanged sword combo retains harmless preparation");
    cd_weapon_tick();with(ObjectSwordHitbox)event_perform(ev_step,0);var first=start-e.hp;
    repeat(18){cd_weapon_tick();with(ObjectSwordHitbox)event_perform(ev_step,0);}var second=start-e.hp-first;
    repeat(20){cd_weapon_tick();with(ObjectSwordHitbox)event_perform(ev_step,0);}var third=start-e.hp-first-second;
    cd_check(first==11 && second==13 && third==19,"Sword original three-hit combo damage remains eleven/thirteen/nineteen");global.cd_metrics.sword_combo=[first,second,third];
}
function cd_mage_tests() {
    cd_reset("Mage");var pl=ObjectPlayer,e=cd_enemy(pl.x+105,pl.y),stages=[],outcomes=[];
    for(var step=1;step<=5;step++) {
        var previous=pl.class_combo_index,guard=0;
        while(pl.class_combo_index==previous && guard++<200)cd_weapon_tick();
        var stage=pl.class_combo_index,expected=((step-1) mod 4)+1;array_push(stages,stage);
        cd_check(stage==expected && pl.class_pending==expected,"Mage exact queued combo step "+string(step));
        var hp0=e.hp,shots0=cd_projectiles();
        var facing=pl.attack_direction;pl.facing_direction=pl.facing_direction+180;
        repeat(max(0,pl.class_release-1))cd_weapon_tick();
        cd_check(e.hp==hp0 && pl.class_pending==expected,"Mage preparation cannot damage early or reset with direction change "+string(step));
        cd_weapon_tick();
        cd_check(pl.class_pending==0 && pl.class_combo_index==expected && pl.attack_direction==facing,"Mage release occurs once without changing queued direction "+string(step));
        if(expected==1)cd_check(cd_projectiles()==shots0+1,"Mage first attack creates exactly one crystal projectile");
        if(expected==4) {
            var star=global.class_effects[array_length(global.class_effects)-1];
            cd_check(star.kind=="mage_star" && star.sx!=star.x && star.sy!=star.y && star.age==0,"Mage star has separate launch and ground target coordinates");
            repeat(50)cd_effect_tick();cd_check(e.hp==hp0,"Mage ballistic star cannot damage during the flight before implosion");
        }
        repeat(90)cd_effect_tick();
        cd_check(e.hp<hp0,"Mage actual HP damage from combo step "+string(expected));
        array_push(outcomes,{step:expected,damage:hp0-e.hp});
        var current_hp=e.hp;repeat(20)cd_effect_tick();cd_check(e.hp==current_hp,"Mage expired effect cannot damage repeatedly "+string(expected));
    }
    global.cd_metrics.mage={stages:stages,outcomes:outcomes};
    cd_check(array_length(global.active_spells)==0,"Mage automatic start weapon consumes no active spell slot");
}
function cd_ranger_tests() {
    cd_reset("Ranger");var pl=ObjectPlayer,e=cd_enemy(pl.x+105,pl.y),counts=[],outcomes=[];
    for(var step=1;step<=13;step++) {
        var previous=pl.class_combo_index,guard=0;while(pl.class_combo_index==previous && guard++<150)cd_weapon_tick();
        var stage=pl.class_combo_index,expected=((step-1) mod 12)+1,hp0=e.hp,shots0=cd_projectiles();
        pl.facing_direction+=45;while(pl.class_pending>0)cd_weapon_tick();
        var count=cd_projectiles()-shots0,wanted=expected==3 ? 3 : (expected==9 ? 5 : (expected==12 ? 0 : 1));array_push(counts,count);
        cd_check(stage==expected && count==wanted,"Ranger exact cycle step/projectile count "+string(step)+" expected "+string(wanted));
        if(expected==12)cd_check(array_length(global.class_effects)>0 && global.class_effects[0].kind=="ranger_rain","Ranger step twelve creates the actual rain effect");
        repeat(90)cd_effect_tick();cd_check(e.hp<hp0,"Ranger step "+string(expected)+" produces actual damage");array_push(outcomes,{step:expected,projectiles:count,damage:hp0-e.hp});
        with(ObjectLightningball)instance_destroy();global.class_effects=[];
    }
    global.cd_metrics.ranger={counts:counts,outcomes:outcomes};cd_check(array_length(global.active_spells)==0,"Ranger automatic start weapon consumes no active spell slot");
    cd_reset("Ranger");e=cd_enemy(ObjectPlayer.x+100,ObjectPlayer.y);with(ObjectPlayer)weapon_auto_step();var index=ObjectPlayer.class_combo_index;
    repeat(60){cd_weapon_tick();cd_effect_tick();}cd_check(ObjectPlayer.class_combo_index>index,"Ranger native cooldown advances the next step automatically");
}
function cd_geometry_tests() {
    var shapes=["circle","sector","line","rectangle","ring"];
    for(var i=0;i<array_length(shapes);i++) {
        var g=telegraph_make(shapes[i],300,300,100,2,30,100,30);
        for(var n=0;n<=4;n++) {
            g.elapsed=n*.5;var actual_progress=telegraph_progress(g),actual_ready=telegraph_ready(g),expected_ready=(n==4);
            // Quarter fractions are exactly representable; a strict '< 1e-5' test
            // is false even for zero error under GameMaker's default epsilon.
            var correct_progress=(actual_progress==n*.25),correct_ready=(actual_ready==expected_ready);
            show_debug_message("COUNTDOWN_SCALAR "+shapes[i]+" elapsed="+string(g.elapsed)+" progress="+string(actual_progress)+" ready="+string(actual_ready)+" expected="+string(n*.25)+"/"+string(expected_ready));
            cd_check(correct_progress && correct_ready,"Countdown "+shapes[i]+" fraction "+string(n*25));
        }
        cd_check(!telegraph_contains(g,600,600),"Countdown "+shapes[i]+" excludes outside hitbox");
    }
    var circle=telegraph_make("circle",0,0,100,1),ring=telegraph_make("ring",0,0,100,1,0,360,20),line=telegraph_make("line",0,0,100,1,90,0,20),sector=telegraph_make("sector",0,0,100,1,0,90);
    cd_check(telegraph_contains(circle,0,0) && !telegraph_contains(circle,101,0),"Circle exact radius and center");
    cd_check(!telegraph_contains(ring,0,0) && telegraph_contains(ring,90,0),"Ring actual hitbox keeps its center safe");
    cd_check(telegraph_contains(line,0,-50) && !telegraph_contains(line,11,-50),"Rotated line actual width matches drawing");
    cd_check(telegraph_contains(sector,50,0) && !telegraph_contains(sector,-50,0),"Sector actual angle matches drawing");
}
function cd_boss_fixture(_kind,_phase=1) {
    cd_reset();var pl=ObjectPlayer,b=boss_spawn("storm_warden");b.x=pl.x+245;b.y=pl.y+200;b.boss_phase=_phase;pl.max_hp=10000;pl.__base_max_hp=10000;pl.hp=10000;global.monster_damage_multiplier=1;dragon_attack_begin(b,_kind);return b;
}
function cd_beam_timing() {
    var hz_values=[30,60,144],samples=[];
    for(var h=0;h<3;h++) {
        var hz=hz_values[h],dt=1/hz,b=cd_boss_fixture("beam"),pl=ObjectPlayer,g=b.enc_geometry;pl.x=g.x+lengthdir_x(120,g.angle);pl.y=g.y+lengthdir_y(120,g.angle)+10;
        var before=pl.hp,t=0,first_damage=-1,guard=0;
        while(t<b.enc_cfg.warning+dt*2 && guard++<400) {
            var age=b.dragon_state_age;boss_step(b,dt);t+=dt;
            if(b.boss_state=="windup")cd_check(pl.hp==before,"Beam harmless before countdown complete at "+string(hz)+" Hz frame "+string(guard));
            if(pl.hp<before){first_damage=t;break;}
        }
        cd_check(first_damage>=b.enc_cfg.warning-.000001 && first_damage<=b.enc_cfg.warning+dt+.000001 && b.boss_state=="active","Beam fill reaches one and deals contact damage in the same update at "+string(hz)+"Hz");
        array_push(samples,{hz:hz,warning:b.enc_cfg.warning,first_contact_damage_time:first_damage,dt:dt});
    }
    var b=cd_boss_fixture("beam"),pl=ObjectPlayer;boss_step(b,.3);var age=b.dragon_state_age,timer=b.boss_timer,hp0=pl.hp,p=telegraph_progress(b.enc_geometry);global.game_paused=true;repeat(90)boss_step(b,1/60);
    cd_check(b.dragon_state_age==age && b.boss_timer==timer && pl.hp==hp0 && telegraph_progress(b.enc_geometry)==p,"Pause freezes warning geometry, attack timer and damage together");global.game_paused=false;
    global.cd_metrics.countdown_timing=samples;
}
// Legacy dragon fixtures (pre boss-v2 sweep beams); off by default, dragon coverage lives in boss/regression suites.
function cd_dragon_tests() {
    var kinds=["beam","arc","meteor","slam","wind","void","stomp","vortex","volley"],outcomes=[];
    for(var i=0;i<array_length(kinds);i++) {
        var kind=kinds[i],b=cd_boss_fixture(kind,3),pl=ObjectPlayer,g=b.enc_geometry,c=b.enc_cfg,point_x=g.x+lengthdir_x(kind=="vortex" ? 80 : 100,g.angle),point_y=g.y+lengthdir_y(kind=="vortex" ? 80 : 100,g.angle);
        if(kind=="meteor" || kind=="stomp"){point_x=b.enc_zones[0].x;point_y=b.enc_zones[0].y;}
        if(kind=="slam"){point_x=g.x+30;point_y=g.y;}
        pl.x=point_x;pl.y=point_y+10;var hp0=pl.hp;
        boss_step(b,c.warning-.001);cd_check(pl.hp==hp0 && b.boss_state=="windup","Dragon "+kind+" cannot hurt before its own complete warning");
        boss_step(b,.0011);
        cd_check(b.boss_state=="active","Dragon "+kind+" activates immediately on countdown completion");
        if(kind=="void" || kind=="volley" || kind=="wind") {
            cd_check(array_length(global.hostile_bullets)>0,"Dragon "+kind+" launches actual hostile projectiles");
            var bullet=global.hostile_bullets[0];pl.x=bullet.x;pl.y=bullet.y+10;boss_hazards_step(.001);
        } else if(kind=="vortex") {pl.x=g.x+80;pl.y=g.y+10;boss_step(b,.001);}
        cd_check(pl.hp<hp0,"Dragon "+kind+" actual active hit removes HP");array_push(outcomes,{kind:kind,warning:c.warning,damage:hp0-pl.hp,projectiles:array_length(global.hostile_bullets)});
        var old=pl.hp;b.boss_state="recovery";b.boss_timer=1;global.hostile_bullets=[];b.enc_zones=[];repeat(4)boss_step(b,.05);cd_check(pl.hp==old,"Dragon "+kind+" cannot deal stale attack damage in recovery");
    }
    var b=cd_boss_fixture("slam"),pl=ObjectPlayer,g=b.enc_geometry;pl.x=g.x+30;pl.y=g.y+10;pl.motion_state=player_motion_state.rising;pl.jump_height=40;var hp0=pl.hp;boss_step(b,b.enc_cfg.warning+.0001);cd_check(pl.hp==hp0,"Jump passes over the dragon ground shockwave");
    b=cd_boss_fixture("beam");pl=ObjectPlayer;g=b.enc_geometry;pl.x=g.x+lengthdir_x(100,g.angle);pl.y=g.y+lengthdir_y(100,g.angle)+10;pl.motion_state=player_motion_state.sliding;hp0=pl.hp;boss_step(b,b.enc_cfg.warning+.0001);cd_check(pl.hp==hp0,"Slide passes beneath the elevated firebeam");
    b=cd_boss_fixture("stomp");pl=ObjectPlayer;pl.x=b.enc_zones[0].x;pl.y=b.enc_zones[0].y+10;pl.motion_state=player_motion_state.rising;pl.jump_height=40;hp0=pl.hp;boss_step(b,b.enc_cfg.warning+.0001);cd_check(pl.hp<hp0,"Jump does not grant blanket immunity to magma at every height");
    var fractions=[1,.75,.5,.25,.10],phases=[1,2,3,4,4];for(var i=0;i<5;i++){b.hp=b.max_hp*fractions[i];cd_check(dragon_phase_for_hp(b)==phases[i],"Dragon HP threshold "+string(fractions[i])+" selects phase "+string(phases[i]));}
    var rotations=[];for(var phase=1;phase<=4;phase++){var r=dragon_rotation(phase);array_push(rotations,r);cd_check(json_stringify(r)==json_stringify(dragon_rotation(phase)) && array_length(r)>=4,"Dragon phase "+string(phase)+" uses a stable authored rotation");}
    b.hp=b.max_hp*.74;b.boss_phase=1;b.boss_state="recovery";b.boss_timer=0;boss_step(b,.001);cd_check(b.boss_phase==2 && b.boss_state=="transition","Dragon actually enters phase two at a safe recovery boundary");
    b.hp=b.max_hp*.49;b.boss_state="recovery";b.boss_timer=0;boss_step(b,.001);cd_check(b.boss_phase==3 && b.boss_state=="transition","Dragon actually enters phase three at a safe recovery boundary");
    b.hp=b.max_hp*.24;b.boss_state="recovery";b.boss_timer=0;boss_step(b,.001);cd_check(b.boss_phase==4 && b.boss_state=="transition","Dragon actually enters phase four at a safe recovery boundary");
    b.hp=50;apply_attack_damage(b,1000,pl,0);cd_check(b.hp<=0,"Dragon can be killed with actual damage without an enforced minimum fight timer");
    global.cd_metrics.dragon={attacks:outcomes,rotations:rotations};
}
function cd_dps_build(_class,_variant,_kill_target=false) {
    cd_reset(_class);var pl=ObjectPlayer;global.current_level=13;
    // Fifteen decisions: five rank-2 active/passive skills plus five rank-1 skills.
    global.active_spells=[cd_entry(101,2),cd_entry(103,2),cd_entry(105,2),cd_entry(106,1)];
    global.passive_spells=[cd_entry(202,2),cd_entry(204,2),cd_entry(207,1),cd_entry(205,1),cd_entry(209,1),cd_entry(210,1)];apply_passives(pl);
    global.round_seconds=300;global.monster_hp_multiplier=1.35;var b=boss_spawn("storm_warden"),encounter_hp=b.max_hp;b.x=pl.x+110;b.y=pl.y;b.hp=_kill_target ? encounter_hp : 1000000;b.max_hp=b.hp;var start_hp=b.hp;random_set_seed(62133);
    var measure=_kill_target ? 240 : 60,active_frames=0;
    while(active_frames<measure*60 && b.hp>0) {
        var frame=active_frames,attack_window=_variant==0 || (frame mod 600)<420;active_frames++;
        if(attack_window){with(pl)weapon_auto_step();hotbar_tick_cooldowns();auto_spells_step();spell_orbit_step(pl);}
        else {if(pl.weapon_cooldown>0)pl.weapon_cooldown--;hotbar_tick_cooldowns();}
        cd_effect_tick();
        // Production DOT/status updates without moving or attacking the stationary damage dummy.
        if(b.burn_time>0){var actual=min(b.hp,b.burn_dps/60);b.hp-=actual;b.burn_time=max(0,b.burn_time-1);}
        b.slow_time=max(0,b.slow_time-1);b.shock_time=max(0,b.shock_time-1);
    }
    var elapsed=active_frames/60,damage=start_hp-b.hp,dps=damage/elapsed,base_hp=encounter_hp;
    return {class_name:_class,variant:_variant==0 ? "stationary_full_uptime" : "scripted_70_percent_attack_uptime",measurement_seconds:elapsed,actual_damage:damage,dps:dps,configured_boss_hp:base_hp,estimated_seconds:base_hp/dps,measured_target_defeat_seconds:_kill_target && b.hp<=0 ? elapsed : -1,stationary_target:true,hostile_rotation_disabled:true,real_runtime_damage:true,human_playtest:false,build_decisions:15};
}
function cd_dps_tests() {
    var out=[],kills=[],classes=["Sword","Mage","Ranger"];
    for(var i=0;i<3;i++) {
        for(var v=0;v<2;v++){var result=cd_dps_build(classes[i],v);array_push(out,result);cd_check(result.actual_damage>0 && result.dps>0,"Real runtime weapon/spell/passive DPS "+classes[i]+" profile "+string(v));}
        var kill=cd_dps_build(classes[i],1,true);array_push(kills,kill);cd_check(kill.measured_target_defeat_seconds>0,"Actual configured dragon HP can be depleted by the scripted representative "+classes[i]+" build");
    }
    global.cd_metrics.dps=out;global.cd_metrics.controlled_target_defeats=kills;
}
function cd_enrage_patterns() {
    var b=cd_boss_fixture("vortex",4);boss_step(b,b.enc_cfg.warning-.001);cd_check(array_length(global.hostile_bullets)==0 && !b.enc_combo_fired,"Enrage vortex cannot release its combined void shots before full warning");
    boss_step(b,.0011);cd_check(b.enc_combo_fired && array_length(global.hostile_bullets)==3,"Enrage vortex releases exactly three warned void shots on activation");
    b=cd_boss_fixture("volley",4);boss_step(b,b.enc_cfg.warning+.0001);var wave1=array_length(global.hostile_bullets);boss_step(b,.48);var wave2=array_length(global.hostile_bullets)-wave1;boss_step(b,.48);var wave3=array_length(global.hostile_bullets)-wave1-wave2;
    cd_check(wave1==3 && wave2==5 && wave3==5 && b.enc_waves==3,"Enrage volley uses three parallel then five/five fan projectiles in separate waves");
    global.cd_metrics.enrage={vortex_void_projectiles:3,volley_waves:[wave1,wave2,wave3]};
}
function cd_assets_audio_tests() {
    var names=["mage_bolt","mage_arc","mage_circle","mage_star","mage_implosion","ranger_arrow","ranger_volley","ranger_rain","dragon_fire","dragon_charge","dragon_meteor","dragon_slam","dragon_wind","dragon_void","dragon_magma","dragon_vortex"],voices=[];fg_audio_stop_effects();
    for(var i=0;i<array_length(names);i++){var name=names[i],resource=asset_get_index("sfx_fg_"+name);cd_check(audio_exists(resource),"Actual imported class/dragon audio resource "+name);}
    global.cd_metrics.audio=[];
    var actors=["magev3","rangerv3"],dirs=["right","up_right","up","up_left","left","down_left","down","down_right"],actions=["idle","walk","run","jump","fall","landing","dodge","slide","dive","hurt","death"];
    for(var a=0;a<2;a++){var valid=true,total_frames=0;for(var d=0;d<8;d++)for(var k=0;k<array_length(actions);k++){var spr=asset_get_index("spr_fg_"+actors[a]+"_"+actions[k]+"_"+dirs[d]);if(!sprite_exists(spr))valid=false;else{total_frames+=sprite_get_number(spr);if(sprite_get_xoffset(spr)!=48 || sprite_get_yoffset(spr)!=88)valid=false;}}cd_check(valid && total_frames>100,"New "+actors[a]+" real eight-direction animation resources and consistent origins");}
    var bounded=true;for(var i=0;i<100;i++)class_fx_add("mage_circle",ObjectPlayer.x,ObjectPlayer.y,0,20,.05);if(array_length(global.class_effects)>48)bounded=false;repeat(80)class_effects_step(.05);cd_check(bounded && array_length(global.class_effects)==0,"Class effect pool is bounded and expired effects are destroyed");
}
function cd_menu_tick() {
    if(!variable_global_exists("cd_started")){global.cd_started=true;global.cd_checks=0;global.cd_failures=[];global.cd_metrics={};global.cd_frame=0;global.cd_hold=true;global.cd_dt=1/60;global.cd_stage=0;menu_mode="main";menu_activate(0);menu_activate(0);menu_activate(0);}
}
function cd_controller_tick() {
    if(global.cd_stage==0){global.cd_stage=1;cd_sword_regression();cd_mage_tests();cd_ranger_tests();cd_geometry_tests();if(variable_global_exists("cd_with_dragon") && global.cd_with_dragon){cd_beam_timing();cd_dragon_tests();cd_enrage_patterns();}cd_dps_tests();cd_assets_audio_tests();cd_reset("Mage");ObjectPlayer.hp=ObjectPlayer.max_hp;global.cd_frame=0;}
    global.cd_frame++;
    cd_real_audio_tick(global.cd_frame);
    cd_visual_tick(global.cd_frame);
    if(global.cd_frame==970){var report={passed:array_length(global.cd_failures)==0,status:array_length(global.cd_failures)==0 ? "PASS" : "FAIL",checks:global.cd_checks,failures:global.cd_failures,metrics:global.cd_metrics,scope:"Native production functions; deterministic fixtures and short scripted damage windows. Not human gameplay E2E."};show_debug_message("CLASS_DRAGON_RESULT "+json_stringify(report));game_end();}
}
function cd_real_audio_tick(_f) {
    if(_f<8 || _f>113 || (_f-8) mod 7!=0)return;
    var names=["mage_bolt","mage_arc","mage_circle","mage_star","mage_implosion","ranger_arrow","ranger_volley","ranger_rain","dragon_fire","dragon_charge","dragon_meteor","dragon_slam","dragon_wind","dragon_void","dragon_magma","dragon_vortex"],i=(_f-8) div 7,name=names[i];
    fg_audio_stop_effects();variable_struct_set(global.fg_audio.last_sfx,name,-10000);var handle=fg_sfx(name);cd_check(handle>=0,"Audio engine actually creates a native-frame voice for "+name);array_push(global.cd_metrics.audio,{cue:name,handle_created:handle>=0,native_frame:_f});
}
function cd_visual_tick(_f) {
    var pl=ObjectPlayer;
    if(_f>=12 && _f<=190) {
        var stage=_f<40 ? 1 : (_f<70 ? 2 : (_f<100 ? 3 : 4));
        if(_f==12 || _f==40 || _f==70 || _f==100){cd_reset("Mage");var e=cd_enemy(pl.x+105,pl.y,10000);pl.class_combo_index=stage-1;pl.weapon_cooldown=0;cd_weapon_tick();}
        if(pl.class_pending>0)cd_weapon_tick();cd_effect_tick();
        var a=player_visual_asset(pl.visual_actor,"attack","right",stage);pl.visual_sprite_index=a.sprite;pl.visual_mirror=a.mirror;pl.visual_size=a.size;pl.visual_frame_index=min(sprite_get_number(a.sprite)-1,floor((1-pl.attack_timer/max(1,pl.attack_duration))*sprite_get_number(a.sprite)));
        if(pl.attack_timer>0)pl.attack_timer--;
    }
    if(_f==200){cd_reset("Ranger");cd_enemy(pl.x+160,pl.y,10000);}
    if(_f>=200 && _f<=300){
        if(_f==200)pl.class_combo_index=2;
        if(_f==225){pl.class_combo_index=8;pl.weapon_cooldown=0;}
        if(_f==250){pl.class_combo_index=11;pl.weapon_cooldown=0;}
        cd_weapon_tick();cd_effect_tick();
        var a=player_visual_asset(pl.visual_actor,"attack","right",pl.attack_stage);pl.visual_sprite_index=a.sprite;pl.visual_mirror=a.mirror;pl.visual_size=a.size;pl.visual_frame_index=min(sprite_get_number(a.sprite)-1,floor((1-pl.attack_timer/max(1,pl.attack_duration))*sprite_get_number(a.sprite)));
    }
    var kinds=["beam","arc","meteor","slam","wind","void","stomp","vortex","volley"];
    if(_f>=320 && _f<905 && variable_global_exists("cd_with_dragon") && global.cd_with_dragon) {
        var i=(_f-320) div 65,local_tick=(_f-320) mod 65;
        if(local_tick==0){var b=cd_boss_fixture(kinds[i],3);pl.hp=100000;pl.max_hp=100000;pl.__base_max_hp=100000;global.cd_visual_boss=b;}
        var b=global.cd_visual_boss;
        if(instance_exists(b)){boss_step(b,b.enc_cfg.warning/30);boss_hazards_step(b.enc_cfg.warning/30);}
    }
    if(_f==905){cd_reset("Ranger");for(var i=0;i<150;i++){var e=cd_enemy(pl.x-330+(i mod 15)*46,pl.y-220+(i div 15)*44,100000);e.base_move_speed=.8;}pl.hp=100000;pl.max_hp=100000;weather_set("heavy_rain",999);global.cd_perf=[];global.cd_perf_last=get_timer();}
    if(_f>=906 && _f<=966) {
        var now=get_timer();if(_f>906)array_push(global.cd_perf,(now-global.cd_perf_last)/1000);global.cd_perf_last=now;
        cd_weapon_tick();cd_effect_tick();weather_step(1/60);feedback_step(1/60);atmosphere_step(1/60);global.cd_hold=false;with(ObjectMonster)event_perform(ev_step,0);global.cd_hold=true;
        if(_f mod 10==0)class_fx_add("mage_circle",pl.x+100,pl.y-30,1,110,.65);
        if(_f==966){var sum=0,largest=0;for(var i=0;i<array_length(global.cd_perf);i++){sum+=global.cd_perf[i];largest=max(largest,global.cd_perf[i]);}global.cd_metrics.performance={enemies:instance_number(ObjectMonster),frames:array_length(global.cd_perf),mean_frame_ms:sum/max(1,array_length(global.cd_perf)),max_frame_ms:largest,weather:"heavy_rain",class_weapon_effects:true,enemy_ai_stepped:true,measurement:"real get_timer intervals between native frames; short sample, not a long-term benchmark"};cd_check(instance_number(ObjectMonster)==150 && array_length(global.cd_perf)==60,"Native rendering sample retains150 enemies and60 actual frame intervals with rain and class effects");}
    }
}
function cd_capture_draw() {
    if(!variable_global_exists("cd_frame"))return;
    var f=global.cd_frame;
    if(f>=2 && f<=6) {
        var p=(f-2)*.25,s=surface_create(800,600);surface_set_target(s);draw_clear(make_color_rgb(12,18,26));
        var shapes=["circle","sector","line","rectangle","ring"];
        for(var i=0;i<5;i++){var marker_x=140+(i mod 3)*255,marker_y=160+(i div 3)*280,g=telegraph_make(shapes[i],marker_x,marker_y,95,1,20,110,34);g.elapsed=p;telegraph_draw(g,make_color_rgb(255,126,63));draw_set_color(c_white);draw_text(marker_x-65,marker_y+115,shapes[i]+" "+string(p*100)+"%");}
        surface_reset_target();surface_save(s,"cdcapture-warning-"+string((f-2)*25)+".png");
        // Read actual native rendered pixels, not just the progress scalar.
        if(f==2)global.cd_fill_counts=[[],[],[],[],[]];
        var pixels=buffer_create(800*600*4,buffer_fixed,1);buffer_get_surface(pixels,s,0);
        for(var i=0;i<5;i++) {
            var cx=140+(i mod 3)*255,cy=160+(i div 3)*280,g=telegraph_make(shapes[i],cx,cy,95,1,20,110,34),filled=0;
            for(var yy=cy-100;yy<cy+100;yy+=2)for(var xx=cx-100;xx<cx+100;xx+=2)if(telegraph_contains(g,xx,yy)) {
                var offset=(yy*800+xx)*4,r=buffer_peek(pixels,offset,buffer_u8),gr=buffer_peek(pixels,offset+1,buffer_u8),b=buffer_peek(pixels,offset+2,buffer_u8),bright=max(r,gr,b);
                if(bright>40)filled++;
            }
            array_push(global.cd_fill_counts[i],filled);
            if(f==6) {
                // Current warning design (DESIGN/BOSS_DESIGN.md): faint zone fill from 0 %, countdown runs along the edge and brightens late.
                var counts=global.cd_fill_counts[i],ratios=[],mono=true;for(var j=0;j<5;j++){array_push(ratios,counts[j]/max(1,counts[4]));if(j>0 && counts[j]<counts[j-1]-2)mono=false;}
                cd_check(counts[0]>0,"Native rendered "+shapes[i]+" warning zone is visible from 0% countdown");
                cd_check(mono && counts[4]>counts[0],"Native rendered "+shapes[i]+" edge countdown grows monotonically to activation");
                if(!variable_struct_exists(global.cd_metrics,"rendered_fill"))global.cd_metrics.rendered_fill=[];
                array_push(global.cd_metrics.rendered_fill,{shape:shapes[i],filled_pixel_samples:counts,ratios:ratios});
            }
        }
        buffer_delete(pixels);surface_free(s);
    }
    var name="";
    switch(f){case 29:name="mage-projectile";break;case 54:name="mage-arc";break;case 84:name="mage-circle";break;case 150:name="mage-star-flight";break;case 184:name="mage-star-implosion";break;case 206:name="ranger-three";break;case 232:name="ranger-five";break;case 299:name="ranger-rain";break;case 967:name="crowd-class-rain";break;}
    if(f>=320 && f<905 && variable_global_exists("cd_with_dragon") && global.cd_with_dragon){var local_tick=(f-320) mod 65,index=(f-320) div 65,kinds=["beam","arc","meteor","slam","wind","void","stomp","vortex","volley"];if(local_tick==14)name="dragon-"+kinds[index]+"-warning";if(local_tick==32)name="dragon-"+kinds[index]+"-active";}
    if(name!="" && surface_exists(application_surface)){surface_save(application_surface,"cdcapture-"+name+".png");show_debug_message("CLASS_DRAGON_CAPTURE "+name);}
}
