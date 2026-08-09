class_name CombatSlot
extends Control


# ============================================================
# SIGNALS
# ============================================================

signal combat_slot_updated(slot_index)


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

	# This Control must receive mouse input
	# for Godot's drag-and-drop system.
	mouse_filter = Control.MOUSE_FILTER_STOP


# ============================================================
# DRAG CAT FROM COMBAT SLOT
# ============================================================

func _get_drag_data(
	_at_position: Vector2
) -> Variant:

	if not occupied:
		return null


	if not is_instance_valid(cat_node):
		return null


	# Get the texture used by the cat.
	var tex: Texture2D = (
		CatManager.textures.get(cat_level)
	)


	if tex == null:

		push_error(
			"Missing texture for cat level %d."
			% cat_level
		)

		return null


	# Information passed to the destination.
	var data := {
		"source_type": "combat",
		"source_combat_slot": self,
		"slot_index": slot_index,
		"cat_level": cat_level,
		"cat_texture": tex
	}


	# Small cat preview under the cursor.
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


	# We accept cats from:
	#
	# "slot"    = normal inventory slot
	# "combat"  = another combat slot
	#
	if (
		source_type != "slot"
		and source_type != "combat"
	):

		return false


	# Cat level must exist.
	if not data.has("cat_level"):
		return false


	# Do not allow dropping into an occupied
	# combat position.
	if occupied:
		return false


	return true


# ============================================================
# DROP CAT INTO COMBAT SLOT
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


	# --------------------------------------------------------
	# CAT CAME FROM NORMAL SLOT
	# --------------------------------------------------------

	if source_type == "slot":

		var source_slot = data.get(
			"source_slot"
		)


		if source_slot == null:

			push_error(
				"Source slot missing from drag data."
			)

			return


		if not source_slot.occupied:

			return


		# Remove cat from normal slot.
		source_slot.remove_cat()


	# --------------------------------------------------------
	# CAT CAME FROM ANOTHER COMBAT SLOT
	# --------------------------------------------------------

	elif source_type == "combat":

		var source_combat_slot = data.get(
			"source_combat_slot"
		)


		if source_combat_slot == null:

			push_error(
				"Source combat slot missing."
			)

			return


		# Don't move onto itself.
		if source_combat_slot == self:
			return


		if not source_combat_slot.occupied:

			return


		# Remove cat from previous combat position.
		source_combat_slot.remove_cat()


	# --------------------------------------------------------
	# CREATE CAT IN THIS COMBAT SLOT
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
	# Load cat scene.
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
	# Create cat.
	# --------------------------------------------------------

	cat_node = cat_scene.instantiate()


	if cat_node == null:

		push_error(
			"Could not instantiate cat.tscn"
		)

		return false


	# --------------------------------------------------------
	# Add cat as child of combat slot.
	# --------------------------------------------------------

	add_child(cat_node)


	# --------------------------------------------------------
	# Initialize cat.
	# --------------------------------------------------------

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


	# --------------------------------------------------------
	# Update slot state.
	# --------------------------------------------------------

	occupied = true

	cat_level = level


	# --------------------------------------------------------
	# Position cat above the brown box.
	# --------------------------------------------------------

	var slot_size: Vector2 = size


	if slot_size == Vector2.ZERO:

		slot_size = Vector2(
			100,
			100
		)


	cat_node.position = Vector2(
		slot_size.x / 2.0,
		slot_size.y / 2.0
	)


	# --------------------------------------------------------
	# Make sure cat renders above the combat position.
	# --------------------------------------------------------

	cat_node.z_index = 10


	# --------------------------------------------------------
	# ACTIVATE COMBAT
	# --------------------------------------------------------

	if cat_node.has_method(
		"set_combat_active"
	):

		cat_node.set_combat_active(
			true
		)

	else:

		push_warning(
			"Cat does not have set_combat_active()."
		)


	# --------------------------------------------------------
	# Notify listeners.
	# --------------------------------------------------------

	emit_signal(
		"combat_slot_updated",
		slot_index
	)


	return true


# ============================================================
# REMOVE CAT
# ============================================================

func remove_cat() -> void:

	# --------------------------------------------------------
	# Disable combat before removing the cat.
	# --------------------------------------------------------

	if is_instance_valid(cat_node):

		if cat_node.has_method(
			"set_combat_active"
		):

			cat_node.set_combat_active(
				false
			)


		# Remove cat.
		cat_node.queue_free()


	# --------------------------------------------------------
	# Reset state.
	# --------------------------------------------------------

	cat_node = null

	occupied = false

	cat_level = 0


	# --------------------------------------------------------
	# Notify listeners.
	# --------------------------------------------------------

	emit_signal(
		"combat_slot_updated",
		slot_index
	)


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

	# Size of the cat while dragging.
	var preview_size := Vector2(
		48,
		48
	)


	# Root follows the mouse cursor.
	var root := Control.new()

	root.size = preview_size

	root.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)


	# Visible cat image.
	var preview := TextureRect.new()

	preview.texture = tex

	# Center the cat around cursor.
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


	# Slight transparency while dragging.
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
