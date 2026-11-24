/// Talent trees: a data-driven system separate from the six active / six passive spell slots.
/// No earlier talent specification existed in the project or the Codex prompts (see DEVELOPMENT_PROGRESS.md);
/// point sources and persistence are therefore configuration values, not hard-wired rules.
function talent_config() {
    static cfg={
        first_point_level:4,   // first talent point at player level 4 ...
        level_interval:4,      // ... then one point every further 4 levels (8, 12, 16, ...)
        boss_points:1,         // per defeated main boss (minibosses: miniboss_points)
        miniboss_points:0,
        persistent:false,      // false: talents belong to one run. true: ranks/points persist per class in save_file.
        save_file:"firstgame_talents.ini"
    };
    return cfg;
}
/// tree: "general" for every class, otherwise the class key. col/row place the node in a 3 x 4 grid.
/// fx: per-rank values read through talent_stat(key). req: [[talent_id, minimum_rank], ...].
function talent_definitions() {
    static defs=[
        // ---------- Allgemein ----------
        {id:"g_vigor",tree:"general",name:"Zaehigkeit",icon:"icon_v2_205",col:0,row:0,max:3,req:[],fx:{max_hp:6},desc:"+{max_hp} maximales Leben."},
        {id:"g_stride",tree:"general",name:"Leichtfuessig",icon:"icon_v2_203",col:1,row:0,max:3,req:[],fx:{move_pct:.03},desc:"+{move_pct}% Bewegungstempo."},
        {id:"g_scav",tree:"general",name:"Sammlerblick",icon:"icon_v2_216",col:2,row:0,max:2,req:[],fx:{pickup:12},desc:"+{pickup} Pixel Sammelradius."},
        {id:"g_hide",tree:"general",name:"Schutzhaut",icon:"icon_v2_214",col:0,row:1,max:3,req:[["g_vigor",2]],fx:{armor:.4},desc:"+{armor} flache Ruestung (Abzug je Treffer)."},
        {id:"g_breath",tree:"general",name:"Zweiter Atem",icon:"icon_v2_204",col:1,row:1,max:3,req:[["g_stride",2]],fx:{dodge_cd:.1},desc:"Ausweichrolle {dodge_cd} s schneller wieder bereit."},
        {id:"g_focus",tree:"general",name:"Konzentration",icon:"icon_v2_210",col:2,row:1,max:3,req:[["g_scav",1]],fx:{cdr_pct:.02},desc:"Zauber-Abklingzeiten -{cdr_pct}%."},
        {id:"g_mend",tree:"general",name:"Lebenskraft",icon:"icon_v2_215",col:0,row:2,max:2,req:[["g_hide",1]],fx:{regen:.15},desc:"+{regen} Leben pro Sekunde."},
        {id:"g_luck",tree:"general",name:"Glueckstreffer",icon:"icon_v2_207",col:2,row:2,max:3,req:[["g_focus",2]],fx:{crit:.02},desc:"+{crit}% kritische Trefferchance."},
        {id:"g_last",tree:"general",name:"Ueberlebenswille",icon:"icon_fg_heart",col:1,row:3,max:1,req:[["g_mend",1],["g_breath",2]],fx:{last_stand:1},desc:"Einmal pro Run: Ein toedlicher Treffer laesst dich mit 1 Leben zurueck, danach 1,5 s unverwundbar."},
        // ---------- Schwertkaempfer: Nahkampf, Bewegung, kontrollierte Flaechen ----------
        {id:"s_edge",tree:"Sword",name:"Klingenschaerfe",icon:"icon_fg_sword",col:0,row:0,max:3,req:[],fx:{sword_dmg_pct:.06},desc:"Schwertkette +{sword_dmg_pct}% Schaden."},
        {id:"s_reach",tree:"Sword",name:"Weiter Schwung",icon:"icon_v2_209",col:1,row:0,max:3,req:[],fx:{sword_reach_pct:.06},desc:"Schwerthiebe +{sword_reach_pct}% Reichweite."},
        {id:"s_rhythm",tree:"Sword",name:"Kampfrhythmus",icon:"icon_v2_204",col:2,row:0,max:3,req:[],fx:{haste:.04},desc:"+{haste}% Angriffstempo der Startwaffe."},
        {id:"s_wave",tree:"Sword",name:"Wellenfinale",icon:"icon_v2_104",col:0,row:1,max:2,req:[["s_edge",2]],fx:{sword_wave:.35},desc:"Der dritte Hieb loest eine Druckwelle (Radius 95) mit {sword_wave}% Schaden aus."},
        {id:"s_charge",tree:"Sword",name:"Sturmangriff",icon:"icon_v2_203",col:2,row:1,max:2,req:[["s_rhythm",2]],fx:{sword_charge:.2},desc:"Nach einer Ausweichrolle: naechste Schwertkette innerhalb 1,5 s +{sword_charge}% Schaden."},
        {id:"s_stance",tree:"Sword",name:"Eiserne Haltung",icon:"icon_fg_defense",col:1,row:1,max:2,req:[["s_reach",1]],fx:{armor:.5},desc:"+{armor} flache Ruestung."},
        {id:"s_blood",tree:"Sword",name:"Blutrausch",icon:"icon_v2_106",col:0,row:2,max:2,req:[["s_wave",1]],fx:{sword_leech:2},desc:"Ein Finale, das mindestens einen Gegner erreicht, heilt {sword_leech} Leben."},
        {id:"s_whirl",tree:"Sword",name:"Klingensturm",icon:"icon_v2_109",col:1,row:3,max:1,req:[["s_wave",2],["s_charge",1]],fx:{sword_whirl:1},desc:"Jede vierte Schwertkette endet in einem Rundumhieb (360 Grad)."},
        // ---------- Zaubermeisterin: langsame, starke Kombos, grosse Effekte ----------
        {id:"m_power",tree:"Mage",name:"Arkane Macht",icon:"icon_v2_202",col:0,row:0,max:3,req:[],fx:{power:1},desc:"+{power} Power (Startwaffe und Zauber)."},
        {id:"m_glyph",tree:"Mage",name:"Weite Glyphen",icon:"icon_v2_209",col:1,row:0,max:3,req:[],fx:{area_pct:.05},desc:"+{area_pct}% Wirkflaeche."},
        {id:"m_ward",tree:"Mage",name:"Arkaner Schild",icon:"icon_v2_201",col:2,row:0,max:2,req:[],fx:{dr:.04},desc:"{dr}% weniger Schaden (Gesamtgrenze 60%)."},
        {id:"m_star",tree:"Mage",name:"Sternenkunde",icon:"icon_v2_113",col:0,row:1,max:2,req:[["m_power",2]],fx:{mage_star:.12},desc:"Sternenorb (Kombo 4): +{mage_star}% Radius und Schaden."},
        {id:"m_flow",tree:"Mage",name:"Zauberfluss",icon:"icon_v2_210",col:1,row:1,max:3,req:[["m_glyph",1]],fx:{cdr_pct:.03},desc:"Zauber-Abklingzeiten -{cdr_pct}%."},
        {id:"m_frost",tree:"Mage",name:"Bannkreis",icon:"icon_v2_115",col:2,row:1,max:2,req:[["m_glyph",2]],fx:{mage_slow:1.2},desc:"Der Magiekreis (Kombo 3) verlangsamt Gegner {mage_slow} s um 30%."},
        {id:"m_elem",tree:"Mage",name:"Elementarfokus",icon:"icon_v2_211",col:1,row:2,max:3,req:[["m_flow",2]],fx:{elem_pct:.05},desc:"+{elem_pct}% Feuer-, Kaelte- und Blitzbonus."},
        {id:"m_nova",tree:"Mage",name:"Supernova",icon:"icon_v2_118",col:1,row:3,max:1,req:[["m_star",2],["m_elem",1]],fx:{mage_nova:1},desc:"Die Sternen-Implosion zieht normale Gegner an und explodiert ein zweites Mal (50% Schaden)."},
        // ---------- Waldlaeufer: schnelle Schuesse, Salven, Pfeilhagel ----------
        {id:"r_tips",tree:"Ranger",name:"Scharfe Spitzen",icon:"icon_v2_108",col:0,row:0,max:3,req:[],fx:{ranger_dmg_pct:.08},desc:"Pfeile +{ranger_dmg_pct}% Schaden."},
        {id:"r_string",tree:"Ranger",name:"Schnelle Sehne",icon:"icon_v2_204",col:1,row:0,max:3,req:[],fx:{haste:.04},desc:"+{haste}% Angriffstempo der Startwaffe."},
        {id:"r_eye",tree:"Ranger",name:"Falkenauge",icon:"icon_v2_208",col:2,row:0,max:2,req:[],fx:{range_pct:.1},desc:"+{range_pct}% Reichweite der Startwaffe."},
        {id:"r_volley",tree:"Ranger",name:"Breite Salve",icon:"icon_v2_105",col:0,row:1,max:2,req:[["r_string",2]],fx:{ranger_volley:1},desc:"Drei- und Fuenf-Pfeil-Salven: +{ranger_volley} Pfeil."},
        {id:"r_rain",tree:"Ranger",name:"Dichter Hagel",icon:"icon_v2_113",col:2,row:1,max:2,req:[["r_tips",2]],fx:{ranger_rain:1},desc:"Pfeilhagel: +{ranger_rain} Einschlagwelle."},
        {id:"r_hunt",tree:"Ranger",name:"Jaegerinstinkt",icon:"icon_v2_203",col:1,row:1,max:3,req:[["r_eye",1]],fx:{move_pct:.03},desc:"+{move_pct}% Bewegungstempo."},
        {id:"r_crit",tree:"Ranger",name:"Praezision",icon:"icon_v2_207",col:1,row:2,max:3,req:[["r_hunt",1]],fx:{crit:.03},desc:"+{crit}% kritische Trefferchance."},
        {id:"r_quiver",tree:"Ranger",name:"Sturmkoecher",icon:"icon_v2_116",col:1,row:3,max:1,req:[["r_volley",1],["r_rain",1]],fx:{ranger_quiver:1},desc:"Jeder Pfeilhagel feuert zusaetzlich einen Faecher aus sieben Pfeilen."}
    ];
    return defs;
}
function talent_tree_title(_tree) {
    switch(_tree){case "general":return "ALLGEMEIN";case "Sword":return "SCHWERTKAEMPFER";case "Mage":return "ZAUBERMEISTERIN";default:return "WALDLAEUFER";}
}
function talent_tree_color(_tree) {
    switch(_tree){case "general":return make_color_rgb(233,196,118);case "Sword":return make_color_rgb(242,140,96);case "Mage":return make_color_rgb(176,132,255);default:return make_color_rgb(134,222,120);}
}
function talent_find(_id) {
    var defs=talent_definitions();
    for(var i=0;i<array_length(defs);i++)if(defs[i].id==_id)return defs[i];
    return undefined;
}
function talent_class_key() {return variable_global_exists("selected_character") ? global.selected_character : "Sword";}
function talent_applies(_def) {return _def.tree=="general" || _def.tree==talent_class_key();}

// ---------------- State ----------------
function talent_reset_run() {
    global.talent_ranks={};global.talent_points=0;global.talent_spent=0;global.talent_earned=0;
    global.talent_menu_active=false;global.talent_hover="";global.talent_mouse_armed=false;global.talent_flash=0;
    global.talent_last_stand_used=false;global.talent_tab=0;
    if(talent_config().persistent)talent_load();
    talent_rebuild_cache();
}
function talent_rank(_id) {
    if(!variable_global_exists("talent_ranks"))return 0;
    return variable_struct_exists(global.talent_ranks,_id) ? global.talent_ranks[$ _id] : 0;
}
/// Returns "" when investing is allowed, otherwise a readable German reason.
function talent_block_reason(_id) {
    var d=talent_find(_id);if(!is_struct(d))return "Unbekanntes Talent";
    if(!talent_applies(d))return "Gehoert zu einer anderen Klasse";
    if(talent_rank(_id)>=d.max)return "Maximaler Rang erreicht";
    for(var i=0;i<array_length(d.req);i++){var r=d.req[i];if(talent_rank(r[0])<r[1])return "Voraussetzung fehlt";}
    if(global.talent_points<=0)return "Keine Talentpunkte";
    return "";
}
function talent_requirements_met(_id) {
    var d=talent_find(_id);if(!is_struct(d))return false;
    for(var i=0;i<array_length(d.req);i++){var r=d.req[i];if(talent_rank(r[0])<r[1])return false;}
    return true;
}
function talent_invest(_id) {
    if(talent_block_reason(_id)!="")return false;
    global.talent_ranks[$ _id]=talent_rank(_id)+1;global.talent_points--;global.talent_spent++;
    talent_rebuild_cache();
    if(talent_config().persistent)talent_save();
    if(instance_exists(ObjectPlayer))apply_passives(ObjectPlayer);
    return true;
}
function talent_grant(_amount,_reason="") {
    if(_amount<=0)return;
    global.talent_points+=_amount;global.talent_earned+=_amount;global.talent_flash=3;
    if(_reason!="")feedback_toast_add("+"+string(_amount)+" Talentpunkt"+(_amount>1 ? "e" : "")+" ("+_reason+") - [T]",make_color_rgb(242,206,120));
    if(talent_config().persistent)talent_save();
}
function talent_on_level(_level) {
    var cfg=talent_config();
    if(_level>=cfg.first_point_level && (_level-cfg.first_point_level) mod cfg.level_interval==0)talent_grant(1,"Stufe "+string(_level));
}
function talent_on_boss_defeated(_main) {
    var cfg=talent_config();
    talent_grant(_main ? cfg.boss_points : cfg.miniboss_points,_main ? "Hauptboss" : "Miniboss");
}
/// Sum of rank * per-rank value for every node of the general tree and the current class tree.
function talent_rebuild_cache() {
    var cache={},defs=talent_definitions();
    for(var i=0;i<array_length(defs);i++) {
        var d=defs[i],rank=talent_rank(d.id);if(rank<=0 || !talent_applies(d))continue;
        var keys=variable_struct_get_names(d.fx);
        for(var k=0;k<array_length(keys);k++){var key=keys[k];cache[$ key]=(variable_struct_exists(cache,key) ? cache[$ key] : 0)+d.fx[$ key]*rank;}
    }
    global.talent_cache=cache;
}
function talent_stat(_key) {
    if(!variable_global_exists("talent_cache"))return 0;
    return variable_struct_exists(global.talent_cache,_key) ? global.talent_cache[$ _key] : 0;
}
function talent_save() {
    var cfg=talent_config(),cls=talent_class_key();
    ini_open(cfg.save_file);
    ini_write_real(cls,"points",global.talent_points);ini_write_real(cls,"earned",global.talent_earned);
    var defs=talent_definitions();
    for(var i=0;i<array_length(defs);i++)if(talent_applies(defs[i]))ini_write_real(cls,defs[i].id,talent_rank(defs[i].id));
    ini_close();
}
function talent_load() {
    var cfg=talent_config(),cls=talent_class_key();
    ini_open(cfg.save_file);
    global.talent_points=ini_read_real(cls,"points",0);global.talent_earned=ini_read_real(cls,"earned",0);
    var defs=talent_definitions();
    for(var i=0;i<array_length(defs);i++)if(talent_applies(defs[i])){var r=clamp(ini_read_real(cls,defs[i].id,0),0,defs[i].max);if(r>0)global.talent_ranks[$ defs[i].id]=r;}
    ini_close();
}
/// Readable effect text: {key} is replaced with rank * value (percent keys as percentages).
function talent_effect_text(_def,_rank) {
    var text=_def.desc,keys=variable_struct_get_names(_def.fx),r=max(1,_rank);
    for(var k=0;k<array_length(keys);k++) {
        var key=keys[k],v=_def.fx[$ key]*r,shown;
        if(string_pos("pct",key)>0 || key=="crit" || key=="dr" || key=="haste" || key=="sword_wave" || key=="sword_charge" || key=="mage_star")shown=string_format(v*100,0,v*100==floor(v*100) ? 0 : 1);
        else shown=string_format(v,0,v==floor(v) ? 0 : (abs(v*10-round(v*10))<0.001 ? 1 : 2));
        text=string_replace_all(text,"{"+key+"}",string_replace(shown," ",""));
    }
    return text;
}

// ---------------- Applying talents and equipment to the player ----------------
/// Called at the end of apply_passives: talents and equipment add to the rebuilt spell baselines.
function talent_equipment_apply(_pl) {
    var E=function(_k){return equipment_stat(_k);};
    _pl.player_power+=talent_stat("power")+E("power");
    _pl.moveSpeed*=1+talent_stat("move_pct")+E("move_pct");
    _pl.damage_reduction=min(.6,_pl.damage_reduction+talent_stat("dr")+E("dr"));
    _pl.weapon_haste+=talent_stat("haste")+E("haste");
    _pl.crit_chance+=talent_stat("crit")+E("crit");
    _pl.spell_area*=1+talent_stat("area_pct")+E("area_pct");
    _pl.spell_cdr=max(GetSpellData(SPELL.COOLDOWN).min_cooldown_factor,_pl.spell_cdr-talent_stat("cdr_pct")-E("cdr_pct"));
    var elem=talent_stat("elem_pct")+E("elem_pct");_pl.fire_bonus+=elem;_pl.cold_bonus+=elem;_pl.storm_bonus+=elem;
    _pl.armor_flat+=talent_stat("armor")+E("armor");
    _pl.regen_rate+=talent_stat("regen")+E("regen");
    _pl.pickup_radius+=talent_stat("pickup")+E("pickup");
    _pl.weapon_range_mult=1+talent_stat("range_pct");
    _pl.weapon_damage_mult=1+E("weapon_pct");
    var extra=round(talent_stat("max_hp")+E("max_hp"));
    var previous=variable_instance_exists(_pl,"extra_hp_bonus") ? _pl.extra_hp_bonus : 0;
    _pl.max_hp+=extra;
    if(extra>previous)_pl.hp=min(_pl.max_hp,_pl.hp+extra-previous);
    _pl.hp=min(_pl.hp,_pl.max_hp);_pl.extra_hp_bonus=extra;
}
/// Lethal-hit guard of the "Ueberlebenswille" capstone. Returns true when the hit was converted.
function talent_last_stand(_pl) {
    if(talent_stat("last_stand")<=0 || global.talent_last_stand_used)return false;
    global.talent_last_stand_used=true;_pl.hp=1;_pl.last_stand_until=global.round_seconds+1.5;
    feedback_toast_add("Ueberlebenswille!",make_color_rgb(255,214,120));light_pulse(_pl.x,_pl.y-20,220,make_color_rgb(255,226,150),1.2,.6);
    fg_sfx("level_up");return true;
}

// ---------------- Character screen (talents + equipment) ----------------
function talent_menu_open() {
    if(global.talent_menu_active || global.game_over || !global.round_active)return;
    global.talent_menu_active=true;global.game_paused=true;global.talent_mouse_armed=false;global.talent_hover="";
    global.equipment_hover=-1;fg_sfx("ui_click");
}
function talent_menu_close() {
    global.talent_menu_active=false;global.game_paused=false;global.pause_initialized=false;
    global.normal_pause_active=false;instance_activate_all();fg_sfx("ui_back");
    if(instance_exists(ObjectPlayer)){ObjectPlayer.mouse_move_armed=false;ObjectPlayer.menu_input_guard=1;apply_passives(ObjectPlayer);}
}
/// Controller hook. Returns true while the screen owns the frame (gameplay is paused).
function talent_menu_step() {
    if(!variable_global_exists("talent_menu_active"))talent_reset_run();
    global.talent_flash=max(0,global.talent_flash-max(0,delta_time/1000000));
    if(!global.talent_menu_active) {
        if(!global.game_paused && !global.game_over && global.round_active && keyboard_check_pressed(ord("T")))talent_menu_open();
        return global.talent_menu_active;
    }
    if(keyboard_check_pressed(vk_escape) || keyboard_check_pressed(ord("T"))){talent_menu_close();return true;}
    if(!mouse_check_button(mb_left) && !mouse_check_button(mb_right))global.talent_mouse_armed=true;
    var L=talent_menu_layout(),mx=device_mouse_x_to_gui(0),my=device_mouse_y_to_gui(0);
    global.talent_hover="";
    var defs=talent_definitions();
    for(var i=0;i<array_length(defs);i++) {
        var d=defs[i];if(!talent_applies(d))continue;
        var p=talent_node_pos(L,d);
        if(point_distance(mx,my,p.x,p.y)<=L.node*.58)global.talent_hover=d.id;
    }
    if(global.talent_mouse_armed && mouse_check_button_pressed(mb_left) && global.talent_hover!="") {
        if(talent_invest(global.talent_hover)){fg_sfx("spell_upgrade");light_pulse(ObjectPlayer.x,ObjectPlayer.y-20,140,talent_tree_color(talent_find(global.talent_hover).tree),.6,.3);}
        else fg_sfx("ui_back");
        global.talent_mouse_armed=false;
    }
    equipment_menu_step(L,mx,my);
    if(point_in_rectangle(mx,my,L.close_x,L.close_y,L.close_x+L.close_w,L.close_y+L.close_h) && global.talent_mouse_armed && mouse_check_button_pressed(mb_left))talent_menu_close();
    return true;
}
function talent_menu_layout() {
    var w=display_get_gui_width(),h=display_get_gui_height(),margin=16,top=64;
    var eq_w=clamp(w*.27,220,330),tree_w=(w-eq_w-margin*4)/2;
    var node=clamp(min(tree_w/5.2,(h-top-150)/6.2),34,52);
    return {w:w,h:h,top:top,margin:margin,node:node,
        eq_x:margin,eq_y:top,eq_w:eq_w,eq_h:h-top-margin-34,
        g_x:margin*2+eq_w,g_y:top,tree_w:tree_w,tree_h:h-top-margin-34,
        c_x:margin*3+eq_w+tree_w,c_y:top,
        close_w:150,close_h:30,close_x:w-margin-150,close_y:h-margin-30};
}
function talent_node_pos(_L,_def) {
    var base_x=_def.tree=="general" ? _L.g_x : _L.c_x,base_y=_L.g_y;
    var gap_y=min((_L.tree_h-70)/4.15,_L.node*2.1);
    return {x:base_x+_L.tree_w*(_def.col+.5)/3,y:base_y+50+_L.node*.6+_def.row*gap_y};
}
function talent_menu_draw() {
    var L=talent_menu_layout(),t=current_time/1000;
    draw_set_alpha(.93);draw_set_color(make_color_rgb(7,10,17));draw_rectangle(0,0,L.w,L.h,false);draw_set_alpha(1);
    draw_set_font(-1);draw_set_halign(fa_left);draw_set_valign(fa_top);
    draw_set_color(make_color_rgb(239,211,158));draw_text_transformed(L.margin,16,"CHARAKTER",1.25,1.25,0);
    var cls=talent_class_key(),cls_name=cls=="Mage" ? "Zaubermeisterin" : (cls=="Ranger" ? "Waldlaeufer" : "Schwertkaempfer");
    draw_set_color(make_color_rgb(170,186,199));draw_text(L.margin+150,22,cls_name+" | Stufe "+string(global.current_level));
    var pts=global.talent_points;
    draw_set_halign(fa_right);draw_set_color(pts>0 ? merge_color(make_color_rgb(242,206,120),c_white,.25+.25*sin(t*5)) : make_color_rgb(140,152,166));
    draw_text_transformed(L.w-L.margin,18,"Talentpunkte: "+string(pts),1.15,1.15,0);draw_set_halign(fa_left);
    equipment_panel_draw(L);
    var trees=["general",cls];
    for(var tr=0;tr<2;tr++) {
        var tree=trees[tr],x0=tr==0 ? L.g_x : L.c_x,col=talent_tree_color(tree);
        talent_frame_panel(x0,L.g_y,L.tree_w,L.tree_h,col);
        draw_set_halign(fa_center);draw_set_color(col);draw_text(x0+L.tree_w/2,L.g_y+12,talent_tree_title(tree));
        var spent=0,defs=talent_definitions();
        for(var i=0;i<array_length(defs);i++)if(defs[i].tree==tree)spent+=talent_rank(defs[i].id);
        draw_set_color(make_color_rgb(128,141,155));draw_text_transformed(x0+L.tree_w/2,L.g_y+30,"investiert: "+string(spent),.8,.8,0);draw_set_halign(fa_left);
    }
    var defs=talent_definitions();
    // Connections first, so nodes cover the line ends.
    for(var i=0;i<array_length(defs);i++) {
        var d=defs[i];if(!talent_applies(d))continue;var b=talent_node_pos(L,d);
        for(var r=0;r<array_length(d.req);r++) {
            var src=talent_find(d.req[r][0]);if(!is_struct(src))continue;var a=talent_node_pos(L,src);
            var ok=talent_rank(src.id)>=d.req[r][1];
            draw_set_color(ok ? merge_color(talent_tree_color(d.tree),c_white,.15) : make_color_rgb(52,60,72));draw_set_alpha(ok ? .9 : .7);
            draw_line_width(a.x,a.y+L.node*.5,b.x,b.y-L.node*.5,ok ? 3 : 2);
            if(ok){draw_set_alpha(.35+.25*sin(t*3+i));draw_set_color(c_white);draw_line_width(a.x,a.y+L.node*.5,b.x,b.y-L.node*.5,1);}
            draw_set_alpha(1);
        }
    }
    for(var i=0;i<array_length(defs);i++){var d=defs[i];if(talent_applies(d))talent_node_draw(L,d,t);}
    // Close button and footer
    spell_ui_panel(L.close_x,L.close_y,L.close_w,L.close_h,point_in_rectangle(device_mouse_x_to_gui(0),device_mouse_y_to_gui(0),L.close_x,L.close_y,L.close_x+L.close_w,L.close_y+L.close_h));
    draw_set_halign(fa_center);draw_set_valign(fa_middle);draw_set_color(c_white);draw_text(L.close_x+L.close_w/2,L.close_y+L.close_h/2,"Zurueck  [T / Esc]");
    draw_set_halign(fa_left);draw_set_valign(fa_middle);draw_set_color(make_color_rgb(128,141,155));
    var cfg=talent_config();
    draw_text_transformed(L.margin,L.close_y+L.close_h/2,"Talentpunkte: ab Stufe "+string(cfg.first_point_level)+" alle "+string(cfg.level_interval)+" Stufen und je besiegtem Hauptboss. Linksklick investiert einen Punkt.",.8,.8,0);
    draw_set_valign(fa_top);
    if(global.talent_hover!="")talent_tooltip_draw(L,talent_find(global.talent_hover));
    else equipment_tooltip_draw(L);
    draw_set_alpha(1);draw_set_color(c_white);draw_set_halign(fa_left);draw_set_valign(fa_top);
}
function talent_frame_panel(_x,_y,_w,_h,_accent) {
    draw_set_alpha(.82);draw_set_color(make_color_rgb(13,18,28));draw_rectangle(_x,_y,_x+_w,_y+_h,false);draw_set_alpha(1);
    draw_set_color(make_color_rgb(42,52,66));draw_rectangle(_x+3,_y+3,_x+_w-3,_y+_h-3,true);
    draw_set_color(merge_color(_accent,make_color_rgb(20,24,32),.55));draw_rectangle(_x,_y,_x+_w,_y+_h,true);
    // pixel corner ornaments
    draw_set_color(_accent);
    var c=[[_x,_y,1,1],[_x+_w,_y,-1,1],[_x,_y+_h,1,-1],[_x+_w,_y+_h,-1,-1]];
    for(var i=0;i<4;i++){var q=c[i];draw_rectangle(q[0],q[1],q[0]+q[2]*9,q[1]+q[3]*2,false);draw_rectangle(q[0],q[1],q[0]+q[2]*2,q[1]+q[3]*9,false);}
}
function talent_node_draw(_L,_d,_t) {
    var p=talent_node_pos(_L,_d),s=_L.node,half=s/2,rank=talent_rank(_d.id),col=talent_tree_color(_d.tree);
    var met=talent_requirements_met(_d.id),avail=met && rank<_d.max && global.talent_points>0,maxed=rank>=_d.max,hover=global.talent_hover==_d.id;
    var cap=array_length(_d.req)>=2;
    // glow
    if(rank>0 || avail){gpu_set_blendmode(bm_add);draw_set_color(col);draw_set_alpha((maxed ? .22 : .12)+(avail ? .10*sin(_t*4)+.1 : 0));draw_circle(p.x,p.y,half*1.25,false);gpu_set_blendmode(bm_normal);draw_set_alpha(1);}
    // frame: capstones are diamonds, others rounded squares
    var bg=make_color_rgb(16,21,31),edge=maxed ? merge_color(col,c_white,.35) : (rank>0 ? col : (avail ? merge_color(make_color_rgb(242,206,120),c_white,.2+.2*sin(_t*5)) : (met ? make_color_rgb(94,108,124) : make_color_rgb(48,56,68))));
    if(cap) {
        draw_set_color(edge);draw_triangle(p.x,p.y-half-4,p.x+half+4,p.y,p.x,p.y+half+4,false);draw_triangle(p.x,p.y-half-4,p.x-half-4,p.y,p.x,p.y+half+4,false);
        draw_set_color(bg);draw_triangle(p.x,p.y-half+1,p.x+half-1,p.y,p.x,p.y+half-1,false);draw_triangle(p.x,p.y-half+1,p.x-half+1,p.y,p.x,p.y+half-1,false);
    } else {
        draw_set_color(edge);draw_roundrect_ext(p.x-half-2,p.y-half-2,p.x+half+2,p.y+half+2,9,9,false);
        draw_set_color(bg);draw_roundrect_ext(p.x-half+1,p.y-half+1,p.x+half-1,p.y+half-1,7,7,false);
    }
    var spr=asset_get_index(_d.icon),isz=cap ? s*.62 : s*.74;
    if(sprite_exists(spr))draw_sprite_stretched_ext(spr,0,p.x-isz/2,p.y-isz/2,isz,isz,rank>0 || avail ? c_white : (met ? make_color_rgb(150,156,166) : make_color_rgb(70,74,84)),rank>0 || avail ? 1 : .85);
    if(!met){draw_set_color(make_color_rgb(20,24,32));draw_rectangle(p.x+half-11,p.y+half-12,p.x+half-2,p.y+half-3,false);draw_set_color(make_color_rgb(150,160,172));draw_rectangle(p.x+half-10,p.y+half-8,p.x+half-3,p.y+half-4,false);draw_circle(p.x+half-6.5,p.y+half-9,2.4,true);}
    if(hover){draw_set_color(c_white);draw_set_alpha(.8);draw_rectangle(p.x-half-4,p.y-half-4,p.x+half+4,p.y+half+4,true);draw_set_alpha(1);}
    // rank pips
    for(var k=0;k<_d.max;k++) {
        var px=p.x+(k-(_d.max-1)/2)*9,py=p.y+half+(cap ? 10 : 8);
        draw_set_color(make_color_rgb(10,13,19));draw_circle(px,py,3.6,false);
        draw_set_color(k<rank ? merge_color(col,c_white,.2) : make_color_rgb(46,54,66));draw_circle(px,py,2.5,false);
    }
}
function talent_tooltip_draw(_L,_d) {
    if(!is_struct(_d))return;
    var rank=talent_rank(_d.id),col=talent_tree_color(_d.tree),body="";
    body+=(rank>0 ? "Aktuell: "+talent_effect_text(_d,rank) : "Wirkung: "+talent_effect_text(_d,1));
    if(rank>0 && rank<_d.max)body+="\nNaechster Rang: "+talent_effect_text(_d,rank+1);
    if(array_length(_d.req)>0) {
        body+="\n\nVoraussetzungen:";
        for(var i=0;i<array_length(_d.req);i++){var r=_d.req[i],src=talent_find(r[0]);body+="\n"+(talent_rank(r[0])>=r[1] ? "[x] " : "[ ] ")+src.name+" Rang "+string(r[1]);}
    }
    var reason=talent_block_reason(_d.id);
    body+="\n\n"+(reason=="" ? "Linksklick: Punkt investieren" : reason);
    var w=min(330,_L.w*.32),tw=w-24,h=62+string_height_ext(body,18,tw);
    var p=talent_node_pos(_L,_d),xx=clamp(p.x+_L.node*.75,8,_L.w-w-8),yy=clamp(p.y-30,8,_L.h-h-8);
    if(xx<p.x && xx+w>p.x-_L.node)xx=clamp(p.x-_L.node*.75-w,8,_L.w-w-8);
    spell_ui_panel(xx,yy,w,h,false);draw_set_color(col);draw_rectangle(xx,yy,xx+w,yy+h,true);
    draw_text(xx+12,yy+10,_d.name);draw_set_color(make_color_rgb(170,182,196));
    draw_text_transformed(xx+12,yy+32,"Rang "+string(rank)+" / "+string(_d.max)+(array_length(_d.req)>=2 ? "  |  Meistertalent" : ""),.82,.82,0);
    draw_set_color(c_white);draw_text_ext(xx+12,yy+54,body,18,tw);
}
/// HUD hint while talent points are unspent.
function talent_hud_draw() {
    if(!variable_global_exists("talent_points") || global.talent_points<=0)return;
    var gh=display_get_gui_height(),pulse=.55+.45*sin(current_time/180);
    draw_set_halign(fa_left);draw_set_valign(fa_top);
    draw_set_color(merge_color(make_color_rgb(242,206,120),c_white,pulse*.3+(global.talent_flash>0 ? .3 : 0)));
    draw_text(70,gh-31,"Talentpunkte: "+string(global.talent_points)+"  [T]");
    draw_set_color(c_white);
}
