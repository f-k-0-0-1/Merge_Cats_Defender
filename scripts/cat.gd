class_name Cat
extends Node2D


# ============================================================
# CAT DATA
# ============================================================

var level: int = 1
var texture: Texture2D

var cat_data: CatData = null


# ============================================================
# COMBAT STATE
# ============================================================

var combat_active: bool = false
var current_target: Node2D = null
var is_shooting: bool = false


# ============================================================
# VISUAL SETTINGS
# ============================================================

@export var cat_scale: Vector2 = Vector2(1.0, 1.0)


# ============================================================
# NODE REFERENCES
# ============================================================

var animated_sprite: AnimatedSprite2D = null
var attack_point: Marker2D = null
var target_detector: Area2D = null
var attack_timer: Timer = null


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	_find_nodes()

	if animated_sprite == null:
		return

	if attack_timer == null:
		return


	# AttackTimer controls the delay between attacks.
	attack_timer.one_shot = true


	# Detect when the shoot animation finishes.
	if not animated_sprite.animation_finished.is_connected(
		_on_animation_finished
	):

		animated_sprite.animation_finished.connect(
			_on_animation_finished
	)


# ============================================================
# FIND REQUIRED NODES
# ============================================================

func _find_nodes() -> void:

	# --------------------------------------------------------
	# Find AnimatedSprite2D by TYPE.
	#
	# This works even if your node is named:
	#
	# Sprite
	# CatSprite
	# AnimatedSprite
	# AnimatedSprite2D
	# etc.
	# --------------------------------------------------------

	var sprites: Array[Node] = find_children(
		"*",
		"AnimatedSprite2D",
		true,
		false
	)


	if sprites.size() > 0:

		animated_sprite = sprites[0] as AnimatedSprite2D


	else:

		push_error(
			"CAT ERROR: No AnimatedSprite2D found inside cat.tscn."
		)


	# --------------------------------------------------------
	# Find AttackPoint.
	# --------------------------------------------------------

	attack_point = find_child(
		"AttackPoint",
		true,
		false
	) as Marker2D


	if attack_point == null:

		push_error(
			"CAT ERROR: AttackPoint (Marker2D) not found."
		)


	# --------------------------------------------------------
	# Find TargetDetector.
	# --------------------------------------------------------

	target_detector = find_child(
		"TargetDetector",
		true,
		false
	) as Area2D


	if target_detector == null:

		push_error(
			"CAT ERROR: TargetDetector (Area2D) not found."
		)


	# --------------------------------------------------------
	# Find AttackTimer.
	# --------------------------------------------------------

	attack_timer = find_child(
		"AttackTimer",
		true,
		false
	) as Timer


	if attack_timer == null:

		push_error(
			"CAT ERROR: AttackTimer (Timer) not found."
		)


# ============================================================
# INITIALIZE CAT
# ============================================================

func init(
	level_value: int,
	tex: Texture2D
) -> void:

	# Make absolutely sure references exist.
	if animated_sprite == null:
		_find_nodes()


	# --------------------------------------------------------
	# Validate required nodes.
	# --------------------------------------------------------

	if animated_sprite == null:

		push_error(
			"Cannot initialize Cat. "
			+ "No AnimatedSprite2D exists in cat.tscn."
		)

		return


	if attack_timer == null:

		push_error(
			"Cannot initialize Cat. "
			+ "AttackTimer is missing."
		)

		return


	# --------------------------------------------------------
	# Store basic information.
	# --------------------------------------------------------

	level = level_value
	texture = tex


	# --------------------------------------------------------
	# Get CatData.
	# --------------------------------------------------------

	cat_data = CatManager.get_cat_data(
		level
	)


	if cat_data == null:

		push_error(
			"CatData not found for cat level %d."
			% level
		)

		return


	# ========================================================
	# CONFIGURE SPRITE FRAMES
	# ========================================================

	if cat_data.sprite_frames == null:

		push_error(
			"CatData for Level %d has no SpriteFrames."
			% level
		)

		return


	animated_sprite.sprite_frames = (
		cat_data.sprite_frames
	)


	# ========================================================
	# CONFIGURE SCALE
	# ========================================================

	animated_sprite.scale = cat_scale


	# ========================================================
	# START IDLE
	# ========================================================

	if animated_sprite.sprite_frames.has_animation(
		"idle"
	):

		animated_sprite.play("idle")

	else:

		push_error(
			"Cat Level %d has no 'idle' animation."
			% level
		)


	# ========================================================
	# CONFIGURE ATTACK TIMER
	# ========================================================

	attack_timer.wait_time = (
		cat_data.attack_cooldown
	)


	# ========================================================
	# CONFIGURE DETECTION RANGE
	# ========================================================

	_setup_detection_range()


# ============================================================
# SET COMBAT ACTIVE
# ============================================================

func set_combat_active(
	active: bool
) -> void:

	combat_active = active


	# --------------------------------------------------------
	# Enable / disable target detection.
	# --------------------------------------------------------

	if target_detector != null:

		target_detector.monitoring = active


	# --------------------------------------------------------
	# Cat removed from combat.
	# --------------------------------------------------------

	if not active:

		current_target = null

		is_shooting = false


		if attack_timer != null:

			attack_timer.stop()


		if animated_sprite != null:

			if animated_sprite.sprite_frames != null:

				if animated_sprite.sprite_frames.has_animation(
					"idle"
				):

					animated_sprite.play("idle")


# ============================================================
# SETUP TARGET DETECTION RANGE
# ============================================================

func _setup_detection_range() -> void:

	if cat_data == null:
		return


	if target_detector == null:

		push_error(
			"Cannot setup detection range. "
			+ "TargetDetector is missing."
		)

		return


	var collision: CollisionShape2D = (
		target_detector.get_node_or_null(
			"CollisionShape2D"
		) as CollisionShape2D
	)


	if collision == null:

		push_error(
			"TargetDetector requires "
			+ "a CollisionShape2D."
		)

		return


	var circle: CircleShape2D = (
		collision.shape as CircleShape2D
	)


	if circle == null:

		circle = CircleShape2D.new()

		collision.shape = circle


	circle.radius = cat_data.attack_range


# ============================================================
# COMBAT LOOP
# ============================================================

func _physics_process(
	_delta: float
) -> void:

	# --------------------------------------------------------
	# Cat only fights when deployed.
	# --------------------------------------------------------

	if not combat_active:
		return


	# --------------------------------------------------------
	# Validate combat nodes.
	# --------------------------------------------------------

	if cat_data == null:
		return


	if target_detector == null:
		return


	if attack_timer == null:
		return


	if animated_sprite == null:
		return


	# --------------------------------------------------------
	# Don't search for another target while shooting.
	# --------------------------------------------------------

	if is_shooting:
		return


	# --------------------------------------------------------
	# Find enemy.
	# --------------------------------------------------------

	current_target = _find_target()


	# ========================================================
	# NO TARGET
	# ========================================================

	if current_target == null:

		if animated_sprite.animation != "idle":

			animated_sprite.play("idle")

		return


	# ========================================================
	# TARGET FOUND
	# ========================================================

	if attack_timer.is_stopped():

		_start_attack()


# ============================================================
# FIND TARGET
# ============================================================

func _find_target() -> Node2D:

	print(
		"\n========== CAT TARGET DEBUG =========="
	)

	print(
		"Cat Level: ",
		level
	)

	# --------------------------------------------------------
	# Check detector
	# --------------------------------------------------------

	if target_detector == null:

		print(
			"[ERROR] TargetDetector is NULL"
		)

		return null


	print(
		"TargetDetector monitoring: ",
		target_detector.monitoring
	)

	print(
		"TargetDetector monitorable: ",
		target_detector.monitorable
	)


	# --------------------------------------------------------
	# Get detected bodies
	# --------------------------------------------------------

	var bodies: Array[Node2D] = (
		target_detector.get_overlapping_bodies()
	)


	print(
		"Detected bodies: ",
		bodies.size()
	)


	# --------------------------------------------------------
	# No bodies detected
	# --------------------------------------------------------

	if bodies.is_empty():

		print(
			"[NO TARGET] TargetDetector detected "
			+ "no physics bodies."
		)

		print(
			"======================================"
		)

		return null


	# --------------------------------------------------------
	# Find closest enemy
	# --------------------------------------------------------

	var best_target: Node2D = null

	var best_distance: float = INF


	for body: Node2D in bodies:

		# ----------------------------------------------------
		# Invalid body
		# ----------------------------------------------------

		if not is_instance_valid(body):

			print(
				"[SKIP] Invalid body."
			)

			continue


		print(
			"[DETECTED] ",
			body.name,
			" | Type: ",
			body.get_class(),
			" | Groups: ",
			body.get_groups()
		)


		# ----------------------------------------------------
		# Check enemy group
		# ----------------------------------------------------

		if not body.is_in_group("enemies"):

			print(
				"[REJECTED] ",
				body.name,
				" is NOT in 'enemies' group."
			)

			continue


		print(
			"[VALID ENEMY] ",
			body.name
		)


		# ----------------------------------------------------
		# Calculate distance
		# ----------------------------------------------------

		var distance: float = (
			global_position.distance_to(
				body.global_position
			)
		)


		print(
			"    Distance: ",
			distance
		)


		# ----------------------------------------------------
		# Check if closest
		# ----------------------------------------------------

		if distance < best_distance:

			best_distance = distance

			best_target = body


			print(
				"    [NEW BEST TARGET] ",
				body.name
			)


	# --------------------------------------------------------
	# Final result
	# --------------------------------------------------------

	if best_target != null:

		print(
			"[TARGET SELECTED] ",
			best_target.name,
			" | Distance: ",
			best_distance
		)

	else:

		print(
			"[NO VALID ENEMY FOUND]"
		)


	print(
		"======================================"
	)


	return best_target


# ============================================================
# START ATTACK
# ============================================================

func _start_attack() -> void:

	if current_target == null:
		return


	if not is_instance_valid(
		current_target
	):

		current_target = null

		return


	if animated_sprite == null:
		return


	if animated_sprite.sprite_frames == null:

		push_error(
			"Cat Level %d has no SpriteFrames."
			% level
		)

		return


	# --------------------------------------------------------
	# Make sure shoot animation exists.
	# --------------------------------------------------------

	if not animated_sprite.sprite_frames.has_animation(
		"shoot"
	):

		push_error(
			"Cat Level %d does not have "
			+ "a 'shoot' animation."
			% level
		)

		return


	# --------------------------------------------------------
	# Start shooting.
	# --------------------------------------------------------

	is_shooting = true

	animated_sprite.play(
		"shoot"
	)


# ============================================================
# FIRE PROJECTILE
# ============================================================

func fire_projectile() -> void:

	# --------------------------------------------------------
	# Validate data.
	# --------------------------------------------------------

	if cat_data == null:
		return


	if current_target == null:
		return


	if not is_instance_valid(
		current_target
	):

		current_target = null

		return


	# --------------------------------------------------------
	# Validate AttackPoint.
	# --------------------------------------------------------

	if attack_point == null:

		push_error(
			"Cannot fire projectile. "
			+ "AttackPoint is missing."
		)

		return


	# --------------------------------------------------------
	# Validate projectile scene.
	# --------------------------------------------------------

	if cat_data.projectile_scene == null:

		push_error(
			"No projectile scene configured "
			+ "for Cat Level %d."
			% level
		)

		return


	# ========================================================
	# CREATE PROJECTILE
	# ========================================================

	var projectile: Node2D = (
		cat_data.projectile_scene.instantiate()
		as Node2D
	)


	if projectile == null:

		push_error(
			"Could not instantiate projectile."
		)

		return


	# --------------------------------------------------------
	# Add to gameplay scene.
	# --------------------------------------------------------

	var current_scene: Node = (
		get_tree().current_scene
	)


	if current_scene == null:

		push_error(
			"Current gameplay scene not found."
		)

		projectile.queue_free()

		return


	current_scene.add_child(
		projectile
	)


	# --------------------------------------------------------
	# Spawn at AttackPoint.
	# --------------------------------------------------------

	projectile.global_position = (
		attack_point.global_position
	)


	# --------------------------------------------------------
	# Give projectile its data.
	# --------------------------------------------------------

	if projectile.has_method(
		"setup"
	):

		projectile.setup(
			current_target,
			cat_data.damage,
			cat_data.projectile_speed
		)

	else:

		push_error(
			"Projectile does not have "
			+ "a setup() function."
		)

		projectile.queue_free()


# ============================================================
# SHOOT ANIMATION FINISHED
# ============================================================

func _on_animation_finished() -> void:

	if animated_sprite == null:
		return

	if animated_sprite.animation != "shoot":
		return


	# Fire projectile when the shooting animation finishes.
	fire_projectile()


	# Shooting is finished.
	is_shooting = false


	# Start attack cooldown.
	if attack_timer != null:
		attack_timer.start()


	# Return to idle.
	if animated_sprite.sprite_frames != null:

		if animated_sprite.sprite_frames.has_animation(
			"idle"
		):

			animated_sprite.play("idle")
