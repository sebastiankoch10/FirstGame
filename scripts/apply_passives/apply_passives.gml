/// Rebuild modifiers from baselines every time; no stacking through repeated application.
function apply_passives(_pl) {
 if(!instance_exists(_pl))return;
 _pl.player_power=_pl.__base_player_power+spell_bonus(SPELL.POWER_UP);
 _pl.moveSpeed=_pl.__base_moveSpeed+spell_bonus(SPELL.MOVE_SPEED);
 _pl.damage_reduction=min(GetSpellData(SPELL.SHIELD).max_reduction,spell_bonus(SPELL.SHIELD));
 _pl.weapon_haste=spell_bonus(SPELL.HASTE);
 _pl.extra_projectiles=ceil(spell_level(SPELL.MULTISHOT)/GetSpellData(SPELL.MULTISHOT).projectile_interval);
 _pl.split_bonus=spell_bonus(SPELL.MULTISHOT);
 _pl.crit_chance=spell_bonus(SPELL.CRIT);_pl.crit_damage=GetSpellData(SPELL.CRIT).crit_multiplier;
 _pl.projectile_factor=1+spell_bonus(SPELL.PROJECTILE_SPEED);
 _pl.spell_area=1+spell_bonus(SPELL.AREA);
 _pl.spell_cdr=max(GetSpellData(SPELL.COOLDOWN).min_cooldown_factor,1-spell_bonus(SPELL.COOLDOWN));
 _pl.fire_bonus=spell_bonus(SPELL.EMBER);_pl.storm_bonus=spell_bonus(SPELL.CONDUCTOR);_pl.cold_bonus=spell_bonus(SPELL.WINTER);
 _pl.armor_flat=spell_bonus(SPELL.ARMOR);
 _pl.regen_rate=spell_bonus(SPELL.REGEN);
 _pl.pickup_radius=GetSpellData(SPELL.PICKUP).base_radius+spell_bonus(SPELL.PICKUP);
 _pl.status_factor=1+spell_bonus(SPELL.LINGER);
 _pl.resonance=spell_bonus(SPELL.RESONANCE);
 var bonus=spell_bonus(SPELL.VITALITY),previous=_pl.passive_hp_bonus;
 _pl.max_hp=_pl.__base_max_hp+bonus;
 var before=_pl.hp;_pl.hp=min(_pl.max_hp,_pl.hp+max(0,bonus-previous));
 if(_pl.hp>before){run_stats_heal(SPELL.VITALITY,_pl.hp-before);run_stats_cast(SPELL.VITALITY);}
 _pl.passive_hp_bonus=bonus;
 talent_equipment_apply(_pl); // talent trees and equipment add on top of the rebuilt spell values
}
function spell_passive_step(_dt) {
 var pl=ObjectPlayer;pl.regen_clock+=_dt;
 if(pl.regen_clock>=1){pl.regen_clock-=1;if(pl.regen_rate>0 && pl.hp<pl.max_hp){var before=pl.hp;pl.hp=min(pl.max_hp,pl.hp+pl.regen_rate);run_stats_heal(SPELL.REGEN,pl.hp-before);run_stats_cast(SPELL.REGEN);}}
}
