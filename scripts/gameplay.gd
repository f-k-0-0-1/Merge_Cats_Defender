extends Node2D


@onready var buy_cat_button: TextureButton = $BuyCatButton
@onready var defense_wall: DefenseWall = $World/DefenseWall
@onready var wave_manager: WaveManager = $WaveManager
@onready var current_wave_label: Label = $CurrentWave/Label
@onready var tutorial_ui: TutorialUI = $TutorialUI
@onready var buy_cat_level_label: Label = $BuyCatButton/LevelLabel


var level_data: LevelData
var slots: Array[TextureRect] = []


func _ready() -> void:
	_load_level_data()

	if level_data == null:
		return

	_apply_level_data()

	_setup_slots()
	_create_starting_cats()
	_connect_slot_signals()
	_update_buy_button()
	_update_buy_cat_level_label()
	_setup_wave_manager()

	if level_data.tutorial_enabled:
		_setup_tutorial()
	else:
		_skip_tutorial()


# ============================================================
# LEVEL DATA
# ============================================================

func _load_level_data() -> void:
	level_data = GameplayManager.selected_level

	if level_data == null:
		push_error(
			"Gameplay: No LevelData selected."
		)


func _apply_level_data() -> void:
	_apply_wall_settings()
	_apply_wave_settings()


func _apply_wall_settings() -> void:
	if defense_wall == null:
		push_error(
			"Gameplay: DefenseWall not found."
		)
		return

	defense_wall.configure(
		level_data.wall_max_health,
		level_data.wall_repair_amount
	)


func _apply_wave_settings() -> void:
	if wave_manager == null:
		push_error(
			"Gameplay: WaveManager not found."
		)
		return

	wave_manager.configure_waves(
		level_data.waves
	)


# ============================================================
# WAVE MANAGER
# ============================================================

func _setup_wave_manager() -> void:
	if wave_manager == null:
		push_error(
			"Gameplay: WaveManager not found."
		)
		return

	wave_manager.set_tutorial_locked(true)

	if not wave_manager.wave_changed.is_connected(
		_on_wave_changed
	):
		wave_manager.wave_changed.connect(
			_on_wave_changed
		)

	_update_wave_label(
		wave_manager.current_wave
	)


# ============================================================
# TUTORIAL
# ============================================================

func _setup_tutorial() -> void:
	if tutorial_ui == null:
		push_error(
			"Gameplay: TutorialUI not found."
		)
		return

	tutorial_ui.visible = true

	if not tutorial_ui.tutorial_finished.is_connected(
		_on_tutorial_finished
	):
		tutorial_ui.tutorial_finished.connect(
			_on_tutorial_finished
	)


func _on_tutorial_finished() -> void:
	if wave_manager == null:
		return

	print(
		"Tutorial finished. Unlocking WaveManager."
	)

	wave_manager.set_tutorial_locked(false)


func _skip_tutorial() -> void:
	if tutorial_ui != null:
		tutorial_ui.visible = false

	if wave_manager != null:
		wave_manager.set_tutorial_locked(false)

	print(
		"Tutorial disabled for ",
		level_data.level_name
	)


# ============================================================
# CAT SLOTS
# ============================================================

func _setup_slots() -> void:
	slots.clear()

	var found_slots: Array[Node] = get_tree().get_nodes_in_group(
		"cat_slots"
	)

	for node: Node in found_slots:
		if node is TextureRect:
			slots.append(node)

	slots.sort_custom(_sort_slots)

	print(
		"Found ",
		slots.size(),
		" cat slots."
	)


func _sort_slots(
	a: TextureRect,
	b: TextureRect
) -> bool:
	return a.slot_index < b.slot_index


func _connect_slot_signals() -> void:
	for slot: TextureRect in slots:
		if not slot.slot_updated.is_connected(
			_on_slot_updated
		):
			slot.slot_updated.connect(
				_on_slot_updated
			)


func _on_slot_updated(
	_slot_index: int
) -> void:
	_update_buy_button()


# ============================================================
# STARTING CATS
# ============================================================

func _create_starting_cats() -> void:
	var texture: Texture2D = CatManager.textures.get(
		level_data.starting_cat_level
	)

	if texture == null:
		push_error(
			"Starting cat texture not found for level: "
			+ str(level_data.starting_cat_level)
		)
		return

	var created_cats: int = 0

	for slot: TextureRect in slots:
		if created_cats >= level_data.starting_cats:
			break

		if slot.occupied:
			continue

		var success: bool = slot.place_cat(
			level_data.starting_cat_level,
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
# BUY CAT
# ============================================================

func _find_empty_slot() -> TextureRect:
	for slot: TextureRect in slots:
		if not slot.occupied:
			return slot

	return null


func _update_buy_button() -> void:
	if buy_cat_button == null:
		return

	var empty_slot: TextureRect = _find_empty_slot()

	buy_cat_button.disabled = empty_slot == null


func _on_buy_cat_button_pressed() -> void:
	var empty_slot: TextureRect = _find_empty_slot()

	if empty_slot == null:
		print(
			"Cannot buy cat: all slots are full."
		)

		_update_buy_button()
		return

	var texture: Texture2D = CatManager.textures.get(
		level_data.buy_cat_level
	)

	if texture == null:
		push_error(
			"Buy cat texture not found for level: "
			+ str(level_data.buy_cat_level)
		)
		return

	var success: bool = empty_slot.place_cat(
		level_data.buy_cat_level,
		texture
	)

	if not success:
		return

	print(
		"Bought Level ",
		level_data.buy_cat_level,
		" cat → ",
		empty_slot.name
	)

	_update_buy_button()

	if tutorial_ui != null:
		if tutorial_ui.is_buy_cat_step():
			tutorial_ui.complete_buy_cat()


# ============================================================
# DEFENSE WALL
# ============================================================

func _on_repair_wall_button_pressed() -> void:
	if defense_wall == null:
		push_error(
			"DefenseWall not found."
		)
		return

	defense_wall.repair()


# ============================================================
# WAVE DISPLAY
# ============================================================

func _on_wave_changed(
	wave_number: int
) -> void:
	_update_wave_label(
		wave_number
	)


func _update_wave_label(
	wave_number: int
) -> void:
	if current_wave_label == null:
		return

	if level_data == null:
		return

	current_wave_label.text = (
		"Wave "
		+ str(wave_number)
		+ "/"
		+ str(level_data.waves.size())
	)


func _update_buy_cat_level_label() -> void:
	if buy_cat_level_label == null:
		return

	if level_data == null:
		return

	buy_cat_level_label.text = (
		"Level "
		+ str(level_data.buy_cat_level)
	)

# ============================================================
# BACK
# ============================================================

func _on_back_button_pressed() -> void:
	SceneManager.go_to_level_select()
