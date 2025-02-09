extends CharacterBody3D

@export var acceleration: float = 15.0  # Acceleration rate
@export var max_speed: float = 8.0  # Maximum speed
@export var min_speed: float = 2.0  # Minimum speed
@export var rotation_speed: float = 5.0
@export var attack_range: float = 1.5
@export var attack_cooldown: float = 1.0
@export var damage: int = 10  # Damage amount
@export var damage_delay: float = 0.2  # Time until damage is dealt
@export var damage_check_range: float = 2.5  # Range to check when dealing damage
@export var wobble_frequency: float = 2.0  # How fast the side-to-side motion is
@export var wobble_amplitude: float = 1.5  # How far the side-to-side motion goes
@export var allow_vertical_movement: bool = true  # Whether to allow vertical movement

var player: Node3D
var can_attack: bool = true
var current_speed: float = 0.0
var time_offset: float  # For randomizing sine wave

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_warning("Enemy: No player found in scene!")
	time_offset = randf() * 10.0  # Random offset for sine wave
	
	_on_ready()  # Virtual method for child classes

func _physics_process(delta: float) -> void:
	if not player:
		return
		
	handle_movement(delta)
	handle_rotation(delta)
	handle_attack()

func handle_movement(delta: float) -> void:
	# Don't move while attacking
	if is_attacking():
		return
	
	nav_agent.target_position = player.neck.global_transform.origin
	var next_nav_point: Vector3 = nav_agent.get_next_path_position()
	var direction: Vector3 = next_nav_point - global_transform.origin
	
	if not allow_vertical_movement:
		direction.y = 0
	direction = direction.normalized()
	
	# Calculate distance to point for speed scaling
	var distance_to_point = global_position.distance_to(next_nav_point)
	var target_speed = lerp(min_speed, max_speed, clamp(distance_to_point / 10.0, 0.0, 1.0))
	
	# Accelerate/decelerate towards target speed
	current_speed = move_toward(current_speed, target_speed, acceleration * delta)
	
	# Add sinusoidal side-to-side motion
	var time = Time.get_ticks_msec() / 1000.0 + time_offset
	
	# Calculate the right vector while keeping it horizontal
	var flat_direction = Vector3(direction.x, 0, direction.z).normalized()
	var side_direction = flat_direction.rotated(Vector3.UP, PI / 2)
	
	# Combine movement with wobble
	var final_direction = direction * current_speed + side_direction * sin(time * wobble_frequency) * wobble_amplitude
	
	velocity = velocity.move_toward(final_direction, acceleration * delta)
	move_and_slide()
	
	update_animation(direction)

func handle_rotation(delta: float) -> void:
	var look_target: Vector3 = player.neck.global_transform.origin
	# Keep the look target at the same height as the enemy for horizontal-only rotation
	look_target.y = global_transform.origin.y
	
	var temp_transform := Transform3D()
	temp_transform = temp_transform.looking_at(look_target - global_transform.origin, Vector3.UP)
	
	rotation.y = lerp_angle(rotation.y, temp_transform.basis.get_euler().y, rotation_speed * delta)

func handle_attack() -> void:
	if not can_attack:
		return
		
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player <= attack_range:
		attack()

func attack() -> void:
	can_attack = false
	start_attack_animation()
	
	# Create timer for damage window
	var damage_timer := get_tree().create_timer(damage_delay)
	damage_timer.timeout.connect(check_and_deal_damage)

func check_and_deal_damage() -> void:
	# Ensure player exists and is still in range
	if not player or not player.has_method("take_damage"):
		return
		
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player <= damage_check_range:
		player.take_damage(damage)

func finish_attack() -> void:
	# Start attack cooldown
	var timer := get_tree().create_timer(attack_cooldown)
	timer.timeout.connect(func(): can_attack = true)

# Virtual methods to be implemented by child classes
func _on_ready() -> void:
	pass

func is_attacking() -> bool:
	return false

func update_animation(_direction: Vector3) -> void:
	pass

func start_attack_animation() -> void:
	pass 
