/// Runtime data and previews resolve the same central catalog.
function GetSpellData(_id,_level=undefined) {
 if(is_string(_id)){var sid=name_to_spell_id(_id);return is_undefined(sid) ? undefined : spell_values(sid,is_undefined(_level) ? 1 : _level);}
 var data=spell_catalog(),index_value=_id>=201 ? 18+_id-201 : _id-101;
 if(index_value>=0 && index_value<array_length(data) && data[index_value].id==_id)return data[index_value];
 return undefined;
}
