/// @description Fetch spell data based on name and level
function scr_get_spell_data(spell_name) {
    switch (spell_name) {
        case "Feuerball":
            return {
                damage: 20, // Base damage
                speed: 8,   // Movement speed
                cooldown: 5 * room_speed // Cooldown in steps
            };
        // Add other spells here...
        default:
            return undefined;
    }
}
