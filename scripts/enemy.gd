class_name DummyEnemy
extends CharacterBody2D


# ============================================================
# STATS
# ============================================================

@export var max_health: float = 100.0
@export var move_speed: float = 50.0

var health: float = 0.0


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	# Initialize health.
	health = max_health

	print(
		"Dummy Enemy spawned. HP: ",
		health
	)


# ============================================================
# MOVEMENT
# ============================================================

func _physics_process(_delta: float) -> void:

	# Move continuously to the left.
	velocity.x = -move_speed

	move_and_slide()


# ============================================================
# TAKE DAMAGE
# ============================================================

func take_damage(amount: float) -> void:

	health -= amount

	print(
		"Enemy took ",
		amount,
		" damage. HP: ",
		health
	)


	if health <= 0.0:

		die()


# ============================================================
# DEATH
# ============================================================

func die() -> void:

	print(
		"Dummy Enemy died."
	)

	queue_free()
