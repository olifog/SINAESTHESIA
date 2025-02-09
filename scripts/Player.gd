extends CharacterBody3D

# Signal declarations
signal health_changed(new_health: int)
signal player_died

# Constants
const MOVEMENT = {
	BASE_SPEED = 12.0,  # Base movement speed
	WRATH_SPEED_MULT = 1.5,  # Speed multiplier when WRATH is assigned to SIGHT
	SLOTH_SPEED_MULT = 0.7,  # Speed multiplier when SLOTH is assigned to SIGHT
	JUMP_VELOCITY = 10.0,
	GREED_JUMP_MULT = 1.4,  # Jump multiplier when GREED is assigned to SIGHT
	FAST_DOWN_MULT = 1.5,
	COYOTE_TIME = 0.15  # Time in seconds where player can still jump after leaving ground
}

const HEAD_BOB = {
	FREQUENCY = 2.0,
	AMPLITUDE = 0.08
}

const FOV = {
	BASE = 90.0,
	CHANGE = 1.5,
	WRATH_MULT = 1.2,  # FOV multiplier when WRATH is assigned to SIGHT
	SLOTH_MULT = 0.8   # FOV multiplier when SLOTH is assigned to SIGHT
}

const MAX_HEALTH := 100

const LASER = {
	DAMAGE = 4,
	COLOR = Color(0.1, 0.1, 1.0, 1.0),
	COOLDOWN = 0.05,
	BEAM_WIDTH = 0.05,  # Thinner beam
	SLOTH_DAMAGE_MULT = 1.5  # Damage multiplier when SLOTH is assigned to SIGHT
}

# Member variables
var current_health: int = MAX_HEALTH
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var t_bob: float = 0.0
var time_since_grounded: float = 0.0
var last_shot_time: float = 0.0

# Node references
@onready var neck: Node3D = $Neck
@onready var camera: Camera3D = $Neck/Camera3D
@onready var pause_menu_scene = preload("res://scenes/pause_menu.tscn")
@onready var sin_menu_scene = preload("res://scenes/sin_menu.tscn")
@onready var weapon_raycast: RayCast3D = $Neck/Camera3D/WeaponRayCast
@onready var laser_beam: GPUParticles3D = $Neck/Camera3D/LaserBeam
@onready var beam_core: MeshInstance3D = $Neck/Camera3D/BeamCore
@onready var color_overlay = $Neck/Camera3D/ColorOverlay

# Built-in virtual methods
func _ready() -> void:
	current_health = MAX_HEALTH
	health_changed.emit(current_health)
	
	# Connect to the sensitivity change signal
	GlobalSettings.mouse_sensitivity_changed.connect(_on_sensitivity_changed)
	
	# Connect to sin assignment changes
	GlobalSettings.sense_sin_assignment_changed.connect(_on_sin_assignment_changed)
	
	# Initialize pause menu if it doesn't exist
	if PauseMenu.instance == null:
		var pause_menu = pause_menu_scene.instantiate()
		get_tree().root.add_child(pause_menu)
	
	# Initialize sin menu if it doesn't exist
	if not get_tree().root.has_node("SinMenu"):
		var sin_menu = sin_menu_scene.instantiate()
		get_tree().root.add_child(sin_menu)
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Wait one frame to ensure nodes are ready
	await get_tree().process_frame
	
	# Setup laser beam particles
	_setup_laser_particles()
	
	# Initial weapon direction setup
	_update_weapon_direction()
	
	# Initialize colors
	_update_sight_color()
	_update_touch_color()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and PauseMenu.instance != null:
		PauseMenu.instance.toggle_pause()
	elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			var mouse_motion = event.relative * GlobalSettings.mouse_sensitivity
			neck.rotate_y(-mouse_motion.x * 0.002)
			camera.rotate_x(-mouse_motion.y * 0.002)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
			# Update weapon direction to match camera
			_update_weapon_direction()

func _physics_process(delta: float) -> void:
	var was_on_floor = is_on_floor()
	
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement()
	_update_camera_effects(delta)
	_handle_shooting(delta)
	move_and_slide()
	
	# Update grounded timer after move_and_slide
	if is_on_floor():
		time_since_grounded = 0.0
	else:
		time_since_grounded += delta

func _exit_tree() -> void:
	# Clean up pause menu when player is freed
	if is_instance_valid(PauseMenu.instance):
		PauseMenu.instance.queue_free()

# Movement and physics methods
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var gravity_mult = MOVEMENT.FAST_DOWN_MULT if velocity.y <= 0 else 1.0
		velocity.y -= gravity * delta * gravity_mult

func _handle_jump() -> void:
	if Input.is_action_just_pressed("ui_accept") and (is_on_floor() or time_since_grounded < MOVEMENT.COYOTE_TIME):
		var jump_velocity = MOVEMENT.JUMP_VELOCITY
		if GlobalSettings.get_sin_for_sense(GlobalSettings.Sense.SIGHT) == GlobalSettings.Sin.GREED:
			jump_velocity *= MOVEMENT.GREED_JUMP_MULT
		velocity.y = jump_velocity
		time_since_grounded = MOVEMENT.COYOTE_TIME  # Prevent double jumping by maxing out the timer

func _handle_movement() -> void:
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Back")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var speed = MOVEMENT.BASE_SPEED
	var current_sight_sin = GlobalSettings.get_sin_for_sense(GlobalSettings.Sense.SIGHT)
	if current_sight_sin == GlobalSettings.Sin.WRATH:
		speed *= MOVEMENT.WRATH_SPEED_MULT
	elif current_sight_sin == GlobalSettings.Sin.SLOTH:
		speed *= MOVEMENT.SLOTH_SPEED_MULT
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

# Camera and visual effects methods
func _update_camera_effects(delta: float) -> void:
	# Update head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _calculate_headbob(t_bob)
	
	# Update FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, MOVEMENT.BASE_SPEED * 2.0)
	var target_fov = FOV.BASE + FOV.CHANGE * velocity_clamped
	var current_sight_sin = GlobalSettings.get_sin_for_sense(GlobalSettings.Sense.SIGHT)
	if current_sight_sin == GlobalSettings.Sin.WRATH:
		target_fov *= FOV.WRATH_MULT
	elif current_sight_sin == GlobalSettings.Sin.SLOTH:
		target_fov *= FOV.SLOTH_MULT
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

func _calculate_headbob(time: float) -> Vector3:
	return Vector3(
		cos(time * HEAD_BOB.FREQUENCY / 2) * HEAD_BOB.AMPLITUDE,
		sin(time * HEAD_BOB.FREQUENCY) * HEAD_BOB.AMPLITUDE,
		0
	)

# Game logic methods
func take_damage(damage: int) -> void:
	print("Player took damage: ", damage)
	current_health = max(0, current_health - damage)
	health_changed.emit(current_health)
	
	if current_health <= 0:
		player_died.emit()

func _on_sensitivity_changed(new_value: float) -> void:
	# Handle sensitivity changes if needed
	pass

func _on_sin_assignment_changed(sense: int, sin: int) -> void:
	if sense == GlobalSettings.Sense.SIGHT:
		_update_sight_color()
	elif sense == GlobalSettings.Sense.TOUCH:
		_update_touch_color(sin)

func _update_sight_color() -> void:
	var sin_color = GlobalSettings.get_color_for_sense(GlobalSettings.Sense.SIGHT)
	# Set alpha to 0.2 for subtle effect
	sin_color.a = 0.2
	color_overlay.material.set_shader_parameter("overlay_color", sin_color)

func _update_touch_color(sin: int = -1) -> void:
	var sin_color = GlobalSettings.get_color_for_sense(GlobalSettings.Sense.TOUCH)
	# Update laser color for both the beam and particles
	if laser_beam and laser_beam.draw_pass_1:
		if laser_beam.draw_pass_1.material:
			laser_beam.draw_pass_1.material.albedo_color = sin_color
		if laser_beam.process_material:
			laser_beam.process_material.color = sin_color
			# Slow down particles if sin is SLOTH
			var base_velocity = 50.0
			if sin == GlobalSettings.Sin.SLOTH:
				laser_beam.process_material.initial_velocity_min = base_velocity * 0.5
				laser_beam.process_material.initial_velocity_max = base_velocity * 0.5
				laser_beam.lifetime = 0.4  # Longer lifetime for slower effect
			else:
				laser_beam.process_material.initial_velocity_min = base_velocity
				laser_beam.process_material.initial_velocity_max = base_velocity
				laser_beam.lifetime = 0.2  # Reset to default lifetime
		if laser_beam.material_override:
			laser_beam.material_override.emission = sin_color

func _setup_laser_particles() -> void:
	# Create a simple particle material
	var particle_material = ParticleProcessMaterial.new()
	particle_material.direction = Vector3(0, 0, -1)
	particle_material.spread = 0.0
	particle_material.gravity = Vector3.ZERO
	particle_material.initial_velocity_min = 50.0
	particle_material.initial_velocity_max = 50.0
	particle_material.color = LASER.COLOR
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	
	# Create a circle mesh for particles
	var circle_mesh = QuadMesh.new()
	circle_mesh.size = Vector2(0.1, 0.1)
	
	# Create an emissive material for the particles
	var spatial_material = StandardMaterial3D.new()
	spatial_material.emission_enabled = true
	spatial_material.emission = LASER.COLOR
	spatial_material.emission_energy_multiplier = 5.0
	spatial_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	spatial_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spatial_material.vertex_color_use_as_albedo = true
	spatial_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spatial_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD  # Additive blending for better glow
	spatial_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	spatial_material.render_priority = 1  # Higher priority to render on top
	
	# Load circle texture
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 1, 1, 1))
	gradient.add_point(1.0, Color(1, 1, 1, 0))
	
	var gradient_texture = GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.fill = GradientTexture2D.FILL_RADIAL
	gradient_texture.width = 32
	gradient_texture.height = 32
	
	spatial_material.albedo_texture = gradient_texture
	
	# Set up the laser beam
	laser_beam.draw_pass_1 = circle_mesh
	laser_beam.process_material = particle_material
	laser_beam.material_override = spatial_material
	laser_beam.amount = 1000  # Many more particles
	laser_beam.lifetime = 0.2
	laser_beam.local_coords = true
	laser_beam.one_shot = false
	laser_beam.explosiveness = 0.0
	laser_beam.fixed_fps = 60
	laser_beam.draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH  # Sort particles by depth

func _handle_shooting(delta: float) -> void:
	if Input.is_action_pressed("shoot"):
		if Time.get_unix_time_from_system() - last_shot_time >= LASER.COOLDOWN:
			last_shot_time = Time.get_unix_time_from_system()
			_shoot_laser()
	else:
		laser_beam.emitting = false

func _shoot_laser() -> void:
	if weapon_raycast.is_colliding():
		var collider = weapon_raycast.get_collider()
		if collider and collider.has_method("take_damage"):
			var damage = LASER.DAMAGE
			var current_sight_sin = GlobalSettings.get_sin_for_sense(GlobalSettings.Sense.SIGHT)
			# Double damage if WRATH is assigned to TOUCH
			if GlobalSettings.get_sin_for_sense(GlobalSettings.Sense.TOUCH) == GlobalSettings.Sin.WRATH:
				damage *= 2
			# Increase damage if SLOTH is assigned to SIGHT
			if current_sight_sin == GlobalSettings.Sin.SLOTH:
				damage = int(damage * LASER.SLOTH_DAMAGE_MULT)
			collider.take_damage(damage)
		
		# Get the distance to the hit point
		var distance = weapon_raycast.get_collision_point().distance_to(weapon_raycast.global_position)
		laser_beam.process_material.emission_box_extents = Vector3(LASER.BEAM_WIDTH, LASER.BEAM_WIDTH, distance)
	else:
		# Default length if no collision
		laser_beam.process_material.emission_box_extents = Vector3(LASER.BEAM_WIDTH, LASER.BEAM_WIDTH, 300.0)
	
	laser_beam.emitting = true

func _update_weapon_direction() -> void:
	# Update only the raycast direction - beam will update on next _shoot_laser call
	weapon_raycast.global_transform.basis = camera.global_transform.basis
