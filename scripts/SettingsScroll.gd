class_name SettingsScroll
extends ScrollContainer

@export_category("Scrolling")
@export var drag_sensitivity: float = 1.0
@export var smooth_scroll: bool = true
@export var smooth_speed: float = 14.0

var dragging: bool = false
var drag_start_y: float = 0.0
var drag_start_scroll: float = 0.0
var target_scroll: float = 0.0


func _ready() -> void:
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	target_scroll = float(scroll_vertical)

	set_process(true)


func _process(delta: float) -> void:
	if dragging:
		return

	if not smooth_scroll:
		return

	var current_scroll: float = float(scroll_vertical)

	if abs(current_scroll - target_scroll) < 0.5:
		scroll_vertical = int(target_scroll)
		return

	scroll_vertical = int(
		lerp(
			current_scroll,
			target_scroll,
			min(smooth_speed * delta, 1.0)
		)
	)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
		return

	if event is InputEventMouseMotion:
		_handle_mouse_motion(event)
		return

	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
		return

	if event is InputEventScreenDrag:
		_handle_screen_drag(event)
		return


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if event.pressed:
		_start_drag(event.position.y)
	else:
		_stop_drag()


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not dragging:
		return

	_update_drag(event.position.y)


func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_start_drag(event.position.y)
	else:
		_stop_drag()


func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if not dragging:
		return

	_update_drag(event.position.y)


func _start_drag(y: float) -> void:
	if _get_max_scroll() <= 0.0:
		return

	dragging = true
	drag_start_y = y
	drag_start_scroll = float(scroll_vertical)
	target_scroll = drag_start_scroll


func _update_drag(y: float) -> void:
	if not dragging:
		return

	var movement: float = y - drag_start_y

	target_scroll = drag_start_scroll - (
		movement * drag_sensitivity
	)

	target_scroll = clamp(
		target_scroll,
		0.0,
		_get_max_scroll()
	)

	scroll_vertical = int(target_scroll)


func _stop_drag() -> void:
	dragging = false


func _get_max_scroll() -> float:
	if get_child_count() == 0:
		return 0.0

	var content: Control = get_child(0) as Control

	if content == null:
		return 0.0

	var content_height: float = content.size.y
	var viewport_height: float = size.y

	return max(
		0.0,
		content_height - viewport_height
	)
