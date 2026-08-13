extends Control

@onready var tap_area: TextureButton = $TapArea
@onready var tap_label: Label = $Label

@export_category("Tap To Play")
@export var attention_scale: float = 1.03
@export var attention_duration: float = 0.16
@export var attention_pause: float = 2.0
@export var attention_alpha: float = 0.85

@export_category("Press Feedback")
@export var press_scale: float = 0.94
@export var press_duration: float = 0.08

var tap_tween: Tween
var original_scale: Vector2
var original_alpha: float


func _ready() -> void:
	if tap_label == null:
		push_error("MainMenu: Label not found.")
		return

	original_scale = tap_label.scale
	original_alpha = tap_label.modulate.a

	await get_tree().process_frame

	_set_label_pivot()
	_start_attention_animation()


# ============================================================
# LABEL PIVOT
# ============================================================

func _set_label_pivot() -> void:
	if tap_label == null:
		return

	tap_label.pivot_offset = tap_label.size / 2.0


# ============================================================
# ATTENTION ANIMATION
# ============================================================

func _start_attention_animation() -> void:
	if tap_label == null:
		return

	if tap_tween != null:
		tap_tween.kill()

	tap_label.scale = original_scale
	tap_label.modulate.a = original_alpha

	tap_tween = create_tween()
	tap_tween.set_loops()

	# --------------------------------------------------------
	# Stay idle
	# --------------------------------------------------------

	tap_tween.tween_interval(
		attention_pause
	)

	# --------------------------------------------------------
	# Small scale emphasis
	# --------------------------------------------------------

	tap_tween.tween_property(
		tap_label,
		"scale",
		original_scale * attention_scale,
		attention_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	# --------------------------------------------------------
	# Slight opacity emphasis
	# --------------------------------------------------------

	tap_tween.parallel().tween_property(
		tap_label,
		"modulate:a",
		1.0,
		attention_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	# --------------------------------------------------------
	# Settle back to normal
	# --------------------------------------------------------

	tap_tween.tween_property(
		tap_label,
		"scale",
		original_scale,
		0.24
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	# --------------------------------------------------------
	# Return opacity
	# --------------------------------------------------------

	tap_tween.parallel().tween_property(
		tap_label,
		"modulate:a",
		original_alpha,
		0.24
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)


# ============================================================
# TAP
# ============================================================

func _on_tap_area_pressed() -> void:
	if tap_tween != null:
		tap_tween.kill()

	var press_tween := create_tween()

	# --------------------------------------------------------
	# Press down
	# --------------------------------------------------------

	press_tween.tween_property(
		tap_label,
		"scale",
		original_scale * press_scale,
		press_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	# --------------------------------------------------------
	# Release / settle
	# --------------------------------------------------------

	press_tween.tween_property(
		tap_label,
		"scale",
		original_scale,
		0.18
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	press_tween.tween_callback(
		_go_to_level_select
	)


# ============================================================
# LEVEL SELECT
# ============================================================

func _go_to_level_select() -> void:
	SceneManager.go_to_level_select()
