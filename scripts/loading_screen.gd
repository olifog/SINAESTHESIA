extends Control

var target_scene = "res://scenes/3DLevel.tscn"

func _ready() -> void:
	# Start loading the scene in the background
	ResourceLoader.load_threaded_request(target_scene)

func _process(_delta: float) -> void:
	# Check the load status
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(target_scene, progress)
	
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			# Loading is done, change to the scene
			var scene = ResourceLoader.load_threaded_get(target_scene)
			get_tree().change_scene_to_packed(scene)
		ResourceLoader.THREAD_LOAD_FAILED:
			push_error("Failed to load scene: " + target_scene)
			# Fallback to direct scene change
			get_tree().change_scene_to_file(target_scene) 
