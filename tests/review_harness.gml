// Review Center end-to-end harness (prefix rv, tag REVIEW), driven by tests/tools/review/review_e2e.py.
// Runs three times against the save folder of the test project (FirstGameReviewE2E, never the real FirstGame folder):
//   phase a: open the Review Center, start test scenarios, close the pause menu without approving, approve through
//            real scripted clicks on the green button (first click arms, second saves) -> TEST approvals only.
//   phase b: same exe restarted -> approvals persisted, entries listed as approved.
//   phase c: rebuilt after review.py sync/bump on a registry copy -> processed entry archived, bumped entry open again,
//            archived scenario still starts the productive boss attack.
global.rv_press = []; global.rv_click = false; global.rv_gx = -100; global.rv_gy = -100;
function gp_key_down(_key) {return false;}
function gp_key_pressed(_key) {return array_contains(global.rv_press, _key);}
function gp_mouse_down(_button) {return false;}
function gp_mouse_pressed(_button) {return _button == mb_left && global.rv_click;}
function gp_mouse_x() {return instance_exists(ObjectPlayer) ? ObjectPlayer.x + 200 : 0;}
function gp_mouse_y() {return instance_exists(ObjectPlayer) ? ObjectPlayer.y : 0;}
function gp_gui_x(_device) {return global.rv_gx;}
function gp_gui_y(_device) {return global.rv_gy;}

function rv_init() {
    if (variable_global_exists("rv_ready")) return;
    global.rv_ready = true; global.rv_checks = 0; global.rv_failed = false; global.rv_failures = []; global.rv_metrics = {};
    global.rv_phase = file_exists("rv_phase_b.done") ? "c" : (file_exists("rv_phase_a.done") ? "b" : "a");
    global.rv_step = 0; global.rv_frame = 0; global.rv_done = false; global.rv_shot = ""; global.rv_world_shot = ""; global.rv_target = "test.e2e.one";
    show_debug_message("REVIEW phase " + global.rv_phase);
}
function rv_check(_ok, _msg) {
    global.rv_checks++;
    if (!_ok) {global.rv_failed = true; array_push(global.rv_failures, global.rv_phase + ": " + _msg); show_debug_message("REVIEW FAIL " + global.rv_phase + ": " + _msg);}
}
function rv_show_error(_msg, _abort = false) {show_debug_message("REVIEW_EXCEPTION show_error " + string(_msg)); throw string(_msg);}
function rv_input_clear() {global.rv_press = []; global.rv_click = false;}
function rv_next(_step) {global.rv_step = _step; global.rv_frame = 0;}
function rv_finish() {
    var f = file_text_open_write("rv_phase_" + global.rv_phase + ".done"); file_text_write_string(f, "ok"); file_text_close(f);
    global.rv_done = true;
}
function rv_result() {
    show_debug_message("REVIEW_RESULT " + json_stringify({phase: global.rv_phase, passed: !global.rv_failed, checks: global.rv_checks, failures: global.rv_failures, metrics: global.rv_metrics}));
    game_end();
}
/// Row index of an entry in the current Review Center list.
function rv_row_of(_id) {var r = review_center_rows(); for (var i = 0; i < array_length(r); i++) if (!r[i].header && r[i].entry.id == _id) return i; return -1;}
function rv_label_index(_pred) {var l = round_menu_labels(); for (var i = 0; i < array_length(l); i++) if (_pred(l[i])) return i; return -1;}
/// Click the centre of pause-list row _i (same geometry as round_menu_step).
function rv_click_pause_row(_i) {var ui = pause_geometry(); global.rv_gx = ui.x + ui.w * .5; global.rv_gy = ui.y + _i * 62 + ui.h * .5; global.rv_click = true;}
function rv_approvals_in_file() {var t = review_read_text(REVIEW_APPROVAL_FILE); if (t == "") return []; try {return json_parse(t).approvals;} catch (_e) {return [];}}

function rv_menu_tick() {
    rv_init(); rv_input_clear();
    if (global.rv_done) {rv_result(); return;}
    global.rv_frame++;
    if (global.rv_frame < 8) return;
    switch (global.rv_phase) {
        case "a":
            if (global.rv_step == 0) {
                var labels = menu_labels("main"), idx = -1;
                for (var i = 0; i < array_length(labels); i++) if (string_pos("Review-Center", labels[i]) == 1) idx = i;
                rv_check(idx >= 0, "main menu lists the Review-Center");
                if (global.rv_frame == 8) global.rv_shot = "a0-main-menu";
                if (global.rv_frame < 12) return;
                menu_mode = "main"; menu_activate(idx); rv_next(1); return;
            }
            if (global.rv_step == 1) {
                rv_check(menu_mode == "review", "Review-Center screen opens");
                if (global.rv_target == "test.e2e.one") {
                    rv_check(rv_row_of("test.e2e.one") >= 0 && rv_row_of("test.e2e.two") >= 0, "test entries listed as open");
                    rv_check(rv_row_of("boss.dragon.beam") >= 0, "registry entries are listed dynamically");
                } else rv_check(rv_row_of("test.e2e.one") < 0, "approved entry left the open list at once");
                if (global.rv_frame == 10) global.rv_shot = "a1-review-center";
                if (global.rv_frame < 14) return;
                global.review_ui.sel = rv_row_of(global.rv_target); global.rv_press = [vk_enter]; rv_next(global.rv_target == "test.e2e.two" ? 20 : 2); return; // real Enter on the selected row
            }
            if ((global.rv_step == 2 || global.rv_step == 20) && global.rv_frame > 400) {rv_check(false, "scenario did not start"); global.rv_done = true;}
            return;
        case "b":
            if (global.rv_step == 0) {
                menu_mode = "main"; var labels = menu_labels("main");
                for (var i = 0; i < array_length(labels); i++) if (string_pos("Review-Center", labels[i]) == 1) menu_activate(i);
                rv_next(1); return;
            }
            if (global.rv_step == 1) {
                var e1 = review_find("test.e2e.one"), e2 = review_find("test.e2e.two");
                rv_check(is_struct(e1) && review_state(e1) == "local", "approval of entry one survived the restart");
                rv_check(is_struct(e2) && review_state(e2) == "local", "approval of entry two survived the restart");
                rv_check(rv_row_of("test.e2e.one") < 0, "approved entry no longer in the open list");
                var a = rv_approvals_in_file(), all_test = array_length(a) >= 2;
                for (var i = 0; i < array_length(a); i++) if (!review_s(a[i], "test", false)) all_test = false;
                rv_check(all_test, "every stored approval is marked as a technical test");
                global.review_ui.filter = 1; rv_next(2); return;
            }
            if (global.rv_step == 2) {
                if (global.rv_frame == 4) {rv_check(rv_row_of("test.e2e.one") >= 0, "approved entry listed under Freigegeben"); global.rv_shot = "b1-approved-tab";}
                if (global.rv_frame > 8) {rv_finish();}
            }
            return;
        case "c":
            if (global.rv_step == 0) {
                var e1 = review_find("test.e2e.one"), e2 = review_find("test.e2e.two");
                rv_check(is_struct(e1) && e1.status == "processed" && review_state(e1) == "processed", "synced approval -> processed");
                rv_check(is_struct(e2) && e2.revision == 2 && review_state(e2) == "open", "bumped revision is open again");
                rv_check(review_local_approved("test.e2e.two", 1) && !review_local_approved("test.e2e.two", 2), "old approval not transferred to the new revision");
                menu_mode = "main"; var labels = menu_labels("main");
                for (var i = 0; i < array_length(labels); i++) if (string_pos("Review-Center", labels[i]) == 1) menu_activate(i);
                rv_check(rv_row_of("test.e2e.one") < 0 && rv_row_of("test.e2e.two") >= 0, "open list: processed entry gone, new revision present");
                global.rv_shot = "c1-review-center"; rv_next(1); return;
            }
            if (global.rv_step == 1 && global.rv_frame > 6) {review_start("test.e2e.one"); rv_next(2); return;} // archived scenario stays startable
            if (global.rv_step == 2 && global.rv_frame > 400) {rv_check(false, "archived scenario did not start"); global.rv_done = true;}
            return;
    }
}
function rv_controller_tick() {
    rv_init(); rv_input_clear();
    if (global.rv_done) {rv_result(); return;}
    if (!instance_exists(ObjectPlayer) || !review_active()) return;
    global.rv_frame++;
    var pl = ObjectPlayer;
    switch (global.rv_phase) {
        case "a":
            switch (global.rv_step) {
                case 2: case 20:
                    if (global.rv_frame < 60) return;
                    var e = review_find(global.review.id);
                    rv_check(global.boss_test.active && instance_exists(global.active_boss), global.review.id + ": boss scenario running");
                    rv_check(global.current_level == review_level(e), global.review.id + ": player level = scenario level (" + string(review_level(e)) + ")");
                    rv_check(!talent_persistent() && dev_session_active(), "review session isolated from the talent save");
                    rv_check(global.boss_test.ability == 1, "forced ability set for repetition");
                    if (global.rv_step == 2) global.rv_world_shot = "a2-scenario";
                    rv_next(global.rv_step + 1); return;
                case 3: case 21:
                    if (global.rv_frame == 2) global.rv_press = [vk_escape];
                    if (global.rv_frame < 6) return;
                    rv_check(global.game_paused && global.normal_pause_active, "Escape opens the pause menu");
                    if (global.rv_step == 3) global.rv_shot = "a3-pause-approve";
                    rv_next(global.rv_step + 1); return;
                case 4: // leave without approving: "Weiter"
                    if (global.rv_frame == 4) rv_click_pause_row(0);
                    if (global.rv_frame < 8) return;
                    rv_check(!global.game_paused, "Weiter closes the menu");
                    rv_check(!review_local_approved(global.review.id, global.review.revision), "closing the menu does not approve");
                    rv_next(5); return;
                case 5:
                    if (global.rv_frame == 2) global.rv_press = [vk_escape];
                    if (global.rv_frame < 6) return;
                    rv_next(6); return;
                case 6: case 22: // first click arms the button
                    var ai = rv_label_index(function(_l) {return review_is_approve_label(_l);});
                    rv_check(ai >= 0, "green approval button present");
                    if (global.rv_frame == 2) rv_click_pause_row(ai);
                    if (global.rv_frame < 5) return;
                    rv_check(global.review.confirm_t > 0 && !review_local_approved(global.review.id, global.review.revision), "first click only arms the button");
                    if (global.rv_step == 6) global.rv_shot = "a4-approve-armed";
                    rv_next(global.rv_step + 1); return;
                case 7: case 23:
                    var ai2 = rv_label_index(function(_l) {return review_is_approve_label(_l);});
                    if (global.rv_frame == 2) rv_click_pause_row(ai2);
                    if (global.rv_frame < 6) return;
                    rv_check(review_local_approved(global.review.id, global.review.revision), global.review.id + ": approval saved by the second click");
                    var recs = rv_approvals_in_file(), last = array_length(recs) > 0 ? recs[array_length(recs) - 1] : undefined;
                    rv_check(is_struct(last) && last.test == true && last.id == global.review.id && last.source == "pause_menu_button", "stored record is a technical test approval");
                    rv_check(file_exists(REVIEW_APPROVAL_LOG), "append-only approval log written");
                    if (global.rv_step == 7) global.rv_shot = "a5-approve-saved";
                    rv_next(global.rv_step + 1); return;
                case 8: // review actions do not throw and keep state consistent
                    if (global.rv_frame == 2) {review_pause_activate("Leben & Abklingzeiten auffuellen"); rv_check(pl.hp == pl.max_hp, "restore fills hp");}
                    if (global.rv_frame == 4) {review_pause_activate("Attacke erneut ausloesen");}
                    if (global.rv_frame == 30) {pl.x += 300; review_reset_positions(); rv_check(abs(pl.x - global.review.start.px) < 1, "reset positions");}
                    if (global.rv_frame < 40) return;
                    global.rv_target = "test.e2e.two"; global.menu_return_mode = "review"; review_back_to_center();
                    global.rv_step = 1; global.rv_frame = 20; // menu phase picks entry two
                    return;
                case 24:
                    if (global.rv_frame < 4) return;
                    rv_finish(); return;
            }
            return;
        case "c":
            if (global.rv_step == 2) {
                if (global.rv_frame == 1) global.rv_metrics.archived_start = true;
                var owned = 0; for (var i = 0; i < array_length(global.bv2_hazards); i++) owned++;
                if (instance_exists(global.active_boss) && variable_instance_exists(global.active_boss, "enc_zones")) owned += array_length(global.active_boss.enc_zones);
                if (owned > 0 || (instance_exists(global.active_boss) && variable_instance_exists(global.active_boss, "boss_cast") && global.active_boss.boss_cast == "beam")) {
                    rv_check(true, ""); global.rv_metrics.attack_after_frames = global.rv_frame; rv_finish(); return;
                }
                if (global.rv_frame > 900) {rv_check(false, "productive beam attack did not start in the archived scenario"); rv_finish();}
            }
            return;
    }
}
/// Menu screens: redraw into a 1280x720 surface (GUI size) and save; called from ObjectMainMenu Draw_64 (driver hook).
function rv_menu_capture() {
    if (!variable_global_exists("rv_ready") || global.rv_shot == "" || instance_exists(ObjectPlayer)) return;
    if (menu_mode == "main") {screen_save("rvcapture-" + global.rv_shot + ".png"); global.rv_shot = ""; return;} // end of Draw_64: back buffer complete
    var s = surface_create(display_get_gui_width(), display_get_gui_height());
    surface_set_target(s); draw_clear(c_black);
    if (menu_mode == "review") review_center_draw();
    surface_reset_target(); surface_save(s, "rvcapture-" + global.rv_shot + ".png"); surface_free(s); global.rv_shot = "";
}
function rv_world_capture() {
    if (!variable_global_exists("rv_ready")) return;
    if (global.rv_world_shot != "" && surface_exists(application_surface)) {surface_save(application_surface, "rvcapture-" + global.rv_world_shot + ".png"); global.rv_world_shot = "";}
}
function rv_gui_capture_begin() {}
/// In-game GUI (pause menu): world + modal composited into one 1280x720 image.
function rv_gui_capture_end() {
    if (!variable_global_exists("rv_ready") || global.rv_shot == "" || !instance_exists(ObjectPlayer)) return;
    var s = surface_create(display_get_gui_width(), display_get_gui_height());
    surface_set_target(s); draw_clear(c_black);
    if (surface_exists(application_surface)) draw_surface_stretched(application_surface, 0, 0, display_get_gui_width(), display_get_gui_height());
    ui_modal_draw(); boss_test_draw_gui();
    surface_reset_target(); surface_save(s, "rvcapture-" + global.rv_shot + ".png"); surface_free(s); global.rv_shot = "";
}
