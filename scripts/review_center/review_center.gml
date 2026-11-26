/// Development Review Center (docs/Systeme/Review-Center.md).
/// Registry: review/registry.json in the project -> generated review_registry_data() (tests/tools/review/review.py build).
/// Scenarios start through the productive boss test / scene pipeline (boss_test_pending_start) plus overrides that use the
/// real progression, talent, equipment and spell systems. Personal approvals are written ONLY by the user's click on the
/// green button in the pause menu, into the GameMaker save folder (sandbox): review_approvals.json + review_approvals.log.
/// Disable for public builds: REVIEW_CENTER_ENABLED false (independent of the test menu macro).
#macro REVIEW_CENTER_ENABLED true
#macro REVIEW_APPROVAL_FILE "review_approvals.json"
#macro REVIEW_APPROVAL_LOG "review_approvals.log"

function review_enabled() {return REVIEW_CENTER_ENABLED;}
function review_s(_s,_k,_d) {return (is_struct(_s) && variable_struct_exists(_s,_k)) ? _s[$ _k] : _d;}
function review_entries() {
    if(!variable_global_exists("review_registry_cache") || !is_array(global.review_registry_cache))global.review_registry_cache=review_registry_data();
    return global.review_registry_cache;
}
function review_find(_id) {var e=review_entries();for(var i=0;i<array_length(e);i++)if(e[i].id==_id)return e[i];return undefined;}
/// A copy of the project built under another name (test harnesses) only ever produces technical test approvals.
function review_is_test_build() {return game_project_name!="FirstGame";}
function review_active() {return variable_global_exists("review") && is_struct(global.review) && global.review.active;}
/// Any development session (review scenario or test mode, also while it is being prepared) is isolated from the
/// normal save data: no talent load/save, no progression audit (talent_persistent, progression_audit_step).
function dev_session_active() {
    if(review_active())return true;
    if(variable_global_exists("boss_test_pending") && is_struct(global.boss_test_pending))return true;
    return variable_global_exists("boss_test") && is_struct(global.boss_test) && global.boss_test.active;
}
function review_minute(_s) {return review_s(_s,"minute",review_s(_s,"type","")=="boss" ? 15 : 0);}
/// Recommended / actual player level of a scenario: explicit override or the test-mode progression preset (one source).
function review_level(_e) {var s=_e.scenario;return review_s(s,"level",boss_test_preset(max(5,review_minute(s))).level);}
function review_class_name(_c) {return _c=="Mage" ? "Arkanistin" : (_c=="Ranger" ? "Waldlaeufer" : "Schwertmeister");}

// ---------------- Local approvals (save folder) ----------------
function review_now_iso() {
    var d=date_current_datetime(),p=function(_v){return (_v<10 ? "0" : "")+string(_v);};
    return string(date_get_year(d))+"-"+p(date_get_month(d))+"-"+p(date_get_day(d))+"T"+p(date_get_hour(d))+":"+p(date_get_minute(d))+":"+p(date_get_second(d));
}
function review_read_text(_file) {
    if(!file_exists(_file))return "";
    var f=file_text_open_read(_file),t="";if(f<0)return "";
    while(!file_text_eof(f)){t+=file_text_read_string(f);file_text_readln(f);if(!file_text_eof(f))t+="\n";}
    file_text_close(f);return t;
}
function review_local_load() {
    var list=[],t=review_read_text(REVIEW_APPROVAL_FILE);
    if(t!="")try{var d=json_parse(t);if(is_struct(d) && variable_struct_exists(d,"approvals") && is_array(d.approvals))list=d.approvals;}catch(_e){list=[];}
    // The append-only log is the safety net: anything missing from the JSON (crash, damage) is still counted.
    var lg=review_read_text(REVIEW_APPROVAL_LOG);
    if(lg!="") {
        var lines=string_split(lg,"\n");
        for(var i=0;i<array_length(lines);i++) {
            if(string_length(string_trim(lines[i]))<2)continue;
            try{var a=json_parse(lines[i]);var have=false;for(var j=0;j<array_length(list);j++)if(list[j].uid==a.uid)have=true;if(!have)array_push(list,a);}catch(_e){}
        }
    }
    global.review_local=list;return list;
}
function review_local() {if(!variable_global_exists("review_local") || !is_array(global.review_local))review_local_load();return global.review_local;}
function review_local_approved(_id,_rev) {
    var l=review_local(),test_ok=review_is_test_build();
    for(var i=0;i<array_length(l);i++)if(l[i].id==_id && l[i].revision==_rev && (test_ok || !review_s(l[i],"test",false)))return true;
    return false;
}
/// open | local (approved in game, waiting for the agent sync) | approved | processed | superseded
function review_state(_e) {
    if(_e.status=="processed" || _e.status=="superseded" || _e.status=="approved")return _e.status;
    return review_local_approved(_e.id,_e.revision) ? "local" : "open";
}
function review_open_count() {var e=review_entries(),n=0;for(var i=0;i<array_length(e);i++)if(review_state(e[i])=="open")n++;return n;}
/// Writes one approval. Robust: JSON via temp file + rename (previous file kept as .bak), plus an append-only log line.
/// Called only from the pause-menu button (review_pause_activate). Test builds mark the record as a technical test.
function review_approve_current() {
    if(!review_active())return false;
    var r=global.review,rec={uid:r.id+"@"+string(r.revision)+"@"+review_now_iso()+"@"+string(get_timer() mod 100000),id:r.id,revision:r.revision,
        approved_at:review_now_iso(),source:"pause_menu_button",test:review_is_test_build(),project:game_project_name,title:r.title};
    var list=[],t=review_read_text(REVIEW_APPROVAL_FILE),damaged=false;
    if(t!="")try{var d=json_parse(t);if(is_struct(d) && is_array(review_s(d,"approvals",undefined)))list=d.approvals;else damaged=true;}catch(_e){damaged=true;}
    if(damaged)file_copy(REVIEW_APPROVAL_FILE,"review_approvals_damaged_"+string(get_timer())+".json"); // never silently drop old data
    array_push(list,rec);
    var tmp="review_approvals.tmp",f=file_text_open_write(tmp);if(f<0)return false;
    file_text_write_string(f,json_stringify({schema:1,note:"Persoenliche Freigaben aus dem Review-Center. Nicht von Hand aendern.",approvals:list},true));file_text_close(f);
    if(file_exists(REVIEW_APPROVAL_FILE)){if(file_exists("review_approvals.bak"))file_delete("review_approvals.bak");file_rename(REVIEW_APPROVAL_FILE,"review_approvals.bak");}
    file_rename(tmp,REVIEW_APPROVAL_FILE);
    var lg=file_text_open_append(REVIEW_APPROVAL_LOG);if(lg>=0){file_text_write_string(lg,json_stringify(rec));file_text_writeln(lg);file_text_close(lg);}
    review_local_load();
    var ok=review_local_approved(r.id,r.revision);
    show_debug_message("REVIEW_APPROVED "+json_stringify(rec)+" saved="+string(ok));
    return ok;
}

// ---------------- Scenario start ----------------
function review_start(_id) {
    if(!review_enabled())return false;
    var e=review_find(_id);if(!is_struct(e))return false;
    var s=e.scenario,cls=review_s(s,"class","Sword"),seed=review_s(s,"seed",1337),lvl=review_s(s,"arena",review_s(s,"level_index",0));
    var restore_c=variable_global_exists("selected_character") ? global.selected_character : "Sword",restore_l=variable_global_exists("selected_level") ? global.selected_level : 0;
    if(review_active()){restore_c=global.review.restore_character;restore_l=global.review.restore_level;}
    var req;
    if(s.type=="boss") {
        req=boss_test_request(s.boss,review_minute(s),cls,seed,review_s(s,"ability",-1),review_s(s,"build","balanced")=="random",review_s(s,"difficulty",1));
        if(!is_struct(req))return false;
    } else {
        req={scene:true,level:lvl,minute:review_minute(s),class_name:cls,seed:seed,build:review_s(s,"build","balanced")=="empty" ? 0 : (review_s(s,"build","balanced")=="random" ? 2 : 1),
            spell:-1,spell_level:9,gear:0,enemies:(s.type=="showroom" || review_s(s,"enemies","normal")=="none") ? 1 : 0};
    }
    req.restore_character=restore_c;req.restore_level=restore_l;
    global.review={active:true,id:e.id,title:e.title,revision:e.revision,category:e.category,scenario:s,restore_character:restore_c,restore_level:restore_l,
        confirm_t:0,note:"",note_t:0,start:undefined};
    global.boss_test_pending=req;global.selected_character=req.class_name;global.selected_level=lvl;global.menu_transition_lock=true;
    instance_activate_all();reset_round();
    var target=level_room(lvl);if(room==target)room_restart();else room_goto(target);
    show_debug_message("REVIEW_START "+json_stringify({id:e.id,revision:e.revision,type:s.type}));
    return true;
}
/// Called at the end of boss_test_pending_start (both paths): applies the scenario overrides with the real systems.
function review_after_start(_ok) {
    if(!review_active() || !_ok || !instance_exists(ObjectPlayer))return;
    var s=global.review.scenario,pl=ObjectPlayer;
    if(variable_struct_exists(s,"level")){global.current_level=s.level;global.coins_needed=progression_cost(global.current_level);}
    var sp=review_s(s,"spells",undefined);
    if(is_array(sp)) {
        if(review_s(s,"spells_replace",false)){global.active_spells=[];global.passive_spells=[];global.hotbar=array_create(6,undefined);hotbar_init();}
        for(var i=0;i<array_length(sp);i++)for(var k=0;k<review_s(sp[i],"level",1);k++)boss_test_add_skill(sp[i].id);
    }
    var tp=review_s(s,"talent_points",0);if(tp>0)talent_grant(tp,"Review");
    var tl=review_s(s,"talents",undefined);
    if(is_array(tl))for(var i=0;i<array_length(tl);i++){talent_grant(review_s(tl[i],"rank",1),"");for(var k=0;k<review_s(tl[i],"rank",1);k++)talent_invest(tl[i].id);}
    repeat(review_s(s,"weapon_upgrades",0))weapon_upgrade_take();
    var g=review_s(s,"gear",-1);
    if(is_real(g) && g>=0){var slots=equipment_slots();for(var i=0;i<array_length(slots);i++)equipment_equip(equipment_generate(slots[i],g,equipment_item_level()+g));}
    var gi=review_s(s,"gear_items",undefined);
    if(is_array(gi))for(var i=0;i<array_length(gi);i++)equipment_equip(equipment_generate(gi[i].slot,review_s(gi[i],"rarity",1),equipment_item_level()+review_s(gi[i],"bonus",0)));
    var bp=review_s(s,"backpack",undefined);
    if(is_array(bp))for(var i=0;i<array_length(bp) && array_length(global.equipment_backpack)<equipment_config().backpack_size;i++)
        array_push(global.equipment_backpack,equipment_generate(bp[i].slot,review_s(bp[i],"rarity",1),equipment_item_level()+review_s(bp[i],"bonus",0)));
    global.boss_test.invulnerable=review_s(s,"invulnerable",false);
    if(review_s(s,"magnet_orb",false))instance_create_layer(pl.x+90,pl.y,"Instances",ObjectMagnetOrb); // walk into it: MAGNET pixel text
    var pk=review_s(s,"enemy_pack",undefined);
    if(is_struct(pk))for(var i=0;i<review_s(pk,"count",6);i++){var a=i*360/max(1,review_s(pk,"count",6)),d=review_s(pk,"radius",220);population_spawn_enemy(pl.x+lengthdir_x(d,a),pl.y+lengthdir_y(d,a));}
    if(review_s(s,"type","")=="boss" && instance_exists(global.active_boss)) {
        var b=global.active_boss,off=review_s(s,"boss_offset",undefined);
        if(is_array(off)){b.x=pl.x+off[0];b.y=pl.y+off[1];}
        if(variable_struct_exists(s,"boss_hp"))b.hp=max(1,b.max_hp*s.boss_hp);
        if(variable_struct_exists(s,"sequence")){bc_seq_init(b);b.bc_seq_force=s.sequence;} // choreographed sequence index of the boss phase (boss_choreo)
    }
    apply_passives(pl);pl.hp=pl.max_hp*review_s(s,"hp",1);pl.hud_hp_trail=pl.hp;
    global.review.start={px:pl.x,py:pl.y,bx:instance_exists(global.active_boss) ? global.active_boss.x : 0,by:instance_exists(global.active_boss) ? global.active_boss.y : 0};
    review_note("Review: "+global.review.title+"  (Esc: pruefen, freigeben, neu starten)");
}
function review_note(_t) {if(review_active()){global.review.note=_t;global.review.note_t=4;}}
function review_restart() {if(review_active())review_start(global.review.id);}
function review_repeat_attack() {
    if(!review_active() || !instance_exists(global.active_boss))return false;
    var ab=review_s(global.review.scenario,"ability",-1);if(ab==-1)return false;
    return boss_v2_force_attack(global.active_boss,ab);
}
function review_reset_positions() {
    if(!review_active() || !is_struct(global.review.start) || !instance_exists(ObjectPlayer))return;
    var st=global.review.start;ObjectPlayer.x=st.px;ObjectPlayer.y=st.py;
    if(instance_exists(global.active_boss)){global.active_boss.x=st.bx;global.active_boss.y=st.by;}
}
function review_restore_player() {
    if(!instance_exists(ObjectPlayer))return;
    with(ObjectPlayer){hp=max_hp;hud_hp_trail=hp;}
    if(variable_global_exists("dodge_cooldown_timer"))global.dodge_cooldown_timer=0;
    for(var i=0;i<array_length(global.active_spells);i++)global.active_spells[i].cooldown_timer=0;
}
function review_end() {if(review_active())global.review.active=false;}
function review_back_to_center() {global.menu_return_mode="review";round_end_to_title();}
function review_tick(_dt) {
    if(!review_active())return;
    var r=global.review;r.note_t=max(0,r.note_t-_dt);
    if(variable_global_exists("review_saved_t"))global.review_saved_t=max(0,global.review_saved_t-_dt);
}
/// Runs while the pause menu is open (the controller is paused): the armed approval button expires after 4 s.
function review_pause_tick() {if(review_active())global.review.confirm_t=max(0,global.review.confirm_t-delta_time/1000000);}

// ---------------- Pause menu (green approval button) ----------------
function review_pause_labels() {
    var l=["Weiter","Talente & Ausruestung","Szenario neu starten"];
    if(review_s(global.review.scenario,"ability",-1)!=-1)array_push(l,"Attacke erneut ausloesen");
    array_push(l,"Positionen zuruecksetzen","Leben & Abklingzeiten auffuellen",
        review_local_approved(global.review.id,global.review.revision) ? "Freigegeben (Rev. "+string(global.review.revision)+")" : (global.review.confirm_t>0 ? "Freigabe bestaetigen" : "Freigeben / Approved"),
        "Zurueck zum Review-Center","Einstellungen");
    return l;
}
function review_is_approve_label(_l) {return string_pos("Freigabe",_l)==1 || string_pos("Freigeben",_l)==1 || string_pos("Freigegeben",_l)==1;}
/// Returns true if the action closed the pause menu.
function review_pause_activate(_label) {
    var unpause=function(){instance_activate_all();global.game_paused=false;global.normal_pause_active=false;global.pause_initialized=false;if(instance_exists(ObjectPlayer)){ObjectPlayer.mouse_move_armed=false;ObjectPlayer.menu_input_guard=1;}};
    if(_label=="Szenario neu starten"){fg_sfx("game_start");review_restart();return true;}
    if(_label=="Attacke erneut ausloesen"){unpause();review_repeat_attack();review_note("Attacke erneut ausgeloest");return true;}
    if(_label=="Positionen zuruecksetzen"){unpause();review_reset_positions();review_note("Positionen zurueckgesetzt");return true;}
    if(_label=="Leben & Abklingzeiten auffuellen"){review_restore_player();review_note("Leben und Abklingzeiten aufgefuellt");return false;}
    if(_label=="Zurueck zum Review-Center"){review_back_to_center();return true;}
    if(review_is_approve_label(_label)) {
        if(review_local_approved(global.review.id,global.review.revision)){review_note("Diese Revision ist bereits freigegeben.");return false;}
        // Two deliberate actions: the first arms the button for 4 s, the second saves. Closing the menu never approves.
        if(global.review.confirm_t<=0){global.review.confirm_t=4;fg_sfx("ui_click");return false;}
        global.review.confirm_t=0;
        if(review_approve_current()){fg_sfx("chest_open");global.review_saved_t=5;review_note((review_is_test_build() ? "TESTFREIGABE gespeichert: " : "Freigabe gespeichert: ")+global.review.title+" (Rev. "+string(global.review.revision)+")");}
        else review_note("Freigabe konnte nicht gespeichert werden - bitte erneut versuchen.");
        return false;
    }
    return false;
}
function review_pause_extra_draw() {
    if(!review_active())return;
    var gw=display_get_gui_width(),gh=display_get_gui_height(),r=global.review,w=min(540,gw*.42),x0=gw-w-18,y0=gh-150; // bottom right: free of the pause list and build texts
    spell_ui_panel(x0,y0,w,100,false);
    draw_set_halign(fa_left);draw_set_valign(fa_top);draw_set_color(make_color_rgb(238,207,133));
    draw_text_transformed(x0+12,y0+8,"REVIEW: "+r.title+"  (Rev. "+string(r.revision)+")",.85,.85,0);
    draw_set_color(make_color_rgb(176,196,210));
    var done=review_local_approved(r.id,r.revision);
    draw_text_ext_transformed(x0+12,y0+32,done ? "Diese Revision hast du freigegeben. Der Agent verarbeitet die Freigabe beim naechsten Auftrag."
        : "Gefaellt dir die Umsetzung, druecke den gruenen Haken und bestaetige. Sonst einfach verlassen - der Eintrag bleibt offen.",18,(w-24)/.78,.78,.78,0);
    if(variable_global_exists("review_saved_t") && global.review_saved_t>0){draw_set_color(make_color_rgb(126,224,140));draw_text_transformed(x0+12,y0+76,r.note,.8,.8,0);}
}
/// Green check drawn into the approval row of the pause list.
function review_approve_button_draw(_x,_y,_w,_h,_label,_sel) {
    var done=string_pos("Freigegeben",_label)==1,arm=string_pos("bestaetigen",_label)>0;
    var base=done ? make_color_rgb(40,96,58) : (arm ? make_color_rgb(70,150,80) : make_color_rgb(34,112,62));
    draw_set_alpha(1);draw_set_color(base);draw_rectangle(_x,_y,_x+_w,_y+_h,false);
    draw_set_color(_sel ? c_white : make_color_rgb(126,224,140));draw_rectangle(_x,_y,_x+_w,_y+_h,true);draw_rectangle(_x+1,_y+1,_x+_w-1,_y+_h-1,true);
    var cx=_x+26,cy=_y+_h*.5;draw_set_color(c_white);
    draw_line_width(cx-9,cy,cx-3,cy+7,4);draw_line_width(cx-3,cy+7,cx+10,cy-8,4);
    draw_set_halign(fa_left);draw_set_valign(fa_middle);draw_text_transformed(_x+46,cy,_label,.95,.95,0);
}

// ---------------- Review Center screen (main menu) ----------------
function review_center_filters() {static f=["Offen","Freigegeben","Archiv"];return f;}
function review_center_open() {
    global.review_registry_cache=undefined;review_local_load();
    if(!variable_global_exists("review_ui"))global.review_ui={filter:0,sel:0,scroll:0,last_click:-1,click_t:0};
    global.review_ui.sel=0;global.review_ui.scroll=0;
}
/// Rows: category headers and entries matching the filter, grouped by category in registry order.
function review_center_rows() {
    var e=review_entries(),f=global.review_ui.filter,cats=[],rows=[];
    for(var i=0;i<array_length(e);i++) {
        var st=review_state(e[i]),ok=(f==0 && st=="open") || (f==1 && (st=="local" || st=="approved")) || (f==2 && (st=="processed" || st=="superseded"));
        if(!ok)continue;
        if(!array_contains(cats,e[i].category))array_push(cats,e[i].category);
    }
    for(var c=0;c<array_length(cats);c++) {
        array_push(rows,{header:true,text:cats[c]});
        for(var i=0;i<array_length(e);i++) {
            var st=review_state(e[i]),ok=(f==0 && st=="open") || (f==1 && (st=="local" || st=="approved")) || (f==2 && (st=="processed" || st=="superseded"));
            if(ok && e[i].category==cats[c])array_push(rows,{header:false,entry:e[i],state:st});
        }
    }
    return rows;
}
function review_center_geometry() {var gw=display_get_gui_width(),gh=display_get_gui_height();return {lx:24,ly:118,lw:gw*.52,lh:gh-118-54,row:34,dx:gw*.52+40,dy:118,dw:gw-(gw*.52+40)-24,dh:gh-118-54};}
function review_center_step() {
    var ui=global.review_ui,G=review_center_geometry(),rows=review_center_rows(),n=array_length(rows),vis=floor(G.lh/G.row);
    if(keyboard_check_pressed(vk_escape)){fg_sfx("ui_back");menu_mode="main";menu_index=4;return;}
    if(keyboard_check_pressed(vk_tab)){ui.filter=(ui.filter+1) mod 3;ui.sel=0;ui.scroll=0;fg_sfx("ui_click");rows=review_center_rows();n=array_length(rows);}
    var mx=device_mouse_x_to_gui(0),my=device_mouse_y_to_gui(0);
    for(var t=0;t<3;t++)if(mouse_check_button_pressed(mb_left) && point_in_rectangle(mx,my,G.lx+t*150,G.ly-38,G.lx+t*150+140,G.ly-8)){ui.filter=t;ui.sel=0;ui.scroll=0;fg_sfx("ui_click");return;}
    if(n==0)return;
    var step=function(_rows,_i,_d){var k=_i;repeat(array_length(_rows)){k=clamp(k+_d,0,array_length(_rows)-1);if(!_rows[k].header)return k;if(k==0 || k==array_length(_rows)-1)break;}return _i;};
    if(rows[clamp(ui.sel,0,n-1)].header)ui.sel=step(rows,clamp(ui.sel,0,n-1),1);
    if(keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W")))ui.sel=step(rows,ui.sel,-1);
    if(keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S")))ui.sel=step(rows,ui.sel,1);
    if(mouse_wheel_up())ui.scroll=max(0,ui.scroll-3);
    if(mouse_wheel_down())ui.scroll=min(max(0,n-vis),ui.scroll+3);
    var hover=-1;
    if(point_in_rectangle(mx,my,G.lx,G.ly,G.lx+G.lw,G.ly+vis*G.row)){var k=ui.scroll+floor((my-G.ly)/G.row);if(k<n && !rows[k].header)hover=k;}
    ui.click_t=max(0,ui.click_t-delta_time/1000000);
    var start_btn={x:G.dx+16,y:G.dy+G.dh-58,w:G.dw-32,h:42},start=false;
    if(mouse_check_button_pressed(mb_left)) {
        if(hover>=0){if(hover==ui.sel && ui.last_click==hover && ui.click_t>0)start=true;ui.sel=hover;ui.last_click=hover;ui.click_t=.35;fg_sfx("ui_click");}
        else if(point_in_rectangle(mx,my,start_btn.x,start_btn.y,start_btn.x+start_btn.w,start_btn.y+start_btn.h))start=true;
    }
    if(ui.sel<ui.scroll)ui.scroll=ui.sel;if(ui.sel>=ui.scroll+vis)ui.scroll=ui.sel-vis+1;
    if(keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space))start=true;
    if(start && !rows[ui.sel].header){fg_sfx("game_start");review_start(rows[ui.sel].entry.id);}
}
function review_center_draw() {
    var ui=global.review_ui,G=review_center_geometry(),rows=review_center_rows(),n=array_length(rows),vis=floor(G.lh/G.row),gw=display_get_gui_width(),gh=display_get_gui_height();
    draw_set_alpha(1);draw_set_color(make_color_rgb(10,16,22));draw_rectangle(0,0,gw,gh,false);
    draw_set_font(-1);draw_set_halign(fa_left);draw_set_valign(fa_top);
    draw_set_color(make_color_rgb(218,186,112));draw_text(24,20,"REVIEW-CENTER  -  OFFENE PRUEFUNGEN (TO-DO)");
    draw_set_color(make_color_rgb(166,192,205));
    draw_text_transformed(24,46,"Jeder Eintrag startet ein spielbares Szenario mit den echten Spielsystemen. Gefaellt dir das Ergebnis: Esc -> gruener Haken. Sonst einfach verlassen.",.72,.72,0);
    for(var t=0;t<3;t++) {
        var tx=G.lx+t*150,cnt=0,e=review_entries();
        for(var i=0;i<array_length(e);i++){var st=review_state(e[i]);if((t==0 && st=="open") || (t==1 && (st=="local" || st=="approved")) || (t==2 && (st=="processed" || st=="superseded")))cnt++;}
        spell_ui_panel(tx,G.ly-38,140,30,ui.filter==t);draw_set_halign(fa_center);draw_set_valign(fa_middle);draw_set_color(ui.filter==t ? make_color_rgb(238,207,133) : c_white);
        draw_text_transformed(tx+70,G.ly-23,review_center_filters()[t]+" ("+string(cnt)+")",.8,.8,0);
    }
    draw_set_halign(fa_left);draw_set_valign(fa_middle);
    if(n==0){draw_set_color(make_color_rgb(140,156,170));draw_text_transformed(G.lx+8,G.ly+24,ui.filter==0 ? "Keine offenen Pruefungen." : "Keine Eintraege.",.85,.85,0);}
    for(var k=ui.scroll;k<min(n,ui.scroll+vis);k++) {
        var yy=G.ly+(k-ui.scroll)*G.row,row=rows[k];
        if(row.header){draw_set_color(make_color_rgb(150,176,198));draw_text_transformed(G.lx+4,yy+G.row*.5+4,string_upper(row.text),.78,.78,0);draw_set_alpha(.35);draw_line(G.lx,yy+G.row-3,G.lx+G.lw,yy+G.row-3);draw_set_alpha(1);continue;}
        spell_ui_panel(G.lx,yy+2,G.lw,G.row-4,k==ui.sel);
        var e=row.entry,col=row.state=="local" ? make_color_rgb(126,224,140) : (row.state=="open" ? c_white : make_color_rgb(150,160,170));
        draw_set_color(col);draw_text_transformed(G.lx+12,yy+G.row*.5,(row.state=="local" || row.state=="approved" || row.state=="processed" ? "[OK] " : "")+e.title,.82,.82,0);
        draw_set_halign(fa_right);draw_set_color(make_color_rgb(150,168,182));
        draw_text_transformed(G.lx+G.lw-10,yy+G.row*.5,"Lv "+string(review_level(e))+"  Rev. "+string(e.revision),.72,.72,0);draw_set_halign(fa_left);
    }
    if(n>vis){var bh=G.lh*vis/n,by=G.ly+(G.lh-bh)*ui.scroll/max(1,n-vis);draw_set_color(make_color_rgb(70,86,100));draw_rectangle(G.lx+G.lw+6,G.ly,G.lx+G.lw+10,G.ly+G.lh,false);draw_set_color(make_color_rgb(170,190,206));draw_rectangle(G.lx+G.lw+6,by,G.lx+G.lw+10,by+bh,false);}
    // detail panel
    talent_frame_panel(G.dx,G.dy-38,G.dw,G.dh+38,make_color_rgb(150,176,198));
    draw_set_valign(fa_top);
    if(n>0 && !rows[clamp(ui.sel,0,n-1)].header) {
        var e=rows[ui.sel].entry,s=e.scenario,yy=G.dy-24,tw=G.dw-32;
        draw_set_color(make_color_rgb(238,207,133));draw_text_ext_transformed(G.dx+16,yy,e.title,20,tw/.95,.95,.95,0);yy+=string_height_ext(e.title,20,tw/.95)*.95+10;
        var st=rows[ui.sel].state,stt=st=="open" ? "Offen - wartet auf deine Pruefung" : (st=="local" ? "Von dir freigegeben - wartet auf Verarbeitung durch den Agenten" : (st=="processed" ? "Freigegeben und verarbeitet" : (st=="superseded" ? "Durch neue Revision ersetzt" : "Freigegeben")));
        var lines=[["Kategorie",e.category],["Inhalt",e.content],["Status",stt],["Spieler",review_class_name(review_s(s,"class","Sword"))+", Level "+string(review_level(e))+(s.type=="boss" ? ", Minute "+string(review_minute(s)) : "")],
            ["Szenario",s.type=="boss" ? "Bosskampf "+s.boss+(review_s(s,"ability",-1)!=-1 ? ", Attacke "+string(s.ability)+" wiederholt" : ", Rotation") : (s.type=="showroom" ? "Testraum ohne Gegner" : "Freie Szene")],
            ["Revision",string(e.revision)+"  |  Auftrag: "+e.task+"  |  seit "+e.created]];
        for(var i=0;i<array_length(lines);i++){draw_set_color(make_color_rgb(150,168,182));draw_text_transformed(G.dx+16,yy,lines[i][0],.72,.72,0);draw_set_color(c_white);draw_text_ext_transformed(G.dx+110,yy,lines[i][1],17,(tw-94)/.75,.75,.75,0);yy+=max(20,string_height_ext(lines[i][1],17,(tw-94)/.75)*.75+6);}
        yy+=8;draw_set_color(make_color_rgb(150,168,182));draw_text_transformed(G.dx+16,yy,"WORAUF ACHTEN",.72,.72,0);yy+=20;
        draw_set_color(make_color_rgb(214,226,234));draw_text_ext_transformed(G.dx+16,yy,e.goal,18,tw/.78,.78,.78,0);
        var b={x:G.dx+16,y:G.dy+G.dh-58,w:G.dw-32,h:42},mx=device_mouse_x_to_gui(0),my=device_mouse_y_to_gui(0);
        spell_ui_panel(b.x,b.y,b.w,b.h,point_in_rectangle(mx,my,b.x,b.y,b.x+b.w,b.y+b.h));draw_set_halign(fa_center);draw_set_valign(fa_middle);draw_set_color(make_color_rgb(238,207,133));
        draw_text(b.x+b.w*.5,b.y+b.h*.5,"Szenario starten  (Enter / Doppelklick)");
    }
    draw_set_halign(fa_left);draw_set_valign(fa_top);draw_set_color(make_color_rgb(198,155,170));
    draw_text_transformed(24,gh-34,"Tab / Reiter: Filter  |  Pfeile, Mausrad: Auswahl  |  Enter: starten  |  Esc: Hauptmenue",.72,.72,0);
}
