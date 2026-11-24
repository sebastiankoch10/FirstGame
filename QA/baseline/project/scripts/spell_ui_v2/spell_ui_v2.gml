/// List tiles and the detail component are deliberately separate; no statistics inside the list.
function spell_values_text(_sid,_level) {
    var d=GetSpellData(_sid),v=spell_values(_sid,_level),lv=v.level;
    if(d.type==2) {
        switch(_sid) {
            case 201:return "Schadensreduktion: "+string(v.damage)+" %\nOrbit-Trefferschaden: "+string(v.orbit_damage);
            case 206:return "Zauber-Zusatzgeschosse: "+string(v.damage)+"\nProjektilschaden: +"+string(v.projectile_bonus);
            case 202:return "Additive Power: +"+string(v.damage);
            case 203:return "Bewegungstempo: +"+string_format(v.damage,0,2);
            case 205:return "Zusaetzliches Lebensmaximum: "+string(v.damage);
            case 214:return "Schadensabzug pro Treffer: "+string_format(v.damage,0,1);
            case 215:return "Regeneration: "+string_format(v.damage,0,2)+" Leben / Sekunde";
            case 216:return "Normaler Sammelradius: "+string(GetSpellData(SPELL.PICKUP).base_radius+v.damage)+" Pixel";
            default:return "Bonus: "+string_format(d.bonus_per_level*lv*100,0,1)+" %"+(_sid==212 ? "\nWeitere Kettenspruenge: "+string((lv>=5 ? 1 : 0)+(lv>=9 ? 1 : 0)) : "");
        }
    }
    var text=(_sid==106 ? "Heilung" : (array_contains([107,109,111,114,115],_sid) ? "Schaden pro Kontakt / Puls" : "Schaden pro Treffer"))+": "+string(v.damage);
    text+="\nAbklingzeit: "+string_format(v.cooldown/room_speed,0,2)+" Sekunden";
    if(_sid==103)text+="\nKettenziele: "+string(v.chain_targets)+" | Sprungweite: "+string(v.chain_range);
    else if(array_contains([101,102,105],_sid))text+="\nProjektile: "+string(v.count)+" | Reichweite: "+string(v.range);
    else if(array_contains([109,110,113,117],_sid))text+="\n"+(_sid==109 ? "Klingen" : (_sid==110 ? "Steinspitzen" : (_sid==113 ? "Einschlaege" : "Folgesplitter")))+": "+string(v.stages);
    if(v.radius>0 && _sid!=106)text+="\nEffektradius: "+string(round(v.radius))+" Pixel";
    if(array_contains([107,109,111,114,115],_sid))text+="\nWirkdauer: "+string_format(v.duration,0,1)+" Sekunden";
    return text;
}
function spell_upgrade_v2(_sid,_level) {
    var d=GetSpellData(_sid),a=spell_values(_sid,_level),b=spell_values(_sid,_level+1);
    if(d.type==2) {
        if(_sid==201)return "Orbit-Trefferschaden +"+string(b.orbit_damage-a.orbit_damage)+(b.damage>a.damage ? ", Reduktion +"+string(b.damage-a.damage)+" Prozentpunkte" : "");
        if(_sid==206)return "Projektilschaden +"+string(b.projectile_bonus-a.projectile_bonus)+(b.damage>a.damage ? ", ein Zusatzgeschoss" : "");
        return spell_values_text(_sid,_level+1);
    }
    var text=(_sid==106 ? "Heilung" : "Trefferschaden")+" +"+string(b.damage-a.damage);
    if(b.cooldown<a.cooldown)text+=" | Abklingzeit kuerzer";
    if(b.radius>a.radius)text+="\nRadius +"+string_format(b.radius-a.radius,0,1);
    if(b.chain_targets>a.chain_targets)text+=" | Ein weiterer Kettensprung";
    if(b.stages>a.stages && array_contains([109,110,113,117],_sid))text+=" | Weitere Klinge / Stufe";
    return text;
}
function spell_detail_draw(_sid,_level,_x,_y,_width,_bottom,_offer=false) {
    var d=GetSpellData(_sid);if(!is_struct(d))return;
    var color=spell_type_color(_sid),lv=clamp(_level,1,9),stats=run_stats_get(_sid);
    var body=d.desc+"\n\n"+spell_values_text(_sid,lv);
    var requirement=spell_requirement_text(d);if(requirement!="")body+="\n\n"+requirement;
    if(!_offer) {
        body+="\n\nAKTUELLER RUN\nGesamtschaden: "+string_format(stats.damage,0,1);
        body+="\nGesamtheilung: "+string_format(stats.healing,0,1);
        body+="\nTreffer: "+string(stats.hits)+"\nAusloesungen: "+string(stats.casts);
        if(stats.dot_damage>0)body+="\nDavon Statusschaden: "+string_format(stats.dot_damage,0,1);
        if(stats.blocked>0)body+="\nVerhinderter Schaden: "+string_format(stats.blocked,0,1);
        if(stats.extra_projectiles>0)body+="\nZusatzprojektile: "+string(stats.extra_projectiles);
    }
    if(lv<9)body+="\n\nNAECHSTE STUFE\n"+spell_upgrade_v2(_sid,lv);else body+="\n\nMaximal ausgebaut";
    var tw=_width-28,body_height=string_height_ext(body,18,tw),scale=min(1,(_bottom-_y-108)/max(1,body_height));
    var height=min(_bottom-_y,108+body_height*scale);
    spell_ui_panel(_x,_y,_width,height,false);draw_set_color(color);draw_rectangle(_x,_y,_x+_width,_y+height,true);
    spell_ui_icon(_sid,_x+12,_y+12,36);draw_set_color(color);
    draw_text_ext_transformed(_x+58,_y+10,d.name,18,(_width-70)/max(.75,scale),max(.75,scale),max(.75,scale),0);
    draw_text_transformed(_x+58,_y+36,(d.type==1 ? "AKTIV" : "PASSIV")+" | Stufe "+string(lv)+" / 9",.82,.82,0);
    draw_upgrade_orbs(_x+18,_y+76,lv,12,color);
    draw_set_color(c_white);draw_text_ext_transformed(_x+14,_y+96,body,18,tw/max(.1,scale),scale,scale,0);
    draw_set_color(c_white);draw_set_alpha(1);
}
function spell_pause_draw() {
    var ui=pause_geometry(),x0=ui.w+36,w=display_get_gui_width(),h=display_get_gui_height();
    var list_w=min(240,(w-x0-30)*.43),detail_x=x0+list_w+14,detail_w=w-detail_x-16;
    var row=min(34,(h-170)/12),hover=undefined,mx=device_mouse_x_to_gui(0),my=device_mouse_y_to_gui(0);
    draw_set_halign(fa_left);draw_set_valign(fa_top);draw_set_color(make_color_rgb(205,218,226));
    draw_text(x0,27,"BUILD | Stufe "+string(global.current_level));
    for(var group=0;group<2;group++) {
        var entries=group==0 ? global.active_spells : global.passive_spells,top=90+group*(6*row+30);
        var role=group==0 ? make_color_rgb(87,211,242) : make_color_rgb(191,132,242);
        draw_set_color(role);draw_text(x0,top-25,group==0 ? "AKTIVE FAEHIGKEITEN" : "PASSIVE FAEHIGKEITEN");
        for(var i=0;i<6;i++) {
            var yy=top+i*row;
            if(i>=array_length(entries)){draw_set_color(make_color_rgb(93,108,123));draw_text(x0+38,yy+5,"- frei -");continue;}
            var e=entries[i],selected=point_in_rectangle(mx,my,x0,yy,x0+list_w,yy+row-1);
            if(selected){draw_set_color(make_color_rgb(37,48,65));draw_rectangle(x0,yy,x0+list_w,yy+row-1,false);hover=e;}
            spell_ui_icon(e.id,x0+2,yy+1,27);draw_set_color(role);
            draw_text_transformed(x0+36,yy,e.name,.86,.86,0);
            draw_upgrade_orbs(x0+40,yy+24,e.level,9,role);
        }
    }
    draw_set_color(make_color_rgb(162,183,198));
    draw_text_ext_transformed(x0,h-56,ObjectPlayer.weapon.name+" | "+string(ceil(ObjectPlayer.hp))+" / "+string(ObjectPlayer.max_hp)+" Leben",18,list_w,.85,.85,0);
    if(is_struct(hover))spell_detail_draw(hover.id,hover.level,detail_x,72,detail_w,h-20,false);
    else {draw_set_color(make_color_rgb(152,171,189));draw_text_ext(detail_x,98,"Mit der Maus auf eine Faehigkeit zeigen, um Werte und vollstaendige Run-Statistiken zu sehen.",20,detail_w);}
    draw_set_color(c_white);
}
function spell_choices_draw() {
    var ui=spell_ui_layout();draw_set_font(-1);draw_set_halign(fa_left);draw_set_valign(fa_top);
    draw_set_color(make_color_rgb(8,12,21));draw_set_alpha(.95);draw_rectangle(0,0,display_get_gui_width(),display_get_gui_height(),false);draw_set_alpha(1);
    draw_set_color(make_color_rgb(239,211,158));draw_text(16,24,global.levelup_active ? "LEVELAUFSTIEG" : "TRUHENFUND");
    draw_set_color(c_white);draw_text(16,52,"Faehigkeit mit frischem Mausklick auswaehlen");
    for(var i=0;i<array_length(global.spell_options);i++) {
        var e=global.spell_options[i],yy=ui.y+i*(ui.row+ui.gap),color=spell_type_color(e.id);
        spell_ui_panel(ui.x,yy,ui.w,ui.row,i==global.selected_spell_index);
        draw_set_color(color);draw_rectangle(ui.x,yy,ui.x+4,yy+ui.row,false);spell_ui_icon(e.id,ui.x+12,yy+14,40);
        draw_set_color(c_white);draw_text_ext_transformed(ui.x+64,yy+7,e.name,18,(ui.w-74)/.92,.92,.92,0);
        draw_set_color(color);draw_text_transformed(ui.x+64,yy+29,e.type=="active" ? "AKTIV" : (e.type=="passive" ? "PASSIV" : "VOLLSTAENDIG"),.8,.8,0);
        draw_set_color(e.level>0 ? make_color_rgb(242,202,110) : color);draw_text_transformed(ui.x+64,yy+49,spell_choice_badge(e),.8,.8,0);
        if(e.id>0)draw_text_transformed(ui.x+140,yy+49,"Stufe "+string(e.level)+" -> "+string(e.level+1),.8,.8,0);
    }
    if(array_length(global.spell_options)>0){var e=global.spell_options[global.selected_spell_index];if(e.id>0)spell_detail_draw(e.id,e.level+1,ui.tx,ui.ty,ui.tw,ui.bottom,true);}
    draw_set_color(c_white);
}
