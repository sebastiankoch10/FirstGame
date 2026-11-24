/// Independent reproducible RNG; particle/audio randomness cannot change a prepared offer sequence.
function spell_choice_random(_limit) {
    global.choice_rng=(global.choice_rng*16807) mod 2147483647;
    return floor(global.choice_rng/2147483647*max(1,_limit));
}
function spell_active_equipped(_sid) {
    for(var i=0;i<array_length(global.active_spells);i++)if(global.active_spells[i].id==_sid && global.active_spells[i].level>0)return true;
    return false;
}
function spell_passive_eligible(_definition) {
    if(!is_struct(_definition))return false;
    if(_definition.type!=SPELL_TYPE.PASSIVE)return true;
    var any=variable_struct_exists(_definition,"requirements_any") ? _definition.requirements_any : [];
    var required_all=variable_struct_exists(_definition,"requirements_all") ? _definition.requirements_all : [];
    var has_any=array_length(any)==0;
    for(var i=0;i<array_length(any);i++)if(spell_active_equipped(any[i]))has_any=true;
    if(!has_any)return false;
    for(var i=0;i<array_length(required_all);i++)if(!spell_active_equipped(required_all[i]))return false;
    return true;
}
function spell_requirement_text(_definition) {
    if(!is_struct(_definition) || _definition.type!=SPELL_TYPE.PASSIVE)return "";
    var any=variable_struct_exists(_definition,"requirements_any") ? _definition.requirements_any : [];
    var required_all=variable_struct_exists(_definition,"requirements_all") ? _definition.requirements_all : [];
    var result="";
    if(array_length(any)>0){result="Benoetigt mindestens einen aktiven Zauber: ";for(var i=0;i<array_length(any);i++){var d=GetSpellData(any[i]);if(i>0)result+=", ";result+=d.name;}}
    if(array_length(required_all)>0){if(result!="")result+="\n";result+="Benoetigt alle: ";for(var i=0;i<array_length(required_all);i++){var d=GetSpellData(required_all[i]);if(i>0)result+=", ";result+=d.name;}}
    return result;
}
function spell_choices_v2(_source) {
    if(_source=="start")return;
    var upgrades=[],fresh=[],catalog=spell_catalog();
    for(var i=0;i<array_length(catalog);i++) {
        var d=catalog[i];if(!d.implemented || !spell_passive_eligible(d))continue;
        var lv=spell_level(d.id),list=d.type==SPELL_TYPE.ACTIVE ? global.active_spells : global.passive_spells;
        if(lv>=9 || (lv==0 && array_length(list)>=6))continue;
        var option={id:d.id,name:d.name,type:d.type==1 ? "active" : "passive",level:lv};
        if(lv>0)array_push(upgrades,option);else array_push(fresh,option);
    }
    var options=[];
    // One owned upgrade and one new option when both exist; the third favours investment 65/35.
    if(array_length(upgrades)>0){var n=spell_choice_random(array_length(upgrades));array_push(options,upgrades[n]);array_delete(upgrades,n,1);}
    if(array_length(fresh)>0){var n=spell_choice_random(array_length(fresh));array_push(options,fresh[n]);array_delete(fresh,n,1);}
    while(array_length(options)<3 && array_length(upgrades)+array_length(fresh)>0) {
        var use_upgrade=array_length(upgrades)>0 && (array_length(fresh)==0 || spell_choice_random(100)<65);
        var pool=use_upgrade ? upgrades : fresh,n=spell_choice_random(array_length(pool));array_push(options,pool[n]);
        if(use_upgrade)array_delete(upgrades,n,1);else array_delete(fresh,n,1);
    }
    // An empty active build always has at least one actual attack to choose from.
    if(array_length(global.active_spells)==0 && array_length(options)>0) {
        var has_active=false;for(var i=0;i<array_length(options);i++)if(options[i].type=="active")has_active=true;
        if(!has_active)for(var i=0;i<array_length(catalog);i++)if(catalog[i].type==1 && catalog[i].implemented){options[array_length(options)-1]={id:catalog[i].id,name:catalog[i].name,type:"active",level:0};break;}
    }
    // Deterministic shuffle prevents a fixed card position for upgrades.
    for(var i=array_length(options)-1;i>0;i--){var j=spell_choice_random(i+1),temp=options[i];options[i]=options[j];options[j]=temp;}
    if(array_length(options)==0)options=[{id:-1,name:"Build vollstaendig",type:"info",level:9}];
    global.spell_options=options;global.selected_spell_index=0;global.choice_open=false;global.choice_mouse_armed=false;
    global.levelup_active=_source=="levelup";global.chest_collected=_source=="chest";global.game_paused=true;
}
function spell_type_color(_sid) {var d=GetSpellData(_sid);return is_struct(d) && d.type==2 ? make_color_rgb(191,132,242) : make_color_rgb(87,211,242);}
function spell_choice_badge(_option) {return _option.type=="info" ? "MAXIMUM" : (_option.level>0 ? "UPGRADE" : "NEU");}
