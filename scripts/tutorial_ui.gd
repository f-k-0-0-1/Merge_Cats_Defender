class_name TutorialUI
extends Control

signal tutorial_finished

@export_category("Tutorial Targets")
@export var cat_target_slot: Control
@export var trap_target_slot: Control

@export_category("Animation")
@export var animation_duration: float = 0.25
@export var start_scale: float = 0.92
@export var slide_distance: float = 20.0

@onready var skip_button: BaseButton = $SkipButton

@onready var step_nodes: Array[Control] = [
	$Step1,
	$Step2,
	$Step3,
	$Step4,
	$Step5,
	$Step6,
	$Step7
]

var steps: Array[Control] = []
var current_step: int = 0
var transitioning: bool = false

var cat_placement_active: bool = false
var trap_placement_active: bool = false
var buy_cat_active: bool = false
var merge_cats_active: bool = false


func _ready() -> void:
	add_to_group("tutorial_ui")
	_get_steps()
	_connect_buttons()
	_connect_skip_button()
	_start_tutorial()


func _get_steps() -> void:
	steps.clear()

	for step: Control in step_nodes:
		if step == null:
			push_warning("TutorialUI: Step node is missing.")
			continue

		step.visible = false
		steps.append(step)


func _connect_buttons() -> void:
	for i: int in range(steps.size()):
		var button := steps[i].get_node_or_null(
			"MessageBox/Button"
		) as Button

		if button == null:
			push_warning(
				"TutorialUI: Button missing in Step%d."
				% (i + 1)
			)
			continue

		if not button.pressed.is_connected(
			_on_button_pressed.bind(i)
		):
			button.pressed.connect(
				_on_button_pressed.bind(i)
			)


func _connect_skip_button() -> void:
	if skip_button == null:
		push_warning("TutorialUI: SkipButton not found.")
		return

	if not skip_button.pressed.is_connected(
		_on_skip_pressed
	):
		skip_button.pressed.connect(
			_on_skip_pressed
	)


func _start_tutorial() -> void:
	if steps.is_empty():
		push_error("TutorialUI: No tutorial steps found.")
		visible = false
		return

	visible = true
	modulate.a = 1.0
	current_step = 0
	cat_placement_active = false
	trap_placement_active = false
	buy_cat_active = false
	merge_cats_active = false

	_show_step(steps[current_step])


func _on_skip_pressed() -> void:
	if not visible:
		return

	if transitioning:
		return

	_finish_tutorial()


func _on_button_pressed(step_index: int) -> void:
	if transitioning:
		return

	if step_index != current_step:
		return

	if current_step == 1:
		return

	if current_step == 2:
		return

	if current_step == 4:
		return

	if current_step == 5:
		return

	if current_step == steps.size() - 1:
		_finish_tutorial()
		return

	_show_next_step()


func _show_next_step() -> void:
	if transitioning:
		return

	if current_step >= steps.size() - 1:
		_finish_tutorial()
		return

	transitioning = true

	var old_step: Control = steps[current_step]

	current_step += 1

	var new_step: Control = steps[current_step]

	_animate_out(old_step, new_step)


func _animate_out(
	old_step: Control,
	new_step: Control
) -> void:
	var box := old_step.get_node_or_null(
		"MessageBox"
	) as Control

	if box == null:
		old_step.visible = false
		_show_step(new_step)
		return

	var original_position: Vector2 = box.position

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)

	tween.parallel().tween_property(
		box,
		"modulate:a",
		0.0,
		animation_duration
	)

	tween.parallel().tween_property(
		box,
		"scale",
		Vector2(start_scale, start_scale),
		animation_duration
	)

	tween.parallel().tween_property(
		box,
		"position",
		original_position + Vector2(0.0, slide_distance),
		animation_duration
	)

	tween.finished.connect(
		func() -> void:
			old_step.visible = false
			_show_step(new_step)
	)


func _show_step(step: Control) -> void:
	step.visible = true

	cat_placement_active = current_step == 1
	trap_placement_active = current_step == 2
	buy_cat_active = current_step == 4
	merge_cats_active = current_step == 5

	var button := step.get_node_or_null(
		"MessageBox/Button"
	) as Button

	if button != null:
		button.visible = (
			not cat_placement_active
			and not trap_placement_active
			and not buy_cat_active
			and not merge_cats_active
		)

	var box := step.get_node_or_null(
		"MessageBox"
	) as Control

	if box == null:
		transitioning = false
		return

	var original_position: Vector2 = box.position

	box.modulate.a = 0.0
	box.scale = Vector2(start_scale, start_scale)
	box.position = original_position - Vector2(0.0, slide_distance)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(
		box,
		"modulate:a",
		1.0,
		animation_duration
	)

	tween.parallel().tween_property(
		box,
		"scale",
		Vector2.ONE,
		animation_duration
	)

	tween.parallel().tween_property(
		box,
		"position",
		original_position,
		animation_duration
	)

	tween.finished.connect(
		func() -> void:
			transitioning = false
	)


func is_cat_placement_step() -> bool:
	return cat_placement_active


func is_valid_cat_target(slot: Control) -> bool:
	if not cat_placement_active:
		return true

	if cat_target_slot == null:
		push_warning(
			"TutorialUI: Cat target slot is not assigned."
		)
		return false

	return slot == cat_target_slot


func complete_cat_placement() -> void:
	if not cat_placement_active:
		return

	if current_step != 1:
		return

	cat_placement_active = false
	_show_next_step()


func is_trap_placement_step() -> bool:
	return trap_placement_active


func is_valid_trap_target(slot: Control) -> bool:
	if not trap_placement_active:
		return true

	if trap_target_slot == null:
		push_warning(
			"TutorialUI: Trap target slot is not assigned."
		)
		return false

	return slot == trap_target_slot


func complete_trap_placement() -> void:
	if not trap_placement_active:
		return

	if current_step != 2:
		return

	trap_placement_active = false
	_show_next_step()


func is_buy_cat_step() -> bool:
	return buy_cat_active


func complete_buy_cat() -> void:
	if not buy_cat_active:
		return

	if current_step != 4:
		return

	buy_cat_active = false
	_show_next_step()


func is_merge_cats_step() -> bool:
	return merge_cats_active


func complete_merge_cats() -> void:
	if not merge_cats_active:
		return

	if current_step != 5:
		return

	merge_cats_active = false
	_show_next_step()


func _finish_tutorial() -> void:
	if transitioning:
		return

	transitioning = true

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(
		self,
		"modulate:a",
		0.0,
		0.2
	)

	tween.finished.connect(_finish_cleanup)


func _finish_cleanup() -> void:
	for step: Control in steps:
		step.visible = false

	visible = false
	modulate.a = 1.0
	transitioning = false

	cat_placement_active = false
	trap_placement_active = false
	buy_cat_active = false
	merge_cats_active = false

	tutorial_finished.emit()
