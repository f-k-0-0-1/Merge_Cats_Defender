extends TextureRect


# ============================================================
# SIGNALS
# ============================================================

signal slot_updated(slot_index)


# ============================================================
# SLOT SETTINGS
# ============================================================

@export var slot_index: int = 0


# ============================================================
# CAT STATE
# ============================================================

var occupied: bool = false
var cat_level: int = 0
var cat_node: Node2D = null


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	mouse_filter = MOUSE_FILTER_STOP

	# Allows gameplay.gd to automatically find this slot.
	add_to_group("cat_slots")


# ============================================================
# DRAG FROM SLOT
# ============================================================

func _get_drag_data(_at_position: Vector2) -> Variant:

	if not occupied:
		return null


	var tex: Texture2D = CatManager.textures.get(cat_level)


	if tex == null:

		push_error(
			"Missing texture for cat level %d."
			% cat_level
		)

		return null


	var data := {
		"source_type": "slot",
		"source_slot": self,
		"slot_index": slot_index,
		"cat_level": cat_level,
		"cat_texture": tex
	}


	set_drag_preview(
		create_centered_preview(tex)
	)


	return data


# ============================================================
# CAN ACCEPT DROP
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


	# Normal slots can receive cats from:
	#
	# "slot"   -> another normal slot
	# "combat" -> a deployed combat slot
	#
	if (
		source_type != "slot"
		and source_type != "combat"
	):

		return false


	if not data.has("cat_level"):
		return false


	if not data.has("cat_texture"):
		return false


	# A combat cat can be recalled into an
	# empty or occupied normal slot.
	#
	# Occupied normal slots are handled by
	# the merge logic below.


	return true


# ============================================================
# DROP
# ============================================================

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


	var source_level: int = data.get(
		"cat_level",
		0
	)


	var source_texture: Texture2D = data.get(
		"cat_texture"
	)


	if source_level <= 0:
		return


	if source_texture == null:

		push_error(
			"Source cat texture is missing."
		)

		return


	# ========================================================
	# COMBAT SLOT → NORMAL SLOT
	# ========================================================

	if source_type == "combat":

		_handle_combat_cat_drop(
			data,
			source_level,
			source_texture
		)

		return


	# ========================================================
	# NORMAL SLOT → NORMAL SLOT
	# ========================================================

	if source_type == "slot":

		_handle_slot_cat_drop(
			data,
			source_level,
			source_texture
		)

		return


# ============================================================
# HANDLE COMBAT → NORMAL SLOT
# ============================================================

func _handle_combat_cat_drop(
	data: Dictionary,
	source_level: int,
	source_texture: Texture2D
) -> void:

	var source_combat_slot = data.get(
		"source_combat_slot"
	)


	if source_combat_slot == null:

		push_error(
			"Source combat slot is missing."
		)

		return


	# Prevent dropping onto the same object
	# if something unexpected is passed.
	if source_combat_slot == self:
		return


	if not source_combat_slot.occupied:
		return


	# ========================================================
	# TARGET EMPTY
	# ========================================================

	if not occupied:

		# Place first.
		# Only remove the source after successful placement.
		var success: bool = place_cat(
			source_level,
			source_texture
		)


		if not success:

			push_error(
				"Failed to recall cat into Slot %d."
				% slot_index
			)

			return


		source_combat_slot.remove_cat()


		print(
			"Recalled Level ",
			source_level,
			" cat from CombatSlot ",
			source_combat_slot.slot_index,
			" to Slot ",
			slot_index
		)

		return


	# ========================================================
	# TARGET OCCUPIED
	# ========================================================

	# Same level → merge.
	if cat_level == source_level:

		_merge_combat_cat(
			source_combat_slot,
			source_level
		)

		return


	# Different levels cannot merge.
	print(
		"Cannot place Level ",
		source_level,
		" on Level ",
		cat_level,
		" Slot."
	)


# ============================================================
# HANDLE NORMAL SLOT → NORMAL SLOT
# ============================================================

func _handle_slot_cat_drop(
	data: Dictionary,
	source_level: int,
	source_texture: Texture2D
) -> void:

	var source_slot = data.get(
		"source_slot"
	)


	if source_slot == null:

		push_error(
			"Source slot missing from drag data."
		)

		return


	# Don't drop onto itself.
	if source_slot == self:
		return


	if not source_slot.occupied:
		return


	# ========================================================
	# TARGET EMPTY → MOVE
	# ========================================================

	if not occupied:

		var success: bool = place_cat(
			source_level,
			source_texture
		)


		if not success:
			return


		source_slot.remove_cat()


		print(
			"Moved Level ",
			source_level,
			" cat to Slot ",
			slot_index
		)

		return


	# ========================================================
	# TARGET OCCUPIED
	# ========================================================

	# Different levels cannot merge.
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

	_merge_normal_cat(
		source_slot,
		source_level
	)


# ============================================================
# MERGE NORMAL SLOT CAT
# ============================================================

func _merge_normal_cat(
	source_slot,
	source_level: int
) -> void:

	var old_level: int = source_level
	var new_level: int = old_level + 1


	var new_texture: Texture2D = (
		CatManager.textures.get(new_level)
	)


	# Maximum level reached.
	if new_texture == null:

		print(
			"Maximum cat level reached: ",
			old_level
		)

		return


	# Remove both old cats.
	source_slot.remove_cat()
	remove_cat()


	# Create upgraded cat.
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
# MERGE COMBAT SLOT CAT
# ============================================================

func _merge_combat_cat(
	source_combat_slot,
	source_level: int
) -> void:

	var old_level: int = source_level
	var new_level: int = old_level + 1


	var new_texture: Texture2D = (
		CatManager.textures.get(new_level)
	)


	# Maximum level reached.
	if new_texture == null:

		print(
			"Maximum cat level reached: ",
			old_level
		)

		return


	# Remove deployed cat.
	source_combat_slot.remove_cat()


	# Remove target inventory cat.
	remove_cat()


	# Create upgraded inventory cat.
	var success: bool = place_cat(
		new_level,
		new_texture
	)


	if success:

		print(
			"Merged combat Level ",
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


	# --------------------------------------------------------
	# Load cat scene
	# --------------------------------------------------------

	var cat_scene: PackedScene = load(
		"res://scenes/cat.tscn"
	)


	if cat_scene == null:

		push_error(
			"Could not load res://scenes/cat.tscn"
		)

		return false


	# --------------------------------------------------------
	# Instantiate cat
	# --------------------------------------------------------

	var new_cat: Node2D = (
		cat_scene.instantiate()
	)


	if new_cat == null:

		push_error(
			"Could not instantiate cat.tscn"
		)

		return false


	# --------------------------------------------------------
	# Initialize cat
	# --------------------------------------------------------

	if not new_cat.has_method("init"):

		push_error(
			"cat.tscn does not contain init()."
		)

		new_cat.queue_free()

		return false


	new_cat.init(
		level,
		tex
	)


	# --------------------------------------------------------
	# Add cat to slot
	# --------------------------------------------------------

	add_child(new_cat)


	cat_node = new_cat


	# --------------------------------------------------------
	# Update slot state
	# --------------------------------------------------------

	occupied = true
	cat_level = level


	# --------------------------------------------------------
	# Center cat in slot
	# --------------------------------------------------------

	var slot_size: Vector2 = size


	if slot_size == Vector2.ZERO:

		slot_size = Vector2(
			100,
			100
		)


	cat_node.position = (
		slot_size / 2.0
	)


	# --------------------------------------------------------
	# NORMAL SLOT = COMBAT INACTIVE
	# --------------------------------------------------------

	if cat_node.has_method(
		"set_combat_active"
	):

		cat_node.set_combat_active(
			false
		)


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


	# --------------------------------------------------------
	# Disable combat just in case.
	# --------------------------------------------------------

	if is_instance_valid(cat_node):

		if cat_node.has_method(
			"set_combat_active"
		):

			cat_node.set_combat_active(
				false
			)


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

	# Temporary visual size while dragging.
	var preview_size := Vector2(
		48,
		48
	)


	# --------------------------------------------------------
	# Root follows cursor
	# --------------------------------------------------------

	var root := Control.new()

	root.size = preview_size

	root.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	# --------------------------------------------------------
	# Cat preview
	# --------------------------------------------------------

	var preview := TextureRect.new()

	preview.texture = tex

	# Center visual around cursor.
	preview.position = (
		-preview_size / 2.0
	)

	preview.size = preview_size


	preview.expand_mode = (
		TextureRect.EXPAND_IGNORE_SIZE
	)


	preview.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)


	preview.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	preview.modulate = Color(
		1.0,
		1.0,
		1.0,
		0.8
	)


	root.add_child(
		preview
	)


	return root
