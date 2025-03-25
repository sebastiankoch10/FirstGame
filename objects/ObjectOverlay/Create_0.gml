/// @description Hier Beschreibung einfügen
// Sie können Ihren Code in diesem Editor schreiben
// Beispielwerte für Debugging und Testen
global.start_time = current_time; // Startzeit für die Uhr
global.level = 1;                // Aktuelles Level
global.coins = 0;                // Anzahl gesammelter Münzen
global.items = [];               // Liste gesammelter Items

/// Create Event von ObjectOverlay oder ObjectController
if (!variable_global_exists("start_time")) {
    global.start_time = current_time; // Initialisiert die Startzeit
}

global.game_paused = false;        // Gibt an, ob das Spiel pausiert ist
global.chest_collected = false;    // Gibt an, ob eine Truhe gesammelt wurde
global.selected_spell = -1;        // Gibt den aktuell ausgewählten Zauber an (-1 = keiner)
global.spell_options = [];         // Array für Zauberoptionen
