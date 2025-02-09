extends Control

# Singleton instance
static var instance: Control = null

var dragged_sin: Label = null
var original_parent: Container = null
var original_position: Vector2 = Vector2.ZERO

func _init() -> void:
	# Ensure only one instance exists
	if instance != null:
		queue_free()
		return
	instance = self

func _ready() -> void:
	# Make this menu process even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Start hidden
	hide()
	# Make it semi-transparent
	modulate.a = 0.9
	
	# Create sin labels
	_create_sin_labels()
	
	# Initialize sin assignments
	_update_sin_positions()
	
	# Connect to sin assignment changes
	GlobalSettings.sense_sin_assignment_changed.connect(_on_sin_assignment_changed)

func _create_sin_labels() -> void:
	# Create a temporary container to hold all sin labels initially
	var temp_container = Control.new()
	add_child(temp_container)
	
	# Create a label for each sin (except NONE)
	for sin in GlobalSettings.Sin.values():
		if sin == GlobalSettings.Sin.NONE:
			continue
			
		var label = Label.new()
		label.custom_minimum_size = Vector2(200, 50)
		label.theme = preload("res://assets/themes/menu_button_theme.tres")
		label.add_theme_font_override("font", preload("res://assets/fonts/cloister_black/CloisterBlack.ttf"))
		label.add_theme_font_size_override("font_size", 48)
		label.text = GlobalSettings.Sin.keys()[sin].capitalize()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_to_group("sin_labels")
		label.set_meta("sin", sin)
		
		# Set the color from GlobalSettings
		label.add_theme_color_override("font_color", GlobalSettings.SIN_COLORS[sin])
		
		# Add to temporary container
		temp_container.add_child(label)
		
	# Now that all labels are created, update their positions
	_update_sin_positions()
	
	# Remove the temporary container (but not its children, as they've been moved)
	temp_container.queue_free()

func _update_sin_positions() -> void:
	for sense in GlobalSettings.Sense.values():
		var slot = get_node("Panel/MarginContainer/HBoxContainer/SinSlots/Slot%d" % sense)
		var sin = GlobalSettings.get_sin_for_sense(sense)
		
		# Find the sin label and move it to this slot
		var sin_label = _find_sin_label(sin)
		if sin_label and sin_label.get_parent() != slot:
			if sin_label.get_parent():
				sin_label.get_parent().remove_child(sin_label)
			slot.add_child(sin_label)

func _find_sin_label(sin: GlobalSettings.Sin) -> Label:
	for label in get_tree().get_nodes_in_group("sin_labels"):
		if label.get_meta("sin") == sin:
			return label
	return null

func _on_sin_assignment_changed(_sense: GlobalSettings.Sense, _sin: GlobalSettings.Sin) -> void:
	_update_sin_positions()

func _get_slot_at_position(position: Vector2) -> Container:
	# Check each slot to see if the position is within its rect
	for sense in GlobalSettings.Sense.values():
		var slot = get_node("Panel/MarginContainer/HBoxContainer/SinSlots/Slot%d" % sense)
		if slot.get_global_rect().has_point(position):
			return slot
	return null

func _swap_sins(slot1: Container, slot2: Container) -> void:
	if slot1 == slot2:
		return
		
	# Get the senses these slots belong to
	var sense1 = int(slot1.name.substr(4))  # "Slot0" -> 0
	var sense2 = int(slot2.name.substr(4))  # "Slot1" -> 1
	
	# Get the sins
	var sin1_enum = GlobalSettings.Sin.NONE
	var sin2_enum = GlobalSettings.Sin.NONE
	
	if slot1.get_child_count() > 0:
		sin1_enum = slot1.get_child(0).get_meta("sin")
	if slot2.get_child_count() > 0:
		sin2_enum = slot2.get_child(0).get_meta("sin")
	
	# Assign the sins to their new senses
	GlobalSettings.assign_sin_to_sense(sense1, sin2_enum)
	GlobalSettings.assign_sin_to_sense(sense2, sin1_enum)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_focus_next"):  # Tab key
		if visible:
			hide()
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			show()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start drag
				var position = event.global_position
				for label in get_tree().get_nodes_in_group("sin_labels"):
					if label.get_global_rect().has_point(position):
						dragged_sin = label
						original_parent = label.get_parent()
						original_position = label.position
						# Move label to be directly under mouse
						label.global_position = position - label.size / 2
						break
			else:
				# End drag
				if dragged_sin:
					var target_slot = _get_slot_at_position(event.global_position)
					if target_slot and target_slot != original_parent:
						_swap_sins(original_parent, target_slot)
					else:
						# Return to original position if not dropped on a valid slot
						dragged_sin.position = original_position
					
					dragged_sin = null
					original_parent = null
	
	elif event is InputEventMouseMotion:
		# Update dragged sin position
		if dragged_sin:
			dragged_sin.global_position = event.global_position - dragged_sin.size / 2 
