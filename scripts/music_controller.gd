extends Node

@onready var music_player = AudioStreamPlayer.new()
@onready var button_player = AudioStreamPlayer.new()
@onready var laser_player = AudioStreamPlayer.new()

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
	
	# Connect to volume changes
	GlobalSettings.music_volume_changed.connect(_on_music_volume_changed)
	
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
	
	# Enable looping and start playing
	music_player.finished.connect(func(): music_player.play())
	music_player.play()

func _on_music_volume_changed(new_volume: float) -> void:
	music_player.volume_db = linear_to_db(new_volume)
	button_player.volume_db = linear_to_db(new_volume)
	laser_player.volume_db = linear_to_db(new_volume) 