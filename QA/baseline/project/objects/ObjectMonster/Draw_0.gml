if(variable_instance_exists(id,"boss_twin") && boss_twin){if(instance_exists(boss_owner))bv2_actor_draw(boss_owner,true);exit;}
if(variable_instance_exists(id,"boss_minion") && boss_minion){master_shadow_draw(x,y,15,5,.35);draw_sprite_ext(spr_bv2_brood,floor(minion_clock*8) mod 4,x,y,1,1,0,c_white,1);exit;}
enemy_draw(monster_scale,false);
