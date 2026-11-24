fg_audio_tick(max(0,delta_time/1000000));
if(menu_mode=="boss_test"){boss_test_menu_step();exit;}
var previous_menu_index=menu_index;
var labels=menu_labels(menu_mode), count=array_length(labels);
if (keyboard_check_pressed(vk_up) || keyboard_check_pressed(ord("W"))) menu_index=(menu_index+count-1) mod count;
if (keyboard_check_pressed(vk_down) || keyboard_check_pressed(ord("S"))) menu_index=(menu_index+1) mod count;
var ui=menu_geometry(count,menu_mode=="characters");
var mx=device_mouse_x_to_gui(0), my=device_mouse_y_to_gui(0), hover=-1;
for(var i=0;i<count;i++) if(point_in_rectangle(mx,my,ui.x,ui.y+i*62,ui.x+ui.w,ui.y+i*62+ui.h)) hover=i;
if (hover>=0) menu_index=hover;
fg_audio_hover(previous_menu_index,menu_index);
if (menu_mode!="main" && keyboard_check_pressed(vk_escape)) {
    fg_sfx("ui_back");
    menu_mode=menu_mode=="levels" ? "characters" : "main";
    menu_index=0;
    exit;
}
if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || (mouse_check_button_pressed(mb_left) && hover>=0)) menu_activate(menu_index);
