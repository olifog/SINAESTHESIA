extends Control

const ICON_SIZE = Vector2(64, 64)
const ICON_SPACING = 10
const GREEK_SINS = {
	GlobalSettings.Sense.SIGHT: "Ὑπερηφανία",  # Pride
	GlobalSettings.Sense.HEARING: "Ὀργή",      # Wrath
	GlobalSettings.Sense.TOUCH: "Πορνεία",     # Lust
}

@onready var sense_containers: Array[TextureRect] = []
@onready var sin_labels: Array[Label] = []
@onready var kill_counter_container = HBoxContainer.new()
@onready var kill_icon = TextureRect.new()
@onready var kill_label = Label.new()

# Preload sense icons and skull animation
@onready var sense_icons = {
	GlobalSettings.Sense.SIGHT: preload("res://assets/senses/sight.png"),
	GlobalSettings.Sense.HEARING: preload("res://assets/senses/hearing.png"),
	GlobalSettings.Sense.TOUCH: preload("res://assets/senses/touch.png"),
}
@onready var skull_animation = preload("res://assets/skull_frames/skull_animation.tres")

func _ready() -> void:
	print("ready")
	# Setup kill counter
	setup_kill_counter()
	
	# Create container for vertical layout
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(20, 20)  # Padding from screen edge
	vbox.custom_minimum_size = Vector2(ICON_SIZE.x + 200, (ICON_SIZE.y + ICON_SPACING) * 5)  # Increased width for text
	add_child(vbox)
	
	# Create TextureRect and Label for each sense
	print("HEYYYY")
	for sense in GlobalSettings.Sense.values():
		print(sense)
		# Create horizontal container for icon and text
		var hbox = HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(ICON_SIZE.x + 200, ICON_SIZE.y)
		
		# Create icon container
		var container = TextureRect.new()
		container.custom_minimum_size = ICON_SIZE
		container.expand_mode = TextureRect.SIZE_EXPAND_FILL
		container.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		container.texture = sense_icons[sense]
		
		# Add monochrome shader
		var shader = preload("res://shaders/monochrome.gdshader")
		var material = ShaderMaterial.new()
		material.shader = shader
		container.material = material
		
		# Create sin label
		var label = Label.new()
		label.text = GREEK_SINS[sense]
		label.add_theme_font_size_override("font_size", 24)
		label.modulate = Color(1, 1, 1, 1)  # Pure white, fully opaque
		
		# Add outline effect
		label.add_theme_constant_override("outline_size", 12)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))  # Black outline
		
		# Adjust letter spacing to be tighter
		label.add_theme_constant_override("letter_spacing", -16)  # Negative value makes letters closer together
		
		# Add to horizontal container
		hbox.add_child(container)
		hbox.add_child(label)
		
		vbox.add_child(hbox)
		sense_containers.push_back(container)
		sin_labels.push_back(label)
		
		# Add spacing between rows
		if sense < GlobalSettings.Sense.size() - 1:
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(0, ICON_SPACING)
			vbox.add_child(spacer)
	
	# Connect to sin assignment changes
	GlobalSettings.sense_sin_assignment_changed.connect(_on_sense_sin_assignment_changed)
	
	# Connect to kill counter changes
	GlobalSettings.kills_changed.connect(_on_kills_changed)
	
	# Initialize colors
	for sense in GlobalSettings.Sense.values():
		_update_sense_color(sense)

func setup_kill_counter() -> void:
	# Create a Control node for top-right positioning
	var position_control = Control.new()
	position_control.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	position_control.position = Vector2(-300, 20)  # Offset from right edge
	add_child(position_control)
	
	# Add container to the position control
	kill_counter_container.size_flags_horizontal = Control.SIZE_SHRINK_END
	position_control.add_child(kill_counter_container)
	
	# Setup skull icon
	kill_icon.custom_minimum_size = Vector2(128, 128)
	kill_icon.expand_mode = TextureRect.SIZE_EXPAND_FILL
	kill_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	kill_icon.texture = skull_animation
	
	# Add some spacing between icon and label
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(2, 0)
	
	# Setup kill count label
	kill_label.text = "x " + str(GlobalSettings.kills)
	kill_label.add_theme_font_override("font", preload("res://assets/fonts/cloister_black/CloisterBlack.ttf"))
	kill_label.add_theme_font_size_override("font_size", 48)  # Made bigger to match the gothic style
	kill_label.add_theme_constant_override("outline_size", 12)
	kill_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	kill_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Add all elements to container
	kill_counter_container.add_child(kill_icon)
	kill_counter_container.add_child(spacer)
	kill_counter_container.add_child(kill_label)

func _update_sense_color(sense: GlobalSettings.Sense) -> void:
	var color = GlobalSettings.get_color_for_sense(sense)
	sense_containers[sense].material.set_shader_parameter("tint_color", color)

func _on_sense_sin_assignment_changed(sense: GlobalSettings.Sense, _sin: GlobalSettings.Sin) -> void:
	_update_sense_color(sense)

func _on_kills_changed(new_kills: int) -> void:
	kill_label.text = "x " + str(new_kills)
