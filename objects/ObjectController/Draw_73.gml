// World layer: lit by the world light and post-processed (render_fx). Dust, ash, smoke and ground marks are drawn
// before the light so they take it; self-luminous effects after it.
fxp_draw(FXP_LIT);atmos_draw(FXP_LIT);
atmosphere_draw();
atmos_haze_draw();atmos_draw(FXP_EMIT);
weather_draw();level_world_overlay();
spell_v2_draw();equipment_world_draw();coin_occlusion_draw();
class_effects_draw();chain_visual_draw();
fx_attacks_draw();fx_char_glow_draw();fxp_decals_glow();fxp_draw(FXP_EMIT);
fx_post_world();

// Readability layer: never blurred, tinted or distorted (Leitbild G5, G15). Damage numbers, hints and markers, then
// every enemy warning and danger, the next impact on top.
feedback_draw();pickup_hint_draw();miniboss_marker_draw();
bv2_hazards_draw(1); // boss warnings (queued)
if(instance_exists(global.active_boss) && global.active_boss.v2_enabled && !global.active_boss.dragon_enabled)bv2_encounter_draw(global.active_boss);
boss_hazards_draw();boss_direction_draw();

if(instance_exists(global.active_boss) && global.active_boss.dragon_enabled) dragon_vfx_draw(global.active_boss);
telegraph_flush(); // enemy warnings sorted by time to impact (scripts/hazard_fx)
bv2_hazards_draw(2); // attacks that hit now lie above every warning (Kampf & Begegnungen 8, rank 2 over rank 3)
fxp_draw(FXP_TOP); // sparks and embers inside opaque danger surfaces (beams): over the surface
ui_modal_draw();
