/// Pixel-perfect rendering (Technische Architektur R2, variant B, decided 25.11.).
/// The world is drawn into a VIEW_W x VIEW_H application surface: 1 world unit = 1 art pixel = 1 surface pixel, so
/// sprites, rotations, effects and particles all snap to the same grid. ObjectRender's Post-Draw scales that surface to
/// the window: integer factors with nearest sampling, any other factor "sharp-bilinear" (nearest to the next integer
/// multiple, then one bilinear step), so every art pixel has the same size on screen. The GUI stays GUI_W x GUI_H.
#macro GUI_W 1280
#macro GUI_H 720
function render_init() {
    if(variable_global_exists("render_ready") && global.render_ready)return;
    global.render_ready=true;global.render_pre=-1;global.render_info={scale:1,mode:"",x:0,y:0,w:VIEW_W,h:VIEW_H};
    application_surface_draw_enable(false);
    ini_open("firstgame_settings.ini");var full=ini_read_real("Grafik","vollbild",0)>=1;ini_close();
    if(full)window_set_fullscreen(true);else render_window_default();
    render_room_start();
}
/// Windowed size: the largest whole multiple of the world view that fits the desktop; on 1080p desktops 1280x720
/// (sharp-bilinear), where fullscreen is an exact 2x.
function render_window_default() {
    if(window_get_fullscreen())return;
    var dw=display_get_width(),dh=display_get_height(),n=1;
    while(VIEW_W*(n+1)<=dw-48 && VIEW_H*(n+1)<=dh-96)n++;
    var w=VIEW_W*n,h=VIEW_H*n;
    if(n==1 && dw>=1280 && dh>=800){w=GUI_W;h=GUI_H;}
    if(window_get_width()!=w || window_get_height()!=h){window_set_size(w,h);call_later(2,time_source_units_frames,function(){window_center();});}
}
function render_set_fullscreen(_on) {
    window_set_fullscreen(_on);
    ini_open("firstgame_settings.ini");ini_write_real("Grafik","vollbild",_on ? 1 : 0);ini_close();
    if(!_on)call_later(2,time_source_units_frames,function(){render_window_default();});
}
function render_room_start() {
    // One view per room, its port is exactly the application surface (no implicit scaling by GameMaker).
    if(view_enabled){view_xport[0]=0;view_yport[0]=0;view_wport[0]=VIEW_W;view_hport[0]=VIEW_H;}
    if(surface_exists(application_surface) && (surface_get_width(application_surface)!=VIEW_W || surface_get_height(application_surface)!=VIEW_H))
        surface_resize(application_surface,VIEW_W,VIEW_H);
    display_set_gui_size(GUI_W,GUI_H);
}
/// Post-Draw: application surface -> window (letterboxed, centred).
function render_present() {
    if(!surface_exists(application_surface))return;
    // GameMaker resizes the application surface to the window when the window size changes after the room started
    // (window_set_size, fullscreen toggle): the world was then drawn 4:3-stretched into 1280x720 until the next room
    // (found 27.11. in scene recordings). Restore the world grid; the new size applies from the next frame.
    if(surface_get_width(application_surface)!=VIEW_W || surface_get_height(application_surface)!=VIEW_H)surface_resize(application_surface,VIEW_W,VIEW_H);
    var sw=surface_get_width(application_surface),sh=surface_get_height(application_surface);
    var ww=max(1,window_get_width()),wh=max(1,window_get_height());
    var s=min(ww/sw,wh/sh),dw=round(sw*s),dh=round(sh*s),dx=(ww-dw) div 2,dy=(wh-dh) div 2,whole=abs(s-round(s))<.001;
    draw_clear(c_black);gpu_set_blendenable(false);gpu_set_texfilter(false);
    if(whole || s<1) {
        if(s<1)gpu_set_texfilter(true);
        draw_surface_stretched(application_surface,dx,dy,dw,dh);
    } else {
        var n=ceil(s),pw=sw*n,ph=sh*n;
        if(!surface_exists(global.render_pre) || surface_get_width(global.render_pre)!=pw || surface_get_height(global.render_pre)!=ph) {
            if(surface_exists(global.render_pre))surface_free(global.render_pre);
            global.render_pre=surface_create(pw,ph);
        }
        surface_set_target(global.render_pre);draw_surface_ext(application_surface,0,0,n,n,0,c_white,1);surface_reset_target();
        gpu_set_texfilter(true);draw_surface_stretched(global.render_pre,dx,dy,dw,dh);
    }
    gpu_set_texfilter(false);gpu_set_blendenable(true);
    global.render_info={scale:s,mode:whole ? "ganzzahlig" : (s<1 ? "verkleinert" : "sharp-bilinear"),x:dx,y:dy,w:dw,h:dh};
}

/// Texture warm-up (26.11., user decision: load while the menu is open). The shared groups Default and Equipment are bz2
/// pages that GameMaker otherwise unpacks on first use, mid-fight (single frames up to ~350 ms). The main menu unpacks one
/// page every TEXTURE_WARMUP_GAP frames, so it stays usable in between; texture_warmup_finish() at run start completes
/// whatever is still missing (logged as TEXTURE_PREFETCH). Level groups are prefetched by level_world_create.
#macro TEXTURE_WARMUP_GAP 8
function texture_warmup_pages() {
    if(!variable_global_exists("texture_warmup_list")) {
        var l=[],groups=["Default","Equipment"];
        for(var g=0;g<array_length(groups);g++){var t=texturegroup_get_textures(groups[g]);for(var i=0;i<array_length(t);i++)array_push(l,t[i]);}
        global.texture_warmup_list=l;global.texture_warmup_index=0;global.texture_warmup_tick=0;
    }
    return global.texture_warmup_list;
}
function texture_warmup_done() {var l=texture_warmup_pages();return global.texture_warmup_index>=array_length(l);} // pages() first: it creates the index
function texture_warmup_step() {
    if(texture_warmup_done())return;
    global.texture_warmup_tick++;if(global.texture_warmup_tick<TEXTURE_WARMUP_GAP)return;
    global.texture_warmup_tick=0;
    var tex=global.texture_warmup_list[global.texture_warmup_index];global.texture_warmup_index++;
    if(!texture_is_ready(tex))texture_prefetch(tex);
}
function texture_warmup_finish() {
    var l=texture_warmup_pages(),t=get_timer(),n=0;
    while(global.texture_warmup_index<array_length(l)){var tex=l[global.texture_warmup_index];global.texture_warmup_index++;if(!texture_is_ready(tex)){texture_prefetch(tex);n++;}}
    texture_prefetch("Default");texture_prefetch("Equipment"); // safety net for whole groups, no-op when resident
    show_debug_message("TEXTURE_PREFETCH ms "+string((get_timer()-t)/1000)+" pages "+string(n)+" of "+string(array_length(l)));
}
