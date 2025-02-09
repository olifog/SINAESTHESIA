extends Node

const WAVE_COOLDOWN := 5.0  # Time between waves in seconds
const INITIAL_ENEMIES_PER_TYPE := 1  # How many of each enemy type to spawn in wave 1
const ENEMIES_INCREASE_PER_WAVE := 0.5  # How many more enemies to add per wave
const MAX_ENEMIES_PER_TYPE := 15  # Maximum enemies of each type that can spawn in a wave

@onready var spawn_timer := $SpawnTimer
@onready var wave_timer := $WaveTimer

var current_wave := 0
var enemies_to_spawn := []  # Queue of enemies to spawn
var spawn_points: Array = []  # Will store Node3D spawn points
var rng := RandomNumberGenerator.new()
var total_enemies_spawned := 0  # Track total enemies spawned across all waves
var profiling_enabled := false

# Preload enemy scenes
var enemy_scenes := {
	"ork": preload("res://scenes/enemies/ork_enemy.tscn"),
	"ghoul": preload("res://scenes/enemies/ghoul_enemy.tscn"),
	"gargoyle": preload("res://scenes/enemies/gargoyle_enemy.tscn")
}

func _ready() -> void:
	rng.randomize()
	# Get all spawn points
	spawn_points = get_tree().get_nodes_in_group("spawn_points")
	if spawn_points.is_empty():
		push_warning("No spawn points found in 'spawn_points' group!")
		return
		
	# Connect to player death signal
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.player_died.connect(_on_player_died)
	
	# Enable built-in performance monitor with F1
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)
	
	# Start first wave
	start_next_wave()

func _input(event: InputEvent) -> void:
	# Toggle profiling with F3
	if event.is_action_pressed("profile") or (event is InputEventKey and event.keycode == KEY_F3):
		profiling_enabled = !profiling_enabled
		if profiling_enabled:
			print("\n=== PERFORMANCE SNAPSHOT ===")
			print("Total Nodes: ", get_tree().get_node_count())
			print("Physics Objects: ", get_tree().get_nodes_in_group("physics").size())
			print_orphan_nodes()
			# Print scene tree
			print("\nScene Tree:")
			_print_scene_tree(get_tree().root)
			
			# Performance metrics
			print("\nPerformance Metrics:")
			print("FPS: ", Engine.get_frames_per_second())
			print("Physics FPS: ", Engine.physics_ticks_per_second)
			print("Process Time: ", Performance.get_monitor(Performance.TIME_PROCESS))
			print("Physics Process Time: ", Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS))
			print("Navigation Process Time: ", Performance.get_monitor(Performance.TIME_NAVIGATION_PROCESS))
			print("Object Count: ", Performance.get_monitor(Performance.OBJECT_COUNT))
			print("Object Resource Count: ", Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))
			print("=========================\n")

func _print_scene_tree(node: Node, indent: String = "") -> void:
	print(indent + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		_print_scene_tree(child, indent + "  ")

func _physics_process(_delta: float) -> void:
	if profiling_enabled and Engine.get_frames_per_second() < 30:
		print("WARNING: Low FPS detected: ", Engine.get_frames_per_second())

func start_next_wave() -> void:
	current_wave += 1
	
	# Calculate how many enemies to spawn this wave
	var enemies_this_wave: int = INITIAL_ENEMIES_PER_TYPE + int(floor(ENEMIES_INCREASE_PER_WAVE * (current_wave - 1)))
	enemies_this_wave = mini(enemies_this_wave, MAX_ENEMIES_PER_TYPE)
	
	# Queue up enemies to spawn
	enemies_to_spawn.clear()
	for enemy_type in enemy_scenes.keys():
		for i in enemies_this_wave:
			enemies_to_spawn.append(enemy_type)
	
	# Shuffle the spawn queue for variety
	enemies_to_spawn.shuffle()
	
	# Start spawning
	spawn_timer.start()
	
	# Log wave info
	print("Wave ", current_wave, " started! Spawning ", enemies_to_spawn.size(), " enemies")
	print("Total enemies spawned so far: ", total_enemies_spawned)

func spawn_enemy() -> void:
	print(enemies_to_spawn)
	if enemies_to_spawn.is_empty():
		spawn_timer.stop()
		wave_timer.start()  # Start cooldown for next wave
		return
	
	var enemy_type = enemies_to_spawn.pop_back()
	var enemy_scene = enemy_scenes[enemy_type]
	var enemy = enemy_scene.instantiate()
	
	# Pick random spawn point
	var spawn_point: Node3D = spawn_points[rng.randi() % spawn_points.size()]
	
	# Add enemy to scene
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = spawn_point.global_position
	
	# Update counter and log
	total_enemies_spawned += 1
	if total_enemies_spawned % 5 == 0:  # Log every 5 enemies to avoid spam
		print("Spawned enemy #", total_enemies_spawned)
		if profiling_enabled:
			print("Current FPS: ", Engine.get_frames_per_second())

func _on_spawn_timer_timeout() -> void:
	spawn_enemy()

func _on_wave_timer_timeout() -> void:
	start_next_wave()

func _on_player_died() -> void:
	# Stop all timers
	spawn_timer.stop()
	wave_timer.stop()
	
	# Final stats
	print("Game Over! Final Stats:")
	print("- Waves Survived: ", current_wave)
	print("- Total Enemies Spawned: ", total_enemies_spawned)
