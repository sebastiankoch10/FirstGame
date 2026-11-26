/// Shared world-space countdown geometry. The attack owns elapsed time; drawing never advances it.
function telegraph_make(_shape,_x,_y,_radius,_duration,_angle=0,_span=360,_width=48) {
    return {shape:_shape,x:_x,y:_y,radius:_radius,duration:max(.001,_duration),angle:_angle,span:_span,width:_width,inner:max(0,_radius-_width),elapsed:0};
}
function telegraph_progress(_g) {return clamp(_g.elapsed/_g.duration,0,1);}
function telegraph_ready(_g) {return _g.elapsed>=_g.duration;}
function telegraph_contains(_g,_x,_y) {
    if(_g.shape=="checker")return geo_checker_contains(_g,_x,_y); // field-wide board (scripts/hazard_fx)
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
// Drawing (telegraph_draw/paint/flash) lives in scripts/hazard_fx: one renderer for every enemy warning.
