class_name Cat
extends Node2D

var level: int = 1
var texture: Texture2D
var cat_data: CatData = null

var combat_active: bool = false
var current_target: Node2D = null
var is_shooting: bool = false      # animation is playing
var is_cooldown: bool = false      # cooldown timer is running (after animation)

@export var cat_scale: Vector2 = Vector2(1.0, 1.0)

var animated_sprite: AnimatedSprite2D = null
var animation_player: AnimationPlayer = null
var attack_point: Marker2D = null
var target_detector: Area2D = null
var attack_timer: Timer = null

func _ready() -> void:
	_find_nodes()
	if attack_timer:
		attack_timer.one_shot = true
		attack_timer.timeout.connect(_on_cooldown_finished)
	if animation_player:
		if not animation_player.animation_finished.is_connected(_on_animation_player_finished):
			animation_player.animation_finished.connect(_on_animation_player_finished)

func _find_nodes() -> void:
	var sprites: Array[Node] = find_children("*", "AnimatedSprite2D", true, false)
	animated_sprite = sprites[0] if sprites.size() > 0 else null
	if not animated_sprite:
		push_error("Cat: AnimatedSprite2D not found.")

	animation_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	if not animation_player:
		push_error("Cat: AnimationPlayer not found.")

	attack_point = find_child("AttackPoint", true, false) as Marker2D
	if not attack_point:
		push_error("Cat: AttackPoint not found.")

	target_detector = find_child("TargetDetector", true, false) as Area2D
	if not target_detector:
		push_error("Cat: TargetDetector not found.")

	attack_timer = find_child("AttackTimer", true, false) as Timer
	if not attack_timer:
		push_error("Cat: AttackTimer not found.")

func init(level_value: int, tex: Texture2D) -> void:
	if not animated_sprite or not animation_player or not attack_timer:
		_find_nodes()
	if not animated_sprite or not animation_player or not attack_timer:
		return

	level = level_value
	texture = tex

	cat_data = CatManager.get_cat_data(level)
	if not cat_data:
		push_error("CatData not found for cat level %d." % level)
		return

	if not cat_data.sprite_frames:
		push_error("CatData for Level %d has no SpriteFrames." % level)
		return

	animated_sprite.sprite_frames = cat_data.sprite_frames
	animated_sprite.scale = cat_scale

	# Play idle initially
	if animated_sprite.sprite_frames.has_animation("idle"):
		animated_sprite.play("idle")
	else:
		push_error("Cat Level %d has no idle animation." % level)

	attack_timer.wait_time = cat_data.attack_cooldown
	_setup_detection_range()

func set_combat_active(active: bool) -> void:
	combat_active = active
	if target_detector:
		target_detector.monitoring = active
	if not active:
		current_target = null
		is_shooting = false
		is_cooldown = false
		if attack_timer:
			attack_timer.stop()
		# Play idle
		if animation_player and animation_player.has_animation("idle"):
			animation_player.play("idle")
		elif animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")

func _setup_detection_range() -> void:
	if not cat_data or not target_detector:
		return
	var collision: CollisionShape2D = target_detector.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not collision:
		push_error("TargetDetector requires a CollisionShape2D.")
		return
	var circle = collision.shape as CircleShape2D
	if not circle:
		circle = CircleShape2D.new()
		collision.shape = circle
	circle.radius = cat_data.attack_range

func _physics_process(_delta: float) -> void:
	# Do nothing if not combat ready or missing dependencies
	if not combat_active or not cat_data or not target_detector or not attack_timer:
		return

	# If we are currently shooting or in cooldown, skip attack logic
	if is_shooting or is_cooldown:
		return

	# Find target
	current_target = _find_target()

	if not current_target:
		# No target – play idle if not already
		if animation_player and animation_player.has_animation("idle"):
			if animation_player.current_animation != "idle":
				animation_player.play("idle")
		elif animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("idle"):
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")
		return

	# Target exists and timer is stopped – start attack
	_start_attack()

func _find_target() -> Node2D:
	if not target_detector:
		return null
	var bodies: Array[Node2D] = target_detector.get_overlapping_bodies()
	var best_target: Node2D = null
	var best_distance: float = INF
	for body in bodies:
		if not is_instance_valid(body):
			continue
		if not body.is_in_group("enemies"):
			continue
		var distance: float = global_position.distance_to(body.global_position)
		if distance < best_distance:
			best_distance = distance
			best_target = body
	return best_target

func _start_attack() -> void:
	if not current_target or not is_instance_valid(current_target):
		current_target = null
		return

	if not animation_player:
		return

	if not animation_player.has_animation("shoot"):
		push_error("Cat Level %d does not have a shoot animation." % level)
		# Fallback: fire and start cooldown immediately
		fire_projectile()
		is_cooldown = true
		attack_timer.start()
		return

	# Play shoot animation – this will trigger fire_projectile via animation track
	is_shooting = true
	animation_player.play("shoot")

func fire_projectile() -> void:
	if not cat_data or not current_target or not is_instance_valid(current_target):
		return
	if not attack_point:
		push_error("Cannot fire projectile. AttackPoint is missing.")
		return
	if not cat_data.projectile_scene:
		push_error("No projectile scene configured for Cat Level %d." % level)
		return

	var projectile: Node2D = cat_data.projectile_scene.instantiate() as Node2D
	if not projectile:
		push_error("Could not instantiate projectile.")
		return

	var current_scene: Node = get_tree().current_scene
	if not current_scene:
		push_error("Current gameplay scene not found.")
		projectile.queue_free()
		return

	current_scene.add_child(projectile)
	projectile.global_position = attack_point.global_position

	if projectile.has_method("setup"):
		projectile.setup(current_target, cat_data.damage, cat_data.projectile_speed)
	else:
		push_error("Projectile does not have a setup() function.")
		projectile.queue_free()

func _on_animation_player_finished(anim_name: StringName) -> void:
	if anim_name == "shoot":
		is_shooting = false
		# Start the cooldown timer
		is_cooldown = true
		attack_timer.start()
		# Play idle while cooldown is active
		if animation_player and animation_player.has_animation("idle"):
			animation_player.play("idle")
		elif animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("idle"):
			animated_sprite.play("idle")

func _on_cooldown_finished() -> void:
	is_cooldown = false
	# Now the cat can attack again in the next physics frame
