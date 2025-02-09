extends Node

signal mouse_sensitivity_changed(new_value: float)
signal sense_sin_assignment_changed(sense: int, sin: int)
signal kills_changed(new_kills: int)

enum Sense {
	SIGHT,
	HEARING,
	TOUCH,
}

enum Sin {
	NONE,
	GREED,
	WRATH,
	SLOTH
}

# Sin colors
const SIN_COLORS = {
	Sin.NONE: Color(0.5, 0.5, 0.5),  # Gray
	Sin.GREED: Color(1.0, 0.84, 0),   # Gold
	Sin.WRATH: Color(0.8, 0, 0),      # Red
	Sin.SLOTH: Color(0, 0.4, 0.8)     # Blue
}

var mouse_sensitivity: float = 0.5:
	set(value):
		mouse_sensitivity = value
		mouse_sensitivity_changed.emit(value)

# Add kill counter
var kills: int = 0:
	set(value):
		kills = value
		kills_changed.emit(value)

# Dictionary to store which sin is assigned to which sense
var sense_sin_assignments = {
	Sense.SIGHT: Sin.WRATH,
	Sense.HEARING: Sin.SLOTH,
	Sense.TOUCH: Sin.GREED,
}

func assign_sin_to_sense(sense: Sense, sin: Sin) -> void:
	sense_sin_assignments[sense] = sin
	sense_sin_assignment_changed.emit(sense, sin)

func get_sin_for_sense(sense: Sense) -> Sin:
	return sense_sin_assignments[sense]

func get_color_for_sense(sense: Sense) -> Color:
	return SIN_COLORS[sense_sin_assignments[sense]]

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
