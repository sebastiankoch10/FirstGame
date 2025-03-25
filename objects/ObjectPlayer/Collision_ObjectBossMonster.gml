// Collision-Event von ObjectPlayer mit ObjectMonster

// Lebenspunkte verringern
hp -= 1;




// Überprüfen, ob Adventurer zerstört werden soll
if (hp <= 0) {
    instance_destroy(); // Adventurer wird zerstört
}
