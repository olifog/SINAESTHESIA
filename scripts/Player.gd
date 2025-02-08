extends CharacterBody3D

# Signal declarations
signal health_changed(new_health: int)
signal player_died

# Constants
const MOVEMENT = {
	SPEED = 12.0,
	JUMP_VELOCITY = 10.0,
	FAST_DOWN_MULT = 1.5
}

const HEAD_BOB = {
	FREQUENCY = 2.0,
	AMPLITUDE = 0.08
}

const FOV = {
	BASE = 90.0,
	CHANGE = 1.5
}

const MAX_HEALTH := 100

# Member variables
var current_health: int = MAX_HEALTH
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var t_bob: float = 0.0

# Node references
@onready var neck: Node3D = $Neck
@onready var camera: Camera3D = $Neck/Camera3D

# Built-in virtual methods
func _ready() -> void:
	current_health = MAX_HEALTH
	health_changed.emit(current_health)

func _unhandled_input(event: InputEvent) -> void:
	_handle_mouse_input(event)

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement()
	_update_camera_effects(delta)
	move_and_slide()

# Movement and physics methods
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var gravity_mult = MOVEMENT.FAST_DOWN_MULT if velocity.y <= 0 else 1.0
		velocity.y -= gravity * delta * gravity_mult

func _handle_jump() -> void:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = MOVEMENT.JUMP_VELOCITY

func _handle_movement() -> void:
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Back")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * MOVEMENT.SPEED
		velocity.z = direction.z * MOVEMENT.SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, MOVEMENT.SPEED)
		velocity.z = move_toward(velocity.z, 0, MOVEMENT.SPEED)

# Camera and visual effects methods
func _handle_mouse_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * 0.002)
			camera.rotate_x(-event.relative.y * 0.002)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _update_camera_effects(delta: float) -> void:
	# Update head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _calculate_headbob(t_bob)
	
	# Update FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, MOVEMENT.SPEED * 2.0)
	var target_fov = FOV.BASE + FOV.CHANGE * velocity_clamped
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
