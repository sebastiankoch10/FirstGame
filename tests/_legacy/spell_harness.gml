function spell_test_check(_condition,_message) {
    global.spell_test_checks+=1;
    if (!_condition) {global.spell_test_failed=true; show_debug_message("SPELL FAIL: "+_message);}
    else show_debug_message("SPELL PASS: "+_message);
}
function spell_test_tick() {
    if (!variable_global_exists("spell_test_frame")) {
        global.spell_test_frame=0; global.spell_test_failed=false; global.spell_test_checks=0;
    }
    global.spell_test_frame++;
    if (global.spell_test_frame==2) {
        with (ObjectSpawner) instance_destroy();
        global.qa_test_mode=true;
        var ids=[101,102,103,201,202,203];
        var classes=["Sword","Mage","Ranger"];
        for (var ci=0;ci<3;ci++) {
            global.selected_character=classes[ci]; reset_round();
            var pl=global.player; pl.x=300; pl.y=300;
            var base_power=pl.player_power, base_move=pl.moveSpeed;
            for (var si=0;si<6;si++) {
                var sid=ids[si], d=GetSpellData(sid);
                spell_test_check(is_struct(d),classes[ci]+" definition "+string(sid));
                spell_test_check(sprite_exists(asset_get_index(d.icon_sprite_name)),"icon "+string(sid));
                learn_spell(sid);
                for (var level=1;level<=9;level++) {
                    if (level>1) learn_spell(sid);
                    apply_passives(pl); apply_passives(pl);
                    var v=spell_values(sid,level);
                    if (sid==201) spell_test_check(abs(pl.damage_reduction-min(0.6,level*0.1))<0.0001,"shield level "+string(level));
                    if (sid==202) spell_test_check(pl.player_power==base_power+2*level,"power level "+string(level));
                    if (sid==203) spell_test_check(pl.moveSpeed==base_move+0.5*level,"move level "+string(level));
                    if (sid<200) {
                        var e=hotbar_find_active_by_name(d.name);
                        spell_test_check(e.level==level,"registered level "+string(sid));
                        cast_spell(e);
                        var obj=sid==101 ? ObjectFireball : (sid==102 ? ObjectIceball : ObjectLightningball);
                        var pr=instance_find(obj,0);
                        spell_test_check(instance_exists(pr),"cast "+string(sid));
                        spell_test_check(!cast_spell(e) && instance_number(obj)==1,"cooldown blocks duplicate cast");
                        spell_test_check(pr.damage==v.damage && pr.speed==0,"shared damage and single movement");
                        var mob=instance_create_layer(500,300,"Instances",ObjectMonster);
                        mob.hp=1000;
                        spell_projectile_hit(pr,mob);
                        spell_test_check(mob.hp==1000-v.damage,"measured HP "+string(sid)+" L"+string(level));
                        if (sid==101) {
                            spell_test_check(mob.burn_time==60 && mob.burn_dps==1,"ignite applied");
                            var before=mob.hp;
                            with (mob) repeat (60) event_perform(ev_step,0);
                            spell_test_check(abs(mob.hp-(before-1))<0.001 && mob.burn_time==0,"burn total and expiry");
                        }
                        if (sid==102) {
                            var normal=mob.base_move_speed;
                            with(mob) event_perform(ev_step,0);
                            spell_test_check(abs(mob.speed-normal*0.5)<0.0001,"slow movement");
                            with(mob) repeat(60) event_perform(ev_step,0);
                            spell_test_check(abs(mob.speed-normal)<0.0001,"slow recovers");
                        }
                        with(mob) instance_destroy();
                        e.cooldown_timer=d.cooldown;
                        repeat(d.cooldown) hotbar_tick_cooldowns();
                        spell_test_check(e.cooldown_timer==0,"cooldown expiry");
                    }
                }
                spell_test_check(!learn_spell(sid),"max level cap "+string(sid));
            }
            spell_test_check(array_length(global.active_spells)==3 && array_length(global.passive_spells)==3,"no duplicates");
            spell_test_check(!learn_spell(-42),"invalid ID rejected");
            reset_round(); apply_passives(pl);
            spell_test_check(array_length(global.passive_spells)==0 && pl.player_power==base_power && pl.moveSpeed==base_move && pl.damage_reduction==0,"round reset "+classes[ci]);
        }
        // Run actual projectile Step code against a boss, then test contact defense.
        var pl=global.player;
        pl.x=300; pl.y=300;
        for(var si=0;si<3;si++) {
            var sid=ids[si]; learn_spell(sid);
            var entry=hotbar_find_active_by_name(GetSpellData(sid).name);
            cast_spell(entry);
            var obj=sid==101 ? ObjectFireball : (sid==102 ? ObjectIceball : ObjectLightningball);
            var pr=instance_find(obj,0);
            pr.x=400; pr.y=300; pr.direction=0;
            var boss=instance_create_layer(430,300,"Instances",ObjectBossMonster); boss.hp=1000;
            var expected=pr.damage;
            with(pr) repeat(10) {if (!hit_done) spell_projectile_step();}
            spell_test_check(abs(boss.hp-(1000-expected))<0.001,"actual projectile Step hits boss once "+string(sid));
            with(boss) instance_destroy();
        }
        learn_spell(201); apply_passives(pl);
        var mob=instance_create_layer(600,300,"Instances",ObjectMonster);
        mob.damage=10; pl.hp=100; pl.invulnerable_timer=0;
        with(mob) {with(global.player) event_perform_object(ObjectPlayer,ev_collision,ObjectMonster);}
        spell_test_check(abs(pl.hp-91)<0.001,"shield reduces actual contact damage");
        with(mob) instance_destroy();
        pl.orbit_angle=0; pl.orbit_frame=0;
        var orbit=GetSpellData(201);
        var target=instance_create_layer(pl.x+lengthdir_x(50,4),pl.y+lengthdir_y(50,4),"Instances",ObjectMonster);
        target.hp=100;
        spell_orbit_step(pl);
        spell_test_check(target.hp==98,"orbit shield deals real contact damage");
        pl.orbit_angle=0; spell_orbit_step(pl);
        spell_test_check(target.hp==98,"orbit shield throttles repeat hits");
        with(target) instance_destroy();
        // Leave a real selection visible for rendering on subsequent frames.
        handle_chest_selection("levelup");
    }
    if (global.spell_test_frame==90) {
        var result={passed:!global.spell_test_failed, classes:["Sword","Mage","Ranger"],checks:global.spell_test_checks};
        show_debug_message("PLAYER_SMOKE_RESULT "+json_stringify(result));
        game_end();
    }
}
