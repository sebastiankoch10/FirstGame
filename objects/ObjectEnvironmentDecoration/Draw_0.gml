var sway=0;
if(variable_global_exists("weather") && image_index<8)sway=sin(global.weather.clock*1.7+x*0.02)*global.weather.wind*1.8;
draw_sprite_ext(sprite_index,image_index,x,y,image_xscale,image_yscale,sway,image_blend,image_alpha);
