extends CanvasLayer

func _on_continue_button_pressed() -> void:
	GameplayManager.reset_game()
	SceneManager.go_to_level_select()
