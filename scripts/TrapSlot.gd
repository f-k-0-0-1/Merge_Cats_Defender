class_name TrapSlot
extends Control

@export var slot_index: int = 0

var occupied: bool = false
var placed_trap: Trap = null

@onready var background_panel: Control = get_node_or_null(
	"Panel"
) as Control


func _ready() -> void:
	add_to_group("trap_slots")

	_update_slot_visual()


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
	trap.set_being_dragged(false)

	_update_slot_visual()

	print(
		"Moved trap to slot: ",
		slot_index
	)

	return true


# ============================================================
# GET WORLD CENTER
# ============================================================

func get_world_position() -> Vector2:
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
