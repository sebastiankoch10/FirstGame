/// Level atmosphere (Grafik-Overhaul 26.11., docs/Design/Visuelles Leitbild & Animation.md 7.3):
/// - motes that drift through the air (forest dust and pollen, swamp spores, ashfrost ash and snow). They are drawn
///   before the world light, so they stay faint in the dark and light up where a lamp, a spell or a light shaft falls;
/// - self-luminous motes (fireflies, embers) with a tiny light each;
/// - light shafts from the upper left (the art direction's light direction): a light pool on the ground (light map)
///   and a faint haze band in the air.
/// Visual only (vfx_random), scaled by "Effektqualitaet". The motes live around the camera and wrap at the view edge.
function atmos_profile() {
    static forest={motes:[{kind:"dust",n:60,el:0,size:1,vx:6,vy:5,sway:10,alpha:.9},{kind:"pollen",n:30,el:7,size:1,vx:4,vy:-3,sway:14,alpha:.95},{kind:"firefly",n:12,el:6,size:2,vx:0,vy:0,sway:26,alpha:1}],
        shafts:{n:3,col:make_color_rgb(255,222,160),pool:.6,haze:.15,spacing:430,angle:298,len:520,width:92}};
    static swamp={motes:[{kind:"spore",n:52,el:6,size:1,vx:3,vy:-7,sway:12,alpha:.9},{kind:"firefly",n:18,el:6,size:2,vx:0,vy:0,sway:30,alpha:1}],
        shafts:{n:2,col:make_color_rgb(200,236,200),pool:.4,haze:.1,spacing:560,angle:296,len:480,width:96}};
    static ashfrost={motes:[{kind:"ash",n:48,el:8,size:1,vx:14,vy:20,sway:12,alpha:.9},{kind:"snow",n:44,el:2,size:1,vx:10,vy:26,sway:16,alpha:.95},{kind:"ember",n:14,el:1,size:1,vx:6,vy:-26,sway:10,alpha:1}],
        shafts:{n:2,col:make_color_rgb(206,224,255),pool:.45,haze:.12,spacing:520,angle:300,len:500,width:84}};
    if(room==Room1)return forest;
    if(!variable_global_exists("selected_level"))return forest;
    var id_=level_def().id;return id_=="swamp" ? swamp : (id_=="ashfrost" ? ashfrost : forest);
}
function atmos_reset() {global.atmos={motes:[],room:-1,level:-1,clock:0};}
function atmos_init() {if(!variable_global_exists("atmos"))atmos_reset();}
/// (Re)fill the mote list for the current level around the camera.
function atmos_fill() {
    atmos_init();var a=global.atmos,prof=atmos_profile(),r=combat_view_rect(),rate=fxp_rate();
    a.motes=[];a.room=room;a.level=variable_global_exists("selected_level") ? global.selected_level : 0;
    for(var g=0;g<array_length(prof.motes);g++) {
        var m=prof.motes[g],n=max(2,round(m.n*rate));
        for(var i=0;i<n;i++)array_push(a.motes,{g:g,x:vfx_random_range(r.left,r.right),y:vfx_random_range(r.top,r.bottom),ph:vfx_random(100),sp:vfx_random_range(.6,1.4)});
    }
}
function atmos_step(_dt) {
    atmos_init();var a=global.atmos;
    if(!instance_exists(ObjectPlayer))return;
    var lvl=variable_global_exists("selected_level") ? global.selected_level : 0;
    if(a.room!=room || a.level!=lvl || array_length(a.motes)==0)atmos_fill();
    a.clock+=_dt;var prof=atmos_profile(),r=combat_view_rect(),w=r.right-r.left+16,h=r.bottom-r.top+16,wind=variable_global_exists("weather") ? global.weather.wind*12 : 0;
    // performance: big hordes thin out the motes (148 enemies keep about a third); counted once per frame
    a.share=clamp(1.25-instance_number(ObjectMonster)/160,.35,1);
    var gs=prof.motes,ms=a.motes,n=ceil(array_length(ms)*a.share),c=a.clock,L=r.left-8,R=r.right+8,T=r.top-8,B=r.bottom+8;
    for(var i=0;i<n;i++) {
        var m=ms[i],p=gs[m.g],t=c*m.sp+m.ph;
        m.x+=(p.vx*m.sp+wind+p.sway*sin(t*.9))*_dt;
        m.y+=(p.vy*m.sp+p.sway*.6*cos(t*1.3))*_dt;
        // wrap around the view (new motes enter from the opposite side)
        if(m.x<L)m.x+=w;else if(m.x>R)m.x-=w;
        if(m.y<T)m.y+=h;else if(m.y>B)m.y-=h;
    }
}
/// _layer FXP_LIT: dust, pollen, spores, ash, snow (lit by the world light). FXP_EMIT: fireflies, embers.
/// Colours and kinds are looked up once per group (perf: up to ~150 motes per frame).
function atmos_draw(_layer) {
    atmos_init();var a=global.atmos,prof=atmos_profile(),gs=prof.motes,ng=array_length(gs),ms=a.motes,n=ceil(array_length(ms)*(variable_struct_exists(a,"share") ? a.share : 1));if(n==0)return;
    var info=array_create(ng);
    for(var g=0;g<ng;g++){var p=gs[g],emit=(p.kind=="firefly" || p.kind=="ember"),ramp=fxp_ramp(p.el);
        info[g]={on:emit==(_layer==FXP_EMIT),k:p.kind=="firefly" ? 1 : (p.kind=="ember" ? 2 : (p.kind=="snow" ? 3 : 0)),c0:ramp[0],c1:ramp[1],c2:ramp[2],main:ramp[p.kind=="ash" ? 1 : 0],alpha:p.alpha};}
    var c=a.clock,flip=floor(c*3) mod 2;
    for(var i=0;i<n;i++) {
        var m=ms[i],q=info[m.g];if(!q.on)continue;
        var t=c*m.sp+m.ph,px=round(m.x),py=round(m.y);
        switch(q.k) {
            case 1:{var glow=clamp(.5+.6*sin(t*2.1),0,1);if(glow<.05)break;
                draw_set_alpha(glow*.35);draw_set_color(q.c2);draw_rectangle(px-1,py-1,px+1,py+1,false);
                draw_set_alpha(glow);draw_set_color(q.c0);draw_point(px,py);}break;
            case 2:draw_set_alpha(.5+.5*sin(t*9));draw_set_color(flip==0 ? q.c1 : q.c2);draw_point(px,py);break;
            default:{
                // twinkle: motes catch the light for a moment
                draw_set_alpha(q.alpha*(.45+.55*max(0,sin(t*1.7))));draw_set_color(q.main);
                if(q.k==3 && (m.g mod 3)==0)draw_rectangle(px,py,px+1,py+1,false);else draw_point(px,py);
            }break;
        }
    }
    draw_set_alpha(1);draw_set_color(c_white);
}
/// Light shaft geometry for this frame: anchor on the ground (pool) and direction towards the light.
function atmos_shafts() {
    atmos_init();var prof=atmos_profile().shafts,r=combat_view_rect(),out=[],t=global.atmos.clock;
    // anchors repeat every `spacing` px in world space with a slight parallax, so the shafts stay put while walking
    var base=floor((r.left*.9)/prof.spacing)-1;
    for(var k=base;k<base+ceil((r.right-r.left)/prof.spacing)+3;k++) {
        var h=vfx_hash(k,77)*.5+.5;if(h<.25)continue;   // some gaps between shafts
        var gx=k*prof.spacing/.9+(vfx_hash(k,13))*120+r.left*.1,gy=r.top+(r.bottom-r.top)*(.45+.35*(vfx_hash(k,29)*.5+.5));
        var breathe=.75+.25*sin(t*.35+k*1.7);
        array_push(out,{x:gx,y:gy,w:prof.width*(.7+.6*h),k:breathe*(.6+.4*h),ang:prof.angle+4*sin(t*.12+k)});
    }
    return out;
}
/// Light contributions into the light map (called inside atmosphere_draw, additive): shaft pools and firefly glows.
function atmos_lights(_rect) {
    if(!instance_exists(ObjectPlayer))return;
    var prof=atmos_profile(),s=atmos_shafts();
    for(var i=0;i<array_length(s);i++) {
        var q=s[i];
        // one elongated pool per shaft (perf: one light sprite instead of two)
        atmosphere_source(q.x+lengthdir_x(q.w*.5,q.ang+180),q.y+lengthdir_y(q.w*.5,q.ang+180),q.w*1.9,prof.shafts.col,prof.shafts.pool*q.k,_rect);
    }
    var a=global.atmos,budget=0;
    for(var i=0;i<array_length(a.motes) && budget<5;i++) {
        var m=a.motes[i],p=prof.motes[m.g];if(p.kind!="firefly")continue;
        var glow=clamp(.5+.6*sin((a.clock*m.sp+m.ph)*2.1),0,1);if(glow<.2)continue;
        atmosphere_source(m.x,m.y,34,fxp_ramp(6)[1],.55*glow,_rect);budget++;
    }
}
/// Haze bands of the light shafts in the air (emissive, additive, very faint; under every danger).
function atmos_haze_draw() {
    if(vfx_quality()==0 || !instance_exists(ObjectPlayer))return;
    var prof=atmos_profile().shafts,s=atmos_shafts(),col=prof.col;
    gpu_set_blendmode(bm_add);
    for(var i=0;i<array_length(s);i++) {
        var q=s[i],ux=lengthdir_x(1,q.ang),uy=lengthdir_y(1,q.ang),nx=-uy,ny=ux,len=prof.len;
        // from the ground pool back towards the light (upper left), widening; brightest in the middle third
        var bx=q.x,by=q.y,tx=q.x-ux*len,ty=q.y-uy*len,w0=q.w*.5,w1=q.w*1.1,a=prof.haze*q.k;
        draw_primitive_begin(pr_trianglestrip);
        draw_vertex_colour(bx+nx*w0,by+ny*w0,col,0);draw_vertex_colour(bx,by,col,a*.6);
        draw_vertex_colour(tx+nx*w1,ty+ny*w1,col,0);draw_vertex_colour(tx,ty,col,a);
        draw_primitive_end();
        draw_primitive_begin(pr_trianglestrip);
        draw_vertex_colour(bx-nx*w0,by-ny*w0,col,0);draw_vertex_colour(bx,by,col,a*.6);
        draw_vertex_colour(tx-nx*w1,ty-ny*w1,col,0);draw_vertex_colour(tx,ty,col,a);
        draw_primitive_end();
    }
    gpu_set_blendmode(bm_normal);draw_set_alpha(1);
}
