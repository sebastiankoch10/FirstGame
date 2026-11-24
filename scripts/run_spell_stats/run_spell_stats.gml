/// Actual run contributions: clipped HP loss/healing, successful casts, real impacts.
function run_stats_reset() {global.run_spell_stats={};}
function run_stats_get(_sid) {
    if(!variable_global_exists("run_spell_stats")) run_stats_reset();
    var key="s"+string(_sid);
    if(!variable_struct_exists(global.run_spell_stats,key)) variable_struct_set(global.run_spell_stats,key,{dot_damage:0,damage:0,healing:0,hits:0,casts:0,blocked:0,extra_projectiles:0});
    return variable_struct_get(global.run_spell_stats,key);
}
function run_stats_damage(_sid,_amount,_hit=true) {
    if(_sid<=0 || _amount<=0) return;
    var s=run_stats_get(_sid);s.damage+=_amount;if(_hit)s.hits++;
}
function run_stats_heal(_sid,_amount) {if(_amount>0)run_stats_get(_sid).healing+=_amount;}
function run_stats_cast(_sid) {run_stats_get(_sid).casts++;}
function run_stats_text(_sid) {
    var s=run_stats_get(_sid);
    var out="Dieser Run: "+string_format(s.damage,0,1)+" Schaden | "+string_format(s.healing,0,1)+" Heilung";
    out+="\nDavon DoT: "+string_format(s.dot_damage,0,1);
    out+="\nTreffer: "+string(s.hits)+" | Ausloesungen: "+string(s.casts);
    if(_sid==SPELL.SHIELD)out+="\nVerhinderter Schaden: "+string_format(s.blocked,0,1);
    if(_sid==SPELL.MULTISHOT)out+="\nZusatzgeschosse: "+string(s.extra_projectiles);
    if(_sid==SPELL.POWER_UP || _sid==SPELL.MOVE_SPEED || _sid==SPELL.HASTE)out+="\nPassiver Modifikator; Schaden zaehlt beim Angriff.";
    return out;
}
