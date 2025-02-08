class_name PauseMenu
extends Control

const RESOLUTIONS = [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

@onready var sensitivity_slider: HSlider = $SettingsPanel/VBoxContainer/MarginContainer/SettingsOptions/SensitivityContainer/HSlider
@onready var resolution_option: OptionButton = $SettingsPanel/VBoxContainer/MarginContainer/SettingsOptions/ResolutionContainer/OptionButton
@onready var fullscreen_check: CheckButton = $SettingsPanel/VBoxContainer/MarginContainer/SettingsOptions/FullscreenContainer/CheckButton

# Singleton instance
static var instance: PauseMenu = null

func _init() -> void:
	# Ensure only one instance exists
	if instance != null:
		queue_free()
		return
	instance = self

func _ready() -> void:
	# Make this pause menu process even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Start hidden
	hide()
	# Make it semi-transparent
	modulate.a = 0.9
	
	# Initialize settings
	sensitivity_slider.value = GlobalSettings.mouse_sensitivity
	
	# Setup resolution options
	for resolution in RESOLUTIONS:
		resolution_option.add_item("%dx%d" % [resolution.x, resolution.y])
	
	# Set current resolution and fullscreen state
	var current_window = get_window()
	resolution_option.selected = RESOLUTIONS.find(current_window.size)
	fullscreen_check.button_pressed = current_window.mode == Window.MODE_FULLSCREEN

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and is_visible():
		if $SettingsPanel.visible:
			$CenterContainer.show()
			$SettingsPanel.hide()
		else:
			unpause()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	if visible:
		unpause()
	else:
		pause()

func pause() -> void:
	if not visible:  # Only pause if not already paused
		get_tree().paused = true
		show()
		$CenterContainer.show()
		$SettingsPanel.hide()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func unpause() -> void:
	if visible:  # Only unpause if currently paused
		get_tree().paused = false
		hide()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_button_pressed() -> void:
	unpause()

func _on_settings_button_pressed() -> void:
	# Hide main menu and show settings panel
	$CenterContainer.hide()
	$SettingsPanel.show()

func _on_quit_button_pressed() -> void:
	# Clean up singleton instance
	instance = null
	# Hide the pause menu
	hide()
	# Unpause the game
	get_tree().paused = false
	# Set mouse mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Change scene
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	# Queue free after scene change
	queue_free()

func _on_back_to_pause_pressed() -> void:
	# Show main menu and hide settings panel
	$CenterContainer.show()
	$SettingsPanel.hide()

func _on_sensitivity_changed(value: float) -> void:
	GlobalSettings.mouse_sensitivity = value

func _on_resolution_selected(index: int) -> void:
	if index >= 0 and index < RESOLUTIONS.size():
		var window = get_window()
		window.size = RESOLUTIONS[index]
		# Center window on screen
		var screen_size = DisplayServer.screen_get_size()
		var window_size = window.size
		window.position = Vector2i(
			(screen_size.x - window_size.x) / 2,
			(screen_size.y - window_size.y) / 2
		)

func _on_fullscreen_toggled(button_pressed: bool) -> void:
	get_window().mode = Window.MODE_FULLSCREEN if button_pressed else Window.MODE_WINDOWED 
