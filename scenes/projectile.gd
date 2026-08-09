class_name CatProjectile
extends Area2D


# ============================================================
# PROJECTILE DATA
# ============================================================

var target: Node2D = null
var damage: float = 0.0
var speed: float = 500.0


# ============================================================
# INITIALIZE
# ============================================================

func setup(
	target_node: Node2D,
	damage_value: float,
	speed_value: float
) -> void:

	target = target_node
	damage = damage_value
	speed = speed_value


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	# Detect enemies through Area2D collision.
	body_entered.connect(_on_body_entered)


# ============================================================
# MOVEMENT
# ============================================================

func _physics_process(delta: float) -> void:

	# Target no longer exists.
	if not is_instance_valid(target):

		queue_free()

		return


	# Direction toward target.
	var direction: Vector2 = (
		target.global_position - global_position
	).normalized()


	# Move projectile.
	global_position += direction * speed * delta


	# Rotate projectile toward target.
	rotation = direction.angle()


# ============================================================
# COLLISION
# ============================================================

func _on_body_entered(body: Node2D) -> void:

	# Ignore anything that isn't an enemy.
	if not body.is_in_group("enemies"):
		return


	# Apply damage.
	if body.has_method("take_damage"):

		body.take_damage(damage)


	# Destroy projectile after hitting enemy.
	queue_free()
