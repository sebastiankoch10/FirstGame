// Lebensdauer der Hitbox verwalten
lifetime -= 1;

if (lifetime <= 0) {
    instance_destroy(); // Hitbox zerstören, wenn Lebensdauer abgelaufen
}
