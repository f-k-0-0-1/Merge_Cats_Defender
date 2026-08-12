class_name TrapSlot
extends Control

@export var slot_index: int = 0

var occupied: bool = false
var placed_trap: Trap = null

func _ready() -> void:
	add_to_group("trap_slots")

func place_trap(data: TrapData) -> bool:
	if occupied:
		return false

	if data == null:
		push_error("TrapSlot: TrapData is null.")
		return false

	if data.trap_scene == null:
		push_error("TrapSlot: Trap scene is not assigned.")
		return false

	var trap: Trap = data.trap_scene.instantiate() as Trap

	if trap == null:
		push_error("TrapSlot: Could not instantiate trap.")
		return false

	var gameplay: Node = get_tree().current_scene

	if gameplay == null:
		push_error("TrapSlot: Gameplay scene not found.")
		trap.queue_free()
		return false

	var trap_container: Node2D = gameplay.get_node_or_null(
		"TrapContainer"
	) as Node2D

	if trap_container == null:
		push_error("TrapSlot: TrapContainer not found.")
		trap.queue_free()
		return false

	trap_container.add_child(trap)

	trap.global_position = get_world_position()

	trap.setup(data)

	placed_trap = trap
	occupied = true

	print(
		"Placed trap: ",
		data.trap_name,
		" | Slot: ",
		slot_index
	)

	return true

func get_world_position() -> Vector2:
	return global_position + size / 2.0

func clear_trap() -> void:
	placed_trap = null
	occupied = false

func remove_trap() -> void:
	if not occupied:
		return

	if placed_trap != null:
		if is_instance_valid(placed_trap):
			placed_trap.queue_free()

	clear_trap()
