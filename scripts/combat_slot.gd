class_name CombatSlot
extends Control

signal combat_slot_updated(slot_index)

@export var slot_index: int = 0

var occupied: bool = false
var cat_level: int = 0
var cat_node: Node2D = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not occupied:
		return null

	if not is_instance_valid(cat_node):
		return null

	var tex: Texture2D = CatManager.textures.get(cat_level)

	if tex == null:
		push_error(
			"Missing texture for cat level %d."
			% cat_level
		)
		return null

	var data := {
		"source_type": "combat",
		"source_combat_slot": self,
		"slot_index": slot_index,
		"cat_level": cat_level,
		"cat_texture": tex
	}

	set_drag_preview(create_centered_preview(tex))

	return data


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

	if source_type != "slot" and source_type != "combat":
		return false

	if not data.has("cat_level"):
		return false

	if occupied:
		return false

	# Tutorial restriction.
	var tutorial_ui := get_tree().get_first_node_in_group(
		"tutorial_ui"
	) as TutorialUI

	if tutorial_ui != null:
		if tutorial_ui.is_cat_placement_step():
			if not tutorial_ui.is_valid_cat_target(self):
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

	var level: int = data.get(
		"cat_level",
		0
	)

	var tex: Texture2D = data.get(
		"cat_texture"
	)

	if level <= 0:
		return

	if tex == null:
		push_error(
			"Cannot place cat. Texture is null."
		)
		return

	# Tutorial restriction.
	var tutorial_ui := get_tree().get_first_node_in_group(
		"tutorial_ui"
	) as TutorialUI

	if tutorial_ui != null:
		if tutorial_ui.is_cat_placement_step():
			if not tutorial_ui.is_valid_cat_target(self):
				return

	# --------------------------------------------------------
	# Check source before modifying it.
	# --------------------------------------------------------

	var source_slot: Node = null
	var source_combat_slot: CombatSlot = null

	if source_type == "slot":
		source_slot = data.get("source_slot")

		if source_slot == null:
			push_error(
				"Source slot missing from drag data."
			)
			return

		if not source_slot.occupied:
			return

	elif source_type == "combat":
		source_combat_slot = data.get(
			"source_combat_slot"
		) as CombatSlot

		if source_combat_slot == null:
			push_error(
				"Source combat slot missing."
			)
			return

		if source_combat_slot == self:
			return

		if not source_combat_slot.occupied:
			return

	# --------------------------------------------------------
	# Place cat first.
	# --------------------------------------------------------

	var success: bool = place_cat(
		level,
		tex
	)

	if not success:
		print(
			"Failed to place cat in CombatSlot ",
			slot_index
		)
		return

	# --------------------------------------------------------
	# Remove cat from source only after successful placement.
	# --------------------------------------------------------

	if source_type == "slot":
		source_slot.remove_cat()

	elif source_type == "combat":
		source_combat_slot.remove_cat()

	# --------------------------------------------------------
	# Complete tutorial objective.
	# --------------------------------------------------------

	if tutorial_ui != null:
		if tutorial_ui.is_cat_placement_step():
			tutorial_ui.complete_cat_placement()


func place_cat(
	level: int,
	tex: Texture2D
) -> bool:
	if occupied:
		return false

	if tex == null:
		push_error(
			"Cannot place cat. Texture is null."
		)
		return false

	var cat_scene: PackedScene = load(
		"res://scenes/cat.tscn"
	)

	if cat_scene == null:
		push_error(
			"Could not load res://scenes/cat.tscn"
		)
		return false

	cat_node = cat_scene.instantiate()

	if cat_node == null:
		push_error(
			"Could not instantiate cat.tscn"
		)
		return false

	add_child(cat_node)

	if not cat_node.has_method("init"):
		push_error(
			"Cat scene does not have init()."
		)

		cat_node.queue_free()
		cat_node = null
		return false

	cat_node.init(
		level,
		tex
	)

	occupied = true
	cat_level = level

	var slot_size: Vector2 = size

	if slot_size == Vector2.ZERO:
		slot_size = Vector2(100.0, 100.0)

	cat_node.position = Vector2(
		slot_size.x / 2.0,
		slot_size.y / 2.0
	)

	cat_node.z_index = 10

	if cat_node.has_method("set_combat_active"):
		cat_node.set_combat_active(true)
	else:
		push_warning(
			"Cat does not have set_combat_active()."
		)

	combat_slot_updated.emit(slot_index)

	return true


func remove_cat() -> void:
	if is_instance_valid(cat_node):
		if cat_node.has_method("set_combat_active"):
			cat_node.set_combat_active(false)

		cat_node.queue_free()

	cat_node = null
	occupied = false
	cat_level = 0

	combat_slot_updated.emit(slot_index)


func get_slot_index() -> int:
	return slot_index


func create_centered_preview(
	tex: Texture2D
) -> Control:
	var preview_size := Vector2(48.0, 48.0)

	var root := Control.new()
	root.size = preview_size
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var preview := TextureRect.new()
	preview.texture = tex
	preview.position = -preview_size / 2.0
	preview.size = preview_size
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.modulate = Color(1.0, 1.0, 1.0, 0.8)

	root.add_child(preview)

	return root
