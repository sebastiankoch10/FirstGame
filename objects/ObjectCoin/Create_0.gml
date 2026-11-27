/// @description Hier Beschreibung einfügen
// Sie können Ihren Code in diesem Editor schreiben
//show_debug_message("Coin erstellt bei X: " + string(x) + ", Y: " + string(y));
coin_value = 1;
collect_radius = 96;
collect_speed = combat_config().normal_coin_speed/60;

speed=0;hspeed=0;vspeed=0;depth=-y; // the step only updates the depth while the coin moves

magnetized=false;coin_collected=false;

magnet_generation=0;magnet_velocity=0;
