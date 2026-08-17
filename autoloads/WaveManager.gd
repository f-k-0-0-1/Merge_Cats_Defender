class_name WaveManager
extends Node2D

signal wave_changed(wave_number: int)

enum WaveState {
	WAITING,
	SPAWNING,
	WAITING_FOR_CLEAR,
	INTERMISSION,
	FINISHED
}

@export_category("Wave Settings")
@export var waves: Array[WaveData] = []
@export var start_delay: float = 2.0
@export var delay_between_waves: float = 3.0

@export_category("References")
@export var enemy_spawner: EnemySpawner
@export var enemy_container: Node2D
@export var wave_announcement: WaveAnnouncement

@export_category("Spawn Points")
@export var spawn_points: Array[Marker2D] = []

@export_category("Tutorial")
@export var wait_for_tutorial: bool = true

var tutorial_locked: bool = true
var current_wave: int = 0
var current_state: WaveState = WaveState.WAITING

var current_enemy_index: int = 0
var current_enemy_spawned: int = 0

var spawn_timer: Timer
var intermission_timer: Timer
var start_timer: Timer


func _ready() -> void:
	_create_timers()

	if not wait_for_tutorial:
		tutorial_locked = false

	if enemy_spawner == null:
		push_error("WaveManager: EnemySpawner is not assigned.")
		return

	if enemy_container == null:
		push_error("WaveManager: EnemyContainer is not assigned.")
		return

	if waves.is_empty():
		push_error("WaveManager: No WaveData resources assigned.")
		return

	if spawn_points.is_empty():
		push_error("WaveManager: No spawn points assigned.")
		return

	if wave_announcement == null:
		push_warning("WaveManager: WaveAnnouncement is not assigned.")

	start_timer.wait_time = max(start_delay, 0.01)

	if tutorial_locked:
		print("WaveManager: Waiting for tutorial to finish.")
	else:
		start_timer.start()

	print("Wave Manager ready.")
	print("Total waves: ", waves.size())


# ============================================================
# TUTORIAL
# ============================================================

func set_tutorial_locked(value: bool) -> void:
	tutorial_locked = value

	if tutorial_locked:
		start_timer.stop()
		current_state = WaveState.WAITING
		print("WaveManager: Tutorial lock enabled.")
		return

	print("WaveManager: Tutorial finished.")

	if current_wave == 0 and current_state == WaveState.WAITING:
		start_timer.wait_time = max(start_delay, 0.01)
		start_timer.start()
		print("WaveManager: Wave 1 will start in ", start_delay, " seconds.")


# ============================================================
# CREATE TIMERS
# ============================================================

func _create_timers() -> void:
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	add_child(spawn_timer)

	intermission_timer = Timer.new()
	intermission_timer.one_shot = true
	add_child(intermission_timer)

	start_timer = Timer.new()
	start_timer.one_shot = true
	add_child(start_timer)

	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	intermission_timer.timeout.connect(_on_intermission_finished)
	start_timer.timeout.connect(_on_start_delay_finished)


# ============================================================
# START DELAY
# ============================================================

func _on_start_delay_finished() -> void:
	if GameplayManager.is_game_over:
		return

	if tutorial_locked:
		return

	start_wave()


# ============================================================
# START WAVE
# ============================================================

func start_wave() -> void:
	if GameplayManager.is_game_over:
		return

	if tutorial_locked:
		print("WaveManager: Wave start blocked by tutorial.")
		return

	if current_wave >= waves.size():
		_finish_all_waves()
		return

	current_wave += 1
	current_state = WaveState.SPAWNING
	current_enemy_index = 0
	current_enemy_spawned = 0

	wave_changed.emit(current_wave)

	var wave: WaveData = waves[current_wave - 1]

	if wave == null:
		push_error(
			"WaveManager: Wave %d is null."
			% current_wave
		)
		return

	print(
		"========== WAVE ",
		current_wave,
		" START =========="
	)

	if wave_announcement != null:
		wave_announcement.show_wave(current_wave)

	_start_current_enemy_type()


# ============================================================
# START CURRENT ENEMY TYPE
# ============================================================

func _start_current_enemy_type() -> void:
	if GameplayManager.is_game_over:
		return

	if tutorial_locked:
		return

	if current_wave <= 0:
		return

	var wave: WaveData = waves[current_wave - 1]

	if wave == null:
		_finish_spawning()
		return

	if current_enemy_index >= wave.enemies.size():
		_finish_spawning()
		return

	if current_enemy_index >= wave.enemy_counts.size():
		push_error(
			"WaveManager: Wave %d is missing an enemy count for index %d."
			% [
				current_wave,
				current_enemy_index
			]
		)
		_finish_spawning()
		return

	var enemy_data: EnemyData = wave.enemies[current_enemy_index]
	var enemy_count: int = wave.enemy_counts[current_enemy_index]

	if enemy_data == null:
		current_enemy_index += 1
		current_enemy_spawned = 0
		_start_current_enemy_type()
		return

	if enemy_count <= 0:
		current_enemy_index += 1
		current_enemy_spawned = 0
		_start_current_enemy_type()
		return

	current_enemy_spawned = 0

	print(
		"Wave ",
		current_wave,
		": spawning ",
		enemy_count,
		" x ",
		enemy_data.enemy_name
	)

	_spawn_next_enemy()


# ============================================================
# SPAWN NEXT ENEMY
# ============================================================

func _spawn_next_enemy() -> void:
	if GameplayManager.is_game_over:
		return

	if tutorial_locked:
		return

	if current_state != WaveState.SPAWNING:
		return

	var wave: WaveData = waves[current_wave - 1]

	if wave == null:
		_finish_spawning()
		return

	if current_enemy_index >= wave.enemies.size():
		_finish_spawning()
		return

	if current_enemy_index >= wave.enemy_counts.size():
		_finish_spawning()
		return

	var enemy_data: EnemyData = wave.enemies[current_enemy_index]
	var enemy_count: int = wave.enemy_counts[current_enemy_index]

	if current_enemy_spawned >= enemy_count:
		current_enemy_index += 1
		current_enemy_spawned = 0
		_start_current_enemy_type()
		return

	var spawn_point: Marker2D = _get_spawn_point()

	if spawn_point == null:
		push_error(
			"WaveManager: No valid spawn point available."
		)

		spawn_timer.wait_time = 0.1
		spawn_timer.start()
		return

	var enemy: Enemy = enemy_spawner.spawn_enemy(
		enemy_data,
		spawn_point
	)

	if enemy == null:
		push_error(
			"WaveManager: Failed to spawn %s."
			% enemy_data.enemy_name
		)

		spawn_timer.wait_time = 0.1
		spawn_timer.start()
		return

	current_enemy_spawned += 1

	print(
		"Wave ",
		current_wave,
		" | ",
		enemy_data.enemy_name,
		" | ",
		current_enemy_spawned,
		"/",
		enemy_count,
		" | Spawn Point: ",
		spawn_point.name
	)

	var spawn_interval: float = wave.spawn_interval

	if spawn_interval <= 0.0:
		spawn_interval = 0.1

	spawn_timer.wait_time = spawn_interval
	spawn_timer.start()


# ============================================================
# SPAWN TIMER
# ============================================================

func _on_spawn_timer_timeout() -> void:
	if GameplayManager.is_game_over:
		return

	if tutorial_locked:
		return

	_spawn_next_enemy()


# ============================================================
# FINISH SPAWNING
# ============================================================

func _finish_spawning() -> void:
	if GameplayManager.is_game_over:
		return

	spawn_timer.stop()

	current_state = WaveState.WAITING_FOR_CLEAR

	print(
		"Wave ",
		current_wave,
		" finished spawning."
	)

	print(
		"Waiting for all enemies to be defeated..."
	)


# ============================================================
# CHECK FOR WAVE CLEAR
# ============================================================

func _process(_delta: float) -> void:
	if GameplayManager.is_game_over:
		return

	if current_state != WaveState.WAITING_FOR_CLEAR:
		return

	if enemy_container == null:
		return

	if enemy_container.get_child_count() > 0:
		return

	_wave_completed()


# ============================================================
# WAVE COMPLETED
# ============================================================

func _wave_completed() -> void:
	if current_state != WaveState.WAITING_FOR_CLEAR:
		return

	current_state = WaveState.INTERMISSION

	print(
		"========== WAVE ",
		current_wave,
		" COMPLETE =========="
	)

	if current_wave >= waves.size():
		_finish_all_waves()
		return

	var delay: float = delay_between_waves

	if delay <= 0.0:
		delay = 0.1

	print(
		"Next wave starts in ",
		delay,
		" seconds."
	)

	intermission_timer.wait_time = delay
	intermission_timer.start()


# ============================================================
# INTERMISSION FINISHED
# ============================================================

func _on_intermission_finished() -> void:
	if GameplayManager.is_game_over:
		return

	if tutorial_locked:
		return

	start_wave()


# ============================================================
# ALL WAVES FINISHED
# ============================================================

func _finish_all_waves() -> void:
	if current_state == WaveState.FINISHED:
		return

	current_state = WaveState.FINISHED

	spawn_timer.stop()
	intermission_timer.stop()
	start_timer.stop()

	if wave_announcement != null:
		wave_announcement.hide_announcement()

	GameplayManager.victory()

	print(
		"========== ALL WAVES COMPLETE =========="
	)

	print(
		"Level completed after ",
		current_wave,
		" waves."
	)


# ============================================================
# RANDOM SPAWN POINT
# ============================================================

func _get_spawn_point() -> Marker2D:
	if spawn_points.is_empty():
		return null

	var valid_points: Array[Marker2D] = []

	for point: Marker2D in spawn_points:
		if is_instance_valid(point):
			valid_points.append(point)

	if valid_points.is_empty():
		return null

	var index: int = randi_range(
		0,
		valid_points.size() - 1
	)

	return valid_points[index]
