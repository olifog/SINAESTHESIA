@tool
extends EditorScript

func _run():
	var animated_texture = AnimatedTexture.new()
	animated_texture.frames = 24
	
	# Load and set each frame
	for i in range(24):
		var frame_path = "res://assets/skull_frames/frame_%03d.png" % i
		var frame = load(frame_path)
		if frame:
			animated_texture.set_frame_texture(i, frame)
	
	animated_texture.fps = 20
	
	# Save the animated texture
	var err = ResourceSaver.save(animated_texture, "res://assets/skull_frames/skull_animation.tres")
	if err == OK:
		print("Successfully saved animated texture!")
	else:
		print("Failed to save animated texture: ", err) 
