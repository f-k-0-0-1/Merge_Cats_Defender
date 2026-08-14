class_name FPSManager
extends Node

@export_category("FPS Display")
@export var update_interval: float = 0.25
@export var font_size: int = 18

@export_category("Position")
@export var default_position: Vector2 = Vector2(12.0, 12.0)
@export var screen_margin: float = 8.0

@export_category("Dragging")
@export var drag_enabled: bool = true

var enabled: bool = false

var canvas_layer: CanvasLayer
var panel: Panel
var fps_label: Label

var update_timer: float = 0.0

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	add_to_group("fps_manager")

	_create_overlay()

	_update_visibility()

	var viewport := get_viewport()

	if not viewport.size_changed.is_connected(
		_on_viewport_size_changed
	):
		viewport.size_changed.connect(
			_on_viewport_size_changed
	)


func _process(delta: float) -> void:
	if not enabled:
		return

	update_timer += delta

	if update_timer >= update_interval:
		update_timer = 0.0
		_update_fps()


func _input(event: InputEvent) -> void:
	if not enabled:
		return

	if not drag_enabled:
		return

	if panel == null:
		return

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


func _create_overlay() -> void:
	canvas_layer = CanvasLayer.new()
	canvas_layer.name = "FPSCanvasLayer"
	canvas_layer.layer = 100

	add_child(canvas_layer)

	panel = Panel.new()
	panel.name = "FPSPanel"

	panel.position = default_position
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	canvas_layer.add_child(panel)

	fps_label = Label.new()
	fps_label.name = "FPSLabel"

	fps_label.text = "FPS: 60"
	fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fps_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	fps_label.add_theme_font_size_override(
		"font_size",
		font_size
	)

	panel.add_child(fps_label)

	_update_panel_size()
	_clamp_position()


func _update_panel_size() -> void:
	if panel == null:
		return

	if fps_label == null:
		return

	var minimum_size: Vector2 = (
		fps_label.get_combined_minimum_size()
	)

	var panel_size: Vector2 = (
		minimum_size + Vector2(20.0, 10.0)
	)

	panel.size = panel_size
	panel.custom_minimum_size = panel_size

	fps_label.position = Vector2(
		10.0,
		5.0
	)

	fps_label.size = minimum_size


func _update_fps() -> void:
	if fps_label == null:
		return

	var fps: int = Engine.get_frames_per_second()

	fps_label.text = "FPS: %d" % fps

	_update_panel_size()


func set_enabled(value: bool) -> void:
	enabled = value

	_update_visibility()

	if enabled:
		_clamp_position()


func _update_visibility() -> void:
	if canvas_layer == null:
		return

	canvas_layer.visible = enabled


func _handle_mouse_button(
	event: InputEventMouseButton
) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	var mouse_position: Vector2 = event.position

	if event.pressed:
		if _is_pointer_over_panel(mouse_position):
			is_dragging = true

			drag_offset = (
				mouse_position - panel.position
			)

			get_viewport().set_input_as_handled()
	else:
		if is_dragging:
			is_dragging = false
			_clamp_position()

			get_viewport().set_input_as_handled()


func _handle_mouse_motion(
	event: InputEventMouseMotion
) -> void:
	if not is_dragging:
		return

	var mouse_position: Vector2 = event.position

	panel.position = (
		mouse_position - drag_offset
	)

	_clamp_position()

	get_viewport().set_input_as_handled()


func _handle_screen_touch(
	event: InputEventScreenTouch
) -> void:
	var touch_position: Vector2 = event.position

	if event.pressed:
		if _is_pointer_over_panel(touch_position):
			is_dragging = true

			drag_offset = (
				touch_position - panel.position
			)

			get_viewport().set_input_as_handled()
	else:
		if is_dragging:
			is_dragging = false
			_clamp_position()

			get_viewport().set_input_as_handled()


func _handle_screen_drag(
	event: InputEventScreenDrag
) -> void:
	if not is_dragging:
		return

	var touch_position: Vector2 = event.position

	panel.position = (
		touch_position - drag_offset
	)

	_clamp_position()

	get_viewport().set_input_as_handled()


func _is_pointer_over_panel(
	position: Vector2
) -> bool:
	if panel == null:
		return false

	var panel_rect := Rect2(
		panel.position,
		panel.size
	)

	return panel_rect.has_point(position)


func _clamp_position() -> void:
	if panel == null:
		return

	var viewport_size: Vector2 = (
		get_viewport().get_visible_rect().size
	)

	var panel_size: Vector2 = panel.size

	var minimum_position: Vector2 = Vector2(
		screen_margin,
		screen_margin
	)

	var maximum_position: Vector2 = Vector2(
		max(
			screen_margin,
			viewport_size.x
			- panel_size.x
			- screen_margin
		),
		max(
			screen_margin,
			viewport_size.y
			- panel_size.y
			- screen_margin
		)
	)

	panel.position = Vector2(
		clamp(
			panel.position.x,
			minimum_position.x,
			maximum_position.x
		),
		clamp(
			panel.position.y,
			minimum_position.y,
			maximum_position.y
		)
	)


func _on_viewport_size_changed() -> void:
	_clamp_position()
