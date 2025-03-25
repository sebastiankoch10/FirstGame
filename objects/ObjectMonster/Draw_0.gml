/// Draw Event von ObjectMonster

if (variable_instance_exists(id, "hp") && variable_instance_exists(id, "max_hp")) {
    var health_ratio = hp / max_hp; // Verhältnis berechnen

    // Lebensbalken zeichnen
    var bar_x = x - 25; // Start X-Position
    var bar_y = y - 40; // Über dem Monster
    var bar_width = 50; // Breite des Balkens
    var bar_height = 6; // Höhe des Balkens

    // Hintergrund des Lebensbalkens (grau)
    draw_set_color(c_black);
    draw_rectangle(bar_x, bar_y, bar_x + bar_width, bar_y + bar_height, false);

    // Gefüllter Lebensbalken basierend auf HP
    var bar_color = make_color_hsv(120 * health_ratio, 255, 255); // Grün zu Rot Verlauf
    draw_set_color(bar_color);
    draw_rectangle(bar_x, bar_y, bar_x + (bar_width * health_ratio), bar_y + bar_height, false);
} else {
    show_debug_message("Warnung: Monster ohne hp oder max_hp gefunden. ID: " + string(id));
}

// Standard-Sprite zeichnen
draw_self();
