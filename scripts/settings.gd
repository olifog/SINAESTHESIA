extends Control

const RESOLUTIONS = [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

@onready var sensitivity_slider: HSlider = $SettingsContainer/MarginContainer/VBoxContainer/SensitivityContainer/HSlider
@onready var volume_slider: HSlider = $SettingsContainer/MarginContainer/VBoxContainer/VolumeContainer/HSlider
@onready var resolution_option: OptionButton = $SettingsContainer/MarginContainer/VBoxContainer/ResolutionContainer/OptionButton
@onready var fullscreen_check: CheckButton = $SettingsContainer/MarginContainer/VBoxContainer/FullscreenContainer/CheckButton

func _ready() -> void:
	# Set initial sensitivity value
	sensitivity_slider.value = GlobalSettings.mouse_sensitivity
	volume_slider.value = GlobalSettings.music_volume
	
	# Setup resolution options
	for resolution in RESOLUTIONS:
		resolution_option.add_item("%dx%d" % [resolution.x, resolution.y])
	
	# Set current resolution and fullscreen state
	var current_window = get_window()
	resolution_option.selected = RESOLUTIONS.find(current_window.size)
	fullscreen_check.button_pressed = current_window.mode == Window.MODE_FULLSCREEN

func _on_sensitivity_changed(value: float) -> void:
	GlobalSettings.mouse_sensitivity = value

func _on_volume_changed(value: float) -> void:
	GlobalSettings.music_volume = value

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
	MusicController.play_button_sound()
	get_window().mode = Window.MODE_FULLSCREEN if button_pressed else Window.MODE_WINDOWED
	
func _on_back_button_pressed() -> void:
	MusicController.play_button_sound()
	# Optionally save settings when leaving
	# GlobalSettings.save_settings()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
