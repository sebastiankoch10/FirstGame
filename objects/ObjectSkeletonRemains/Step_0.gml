if(global.game_paused)exit;
life+=min(.05,delta_time/1000000);
if(life>=1.25){instance_destroy();exit;}
image_index=min(sprite_get_number(sprite_index)-1,floor(life*12));
