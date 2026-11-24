// Audio playback API assertions, only compiled into the isolated runtime fixture.
function af_count(_event) {
    var a=global.fg_audio;
    return variable_struct_exists(a.requests,_event) ? variable_struct_get(a.requests,_event) : 0;
}
function af_fixture() {
    fg_audio_init();
    var a=global.fg_audio,pl=global.player;
    var saved_master=global.master_volume,saved_music=global.music_volume,saved_effects=global.effects_volume;
    global.master_volume=0;audio_master_gain(0); // Device playback is exercised without speaker noise.
    // Real event paths not otherwise covered by the combat fixtures.
    var coin=instance_create_layer(pl.x,pl.y,"Instances",ObjectCoin),before=af_count("coin");
    with(coin) event_perform(ev_collision,ObjectPlayer);
    gp_check(af_count("coin")==before+1,"coin collision emits one audio event");
    var e=instance_create_layer(pl.x+75,pl.y,"Instances",ObjectMonster);e.hp=0;
    with(e) event_perform(ev_step,0);
    gp_check(af_count("enemy_death")>0,"real monster death emits audio");
    gp_clear_enemies();
    var target=instance_create_layer(pl.x+150,pl.y,"Instances",ObjectMonster);target.hp=10000;
    var saved_weapon=pl.weapon;
    pl.weapon=weapon_definition("Ranger");pl.weapon_cooldown=0;with(pl) weapon_auto_step();
    with(ObjectLightningball) repeat(30) spell_projectile_step();
    pl.weapon=weapon_definition("Mage");pl.weapon_cooldown=0;with(pl) weapon_auto_step();
    pl.weapon=saved_weapon;
    gp_check(af_count("crossbow")>0 && af_count("arrow_hit")>0 && af_count("magic_projectile")>0,"ranged weapon launch and actual impact are wired");
    gp_clear_enemies();
    before=af_count("ui_hover");repeat(10) fg_audio_hover(1,1);
    gp_check(af_count("ui_hover")==before,"stationary menu selection produces no hover spam");
    fg_audio_hover(1,2);gp_check(af_count("ui_hover")==before+1,"selection transition emits hover event");
    pl.hp=pl.max_hp;pl.invulnerable_timer=0;pl.motion_state=0;pl.dodge_timer=0;
    player_receive_damage(pl,100000);
    gp_check(global.game_over && af_count("game_over")>0,"fatal real damage emits game-over audio");
    global.game_over=false;global.game_paused=false;pl.hp=pl.max_hp;pl.invulnerable_timer=0;
    var names=variable_struct_get_names(fg_audio_bank());
    for(var i=0;i<array_length(names);i++) {
        fg_audio_stop_effects();a.last_sfx={};
        var event=names[i],asset=variable_struct_get(fg_audio_bank(),event);
        gp_check(audio_exists(asset) && audio_sound_length(asset)>0,"imported audible resource "+event);
        var handle=fg_sfx(event);
        gp_check(handle>=0 && audio_is_playing(handle),"actual audio playback handle "+event);
    }
    fg_audio_stop_effects();a.last_sfx={};
    var peak_voices=0;
    repeat(25) {a.last_sfx={};fg_sfx("game_over");peak_voices=max(peak_voices,array_length(a.voices));}
    gp_check(peak_voices>0 && peak_voices<=16,"effect voice cap holds even as backend voices finish/recycle");
    show_debug_message("AUDIO_PEAK_EFFECT_VOICES "+string(peak_voices));
    fg_audio_stop_effects();
    fg_music_set("menu");var starts=a.music_starts;var menu_handle=a.current;
    repeat(10) fg_music_set("menu");
    gp_check(a.music_starts==starts && a.current==menu_handle,"same music context does not start duplicate tracks");
    fg_music_set("level");var level_handle=a.current;
    var boss=boss_spawn("storm_warden");
    gp_check(a.context=="boss" && audio_is_playing(a.current),"real boss spawn chooses boss music");
    gp_check(!audio_is_playing(menu_handle),"rapid transitions retire superseded music");
    gp_check(a.retiring==level_handle && audio_is_playing(a.retiring),"only current and intentional crossfade predecessor coexist");
    global.music_volume=0.25;global.effects_volume=0.75;fg_audio_tick(1);
    gp_check(a.retiring==-1 && abs(audio_sound_get_gain(a.current)-0.25)<0.001,"crossfade ends with one music voice at music volume");
    a.last_sfx={};var handle=fg_sfx("coin");fg_audio_tick(0.01);
    gp_check(abs(audio_sound_get_gain(handle)-0.55*0.75)<0.001,"effects volume is independent of music");
    global.effects_volume=0.25;fg_audio_tick(0.01);
    gp_check(abs(audio_sound_get_gain(handle)-0.55*0.25)<0.001,"live effects volume updates existing voices");
    global.game_paused=true;fg_audio_tick(0.01);
    gp_check(abs(audio_sound_get_gain(a.current)-0.25*0.45)<0.001,"pause ducks music without duplicating it");
    global.game_paused=false;
    boss.hp=0;boss_step(boss,1/60);
    gp_check(a.context=="level","real boss victory returns level music");
    fg_audio_stop_effects();
    global.master_volume=saved_master;global.music_volume=saved_music;global.effects_volume=saved_effects;
    global.coins=0;
}
