var props=[spr_master_oak,spr_master_maple,spr_master_pine,spr_master_ancient,spr_master_ferns,spr_master_redshrub,spr_master_blueflowers,spr_master_goldbush,spr_master_pillar,spr_master_arch,spr_master_wall,spr_master_brazier,spr_master_rocks,spr_master_stump,spr_master_paving,spr_master_leaves];
master_prop=clamp(round(image_index),0,15);
sprite_index=props[master_prop];image_index=0;image_speed=0;
depth=master_prop>=14 ? 90000 : -y;
blocks_movement=master_prop>=8 && master_prop<=10;
visible=false; // The world renderer enables only camera-near scenery before its draw pass.
