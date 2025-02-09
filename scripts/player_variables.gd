extends Node

signal mouse_sensitivity_changed(new_value: float)
signal music_volume_changed(new_value: float)
signal sense_sin_assignment_changed(sense: int, sin: int)
signal kills_changed(new_kills: int)
signal souls_changed(new_souls: int)
signal sin_level_changed(sin: int, new_level: int)

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

# Sin upgrade costs (exponential scaling)
const BASE_UPGRADE_COST = 10
const UPGRADE_COST_MULTIPLIER = 2.0

var mouse_sensitivity: float = 0.5:
	set(value):
		mouse_sensitivity = value
		mouse_sensitivity_changed.emit(value)

var music_volume: float = 0.3:
	set(value):
		music_volume = value
		music_volume_changed.emit(value)

# Add kill counter (resets each run)
var kills: int = 0:
	set(value):
		kills = value
		kills_changed.emit(value)

# Add souls (persistent between runs)
var souls: int = 0:
	set(value):
		souls = value
		souls_changed.emit(value)

# Dictionary to store which sin is assigned to which sense
var sense_sin_assignments = {
	Sense.SIGHT: Sin.WRATH,
	Sense.HEARING: Sin.GREED,
	Sense.TOUCH: Sin.SLOTH,
}

# Dictionary to store sin levels
var sin_levels = {
	Sin.GREED: 0,
	Sin.WRATH: 0,
	Sin.SLOTH: 0
}

func assign_sin_to_sense(sense: Sense, sin: Sin) -> void:
	sense_sin_assignments[sense] = sin
	sense_sin_assignment_changed.emit(sense, sin)

func get_sin_for_sense(sense: Sense) -> Sin:
	return sense_sin_assignments[sense]

func get_color_for_sense(sense: Sense) -> Color:
	return SIN_COLORS[sense_sin_assignments[sense]]

func get_sin_level(sin: Sin) -> int:
	return sin_levels[sin]

func get_sin_upgrade_cost(sin: Sin) -> int:
	return int(BASE_UPGRADE_COST * pow(UPGRADE_COST_MULTIPLIER, sin_levels[sin]))

func can_upgrade_sin(sin: Sin) -> bool:
	return souls >= get_sin_upgrade_cost(sin)

func upgrade_sin(sin: Sin) -> bool:
	var cost = get_sin_upgrade_cost(sin)
	if souls >= cost:
		souls -= cost
		sin_levels[sin] += 1
		sin_level_changed.emit(sin, sin_levels[sin])
		return true
	return false

func convert_kills_to_souls() -> void:
	souls += kills
	kills = 0

func _ready() -> void:
	load_game()

# Save/Load functions for persistence
func save_game() -> void:
	pass
	# var save_data = {
	# 	"mouse_sensitivity": mouse_sensitivity,
	# 	"souls": souls,
	# 	"sin_levels": sin_levels
	# }
	# var file = FileAccess.open("user://game.save", FileAccess.WRITE)
	# file.store_var(save_data)

func load_game() -> void:
	pass
	# if FileAccess.file_exists("user://game.save"):
	# 	var file = FileAccess.open("user://game.save", FileAccess.READ)
	# 	var save_data = file.get_var()
	# 	mouse_sensitivity = save_data.get("mouse_sensitivity", 0.5)
	# 	souls = save_data.get("souls", 0)
	# 	sin_levels = save_data.get("sin_levels", {Sin.GREED: 0, Sin.WRATH: 0, Sin.SLOTH: 0})
