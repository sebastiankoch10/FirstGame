if (global.game_paused && (global.levelup_active || global.chest_collected)) {
    // Hintergrund bleibt sichtbar, Optionen anzeigen

    // Zentrierte Startpositionen für die Auswahl
    var start_x = display_get_gui_width() div 2 - 200; // Zentriert horizontal
    var start_y = display_get_gui_height() div 2 - 150; // Zentriert vertikal
    var box_width = 400; // Breite der Boxen
    var box_height = 100; // Höhe der Boxen
    var spacing = 20; // Abstand zwischen den Boxen

    for (var i = 0; i < array_length(global.spell_options); i++) {
        var spell = global.spell_options[i];

        // Highlight der aktuellen Auswahl
        if (i == global.selected_spell_index) {
            draw_set_color(c_yellow); // Gelbe Umrandung für Auswahl
        } else {
            draw_set_color(c_white); // Weiße Umrandung sonst
        }

        // Position der Box berechnen
        var box_x1 = start_x;
        var box_y1 = start_y + i * (box_height + spacing);
        var box_x2 = box_x1 + box_width;
        var box_y2 = box_y1 + box_height;

        // Kasten zeichnen
        draw_rectangle(box_x1, box_y1, box_x2, box_y2, false);

        // Zaubersymbol zeichnen (Prüfen, ob `spell.icon` existiert)
        if (variable_struct_exists(spell, "icon")) {
            draw_sprite(spell.icon, 0, box_x1 + 10, box_y1 + 10);
        } else {
            draw_set_color(c_red);
            draw_text(box_x1 + 10, box_y1 + 10, "No Icon");
        }

        // Zaubername zeichnen
        draw_set_color(c_white);
        draw_text(box_x1 + 60, box_y1 + 10, spell.name);

        // Zauberbeschreibung zeichnen
        draw_set_color(c_gray);
        draw_text(box_x1 + 60, box_y1 + 40, spell.description);
    }

    // Farben zurücksetzen
    draw_set_color(c_white);
}
