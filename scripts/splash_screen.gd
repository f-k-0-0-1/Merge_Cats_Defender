extends Node

# Lazy Load

@onready var logo = $LbsLogo
@onready var org_name: Label = $LbsLogo/Label

# Exported to Inspector

@export var visible_speed: float = 1.0
@export var exit_wait_time: float = 10.0

# Constants

const ERROR := 1
const MAX_VISIBLE := 1.0

# Local Vars

var cached_alpha := 0.0
var log_t: RichTextLabel
var is_waiting := false
var has_transitioned := false

func _ready() -> void:
	# Black background
	RenderingServer.set_default_clear_color(Color.BLACK)

	log_t = RichTextLabel.new()

	# Start invisible
	cached_alpha = 0.0

	logo.modulate.a = 0.0
	org_name.modulate.a = 0.0

func _process(delta: float) -> void:
	if is_waiting:
		return

	if has_transitioned:
		return

	# Fade in
	cached_alpha += 0.1 * delta * visible_speed
	cached_alpha = clamp(cached_alpha, 0.0, MAX_VISIBLE)

	logo.modulate.a = cached_alpha
	org_name.modulate.a = cached_alpha

	# Finished fading
	if cached_alpha >= MAX_VISIBLE:
		has_transitioned = true

		if SceneManager.has_method("go_to_menu"):
			SceneManager.go_to_menu()
		else:
			var error := get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
			if error != OK:
				_show_error_and_quit("Main Menu Scene Not Found!")

func _show_error_and_quit(error_message: String) -> void:
	is_waiting = true

	log_t.bbcode_enabled = true
	log_t.text = "[color=red]Error:[/color] " + error_message
	log_t.modulate.a = 0.8
	log_t.custom_minimum_size = Vector2(200, 20)
	log_t.add_theme_font_size_override("normal_font_size", 12)
	log_t.fit_content = true
	log_t.scroll_active = false

	add_child(log_t)

	log_t.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	log_t.grow_vertical = Control.GROW_DIRECTION_BEGIN
	log_t.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)

	await get_tree().create_timer(exit_wait_time).timeout
	get_tree().quit(ERROR)
