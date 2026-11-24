/// Camera-relative bounded atmosphere, with profiles per existing level. No particle instances.
function weather_profile(_level) {
    switch(_level) {
        case 1:return {fog:0.12,rain:0.4,wind:0.22,ambient:make_color_rgb(126,139,158)};
        case 2:return {fog:0.035,rain:0.8,wind:0.65,ambient:make_color_rgb(147,150,157)};
    }
    return {fog:0.045,rain:1,wind:0.45,ambient:make_color_rgb(187,202,219)};
}
function weather_init() {
    global.weather={clock:0,index:0,remaining:35,type:"mist",fog:0.04,rain:0,wind:0.12,sun:0.25,
        target_fog:0.07,target_rain:0,target_wind:0.15,target_sun:0.25,leaves:[],rain_particles:[],transitions:0};
    weather_set("mist",35);
}
function weather_set(_type,_duration) {
    var w=global.weather,p=weather_profile(global.selected_level);
    w.type=_type;w.remaining=_duration;w.transitions++;
    w.target_fog=p.fog;w.target_rain=0;w.target_wind=p.wind*0.25;w.target_sun=0.35;
    switch(_type) {
        case "clear":w.target_fog=p.fog*0.3;w.target_sun=0.85;break;
        case "mist":w.target_fog=p.fog*1.3;w.target_sun=0.25;break;
        case "wind":w.target_wind=p.wind;break;
        case "gust":w.target_wind=1;w.target_sun=0.45;break;
        case "cloud":w.target_sun=0.05;w.target_fog=p.fog*1.2;break;
        case "light_rain":w.target_rain=0.35*p.rain;w.target_sun=0.05;break;
        case "heavy_rain":w.target_rain=p.rain;w.target_sun=0;w.target_wind=p.wind*0.8;break;
        case "clearing":w.target_sun=0.9;w.target_fog=p.fog*0.6;break;
    }
}
function weather_step(_dt) {
    var w=global.weather;w.clock+=_dt;w.remaining-=_dt;
    if(w.remaining<=0) {
        var types=["clear","wind","gust","cloud","light_rain","heavy_rain","light_rain","clearing","mist"];
        var durations=[40,28,8,15,15,45,15,25,35];
        w.index=(w.index+1) mod array_length(types);weather_set(types[w.index],durations[w.index]);
    }
    var blend=1-exp(-_dt/3);
    w.fog=lerp(w.fog,w.target_fog,blend);w.rain=lerp(w.rain,w.target_rain,blend);
    w.wind=lerp(w.wind,w.target_wind,blend);w.sun=lerp(w.sun,w.target_sun,blend);
    var target_rain=round(160*w.rain);
    while(array_length(w.rain_particles)<target_rain)array_push(w.rain_particles,{x:random(1000),y:random(800)});
    while(array_length(w.rain_particles)>target_rain)array_delete(w.rain_particles,array_length(w.rain_particles)-1,1);
    for(var i=0;i<array_length(w.rain_particles);i++) {var p=w.rain_particles[i];p.x=(p.x+_dt*(45+w.wind*180)) mod 1000;p.y=(p.y+_dt*620) mod 800;}
    if(w.type=="gust" && array_length(w.leaves)<24)array_push(w.leaves,{x:-80,y:random(700),spin:random(360),life:0});
    for(var i=array_length(w.leaves)-1;i>=0;i--) {
        var p=w.leaves[i];p.life+=_dt;p.x+=_dt*(100+180*w.wind);p.y+=sin(w.clock*2+i)*_dt*18;p.spin+=_dt*110;
        if(p.x>1000 || p.life>7)array_delete(w.leaves,i,1);
    }
}
function weather_ambient() {
    var w=global.weather,p=weather_profile(global.selected_level),gain=0.94+0.15*w.sun-0.07*w.rain;
    var master=room==Room1;
    return make_color_rgb(clamp(color_get_red(p.ambient)*gain,master ? 152 : 112,master ? 210 : 175),clamp(color_get_green(p.ambient)*gain,master ? 165 : 125,master ? 220 : 180),clamp(color_get_blue(p.ambient)*gain,master ? 183 : 140,master ? 235 : 190));
}
function weather_draw() {
    var w=global.weather,r=combat_view_rect(),ww=r.right-r.left,hh=r.bottom-r.top;
    for(var i=0;i<6;i++) {
        var xx=r.left+((i*193+w.clock*(4+w.wind*12)) mod (ww+400))-200,yy=r.top+((i*127+w.clock*2) mod (hh+120))-60;
        draw_primitive_begin(pr_trianglefan);draw_vertex_colour(xx,yy,make_color_rgb(181,201,210),w.fog*0.35);
        for(var j=0;j<=24;j++) {var a=j*15;draw_vertex_colour(xx+lengthdir_x(380,a),yy+lengthdir_y(85,a),make_color_rgb(181,201,210),0);}
        draw_primitive_end();
    }
    draw_set_color(make_color_rgb(174,207,229));draw_set_alpha(0.26+0.15*w.rain);
    for(var i=0;i<array_length(w.rain_particles);i++) {
        var p=w.rain_particles[i],xx=r.left+(p.x/1000)*ww,yy=r.top+(p.y/800)*hh;
        draw_line(xx,yy,xx-3-w.wind*7,yy-11);
    }
    draw_set_alpha(0.8);
    for(var i=0;i<array_length(w.leaves);i++) {
        var p=w.leaves[i],xx=r.left+p.x/1000*ww,yy=r.top+p.y/800*hh;
        draw_set_color(room==Room1 ? (i mod 2 ? make_color_rgb(188,128,55) : make_color_rgb(172,62,48)) : (i mod 2 ? make_color_rgb(173,146,65) : make_color_rgb(109,167,90)));
        draw_triangle(xx+lengthdir_x(5,p.spin),yy+lengthdir_y(5,p.spin),xx+lengthdir_x(3,p.spin+120),yy+lengthdir_y(3,p.spin+120),xx+lengthdir_x(3,p.spin-120),yy+lengthdir_y(3,p.spin-120),false);
    }
    draw_set_color(c_white);draw_set_alpha(1);
}
