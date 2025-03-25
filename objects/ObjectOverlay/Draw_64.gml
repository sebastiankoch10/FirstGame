/// @description Hier Beschreibung einfügen
// Sie können Ihren Code in diesem Editor schreiben
/// Draw GUI Event

// Setze Schrift und Ausrichtung
draw_set_font(-1); // Standard-Schriftart
draw_set_halign(fa_left); // Links ausrichten
draw_set_color(c_white);  // Weiße Schriftfarbe

// GUI-Breite und -Höhe abrufen
var gui_width = display_get_gui_width();
var gui_height = display_get_gui_height();

// Zeit anzeigen
var elapsed_time = (current_time - global.start_time) div 1000;
draw_text(10, 10, "Time: " + string(elapsed_time) + "s");

// Level anzeigen
draw_text(10, 30, "Level: " + string(global.level));

// Münzen anzeigen
draw_text(10, 50, "Coins: " + string(global.coins));

// Gesammelte Items anzeigen (Beispiel für eine Liste)
var items_display = "Items: ";
for (var i = 0; i < array_length(global.items); i++) {
    items_display += global.items[i] + ", ";
}
draw_text(10, 70, items_display);

// Debugging

