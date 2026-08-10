class_name Enemy
extends CharacterBody2D

enum State {
	WALKING,
	ATTACKING,
	DYING
}

var enemy_data: EnemyData = null
var health: float = 0.0
var state: State = State.WALKING
var wall_target: Node2D = null

var animated_sprite: AnimatedSprite2D = null
var wall_detector: Area2D = null
var attack_timer: Timer = null
var collision_shape: CollisionShape2D = null

func _ready() -> void:
	_find_nodes()

	if attack_timer:
		attack_timer.one_shot = true

	if animated_sprite:
		if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
			animated_sprite.animation_finished.connect(_on_animation_finished)

func _find_nodes() -> void:
	animated_sprite = find_child(
		"AnimatedSprite2D",
		true,
		false
	) as AnimatedSprite2D

	if not animated_sprite:
		push_error(
			"Enemy: AnimatedSprite2D not found in Enemy scene."
		)

	wall_detector = find_child(
		"WallDetector",
		true,
		false
	) as Area2D

	if not wall_detector:
		push_error(
			"Enemy: WallDetector not found in Enemy scene."
		)

	attack_timer = find_child(
		"AttackTimer",
		true,
		false
	) as Timer

	if not attack_timer:
		push_error(
			"Enemy: AttackTimer not found in Enemy scene."
		)

	collision_shape = find_child(
		"CollisionShape2D",
		true,
		false
	) as CollisionShape2D

	if not collision_shape:
		push_error(
			"Enemy: CollisionShape2D not found in Enemy scene."
		)

func setup(data: EnemyData) -> void:
	if not animated_sprite or not wall_detector or not attack_timer:
		_find_nodes()

	if not animated_sprite:
		push_error(
			"Enemy setup failed: AnimatedSprite2D is missing."
		)
		return

	if not attack_timer:
		push_error(
			"Enemy setup failed: AttackTimer is missing."
		)
		return

	enemy_data = data

	if enemy_data == null:
		push_error(
			"Enemy setup failed: EnemyData is null."
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

	attack_timer.wait_time = enemy_data.attack_cooldown

	state = State.WALKING
	wall_target = null

	if animated_sprite.sprite_frames.has_animation("walk"):
		animated_sprite.play("walk")
	else:
		push_error(
			"Enemy '%s' has no walk animation."
			% enemy_data.enemy_name
		)

func _physics_process(_delta: float) -> void:
	if enemy_data == null:
		return

	if state == State.WALKING:
		_process_walking()

	elif state == State.ATTACKING:
		_process_attacking()

	elif state == State.DYING:
		velocity = Vector2.ZERO

func _process_walking() -> void:
	wall_target = _find_wall()

	if wall_target != null:
		_start_attacking()
		return

	velocity.x = -enemy_data.move_speed
	velocity.y = 0.0

	move_and_slide()

	if animated_sprite and animated_sprite.animation != "walk":
		if animated_sprite.sprite_frames.has_animation("walk"):
			animated_sprite.play("walk")

func _process_attacking() -> void:
	velocity = Vector2.ZERO

	if wall_target == null or not is_instance_valid(wall_target):
		wall_target = _find_wall()

	if wall_target == null:
		_stop_attacking()
		return

	if attack_timer.is_stopped():
		_damage_wall()

func _find_wall() -> Node2D:
	if wall_detector == null:
		return null

	var bodies: Array[Node2D] = wall_detector.get_overlapping_bodies()

	for body in bodies:
		if not is_instance_valid(body):
			continue

		if body.is_in_group("defense_wall"):
			return body

	return null

func _start_attacking() -> void:
	if state == State.DYING:
		return

	state = State.ATTACKING
	velocity = Vector2.ZERO

	if animated_sprite:
		if animated_sprite.sprite_frames.has_animation("attack"):
			if animated_sprite.animation != "attack":
				animated_sprite.play("attack")

	_damage_wall()

func _damage_wall() -> void:
	if state != State.ATTACKING:
		return

	if wall_target == null:
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

func _stop_attacking() -> void:
	if state == State.DYING:
		return

	state = State.WALKING
	wall_target = null

	attack_timer.stop()

	if animated_sprite:
		if animated_sprite.sprite_frames.has_animation("walk"):
			animated_sprite.play("walk")

func take_damage(amount: float) -> void:
	if state == State.DYING:
		return

	health -= amount

	print(
		enemy_data.enemy_name,
		" took ",
		amount,
		" damage. HP: ",
		health
	)

	if health <= 0.0:
		die()

func die() -> void:
	if state == State.DYING:
		return

	state = State.DYING
	velocity = Vector2.ZERO

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

func _on_animation_finished() -> void:
	if state != State.DYING:
		return

	if not animated_sprite:
		return

	if animated_sprite.animation != "dead":
		return

	queue_free()
