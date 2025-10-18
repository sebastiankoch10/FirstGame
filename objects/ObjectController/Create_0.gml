/// @description Initialisierung des Controllers
// ObjectController: Create
global._ui_hover_index = -1;

// Startzeit initialisieren
if (!variable_global_exists("start_time")) {
    global.start_time = current_time;
    show_debug_message("global.start_time initialisiert: " + string(global.start_time));
}

/// Create Event für ObjectController
global.levelup_active = false;    // Level-Up Auswahl ist anfangs nicht aktiv
global.chest_collected = false;   // Truhen-Auswahl ist anfangs nicht aktiv
global.game_paused = false;       // Spiel ist anfangs nicht pausiert
global.pause_initialized = false; // Pause wurde noch nicht initialisiert
global.spell_options = [];        // Liste für Zauberoptionen
global.selected_spell_index = 0;  // Index der aktuellen Auswahl
global.active_spells = [];        // Aktive Zauber
global.passive_spells = [];       // Passive Zauber
global.coins = 0;                 // Anfangsanzahl der Münzen
global.coins_needed = 10;         // Münzen, die für das erste Level-Up benötigt werden
global.current_level = 1;         // Startlevel


// Zauberpool erstellen (18 aktive und 18 passive Zauber)
global.abilities_pool = [
    {
        name: "1",
        type: "active",
        icon: spr_fireball_1,
        description: "Schießt einen mächtigen Feuerball.",
        damage: 25,
        cooldown: 4 // 4 Sekunden
    },
    {
        name: "2",
        type: "active",
        icon: spr_fireball_1,
        description: "Schießt einen gefrierenden Eisstrahl.",
        damage: 20,
        cooldown: 6  // 6 Sekunden
    },
    {
        name: "3",
        type: "active",
        icon: spr_fireball_1,
        description: "Erhöht die Verteidigung vorübergehend.",
        duration: 5 , // 5 Sekunden
        cooldown: 10 * room_speed // 10 Sekunden
    },
    {
        name: "4",
        type: "passive",
        icon: spr_fireball_1,
        description: "Erhöht den Schaden aller Feuerangriffe.",
        bonus_damage: 5
    },
    {
        name: "5",
        type: "passive",
        icon: spr_fireball_1,
        description: "Erhöht den Schaden aller Eisangriffe.",
        bonus_damage: 5
    },
    {
        name: "6",
        type: "passive",
        icon: spr_fireball_1,
        description: "Erhöht die Verteidigung dauerhaft.",
        bonus_defense: 10
    },
    {
        name: "7",
        type: "active",
        icon: spr_fireball_1,
        description: "Schießt einen weiteren Feuerball gleichzeitig.",
        damage: 30,
        cooldown: 4 * room_speed // 4 Sekunden
    },
    {
        name: "8",
        type: "active",
        icon: spr_fireball_1,
        description: "Gefrierende Strahlen werden häufiger.",
        damage: 25,
        cooldown: 5
    },
   {
        name: "9",
        type: "passive",
        icon: spr_fireball_1,
        description: "Erhöht die Angriffsreichweite von Feuerangriffen.",
        range_boost: 20
    },
    {
        name: "10",
        type: "passive",
        icon: spr_fireball_1,
        description: "Erhöht die Angriffsreichweite von Feuerangriffen.",
        range_boost: 20
    },
    {
        name: "11",
        type: "passive",
        icon: spr_fireball_1,
        description: "Verlangsamt Feinde zusätzlich durch Eisangriffe.",
        slow_percentage: 20 // 20% Verlangsamung
    },
    {
        name: "12",
        type: "passive",
        icon: spr_fireball_1,
        description: "Verringert den Schaden durch feindliche Angriffe.",
        damage_reduction: 15 // 15% weniger Schaden
    },
];


global.active_spells = [];
global.passive_spells = [];


// Debugging
show_debug_message("ObjectController: Initialisierung abgeschlossen.");
