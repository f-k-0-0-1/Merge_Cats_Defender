class_name EnemySpawner
extends Node2D

@export_category("General")
@export var enemy_scene: PackedScene
@export var enemy_container: Node2D

func _ready() -> void:
	if enemy_scene == null:
		push_error(
			"EnemySpawner: Enemy Scene is not assigned."
		)

	if enemy_container == null:
		push_error(
			"EnemySpawner: Enemy Container is not assigned."
		)


func spawn_enemy(
	data: EnemyData,
	point: Marker2D
) -> Enemy:

	if enemy_scene == null:
		push_error(
			"EnemySpawner: Enemy Scene is not assigned."
		)
		return null

	if enemy_container == null:
		push_error(
			"EnemySpawner: Enemy Container is not assigned."
		)
		return null

	if data == null:
		push_error(
			"EnemySpawner: EnemyData is null."
		)
		return null

	if point == null:
		push_error(
			"EnemySpawner: SpawnPoint is null."
		)
		return null

	var enemy: Enemy = (
		enemy_scene.instantiate()
		as Enemy
	)

	if enemy == null:
		push_error(
			"EnemySpawner: Could not instantiate Enemy.tscn."
		)
		return null

	enemy_container.add_child(enemy)

	enemy.global_position = point.global_position

	enemy.setup(data)

	print(
		"Spawned enemy: ",
		data.enemy_name,
		" at ",
		point.name
	)

	return enemy
