// Boss AI, phase and hazard time are advanced once by ObjectController.
depth=-y;

if(dragon_enabled && dragon_dying) dragon_death_step(id,max(0,delta_time/1000000));
if(variable_instance_exists(id,"v2_enabled") && v2_enabled && v2_dying)boss_v2_death_step(id,max(0,delta_time/1000000));
