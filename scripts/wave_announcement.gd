class_name WaveAnnouncement
extends Control

@onready var panel: Panel = $Panel
@onready var wave_label: Label = $WaveLabel

@export_category("Animation")
@export var intro_duration: float = 0.35
@export var hold_duration: float = 1.5
@export var outro_duration: float = 0.4

@export_category("Label Overshoot")
@export var label_overshoot_scale: Vector2 = Vector2(1.08, 1.08)

var animation_tween: Tween = null

var panel_original_scale: Vector2
var label_original_scale: Vector2

var is_showing: bool = false


func _ready() -> void:
	# --------------------------------------------------------
	# Store original values
	# --------------------------------------------------------

	panel_original_scale = panel.scale
	label_original_scale = wave_label.scale

	# --------------------------------------------------------
	# Initial state
	# --------------------------------------------------------

	visible = false

	panel.modulate.a = 0.0
	wave_label.modulate.a = 0.0

	panel.scale = panel_original_scale
	wave_label.scale = label_original_scale


# ============================================================
# SHOW WAVE
# ============================================================

func show_wave(wave_number: int) -> void:
	if wave_number <= 0:
		return

	# Kill previous animation if one is running.
	if animation_tween != null:
		animation_tween.kill()

	is_showing = true
	visible = true

	# --------------------------------------------------------
	# Set wave text
	# --------------------------------------------------------

	wave_label.text = "WAVE %d" % wave_number

	# --------------------------------------------------------
	# Reset visual state
	# --------------------------------------------------------

	panel.modulate.a = 0.0
	wave_label.modulate.a = 0.0

	panel.scale = panel_original_scale
	wave_label.scale = label_original_scale

	# --------------------------------------------------------
	# Create tween
	# --------------------------------------------------------

	animation_tween = create_tween()

	# --------------------------------------------------------
	# PANEL FADE IN
	# --------------------------------------------------------

	animation_tween.tween_property(
		panel,
		"modulate:a",
		1.0,
		intro_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	# --------------------------------------------------------
	# LABEL FADE IN
	# --------------------------------------------------------

	animation_tween.tween_property(
		wave_label,
		"modulate:a",
		1.0,
		intro_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_OUT
	)

	# --------------------------------------------------------
	# LABEL OVERSHOOT
	# --------------------------------------------------------

	animation_tween.tween_property(
		wave_label,
		"scale",
		label_overshoot_scale,
		intro_duration
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	# --------------------------------------------------------
	# Return label to normal scale
	# --------------------------------------------------------

	animation_tween.tween_property(
		wave_label,
		"scale",
		label_original_scale,
		0.15
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	# --------------------------------------------------------
	# HOLD
	# --------------------------------------------------------

	animation_tween.tween_interval(
		hold_duration
	)

	# --------------------------------------------------------
	# OUTRO
	# --------------------------------------------------------

	animation_tween.set_parallel(true)

	animation_tween.tween_property(
		panel,
		"modulate:a",
		0.0,
		outro_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	animation_tween.tween_property(
		wave_label,
		"modulate:a",
		0.0,
		outro_duration
	).set_trans(
		Tween.TRANS_QUAD
	).set_ease(
		Tween.EASE_IN
	)

	# --------------------------------------------------------
	# Finish
	# --------------------------------------------------------

	animation_tween.chain().tween_callback(
		_finish_animation
	)


# ============================================================
# FINISH ANIMATION
# ============================================================

func _finish_animation() -> void:
	is_showing = false
	visible = false

	panel.modulate.a = 0.0
	wave_label.modulate.a = 0.0

	panel.scale = panel_original_scale
	wave_label.scale = label_original_scale


# ============================================================
# HIDE IMMEDIATELY
# ============================================================

func hide_announcement() -> void:
	if animation_tween != null:
		animation_tween.kill()

	is_showing = false
	visible = false

	panel.modulate.a = 0.0
	wave_label.modulate.a = 0.0

	panel.scale = panel_original_scale
	wave_label.scale = label_original_scale
