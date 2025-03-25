// Draw-Event von ObjectPlayer oder ObjectMonster

// Standard-Sprite zeichnen
draw_self();

// Position des Lebensbalkens
var bar_x = x - 25; // Start X-Position
var bar_y = y - 40; // Über dem Spieler (anpassen für Monster)
var bar_width = 50; // Breite des Balkens
var bar_height = 6; // Höhe des Balkens

// Lebensbalken-Farbe (grün bei vollem Leben, rot bei wenig Leben)
var health_ratio = hp / max_hp;
var bar_color = make_color_hsv(120 * health_ratio, 255, 255);

// Hintergrund des Lebensbalkens (grau)
draw_set_color(c_black);
draw_rectangle(bar_x, bar_y, bar_x + bar_width, bar_y + bar_height, false);

// Gefüllter Lebensbalken basierend auf HP
draw_set_color(bar_color);
draw_rectangle(bar_x, bar_y, bar_x + (bar_width * health_ratio), bar_y + bar_height, false);
