extends TextureRect

signal slot_updated(slot_index)

@export var slot_index: int = 0

var occupied: bool = false
var cat_level: int = 0
var cat_node: Node2D = null


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP

	# Allows gameplay.gd to automatically find this slot.
	add_to_group("cat_slots")


# ============================================================
# DRAG FROM SLOT
# ============================================================

func _get_drag_data(_at_position: Vector2):

	if not occupied:
		return null

	var tex: Texture2D = CatManager.textures.get(cat_level)

	if tex == null:
		push_error("Missing texture for cat level ", cat_level)
		return null

	var data := {
		"source_type": "slot",
		"source_slot": self,
		"slot_index": slot_index,
		"cat_level": cat_level,
		"cat_texture": tex
	}

	set_drag_preview(create_centered_preview(tex))

	return data


# ============================================================
# CAN ACCEPT DROP
# ============================================================

func _can_drop_data(_position: Vector2, data: Variant) -> bool:

	if not data is Dictionary:
		return false

	if data.get("source_type", "") != "slot":
		return false

	if not data.has("source_slot"):
		return false

	if not data.has("cat_level"):
		return false

	return true


# ============================================================
# DROP
# ============================================================

func _drop_data(_position: Vector2, data: Variant) -> void:

	if not data is Dictionary:
		return

	if data.get("source_type", "") != "slot":
		return

	var source_slot = data.get("source_slot")

	if source_slot == null:
		push_error("Source slot missing from drag data.")
		return

	# Don't drop a cat onto itself.
	if source_slot == self:
		return

	if not source_slot.occupied:
		return

	var source_level: int = data.get("cat_level", 0)
	var source_texture: Texture2D = data.get("cat_texture")

	if source_texture == null:
		push_error("Source cat texture is missing.")
		return


	# ========================================================
	# TARGET IS EMPTY → MOVE CAT
	# ========================================================

	if not occupied:

		source_slot.remove_cat()

		place_cat(
			source_level,
			source_texture
		)

		print(
			"Moved level ",
			source_level,
			" cat to Slot ",
			slot_index
		)

		return


	# ========================================================
	# TARGET IS OCCUPIED → CHECK LEVEL
	# ========================================================

	if cat_level != source_level:

		print(
			"Cannot merge Level ",
			source_level,
			" with Level ",
			cat_level
		)

		return


	# ========================================================
	# SAME LEVEL → MERGE
	# ========================================================

	var old_level: int = cat_level
	var new_level: int = old_level + 1

	var new_texture: Texture2D = CatManager.textures.get(
		new_level
	)

	if new_texture == null:

		print(
			"Maximum cat level reached: ",
			old_level
		)

		return


	# Remove source cat.
	source_slot.remove_cat()

	# Remove target cat.
	remove_cat()

	# Create upgraded cat in this slot.
	var success: bool = place_cat(
		new_level,
		new_texture
	)

	if success:

		print(
			"Merged Level ",
			old_level,
			" → Level ",
			new_level
		)


# ============================================================
# PLACE CAT
# ============================================================

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


	# --------------------------------------------------------
	# Update slot state
	# --------------------------------------------------------

	occupied = true
	cat_level = level


	# --------------------------------------------------------
	# Create actual cat
	# --------------------------------------------------------

	cat_node = cat_scene.instantiate()

	if cat_node == null:

		occupied = false
		cat_level = 0

		push_error(
			"Could not instantiate cat.tscn"
		)

		return false


	add_child(cat_node)

	cat_node.init(
		level,
		tex
	)


	# --------------------------------------------------------
	# Center cat in slot
	# --------------------------------------------------------

	var slot_size: Vector2 = size

	if slot_size == Vector2.ZERO:
		slot_size = Vector2(100, 100)

	cat_node.position = slot_size / 2


	# --------------------------------------------------------
	# Notify Gameplay
	# --------------------------------------------------------

	emit_signal(
		"slot_updated",
		slot_index
	)

	return true


# ============================================================
# REMOVE CAT
# ============================================================

func remove_cat() -> Node2D:

	var removed_cat: Node2D = cat_node


	if is_instance_valid(cat_node):

		cat_node.queue_free()


	# --------------------------------------------------------
	# Clear slot state
	# --------------------------------------------------------

	cat_node = null
	occupied = false
	cat_level = 0


	# --------------------------------------------------------
	# Notify Gameplay
	# --------------------------------------------------------

	emit_signal(
		"slot_updated",
		slot_index
	)


	return removed_cat


# ============================================================
# GET SLOT INDEX
# ============================================================

func get_slot_index() -> int:

	return slot_index


# ============================================================
# DRAG PREVIEW
# ============================================================

func create_centered_preview(
	tex: Texture2D
) -> Control:

	# Only the temporary drag preview uses this size.
	var preview_size := Vector2(48, 48)


	# --------------------------------------------------------
	# Root follows the mouse cursor
	# --------------------------------------------------------

	var root := Control.new()

	root.size = preview_size

	root.mouse_filter = Control.MOUSE_FILTER_IGNORE


	# --------------------------------------------------------
	# Visible cat
	# --------------------------------------------------------

	var preview := TextureRect.new()

	preview.texture = tex

	# Move visual texture half its size
	# so cursor is at the center.
	preview.position = -preview_size / 2

	preview.size = preview_size

	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE

	preview.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)

	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	preview.modulate = Color(
		1,
		1,
		1,
		0.8
	)


	root.add_child(preview)

	return root
