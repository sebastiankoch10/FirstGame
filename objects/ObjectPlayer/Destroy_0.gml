if (variable_instance_exists(id, "camera") && camera >= 0) {
    camera_destroy(camera);
}
if (variable_global_exists("player") && global.player == id) {
    global.player = noone;
}
