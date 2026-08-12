class_name Enemy
extends CharacterBody2D

enum State {
	WALKING,
	ATTACKING_TRAP,
	ATTACKING_WALL,
	DYING
}

var enemy_data: EnemyData = null
var health: float = 0.0
var state: State = State.WALKING

var trap_target: Node2D = null
var wall_target: Node2D = null

var animated_sprite: AnimatedSprite2D = null
var wall_detector: Area2D = null
var attack_timer: Timer = null
var collision_shape: CollisionShape2D = null

func _ready() -> void:
	add_to_group("enemies")

	_find_nodes()

	if attack_timer:
		attack_timer.one_shot = true

	if animated_sprite:
		if not animated_sprite.animation_finished.is_connected(
			_on_animation_finished
		):
			animated_sprite.animation_finished.connect(
				_on_animation_finished
			)

func _find_nodes() -> void:
	animated_sprite = find_child(
		"AnimatedSprite2D",
		true,
		false
	) as AnimatedSprite2D

	if not animated_sprite:
		push_error(
			"Enemy: AnimatedSprite2D not found."
		)

	wall_detector = find_child(
		"WallDetector",
		true,
		false
	) as Area2D

	if not wall_detector:
		push_error(
			"Enemy: WallDetector not found."
		)

	attack_timer = find_child(
		"AttackTimer",
		true,
		false
	) as Timer

	if not attack_timer:
		push_error(
			"Enemy: AttackTimer not found."
		)

	collision_shape = find_child(
		"CollisionShape2D",
		true,
		false
	) as CollisionShape2D

	if not collision_shape:
		push_error(
			"Enemy: CollisionShape2D not found."
		)

func setup(data: EnemyData) -> void:
	_find_nodes()

	if enemy_data == null:
		pass

	enemy_data = data

	if enemy_data == null:
		push_error(
			"Enemy setup failed: EnemyData is null."
		)
		return

	if animated_sprite == null:
		push_error(
			"Enemy setup failed: AnimatedSprite2D missing."
		)
		return

	if attack_timer == null:
		push_error(
			"Enemy setup failed: AttackTimer missing."
		)
		return

	if enemy_data.sprite_frames == null:
		push_error(
			"EnemyData has no SpriteFrames."
		)
		return

	health = enemy_data.max_health

	animated_sprite.sprite_frames = enemy_data.sprite_frames
	animated_sprite.scale = enemy_data.scale

	attack_timer.wait_time = max(
		enemy_data.attack_cooldown,
		0.01
	)

	state = State.WALKING
	trap_target = null
	wall_target = null

	if animated_sprite.sprite_frames.has_animation("walk"):
		animated_sprite.play("walk")

func _physics_process(_delta: float) -> void:
	if enemy_data == null:
		return

	if state == State.WALKING:
		_process_walking()

	elif state == State.ATTACKING_TRAP:
		_process_attacking_trap()

	elif state == State.ATTACKING_WALL:
		_process_attacking_wall()

	elif state == State.DYING:
		velocity = Vector2.ZERO

# ============================================================
# WALKING
# ============================================================

func _process_walking() -> void:
	# Trap has priority over wall.
	trap_target = _find_trap()

	if trap_target != null:
		_start_attacking_trap()
		return

	wall_target = _find_wall()

	if wall_target != null:
		_start_attacking_wall()
		return

	velocity.x = -enemy_data.move_speed
	velocity.y = 0.0

	move_and_slide()

	if animated_sprite:
		if animated_sprite.sprite_frames.has_animation("walk"):
			if animated_sprite.animation != "walk":
				animated_sprite.play("walk")

# ============================================================
# FIND TRAP
# ============================================================

func _find_trap() -> Node2D:
	if enemy_data == null:
		return null

	var traps: Array[Node] = get_tree().get_nodes_in_group(
		"traps"
	)

	var best_trap: Node2D = null
	var best_distance: float = INF

	for trap_node: Node in traps:
		if not is_instance_valid(trap_node):
			continue

		var trap := trap_node as Node2D

		if trap == null:
			continue

		if not _is_trap_valid(trap):
			continue

		var distance: float = global_position.distance_to(
			trap.global_position
		)

		if distance > enemy_data.trap_attack_range:
			continue

		if distance < best_distance:
			best_distance = distance
			best_trap = trap

	return best_trap

# ============================================================
# VALIDATE TRAP
# ============================================================

func _is_trap_valid(trap: Node2D) -> bool:
	if trap == null:
		return false

	if not is_instance_valid(trap):
		return false

	if not trap.is_in_group("traps"):
		return false

	if trap.get("is_destroyed") == true:
		return false

	if trap.get("health") != null:
		if trap.health <= 0.0:
			return false

	return true

# ============================================================
# ATTACK TRAP
# ============================================================

func _start_attacking_trap() -> void:
	if state == State.DYING:
		return

	if trap_target == null:
		state = State.WALKING
		return

	state = State.ATTACKING_TRAP
	velocity = Vector2.ZERO

	_play_attack_animation()

	_damage_trap()

func _process_attacking_trap() -> void:
	velocity = Vector2.ZERO

	if trap_target == null:
		_stop_attacking()
		return

	if not _is_trap_valid(trap_target):
		trap_target = null
		_stop_attacking()
		return

	var distance: float = global_position.distance_to(
		trap_target.global_position
	)

	if distance > enemy_data.trap_attack_range:
		trap_target = null
		_stop_attacking()
		return

	if attack_timer.is_stopped():
		_damage_trap()

func _damage_trap() -> void:
	if state != State.ATTACKING_TRAP:
		return

	if trap_target == null:
		_stop_attacking()
		return

	if not is_instance_valid(trap_target):
		trap_target = null
		_stop_attacking()
		return

	if not _is_trap_valid(trap_target):
		trap_target = null
		_stop_attacking()
		return

	var distance: float = global_position.distance_to(
		trap_target.global_position
	)

	if distance > enemy_data.trap_attack_range:
		trap_target = null
		_stop_attacking()
		return

	if trap_target.has_method("take_damage"):
		trap_target.take_damage(
			enemy_data.wall_damage
		)

		print(
			enemy_data.enemy_name,
			" attacked trap for ",
			enemy_data.wall_damage,
			" damage."
		)

	attack_timer.start()

# ============================================================
# FIND WALL
# ============================================================

func _find_wall() -> Node2D:
	if wall_detector == null:
		return null

	var bodies: Array[Node2D] = (
		wall_detector.get_overlapping_bodies()
	)

	for body: Node2D in bodies:
		if not is_instance_valid(body):
			continue

		if body.is_in_group("defense_wall"):
			return body

	return null

# ============================================================
# ATTACK WALL
# ============================================================

func _start_attacking_wall() -> void:
	if state == State.DYING:
		return

	state = State.ATTACKING_WALL
	velocity = Vector2.ZERO

	_play_attack_animation()

	_damage_wall()

func _process_attacking_wall() -> void:
	velocity = Vector2.ZERO

	if wall_target == null:
		wall_target = _find_wall()

	if wall_target == null:
		_stop_attacking()
		return

	if not is_instance_valid(wall_target):
		wall_target = null
		_stop_attacking()
		return

	if attack_timer.is_stopped():
		_damage_wall()

func _damage_wall() -> void:
	if state != State.ATTACKING_WALL:
		return

	if wall_target == null:
		_stop_attacking()
		return

	if not is_instance_valid(wall_target):
		wall_target = null
		_stop_attacking()
		return

	if wall_target.has_method("take_damage"):
		wall_target.take_damage(
			enemy_data.wall_damage
		)

	attack_timer.start()

# ============================================================
# ATTACK ANIMATION
# ============================================================

func _play_attack_animation() -> void:
	if animated_sprite == null:
		return

	if animated_sprite.sprite_frames.has_animation("attack"):
		if animated_sprite.animation != "attack":
			animated_sprite.play("attack")

# ============================================================
# STOP ATTACKING
# ============================================================

func _stop_attacking() -> void:
	if state == State.DYING:
		return

	trap_target = null
	wall_target = null

	attack_timer.stop()

	state = State.WALKING

	if animated_sprite:
		if animated_sprite.sprite_frames.has_animation("walk"):
			animated_sprite.play("walk")

# ============================================================
# TAKE DAMAGE
# ============================================================

func take_damage(amount: float) -> void:
	if state == State.DYING:
		return

	if amount <= 0.0:
		return

	health -= amount
	health = max(health, 0.0)

	print(
		enemy_data.enemy_name,
		" took ",
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
	if state == State.DYING:
		return

	state = State.DYING

	velocity = Vector2.ZERO

	trap_target = null
	wall_target = null

	if attack_timer:
		attack_timer.stop()

	if wall_detector:
		wall_detector.monitoring = false

	if collision_shape:
		collision_shape.set_deferred(
			"disabled",
			true
		)

	if animated_sprite:
		if animated_sprite.sprite_frames.has_animation("dead"):
			animated_sprite.play("dead")
		else:
			queue_free()

# ============================================================
# DEATH ANIMATION
# ============================================================

func _on_animation_finished() -> void:
	if state != State.DYING:
		return

	if animated_sprite == null:
		return

	if animated_sprite.animation != "dead":
		return

	queue_free()
