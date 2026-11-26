/// Resolve only approved ArtPack sprites, and fail before any sprite API sees -1.
function player_artpack_sprite(_name) {
    var _sprite = asset_get_index(_name);
    if (!sprite_exists(_sprite)) {
        show_error("Required player ArtPack sprite is missing: " + _name, true);
        return -1;
    }
    if (sprite_get_number(_sprite) < 1) {
        show_error("Player ArtPack sprite has no frames: " + _name, true);
        return -1;
    }
    return _sprite;
}

/// Call in the player instance, both on Create and round reset.
function player_initialize_artpack() {
    visual_actor = "swordsmanv3";
    if (global.selected_character == "Mage") visual_actor = "magev3";
    else if (global.selected_character == "Ranger") visual_actor = "rangerv3";

    var _actions = ["idle", "walk", "run", "attack", "jump", "fall", "dive", "slide", "hurt", "death"];
    var _directions = ["right", "left", "up", "down"];
    if(player_authored_actor(visual_actor)) {
        _actions=["idle","turn","walk","run","attack1","attack2","attack3","jump","fall","dive","landing","slide","dodge","hurt","death"];
        if(visual_actor=="magev3")array_push(_actions,"attack4");
        _directions=["right","up_right","up","up_left","left","down_left","down","down_right"];
    }
    for (var _a = 0; _a < array_length(_actions); _a++) {
        for (var _d = 0; _d < array_length(_directions); _d++) {
            player_artpack_sprite("spr_fg_" + visual_actor + "_" + _actions[_a] + "_" + _directions[_d]);
        }
    }

    // Stable collision mask; attack poses and class changes cannot resize it.
    mask_index = combat_mask();
    collision_half_width = 11;
    collision_half_height = 12;
    visual_animation_key = "spr_fg_" + visual_actor + "_idle_right";
    visual_sprite_index = player_artpack_sprite(visual_animation_key);
    visual_mirror=1; visual_size=1;
    visual_frame_index = 0;
    visual_land_timer=0;
    visual_facing_angle=facing_direction;visual_move_time=0;
    sprite_index = visual_sprite_index;
    image_index = 0;
    image_speed = 0;
}

/// Select authored pose sequences; visual scale never changes the physical mask.
function player_visual_asset(_actor,_action,_direction,_stage=1) {
    var mirror=1,size=1,resource_direction=_direction;
    if(player_authored_actor(_actor) && _action=="attack")_action="attack"+string(clamp(_stage,1,_actor=="magev3" ? 4 : 3));
    if(_actor=="knightv2") {
        if(_direction=="left") {resource_direction="right"; mirror=-1;}
        size=1.10;
    }
    return {sprite:player_artpack_sprite("spr_fg_"+_actor+"_"+_action+"_"+resource_direction),mirror:mirror,size:size};
}

/// GameMaker angles increase counter-clockwise; each octant has its own authored view.
function player_visual_direction(_actor,_angle) {
    var angle=((_angle mod 360)+360) mod 360;
    if(player_authored_actor(_actor)) {
        var dirs=["right","up_right","up","up_left","left","down_left","down","down_right"];
        return dirs[floor((angle+22.5)/45) mod 8];
    }
    if(angle>=45 && angle<135)return "up";
    if(angle>=135 && angle<225)return "left";
    if(angle>=225 && angle<315)return "down";
    return "right";
}

function player_authored_actor(_actor) {return _actor=="swordsmanv3" || _actor=="magev3" || _actor=="rangerv3";}

/// Procedural life of the player figure (docs/Design/Visuelles Leitbild & Animation.md 5.2): takeoff stretch,
/// landing squash, a short squash on direction flips and a spring-damped lean into speed and acceleration.
/// Render-only: called from the Draw event, changes no gameplay state, adds no input delay.
/// Returns scale factors about the feet and a rotation in degrees (GameMaker: counter-clockwise positive).
function player_motion_life() {
    var dt=clamp(delta_time/1000000,0,.05);
    if(!variable_instance_exists(id,"life_lean")){life_lean=0;life_land=0;life_turn=0;life_prev_x=x;life_vx=0;life_prev_air=false;life_prev_mirror=visual_mirror;}
    if(!variable_instance_exists(id,"life_cape")){life_cape=0;life_cape_v=0;life_hair=0;life_hair_v=0;}
    var air=motion_state!=player_motion_state.grounded,vx=dt>0 ? (x-life_prev_x)/dt : 0;
    vx=clamp(vx,-600,600);
    if(life_prev_air && !air){life_land=.14;life_cape_v+=90;life_hair_v+=110;}
    var back=visual_mirror<0 ? 1 : -1; // "behind" the character in screen degrees (visual_mirror is 1 or -1)
    if(!life_prev_air && air && dodge_timer<=0){life_cape_v-=110*back;life_hair_v-=130*back;} // take-off kick: hair and cape whip back
    if(visual_mirror!=life_prev_mirror && !air)life_turn=.09;
    var ax=dt>0 ? (vx-life_vx)/dt : 0;
    var target=(hp>0 && dodge_timer<=0) ? clamp(vx/260,-1,1)*1.4+clamp(ax/2600,-1,1)*1.4 : 0;
    life_lean+=(target-life_lean)*min(1,dt*10);
    life_land=max(0,life_land-dt);life_turn=max(0,life_turn-dt);
    life_prev_x=x;life_vx=lerp(life_vx,vx,.5);life_prev_air=air;life_prev_mirror=visual_mirror;
    var sx=1,sy=1;
    if(life_land>0){var k=sin(pi*life_land/.14);sx+=.07*k;sy-=.09*k;}
    else if(air && variable_instance_exists(id,"jump_time")){var jp=jump_time/max(.01,movement_config().jump_duration);if(jp<.15){var k=1-jp/.15;sx-=.05*k;sy+=.07*k;}}
    if(life_turn>0)sx*=1-.1*sin(pi*life_turn/.09);
    // Hair and cape: damped springs that trail the movement (screen degrees; positive swings the tip to the left).
    var trail=clamp(vx/260,-1,1),push=clamp(ax/2600,-1,1),sway=sin(current_time/620);
    var tc=(trail*14+push*6)+sway*1.2,th=(trail*8+push*4)+sway*.8;
    // in the air: rising -> hair and cape trail behind and down, falling -> they lift (follow-through of the jump arc)
    if(air && variable_instance_exists(id,"jump_time")){var jp=clamp(jump_time/max(.01,movement_config().jump_duration),0,1),arc=jp<.5 ? -(1-jp*2) : (jp-.5)*2;tc+=back*arc*10;th+=back*arc*7;}
    life_cape_v+=((tc-life_cape)*55-life_cape_v*8)*dt;life_cape+=life_cape_v*dt;
    life_hair_v+=((th-life_hair)*85-life_hair_v*9)*dt;life_hair+=life_hair_v*dt;
    life_cape=clamp(life_cape,-24,24);life_hair=clamp(life_hair,-16,16);
    return {sx:sx,sy:sy,rot:-life_lean,cape:life_cape,hair:life_hair};
}
