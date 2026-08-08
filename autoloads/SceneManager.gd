extends Node

const SPLASH_SCENE := "res://scene/Splash_Screen.tscn"
const LOADING_SCENE := "res://scene/loading_screen.tscn"
const MENU_SCENE := "res://scene/main_menu.tscn"
const LEVEL_SELECT := "res://scene/Level_Select.tscn"
const GAMEPLAY := "res://scene/gameplay.tscn"

var _target_scene : String = ""
var _is_loading := false

func go_to_splash() -> void:
	change_scene(SPLASH_SCENE)

func go_to_menu() -> void:
	change_scene(MENU_SCENE)

func go_to_level_select() -> void:
	change_scene(LEVEL_SELECT)

func go_to_gameplay() -> void:
	change_scene(GAMEPLAY)

func load_level(scene_path : String) -> void:
	if _is_loading:
		return

	_target_scene = scene_path
	change_scene(LOADING_SCENE)

func get_target_scene() -> String:
	return _target_scene

func change_scene(scene_path : String) -> void:

	if _is_loading:
		return

	_is_loading = true

	var error := get_tree().change_scene_to_file(scene_path)

	if error != OK:
		push_error("Failed to load scene: %s" % scene_path)

	_is_loading = false

func loading_finished() -> void:
	_is_loading = false
