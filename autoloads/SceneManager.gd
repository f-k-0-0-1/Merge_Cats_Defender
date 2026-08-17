extends Node

const SPLASH_SCENE := "res://scenes/Splash_Screen.tscn"
const MENU_SCENE := "res://scenes/main_menu.tscn"
const LEVEL_SELECT := "res://scenes/Level_Select.tscn"
const GAMEPLAY := "res://scenes/gameplay.tscn"

var _is_loading: bool = false
var _loading_path: String = ""


func go_to_splash() -> void:
	change_scene(SPLASH_SCENE)


func go_to_menu() -> void:
	change_scene(MENU_SCENE)


func go_to_level_select() -> void:
	change_scene(LEVEL_SELECT)


func go_to_gameplay() -> void:
	if _is_loading:
		return

	if not ResourceLoader.exists(GAMEPLAY):
		push_error(
			"SceneManager: Gameplay scene not found: "
			+ GAMEPLAY
		)
		return

	_loading_path = GAMEPLAY

	var error: Error = ResourceLoader.load_threaded_request(
		_loading_path,
		"PackedScene"
	)

	if error != OK:
		push_error(
			"SceneManager: Failed to start threaded loading. Error: "
			+ str(error)
		)
		_loading_path = ""
		_is_loading = false
		return

	_is_loading = true
	set_process(true)


func change_scene(scene_path: String) -> void:
	if _is_loading:
		return

	if not ResourceLoader.exists(scene_path):
		push_error(
			"SceneManager: Scene not found: "
			+ scene_path
		)
		return

	var error: Error = get_tree().change_scene_to_file(
		scene_path
	)

	if error != OK:
		push_error(
			"SceneManager: Failed to load scene: "
			+ scene_path
		)


func is_loading() -> bool:
	return _is_loading


func _process(_delta: float) -> void:
	if not _is_loading:
		return

	if _loading_path.is_empty():
		_is_loading = false
		set_process(false)
		return

	var progress: Array = []

	var status := ResourceLoader.load_threaded_get_status(
		_loading_path,
		progress
	)

	var current_scene := get_tree().current_scene

	if current_scene != null:
		if current_scene.has_method("update_loading"):
			var value: float = 0.0

			if not progress.is_empty():
				value = float(progress[0]) * 100.0

			current_scene.update_loading(value)

	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return

		ResourceLoader.THREAD_LOAD_LOADED:
			_finish_gameplay_loading()

		ResourceLoader.THREAD_LOAD_FAILED:
			push_error(
				"SceneManager: Gameplay loading failed: "
				+ _loading_path
			)
			_cancel_loading()

		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error(
				"SceneManager: Invalid threaded resource: "
				+ _loading_path
			)
			_cancel_loading()


func _finish_gameplay_loading() -> void:
	var loaded_resource: Resource = ResourceLoader.load_threaded_get(
		_loading_path
	)

	var gameplay_scene := loaded_resource as PackedScene

	if gameplay_scene == null:
		push_error(
			"SceneManager: Loaded resource is not a PackedScene."
		)
		_cancel_loading()
		return

	_is_loading = false
	_loading_path = ""
	set_process(false)

	get_tree().change_scene_to_packed(
		gameplay_scene
	)


func _cancel_loading() -> void:
	_is_loading = false
	_loading_path = ""
	set_process(false)
