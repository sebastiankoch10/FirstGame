if(global.game_paused || !instance_exists(ObjectPlayer)) exit;
// Fast path (perf 27.11.): a coin that is not pulled and lies outside the pickup square cannot move or be collected
// this frame, exactly as in the full test below (dist > radius >= 16); speed and depth stay as set when it last moved.
var pr=max(16,ObjectPlayer.pickup_radius);
if(!magnetized && (abs(ObjectPlayer.x-x)>pr || abs(ObjectPlayer.y-y)>pr)) exit;
speed=0;hspeed=0;vspeed=0;
depth=-y;
var dist=point_distance(x,y,ObjectPlayer.x,ObjectPlayer.y);
collect_radius=ObjectPlayer.pickup_radius;
if((magnetized || dist<=collect_radius) && dist>0) {
    var dt=min(0.05,max(0,delta_time/1000000));
    if(magnetized)magnet_velocity=min(combat_config().magnet_max,magnet_velocity+combat_config().magnet_acceleration*dt);
    var step_distance=min(dist,(magnetized ? magnet_velocity : combat_config().normal_coin_speed)*dt);
    var dir=point_direction(x,y,ObjectPlayer.x,ObjectPlayer.y);
    x+=lengthdir_x(step_distance,dir);y+=lengthdir_y(step_distance,dir);
}

if(magnetized)fx_coin_trail(id); // overhaul magnet trail (visual only); glints come from fx_world_step
if(point_distance(x,y,ObjectPlayer.x,ObjectPlayer.y)<=16) event_perform(ev_collision,ObjectPlayer);
