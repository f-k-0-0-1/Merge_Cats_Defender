class_name TrapSlot
extends Control

@export var slot_index: int = 0

var occupied: bool = false
var placed_trap: Trap = null

var background_panel: Control = null


func _ready() -> void:
	add_to_group("trap_slots")

	# The slot itself receives mouse input.
	mouse_filter = Control.MOUSE_FILTER_STOP

	_find_background_panel()

	# Make children of the slot non-interactive.
	# This is important if Panel or other UI elements overlap
	# the slot and steal the mouse event.
	_disable_child_mouse_input()

	_update_slot_visual()


# ============================================================
# FIND PANEL
# ============================================================

func _find_background_panel() -> void:
	background_panel = get_node_or_null(
		"Panel"
	) as Control


# ============================================================
# DISABLE CHILD INPUT
# ============================================================

func _disable_child_mouse_input() -> void:
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE


# ============================================================
# INPUT
# ============================================================

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index != MOUSE_BUTTON_LEFT:
			return

		if not event.pressed:
			return

		_on_slot_pressed()

		accept_event()

	elif event is InputEventScreenTouch:
		if not event.pressed:
			return

		_on_slot_pressed()

		accept_event()


# ============================================================
# SLOT PRESSED
# ============================================================

func _on_slot_pressed() -> void:
	if not occupied:
		return

	if placed_trap == null:
		return

	if not is_instance_valid(placed_trap):
		clear_trap()
		return

	var manager := get_tree().get_first_node_in_group(
		"trap_manager"
	)

	if manager == null:
		push_error(
			"TrapSlot: TrapManager not found."
		)
		return

	if manager.has_method("start_drag_existing"):
		manager.start_drag_existing(
			placed_trap,
			self
		)


# ============================================================
# PLACE NEW TRAP
# ============================================================

func place_trap(data: TrapData) -> bool:
	if occupied:
		return false

	if data == null:
		push_error(
			"TrapSlot: TrapData is null."
		)
		return false

	if data.trap_scene == null:
		push_error(
			"TrapSlot: Trap scene is not assigned."
		)
		return false

	var trap: Trap = data.trap_scene.instantiate() as Trap

	if trap == null:
		push_error(
			"TrapSlot: Could not instantiate trap."
		)
		return false

	var gameplay := get_tree().current_scene

	if gameplay == null:
		trap.queue_free()
		return false

	var trap_container := gameplay.get_node_or_null(
		"TrapContainer"
	) as Node2D

	if trap_container == null:
		push_error(
			"TrapSlot: TrapContainer not found."
		)
		trap.queue_free()
		return false

	trap_container.add_child(trap)

	# IMPORTANT:
	# Set position after adding to TrapContainer.
	trap.global_position = get_world_position()

	trap.setup(data)

	placed_trap = trap
	occupied = true

	_update_slot_visual()

	print(
		"Placed trap: ",
		data.trap_name,
		" | Slot: ",
		slot_index
	)

	return true


# ============================================================
# PLACE EXISTING TRAP
# ============================================================

func place_existing_trap(trap: Trap) -> bool:
	if occupied:
		return false

	if trap == null:
		return false

	if not is_instance_valid(trap):
		return false

	placed_trap = trap
	occupied = true

	trap.global_position = get_world_position()

	trap.visible = true
	trap.set_being_dragged(false)

	_update_slot_visual()

	print(
		"Trap moved into slot: ",
		slot_index
	)

	return true


# ============================================================
# GET WORLD CENTER
# ============================================================

func get_world_position() -> Vector2:
	var gameplay := get_tree().current_scene
	if gameplay != null:
		var trap_positions_node := gameplay.get_node_or_null("World/TrapPositions")
		if trap_positions_node != null:
			# Match slot_index to the corresponding marker (0 -> TrapPosition1, etc.)
			var marker_name = "TrapPosition" + str(slot_index + 1)
			var marker := trap_positions_node.get_node_or_null(marker_name) as Marker2D
			if marker != null:
				return marker.global_position

	# Fallback if marker is missing
	return global_position + size * 0.5


# ============================================================
# CLEAR TRAP
# ============================================================

func clear_trap() -> void:
	placed_trap = null
	occupied = false

	_update_slot_visual()


# ============================================================
# REMOVE TRAP
# ============================================================

func remove_trap() -> void:
	if placed_trap != null:
		if is_instance_valid(placed_trap):
			placed_trap.queue_free()

	clear_trap()


# ============================================================
# SLOT VISUAL
# ============================================================

func _update_slot_visual() -> void:
	if background_panel == null:
		return

	background_panel.visible = not occupied
