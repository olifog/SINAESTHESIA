extends Node3D

@export var shopUI : ColorRect;
@export var label : RichTextLabel;

func _on_static_body_3d_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if (event.is_action_pressed("shoot")):
		shopUI.visible = !shopUI.visible;
		if (shopUI.visible):
			label.text = "Close"
		else:
			label.text = "Buy"
