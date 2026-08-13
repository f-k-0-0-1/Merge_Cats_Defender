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
var dragged_existing_trap: Trap = null
var source_slot: TrapSlot = null

var drag_preview: Sprite2D = null


func _ready() -> void:
	add_to_group("trap_manager")
	set_process(true)


# ============================================================
# INPUT
# ============================================================

func _input(event: InputEvent) -> void:
	if is_dragging:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if not event.pressed:
					_finish_drag()
					get_viewport().set_input_as_handled()

		elif event is InputEventScreenTouch:
			if not event.pressed:
				_finish_drag()
				get_viewport().set_input_as_handled()

		return

	# --------------------------------------------------------
	# Mouse press
	# --------------------------------------------------------

	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return

		if not event.pressed:
			return

		var trap: Trap = _get_trap_at_mouse()

		if trap != null:
			start_drag_existing(trap)
			get_viewport().set_input_as_handled()

		return

	# --------------------------------------------------------
	# Touch press
	# --------------------------------------------------------

	if event is InputEventScreenTouch:
		if not event.pressed:
			return

		var touch_position: Vector2 = event.position
		var trap: Trap = _get_trap_at_world_position(
			_screen_to_world(touch_position)
		)

		if trap != null:
			start_drag_existing(trap)
			get_viewport().set_input_as_handled()


# ============================================================
# START NEW TRAP DRAG
# ============================================================

func start_drag(data: TrapData) -> void:
	if data == null:
		return

	if is_dragging:
		return

	dragged_trap = data
	dragged_existing_trap = null
	source_slot = null

	is_dragging = true

	_create_drag_preview(
		data.icon,
		data.scale
	)

	print(
		"Started dragging trap: ",
		data.trap_name
	)


# ============================================================
# START EXISTING TRAP DRAG
# ============================================================

func start_drag_existing(trap: Trap) -> void:
	if trap == null:
		return

	if not is_instance_valid(trap):
		return

	if is_dragging:
		return

	if trap.trap_data == null:
		push_error(
			"TrapManager: Existing trap has no TrapData."
		)
		return

	var found_slot: TrapSlot = _find_slot_for_trap(
		trap
	)

	if found_slot == null:
		push_error(
			"TrapManager: Could not find source slot for trap."
		)
		return

	# --------------------------------------------------------
	# Save drag state
	# --------------------------------------------------------

	dragged_existing_trap = trap
	dragged_trap = trap.trap_data
	source_slot = found_slot

	is_dragging = true

	# --------------------------------------------------------
	# Clear source slot.
	#
	# This makes its Panel visible.
	# --------------------------------------------------------

	source_slot.clear_trap()

	# --------------------------------------------------------
	# Disable trap combat while moving.
	# --------------------------------------------------------

	trap.set_being_dragged(true)

	# --------------------------------------------------------
	# Put trap above gameplay.
	# --------------------------------------------------------

	trap.visible = true
	trap.z_index = 1000

	print(
		"Started moving trap: ",
		dragged_trap.trap_name,
		" | Source Slot: ",
		source_slot.slot_index
	)


# ============================================================
# PROCESS
# ============================================================

func _process(_delta: float) -> void:
	if not is_dragging:
		return

	var mouse_position: Vector2 = (
		get_global_mouse_position()
	)

	# --------------------------------------------------------
	# Existing trap follows mouse.
	# --------------------------------------------------------

	if dragged_existing_trap != null:
		if is_instance_valid(
			dragged_existing_trap
		):
			dragged_existing_trap.global_position = (
				mouse_position
			)

	# --------------------------------------------------------
	# New trap preview follows mouse.
	# --------------------------------------------------------

	elif drag_preview != null:
		drag_preview.global_position = (
			mouse_position
		)


# ============================================================
# GET TRAP AT MOUSE
# ============================================================

func _get_trap_at_mouse() -> Trap:
	return _get_trap_at_world_position(
		get_global_mouse_position()
	)


# ============================================================
# GET TRAP AT WORLD POSITION
# ============================================================

func _get_trap_at_world_position(
	world_position: Vector2
) -> Trap:

	var traps: Array[Node] = get_tree().get_nodes_in_group(
		"traps"
	)

	var best_trap: Trap = null
	var best_distance: float = INF

	# ========================================================
	# FIRST: CHECK THE SLOT THAT CONTAINS THE TRAP
	#
	# This is more reliable than checking the Sprite2D.
	# ========================================================

	for node: Control in trap_slots:
		if not is_instance_valid(node):
			continue

		var slot := node as TrapSlot

		if slot == null:
			continue

		if not slot.occupied:
			continue

		if slot.placed_trap == null:
			continue

		if not is_instance_valid(
			slot.placed_trap
		):
			continue

		var trap: Trap = slot.placed_trap

		if trap.is_destroyed:
			continue

		if trap.is_being_dragged:
			continue

		var slot_center: Vector2 = (
			slot.get_world_position()
		)

		# Use a generous interaction radius around the slot.
		var distance: float = (
			world_position.distance_to(
				slot_center
			)
		)

		var interaction_radius: float = (
			min(slot.size.x, slot.size.y) * 0.5
		)

		interaction_radius = max(
			interaction_radius,
			60.0
		)

		if distance <= interaction_radius:
			return trap


	# ========================================================
	# SECOND: CHECK ACTUAL SPRITE
	# ========================================================

	for node: Node in traps:
		if not is_instance_valid(node):
			continue

		var trap := node as Trap

		if trap == null:
			continue

		if trap.is_destroyed:
			continue

		if trap.is_being_dragged:
			continue

		if not trap.visible:
			continue

		if trap.sprite == null:
			continue

		if trap.sprite.texture == null:
			continue

		var local_position: Vector2 = (
			trap.sprite.to_local(
				world_position
			)
		)

		if trap.sprite.get_rect().has_point(
			local_position
		):
			var distance: float = (
				world_position.distance_to(
					trap.global_position
				)
			)

			if distance < best_distance:
				best_distance = distance
				best_trap = trap


	# ========================================================
	# THIRD: DISTANCE FALLBACK
	# ========================================================

	if best_trap == null:
		for node: Node in traps:
			if not is_instance_valid(node):
				continue

			var trap := node as Trap

			if trap == null:
				continue

			if trap.is_destroyed:
				continue

			if trap.is_being_dragged:
				continue

			var distance: float = (
				world_position.distance_to(
					trap.global_position
				)
			)

			if distance <= 80.0:
				if distance < best_distance:
					best_distance = distance
					best_trap = trap

	return best_trap


# ============================================================
# SCREEN TO WORLD
# ============================================================

func _screen_to_world(
	screen_position: Vector2
) -> Vector2:

	var canvas_transform: Transform2D = (
		get_viewport().get_canvas_transform()
	)

	return canvas_transform.affine_inverse() * screen_position


# ============================================================
# CREATE PREVIEW
# ============================================================

func _create_drag_preview(
	texture: Texture2D,
	trap_scale: Vector2
) -> void:
	_remove_drag_preview()

	if texture == null:
		push_error(
			"TrapManager: Cannot create preview without texture."
		)
		return

	drag_preview = Sprite2D.new()

	drag_preview.texture = texture
	drag_preview.scale = trap_scale
	drag_preview.modulate.a = preview_alpha
	drag_preview.z_index = 1000

	add_child(
		drag_preview
	)

	drag_preview.global_position = (
		get_global_mouse_position()
	)


# ============================================================
# FINISH DRAG
# ============================================================

func _finish_drag() -> void:
	if not is_dragging:
		return

	var mouse_position: Vector2 = (
		get_global_mouse_position()
	)

	var best_slot: TrapSlot = null
	var best_distance: float = INF

	# --------------------------------------------------------
	# Find closest empty slot.
	# --------------------------------------------------------

	for node: Control in trap_slots:
		if not is_instance_valid(node):
			continue

		var slot := node as TrapSlot

		if slot == null:
			continue

		if slot.occupied:
			continue

		var slot_position: Vector2 = (
			slot.get_world_position()
		)

		var distance: float = (
			mouse_position.distance_to(
				slot_position
			)
		)

		if distance < best_distance:
			best_distance = distance
			best_slot = slot


	# --------------------------------------------------------
	# No slot.
	# --------------------------------------------------------

	if best_slot == null:
		print(
			"No available trap slot."
		)

		_cancel_drag()
		return


	# --------------------------------------------------------
	# Too far.
	# --------------------------------------------------------

	if best_distance > placement_distance:
		print(
			"Trap dropped too far from slot. Distance: ",
			best_distance
		)

		_cancel_drag()
		return


	# ========================================================
	# EXISTING TRAP
	# ========================================================

	if dragged_existing_trap != null:
		_move_existing_trap(
			best_slot
		)

		return


	# ========================================================
	# NEW TRAP
	# ========================================================

	if dragged_trap != null:
		var success: bool = best_slot.place_trap(
			dragged_trap
		)

		if success:
			print(
				"Trap placed in slot: ",
				best_slot.slot_index
			)
		else:
			print(
				"Failed to place trap."
			)

	_cancel_drag()


# ============================================================
# MOVE EXISTING TRAP
# ============================================================

func _move_existing_trap(
	target_slot: TrapSlot
) -> void:

	if dragged_existing_trap == null:
		_cancel_drag()
		return

	if not is_instance_valid(
		dragged_existing_trap
	):
		_cancel_drag()
		return

	if source_slot == null:
		_cancel_drag()
		return

	var trap: Trap = dragged_existing_trap


	# --------------------------------------------------------
	# Same slot.
	# --------------------------------------------------------

	if target_slot == source_slot:
		_restore_existing_trap()
		return


	# --------------------------------------------------------
	# Place into new slot.
	# --------------------------------------------------------

	var success: bool = (
		target_slot.place_existing_trap(
			trap
		)
	)

	if success:
		trap.visible = true
		trap.z_index = 0
		trap.set_being_dragged(false)

		print(
			"Moved trap: ",
			trap.trap_data.trap_name,
			" | From Slot: ",
			source_slot.slot_index,
			" | To Slot: ",
			target_slot.slot_index
		)

		_clear_drag_state()

		return


	# --------------------------------------------------------
	# Failed.
	# --------------------------------------------------------

	print(
		"Failed to move trap. Restoring source slot."
	)

	_restore_existing_trap()


# ============================================================
# FIND SOURCE SLOT
# ============================================================

func _find_slot_for_trap(
	trap: Trap
) -> TrapSlot:

	for node: Control in trap_slots:
		if not is_instance_valid(node):
			continue

		var slot := node as TrapSlot

		if slot == null:
			continue

		if slot.placed_trap == trap:
			return slot

	return null


# ============================================================
# RESTORE EXISTING TRAP
# ============================================================

func _restore_existing_trap() -> void:
	if dragged_existing_trap == null:
		_clear_drag_state()
		return

	if not is_instance_valid(
		dragged_existing_trap
	):
		_clear_drag_state()
		return

	var trap: Trap = dragged_existing_trap

	if source_slot != null:
		var success: bool = (
			source_slot.place_existing_trap(
				trap
			)
		)

		if not success:
			push_error(
				"TrapManager: Failed to restore trap."
			)

	trap.visible = true
	trap.z_index = 0
	trap.set_being_dragged(false)

	print(
		"Trap returned to original slot."
	)

	_clear_drag_state()


# ============================================================
# CANCEL DRAG
# ============================================================

func _cancel_drag() -> void:
	if dragged_existing_trap != null:
		_restore_existing_trap()
		return

	_remove_drag_preview()

	is_dragging = false
	dragged_trap = null
	dragged_existing_trap = null
	source_slot = null


# ============================================================
# CLEAR STATE
# ============================================================

func _clear_drag_state() -> void:
	_remove_drag_preview()

	is_dragging = false
	dragged_trap = null
	dragged_existing_trap = null
	source_slot = null


# ============================================================
# REMOVE PREVIEW
# ============================================================

func _remove_drag_preview() -> void:
	if drag_preview == null:
		return

	if is_instance_valid(
		drag_preview
	):
		drag_preview.queue_free()

	drag_preview = null
