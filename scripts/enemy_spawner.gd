class_name EnemySpawner
extends Node2D

@export_category("General")
@export var enemy_scene: PackedScene
@export var enemy_container: Node2D

@export_category("Enemy 1")
@export var enemy_1_data: EnemyData
@export var enemy_1_spawn_point: Marker2D
@export var enemy_1_spawn_interval: float = 5.0
@export var enemy_1_start_delay: float = 5.0
@export var enemy_1_max_enemies: int = 6

@export_category("Enemy 2")
@export var enemy_2_data: EnemyData
@export var enemy_2_spawn_point: Marker2D
@export var enemy_2_spawn_interval: float = 7.0
@export var enemy_2_start_delay: float = 7.0
@export var enemy_2_max_enemies: int = 5

@export_category("Enemy 3")
@export var enemy_3_data: EnemyData
@export var enemy_3_spawn_point: Marker2D
@export var enemy_3_spawn_interval: float = 10.0
@export var enemy_3_start_delay: float = 10.0
@export var enemy_3_max_enemies: int = 4

var enemy_1_spawned: int = 0
var enemy_2_spawned: int = 0
var enemy_3_spawned: int = 0

@onready var spawn_timer_1: Timer = $"../SpawnTimer1"
@onready var spawn_timer_2: Timer = $"../SpawnTimer2"
@onready var spawn_timer_3: Timer = $"../SpawnTimer3"


func _ready() -> void:
	if enemy_scene == null:
		push_error("EnemySpawner: Enemy Scene is not assigned.")
		return

	if enemy_container == null:
		push_error("EnemySpawner: Enemy Container is not assigned.")
		return

	if spawn_timer_1 == null:
		push_error("EnemySpawner: SpawnTimer1 not found.")

	if spawn_timer_2 == null:
		push_error("EnemySpawner: SpawnTimer2 not found.")

	if spawn_timer_3 == null:
		push_error("EnemySpawner: SpawnTimer3 not found.")

	_setup_timer_1()
	_setup_timer_2()
	_setup_timer_3()

func _setup_timer_1() -> void:
	spawn_timer_1.stop()
	spawn_timer_1.one_shot = false

	if enemy_1_start_delay <= 0.0:
		_spawn_enemy_1()
	else:
		spawn_timer_1.wait_time = enemy_1_start_delay

		if not spawn_timer_1.timeout.is_connected(_start_enemy_1_spawning):
			spawn_timer_1.timeout.connect(_start_enemy_1_spawning)

		spawn_timer_1.start()

func _setup_timer_2() -> void:
	spawn_timer_2.stop()
	spawn_timer_2.one_shot = false

	if enemy_2_start_delay <= 0.0:
		_spawn_enemy_2()
	else:
		spawn_timer_2.wait_time = enemy_2_start_delay

		if not spawn_timer_2.timeout.is_connected(_start_enemy_2_spawning):
			spawn_timer_2.timeout.connect(_start_enemy_2_spawning)

		spawn_timer_2.start()

func _setup_timer_3() -> void:
	spawn_timer_3.stop()
	spawn_timer_3.one_shot = false

	if enemy_3_start_delay <= 0.0:
		_spawn_enemy_3()
	else:
		spawn_timer_3.wait_time = enemy_3_start_delay

		if not spawn_timer_3.timeout.is_connected(_start_enemy_3_spawning):
			spawn_timer_3.timeout.connect(_start_enemy_3_spawning)

		spawn_timer_3.start()

func _start_enemy_1_spawning() -> void:
	spawn_timer_1.stop()

	_spawn_enemy_1()

	if enemy_1_spawned < enemy_1_max_enemies:
		spawn_timer_1.wait_time = enemy_1_spawn_interval
		spawn_timer_1.one_shot = false
		spawn_timer_1.start()

func _start_enemy_2_spawning() -> void:
	spawn_timer_2.stop()

	_spawn_enemy_2()

	if enemy_2_spawned < enemy_2_max_enemies:
		spawn_timer_2.wait_time = enemy_2_spawn_interval
		spawn_timer_2.one_shot = false
		spawn_timer_2.start()

func _start_enemy_3_spawning() -> void:
	spawn_timer_3.stop()

	_spawn_enemy_3()

	if enemy_3_spawned < enemy_3_max_enemies:
		spawn_timer_3.wait_time = enemy_3_spawn_interval
		spawn_timer_3.one_shot = false
		spawn_timer_3.start()

func _spawn_enemy_1() -> void:
	if enemy_1_spawned >= enemy_1_max_enemies:
		spawn_timer_1.stop()
		return

	var enemy: Enemy = spawn_enemy(
		enemy_1_data,
		enemy_1_spawn_point
	)

	if enemy != null:
		enemy_1_spawned += 1

func _spawn_enemy_2() -> void:
	if enemy_2_spawned >= enemy_2_max_enemies:
		spawn_timer_2.stop()
		return

	var enemy: Enemy = spawn_enemy(
		enemy_2_data,
		enemy_2_spawn_point
	)

	if enemy != null:
		enemy_2_spawned += 1

func _spawn_enemy_3() -> void:
	if enemy_3_spawned >= enemy_3_max_enemies:
		spawn_timer_3.stop()
		return

	var enemy: Enemy = spawn_enemy(
		enemy_3_data,
		enemy_3_spawn_point
	)

	if enemy != null:
		enemy_3_spawned += 1

func spawn_enemy(
	data: EnemyData,
	point: Marker2D
) -> Enemy:

	if data == null:
		push_error("EnemySpawner: EnemyData is null.")
		return null

	if point == null:
		push_error("EnemySpawner: SpawnPoint is null.")
		return null

	var enemy: Enemy = enemy_scene.instantiate() as Enemy

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
