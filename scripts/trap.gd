class_name Trap
extends Node2D

var trap_data: TrapData = null

var health: float = 0.0
var current_target: Node2D = null

var is_attacking: bool = false
var is_destroyed: bool = false

var sprite: Sprite2D = null
var health_bar: ProgressBar = null
var attack_timer: Timer = null

func _ready() -> void:
	add_to_group("traps")
	_find_nodes()

	if attack_timer:
		attack_timer.one_shot = true

func _find_nodes() -> void:
	sprite = find_child(
		"Sprite2D",
		true,
		false
	) as Sprite2D

	if sprite == null:
		push_error("Trap: Sprite2D not found.")

	health_bar = find_child(
		"HealthBar",
		true,
		false
	) as ProgressBar

	if health_bar == null:
		push_error("Trap: HealthBar not found.")

	attack_timer = find_child(
		"AttackTimer",
		true,
		false
	) as Timer

	if attack_timer == null:
		push_error("Trap: AttackTimer not found.")

func setup(data: TrapData) -> void:
	_find_nodes()

	if attack_timer == null:
		push_error(
			"Trap setup failed: AttackTimer is missing."
		)
		return

	if sprite == null:
		push_error(
			"Trap setup failed: Sprite2D is missing."
		)
		return

	if data == null:
		push_error(
			"Trap setup failed: TrapData is null."
		)
		return

	trap_data = data

	if trap_data.icon == null:
		push_error(
			"Trap '%s' has no icon."
			% trap_data.trap_name
		)
		return

	health = trap_data.max_health
	current_target = null
	is_attacking = false
	is_destroyed = false

	# Setup sprite
	sprite.texture = trap_data.icon
	sprite.scale = trap_data.scale

	# Setup health bar
	_setup_health_bar()

	# Setup attack timer
	attack_timer.one_shot = true
	attack_timer.wait_time = max(
		trap_data.attack_cooldown,
		0.01
	)
	attack_timer.stop()

	print(
		"Trap initialized: ",
		trap_data.trap_name,
		" | HP: ",
		health,
		"/",
		trap_data.max_health
	)

func _setup_health_bar() -> void:
	if health_bar == null:
		return

	health_bar.min_value = 0.0
	health_bar.max_value = trap_data.max_health
	health_bar.value = health
	health_bar.show_percentage = false

func _update_health_bar() -> void:
	if health_bar == null:
		return

	health_bar.value = health

func _physics_process(_delta: float) -> void:
	if trap_data == null:
		return

	if is_destroyed:
		return

	# Find a target if we don't currently have one.
	if current_target == null:
		current_target = _find_target()

	# Check whether the current target is still valid.
	if current_target != null:
		if not _is_target_valid(current_target):
			current_target = null

	# No valid target.
	if current_target == null:
		return

	# Attack when cooldown is finished.
	if attack_timer == null:
		return

	if attack_timer.is_stopped():
		_attack()

func _find_target() -> Node2D:
	if trap_data == null:
		return null

	var enemies: Array[Node] = get_tree().get_nodes_in_group(
		"enemies"
	)

	var best_target: Node2D = null
	var best_distance: float = INF

	for enemy_node: Node in enemies:
		if not is_instance_valid(enemy_node):
			continue

		var enemy := enemy_node as Node2D

		if enemy == null:
			continue

		if not _is_target_valid(enemy):
			continue

		var distance: float = global_position.distance_to(
			enemy.global_position
		)

		if distance > trap_data.attack_range:
			continue

		if distance < best_distance:
			best_distance = distance
			best_target = enemy

	return best_target

func _is_target_valid(target: Node2D) -> bool:
	if target == null:
		return false

	if not is_instance_valid(target):
		return false

	if not target.is_in_group("enemies"):
		return false

	if trap_data == null:
		return false

	var distance: float = global_position.distance_to(
		target.global_position
	)

	if distance > trap_data.attack_range:
		return false

	return true

func _attack() -> void:
	if is_destroyed:
		return

	if current_target == null:
		return

	if not _is_target_valid(current_target):
		current_target = null
		return

	is_attacking = true

	print(
		trap_data.trap_name,
		" attacks ",
		current_target.name,
		" for ",
		trap_data.damage,
		" damage."
	)

	if current_target.has_method("take_damage"):
		current_target.take_damage(
			trap_data.damage
		)
	else:
		push_error(
			"Trap target does not have take_damage()."
		)

	_play_attack_effect()

	attack_timer.start()

	is_attacking = false

func _play_attack_effect() -> void:
	if sprite == null:
		return

	var original_scale: Vector2 = trap_data.scale

	var tween := create_tween()

	sprite.scale = original_scale * Vector2(
		1.12,
		0.88
	)

	tween.tween_property(
		sprite,
		"scale",
		original_scale,
		0.12
	)

func take_damage(amount: float) -> void:
	if is_destroyed:
		return

	if amount <= 0.0:
		return

	health -= amount
	health = max(health, 0.0)

	_update_health_bar()

	print(
		trap_data.trap_name,
		" took ",
		amount,
		" damage. HP: ",
		health,
		"/",
		trap_data.max_health
	)

	_play_hit_effect()

	if health <= 0.0:
		die()

func _play_hit_effect() -> void:
	if sprite == null:
		return

	var original_modulate: Color = sprite.modulate

	sprite.modulate = Color(
		1.0,
		0.5,
		0.5,
		1.0
	)

	var tween := create_tween()

	tween.tween_property(
		sprite,
		"modulate",
		original_modulate,
		0.12
	)

func die() -> void:
	if is_destroyed:
		return

	is_destroyed = true
	current_target = null

	if attack_timer:
		attack_timer.stop()

	print(
		trap_data.trap_name,
		" destroyed."
	)

	var parent_slot := _find_parent_slot()

	if parent_slot != null:
		parent_slot.clear_trap()

	queue_free()

func _find_parent_slot() -> TrapSlot:
	var slots: Array[Node] = get_tree().get_nodes_in_group(
		"trap_slots"
	)

	for node: Node in slots:
		var slot := node as TrapSlot

		if slot == null:
			continue

		if slot.placed_trap == self:
			return slot

	return null
