class_name DefenseWall
extends StaticBody2D

signal health_changed(current_health: float, max_health: float)
signal wall_destroyed

@export var max_health: float = 100.0

var health: float = 0.0
var destroyed: bool = false

func _ready() -> void:
	add_to_group("defense_wall")
	health = max_health
	destroyed = false

	print(
		"Defense Wall ready. HP: ",
		health,
		"/",
		max_health
	)

func take_damage(amount: float) -> void:
	if destroyed:
		return

	if amount <= 0.0:
		return

	health -= amount
	health = max(health, 0.0)

	print(
		"Wall took ",
		amount,
		" damage. HP: ",
		health,
		"/",
		max_health
	)

	health_changed.emit(
		health,
		max_health
	)

	if health <= 0.0:
		_destroy_wall()

func _destroy_wall() -> void:
	if destroyed:
		return

	destroyed = true

	print("DEFENSE WALL DESTROYED")

	wall_destroyed.emit()

	GameplayManager.game_over()
