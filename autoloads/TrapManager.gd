class_name TrapManager
extends Node2D

@export_category("Trap Slots")
@export var trap_slots: Array[Control] = []

@export_category("Placement")
@export var placement_distance: float = 120.0

@export_category("Preview")
@export var preview_alpha: float = 0.6

var is_dragging: bool = false
var dragged_trap: TrapData = null
var drag_preview: Sprite2D = null

func _ready() -> void:
	set_process(true)

func start_drag(data: TrapData) -> void:
	if data == null:
		return

	if is_dragging:
		return

	dragged_trap = data
	is_dragging = true

	_create_drag_preview()

	print(
		"Started dragging trap: ",
		data.trap_name
	)

func _process(_delta: float) -> void:
	if not is_dragging:
		return

	if drag_preview != null:
		drag_preview.global_position = get_global_mouse_position()

	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_finish_drag()

func _create_drag_preview() -> void:
	_remove_drag_preview()

	if dragged_trap == null:
		return

	if dragged_trap.icon == null:
		return

	drag_preview = Sprite2D.new()
	drag_preview.texture = dragged_trap.icon
	drag_preview.scale = dragged_trap.scale
	drag_preview.modulate.a = preview_alpha
	drag_preview.z_index = 1000

	add_child(drag_preview)

	drag_preview.global_position = get_global_mouse_position()

func _finish_drag() -> void:
	if not is_dragging:
		return

	if dragged_trap == null:
		_cancel_drag()
		return

	var mouse_position: Vector2 = get_global_mouse_position()

	var best_slot: TrapSlot = null
	var best_distance: float = INF

	for node: Control in trap_slots:
		if not is_instance_valid(node):
			continue

		var slot := node as TrapSlot

		if slot == null:
			continue

		if slot.occupied:
			continue

		var slot_position: Vector2 = slot.get_world_position()

		var distance: float = mouse_position.distance_to(
			slot_position
		)

		if distance < best_distance:
			best_distance = distance
			best_slot = slot

	if best_slot == null:
		print("No available trap slot.")
		_cancel_drag()
		return

	if best_distance > placement_distance:
		print(
			"Trap dropped too far from slot. Distance: ",
			best_distance
		)
		_cancel_drag()
		return

	var success: bool = best_slot.place_trap(
		dragged_trap
	)

	if success:
		print(
			"Trap placed in slot: ",
			best_slot.slot_index
		)
	else:
		print("Failed to place trap.")

	_cancel_drag()

func _cancel_drag() -> void:
	_remove_drag_preview()

	is_dragging = false
	dragged_trap = null

func _remove_drag_preview() -> void:
	if drag_preview != null:
		if is_instance_valid(drag_preview):
			drag_preview.queue_free()

		drag_preview = null
