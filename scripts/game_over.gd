extends CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _on_restart_button_pressed() -> void:
	GameplayManager.reset_game()
	get_tree().reload_current_scene()

func _on_home_button_pressed() -> void:
	GameplayManager.reset_game()
	SceneManager.go_to_level_select()
