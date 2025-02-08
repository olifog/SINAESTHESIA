extends CharacterBody3D

@export var speed: float = 5.0
@export var rotation_speed: float = 5.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.0
@export var damage: int = 10  # Damage amount
@export var damage_delay: float = 0.2  # Time until damage is dealt
@export var damage_check_range: float = 2.5  # Range to check when dealing damage

var player: Node3D
var can_attack: bool = true

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_warning("Enemy: No player found in scene!")

func _physics_process(delta: float) -> void:
	if not player:
		return
		
	handle_movement(delta)
	handle_rotation(delta)
	handle_attack()

func handle_movement(delta: float) -> void:
	# Don't move while attacking
	if sprite.animation == "attack":
		return
		
	var direction: Vector3 = player.neck.global_transform.origin - global_transform.origin
	direction.y = 0
	direction = direction.normalized()
	
	velocity = direction * speed
	move_and_slide()

func handle_rotation(delta: float) -> void:
	var look_target: Vector3 = player.global_transform.origin
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
	sprite.play("attack")
	
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

func _on_animation_finished() -> void:
	print(sprite.animation)
	if sprite.animation == "attack":
		sprite.play("flying")  # Or whatever your default animation is
		
		# Start attack cooldown
		var timer := get_tree().create_timer(attack_cooldown)
		timer.timeout.connect(func(): can_attack = true)

	sprite.play("flying")
	
