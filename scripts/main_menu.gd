extends Control

func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/3DLevel.tscn")

func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")
	
func _on_quit_button_pressed() -> void:
	get_tree().quit()
