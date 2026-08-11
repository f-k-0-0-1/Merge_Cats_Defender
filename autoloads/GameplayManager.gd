extends Node

var is_game_over: bool = false

const GAME_OVER_SCENE: PackedScene = preload(
	"res://scenes/game_over.tscn"
)

func game_over() -> void:
	if is_game_over:
		return

	is_game_over = true

	print("GAME OVER")

	var current_scene: Node = get_tree().current_scene

	if current_scene:
		var game_over_ui := GAME_OVER_SCENE.instantiate()

		current_scene.add_child(game_over_ui)

	get_tree().paused = true

func reset_game() -> void:
	is_game_over = false
	get_tree().paused = false
