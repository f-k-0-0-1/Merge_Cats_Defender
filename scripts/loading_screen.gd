extends Control

var next_scene: String

func _ready() -> void:
	# 1. Grab the path from the SceneManager
	next_scene = SceneManager.target_level_path
	
	# 2. Tell Godot's background thread to start pushing the heavy Level 1 assets into RAM
	ResourceLoader.load_threaded_request(next_scene)

func _process(_delta: float) -> void:
	var progress = []
	# 3. Check the status of the background loader every frame
	var status = ResourceLoader.load_threaded_get_status(next_scene, progress)
	
	# Optional: You can use progress[0] (which returns a float from 0.0 to 1.0) to update a loading bar here!
	
	# 4. Once fully loaded, safely swap the scenes
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed_scene = ResourceLoader.load_threaded_get(next_scene)
		get_tree().change_scene_to_packed(packed_scene)
