/// Native boss-mechanics checks (docs/Design/Boss-Design.md): forced abilities per boss and phase with an oracle
/// "dodger" bot (does a reachable safe position exist?), plus a max-range kiting bot (does kiting still meet
/// the mechanics, do catch-up moves happen?). Injected only into the copy built by run_native_harness.py boss.
function gp_key_down(_key) {return false;}
function gp_key_pressed(_key) {return false;}
function gp_mouse_down(_button) {return false;}
function gp_mouse_pressed(_button) {return false;}
function gp_mouse_x() {return instance_exists(ObjectPlayer) ? ObjectPlayer.x+200 : 0;}
function gp_mouse_y() {return instance_exists(ObjectPlayer) ? ObjectPlayer.y : 0;}
function gp_gui_x(_device) {return -100;}
function gp_gui_y(_device) {return -100;}
function bh_show_error(_msg,_abort=false) {show_debug_message("BOSSMECH_EXCEPTION show_error "+string(_msg));throw string(_msg);}
function bh_check(_ok,_msg) {
    global.bh_checks++;
    if(!_ok){global.bh_failed=true;array_push(global.bh_failures,_msg);show_debug_message("BOSSMECH FAIL "+_msg);}
    else show_debug_message("BOSSMECH PASS "+_msg);
}
function bh_init() {
    if(variable_global_exists("bh_ready"))return;
    global.bh_ready=true;global.bh_checks=0;global.bh_failed=false;global.bh_failures=[];global.bh_metrics={};global.bh_rows=[];
    // runs: [boss, class, mode]
    global.bh_runs=[["storm_warden","Mage","patterns"],["twins","Mage","patterns"],["behemoth","Mage","patterns"],
        ["storm_warden","Ranger","kite"],["twins","Ranger","kite"],["behemoth","Ranger","kite"]];
    global.bh_run=0;global.bh_stage=0;global.bh_frame=0;global.bh_case=0;global.bh_done=false;global.bh_shot="";global.bh_world_shot="";
}
function bh_menu_tick() {
    bh_init();
    if(global.bh_done){show_debug_message("BOSSMECH_RESULT "+json_stringify({passed:!global.bh_failed,checks:global.bh_checks,failures:global.bh_failures,metrics:global.bh_metrics,rows:global.bh_rows}));game_end();return;}
    if(global.bh_stage!=0)return;
    var r=global.bh_runs[global.bh_run];
    global.bh_stage=1;global.bh_frame=0;global.bh_case=0;
    boss_test_start(r[0],15,r[1],4242+global.bh_run,-1,false,1);
}
function bh_boss() {return instance_exists(global.active_boss) ? global.active_boss : noone;}
function bh_center(_b) {
    if(variable_instance_exists(_b,"v2_kind") && _b.v2_kind=="twins" && instance_exists(_b.v2_child))return {x:(_b.x+_b.v2_child.x)*.5,y:(_b.y+_b.v2_child.y)*.5};
    return {x:_b.x,y:_b.y};
}
/// Per-frame list of hazards that matter within _horizon seconds, each with a bounding circle (cheap prefilter).
function bh_relevant(_horizon) {
    var out=[];if(!variable_global_exists("bv2_hazards"))return out;
    for(var i=0;i<array_length(global.bv2_hazards);i++) {
        var h=global.bv2_hazards[i];
        if(h.age>=h.warning+h.active || h.warning-h.age>_horizon)continue;
        var g=h.g,cx=g.x,cy=g.y,r=g.radius+16;
        if(g.shape=="line" || g.shape=="rectangle"){cx=g.x+lengthdir_x(g.radius*.5,g.angle);cy=g.y+lengthdir_y(g.radius*.5,g.angle);r=sqrt(sqr(g.radius*.5)+sqr(g.width*.5))+16;}
        if(variable_struct_exists(h,"sweep_from")){cx=g.x;cy=g.y;r=g.radius+40;}
        if(variable_struct_exists(h,"expand_from"))r=max(r,h.expand_from+16);
        array_push(out,{h:h,cx:cx,cy:cy,r:r});
    }
    return out;
}
/// Oracle danger test of a world point against the prefiltered hazards (12 px player margin on circles/rings).
function bh_point_unsafe_list(_list,_px,_py) {
    var probe={x:_px,y:_py};
    for(var i=0;i<array_length(_list);i++) {
        var e=_list[i];if(point_distance(e.cx,e.cy,_px,_py-10)>e.r)continue;
        var h=e.h;
        if(variable_struct_exists(h,"sweep_from")) {
            var d=point_distance(h.g.x,h.g.y,_px,_py-10);
            var a=point_direction(h.g.x,h.g.y,_px,_py-10),lo=min(h.sweep_from,h.sweep_to),hi=max(h.sweep_from,h.sweep_to);
            var halfspan=(hi-lo)*.5+(h.g.shape=="sector" ? h.g.span*.5 : 0)+radtodeg(arctan2(h.g.width*.5+14,max(30,d)));
            if(abs(angle_difference(a,(lo+hi)*.5))<=halfspan)return true;
            continue;
        }
        if(bv2_hazard_hit(h,probe))return true;
        if(h.g.shape!="line" && h.g.shape!="rectangle")for(var k=0;k<4;k++)if(bv2_hazard_hit(h,{x:_px+lengthdir_x(12,k*90),y:_py+lengthdir_y(12,k*90)}))return true;
    }
    return false;
}
function bh_point_unsafe(_px,_py,_horizon) {return bh_point_unsafe_list(bh_relevant(_horizon),_px,_py);}
function bh_move_toward(_pl,_tx,_ty,_speed,_dt) {
    var d=point_distance(_pl.x,_pl.y,_tx,_ty);if(d<1)return;
    var step=min(d,_speed*_dt),a=point_direction(_pl.x,_pl.y,_tx,_ty),ox=_pl.x,oy=_pl.y;
    _pl.x=clamp(_pl.x+lengthdir_x(step,a),20,room_width-20);_pl.y=clamp(_pl.y+lengthdir_y(step,a),20,room_height-20);
    scenery_resolve(_pl,ox,oy);
}
/// Counts every bv2 hazard that actually touches the (unprotected) player once.
function bh_contacts(_pl,_rec) {
    if(!variable_global_exists("bv2_hazards"))return;
    for(var i=0;i<array_length(global.bv2_hazards);i++) {
        var h=global.bv2_hazards[i];
        if(!variable_struct_exists(h,"bh_seen")){h.bh_seen=true;_rec.hazards++;if(variable_struct_exists(h,"sweep_from"))_rec.max_beam=max(_rec.max_beam,h.g.radius);if(h.g.shape=="line" || h.g.shape=="rectangle")_rec.max_line=max(_rec.max_line,variable_struct_exists(h,"wave_length") ? h.wave_length : h.g.radius);
            if(_rec.mode=="kite"){var b=bh_boss();if(instance_exists(b)){var c=bh_center(b),reach=false;for(var s=0;s<36 && !reach;s++){var px=c.x+lengthdir_x(560,s*10),py=c.y+lengthdir_y(560,s*10);if(variable_struct_exists(h,"sweep_from")){var a=point_direction(h.g.x,h.g.y,px,py-10),lo=min(h.sweep_from,h.sweep_to),hi=max(h.sweep_from,h.sweep_to);if(point_distance(h.g.x,h.g.y,px,py-10)<=h.g.radius && abs(angle_difference(a,(lo+hi)*.5))<=(hi-lo)*.5+5)reach=true;}else if(bv2_hazard_hit(h,{x:px,y:py}))reach=true;}if(reach){_rec.reach++;var ab=b.v2_enabled && b.dragon_enabled ? b.boss_cast : string(b.v2_attack);if(!array_contains(_rec.reach_abilities,ab))array_push(_rec.reach_abilities,ab);}}}}
        if(h.age>=h.warning && h.age<h.warning+h.active && !variable_struct_exists(h,"bh_contact") && bv2_hazard_hit(h,_pl) && !player_protected_from(_pl,h.height)){h.bh_contact=true;_rec.contacts++;if(!array_contains(_rec.contact_kinds,h.kind))array_push(_rec.contact_kinds,h.kind);}
    }
}
function bh_case_list(_boss) {
    var out=[];
    for(var a=1;a<=9;a++){array_push(out,[a,1]);array_push(out,[a,3]);}
    return out;
}
function bh_new_rec(_mode,_label) {return {natural:0,forced_catchup:false,dist_sum:0,mode:_mode,label:_label,hazards:0,contacts:0,contact_kinds:[],unsafe_frames:0,frames:0,moved:0,max_beam:0,max_line:0,reach:0,reach_abilities:[],catchups:0,start_unsafe:false};}
function bh_controller_tick() {
    bh_init();
    if(!instance_exists(ObjectPlayer) || global.bh_stage==0)return;
    var pl=ObjectPlayer,dt=1/60,run=global.bh_runs[global.bh_run],b=bh_boss();
    global.bh_frame++;
    if(variable_global_exists("boss_test") && is_struct(global.boss_test))global.boss_test.invulnerable=true;
    pl.hp=pl.max_hp;with(ObjectMonster)if(!variable_instance_exists(id,"boss_twin") && !variable_instance_exists(id,"boss_minion"))instance_destroy();
    if(global.bh_stage==1) { // wait until the boss of this run exists
        if(!instance_exists(b) || global.bh_frame<20)return;
        bh_check(b.boss_id==run[0],run[0]+" spawned in boss test mode");
        bh_check(b.v2_unlocked==9,run[0]+" minute 15 unlocks 9 abilities");
        global.bh_stage=run[2]=="patterns" ? 2 : 5;global.bh_frame=0;global.bh_case=0;
        global.bh_cases=bh_case_list(run[0]);
        return;
    }
    if(!instance_exists(b)) {bh_check(false,run[0]+" boss vanished during "+run[2]);bh_next_run();return;}
    b.hp=max(b.hp,b.max_hp*.3);
    if(global.bh_stage==2) { // start a forced case
        var c=global.bh_cases[global.bh_case],ab=c[0],ph=c[1];
        bv2_clear_owner(b);global.hostile_bullets=[];
        b.boss_phase=ph;b.hp=b.max_hp*(ph==1 ? .95 : .35);
        if(variable_instance_exists(b,"bc_catch")){b.bc_catch=undefined;b.bc_far_time=0;b.bc_catch_cd=999;b.bc_alpha=1;b.bc_lift=0;}
        // put the player in a neutral spot 330 px in front of the boss
        var cen=bh_center(b);pl.x=clamp(cen.x+(cen.x>room_width/2 ? -330 : 330),200,room_width-200);pl.y=clamp(cen.y+60,250,room_height-200);
        global.boss_test.ability=ab;
        var ok=boss_v2_force_attack(b,ab);
        global.bh_rec=bh_new_rec("patterns",run[0]+" A"+string(ab)+" P"+string(ph));
        bh_check(ok,global.bh_rec.label+" can be forced");
        global.bh_case_frame=0;global.bh_stage=3;global.bh_start_x=pl.x;global.bh_start_y=pl.y;
        return;
    }
    if(global.bh_stage==3) { // oracle dodger: move to the nearest point that stays safe for the next 0.9 s
        var rec=global.bh_rec;global.bh_case_frame++;rec.frames++;
        var spd=pl.moveSpeed*60,best=-1,bx=pl.x,by=pl.y,any=false,soon=bh_relevant(1.3),now=bh_relevant(.35);
        if(!bh_point_unsafe_list(soon,pl.x,pl.y)){best=0;}
        else {
            if(global.bh_case_frame<5)rec.start_unsafe=true;
            for(var r=45;r<=450 && best<0;r+=45)for(var k=0;k<16;k++){var px=pl.x+lengthdir_x(r,k*22.5),py=pl.y+lengthdir_y(r,k*22.5);if(px<30 || py<30 || px>room_width-30 || py>room_height-30)continue;if(!bh_point_unsafe_list(soon,px,py)){best=r;bx=px;by=py;break;}}
        }
        if(bh_point_unsafe_list(now,pl.x,pl.y)) {
            for(var r=45;r<=315 && !any;r+=45)for(var k=0;k<16;k++)if(!bh_point_unsafe_list(now,pl.x+lengthdir_x(r,k*22.5),pl.y+lengthdir_y(r,k*22.5))){any=true;break;}
            if(!any)rec.unsafe_frames++;
        }
        if(best>0){bh_move_toward(pl,bx,by,spd,dt);rec.moved+=1;}
        bh_contacts(pl,rec);
        if(global.bh_case==4 && global.bh_case_frame==70 && run[0]=="storm_warden")global.bh_world_shot="dragon-beam-sweep";
        if(global.bh_case_frame==72){var c=global.bh_cases[global.bh_case];if(c[1]==3 && ((run[0]=="storm_warden" && c[0]==3) || (run[0]=="twins" && (c[0]==3 || c[0]==4 || c[0]==8)) || (run[0]=="behemoth" && (c[0]==2 || c[0]==5 || c[0]==6))))global.bh_world_shot=string_replace_all(rec.label," ","-");}
        if(global.bh_case_frame>=390) {
            array_push(global.bh_rows,{label:rec.label,hazards:rec.hazards,contacts:rec.contacts,kinds:rec.contact_kinds,unsafe_frames:rec.unsafe_frames,frames:rec.frames,moved:rec.moved,start_unsafe:rec.start_unsafe,max_beam:rec.max_beam,max_line:rec.max_line});
            global.bh_case++;global.bh_stage=global.bh_case<array_length(global.bh_cases) ? 2 : 4;
        }
        return;
    }
    if(global.bh_stage==4) {
        bh_pattern_checks(run[0]);
        // Escalation rule: complex variants of abilities 1-3 only for bosses with >= 6 unlocked abilities (minute 10+).
        var probe=run[0]=="storm_warden" ? 3 : (run[0]=="twins" ? 3 : 2),saved=b.v2_unlocked;
        for(var tier=0;tier<2;tier++) {
            bv2_clear_owner(b);b.v2_unlocked=tier==0 ? 3 : 9;b.boss_phase=3;b.hp=b.max_hp*.35;boss_v2_force_attack(b,probe);
            var cells=0;for(var i=0;i<array_length(global.bv2_hazards);i++)if(global.bv2_hazards[i].owner==b && variable_struct_exists(global.bv2_hazards[i],"cell"))cells++;
            bh_check(tier==0 ? cells==0 : cells>0,run[0]+" ability "+string(probe)+" phase 3 with "+string(b.v2_unlocked)+" unlocked: "+(tier==0 ? "no" : "has")+" pattern cells ("+string(cells)+")");
        }
        b.v2_unlocked=saved;bv2_clear_owner(b);
        bh_next_run();return;
    }
    if(global.bh_stage==5) { // max-range kiting with the fastest class, normal rotation incl. catch-up moves
        if(global.bh_frame==1){global.boss_test.ability=-1;bv2_clear_owner(b);b.boss_phase=3;b.hp=b.max_hp*.35;global.bh_rec=bh_new_rec("kite",run[0]+" kite 560px");global.bh_kite_a=point_direction(bh_center(b).x,bh_center(b).y,pl.x,pl.y);global.bh_was_catch=false;}
        var rec=global.bh_rec,cen=bh_center(b),spd=pl.moveSpeed*60;rec.frames++;rec.dist_sum+=point_distance(cen.x,cen.y,pl.x,pl.y);
        global.bh_kite_a+=spd*dt/560*57.2958*.8;
        bh_move_toward(pl,cen.x+lengthdir_x(560,global.bh_kite_a),cen.y+lengthdir_y(560,global.bh_kite_a),spd,dt);
        // Each catch-up code path must run at least once: from 25 s on, allow it like the F7 test key does.
        if(global.bh_frame==60*25 && rec.catchups==0 && variable_instance_exists(b,"bc_far_time")){b.bc_far_time=99;b.bc_catch_cd=0;rec.forced_catchup=true;}
        var catching=variable_instance_exists(b,"bc_catch") && is_struct(b.bc_catch);
        if(catching && !global.bh_was_catch){rec.catchups++;if(!rec.forced_catchup)rec.natural++;global.bh_world_shot=run[0]+"-catchup";}
        global.bh_was_catch=catching;
        bh_contacts(pl,rec);
        if(global.bh_frame>=60*45) {
            array_push(global.bh_rows,{label:rec.label,hazards:rec.hazards,contacts:rec.contacts,kinds:rec.contact_kinds,reach:rec.reach,reach_abilities:rec.reach_abilities,catchups:rec.catchups,forced_catchup:rec.forced_catchup,frames:rec.frames});
            var avg_dist=rec.dist_sum/max(1,rec.frames);global.bh_metrics[$ run[0]+"_kite_mean_distance"]=avg_dist;
            bh_check(rec.natural>=1 || avg_dist<520,rec.label+": boss closes in by itself (natural catch-ups "+string(rec.natural)+", mean distance "+string(round(avg_dist))+")");
            bh_check(rec.catchups>=1,rec.label+": catch-up move code path ran ("+string(rec.catchups)+")");
            global.bh_metrics[$ run[0]+"_natural_catchups"]=rec.natural;
            bh_check(rec.reach>=3,rec.label+": mechanics still reach the 560 px kiting ring ("+string(rec.reach)+" hazards)");
            global.bh_metrics[$ run[0]+"_kite_contacts"]=rec.contacts;global.bh_metrics[$ run[0]+"_kite_reach"]=rec.reach;global.bh_metrics[$ run[0]+"_catchups"]=rec.catchups;
            bh_next_run();
        }
    }
}
function bh_pattern_checks(_boss) {
    var rows=global.bh_rows,total_unsafe=0,total_frames=0,total_contacts=0,moved_cases=0,n=0,hazard_cases=0;
    for(var i=0;i<array_length(rows);i++) {
        var r=rows[i];if(string_pos(_boss+" A",r.label)!=1)continue;n++;
        total_unsafe+=r.unsafe_frames;total_frames+=r.frames;total_contacts+=r.contacts;if(r.moved>20)moved_cases++;if(r.hazards>0)hazard_cases++;
        bh_check(r.unsafe_frames<=6,r.label+": a safe position stays reachable (unsafe frames "+string(r.unsafe_frames)+")");
    }
    global.bh_metrics[$ _boss+"_oracle_contacts"]=total_contacts;global.bh_metrics[$ _boss+"_cases"]=n;global.bh_metrics[$ _boss+"_cases_with_movement"]=moved_cases;
    var beam=0,line=0;for(var i=0;i<array_length(rows);i++)if(string_pos(_boss+" A",rows[i].label)==1){beam=max(beam,rows[i].max_beam);line=max(line,rows[i].max_line);}
    if(_boss=="storm_warden")bh_check(beam>=2000,"dragon fire beam reaches >= 2000 px ("+string(beam)+")");
    if(_boss=="twins")bh_check(line>=2000,"twins cross beams reach >= 2000 px ("+string(line)+")");
    if(_boss=="behemoth")bh_check(line>=1500,"behemoth mud wave lane reaches 1500 px ("+string(line)+")");
    // Only cases with shared bv2 hazards are visible to the oracle (legacy dragon projectiles/rings are not).
    bh_check(moved_cases*2>=hazard_cases,_boss+": patterns force repositioning in "+string(moved_cases)+" of "+string(hazard_cases)+" hazard cases");
    global.bh_metrics[$ _boss+"_hazard_cases"]=hazard_cases;
}
function bh_next_run() {
    global.bh_run++;global.bh_stage=0;global.bh_frame=0;
    if(global.bh_run>=array_length(global.bh_runs))global.bh_done=true;
    round_end_to_title();
}
function bh_gui_capture_begin() {}
function bh_gui_capture_end() {}
function bh_world_capture() {
    if(!variable_global_exists("bh_world_shot") || global.bh_world_shot=="")return;
    if(surface_exists(application_surface))surface_save(application_surface,"bhcapture-"+global.bh_world_shot+".png");
    global.bh_world_shot="";
}
