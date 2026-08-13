class_name TrapManager
extends Node2D

@export_category("Trap Slots")
@export var trap_slots: Array[Control] = []

@export_category("Placement")
@export var placement_distance: float = 120.0

@export_category("Preview")
@export var preview_alpha: float = 0.6

@export_category("Trash Bin")
@export var trash_bin: Control
@export var trash_drop_margin: float = 20.0

var is_dragging: bool = false

var dragged_trap: TrapData = null
var dragged_existing_trap: Trap = null
var source_slot: TrapSlot = null

var drag_preview: Sprite2D = null


func _ready() -> void:
	add_to_group("trap_manager")
	set_process(true)

	if trash_bin != null:
		trash_bin.mouse_filter = Control.MOUSE_FILTER_IGNORE


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

func start_drag_existing(
	trap: Trap,
	from_slot: TrapSlot
) -> void:
	if trap == null:
		return

	if from_slot == null:
		return

	if is_dragging:
		return

	if not is_instance_valid(trap):
		return

	if not is_instance_valid(from_slot):
		return

	if trap.trap_data == null:
		push_error(
			"TrapManager: Existing trap has no TrapData."
		)
		return

	dragged_existing_trap = trap
	dragged_trap = trap.trap_data
	source_slot = from_slot

	is_dragging = true

	# Remove trap from source slot.
	source_slot.clear_trap()

	# Disable combat while dragging.
	if trap.has_method("set_being_dragged"):
		trap.set_being_dragged(true)

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

	var mouse_position: Vector2 = get_global_mouse_position()

	# --------------------------------------------------------
	# Update Trash Bin Hover State
	# --------------------------------------------------------
	if trash_bin != null and trash_bin.has_method("set_hovered"):
		trash_bin.set_hovered(_is_mouse_over_trash_bin())

	# --------------------------------------------------------
	# Existing trap follows mouse
	# --------------------------------------------------------
	if dragged_existing_trap != null:
		if is_instance_valid(dragged_existing_trap):
			dragged_existing_trap.global_position = mouse_position

	# --------------------------------------------------------
	# New trap preview follows mouse
	# --------------------------------------------------------
	elif drag_preview != null:
		drag_preview.global_position = mouse_position

	# --------------------------------------------------------
	# Mouse release
	# --------------------------------------------------------
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_finish_drag()

# ============================================================
# CREATE DRAG PREVIEW
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

	var mouse_position: Vector2 = get_global_mouse_position()

	# ========================================================
	# 1. ABSOLUTE PRIORITY: TRASH BIN CHECK
	# ========================================================
	if _is_mouse_over_trash_bin():
		print("SUCCESS: Drop detected inside Trash Bin.")
		_delete_dragged_trap()
		return

	# ========================================================
	# 2. NORMAL SLOT CHECK
	# ========================================================
	var target_slot: TrapSlot = _find_best_slot(mouse_position)

	if target_slot == null:
		print("No valid trap slot.")
		_restore_existing_trap()
		return

	var slot_position: Vector2 = target_slot.get_world_position()
	var distance: float = mouse_position.distance_to(slot_position)

	if distance > placement_distance:
		print("Trap dropped too far from slot. Distance: ", distance)
		_restore_existing_trap()
		return

	# ========================================================
	# 3. EXISTING TRAP MOVE
	# ========================================================
	if dragged_existing_trap != null:
		_move_existing_trap(target_slot)
		return

	# ========================================================
	# 4. NEW TRAP PLACEMENT
	# ========================================================
	if dragged_trap != null:
		var success: bool = target_slot.place_trap(dragged_trap)
		if success:
			print("Trap placed in slot: ", target_slot.slot_index)
		else:
			print("Failed to place trap.")

	_clear_drag_state()
# ============================================================
# TRASH BIN DETECTION
# ============================================================

func _is_mouse_over_trash_bin() -> bool:
	if trash_bin == null:
		return false

	if not is_instance_valid(trash_bin):
		return false

	# Get global bounding rect of the trash bin control element
	var rect: Rect2 = trash_bin.get_global_rect()

	# Expand the bounding box slightly to make it easier to drop items onto it on mobile touchscreens
	rect = rect.grow(trash_drop_margin)

	# Use viewport mouse position for reliable UI canvas hit testing
	var viewport_mouse: Vector2 = get_viewport().get_mouse_position()

	var inside: bool = rect.has_point(viewport_mouse)

	if inside:
		print("TRASH BIN DETECTED AT VIEWPORT POS: ", viewport_mouse)

	return inside

# ============================================================
# DELETE DRAGGED TRAP
# ============================================================

func _delete_dragged_trap() -> void:
	# --------------------------------------------------------
	# Existing trap from a slot
	# --------------------------------------------------------
	if dragged_existing_trap != null:
		if is_instance_valid(dragged_existing_trap):
			if trash_bin != null and trash_bin.has_method("delete_trap"):
				trash_bin.delete_trap(dragged_existing_trap)
			else:
				dragged_existing_trap.queue_free()

		_clear_drag_state()
		return

	# --------------------------------------------------------
	# New unplaced trap from shop button
	# --------------------------------------------------------
	if dragged_trap != null:
		print("Cancelled/Deleted new unplaced trap: ", dragged_trap.trap_name)
		_clear_drag_state()
		return

	_clear_drag_state()

# ============================================================
# FIND BEST SLOT
# ============================================================

func _find_best_slot(
	mouse_position: Vector2
) -> TrapSlot:

	var best_slot: TrapSlot = null
	var best_distance: float = INF

	for node: Control in trap_slots:

		if not is_instance_valid(node):
			continue

		var slot: TrapSlot = (
			node as TrapSlot
		)

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

	return best_slot


# ============================================================
# MOVE EXISTING TRAP
# ============================================================

func _move_existing_trap(
	target_slot: TrapSlot
) -> void:

	if dragged_existing_trap == null:
		_clear_drag_state()
		return

	if not is_instance_valid(
		dragged_existing_trap
	):
		_clear_drag_state()
		return

	if source_slot == null:
		_restore_existing_trap()
		return

	var trap: Trap = (
		dragged_existing_trap
	)

	# Same slot.
	if target_slot == source_slot:
		_restore_existing_trap()
		return

	var success: bool = (
		target_slot.place_existing_trap(
			trap
		)
	)

	if success:

		trap.visible = true
		trap.z_index = 0

		if trap.has_method("set_being_dragged"):
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

	else:

		print(
			"Failed to move trap. Restoring source slot."
		)

		_restore_existing_trap()


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

	var trap: Trap = (
		dragged_existing_trap
	)

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

	if trap.has_method("set_being_dragged"):
		trap.set_being_dragged(false)

	print(
		"Trap returned to original slot."
	)

	_clear_drag_state()


# ============================================================
# CLEAR DRAG STATE
# ============================================================

func _clear_drag_state() -> void:
	_remove_drag_preview()

	if trash_bin != null and trash_bin.has_method("set_hovered"):
		trash_bin.set_hovered(false)

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
