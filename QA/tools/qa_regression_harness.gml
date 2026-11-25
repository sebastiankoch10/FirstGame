/// Actual production event/function regressions; input injection only in isolated copy.
function qr_key(_key){return array_contains(global.qr_keys,_key);}
function qr_key_pressed(_key){return array_contains(global.qr_pressed_keys,_key);}
function qr_mouse(_button){return global.qr_mouse_down;}
function qr_mouse_pressed(_button){return global.qr_mouse_clicked;}
function qr_gui_x(_device){return global.qr_gui_x;}
function qr_gui_y(_device){return global.qr_gui_y;}
function qr_input(){global.qr_keys=[];global.qr_pressed_keys=[];global.qr_mouse_down=false;global.qr_mouse_clicked=false;global.qr_mouse_x=2200;global.qr_mouse_y=2048;global.qr_gui_x=-100;global.qr_gui_y=-100;}
function qr_player_tick(){global.bt_hold=false;with(ObjectPlayer)event_perform(ev_step,0);global.bt_hold=true;global.qr_pressed_keys=[];global.qr_mouse_clicked=false;}
function qr_controls(){
    var classes=["Sword","Mage","Ranger"];
    for(var c=0;c<3;c++){
        bt_reset(classes[c]);qr_input();var pl=ObjectPlayer;pl.menu_input_guard=0;var pace=pl.moveSpeed,x0=pl.x,y0=pl.y;
        global.qr_keys=[ord("D")];qr_player_tick();bt_check(abs(pl.x-x0-pace)<.001 && pl.y==y0,classes[c]+" actual Player Step D moves at class speed");
        global.qr_keys=[ord("A")];qr_player_tick();bt_check(abs(pl.x-x0)<.001,classes[c]+" actual Player Step A reverses direction");
        global.qr_keys=[ord("W")];qr_player_tick();bt_check(abs(pl.y-y0+pace)<.001,classes[c]+" actual Player Step W moves up");
        global.qr_keys=[ord("S")];qr_player_tick();bt_check(abs(pl.y-y0)<.001,classes[c]+" actual Player Step S moves down");
        global.qr_keys=[ord("D"),ord("W")];qr_player_tick();bt_check(abs(point_distance(x0,y0,pl.x,pl.y)-pace)<.001,classes[c]+" diagonal movement is normalized");
        bt_pos();qr_input();pl.menu_input_guard=0;pl.mouse_move_armed=false;global.qr_mouse_down=true;x0=pl.x;qr_player_tick();bt_check(pl.x==x0,classes[c]+" held menu click cannot leak into movement");
        global.qr_mouse_down=false;qr_player_tick();global.qr_mouse_down=true;qr_player_tick();bt_check(pl.x>x0,classes[c]+" mouse movement arms after release");
        bt_pos();qr_input();pl.menu_input_guard=0;global.qr_keys=[ord("D")];global.qr_pressed_keys=[vk_space];qr_player_tick();var slide_seen=false;
        repeat(44){qr_player_tick();if(pl.motion_state==player_motion_state.sliding)slide_seen=true;}
        bt_check(pl.motion_state==player_motion_state.grounded && !slide_seen && pl.jump_height==0,classes[c]+" one jump lands without automatic slide");
        pl.mobility_cooldown=0;global.qr_pressed_keys=[vk_space];qr_player_tick();repeat(19)qr_player_tick();global.qr_pressed_keys=[vk_space];qr_player_tick();
        bt_check(pl.motion_state==player_motion_state.diving,classes[c]+" second jump press in apex window initiates dive");
        slide_seen=false;repeat(35){qr_player_tick();if(pl.motion_state==player_motion_state.sliding)slide_seen=true;}
        bt_check(slide_seen && pl.motion_state==player_motion_state.grounded,classes[c]+" dive reaches slide then finite recovery");
        pl.mobility_cooldown=0;pl.dodge_cooldown=0;global.qr_pressed_keys=[vk_control];qr_player_tick();bt_check(pl.dodge_timer>0,classes[c]+" Control starts actual dodge");
        var hp0=pl.hp;player_receive_damage(pl,9,"all");bt_check(pl.hp==hp0,classes[c]+" dodge protects against all-height damage");
        repeat(12)qr_player_tick();bt_check(pl.dodge_timer<=0 && pl.dodge_cooldown>0,classes[c]+" dodge ends while cooldown remains");
        pl.motion_state=player_motion_state.rising;hp0=pl.hp;player_receive_damage(pl,7,"ground");bt_check(pl.hp==hp0,classes[c]+" jump clears ground damage");player_receive_damage(pl,7,"all");bt_check(pl.hp<hp0,classes[c]+" airborne player still takes all-height damage");
    }
}
function qr_contacts_loot(){
    bt_reset();qr_input();var pl=ObjectPlayer,e=instance_create_layer(pl.x+12,pl.y,"Instances",ObjectMonster);e.damage=8;e.skeleton_strike=true;
    var hp0=pl.hp;bt_check(player_contact(pl,e) && pl.hp==hp0-8,"Actual skeleton strike contact deals configured damage");
    hp0=pl.hp;bt_check(!player_contact(pl,e) && pl.hp==hp0,"Same attacker cannot bypass its contact cooldown");
    var e2=instance_create_layer(pl.x-12,pl.y,"Instances",ObjectMonster);e2.damage=6;e2.skeleton_strike=true;
    bt_check(player_contact(pl,e2) && pl.hp==hp0-6,"Independent simultaneous attackers retain independent contact cooldowns");
    hp0=pl.hp;e.contact_next=0;e.skeleton_strike=false;bt_check(!player_contact(pl,e) && pl.hp==hp0,"Skeleton outside strike frames has harmless body contact");
    e.skeleton_strike=true;e.hit_stun=.1;bt_check(!player_contact(pl,e),"Stunned skeleton cannot contact-hit");
    var kills=global.run_kills,coins=instance_number(ObjectCoin);e.hp=0;global.bt_hold=false;with(e)event_perform(ev_step,0);global.bt_hold=true;
    bt_check(global.run_kills==kills+1 && instance_number(ObjectCoin)==coins+1,"Actual enemy death creates one coin and one kill");
    with(ObjectMonster)instance_destroy();with(ObjectCoin)instance_destroy();
    var positions=[[pl.x+60,pl.y],[pl.x+700,pl.y],[pl.x-700,pl.y+500]];
    for(var i=0;i<3;i++)instance_create_layer(positions[i][0],positions[i][1],"Instances",ObjectCoin);
    var orb=magnet_drop(pl.x,pl.y,true),before=global.coins;
    bt_check(magnet_collect(orb,pl,true) && global.magnet_metrics.marked==3,"Real boss orb marks nearby and distant coins once");
    var allmarked=true;with(ObjectCoin)if(!magnetized)allmarked=false;bt_check(allmarked,"Every existing coin is magnetized");
    repeat(180){global.bt_hold=false;with(ObjectCoin)event_perform(ev_step,0);global.bt_hold=true;}
    bt_check(instance_number(ObjectCoin)==0 && global.coins==before+3 && global.magnet_metrics.collected==3,"Magnetized coins converge and award XP exactly once");
    bt_reset();qr_input();pl=ObjectPlayer;var chest=instance_create_layer(pl.x,pl.y-12,"Instances",ObjectChest);global.bt_hold=false;with(chest)event_perform(ev_step,0);global.bt_hold=true;
    bt_check(global.chest_collected && global.game_paused && array_length(global.spell_options)==3,"Actual chest overlap opens three valid choices and pauses");
}
function qr_states_choices(){
    bt_reset();qr_input();var pl=ObjectPlayer;global.qr_pressed_keys=[vk_escape];qr_controller_production();
    bt_check(global.game_paused && global.normal_pause_active,"Production Escape opens normal pause");qr_controller_production();
    bt_check(!global.game_paused && !global.normal_pause_active,"Production Escape resumes simulation");qr_input();
    global.coins=global.coins_needed;global.next_levelup_time=0;qr_controller_production();
    bt_check(global.current_level==2 && global.levelup_active && global.game_paused,"Actual earned XP triggers level-up and pauses");
    var options=global.spell_options;qr_input();qr_controller_production();var ui=spell_ui_layout();global.qr_gui_x=ui.x+20;global.qr_gui_y=ui.y+20;global.qr_mouse_down=true;global.qr_mouse_clicked=true;qr_controller_production();
    bt_check(!global.game_paused && !global.levelup_active && (options[0].id==-2 ? weapon_upgrade_level()==1 : spell_level(options[0].id)==1),"Actual choice-card click learns only the selected offered skill and resumes");
    bt_check(pl.menu_input_guard==1 && !pl.mouse_move_armed,"Choice confirmation restores movement input guard");
    for(var k=0;k<3;k++){
        global.selected_character=["Sword","Mage","Ranger"][k];reset_round();qr_input();
        bt_check(global.current_level==1 && global.round_seconds==0 && global.run_kills==0 && global.run_boss_kills==0,"Sequential reset "+string(k)+" clears progression and counters");
        bt_check(array_length(global.active_spells)==0 && array_length(global.passive_spells)==0 && array_length(global.hostile_bullets)==0 && array_length(global.bv2_hazards)==0,"Sequential reset "+string(k)+" clears builds and hazards");
        bt_check(ObjectPlayer.hp==ObjectPlayer.max_hp && !global.game_over && !global.game_paused,"Sequential reset "+string(k)+" restores class HP and active state");
    }
    bt_reset();qr_input();player_receive_damage(ObjectPlayer,10000,"all");
    bt_check(global.game_over && global.game_paused && ObjectPlayer.hp==0,"Lethal actual damage enters paused Game Over");reset_round();
    bt_check(!global.game_over && !global.game_paused && ObjectPlayer.hp==120,"Restart clears Game Over and restores original Sword HP");
}
function qr_controller_tick(){
    if(!variable_global_exists("qr_started")){
        global.qr_started=true;qr_input();qr_controls();qr_contacts_loot();qr_states_choices();
        // Current-source boss/weapon regressions. Short controlled fixtures, no complete fights.
        bt_catalog_tests();bt_dragon_abilities();bt_encounter_abilities("twins");bt_encounter_abilities("behemoth");bt_twins_tests();bt_swamp_tests();bt_passive_tests();bt_testmode_tests();bt_warning_fps_tests();bt_sword_regression();
        bt_reset();qr_input();global.qr_frame=0;
    }
    global.qr_frame++;
    if(global.qr_frame==1){global.qr_boss=bt_spawn("twins");global.qr_boss.hurt_flash_timer=4;}
    if(global.qr_frame==3)global.qr_boss.hurt_flash_timer=2;
    if(global.qr_frame==5){bt_reset("Mage");qr_input();}
    if(global.qr_frame==7){bt_reset("Ranger");qr_input();}
    if(global.qr_frame==9){
        bt_reset();qr_input();global.round_seconds=900;global.current_level=36;
        var active=[101,102,103,107,109,118],passive=[201,202,203,204,214,218];
        for(var i=0;i<6;i++)repeat(5){boss_test_add_skill(active[i]);boss_test_add_skill(passive[i]);}
        apply_passives(ObjectPlayer);var b=boss_spawn("storm_warden");b.hp=b.max_hp*.7;
        display_set_gui_size(1280,720);
    }
    if(global.qr_frame==11){var ui=hud_layout();global.qr_gui_x=ui.slots_x+10;global.qr_gui_y=ui.active_y+10;}
    if(global.qr_frame==13){spell_choices_v2("levelup");global.selected_spell_index=0;}
    if(global.qr_frame==15)display_set_gui_size(800,600);
    if(global.qr_frame==17){global.game_paused=false;global.levelup_active=false;var ui=hud_layout();global.qr_gui_x=ui.slots_x+10;global.qr_gui_y=ui.passive_y+10;}
    if(global.qr_frame==20){display_set_gui_size(1280,720);bt_visual_tick(460);}
    if(global.qr_frame>=21 && global.qr_frame<=101)bt_visual_tick(440+global.qr_frame);
    if(global.qr_frame>=102){var r={passed:array_length(global.bt_failures)==0,checks:global.bt_checks,failures:global.bt_failures,metrics:global.bt_metrics,scope:"Current production functions and input-injected actual Player/Controller Steps in isolated native runner. Targeted regressions and short rendered150-enemy stress fixture; not full runs or human playtests."};show_debug_message("QA_REGRESSION_RESULT "+json_stringify(r));game_end();}
}
function qr_capture_draw(){
    if(!variable_global_exists("qr_frame"))return;
    var name="";switch(global.qr_frame){case 2:name="twins-hurt-timer4";break;case 4:name="twins-hurt-timer2";break;case 6:name="mage-current-world";break;case 8:name="ranger-current-world";break;case 101:name="crowd150-heavy-rain";break;}
    if(name!="" && surface_exists(application_surface))surface_save(application_surface,"qacapture-"+name+".png");
    name="";switch(global.qr_frame){case 10:name="hud-full-build-1280";break;case 12:name="hud-tooltip-1280";break;case 14:name="levelup-1280";break;case 16:name="levelup-800";break;case 18:name="hud-tooltip-800";break;}
    if(name!=""){
        var w=display_get_gui_width(),h=display_get_gui_height(),s=surface_create(w,h);
        surface_set_target(s);draw_clear(c_black);
        if(surface_exists(application_surface))draw_surface_stretched(application_surface,0,0,w,h);
        // Invoke the same current production GUI functions in their native Draw GUI projection.
        hud_draw();ui_modal_draw();boss_test_draw_gui();
        surface_reset_target();surface_save(s,"qacapture-"+name+".png");surface_free(s);
    }
}
function qr_coin_controller_tick(){
    if(variable_global_exists("qr_coin_done"))return;global.qr_coin_done=true;qr_input();var results=[];
    for(var index=0;index<4;index++){
        var klass=["Sword","Mage","Ranger","Ranger"][index];bt_reset(klass);qr_input();bt_pos(640,640);var pl=ObjectPlayer;pl.menu_input_guard=0;
        if(index==3){repeat(9)boss_test_add_skill(203);apply_passives(pl);}
        var x0=pl.x,xp0=global.coin_xp_earned,pace=pl.moveSpeed,coin=instance_create_layer(pl.x-80,pl.y,"Instances",ObjectCoin),collected_at=-1;
        global.qr_keys=[ord("D")];
        for(var frame=0;frame<180;frame++){
            qr_player_tick();global.bt_hold=false;with(ObjectCoin)event_perform(ev_step,0);global.bt_hold=true;
            if(global.coin_xp_earned>xp0 && collected_at<0)collected_at=frame+1;
        }
        var moved=pl.x-x0,dist=instance_exists(coin) ? point_distance(pl.x,pl.y,coin.x,coin.y) : 0;
        array_push(results,{class_name:klass,fleet_footed_level:index==3 ? 9 : 0,player_speed_pixels_second:pace*60,
            coin_speed_pixels_second:combat_config().normal_coin_speed,seconds:3,player_distance:moved,
            collected:global.coin_xp_earned==xp0+1,collected_at_tick:collected_at,remaining_distance:dist});
        bt_check(abs(moved-pace*180)<.02,klass+" moving-coin probe uses an unobstructed actual Player Step path "+string(index));
        bt_check(global.coin_xp_earned==xp0+1,klass+" ordinary nearby coin catches the moving player "+string(index));
    }
    var r={passed:array_length(global.bt_failures)==0,checks:global.bt_checks,failures:global.bt_failures,
        metrics:{moving_coin:results},scope:"Controlled native three-second moving-coin fixture, actual Player and Coin Steps; no complete run."};
    show_debug_message("QA_REGRESSION_RESULT "+json_stringify(r));game_end();
}
function qr_stress_controller_tick(){
    if(!variable_global_exists("qr_stress_frame")){qr_input();global.qr_stress_frame=0;bt_visual_tick(460);}
    global.qr_stress_frame++;global.qr_frame=20+global.qr_stress_frame;
    if(global.qr_stress_frame<=81)bt_visual_tick(460+global.qr_stress_frame);
    if(global.qr_stress_frame>=82){var r={passed:array_length(global.bt_failures)==0,checks:global.bt_checks,failures:global.bt_failures,metrics:global.bt_metrics,scope:"Short native rendered150-enemy heavy-rain/boss-hazard fixture. Elevated fixture HP; not a full run, sustained frame-rate guarantee or memory soak test."};show_debug_message("QA_REGRESSION_RESULT "+json_stringify(r));game_end();}
}
