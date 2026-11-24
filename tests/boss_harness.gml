// Deterministic boss/HUD/automatic-spell fixtures, appended only in the isolated copy.
function bh_clear_hazards() {global.hostile_bullets=[]; global.boss_zones=[];}
function bh_capture(_name) {
    var surf=surface_create(800,600); surface_set_target(surf); draw_clear(make_color_rgb(21,32,36));
    with(ObjectPlayer) event_perform(ev_draw,0);
    with(ObjectMonster) event_perform(ev_draw,0);
    with(ObjectBossMonster) event_perform(ev_draw,0);
    boss_hazards_draw(); hud_draw(); surface_reset_target();
    gp_capture(surf,_name); surface_free(surf);
}
function bh_fixture() {
    gp_clear_enemies(); bh_clear_hazards();
    var pl=global.player; pl.x=300; pl.y=320; pl.motion_state=0; pl.dodge_timer=0; pl.invulnerable_timer=0;
    pl.hp=pl.max_hp;
    // Every active ability is triggered without any input in every protected motion state.
    var ids=[101,102,103,104,105,106];
    for(var motion=0;motion<6;motion++) {
        gp_clear_enemies();
        var target=instance_create_layer(pl.x+55,pl.y,"Instances",ObjectMonster); target.hp=100000;
        pl.motion_state=motion<5 ? motion : 0; pl.dodge_timer=motion==5 ? 5 : 0;
        pl.hp=pl.max_hp/3;
        for(var i=0;i<6;i++) global.active_spells[i].cooldown_timer=0;
        auto_spells_step();
        for(var i=0;i<6;i++) gp_check(global.active_spells[i].cooldown_timer>0,"automatic spell "+string(ids[i])+" during motion "+string(motion));
        gp_check(target.hp<100000,"automatic nova deals actual damage");
    }
    pl.motion_state=0; pl.dodge_timer=0; pl.hp=pl.max_hp; pl.invulnerable_timer=0;
    gp_clear_enemies();
    for(var i=0;i<6;i++) global.active_spells[i].cooldown_timer=0;
    auto_spells_step();
    for(var i=0;i<6;i++) gp_check(global.active_spells[i].cooldown_timer==0,"no wasteful casts without target/full HP");
    var isolated=instance_create_layer(340,320,"Instances",ObjectMonster); isolated.hp=1000;
    var group_a=instance_create_layer(480,320,"Instances",ObjectMonster); group_a.hp=1000;
    var group_b=instance_create_layer(500,320,"Instances",ObjectMonster); group_b.hp=1000;
    var group_c=instance_create_layer(520,320,"Instances",ObjectMonster); group_c.hp=1000;
    var chosen=auto_spell_target(101,spell_values(101,9),pl);
    gp_check(chosen!=isolated,"fireball prioritizes reachable group");
    global.game_paused=true; auto_spells_step();
    gp_check(instance_number(ObjectFireball)==0,"pause blocks automatic spells");
    global.game_paused=false;
    global.game_over=true; auto_spells_step();
    gp_check(instance_number(ObjectFireball)==0,"game over blocks automatic spells"); global.game_over=false;
    auto_spells_step();
    var fire=global.active_spells[0];
    var cd=fire.cooldown_timer; hotbar_tick_cooldowns();
    gp_check(fire.cooldown_timer==cd-1,"independent cooldown advances");
    fire.cooldown_timer=1; hotbar_tick_cooldowns();
    gp_check(fire.cooldown_timer==0 && fire.ready_flash==12,"readiness pulse follows real cooldown completion");
    gp_clear_enemies();
    var hp_before=pl.hp;
    gp_check(player_receive_damage(pl,25),"actual incoming damage accepted");
    gp_check(abs(pl.hp-(hp_before-25*(1-pl.damage_reduction)))<0.001,"live player HP and reduction");
    gp_check(pl.hud_hp_trail>=hp_before && pl.hud_damage_hold>0,"health trail lags damage while live HP is immediate");
    bh_capture("hud");
    var fractions=[0,0.25,0.5,0.75,1,0];
    for(var i=0;i<6;i++) global.active_spells[i].cooldown_timer=global.active_spells[i].cooldown*fractions[i];
    bh_capture("cooldowns"); pl.invulnerable_timer=0; pl.hp=pl.max_hp;
    // Approved sprite asset resolution is checked across all actions and directions.
    var actions=["idle","walk","run","attack","jump","fall","dive","slide","hurt","death"];
    var directions=["right","left","up","down"];
    for(var a=0;a<10;a++) for(var d=0;d<4;d++) {
        var v=player_visual_asset("warrior",actions[a],directions[d]);
        gp_check(sprite_exists(v.sprite) && sprite_get_xoffset(v.sprite)==32 && sprite_get_yoffset(v.sprite)==51,"warrior approved sprite/origin "+actions[a]+" "+directions[d]);
        if(d==1) gp_check(v.sprite==player_visual_asset("warrior",actions[a],"right").sprite && v.mirror==-1,"left uses canonical mirrored right "+actions[a]);
    }
    var sheet=surface_create(800,600); surface_set_target(sheet); draw_clear(make_color_rgb(21,32,36));
    draw_set_color(c_white); draw_set_halign(fa_center); draw_set_valign(fa_top);
    for(var d=0;d<4;d++) draw_text(220+d*145,8,directions[d]);
    for(var a=0;a<10;a++) {
        draw_set_halign(fa_left); draw_text(12,38+a*55,actions[a]);
        for(var d=0;d<4;d++) {
            var v=player_visual_asset("warrior",actions[a],directions[d]);
            draw_sprite_ext(v.sprite,0,220+d*145,80+a*55,1.4*v.size*v.mirror,1.4*v.size,0,c_white,1);
        }
    }
    surface_reset_target(); gp_capture(sheet,"warrior"); surface_free(sheet);
    // Real schedule, not real-time waits: advance the round clock directly in this fixture.
    gp_check(!global.boss_dev_enabled && !instance_exists(boss_dev_start()),"development controls inert without opt-in");
    global.round_seconds=59.99; boss_schedule_step(); gp_check(!instance_exists(ObjectBossMonster),"no miniboss before minute one");
    global.round_seconds=60; boss_schedule_step();
    gp_check(instance_exists(global.active_boss) && global.active_boss.boss_id=="mini_sentinel","minute-one miniboss has explicit ID");
    var first=global.active_boss; boss_schedule_step(); gp_check(instance_number(ObjectBossMonster)==1 && global.active_boss==first,"schedule cannot duplicate boss");
    first.hp=0; boss_step(first,1/60);
    gp_check(!instance_exists(first) && array_length(global.hostile_bullets)==0,"miniboss death cleans encounter");
    global.round_seconds=180; boss_schedule_step(); gp_check(global.active_boss.boss_id=="mini_warden","minute-three second miniboss");
    first=global.active_boss; first.hp=0; boss_step(first,1/60);
    global.round_seconds=300; boss_schedule_step();
    var boss=global.active_boss;
    gp_check(instance_exists(boss) && boss.boss_id=="storm_warden" && boss.boss_phase==1,"minute-five main boss starts in phase one");
    gp_check(point_distance(pl.x,pl.y,boss.x,boss.y)>=180,"boss spawn has safe player spacing");
    boss_attack_begin(boss,"lightning");
    var mark=global.boss_zones[0],locked_x=mark.x,locked_y=mark.y;
    hp_before=pl.hp; boss_hazards_step(1.14);
    gp_check(pl.hp==hp_before,"lightning does no damage before warning finishes");
    pl.x+=15; gp_check(mark.x==locked_x && mark.y==locked_y,"warning position stays locked instead of tracking");
    pl.x=locked_x; pl.y=locked_y+10;
    boss_hazards_step(0.02);
    gp_check(abs(pl.hp-(hp_before-boss.boss_data.strike*global.monster_damage_multiplier*(1-pl.damage_reduction)))<0.001,"lightning deals exact real HP damage after telegraph");
    var damaged=pl.hp; boss_hazards_step(0.02); gp_check(pl.hp==damaged,"one strike cannot damage twice");
    bh_clear_hazards(); pl.invulnerable_timer=0; pl.hp=pl.max_hp;
    boss_zone_add(boss,"lightning",pl.x+53,pl.y-10,52,1,86);
    boss_hazards_step(1.01); gp_check(pl.hp==pl.max_hp,"no damage outside exact visible warning radius");
    var clock_before=global.round_seconds,age_before=global.boss_zones[0].age;
    global.game_paused=true; boss_world_step(5);
    gp_check(global.round_seconds==clock_before && global.boss_zones[0].age==age_before,"pause freezes round schedule and attack time");
    global.game_paused=false;
    for(var motion=1;motion<=5;motion++) {
        bh_clear_hazards(); pl.motion_state=motion<5 ? motion : 0; pl.dodge_timer=motion==5 ? 5 : 0;
        pl.invulnerable_timer=0; hp_before=pl.hp;
        boss_zone_add(boss,"lightning",pl.x,pl.y-10,52,1,86); boss_hazards_step(1.01);
        gp_check(pl.hp==hp_before,"boss strike respects protected movement "+string(motion));
    }
    pl.motion_state=0; pl.dodge_timer=0; pl.invulnerable_timer=0;
    for(var use=0;use<3;use++) {
        bh_clear_hazards(); boss_attack_begin(boss,"fan");
        gp_check(array_length(global.hostile_bullets)==0,"fan does not fire during initial telegraph");
        boss_step(boss,0.76);
        gp_check(array_length(global.hostile_bullets)==1+2*use,"fan escalation 1/3/5 emits actual projectiles");
    }
    boss.hp=boss.max_hp*0.49; boss_step(boss,0.01);
    gp_check(boss.boss_phase==2 && boss.boss_state=="transition" && array_length(global.hostile_bullets)==0,"phase two announces transition and clears prior hazards");
    boss_attack_begin(boss,"lightning"); gp_check(array_length(global.boss_zones)==3,"phase two expands lightning into three marked zones");
    bh_clear_hazards(); boss_ring_pattern(boss,0);
    var safe=true;
    for(var i=0;i<array_length(global.hostile_bullets);i++) {
        var bullet=global.hostile_bullets[i];
        if(abs(angle_difference(point_direction(0,0,bullet.vx,bullet.vy),0))<36) safe=false;
    }
    gp_check(safe && array_length(global.hostile_bullets)>10,"ring pattern deliberately preserves safe wedge");
    bh_clear_hazards(); boss_attack_begin(boss,"lob");
    mark=global.boss_zones[0]; locked_x=mark.x; locked_y=mark.y;
    boss_hazards_step(0.7);
    gp_check(mark.kind=="lob" && mark.age<mark.warning && mark.x==locked_x,"ballistic attack has grounded target and airborne interval");
    bh_capture("boss");
    pl.x=locked_x;pl.y=locked_y+10;pl.hp=pl.max_hp;pl.invulnerable_timer=0;
    hp_before=pl.hp;boss_hazards_step(0.71);
    gp_check(abs(pl.hp-(hp_before-boss.boss_data.lob*global.monster_damage_multiplier*(1-pl.damage_reduction)))<0.001,"ballistic impact deals actual area damage at landing");
    // Swept collision catches even a fast bullet crossing the player in one update.
    bh_clear_hazards(); pl.x=300;pl.y=320;pl.hp=pl.max_hp;pl.invulnerable_timer=0;
    boss_fan_pattern(boss,0,1,0,1000,12);
    global.hostile_bullets[0].x=200;global.hostile_bullets[0].y=pl.y-10;
    boss_hazards_step(0.2);
    gp_check(abs(pl.hp-(pl.max_hp-12*(1-pl.damage_reduction)))<0.001 && array_length(global.hostile_bullets)==0,"swept hostile projectile collision cannot tunnel");
    bh_clear_hazards(); boss_fan_pattern(boss,0,600,14,100,1);
    gp_check(array_length(global.hostile_bullets)==512,"hostile projectile allocation is capped");
    boss_hazards_step(7); gp_check(array_length(global.hostile_bullets)==0,"expired hostile projectiles are removed");
    bh_clear_hazards();
    // Bounded complete rotations in both phases; no five-minute gameplay wait is needed.
    var seen_one=[],seen_two=[];
    bh_clear_hazards();
    for(var phase=1;phase<=2;phase++) {
        boss.boss_phase=phase; boss.hp=phase==1 ? boss.max_hp : boss.max_hp*0.49;
        boss.boss_state="intro"; boss.boss_timer=0.01; boss.boss_rotation=0;
        var last_cast="";
        for(var frame=0;frame<900;frame++) {
            pl.x=boss.x+lengthdir_x(220,frame*0.72); pl.y=boss.y+lengthdir_y(220,frame*0.72);
            pl.invulnerable_timer=max(0,pl.invulnerable_timer-1);
            boss_step(boss,1/60); boss_hazards_step(1/60);
            if(boss.boss_state=="windup" && boss.boss_cast!=last_cast) {
                if(phase==1) array_push(seen_one,boss.boss_cast); else array_push(seen_two,boss.boss_cast);
                last_cast=boss.boss_cast;
            }
        }
        gp_check(pl.hp>0 && !global.game_over,"learnable rotation is survivable by ordinary continuous movement in fixture phase "+string(phase));
    }
    gp_check(array_contains(seen_one,"lightning") && array_contains(seen_one,"fan") && array_contains(seen_one,"lob"),"phase-one AI performs complete learned rotation");
    gp_check(array_contains(seen_two,"lightning") && array_contains(seen_two,"fan") && array_contains(seen_two,"lob") && array_contains(seen_two,"ring"),"phase-two AI performs expanded learned rotation");
    bh_clear_hazards();pl.x=300;pl.y=320;pl.hp=pl.max_hp;pl.invulnerable_timer=0;
    var reward_before=global.coins,chests_before=instance_number(ObjectChest);
    boss_fan_pattern(boss,0,5,14,130,12);
    boss_zone_add(boss,"lightning",pl.x,pl.y-10,52,1,86);
    boss.hp=0; boss_step(boss,1/60);
    gp_check(!instance_exists(boss) && array_length(global.hostile_bullets)==0 && array_length(global.boss_zones)==0,"boss death cleans all owned threats");
    gp_check(global.coins==reward_before+30 && instance_number(ObjectChest)==chests_before+1,"boss victory awards coins and chest");
    // Later encounters exist as explicitly reusable prototypes, not claimed unique finished fights.
    var defs=boss_definitions();
    for(var i=3;i<8;i++) {
        global.round_seconds=defs[i].at; boss_schedule_step();
        gp_check(global.active_boss.boss_id==defs[i].id && !defs[i].individual,"later scheduled encounter identity "+defs[i].id);
        var b=global.active_boss; b.hp=0; boss_step(b,1/60);
    }
    global.boss_dev_enabled=true;
    var dev=boss_dev_start("storm_warden",2,0.4,0.35);
    gp_check(instance_exists(dev) && dev.boss_phase==2 && abs(dev.hp/dev.max_hp-0.4)<0.001,"opt-in dev fixture supports ID phase HP and slowdown");
    boss_cleanup(dev); with(dev) instance_destroy();
    global.boss_dev_enabled=false;
    reset_round();
    gp_check(global.round_seconds==0 && array_length(global.hostile_bullets)==0 && array_length(global.boss_zones)==0,"new round resets clock and all boss threats");
    gp_check(!global.start_choice_pending && array_length(global.active_spells)==0 && array_length(global.passive_spells)==0,"restart still has no initial selection or skills");
}

function bh_class_auto_check() {
    var pl=global.player;gp_clear_enemies();
    var e=instance_create_layer(pl.x+55,pl.y,"Instances",ObjectMonster);e.hp=10000;
    for(var i=0;i<6;i++) global.active_spells[i].cooldown_timer=0;
    pl.hp=pl.max_hp/3;
    auto_spells_step();
    for(var i=0;i<6;i++) gp_check(global.active_spells[i].cooldown_timer>0,global.selected_character+" automatic spell "+global.active_spells[i].name);
    pl.hp=pl.max_hp;gp_clear_enemies();
}
