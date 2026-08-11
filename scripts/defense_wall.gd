class_name DefenseWall
extends StaticBody2D

signal health_changed(current_health: float, max_health: float)
signal wall_destroyed

@export var max_health: float = 500.0
@export var repair_amount: float = 100.0

var health: float = 0.0
var destroyed: bool = false

@onready var health_bar: ProgressBar = $ProgressBar

func _ready() -> void:
	add_to_group("defense_wall")

	health = max_health
	destroyed = false

	health_bar.min_value = 0.0
	health_bar.max_value = max_health
	health_bar.value = health

func take_damage(amount: float) -> void:
	if destroyed:
		return

	if amount <= 0.0:
		return

	health -= amount
	health = max(health, 0.0)

	_update_health_bar()

	print(
		"Wall took ",
		amount,
		" damage. HP: ",
		health,
		"/",
		max_health
	)

	if health <= 0.0:
		_destroy_wall()

func repair() -> void:
	if destroyed:
		return

	if health >= max_health:
		print("Wall is already at full health.")
		return

	health += repair_amount
	health = min(health, max_health)

	_update_health_bar()

	print(
		"Wall repaired. HP: ",
		health,
		"/",
		max_health
	)

func _update_health_bar() -> void:
	health_bar.value = health

	health_changed.emit(
		health,
		max_health
	)

func _destroy_wall() -> void:
	if destroyed:
		return

	destroyed = true

	print("DEFENSE WALL DESTROYED")

	wall_destroyed.emit()

	GameplayManager.game_over()
