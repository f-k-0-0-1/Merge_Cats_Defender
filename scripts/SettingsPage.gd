class_name SettingsPage
extends Control

@onready var master_slider: HSlider = $ScrollContainer/VBoxContainer/Panel1/HSlider
@onready var music_slider: HSlider = $ScrollContainer/VBoxContainer/Panel2/HSlider
@onready var sfx_slider: HSlider = $ScrollContainer/VBoxContainer/Panel3/HSlider

@onready var master_percent: Label = $ScrollContainer/VBoxContainer/Panel1/vol_percent
@onready var music_percent: Label = $ScrollContainer/VBoxContainer/Panel2/vol_percent
@onready var sfx_percent: Label = $ScrollContainer/VBoxContainer/Panel3/vol_percent

@onready var damage_numbers_button: TextureButton = $ScrollContainer/VBoxContainer/Panel4/TextureButton
@onready var vibration_button: TextureButton = $ScrollContainer/VBoxContainer/Panel5/TextureButton
@onready var fps_overlay_button: TextureButton = $ScrollContainer/VBoxContainer/Panel6/TextureButton
@onready var restore_defaults_button: TextureButton = $ScrollContainer/VBoxContainer/Panel7/TextureButton

@export_category("Toggle Textures")
@export var on_texture: Texture2D
@export var off_texture: Texture2D

var damage_numbers_enabled: bool = true
var vibration_enabled: bool = true
var fps_overlay_enabled: bool = false


func _ready() -> void:
	_setup_sliders()
	_connect_signals()
	_load_settings()
	_update_ui()


func _setup_sliders() -> void:
	master_slider.min_value = 0.0
	master_slider.max_value = 100.0
	master_slider.step = 1.0

	music_slider.min_value = 0.0
	music_slider.max_value = 100.0
	music_slider.step = 1.0

	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 100.0
	sfx_slider.step = 1.0


func _connect_signals() -> void:
	if not master_slider.value_changed.is_connected(_on_master_volume_changed):
		master_slider.value_changed.connect(_on_master_volume_changed)

	if not music_slider.value_changed.is_connected(_on_music_volume_changed):
		music_slider.value_changed.connect(_on_music_volume_changed)

	if not sfx_slider.value_changed.is_connected(_on_sfx_volume_changed):
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)

	if not damage_numbers_button.pressed.is_connected(_on_damage_numbers_pressed):
		damage_numbers_button.pressed.connect(_on_damage_numbers_pressed)

	if not vibration_button.pressed.is_connected(_on_vibration_pressed):
		vibration_button.pressed.connect(_on_vibration_pressed)

	if not fps_overlay_button.pressed.is_connected(_on_fps_overlay_pressed):
		fps_overlay_button.pressed.connect(_on_fps_overlay_pressed)

	if not restore_defaults_button.pressed.is_connected(_on_restore_defaults_pressed):
		restore_defaults_button.pressed.connect(_on_restore_defaults_pressed)


func _on_master_volume_changed(value: float) -> void:
	master_percent.text = "%d%%" % int(value)
	_set_bus_volume("Master", value)
	_save_settings()


func _on_music_volume_changed(value: float) -> void:
	music_percent.text = "%d%%" % int(value)
	_set_bus_volume("Music", value)
	_save_settings()


func _on_sfx_volume_changed(value: float) -> void:
	sfx_percent.text = "%d%%" % int(value)
	_set_bus_volume("SFX", value)
	_save_settings()


func _set_bus_volume(bus_name: String, percentage: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)

	if bus_index == -1:
		push_warning(
			"SettingsPage: Audio bus not found: " + bus_name
		)
		return

	if percentage <= 0.0:
		AudioServer.set_bus_mute(bus_index, true)
		AudioServer.set_bus_volume_db(bus_index, -80.0)
		return

	AudioServer.set_bus_mute(bus_index, false)

	AudioServer.set_bus_volume_db(
		bus_index,
		linear_to_db(percentage / 100.0)
	)


func _on_damage_numbers_pressed() -> void:
	damage_numbers_enabled = not damage_numbers_enabled

	_update_toggle_texture(
		damage_numbers_button,
		damage_numbers_enabled
	)

	_save_settings()


func _on_vibration_pressed() -> void:
	vibration_enabled = not vibration_enabled

	_update_toggle_texture(
		vibration_button,
		vibration_enabled
	)

	_save_settings()


func _on_fps_overlay_pressed() -> void:
	fps_overlay_enabled = not fps_overlay_enabled

	_update_toggle_texture(
		fps_overlay_button,
		fps_overlay_enabled
	)

	_apply_fps_overlay()
	_save_settings()


func _apply_fps_overlay() -> void:
	if FpsManager == null:
		return

	if FpsManager.has_method("set_enabled"):
		FpsManager.set_enabled(
			fps_overlay_enabled
		)


func _update_toggle_texture(
	button: TextureButton,
	enabled: bool
) -> void:
	if button == null:
		return

	var texture: Texture2D

	if enabled:
		texture = on_texture
	else:
		texture = off_texture

	if texture == null:
		return

	button.texture_normal = texture
	button.texture_pressed = texture
	button.texture_hover = texture


func _update_ui() -> void:
	master_percent.text = "%d%%" % int(master_slider.value)
	music_percent.text = "%d%%" % int(music_slider.value)
	sfx_percent.text = "%d%%" % int(sfx_slider.value)

	_update_toggle_texture(
		damage_numbers_button,
		damage_numbers_enabled
	)

	_update_toggle_texture(
		vibration_button,
		vibration_enabled
	)

	_update_toggle_texture(
		fps_overlay_button,
		fps_overlay_enabled
	)


func _on_restore_defaults_pressed() -> void:
	master_slider.value = 100.0
	music_slider.value = 100.0
	sfx_slider.value = 100.0

	damage_numbers_enabled = true
	vibration_enabled = true
	fps_overlay_enabled = false

	_apply_audio_settings()
	_apply_fps_overlay()

	_update_ui()
	_save_settings()

	print("Settings restored to defaults.")


func _save_settings() -> void:
	var config := ConfigFile.new()

	config.set_value(
		"audio",
		"master_volume",
		master_slider.value
	)

	config.set_value(
		"audio",
		"music_volume",
		music_slider.value
	)

	config.set_value(
		"audio",
		"sfx_volume",
		sfx_slider.value
	)

	config.set_value(
		"gameplay",
		"damage_numbers",
		damage_numbers_enabled
	)

	config.set_value(
		"accessibility",
		"vibration",
		vibration_enabled
	)

	config.set_value(
		"display",
		"fps_overlay",
		fps_overlay_enabled
	)

	config.save("user://settings.cfg")


func _load_settings() -> void:
	var config := ConfigFile.new()

	var error: Error = config.load(
		"user://settings.cfg"
	)

	if error != OK:
		master_slider.value = 100.0
		music_slider.value = 100.0
		sfx_slider.value = 100.0

		damage_numbers_enabled = true
		vibration_enabled = true
		fps_overlay_enabled = false

		_apply_audio_settings()
		_apply_fps_overlay()
		return

	master_slider.value = config.get_value(
		"audio",
		"master_volume",
		100.0
	)

	music_slider.value = config.get_value(
		"audio",
		"music_volume",
		100.0
	)

	sfx_slider.value = config.get_value(
		"audio",
		"sfx_volume",
		100.0
	)

	damage_numbers_enabled = config.get_value(
		"gameplay",
		"damage_numbers",
		true
	)

	vibration_enabled = config.get_value(
		"accessibility",
		"vibration",
		true
	)

	fps_overlay_enabled = config.get_value(
		"display",
		"fps_overlay",
		false
	)

	_apply_audio_settings()
	_apply_fps_overlay()


func _apply_audio_settings() -> void:
	_set_bus_volume(
		"Master",
		master_slider.value
	)

	_set_bus_volume(
		"Music",
		music_slider.value
	)

	_set_bus_volume(
		"SFX",
		sfx_slider.value
	)
