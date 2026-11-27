var sway=0;
if(variable_global_exists("weather") && image_index<8)sway=sin(global.weather.clock*1.7+x*0.02)*global.weather.wind*1.8;
fx_sway_draw(sprite_index,image_index,x,y,image_xscale,image_yscale,sprite_get_yoffset(sprite_index)*image_yscale*dsin(sway),image_blend,image_alpha); // pixel-grid sway
