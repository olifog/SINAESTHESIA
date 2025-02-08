extends Node

signal mouse_sensitivity_changed(new_value: float)

var mouse_sensitivity: float = 0.5:
	set(value):
		mouse_sensitivity = value
		mouse_sensitivity_changed.emit(value)

func _ready() -> void:
	# Initialize default settings
	pass

# Optional: Save/Load functions for persistence
func save_settings() -> void:
	var settings = {
		"mouse_sensitivity": mouse_sensitivity
	}
	var file = FileAccess.open("user://settings.save", FileAccess.WRITE)
	file.store_var(settings)

func load_settings() -> void:
	if FileAccess.file_exists("user://settings.save"):
		var file = FileAccess.open("user://settings.save", FileAccess.READ)
		var settings = file.get_var()
		mouse_sensitivity = settings.get("mouse_sensitivity", 0.5)
