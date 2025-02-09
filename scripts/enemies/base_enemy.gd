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
@export var max_health: int = 100  # Base health value
@export var death_animation_duration: float = 1.0  # Duration of death animation in seconds
@export var nav_update_threshold: float = 2.0  # Distance player must move before updating path
@export var nav_update_group: int = 0  # Which update group this enemy belongs to (0-3)
@export var stat_variation: float = 0.8  # How much stats can vary (20% by default)

var player: Node3D
var can_attack: bool = true
var current_speed: float = 0.0
var time_offset: float  # For randomizing sine wave
var current_health: int
var is_dying: bool = false
var death_animation_time: float = 0.0
var original_modulate: Color
var _last_player_pos: Vector3
var _update_timer: float = 0.0
var _update_interval: float  # Will be set in _ready

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D

func _ready() -> void:
	randomize_stats()
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_warning("Enemy: No player found in scene!")
	time_offset = randf() * 10.0  # Random offset for sine wave
	current_health = max_health
	
	if sprite:
		original_modulate = sprite.modulate
	
	# Set up navigation update timing
	nav_update_group = randi() % 10  # Randomly assign to one of 10 groups
	_update_interval = 0.5  # Update every 0.5 seconds
	_update_timer = randf() * _update_interval  # Random initial offset
	
	_last_player_pos = player.neck.global_transform.origin
	nav_agent.target_position = _last_player_pos
	
	_on_ready()  # Virtual method for child classes

func randomize_stats() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Helper function to apply random variation
	var vary = func(base_value: float) -> float:
		var variation = base_value * stat_variation
		return base_value + rng.randf_range(-variation, variation)
	
	# Apply variations to stats
	acceleration = vary.call(acceleration)
	max_speed = vary.call(max_speed)
	min_speed = vary.call(min_speed)
	rotation_speed = vary.call(rotation_speed)
	attack_range = vary.call(attack_range)
	attack_cooldown = vary.call(attack_cooldown)
	damage = int(vary.call(float(damage)))
	damage_delay = vary.call(damage_delay)
	damage_check_range = vary.call(damage_check_range)
	wobble_frequency = vary.call(wobble_frequency)
	wobble_amplitude = vary.call(wobble_amplitude)
	max_health = int(vary.call(float(max_health)))
	
	# Ensure stats stay within reasonable bounds
	max_speed = maxf(max_speed, min_speed + 2.0)  # Max speed should be notably higher than min
	attack_cooldown = maxf(attack_cooldown, 0.5)  # Prevent too rapid attacks
	damage = maxi(damage, 1)  # Ensure at least 1 damage
	max_health = maxi(max_health, 20)  # Ensure reasonable minimum health
	damage_delay = clampf(damage_delay, 0.1, 0.5)  # Keep damage delay in reasonable range

func _physics_process(delta: float) -> void:
	if is_dying:
		_process_death_animation(delta)
		return
		
	if not player:
		return
		
	handle_movement(delta)
	handle_rotation(delta)
	handle_attack()

func handle_movement(delta: float) -> void:
	# Don't move while attacking
	if is_attacking():
		return
	
	# Update navigation path on a fixed interval based on group
	_update_timer += delta
	if _update_timer >= _update_interval:
		_update_timer = 0.0
		var current_player_pos = player.neck.global_transform.origin
		if current_player_pos.distance_to(_last_player_pos) > nav_update_threshold:
			nav_agent.target_position = current_player_pos
			_last_player_pos = current_player_pos
	
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

func take_damage(amount: int) -> void:
	if is_dying:
		return
		
	current_health -= amount
	
	# Flash the enemy red briefly
	if sprite:
		sprite.modulate = Color(1, 0.3, 0.3, 1.0)  # More subtle red tint
		var timer = get_tree().create_timer(0.1)
		timer.timeout.connect(func(): sprite.modulate = original_modulate)
	
	if current_health <= 0:
		start_death()

func start_death() -> void:
	is_dying = true
	death_animation_time = 0.0
	
	# Increment kill counter
	GlobalSettings.kills += 1
	
	# Disable collision and navigation
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	nav_agent.set_navigation_layer_value(1, false)
	
	# Stop any current animation and switch to idle if it exists
	if sprite and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")

func _process_death_animation(delta: float) -> void:
	death_animation_time += delta
	var progress = death_animation_time / death_animation_duration
	
	if progress >= 1.0:
		queue_free()
		return
	
	if sprite:
		# Fade out
		sprite.modulate.a = 1.0 - progress
		
		# Float upward
		sprite.position.y += delta * 50.0  # Faster upward movement
		
		# Add some wobble
		sprite.position.x = sin(progress * PI * 4) * 20.0 * (1.0 - progress)
		
		# Scale effect
		var scale_factor = 1.0 + (progress * 0.5)  # Grow slightly before disappearing
		if progress > 0.7:  # Start shrinking near the end
			scale_factor = (1.0 - progress) * 3.0
		sprite.scale = Vector3.ONE * scale_factor

# Virtual methods to be implemented by child classes
func _on_ready() -> void:
	pass

func is_attacking() -> bool:
	return false

func update_animation(_direction: Vector3) -> void:
	pass

func start_attack_animation() -> void:
	pass 
