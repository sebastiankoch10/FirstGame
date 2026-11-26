/// Shared hazard rendering (Phase 2A, docs/Design/Kampf & Begegnungen.md "Telegraphs & Schadensgeometrie").
/// WYSIWYG: telegraph, active area, particles and damage all read the same geometry struct g (telegraph_make) that
/// telegraph_contains() tests. Shapes: circle, ring (optional gap), sector, line/rectangle (beam).
/// Telegraphs are queued and drawn sorted by time to impact (soonest on top, later ones as a faint preview).

// ---------------- Geometry helpers ----------------
function geo_is_line(_g) {return _g.shape=="line" || _g.shape=="rectangle";}
/// Field-wide checkerboard (Phase 2B): one hazard, cells anchored to world coordinates (origin g.x/g.y, cell size
/// g.radius, dangerous parity g.parity, arena g.bounds [l,t,r,b]). Logic covers the whole arena; only visible cells draw.
function geo_is_checker(_g) {return _g.shape=="checker";}
function geo_checker_cells(_g) {
    var fr=variable_global_exists("hz_frame") ? global.hz_frame : 0;
    if(variable_struct_exists(_g,"cells_frame") && _g.cells_frame==fr)return _g.cells; // once per frame (particles sample often)
    var v=combat_view_rect(),b=_g.bounds,c=_g.radius,out=[];
    var l=max(v.left,b[0]),t=max(v.top,b[1]),r=min(v.right,b[2]),bt=min(v.bottom,b[3]);
    for(var i=floor((l-_g.x)/c);i<=floor((r-_g.x)/c);i++)for(var j=floor((t-_g.y)/c);j<=floor((bt-_g.y)/c);j++)
        if(((i+j) mod 2+2) mod 2==_g.parity)array_push(out,[_g.x+i*c,_g.y+j*c]);
    _g.cells=out;_g.cells_frame=fr;return out;
}
function geo_checker_contains(_g,_x,_y) {
    var b=_g.bounds;if(_x<b[0] || _x>b[2] || _y<b[1] || _y>b[3])return false;
    var i=floor((_x-_g.x)/_g.radius),j=floor((_y-_g.y)/_g.radius);return ((i+j) mod 2+2) mod 2==_g.parity;
}
function geo_inner(_g) {return _g.shape=="ring" ? _g.inner : 0;}
/// Uniform point inside the shape for parameters u,v in [0,1).
function geo_sample(_g,_u,_v) {
    if(geo_is_checker(_g)){var cells=geo_checker_cells(_g);if(array_length(cells)==0)return {x:-99999,y:-99999};var k=min(array_length(cells)-1,floor(_u*array_length(cells))),fu=frac(_u*array_length(cells));return {x:cells[k][0]+fu*_g.radius,y:cells[k][1]+_v*_g.radius};}
    if(geo_is_line(_g)){var al=_g.radius*_u,ac=(_v-.5)*_g.width;return {x:_g.x+lengthdir_x(al,_g.angle)+lengthdir_x(ac,_g.angle+90),y:_g.y+lengthdir_y(al,_g.angle)+lengthdir_y(ac,_g.angle+90)};}
    var r0=geo_inner(_g),r=sqrt(lerp(r0*r0,_g.radius*_g.radius,_u)),a;
    if(_g.shape=="sector")a=_g.angle-_g.span*.5+_g.span*_v;
    else if(_g.shape=="ring" && variable_struct_exists(_g,"gap_width") && _g.gap_width>0)a=_g.gap_angle+_g.gap_width*.5+(360-_g.gap_width)*_v;
    else a=360*_v;
    return {x:_g.x+lengthdir_x(r,a),y:_g.y+lengthdir_y(r,a)};
}
function geo_area(_g) {
    if(geo_is_checker(_g))return array_length(geo_checker_cells(_g))*_g.radius*_g.radius;
    if(geo_is_line(_g))return _g.radius*_g.width;
    var a=pi*(_g.radius*_g.radius-sqr(geo_inner(_g)));
    if(_g.shape=="sector")a*=_g.span/360;
    if(_g.shape=="ring" && variable_struct_exists(_g,"gap_width"))a*=(360-_g.gap_width)/360;
    return a;
}
/// Angular range [start, span] covered by the shape (degrees, counter-clockwise).
function geo_arc(_g) {
    if(_g.shape=="sector")return [_g.angle-_g.span*.5,_g.span];
    if(_g.shape=="ring" && variable_struct_exists(_g,"gap_width") && _g.gap_width>0)return [_g.gap_angle+_g.gap_width*.5,360-_g.gap_width];
    return [0,360];
}
/// Filled band between radii r0..r1 over the shape's arc, or for lines the length range l0..l1 (one primitive batch).
function geo_fill_band(_g,_r0,_r1,_col,_alpha) {
    if(_r1<=_r0)return;
    draw_set_color(_col);draw_set_alpha(_alpha);
    if(geo_is_checker(_g)) {
        // countdown inside every cell: a centred square from _r0 to _r1 (fractions of the cell)
        var cells=geo_checker_cells(_g),c=_g.radius,o1=c*(1-_r1)*.5,o0=c*(1-_r0)*.5;
        for(var i=0;i<array_length(cells);i++) {
            var x0=cells[i][0],y0=cells[i][1];
            if(_r0<=0)draw_rectangle(x0+o1,y0+o1,x0+c-o1-1,y0+c-o1-1,false);
            else {draw_rectangle(x0+o1,y0+o1,x0+c-o1-1,y0+o0-1,false);draw_rectangle(x0+o1,y0+c-o0,x0+c-o1-1,y0+c-o1-1,false);draw_rectangle(x0+o1,y0+o0,x0+o0-1,y0+c-o0-1,false);draw_rectangle(x0+c-o0,y0+o0,x0+c-o1-1,y0+c-o0-1,false);}
        }
        return;
    }
    if(geo_is_line(_g)) {
        var nx=lengthdir_x(_g.width*.5,_g.angle+90),ny=lengthdir_y(_g.width*.5,_g.angle+90),ax=_g.x+lengthdir_x(_r0,_g.angle),ay=_g.y+lengthdir_y(_r0,_g.angle),bx=_g.x+lengthdir_x(_r1,_g.angle),by=_g.y+lengthdir_y(_r1,_g.angle);
        draw_primitive_begin(pr_trianglelist);
        draw_vertex(ax+nx,ay+ny);draw_vertex(bx+nx,by+ny);draw_vertex(bx-nx,by-ny);draw_vertex(ax+nx,ay+ny);draw_vertex(bx-nx,by-ny);draw_vertex(ax-nx,ay-ny);
        draw_primitive_end();return;
    }
    var arc=geo_arc(_g),steps=max(6,ceil(arc[1]/(_r1>200 ? 3 : 6)));
    draw_primitive_begin(pr_trianglelist);
    for(var i=0;i<steps;i++) {
        var a=arc[0]+arc[1]*i/steps,b=arc[0]+arc[1]*(i+1)/steps;
        var ox=_g.x+lengthdir_x(_r1,a),oy=_g.y+lengthdir_y(_r1,a),px=_g.x+lengthdir_x(_r1,b),py=_g.y+lengthdir_y(_r1,b);
        if(_r0<=.5){draw_vertex(_g.x,_g.y);draw_vertex(ox,oy);draw_vertex(px,py);}
        else {
            var ix=_g.x+lengthdir_x(_r0,a),iy=_g.y+lengthdir_y(_r0,a),jx=_g.x+lengthdir_x(_r0,b),jy=_g.y+lengthdir_y(_r0,b);
            draw_vertex(ix,iy);draw_vertex(ox,oy);draw_vertex(px,py);draw_vertex(ix,iy);draw_vertex(px,py);draw_vertex(jx,jy);
        }
    }
    draw_primitive_end();
}
/// Range of the shape along its fill axis: radius band for round shapes, length for lines.
function geo_extent(_g) {if(geo_is_checker(_g))return [0,1];return geo_is_line(_g) ? [0,_g.radius] : [geo_inner(_g),_g.radius];}
function geo_fill(_g,_col,_alpha) {var e=geo_extent(_g);geo_fill_band(_g,e[0],e[1],_col,_alpha);}
/// One-pixel outline of the full shape.
function geo_edge(_g,_col,_alpha,_w=1) {
    draw_set_color(_col);draw_set_alpha(_alpha);
    if(geo_is_checker(_g)){var cells=geo_checker_cells(_g),c=_g.radius;for(var i=0;i<array_length(cells);i++)for(var k=0;k<_w;k++)draw_rectangle(cells[i][0]+k,cells[i][1]+k,cells[i][0]+c-1-k,cells[i][1]+c-1-k,true);return;}
    if(geo_is_line(_g)) {
        var nx=lengthdir_x(_g.width*.5,_g.angle+90),ny=lengthdir_y(_g.width*.5,_g.angle+90),ex=_g.x+lengthdir_x(_g.radius,_g.angle),ey=_g.y+lengthdir_y(_g.radius,_g.angle);
        vfx_pixel_line(_g.x+nx,_g.y+ny,ex+nx,ey+ny,_w,_col,_alpha);vfx_pixel_line(_g.x-nx,_g.y-ny,ex-nx,ey-ny,_w,_col,_alpha);
        vfx_pixel_line(ex+nx,ey+ny,ex-nx,ey-ny,_w,_col,_alpha);vfx_pixel_line(_g.x+nx,_g.y+ny,_g.x-nx,_g.y-ny,_w,_col,_alpha);return;
    }
    var arc=geo_arc(_g),r0=geo_inner(_g),steps=max(8,ceil(arc[1]/(_g.radius>200 ? 2.5 : 5)));
    for(var i=0;i<steps;i++) {
        var a=arc[0]+arc[1]*i/steps,b=arc[0]+arc[1]*(i+1)/steps;
        vfx_pixel_line(_g.x+lengthdir_x(_g.radius,a),_g.y+lengthdir_y(_g.radius,a),_g.x+lengthdir_x(_g.radius,b),_g.y+lengthdir_y(_g.radius,b),_w,_col,_alpha);
        if(r0>1)vfx_pixel_line(_g.x+lengthdir_x(r0,a),_g.y+lengthdir_y(r0,a),_g.x+lengthdir_x(r0,b),_g.y+lengthdir_y(r0,b),_w,_col,_alpha);
    }
    if(arc[1]<360)for(var s=0;s<2;s++){var a=arc[0]+arc[1]*s;vfx_pixel_line(_g.x+lengthdir_x(r0,a),_g.y+lengthdir_y(r0,a),_g.x+lengthdir_x(_g.radius,a),_g.y+lengthdir_y(_g.radius,a),_w,_col,_alpha);}
}
/// Element from a hazard kind or a colour (fallback for callers that only pass a colour).
function hz_element_of(_kind) {
    if(is_string(_kind)) {
        if(string_pos("ice",_kind)>0 || string_pos("frost",_kind)>0)return 2;
        if(string_pos("void",_kind)>0 || string_pos("arcane",_kind)>0)return 4;
        if(string_pos("lightning",_kind)>0 || string_pos("storm",_kind)>0)return 3;
        if(string_pos("swamp",_kind)>0 || string_pos("acid",_kind)>0 || string_pos("poison",_kind)>0)return (string_pos("roots",_kind)>0 || string_pos("stomp",_kind)>0 || string_pos("wave",_kind)>0) ? 5 : 6;
        return 1;
    }
    var r=colour_get_red(_kind),g=colour_get_green(_kind),b=colour_get_blue(_kind);
    if(b>r && b>g)return r>g ? 4 : 2;
    if(g>r && g>=b)return 6;
    return 1;
}

// ---------------- Bounded element particles ----------------
/// Deterministic particles strictly inside g. _mode: 0 warning (sparse, drifting to the centre/origin),
/// 1 active (dense element motion), 2 dissipation (rising, fading, desaturated). _k = intensity 0..1.
function hz_particles(_g,_el,_t,_mode,_k,_seed=0) {
    if(_k<=0)return;
    var pal=vfx_palette(_el),q=vfx_quality(),dens=_mode==1 ? 1/170 : (_mode==0 ? 1/900 : 1/520);
    var n=clamp(round(geo_area(_g)*dens*(q==0 ? .45 : (q==1 ? .75 : 1))),3,_mode==1 ? 150 : 48);
    if(!variable_global_exists("hz_budget"))global.hz_budget=0;
    n=min(n,max(0,1100-global.hz_budget));global.hz_budget+=n;
    for(var i=0;i<n;i++) {
        var h1=vfx_hash(i,_seed+1)*.5+.5,h2=vfx_hash(i,_seed+7)*.5+.5,h3=vfx_hash(i,_seed+13)*.5+.5;
        var life=frac(_t*(.7+h3*.9)+h1),u=h1,v=h2,size=1+(h3>.72 ? 1 : 0);
        if(_mode==0){u=frac(h1*(1-life*.6));}                 // drift inward (warning: energy gathers toward the centre)
        if(_mode==1 && _el==1)v=frac(v+_t*.03*(h3-.5));        // fire licks sideways a little
        if(_mode==1 && (_el==4 || _el==2))v=frac(v+_t*.05*(h3>.5 ? 1 : -1)); // arcane/ice swirl
        var p=geo_sample(_g,u,v),px=p.x,py=p.y;
        if(_mode==1 && (_el==1 || _el==6))py-=life*(_el==1 ? 7 : 4);      // embers / bubbles rise
        if(_mode==2)py-=life*10;
        if(!telegraph_contains(_g,px,py+(_mode==2 ? life*10 : 0)))continue; // stays inside the danger area
        var a=_k*(_mode==2 ? (1-life) : sin(pi*life));if(a<.04)continue;
        // active particles stay bright against their own element base (pale core colour, a few in the body colour)
        var col=_mode==2 ? merge_color(pal[1],c_gray,.6) : (_mode==1 ? (h3>.35 ? pal[2] : merge_color(pal[1],c_white,.3)) : (life<.35 ? pal[2] : (life<.75 ? pal[1] : pal[0])));
        draw_set_alpha(a);draw_set_color(col);
        if(_el==3 && _mode==1 && h3>.8){var len=3+h2*4,ang=h1*360;vfx_pixel_line(px,py,px+lengthdir_x(len,ang),py+lengthdir_y(len,ang),1,pal[2],a);continue;}
        if(_el==2 && h3>.7){draw_rectangle(round(px),round(py)-1,round(px),round(py)+1,false);draw_rectangle(round(px)-1,round(py),round(px)+1,round(py),false);continue;}
        if(_el==6 && h3>.6 && _mode==1){draw_circle(round(px),round(py),1+size,true);continue;}
        draw_rectangle(round(px),round(py),round(px)+size-1,round(py)+size-1,false);
    }
}
/// Short crackling arcs inside the area (lightning), regenerated every 50 ms.
function hz_crackle(_g,_t,_k,_seed=0) {
    if(_k<=0 || vfx_quality()==0)return;
    var pal=vfx_palette(3),tick=floor(_t*20),n=clamp(round(geo_area(_g)/9000),2,10);
    for(var i=0;i<n;i++) {
        var u=vfx_hash(i,tick+_seed)*.5+.5,v=vfx_hash(i+31,tick+_seed)*.5+.5,p=geo_sample(_g,u,v),x0=p.x,y0=p.y,ang=vfx_hash(i+5,tick)*180;
        for(var s=0;s<3;s++){var x1=x0+lengthdir_x(5,ang+vfx_hash(s,tick+i)*60),y1=y0+lengthdir_y(5,ang+vfx_hash(s,tick+i)*60);
            if(!telegraph_contains(_g,x1,y1))break;vfx_pixel_line(x0,y0,x1,y1,1,s==0 ? pal[2] : pal[1],_k*(1-s*.25));x0=x1;y0=y1;}
    }
}

// ---------------- Telegraph (warning) ----------------
/// Queue an enemy warning; drawn by telegraph_flush() sorted by time to impact. _el: element (-1 = from colour).
function telegraph_draw(_g,_color,_el=-1) {
    if(!variable_global_exists("tg_queue"))global.tg_queue=[];
    var c={shape:_g.shape,x:_g.x,y:_g.y,radius:_g.radius,angle:_g.angle,span:_g.span,width:_g.width,inner:_g.inner,elapsed:_g.elapsed,duration:_g.duration};
    if(variable_struct_exists(_g,"parity")){c.parity=_g.parity;c.bounds=_g.bounds;}
    if(variable_struct_exists(_g,"height"))c.height=_g.height;
    if(variable_struct_exists(_g,"gap_width")){c.gap_width=_g.gap_width;c.gap_angle=_g.gap_angle;}
    array_push(global.tg_queue,{g:c,col:_color,el:_el==-1 ? hz_element_of(_color) : _el,remain:max(0,_g.duration-_g.elapsed)});
}
/// Draw all queued warnings: later impacts first and faint, the next impact last and fully readable (FFXIV-like
/// priority). Every warning: full-area tint + integrated filling countdown + edge; no clock hand.
function telegraph_flush() {
    global.hz_last=variable_global_exists("hz_budget") ? global.hz_budget : 0; // hazard-fx particles drawn this frame (perf metric)
    global.hz_budget=0;global.hz_frame=(variable_global_exists("hz_frame") ? global.hz_frame : 0)+1;
    if(!variable_global_exists("tg_queue") || array_length(global.tg_queue)==0)return;
    var q=global.tg_queue,soon=999;
    for(var i=0;i<array_length(q);i++)soon=min(soon,q[i].remain);
    array_sort(q,function(_a,_b){return _b.remain-_a.remain;});
    for(var i=0;i<array_length(q);i++)tg_render(q[i].g,q[i].col,q[i].el,q[i].remain>soon+.45);
    global.tg_queue=[];draw_set_alpha(1);draw_set_color(c_white);
}
/// One warning. Phases on the warning clock p (0..1): gathering (sparse inward particles), formation (fill grows
/// from the origin/centre), commitment (last 25 %: saturation and edge brighten), impact (handled by the hazard).
function tg_render(_g,_col,_el,_later) {
    var p=clamp(_g.elapsed/_g.duration,0,1),t=current_time/1000,late=clamp((p-.75)/.25,0,1);
    var pal=vfx_palette(_el),deep=merge_color(_col,pal[0],.35),hot=merge_color(_col,c_white,.25+.35*late);
    if(_later) {
        // A later mechanic is only an outline until it is next: the area that is safe right now must look safe.
        geo_edge(_g,_col,.28,1);draw_set_alpha(1);return;
    }
    // big patterns (field-wide boards, wide rings) stay lighter so the screen never floods
    var k=geo_area(_g)>160000 ? .7 : 1;
    // 1) the whole future danger area, always visible: subtle tint that deepens over time
    geo_fill(_g,deep,k*(.05+.10*power(p,1.4)+.07*late));
    // 2) integrated countdown: the same shape fills from its origin; the front is a soft brighter band
    var e=geo_extent(_g),front=lerp(e[0],e[1],p),bw=max(2,(e[1]-e[0])*.06);
    geo_fill_band(_g,e[0],front,_col,k*(.07+.10*p+.08*late));
    if(p<1)geo_fill_band(_g,max(e[0],front-bw),front,hot,k*(.14+.16*p));
    // 2b) focus: a light outline converges from outside onto the real edge (reference: shapes that focus before impact)
    if(p<.75 && !geo_is_checker(_g)){var fk=1-p/.75,fg=tg_scaled(_g,1+.35*fk);geo_edge(fg,merge_color(_col,c_white,.5),.35*fk*(.6+.4*sin(t*12)),1);}
    // 3) edge: present from the start, brightens and pulses in the commitment phase
    // edge weight tells how the attack is solved: 2 px = only a dodge helps ("all"), 1 px = jumpable/slidable
    geo_edge(_g,late>0 ? hot : _col,.42+.4*late+.12*late*sin(t*28),hz_edge_width(_g));
    // 4) inner energy: sparse particles drifting inward, denser near the end
    hz_particles(_g,_el,t,0,.35+.55*p,round(_g.x+_g.y));if(_el==3)hz_crackle(_g,t,.4*late,round(_g.x));
    draw_set_alpha(1);
}
/// Legacy helpers kept for callers (choreography previews): flat tint + edge in the new style.
function telegraph_paint(_g,_color,_fill_alpha,_edge_alpha) {geo_fill(_g,_color,_fill_alpha);if(_edge_alpha>0)geo_edge(_g,_color,_edge_alpha);draw_set_alpha(1);draw_set_color(c_white);}
function telegraph_flash(_g,_color) {geo_fill(_g,merge_color(_color,c_white,.5),.35);geo_edge(_g,c_white,.6);draw_set_alpha(1);}

/// Copy of a shape scaled around its own definition: radius/length, ring band, sector span and beam width grow by _k.
function tg_scaled(_g,_k) {
    var c={shape:_g.shape,x:_g.x,y:_g.y,radius:_g.radius*_k,angle:_g.angle,span:min(359,_g.span*_k),width:_g.width*_k,inner:_g.inner/_k};
    if(geo_is_line(_g)){c.radius=_g.radius;}            // beams focus in width, not in length
    if(variable_struct_exists(_g,"gap_width")){c.gap_width=_g.gap_width;c.gap_angle=_g.gap_angle;}
    return c;
}
function hz_edge_width(_g) {return (variable_struct_exists(_g,"height") && _g.height=="all") ? 2 : 1;}
// ---------------- Active area and dissipation ----------------
/// Coherent active danger area: transparent element base over the exact geometry, bright edge, dense bounded
/// particles; after the active time it dissipates (desaturated, rising) and no longer reads as dangerous.
function hz_area_draw(_g,_el,_col,_age,_active,_seed=0) {
    var t=current_time/1000,pal=vfx_palette(_el);
    if(_age<=_active) {
        var flash=clamp(1-_age/.12,0,1),pulse=.035*sin(t*9+_seed);
        var big=geo_area(_g)>160000 ? .75 : 1;
        geo_fill(_g,merge_color(pal[0],_col,.5),big*(.22+pulse+.25*flash));
        // a brighter rim band inside the edge: the boundary belongs to the surface, the centre stays see-through
        var e=geo_extent(_g);
        if(!geo_is_line(_g) && !geo_is_checker(_g))geo_fill_band(_g,max(e[0],e[1]-5),e[1],pal[1],.30);
        if(geo_is_checker(_g))geo_fill_band(_g,.88,1,pal[1],.28);
        geo_fill(_g,pal[2],.10*flash);
        geo_edge(_g,merge_color(pal[1],c_white,.35),.85,hz_edge_width(_g));
        hz_particles(_g,_el,t,1,1,_seed);
        if(_el==3)hz_crackle(_g,t,1,_seed);
    } else {
        var f=clamp(1-(_age-_active)/.3,0,1);if(f<=0)return;
        geo_fill(_g,merge_color(pal[0],c_gray,.6),.12*f);
        hz_particles(_g,_el,t,2,f*.8,_seed);
    }
    draw_set_alpha(1);draw_set_color(c_white);
}

// ---------------- Beams and charges ----------------
/// Coherent beam stream over the exact line geometry g (x,y origin, angle, radius = length, width). Body layers flicker
/// inside the hit width; a 1-px boundary marks the sides; particles flow from the origin outward. Drawn only up to the
/// view edge (the hitbox may continue off screen). _age/_active on the hazard clock; after _active it dissipates.
function vfx_beam_stream(_g,_el,_age,_active,_seed=0) {
    if(_el==1 && FX_HD_HAZARDS){vfx_beam_fire_hd(_g,_age,_active,_seed);return;}
    var pal=vfx_palette(_el),t=current_time/1000,r=combat_view_rect(),vis=200,corners=[[r.left,r.top],[r.right,r.top],[r.left,r.bottom],[r.right,r.bottom]];
    for(var i=0;i<4;i++)vis=max(vis,(corners[i][0]-_g.x)*lengthdir_x(1,_g.angle)+(corners[i][1]-_g.y)*lengthdir_y(1,_g.angle)+40);
    var len=min(_g.radius,vis),fade=_age<=_active ? 1 : clamp(1-(_age-_active)/.25,0,1);if(fade<=0 || len<4)return;
    var hw=_g.width*.5*(.35+.65*fade),ux=lengthdir_x(1,_g.angle),uy=lengthdir_y(1,_g.angle),nx=-uy,ny=ux,seg=4,n=max(2,ceil(len/seg)),flash=clamp(1-_age/.1,0,1);
    var layers=[[1,pal[0],.85,.16],[.74,pal[1],.95,.12],[.4,merge_color(pal[2],pal[1],.3),1,.1],[.15,c_white,.9,.08]];
    for(var L=0;L<4;L++) {
        var wl=layers[L][0],amp=layers[L][3];draw_set_color(layers[L][1]);draw_set_alpha(layers[L][2]*fade);draw_primitive_begin(pr_trianglestrip);
        for(var i=0;i<=n;i++) {
            // smooth waves travelling outward (three wavelengths): licking flames instead of per-segment jitter
            var d=min(len,i*seg),grow=clamp(d/40,.4,1);
            var wave=.5*sin(d*.045-t*14+L*1.3+_seed)+.3*sin(d*.11-t*23+L*2.1)+.2*sin(d*.27-t*37+L);
            var w=hw*wl*grow*clamp(1-amp+amp*wave+flash*.25,.2,1),cx=_g.x+ux*d,cy=_g.y+uy*d;
            if(L==3)w*=clamp(1-d/(len*.55),0,1); // white-hot core only near the mouth
            var side=.5*sin(d*.06-t*11+L)*amp*hw*.25;   // slight lateral sway, always inside the hit width
            draw_vertex(cx+nx*(w+side),cy+ny*(w+side));draw_vertex(cx-nx*(w-side),cy-ny*(w-side));
        }
        draw_primitive_end();
    }
    // side boundaries exactly at the hit width (WYSIWYG), steady so the safe side is readable
    var bcol=merge_color(pal[0],c_black,.25);
    vfx_pixel_line(_g.x+nx*hw,_g.y+ny*hw,_g.x+ux*len+nx*hw,_g.y+uy*len+ny*hw,1,bcol,.9*fade);
    vfx_pixel_line(_g.x-nx*hw,_g.y-ny*hw,_g.x+ux*len-nx*hw,_g.y+uy*len-ny*hw,1,bcol,.9*fade);
    // flowing particles (embers / shards / sparks), always inside the width
    var cnt=min(140,round(len/9))*(vfx_quality()==0 ? .5 : 1);
    for(var i=0;i<cnt;i++) {
        var h1=vfx_hash(i,_seed+3)*.5+.5,h2=vfx_hash(i,_seed+9)*.5+.5,h3=vfx_hash(i,_seed+21)*.5+.5;
        var d=frac(h1+t*(1.1+h3*.9)*(380/max(200,len)))*len,ac=(h2-.5)*1.7*hw*.85,px=_g.x+ux*d+nx*ac,py=_g.y+uy*d+ny*ac;
        var col=d<len*.25 ? pal[2] : (h3>.5 ? pal[1] : pal[0]),sz=h3>.8 ? 2 : 1;
        draw_set_alpha(fade*(.55+.45*h3));draw_set_color(col);draw_rectangle(round(px),round(py),round(px)+sz-1,round(py)+sz-1,false);
    }
    // mouth flare: small, flickering
    var fl=hw*(.55+.08*sin(t*33));
    draw_set_alpha(.8*fade);draw_set_color(pal[1]);draw_circle(round(_g.x),round(_g.y),max(3,fl),false);
    draw_set_color(pal[2]);draw_circle(round(_g.x),round(_g.y),max(2,fl*.55),false);
    draw_set_alpha(1);draw_set_color(c_white);
}
/// Graphics overhaul (26.11. Ergänzung): danger surfaces may be redesigned in the HD-2D style. Fire beams first (showcase);
/// false shows the previous stream for an A/B comparison.
#macro FX_HD_HAZARDS true
/// Fire beam in the HD-2D style over the exact line geometry (WYSIWYG, G15):
/// - the full hit width carries a clear warm tint (semi-transparent, the fire light on the ground shows through);
/// - both sides have a 1-px bright inner edge plus a 1-px dark outline just outside, readable on dark and on lit ground;
/// - inside: licking flame tongues (noise along the beam, never wider than the hit width), a white-hot flickering core,
///   hot spots that race outward; at the mouth a flare with short pixel rays.
/// Glow, heat shimmer, ground light and sparks come from fx_attacks (world layer and FXP_TOP).
function vfx_beam_fire_hd(_g,_age,_active,_seed=0) {
    var t=current_time/1000,len=fx_beam_visible_len(_g.x,_g.y,_g.angle,_g.radius),fade=_age<=_active ? 1 : clamp(1-(_age-_active)/.25,0,1);
    if(fade<=0 || len<4)return;
    // after the active time it dissipates like the previous stream: shrinks to 35 % width, turns grey, loses its edges
    var dis=_age>_active,hw=_g.width*.5*(dis ? .35+.65*fade : 1),ux=lengthdir_x(1,_g.angle),uy=lengthdir_y(1,_g.angle),nx=-uy,ny=ux,seg=4,n=max(2,ceil(len/seg)),flash=dis ? 0 : clamp(1-_age/.1,0,1);
    var ramp=fxp_ramp(1),deep=make_color_rgb(150,36,18);
    if(dis){var gr=c_gray;ramp=[merge_color(ramp[0],gr,.6),merge_color(ramp[1],gr,.6),merge_color(ramp[2],gr,.6),merge_color(ramp[3],gr,.6),merge_color(ramp[4],gr,.6)];deep=merge_color(deep,gr,.6);}
    // 1) the whole hit width: warm tint, a little stronger in the first frames
    draw_set_color(deep);draw_set_alpha((.65+.2*flash)*fade);draw_primitive_begin(pr_trianglestrip);
    draw_vertex(_g.x+nx*hw,_g.y+ny*hw);draw_vertex(_g.x-nx*hw,_g.y-ny*hw);draw_vertex(_g.x+ux*len+nx*hw,_g.y+uy*len+ny*hw);draw_vertex(_g.x+ux*len-nx*hw,_g.y+uy*len-ny*hw);
    draw_primitive_end();
    // 2) flame tongues: three layers whose width wavers with travelling noise, always inside the hit width
    var layers=[[.95,ramp[3],.8],[.66,ramp[2],.9],[.38,ramp[1],.95]];
    for(var L=0;L<3;L++) {
        var wl=layers[L][0];draw_set_color(layers[L][1]);draw_set_alpha(layers[L][2]*fade);draw_primitive_begin(pr_trianglestrip);
        for(var i=0;i<=n;i++) {
            var d=min(len,i*seg),grow=clamp(d/36,.35,1);
            // the outer layer never drops below ~75 % of the hit width, so the whole width stays clearly hot
            var lo=L==0 ? .78 : .55;
            var w1=lo+(1-lo)*(.5+.5*sin(d*.07-t*17+L*1.9+_seed))*(.6+.4*sin(d*.19-t*29+L*.7));
            var w2=lo+(1-lo)*(.5+.5*sin(d*.07-t*17+L*1.9+_seed+2.1))*(.6+.4*sin(d*.23-t*31+L*1.3));
            var cx=_g.x+ux*d,cy=_g.y+uy*d,wa=hw*wl*grow*min(1,w1+flash*.3),wb=hw*wl*grow*min(1,w2+flash*.3);
            draw_vertex(cx+nx*wa,cy+ny*wa);draw_vertex(cx-nx*wb,cy-ny*wb);
        }
        draw_primitive_end();
    }
    // 3) white-hot core: flickering, strongest near the mouth
    var cw=max(1,round(hw*.16*(1+.25*sin(t*41))));
    draw_set_color(ramp[0]);draw_set_alpha(.95*fade);draw_line_width(round(_g.x),round(_g.y),round(_g.x+ux*len*.7),round(_g.y+uy*len*.7),cw);
    // 4) hot spots racing outward (pixel clusters)
    var cnt=min(40,round(len/16))*(vfx_quality()==0 ? .5 : 1);
    for(var i=0;i<cnt;i++) {
        var h1=vfx_hash(i,_seed+3)*.5+.5,h2=vfx_hash(i,_seed+9)*.5+.5,d=frac(h1+t*(1.6+h2))*len,o=(h2-.5)*1.2*hw*.8;
        var px=round(_g.x+ux*d+nx*o),py=round(_g.y+uy*d+ny*o),s=h2>.7 ? 2 : 1;
        draw_set_alpha(fade*(1-d/len*.6));draw_set_color(d<len*.3 ? ramp[0] : ramp[1]);draw_rectangle(px,py,px+s-1,py+s-1,false);
    }
    // 5) edges exactly at the hit width: bright inner line, dark outline just outside (contrast on any ground)
    var ec=merge_color(ramp[1],c_white,.35),oc=make_color_rgb(40,10,6);
    if(dis){draw_set_alpha(1);draw_set_color(c_white);return;} // no edges, no flare once it no longer hurts
    vfx_pixel_line(_g.x+nx*(hw+1),_g.y+ny*(hw+1),_g.x+ux*len+nx*(hw+1),_g.y+uy*len+ny*(hw+1),1,oc,.75*fade);
    vfx_pixel_line(_g.x-nx*(hw+1),_g.y-ny*(hw+1),_g.x+ux*len-nx*(hw+1),_g.y+uy*len-ny*(hw+1),1,oc,.75*fade);
    vfx_pixel_line(_g.x+nx*hw,_g.y+ny*hw,_g.x+ux*len+nx*hw,_g.y+uy*len+ny*hw,1,ec,.95*fade);
    vfx_pixel_line(_g.x-nx*hw,_g.y-ny*hw,_g.x+ux*len-nx*hw,_g.y+uy*len-ny*hw,1,ec,.95*fade);
    // 6) mouth flare with short pixel rays
    // flare rays stay inside the hit width (r1 <= 95 % of the half width)
    var fl=hw*(.6+.1*sin(t*33));
    draw_set_alpha(.85*fade);draw_set_color(ramp[2]);draw_circle(round(_g.x),round(_g.y),max(3,round(fl)),false);
    draw_set_color(ramp[0]);draw_circle(round(_g.x),round(_g.y),max(2,round(fl*.55)),false);
    for(var k=0;k<6;k++){var a=k*60+t*140,r0=fl*.9,r1=min(hw*.95,fl*(1.35+.25*sin(t*23+k)));vfx_pixel_line(_g.x+lengthdir_x(r0,a),_g.y+lengthdir_y(r0,a),_g.x+lengthdir_x(r1,a),_g.y+lengthdir_y(r1,a),1,ramp[1],.8*fade);}
    draw_set_alpha(1);draw_set_color(c_white);
}
/// Energy gathering at an origin (mouth, hand, staff): particles converge, the core grows and brightens with p (0..1).
/// Reusable for every element (fire embers, ice motes, arcane sparks, lightning crackle).
function vfx_charge(_x,_y,_p,_el,_radius=60,_seed=0) {
    if(_p<=0)return;
    var pal=vfx_palette(_el),t=current_time/1000,n=vfx_quality()==0 ? 10 : 22,x0=round(_x),y0=round(_y);
    for(var i=0;i<n;i++) {
        var h1=vfx_hash(i,_seed+2)*.5+.5,h2=vfx_hash(i,_seed+5)*.5+.5,life=frac(t*(1.4+h2)+h1),a=h1*360+t*40*(h2-.5);
        var d=_radius*(1-life)*(.5+.5*h2),px=x0+lengthdir_x(d,a),py=y0+lengthdir_y(d,a);
        draw_set_alpha(_p*(.3+.7*life));draw_set_color(life>.7 ? pal[2] : pal[1]);
        if(_el==3 && h2>.6)vfx_pixel_line(px,py,px+lengthdir_x(3,a+90),py+lengthdir_y(3,a+90),1,pal[2],_p*life);
        else draw_rectangle(round(px),round(py),round(px)+(h2>.75 ? 1 : 0),round(py)+(h2>.75 ? 1 : 0),false);
    }
    var core=2+7*_p+sin(t*24)*_p;
    draw_set_alpha(.35*_p);draw_set_color(pal[0]);draw_circle(x0,y0,core*1.9,false);
    draw_set_alpha(.8*_p);draw_set_color(pal[1]);draw_circle(x0,y0,core,false);
    draw_set_alpha(_p);draw_set_color(pal[2]);draw_circle(x0,y0,max(1,core*.45),false);
    if(vfx_quality()>0)vfx_glow_disc(x0,y0,core*3,pal[1],.15*_p);
    draw_set_alpha(1);draw_set_color(c_white);
}
