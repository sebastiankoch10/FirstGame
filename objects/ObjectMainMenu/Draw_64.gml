var gw = display_get_gui_width();
if(menu_mode=="boss_test"){boss_test_menu_draw();exit;}
if(menu_mode=="review"){review_center_draw();exit;}
var gh = display_get_gui_height();
draw_set_alpha(1);
draw_set_color(make_color_rgb(10, 16, 22));
draw_rectangle(0, 0, gw, gh, false);

draw_set_alpha(0.10);
draw_set_color(make_color_rgb(90, 125, 130));
for (var py = 0; py < gh; py += 24) draw_line(0, py, gw, py);
draw_set_alpha(1);

var labels=menu_labels(menu_mode);
var title_text=menu_mode=="characters" ? "CHARAKTER" : (menu_mode=="levels" ? "LEVEL" : (menu_mode=="settings" ? "EINSTELLUNGEN" : "FIRSTGAME"));
draw_set_halign(fa_center); draw_set_valign(fa_middle);
draw_set_color(make_color_rgb(218,186,112));
draw_text(gw*0.5,gh*0.18,title_text);
var count=array_length(labels), ui=menu_geometry(count,menu_mode=="characters" || menu_mode=="levels");
var menu_w=ui.w, menu_x=ui.x, button_h=ui.h, gap=ui.gap, top=ui.y;
var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);

for (var i = 0; i < count; i++) {
    var bx = menu_x;
    var by = top + i * (button_h + gap);
    var hovered = (mx >= bx && mx <= bx + menu_w && my >= by && my <= by + button_h);
    var selected = (i == menu_index) || hovered;
    draw_set_color(selected ? make_color_rgb(174, 132, 62) : make_color_rgb(38, 48, 58));
    draw_rectangle(bx, by, bx + menu_w, by + button_h, false);
    draw_set_color(selected ? make_color_rgb(245, 220, 150) : make_color_rgb(116, 132, 130));
    draw_rectangle(bx, by, bx + menu_w, by + button_h, true);
    draw_set_color(c_white);

    var text_label = labels[i];
    if (menu_mode == "settings" && i>=1 && i<=3) text_label += fg_audio_volume_label(i);
    if(menu_mode=="settings" && i==4) text_label+=global.audio_background ? ": Ein" : ": Aus";
    if(menu_mode=="settings" && i==5) text_label+=vfx_quality_label();
    draw_text(bx + menu_w * 0.5, by + button_h * 0.5, text_label);
}

if (menu_mode == "characters") {
    var descriptions = [
        "Ausgeglichen - hohes Leben - Schwert",
        "Sternenstab - maechtige Viererkombo",
        "Waldbogen - schnelle Salven und Pfeilhagel"
    ];
    var portrait_names = ["spr_fg_swordsmanv3_idle_down", "spr_fg_magev3_idle_down", "spr_fg_rangerv3_idle_down"];
    var portrait_sprite = asset_get_index(portrait_names[menu_index]);
    if (sprite_exists(portrait_sprite)) {
        var portrait_scale = min(200 / sprite_get_width(portrait_sprite), 240 / sprite_get_height(portrait_sprite));
        // Base model + start weapon (no equipment in the menu).
        var portrait_actors = ["swordsmanv3", "magev3", "rangerv3"];
        player_layers_draw(portrait_actors[menu_index], portrait_sprite, 0, gw * 0.78, gh * 0.55, portrait_scale, portrait_scale, c_white, 1, {});
    }
    draw_set_color(make_color_rgb(210, 218, 210));
    draw_text_ext(menu_x+menu_w*0.5, top + count * (button_h + gap) + 24, descriptions[menu_index], 20, menu_w);
} else if (menu_mode == "levels") {
    level_select_preview_draw(menu_index, gw, gh);
}
