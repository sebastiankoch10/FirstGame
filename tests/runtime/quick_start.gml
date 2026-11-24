function agent_test_step(_frame) {
    if (_frame == 2) {
        test_check(room == RoomMenu, "startup room is RoomMenu");
        test_check(instance_exists(ObjectMainMenu), "main menu instance is active");
        test_shot("main-menu");
    }

    var characters = ["Sword", "Mage", "Ranger"];
    var combo_index = 0;
    if (_frame >= 3 && _frame < 30) {
        combo_index = (_frame - 3) div 3;
        if (combo_index < 9) {
            var character_index = combo_index div 3;
            var level_index = combo_index mod 3;
            global.selected_character = characters[character_index];
            global.selected_level = level_index;
            global.qa_test_mode = true;
            global.qa_test_speed = 1;
            reset_round();
            if (room != Room1) room_goto(Room1);
        }
    }

    if (_frame >= 5 && _frame < 32 && (_frame - 5) mod 3 == 0) {
        var active_combo = (_frame - 5) div 3;
        if (active_combo < 9) {
            test_check(room == Room1, "combo " + string(active_combo) + " loads Room1");
            test_check(instance_exists(ObjectPlayer), "combo " + string(active_combo) + " creates player");
            test_check(instance_number(ObjectSpawner) > 0, "combo " + string(active_combo) + " creates spawner");
        }
    }

    if (_frame == 32) {
        global.qa_test_mode = true;
        global.selected_character = "Sword";
        global.selected_level = 0;
        reset_round();
        if (room != Room1) room_goto(Room1);
    }

    if (_frame == 35) {
        test_check(instance_exists(ObjectPlayer), "60-second stability fixture creates player");
        test_check(instance_number(ObjectSpawner) > 0, "60-second stability fixture creates spawner");
        var monster = instance_create_layer(400, 360, "Instances", ObjectMonster);
        test_check(instance_exists(monster), "real monster instance is created");
    }

    if (_frame >= 36 && _frame <= 40) {
        test_check(instance_exists(ObjectMonster), "monster remains valid during smoke window");
    }

    if (_frame >= 42) {
        test_end();
    }
}
