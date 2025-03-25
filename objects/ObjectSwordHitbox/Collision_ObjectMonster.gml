// Überprüfen, ob das Monster existiert und die Variable `hp` hat
if (variable_instance_exists(other.id, "hp")) {
    other.hp -= 100; // Reduziert die HP des Monsters um 10

 
}

// Optional: Die Hitbox entfernen, wenn sie nur für einen Angriff aktiv sein soll
instance_destroy();

