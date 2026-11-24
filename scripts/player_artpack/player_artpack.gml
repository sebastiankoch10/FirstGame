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
