extends Node2D


# ============================================================
# REFERENCES
# ============================================================

@onready var buy_cat_button: TextureButton = $BuyCatButton
@onready var defense_wall: DefenseWall = $World/DefenseWall


# ============================================================
# SETTINGS
# ============================================================

const STARTING_CATS: int = 2
const STARTING_CAT_LEVEL: int = 1
const BUY_CAT_LEVEL: int = 1


# ============================================================
# VARIABLES
# ============================================================

var slots: Array[TextureRect] = []

# ============================================================
# READY
# ============================================================

func _ready() -> void:
	# Find all slots.
	_setup_slots()

	# Create the two starting cats.
	_create_starting_cats()

	# Connect slot state changes.
	_connect_slot_signals()

	# Update Buy button.
	_update_buy_button()


# ============================================================
# SETUP SLOTS
# ============================================================

func _setup_slots() -> void:

	slots.clear()

	var found_slots: Array[Node] = get_tree().get_nodes_in_group(
		"cat_slots"
	)

	for node: Node in found_slots:

		if node is TextureRect:
			slots.append(node)

	# Sort according to slot_index.
	slots.sort_custom(_sort_slots)

	print(
		"Found ",
		slots.size(),
		" cat slots."
	)


# ============================================================
# SORT SLOTS
# ============================================================

func _sort_slots(
	a: TextureRect,
	b: TextureRect
) -> bool:

	return a.slot_index < b.slot_index


# ============================================================
# CONNECT SLOT SIGNALS
# ============================================================

func _connect_slot_signals() -> void:

	for slot: TextureRect in slots:

		if not slot.slot_updated.is_connected(
			_on_slot_updated
		):
			slot.slot_updated.connect(
				_on_slot_updated
			)


# ============================================================
# SLOT UPDATED
# ============================================================

func _on_slot_updated(_slot_index: int) -> void:

	# A slot may have become empty because of:
	#
	# - moving a cat
	# - merging cats
	# - removing a cat
	#
	# Re-check the Buy button every time.

	_update_buy_button()


# ============================================================
# CREATE STARTING CATS
# ============================================================

func _create_starting_cats() -> void:

	var texture: Texture2D = CatManager.textures.get(
		STARTING_CAT_LEVEL
	)

	if texture == null:

		push_error(
			"Level 1 cat texture not found."
		)

		return


	var created_cats: int = 0


	for slot: TextureRect in slots:

		if created_cats >= STARTING_CATS:
			break

		if slot.occupied:
			continue

		var success: bool = slot.place_cat(
			STARTING_CAT_LEVEL,
			texture
		)

		if success:
			created_cats += 1


	print(
		"Created ",
		created_cats,
		" starting cats."
	)



# ============================================================
# FIND EMPTY SLOT
# ============================================================

func _find_empty_slot() -> TextureRect:

	for slot: TextureRect in slots:

		if not slot.occupied:
			return slot

	return null


# ============================================================
# UPDATE BUY BUTTON
# ============================================================

func _update_buy_button() -> void:

	var empty_slot: TextureRect = _find_empty_slot()

	if empty_slot == null:

		buy_cat_button.disabled = true

	else:

		buy_cat_button.disabled = false


# ============================================================
# BACK BUTTON
# ============================================================

func _on_back_button_pressed() -> void:

	SceneManager.go_to_level_select()



func _on_buy_cat_button_pressed() -> void:

	var empty_slot: TextureRect = _find_empty_slot()

	if empty_slot == null:

		print(
			"Cannot buy cat: all slots are full."
		)

		_update_buy_button()

		return


	var texture: Texture2D = CatManager.textures.get(
		BUY_CAT_LEVEL
	)

	if texture == null:

		push_error(
			"Level 1 cat texture not found."
		)

		return


	var success: bool = empty_slot.place_cat(
		BUY_CAT_LEVEL,
		texture
	)

	if success:

		print(
			"Bought Level 1 cat → ",
			empty_slot.name
		)


	_update_buy_button()


func _on_repair_wall_button_pressed() -> void:
	if defense_wall == null:
		push_error("DefenseWall not found.")
		return

	defense_wall.repair()
