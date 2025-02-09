extends Node

@onready var music_player = AudioStreamPlayer.new()
@onready var button_player = AudioStreamPlayer.new()
@onready var laser_player = AudioStreamPlayer.new()

const PLAYBACK_SPEEDS = {
	GlobalSettings.Sin.WRATH: 1.15,  # Faster for WRATH
	GlobalSettings.Sin.SLOTH: 0.8,  # Slower for SLOTH
	GlobalSettings.Sin.GREED: 1.0,  # Normal for GREED
	GlobalSettings.Sin.NONE: 1.0    # Normal for NONE
}

func _ready() -> void:
	add_child(music_player)
	add_child(button_player)
	add_child(laser_player)
	
	# Create a timer to delay music loading
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.5  # Half second delay
	timer.one_shot = true
	timer.timeout.connect(_load_and_play_music)
	timer.start()
	
	# Connect to volume changes and sin assignment changes
	GlobalSettings.music_volume_changed.connect(_on_music_volume_changed)
	GlobalSettings.sense_sin_assignment_changed.connect(_on_sin_assignment_changed)
	
	# Load sound effects
	var button_sound = load("res://assets/sounds/button.mp3")  # Adjust filename as needed
	var laser_sound = load("res://assets/sounds/lazer.wav")    # Adjust filename as needed
	
	if button_sound:
		button_player.stream = button_sound
		button_player.volume_db = linear_to_db(GlobalSettings.music_volume)
	
	if laser_sound:
		laser_player.stream = laser_sound
		laser_player.volume_db = linear_to_db(GlobalSettings.music_volume)

func play_button_sound() -> void:
	if not button_player.playing:
		button_player.play()

func play_laser_sound() -> void:
	if not laser_player.playing:
		laser_player.play()

func stop_laser_sound() -> void:
	laser_player.stop()

func _load_and_play_music() -> void:
	# Load the music file with error handling
	var music = load("res://assets/sounds/SINesthesia Final Draft Music.mp3")
	if music == null:
		push_error("Failed to load music file")
		return
		
	music_player.stream = music
	music_player.volume_db = linear_to_db(GlobalSettings.music_volume)
	
	# Set initial playback speed based on current sin assignment
	_update_playback_speed()
	
	# Enable looping and start playing
	music_player.finished.connect(func(): music_player.play())
	music_player.play()

func _on_music_volume_changed(new_volume: float) -> void:
	music_player.volume_db = linear_to_db(new_volume)
	button_player.volume_db = linear_to_db(new_volume)
	laser_player.volume_db = linear_to_db(new_volume)

func _on_sin_assignment_changed(sense: int, sin: int) -> void:
	if sense == GlobalSettings.Sense.HEARING:
		_update_playback_speed()

func _update_playback_speed() -> void:
	var current_hearing_sin = GlobalSettings.get_sin_for_sense(GlobalSettings.Sense.HEARING)
	var base_speed = PLAYBACK_SPEEDS[current_hearing_sin]
	
	# Apply sin level multiplier (each level adds 10% to the multiplier)
	var level_multiplier = 1.0
	if current_hearing_sin != GlobalSettings.Sin.NONE:
		var sin_level = GlobalSettings.get_sin_level(current_hearing_sin)
		level_multiplier = 1.0 + (sin_level * 0.1)
	
	# Calculate final speed with level multiplier
	var final_speed = base_speed * level_multiplier
	
	# Clamp the speed to reasonable values
	final_speed = clamp(final_speed, 0.5, 2.0)
	
	# Apply the speed
	music_player.pitch_scale = final_speed 
