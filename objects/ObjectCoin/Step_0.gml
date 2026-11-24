speed=0;hspeed=0;vspeed=0;
depth=-y;
if(global.game_paused || !instance_exists(ObjectPlayer)) exit;
var dist=point_distance(x,y,ObjectPlayer.x,ObjectPlayer.y);
collect_radius=ObjectPlayer.pickup_radius;
if((magnetized || dist<=collect_radius) && dist>0) {
    var dt=min(0.05,max(0,delta_time/1000000));
    if(magnetized)magnet_velocity=min(combat_config().magnet_max,magnet_velocity+combat_config().magnet_acceleration*dt);
    var step_distance=min(dist,(magnetized ? magnet_velocity : combat_config().normal_coin_speed)*dt);
    var dir=point_direction(x,y,ObjectPlayer.x,ObjectPlayer.y);
    x+=lengthdir_x(step_distance,dir);y+=lengthdir_y(step_distance,dir);
}

if(point_distance(x,y,ObjectPlayer.x,ObjectPlayer.y)<=16) event_perform(ev_collision,ObjectPlayer);
