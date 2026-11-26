atmosphere_draw();
weather_draw();level_world_overlay();feedback_draw();pickup_hint_draw();
spell_v2_draw();equipment_world_draw();coin_occlusion_draw();miniboss_marker_draw();
class_effects_draw();
bv2_hazards_draw();
if(instance_exists(global.active_boss) && global.active_boss.v2_enabled && !global.active_boss.dragon_enabled)bv2_encounter_draw(global.active_boss);
boss_hazards_draw();chain_visual_draw();boss_direction_draw();

if(instance_exists(global.active_boss) && global.active_boss.dragon_enabled) dragon_vfx_draw(global.active_boss);
telegraph_flush(); // enemy warnings sorted by time to impact (scripts/hazard_fx)
