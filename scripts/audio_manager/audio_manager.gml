/// Persistent audio state, owned sound handles, bounded effects and short music crossfades.
function fg_audio_bank() {
    static bank={magic_hit:sfx_fg_magic_hit,ice_hit:sfx_fg_ice_hit,arcane_hit:sfx_fg_arcane_hit,nova_cast:sfx_fg_nova_cast,heal_cast:sfx_fg_heal_cast,shock_hit:sfx_fg_shock_hit,ui_hover:sfx_fg_ui_hover,ui_click:sfx_fg_ui_click,ui_back:sfx_fg_ui_back,
        character_select:sfx_fg_character_select,game_start:sfx_fg_game_start,
        sword_swing:sfx_fg_sword_swing,sword_hit:sfx_fg_sword_hit,crossbow:sfx_fg_crossbow,arrow_hit:sfx_fg_arrow_hit,
        magic_projectile:sfx_fg_magic_projectile,fireball:sfx_fg_fireball,explosion:sfx_fg_explosion,
        lightning:sfx_fg_lightning,ice:sfx_fg_ice,player_hit:sfx_fg_player_hit,enemy_death:sfx_fg_enemy_death,
        coin:sfx_fg_coin,level_up:sfx_fg_level_up,spell_select:sfx_fg_spell_select,spell_upgrade:sfx_fg_spell_upgrade,
        jump:sfx_fg_jump,dodge:sfx_fg_dodge,slide:sfx_fg_slide,game_over:sfx_fg_game_over,
        boss_spawn:sfx_fg_boss_spawn,boss_phase:sfx_fg_boss_phase,boss_defeated:sfx_fg_boss_defeated};
    static v2_loaded=false;
    if(!v2_loaded){for(var sid=101;sid<=118;sid++)variable_struct_set(bank,"skill_"+string(sid),asset_get_index("sfx_fg_skill_"+string(sid)));v2_loaded=true;}
    static classes_loaded=false;
    static bosses_loaded=false;
    if(!bosses_loaded){for(var family=0;family<2;family++)for(var i=1;i<=9;i++){var cue=(family==0 ? "twins_" : "swamp_")+string(i);variable_struct_set(bank,cue,asset_get_index("sfx_fg_"+cue));}bosses_loaded=true;}
    if(!classes_loaded){var names=["mage_bolt","mage_arc","mage_circle","mage_star","mage_implosion","ranger_arrow","ranger_volley","ranger_rain","dragon_fire","dragon_charge","dragon_meteor","dragon_slam","dragon_wind","dragon_void","dragon_magma","dragon_vortex"];for(var i=0;i<array_length(names);i++)variable_struct_set(bank,names[i],asset_get_index("sfx_fg_"+names[i]));classes_loaded=true;}
    return bank;
}
function fg_audio_init() {
    if(variable_global_exists("fg_audio")) return;
    if(!variable_global_exists("audio_background")) {
        ini_open("firstgame_audio.ini");global.audio_background=ini_read_real("Audio","background",0)!=0;ini_close();
    }
    if(!variable_global_exists("master_volume")) global.master_volume=1;
    if(!variable_global_exists("music_volume")) global.music_volume=0.65;
    if(!variable_global_exists("effects_volume")) global.effects_volume=0.8;
    global.fg_audio={context:"",asset:-1,current:-1,retiring:-1,fade:1,retire_level:0,
        voices:[],last_sfx:{},requests:{},played:{},music_starts:0,skipped:0};
    audio_channel_num(24);
    fg_audio_apply_focus(window_has_focus());
}
function fg_audio_prune() {
    var a=global.fg_audio;
    for(var i=array_length(a.voices)-1;i>=0;i--) if(!audio_is_playing(a.voices[i].handle)) array_delete(a.voices,i,1);
}
function fg_audio_stop_effects() {
    fg_audio_init();
    var a=global.fg_audio;
    for(var i=0;i<array_length(a.voices);i++) audio_stop_sound(a.voices[i].handle);
    a.voices=[];
}
function fg_sfx(_event) {
    fg_audio_init();
    var a=global.fg_audio,bank=fg_audio_bank();
    if(!variable_struct_exists(bank,_event)) return -1;
    var requests=variable_struct_exists(a.requests,_event) ? variable_struct_get(a.requests,_event) : 0;
    variable_struct_set(a.requests,_event,requests+1);
    var interval=70;
    if(_event=="ui_hover") interval=35;
    if(_event=="explosion") interval=140;
    if(_event=="coin") interval=55;
    var last=variable_struct_exists(a.last_sfx,_event) ? variable_struct_get(a.last_sfx,_event) : -10000;
    if(current_time-last<interval) {a.skipped++;return -1;}
    fg_audio_prune();
    var same=0;for(var i=0;i<array_length(a.voices);i++)if(a.voices[i].event==_event)same++;
    if(same>=2){a.skipped++;return -1;}
    var important=array_contains(["game_over","level_up","boss_spawn","boss_phase","boss_defeated","spell_select","spell_upgrade"],_event);
    if(array_length(a.voices)>=16) {
        if(!important) {a.skipped++;return -1;}
        audio_stop_sound(a.voices[0].handle);array_delete(a.voices,0,1);
    }
    var handle=audio_play_sound(variable_struct_get(bank,_event),important ? 30 : 10,false);
    if(handle<0) return -1;
    var gain=important ? 0.8 : 0.55;
    audio_sound_gain(handle,gain*clamp(global.effects_volume,0,1),0);
    // Repeated cues vary slightly in pitch (+-5 %) so rapid fire does not sound mechanical. Deterministic, no RNG.
    if(!important)audio_sound_pitch(handle,1+((requests mod 5)-2)*.025);
    array_push(a.voices,{handle:handle,gain:gain,event:_event});
    variable_struct_set(a.last_sfx,_event,current_time);
    var played=variable_struct_exists(a.played,_event) ? variable_struct_get(a.played,_event) : 0;
    variable_struct_set(a.played,_event,played+1);
    return handle;
}
function fg_music_set(_context) {
    fg_audio_init();
    var a=global.fg_audio,asset=-1;
    if(_context=="menu") asset=mus_fg_menu;
    if(_context=="level") asset=level_music_asset(); // Per-level track when imported, otherwise mus_fg_level.
    if(_context=="boss") asset=mus_fg_boss;
    if(a.context==_context && (asset==-1 || audio_is_playing(a.current))) return;
    if(a.retiring!=-1) audio_stop_sound(a.retiring);
    a.retiring=a.current;a.retire_level=a.fade;
    a.context=_context;a.asset=asset;a.current=-1;a.fade=0;
    if(asset!=-1) {
        a.current=audio_play_sound(asset,100,true);
        audio_sound_gain(a.current,0,0);
        a.music_starts++;
    }
}
function fg_audio_tick(_dt) {
    fg_audio_init();
    var a=global.fg_audio;
    var context="menu";
    if(room!=RoomMenu) {
        context="level";
        if(!global.round_active || global.game_over) context="none";
        else if(instance_exists(global.active_boss)) context="boss";
    }
    fg_music_set(context);
    a.fade=min(1,a.fade+max(0,_dt)/0.65);
    var duck=(room!=RoomMenu && global.game_paused && !global.game_over) ? 0.45 : 1;
    // While a boss hazard is in its warning phase the music dips smoothly to 72 %, so warning cues stand out.
    var danger=false;
    if(variable_global_exists("bv2_hazards"))for(var i=0;i<array_length(global.bv2_hazards);i++){var h=global.bv2_hazards[i];if(h.age<h.warning){danger=true;break;}}
    if(!variable_struct_exists(a,"danger_duck"))a.danger_duck=1;
    a.danger_duck=lerp(a.danger_duck,danger ? .72 : 1,min(1,max(0,_dt)*6));
    var music=clamp(global.music_volume,0,1)*duck*a.danger_duck;
    fg_audio_apply_focus(window_has_focus());
    if(a.current!=-1) audio_sound_gain(a.current,music*a.fade,0);
    if(a.retiring!=-1) {
        audio_sound_gain(a.retiring,music*a.retire_level*(1-a.fade),0);
        if(a.fade>=1 || !audio_is_playing(a.retiring)) {audio_stop_sound(a.retiring);a.retiring=-1;}
    }
    fg_audio_prune();
    for(var i=0;i<array_length(a.voices);i++) audio_sound_gain(a.voices[i].handle,a.voices[i].gain*clamp(global.effects_volume,0,1),0);
}
function fg_audio_cycle_volume(_which) {
    fg_audio_init();
    var value=variable_global_get(_which);
    variable_global_set(_which,value>=1 ? 0 : min(1,value+0.25));
    fg_audio_apply_focus(window_has_focus());
}
function fg_audio_volume_label(_index) {
    var values=[global.master_volume,global.music_volume,global.effects_volume];
    return ": "+string(round(values[_index-1]*100))+" %";
}

function fg_audio_hover(_before,_after) {
    if(_before!=_after) return fg_sfx("ui_hover");
    return -1;
}

function fg_audio_apply_focus(_focused) {
    fg_audio_init();
    global.fg_audio.focused=_focused;
    global.fg_audio.effective_master=clamp(global.master_volume,0,1)*((_focused || global.audio_background) ? 1 : 0);
    audio_master_gain(global.fg_audio.effective_master);
}
function fg_audio_toggle_background() {
    global.audio_background=!global.audio_background;
    ini_open("firstgame_audio.ini");ini_write_real("Audio","background",global.audio_background ? 1 : 0);ini_close();
    fg_audio_apply_focus(window_has_focus());
}
