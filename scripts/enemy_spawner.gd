class_name EnemySpawner
extends Node2D

@export_category("Spawner")
@export var enemy_scene: PackedScene
@export var enemy_container: Node2D
@export var spawn_point: Marker2D

@export_category("Enemy")
@export var enemy_data: EnemyData

@export_category("Spawn Settings")
@export var spawn_interval: float = 2.0
@export var spawn_on_ready: bool = true
@export var max_enemies: int = 10

var spawned_enemies: int = 0

@onready var spawn_timer: Timer = $SpawnTimer

func _ready() -> void:
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false

	if not spawn_timer.timeout.is_connected(_on_spawn_timer_timeout):
		spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	if spawn_on_ready:
		spawn_enemy(enemy_data)

		spawned_enemies += 1

		spawn_timer.start()

func _on_spawn_timer_timeout() -> void:
	if spawned_enemies >= max_enemies:
		spawn_timer.stop()
		return

	var enemy: Enemy = spawn_enemy(enemy_data)

	if enemy != null:
		spawned_enemies += 1

func spawn_enemy(data: EnemyData) -> Enemy:
	if enemy_scene == null:
		push_error("EnemySpawner: Enemy Scene is not assigned.")
		return null

	if enemy_container == null:
		push_error("EnemySpawner: Enemy Container is not assigned.")
		return null

	if spawn_point == null:
		push_error("EnemySpawner: Spawn Point is not assigned.")
		return null

	if data == null:
		push_error("EnemySpawner: EnemyData is not assigned.")
		return null

	var enemy: Enemy = enemy_scene.instantiate() as Enemy

	if enemy == null:
		push_error("EnemySpawner: Could not instantiate Enemy.tscn.")
		return null

	enemy_container.add_child(enemy)

	enemy.global_position = spawn_point.global_position

	enemy.setup(data)

	print(
		"Spawned enemy: ",
		data.enemy_name,
		" | Total spawned: ",
		spawned_enemies + 1
	)

	return enemy
