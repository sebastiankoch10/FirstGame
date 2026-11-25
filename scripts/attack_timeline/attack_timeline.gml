/// S1 Attack Timeline (docs/Design/Technische Architektur.md 4.1).
/// An attack is a list of events on ONE clock of its owner. Gameplay (hitboxes), body poses and effects read the
/// same events, so pose, contact and damage cannot drift apart (G1).
/// Event times use the owner's clock unit: player weapons count 60 Hz steps scaled by haste; boss hazards use
/// seconds on v2_clock (bv2_*). Events must be sorted by t.
/// Event kinds: "windup" (a stage begins: aim, body pose), "hitbox_on" (contact), "pose" (visual only), "end".
function atl_definitions() {
    static defs = {
        // Swordsman: one automatic attack is a three-hit chain. Values are the former fixed grid
        // [0,4,16,22,34,42,56] with the old per-stage numbers; frame keys replace master_sword_frame's constants.
        sword_chain: {length: 56, events: [
            {t: 0,  ev: "windup", stage: 1, frame: 0, dur: 16},
            {t: 4,  ev: "hitbox_on", stage: 1, frame: 1, mult: .5, radius: 116, span: 58, life: 10, sparks: 6, sweep: 1, light_r: 105, light_a: .25, finisher: false},
            {t: 16, ev: "windup", stage: 2, frame: 0, dur: 18},
            {t: 22, ev: "hitbox_on", stage: 2, frame: 1, mult: .6, radius: 116, span: 58, life: 10, sparks: 6, sweep: -1, light_r: 105, light_a: .25, finisher: false},
            {t: 34, ev: "windup", stage: 3, frame: 0, dur: 22},
            {t: 42, ev: "hitbox_on", stage: 3, frame: 1, mult: .9, radius: 130, span: 70, life: 10, sparks: 10, sweep: 1, light_r: 160, light_a: .55, finisher: true},
            {t: 50, ev: "pose", stage: 3, frame: 2},
            {t: 56, ev: "end"}
        ]},
        // Class weapons (Arkanistin, Waldlaeufer): one timeline per combo step. "windup" sets stage and body
        // duration, "release" fires the shot; the countdown class_release runs to the release time.
        mage_1: atl_step(1, 30, 12), mage_2: atl_step(2, 30, 12), mage_3: atl_step(3, 30, 12), mage_4: atl_step(4, 44, 22),
        ranger_light: atl_step(1, 14, 4), ranger_heavy: atl_step(2, 14, 6), ranger_finisher: atl_step(3, 28, 10)
    };
    return defs;
}
function atl_get(_name) {return atl_definitions()[$ _name];}
/// Two-event timeline of one ranged combo step: windup (stage, body duration) and release.
function atl_step(_stage, _dur, _release) {
    return {length: _dur, events: [{t: 0, ev: "windup", stage: _stage, frame: 0, dur: _dur}, {t: _release, ev: "release", stage: _stage}]};
}
/// True when the event at _cursor is due on the owner's clock.
function atl_due(_tl, _cursor, _clock) {return _cursor < array_length(_tl.events) && _clock >= _tl.events[_cursor].t;}
/// Body pose frame of a stage at a clock time: the last frame key of that stage at or before _clock (0 before any).
function atl_frame(_tl, _stage, _clock) {
    var f = 0, ev = _tl.events, n = array_length(ev);
    for (var i = 0; i < n; i++) {
        var e = ev[i];
        if (e.t > _clock) break;
        if (variable_struct_exists(e, "stage") && e.stage == _stage && variable_struct_exists(e, "frame")) f = e.frame;
    }
    return f;
}
/// Time of the first event of a kind (optionally of one stage); -1 if none. For tests and tools.
function atl_time(_tl, _kind, _stage = -1) {
    var ev = _tl.events;
    for (var i = 0; i < array_length(ev); i++) if (ev[i].ev == _kind && (_stage < 0 || (variable_struct_exists(ev[i], "stage") && ev[i].stage == _stage))) return ev[i].t;
    return -1;
}
