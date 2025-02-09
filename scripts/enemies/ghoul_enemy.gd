extends "res://scripts/enemies/base_enemy.gd"

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D

func _on_ready() -> void:
	sprite.play("towards")

func is_attacking() -> bool:
	return sprite.animation == "attack"

func update_animation(direction: Vector3) -> void:
	if sprite.animation != "attack":
		var flat_velocity = Vector3(velocity.x, 0, velocity.z).normalized()
		var flat_to_player = Vector3(direction.x, 0, direction.z).normalized()
		var dot_product = flat_to_player.dot(flat_velocity)
		if dot_product < -0.2:  # Moving away from player
			sprite.play("away")
		else:  # Moving towards player
			sprite.play("towards")

func start_attack_animation() -> void:
	sprite.play("attack")

func _on_animation_finished() -> void:
	if sprite.animation == "attack":
		finish_attack()
		
		# Return to appropriate animation based on movement direction
		var direction = (player.neck.global_transform.origin - global_transform.origin).normalized()
		var dot_product = direction.dot(velocity.normalized())
		if dot_product < -0.2:
			sprite.play("away")
		else:
			sprite.play("towards") 
