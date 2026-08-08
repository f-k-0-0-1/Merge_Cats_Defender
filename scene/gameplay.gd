extends Node2D

@onready var back_button: TextureButton = $UI/BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_button_pressed)

func _on_back_button_pressed() -> void:
	SceneManager.go_to_level_select()
