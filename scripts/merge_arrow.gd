extends TextureRect

@export var rotation_amount: float = 360.0
@export var acceleration_time: float = 0.35
@export var rotation_time: float = 0.7
@export var deceleration_time: float = 0.35
@export var pause_time: float = 0.15

@export var pulse_amount: float = 1.08
@export var pulse_time: float = 0.25

var original_scale: Vector2


func _ready() -> void:
	original_scale = scale
	pivot_offset = size / 2.0
	_start_animation()


func _start_animation() -> void:
	rotation = 0.0
	scale = original_scale

	var tween := create_tween()
	tween.set_loops()

	# Smooth acceleration.
	tween.tween_property(
		self,
		"rotation",
		deg_to_rad(rotation_amount * 0.25),
		acceleration_time
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Fast smooth rotation.
	tween.tween_property(
		self,
		"rotation",
		deg_to_rad(rotation_amount),
		rotation_time
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	# Smooth deceleration.
	tween.tween_property(
		self,
		"rotation",
		deg_to_rad(rotation_amount * 1.25),
		deceleration_time
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Small pause before the next rotation.
	tween.tween_interval(pause_time)

	# Subtle pulse.
	tween.parallel().tween_property(
		self,
		"scale",
		original_scale * pulse_amount,
		pulse_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		self,
		"scale",
		original_scale,
		pulse_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
