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
var is_cooldown: bool = false


# ============================================================
# VISUAL SETTINGS
# ============================================================

@export var cat_scale: Vector2 = Vector2(1.0, 1.0)


# ============================================================
# THEME
# ============================================================

const THEME_1: int = 0
const THEME_2: int = 1
const THEME_3: int = 2

var active_theme: int = THEME_1


# ============================================================
# NODES
# ============================================================

var visual_root: Node2D = null

var theme_1_root: Node2D = null
var theme_2_root: Node2D = null
var theme_3_root: Node2D = null

var theme_1_sprite: AnimatedSprite2D = null
var theme_2_sprite: AnimatedSprite2D = null
var theme_3_sprite: AnimatedSprite2D = null

var theme_1_shoot_fx: AnimatedSprite2D = null
var theme_2_shoot_fx: AnimatedSprite2D = null
var theme_3_shoot_fx: AnimatedSprite2D = null

var theme_1_attack_point: Marker2D = null
var theme_2_attack_point: Marker2D = null
var theme_3_attack_point: Marker2D = null

var animated_sprite: AnimatedSprite2D = null
var shoot_animation: AnimatedSprite2D = null
var attack_point: Marker2D = null

var animation_player: AnimationPlayer = null
var attack_timer: Timer = null


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	_find_nodes()

	if attack_timer:
		attack_timer.one_shot = true

		if not attack_timer.timeout.is_connected(
			_on_cooldown_finished
		):
			attack_timer.timeout.connect(
				_on_cooldown_finished
			)

	if animation_player:
		if not animation_player.animation_finished.is_connected(
			_on_animation_player_finished
		):
			animation_player.animation_finished.connect(
				_on_animation_player_finished
			)


# ============================================================
# FIND NODES
# ============================================================

func _find_nodes() -> void:
	visual_root = find_child(
		"VisualRoot",
		true,
		false
	) as Node2D

	if not visual_root:
		push_error(
			"Cat: VisualRoot not found."
		)
		return


	# --------------------------------------------------------
	# THEME ROOTS
	# --------------------------------------------------------

	theme_1_root = visual_root.get_node_or_null(
		"Theme1"
	) as Node2D

	theme_2_root = visual_root.get_node_or_null(
		"Theme2"
	) as Node2D

	theme_3_root = visual_root.get_node_or_null(
		"Theme3"
	) as Node2D


	if not theme_1_root:
		push_error(
			"Cat: Theme1 node not found under VisualRoot."
		)

	if not theme_2_root:
		push_error(
			"Cat: Theme2 node not found under VisualRoot."
		)

	if not theme_3_root:
		push_error(
			"Cat: Theme3 node not found under VisualRoot."
		)


	# --------------------------------------------------------
	# THEME 1
	# --------------------------------------------------------

	if theme_1_root:
		theme_1_sprite = theme_1_root.get_node_or_null(
			"AnimatedSprite2D"
		) as AnimatedSprite2D

		theme_1_shoot_fx = theme_1_root.get_node_or_null(
			"ShootFX"
		) as AnimatedSprite2D

		theme_1_attack_point = theme_1_root.get_node_or_null(
			"AttackPoint"
		) as Marker2D


	# --------------------------------------------------------
	# THEME 2
	# --------------------------------------------------------

	if theme_2_root:
		theme_2_sprite = theme_2_root.get_node_or_null(
			"AnimatedSprite2D"
		) as AnimatedSprite2D

		theme_2_shoot_fx = theme_2_root.get_node_or_null(
			"ShootFX"
		) as AnimatedSprite2D

		theme_2_attack_point = theme_2_root.get_node_or_null(
			"AttackPoint"
		) as Marker2D


	# --------------------------------------------------------
	# THEME 3
	# --------------------------------------------------------

	if theme_3_root:
		theme_3_sprite = theme_3_root.get_node_or_null(
			"AnimatedSprite2D"
		) as AnimatedSprite2D

		theme_3_shoot_fx = theme_3_root.get_node_or_null(
			"ShootFX"
		) as AnimatedSprite2D

		theme_3_attack_point = theme_3_root.get_node_or_null(
			"AttackPoint"
		) as Marker2D


	# --------------------------------------------------------
	# VALIDATION
	# --------------------------------------------------------

	if not theme_1_sprite:
		push_error(
			"Cat: Theme1 AnimatedSprite2D not found."
		)

	if not theme_1_shoot_fx:
		push_error(
			"Cat: Theme1 ShootFX not found."
		)

	if not theme_1_attack_point:
		push_error(
			"Cat: Theme1 AttackPoint not found."
		)

	if not theme_2_sprite:
		push_error(
			"Cat: Theme2 AnimatedSprite2D not found."
		)

	if not theme_2_shoot_fx:
		push_error(
			"Cat: Theme2 ShootFX not found."
		)

	if not theme_2_attack_point:
		push_error(
			"Cat: Theme2 AttackPoint not found."
		)

	if not theme_3_sprite:
		push_error(
			"Cat: Theme3 AnimatedSprite2D not found."
		)

	if not theme_3_shoot_fx:
		push_error(
			"Cat: Theme3 ShootFX not found."
		)

	if not theme_3_attack_point:
		push_error(
			"Cat: Theme3 AttackPoint not found."
		)


	# --------------------------------------------------------
	# SHARED NODES
	# --------------------------------------------------------

	animation_player = find_child(
		"AnimationPlayer",
		true,
		false
	) as AnimationPlayer

	if not animation_player:
		push_error(
			"Cat: AnimationPlayer not found."
		)

	attack_timer = find_child(
		"AttackTimer",
		true,
		false
	) as Timer

	if not attack_timer:
		push_error(
			"Cat: AttackTimer not found."
		)


# ============================================================
# INITIALIZE CAT
# ============================================================

func init(
	level_value: int,
	tex: Texture2D
) -> void:

	if not animation_player or not attack_timer:
		_find_nodes()

	if not animation_player or not attack_timer:
		return

	level = level_value
	texture = tex

	cat_data = CatManager.get_cat_data(level)

	if not cat_data:
		push_error(
			"CatData not found for cat level %d."
			% level
		)
		return

	if not cat_data.sprite_frames:
		push_error(
			"CatData for Level %d has no SpriteFrames."
			% level
		)
		return


	# --------------------------------------------------------
	# SET THEME
	# --------------------------------------------------------

	active_theme = cat_data.theme_id

	_setup_theme()


	# --------------------------------------------------------
	# SET SPRITE FRAMES
	# --------------------------------------------------------

	if animated_sprite:
		animated_sprite.sprite_frames = (
			cat_data.sprite_frames
		)

		if animated_sprite.sprite_frames.has_animation(
			"idle"
		):
			animated_sprite.play("idle")
		else:
			push_error(
				"Cat Level %d has no idle animation."
				% level
			)


	# --------------------------------------------------------
	# SCALE
	# --------------------------------------------------------

	if visual_root:
		visual_root.scale = cat_scale


	# --------------------------------------------------------
	# ATTACK TIMER
	# --------------------------------------------------------

	attack_timer.wait_time = max(
		cat_data.attack_cooldown,
		0.01
	)


	# --------------------------------------------------------
	# RESET SHOOT FX
	# --------------------------------------------------------

	_hide_all_shoot_fx()


# ============================================================
# SETUP ACTIVE THEME
# ============================================================

func _setup_theme() -> void:
	# Hide everything first.
	if theme_1_root:
		theme_1_root.visible = false

	if theme_2_root:
		theme_2_root.visible = false

	if theme_3_root:
		theme_3_root.visible = false


	# --------------------------------------------------------
	# THEME 1
	# --------------------------------------------------------

	if active_theme == THEME_1:
		if theme_1_root:
			theme_1_root.visible = true

		animated_sprite = theme_1_sprite
		shoot_animation = theme_1_shoot_fx
		attack_point = theme_1_attack_point

		return


	# --------------------------------------------------------
	# THEME 2
	# --------------------------------------------------------

	if active_theme == THEME_2:
		if theme_2_root:
			theme_2_root.visible = true

		animated_sprite = theme_2_sprite
		shoot_animation = theme_2_shoot_fx
		attack_point = theme_2_attack_point

		return


	# --------------------------------------------------------
	# THEME 3
	# --------------------------------------------------------

	if active_theme == THEME_3:
		if theme_3_root:
			theme_3_root.visible = true

		animated_sprite = theme_3_sprite
		shoot_animation = theme_3_shoot_fx
		attack_point = theme_3_attack_point

		return


	# --------------------------------------------------------
	# INVALID THEME
	# --------------------------------------------------------

	push_error(
		"Cat Level %d has invalid theme_id: %d."
		% [
			level,
			active_theme
		]
	)

	active_theme = THEME_1

	if theme_1_root:
		theme_1_root.visible = true

	animated_sprite = theme_1_sprite
	shoot_animation = theme_1_shoot_fx
	attack_point = theme_1_attack_point


# ============================================================
# HIDE ALL SHOOT FX
# ============================================================

func _hide_all_shoot_fx() -> void:
	if theme_1_shoot_fx:
		theme_1_shoot_fx.visible = false
		theme_1_shoot_fx.stop()

	if theme_2_shoot_fx:
		theme_2_shoot_fx.visible = false
		theme_2_shoot_fx.stop()

	if theme_3_shoot_fx:
		theme_3_shoot_fx.visible = false
		theme_3_shoot_fx.stop()


# ============================================================
# COMBAT ACTIVE
# ============================================================

func set_combat_active(
	active: bool
) -> void:

	combat_active = active

	if not active:
		current_target = null
		is_shooting = false
		is_cooldown = false

		if attack_timer:
			attack_timer.stop()

		if animation_player:
			animation_player.stop()

		_hide_all_shoot_fx()

		if visual_root:
			visual_root.rotation = 0.0

		if animated_sprite and animated_sprite.sprite_frames:
			if animated_sprite.sprite_frames.has_animation(
				"idle"
			):
				animated_sprite.play("idle")


# ============================================================
# PHYSICS PROCESS
# ============================================================

func _physics_process(
	_delta: float
) -> void:

	if not combat_active:
		return

	if not cat_data:
		return

	if not attack_timer:
		return

	if is_shooting or is_cooldown:
		return

	current_target = _find_target()

	if not current_target:
		_play_idle()
		return

	_start_attack()


# ============================================================
# FIND TARGET
# ============================================================

func _find_target() -> Node2D:
	if not cat_data:
		return null

	var enemies: Array[Node] = (
		get_tree().get_nodes_in_group("enemies")
	)

	var best_target: Node2D = null
	var best_distance: float = INF

	for enemy_node: Node in enemies:
		if not is_instance_valid(enemy_node):
			continue

		var enemy: Node2D = enemy_node as Node2D

		if enemy == null:
			continue

		var distance: float = (
			global_position.distance_to(
				enemy.global_position
			)
		)

		if distance > cat_data.attack_range:
			continue

		if distance < best_distance:
			best_distance = distance
			best_target = enemy

	return best_target


# ============================================================
# START ATTACK
# ============================================================

func _start_attack() -> void:
	if not current_target:
		return

	if not is_instance_valid(current_target):
		current_target = null
		return

	if not _is_target_in_range(current_target):
		current_target = null
		return

	if not animation_player:
		return


	# --------------------------------------------------------
	# ROTATE TOWARD TARGET
	# --------------------------------------------------------

	_rotate_toward_target()


	# --------------------------------------------------------
	# GET THEME-SPECIFIC SHOOT ANIMATION
	# --------------------------------------------------------

	var shoot_animation_name: StringName = (
		_get_shoot_animation_name()
	)

	if not animation_player.has_animation(
		shoot_animation_name
	):
		push_error(
			"Cat Level %d does not have animation '%s'."
			% [
				level,
				shoot_animation_name
			]
		)

		# Fire anyway so the cat doesn't become permanently stuck.
		fire_projectile()

		is_cooldown = true
		attack_timer.start()

		return


	# --------------------------------------------------------
	# SHOOT FX
	# --------------------------------------------------------

	is_shooting = true

	_hide_all_shoot_fx()

	if shoot_animation:
		shoot_animation.visible = true
		shoot_animation.play("shoot_fx")


	# --------------------------------------------------------
	# ANIMATION PLAYER
	# --------------------------------------------------------

	animation_player.play(
		shoot_animation_name
	)


# ============================================================
# GET THEME SHOOT ANIMATION
# ============================================================

func _get_shoot_animation_name() -> StringName:
	match active_theme:
		THEME_1:
			return &"Shoot_Theme1"

		THEME_2:
			return &"Shoot_Theme2"

		THEME_3:
			return &"Shoot_Theme3"

	return &"Shoot_Theme1"


# ============================================================
# ROTATE TOWARD TARGET
# ============================================================

func _rotate_toward_target() -> void:
	if not current_target:
		return

	if not is_instance_valid(current_target):
		return

	if not visual_root:
		return

	var direction: Vector2 = (
		current_target.global_position
		- global_position
	)

	if direction.length_squared() <= 0.001:
		return

	visual_root.rotation = direction.angle()


# ============================================================
# FIRE PROJECTILE
# ============================================================

func fire_projectile() -> void:
	if not cat_data:
		return

	if not current_target:
		return

	if not is_instance_valid(current_target):
		current_target = null
		return

	if not _is_target_in_range(current_target):
		current_target = null
		return

	if not attack_point:
		push_error(
			"Cannot fire projectile. "
			+ "Active theme AttackPoint is missing."
		)
		return

	if not cat_data.projectile_scene:
		push_error(
			"No projectile scene configured "
			+ "for Cat Level %d."
			% level
		)
		return


	var projectile: Node2D = (
		cat_data.projectile_scene.instantiate()
		as Node2D
	)

	if not projectile:
		push_error(
			"Could not instantiate projectile."
		)
		return


	var current_scene: Node = (
		get_tree().current_scene
	)

	if not current_scene:
		push_error(
			"Current gameplay scene not found."
		)

		projectile.queue_free()
		return


	current_scene.add_child(projectile)


	# --------------------------------------------------------
	# THEME-SPECIFIC PROJECTILE ORIGIN
	# --------------------------------------------------------

	projectile.global_position = (
		attack_point.global_position
	)


	# --------------------------------------------------------
	# PROJECTILE SETUP
	# --------------------------------------------------------

	if projectile.has_method("setup"):
		projectile.setup(
			current_target,
			cat_data.damage,
			cat_data.projectile_speed
		)
	else:
		push_error(
			"Projectile does not have a setup() function."
		)

		projectile.queue_free()


# ============================================================
# TARGET RANGE
# ============================================================

func _is_target_in_range(
	target: Node2D
) -> bool:

	if not is_instance_valid(target):
		return false

	if not cat_data:
		return false

	var distance: float = (
		global_position.distance_to(
			target.global_position
		)
	)

	return distance <= cat_data.attack_range


# ============================================================
# IDLE
# ============================================================

func _play_idle() -> void:
	if animation_player:
		if animation_player.has_animation("idle"):
			if animation_player.current_animation != "idle":
				animation_player.play("idle")

	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation(
			"idle"
		):
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")


# ============================================================
# ANIMATION FINISHED
# ============================================================

func _on_animation_player_finished(
	anim_name: StringName
) -> void:

	if anim_name != &"Shoot_Theme1" \
	and anim_name != &"Shoot_Theme2" \
	and anim_name != &"Shoot_Theme3":
		return


	is_shooting = false
	is_cooldown = true


	_hide_all_shoot_fx()


	if attack_timer:
		attack_timer.start()


	_play_idle()


# ============================================================
# COOLDOWN FINISHED
# ============================================================

func _on_cooldown_finished() -> void:
	is_cooldown = false
