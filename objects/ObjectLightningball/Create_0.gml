/// ObjectIceBall: Create
// Wird vom Cast/Spawner mit direction/speed/lifetime/damage bestückt
if (!variable_instance_exists(self, "direction")) direction = 0;
if (!variable_instance_exists(self, "speed"))     speed = 10;
if (!variable_instance_exists(self, "lifetime"))  lifetime = 65;
if (!variable_instance_exists(self, "damage"))    damage = 5;

image_angle = direction;
alarm[0] = lifetime;

// optionale Felder (falls vom Cast gesetzt): slow_on_hit, slow_factor, slow_time
