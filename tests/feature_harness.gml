/// Native feature checks (talents, equipment, spell VFX, character screen) for all three classes.
/// Injected only into the isolated copy built by tests/tools/run_feature_smoke.py.
function gp_key_down(_key) {return global.ft_hold_key==_key;}
function gp_key_pressed(_key) {return global.ft_press_key==_key;}
function gp_mouse_down(_button) {return global.ft_mouse_hold==_button;}
function gp_mouse_pressed(_button) {return global.ft_mouse_press==_button;}
function gp_mouse_x() {return instance_exists(ObjectPlayer) ? ObjectPlayer.x+200 : 0;}
function gp_mouse_y() {return instance_exists(ObjectPlayer) ? ObjectPlayer.y : 0;}
function gp_gui_x(_device) {return global.ft_mx;}
function gp_gui_y(_device) {return global.ft_my;}
function ft_check(_ok,_msg) {
    global.ft_checks++;
    var tag=global.ft_classes[global.ft_class];
    if(!_ok){global.ft_failed=true;array_push(global.ft_failures,tag+" "+_msg);show_debug_message("FEATURE FAIL "+tag+" "+_msg);}
    else show_debug_message("FEATURE PASS "+tag+" "+_msg);
}
function ft_init() {
    if(variable_global_exists("ft_ready"))return;
    global.ft_ready=true;global.ft_checks=0;global.ft_failed=false;global.ft_failures=[];global.ft_metrics={};
    global.ft_classes=["Sword","Mage","Ranger"];global.ft_class=0;global.ft_stage=0;global.ft_frame=0;
    global.ft_hold_key=-1;global.ft_press_key=-1;global.ft_mouse_press=-1;global.ft_mouse_hold=-1;global.ft_mx=-100;global.ft_my=-100;
    global.ft_shot="";global.ft_world_shot="";global.ft_done=false;
}
function ft_show_error(_msg,_abort=false) {show_debug_message("FEATURE_EXCEPTION show_error "+string(_msg));throw string(_msg);}
function ft_menu_tick() {
    ft_init();
    global.ft_press_key=-1;global.ft_hold_key=-1;global.ft_mouse_press=-1;
    if(global.ft_done){show_debug_message("FEATURE_RESULT "+json_stringify({passed:!global.ft_failed,checks:global.ft_checks,failures:global.ft_failures,metrics:global.ft_metrics}));game_end();return;}
    if(global.ft_stage!=0)return;
    menu_mode="main";menu_activate(0);menu_activate(global.ft_class);
    global.ft_stage=1;global.ft_frame=0;menu_activate(0);
}
function ft_clear() {with(ObjectMonster)instance_destroy();with(ObjectBossMonster)instance_destroy();with(ObjectCoin)instance_destroy();with(ObjectChest)instance_destroy();with(ObjectMagnetOrb)instance_destroy();global.active_boss=noone;global.boss_exists=false;}
function ft_spawn_dummy(_x,_y) {var e=instance_create_layer(_x,_y,"Instances",ObjectMonster);e.hp=99999;e.max_hp=99999;e.damage=0;e.base_move_speed=0;return e;}
function ft_count(_obj) {return instance_number(_obj);}
function ft_controller_tick() {
    ft_init();
    global.ft_press_key=-1;global.ft_mouse_press=-1;
    if(!instance_exists(ObjectPlayer))return;
    var pl=ObjectPlayer,cls=global.ft_classes[global.ft_class];
    global.ft_frame++;
    if(global.ft_stage!=13 && !global.game_over)pl.hp=pl.max_hp; // keep the bot alive: these are feature checks, not survival runs
    global.next_levelup_time=999999; // no automatic level-up popups during the feature stages
    switch(global.ft_stage) {
        case 1:
            if(global.ft_frame<20)return;
            ft_clear();
            ft_check(global.selected_character==cls,"class selected");
            ft_check(global.talent_points==0 && global.talent_spent==0,"run starts with 0 talent points");
            var eq_empty=true,s=equipment_slots();for(var i=0;i<6;i++)if(is_struct(global.equipment[$ s[i]]))eq_empty=false;
            ft_check(eq_empty && array_length(global.equipment_backpack)==0,"run starts without equipment");
            ft_check(pl.armor_flat==0 && pl.weapon_damage_mult==1,"no gear: armor 0, weapon multiplier 1");
            global.ft_base_hp=pl.max_hp;global.ft_base_speed=pl.moveSpeed;global.ft_base_power=pl.player_power;
            global.ft_stage=2;global.ft_frame=0;break;
        case 2: // talent points and rules
            talent_on_level(3);ft_check(global.talent_points==0,"no point at level 3");
            talent_on_level(4);ft_check(global.talent_points==1,"point at level 4");
            talent_on_level(5);ft_check(global.talent_points==1,"no point at level 5");
            talent_on_level(8);ft_check(global.talent_points==2,"point at level 8");
            talent_on_boss_defeated(true);ft_check(global.talent_points==3,"point for a main boss");
            talent_on_boss_defeated(false);ft_check(global.talent_points==3,"no point for a miniboss (config 0)");
            var own=cls=="Sword" ? "s_edge" : (cls=="Mage" ? "m_power" : "r_tips"),foreign=cls=="Sword" ? "m_power" : "s_edge";
            var gated=cls=="Sword" ? "s_wave" : (cls=="Mage" ? "m_star" : "r_rain");
            ft_check(talent_block_reason(foreign)!="" && !talent_invest(foreign),"other class talent "+foreign+" is rejected");
            ft_check(!talent_invest(gated) && talent_rank(gated)==0,"locked talent "+gated+" cannot be bought early");
            ft_check(talent_invest(own) && talent_rank(own)==1 && global.talent_points==2,"invest "+own+" rank 1");
            ft_check(talent_invest(own) && talent_rank(own)==2,"invest "+own+" rank 2");
            ft_check(talent_requirements_met(gated),"requirement of "+gated+" fulfilled after 2 ranks");
            ft_check(talent_invest(gated) && talent_rank(gated)==1 && global.talent_points==0,"invest gated talent "+gated);
            ft_check(!talent_invest("g_vigor"),"no investment without points");
            talent_grant(3);
            ft_check(talent_invest("g_vigor") && talent_invest("g_vigor"),"general talent g_vigor x2");
            apply_passives(pl);
            ft_check(pl.max_hp==global.ft_base_hp+12,"g_vigor rank 2 adds 12 max HP ("+string(pl.max_hp)+")");
            ft_check(talent_invest("g_stride"),"general talent g_stride");apply_passives(pl);
            ft_check(abs(pl.moveSpeed-global.ft_base_speed*1.03)<.001,"g_stride rank 1 = +3% speed");
            if(cls=="Sword")ft_check(abs(talent_stat("sword_dmg_pct")-.12)<.0001 && talent_stat("power")==0,"sword talent stats only");
            if(cls=="Mage"){ft_check(talent_stat("power")==2 && talent_stat("sword_dmg_pct")==0,"mage talent stats only");ft_check(pl.player_power==global.ft_base_power+2,"m_power adds power");}
            if(cls=="Ranger")ft_check(abs(talent_stat("ranger_dmg_pct")-.16)<.0001 && talent_stat("sword_dmg_pct")==0,"ranger talent stats only");
            var maxed=talent_find(own);while(talent_rank(own)<maxed.max){talent_grant(1);talent_invest(own);}
            talent_grant(1);ft_check(!talent_invest(own) && talent_block_reason(own)=="Maximaler Rang erreicht","max rank enforced");
            // Talents persist between runs in the real game only (decision 25.11.2026); renamed test builds stay per run.
            ft_check(!talent_persistent(),"test build keeps talents per run (no ini side effects)");
            // Slower meta progression: only main-boss points (and the ranks bought with them) survive a run.
            ft_check(global.talent_spent_meta==1 && talent_rank_meta(own)==1,"the main-boss point was spent first and is permanent");
            global.talent_persist_override=true;file_delete(talent_config().save_file);
            var keep_meta=talent_rank_meta(own),keep_mp=global.talent_points_meta,keep_ms=global.talent_spent_meta;
            talent_save();talent_reset_run();
            ft_check(talent_rank(own)==keep_meta && talent_rank(gated)==talent_rank_meta(gated) && global.talent_points==keep_mp && global.talent_spent==keep_ms,"only boss-point talents survive a new run");
            ft_check(talent_respec() && talent_rank(own)==0 && global.talent_spent==0 && global.talent_points_meta==keep_mp+keep_ms,"respec refunds the permanent points");
            talent_reset_run();ft_check(talent_rank(own)==0 && global.talent_points==keep_mp+keep_ms,"respec is saved for the next run");
            file_delete(talent_config().save_file);global.talent_persist_override=false;talent_reset_run();
            // Weapon upgrades (cards in the level-up offer, decision 25.11.2026): level, damage hook, look tier, offer, cap.
            weapon_upgrade_reset();var wkey=cls=="Mage" ? "mage_dmg_pct" : (cls=="Ranger" ? "ranger_dmg_pct" : "sword_dmg_pct"),w0=talent_stat(wkey);
            ft_check(learn_spell(-2) && weapon_upgrade_level()==1 && talent_stat(wkey)>w0,"weapon upgrade card raises weapon level and damage hook");
            ft_check(weapon_visual_tier()==1,"weapon look tier 1 at upgrade 1");learn_spell(-2);ft_check(weapon_visual_tier()==2,"weapon look tier 2 at upgrade 2");
            var offered=false;repeat(40){spell_choices_v2("chest");for(var oi=0;oi<array_length(global.spell_options);oi++)if(global.spell_options[oi].id==-2)offered=true;global.game_paused=false;global.chest_collected=false;}
            ft_check(offered,"weapon upgrade cards appear in the offers");
            repeat(5)learn_spell(-2);ft_check(weapon_upgrade_level()==weapon_upgrade_max() && !learn_spell(-2),"weapon upgrades stop at level 5");
            weapon_upgrade_reset();apply_passives(pl);
            global.ft_stage=3;global.ft_frame=0;break;
        case 3: // equipment
            var armor0=pl.armor_flat;
            var chest=equipment_generate("chest",2,5);
            ft_check(is_struct(chest) && array_length(chest.order)==3 && chest.order[0]=="armor","rare chest has 3 stats with armor first");
            ft_check(equipment_receive(chest) && global.equipment.chest==chest,"first chest is auto-equipped");
            apply_passives(pl);
            ft_check(abs(pl.armor_flat-(armor0+chest.stats.armor))<.0001,"chest armor is applied ("+string(pl.armor_flat)+")");
            var chest2=equipment_generate("chest",0,1);
            ft_check(equipment_receive(chest2) && array_length(global.equipment_backpack)==1 && global.equipment.chest==chest,"second chest goes to the backpack");
            equipment_equip(chest2);array_delete(global.equipment_backpack,0,1);
            ft_check(global.equipment.chest==chest2 && array_length(global.equipment_backpack)==1 && global.equipment_backpack[0]==chest,"swap puts the old item into the backpack");
            var weapon=equipment_generate("weapon",1,3);equipment_receive(weapon);apply_passives(pl);
            ft_check(abs(pl.weapon_damage_mult-(1+weapon.stats.weapon_pct))<.0001,"weapon item raises the class weapon multiplier");
            var drops0=array_length(global.equipment_drops);
            equipment_boss_drop({x:pl.x+400,y:pl.y,boss_data:{main:true}});
            ft_check(array_length(global.equipment_drops)==drops0+2,"main boss drops two items");
            var best=0;for(var i=drops0;i<array_length(global.equipment_drops);i++)best=max(best,global.equipment_drops[i].item.rarity);
            ft_check(best>=2,"main boss drop contains at least a rare item");
            equipment_boss_drop({x:pl.x+400,y:pl.y,boss_data:{main:false}});
            ft_check(array_length(global.equipment_drops)==drops0+3,"miniboss drops one item");
            var feet=equipment_generate("feet",1,2);equipment_drop(pl.x+10,pl.y,feet);
            global.ft_drop_count=array_length(global.equipment_drops);
            global.ft_stage=4;global.ft_frame=0;break;
        case 4: // walking over a drop picks it up
            if(global.ft_frame<4)return;
            ft_check(array_length(global.equipment_drops)==global.ft_drop_count-1 && global.equipment.feet!=undefined,"drop near the player is picked up and equipped");
            global.ft_world_shot="world-loot-"+cls;
            with(ObjectPlayer){x+=300;}
            equipment_drop(pl.x+60,pl.y+20,equipment_generate("head",3,9));equipment_drop(pl.x-70,pl.y+30,equipment_generate("trinket",2,9));
            global.ft_stage=5;global.ft_frame=0;break;
        case 5: // vfx: cast some effects for a world capture
            if(global.ft_frame==1) {
                var d=ft_spawn_dummy(pl.x+140,pl.y);
                spell_fx_burst(pl.x+140,pl.y,60,1);spell_fx_burst(pl.x-120,pl.y+40,70,2);spell_fx_burst(pl.x,pl.y-110,60,3);
                ft_check(array_length(global.spell_particles)>0,"spell bursts emit particles");
                array_push(global.spell_fields,{sid:107,level:5,kind:"field",element:1,x:pl.x-150,y:pl.y-40,sx:pl.x,sy:pl.y,ex:pl.x,ey:pl.y,age:0,next:99,ticks:0,radius:70,damage:0,duration:3,count:1,angle:0,hit_ids:[],return_done:false});
            }
            if(global.ft_frame==24){global.ft_world_shot="world-vfx-"+cls;ft_check(array_length(global.spell_particles)>5,"active field keeps emitting ("+string(array_length(global.spell_particles))+")");}
            if(global.ft_frame<30)return;
            ft_clear();global.ft_stage=6;global.ft_frame=0;break;
        case 6: // open the character screen with T, buy a node with the mouse, capture it
            talent_grant(2);
            global.ft_press_key=ord("T");
            global.ft_stage=7;global.ft_frame=0;break;
        case 7:
            if(global.ft_frame==2)ft_check(global.talent_menu_active && global.game_paused,"T opens the character screen and pauses");
            if(global.ft_frame==4) {
                var L=talent_menu_layout(),node=talent_find("g_scav"),p=talent_node_pos(L,node);
                global.ft_mx=p.x;global.ft_my=p.y;global.ft_before=talent_rank("g_scav");
            }
            if(global.ft_frame==6)global.ft_mouse_press=mb_left;
            if(global.ft_frame==9)ft_check(talent_rank("g_scav")==global.ft_before+1,"mouse click on a node invests a point");
            if(global.ft_frame==12){var L=talent_menu_layout(),G=equipment_panel_geometry(L),r=equipment_bag_rect(G,0);global.ft_mx=r.x+5;global.ft_my=r.y+5;}
            if(global.ft_frame==16)global.ft_shot="character-"+cls;
            if(global.ft_frame==22){global.ft_press_key=vk_escape;}
            if(global.ft_frame==26){ft_check(!global.talent_menu_active && !global.game_paused,"Escape closes the screen and resumes");global.ft_stage=8;global.ft_frame=0;}
            break;
        case 8: // class mechanics with talents
            ft_clear();
            if(cls=="Sword") {
                var d=ft_spawn_dummy(pl.x+60,pl.y);
                global.talent_ranks[$ "s_wave"]=2;talent_rebuild_cache();
                var fx0=array_length(global.class_effects);
                with(pl){sword_combo_active=false;weapon_cooldown=0;master_sword_start(d);repeat(80){sword_combo_clock+=1;if(sword_combo_active)master_sword_step();}}
                var found=false;for(var i=0;i<array_length(global.class_effects);i++)if(global.class_effects[i].kind=="sword_wave")found=true;
                ft_check(found,"Wellenfinale adds a shockwave after the third hit");
            } else if(cls=="Mage") {
                global.talent_ranks[$ "m_star"]=2;talent_rebuild_cache();
                pl.class_target_x=pl.x+200;pl.class_target_y=pl.y;
                class_weapon_release(pl,4);var f=global.class_effects[array_length(global.class_effects)-1];
                ft_check(abs(f.radius-170*pl.spell_area*1.24)<.5,"Sternenkunde raises the star radius ("+string(f.radius)+")");
            } else {
                global.talent_ranks[$ "r_volley"]=2;talent_rebuild_cache();
                var n0=instance_number(ObjectLightningball);pl.attack_direction=0;class_weapon_release(pl,3);
                ft_check(instance_number(ObjectLightningball)-n0==5,"Breite Salve 2: three-arrow step fires 5 arrows ("+string(instance_number(ObjectLightningball)-n0)+")");
                n0=instance_number(ObjectLightningball);class_weapon_release(pl,9);
                ft_check(instance_number(ObjectLightningball)-n0==7,"Breite Salve 2: five-arrow step fires 7 arrows");
                n0=instance_number(ObjectLightningball);class_weapon_release(pl,1);
                ft_check(instance_number(ObjectLightningball)-n0==1,"single arrow step stays single");
            }
            global.ft_stage=13;global.ft_frame=0;break;
        case 13: // last stand capstone
            if(global.ft_frame==1) {
                global.talent_ranks[$ "g_last"]=1;talent_rebuild_cache();global.talent_last_stand_used=false;
                pl.hp=5;player_receive_damage(pl,500,"all");
                ft_check(pl.hp==1 && !global.game_over,"Ueberlebenswille converts a lethal hit into 1 HP");
                player_receive_damage(pl,500,"all");
                ft_check(pl.hp==1 && !global.game_over,"short invulnerability after Ueberlebenswille");
            }
            if(global.ft_frame==120) {
                player_receive_damage(pl,500,"all");
                ft_check(global.game_over,"second lethal hit later ends the run");
                global.ft_metrics[$ cls+"_particles_peak"]=array_length(global.spell_particles);
            }
            if(global.ft_frame<130)return;
            global.ft_stage=0;global.ft_class++;
            if(global.ft_class>=3)global.ft_done=true;
            round_end_to_title();break;
    }
}
function ft_gui_capture_begin() {
    if(!variable_global_exists("ft_shot") || global.ft_shot=="")return;
    global.ft_surface=surface_create(display_get_gui_width(),display_get_gui_height());
    surface_set_target(global.ft_surface);draw_clear_alpha(c_black,1);
}
function ft_gui_capture_end() {
    if(!variable_global_exists("ft_shot") || global.ft_shot=="" || !surface_exists(global.ft_surface))return;
    surface_reset_target();surface_save(global.ft_surface,"ftcapture-"+global.ft_shot+".png");
    draw_surface(global.ft_surface,0,0);surface_free(global.ft_surface);global.ft_shot="";
}
function ft_world_capture() {
    if(!variable_global_exists("ft_world_shot") || global.ft_world_shot=="")return;
    if(surface_exists(application_surface))surface_save(application_surface,"ftcapture-"+global.ft_world_shot+".png");
    global.ft_world_shot="";
}
