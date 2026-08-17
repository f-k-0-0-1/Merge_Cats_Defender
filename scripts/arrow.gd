class_name TutorialArrow
extends TextureRect

@export var move_distance: float = 12.0
@export var move_duration: float = 0.5

var start_position: Vector2
var tween: Tween


func _ready() -> void:
	start_position = position
	_start_animation()


func _start_animation() -> void:
	if tween:
		tween.kill()

	position = start_position

	tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		self,
		"position",
		start_position + Vector2(0.0, move_distance),
		move_duration
	)

	tween.tween_property(
		self,
		"position",
		start_position,
		move_duration
	)
