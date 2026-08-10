class_name Projectile
extends Area2D

var target: Node2D = null
var damage: float = 10.0
var speed: float = 500.0
var has_hit: bool = false

func setup(
	new_target: Node2D,
	new_damage: float,
	new_speed: float
) -> void:
	target = new_target
	damage = new_damage
	speed = new_speed

func _physics_process(delta: float) -> void:
	if has_hit:
		return

	if target == null or not is_instance_valid(target):
		queue_free()
		return

	var direction: Vector2 = global_position.direction_to(
		target.global_position
	)

	rotation = direction.angle()

	global_position += direction * speed * delta

	if global_position.distance_to(target.global_position) <= 20.0:
		_hit_target()

func _hit_target() -> void:
	if has_hit:
		return

	has_hit = true

	if target != null and is_instance_valid(target):
		if target.has_method("take_damage"):
			target.take_damage(damage)

	queue_free()
