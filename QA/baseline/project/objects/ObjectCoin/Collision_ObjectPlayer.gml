if(global.game_paused || coin_collected) exit;
coin_collected=true;
if (variable_instance_exists(id, "coin_value")) {
    global.coins += coin_value;
} else {
    global.coins += 1;
}
global.coin_xp_earned+=coin_value;
if(magnet_generation>0) {global.magnet_metrics.collected++;global.magnet_metrics.xp+=coin_value;}
fg_sfx("coin");
instance_destroy();

