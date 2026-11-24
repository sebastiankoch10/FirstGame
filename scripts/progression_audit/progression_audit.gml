/// Actual future run samples, not inferred kill rates. Saved only in GameMaker's local sandbox.
function progression_audit_step() {
    var points=[60,180,300,420,600,900,1200,1500,1680,1740,1800];
    while(global.progression_sample_index<array_length(points) && global.round_seconds>=points[global.progression_sample_index]) {
        var upgrades=0;
        for(var i=0;i<array_length(global.active_spells);i++)upgrades+=global.active_spells[i].level;
        for(var i=0;i<array_length(global.passive_spells);i++)upgrades+=global.passive_spells[i].level;
        array_push(global.progression_samples,{seconds:points[global.progression_sample_index],level:global.current_level,
            earned_coin_xp:global.coin_xp_earned,kills:global.run_kills,boss_kills:global.run_boss_kills,ability_steps:upgrades});
        global.progression_sample_index++;
        var file=file_text_open_write("firstgame_progression_current.json");
        file_text_write_string(file,json_stringify({run:global.run_token,samples:global.progression_samples}));file_text_close(file);
    }
}
