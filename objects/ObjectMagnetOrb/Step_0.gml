if(global.game_paused || !instance_exists(global.player))exit;
// Ordinary overlap is handled by the real collision event; sweep only rescues fast crossings.
var radius=combat_config().orb_radius+global.player.contact_radius;
if(point_distance(x,y,global.player.x,global.player.y)>radius && magnet_touching(id,global.player))magnet_collect(id,global.player);
