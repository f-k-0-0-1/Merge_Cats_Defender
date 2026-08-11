extends Node

var is_game_over: bool = false

func game_over() -> void:
	if is_game_over:
		return

	is_game_over = true

	print("GAME OVER")

	get_tree().paused = true
