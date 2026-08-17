extends TextureRect

@export var move_distance: float = 18.0
@export var move_duration: float = 0.65
@export var pause_time: float = 0.08

var start_position: Vector2


func _ready() -> void:
	start_position = position
	_start_animation()


func _start_animation() -> void:
	var tween := create_tween()
	tween.set_loops()

	tween.tween_property(
		self,
		"position",
		start_position + Vector2(0.0, -move_distance),
		move_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_interval(pause_time)

	tween.tween_property(
		self,
		"position",
		start_position,
		move_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	tween.tween_interval(pause_time)
