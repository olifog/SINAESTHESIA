extends Node3D

var object = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_window().transparent_bg = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	object = get_node("door")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_static_body_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if (event.is_action_pressed("shoot")):
		get_tree().change_scene_to_file("res://scenes/loading_screen.tscn")


func _on_static_body_3d_mouse_entered() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var door = get_node("door")
	door.rotation = door.rotation + Vector3(0.0, 0.01, 0.0)


func _on_static_body_3d_mouse_exited() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var door = get_node("door")
	door.rotation = door.rotation + Vector3(0.0, -0.01, 0.0)
