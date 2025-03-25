/// @description Hier Beschreibung einfügen
// Sie können Ihren Code in diesem Editor schreiben
// Schaden an Monster zufügen
if (variable_instance_exists(other, "hp")) {
    other.hp -= 200000; // Beispiel-Schaden
    show_debug_message("Feuerball trifft Monster! Monster HP: " + string(other.hp));
}

// Feuerball zerstören
instance_destroy();
