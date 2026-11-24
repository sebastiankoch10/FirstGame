/// Equipment: every run starts without gear. Items drop from bosses (guaranteed) and rarely from normal enemies,
/// are picked up by walking over them, auto-equip into empty slots, otherwise go to the backpack.
/// Values are new design values (no earlier specification existed); see DEVELOPMENT_PROGRESS.md.
function equipment_config() {
    static cfg={enemy_drop_chance:.003,backpack_size:8,pickup_radius:34,max_world_drops:24,
        ilvl_minutes:2.5,rarity_mult:[1,1.1,1.22,1.38],rarity_stats:[1,2,3,4]};
    return cfg;
}
function equipment_slots() {static s=["weapon","head","chest","hands","feet","trinket"];return s;}
function equipment_slot_label(_slot) {
    switch(_slot){case "weapon":return "Waffe";case "head":return "Kopf";case "chest":return "Brust";case "hands":return "Haende";case "feet":return "Fuesse";default:return "Talisman";}
}
function equipment_rarity_name(_r) {static n=["Gewoehnlich","Magisch","Selten","Episch"];return n[clamp(_r,0,3)];}
function equipment_rarity_color(_r) {
    switch(clamp(_r,0,3)){case 0:return make_color_rgb(205,210,214);case 1:return make_color_rgb(112,170,255);case 2:return make_color_rgb(242,200,92);default:return make_color_rgb(196,124,255);}
}
function equipment_stat_info() {
    static info={
        armor:{label:"Ruestung",base:.5,per:.09,dec:1,pct:false},
        max_hp:{label:"Leben",base:6,per:1.3,dec:0,pct:false},
        move_pct:{label:"Bewegungstempo",base:.025,per:.002,dec:1,pct:true},
        pickup:{label:"Sammelradius",base:10,per:1.5,dec:0,pct:false},
        dodge_cd:{label:"Ausweich-Abklingzeit",base:.06,per:.008,dec:2,pct:false,minus:true,unit:" s"},
        haste:{label:"Angriffstempo",base:.03,per:.004,dec:1,pct:true},
        crit:{label:"Kritische Chance",base:.015,per:.002,dec:1,pct:true},
        power:{label:"Power",base:1,per:.18,dec:0,pct:false},
        weapon_pct:{label:"Waffenschaden",base:.05,per:.008,dec:1,pct:true},
        cdr_pct:{label:"Zauber-Abklingzeit",base:.02,per:.003,dec:1,pct:true,minus:true},
        area_pct:{label:"Wirkflaeche",base:.03,per:.004,dec:1,pct:true},
        elem_pct:{label:"Elementarbonus",base:.04,per:.005,dec:1,pct:true},
        regen:{label:"Leben pro Sekunde",base:.1,per:.015,dec:2,pct:false},
        dr:{label:"Schadensreduktion",base:.015,per:.002,dec:1,pct:true}
    };
    return info;
}
/// First entry is the slot's guaranteed primary stat.
function equipment_slot_pool(_slot) {
    switch(_slot) {
        case "weapon":return ["weapon_pct","crit","haste","power"];
        case "head":return ["armor","max_hp","cdr_pct","regen"];
        case "chest":return ["armor","max_hp","dr","regen"];
        case "hands":return ["armor","haste","crit","power"];
        case "feet":return ["armor","move_pct","dodge_cd","pickup"];
        default:return ["regen","power","area_pct","elem_pct","pickup","max_hp"];
    }
}
function equipment_base_name(_slot,_tier) {
    var t=clamp(_tier,0,3),cls=variable_global_exists("selected_character") ? global.selected_character : "Sword";
    switch(_slot) {
        case "weapon":
            if(cls=="Mage"){var n1=["Eichenstab","Kristallstab","Sternenzepter","Leerenfokus"];return n1[t];}
            if(cls=="Ranger"){var n2=["Jagdbogen","Kompositbogen","Mondbogen","Sturmbogen"];return n2[t];}
            var n3=["Kurzschwert","Langschwert","Runenklinge","Drachenzahn"];return n3[t];
        case "head":var n4=["Lederkappe","Eisenhelm","Runenhelm","Schuppenhelm"];return n4[t];
        case "chest":var n5=["Lederwams","Kettenhemd","Plattenpanzer","Schuppenpanzer"];return n5[t];
        case "hands":var n6=["Lederhandschuhe","Eisenhandschuhe","Runenhandschuhe","Klauenhandschuhe"];return n6[t];
        case "feet":var n7=["Lederstiefel","Wanderstiefel","Runenstiefel","Schattentreter"];return n7[t];
        default:var n8=["Knochenamulett","Silberring","Mondtalisman","Phoenixamulett"];return n8[t];
    }
}
function equipment_suffix(_stat) {
    switch(_stat){case "max_hp":return " des Baeren";case "haste":return " der Eile";case "crit":return " des Falken";case "move_pct":return " des Windes";
        case "power":return " der Macht";case "cdr_pct":return " der Weisheit";case "regen":return " des Lebens";case "armor":return " der Festung";
        case "dr":return " des Bollwerks";case "area_pct":return " der Weite";case "elem_pct":return " der Elemente";case "pickup":return " des Sammlers";
        case "dodge_cd":return " der Gewandtheit";default:return " der Klinge";}
}
/// Icon frame in spr_eq_icons: 0 sword, 1 staff, 2 bow, 3 head, 4 chest, 5 hands, 6 feet, 7 trinket.
function equipment_icon_frame(_slot) {
    if(_slot=="weapon"){var cls=variable_global_exists("selected_character") ? global.selected_character : "Sword";return cls=="Mage" ? 1 : (cls=="Ranger" ? 2 : 0);}
    var order=["head","chest","hands","feet","trinket"];
    for(var i=0;i<5;i++)if(order[i]==_slot)return 3+i;
    return 7;
}
/// Deterministic item generation from the run's own RNG stream (independent of particles/boss choice).
function equipment_rng() {
    global.equipment_seed=(global.equipment_seed*16807) mod 2147483647;
    return global.equipment_seed/2147483647;
}
function equipment_generate(_slot,_rarity,_ilvl) {
    var cfg=equipment_config(),info=equipment_stat_info(),pool=equipment_slot_pool(_slot),r=clamp(_rarity,0,3);
    var count=min(array_length(pool),cfg.rarity_stats[r]),chosen=[pool[0]],rest=[];
    for(var i=1;i<array_length(pool);i++)array_push(rest,pool[i]);
    while(array_length(chosen)<count && array_length(rest)>0){var k=floor(equipment_rng()*array_length(rest));array_push(chosen,rest[k]);array_delete(rest,k,1);}
    var stats={};
    for(var i=0;i<array_length(chosen);i++) {
        var key=chosen[i],s=info[$ key],v=(s.base+s.per*_ilvl)*cfg.rarity_mult[r]*(.88+equipment_rng()*.24);
        if(s.dec==0)v=max(1,round(v));
        stats[$ key]=v;
    }
    var name=equipment_base_name(_slot,floor((_ilvl-1)/4));
    if(r>=1 && count>=2)name+=equipment_suffix(chosen[1]);
    return {slot:_slot,rarity:r,ilvl:_ilvl,stats:stats,name:name,order:chosen};
}
function equipment_random_slot() {var s=equipment_slots();return s[floor(equipment_rng()*array_length(s))];}
function equipment_item_level() {return 1+floor((variable_global_exists("round_seconds") ? global.round_seconds : 0)/60/equipment_config().ilvl_minutes);}

// ---------------- State ----------------
function equipment_reset_run() {
    global.equipment={};var s=equipment_slots();for(var i=0;i<array_length(s);i++)global.equipment[$ s[i]]=undefined;
    global.equipment_backpack=[];global.equipment_drops=[];global.equipment_hover=-1;global.equipment_found=0;
    global.equipment_seed=max(1,(variable_global_exists("choice_rng") ? global.choice_rng : 12345) mod 2147483646);
    if(!variable_global_exists("toasts"))global.toasts=[];
    equipment_rebuild_cache();
}
function equipment_rebuild_cache() {
    var cache={},s=equipment_slots();
    for(var i=0;i<array_length(s);i++) {
        var it=global.equipment[$ s[i]];if(!is_struct(it))continue;
        var keys=variable_struct_get_names(it.stats);
        for(var k=0;k<array_length(keys);k++)cache[$ keys[k]]=(variable_struct_exists(cache,keys[k]) ? cache[$ keys[k]] : 0)+it.stats[$ keys[k]];
    }
    global.equipment_cache=cache;
}
function equipment_stat(_key) {
    if(!variable_global_exists("equipment_cache"))return 0;
    return variable_struct_exists(global.equipment_cache,_key) ? global.equipment_cache[$ _key] : 0;
}
function equipment_score(_item) {
    if(!is_struct(_item))return 0;
    var info=equipment_stat_info(),keys=variable_struct_get_names(_item.stats),total=0;
    for(var k=0;k<array_length(keys);k++)total+=_item.stats[$ keys[k]]/info[$ keys[k]].base;
    return total;
}
/// Put an item into its slot. The previous item (if any) goes to the backpack. Returns false if nothing changed.
function equipment_equip(_item) {
    if(!is_struct(_item))return false;
    var old=global.equipment[$ _item.slot];
    global.equipment[$ _item.slot]=_item;
    if(is_struct(old))array_push(global.equipment_backpack,old);
    equipment_rebuild_cache();
    if(instance_exists(ObjectPlayer))apply_passives(ObjectPlayer);
    return true;
}
/// Pickup rule: empty slot -> equip, otherwise backpack. Returns false only if the backpack is full.
function equipment_receive(_item) {
    var name_col=equipment_rarity_color(_item.rarity);
    if(!is_struct(global.equipment[$ _item.slot])){equipment_equip(_item);feedback_toast_add("Angelegt: "+_item.name,name_col);}
    else if(array_length(global.equipment_backpack)<equipment_config().backpack_size){array_push(global.equipment_backpack,_item);feedback_toast_add("Gefunden: "+_item.name+" (Rucksack, [T])",name_col);}
    else return false;
    global.equipment_found++;fg_sfx("chest_open");
    return true;
}
function equipment_drop(_x,_y,_item) {
    var cfg=equipment_config();
    if(array_length(global.equipment_drops)>=cfg.max_world_drops)array_delete(global.equipment_drops,0,1);
    array_push(global.equipment_drops,{x:clamp(_x,24,room_width-24),y:clamp(_y,24,room_height-24),item:_item,age:0,blocked:false});
}
function equipment_enemy_drop(_x,_y) {
    if(!variable_global_exists("equipment_drops") || global.game_over)return;
    if(random(1)>=equipment_config().enemy_drop_chance)return;
    var roll=equipment_rng(),rarity=roll<.75 ? 0 : (roll<.95 ? 1 : 2);
    equipment_drop(_x,_y,equipment_generate(equipment_random_slot(),rarity,equipment_item_level()));
}
function equipment_boss_drop(_b) {
    if(!variable_global_exists("equipment_drops"))return;
    var main=is_struct(_b.boss_data) && _b.boss_data.main,ilvl=equipment_item_level();
    if(main) {
        equipment_drop(_b.x-36,_b.y+18,equipment_generate(equipment_random_slot(),equipment_rng()<.3 ? 3 : 2,ilvl+1));
        equipment_drop(_b.x+6,_b.y+40,equipment_generate(equipment_random_slot(),1,ilvl));
    } else equipment_drop(_b.x-30,_b.y+20,equipment_generate(equipment_random_slot(),equipment_rng()<.3 ? 2 : 1,ilvl));
}
function equipment_step(_dt) {
    if(!variable_global_exists("equipment_drops") || !instance_exists(ObjectPlayer))return;
    var pl=ObjectPlayer,r=equipment_config().pickup_radius;
    for(var i=array_length(global.equipment_drops)-1;i>=0;i--) {
        var d=global.equipment_drops[i];d.age+=_dt;
        var near=point_distance(pl.x,pl.y,d.x,d.y)<=r;
        if(near && !d.blocked) {
            if(equipment_receive(d.item)){light_pulse(d.x,d.y-12,170,equipment_rarity_color(d.item.rarity),1,.35);array_delete(global.equipment_drops,i,1);continue;}
            d.blocked=true;feedback_toast_add("Rucksack voll - im Charaktermenue [T] Platz schaffen",make_color_rgb(255,150,120));
        }
        if(!near)d.blocked=false;
    }
}
function equipment_world_draw() {
    if(!variable_global_exists("equipment_drops"))return;
    var spr=asset_get_index("spr_eq_icons"),t=current_time/1000;
    for(var i=0;i<array_length(global.equipment_drops);i++) {
        var d=global.equipment_drops[i],col=equipment_rarity_color(d.item.rarity),bob=sin(t*3+i)*3,fade=clamp(d.age*3,0,1);
        gpu_set_blendmode(bm_add);
        draw_set_color(col);
        for(var k=0;k<4;k++){draw_set_alpha((.10-k*.02)*fade);draw_rectangle(d.x-3+k*-1,d.y-14-(70-k*12),d.x+3+k,d.y-14,false);}
        draw_set_alpha(.16*fade);draw_ellipse(d.x-20,d.y-6,d.x+20,d.y+6,false);
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(.5*fade);draw_set_color(c_black);draw_ellipse(d.x-11,d.y-3,d.x+11,d.y+3,false);draw_set_alpha(fade);
        if(sprite_exists(spr))draw_sprite_ext(spr,equipment_icon_frame(d.item.slot),d.x,d.y-16+bob,.75,.75,0,c_white,fade);
        else{draw_set_color(col);draw_circle(d.x,d.y-16+bob,7,false);}
    }
    draw_set_alpha(1);draw_set_color(c_white);
}
function equipment_lights(_rect) {
    if(!variable_global_exists("equipment_drops"))return;
    for(var i=0;i<array_length(global.equipment_drops);i++){var d=global.equipment_drops[i];atmosphere_source(d.x,d.y-14,95+d.item.rarity*18,equipment_rarity_color(d.item.rarity),.85,_rect);}
}
function equipment_minimap_draw(_x,_y,_size) {
    if(!variable_global_exists("equipment_drops"))return;
    for(var i=0;i<array_length(global.equipment_drops);i++){var d=global.equipment_drops[i];draw_set_color(equipment_rarity_color(d.item.rarity));draw_rectangle(_x+d.x/room_width*_size-1,_y+d.y/room_height*_size-1,_x+d.x/room_width*_size+1,_y+d.y/room_height*_size+1,false);}
}

// ---------------- Text helpers ----------------
function equipment_stat_text(_key,_value) {
    var all_info=equipment_stat_info(),s=all_info[$ _key],v=s.pct ? _value*100 : _value;
    var num=string_replace_all(string_format(v,0,s.dec)," ","");
    var unit=s.pct ? "%" : (variable_struct_exists(s,"unit") ? s.unit : "");
    return (variable_struct_exists(s,"minus") ? "-" : "+")+num+unit+" "+s.label;
}

// ---------------- Toast notifications (GUI, real time so they also fade in menus) ----------------
function feedback_toast_add(_text,_color) {
    if(!variable_global_exists("toasts"))global.toasts=[];
    if(array_length(global.toasts)>=5)array_delete(global.toasts,0,1);
    array_push(global.toasts,{text:_text,color:_color,t0:current_time});
}
function feedback_toast_draw() {
    if(!variable_global_exists("toasts"))return;
    var w=display_get_gui_width(),y0=58;
    draw_set_halign(fa_center);draw_set_valign(fa_top);
    for(var i=array_length(global.toasts)-1;i>=0;i--) {
        var e=global.toasts[i],age=(current_time-e.t0)/1000;
        if(age>3.6){array_delete(global.toasts,i,1);continue;}
    }
    for(var i=0;i<array_length(global.toasts);i++) {
        var e=global.toasts[i],age=(current_time-e.t0)/1000,a=clamp(min(age*6,(3.6-age)*2),0,1),tw=string_width(e.text)+24,yy=y0+i*26;
        draw_set_alpha(.72*a);draw_set_color(make_color_rgb(9,13,21));draw_rectangle(w/2-tw/2,yy,w/2+tw/2,yy+22,false);
        draw_set_alpha(a);draw_set_color(e.color);draw_rectangle(w/2-tw/2,yy,w/2+tw/2,yy+22,true);draw_text(w/2,yy+3,e.text);
    }
    draw_set_alpha(1);draw_set_color(c_white);draw_set_halign(fa_left);
}

// ---------------- Character screen panel ----------------
function equipment_panel_geometry(_L) {
    var cell=min(58,(_L.eq_w-36)/2*.42),x0=_L.eq_x+14,y0=_L.eq_y+44;
    var slot_w=(_L.eq_w-40)/2,bag_cell=min(46,(_L.eq_w-28-3*6)/4),bag_y=y0+3*(cell+12)+30;
    return {cell:cell,x0:x0,y0:y0,slot_w:slot_w,bag_cell:bag_cell,bag_y:bag_y,sum_y:bag_y+2*(bag_cell+6)+26};
}
function equipment_slot_rect(_G,_i) {var col=_i mod 2,row=_i div 2;return {x:_G.x0+col*(_G.slot_w+12),y:_G.y0+row*(_G.cell+12),w:_G.slot_w,h:_G.cell};}
function equipment_bag_rect(_G,_i) {var col=_i mod 4,row=_i div 4;return {x:_G.x0+col*(_G.bag_cell+6),y:_G.bag_y+row*(_G.bag_cell+6),w:_G.bag_cell,h:_G.bag_cell};}
function equipment_menu_step(_L,_mx,_my) {
    var G=equipment_panel_geometry(_L),s=equipment_slots();global.equipment_hover=-1;
    for(var i=0;i<6;i++){var r=equipment_slot_rect(G,i);if(point_in_rectangle(_mx,_my,r.x,r.y,r.x+r.w,r.y+r.h))global.equipment_hover=i;}
    for(var i=0;i<equipment_config().backpack_size;i++){var r=equipment_bag_rect(G,i);if(point_in_rectangle(_mx,_my,r.x,r.y,r.x+r.w,r.y+r.h))global.equipment_hover=100+i;}
    if(!global.talent_mouse_armed || global.equipment_hover<0)return;
    var h=global.equipment_hover;
    if(mouse_check_button_pressed(mb_left)) {
        global.talent_mouse_armed=false;
        if(h>=100 && h-100<array_length(global.equipment_backpack)){var it=global.equipment_backpack[h-100];array_delete(global.equipment_backpack,h-100,1);equipment_equip(it);fg_sfx("spell_select");}
        else if(h<6 && is_struct(global.equipment[$ s[h]]) && array_length(global.equipment_backpack)<equipment_config().backpack_size){array_push(global.equipment_backpack,global.equipment[$ s[h]]);global.equipment[$ s[h]]=undefined;equipment_rebuild_cache();if(instance_exists(ObjectPlayer))apply_passives(ObjectPlayer);fg_sfx("ui_click");}
    } else if(mouse_check_button_pressed(mb_right)) {
        global.talent_mouse_armed=false;
        if(h>=100 && h-100<array_length(global.equipment_backpack)){array_delete(global.equipment_backpack,h-100,1);fg_sfx("ui_back");}
    }
}
function equipment_icon_draw(_item,_x,_y,_size,_alpha=1) {
    var spr=asset_get_index("spr_eq_icons");
    if(sprite_exists(spr))draw_sprite_stretched_ext(spr,equipment_icon_frame(_item.slot),_x,_y,_size,_size,c_white,_alpha);
    else{draw_set_color(equipment_rarity_color(_item.rarity));draw_circle(_x+_size/2,_y+_size/2,_size*.3,false);}
}
function equipment_cell_draw(_r,_item,_hover,_empty_label) {
    var col=is_struct(_item) ? equipment_rarity_color(_item.rarity) : make_color_rgb(58,68,82);
    draw_set_color(make_color_rgb(14,19,28));draw_rectangle(_r.x,_r.y,_r.x+_r.w,_r.y+_r.h,false);
    if(is_struct(_item)){gpu_set_blendmode(bm_add);draw_set_alpha(.10+(_item.rarity*.03));draw_set_color(col);draw_rectangle(_r.x+2,_r.y+2,_r.x+_r.w-2,_r.y+_r.h-2,false);gpu_set_blendmode(bm_normal);draw_set_alpha(1);}
    draw_set_color(_hover ? c_white : col);draw_rectangle(_r.x,_r.y,_r.x+_r.w,_r.y+_r.h,true);
    draw_set_color(make_color_rgb(36,44,56));draw_rectangle(_r.x+2,_r.y+2,_r.x+_r.w-2,_r.y+_r.h-2,true);
    var isz=min(_r.h-8,40);
    if(is_struct(_item))equipment_icon_draw(_item,_r.x+4,_r.y+(_r.h-isz)/2,isz);
    if(_empty_label!="") {
        draw_set_valign(fa_middle);
        if(is_struct(_item)){draw_set_color(col);draw_text_ext_transformed(_r.x+isz+10,_r.y+_r.h/2,_item.name,16,(_r.w-isz-14)/.72,.72,.72,0);}
        else{draw_set_color(make_color_rgb(96,108,122));draw_text_transformed(_r.x+10,_r.y+_r.h/2,_empty_label+": leer",.78,.78,0);}
        draw_set_valign(fa_top);
    }
}
function equipment_panel_draw(_L) {
    var G=equipment_panel_geometry(_L),s=equipment_slots();
    talent_frame_panel(_L.eq_x,_L.eq_y,_L.eq_w,_L.eq_h,make_color_rgb(150,176,198));
    draw_set_halign(fa_center);draw_set_color(make_color_rgb(190,210,226));draw_text(_L.eq_x+_L.eq_w/2,_L.eq_y+12,"AUSRUESTUNG");draw_set_halign(fa_left);
    for(var i=0;i<6;i++)equipment_cell_draw(equipment_slot_rect(G,i),global.equipment[$ s[i]],global.equipment_hover==i,equipment_slot_label(s[i]));
    draw_set_color(make_color_rgb(150,166,182));draw_text(G.x0,G.bag_y-22,"RUCKSACK  "+string(array_length(global.equipment_backpack))+" / "+string(equipment_config().backpack_size));
    for(var i=0;i<equipment_config().backpack_size;i++)equipment_cell_draw(equipment_bag_rect(G,i),i<array_length(global.equipment_backpack) ? global.equipment_backpack[i] : undefined,global.equipment_hover==100+i,"");
    // totals
    var keys=variable_struct_get_names(global.equipment_cache),yy=G.sum_y;
    draw_set_color(make_color_rgb(150,166,182));draw_text(G.x0,yy,"BONI DER AUSRUESTUNG");yy+=22;
    if(array_length(keys)==0){draw_set_color(make_color_rgb(96,108,122));draw_text_ext_transformed(G.x0,yy,"Keine Ausruestung angelegt. Bosse lassen garantiert Gegenstaende fallen, normale Gegner selten.",17,(_L.eq_w-30)/.78,.78,.78,0);}
    else for(var k=0;k<array_length(keys) && yy<_L.eq_y+_L.eq_h-18;k++){draw_set_color(make_color_rgb(198,214,226));draw_text_transformed(G.x0,yy,equipment_stat_text(keys[k],global.equipment_cache[$ keys[k]]),.78,.78,0);yy+=17;}
}
function equipment_tooltip_draw(_L) {
    var h=variable_global_exists("equipment_hover") ? global.equipment_hover : -1;if(h<0)return;
    var s=equipment_slots(),item=undefined,bag=h>=100;
    if(bag){if(h-100<array_length(global.equipment_backpack))item=global.equipment_backpack[h-100];}
    else item=global.equipment[$ s[h]];
    if(!is_struct(item))return;
    var col=equipment_rarity_color(item.rarity),body="",info=equipment_stat_info();
    for(var i=0;i<array_length(item.order);i++)body+=(i>0 ? "\n" : "")+equipment_stat_text(item.order[i],item.stats[$ item.order[i]]);
    if(bag) {
        var cur=global.equipment[$ item.slot];
        if(is_struct(cur)) {
            body+="\n\nGEGENUEBER ANGELEGT ("+cur.name+")";
            var keys=[];for(var i=0;i<array_length(item.order);i++)array_push(keys,item.order[i]);
            for(var i=0;i<array_length(cur.order);i++)if(!array_contains(keys,cur.order[i]))array_push(keys,cur.order[i]);
            for(var i=0;i<array_length(keys);i++) {
                var k=keys[i],a=variable_struct_exists(item.stats,k) ? item.stats[$ k] : 0,b=variable_struct_exists(cur.stats,k) ? cur.stats[$ k] : 0;
                if(abs(a-b)<.0001)continue;
                body+="\n"+(a>b ? "[+] " : "[-] ")+equipment_stat_text(k,a-b);
            }
        } else body+="\n\nPlatz ist frei.";
        body+="\n\nLinksklick: anlegen | Rechtsklick: wegwerfen";
    } else body+="\n\nLinksklick: in den Rucksack legen";
    var w=min(320,_L.w*.3),tw=w-24,hh=66+string_height_ext(body,18,tw),xx=_L.eq_x+_L.eq_w+8,yy=clamp(device_mouse_y_to_gui(0)-20,8,_L.h-hh-8);
    spell_ui_panel(xx,yy,w,hh,false);draw_set_color(col);draw_rectangle(xx,yy,xx+w,yy+hh,true);
    draw_text(xx+12,yy+10,item.name);draw_set_color(make_color_rgb(170,182,196));
    draw_text_transformed(xx+12,yy+32,equipment_rarity_name(item.rarity)+" | "+equipment_slot_label(item.slot)+" | Gegenstandsstufe "+string(item.ilvl),.8,.8,0);
    draw_set_color(c_white);draw_text_ext(xx+12,yy+56,body,18,tw);
}
/// Compact HUD strip above the spell slots: equipped items with rarity frames, empty slots dimmed.
function equipment_hud_draw(_x,_y) {
    if(!variable_global_exists("equipment"))return;
    var s=equipment_slots(),cell=22,spr=asset_get_index("spr_eq_icons");
    for(var i=0;i<6;i++) {
        var it=global.equipment[$ s[i]],xx=_x+i*(cell+3);
        draw_set_alpha(.7);draw_set_color(make_color_rgb(12,17,25));draw_rectangle(xx,_y,xx+cell,_y+cell,false);draw_set_alpha(1);
        draw_set_color(is_struct(it) ? equipment_rarity_color(it.rarity) : make_color_rgb(52,62,76));draw_rectangle(xx,_y,xx+cell,_y+cell,true);
        if(is_struct(it) && sprite_exists(spr))draw_sprite_stretched(spr,equipment_icon_frame(it.slot),xx+1,_y+1,cell-2,cell-2);
        else if(sprite_exists(spr))draw_sprite_stretched_ext(spr,equipment_icon_frame(s[i]),xx+3,_y+3,cell-6,cell-6,c_black,.45);
    }
    if(array_length(global.equipment_backpack)>0){draw_set_color(make_color_rgb(200,214,226));draw_text_transformed(_x+6*(cell+3)+4,_y+4,"+"+string(array_length(global.equipment_backpack))+" [T]",.75,.75,0);}
    draw_set_color(c_white);
}
/// Visible gear feedback on the character (no armour sprite variants exist): a ground ring in the colour of the
/// best equipped rarity, thicker with more pieces, and a short sheen every few seconds. Drawn under the player.
function equipment_player_aura_draw(_pl) {
    if(!variable_global_exists("equipment"))return;
    var s=equipment_slots(),best=-1,pieces=0;
    for(var i=0;i<6;i++){var it=global.equipment[$ s[i]];if(is_struct(it)){pieces++;best=max(best,it.rarity);}}
    if(pieces==0)return;
    var col=equipment_rarity_color(best),t=current_time/1000,pulse=.5+.5*sin(t*2.2),lift=_pl.jump_height;
    gpu_set_blendmode(bm_add);draw_set_color(col);
    for(var k=0;k<min(3,1+pieces div 2);k++){draw_set_alpha((.10+.05*pulse)*(1-k*.25)*(lift>0 ? .5 : 1));draw_ellipse(_pl.x-22-k*3,_pl.y-4-k,_pl.x+22+k*3,_pl.y+8+k,true);}
    var sheen=frac(t/3.2);
    if(sheen<.18){var a=sheen/.18*360;draw_set_alpha(.35*(1-sheen/.18));draw_circle(_pl.x+lengthdir_x(22,a),_pl.y+2+lengthdir_y(6,a),2,false);}
    gpu_set_blendmode(bm_normal);draw_set_alpha(1);draw_set_color(c_white);
}
