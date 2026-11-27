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
/// The user's latest verdict for an entry revision (records are appended in time order; the last one wins), or
/// undefined. Old records from before 26.11. carry no verdict and count as "good".
function review_local_verdict(_id,_rev) {
    var l=review_local(),test_ok=review_is_test_build(),out=undefined;
    for(var i=0;i<array_length(l);i++)if(l[i].id==_id && l[i].revision==_rev && (test_ok || !review_s(l[i],"test",false)))out=l[i];
    return out;
}
function review_local_approved(_id,_rev) {var v=review_local_verdict(_id,_rev);return is_struct(v) && review_s(v,"verdict","good")=="good";}
function review_local_rejected(_id,_rev) {var v=review_local_verdict(_id,_rev);return is_struct(v) && review_s(v,"verdict","good")=="bad";}
/// open | local (good in game, waiting for the agent sync) | local_bad (not good, waiting) | approved | processed |
/// rejected (not good, synced: the agent reworks or removes it) | superseded | withdrawn (taken off the open list by the
/// agent, decided by the design canon; not a personal approval; still startable from the archive)
function review_state(_e) {
    var v=review_local_verdict(_e.id,_e.revision);
    if(_e.status=="superseded")return "superseded";
    // a newer verdict in the game overrides the synced one until the next sync
    if(is_struct(v) && _e.status!="processed" && _e.status!="rejected")return review_s(v,"verdict","good")=="bad" ? "local_bad" : "local";
    if(_e.status=="processed" || _e.status=="approved" || _e.status=="rejected" || _e.status=="withdrawn")return _e.status;
    return "open";
}
/// Review Center tabs: 0 Offen, 1 Freigegeben, 2 Nicht gut, 3 Archiv.
function review_filter_match(_f,_st) {
    switch(_f){case 0:return _st=="open";case 1:return _st=="local" || _st=="approved";case 2:return _st=="local_bad" || _st=="rejected";default:return _st=="processed" || _st=="superseded" || _st=="withdrawn";}
}
function review_open_count() {var e=review_entries(),n=0;for(var i=0;i<array_length(e);i++)if(review_state(e[i])=="open")n++;return n;}
/// Writes the user's verdict for the running scenario: _verdict "good" | "bad", _decision "keep" (good) or
/// "remove" | "change" (bad), _comment free text (typed or dictated). Robust: JSON via temp file + rename (previous file
/// kept as .bak), plus an append-only log line. Called only from the pause-menu dialog. Test builds mark the record.
function review_save_verdict(_verdict,_decision,_comment) {
    if(!review_active())return false;
    var r=global.review,stamp=review_now_iso(),rec={uid:r.id+"@"+string(r.revision)+"@"+stamp+"@"+string(get_timer() mod 100000),id:r.id,revision:r.revision,
        verdict:_verdict,decision:_decision,comment:_comment,at:stamp,source:"pause_menu_dialog",test:review_is_test_build(),project:game_project_name,title:r.title};
    if(_verdict=="good")rec.approved_at=stamp;
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
    var v=review_local_verdict(r.id,r.revision),ok=is_struct(v) && v.uid==rec.uid;
    show_debug_message("REVIEW_VERDICT "+json_stringify(rec)+" saved="+string(ok));
    return ok;
}
function review_approve_current() {return review_save_verdict("good","keep","");}

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
    var v=review_local_verdict(global.review.id,global.review.revision),vv=is_struct(v) ? review_s(v,"verdict","good") : "";
    array_push(l,"Positionen zuruecksetzen","Leben & Abklingzeiten auffuellen",
        vv=="good" ? "Gut (gespeichert) - aendern" : "Gut - freigeben",
        vv=="bad" ? "Nicht gut (gespeichert) - aendern" : "Nicht gut",
        "Zurueck zum Review-Center","Einstellungen");
    return l;
}
/// "good" / "bad" for the two verdict rows of the pause list, "" for every other row.
function review_verdict_of_label(_l) {return string_pos("Gut",_l)==1 ? "good" : (string_pos("Nicht gut",_l)==1 ? "bad" : "");}
function review_is_approve_label(_l) {return review_verdict_of_label(_l)!="";}
/// Returns true if the action closed the pause menu.
function review_pause_activate(_label) {
    var unpause=function(){instance_activate_all();global.game_paused=false;global.normal_pause_active=false;global.pause_initialized=false;if(instance_exists(ObjectPlayer)){ObjectPlayer.mouse_move_armed=false;ObjectPlayer.menu_input_guard=1;}};
    if(_label=="Szenario neu starten"){fg_sfx("game_start");review_restart();return true;}
    if(_label=="Attacke erneut ausloesen"){unpause();review_repeat_attack();review_note("Attacke erneut ausgeloest");return true;}
    if(_label=="Positionen zuruecksetzen"){unpause();review_reset_positions();review_note("Positionen zurueckgesetzt");return true;}
    if(_label=="Leben & Abklingzeiten auffuellen"){review_restore_player();review_note("Leben und Abklingzeiten aufgefuellt");return false;}
    if(_label=="Zurueck zum Review-Center"){review_back_to_center();return true;}
    // Two deliberate actions: the row opens the dialog, "Speichern" (Enter or click) saves. Closing never saves.
    var verdict=review_verdict_of_label(_label);
    if(verdict!=""){review_feedback_open(verdict);return false;}
    return false;
}

// ---------------- Verdict dialog: "Gut" / "Nicht gut" with a comment (user order 26.11.) ----------------
// Typing goes into keyboard_string, so Windows voice typing (Win+H) writes into the field as well.
#macro REVIEW_COMMENT_MAX 600
function review_feedback_active() {return review_active() && is_struct(review_s(global.review,"fb",undefined));}
function review_feedback_open(_verdict) {
    var v=review_local_verdict(global.review.id,global.review.revision),same=is_struct(v) && review_s(v,"verdict","good")==_verdict;
    global.review.fb={verdict:_verdict,decision:same ? review_s(v,"decision",_verdict=="good" ? "keep" : "change") : (_verdict=="good" ? "keep" : "change"),
        text:same ? review_s(v,"comment","") : "",guard:2};
    keyboard_string=global.review.fb.text;fg_sfx("ui_click");
}
function review_feedback_close() {global.review.fb=undefined;keyboard_string="";}
function review_feedback_geometry() {
    var gw=display_get_gui_width(),gh=display_get_gui_height(),w=min(760,gw-80),h=330,x0=(gw-w)*.5,y0=(gh-h)*.5;
    return {x:x0,y:y0,w:w,h:h,ox:x0+20,oy:y0+84,ow:(w-60)*.5,oh:40,tx:x0+20,ty:y0+140,tw:w-40,th:110,
        sx:x0+w-20-220,sy:y0+h-56,sw:220,sh:40,cx:x0+20,cy:y0+h-56,cw:180,ch:40};
}
/// Runs instead of the pause list while the dialog is open (round_menu_step).
function review_feedback_step() {
    var fb=global.review.fb;
    if(fb.guard>0){fb.guard--;keyboard_string=fb.text;return;} // the key or click that opened the dialog is not typed into it
    keyboard_string=string_replace_all(string_replace_all(keyboard_string,"\n"," "),"\r","");
    if(string_length(keyboard_string)>REVIEW_COMMENT_MAX)keyboard_string=string_copy(keyboard_string,1,REVIEW_COMMENT_MAX);
    fb.text=keyboard_string;
    var g=review_feedback_geometry(),mx=device_mouse_x_to_gui(0),my=device_mouse_y_to_gui(0),click=mouse_check_button_pressed(mb_left);
    if(fb.verdict=="bad") {
        if(keyboard_check_pressed(vk_left) || keyboard_check_pressed(vk_right) || keyboard_check_pressed(vk_tab))fb.decision=fb.decision=="remove" ? "change" : "remove";
        if(click && point_in_rectangle(mx,my,g.ox,g.oy,g.ox+g.ow,g.oy+g.oh))fb.decision="remove";
        if(click && point_in_rectangle(mx,my,g.ox+g.ow+20,g.oy,g.ox+2*g.ow+20,g.oy+g.oh))fb.decision="change";
    }
    if(keyboard_check_pressed(vk_escape) || (click && point_in_rectangle(mx,my,g.cx,g.cy,g.cx+g.cw,g.cy+g.ch))){review_feedback_close();fg_sfx("ui_back");return;}
    if(keyboard_check_pressed(vk_enter) || (click && point_in_rectangle(mx,my,g.sx,g.sy,g.sx+g.sw,g.sy+g.sh))) {
        var verdict=fb.verdict,decision=fb.decision,comment=string_trim(fb.text);
        review_feedback_close();
        if(review_save_verdict(verdict,decision,comment)) {
            fg_sfx(verdict=="good" ? "chest_open" : "ui_click");global.review_saved_t=5;
            review_note((review_is_test_build() ? "TEST: " : "")+(verdict=="good" ? "Gut gespeichert" : (decision=="remove" ? "Nicht gut (komplett weg) gespeichert" : "Nicht gut (anders umsetzen) gespeichert"))+": "+global.review.title);
        } else review_note("Urteil konnte nicht gespeichert werden - bitte erneut versuchen.");
    }
}
/// The game font only covers ASCII: umlauts are shown as ae/oe/ue/ss (the comment itself is stored unchanged).
function review_ascii(_t) {
    var a=["ä","ö","ü","Ä","Ö","Ü","ß"],b=["ae","oe","ue","Ae","Oe","Ue","ss"];
    for(var i=0;i<7;i++)_t=string_replace_all(_t,a[i],b[i]);
    return _t;
}
function review_feedback_draw() {
    var fb=global.review.fb,g=review_feedback_geometry(),good=fb.verdict=="good",mx=device_mouse_x_to_gui(0),my=device_mouse_y_to_gui(0);
    draw_set_alpha(.6);draw_set_color(c_black);draw_rectangle(0,0,display_get_gui_width(),display_get_gui_height(),false);draw_set_alpha(1);
    talent_frame_panel(g.x,g.y,g.w,g.h,good ? make_color_rgb(126,224,140) : make_color_rgb(236,120,104));
    draw_set_halign(fa_left);draw_set_valign(fa_top);draw_set_color(good ? make_color_rgb(126,224,140) : make_color_rgb(236,120,104));
    draw_text_transformed(g.x+20,g.y+16,good ? "GUT - FREIGEBEN" : "NICHT GUT",1,1,0);
    draw_set_color(make_color_rgb(176,196,210));
    draw_text_ext_transformed(g.x+20,g.y+44,good ? "Was war gut? Wunsch dazu, z. B. \"genau so, nur etwas schneller\" (optional)."
        : "Soll es komplett weg oder anders umgesetzt werden? Was genau? (Pfeile / Tab / Klick waehlen)",18,(g.w-40)/.8,.8,.8,0);
    if(!good) for(var k=0;k<2;k++) {
        var bx=g.ox+k*(g.ow+20),on=(k==0 && fb.decision=="remove") || (k==1 && fb.decision=="change");
        spell_ui_panel(bx,g.oy,g.ow,g.oh,on);draw_set_halign(fa_center);draw_set_valign(fa_middle);
        draw_set_color(on ? make_color_rgb(238,207,133) : make_color_rgb(150,160,170));
        draw_text_transformed(bx+g.ow*.5,g.oy+g.oh*.5,(on ? "> " : "")+(k==0 ? "Komplett weg" : "Anders umsetzen"),.9,.9,0);
    }
    var ty=good ? g.oy : g.ty,th=good ? g.th+56 : g.th;
    draw_set_color(make_color_rgb(12,18,26));draw_rectangle(g.tx,ty,g.tx+g.tw,ty+th,false);
    draw_set_color(make_color_rgb(110,130,150));draw_rectangle(g.tx,ty,g.tx+g.tw,ty+th,true);
    draw_set_halign(fa_left);draw_set_valign(fa_top);draw_set_color(c_white);
    var caret=(current_time div 500) mod 2==0 ? "|" : "";
    draw_text_ext_transformed(g.tx+8,ty+6,review_ascii(fb.text)+caret,18,(g.tw-16)/.85,.85,.85,0);
    draw_set_color(make_color_rgb(140,156,170));
    draw_text_transformed(g.tx,ty+th+6,"Tippen oder diktieren (Windows: Win+H)  |  "+string(string_length(fb.text))+"/"+string(REVIEW_COMMENT_MAX)+" Zeichen",.72,.72,0);
    var hs=point_in_rectangle(mx,my,g.sx,g.sy,g.sx+g.sw,g.sy+g.sh),hc=point_in_rectangle(mx,my,g.cx,g.cy,g.cx+g.cw,g.cy+g.ch);
    spell_ui_panel(g.sx,g.sy,g.sw,g.sh,hs);spell_ui_panel(g.cx,g.cy,g.cw,g.ch,hc);
    draw_set_halign(fa_center);draw_set_valign(fa_middle);
    draw_set_color(good ? make_color_rgb(126,224,140) : make_color_rgb(238,207,133));draw_text(g.sx+g.sw*.5,g.sy+g.sh*.5,"Speichern (Enter)");
    draw_set_color(make_color_rgb(176,196,210));draw_text(g.cx+g.cw*.5,g.cy+g.ch*.5,"Abbrechen (Esc)");
    draw_set_halign(fa_left);draw_set_valign(fa_top);draw_set_color(c_white);
}
function review_pause_extra_draw() {
    if(!review_active())return;
    var gw=display_get_gui_width(),gh=display_get_gui_height(),r=global.review,w=min(540,gw*.42),x0=gw-w-18,y0=gh-150; // bottom right: free of the pause list and build texts
    spell_ui_panel(x0,y0,w,100,false);
    draw_set_halign(fa_left);draw_set_valign(fa_top);draw_set_color(make_color_rgb(238,207,133));
    draw_text_transformed(x0+12,y0+8,"REVIEW: "+r.title+"  (Rev. "+string(r.revision)+")",.85,.85,0);
    draw_set_color(make_color_rgb(176,196,210));
    var v=review_local_verdict(r.id,r.revision);
    draw_text_ext_transformed(x0+12,y0+32,is_struct(v) ? (review_s(v,"verdict","good")=="good" ? "Du hast \"Gut\" gespeichert" : "Du hast \"Nicht gut\" gespeichert")+(review_s(v,"comment","")!="" ? ": "+review_ascii(string_copy(v.comment,1,70)) : ".")+" Der Agent liest es beim naechsten Auftrag."
        : "Gut oder Nicht gut waehlen und dazuschreiben, was gut war oder was anders sein soll (tippen oder Win+H). Verlassen ohne Urteil laesst den Eintrag offen.",18,(w-24)/.78,.78,.78,0);
    if(variable_global_exists("review_saved_t") && global.review_saved_t>0){draw_set_color(make_color_rgb(126,224,140));draw_text_transformed(x0+12,y0+76,r.note,.8,.8,0);}
}
/// Verdict rows of the pause list: green check ("Gut") or red cross ("Nicht gut"); darker once saved.
function review_approve_button_draw(_x,_y,_w,_h,_label,_sel) {
    var good=review_verdict_of_label(_label)=="good",done=string_pos("gespeichert",_label)>0;
    var base=good ? (done ? make_color_rgb(40,96,58) : make_color_rgb(34,112,62)) : (done ? make_color_rgb(104,44,40) : make_color_rgb(128,48,42));
    draw_set_alpha(1);draw_set_color(base);draw_rectangle(_x,_y,_x+_w,_y+_h,false);
    draw_set_color(_sel ? c_white : (good ? make_color_rgb(126,224,140) : make_color_rgb(236,120,104)));draw_rectangle(_x,_y,_x+_w,_y+_h,true);draw_rectangle(_x+1,_y+1,_x+_w-1,_y+_h-1,true);
    var cx=_x+26,cy=_y+_h*.5;draw_set_color(c_white);
    if(good){draw_line_width(cx-9,cy,cx-3,cy+7,4);draw_line_width(cx-3,cy+7,cx+10,cy-8,4);}
    else {draw_line_width(cx-8,cy-8,cx+8,cy+8,4);draw_line_width(cx-8,cy+8,cx+8,cy-8,4);}
    draw_set_halign(fa_left);draw_set_valign(fa_middle);draw_text_transformed(_x+46,cy,_label,.95,.95,0);
}

// ---------------- Review Center screen (main menu) ----------------
function review_center_filters() {static f=["Offen","Freigegeben","Nicht gut","Archiv"];return f;}
function review_center_open() {
    global.review_registry_cache=undefined;review_local_load();
    if(!variable_global_exists("review_ui"))global.review_ui={filter:0,sel:0,scroll:0,last_click:-1,click_t:0};
    global.review_ui.sel=0;global.review_ui.scroll=0;
}
/// Rows: category headers and entries matching the filter, grouped by category in registry order.
function review_center_rows() {
    var e=review_entries(),f=global.review_ui.filter,cats=[],rows=[];
    for(var i=0;i<array_length(e);i++) {
        if(!review_filter_match(f,review_state(e[i])))continue;
        if(!array_contains(cats,e[i].category))array_push(cats,e[i].category);
    }
    for(var c=0;c<array_length(cats);c++) {
        array_push(rows,{header:true,text:cats[c]});
        for(var i=0;i<array_length(e);i++) {
            var st=review_state(e[i]);
            if(review_filter_match(f,st) && e[i].category==cats[c])array_push(rows,{header:false,entry:e[i],state:st});
        }
    }
    return rows;
}
function review_center_geometry() {var gw=display_get_gui_width(),gh=display_get_gui_height();return {lx:24,ly:118,lw:gw*.52,lh:gh-118-54,row:34,dx:gw*.52+40,dy:118,dw:gw-(gw*.52+40)-24,dh:gh-118-54};}
function review_center_step() {
    var ui=global.review_ui,G=review_center_geometry(),rows=review_center_rows(),n=array_length(rows),vis=floor(G.lh/G.row);
    if(keyboard_check_pressed(vk_escape)){fg_sfx("ui_back");menu_mode="main";menu_index=4;return;}
    if(keyboard_check_pressed(vk_tab)){ui.filter=(ui.filter+1) mod 4;ui.sel=0;ui.scroll=0;fg_sfx("ui_click");rows=review_center_rows();n=array_length(rows);}
    var mx=device_mouse_x_to_gui(0),my=device_mouse_y_to_gui(0);
    for(var t=0;t<4;t++)if(mouse_check_button_pressed(mb_left) && point_in_rectangle(mx,my,G.lx+t*150,G.ly-38,G.lx+t*150+140,G.ly-8)){ui.filter=t;ui.sel=0;ui.scroll=0;fg_sfx("ui_click");return;}
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
    draw_text_transformed(24,46,"Jeder Eintrag startet ein spielbares Szenario mit den echten Spielsystemen. Im Spiel: Esc -> \"Gut\" oder \"Nicht gut\", mit Kommentar.",.72,.72,0);
    for(var t=0;t<4;t++) {
        var tx=G.lx+t*150,cnt=0,e=review_entries();
        for(var i=0;i<array_length(e);i++)if(review_filter_match(t,review_state(e[i])))cnt++;
        spell_ui_panel(tx,G.ly-38,140,30,ui.filter==t);draw_set_halign(fa_center);draw_set_valign(fa_middle);draw_set_color(ui.filter==t ? make_color_rgb(238,207,133) : c_white);
        draw_text_transformed(tx+70,G.ly-23,review_center_filters()[t]+" ("+string(cnt)+")",.8,.8,0);
    }
    draw_set_halign(fa_left);draw_set_valign(fa_middle);
    if(n==0){draw_set_color(make_color_rgb(140,156,170));draw_text_transformed(G.lx+8,G.ly+24,ui.filter==0 ? "Keine offenen Pruefungen." : "Keine Eintraege.",.85,.85,0);}
    for(var k=ui.scroll;k<min(n,ui.scroll+vis);k++) {
        var yy=G.ly+(k-ui.scroll)*G.row,row=rows[k];
        if(row.header){draw_set_color(make_color_rgb(150,176,198));draw_text_transformed(G.lx+4,yy+G.row*.5+4,string_upper(row.text),.78,.78,0);draw_set_alpha(.35);draw_line(G.lx,yy+G.row-3,G.lx+G.lw,yy+G.row-3);draw_set_alpha(1);continue;}
        spell_ui_panel(G.lx,yy+2,G.lw,G.row-4,k==ui.sel);
        var e=row.entry,bad=row.state=="local_bad" || row.state=="rejected";
        var col=row.state=="local" ? make_color_rgb(126,224,140) : (bad ? make_color_rgb(236,120,104) : (row.state=="open" ? c_white : make_color_rgb(150,160,170)));
        var lbl=(row.state=="local" || row.state=="approved" || row.state=="processed" ? "[OK] " : (bad ? "[X] " : (row.state=="withdrawn" ? "[-] " : "")))+e.title;
        var rt="Lv "+string(review_level(e))+"  Rev. "+string(e.revision),maxw=(G.lw-34-string_width(rt)*.72)/.82;
        // long titles are cut before the level/revision column (full title in the detail panel)
        if(string_width(lbl)>maxw){while(string_length(lbl)>4 && string_width(lbl+"...")>maxw)lbl=string_copy(lbl,1,string_length(lbl)-1);lbl+="...";}
        draw_set_color(col);draw_text_transformed(G.lx+12,yy+G.row*.5,lbl,.82,.82,0);
        draw_set_halign(fa_right);draw_set_color(make_color_rgb(150,168,182));
        draw_text_transformed(G.lx+G.lw-10,yy+G.row*.5,rt,.72,.72,0);draw_set_halign(fa_left);
    }
    if(n>vis){var bh=G.lh*vis/n,by=G.ly+(G.lh-bh)*ui.scroll/max(1,n-vis);draw_set_color(make_color_rgb(70,86,100));draw_rectangle(G.lx+G.lw+6,G.ly,G.lx+G.lw+10,G.ly+G.lh,false);draw_set_color(make_color_rgb(170,190,206));draw_rectangle(G.lx+G.lw+6,by,G.lx+G.lw+10,by+bh,false);}
    // detail panel
    talent_frame_panel(G.dx,G.dy-38,G.dw,G.dh+38,make_color_rgb(150,176,198));
    draw_set_valign(fa_top);
    if(n>0 && !rows[clamp(ui.sel,0,n-1)].header) {
        var e=rows[ui.sel].entry,s=e.scenario,yy=G.dy-24,tw=G.dw-32;
        draw_set_color(make_color_rgb(238,207,133));draw_text_ext_transformed(G.dx+16,yy,e.title,20,tw/.95,.95,.95,0);yy+=string_height_ext(e.title,20,tw/.95)*.95+10;
        var st=rows[ui.sel].state,stt=st=="open" ? "Offen - wartet auf deine Pruefung" : (st=="local" ? "Von dir als gut bewertet - wartet auf den Agenten" : (st=="processed" ? "Freigegeben und verarbeitet"
            : (st=="local_bad" ? "Von dir als nicht gut bewertet - wartet auf den Agenten" : (st=="rejected" ? "Nicht gut - der Agent setzt es um oder entfernt es" : (st=="superseded" ? "Durch neue Revision ersetzt" : (st=="withdrawn" ? "Zurueckgezogen - vom Agenten nach Design-Kanon entschieden (keine persoenliche Freigabe)" : "Freigegeben"))))));
        var lv=review_local_verdict(e.id,e.revision);
        if(is_struct(lv))stt+=" | Dein Urteil: "+(review_s(lv,"verdict","good")=="good" ? "gut" : (review_s(lv,"decision","change")=="remove" ? "nicht gut, komplett weg" : "nicht gut, anders umsetzen"))+(review_s(lv,"comment","")!="" ? " - \""+review_ascii(lv.comment)+"\"" : "");
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
