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

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_detector: Area2D = $WallDetector
@onready var attack_timer: Timer = $AttackTimer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	attack_timer.one_shot = true

	if not animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.connect(_on_animation_finished)

func setup(data: EnemyData) -> void:
	enemy_data = data

	if enemy_data == null:
		push_error("Enemy setup failed: EnemyData is null.")
		return

	health = enemy_data.max_health
	animated_sprite.sprite_frames = enemy_data.sprite_frames
	animated_sprite.scale = enemy_data.scale

	attack_timer.wait_time = enemy_data.attack_cooldown

	state = State.WALKING
	wall_target = null

	animated_sprite.play("walk")

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

	if animated_sprite.animation != "walk":
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

	for body: Node2D in bodies:
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
		wall_target.take_damage(enemy_data.wall_damage)

	attack_timer.start()

func _stop_attacking() -> void:
	if state == State.DYING:
		return

	state = State.WALKING
	wall_target = null
	attack_timer.stop()
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

	if wall_detector != null:
		wall_detector.monitoring = false

	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)

	animated_sprite.play("dead")

func _on_animation_finished() -> void:
	if state != State.DYING:
		return

	if animated_sprite.animation != "dead":
		return

	queue_free()
