/// Dragon as a composite unit (user decision 25.11.2026, docs/Design/Boss-Design.md): body, neck rings with dorsal
/// spikes and the head are separate baked parts (tests/tools/bosses/build_dragon_parts.py, 1 art pixel = 1 world
/// pixel, rotation frames instead of runtime rotation). The neck is a curve from the chest socket to the head; the head
/// looks at its target and carries the mouth, so fire, cone and bite start exactly where the drawn head is (G1).
/// The parts are hit shapes of the boss itself (combat_body_distance, boss_parts_collide): one unit, one health bar,
/// an area attack still hits the dragon once. Damage numbers and timings are unchanged.
/// Geometry is kept in local space (facing right, relative to the boss origin) and mirrored with dragon_facing.
#macro DRAGON_PARTS_ENABLED true
#macro DRAGON_FIRE_REACH 112   // chest socket -> mouth during fire attacks (world px)

function dragon_parts_composite(_action) {
    return array_contains(["idle","walk","turn","hurt","breath","breath_up","breath_down","charge"],_action);
}
function dragon_parts_init(_b) {
    var s=dragon_parts_spec(),k=s.sockets.idle[0];
    _b.dp={active:false,sx:k[0],sy:k[1],hx:k[0]+s.rest[0],hy:k[1]+s.rest[1],ha:10,hvx:0,hvy:0,hva:0,open:0,
        rings:[],shapes:[],mouth_x:_b.x,mouth_y:_b.y+k[1],body_spr:spr_drg_body_idle,body_frame:0};
}
/// Screen angle -> local angle (facing right), in -180..180.
function dragon_parts_local(_b,_world) {return angle_difference(_b.dragon_facing>0 ? _world : 180-_world,0);}
function dragon_parts_frame(_a) {var n=dragon_parts_spec().steps;return ((round(_a/(360/n)) mod n)+n) mod n;}
function dragon_parts_quant(_a) {var st=360/dragon_parts_spec().steps;return round(_a/st)*st;}
/// Mouth of fire attacks (beam, sweep): a fixed reach from the idle chest socket along the aim, so telegraph origin,
/// hitbox and drawn head agree in every frame of the attack (also while a sweep turns the aim).
function dragon_parts_fire_mouth(_b,_angle) {
    var k=dragon_parts_spec().sockets.idle[0];
    return {x:_b.x+_b.dragon_facing*k[0]+lengthdir_x(DRAGON_FIRE_REACH,_angle),y:_b.y+k[1]+lengthdir_y(DRAGON_FIRE_REACH,_angle)};
}
/// Local head pivot that puts the (quantised, as drawn) mouth exactly on a world point.
function dragon_parts_pivot_for(_b,_wx,_wy,_local_angle,_open) {
    var s=dragon_parts_spec(),q=dragon_parts_quant(_local_angle),m=_open ? s.head.open.mouth : s.head.closed.mouth;
    return [(_wx-_b.x)*_b.dragon_facing-lengthdir_x(m,q),(_wy-_b.y)-lengthdir_y(m,q)];
}
function dragon_parts_step(_b,_dt) {
    if(!DRAGON_PARTS_ENABLED || global.game_paused)return;
    if(!variable_instance_exists(_b,"dp"))dragon_parts_init(_b);
    var dp=_b.dp,s=dragon_parts_spec(),a=dragon_animation(_b);
    var walk=a.action=="walk",fr=walk ? (a.frame mod 4) : (floor(_b.dragon_clock*4) mod 4),k=walk ? s.sockets.walk[fr] : s.sockets.idle[fr];
    dp.body_spr=walk ? spr_drg_body_walk : spr_drg_body_idle;dp.body_frame=fr;dp.sx=k[0];dp.sy=k[1];
    dp.active=!_b.dragon_dying && dragon_parts_composite(a.action);
    if(!dp.active){dp.shapes=[];return;}
    var f=_b.dragon_facing,pl=ObjectPlayer,cast=_b.boss_cast,st=_b.boss_state,attack=st=="windup" || st=="active";
    var tx=dp.sx+s.rest[0],ty=dp.sy+s.rest[1],ta=10,open=false,stiff=7,exact=false,p;
    if(attack && (cast=="beam" || cast=="sweep")) {
        // fire breath: the mouth sits on the attack origin, the head points along the (sweeping) beam
        var m=dragon_mouth(_b,true);ta=dragon_parts_local(_b,_b.dragon_angle);
        open=st=="active" || _b.dragon_state_age>_b.enc_cfg.warning*.45;
        p=dragon_parts_pivot_for(_b,m.x,m.y,ta,open);tx=p[0];ty=p[1];stiff=14;exact=st=="active";
    } else if(attack && cast=="bite" && is_struct(_b.enc_geometry)) {
        var g=_b.enc_geometry;ta=dragon_parts_local(_b,g.angle);
        if(st=="windup") {
            // coil: the head pulls back and down, the jaws open late in the warning
            tx=dp.sx+s.rest[0]-lengthdir_x(16,ta);ty=dp.sy+s.rest[1]+8;open=_b.dragon_state_age>_b.enc_cfg.warning*.5;stiff=9;
        } else {
            // lunge along the telegraphed sector, the jaws close on the spot the player stood on
            var reach=g.radius*.8;if(instance_exists(pl))reach=min(reach,point_distance(g.x,g.y,pl.x,pl.y-10));
            open=_b.dragon_state_age<_b.enc_cfg.active*.6;
            p=dragon_parts_pivot_for(_b,g.x+lengthdir_x(reach,g.angle),g.y+lengthdir_y(reach,g.angle),ta,open);tx=p[0];ty=p[1];stiff=32;
        }
    } else if(attack && is_struct(_b.enc_geometry) && array_contains(["arc","volley","void"],cast)) {
        var g=_b.enc_geometry;ta=dragon_parts_local(_b,g.angle);open=st=="active" || _b.dragon_state_age>_b.enc_cfg.warning*.5;
        p=dragon_parts_pivot_for(_b,g.x,g.y,ta,open);tx=p[0];ty=p[1];stiff=12;
    } else {
        // look at the player with a slow breathing reach
        var wx=_b.x+f*dp.sx,wy=_b.y+dp.sy;
        if(instance_exists(pl))ta=clamp(dragon_parts_local(_b,point_direction(wx,wy-20,pl.x,pl.y-30)),-50,60);
        var reach=8+5*sin(_b.dragon_clock*1.7);
        tx=dp.sx+s.rest[0]+lengthdir_x(reach,ta);ty=dp.sy+s.rest[1]+lengthdir_y(reach,ta)-3*cos(_b.dragon_clock*1.7);
        open=_b.dragon_hit_age<.15;
    }
    if(exact) {dp.hx=tx;dp.hy=ty;dp.ha=ta;dp.hvx=0;dp.hvy=0;dp.hva=0;}
    else {
        // critically damped springs, sub-stepped so a fast lunge stays stable
        var n=stiff>15 ? 3 : 1,h=min(_dt,.05)/n;
        repeat(n) {
            dp.hvx+=(stiff*stiff*(tx-dp.hx)-2*stiff*dp.hvx)*h;dp.hx+=dp.hvx*h;
            dp.hvy+=(stiff*stiff*(ty-dp.hy)-2*stiff*dp.hvy)*h;dp.hy+=dp.hvy*h;
            dp.hva+=(stiff*stiff*angle_difference(ta,dp.ha)-2*stiff*dp.hva)*h;dp.ha+=dp.hva*h;
        }
    }
    dp.open=open;
    dragon_parts_layout(_b);
}
/// Neck rings along a cubic curve: it leaves the chest upwards and enters the head from behind its jaw; the more the
/// neck is stretched, the more it lines up with the head. Also the world hit shapes and the mouth.
function dragon_parts_layout(_b) {
    var dp=_b.dp,s=dragon_parts_spec(),f=_b.dragon_facing;
    var x0=dp.sx,y0=dp.sy,x3=dp.hx,y3=dp.hy,L=max(1,point_distance(x0,y0,x3,y3));
    var stretch=clamp((L-24)/70,0,1),te=dp.ha+75*(1-stretch);
    var x1=x0,y1=y0-L*.45,x2=x3-lengthdir_x(L*.35,te),y2=y3-lengthdir_y(L*.35,te);
    var px=x0,py=y0,acc=0,next=0,rings=[],seg=20;
    for(var i=1;i<=seg;i++) {
        var t=i/seg,u=1-t;
        var qx=u*u*u*x0+3*u*u*t*x1+3*u*t*t*x2+t*t*t*x3,qy=u*u*u*y0+3*u*u*t*y1+3*u*t*t*y2+t*t*t*y3;
        var d=point_distance(px,py,qx,qy),ang=point_direction(px,py,qx,qy);
        while(next<=acc+d) {var r=d>0 ? (next-acc)/d : 0;array_push(rings,{x:px+(qx-px)*r,y:py+(qy-py)*r,a:ang});next+=s.ring.spacing;}
        acc+=d;px=qx;py=qy;
    }
    dp.rings=rings;
    var q=dragon_parts_quant(dp.ha),m=dp.open ? s.head.open.mouth : s.head.closed.mouth;
    var mx=dp.hx+lengthdir_x(m,q),my=dp.hy+lengthdir_y(m,q);
    dp.mouth_x=_b.x+f*mx;dp.mouth_y=_b.y+my;
    var hr=dp.open ? s.head.open.radius : s.head.closed.radius,cx=dp.hx+lengthdir_x(m*.45,q),cy=dp.hy+lengthdir_y(m*.45,q);
    var shapes=[[_b.x+f*cx,_b.y+cy,hr]];
    for(var i=2;i<array_length(rings);i+=3)array_push(shapes,[_b.x+f*rings[i].x,_b.y+rings[i].y,s.ring.radius]);
    dp.shapes=shapes;
}
function dragon_parts_draw(_b,_lift,_col,_alpha) {
    var dp=_b.dp,f=_b.dragon_facing,s=dragon_parts_spec(),dark=merge_color(_col,c_black,.16),bx=round(_b.x),by=round(_b.y-_lift);
    draw_sprite_ext(dp.body_spr,dp.body_frame,bx,by,f,1,0,_col,_alpha);
    var n=array_length(dp.rings),off=s.ring.half*.7;
    for(var i=1;i<n;i+=2) {
        var r=dp.rings[i];
        draw_sprite_ext(spr_drg_spike,dragon_parts_frame(r.a),bx+f*round(r.x+lengthdir_x(off,r.a+90)),by+round(r.y+lengthdir_y(off,r.a+90)),f,1,0,_col,_alpha);
    }
    for(var i=0;i<n;i++){var r=dp.rings[i];draw_sprite_ext(spr_drg_neck,dragon_parts_frame(r.a),bx+f*round(r.x),by+round(r.y),f,1,0,i mod 2 ? dark : _col,_alpha);}
    draw_sprite_ext(dp.open ? spr_drg_head_open : spr_drg_head_closed,dragon_parts_frame(dp.ha),bx+f*round(dp.hx),by+round(dp.hy),f,1,0,_col,_alpha);
}
/// Distance from a point to the nearest part (0 inside). Used by combat_body_distance for area and melee hits.
function dragon_parts_distance(_b,_x,_y) {
    var d=1000000,sh=_b.dp.shapes;
    for(var i=0;i<array_length(sh);i++)d=min(d,max(0,point_distance(_x,_y,sh[i][0],sh[i][1])-sh[i][2]));
    return d;
}
/// Projectiles and orbiting blades test masks with collision_circle_list; this adds a boss whose parts they touch.
function boss_parts_collide(_x,_y,_r,_list) {
    with(ObjectBossMonster)if(variable_instance_exists(id,"dp") && dp.active && hp>0 && ds_list_find_index(_list,id)<0 && dragon_parts_distance(id,_x,_y)<=_r)ds_list_add(_list,id);
}
