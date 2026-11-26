/// Scene recorder harness (prefix sc, tag SCENE), driven by tests/tools/record_scene.py.
/// The recorder prepends the macros SC_SCENE, SC_CLASS, SC_LEVEL_INDEX, SC_SPELL, SC_SPELL_LEVEL, SC_BOSS, SC_MINUTE,
/// SC_ABILITY (forced boss ability, -1 = rotation), SC_START, SC_FRAMES and SC_EVERY, and replaces delta_time with a fixed 60 Hz step, so every saved frame is one game frame.
/// Scenes: walk, combat, spell, boss, horde. This is a capture tool, not a test: it only reports how many frames it saved.

// Scripted input: global.sc_move is a screen direction in degrees (-1 = stand), global.sc_press one key for one frame.
function gp_key_down(_key) {
    if(!variable_global_exists("sc_move") || global.sc_move<0)return false;
    var dx=lengthdir_x(1,global.sc_move),dy=lengthdir_y(1,global.sc_move);
    if(_key==ord("D"))return dx>.38;
    if(_key==ord("A"))return dx<-.38;
    if(_key==ord("S"))return dy>.38;
    if(_key==ord("W"))return dy<-.38;
    return false;
}
function gp_key_pressed(_key) {return variable_global_exists("sc_press") && global.sc_press==_key;}
function gp_mouse_down(_button) {return false;}
function gp_mouse_pressed(_button) {return false;}
function gp_mouse_x() {return instance_exists(ObjectPlayer) ? ObjectPlayer.x+200 : 0;}
function gp_mouse_y() {return instance_exists(ObjectPlayer) ? ObjectPlayer.y : 0;}
function gp_gui_x(_device) {return -100;}
function gp_gui_y(_device) {return -100;}
function sc_show_error(_msg,_abort=false) {show_debug_message("SCENE_EXCEPTION show_error "+string(_msg));throw string(_msg);}
function sc_gui_capture_begin() {}
function sc_gui_capture_end() {}
function sc_world_capture() {
    if(!variable_global_exists("sc_shot") || global.sc_shot<0)return;
    surface_save(application_surface,"sccapture-"+string_replace_all(string_format(global.sc_shot,4,0)," ","0")+".png");
    global.sc_saved++;global.sc_shot=-1;
}
function sc_class_index() {return SC_CLASS=="Mage" ? 1 : (SC_CLASS=="Ranger" ? 2 : 0);}
function sc_menu_tick() {
    if(!variable_global_exists("sc_stage")){global.sc_stage=0;global.sc_frame=0;global.sc_shot=-1;global.sc_move=-1;global.sc_press=-1;global.sc_saved=0;global.sc_dummies=[];}
    if(global.sc_stage!=0)return;
    global.sc_stage=1;menu_mode="main";
    if(SC_SCENE=="boss"){boss_test_start(SC_BOSS,15,SC_CLASS,1337,SC_ABILITY,false,1);return;}
    menu_activate(0);menu_activate(sc_class_index());menu_activate(SC_LEVEL_INDEX);
}
// Enemy from the level's own pool that stays alive and harmless (hit reactions stay visible).
function sc_dummy(_x,_y,_move,_tough=true) {
    var e=population_spawn_enemy_base(_x,_y);if(!instance_exists(e))return noone;
    e.damage=0;if(_tough){e.hp=999999;e.max_hp=999999;}if(!_move)e.base_move_speed=0;
    array_push(global.sc_dummies,e);return e;
}
function sc_setup() {
    var pl=ObjectPlayer;global.sc_cx=pl.x;global.sc_cy=pl.y;
    if(SC_SCENE!="boss" && SC_SCENE!="horde")with(ObjectMonster)instance_destroy();
    // combat: six approaching enemies, every third one can die (death and remains on film)
    if(SC_SCENE=="combat")for(var i=0;i<6;i++)sc_dummy(pl.x+lengthdir_x(170+(i mod 2)*60,i*60+15),pl.y+lengthdir_y(150+(i mod 2)*50,i*60+15),true,i mod 3!=0);
    if(SC_SCENE=="spell"){global.vfx_band_override=vfx_band(SC_SPELL_LEVEL);for(var i=0;i<3;i++)sc_dummy(pl.x+170+i*55,pl.y-50+i*50,false);}
    if(SC_SCENE=="spellsheet"){global.vfx_band_override=vfx_band(SC_SPELL_LEVEL);for(var i=0;i<3;i++)sc_dummy(pl.x+120+i*40,pl.y-30+i*30,false);} // targets inside the 560x315 crop
    if(SC_SCENE=="horde"){global.round_seconds=SC_MINUTE*60;if(instance_exists(ObjectSpawner))ObjectSpawner.population_timer=0;}
}
function sc_cast(_t) {
    if(_t!=10 && _t!=110 && _t!=210)return;
    var pl=ObjectPlayer,target=noone;
    for(var i=0;i<array_length(global.sc_dummies);i++)if(instance_exists(global.sc_dummies[i])){target=global.sc_dummies[i];break;}
    if(SC_SPELL==SPELL.HEAL)pl.hp=pl.max_hp*.5;
    global.spell_fields=[];global.spell_bursts=[];
    cast_spell({id:SC_SPELL,level:SC_SPELL_LEVEL,cooldown:0,cooldown_timer:0},SC_SPELL==SPELL.HEAL ? undefined : target);
}
function sc_drive(_t) {
    var pl=ObjectPlayer;global.sc_move=-1;
    if(SC_SCENE=="walk") {
        // right, diagonal, left, stop (settle), jump while walking up, stop
        if(_t<60)global.sc_move=0;else if(_t<100)global.sc_move=315;else if(_t<160)global.sc_move=180;
        else if(_t>=190 && _t<240)global.sc_move=90;
        if(_t==192)global.sc_press=vk_space;
    } else if(SC_SCENE=="spell") {
        pl.weapon_cooldown=99999;pl.class_pending=0;sc_cast(_t);
    } else if(SC_SCENE=="spellsheet") {
        // all 18 active spells (101-118) at SC_SPELL_LEVEL, one per 90 frames: cleared at 0, cast at 5
        pl.weapon_cooldown=99999;pl.class_pending=0;
        var k=_t div 90,o=_t mod 90;if(k>=18)return;
        if(o==0){global.spell_fields=[];global.spell_bursts=[];global.spell_particles=[];with(ObjectFireball)instance_destroy();with(ObjectIceball)instance_destroy();with(ObjectLightningball)instance_destroy();}
        if(o==5){var target=noone;for(var i=0;i<array_length(global.sc_dummies);i++)if(instance_exists(global.sc_dummies[i])){target=global.sc_dummies[i];break;}
            if(101+k==SPELL.HEAL)pl.hp=pl.max_hp*.5;
            cast_spell({id:101+k,level:SC_SPELL_LEVEL,cooldown:0,cooldown_timer:0},101+k==SPELL.HEAL ? undefined : target);}
    } else if(SC_SCENE=="boss" || SC_SCENE=="horde") {
        // Circle-strafe: around the boss at ~300 px, in the horde around the start point.
        var cx=global.sc_cx,cy=global.sc_cy,r=SC_SCENE=="boss" ? 300 : 160;
        if(SC_SCENE=="boss"){if(!instance_exists(global.active_boss))return;cx=global.active_boss.x;cy=global.active_boss.y;}
        var a=point_direction(cx,cy,pl.x,pl.y),dist=point_distance(cx,cy,pl.x,pl.y);
        global.sc_move=a+90+60*clamp((dist-r)/80,-1,1);
    }
}
function sc_controller_tick() {
    if(!variable_global_exists("sc_stage") || !instance_exists(ObjectPlayer))return;
    global.sc_frame++;var f=global.sc_frame,pl=ObjectPlayer;global.sc_press=-1;
    pl.hp=max(pl.hp,pl.max_hp*.9);
    // --boss-hp: start the boss in a later phase (phase follows HP), once
    if(SC_BOSS_HP<1 && instance_exists(global.active_boss) && !variable_global_exists("sc_hp_set")){global.sc_hp_set=true;global.active_boss.hp=global.active_boss.max_hp*SC_BOSS_HP;}
    if(SC_SCENE=="boss"){if(variable_global_exists("boss_test") && is_struct(global.boss_test))global.boss_test.invulnerable=true;}
    else {
        global.next_levelup_time=1000000000;
        if(SC_SCENE!="horde" && instance_exists(ObjectSpawner))ObjectSpawner.population_timer=999;
    }
    if(f==20)sc_setup();
    if(f>20)sc_drive(f-21);
    var t=f-21-SC_START;
    global.sc_shot=(t>=0 && t<SC_FRAMES*SC_EVERY && t mod SC_EVERY==0) ? t div SC_EVERY : -1;
    if(t>=SC_FRAMES*SC_EVERY+2) {
        show_debug_message("SCENE_RESULT "+json_stringify({passed:global.sc_saved>0,checks:1,failures:[],metrics:{frames:global.sc_saved,scene:SC_SCENE}}));
        game_end();
    }
}
