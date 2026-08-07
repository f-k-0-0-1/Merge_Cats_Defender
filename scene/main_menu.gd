extends Control

@onready var tap_area: TextureButton = $TapArea

func _on_tap_area_pressed() -> void:
	SceneManager.go_to_level_select()
