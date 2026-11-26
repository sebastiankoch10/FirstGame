/// Inventory and equipment interaction (character screen [T]): atomic transactions, drag and drop, right-click
/// unequip, data-driven tooltips and the Shift comparison. All changes go through equipment_tx_* so that the equipped
/// set, backpack, stats (equipment_rebuild_cache + apply_passives) and the visible layers always come from one state.
/// While dragging nothing is changed; only a valid drop runs a transaction (cancel = original state, no loss/dup).

// ---------------- Rules ----------------
/// Slots an item may occupy. Today every item fits exactly its own slot; rings/off-hands would list several here.
function equipment_compatible_slots(_item) {return is_struct(_item) ? [_item.slot] : [];}
/// Requirements of an item (level / class fields are optional and future-proof; no current item carries them).
function equipment_requirements(_item) {
    var r=[];
    if(variable_struct_exists(_item,"req_level"))array_push(r,{text:"Stufe "+string(_item.req_level),ok:(variable_global_exists("current_level") ? global.current_level : 1)>=_item.req_level});
    if(variable_struct_exists(_item,"req_class"))array_push(r,{text:review_class_name(_item.req_class),ok:global.selected_character==_item.req_class});
    return r;
}
function equipment_requirements_met(_item) {var r=equipment_requirements(_item);for(var i=0;i<array_length(r);i++)if(!r[i].ok)return false;return true;}
function equipment_bag_full() {return array_length(global.equipment_backpack)>=equipment_config().backpack_size;}
/// Total item count (equipped + backpack): every transaction must keep it (checked by the feature harness).
function equipment_item_count() {var n=array_length(global.equipment_backpack),s=equipment_slots();for(var i=0;i<array_length(s);i++)if(is_struct(global.equipment[$ s[i]]))n++;return n;}
function equipment_after_change() {equipment_rebuild_cache();if(instance_exists(ObjectPlayer))apply_passives(ObjectPlayer);}
function equipment_tx_fail(_msg) {feedback_toast_add(_msg,make_color_rgb(232,128,112));fg_sfx("ui_back");return false;}

// ---------------- Transactions ----------------
/// Backpack item _i into slot _slot; a previously equipped item takes the freed backpack position (swap).
function equipment_tx_equip_from_bag(_i,_slot) {
    if(_i<0 || _i>=array_length(global.equipment_backpack))return false;
    var it=global.equipment_backpack[_i];
    if(!array_contains(equipment_compatible_slots(it),_slot))return equipment_tx_fail("Passt nicht in diesen Platz ("+equipment_slot_label(it.slot)+")");
    if(!equipment_requirements_met(it))return equipment_tx_fail("Anforderungen nicht erfuellt");
    var old=global.equipment[$ _slot];
    global.equipment[$ _slot]=it;
    if(is_struct(old))global.equipment_backpack[_i]=old;else array_delete(global.equipment_backpack,_i,1);
    equipment_after_change();fg_sfx("spell_select");return true;
}
/// Equipped item of _slot into the backpack (at _at if given). Refused when the backpack is full.
function equipment_tx_unequip(_slot,_at=-1) {
    var it=global.equipment[$ _slot];if(!is_struct(it))return false;
    if(equipment_bag_full())return equipment_tx_fail("Rucksack voll - nichts abgelegt");
    global.equipment[$ _slot]=undefined;
    if(_at>=0 && _at<array_length(global.equipment_backpack))array_insert(global.equipment_backpack,_at,it);else array_push(global.equipment_backpack,it);
    equipment_after_change();fg_sfx("ui_back");return true;
}
/// Equipped item dropped on backpack cell _j: swap if the bag item fits the slot, otherwise insert there.
function equipment_tx_slot_to_bag(_slot,_j) {
    if(_j<array_length(global.equipment_backpack)) {
        var other_item=global.equipment_backpack[_j];
        if(array_contains(equipment_compatible_slots(other_item),_slot) && equipment_requirements_met(other_item))return equipment_tx_equip_from_bag(_j,_slot);
    }
    return equipment_tx_unequip(_slot,_j);
}
/// Move inside the backpack: swap with an occupied cell, or move to the end when dropped on an empty cell.
function equipment_tx_bag_move(_i,_j) {
    var n=array_length(global.equipment_backpack);if(_i<0 || _i>=n || _i==_j)return false;
    if(_j<n){var t=global.equipment_backpack[_i];global.equipment_backpack[_i]=global.equipment_backpack[_j];global.equipment_backpack[_j]=t;}
    else{var it=global.equipment_backpack[_i];array_delete(global.equipment_backpack,_i,1);array_push(global.equipment_backpack,it);}
    fg_sfx("ui_click");return true;
}
/// Slot to slot (only meaningful for multi-slot items; refused otherwise).
function equipment_tx_slot_to_slot(_a,_b) {
    if(_a==_b)return false;var it=global.equipment[$ _a],ot=global.equipment[$ _b];
    if(!is_struct(it) || !array_contains(equipment_compatible_slots(it),_b) || (is_struct(ot) && !array_contains(equipment_compatible_slots(ot),_a)))return equipment_tx_fail("Passt nicht in diesen Platz");
    global.equipment[$ _b]=it;global.equipment[$ _a]=ot;equipment_after_change();return true;
}

// ---------------- Input (called from equipment_menu_step) ----------------
function equipment_drag_cancel() {global.eq_drag=undefined;global.eq_left_prev=false;}
function equipment_hover_item(_h) {
    if(_h<0)return undefined;
    if(_h>=100)return _h-100<array_length(global.equipment_backpack) ? global.equipment_backpack[_h-100] : undefined;
    return global.equipment[$ equipment_slots()[_h]];
}
/// Drop target validity for highlighting: slot index (0-5) or backpack cell (100+).
function equipment_drop_valid(_d,_h) {
    if(_h<0)return false;
    if(_h<100)return array_contains(equipment_compatible_slots(_d.item),equipment_slots()[_h]) && equipment_requirements_met(_d.item);
    return _d.src=="bag" || !equipment_bag_full() || (_h-100<array_length(global.equipment_backpack) && array_contains(equipment_compatible_slots(global.equipment_backpack[_h-100]),_d.slot));
}
function equipment_input(_mx,_my) {
    if(!variable_global_exists("eq_drag"))equipment_drag_cancel();
    var h=global.equipment_hover,s=equipment_slots(),down=mouse_check_button(mb_left),released=global.eq_left_prev && !down;global.eq_left_prev=down;
    var d=global.eq_drag;
    // press on an item: remember a pending drag (nothing changes yet)
    if(!is_struct(d) && global.talent_mouse_armed && mouse_check_button_pressed(mb_left) && is_struct(equipment_hover_item(h))) {
        global.talent_mouse_armed=false;
        global.eq_drag={src:h>=100 ? "bag" : "slot",index:h>=100 ? h-100 : h,slot:h>=100 ? "" : s[h],item:equipment_hover_item(h),x0:_mx,y0:_my,moved:false};
        if(h<100)global.eq_drag.slot=s[h];
        return;
    }
    if(is_struct(d)) {
        if(mouse_check_button_pressed(mb_right) || keyboard_check_pressed(vk_escape)){equipment_drag_cancel();fg_sfx("ui_back");return;}
        if(point_distance(_mx,_my,d.x0,d.y0)>5)d.moved=true;
        if(!released && down)return;
        var before=equipment_item_count();
        global.eq_drag=undefined;
        if(!d.moved) {
            // plain click keeps the old behaviour: backpack -> equip, equipped -> backpack
            if(d.src=="bag")equipment_tx_equip_from_bag(d.index,d.item.slot);else equipment_tx_unequip(d.slot);
        } else if(h>=0) {
            if(d.src=="bag" && h<100)equipment_tx_equip_from_bag(d.index,s[h]);
            else if(d.src=="bag")equipment_tx_bag_move(d.index,h-100);
            else if(h<100)equipment_tx_slot_to_slot(d.slot,s[h]);
            else equipment_tx_slot_to_bag(d.slot,h-100);
        } // dropped outside every cell: cancelled, nothing changed
        if(equipment_item_count()!=before)show_debug_message("EQUIPMENT INVARIANT BROKEN "+string(before)+" -> "+string(equipment_item_count()));
        return;
    }
    if(!global.talent_mouse_armed || h<0)return;
    if(mouse_check_button_pressed(mb_right)) {
        global.talent_mouse_armed=false;
        if(h<6)equipment_tx_unequip(s[h]);                    // right click on an equipped item: unequip into a free backpack cell
        else if(h-100<array_length(global.equipment_backpack)){array_delete(global.equipment_backpack,h-100,1);fg_sfx("ui_back");} // existing: discard from the backpack
    }
}

// ---------------- Drawing ----------------
function equipment_drag_draw(_L) {
    if(!variable_global_exists("eq_drag") || !is_struct(global.eq_drag) || !global.eq_drag.moved)return;
    var d=global.eq_drag,G=equipment_panel_geometry(_L),mx=device_mouse_x_to_gui(0),my=device_mouse_y_to_gui(0),s=equipment_slots(),t=current_time/1000;
    // subtle highlight of valid targets
    for(var i=0;i<6;i++)if(equipment_drop_valid(d,i)){var r=equipment_slot_rect(G,i);draw_set_alpha(.22+.08*sin(t*6));draw_set_color(make_color_rgb(126,224,170));draw_rectangle(r.x+1,r.y+1,r.x+r.w-1,r.y+r.h-1,false);draw_set_alpha(.8);draw_rectangle(r.x,r.y,r.x+r.w,r.y+r.h,true);}
    if(d.src=="slot" && !equipment_bag_full()){var c=equipment_bag_rect(G,array_length(global.equipment_backpack));draw_set_alpha(.25);draw_set_color(make_color_rgb(126,224,170));draw_rectangle(c.x,c.y,c.x+c.w,c.y+c.h,true);}
    // source cell dimmed, item follows the mouse
    var src=d.src=="bag" ? equipment_bag_rect(G,d.index) : equipment_slot_rect(G,d.index);
    draw_set_alpha(.55);draw_set_color(make_color_rgb(8,12,18));draw_rectangle(src.x,src.y,src.x+src.w,src.y+src.h,false);
    draw_set_alpha(1);var sz=44;
    draw_set_color(equipment_rarity_color(d.item.rarity));draw_rectangle(mx-sz*.5-2,my-sz*.5-2,mx+sz*.5+2,my+sz*.5+2,true);
    equipment_icon_draw(d.item,mx-sz*.5,my-sz*.5,sz,.92);
    draw_set_alpha(1);
}
/// Tooltip content from the real item data. _cmp (optional): item to compare against -> per-stat difference markers.
function equipment_tooltip_lines(_item,_cmp=undefined,_title="") {
    var L=[],grey=make_color_rgb(170,182,196),good=make_color_rgb(126,224,140),bad=make_color_rgb(232,128,112);
    if(_title!="")array_push(L,{t:_title,c:make_color_rgb(238,207,133),s:.72});
    array_push(L,{t:_item.name,c:equipment_rarity_color(_item.rarity),s:1});
    array_push(L,{t:equipment_rarity_name(_item.rarity)+"  |  "+equipment_slot_label(_item.slot)+"  |  Stufe "+string(_item.ilvl),c:grey,s:.78});
    var vis=eqv_item_tier(_item),tiers=["Grundausfuehrung","Verbessert","Meisterwerk","Legendaer"];
    array_push(L,{t:"Aussehen: "+tiers[clamp(vis,0,3)]+(_item.slot=="trinket" ? " (am Koerper nicht sichtbar)" : ""),c:grey,s:.72});
    var req=equipment_requirements(_item),rt="Anforderungen: keine";
    if(array_length(req)>0){rt="Anforderungen: ";for(var i=0;i<array_length(req);i++)rt+=(i>0 ? ", " : "")+req[i].text+(req[i].ok ? "" : " (nicht erfuellt)");}
    array_push(L,{t:rt,c:equipment_requirements_met(_item) ? grey : bad,s:.72});
    array_push(L,{t:"",c:grey,s:.5});
    var keys=[];for(var i=0;i<array_length(_item.order);i++)array_push(keys,_item.order[i]);
    if(is_struct(_cmp))for(var i=0;i<array_length(_cmp.order);i++)if(!array_contains(keys,_cmp.order[i]))array_push(keys,_cmp.order[i]);
    for(var i=0;i<array_length(keys);i++) {
        var k=keys[i],a=variable_struct_exists(_item.stats,k) ? _item.stats[$ k] : undefined;
        if(is_undefined(a)) {   // property only the compared item has: it would be lost
            if(is_struct(_cmp))array_push(L,{t:"entfaellt: "+equipment_stat_text(k,_cmp.stats[$ k]),c:bad,s:.8});
            continue;
        }
        var line=equipment_stat_text(k,a),col=c_white;
        if(is_struct(_cmp)) {
            var b=variable_struct_exists(_cmp.stats,k) ? _cmp.stats[$ k] : 0;
            if(!variable_struct_exists(_cmp.stats,k)){line+="   (neu)";col=good;}
            else if(abs(a-b)>.0001){line+="   ("+equipment_stat_delta(k,a-b)+")";col=a>b ? good : bad;}
        }
        array_push(L,{t:line,c:col,s:.84});
    }
    if(array_length(keys)==0)array_push(L,{t:"Keine Werte",c:grey,s:.8});
    return L;
}
/// Difference of one stat as "+1.2 %" / "-3"; for every stat a larger value is better (dodge_cd is a reduction).
function equipment_stat_delta(_key,_delta) {
    var s=equipment_stat_info()[$ _key],v=abs(s.pct ? _delta*100 : _delta);
    return (_delta>0 ? "+" : "-")+string_replace_all(string_format(v,0,s.dec)," ","")+(s.pct ? "%" : (variable_struct_exists(s,"unit") ? s.unit : ""));
}
function equipment_tooltip_size(_lines,_w) {var h=16;for(var i=0;i<array_length(_lines);i++)h+=max(10,string_height_ext(_lines[i].t,18,(_w-24)/_lines[i].s)*_lines[i].s)+3;return h;}
function equipment_tooltip_box(_lines,_x,_y,_w,_h,_col) {
    spell_ui_panel(_x,_y,_w,_h,false);draw_set_color(_col);draw_rectangle(_x,_y,_x+_w,_y+_h,true);
    var yy=_y+8;draw_set_halign(fa_left);draw_set_valign(fa_top);
    for(var i=0;i<array_length(_lines);i++){var l=_lines[i];draw_set_color(l.c);draw_text_ext_transformed(_x+12,yy,l.t,18,(_w-24)/l.s,l.s,l.s,0);yy+=max(10,string_height_ext(l.t,18,(_w-24)/l.s)*l.s)+3;}
}
function equipment_tooltips_draw(_L) {
    if(variable_global_exists("eq_drag") && is_struct(global.eq_drag) && global.eq_drag.moved)return;
    var h=variable_global_exists("equipment_hover") ? global.equipment_hover : -1,item=equipment_hover_item(h);if(!is_struct(item))return;
    var shift=keyboard_check(vk_shift),cur=undefined;
    if(h>=100 && shift){var cs=equipment_compatible_slots(item);for(var i=0;i<array_length(cs) && !is_struct(cur);i++)cur=global.equipment[$ cs[i]];}
    var w=min(300,_L.w*.24),main_lines=equipment_tooltip_lines(item,cur,h>=100 ? "IM RUCKSACK" : "ANGELEGT");
    if(h>=100)array_push(main_lines,{t:shift ? "" : "Shift: mit angelegtem Gegenstand vergleichen",c:make_color_rgb(140,156,170),s:.7});
    array_push(main_lines,{t:h>=100 ? "Ziehen oder Klick: anlegen  |  Rechtsklick: wegwerfen" : "Ziehen oder Klick: in den Rucksack  |  Rechtsklick: ablegen",c:make_color_rgb(140,156,170),s:.7});
    var hm=equipment_tooltip_size(main_lines,w),xx=_L.eq_x+_L.eq_w+8,yy=clamp(device_mouse_y_to_gui(0)-20,8,_L.h-hm-8);
    if(is_struct(cur)) {
        var cl=equipment_tooltip_lines(cur,undefined,"AUSGERUESTET (zum Vergleich)"),hc=equipment_tooltip_size(cl,w);
        // side by side, never overlapping and always on screen
        var x2=xx+w+8;if(x2+w>_L.w-8)x2=max(8,xx-w-8);
        var y2=clamp(yy,8,_L.h-hc-8);
        equipment_tooltip_box(cl,x2,y2,w,hc,equipment_rarity_color(cur.rarity));
    } else if(h>=100 && shift) {
        main_lines[array_length(main_lines)-2].t="Kein Gegenstand in diesem Platz angelegt";
    }
    equipment_tooltip_box(main_lines,xx,yy,w,hm,equipment_rarity_color(item.rarity));
}
