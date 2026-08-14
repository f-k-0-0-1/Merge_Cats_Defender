class_name TrashBin
extends TextureButton

@export_category("Visual")
@export var hover_scale: Vector2 = Vector2(1.1, 1.1)

@export_category("Detection")
@export var drop_margin: float = 20.0

var original_scale: Vector2
var _bin_is_hovered: bool = false


func _ready() -> void:
	add_to_group("trash_bin")

	original_scale = scale

	# The TrashBin must receive Control drag/drop events.
	mouse_filter = Control.MOUSE_FILTER_STOP


# ============================================================
# CAT DRAG & DROP
# ============================================================

func _can_drop_data(
	_position: Vector2,
	data: Variant
) -> bool:

	if not data is Dictionary:
		return false

	var source_type: String = data.get(
		"source_type",
		""
	)

	# Your current Slot.gd uses:
	#
	# "slot"   -> normal inventory cat
	# "combat" -> deployed combat cat
	#
	if source_type != "slot" and source_type != "combat":
		return false

	# Make sure this is actually cat drag data.
	if not data.has("cat_level"):
		return false

	if not data.has("cat_texture"):
		return false

	return true


func _drop_data(
	_position: Vector2,
	data: Variant
) -> void:

	if not data is Dictionary:
		return

	var source_type: String = data.get(
		"source_type",
		""
	)

	# ========================================================
	# NORMAL INVENTORY CAT
	# ========================================================

	if source_type == "slot":
		_delete_inventory_cat(data)
		return

	# ========================================================
	# COMBAT CAT
	# ========================================================

	if source_type == "combat":
		_delete_combat_cat(data)
		return


# ============================================================
# DELETE NORMAL INVENTORY CAT
# ============================================================

func _delete_inventory_cat(
	data: Dictionary
) -> void:

	if not data.has("source_slot"):
		push_error(
			"TrashBin: source_slot missing from cat drag data."
		)
		return

	var source_slot = data.get(
		"source_slot"
	)

	if source_slot == null:
		return

	if not is_instance_valid(source_slot):
		return

	# Make sure the source is actually occupied.
	if not source_slot.occupied:
		return

	# Get the actual Cat Node2D.
	var cat: Node2D = source_slot.cat_node

	if cat == null:
		# Slot state exists but the node doesn't.
		# remove_cat() will clean the slot state.
		source_slot.remove_cat()

		print(
			"Trash Bin: Cleared empty cat slot."
		)

		return

	var level: int = data.get(
		"cat_level",
		source_slot.cat_level
	)

	print(
		"Trash Bin: Deleted Level ",
		level,
		" cat from Slot ",
		source_slot.slot_index
	)

	# IMPORTANT:
	# remove_cat() already:
	# - disables combat
	# - queue_free()s the Cat
	# - clears cat_node
	# - clears occupied
	# - resets cat_level
	# - emits slot_updated
	source_slot.remove_cat()


# ============================================================
# DELETE COMBAT CAT
# ============================================================

func _delete_combat_cat(
	data: Dictionary
) -> void:

	if not data.has("source_combat_slot"):
		push_error(
			"TrashBin: source_combat_slot missing from cat drag data."
		)
		return

	var source_combat_slot = data.get(
		"source_combat_slot"
	)

	if source_combat_slot == null:
		return

	if not is_instance_valid(
		source_combat_slot
	):
		return

	if not source_combat_slot.occupied:
		return

	var level: int = data.get(
		"cat_level",
		0
	)

	print(
		"Trash Bin: Deleted Level ",
		level,
		" combat cat from CombatSlot ",
		source_combat_slot.slot_index
	)

	# Your CombatSlot already uses remove_cat()
	# in the existing cat movement/merge system.
	if source_combat_slot.has_method(
		"remove_cat"
	):
		source_combat_slot.remove_cat()
	else:
		push_error(
			"TrashBin: CombatSlot does not have remove_cat()."
	)


# ============================================================
# POINTER DETECTION
#
# Used by TrapManager.
# ============================================================

func is_pointer_inside(
	_world_position: Vector2
) -> bool:

	var rect: Rect2 = get_global_rect()

	# Slightly enlarge the drop area.
	rect = rect.grow(
		drop_margin
	)

	var viewport_mouse: Vector2 = (
		get_viewport().get_mouse_position()
	)

	return rect.has_point(
		viewport_mouse
	)


# ============================================================
# HOVER EFFECT
# ============================================================

func set_hovered(
	value: bool
) -> void:

	if _bin_is_hovered == value:
		return

	_bin_is_hovered = value

	var target_scale: Vector2

	if _bin_is_hovered:
		target_scale = hover_scale
	else:
		target_scale = original_scale

	var tween := create_tween()

	tween.set_trans(
		Tween.TRANS_QUAD
	)

	tween.set_ease(
		Tween.EASE_OUT
	)

	tween.tween_property(
		self,
		"scale",
		target_scale,
		0.12
	)


# ============================================================
# DELETE TRAP
#
# Used by TrapManager.
# ============================================================

func delete_trap(
	trap: Trap
) -> void:

	if trap == null:
		return

	if not is_instance_valid(
		trap
	):
		return

	var trap_name: String = "Unknown"

	if trap.trap_data != null:
		trap_name = trap.trap_data.trap_name

	print(
		"Trash Bin: Deleted trap -> ",
		trap_name
	)

	# Your Trap.gd handles finding and clearing
	# its TrapSlot when it dies.
	trap.queue_free()
