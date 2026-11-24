/// Shared world-space countdown geometry. The attack owns elapsed time; drawing never advances it.
function telegraph_make(_shape,_x,_y,_radius,_duration,_angle=0,_span=360,_width=48) {
    return {shape:_shape,x:_x,y:_y,radius:_radius,duration:max(.001,_duration),angle:_angle,span:_span,width:_width,inner:max(0,_radius-_width),elapsed:0};
}
function telegraph_progress(_g) {return clamp(_g.elapsed/_g.duration,0,1);}
function telegraph_ready(_g) {return _g.elapsed>=_g.duration;}
function telegraph_contains(_g,_x,_y) {
    var dx=_x-_g.x,dy=_y-_g.y,dist=point_distance(0,0,dx,dy);
    if(_g.shape=="line" || _g.shape=="rectangle") {
        var along=dx*lengthdir_x(1,_g.angle)+dy*lengthdir_y(1,_g.angle);
        var across=dx*lengthdir_x(1,_g.angle+90)+dy*lengthdir_y(1,_g.angle+90);
        return along>=0 && along<=_g.radius && abs(across)<=_g.width*.5;
    }
    if(dist>_g.radius || (_g.shape=="ring" && dist<_g.inner))return false;
    if(_g.shape=="sector")return dist<.001 || abs(angle_difference(point_direction(_g.x,_g.y,_x,_y),_g.angle))<=_g.span*.5;
    return true;
}
function telegraph_arc(_g,_from,_span,_fill,_alpha,_color) {
    if(_span<=0)return;
    draw_set_color(_color);draw_set_alpha(_alpha);
    var steps=max(1,ceil(abs(_span)/5)),inner=_g.shape=="ring" ? _g.inner : 0;
    for(var i=0;i<steps;i++) {
        var a=_from-_span*i/steps,b=_from-_span*(i+1)/steps;
        var ax=_g.x+lengthdir_x(_g.radius,a),ay=_g.y+lengthdir_y(_g.radius,a),bx=_g.x+lengthdir_x(_g.radius,b),by=_g.y+lengthdir_y(_g.radius,b);
        if(_fill) {
            var ix=_g.x+lengthdir_x(inner,a),iy=_g.y+lengthdir_y(inner,a),jx=_g.x+lengthdir_x(inner,b),jy=_g.y+lengthdir_y(inner,b);
            draw_triangle(ix,iy,ax,ay,bx,by,false);if(inner>0)draw_triangle(ix,iy,bx,by,jx,jy,false);
        } else {draw_line_width(ax,ay,bx,by,1);if(inner>0)draw_line_width(_g.x+lengthdir_x(inner,a),_g.y+lengthdir_y(inner,a),_g.x+lengthdir_x(inner,b),_g.y+lengthdir_y(inner,b),1);}
    }
}
function telegraph_draw(_g,_color) {
    var p=telegraph_progress(_g);telegraph_paint(_g,_color,.045,.18);
    var xx=_g.x,yy=_g.y;
    if(_g.shape=="line" || _g.shape=="rectangle"){xx+=lengthdir_x(_g.radius*.5,_g.angle);yy+=lengthdir_y(_g.radius*.5,_g.angle);}
    if(_g.shape=="sector"){xx+=lengthdir_x(_g.radius*.35,_g.angle);yy+=lengthdir_y(_g.radius*.35,_g.angle);}
    var radius=clamp(_g.radius*.12,12,22),angle=90-360*p;
    draw_set_alpha(.35);draw_set_color(_color);draw_circle(xx,yy,radius,true);
    draw_set_alpha(.85);draw_set_color(merge_color(_color,c_white,.65));draw_line_width(xx,yy,xx+lengthdir_x(radius,angle),yy+lengthdir_y(radius,angle),1);
    draw_circle(xx,yy,1.5,false);draw_set_alpha(1);draw_set_color(c_white);
}
function telegraph_paint(_g,_color,_fill_alpha,_edge_alpha) {
    if(_g.shape=="line" || _g.shape=="rectangle") {
        var nx=lengthdir_x(_g.width*.5,_g.angle+90),ny=lengthdir_y(_g.width*.5,_g.angle+90),ex=_g.x+lengthdir_x(_g.radius,_g.angle),ey=_g.y+lengthdir_y(_g.radius,_g.angle);
        draw_set_color(_color);draw_set_alpha(_fill_alpha);
        draw_triangle(_g.x+nx,_g.y+ny,ex+nx,ey+ny,ex-nx,ey-ny,false);draw_triangle(_g.x+nx,_g.y+ny,ex-nx,ey-ny,_g.x-nx,_g.y-ny,false);
        draw_set_alpha(_edge_alpha);draw_line(_g.x+nx,_g.y+ny,ex+nx,ey+ny);draw_line(ex+nx,ey+ny,ex-nx,ey-ny);draw_line(ex-nx,ey-ny,_g.x-nx,_g.y-ny);draw_line(_g.x-nx,_g.y-ny,_g.x+nx,_g.y+ny);
    } else {
        var span=_g.shape=="sector" ? _g.span : 360,start=_g.shape=="sector" ? _g.angle+span*.5 : 90;
        if(_g.shape=="ring" && variable_struct_exists(_g,"gap_width") && _g.gap_width>0){start=_g.gap_angle-_g.gap_width*.5;span=360-_g.gap_width;}
        telegraph_arc(_g,start,span,false,_edge_alpha,_color);telegraph_arc(_g,start,span,true,_fill_alpha,_color);
        draw_set_alpha(_edge_alpha);draw_set_color(_color);
        if(_g.shape=="sector")for(var side=-1;side<=1;side+=2){var a=_g.angle+side*span*.5;draw_line(_g.x,_g.y,_g.x+lengthdir_x(_g.radius,a),_g.y+lengthdir_y(_g.radius,a));}
    }
    draw_set_alpha(1);draw_set_color(c_white);
}
function telegraph_flash(_g,_color) {telegraph_paint(_g,_color,.3,0);}
