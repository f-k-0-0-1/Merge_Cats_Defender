class_name Trap
extends Node2D

var trap_data: TrapData = null

var health: float = 0.0
var current_target: Node2D = null

var is_attacking: bool = false
var is_destroyed: bool = false
var is_exploding: bool = false
var is_being_dragged: bool = false

var sprite: Sprite2D = null
var health_bar: ProgressBar = null
var attack_timer: Timer = null
var visibility_timer: Timer = null

# TNT
var fuse_timer: Timer = null
var explosion_effect: AnimatedSprite2D = null
var fuse_tween: Tween = null


func _ready() -> void:
	add_to_group("traps")

	_find_nodes()

	if health_bar:
		health_bar.visible = false

	if attack_timer:
		attack_timer.one_shot = true

	if visibility_timer:
		visibility_timer.one_shot = true
		visibility_timer.wait_time = 2.0

		if not visibility_timer.timeout.is_connected(
			_on_visibility_timer_timeout
		):
			visibility_timer.timeout.connect(
				_on_visibility_timer_timeout
			)

	if fuse_timer:
		fuse_timer.one_shot = true

		if not fuse_timer.timeout.is_connected(
			_on_fuse_finished
		):
			fuse_timer.timeout.connect(
				_on_fuse_finished
			)

	if explosion_effect:
		explosion_effect.visible = false
		explosion_effect.stop()


# ============================================================
# FIND NODES
# ============================================================

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

	visibility_timer = find_child(
		"VisibilityTimer",
		true,
		false
	) as Timer

	fuse_timer = find_child(
		"FuseTimer",
		true,
		false
	) as Timer

	explosion_effect = find_child(
		"ExplosionEffect",
		true,
		false
	) as AnimatedSprite2D


# ============================================================
# SET DRAGGING STATE
# ============================================================

func set_being_dragged(value: bool) -> void:
	is_being_dragged = value

	if value:
		current_target = null
		is_attacking = false

		if attack_timer:
			attack_timer.stop()


# ============================================================
# SETUP
# ============================================================

func setup(data: TrapData) -> void:
	_find_nodes()

	if data == null:
		push_error("Trap setup failed: TrapData is null.")
		return

	if sprite == null:
		push_error("Trap setup failed: Sprite2D is missing.")
		return

	if attack_timer == null:
		push_error("Trap setup failed: AttackTimer is missing.")
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
	is_exploding = false
	is_being_dragged = false

	sprite.texture = trap_data.icon
	sprite.scale = trap_data.scale
	sprite.position = Vector2.ZERO

	_setup_health_bar()

	if health_bar:
		health_bar.visible = false

	if visibility_timer:
		visibility_timer.stop()
		visibility_timer.one_shot = true
		visibility_timer.wait_time = 2.0

	attack_timer.stop()
	attack_timer.one_shot = true
	attack_timer.wait_time = max(
		trap_data.attack_cooldown,
		0.01
	)

	if fuse_timer:
		fuse_timer.stop()
		fuse_timer.one_shot = true

	if explosion_effect:
		explosion_effect.stop()
		explosion_effect.visible = false
		explosion_effect.position = Vector2.ZERO

	print(
		"Trap initialized: ",
		trap_data.trap_name,
		" | HP: ",
		health,
		"/",
		trap_data.max_health
	)


# ============================================================
# COMBAT
# ============================================================

func _physics_process(_delta: float) -> void:
	if trap_data == null:
		return

	if is_destroyed:
		return

	if is_being_dragged:
		return

	if is_exploding:
		return

	if current_target == null:
		current_target = _find_target()

	if current_target != null:
		if not _is_target_valid(current_target):
			current_target = null

	if current_target == null:
		return

	if attack_timer == null:
		return

	if attack_timer.is_stopped():
		_attack()


# ============================================================
# FIND TARGET
# ============================================================

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


# ============================================================
# VALIDATE TARGET
# ============================================================

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

	return distance <= trap_data.attack_range


# ============================================================
# ATTACK
# ============================================================

func _attack() -> void:
	if is_destroyed:
		return

	if is_exploding:
		return

	if current_target == null:
		return

	if not _is_target_valid(current_target):
		current_target = null
		return

	if attack_timer == null:
		return

	if _is_explosive():
		_start_explosion()
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

	_play_attack_effect()

	attack_timer.start()

	is_attacking = false


# ============================================================
# CHECK EXPLOSIVE
# ============================================================

func _is_explosive() -> bool:
	if trap_data == null:
		return false

	var value = trap_data.get("trap_type")

	return value == "EXPLOSIVE"


# ============================================================
# NORMAL ATTACK EFFECT
# ============================================================

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


# ============================================================
# TNT
# ============================================================

func _start_explosion() -> void:
	if is_destroyed:
		return

	if is_exploding:
		return

	is_exploding = true
	is_attacking = true
	current_target = null

	if attack_timer:
		attack_timer.stop()

	var delay: float = _get_explosion_delay()

	print(
		"TNT armed: ",
		trap_data.trap_name,
		" | Fuse: ",
		delay,
		" seconds"
	)

	_start_fuse_effect()

	if fuse_timer:
		fuse_timer.wait_time = max(
			delay,
			0.05
		)

		fuse_timer.start()
	else:
		await get_tree().create_timer(delay).timeout

		if not is_destroyed:
			_explode()


func _get_explosion_delay() -> float:
	var value = trap_data.get("explosion_delay")

	if value == null:
		return 0.35

	return max(
		float(value),
		0.05
	)


func _get_explosion_damage() -> float:
	var value = trap_data.get("explosion_damage")

	if value == null:
		return trap_data.damage

	return float(value)


func _get_explosion_radius() -> float:
	var value = trap_data.get("explosion_radius")

	if value == null:
		return trap_data.attack_range

	return float(value)


# ============================================================
# TNT FUSE EFFECT
# ============================================================

func _start_fuse_effect() -> void:
	if sprite == null:
		return

	if fuse_tween:
		fuse_tween.kill()

	var original_position: Vector2 = sprite.position

	fuse_tween = create_tween()
	fuse_tween.set_loops()

	fuse_tween.tween_property(
		sprite,
		"position",
		original_position + Vector2(3.0, 0.0),
		0.05
	)

	fuse_tween.tween_property(
		sprite,
		"position",
		original_position - Vector2(3.0, 0.0),
		0.05
	)

	fuse_tween.tween_property(
		sprite,
		"position",
		original_position,
		0.05
	)


func _on_fuse_finished() -> void:
	if is_destroyed:
		return

	if not is_exploding:
		return

	_explode()


# ============================================================
# TNT EXPLOSION
# ============================================================

func _explode() -> void:
	if is_destroyed:
		return

	if not is_exploding:
		return

	if fuse_tween:
		fuse_tween.kill()
		fuse_tween = null

	if sprite:
		sprite.position = Vector2.ZERO

	var damage: float = _get_explosion_damage()
	var radius: float = _get_explosion_radius()

	print(
		"TNT EXPLOSION | Damage: ",
		damage,
		" | Radius: ",
		radius
	)

	_damage_enemies_in_explosion(
		damage,
		radius
	)

	_play_explosion_effect()


func _damage_enemies_in_explosion(
	damage: float,
	radius: float
) -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group(
		"enemies"
	)

	for enemy_node: Node in enemies:
		if not is_instance_valid(enemy_node):
			continue

		var enemy := enemy_node as Node2D

		if enemy == null:
			continue

		var distance := global_position.distance_to(
			enemy.global_position
		)

		if distance > radius:
			continue

		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)

			print(
				"TNT hit ",
				enemy.name,
				" for ",
				damage,
				" damage."
			)


func _play_explosion_effect() -> void:
	if explosion_effect == null:
		_destroy_after_explosion()
		return

	explosion_effect.visible = true
	explosion_effect.position = Vector2.ZERO

	if explosion_effect.sprite_frames == null:
		_destroy_after_explosion()
		return

	if not explosion_effect.sprite_frames.has_animation(
		"explode"
	):
		push_warning(
			"Trap: ExplosionEffect has no 'explode' animation."
		)

		_destroy_after_explosion()
		return

	explosion_effect.play("explode")

	if not explosion_effect.animation_finished.is_connected(
		_on_explosion_animation_finished
	):
		explosion_effect.animation_finished.connect(
			_on_explosion_animation_finished,
			CONNECT_ONE_SHOT
		)


func _on_explosion_animation_finished() -> void:
	_destroy_after_explosion()


func _destroy_after_explosion() -> void:
	if is_destroyed:
		return

	is_destroyed = true
	current_target = null
	is_attacking = false
	is_exploding = false

	if attack_timer:
		attack_timer.stop()

	if fuse_timer:
		fuse_timer.stop()

	if visibility_timer:
		visibility_timer.stop()

	if fuse_tween:
		fuse_tween.kill()
		fuse_tween = null

	var parent_slot: Node = _find_parent_slot()

	if parent_slot != null:
		if parent_slot.has_method("clear_trap"):
			parent_slot.clear_trap()

	queue_free()


# ============================================================
# DAMAGE
# ============================================================

func take_damage(amount: float) -> void:
	if is_destroyed:
		return

	if trap_data == null:
		return

	if amount <= 0.0:
		return

	show_health_bar()

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


# ============================================================
# HIT EFFECT
# ============================================================

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


# ============================================================
# HEALTH BAR
# ============================================================

func _setup_health_bar() -> void:
	if health_bar == null:
		return

	if trap_data == null:
		return

	health_bar.min_value = 0.0
	health_bar.max_value = trap_data.max_health
	health_bar.value = health
	health_bar.show_percentage = false


func _update_health_bar() -> void:
	if health_bar:
		health_bar.value = health


func show_health_bar() -> void:
	if health_bar == null:
		return

	health_bar.visible = true

	if visibility_timer:
		visibility_timer.start()


func hide_health_bar() -> void:
	if health_bar:
		health_bar.visible = false


func _on_visibility_timer_timeout() -> void:
	hide_health_bar()


# ============================================================
# DEATH
# ============================================================

func die() -> void:
	if is_destroyed:
		return

	is_destroyed = true
	current_target = null
	is_attacking = false
	is_exploding = false

	if attack_timer:
		attack_timer.stop()

	if fuse_timer:
		fuse_timer.stop()

	if visibility_timer:
		visibility_timer.stop()

	if fuse_tween:
		fuse_tween.kill()
		fuse_tween = null

	print(
		trap_data.trap_name,
		" destroyed."
	)

	var parent_slot: Node = _find_parent_slot()

	if parent_slot != null:
		if parent_slot.has_method("clear_trap"):
			parent_slot.clear_trap()

	queue_free()


# ============================================================
# FIND PARENT SLOT
# ============================================================

func _find_parent_slot() -> Node:
	var slots: Array[Node] = get_tree().get_nodes_in_group(
		"trap_slots"
	)

	for node: Node in slots:
		if not is_instance_valid(node):
			continue

		var placed_trap = node.get("placed_trap")

		if placed_trap == self:
			return node

	return null
